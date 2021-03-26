class GNSSTestCase6 extends ImpTestCase {

    function setUp() {

        // MAKE SURE WE HAVE ASSIST DATA
        if (adb == null) return;
        local result = BG96_GPS.disableGNSS();

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


    function testDeleteAssistData() {

        // TEST DELETE ASSIST DATA WITH MODE 0
        return Promise(function(resolve, reject) {
            // Set the notification handler
            BG96_GPS.onNotify = function(data) {
                if ("event" in data && data.event == "Assist data deleted") {
                    resolve("Assist data deleted");
                } else {
                    reject("error" in data ? (data.error + ", code: " + data.errcode) : "delete assist error" );
                }
            }.bindenv(this);

            // Delete assist data
            BG96_GPS.deleteAssistData(BG96_RESET_MODE.COLD_START);

        }.bindenv(this));
    }


    function tearDown() {

        return Promise(function(resolve, reject) {
            // Set the notification handler
            BG96_GPS.onNotify = function(resp) {
                local result = BG96_GPS.disableGNSS();
                if ("error" in resp) {
                    reject(resp.error + ", code: " + resp.errcode);
                } else if ("data" in resp) {
                    if (resp.data.valid) {
                        reject(resp.event);
                    } else {
                        resolve(resp.event);
                    }
                } else {
                    reject("Bad notification");
                }
            }.bindenv(this);

            // Delete assist data
            local result = BG96_GPS.isAssistDataValid();

        }.bindenv(this));

    }

}