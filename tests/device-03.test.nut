class GNSSTestCase3 extends ImpTestCase {

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


    function testDeleteAssistData() {

        // TEST DELETE ASSIST DATA WITH MODE 3 (DEFAULT)
        return Promise(function(resolve, reject) {
            // Set the notification handler
            BG96_GPS.onNotify = function(data) {
                if ("event" in data && data.event == "Assist data deleted") {
                    resolve(data.event);
                } else {
                    reject("error" in data ? (data.error + ", code: " + data.errcode) : "delete assist error" );
                }
            }.bindenv(this);

            // Delete assist data
            BG96_GPS.deleteAssistData();

        }.bindenv(this));
    }


    function tearDown() {

        // CONFIRM DATA IS INVALID
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