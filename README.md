# BG96 GPS #

This library provides your application with access to GPS location data retrieved from a BG96 module. It is intended for use with the imp006 module.

**To include this library to your project, add**

```
#require "BG96_GPS.device.lib.nut:0.0.1"
```

**at the top of your device code**

## BG96 GPS Usage ##

The library provides a singleton, *BG_96*, and therefore has no constructor. The singleton is initialized for you. All of the methods listed below should be called on *BG96_GPS* directly.

### Usage Example ###

This is a very simple example that enables GNSS on the bG96 and then polls and prints out the fix every ten seconds:

```squirrel
#require "BG96_GPS.device.lib.nut:0.0.1"

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
    // Note: Non-assist cold fix time can be up to 12.5 min if new almanacs and ephemerides need to be fetched
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

Boolean &mdash; whether GNSS is enabled.

### enableGNSS(*[options]*) ###

This method turns on GNSS with the specified options. This method will run asynchronously; please use the *onEnabled* and/or *onLocation* callbacks to handle errors and schedule next tasks.

The BG96 modem must be powered on to enable GNSS. If the modem is not up when *enableGNSS()* is a called, the impOS method [**imp.net.open()**](https://developer.electricimp.com/api/imp/net/open) will be triggered for the `cell0` interface and the [**interface**](https://developer.electricimp.com/api/interface) object returned by this call will be stored. This [**interface**](https://developer.electricimp.com/api/interface) object can be accessed by calling *getNetOpenObject()*, and can be cleared by calling *clearNetOpenObject()* or by passing a parameter with a value of `true` when calling *disableGNSS()*.

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
| *onLocation* | Function | Callback to be triggered when GNSS location data is ready. This function has one parameter, a table, that may contain the keys *error* or *fix*. Default: no callback |

#### Location Mode Values ####

The following are the allowed values for the *locMode* option. Each is a member of the *BG96_GNSS_LOCATION_MODE* enum.

| Enum Value | Latitude and Longitude Format |
| --- | --- |
| *BG96_GNSS_LOCATION_MODE.ZERO* | `ddmm.mmmm N/S,dddmm.mmmm E/W` |
| *BG96_GNSS_LOCATION_MODE.ONE* | `ddmm.mmmmmm N/S,dddmm.mmmmmm E/W` |
| *BG96_GNSS_LOCATION_MODE.TWO* | `(-)dd.ddddd,(-)ddd.ddddd` |

#### Return Value ####

Nothing.

### disableGNSS(*[clearNetOpen]*) ###

This method turns off GNSS and cancels all active location polling.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *clearNetOpen* | Boolean | No | Clears the [**interface**](https://developer.electricimp.com/api/interface) object created if [**imp.net.open()**](https://developer.electricimp.com/api/imp/net/open) was called during *enableGNSS()*. Default: `true` |

#### Return Value ####

Boolean &mdash; whether GNSS was successfully disabled.

### getLocation(*[options]*) ###

This method can be used to start polling for location data or to make a single request for location data.

**Note** This method will not enable GNSS or the BG96 modem. If GNSS is not turned on this request will return an error. If no *onLocation* callback is provided, a single location request will be made and the result will be returned immediately and the polling option will be ignored.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *options* | Table | No | Configuration options for the location request, see [**Location Options**](#location-options), below, for details. If no table is passed in, or a partial table is provided, default values will be used |

#### Location Options ####

| Key | Value Type | Description |
| --- | --- | --- |
| *locMode* | Integer | Latitude and longitude display formats. See [**Location Mode Values**](#location-mode-values), above, for more details. Default: 2 |
| *poll* | Boolean | If `false` a single location request will be triggered, otherwise a location polling loop will be started. Default: `true` |
| *checkFreq* | Integer | If configured to poll, how often in seconds to check for fix data. Default: 1 |
| *onLocation* | Function | Callback to be triggered when GNSS location data is ready. This function has one parameter, a table, that may contain the keys *error* or *fix*. Default: no callback |

#### Return Value ####

Table or `null` &mdash; If no *onLocation* callback is included, a table with the keys *error* or *fix* will be returned, otherwise results will be passed to the *onLocation* callback and this function will return `null`.

### getNetOpenObject() ###

If the impOS method [**imp.net.open()**](https://developer.electricimp.com/api/imp/net/open) has been triggered by this library, use this method to obtain the [**interface**](https://developer.electricimp.com/api/interface) object created by that call. If the library has not made a call to power up the BG96 modem, this object will be `null`.

#### Return Value ####

[**interface**](https://developer.electricimp.com/api/interface) object or `null`.

### clearNetOpenObject() ###

This method sets the stored [**interface**](https://developer.electricimp.com/api/interface) object to `null`.

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

The BG96 GPS library is licensed under the [MIT License](LICENSE). Copyright 2019-20 Electric Imp, Inc.
