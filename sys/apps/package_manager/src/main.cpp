#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>
#include <filesystem>
#include <cstdlib>

// Third-party libraries (assumed to be available in include path)
#include <curl/curl.h>
#include "sqlite3.h"
#include "json.hpp"
#include "CLI11.hpp"

namespace fs = std::filesystem;
using json = nlohmann::json;

// ==========================================
// GLOBALS & CONSTANTS
// ==========================================

struct PackageMeta {
    std::string name;
    std::string version;
    std::string description;
};

std::map<std::string, PackageMeta> package_cache; 

const std::string PORTS_DIR = "ports";
const std::string REPO_NAME = "hultrix";
const std::string DB_FILE   = "hpm.db";
const std::string INSTALL_ROOT_DIR = "install"; // New: Dedicated install directory

// UPDATED: Default mirror URL (mutable so it can be overridden by config)
std::string mirror_url = "http://packages.hultrix.com";

// New: Global configuration for target platform and build
std::string global_target_os = "linux";
std::string global_target_arch = "x64";
std::string global_build_type = "Release";

sqlite3* db_handle = nullptr;

// ==========================================
// DATABASE HELPERS
// ==========================================

void init_db() {
    int rc = sqlite3_open(DB_FILE.c_str(), &db_handle);
    if (rc) {
        std::cerr << "Can't open database: " << sqlite3_errmsg(db_handle) << "\n";
        exit(1);
    }

    const char* sql = R"(
        CREATE TABLE IF NOT EXISTS packages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            version TEXT NOT NULL,
            installed_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    )";

    char* errMsg = nullptr;
    rc = sqlite3_exec(db_handle, sql, nullptr, nullptr, &errMsg);
    if (rc != SQLITE_OK) {
        std::cerr << "SQL error: " << errMsg << "\n";
        sqlite3_free(errMsg);
    }
}

void register_package(const std::string& name, const std::string& version) {
    std::string sql = "INSERT OR REPLACE INTO packages (name, version) VALUES ('" + name + "', '" + version + "');";
    char* errMsg = nullptr;
    int rc = sqlite3_exec(db_handle, sql.c_str(), nullptr, nullptr, &errMsg);
    if (rc != SQLITE_OK) {
        std::cerr << "Failed to register package: " << errMsg << "\n";
        sqlite3_free(errMsg);
    } else {
        std::cout << "Package registered in database.\n";
    }
}

// ==========================================
// CONFIG LOADER
// ==========================================
void load_config() {
    if (fs::exists("hultrix.json")) {
        try {
            std::ifstream f("hultrix.json");
            json root_data = json::parse(f);
            
            // Check for mirror override in hultrix.json
            if (root_data.contains("mirror")) {
                mirror_url = root_data["mirror"];
                // Remove trailing slash if present to ensure consistency
                if (!mirror_url.empty() && mirror_url.back() == '/') {
                    mirror_url.pop_back();
                }
                std::cout << "Configuration: Using custom mirror: " << mirror_url << "\n";
            }
            // New: Load global target OS, arch, and build type
            if (root_data.contains("target_os")) {
                global_target_os = root_data["target_os"];
                std::cout << "Configuration: Target OS set to: " << global_target_os << "\n";
            }
            if (root_data.contains("target_arch")) {
                global_target_arch = root_data["target_arch"];
                std::cout << "Configuration: Target Architecture set to: " << global_target_arch << "\n";
            }
            if (root_data.contains("build_type")) {
                global_build_type = root_data["build_type"];
                std::cout << "Configuration: Build Type set to: " << global_build_type << "\n";
            }
        } catch (const std::exception& e) {
            std::cerr << "Warning: Failed to parse hultrix.json configuration: " << e.what() << "\n";
        }
    }
}

// ==========================================
// CURL HELPERS (Network Layer)
// ==========================================

// Callback function to write received data to a file stream
size_t write_data(void* ptr, size_t size, size_t nmemb, FILE* stream) {
    size_t written = fwrite(ptr, size, nmemb, stream);
    return written;
}

bool download_file(const std::string& url, const std::string& output_path) {
    CURL* curl;
    FILE* fp;
    CURLcode res;
    bool success = false;

    curl = curl_easy_init();
    if (curl) {
        fp = fopen(output_path.c_str(), "wb");
        if (!fp) {
            std::cerr << "Error: Could not open file for writing: " << output_path << "\n";
            return false;
        }

        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
        curl_easy_setopt(curl, CURLOPT_FAILONERROR, 1L); // Fail on 4xx/5xx

        // Perform request
        std::cout << "Downloading: " << url << " ... ";
        res = curl_easy_perform(curl);
        
        long http_code = 0;
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);

        if (res == CURLE_OK) {
            std::cout << "[OK]\n";
            success = true;
        } else {
            std::cout << "[FAILED] (HTTP " << http_code << ")\n";
            std::cerr << "curl_easy_perform() failed: " << curl_easy_strerror(res) << "\n";
            // Clean up partial file
            fclose(fp);
            fs::remove(output_path); 
            fp = nullptr; 
        }

        if(fp) fclose(fp);
        curl_easy_cleanup(curl);
    }
    return success;
}


