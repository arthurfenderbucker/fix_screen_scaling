#!/bin/bash
set -eo pipefail

# Configuration
primary_scale=0.999
# Scale adjustment factor (divide calculated DPI-matched scale by this value)
# IMPORTANT: If you're using default 100% scaling on your primary display, set this to 1.0
# The default value of 1.01 is designed for 100% scaling on the primary display
# Adjust this to match your primary display's scaling factor if needed
scale_adjustment=1.01

# Alignment configuration
# Options: "center", "left", "right"
# Default alignment for the primary display relative to the external display
default_alignment="center"

# Optional: Override auto-detected physical dimensions (set to 0 to use auto-detection)
# If xrandr reports incorrect physical dimensions, you can hardcode them here
primary_physical_width_mm_override=293
primary_physical_height_mm_override=183

# Auto-detect primary display (typically the built-in display)
xrandr_output=$(xrandr --query)

# Find primary display - look for display marked as "primary" or first connected display
primary_display=$(awk '
    $2=="connected" && $3=="primary" {print $1; exit}
    !found && $2=="connected" {candidate=$1; found=1}
    END {if (candidate) print candidate}
' <<< "$xrandr_output")

if [[ -z "$primary_display" ]]; then
    echo "Error: Unable to detect primary display." >&2
    exit 1
fi

echo "Detected primary display: $primary_display" >&2

# Parse command-line arguments for alignment
alignment="$default_alignment"
scale_arg=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--center)
            alignment="center"
            shift
            ;;
        -l|--left)
            alignment="left"
            shift
            ;;
        -r|--right)
            alignment="right"
            shift
            ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [scale] [-c|--center] [-l|--left] [-r|--right]" >&2
            exit 1
            ;;
        *)
            scale_arg="$1"
            shift
            ;;
    esac
done

echo "Alignment mode: $alignment" >&2

# Use override values if set, otherwise auto-detect
if [[ $primary_physical_width_mm_override -gt 0 ]] && [[ $primary_physical_height_mm_override -gt 0 ]]; then
    primary_physical_width_mm=$primary_physical_width_mm_override
    primary_physical_height_mm=$primary_physical_height_mm_override
    echo "Using configured primary display physical size: ${primary_physical_width_mm}mm x ${primary_physical_height_mm}mm" >&2
