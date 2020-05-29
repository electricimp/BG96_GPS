# BG96_GPS #

Library to access GPS location data for the imp006. 

To add this library to your project, add `#require "BG96_GPS.device.lib.nut:0.0.1"` to the top of your device code

## BG96_GPS Usage ##

BG96_GPS is a singleton and has no constructor. There is no need to create an instance or initialize. All of the methods listed below should be called on BG96_GPS directly. 

## BG96_GPS Example ##

A very simple example that enables the GNSS and then polls and prints out the fix every 10 seconds:

```
#require "BG96_GPS.device.lib.nut:0.0.1"

function onLocation(result) {
    if ("fix" in result) {
        server.log("got fix:");
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

server.log("enabling GNSS and getting fix ...");
BG96_GPS.enableGNSS({
    // Note: Non-assist cold fix time can be up to 12.5 min if new almanacs and ephemerides need to be fetched
    "maxPosTime" : 90, 
    "checkFreq" : 10,
    "onLocation" : onLocation
});
```
## BG96_GPS Antenna ##

The BG96 will need to be connected to an external antenna for GNSS operation. There are many GNSS antennas available, for simplicity and performance an active patch antenna with integrated ground plane is preferrable. We've had good results with  the Molex 206640, but there are others such as Taoglas.

## BG96_GPS Methods ##

### isGNSSEnabled() ###

A helper method used to determine if GNSS is currently enabled.

#### Return Value ####

Boolean, whether GNSS is enabled.

### enableGNSS(*[opts]*) ###

This method turns on GNSS with the specified options. This method will run asynchronously, please use the *onEnabled* and/or *onLocation* callbacks to handle errors and schedule next tasks.

Please note that the BG96 modem must be on to enable GNSS, if the modem is not up when *enableGNSS* is a called the impOS method `imp.net.open` will be triggered for `cell0` interface and the object returned by this call will be stored. The net open object can be accessed by calling the *getNetOpenObject* method. The net open object can be cleared by calling the *clearNetOpenObject* method or by passing a parameter with a value of `true` when calling the *disableGNSS* method. 

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *options* | Table | No | Configuration options for the GNSS, see [Enable Options Table](#enable-options-table) below for details. If no table is passed in default values will be used. | 

##### Enable Options Table #####

| Key | Value Type | Description |
| --- | --- | --- |
| *gnssMode* | Integer | GNSS working mode. Currently Stand Alone mode (1) is the only mode supported on the BG96. Default: 1 |
| *maxPosTime* | Integer | The maximum positioning time in seconds. Range: 1-255, Default: 30 |
| *accuracy* | Integer | Accuracy threshold of positioning in meters. Range: 1-1000, Default: 50 |
| *numFixes* | Integer | Number of attempts for positioning. 0 indicates continuous positioning. Non-zero values indicate the actual number of attempts for positioning. Range 0 - 1000, Default: 0 |
| *checkFreq* | Integer | How often in seconds fix data is returned. Range: 1 - 65535, Default: 1 |
| *retryTime* | Integer/Float | How long to wait between retries when powering up the modem. Default: 1 |
| *locMode* | Integer | Latitude and longitude display formats. See [BG96_GNSS_LOCATION_MODE Enum](#bg96_gnss_location_mode-enum) below for more details. Default: 2 |
| *onEnabled* | Function | Callback function to be triggered when GNSS has been enabled. This function has one parameter which will contain an error message or `null` if no error was encountered. Default: `null` |
| *onLocation* | Function | Callback function to be triggered when GNSS location data is ready. This function has one parameter, a table, that may contain the keys `error` or `fix`. Default: `null` |

##### BG96_GNSS_LOCATION_MODE Enum #####

| Enum Value | Format |
| --- | --- |
| BG96_GNSS_LOCATION_MODE.ZERO | latitude,longitude format: ddmm.mmmm N/S,dddmm.mmmm E/W |
| BG96_GNSS_LOCATION_MODE.ONE | latitude,longitude format: ddmm.mmmmmm N/S,dddmm.mmmmmm E/W |
| BG96_GNSS_LOCATION_MODE.TWO | latitude,longitude format: (-)dd.ddddd,(-)ddd.ddddd |

#### Return Value ####

Nothing.

### disableGNSS(*[clearNetOpen]*) ###

This method turns off GNSS and cancels all active location polling. 

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *clearNetOpen* | Boolean | No | Clears the object created if `imp.net.open` was called during *enableGNSS*. Default: true | 

#### Return Value ####

Boolean - whether GNSS was successfully disabled.

### getLocation(*[opts]*) ###

This method can be used to start polling for location data or to make a single request for location data. 

Please note this method will not enable GNSS or the BG96 modem. If GNSS is not turned on this request will return an error. If no *onLocation* callback is provided a single location request will be made and the result will be returned immediately and the polling option will be ignored. 

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *options* | Table | No | Configuration options for the location request, see [Location Options Table](#location-options-table) below for details. If no table is passed in default values will be used. | 

##### Location Options Table #####

| Key | Value Type | Description |
| --- | --- | --- |
| *locMode* | Integer | Latitude and longitude display formats. See [BG96_GNSS_LOCATION_MODE Enum](#bg96_gnss_location_mode-enum) above for more details. Default: 2 |
| *poll* | Boolean | If `false` a single location request will be triggered, otherwise a location polling loop will be started. Default: `true` |
| *checkFreq* | Integer | If configured to poll, how often in seconds to check for fix data. Default: 1 |
| *onLocation* | Function | Callback function to be triggered when GNSS location data is ready. This function has one parameter, a table, that may contain the keys `error` or `fix`. Default: `null` |

#### Return Value ####

Table or null - If *onLocation* callback is not passed into via options a table with the keys `error` or `fix` will be returned, otherwise results will be passed to the *onLocation* callback and this function will return `null`.

### getNetOpenObject() ###

If the impOS method `imp.net.open` has been triggered by this library, use this method to obtain the object created by the `imp.net.open` call. If the library has not made a call to powered up the BG96 modem this object will be `null`.

#### Return Value ####

Object created by `imp.net.open` or `null`

### clearNetOpenObject() ###

This method sets the stored `imp.net.open` object to `null`. 

#### Return Value ####

Nothing

### enableDebugLogging(*enable*) ###

Use this method to enable/disable library debug logging.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *enable* | Boolean | Yes | If `false` the library will disable all internal logging, otherwise debug logs will be displayed if the device is online. | 

#### Return Value ####

Nothing

## License ##

The BG96_GPS library is licensed under the [MIT License](LICENSE).
