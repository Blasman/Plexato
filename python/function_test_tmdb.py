import requests
from py_cfg import echo_ts, TMDB_APIKEY

def verify_tmdb_api_key(TMDB_APIKEY):
    # TMDb API endpoint for testing API key validity
    url = f'https://api.themoviedb.org/3/configuration?api_key={TMDB_APIKEY}'

    try:
        # Make a request to TMDb API
        response = requests.get(url)
        response.raise_for_status()  # Raise an exception for HTTP errors

        # Check if the response contains the expected data
        if 'images' in response.json():
            pass
        else:
            echo_ts(f"[ERROR] TMDB API key appears to be invalid.")
    except requests.exceptions.RequestException as e:
        echo_ts(f"[ERROR] Could not make TMDB API request: {e}")

# Replace 'your_tmdb_api_key' with your actual TMDB API key
verify_tmdb_api_key(TMDB_APIKEY)
