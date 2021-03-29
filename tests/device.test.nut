class GNSSTestCase extends ImpTestCase {

    function setUp() {

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


    function tearDown() {

        // TEST WE CAN DISABLE GNSS
        local result = BG96_GPS.disableGNSS();
        this.assert(result);

        // CHECK DISABLED GNSS IS TRAPPED IN isAssistDataValid() CALLS
        result = BG96_GPS.isAssistDataValid();
        this.assert(result == false);

        // CHECK DISABLED GNSS IS TRAPPED IN getLocation() CALLS
        return Promise(function(resolve, reject) {
            BG96_GPS.getLocation({
                "onLocation": function(result) {
                    if ("error" in result) {
                        // THIS WHAT WE WANT TO SEE
                        resolve(result.error);
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
                }
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
                "waitFix": true
            });
        }.bindenv(this));
    }


    function testGetLocationNoCallback() {

        // TEST THAT getLocation() CORRECTLY TRAPS NO CALLBACK
        return Promise(function(resolve, reject) {
            BG96_GPS.onNotify = function(data) {
                if ("error" in data && data.error == "No location report callback") {
                    // Correctly trapped
                    resolve();
                } else {
                    reject();
                }
            }.bindenv(this);

            BG96_GPS.onLocation = null;
            BG96_GPS.getLocation();

        }.bindenv(this));
    }


    function testAssistData() {

        // MAKE SURE WE HAVE ASSIST DATA
        if (adb == null) return;
        this.info("Got assist data");

        // TEST WE CAN DISABLE GNSS
        local result = BG96_GPS.disableGNSS();
        this.assert(result);

        // TEST WE CAN LOAD GNSS ASSIST DATA
        return Promise(function(resolve, reject) {
            BG96_GPS.enableGNSS({
                "maxPosTime" : 120,
                "checkFreq" : 60,
                "assistData": adb,
                "onEnabled": function(result) {
                    if ("error" in result) {
                        reject("Error code: " + result.errcode.tostring());
                    } else {
                        resolve("event" in result ? result.event : "???");
                    }
                }
            });
        }.bindenv(this));
    }


    function testGetValidTime() {

        // TEST _getValidTime()
        local testDate = "2021/03/20,16:00:00"
        local result = BG96_GPS._getValidTime(testDate);
        //this.info(result);
        this.assertLess(result, 10080);

        testDate = "2021/03/20,18:00:00"
        result = BG96_GPS._getValidTime(testDate);
        //this.info(result);
        this.assertLess(result, 10080);

        testDate = "2021/03/20,13:00:00"
        result = BG96_GPS._getValidTime(testDate);
        //this.info(result);
        this.assertLess(result, 10080);

        testDate = "2021/03/21,15:43:00"
        result = BG96_GPS._getValidTime(testDate);
        //this.info(result);
        this.assertLess(result, 10080);

        local td = {"month": 1, "day": 2, "min": 57, "hour": 16, "year": 2021}
        testDate = "2021/01/27,15:43:00"
        result = BG96_GPS._getValidTime(testDate, td);
        //this.info(result);
        this.assertLess(result, 10080);
    }

}