#! /bin/bash

[ $# -eq 0 ] && echo "This script expects argument <gamelist> + optional argument <nfo folder>"$'\n'\
$'\n'\
"1) Provide the gamelist.xml to be used"$'\n'\
"NOTE. If gamelist is not in the same folder where this script is launched"$'\n'\
"provide the full location: /full/location/gamelist.xml"$'\n'\
$'\n'\
"2) The second optional argument is the location where the nfo files will be saved"$'\n'\
"if not specified the script will save the nfo files where the roms are"$'\n'\
 && exit 1;

# gamelist passed as argument to this script
[ ! -z "$1" ] && gameList="$1";

# Skyscraper standard output fields, initialise them as empty arrays
declare -a path;
declare -a name;
declare -a thumbnail;
declare -a image;
declare -a marquee;
declare -a video;
declare -a rating;
declare -a desc;
declare -a releasedate;
declare -a developer;
declare -a publisher;
declare -a genre;
declare -a players;
declare -a kidgame;

# based on https://stackoverflow.com/questions/893585/how-to-parse-xml-in-bash
# let's define a function that will parse the xml file and 
# assign ENTITY and CONTENT to anything between > and <
# i.e. in <tag>value</tag> --> ENTITY=tag and CONTENT=value
read_dom () {
    local IFS=\>
    read -d \< ENTITY CONTENT
}


while read_dom; do
    case "$ENTITY" in
        "path")         path+=("$CONTENT") ;;
        "name")         name+=("$CONTENT") ;;
        "thumbnail")    thumbnail+=("$CONTENT") ;;
        "image")        image+=("$CONTENT") ;;
        "marquee")      marquee+=("$CONTENT") ;;
        "video")        video+=("$CONTENT") ;;
        "rating")       rating+=("$CONTENT") ;;
        "desc")         desc+=("$CONTENT") ;;
        "releasedate")  releasedate+=("$CONTENT") ;;
        "developer")    developer+=("$CONTENT") ;;
        "publisher")    publisher+=("$CONTENT") ;;
        "genre")        genre+=("$CONTENT") ;;
        "players")      players+=("$CONTENT") ;;
        "kidsgame")     kidsgame+=("$CONTENT") ;;
    esac
done < $gameList

# nfo folder can be passed as argument to this script
nfoDir="$2";
# if nfo folder does not exit, generate it
[ ! -d "$nfoDir" ] && mkdir -p "$nfoDir";
# if not specified then the script will try to get it from the path in the gamelist
[ -z "$2" ] && echo "nfo location not specified, use the same of roms" && nfoDir=$(dirname "${path[0]}");



gameQty=${#path[@]};
echo "processed gamelist contains: ""$gameQty"" game(s)"

# change from full release date (in the original xml) to only year (as in the .nfo file)
declare -a year;
for (( i=0 ; i<=($gameQty-1) ; i++ )); do
    temp=${releasedate[$i]};
    year+=(${temp:0:4});
done

# convert ratings from % to 0 to 10 scale
declare -a convertedRating;
for (( i=0 ; i<=($gameQty-1) ; i++ )); do
    tempString="${rating[$i]}";
    tempValue="${tempString#*.}";
    firstDigit="${tempValue:0:1}";
    secondDigit="${tempValue:1:1}";
    [ -z "$secondDigit" ] && secondDigit="0";
    fsafa="$firstDigit"."$secondDigit";
    convertedRating+=("$fsafa");
done

# this is currently using the structure of the dr_mario.nfo example, can be suited to what is needed
# https://github.com/chrisism/plugin.program.akl/blob/master/tests/assets/dr_mario.nfo
# i kept the field which are available in gamelist but not used: developer, players, kidsgame

# implement some checks not to overwrite existing files
# if "${name[$i]}".nfo already exists (2 game with the same name) don't overwrite them

# maybe get the platform from the folder location i.e. atari2600/roms --> platform = atari2600


for (( i=0 ; i<=($gameQty-1) ; i++ )); do
    echo "game"$(($i+1))": "${name[$i]}" generating nfo file";
    echo "<?xml version="'"1.0"'" encoding="'"utf-8"'" standalone="'"yes"?>' $'\n'\
'<game>' $'\n'\
  '<title>'"${name[$i]}"'</title>' $'\n'\
  '<year>'"${year[$i]}"'</year>' $'\n'\
  '<genre>'"${genre[$i]}"'</genre>' $'\n'\
  '<publisher>'"${publisher[$i]}"'</publisher>' $'\n'\
  '<rating>'"${convertedRating[$i]}"'</rating>' $'\n'\
  '<plot>'"${desc[$i]}"'</plot>' $'\n'\
  '<developer>'"${developer[$i]}"'</developer>' $'\n'\
  '<players>'"${players[$i]}"'</players>' $'\n'\
  '<kidsgame>'"${kidsgame[$i]}"'</kidsgame>' $'\n'\
'</game>' $'\n'\
> "$nfoDir""${name[$i]}".nfo
done

# banner in AKL is the same of marquee in gamelist
# title/snap in AKL are the same of screenshots in gamelist
# 
# better change the asset location in AKL ?
#
# change into rom dir
cd "${nfoDir}";
# go one level up
cd ..;
# check if media folder exist and if not generate one
[ ! -d "./media" ] && mkdir "./media" && echo "media folder not found --> generated";
# check if wheels folder exist and if not generate one
[ ! -d "./media/wheels" ] && mkdir "./media/wheels" && echo "wheel folder not found --> generated";
# the same for the screenshots
[ ! -d "./media/screenshots" ] && mkdir "./media/screenshots" && echo "screenshot folder not found --> generated";
#
# check if banners/titles/snaps exist on level above roms(nfos)
# if so backup it and soft-link it to ./media/wheels ./media/screenshots 
[ -d "./banners" ] && mv "./banners" "./banners-backup" && echo "banners folder existing --> backup generated";
ln -s "./media/marquees" "./banners" && echo "linked ./banners to ./media/marquees";
#
[ -d "./titles" ] && mv "./titles" "./titles-backup" && echo "titles folder existing --> backup generated";
ln -s "./media/screenshots" "./titles" && echo "linked ./titles to ./media/screenshots";
[ -d "./snaps" ] && mv "./snaps" "./snaps-backup" && echo "snaps folder existing --> backup generated";
ln -s "./media/screenshots" "./snaps" && echo "linked ./snaps to ./media/screenshots";
[ -d "./fanarts" ] && mv "./fanarts" "./fanarts-backup" && echo "fanarts folder existing --> backup generated";
ln -s "./media/screenshots" "./fanarts" && echo "linked ./fanarts to ./media/screenshots";
#
# check if covers folders is empty, in case replace with screenshots
coverDir="./media/covers"
[ -z "$(ls -A ./media/covers)" ] && coverDir="./media/screenshots";
[ -d "./boxfronts" ] && mv "./boxfronts" "./boxfronts-backup" && echo "boxfronts folder existing --> backup generated";
ln -s "$coverDir" "./boxfronts" && echo "linked ./boxfronts to ./media/covers if not empty or to ./media/screenshots if covers are emtpy";
[ -d "./cartridges" ] && mv "./cartridges" "./cartridges-backup" && echo "cartridges folder existing --> backup generated";
ln -s "$coverDir" "./cartridges" && echo "linked ./cartridges to ./media/covers if not empty or to ./media/screenshots if covers are emtpy";
