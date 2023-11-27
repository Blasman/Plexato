from plexapi.server import PlexServer
import os
from py_cfg import PLEX_URL, PLEX_TOKEN, MOVIES_LIBRARY

# Connect to your Plex server
plex = PlexServer(PLEX_URL, PLEX_TOKEN)

# Get the library section by name
library_section = plex.library.section(MOVIES_LIBRARY)

# Get all movies in the library
movies = library_section.search()

movie_details = []
for movie in movies:
    # Check if the movie's guids contain an IMDb ID
    for guid in movie.guids:
        if guid.id.startswith('imdb://'):
            # Use os.path.basename to extract the filename without path
            file_name = os.path.basename(movie.media[0].parts[0].file)
            imdb_id = guid.id.split('imdb://')[1]
            movie_details.append(f"{file_name}\t{imdb_id}")
            break

# Define the output file path
output_file_path = 'plex_movie_filenames.txt'

# Save the movie details to a file
with open(output_file_path, 'w', encoding='utf-8') as file:
    file.write('\n'.join(movie_details))

print(f"Movie list has been updated at 'plex_movie_filenames.txt'.")