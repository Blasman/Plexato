#!/bin/bash

################################################################################
#                                   PLEXATO                                    #
################################################################################

echo_ts() { printf "[%(%Y_%m_%d)T %(%H:%M:%S)T.${EPOCHREALTIME: -6:3}] $@\\n"; }  # use built-in bash functions for timestamps on log messages.

determine_movie_quality() {  # Regex version, doesn't work with bash: #  \b(PATTERN)\b(?!.*\b\d{4}\b)
    # Ensure that we only pattern match AFTER the LAST instance of YYYY in the filename.
    # Bash regex is seemingly incapable of the same ideal match. awk is much slower than regex, but should not matter much except for overlay-control.sh.
    local pattern_to_match_from_movie=$(echo "${1}" | awk -F'([^[:alnum:]]|^)[0-9]{4}([^[:alnum:]]|$)' '{print $NF}')
    shopt -s nocasematch
    for set_name in "${!QUALITY_PATTERNS[@]}"; do
        pattern="\\b(${QUALITY_PATTERNS["$set_name"]})\\b"
        if [[ $pattern_to_match_from_movie =~ $pattern ]]; then
            echo "$set_name"
            return
        fi
    done
    echo "GOOD"
}  

time_elapsed_since_last_pmm_write() { 
    local last_pmm_log_modification_time=$(stat -c %Y "$PMM_LOG_FILE")
    echo $(( $(date +%s) - last_pmm_log_modification_time ))
}

pmm_active_check() {
    local had_to_wait=false
    while true; do
        local elapsed_time=$(time_elapsed_since_last_pmm_write)
        # Check if the time elapsed since the last write is greater than or equal to PMM_WAIT_TIME seconds and then sleep for the time difference.
        if (( $elapsed_time < $PMM_WAIT_TIME )); then  
            if [[ $had_to_wait == false ]]; then echo_ts "[INFO] PMM Builder appears to be active. Waiting for it to finish..."; fi
            had_to_wait=true
            sleep $(($PMM_WAIT_TIME - elapsed_time))
        else
            break
        fi
    done
    if [[ $had_to_wait == true ]]; then echo_ts "[INFO] PMM Builder has finished. Continuing..."; fi
}

venv_start() { if [[ -n "$VENV_DIR" ]] && [[ -f "$VENV_DIR/bin/activate" ]]; then source "$VENV_DIR/bin/activate"; fi }
venv_stop() { if [[ -n "$VENV_DIR" ]] && [[ -f "$VENV_DIR/bin/activate" ]]; then deactivate; fi }

# Function to run python scripts.
python_function() {
    if [[ $PMM_USAGE == true ]]; then pmm_active_check; fi
    venv_start
    python3 "$python_dir/function_$1.py" "${@:2}"
    # to do: record if error message? has not been necessary yet as it is handled in script.
    venv_stop
    msg_python_ran=true  # So we can display progress complete message.
}

################################################################################
#                              BEGIN PROCESSING                                #
################################################################################

# Print script start message.
if [[ $1 == overlay-control ]]; then echo_ts "Starting Overlay-Control... please wait..."
else echo_ts "Starting Plexato... please wait..."; fi

# Source the configuration file.
config_file="$(dirname "${BASH_SOURCE[0]}")/config.cfg"  
if [ -f "$config_file" ]; then
    source "$config_file"
else
    echo_ts "[ERROR] Configuration file not found at '$config_file'"
    exit 1
fi

# Clean and verify DIR variables.
if [[ -n "$VENV_DIR" ]]; then dir_vars=("RADARR_OUTPUT_DIR" "VENV_DIR");
else dir_vars=("RADARR_OUTPUT_DIR"); fi
for dir in "${dir_vars[@]}"; do
    clean_dir="${!dir}"
    clean_dir="${clean_dir%/}"  # Remove trailing slashes.
    eval "$dir=\"$clean_dir\""  # Update the variable with the cleaned path.
    if [ ! -d "$clean_dir" ]; then
        echo_ts "[ERROR] $dir variable is not a valid path at '$clean_dir/'. Exiting."
        exit 1
    fi
done

# Verify that VENV environment exists if choosing to use one.
if [[ -n "$VENV_DIR" ]] && ! [[ -f "$VENV_DIR/bin/activate" ]]; then
    echo_ts "[ERROR] Virtual environment (VENV) not found at '$VENV_DIR/'. Exiting."
    exit 1
fi

# Verify log file directory exists if choosing to use a log file.
if [[ -n "$LOG_FILE" ]] && ! [[ -d $(dirname "$LOG_FILE") ]]; then
    echo_ts "[ERROR] Could not find log file directory at '$(dirname "$LOG_FILE")'."
    exit 1
fi

