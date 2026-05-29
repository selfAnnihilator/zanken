# Hardware

Hardware detection scripts (return exit codes for use in conditionals).

| Command | Description |
|---------|-------------|
| `zanken-hw-asus-expertbook-b9406` | Detect ASUS ExpertBook B9406 series laptops on Intel Panther Lake. |
| `zanken-hw-asus-rog` | Detect whether the computer is an Asus ROG machine. |
| `zanken-hw-asus-zenbook-ux5406aa` | Detect ASUS Zenbook UX5406AA series laptops on Intel Panther Lake. |
| `zanken-hw-dell-xps-haptic-touchpad` | Match Dell XPS systems with the Synaptics haptic touchpad. |
| `zanken-hw-dell-xps-oled` | Match Dell XPS systems with LG OLED panel on Intel Panther Lake (Xe3) GPU. |
| `zanken-hw-external-monitors` | Returns true when an external monitor is physically connected. |
| `zanken-hw-framework16` | Detect whether the computer is a Framework Laptop 16. |
| `zanken-hw-hybrid-gpu` | Detect whether the system has an active hybrid GPU configuration |
| `zanken-hw-intel` | Detect whether the computer has an Intel CPU. |
| `zanken-hw-intel-ptl` | Detect whether the computer has an Intel Panther Lake GPU. |
| `zanken-hw-match` | Match against the computer's DMI product name or product family (case-insensitive). |
| `zanken-hw-nvidia-gsp` | Detect whether the computer has an NVIDIA GPU with GSP firmware (Turing or newer). |
| `zanken-hw-nvidia-without-gsp` | Detect whether the computer has an NVIDIA GPU without GSP firmware (Maxwell/Pascal/Volta). |
| `zanken-hw-recover-internal-monitor` | Clear the internal-monitor-disable toggle if no external display is connected. |
| `zanken-hw-surface` | Detect whether the computer is a Microsoft Surface device. |
| `zanken-hw-touchpad` | Print the detected Hyprland touchpad or trackpad device name |
| `zanken-hw-touchscreen` | Print the detected Hyprland touchscreen or tablet device name |
| `zanken-hw-vulkan` | Detect whether Vulkan is available. |
