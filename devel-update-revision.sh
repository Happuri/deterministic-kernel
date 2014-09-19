#!/bin/bash

echo ""
echo "==============================================================="
echo "Updating revision / seed"
echo ""


arg_metod=$1

# load current kernel version
# and other data that might be useful (the old data before we will overwrite it)

echo "Loading current data to start with"
. kernel-build/linux-mempo/env-data.sh
kernel_ver="$kernel_general_version"
echo "We have kernel_ver=$kernel_ver"
# TODO assert correct format

if [[ -z "$arg_metod" ]] ; then arg_metod="increase" ; fi

echo "### Preparing new env"
url_provable_entropy="http://mempo.org/random/blockchain/default/get/"
echo "Getting provable entropy from $url_provable_entropy"
entropy_data=$( wget -q "$url_provable_entropy" --output-document - ) 
entropy_seed=$( printf '%s\n' "$entropy_data" | head -n 1 | tail -n 1 )
entropy_index=$( printf '%s\n' "$entropy_data" | head -n 2 | tail -n 1 )
entropy_name=$( printf '%s\n' "$entropy_data" | head -n 3 | tail -n 1 )
if [[ -z "$entropy_index" ]] || [[ -z "$entropy_seed" ]] ; then
	echo ""
	echo "@@@@@@ ERROR:      OUPSS. It seems we can not download the entropy. @@@@@@ Enter your own seed!!! @@@@@@"
	echo "  Go to e.g. http://block-explorer.com/ , you see a list of blocks. The highest number is the newest block. "
	echo "  Pick not the newest block but 6 blocks before, click it to see details"
	echo "  And copy the number of block as INDEX and the Hash as SEED."
	echo "  Or even better use local litecoin node once is synchronized"
	echo "Sorry for this problem. Press ENTER to continue"
	read _
else
	echo "Got entropy seed from $entropy_name index $entropy_index:"
	echo "$entropy_seed"
fi

echo ""
echo "This is the seeds we have now, you can review them or edit them."
echo "  (It is best to confirm with locally running litecoin node if you can;"
echo "  though that is not too important as we anyway in binary distributions)"
echo ""

read -e -p "The block INDEX (short nunber): " -i "$entropy_index"
read -e -p "The block SEED (long random string): " -i "$entropy_seed"
echo ""

newenv_date=$(date +'%Y-%m-%d %H:%M:%S')

case $arg_metod in
"restart")
		newenv_rev='01'
  ;;
"increase")
	echo "Increase revision, please enter revision like 02:" # TODO auto
	read newenv_rev
	;;
*)
	echo "Error, method $arg_metod" ; exit 2
  ;;
esac

f_oldenv="kernel-build/linux-mempo/env-data.sh" # this will be updated
f_newenv_dir="var.update" # temp dir
mkdir -p "$f_newenv_dir"

f_newenv="$f_newenv_dir/env-data.sh"

printf '' > $f_newenv
printf '%s\n' "# place for STATIC settings for release. [autogenerated] ${commit_msg_extra1}" >> $f_newenv
printf '%s\n' "export kernel_general_version=\"$kernel_ver\" # base version (should match the one is sources.list)" >> $f_newenv
printf '%s\n' "export KERNEL_DATE='$newenv_date' # UTC time of mempo version. This is > then max(kernel,grsec,patches) times" >> $f_newenv
printf '%s\n' "export CURRENT_SEED='$entropy_seed' # $entropy_name block $entropy_index (*)" >> $f_newenv
printf '%s\n' "export DEBIAN_REVISION='$newenv_rev' # see README.md how to update it on git tag, on rc and final releases" >> $f_newenv

cp "$f_newenv" "$f_oldenv"
echo "New env is:"
cat "$f_oldenv"
echo ""
