#!/bin/sh
# vim:ff=unix noati:ts=4:ss=4
#!/bin/sh


# Mach2 Harrier
DSK_PREFIX='wwn-0x6000c500ae'
# ST14000 10TB disks
#DSK_PREFIX='wwn-0x5000c5009'

# ls /dev/disk/by-id/$DSK_PREFIX*LUN0SUFFIX = LUN0 devs
# ls /dev/disk/by-id/$DSK_PREFIX*LUN1SUFFIX = LUN1 devs
LUN0SUFFIX='0000000000000000'
LUN1SUFFIX='0001000000000000'

enclosure_sg=$(lsscsi -g \
   | grep enclos | grep SEAGATE \
   | awk '{ print $7 }' | tail -1)
# for d in $(lsscsi -g | grep ST14000 | awk '{ print $6 }')
map_disk_slots() { 
   for dev in $(ls /dev/disk/by-id/ | grep "$DSK_PREFIX" | grep -v part) 
   do
       d="/dev/disk/by-id/$dev"
       this_sn=$(sg_vpd --page=0x80 $d \
           | grep 'Unit serial number:' \
           | awk -F ' ' '{print $4}')
       sas_address=$(sg_vpd --page=0x83 ${d} \
           | grep -A 3 'Target port:' \
           | grep "0x" | tr -d ' ' \
           | cut -c 3-)
       device_slot=$(sg_ses -p 0xa ${enclosure_sg} \
           | grep -B 8 -i $sas_address  \
           | grep 'device slot number:'  \
           | sed 's/^.*device slot number: //g')
       device_slot=$(printf "%03d" $device_slot)
       kdev=$(readlink -f $d)
       echo "slot=$device_slot $dev sas_addr=$sas_address s/n=$this_sn $kdev"
   done
}

map_disk_slots | sort
