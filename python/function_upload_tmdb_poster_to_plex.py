import sys
import requests
from plexapi.server import PlexServer
from py_cfg import echo_ts, PLEX_URL, PLEX_TOKEN, MOVIES_LIBRARY, TMDB_APIKEY

# Check if an IMDb ID is provided as a command-line argument
if len(sys.argv) != 2:
    print("Usage: python3 function_upload_tmdb_poster_to_plex.py 'IMDb ID'")
    sys.exit(1)

# Retrieve IMDb ID from command-line argument
imdb_id = sys.argv[1]

# Construct the URL for searching by IMDb ID
search_url = f'https://api.themoviedb.org/3/movie/{imdb_id}?api_key={TMDB_APIKEY}'

try:
    response = requests.get(search_url)
    response.raise_for_status()  # Raise an HTTPError for bad responses
    data = response.json()
    
    if 'poster_path' in data:
        # Construct the poster image URL
        poster_url = 'https://image.tmdb.org/t/p/original' + data['poster_path']

except requests.RequestException as e:
  # echo_ts(f"[ERROR] Could not connect to TMDB. {e}")
    sys.stderr.write(f"[ERROR] {str(e)}\n")
    sys.exit(1)

# Connect to the Plex server
plex = PlexServer(PLEX_URL, PLEX_TOKEN)

# Find the movie in Plex by IMDb ID
try:
    movie = plex.library.section(MOVIES_LIBRARY).getGuid(f'imdb://{imdb_id}')
    if not movie:
        raise ValueError("Movie not found in Plex library.")
except Exception as e:
  # echo_ts(f"[ERROR] {e}")
    sys.stderr.write(f"[ERROR] {str(e)}\n")
    sys.exit(1)

# Upload the TMDB movie poster to Plex
try:
    upload_success = movie.uploadPoster(url=poster_url)
    if upload_success:
        pass
        echo_ts(f"[INFO] Uploaded poster image from TMDB to Plex.")
      # sys.stdout.write(f"[INFO] Uploaded poster image from TMDB to Plex.\n")
    else:
        raise ValueError("Failed to upload TMDB poster to Plex.")
except Exception as e:
  # echo_ts(f"[ERROR] {e}")
    sys.stderr.write(f"[ERROR] {str(e)}\n")
    sys.exit(1)
