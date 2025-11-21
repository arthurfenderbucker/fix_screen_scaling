# 🖥️ Fix Screen Scaling

> A smart bash script to eliminate screen flickering and fix scaling issues when using fractional scaling on Ubuntu with external monitors.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform: Ubuntu](https://img.shields.io/badge/Platform-Ubuntu-orange.svg)](https://ubuntu.com/)

## 🎯 Problem Statement

When using fractional scaling on Ubuntu (particularly with HiDPI displays), many users experience:

- **Screen flickering** on external monitors
- **Poor scaling coordination** between built-in and external displays
- **DPI mismatches** causing blurry text or UI elements
- **Inconsistent display behavior** when connecting/disconnecting monitors

This script solves these issues by intelligently managing display scaling through `xrandr`, ensuring smooth operation with both your primary and external displays.

## ✨ Features

- 🔄 **Automatic DPI Matching**: Automatically calculates optimal scaling based on physical display dimensions
- 🎚️ **Manual Scale Override**: Option to specify custom scaling factors
- 📐 **Smart Display Positioning**: Automatically positions displays in a vertical stack with configurable alignment (left, center, right)
- 🔍 **Highest Resolution Detection**: Automatically detects and uses the best available resolution for each display
- 🤖 **Auto-Detection**: Automatically detects primary display name, resolution, and physical dimensions
- 🛡️ **Zero Configuration**: Works out-of-the-box without manual configuration
- ⚡ **Zero Flickering**: Uses precise scaling values to eliminate display flickering

## 📋 Prerequisites

- Ubuntu Linux (or other Linux distributions using X11)
- `xrandr` utility (usually pre-installed)
- `awk` (usually pre-installed)
- Bash shell

## 🚀 Installation

1. Clone or download this repository:

```bash
git clone https://github.com/arthurfenderbucker/fix_screen_scaling.git
cd fix_screen_scaling
```

2. Make the script executable:

```bash
chmod +x screen.sh
```

## 💡 Usage

### Automatic Scaling (Recommended)

Let the script automatically calculate the optimal scale based on DPI matching:

```bash
./screen.sh
```

The script will:
- Auto-detect your primary display
- Auto-detect your external monitor
- Auto-detect physical dimensions for both displays
- Calculate DPI for both displays
- Apply the optimal scaling factor
- Position displays in a centered vertical stack (default alignment)

### Alignment Options

You can control how the primary display is aligned relative to the external display:

**Center alignment (default):**
```bash
./screen.sh -c
# or
./screen.sh --center
```

**Left alignment:**
```bash
./screen.sh -l
# or
./screen.sh --left
```

**Right alignment:**
```bash
./screen.sh -r
# or
./screen.sh --right
```

### Manual Scaling

Specify a custom scaling factor for your external display:

```bash
./screen.sh 1.5
```

Replace `1.5` with your desired scale factor (must be a positive number).

### Combining Options

You can combine manual scaling with alignment options:

```bash
./screen.sh 1.5 --right
./screen.sh 1.25 -l
```

### Example Output

```
Detected primary display: eDP-1
Primary display physical size: 293mm x 183mm
No scale provided, will auto-detect based on DPI matching.
Alignment mode: center
Detected external display: HDMI-1
Primary display mode: 3456x2160
External display mode: 1920x1080
External display physical size: 527mm x 296mm
Primary DPI: 234.5
Connected DPI: 92.7
Calculated scale: 1.262
Executing: xrandr --output eDP-1 --primary --mode 3456x2160 --pos 427x1363 --rotate normal --scale 0.999x0.999 --output HDMI-1 --mode 1920x1080 --scale 1.262x1.262 --pos 0x0 --rotate normal
```

## ⚙️ Configuration

The script now **automatically detects** most settings! You only need to configure these variables in special cases:

| Variable | Description | Default |
|----------|-------------|---------|
| `primary_scale` | Scale factor for primary display (fine-tuning) | `0.999` |
| `scale_adjustment` | Fine-tuning adjustment factor for DPI-based scaling. **If you're using default 100% scaling on your primary display, set this to `1.0`** | `1.01` |
| `default_alignment` | Default alignment for primary display (options: "center", "left", "right") | `"center"` |
| `primary_physical_width_mm_override` | Override auto-detected width (set to 0 to use auto-detection) | `293` |
| `primary_physical_height_mm_override` | Override auto-detected height (set to 0 to use auto-detection) | `183` |

**What's Auto-Detected:**
- ✅ Primary display name (e.g., `eDP-1`)
- ✅ External display name (e.g., `HDMI-1`, `DP-1`)
- ✅ Primary display resolution
- ✅ External display resolution
- ✅ Primary display physical dimensions (can be overridden)
- ✅ External display physical dimensions
- ✅ Optimal scaling factor based on DPI

### Advanced Configuration

If you need to override auto-detection or change the default alignment, you can modify the script directly:

- **Default Alignment**: Change `default_alignment` to "left", "center", or "right" to set your preferred default alignment
- **Primary Scale**: Adjust `primary_scale` if you want to fine-tune the primary display scaling (values close to 1.0)
- **Scale Adjustment**: Modify `scale_adjustment` to fine-tune the DPI-matched scaling calculation
  - **Important**: If you're using the default 100% screen scaling on your primary display (no fractional scaling), set `scale_adjustment` to `1.0`
  - The default value of `1.01` is designed for systems using 100% scaling on the primary display
  - If the calculated scaling doesn't look right, adjust this value to match your primary display's scaling factor
- **Physical Dimensions Override**: If xrandr reports incorrect physical dimensions for your primary display, set `primary_physical_width_mm_override` and `primary_physical_height_mm_override` to the correct values. Set both to `0` to use auto-detection.

## 🔧 How It Works

1. **Primary Display Detection**: Automatically identifies your primary display (marked as "primary" in xrandr or first connected display)
2. **Physical Dimensions Detection**: Extracts physical dimensions (mm) from both displays for DPI calculation
3. **External Display Detection**: Identifies any connected external display
4. **Resolution Detection**: Finds the highest available resolution for each display
5. **DPI Calculation**: Computes DPI based on resolution and physical dimensions
5. **Scale Calculation**: Derives optimal scaling to match primary display DPI
6. **Alignment**: Positions the primary display below the external monitor according to the selected alignment (center, left, or right)
7. **Application**: Applies all settings using a single `xrandr` command

## 🐛 Troubleshooting

### Script says "No external connected display detected"

- Ensure your external monitor is connected and powered on
- Run `xrandr --query` to verify the display is detected
- The script automatically detects all connected displays

### Script says "Unable to detect primary display"

- Run `xrandr --query` to check if any displays are connected
- Ensure you're running the script in an X11 session (not Wayland)
- Check if xrandr is installed: `which xrandr`

### Scaling doesn't look right

- Try adjusting the `scale_adjustment` factor in the script
- Use manual scaling to test different values: `./screen.sh 1.5`
- Check if physical dimensions are detected correctly in the output

### Display positioning is off

The script supports three alignment modes (left, center, right) for vertical stacking. Use the command-line options `-l`, `-c`, or `-r` to change the alignment, or modify the `default_alignment` variable in the script to change the default behavior.

### "Unable to detect physical dimensions"

If the script can't detect physical dimensions:
- It will fall back to a default scale of 1.0
- You can manually specify a scale: `./screen.sh 1.25`
- Some displays don't report physical dimensions correctly via EDID

### Incorrect scaling despite auto-detection

If the auto-detected scaling doesn't match your previous working configuration:
- The physical dimensions reported by xrandr may be inaccurate
- Check the output for "Auto-detected primary display physical size" or "Using configured primary display physical size"
- Override the auto-detection by setting `primary_physical_width_mm_override` and `primary_physical_height_mm_override` in the script
- Compare the DPI values in the output with your working configuration to verify correctness
- **If you're using 100% scaling on your primary display**: Set `scale_adjustment` to `1.0` instead of the default `2.01`
- **If you're using custom fractional scaling**: Adjust `scale_adjustment` to match your primary display's scaling factor (e.g., 1.5 for 150% scaling, 1.25 for 125% scaling)

## 🤝 Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thanks to the Ubuntu and X.Org communities for their excellent documentation
- Inspired by the need to solve fractional scaling issues on modern HiDPI displays

## 📧 Contact

Arthur Fender Coelho Bucker - [@arthurfenderbucker](https://github.com/arthurfenderbucker)

---

**Note**: This script is designed for X11. If you're using Wayland, you may need different tools for display management.

⭐ If this script helped you eliminate screen flickering, please consider giving it a star!
