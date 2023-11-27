# Plexato
Plexato (short for "**PLEX A**u**T**omatic **O**verlays") automatically applies, changes, and/or removes overlays to/from movie posters when movies are imported into [Plex](https://github.com/plexinc) from [Radarr](https://github.com/Radarr/Radarr). Plexato was primarily designed for use with "low quality" overlays in mind (CAM) but can also work with any custom overlays (4K, etc). The default [config.cfg](config.cfg) is already setup for CAM and HCS (hardcoded subtitles) overlays.

<details>
  <summary>EXAMPLE MOVIE POSTER (click to expand)</summary>
  
  <img src="https://i.postimg.cc/jd97GSKt/plexato-cam-example-02.png" alt="plexato-cam-example-02.png" style="pointer-events:none;">
</details>

Why? CAM overlays provide useful information for users of your Plex server, as they now know before they hit play that the movie is in a much lower quality than usual. In addition, to solve the issue of users not noticing when a movie has been upgraded to "GOOD" quality (upon overlay _removal_), the "addedAt" value of the movie can optionally be reset to the current time. This means that Plex will put the movie back to the front of Plex's or any "recently added movies" collection so that your users can actually notice that the movie has been upgraded to full quality. 

## How It Works
Plexato should work in any environment that can run bash and python scripts. Plexato is a lightweight bash script that runs an inotify process to monitor a specified shared directory for small "info files" created by Radarr (no webhook servers are used/required). Plexato will run python functions only when required (optionally source a VENV as well). If using Unraid, it can be conveniently ran as a 'User-Script' (by sourcing it).

Plexato works by regex matching the filename of the movie that has just been imported into Plex from Radarr, as well as the filename of the movie (if any) that it has replaced. Various actions (if any) are then taken.

Example 1: NEW movie. No regex match is found, so no overlay is needed.

<details>
  <summary>LOG FILE (click to expand)</summary>
    
```
[2023_11_12 00:22:52.228] [PROCESSING MOVIE] 'A Fake Movie (2023) 1080p BluRay-LAMA {imdb-tt29079593}.mp4'
[2023_11_12 00:22:52.274] [PROCESSING COMPLETE] NEW movie in 'GOOD' quality. No actions required.
```
</details>


Example 2: NEW movie. Regex match is found, so overlay is applied.

<details>
  <summary>LOG FILE (click to expand)</summary>
    
```
[2023_11_21 14:16:18.756] [PROCESSING MOVIE] 'A.Fake.Movie.2023.1080p.CAM.x265-ACEM {imdb-tt1136617}.mkv'
[2023_11_21 14:16:18.764] [INFO] NEW movie in 'CAM' quality. Overlay change required. Applying overlays. Waiting for Plex...
[2023_11_21 14:16:30.361] [INFO] Uploaded poster image from TMDB to Plex.
[2023_11_21 14:16:32.574] [INFO] 'CAM.png' overlay applied to the local copy of the original poster.
[2023_11_21 14:16:32.588] [INFO] Successfully uploaded and replaced the current poster in Plex.
[2023_11_21 14:16:34.251] [INFO] Poster and Label 'overlay_applied' applied and locked.
[2023_11_21 14:16:34.258] [INFO] Local copy of the modified poster deleted.
[2023_11_21 14:16:34.281] [PROCESSING COMPLETE]
```
</details>


Example 3: REPLACEMENT movie. Quality is the same as previous movie. No actions are required.

<details>
  <summary>LOG FILE (click to expand)</summary>
    
```
[2023_11_12 07:13:48.454] [PROCESSING MOVIE] 'A.Fake.Movie.2023.1080p.NF.WEB-DL.DDP5.1.H.264-ACEM {imdb-tt1136617}.mkv'
[2023_11_12 07:13:48.463] [PROCESSING COMPLETE] 'GOOD' replaced 'GOOD' quality. No actions required.
```
</details>


Example 4: REPLACEMENT movie. Previous filename was a 'CAM' overlay. New movie requires no overlay (because it's 'GOOD' quality). Therefor, overlay is removed and original poster is restored. Optionally, 'addedAt' value is reset to the current time.

<details>
  <summary>LOG FILE (click to expand)</summary>
    
```
[2023_11_12 10:39:01.617] [PROCESSING MOVIE] 'A.Fake.Movie.2023.1080p.WEB-DL.X264.Will1869 {imdb-tt10676048}.mp4'
[2023_11_12 10:39:01.626] [INFO] 'GOOD' replaced 'CAM' quality. Overlay removal required. Restoring original poster.
[2023_11_12 10:39:02.600] [INFO] Original poster uploaded and restored.
[2023_11_12 10:39:03.233] [INFO] Label 'overlay_applied' removed.
[2023_11_12 10:39:03.235] [INFO] Local copy of the original poster deleted.
[2023_11_12 10:39:05.062] [INFO] 'addedAt' value has been modified to the current time.
[2023_11_12 10:39:05.082] [PROCESSING COMPLETE]
```
</details>


Example 5: REPLACEMENT movie. Previous filename was a 'CAM' overlay. New movie is a 'HCS' overlay. Therefor, overlay is changed from 'CAM' to 'HCS'.

<details>
  <summary>LOG FILE (click to expand)</summary>
    
```
[2023_11_12 13:06:03.700] [PROCESSING MOVIE] 'A.Fake.Movie.2023.1080p.HCS.X264.Will1869 {imdb-tt10676048}.mp4'
[2023_11_12 13:06:03.710] [INFO] 'HCS' replaced 'CAM' quality. Overlay change required. Applying new overlay.
[2023_11_12 13:06:05.078] [INFO] 'HCS.png' overlay applied to the local copy of the original poster.
[2023_11_12 13:06:05.112] [INFO] Successfully uploaded and replaced the current poster in Plex.
[2023_11_12 13:06:06.503] [INFO] Label 'overlay_applied' applied and locked.
[2023_11_12 13:06:06.512] [INFO] Local copy of the modified poster deleted.
[2023_11_12 13:06:06.535] [PROCESSING COMPLETE]
```
</details>


## Requirements
Plex needs to be using the default "Plex Movie" agent for your movies library so that Plexato can find the movies in Plex via their IMDb ID.

I have only tested this on Python 3.9.16 as that is what is included with the NerdTools plugin for Unraid. Therefor, that is the minimum version of python required. The three python packages required are: `requests` `plexapi` and `pillow`. Details in installation instructions below.

You will need to edit [config.cfg](config.cfg) with info such as your [Plex Server token](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/) and [TMDB API Key](https://www.themoviedb.org/settings/api). TMDB is only required to get a movie poster when adding **new** movies that *also* require an overlay (can optionally be used for **all** new movies instead). This is because [Plex is becomming less reliable with finding movie posters on it's own](https://forums.plex.tv/t/once-upon-a-time-in-the-west-metadata/852193). Using TMDB ensures that we get the most recent version of the movie poster and that we do not end up applying an overlay to a thumbnail of the movie instead.


## Installation
1. Create `plexato` appdata directory.

    Example command: `mkdir /mnt/user/appdata/plexato`
   
2. Copy/Download all Github files to the `plexato` directory.

    Example command: `git clone https://github.com/Blasman/Plexato.git /mnt/user/appdata/plexato`

3. Ensure that bash scripts are executable.

    Example command: `chmod +x /mnt/user/appdata/plexato/*.sh`

4. Edit `OUTPUT_DIR` variable in [radarr-to-plexato.sh](radarr-to-plexato.sh) to prefered directory *as seen by Radarr* that Radarr has write access to (ie a sub-folder in Radarr's appdata folder). Create that directory if it does not already exist. This needs to be a directory that Plexato can also read/write to.

5. Move [radarr-to-plexato.sh](radarr-to-plexato.sh) into your Radarr docker's 'appdata' directory (or anywhere that Radarr can access it).

6. "Install" [radarr-to-plexato.sh](radarr-to-plexato.sh) into Radarr as a "Custom Script" with `On Import` and `On Upgrade` selected.

<details>
  <summary>RADARR SCREENSHOT (click to expand)</summary>

  <img src="https://i.postimg.cc/Pf1YfdxT/plexato.jpg" alt="plexato.jpg" style="pointer-events:none;">

</details>

7. Optional: Create VENV environment for use with Plexato.

    Example command: `python3 -m venv /mnt/user/appdata/plexato/venv`

8. Install/update python packages. If using VENV, source VENV and install/update required python packages. If not using VENV, simply omit the `source` and `deactivate` lines.
Example:
```
source /mnt/user/appdata/plexato/venv/bin/activate
pip install requests
pip install plexapi
pip install pillow
deactivate
```

## Getting Started

Once the above install is complete, do the following:

1. Edit [config.cfg](config.cfg) in Plexato directory as required. The default overlay setup is for CAM and HCS overlays.

2. Run [overlay-control.sh](overlay-control.sh) to apply first time overlays. Ideally, you should never need to run this script again until you want to remove all overlays.

<details>
  <summary>FULL RUN OF 'overlay-control.sh' (click to expand)</summary>

    
1. Generate a fresh list of movie filenames from the Plex API.

```
*** PLEXATO OVERLAY CONTROL ***

[G]enerate FRESH UPDATED list of movie filenames. Do this first. Info is saved to 'plex_movie_filenames.txt'.
[P]rocess list from [G] and list the overlays that are/can be matched to each movie (dry run). Info is saved to 'plex_processed_filenames.txt'.
[A]pply overlays to movies listed in [P] that do not already have an overlay applied.
[R]emove overlays/Restore original posters for all movies.
[E]xit.

Enter your choice: g

Getting latest movie filenames from Plex API. Please wait...

Movie list has been updated at 'plex_movie_filenames.txt'.

Press Enter to continue...
```

2. Process the list of filenames to discover which overlays will match with which filenames and which movies already have an overlay. This also acts as a "dry run."

```
*** PLEXATO OVERLAY CONTROL ***

[G]enerate FRESH UPDATED list of movie filenames. Do this first. Info is saved to 'plex_movie_filenames.txt'.
[P]rocess list from [G] and list the overlays that are/can be matched to each movie (dry run). Info is saved to 'plex_processed_filenames.txt'.
[A]pply overlays to movies listed in [P] that do not already have an overlay applied.
[R]emove overlays/Restore original posters for all movies.
[E]xit.

Enter your choice: p

Processing Plex movie filenames... this may take some time...


APPLIED (* == true) | OVERLAY | FILENAME

  | HCS | A.Real.Awesome.Movie.2019.1080p.HC.HDRip.X264.AC3-EVO [imdb-tt2076298].mkv
  | CAM | Bananas.Are.Delicious.2023.1080p.Cam.X264.Will1869 {imdb-tt5537002}.mp4
  | CAM | The.Superhero.Adventures.2023.1080p.Cam.X264.Will1869 {imdb-tt10676048}.mp4
  | CAM | Taylor.Sings.A.Lot.2023.720p.V2.New.Audio.Cam.X264.Will1869 {imdb-tt28814949}.mp4


Press Enter to continue...
```

3. Apply overlays.

```
*** PLEXATO OVERLAY CONTROL ***

[G]enerate FRESH UPDATED list of movie filenames. Do this first. Info is saved to 'plex_movie_filenames.txt'.
[P]rocess list from [G] and list the overlays that are/can be matched to each movie (dry run). Info is saved to 'plex_processed_filenames.txt'.
[A]pply overlays to movies listed in [P] that do not already have an overlay applied.
[R]emove overlays/Restore original posters for all movies.
[E]xit.

Enter your choice: a

This action will apply overlays to ALL movies that do not currently already have one as determined by the last '[P]rocess movies'.
Type 'APPLY' to apply changes, or any other input to cancel.

APPLY

Applying overlays...

Applying 'HCS' to 'A.Real.Awesome.Movie.2019.1080p.HC.HDRip.X264.AC3-EVO [imdb-tt2076298].mkv'.
[2023_11_13 12:19:08.719] [INFO] Downloaded and saved the current movie poster from Plex.
[2023_11_13 12:19:09.056] [INFO] 'HCS.png' overlay applied to the local copy of the original poster.
[2023_11_13 12:19:09.073] [INFO] Successfully uploaded and replaced the current poster in Plex.
[2023_11_13 12:19:09.643] [INFO] Label 'overlay_applied' applied and locked.
[2023_11_13 12:19:09.648] [INFO] Local copy of the modified poster deleted.
Applying 'CAM' to 'Bananas.Are.Delicious.2023.1080p.Cam.X264.Will1869 {imdb-tt5537002}.mp4'.
[2023_11_13 12:19:10.469] [INFO] Downloaded and saved the current movie poster from Plex.
[2023_11_13 12:19:10.788] [INFO] 'CAM.png' overlay applied to the local copy of the original poster.
[2023_11_13 12:19:10.809] [INFO] Successfully uploaded and replaced the current poster in Plex.
[2023_11_13 12:19:12.035] [INFO] Label 'overlay_applied' applied and locked.
[2023_11_13 12:19:12.045] [INFO] Local copy of the modified poster deleted.
Applying 'CAM' to 'The.Superhero.Adventures.2023.1080p.Cam.X264.Will1869 {imdb-tt10676048}.mp4'.
[2023_11_13 12:19:12.922] [INFO] Downloaded and saved the current movie poster from Plex.
[2023_11_13 12:19:13.291] [INFO] 'CAM.png' overlay applied to the local copy of the original poster.
[2023_11_13 12:19:13.310] [INFO] Successfully uploaded and replaced the current poster in Plex.
[2023_11_13 12:19:14.128] [INFO] Label 'overlay_applied' applied and locked.
[2023_11_13 12:19:14.135] [INFO] Local copy of the modified poster deleted.
Applying 'CAM' to 'Taylor.Sings.A.Lot.2023.720p.V2.New.Audio.Cam.X264.Will1869 {imdb-tt28814949}.mp4'.
[2023_11_13 12:19:14.964] [INFO] Downloaded and saved the current movie poster from Plex.
[2023_11_13 12:19:15.253] [INFO] 'CAM.png' overlay applied to the local copy of the original poster.
[2023_11_13 12:19:15.267] [INFO] Successfully uploaded and replaced the current poster in Plex.
[2023_11_13 12:19:16.136] [INFO] Label 'overlay_applied' applied and locked.
[2023_11_13 12:19:16.145] [INFO] Local copy of the modified poster deleted.

Overlays applied to matching movies.


Press Enter to continue...

```

Removing overlays.

```
*** PLEXATO OVERLAY CONTROL ***

[G]enerate FRESH UPDATED list of movie filenames. Do this first. Info is saved to 'plex_movie_filenames.txt'.
[P]rocess list from [G] and list the overlays that are/can be matched to each movie (dry run). Info is saved to 'plex_processed_filenames.txt'.
[A]pply overlays to movies listed in [P] that do not already have an overlay applied.
[R]emove overlays/Restore original posters for all movies.
[E]xit.

Enter your choice: r

This action will remove overlays from ALL movies that currently have one.
Type 'RESTORE' to apply changes, or any other input to cancel.

RESTORE

Getting latest movie filenames from Plex API. Please wait...

Movie list has been updated at 'plex_movie_filenames.txt'.

Processing Plex movie filenames... this may take some time...


Removing overlays and restoring original poster art...

Removing 'HCS' from 'A.Real.Awesome.Movie.2019.1080p.HC.HDRip.X264.AC3-EVO [imdb-tt2076298].mkv'.
[2023_11_13 12:14:35.396] [INFO] Original poster uploaded and restored.
[2023_11_13 12:14:35.928] [INFO] Label 'overlay_applied' removed.
[2023_11_13 12:14:35.929] [INFO] Local copy of the original poster deleted.
Removing 'CAM' from 'Bananas.Are.Delicious.2023.1080p.Cam.X264.Will1869 {imdb-tt5537002}.mp4'.
[2023_11_13 12:14:36.765] [INFO] Original poster uploaded and restored.
[2023_11_13 12:14:37.223] [INFO] Label 'overlay_applied' removed.
[2023_11_13 12:14:37.224] [INFO] Local copy of the original poster deleted.
Removing 'CAM' from 'The.Superhero.Adventures.2023.1080p.Cam.X264.Will1869 {imdb-tt10676048}.mp4'.
[2023_11_13 12:14:38.048] [INFO] Original poster uploaded and restored.
[2023_11_13 12:14:38.511] [INFO] Label 'overlay_applied' removed.
[2023_11_13 12:14:38.512] [INFO] Local copy of the original poster deleted.
Removing 'CAM' from 'Taylor.Sings.A.Lot.2023.720p.V2.New.Audio.Cam.X264.Will1869 {imdb-tt28814949}.mp4'.
[2023_11_13 12:14:39.355] [INFO] Original poster uploaded and restored.
[2023_11_13 12:14:39.726] [INFO] Label 'overlay_applied' removed.
[2023_11_13 12:14:39.727] [INFO] Local copy of the original poster deleted.

Original poster art restored to all movies.


Press Enter to continue...
```
</details>

3. Run [plexato.sh](plexato.sh) to start the service and begin monitoring for new movies being imported from Radarr.

    ```
    [2023_11_15 07:47:20.549] Starting Plexato...
    [2023_11_15 07:47:24.052] [*STARTED*] Monitoring for newly imported movies. 
    ```

<details>
  <summary>UNRAID USER-SCRIPT (click to expand)</summary>
  
If using Unraid, you can create a script in the 'User-Scripts' plug-in to run "At Startup of Array" (and/or start it manually with "Run in Background") that simply sources the [plexato.sh](plexato.sh) file. Example Unraid User-Script:
```
#!/bin/bash
source "/mnt/user/appdata/plexato/plexato.sh"
```
</details>

## Overlay Config / Regex Matching

Overlays are meant to be simple. Only one overlay at a time is used per movie poster.

Regex matching the filenames of movies is currently the only way to match overlays with movies using Plexato.

Regex matching is **not** case sensitive. 

Example. Assume the default is used for 'CAM' overlays in [config.cfg](config.cfg):

`OVERLAY_CAM="CAM|HDCAM|HQCAM|TS|HDTS|TELESYNC|TC|HDTC|TELECINE"`

The part that comes after `OVERLAY_` in the variable name is the filename of the `.png` file for your custom overlay image located at `/overlays`. In this case, it would be `CAM.png` (case sensitive filename). Keep the filename **simple**. Stick to letters, numbers, and underscores (no spaces).

Then, assume that a movie was just imported into Plex from Radarr with the filename:

`A.Totally.Real.Movie.2023.1080p.V2.New.Audio.Cam.X264.Will1869 {imdb-tt28814949}.mp4`

When it comes time to search for a regex match, Plexato converts the filename to only match patterns after the year of the movie:

`1080p.V2.New.Audio.Cam.X264.Will1869 {imdb-tt28814949}.mp4`

In the above example there would be a positive match for 'CAM'.

Your custom overlay files go in `/overlays` and should be full poster size 1000x1500 .png's like the examples included. Plexato saves original movie posters to `/original_movie_posters` with the IMDb ID's as part the filename (ie `tt10676048_poster.jpg`). These local copies are used to restore the original poster art as well as change the overlays when needed.

## Background Info

Plexato was inspired by [Plex-Meta-Manager](https://github.com/meisnate12/Plex-Meta-Manager)'s overlay features. PMM is amazing for overlays (and more!), however, I felt that it was a bit "too much" for what I needed, and I wanted overlays to change immediately upon movie import without having to load and scan my entire library every time. Therefor, I started writing various scripts in Unraid to see what I could do about it while also keeping it as minimal as possible. Then, I figured with a few tweaks here and there that I could make the scripts sharable and give them a silly name, hence Plexato being an arguably weird mix of bash and python. The code itself still has a lot of room for improvement, and I may consider rewriting Plexato "properly" in python and/or use docker or something else at some point if I feel so inclined. For now though, as long as everything is fully functional, that's what matters most.

If you have any ideas, requests, and/or bug reports related to Plexato, please let me know.

## Legal Disclaimer

Plexato is a project developed for educational purposes. It is not intended to endorse, promote, or facilitate piracy or any unauthorized use of copyrighted content. Users are responsible for ensuring compliance with applicable laws and should only use this software in accordance with legal and ethical standards.
