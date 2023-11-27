from plexapi.server import PlexServer
from requests.exceptions import RequestException
from py_cfg import echo_ts, PLEX_URL, PLEX_TOKEN, MOVIES_LIBRARY

# Function to check if the Plex server and movies library are valid
def check_plex_server():
    try:
        # Connect to Plex server
        plex_server = PlexServer(PLEX_URL, PLEX_TOKEN)
        
        # Replace 'Movies' with the name of your movies library
        movies_library = plex_server.library.section(MOVIES_LIBRARY)
        
        # Check if the movies library is valid
        if movies_library:
            # Do nothing if everything is valid
            pass
        else:
            echo_ts(f"[ERROR] Plex 'MOVIES_LIBRARY' not found.")
    
    except RequestException as e:
        echo_ts(f"[ERROR] Verify Plex API variables in config.cfg. ERROR: {e}")
    except Exception as e:
        echo_ts(f"[ERROR] Verify Plex API variables in config.cfg. ERROR: {e}")

# Run the function to check Plex server and movies library
check_plex_server()
