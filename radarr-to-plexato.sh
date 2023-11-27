#!/bin/bash

##############################################################################
# Define the directory (AS RADARR SEES IT!) where you want Radarr to create the info files for Plexato to read from (no trailing backslash).
OUTPUT_DIR="/config/plexato-info"
##############################################################################

if [[ "$radarr_eventtype" == "Download" ]] && [[ -n $radarr_movie_imdbid ]]; then
    echo -e "${radarr_movie_imdbid}${radarr_deletedrelativepaths:+\n${radarr_deletedrelativepaths}}" > "${OUTPUT_DIR}/${radarr_moviefile_relativepath}.p"
fi
exit 0