from plexapi.server import PlexServer
from PIL import Image
import os
import sys
import requests
from py_cfg import script_dir, echo_ts, PLEX_URL, PLEX_TOKEN, MOVIES_LIBRARY 

# Check if the correct number of command-line arguments are provided
if len(sys.argv) != 3:
    print(f"Usage: python3 function_apply_overlay.py 'IMDb ID' 'overlay_filename'")
    sys.exit(1)

# Command-line arguments
imdb_id = sys.argv[1]
overlay_filename = sys.argv[2] + '.png'  # Append '.png' to the overlay filename

# Get overlay path
overlays_dir = os.path.join(script_dir, 'overlays')
overlay_image_path = os.path.join(overlays_dir, overlay_filename)

# Get original movie posters path
original_movie_posters_dir = os.path.join(script_dir, 'original_movie_posters')

# Connect to the Plex server
plex = PlexServer(PLEX_URL, PLEX_TOKEN)

# Find the movie in Plex by IMDb ID
movie = plex.library.section(MOVIES_LIBRARY).getGuid(f'imdb://{imdb_id}')

# Check if the movie was found
if movie:
    # Create a folder for original posters if it doesn't exist
    if not os.path.exists(original_movie_posters_dir):
        os.makedirs(original_movie_posters_dir)

    # Check if the original poster already exists
    original_poster_path = os.path.join(original_movie_posters_dir, f"{imdb_id}_poster.jpg")

    if not os.path.exists(original_poster_path):
        # Get the poster URL
        poster_url = movie.posterUrl

        # Download the poster image
        if poster_url:
            response = requests.get(poster_url)
        
            if response.status_code == 200:
                # Save the original poster with the original filename
                with open(original_poster_path, 'wb') as f:
                    f.write(response.content)
                echo_ts(f"[INFO] Downloaded and saved the current movie poster from Plex.")
            else:
              # sys.stderr.write(f"[ERROR] Failed to download original poster. Status code: {response.status_code}\n")
                echo_ts(f"[ERROR] Failed to download original poster. Status code: {response.status_code}")
                sys.exit(1)
        else:
          # sys.stderr.write(f"[ERROR] Poster URL not found.\n")
            echo_ts(f"[ERROR] Poster URL not found.")
            sys.exit(1)

    # Check again if the original poster now exists
    if os.path.exists(original_poster_path):
        if os.path.exists(overlay_image_path):
            overlay_image = Image.open(overlay_image_path)

            # Open the poster image (either downloaded or existing)
            poster_image = Image.open(original_poster_path)

            # Resize overlay image to fit the poster
            overlay_image = overlay_image.resize(poster_image.size)

            # Apply the overlay
            poster_image.paste(overlay_image, (0, 0), overlay_image)

            # Save the result as a new file
            modified_poster_path = os.path.join(original_movie_posters_dir, f"{imdb_id}_modified_poster.jpg")
            poster_image.save(modified_poster_path)
            echo_ts(f"[INFO] '{overlay_filename}' overlay applied to the local copy of the original poster.")

            # Upload the modified poster to Plex
            upload_success = movie.uploadPoster(filepath=modified_poster_path)

            if upload_success:
                echo_ts(f"[INFO] Successfully uploaded and replaced the current poster in Plex.")

                # Lock the poster
                movie.lockPoster()

                # Add the 'overlay_applied' label to the movie
                label_name = 'overlay_applied'
                movie.addLabel(label_name, locked=True)
                
                echo_ts(f"[INFO] Poster and Label '{label_name}' applied and locked.")
                
                # Close the images
                poster_image.close()
                overlay_image.close()
                
                # Delete the local copy of the modified poster
                os.remove(modified_poster_path)
                echo_ts(f"[INFO] Local copy of the modified poster deleted.")
            else:
                echo_ts(f"[ERROR] Failed to upload modified poster to Plex.")
        else:
            echo_ts(f"[ERROR] Overlay image not found at '{overlay_image_path}'.")
    else:
        echo_ts(f"[ERROR] Original poster not found at '{original_poster_path}'.")
else:
    echo_ts(f"[ERROR] Movie not found in Plex library.")
