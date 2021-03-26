class GNSSTestCase4 extends ImpTestCase {

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

    function testGetLocation() {

        // TEST WE CAN GET A SINGLE GNSS LOCATION WITHOUT ASSIST DATA
        return Promise(function(resolve, reject) {
            BG96_GPS.getLocation({
                "waitFix" : true,
                "onLocation": function(result) {
                    if ("error" in result) {
                        reject(result.error);
                    } else if ("fix" in result) {
                        if (result.fix != "GPS fix not yet available") resolve(result.fix);
                    }
                }
            });
        }.bindenv(this));
    }


    function tearDown() {

        // TEST WE CAN DISABLE GNSS
        local result = BG96_GPS.disableGNSS();
        this.assert(result);
    }

}