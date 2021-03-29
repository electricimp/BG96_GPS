adb <- null;

device.on("get.assist.data", function(dummy) {
    // Set up an HTTP request to get the assist data
    local assistDataURL = "http://xtrapath4.izatcloud.net/xtra3grc.bin";
    local request = http.get(assistDataURL);

    // Send the request asynchronously
    request.sendasync(function(response) {
        // We've got a response -- it is good?
        if (response.statuscode == 200) {
            // Yes! Relay the data to the device as a blob
            adb = blob(response.body.len());
            adb.writestring(response.body);
            device.send("set.assist.data", adb);
        } else {
            // No!
            server.error("Could not get assist data (Error " + response.statuscode + ")");
        }
    });
})