else
    # Extract physical dimensions of the primary display
    primary_physical=$(awk -v display="$primary_display" '
        $1==display && $2=="connected" {
            for (i=3; i<=NF; i++) {
                if ($i ~ /^[0-9]+mm$/ && $(i+2) ~ /^[0-9]+mm$/) {
                    w=$(i)
                    h=$(i+2)
                    gsub(/mm$/, "", w)
                    gsub(/mm$/, "", h)
                    printf "%s %s", w, h
                    exit
                }
            }
        }
    ' <<< "$xrandr_output")

    if [[ -z "$primary_physical" ]]; then
        echo "Warning: Unable to detect physical dimensions of primary display." >&2
        echo "DPI-based scaling may not work correctly." >&2
        primary_physical_width_mm=0
        primary_physical_height_mm=0
    else
        read -r primary_physical_width_mm primary_physical_height_mm <<< "$primary_physical"
        echo "Auto-detected primary display physical size: ${primary_physical_width_mm}mm x ${primary_physical_height_mm}mm" >&2
    fi
fi

if [[ -n "$scale_arg" ]]; then
    scale="$scale_arg"
    if ! awk -v s="$scale" 'BEGIN{exit !(s > 0)}'; then
        echo "Scale must be a positive number." >&2
        exit 1
    fi
    auto_scale=false
else
    echo "No scale provided, will auto-detect based on DPI matching." >&2
    auto_scale=true
fi

# Detect external display (any connected display that is not the primary)
connected_display_name=$(awk -v primary="$primary_display" '$2=="connected" && $1!=primary {print $1}' <<< "$xrandr_output" | head -n 1)

if [[ -z "$connected_display_name" ]]; then
    echo "No external connected display detected." >&2
    exit 1
fi

echo "Detected external display: $connected_display_name" >&2

get_highest_mode() {
    local display_name="$1"
    awk -v display="$display_name" '
        $1==display {
            in_display=1
            next
        }
        in_display && $0 !~ /^\s+/ {
            in_display=0
        }
        in_display {
            mode=$1
            gsub(/^\s+/, "", mode)
            if (mode ~ /^[0-9]+x[0-9]+$/) {
                split(mode, dims, "x")
                area=dims[1]*dims[2]
                if (area>max_area || (area==max_area && dims[1]>max_width)) {
                    max_area=area
                    max_width=dims[1]
                    best=mode
                }
            }
        }
        END {
            if (best!="") {
                print best
            }
        }
    ' <<< "$xrandr_output"
}

connected_mode=$(get_highest_mode "$connected_display_name")
if [[ -z "$connected_mode" ]]; then
    echo "Unable to determine a mode for $connected_display_name." >&2
    exit 1
fi

primary_mode=$(get_highest_mode "$primary_display")
if [[ -z "$primary_mode" ]]; then
    echo "Unable to determine a mode for $primary_display." >&2
    exit 1
fi

echo "Primary display mode: $primary_mode" >&2
echo "External display mode: $connected_mode" >&2

IFS='x' read -r connected_width connected_height <<< "$connected_mode"
IFS='x' read -r primary_width primary_height <<< "$primary_mode"

# If auto-scaling, calculate scale to match DPI of primary display
if [[ "$auto_scale" == "true" ]]; then
    # Extract physical dimensions of the connected display from xrandr output
    connected_physical=$(awk -v display="$connected_display_name" '
        $1==display && $2=="connected" {
            for (i=3; i<=NF; i++) {
                if ($i ~ /^[0-9]+mm$/ && $(i+2) ~ /^[0-9]+mm$/) {
                    w=$(i)
                    h=$(i+2)
                    gsub(/mm$/, "", w)
                    gsub(/mm$/, "", h)
                    printf "%s %s", w, h
                    exit
                }
            }
        }
    ' <<< "$xrandr_output")
    
    if [[ -z "$connected_physical" ]] || [[ "$primary_physical_width_mm" -eq 0 ]]; then
        echo "Warning: Unable to detect physical dimensions for DPI calculation, using default scale 1.0" >&2
        scale=1.0
    else
        read -r connected_physical_width_mm connected_physical_height_mm <<< "$connected_physical"
        
        echo "External display physical size: ${connected_physical_width_mm}mm x ${connected_physical_height_mm}mm" >&2
        
        # Calculate DPI for both displays and derive scale factor
        scale=$(awk -v pw="$primary_width" -v ph="$primary_height" \
                    -v pwmm="$primary_physical_width_mm" -v phmm="$primary_physical_height_mm" \
                    -v cw="$connected_width" -v ch="$connected_height" \
                    -v cwmm="$connected_physical_width_mm" -v chmm="$connected_physical_height_mm" 'BEGIN {
            primary_dpi = (pw / pwmm) * 25.4
            connected_dpi = (cw / cwmm) * 25.4
            scale = primary_dpi / connected_dpi
            printf "%.3f", scale
        }')
        # Adjust the scale using the scale_adjustment factor
        scale=$(awk -v s="$scale" -v adj="$scale_adjustment" 'BEGIN {printf "%.3f", s/adj}')
        
        echo "Primary DPI: $(awk -v pw="$primary_width" -v pwmm="$primary_physical_width_mm" 'BEGIN {printf "%.1f", (pw/pwmm)*25.4}')" >&2
        echo "Connected DPI: $(awk -v cw="$connected_width" -v cwmm="$connected_physical_width_mm" 'BEGIN {printf "%.1f", (cw/cwmm)*25.4}')" >&2
        echo "Calculated scale: $scale" >&2
    fi
fi

# Center the built-in display under the external monitor and stack it vertically.
# Calculate position based on alignment mode
pos_values=$(awk -v cw="$connected_width" -v ch="$connected_height" -v s="$scale" \
         -v pw="$primary_width" -v ph="$primary_height" -v ps="$primary_scale" \
         -v align="$alignment" 'BEGIN {
    connected_w = cw * s
    connected_h = ch * s
    primary_w = pw * ps
    
    # Calculate horizontal position based on alignment
    if (align == "left") {
        pos_x = 0
    } else if (align == "right") {
        pos_x = connected_w - primary_w
    } else {
        # center (default)
        pos_x = (connected_w - primary_w) / 2
    }
    
    pos_y = connected_h
    printf "%.0f %.0f", pos_x, pos_y
}')
read -r primary_pos_x primary_pos_y <<< "$pos_values"

command=(xrandr --output "$primary_display" --primary --mode "$primary_mode" \
         --pos "${primary_pos_x}x${primary_pos_y}" --rotate normal \
         --scale "${primary_scale}x${primary_scale}")

# Only turn off known external displays if they are defined
if [[ -v known_external_displays ]]; then
    for display_name in "${known_external_displays[@]}"; do
        if [[ "$display_name" != "$connected_display_name" ]]; then
            command+=(--output "$display_name" --off)
        fi
    done
fi

command+=(--output "$connected_display_name" --mode "$connected_mode" \
          --scale "${scale}x${scale}" --pos 0x0 --rotate normal)

# Get terminal width and create a line that spans it
term_width=$(tput cols 2>/dev/null || echo 80)
echo -e "\033[1;36m$(printf '━%.0s' $(seq 1 $term_width))\033[0m"
printf 'Executing: %s\n' "${command[*]}"
echo -e "\033[1;36m$(printf '━%.0s' $(seq 1 $term_width))\033[0m"

if "${command[@]}"; then
    echo "Display configuration applied successfully."
else
    echo -e "\033[1;33mWarning: xrandr command returned an error, but configuration may have been applied.\033[0m" >&2
    echo -e "\033[1;33mThis can happen if the settings were already active.\033[0m" >&2
fi

