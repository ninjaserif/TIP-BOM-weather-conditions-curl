# TIP-BOM-weather-conditions-curl

Telegraf Input Plugin (TIP) to call the Bureau Of Meteorology (BOM) to get weather conditions.  My use case was to create this script so the data could be stored in InfluxDB - visualized in Grafana - but the script could be used for other uses if you just need the json.

The script works in 3 steps:

1. curl the BOM URL to BOMout1.json
2. compare the most recent entry of BOMout1.json with BOMout2.json (if exists)
3. if BOMout2.json doesn't exist - or it is different to BOMout1.json, then cleanup the output into BOMout3.json for Telegraf to consume.  If BOMout1.json and BOMout2.json are the same, then output nothing.

The script returns the below output:

```json
{
  "name": "<location>",
  "local_date_time": "19/11:30am",
  "local_date_time_full": "20200919113000",
  "air_temp": 23.5,
  "apparent_t": 21.9,
  "delta_t": 6.2,
  "dewpt": 12.8,
  "press": 1018.2,
  "rel_hum": 51,
  "wind_dir": "E",
  "wind_spd_kmh": 13,
  "gust_kmh": 22,
  "rain_trace": 0.0
}
```

## Features

* cURL is used to read BOM weather conditions for desired city / town
* jq is used to format results
* Output results to json for consumption by Telegraf
* Only return a result if different to last result.  BOM only reports conditions every 15 minutes or so - and if we report every call to BOM then it looks messy in Grafana
* Copies of script and config could be created to retrieve weather conditions of multiple locations
* I have limited the result to the condition elements which I was interested in tracking.  There are additional elements which you could be added to the WCOND variable
* Weather conditions include:
  * name (location of returned results)
  * local date time
  * air temp (degrees C)
  * apparent temp (degrees C)
  * delta temp (wet bulb depression, degrees C)
  * dew point temp (degrees C)
  * pressure (pressure QNH, hectopascals hPa)
  * relative humidity (percentage)
  * wind direction
  * wind speed (km/h)
  * wind gust speed (km/h)
  * rain trace (since 9am, millimeters mm)
* tested / works on various releases of Rasbian as well as Ubuntu

## Prerequisite

Install:

* telegraf (apt-get install telegraf)
* cURL (apt-get install curl)
* jq (apt-get install jq)

## Setup

* download latest release - <https://github.com/ninjaserif/TIP-BOM-weather-conditions-curl/releases/latest/>

Below is a "one-liner" to download the latest release

```bash
LOCATION=$(curl -s https://api.github.com/repos/ninjaserif/TIP-BOM-weather-conditions-curl/releases/latest \
| grep "tag_name" \
| awk '{print "https://github.com/ninjaserif/TIP-BOM-weather-conditions-curl/archive/" substr($2, 2, length($2)-3) ".tar.gz"}') \
; curl -L -o TIP-BOM-weather-conditions-curl_latest.tar.gz $LOCATION
```

* extract release

```bash
sudo mkdir /usr/local/bin/TIP-BOM-weather-conditions-curl && sudo tar -xvzf TIP-BOM-weather-conditions-curl_latest.tar.gz --strip=1 -C /usr/local/bin/TIP-BOM-weather-conditions-curl
```

* navigate to where you extracted TIP-BOM-weather-conditions-curl - i.e. `cd /usr/local/bin/TIP-BOM-weather-conditions-curl/`
* create your own config file `# this is preferred over renaming to avoid wiping if updating to new release`

```bash
cp config-sample.sh config.sh
```

* visit BOM and navigate to your states "Observations" page - then locate your desired city / town.  Once on the page which shows a table of recent observations locate the "Other formats" link and navigate to that - which takes you to the bottom of the page - and copy the URL below "JavaScript Object Notation format (JSON) in row-major order".

* edit config.sh and set your configuration - paste your URL into the config for BOMURL

```bash
BOMURL="<URL>"               # URL to retrieve weather conditions
```

* confirm scripts have execute permissions
  * TIP-BOM-weather-conditions-curl.sh should be executable
  * config.sh should be executable

* you may also need to modify the permissions of both the script and config.sh to be owned by the telegraf user:group - i.e. `sudo chown telegraf:telegraf TIP-BOM-weather-conditions-curl.sh | sudo chown telegraf:telegraf config.sh`

* you may also need to modify the permissions of the directory the script and config.sh are stored to be  - i.e. `sudo chmod 774 /usr/local/bin/TIP-BOM-weather-conditions-curl`

* add the following to your telegraf.conf

```bash
[[inputs.exec]]
  commands = ["/usr/local/bin/TIP-BOM-weather-conditions-curl/TIP-BOM-weather-conditions-curl.sh"]
  timeout = "10s"
  data_format = "json"
  name_suffix = "_BOMweather"
  tag_keys = ["name","local_date_time","local_date_time_full","wind_dir"]
```

## Change log

* 1.0 15-05-2017
  * first release
* 1.0.0 19-09-2020
  * cleaned up for git - set to version 1.0.0
  * use config and location for reference
* 1.0.1 27-09-2020
  * updated README instructions to include setting folder permissions following first deployment / test

## -END-
