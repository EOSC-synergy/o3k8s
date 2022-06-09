#!/bin/sh
###
# Shell script to download published data and dearchive
# One can provide publicly available list of files to download via O3AS_PUBLISHED_DATA_LIST
###

### some defaults
# default (remote) address of the o3as_publised_list
o3as_published_list_remote=https://git.scc.kit.edu/synergy.o3as/o3sources/-/raw/datarepo/o3as_published_data.txt
# local path
o3as_data_path=/data
o3as_published_list="${o3as_data_path}/o3as_published_data.txt"
###

# function to download data and dearchive it in the same directory
get_data()
{
  link=$1
  echo "[INFO] Link: ${link}"

  # generate random filename for downloading
  filename_tmp=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 16)

  # download data archive and deduce the original filename
  filename=$(wget --server-response -q -O ${filename_tmp} "${link}" 2>&1 \
  | grep -i "Content-Disposition:" \
  | awk -F"filename=" '{print $2}' \
  | cut -d ";" -f1 | tr -d "'" | tr -d '"')

  # rename downloaded archive correspondently
  mv ${filename_tmp} ${filename}

  # now dearchive, supported tar.gz and zip
  extension="${filename#*.}"
  # tar.gz
  if [ "${extension}" = "tar.gz" ]; then
    tar --overwrite -xvf $filename  # overwrite existing files
  fi
  
  # zip
  if [ "${extension}" = "zip" ]; then
    unzip -o $filename  # overwrite existing files
  fi
  
  if [ $? -eq 0 ]; then
    rm $filename
  else
    echo "[ERROR] Something went wrong, ${filename} is not deleted"
  fi
}

# one can define O3AS_PUBLISHED_LIST_REMOTE via Environment Variable
# if not defined => use default value provided above
if [ ${#O3AS_PUBLISHED_LIST_REMOTE} -le 1 ]; then
  O3AS_PUBLISHED_LIST_REMOTE=${o3as_published_list_remote}
fi

# check if local data directory exists, if not => create
if [ ! -d "${o3as_data_path}" ]; then
  mkdir -p "${o3as_data_path}"
fi

# change to o3as_data_path directory
cd ${o3as_data_path}

# Download $O3AS_PUBLISHED_LIST_REMOTE and store in $o3as_published_list
wget -O ${o3as_published_list} ${O3AS_PUBLISHED_LIST_REMOTE}

# https://stackoverflow.com/questions/8195950/reading-lines-in-a-file-and-avoiding-lines-with-with-bash
# allow comments started with '#'
grep -v '^#' ${o3as_published_list} | while read -r wl
do
  echo "[TEST] ${wl}"
  get_data "${wl}" || continue
done
