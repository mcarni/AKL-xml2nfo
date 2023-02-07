#! /bin/bash

# initial version (_1) of this script was pure bash
# it worked most of the times, but it could not handle some case, i guess when the rom's name has . , [] () or {} or similar
# it was based on the work done by Chad in SO thread https://stackoverflow.com/questions/893585/how-to-parse-xml-in-bash
# but still as a comment in this thread : "Just because you can write your own parser, doesn't mean you should. – Stephen Niedzielski"
#
# so this second version (_2) uses xmlstarlet
# https://xmlstar.sourceforge.net/

# see also:
# https://stackoverflow.com/questions/19924798/bash-xmlstarlet-v-to-variable
# https://stackoverflow.com/questions/58390975/how-do-i-select-multiple-elements-with-the-same-name-using-xmlstarlet
# https://stackoverflow.com/questions/56886651/how-to-split-a-single-xml-file-into-multiple-based-on-tags
# https://xmlstar.sourceforge.net/doc/UG/xmlstarlet-ug.html

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

# nfo folder can be passed as argument to this script
nfoDir="$2";
# if nfo folder does not exit, generate it
[ ! -d "$nfoDir" ] && mkdir -p "$nfoDir";
# if not specified then the script will try to get it from the path in the gamelist
[ -z "$2" ] && echo "nfo location not specified, use the same of roms" && nfoDir=$(dirname "${path[0]}");

# count how many games there are in the gamelist
gameQty=$(xml sel -t -v "count(/gameList/game)" "$gameList");
echo "processed gamelist contains: ""$gameQty"" game(s)"

# parse the game list
parse_game () {
    # this is currently using the structure of the dr_mario.nfo example, can be suited to what is needed
    # https://github.com/chrisism/plugin.program.akl/blob/master/tests/assets/dr_mario.nfo
    # i kept the field which are available in gamelist but not used: developer, players, kidsgame
    path=$(xml sel -t -v "/gameList/game[$i]/path" "$gameList");
    extension="${path##*.}";
    path=$(basename -s ".$extension" "$path");
    name=$(xml sel -t -v "/gameList/game[$i]/name" "$gameList");
    # remove special characters from the nfo name... needed???
    #name=$(echo "$name" | sed -r 's/[\\\/\.\,\;\:\#\*\$]+//g');
    year=$(xml sel -t -v "/gameList/game[$i]/releasedate" "$gameList");
    # change from full release date (in the original xml) to only year (as in the .nfo file)
    year=(${year:0:4});
    genre=$(xml sel -t -v "/gameList/game[$i]/genre" "$gameList");
    publisher=$(xml sel -t -v "/gameList/game[$i]/publisher" "$gameList");
    rating=$(xml sel -t -v "/gameList/game[$i]/rating" "$gameList");
    # convert ratings from % to 0 to 10 scale
    firstDigit="${rating:0:1}";
    secondDigit="${rating:2:1}";
    thirdDigit="${rating:3:1}";
    [ -z "$thirdDigit" ] && thirdDigit="0";
    [ "$firstDigit" == "1" ] && convertedRating="10"
    [ "$firstDigit" == "0" ] && convertedRating="$secondDigit"."$thirdDigit";
    desc=$(xml sel -t -v "/gameList/game[$i]/desc" "$gameList");
    developer=$(xml sel -t -v "/gameList/game[$i]/developer" "$gameList");
    players=$(xml sel -t -v "/gameList/game[$i]/players" "$gameList");
    kidsgame=$(xml sel -t -v "/gameList/game[$i]/kidsgame" "$gameList");
}


generate_nfo () {
    echo "game"$i": "$name" generating nfo file";
    echo "<?xml version="'"1.0"'" encoding="'"utf-8"'" standalone="'"yes"?>' $'\n'\
'<game>' $'\n'\
  '<title>'"$name"'</title>' $'\n'\
  '<year>'"$year"'</year>' $'\n'\
  '<genre>'"$genre"'</genre>' $'\n'\
  '<publisher>'"$publisher"'</publisher>' $'\n'\
  '<rating>'"$convertedRating"'</rating>' $'\n'\
  '<plot>'"$desc"'</plot>' $'\n'\
  '<developer>'"$developer"'</developer>' $'\n'\
  '<players>'"$players"'</players>' $'\n'\
  '<kidsgame>'"$kidsgame"'</kidsgame>' $'\n'\
'</game>' $'\n'\
> "$nfoDir""$path".nfo
}

for (( i=1 ; i<=($gameQty) ; i++ )); do
    parse_game;
    generate_nfo;
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



