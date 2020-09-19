#!/bin/bash

# TIP-BOM-weather-conditions-curl

##### START
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPTDIR

if [ -f "$SCRIPTDIR/config.sh" ]; then
  . config.sh
else
  echo "$SCRIPTDIR/config.sh missing - copy config-sample.sh and update with your own config"
  exit 1
fi

##### Load config
SWVER="~~ TIP-BOM-weather-conditions-curl version 1.0.0 19/09/2020 ~~"
WCOND="name,local_date_time,local_date_time_full,air_temp,apparent_t,delta_t,dewpt,press,rel_hum,wind_dir,wind_spd_kmh,gust_kmh,rain_trace"

##### Functions
clean_output()
{
  # reading is different so update it and return reading
  cat $SCRIPTDIR/BOMout1.json | jq ".observations.data[0] | {$WCOND}" > $SCRIPTDIR/BOMout2.json
  # remove quotes from rain_trace value using sed
  find_rain_trace=$(jq '.rain_trace' $SCRIPTDIR/BOMout2.json)
  fix_rain_trace=$(jq -r '.rain_trace' $SCRIPTDIR/BOMout2.json)
  # check if rain_trace = "-" and replace with 0
  if [[ $fix_rain_trace = "-" ]]; then
    fix_rain_trace="0"
  fi
  sed "s/$find_rain_trace/$fix_rain_trace/g" $SCRIPTDIR/BOMout2.json > $SCRIPTDIR/BOMout3.json
  rm -f $SCRIPTDIR/BOMout1.json
} # end of clean_output

##### Main
# clear last run
rm -f $SCRIPTDIR/BOMout3.json

# get current readings from BOM
curl -s $BOMURL > $SCRIPTDIR/BOMout1.json

if [ -f $SCRIPTDIR/BOMout2.json ]; then
  # file exists check if current reading is the same as last reading
  if [[ $(cat $SCRIPTDIR/BOMout1.json | jq ".observations.data[0] | {$WCOND}") = $(cat $SCRIPTDIR/BOMout2.json) ]]; then
    # reading is the same so ignore it
    :
  else
    clean_output
    cat $SCRIPTDIR/BOMout3.json
  fi
else
  clean_output
  cat $SCRIPTDIR/BOMout3.json
fi

##### END