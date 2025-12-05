Here is the official internal structure of a **Hultrix Application Bundle (`.app`)**.

This layout is designed to be **self-contained**. You should be able to zip this folder, move it to another Hultrix machine, and have it run immediately without installing dependencies.

### **The Standard Layout**

Plaintext

```
/apps/SpaceGame.app/
├── Run                  # (Script) The Launch Entry Point
├── meta.json            # (File)   The Manifest (ID, Name, Version)
├── icon.png             # (File)   The App Icon (512x512 recommended)
├── bin/                 # (Dir)    Compiled Executables
│   ├── space_game       #          The actual heavy binary
│   └── crash_reporter   #          Helper executables
├── lib/                 # (Dir)    Private Libraries (.so)
│   ├── libphys.so       #          Bundled physics engine
│   └── liblua.so        #          Bundled scripting engine
└── res/                 # (Dir)    Static Assets (Read-Only)
    ├── fonts/           #          .ttf / .otf / .sdf
    ├── img/             #          UI textures and sprites
    ├── shaders/         #          .glsl / .spv (User-interest specific)
    ├── sfx/             #          Audio files
    └── lang/            #          Localization files (.json/.po)
```

------

### **Detailed Component Breakdown**

#### **1. The `Run` Script (The Brain)**

This is the most critical file. It is a shell script (or a small C++ loader) that prepares the environment before the actual binary starts.

**Standard `Run` Content:**

Bash

```
#!/sys/bin/sh

# 1. Resolve the absolute path of the bundle
HERE="$(dirname "$(readlink -f "$0")")"

# 2. Force the app to prioritize its own 'lib' folder over the system
#    This prevents "Dependency Hell" updates.
export LD_LIBRARY_PATH="$HERE/lib:$LD_LIBRARY_PATH"

# 3. Launch the actual binary located in 'bin', passing all user arguments ($@)
exec "$HERE/bin/space_game" "$@"
```

#### **2. `bin/` (The Muscle)**

This contains your platform-specific ELF binaries.

- **Why hide them?** Users should never click these directly because they rely on the environment variables set by `Run`.
- **Architecture:** If you plan to support multiple architectures (e.g., ARM64 and x86_64) in one bundle, you can use subfolders here (`bin/x86/`, `bin/arm/`) and have the `Run` script detect the CPU and choose the right one.

#### **3. `lib/` (The Skeleton)**

This contains **Shared Objects (`.so`)**.

- **Rule:** If your app uses a specific version of a library (e.g., `libpng16.so`), you put it here.
- **Isolation:** The OS ignores these files for everyone *except* this specific app. This guarantees your app never breaks when the OS updates.

#### **4. `res/` (The Skin)**

Standardizing the `res` folder allows your SDK to have built-in functions for asset loading.

**SDK Helper Example:**

C++

```
// In your C++ code
// You don't type "../res/shaders/phong.vert"
// You use the SDK standard:
auto shader = Hultrix::LoadShader("phong.vert"); 
// The SDK automatically resolves this to: {BundleRoot}/res/shaders/phong.vert
```

------

### **Optional Directories**

If your application is complex, you may add these standard optional folders:

- **`plugins/`**: If your app supports user add-ons, look for `.so` or `.lua` files here.
- **`defaults/`**: Contains the default configuration files. If the app runs for the first time, it copies files from `defaults/` to `~/.conf/com.app.id/`.

### **Summary of Separation**

| **Location**         | **Purpose**                    | **Writable?**      |
| -------------------- | ------------------------------ | ------------------ |
| **`SpaceGame.app/`** | The immutable code and assets. | **NO** (Read-Only) |
| **`~/.conf/game/`**  | User preferences/settings.     | **YES**            |
| **`~/Documents/`**   | User-created save files.       | **YES**            |
| **`/tmp/`**          | Runtime PID files and cache.   | **YES**            |

**Does this internal structure cover everything you need for your SDK, or do you need a specific place for things like "Shader Caches" or "intermediate build files"?**