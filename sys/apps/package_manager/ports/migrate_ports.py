import os
import re
import json
import glob

PORTS_DIR = os.getcwd()

CMAKE_TEMPLATE = """cmake_minimum_required(VERSION 3.20)

include(ExternalProject)

set(PORT_NAME "{name}")
set(PORT_VERSION "{version}")
set(PKG_FILENAME "${{PORT_NAME}}-${{PORT_VERSION}}-${{TARGET_OS}}-${{TARGET_ARCH}}.zip")

set(MY_SRC     "${{CMAKE_CURRENT_BINARY_DIR}}/src")
set(MY_BUILD   "${{CMAKE_CURRENT_BINARY_DIR}}/build")
set(MY_INSTALL "${{CMAKE_CURRENT_BINARY_DIR}}/install")

ExternalProject_Add(${{PORT_NAME}}_pkg
    URL "{url}"
    SOURCE_DIR "${{MY_SRC}}"
    {build_config}
    INSTALL_DIR "${{MY_INSTALL}}"
)

ExternalProject_Add_Step(${{PORT_NAME}}_pkg package_step
    COMMAND ${{CMAKE_COMMAND}} -E tar cfv "../${{PKG_FILENAME}}" --format=zip .
    WORKING_DIRECTORY "${{MY_INSTALL}}"
    DEPENDEES install
    COMMENT ">>> PACKAGING: Creating ${{PKG_FILENAME}} from ${{MY_INSTALL}}"
)

set({upper_name}_INSTALL_DIR "${{MY_INSTALL}}" PARENT_SCOPE)
set({upper_name}_PACKAGE_PATH "${{CMAKE_CURRENT_BINARY_DIR}}/${{PKG_FILENAME}}" PARENT_SCOPE)
"""

PORT_JSON_TEMPLATE = {{
  "name": "{name}",
  "version": "{version}",
  "description": "{name} library",
  "license": "Unknown",
  "dependencies": []
}}

def find_sh_file(directory):
    files = glob.glob(os.path.join(directory, "*.sh"))
    if not files:
        return None
    # Prefer name.sh over build.sh if both exist, but usually it's one or the other
    return files[0]

def parse_sh_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    version_match = re.search(r'VERSION="([^"]+)"', content)
    version = version_match.group(1) if version_match else "0.0.1"

    url_match = re.search(r'URL="([^"]+)"', content)
    url = url_match.group(1) if url_match else ""

    # Try to find tarball URL if URL var is not explicit or uses variables
    if not url or "${" in url:
        # If URL has ${VERSION}, substitute it
        if version and "${VERSION}" in url:
            url = url.replace("${VERSION}", version)
        
        # If still not resolved or empty, try to find wget/curl lines
        # But for now, let's stick to the variable if possible
        pass

    # Detect build type
    build_config = ""
    
    # 1. CMake
    if "cmake .." in content or "cmake ." in content:
        # Try to extract args
        # This is rough, but better than nothing
        # Look for lines starting with -D inside the cmake command block?
        # Or just set standard args
        build_config = """BINARY_DIR "${MY_BUILD}"
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${BUILD_TYPE}
        -DBUILD_SHARED_LIBS=OFF"""
    
    # 2. Autotools (configure)
    elif "./configure" in content:
        build_config = """BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ./configure --prefix=<INSTALL_DIR>
    BUILD_COMMAND make -j8
    INSTALL_COMMAND make install"""

    # 3. Make (no configure)
    elif "make" in content:
        build_config = """BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ""
    BUILD_COMMAND make -j8
    INSTALL_COMMAND make install PREFIX=<INSTALL_DIR>"""
        # Check if PREFIX is used in the script, otherwise might be DESTDIR or just 'install'
        if "PREFIX=" not in content and "DESTDIR=" not in content:
             # Fallback to standard make install
             build_config = build_config.replace(" PREFIX=<INSTALL_DIR>", "")

    # 4. Meson
    elif "meson" in content:
        build_config = """BINARY_DIR "${MY_BUILD}"
    CONFIGURE_COMMAND meson setup <BINARY_DIR> <SOURCE_DIR> --prefix=<INSTALL_DIR> --buildtype=release
    BUILD_COMMAND meson compile -C <BINARY_DIR>
    INSTALL_COMMAND meson install -C <BINARY_DIR>"""

    return {
        "version": version,
        "url": url,
        "build_config": build_config
    }

def process_directory(dirname):
    sh_file = find_sh_file(dirname)
    if not sh_file:
        print(f"Skipping {dirname}: No .sh file found")
        return

    pkg_name = os.path.basename(dirname)
    print(f"Processing {pkg_name}...")

    data = parse_sh_file(sh_file)
    
    # Create CMakeLists.txt
    cmake_content = CMAKE_TEMPLATE.format(
        name=pkg_name,
        upper_name=pkg_name.upper().replace("-", "_"),
        version=data['version'],
        url=data['url'],
        build_config=data['build_config']
    )
    
    with open(os.path.join(dirname, "CMakeLists.txt"), "w") as f:
        f.write(cmake_content)

    # Create port.json
    json_content = PORT_JSON_TEMPLATE.format(
        name=pkg_name,
        version=data['version']
    )
    # Beautify json
    json_obj = json.loads(json_content.replace("'", '"')) # rough fix for single quotes
    
    with open(os.path.join(dirname, "port.json"), "w") as f:
        json.dump(json_obj, f, indent=2)

def main():
    dirs = [d for d in os.listdir(PORTS_DIR) if os.path.isdir(d)]
    dirs.sort()
    
    for d in dirs:
        if d in ["boost", "testpkg", "dep-pkg"]: # Skip existing or special
            continue
        process_directory(d)

if __name__ == "__main__":
    main()
