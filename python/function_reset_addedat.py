from plexapi.server import PlexServer
from datetime import datetime
import sys
from py_cfg import echo_ts, PLEX_URL, PLEX_TOKEN, MOVIES_LIBRARY

# Command-line arguments
imdb_id = sys.argv[1]

def update_added_at(imdb_id):
    plex = PlexServer(PLEX_URL, PLEX_TOKEN)
    movie = plex.library.section(MOVIES_LIBRARY).getGuid(f'imdb://{imdb_id}')

    if movie:
        try:
            movie.editAddedAt(datetime.now())
            echo_ts(f"[INFO] 'addedAt' value has been modified to the current time.")
        except Exception as e:
            echo_ts(f"[ERROR] Failed to edit 'addedAt' value: {e}")
    else:
        echo_ts(f"[ERROR] Could not find movie with IMDb ID {imdb_id}.")

if len(sys.argv) != 2:
    print("Usage: python3 function_reset_addedat.py 'IMDb ID'")
    sys.exit(1)

update_added_at(imdb_id)
