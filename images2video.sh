#!/bin/bash
#
# Copyright 2016 Mario Ynocente Castro, Mathieu Bernard
#
# You can redistribute this file and/or modify it under the terms of
# the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

#
# Convert the png files in a directory into a mp4 video using avconv
#

# remove any trailing slash
data_dir=${1%/}

# display a usage message if bad params
[ -z "$data_dir" ] && echo "Usage: $0 directory" && exit 0

# display error message if input is not a directory
[ ! -d "$data_dir" ] && echo "Error: $data_dir is not a directory"  && exit 1

# display error message if avconv is not installed
[ -z $(which avconv) ] && echo "Error: avconv is not installed on your system"  && exit 1

# list all png images in the directory
png=$(ls $data_dir/*.png 2> /dev/null)

# display error message if no png in the directory
[ -z "$png" ] && echo "Error: no png file in $data_dir" && exit 1

# get the first png file in the luist
first=$(echo $png | cut -f1 -d' ')

# find the length of the images index (just consider the first png, we
# assume they all have same index length)
index=$(echo $first | sed -r 's|^.+_([0-9]+)\.png$|\1|g')
n=${#index}

# png files basename, with extension and index removed
base=$(basename $first | sed -r 's|^(.+_)[0-9]+\.png$|\1|g')

# the global pattern matching png files for avconv
pattern=$(echo $data_dir/$base%0${n}d.png)

# convert the png images into a video.avi
avconv -y -framerate 24 -i $pattern -c:v libx264 -r 30 -pix_fmt yuv420p $data_dir/video.avi \
       || (echo "Error: failed to write video from $pattern"; exit 1)

echo "Wrote $data_dir/video.avi"
exit 0