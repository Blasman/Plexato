#!/bin/bash

################################################################################
#                           PLEXATO OVERLAY CONTROL                            #
################################################################################

generate_movie_list() {
    echo ""
    echo "Getting latest movie filenames from Plex API. Please wait..."
    echo ""
    venv_start
    python3 "${python_dir}/function_get_movieinfo.py"
    venv_stop
}

# Function to process each line in the plex_movie_filenames.txt file.
process_movie_list() {
    echo ""
    echo "Processing Plex movie filenames... this may take some time as it's done in bash using 'awk' to ensure proper regex matching..."
    echo ""
    # Generate first-time plex_movie_filenames.txt if one does not exist.
    if ! [[ -f plex_movie_filenames.txt ]]; then generate_movie_list; fi
    # Remove old plex_processed_filenames.txt if it exists.
    if [[ -f plex_processed_filenames.txt ]]; then rm plex_processed_filenames.txt; fi
    # Create empty plex_processed_filenames.txt.
    touch plex_processed_filenames.txt
    while IFS=$'\t' read -r movie_filename imdb_id; do
        # Check the quality of the movie filename
        local quality_result=$(determine_movie_quality "$movie_filename")  # VERY slow due to 'awk'. Bash regex is not great.
        # Check if the quality result is not 'GOOD'. Create a .txt file of all movies where an overlay function is required.
        if [[ "$quality_result" != "GOOD" ]]; then
            echo -e "$quality_result\t$movie_filename\t$imdb_id" >> plex_processed_filenames.txt
        fi
    done < plex_movie_filenames.txt
}

determine_overlays_required() {
    echo ""
    echo "APPLIED (* == true) | OVERLAY | FILENAME"
    echo ""
    # Determine which overlays are required for each movie and whether or not an overlay is applied (determined by local poster availability).
    while IFS=$'\t' read -r quality_result movie_filename imdb_id ; do
        # Check if a local poster exists.
        local applied=" "
        # Get IMDb ID from the movie filename.
        if [[ -f "original_movie_posters/${imdb_id}_poster.jpg" ]]; then applied="*"; fi
        echo "$applied | $quality_result | $movie_filename"
    done < plex_processed_filenames.txt
    echo ""
}

apply_all_overlays() {
    if ! [[ -f plex_processed_filenames.txt ]]; then
        echo ""
        echo "Please [P]rocess movie list first."
        echo ""
        return
    fi
    echo ""
    echo "This action will apply overlays to ALL movies that do not currently already have one as determined by the last '[P]rocess movies'."
    echo "Type 'APPLY' to apply changes, or any other input to cancel."
    echo ""
    read user_input
    if [[ "$user_input" == "APPLY" ]]; then
        echo ""
        echo "Applying overlays..."
        echo ""
        venv_start
        while IFS=$'\t' read -r quality_result movie_filename imdb_id; do
            # If a local poster copy does not exist, then apply an overlay to the movie.
            if ! [[ -f "original_movie_posters/${imdb_id}_poster.jpg" ]]; then
                echo "Applying '$quality_result' to '$movie_filename'."
                python3 "${python_dir}/function_apply_overlay.py" "$imdb_id" "$quality_result"
              # sleep 0.5  # SLOW DOWN PROCESSING. THIS MAY OR MAY NOT BE REQUIRED.
            fi
        done < plex_processed_filenames.txt
        venv_stop
        echo ""
        echo "Overlays applied to matching movies."
        echo ""
    else
        echo ""
        echo "Aborted."
        echo ""
    fi
}

remove_all_overlays() {
    echo ""
    echo "This action will remove overlays from ALL movies that currently have one."
    echo "Type 'RESTORE' to apply changes, or any other input to cancel."
    echo ""
    read user_input
    if [[ "$user_input" == "RESTORE" ]]; then
        generate_movie_list
        process_movie_list
        echo ""
        echo "Removing overlays and restoring original poster art..."
        echo ""
        venv_start
        while IFS=$'\t' read -r quality_result movie_filename imdb_id; do
            # If a local poster copy does exist, then restore original poster art.
            if [[ -f "original_movie_posters/${imdb_id}_poster.jpg" ]]; then
                echo "Removing '$quality_result' from '$movie_filename'."
                python3 "${python_dir}/function_restore_poster.py" "$imdb_id"
              # sleep 0.5  # SLOW DOWN PROCESSING. THIS MAY OR MAY NOT BE REQUIRED.
            fi
        done < plex_processed_filenames.txt
        venv_stop
        echo ""
        echo "Original poster art restored to all movies."
        echo ""
    else
        echo ""
        echo "Aborted."
        echo ""
    fi
}

################################################################################
#                              BEGIN PROCESSING                                #
################################################################################

# Source plexato.sh for required variables and functions.
if ! source plexato.sh overlay-control; then
    echo "[ERROR] Could not find/source 'plexato.sh'. Exiting."
    exit 1
fi

while true; do
    # Give user options.
    echo ""
    echo "*** PLEXATO OVERLAY CONTROL ***"
    echo ""
    echo "[G]enerate FRESH UPDATED list of movie filenames. Do this first. Info is saved to 'plex_movie_filenames.txt'."
    echo "[P]rocess list from [G] and list the overlays that are/can be matched to each movie (dry run). Info is saved to 'plex_processed_filenames.txt'."
    echo "[A]pply overlays to movies listed in [P] that do not already have an overlay applied."
    echo "[R]emove overlays/Restore original posters for all movies."
    echo "[E]xit."
    echo ""

    # Prompt the user for their choice.
    read -rp "Enter your choice: " user_choice

    # Use a case statement to handle the user's choice.
    case "$user_choice" in
      [Gg])
        generate_movie_list
        ;;
      [Pp])
        process_movie_list
        determine_overlays_required
        ;;
      [Aa])
        apply_all_overlays
        ;;
      [Rr])
        remove_all_overlays
        ;;
      [Ee])
        exit 0
        ;;
      *)
        echo "Invalid choice."
        ;;
    esac

    # Add a "Press Enter to continue..." message.
    echo ""
    read -rp "Press Enter to continue..."
    echo ""
done