# Verify PMM log file exists if using PMM compatibility settings.
if [[ $PMM_USAGE == true ]] && ! [[ -f "$PMM_LOG_FILE" ]]; then
    echo_ts "[ERROR] Could not find PMM log file at '$PMM_LOG_FILE'."
    exit 1
fi

# Navigate to working script directory and set variables for directories.
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
python_dir="${script_dir}/python"

# Verify custom overlay files exist.
for var_name in $(compgen -v); do
    if [[ "$var_name" == "OVERLAY_"* ]]; then
        if ! [[ -f "$script_dir/overlays/${var_name#OVERLAY_}.png" ]]; then
            echo_ts "[ERROR] Could not find custom overlay file '${var_name#OVERLAY_}.png'."
            exit 1
        fi
    fi
done

# Verify that python scripts directory exists.
if ! [[ -d "$python_dir" ]]; then
    echo_ts "[ERROR] Could not find python scripts directory at '$python_dir'."
    exit 1
fi

venv_start

# Verify that python3 is installed.
if ! command -v python3 > /dev/null 2>&1; then
    echo_ts "[ERROR] Python3 is not installed."
    exit 1
fi

# Verify that we have the minimum version of python installed.
required_python_version="3.9.16"
installed_python_version=$(python --version 2>&1 | awk '{print $2}')
if ! [[ "$(printf '%s\n' "$required_python_version" "$installed_python_version" | sort -V | head -n 1)" == "$required_python_version" ]]; then
    echo_ts "[ERROR] Python version $required_python_version or newer is required."
    venv_stop
    exit 1
fi

# Verify that python packages are installed. Add version checks???
required_packages=("requests" "PlexAPI" "Pillow"); missing_packages=()
pip_list_output=$(pip list)
for package in "${required_packages[@]}"; do
    if ! echo "$pip_list_output" | grep -q "^$package "; then missing_packages+=("$package"); fi
