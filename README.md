# Linux Auto Display Setup

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-brightgreen.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)

Intelligent Linux display manager that automatically configures multiple monitors based on laptop lid status and connected displays. Supports seamless switching between various display scenarios with smart resolution detection.

## Motivation

Working with multiple monitors on Linux can be frustrating. Every time you dock your laptop, undock it, or close the lid, you need to manually reconfigure your displays. Common problems include:

- Displays not activating at the correct resolution
- Wrong monitor being set as primary
- Wrong monitor position.
- Laptop screen staying on when the lid is closed
- Manual xrandr commands needed for each configuration change
- Inconsistent behavior when switching between docked and undocked setups
- Time wasted configuring displays multiple times per day

This script solves these issues by automatically detecting your setup and applying the optimal configuration every time.

## Features

- Automatic configuration based on connected displays and laptop lid status
- Supports up to 3 external monitors plus laptop display
- Smart resolution selection (prefers 2560x1440, falls back to 1920x1080)
- Comprehensive logging for troubleshooting
- Desktop notifications for configuration changes
- Can run automatically at startup

## Supported Scenarios

The script handles seven different display configurations:

1. Laptop display only
2. Laptop + 1 external monitor (external as primary)
3. Laptop + 2 external monitors
4. Laptop + 3 external monitors
5. 1 external monitor only (lid closed)
6. 2 external monitors only (lid closed)
7. 3 external monitors only (lid closed)

## Installation

Create the directory and download the script:

```bash
cd /home/yourusername
mkdir -p ~/.screenlayout
cd ~/.screenlayout
wget https://raw.githubusercontent.com/yourusername/linux-auto-display-setup/main/display-setup.sh
```

Make it executable:

```bash
chmod +x display-setup.sh
```

Run the script:

```bash
./display-setup.sh
```

### Usage Notes for Manual Execution

- The script will detect your current display configuration automatically
- Check the log file (`~/.screenlayout/display-setup.log`) for detailed execution information
- If you encounter permission issues, ensure the script is executable with `chmod +x`

## Automatic Startup

To run the script automatically at login:

1. Open "Startup Applications Preferences" (search for it in Activities)
2. Click the "Add" button to create a new startup item
3. Fill in the following details:
   - **Name**: Display Setup Script
   - **Command**: `sleep 10 && /home/yourusername/.screenlayout/display-setup.sh`
   - **Comment**: Automatic display configuration at startup
4. Click "Add" to save the configuration

Replace `yourusername` with your actual username. The 10-second delay ensures the display system is fully initialized before the script runs.

### Startup Configuration Notes

- The 10-second delay ensures the display system is fully initialized
- Adjust the sleep duration if you experience timing issues (try 15 seconds if needed)
- To disable: Open "Startup Applications" and uncheck or remove the entry
- Log files are created in the same directory as the script
- If the script doesn't run at startup, check the log file for error messages

## Configuration

You can customize the preferred resolutions by editing these variables in the script:

```bash
PREFERRED_RESOLUTION="2560x1440"
FALLBACK_RESOLUTION="1920x1080"
```

## Logging

The script creates detailed logs at `~/.screenlayout/display-setup.log` with timestamps and execution details:

```
[2024-01-15 09:30:45] [INFO] Display Setup Script Started
[2024-01-15 09:30:45] [INFO] Display Detection Results:
[2024-01-15 09:30:45] [INFO]   Laptop Display: eDP-1
[2024-01-15 09:30:45] [INFO]   External Displays: DP-1 DP-2
[2024-01-15 09:30:45] [INFO]   External Display Count: 2
[2024-01-15 09:30:45] [INFO] Selected Scenario: 6 - 2 external monitors only (lid closed)
[2024-01-15 09:30:46] [INFO] Display configuration successful: 2 external monitors (laptop OFF)
```

Check the logs to troubleshoot issues:

```bash
tail -f ~/.screenlayout/display-setup.log
```

## Troubleshooting

**Script doesn't run at startup**: Check the startup application command path, increase the sleep delay to 15 seconds, and verify the script is executable.

**Wrong display configuration**: Check logs for detection issues and verify monitor connections are secure.

**Lid detection not working**: The script uses best-effort lid detection. Some systems may not support all detection methods, but monitor positioning should still work correctly.

**Permission issues**: Ensure the script is executable:
```bash
chmod +x ~/.screenlayout/display-setup.sh
```

For verbose debugging output:

```bash
bash -x ~/.screenlayout/display-setup.sh
```

## Requirements

- Linux system with X11
- xrandr utility (usually pre-installed)
- notify-send for desktop notifications (optional)

## Contributing

Contributions are welcome. Please fork the repository, create a feature branch, make your changes, and submit a pull request.

## License

This project is licensed under the MIT License.

---

If this script helps improve your multi-monitor workflow, please consider giving it a star!