// ==========================================
// BUILD & DEPENDENCY LOGIC
// ==========================================

enum BuildType {
    SCRIPT_BUILD,
    CMAKE_BUILD
};

struct PortInfo {
    std::string name;
    std::string version;
    std::vector<std::string> dependencies;
    fs::path build_path; // Points to the script for SCRIPT_BUILD, or port_dir for CMAKE_BUILD
    BuildType type;
};

// Helper to find the build definition (script or CMakeLists.txt)
PortInfo load_port_info(const std::string& name) {
    PortInfo info;
    info.name = name;
    info.type = SCRIPT_BUILD; // Default to script build

    fs::path port_dir = fs::path(PORTS_DIR) / name;
    
    // Check for CMakeLists.txt first
    fs::path cmake_list_path = port_dir / "CMakeLists.txt";
    if (fs::exists(cmake_list_path)) {
        info.type = CMAKE_BUILD;
        info.build_path = port_dir; // For CMake, the build_path is the source directory
    } else {
        // Fallback to script if no CMakeLists.txt
        fs::path p1 = port_dir / "build.sh";
        fs::path p2 = port_dir / (name + ".sh");

        if (fs::exists(p1)) {
            info.build_path = p1;
        } else if (fs::exists(p2)) {
            info.build_path = p2;
        } else {
            std::cerr << "Error: No build definition (CMakeLists.txt or .sh script) found for port '" << name << "'\n";
            exit(1);
        }
    }

    // Load port.json metadata
    fs::path json_path = port_dir / "port.json";
    if (fs::exists(json_path)) {
        try {
            std::ifstream f(json_path);
            json data = json::parse(f);
            info.version = data.value("version", "latest");
            if (data.contains("dependencies")) {
                for (const auto& dep : data["dependencies"]) {
                    info.dependencies.push_back(dep);
                }
            }
        } catch (const std::exception& e) {
            std::cerr << "Warning: Failed to parse port.json for " << name << ": " << e.what() << "\n";
        }
    }
    
    return info;
}

// Recursive build function
void build_recursive(const std::string& name, std::vector<std::string>& built_cache, const std::vector<std::string>& build_args) {
    // Avoid cycles or rebuilding
    for (const auto& b : built_cache) {
        if (b == name) return;
    }

    PortInfo info = load_port_info(name);
    
    // 1. Build Dependencies first
    if (!info.dependencies.empty()) {
        std::cout << "Resolving dependencies for " << name << "...\n";
        for (const auto& dep : info.dependencies) {
            build_recursive(dep, built_cache, build_args);
        }
    }

    // 2. Build the Package
    std::cout << "\n>>> Building " << name << " (" << info.version << ") <<<\n";
    
    fs::create_directories(INSTALL_ROOT_DIR); // Ensure install directory exists

    int ret = -1;
    if (info.type == SCRIPT_BUILD) {
        // Construct command: bash /path/to/script.sh [args...]
        std::string cmd = "bash " + info.build_path.string();
        for (const auto& arg : build_args) {
            cmd += " \"" + arg + "\"";
        }
        std::cout << "Executing script build: " << cmd << "\n";
        ret = std::system(cmd.c_str());
    } else if (info.type == CMAKE_BUILD) {
        // Create a temporary build directory within cache for CMake
        fs::path temp_cmake_build_dir = fs::path("cache") / "cmake_builds" / name;
        fs::create_directories(temp_cmake_build_dir);

        // Construct CMake configure command
        std::string cmake_configure_cmd = "cmake -S " + info.build_path.string() + // info.build_path is the source dir
                                           " -B " + temp_cmake_build_dir.string() +
                                           " -DCMAKE_INSTALL_PREFIX=" + fs::path(INSTALL_ROOT_DIR).string() +
                                           " -DCMAKE_BUILD_TYPE=" + global_build_type +
                                           " -DTARGET_OS=" + global_target_os +
                                           " -DTARGET_ARCH=" + global_target_arch;
        for (const auto& arg : build_args) { // Pass user args to CMake
            cmake_configure_cmd += " \"" + arg + "\"";
        }

        std::cout << "Running CMake configure: " << cmake_configure_cmd << "\n";
        ret = std::system(cmake_configure_cmd.c_str());
        if (ret != 0) {
            std::cerr << "CMake configure failed for " << name << "\n";
            exit(1);
        }

        // Construct CMake build command
        std::string cmake_build_cmd = "cmake --build " + temp_cmake_build_dir.string();
        // Assuming 'install' target exists or 'package_step' might be needed for some ports.
        // For now, a generic build. 'ExternalProject_Add' will often do the install in its BUILD_COMMAND.
        // A specific target like 'package_step' from boost's CMakeLists.txt could be specified
        // if we detect it, but for now, we rely on ExternalProject's BUILD_COMMAND for installation.
        // cmake_build_cmd += " --target install"; // Or package_step?
        
        std::cout << "Running CMake build: " << cmake_build_cmd << "\n";
        ret = std::system(cmake_build_cmd.c_str());
    }

    if (ret != 0) {
        std::cerr << "Build failed for " << name << "\n";
        exit(1);
    }

    // 3. Register as built/installed
    register_package(name, info.version);
    built_cache.push_back(name);
}

