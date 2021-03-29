class GNSSTestCase3 extends ImpTestCase {

    function setUp() {

        this.info("GET LOCATION WITH ASSIST TESTS");

        // TEST WE CAN ENABLE GNSS
        return Promise(function(resolve, reject) {
            BG96_GPS.enableGNSS({
                "maxPosTime" : 120,
                "checkFreq" : 60,
                "onEnabled": function(result) {
                    if ("error" in result) {
                        reject("Error code: " + result.errcode.tostring());
                    } else {
                        resolve(result.event);
                    }
                }
            });
        }.bindenv(this));
    }


    function testGetLocation() {

        // TEST WE CAN GET A SINGLE GNSS LOCATION
        return Promise(function(resolve, reject) {
            BG96_GPS.getLocation({
                "onLocation": function(result) {
                    if ("error" in result) {
                        if (result.error == "GPS fix not available") {
                            resolve(result.error);
                        } else {
                            reject(result.error);
                        }
                    } else if ("fix" in result) {
                        resolve(result.fix);
                    }
                },
                "mode": BG96_GNSS_LOCATION_MODE.TWO
            });
        }.bindenv(this));
    }


    function testGetLocationWaitForFix() {

        // TEST WE CAN GET A GNSS LOCATION AND WAIT FOR A FIX
        // IN THIS CASE ('ops.waitFix = true') NO GPS FIX IS NOT AN ERROR
        return Promise(function(resolve, reject) {
            BG96_GPS.getLocation({
                "onLocation": function(result) {
                    if ("error" in result) {
                        // GPS FIX MAY BE CALLED REPEATEDLY -- NOT REALLY A LIB FAIL
                        reject(result.error);
                    } else if ("fix" in result) {
                        resolve(result.fix);
                    }
                },
                "waitFix": true,
                "mode": BG96_GNSS_LOCATION_MODE.TWO
            });
        }.bindenv(this));
    }


    function tearDown() {

        // CHECK DISABLED GNSS IS TRAPPED IN isAssistDataValid() CALLS
        local result = BG96_GPS.isAssistDataValid();
        this.assert(result == true);

        // TEST WE CAN DISABLE GNSS
        result = BG96_GPS.disableGNSS();
        this.assert(result);
    }

}