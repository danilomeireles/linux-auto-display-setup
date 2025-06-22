#!/bin/bash

# Linux Auto Display Setup
# Supports all combinations of laptop + external monitors
# Handles laptop lid closed/open scenarios automatically
# More Information: https://github.com/danilomeireles/linux-auto-display-setup

# =============================================================================
# CONFIGURATION
# =============================================================================
PREFERRED_RESOLUTION="2560x1440"
FALLBACK_RESOLUTION="1920x1080"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/display-setup.log"

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    echo "[$level] $message" >&2  # Send to stderr to avoid interfering with function returns
}

log_info() {
    log_message "INFO" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

log_debug() {
    log_message "DEBUG" "$1"
}

log_separator() {
    echo "" >> "$LOG_FILE"
    echo "=================================================================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Initialize logging
init_logging() {
    log_separator
    log_info "Display Setup Script Started"
    log_info "Script Directory: $SCRIPT_DIR"
    log_info "Log File: $LOG_FILE"
}

# Get the best available resolution for a monitor
get_best_resolution() {
    local monitor="$1"
    local available_resolutions
    
    available_resolutions=$(xrandr --query | grep -A 20 "^$monitor connected" | grep -E '^\s+[0-9]+x[0-9]+' | awk '{print $1}')
    
    if echo "$available_resolutions" | grep -q "^$PREFERRED_RESOLUTION$"; then
        echo "$PREFERRED_RESOLUTION"
        log_debug "Using preferred resolution $PREFERRED_RESOLUTION for $monitor"
    elif echo "$available_resolutions" | grep -q "^$FALLBACK_RESOLUTION$"; then
        echo "$FALLBACK_RESOLUTION"
        log_debug "Using fallback resolution $FALLBACK_RESOLUTION for $monitor"
    else
        echo "auto"
        log_debug "Using auto resolution for $monitor"
    fi
}

# Get resolution width for positioning calculations
get_resolution_width() {
    local resolution="$1"
    local width
    
    if [ "$resolution" = "auto" ]; then
        width="1920"  # Default width assumption
    else
        # Extract width from resolution string and ensure it's numeric
        width="${resolution%x*}"  # Extract everything before 'x'
        
        # Validate that width is numeric
        if ! [[ "$width" =~ ^[0-9]+$ ]]; then
            log_error "Invalid width extracted from resolution '$resolution': '$width'"
            width="1920"  # Fallback to default
        fi
    fi
    
    log_debug "Resolution '$resolution' -> width: $width"
    echo "$width"
}

# Check if laptop lid is closed (best effort detection)
is_laptop_lid_closed() {
    # Method 1: Check /proc/acpi/button/lid (if available)
    if [ -d "/proc/acpi/button/lid" ]; then
        for lid_dir in /proc/acpi/button/lid/*/; do
            if [ -f "${lid_dir}state" ]; then
                local lid_state=$(cat "${lid_dir}state" 2>/dev/null | awk '{print $2}')
                if [ "$lid_state" = "closed" ]; then
                    log_debug "Laptop lid detected as closed via /proc/acpi"
                    return 0
                fi
            fi
        done
    fi
    
    # Method 2: Check if laptop display is physically disconnected/disabled
    # This is not perfect but gives us a hint
    local laptop_status=$(xrandr --query | grep "^eDP-1" | grep -o "connected\|disconnected")
    if [ "$laptop_status" = "disconnected" ]; then
        log_debug "Laptop display appears disconnected (possible lid closed)"
        return 0
    fi
    
    # Default: assume lid is open
    log_debug "Laptop lid assumed to be open"
    return 1
}

# Get display information
get_display_info() {
    # Find laptop display - try multiple common names
    laptop_display=""
    for display_name in "eDP-1" "LVDS-1" "LVDS1" "eDP1"; do
        if xrandr --query | grep -q "^$display_name connected"; then
            laptop_display="$display_name"
            break
        fi
    done
    
    # Find external displays - exclude laptop display
    external_displays=$(xrandr --query | grep " connected" | grep -v "^$laptop_display " | awk '{print $1}')
    external_count=$(echo "$external_displays" | grep -v '^$' | wc -l)
    
    log_info "Display Detection Results:"
    log_info "  Laptop Display: ${laptop_display:-'Not Found'}"
    log_info "  External Displays: ${external_displays:-'None'}"
    log_info "  External Display Count: $external_count"
    
    # Debug: Show all connected displays
    log_debug "All connected displays:"
    xrandr --query | grep " connected" | while read line; do
        log_debug "    $line"
    done
    
    # Check if laptop display is available
    laptop_available=false
    if [ -n "$laptop_display" ]; then
        laptop_available=true
        log_info "  Laptop Display Available: Yes"
    else
        log_info "  Laptop Display Available: No"
    fi
}

# Determine the desired configuration based on available displays and lid status
determine_configuration() {
    local use_laptop_display=false
    
    # Decide whether to use laptop display
    if [ "$laptop_available" = true ]; then
        if is_laptop_lid_closed; then
            use_laptop_display=false
            log_info "Configuration Decision: Laptop lid closed - using external displays only"
        else
            use_laptop_display=true
            log_info "Configuration Decision: Laptop lid open - including laptop display"
        fi
    else
        use_laptop_display=false
        log_info "Configuration Decision: Laptop display not available"
    fi
    
    # Determine scenario
    if [ "$use_laptop_display" = true ] && [ "$external_count" -eq 0 ]; then
        scenario="laptop_only"
        log_info "Selected Scenario: 1 - Laptop display only"
    elif [ "$use_laptop_display" = true ] && [ "$external_count" -eq 1 ]; then
        scenario="laptop_plus_1_external"
        log_info "Selected Scenario: 2 - Laptop + 1 external monitor"
    elif [ "$use_laptop_display" = true ] && [ "$external_count" -eq 2 ]; then
        scenario="laptop_plus_2_external"
        log_info "Selected Scenario: 3 - Laptop + 2 external monitors"
    elif [ "$use_laptop_display" = true ] && [ "$external_count" -eq 3 ]; then
        scenario="laptop_plus_3_external"
        log_info "Selected Scenario: 4 - Laptop + 3 external monitors"
    elif [ "$use_laptop_display" = false ] && [ "$external_count" -eq 1 ]; then
        scenario="1_external_only"
        log_info "Selected Scenario: 5 - 1 external monitor only (lid closed)"
    elif [ "$use_laptop_display" = false ] && [ "$external_count" -eq 2 ]; then
        scenario="2_external_only"
        log_info "Selected Scenario: 6 - 2 external monitors only (lid closed)"
    elif [ "$use_laptop_display" = false ] && [ "$external_count" -eq 3 ]; then
        scenario="3_external_only"
        log_info "Selected Scenario: 7 - 3 external monitors only (lid closed)"
    else
        scenario="fallback"
        log_info "Selected Scenario: Fallback - Unsupported configuration ($external_count external, laptop available: $laptop_available)"
    fi
}

# Execute xrandr command with error handling
execute_xrandr() {
    local cmd="$1"
    log_info "Executing xrandr command: $cmd"
    
    if eval "$cmd" 2>&1 | tee -a "$LOG_FILE" >&2; then
        log_info "xrandr command executed successfully"
        return 0
    else
        log_error "xrandr command failed"
        return 1
    fi
}

# Configure displays based on determined scenario
configure_displays() {
    local xrandr_cmd=""
    local notification_msg=""
    
    case "$scenario" in
        "laptop_only")
            xrandr_cmd="xrandr --output $laptop_display --primary --auto --pos 0x0 --rotate normal --scale 1x1"
            # Turn off external displays
            for ext_display in $external_displays; do
                xrandr_cmd="$xrandr_cmd --output $ext_display --off"
            done
            notification_msg="Laptop display only"
            ;;
            
        "laptop_plus_1_external")
            local ext_display=$(echo "$external_displays" | head -n1)
            local ext_resolution=$(get_best_resolution "$ext_display")
            local ext_width=$(get_resolution_width "$ext_resolution")
            
            if [ "$ext_resolution" = "auto" ]; then
                xrandr_cmd="xrandr --output $ext_display --primary --auto --pos 0x0 --rotate normal --scale 1x1 --output $laptop_display --auto --pos ${ext_width}x0 --rotate normal --scale 1x1"
            else
                xrandr_cmd="xrandr --output $ext_display --primary --mode $ext_resolution --pos 0x0 --rotate normal --scale 1x1 --output $laptop_display --auto --pos ${ext_width}x0 --rotate normal --scale 1x1"
            fi
            notification_msg="External monitor + laptop display"
            ;;
            
        "laptop_plus_2_external"|"laptop_plus_3_external")
            local display_array=($external_displays)
            local current_x_pos=0
            
            xrandr_cmd="xrandr"
            
            # Configure external monitors first
            for i in "${!display_array[@]}"; do
                local monitor="${display_array[$i]}"
                local resolution=$(get_best_resolution "$monitor")
                local width=$(get_resolution_width "$resolution")
                
                log_debug "Configuring monitor $monitor at position $current_x_pos with resolution $resolution (width: $width)"
                
                if [ $i -eq 0 ]; then
                    # First external monitor is primary
                    if [ "$resolution" = "auto" ]; then
                        xrandr_cmd="$xrandr_cmd --output $monitor --primary --auto --pos ${current_x_pos}x0 --rotate normal --scale 1x1"
                    else
                        xrandr_cmd="$xrandr_cmd --output $monitor --primary --mode $resolution --pos ${current_x_pos}x0 --rotate normal --scale 1x1"
                    fi
                else
                    if [ "$resolution" = "auto" ]; then
                        xrandr_cmd="$xrandr_cmd --output $monitor --auto --pos ${current_x_pos}x0 --rotate normal --scale 1x1"
                    else
                        xrandr_cmd="$xrandr_cmd --output $monitor --mode $resolution --pos ${current_x_pos}x0 --rotate normal --scale 1x1"
                    fi
                fi
                # Ensure width is treated as a number for arithmetic
                current_x_pos=$((current_x_pos + width))
            done
            
            # Add laptop display at the end
            xrandr_cmd="$xrandr_cmd --output $laptop_display --auto --pos ${current_x_pos}x0 --rotate normal --scale 1x1"
            
            notification_msg="$external_count external monitors + laptop display"
            ;;
            
        "1_external_only")
            local ext_display=$(echo "$external_displays" | head -n1)
            local ext_resolution=$(get_best_resolution "$ext_display")
            
            if [ "$ext_resolution" = "auto" ]; then
                xrandr_cmd="xrandr --output $ext_display --primary --auto --pos 0x0 --rotate normal --scale 1x1"
            else
                xrandr_cmd="xrandr --output $ext_display --primary --mode $ext_resolution --pos 0x0 --rotate normal --scale 1x1"
            fi
            
            # Turn off laptop display if it exists
            if [ -n "$laptop_display" ]; then
                xrandr_cmd="$xrandr_cmd --output $laptop_display --off"
            fi
            
            notification_msg="Single external monitor (laptop OFF)"
            ;;
            
        "2_external_only"|"3_external_only")
            local display_array=($external_displays)
            local current_x_pos=0
            
            xrandr_cmd="xrandr"
            
            # Turn off laptop display first if it exists
            if [ -n "$laptop_display" ]; then
                xrandr_cmd="$xrandr_cmd --output $laptop_display --off"
            fi
            
            # Configure external monitors
            for i in "${!display_array[@]}"; do
                local monitor="${display_array[$i]}"
                local resolution=$(get_best_resolution "$monitor")
                local width=$(get_resolution_width "$resolution")
                
                log_debug "Configuring monitor $monitor at position $current_x_pos with resolution $resolution (width: $width)"
                
                if [ $i -eq 0 ]; then
                    # First monitor is primary
                    if [ "$resolution" = "auto" ]; then
                        xrandr_cmd="$xrandr_cmd --output $monitor --primary --auto --pos ${current_x_pos}x0 --rotate normal --scale 1x1"
                    else
                        xrandr_cmd="$xrandr_cmd --output $monitor --primary --mode $resolution --pos ${current_x_pos}x0 --rotate normal --scale 1x1"
                    fi
                else
                    if [ "$resolution" = "auto" ]; then
                        xrandr_cmd="$xrandr_cmd --output $monitor --auto --pos ${current_x_pos}x0 --rotate normal --scale 1x1"
                    else
                        xrandr_cmd="$xrandr_cmd --output $monitor --mode $resolution --pos ${current_x_pos}x0 --rotate normal --scale 1x1"
                    fi
                fi
                # Ensure width is treated as a number for arithmetic
                current_x_pos=$((current_x_pos + width))
            done
            
            notification_msg="$external_count external monitors (laptop OFF)"
            ;;
            
        "fallback")
            log_error "Unsupported display configuration - falling back to laptop display"
            if [ "$laptop_available" = true ]; then
                xrandr_cmd="xrandr --output $laptop_display --primary --auto --pos 0x0 --rotate normal --scale 1x1"
                for ext_display in $external_displays; do
                    xrandr_cmd="$xrandr_cmd --output $ext_display --off"
                done
                notification_msg="Fallback: Laptop display only"
            else
                log_error "No laptop display available and unsupported external configuration"
                return 1
            fi
            ;;
    esac
    
    # Turn off any disconnected displays
    for output in $(xrandr --query | awk '/disconnected/ {print $1}'); do
        xrandr_cmd="$xrandr_cmd --output $output --off"
    done
    
    # Execute the configuration
    if execute_xrandr "$xrandr_cmd"; then
        log_info "Display configuration successful: $notification_msg"
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "Display Setup" "$notification_msg" -i video-display 2>/dev/null || true
        fi
        return 0
    else
        log_error "Display configuration failed"
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "Display Setup" "Configuration failed - check logs" -i dialog-error 2>/dev/null || true
        fi
        return 1
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main() {
    # Initialize logging
    init_logging
    
    # Trap errors
    set -e
    trap 'log_error "Script failed at line $LINENO"' ERR
    
    # Get display information
    get_display_info
    
    # Determine configuration
    determine_configuration
    
    # Configure displays
    if configure_displays; then
        log_info "Display setup completed successfully"
        exit 0
    else
        log_error "Display setup failed"
        exit 1
    fi
}

# Run main function
main "$@"