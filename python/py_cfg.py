import os, datetime

# Simple, consistent message timestamp with bash.
def echo_ts(message):
    current_time = datetime.datetime.now()
    timestamp = current_time.strftime("[%Y_%m_%d %H:%M:%S.%f")[:-3]
    print(f"{timestamp}] {message}")

# Function to read configuration from an external file.
def read_config_file(config_file_path):
    config = {}
    try:
        with open(config_file_path, "r") as config_file:
            for line in config_file:
                # Remove comments from the line
                line = line.split('#', 1)[0]
                # Split the line into key and value using "=" as the delimiter
                parts = line.strip().split("=")
                if len(parts) == 2:
                    key = parts[0].strip()
                    value = parts[1].strip()
                    
                    # Check if the value is enclosed in quotes and remove them
                    if value.startswith(("'", '"')) and value.endswith(("'", '"')):
                        value = value[1:-1]

                    config[key] = value
    except FileNotFoundError:
        pass
    
    return config

script_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
config = read_config_file(os.path.join(script_dir, "config.cfg"))

# Define the variables based on the loaded config.
PLEX_URL = config.get("PLEX_URL", "")
PLEX_TOKEN = config.get("PLEX_TOKEN", "")
MOVIES_LIBRARY = config.get("MOVIES_LIBRARY", "")
TMDB_APIKEY = config.get("TMDB_APIKEY", "")