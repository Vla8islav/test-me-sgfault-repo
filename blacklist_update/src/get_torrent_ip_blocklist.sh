#!/bin/bash
set -euf

newline='
'
OIFS="$IFS"
IFS="$newline"

# Скачивает новую версию и сравнивает с существующей,
# если не идентичны копирует файл в директорию transmission
# и возвращает 1, в противном случае - 0
update_blacklist()
{
    local url_adress="$1"
    local current_blacklist_filename="$2"
    local current_tmp_folder="$3"
    local cur_transm_blacklist_folder="$4"
    wget -qO- $url_adress | gzip -d - >"$current_tmp_folder/$current_blacklist_filename"

    echo "Comparing $current_tmp_folder/$current_blacklist_filename and $cur_transm_blacklist_folder/$current_blacklist_filename..."
    if diff  $current_tmp_folder/$current_blacklist_filename $cur_transm_blacklist_folder/$current_blacklist_filename ; then
            echo "Identical files."
            return 0
    else
            echo 'New and old file is not identical. Lets rewrite the old file...'
            if cp -aT $current_tmp_folder/$current_blacklist_filename $cur_transm_blacklist_folder/$current_blacklist_filename; then
                echo 'File copy successful.'
            else
                echo 'File copy failed.'
            fi
            return 1
    fi
}

#retval=0
tmpfolder='/tmp/ip_torrent_blacklist'
blacklist_dir='/var/lib/transmission-daemon/info/blocklists'

first_block_list_name='blocklist1.txt'
second_block_list_name='blocklist2.txt'
third_block_list_name='blocklist3.txt'
rm -rf "$tmpfolder" && mkdir "$tmpfolder"

update_blacklist 'http://list.iblocklist.com/?list=bt_level1&fileformat=p2p&archiveforma$' $first_block_list_name $tmpfolder $blacklist_dir
rez1=$?
update_blacklist 'http://list.iblocklist.com/?list=bt_level2&fileformat=p2p&archiveforma$' $second_block_list_name $tmpfolder $blacklist_dir
rez2=$?
update_blacklist 'http://list.iblocklist.com/?list=bt_level3&fileformat=p2p&archiveforma$' $third_block_list_name $tmpfolder $blacklist_dir
rez3=$?
echo '1'
let "retval = rez1 + rez2 + rez3" && echo '11'
echo "$retval"
if [ "0" = "$retval" ]; then
    echo 'All files already up to date, no restart necessary.'
else
    echo 'Blacklist updated. Need to restart Transmission daemon.'
    echo 'Stoping transmission...'
    /etc/init.d/transmission-daemon stop
    echo 'Starting transmission...'
    /etc/init.d/transmission-daemon start
fi
echo '111'
exit 0

for bl in $bl_list; do
    update_bl $bl
    cmp_bl $bl
    upgrade_bl $bl
done