void cmd_build(const std::string& target, const std::vector<std::string>& args) {
    std::vector<std::string> built_cache;
    build_recursive(target, built_cache, args);
    std::cout << "\nBuild chain complete for " << target << ".\n";
}

// ==========================================
// COMMANDS
// ==========================================

void cmd_fetch(const std::string& term) {
    std::cout << "Attempting to fetch binary for: " << term << "\n";
    
    // Logic: Look up version from ports/
    fs::path manifest_path = fs::path(PORTS_DIR) / term / "port.json";
    std::string version = "latest";
    
    if (fs::exists(manifest_path)) {
        try {
            std::ifstream f(manifest_path);
            json data = json::parse(f);
            version = data.value("version", "latest");
        } catch (...) {
            std::cerr << "Error parsing port manifest. Defaulting to 'latest'.\n";
        }
    } else {
        std::cout << "No local port found for " << term << ", trying generic fetch.\n";
    }
    
    // Construct URL using the dynamic mirror_url
    std::string filename = term + "-" + version + "-x64.zip";
    std::string url = mirror_url + "/" + filename;
    
    std::cout << "Target URL: " << url << "\n";
    
    // Check if we have a cache dir
    fs::create_directories("cache");
    std::string output_path = "cache/" + filename;
    
    if (download_file(url, output_path)) {
        std::cout << "Successfully fetched " << filename << "\n";
    } else {
        std::cout << "Binary not found in mirror. Falling back to source build...\n";
        // Fallback logic for source build would go here
    }
}

void cmd_install(const std::string& term) {
    // 1. Fetch
    cmd_fetch(term);

    // 2. Mock Install (Unzip and Link)
    // In a real app, we'd use libzip or system("unzip ...")
    // Here we just simulate success if the cache file exists.
    
    // Re-derive filename (simplified logic)
    fs::path manifest_path = fs::path(PORTS_DIR) / term / "port.json";
    std::string version = "latest";
    if (fs::exists(manifest_path)) {
        std::ifstream f(manifest_path);
        json data = json::parse(f);
        version = data.value("version", "latest");
    }
    
    std::string filename = "cache/" + term + "-" + version + "-x64.zip";
    
    if (fs::exists(filename)) {
        std::cout << "Installing " << term << "...\n";
        // Simulate installation
        register_package(term, version);
        std::cout << "Done.\n";
    } else {
        std::cerr << "Install failed: Binary archive not found.\n";
    }
}

void cmd_list() {
    std::cout << "Installed Packages:\n";
    std::cout << "-------------------\n";
    const char* sql = "SELECT name, version, installed_at FROM packages;";
    char* errMsg = nullptr;
    
    auto callback = [](void* NotUsed, int argc, char** argv, char** azColName) -> int {
        std::cout << argv[0] << " \t (v" << argv[1] << ") \t " << argv[2] << "\n";
        return 0;
    };

    int rc = sqlite3_exec(db_handle, sql, callback, nullptr, &errMsg);
    if (rc != SQLITE_OK) {
        std::cerr << "SQL error: " << errMsg << "\n";
        sqlite3_free(errMsg);
    }
}

// ==========================================
// MAIN
// ==========================================
int main(int argc, char** argv) {
    // Global Init
    curl_global_init(CURL_GLOBAL_ALL);
    init_db();
    
    // Load configuration (including mirror) from hultrix.json
    load_config();

    CLI::App app{"Hultrix Package Manager (HPM)"};
    
    std::string target;

    // Command: fetch
    auto fetch_cmd = app.add_subcommand("fetch", "Download a package binary");
    fetch_cmd->add_option("package", target, "Package name")->required();
    fetch_cmd->callback([&](){ cmd_fetch(target); });

    // Command: install
    auto install_cmd = app.add_subcommand("install", "Install a package");
    install_cmd->add_option("package", target, "Package name")->required();
    install_cmd->callback([&](){ cmd_install(target); });

    // Command: build
    std::vector<std::string> build_args;
    auto build_cmd = app.add_subcommand("build", "Build a package from source");
    build_cmd->add_option("package", target, "Package name")->required();
    build_cmd->add_option("--args", build_args, "Arguments to pass to the build script");
    build_cmd->callback([&](){ cmd_build(target, build_args); });

    // Command: list
    auto list_cmd = app.add_subcommand("list", "List installed packages");
    list_cmd->callback([&](){ cmd_list(); });

    app.require_subcommand(1); 

    try {
        app.parse(argc, argv);
    } catch (const CLI::ParseError &e) {
        return app.exit(e);
    }

    // Cleanup
    sqlite3_close(db_handle);
    curl_global_cleanup();

    return 0;
}
