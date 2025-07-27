#!/bin/bash

#-----------CPU UTILIZATION MONITOR-------------#
   # Color Codes
   GREEN='\033[0;32m'
   YELLOW='\033[1;33m'
   RED='\033[0;31m'
   NC='\033[0m' #no color 
#----------------------- Variables--------------------------
  timestamp=$(date "+%Y-%m-%d %H:%M:%S") 
  cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk -F',' '{print $4}' | awk '{print $1}') # Returns id,idle: time spent in the kernel idle handler
  cpu_usage=$(echo "100 - $cpu_idle" | bc) # bc for basic calculations, needed for accurate calculations with decimals 

#----------------------------------------------
if [ "$(echo "$cpu_usage < 80" | bc -l)" -eq 1 ]; then
  echo -e "${GREEN}$timestamp - OK - ${cpu_usage}%${NC}"  # if usage < 80%
	exit 0
elif [ "$(echo "$cpu_usage < 90" | bc -l)" -eq 1 ]; then
	echo -e "${YELLOW}$timestamp - WARNING - ${cpu_usage}%${NC}"  # if usage >= 80% && usage < 90%
  exit 1
else 
	echo -e "${RED}$timestamp - CRITICAL - ${cpu_usage}%${NC}"   # if usage >= 90%
	exit 2
fi


