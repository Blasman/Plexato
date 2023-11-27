from plexapi.server import PlexServer
from datetime import datetime, timedelta
import time
import sys
from py_cfg import echo_ts, PLEX_URL, PLEX_TOKEN, MOVIES_LIBRARY

# Check if an IMDb ID is provided as a command-line argument
if len(sys.argv) != 2:
    print("Usage: python3 function_verify_movie_added_to_plex.py 'IMDb ID'")
    sys.exit(1)

# Retrieve IMDb ID from command-line argument
imdb_id = sys.argv[1]

# Connect to the Plex server
plex = PlexServer(PLEX_URL, PLEX_TOKEN)

# Initial sleep delay to give Plex time to import the movie.
time.sleep(3)  # Additional 10 second delay in plexato.sh after movie is verified.

# Set the maximum duration for trying to find the movie (in seconds)
max_duration = 30

# Get the current timestamp.
start_time = datetime.now()

movie = None
while (datetime.now() - start_time).seconds < max_duration:
    try:
        # Attempt to find the movie in Plex by IMDb ID
        movie = plex.library.section(MOVIES_LIBRARY).getGuid(f'imdb://{imdb_id}')
        # Break out of the loop if the movie is found
        if movie is not None: sys.exit(0)
    except Exception as e:
        # Handle any exceptions that may occur
        error_message = str(e)        
        if "is not found in the library" in error_message:
            time.sleep(3)
            continue
        else:
            echo_ts(f"[ERROR] {error_message}")
            sys.exit(1)

if movie is None:
    echo_ts(f"[ERROR] Could not find the movie on Plex. End of processing.")
