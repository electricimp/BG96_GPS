class GNSSTestCase extends ImpTestCase {

    function setUp() {

        // Enable GNSS
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
                        reject(result.error + ", code: " + result.errcode.tostring());
                    } else {
                        resolve("event" in result ? result.event : "???");
                    }
                }
            });
        }.bindenv(this));
    }


   function testGetValidTime() {

        // Valid results should come in at less than 10080 minutes

        // Set 'now' for consistent testing: 23/02/2021,15:57:00
        local nowTime = {"year": 2021, "month": 1, "day": 23, "hour": 15, "min": 57};

        // Ten days ago -- data invalid
        local testDate = "2021/02/13,15:00:00"
        local result = BG96_GPS._getValidTime(testDate, nowTime);
        //this.info(result);
        this.assertEqual(result, -1);

        // 4 hrs, 45 mins ago -- data valid
        local testDate = "2021/02/23,11:12:00"
        local result = BG96_GPS._getValidTime(testDate, nowTime);
        //this.info(result);
        this.assert(result < 10080 && result != -1);

        // Ancient time
        testDate = "1980/01/01,00:00:00"
        result = BG96_GPS._getValidTime(testDate, nowTime);
        //this.info(result);
        this.assertEqual(result, -1);

        // Future time
        testDate = "2021/05/15,13:00:00"
        result = BG96_GPS._getValidTime(testDate, nowTime);
        //this.info(result);
        this.assertEqual(result, -1);

        // Just in the zone
        testDate = "2021/02/16,16:01:00"
        result = BG96_GPS._getValidTime(testDate, nowTime);
        //this.info(result);
        this.assert(result < 10080 && result != -1);

        // Cross-month valid
        nowTime = {"year": 2021, "month": 4, "day": 4, "hour": 11, "min": 57};
        testDate = "2021/04/30,12:12:00"
        result = BG96_GPS._getValidTime(testDate, nowTime);
        //this.info(result);
        this.assert(result < 10080 && result != -1);

        // Cross-month valid -- just
        nowTime = {"year": 2021, "month": 4, "day": 4, "hour": 11, "min": 57};
        testDate = "2021/04/27,12:12:00"
        result = BG96_GPS._getValidTime(testDate, nowTime);
        //this.info(result);
        this.assert(result < 10080 && result != -1);

        // Cross-month invalid
        nowTime = {"year": 2021, "month": 4, "day": 4, "hour": 11, "min": 57};
        testDate = "2021/04/27,09:22:00"
        result = BG96_GPS._getValidTime(testDate, nowTime);
        //this.info(result);
        this.assertEqual(result, -1);
    }


    function tearDown() {

        // TEST WE CAN DISABLE GNSS
        local result = BG96_GPS.disableGNSS();
        this.assert(result);
    }
}