done
if [ ${#missing_packages[@]} -gt 0 ]; then
    echo_ts "[ERROR] The following required python packages are not installed: ${missing_packages[*]}"
    venv_stop
    exit 1
fi

# Verify Plex API variables and python functionality at the same time.
plexapi_test=$(python3 "$python_dir/function_test_plexapi.py")
if [[ -n "$plexapi_test" ]]; then
    venv_stop
    echo "$plexapi_test"
    exit 1
fi

# Verify TMDB API Key.
tmdb_test=$(python3 "$python_dir/function_test_tmdb.py")
if [[ -n "$tmdb_test" ]]; then
    venv_stop
    echo "$tmdb_test"
    exit 1
fi

venv_stop

# Create the array to store the overlay patterns.
declare -A QUALITY_PATTERNS

# Generate the overlay arrays from the user-defined overlay variables.
for var_name in $(compgen -v); do
    if [[ "$var_name" == "OVERLAY_"* ]]; then
        overlay_pattern="${!var_name}"
        set_name="${var_name#OVERLAY_}"  # Extract set_name from variable name.
     #  set_name="${set_name//[^a-zA-Z0-9]/}"  # Remove any spaces or special characters from set_name.
        QUALITY_PATTERNS["$set_name"]=$overlay_pattern
    fi
done

# Check if script is being sourced by overlay-control.sh. If true, then end processing and keep script sourced in overlay-control.sh.
if [[ $1 == overlay-control ]]; then return; fi

# Enable console logging to file if set in config.cfg.
if [[ -n "$LOG_FILE" ]]; then
    echo_ts "[*STARTED*] Monitoring for newly imported movies. Redirecting console output to: '$LOG_FILE'."
    exec >> "$LOG_FILE"
fi

# Print monitoring started message to console or log file.
echo_ts "[*STARTED*] Monitoring for newly imported movies..."

# Create array to store processed files and their timestamps so that we do not accidentally process the same movie twice.
declare -A PROCESSED_FILES

while true; do

    # Begin monitoring the Radarr shared directory for new info files.
    inotifywait -q -e close_write,create --format "%e %f" -m "$RADARR_OUTPUT_DIR" | while read -r event filename; do

		# Check if we want to process the file event.
        if [[ $event == "CLOSE_WRITE,CLOSE" ]] && [[ $filename =~ .*\.p$ ]]; then

            # Clean up old entries in the PROCESSED_FILES array before we continue.
            file_process_start_time=$(date +%s)
            for processed_filename in "${!PROCESSED_FILES[@]}"; do
                processed_time="${PROCESSED_FILES[$filename]}"
                time_difference=$((file_process_start_time - processed_time))
                [[ "$time_difference" -ge 300 ]] && unset "PROCESSED_FILES[$processed_filename]"
            done

            # Prevent accidentally processing the same file multiple times. End processing if the file has been processed within the last five minutes.
            if [[ "${PROCESSED_FILES[$filename]}" ]]; then continue; fi

            # Store the current TIMESTAMP for the processed file.
            PROCESSED_FILES["$filename"]=$(date +%s)

            # Initialize variables.
            movie_filename=""; imdb_id=""; previous_filename=""; current_movie_quality=""; previous_movie_quality=""; msg_info=""

            # Give Radarr a second to write all the info to the info file as well as moderate the pace of processing in the event of a mass queue.
            sleep 0.5

            # Get filename of the new movie by removing the .p extension from the info file.
            movie_filename="${filename%.p}"

            # Get IMDb ID.
            imdb_id=$(head -n 1 "$RADARR_OUTPUT_DIR/$filename")

            # Check if the new movie is a replacement/upgrade for an existing movie and get the filename of the movie that has been replaced (if any).
            previous_filename=$(sed -n '2p' "$RADARR_OUTPUT_DIR/$filename")

            # Delete the plexato file.
            rm "$RADARR_OUTPUT_DIR/$filename"

            # Display begin processing message.
            echo_ts "[PROCESSING MOVIE] '$movie_filename'"

            # Get 'quality' of imported movie to determine if we need to apply an overlay or restore a poster.
            current_movie_quality=$(determine_movie_quality "$movie_filename")

            # Default assume that python is not ran. Used for PROCESSING COMPLETE message.
            msg_python_ran=false

            # If this is a NEW movie (not an upgrade/replacement), then process it here.
            if ! [[ "$previous_filename" ]]; then

                # Create message information that will be re-used multiple times.
                msg_info="NEW movie in '$current_movie_quality' quality."
                if [[ $ALWAYS_USE_TMDB == true ]] && [[ "$current_movie_quality" == "GOOD" ]]; then msg_info="$msg_info Replacing movie poster in Plex with fresh TMDB poster. Waiting for Plex..."
                elif [[ "$current_movie_quality" != "GOOD" ]]; then msg_info="$msg_info Overlay change required. Waiting for Plex..."; fi

                # Verify that movie is in Plex and replace current movie poster with a fresh TMDB movie poster if required.
                if [[ $ALWAYS_USE_TMDB == true ]] || [[ "$current_movie_quality" != "GOOD" ]]; then
                    in_plex=false
                    echo_ts "[INFO] $msg_info"
                    # Keep checking Plex for up to 30 seconds until the movie has been fully imported.
                    verify_movie_added_to_plex=$(python_function verify_movie_added_to_plex "$imdb_id")
                    if [ -n "$verify_movie_added_to_plex" ]; then echo "$verify_movie_added_to_plex"; else in_plex=true; fi
                    if [[ $in_plex == true ]]; then
                        sleep 10  # Give Plex more time to fetch movie info and download its own movie poster.
                        # Replace movie poster with a fresh TMDB poster.
                        python_function upload_tmdb_poster_to_plex "$imdb_id"
                    fi
                fi
                # If new movie requires an overlay, then apply overlay to the movie poster.
                if [[ $in_plex == true ]] && [[ "$current_movie_quality" != "GOOD" ]]; then
                    sleep 1  # added delay just in case.
                    python_function apply_overlay "$imdb_id" "$current_movie_quality"
                # If we do not need to run any python functions, then end processing.
                elif [[ $ALWAYS_USE_TMDB != true ]] && [[ "$current_movie_quality" == "GOOD" ]];
                    then echo_ts "[PROCESSING COMPLETE] $msg_info No actions required."
                fi
            # If this is an UPGRADE/REPLACEMENT for an existing movie, then process it here.
            else
                # Get quality of the previous movie.
                previous_movie_quality=$(determine_movie_quality "$previous_filename")

                # Create message information that will be re-used multiple times.
                msg_info="'$current_movie_quality' replaced '$previous_movie_quality' quality."

                # Compare the quality of the newer movie with the replaced movie. If they are different, then continue processing.
                if [[ "$previous_movie_quality" != "$current_movie_quality" ]]; then

                    # If newer movie is a full quality release, remove it's poster overlay and reset 'addedAt' time of the movie to the current time.
                    if [[ "$current_movie_quality" == "GOOD" ]]; then
                        echo_ts "[INFO] $msg_info Overlay removal required. Restoring original poster."
                        python_function restore_poster "$imdb_id"
                        if [[ $RESET_ADDEDAT == true ]]; then
                            sleep 1
                            python_function reset_addedat "$imdb_id"
                        fi
                    # If newer movie requires a different overlay than the current custom overlay that it is using, then apply the new overlay.    
                    else
                        echo_ts "[INFO] $msg_info Overlay change required. Appling new overlay."
                        python_function apply_overlay "$imdb_id" "$current_movie_quality"
                    fi
             	else
             	    echo_ts "[PROCESSING COMPLETE] $msg_info No actions required."
                fi
            fi
            if [[ $msg_python_ran == true ]]; then echo_ts "[PROCESSING COMPLETE]"; fi
        fi 
    done
done
