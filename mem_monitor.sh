#!/bin/bash

#-----------------------------MEMORY UTILIZATION MONITOR---------------------------------#

 # color codes 
   GREEN='\033[0;32m'
   YELLOW='\033[1;33m'
   RED='\033[0;31m'
   NC='\033[0m'


#-----------VARIABLES------------
   timestamp=$(date "+%Y-%m-%d %H:%M:%S")
   total=$(grep MemTotal /proc/meminfo | awk '{print $2}') # returns the Total Memory kB
   available=$(grep MemAvailable /proc/meminfo | awk '{print $2}') # returns the Available Memort kB
   used_memory=$(echo "scale=2; ( $total - $available ) * 100 / $total" | bc ) # Used Memory in %
#-------------------------------

if [ "$(echo "$used_memory < 80" | bc -l)" -eq 1 ]; then
    echo -e "${GREEN}$timestamp - OK - ${used_memory}%${NC}"
    exit 0
elif [ "$(echo "$used_memory < 90" | bc -l)" -eq 1 ]; then
    echo -e "${YELLOW}$timestamp - WARNING - ${used_memory}%${NC}"
    exit 1
else
    echo -e "${RED}$timestamp - CRITICAL - ${used_memory}%${NC}"
    exit 2
fi