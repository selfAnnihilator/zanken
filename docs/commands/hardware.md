# Hardware

Hardware detection scripts (return exit codes for use in conditionals).

| Command | Description |
|---------|-------------|
| `omarchy-hw-asus-expertbook-b9406` | Detect ASUS ExpertBook B9406 series laptops on Intel Panther Lake. |
| `omarchy-hw-asus-rog` | Detect whether the computer is an Asus ROG machine. |
| `omarchy-hw-asus-zenbook-ux5406aa` | Detect ASUS Zenbook UX5406AA series laptops on Intel Panther Lake. |
| `omarchy-hw-dell-xps-haptic-touchpad` | Match Dell XPS systems with the Synaptics haptic touchpad. |
| `omarchy-hw-dell-xps-oled` | Match Dell XPS systems with LG OLED panel on Intel Panther Lake (Xe3) GPU. |
| `omarchy-hw-external-monitors` | Returns true when an external monitor is physically connected. |
| `omarchy-hw-framework16` | Detect whether the computer is a Framework Laptop 16. |
| `omarchy-hw-hybrid-gpu` | Detect whether the system has an active hybrid GPU configuration |
| `omarchy-hw-intel` | Detect whether the computer has an Intel CPU. |
| `omarchy-hw-intel-ptl` | Detect whether the computer has an Intel Panther Lake GPU. |
| `omarchy-hw-match` | Match against the computer's DMI product name or product family (case-insensitive). |
| `omarchy-hw-nvidia-gsp` | Detect whether the computer has an NVIDIA GPU with GSP firmware (Turing or newer). |
| `omarchy-hw-nvidia-without-gsp` | Detect whether the computer has an NVIDIA GPU without GSP firmware (Maxwell/Pascal/Volta). |
| `omarchy-hw-recover-internal-monitor` | Clear the internal-monitor-disable toggle if no external display is connected. |
| `omarchy-hw-surface` | Detect whether the computer is a Microsoft Surface device. |
| `omarchy-hw-touchpad` | Print the detected Hyprland touchpad or trackpad device name |
| `omarchy-hw-touchscreen` | Print the detected Hyprland touchscreen or tablet device name |
| `omarchy-hw-vulkan` | Detect whether Vulkan is available. |
