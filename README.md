# BG96 GPS 1.0.1 #

This library provides your application with access to GPS location data retrieved from a BG96 module. It is intended for use with the imp006.

**To include this library to your project, add the following line to the top of your device code:**

```squirrel
#require "BG96_GPS.device.lib.nut:1.0.1"
```

![Build Status](https://cse-ci.electricimp.com/app/rest/builds/buildType:(id:Bg96gps_BuildAndTest)/statusIcon)

## BG96 GPS Usage ##

The library provides a singleton, *BG_96*, and therefore has no constructor. The singleton is initialized for you. All of the methods listed below should be called on *BG96_GPS* directly.

### Usage Example ###

This is a very simple example that enables GNSS on the BG96 and then polls and prints out the location fix every ten seconds:

```squirrel
#require "BG96_GPS.device.lib.nut:1.0.1"

function onLocation(result) {
    if ("fix" in result) {
        server.log("Got fix:");
        foreach (key, value in result) {
            server.log(key + ": " + value);
            if ((typeof value) == "table") {
                foreach (k, v in value) {
                    server.log(" " + k + ": " + v);
                }
            }
        }
    } else {
        server.error(result.error);
    }
}

server.log("Enabling GNSS and getting fix...");

BG96_GPS.enableGNSS({
    // NOTE Non-assist cold fix time can be up to 12.5 mins
    //      if new almanacs and ephemerides need to be fetched
    "maxPosTime" : 90,
    "checkFreq" : 10,
    "onLocation" : onLocation
});
```

### BG96 GNSS Antenna ###

The BG96 will need to be connected to an external antenna for GNSS operation. There are many GNSS antennas available. For simplicity and performance, an active patch antenna with integrated ground plane is preferable. We’ve had good results with the [Molex 206640](https://www.molex.com/molex/products/part-detail/antennas/2066400001), but there are others such as those made by [Taoglas](https://www.taoglas.com/product-category/gps-glonass-gnss/).

## BG96 GPS Methods ##

### isGNSSEnabled() ###

A helper method used to determine if GNSS is currently enabled.

#### Return Value ####

Boolean &mdash; whether GNSS is enabled (`true`) or disabled (`false`).

### enableGNSS(*[options]*) ###

This method turns on GNSS with the specified options. This method will run asynchronously; please use the *onEvent* and/or *onLocation* callbacks to handle errors and schedule next tasks.

The BG96 modem must be powered on to enable GNSS.

#### Assist Data ####

If you wish to load GNSS assist data — which we strongly recommend — pass this to the library as the value of the *options* key *assistData*. Provide the binary data as a blob. The BG96 uses Quectel’s gpsOneXTRA assist data format. The latest file is available from Quectel at either of the following URLs:

* [https://xtrapath4.izatcloud.net/xtra2.bin](https://xtrapath4.izatcloud.net/xtra2.bin)
* [https://xtrapath4.izatcloud.net/xtra3grc.bin](https://xtrapath4.izatcloud.net/xtra3grc.bin)

The `xtra2.bin` data supports GPS and Glonass; the `xtra3grc.bin` data supports GPS, Glonass and BeiDou. Choose the data package that best meets your needs. Both are well under 50KB, so can be easily acquired by your agent and passed to the device for use in your *enableGNSS()* call. See [the Dev Center for sample code](https://developer.electricimp.com/reference/gnss-on-imp006#load-gnss-location-assist-data).

You can check the validity of assist data you have already loaded using [*isAssistDataValid()*](#isassistdatavalid).

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *options* | Table | No | Configuration options for the GNSS: see [**Enable Options**](#enable-options) for details. If no table is passed in, or a partial table is provided, default values will be used |

#### Enable Options ####

| Key | Value Type | Description |
| --- | --- | --- |
| *gnssMode* | Integer | GNSS working mode. Currently Stand Alone mode (1) is the only mode supported on the BG96. Default: 1 |
| *maxPosTime* | Integer | The maximum positioning time in seconds. Range: 1-255. Default: 30 |
| *accuracy* | Integer | Accuracy threshold of positioning in meters. Range: 1-1000. Default: 50 |
| *numFixes* | Integer | Number of attempts for positioning. 0 indicates continuous positioning. Non-zero values indicate the actual number of attempts for positioning. Range 0 - 1000. Default: 0 |
| *checkFreq* | Integer | How often in seconds fix data is returned. Range: 1 - 65535. Default: 1 |
| *retryTime* | Integer or Float | How long to wait between retries when powering up the modem. Default: 1 |
| *locMode* | Integer | Latitude and longitude display formats. See [**Location Mode Values**](#location-mode-values), below, for more details. Default: 2 |
| *onEvent* | Function | Callback to be triggered when GNSS has been enabled or some other event occurs. This function has one parameter, a table, that may contain the keys *error* or *event*. Default: no callback |
| *onLocation* | Function | Callback to be triggered when GNSS location data is ready. This function has one parameter: a table that may contain the keys *error* or *fix*. Default: no callback |
| *useAssist* | Boolean | Enable assist without loading new assist data. Default: `false` |
| *assistData* | Blob | GPS fix assist data. Default: no data |

#### Location Mode Values ####

The following are the allowed values for the *locMode* option. Each is a member of the *BG96_GNSS_LOCATION_MODE* enum.

| Enum Value | Latitude and Longitude Format |
| --- | --- |
| *BG96_GNSS_LOCATION_MODE.ZERO* | `ddmm.mmmm N/S,dddmm.mmmm E/W` |
| *BG96_GNSS_LOCATION_MODE.ONE* | `ddmm.mmmmmm N/S,dddmm.mmmmmm E/W` |
| *BG96_GNSS_LOCATION_MODE.TWO* | `(-)dd.ddddd,(-)ddd.ddddd` |

#### Return Value ####

Nothing.

### disableGNSS() ###

This method turns off GNSS and cancels all active location polling.

#### Return Value ####

Boolean &mdash; whether GNSS was successfully disabled (`true`) or not (`false`).

### getLocation(*options*) ###

This method can be used to start polling for location data or to make a single request for location data. While most of the keys you can include in the table passed into *options*, you **must** include *onLocation* and a suitable callback function.

This method will not enable GNSS or the BG96 modem. If GNSS is not turned on this request will return an error.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *options* | Table | Yes | Configuration options for the location request, see [**Location Options**](#location-options), below, for details |

#### Location Options ####

| Key | Value Type | Required | Description |
| --- | --- | --- | --- |
| *mode* | Integer | No | Latitude and longitude display formats. See [**Location Mode Values**](#location-mode-values), above, for more details. Default: 2 |
| *poll* | Boolean | No | If `false`, a single location request will be triggered, otherwise a location polling loop will be started. Default: `true` |
| *waitFix* | Boolean | No | If `true` and the modem reports it is waiting for a fix, this will not be treated as an error, otherwise an error will be issued. Default: `false` |
| *checkFreq* | Integer | No |  If configured to poll, how often in seconds to check for fix data. Default: 1 |
| *onLocation* | Function | Yes | Callback to be triggered when GNSS location data is ready. This function has one parameter, a table, that may contain the keys *error* or *fix* |

#### Return Value ####

Nothing.

### cancelPoll() ###

Cancels polling immediately without disabling GNSS.

#### Return Value ####

Nothing.

### isAssistDataValid() ###

Check if the BG96’s assist data is valid or not present.

This method returns a value, but also issues notifications via the *onEvent* callback (see [**EnableGNSS() Options**](#enable-options)). The table passed to the callback will include the key *data*, which is a table: it has the key *valid*, which will be `true` if the data is valid, otherwise `false`. If *valid* is true, *data* will also contain the key *time* to provide the remaining validity period in minutes.

If the validity could not be determined, eg. the modem is off, the *onEvent* table will contain a single key, *error*.

#### Return Value ####

Boolean — `true` if the assist data is valid, or `false` if the data is invalid or validity could not be determined.

### deleteAssistData(*[mode]*) ###

Delete any installed assist data. **Note** This call will also disable GNSS.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *mode* | Integer | No | The desired reset mode (see [**gnss-session.assist.reset()**](https://developer.electricimp.com/api/gnss-session/assist/reset)) |

#### Return Value ####

Nothing.

## Release Notes ##

* 1.0.1
    * Implement BG96 GNSS default states, reset modes as constants.
* 1.0.0
    * Initial public release.

## License ##

The BG96 GPS library is licensed under the [MIT License](LICENSE). Copyright 2021 Twilio.
