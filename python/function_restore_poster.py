from plexapi.server import PlexServer
import os
import sys
from py_cfg import script_dir, echo_ts, PLEX_URL, PLEX_TOKEN, MOVIES_LIBRARY

# Check if the correct number of command-line arguments are provided
if len(sys.argv) != 2:
    echo_ts(f"Usage: python3 function_restore_poster.py 'imdb_id'")
    sys.exit(1)

# Command-line arguments
imdb_id = sys.argv[1]

# Connect to the Plex server
plex = PlexServer(PLEX_URL, PLEX_TOKEN)

# Find the movie in Plex by IMDb ID
movie = plex.library.section(MOVIES_LIBRARY).getGuid(f'imdb://{imdb_id}')

# Get original movie posters path
original_movie_posters_dir = os.path.join(script_dir, 'original_movie_posters')

# Check if the movie was found
if movie:
    # Check if the original poster exists in the 'original_movie_posters' folder
    original_poster_path = os.path.join(original_movie_posters_dir, f"{imdb_id}_poster.jpg")
    
    if os.path.exists(original_poster_path):

        # Unlock the poster
        movie.unlockPoster()

        # Upload the original poster to Plex
        try:
            upload_success = movie.uploadPoster(filepath=original_poster_path)
            
            if upload_success:
                echo_ts(f"[INFO] Original poster uploaded and restored.")
        
                # Remove the 'overlay_applied' label from the movie
                movie.removeLabel("overlay_applied")
        
                echo_ts(f"[INFO] Label 'overlay_applied' removed.")
        
                # Delete the local copy of the original poster
                os.remove(original_poster_path)
                echo_ts(f"[INFO] Local copy of the original poster deleted.")
        
            else:
                echo_ts(f"[ERROR] Failed to upload original poster to Plex.")
        except Exception as e:
            echo_ts(f"[ERROR] Exception during poster upload: {e}")
    else:
        echo_ts(f"[ERROR] Original poster not found at '{original_poster_path}'.")
else:
    echo_ts(f"[ERROR] Movie not found in your Plex library.")
