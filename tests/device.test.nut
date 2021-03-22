class GNSSTestCase extends ImpTestCase {

    function setUp() {

        return Promise(function(resolve, reject) {
            BG96_GPS.enableGNSS({
                "maxPosTime" : 120,
                "checkFreq" : 60,
                "onEnabled": function(result) {
                    if (result != null) {
                        reject();
                    } else {
                        resolve();
                    }
                }
            });
        }.bindenv(this));
    }

    function tearDown() {

        //local result = BG96_GPS.disableGNSS();
        //this.assert(result);

        return Promise(function(resolve, reject) {
            BG96_GPS.deleteAssistData(3, function(result) {
                if ("error" in result) {
                    reject();
                } else {
                    resolve();
                }
            });
        }.bindenv(this));

    }

    function testGetLocation() {

        // Correctly reject attempts w/o an onLocation callback
        local result = BG96_GPS.getLocation();
        this.assert(result.error != null);

        // Async call check
        return Promise(function(resolve, reject) {
            BG96_GPS.getLocation({
                "onLocation": function(result) {
                    if ("fix" in result) {
                        resolve();
                    }
                }
            });
        }.bindenv(this));
    }

    function testAssistData() {

        if (adb == null) return;
        this.info("Got assist data");

        local result = BG96_GPS.disableGNSS();
        this.assert(result);

        return Promise(function(resolve, reject) {
            BG96_GPS.enableGNSS({
                "maxPosTime" : 120,
                "checkFreq" : 60,
                "assistData": adb,
                "onEnabled": function(result) {
                    if (result != null) {
                        reject();
                    } else {
                        resolve();
                    }
                }
            });
        }.bindenv(this));
    }

    function testGetValidTime() {

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