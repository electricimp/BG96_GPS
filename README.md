# BG96 GPS 0.1.0 #

This library provides your application with access to GPS location data retrieved from a BG96 module. It is intended for use with the imp006.

**To include this library to your project, copy the content of the file**

```
bg96_gps.device.lib.nut
```

**and paste it at the top of your device code**

**IMPORTANT** This library has been released in alpha form to support early testers of impOS™ 43. An exception will be thrown if this library is run on an earlier version of impOS. If you are working with impOS 42, use the version of this library in the [*master* branch](https://github.com/electricimp/BG96_GPS/tree/master).

## BG96 GPS Usage ##

The library provides a singleton, *BG_96*, and therefore has no constructor. The singleton is initialized for you. All of the methods listed below should be called on *BG96_GPS* directly.

### Usage Example ###

This is a very simple example that enables GNSS on the BG96 and then polls and prints out the location fix every ten seconds:

```squirrel
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

This method turns on GNSS with the specified options. This method will run asynchronously; please use the *onEnabled* and/or *onLocation* callbacks to handle errors and schedule next tasks.

The BG96 modem must be powered on to enable GNSS.

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
| *onEnabled* | Function | Callback to be triggered when GNSS has been enabled. This function has one parameter which will contain an error message or be `null` if no error was encountered. Default: no callback |
| *onLocation* | Function | Callback to be triggered when GNSS location data is ready. This function has one parameter: a table that may contain the keys *error* or *fix*. Default: no callback |
| *useAssist* | Boolean | Enable assist without loading new assist data. New in library version 0.1.0. Default: `false` |
| *assistData* | Blob | GPS fix assist data. New in library version 0.1.0. Default: no data |

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
| *poll* | Boolean | No | If `false` a single location request will be triggered, otherwise a location polling loop will be started. Default: `true` |
| *checkFreq* | Integer | No |  If configured to poll, how often in seconds to check for fix data. Default: 1 |
| *onLocation* | Function | Yes | Callback to be triggered when GNSS location data is ready. This function has one parameter, a table, that may contain the keys *error* or *fix*. Default: no callback |

#### Return Value ####

Nothing.

### enableDebugLogging(*enable*) ###

Use this method to enable/disable library debug logging.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *enable* | Boolean | Yes | If `false` the library will disable all internal logging, otherwise debug logs will be displayed if the device is online |

#### Return Value ####

Nothing.

## License ##

The BG96 GPS library is licensed under the [MIT License](LICENSE). Copyright 2020 Twilio.
