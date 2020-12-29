/*
 * BG96_GPS library
 * Copyright 2020 Twilio
 *
 * MIT License
 * SPDX-License-Identifier: MIT
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:

 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.

 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
 * EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
 * OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */


/*
 * Enums
 */
enum BG96_AT_ERROR_CODE {
    FILE_INVALID_INPUT              = "400",
    FILE_SIZE_MISMATCH              = "401",
    FILE_READ_ZERO_BYTE             = "402",
    FILE_DRIVE_FULL                 = "403",
    FILE_NOT_FOUND                  = "405",
    FILE_INVALID_NAME               = "406",
    FILE_ALREADY_EXISTS             = "407",
    FILE_WRITE_FAIL                 = "409",
    FILE_OPEN_FAIL                  = "410",
    FILE_READ_FAIL                  = "411",
    FILE_MAX_OPEN_FILES             = "413",
    FILE_READ_ONLY                  = "414",
    FILE_INVALID_DESCRIPTOR         = "416",
    FILE_LIST_FAIL                  = "417",
    FILE_DELETE_FAIL                = "418",
    FILE_GET_DISK_INFO_FAIL         = "419",
    FILE_NO_SPACE                   = "420",
    FILE_TIMEOUT                    = "421",
    FILE_TOO_LARGE                  = "423",
    FILE_INVALID_PARAM              = "425",
    FILE_ALREADY_OPEN               = "426",
    GPS_INVALID_PARAM               = "501",
    GPS_OPERATION_NOT_SUPPORTED     = "502",
    GPS_GNSS_SUBSYSTEM_BUSY         = "503",
    GPS_SESSION_IS_ONGOING          = "504",
    GPS_SESSION_NOT_ACTIVE          = "505",
    GPS_OPERATION_TIMEOUT           = "506",
    GPS_FUNCTION_NOT_ENABLED        = "507",
    GPS_TIME_INFO_ERROR             = "508",
    GPS_XTRA_NOT_ENABLED            = "509",
    GPS_VALIDITY_TIME_OUT_OF_RANGE  = "512",
    GPS_INTERNAL_RESOURCE_ERROR     = "513",
    GPS_GNSS_LOCKED                 = "514",
    GPS_END_BY_E911                 = "515",
    GPS_NO_FIX_NOW                  = "516",
    GPS_GEO_FENCE_ID_DOES_NOT_EXIST = "517",
    GPS_UNKNOWN_ERROR               = "549"
}

enum BG96_GNSS_ON_DEFAULT {
    MODE                = 1,    // Stand Alone is the only mode supported (1)
    MAX_POS_TIME_SEC    = 30,   // Sec max pos time (30)
    FIX_ACCURACY_METERS = 50,   // Fix accuracy in meters (50)
    NUM_FIX_CHECKS      = 0,    // Num of checks after fix before powering down GPS (0 - continuous)
    GET_LOC_FREQ_SEC    = 1,    // Check every x sec (1)
    RETRY_TIME_SEC      = 1,    // Time to wait for modem to power up
}

enum BG96_GNSS_LOCATION_MODE {
    ZERO,   // <latitude>,<longitude> format: ddmm.mmmm N/S,dddmm.mmmm E/W
    ONE,    // <latitude>,<longitude> format: ddmm.mmmmmm,N/S,dddmm.mmmmmm,E/W
    TWO     // <latitude>,<longitude> format: (-)dd.ddddd,(-)ddd.ddddd
}

// Stale location data is often returned immediately after power up
const BG96_GPS_EN_POLLING_TIMEOUT = 3;

/*
 * Library
 */
BG96_GPS <- {

    VERSION   = "0.1.0",

    _debug    = false,
    _locTimer = null,
    _session   = null,
    _minSuppportedImpOS = 43.0,
    _impOSVersion = null,

    /*
     * PUBLIC FUNCTIONS
     */

    isGNSSEnabled = function() {
        _checkOS();

        if (_session == null) {
            return false;
        }
        try {
            local resp = _session.getstate();
            return (resp.state == 1);
        } catch(e) {
            _log("[BG96_GPS] " + e);
        }
    },

    enableGNSS = function(opts = {}) {
        _checkOS();
        local gnssMode   = ("gnssMode" in opts)   ? opts.gnssMode   : BG96_GNSS_ON_DEFAULT.MODE;
        local posTime    = ("maxPosTime" in opts) ? opts.maxPosTime : BG96_GNSS_ON_DEFAULT.MAX_POS_TIME_SEC;
        local accuracy   = ("accuracy" in opts)   ? opts.accuracy   : BG96_GNSS_ON_DEFAULT.FIX_ACCURACY_METERS;
        local numFixes   = ("numFixes" in opts)   ? opts.numFixes   : BG96_GNSS_ON_DEFAULT.NUM_FIX_CHECKS;
        local checkFreq  = ("checkFreq" in opts)  ? opts.checkFreq  : BG96_GNSS_ON_DEFAULT.GET_LOC_FREQ_SEC;
        local retryTime  = ("retryTime" in opts)  ? opts.retryTime  : BG96_GNSS_ON_DEFAULT.RETRY_TIME_SEC;
        local locMode    = ("locMode" in opts)    ? opts.locMode    : BG96_GNSS_LOCATION_MODE.TWO;
        local onEnabled  = ("onEnabled" in opts && typeof opts.onEnabled == "function")   ? opts.onEnabled  : null;
        local onLocation = ("onLocation" in opts && typeof opts.onLocation == "function") ? opts.onLocation : null;
        local assistData = ("assistData" in opts) ? opts.assistData : null;
        local useAssist  = ("useAssist" in opts) ? opts.useAssist : false;

        if (!isGNSSEnabled()) {
            if (_session == null) {
                _session = hardware.gnss.open(function(t) {
                    _log("[BG96_GPS] Session readiness now " + t.ready);
                    if (t.ready == 1) enableGNSS(opts);
                }.bindenv(this));
                return;
            }

            if (assistData) {
                _session.assist.load(function(t) {
                    _log("[BG96_GPS] Assist data loaded " + t.status);
                    if ("restart" in t) _log("[BG96_GPS] Restart required = " + t.restart);
                    local t2 = _session.assist.read();
                    _log("[BG96_GPS] xtradatadurtime " + t2.xtradatadurtime);
                    _log("[BG96_GPS] injecteddatatime " + t2.injecteddatatime);
                    opts.assistData = null;
                    if (!"useAssist" in opts) opts.useAssist <- true;
                    enableGNSS(opts);
                }.bindenv(this), assistData);
                return;
            }

            if (useAssist) {
                local t = _session.assist.enable(); // use impOS time
                _log("[BG96_GPS] Assist enable " + t.status);
            }

            local resp = _session.enable(gnssMode, posTime, accuracy, numFixes, checkFreq);

            if (resp.status != 0) {
                local stratus = resp.status.tostring();
                if (stratus != BG96_AT_ERROR_CODE.GPS_SESSION_IS_ONGOING) {
                    local err = "[BG96_GPS] Error enabling GNSS: " + resp.status;
                    _log(err);
                    if (onEnabled != null) onEnabled(err);
                    return;
                }
                imp.wakeup(retryTime, function() {
                    enableGNSS(opts);
                }.bindenv(this))
            } else {
                if (onEnabled != null) onEnabled(null);
                if (onLocation != null) {
                    // If there is no delay returns stale loc on first 2 (1sec) requests
                    imp.wakeup(BG96_GPS_EN_POLLING_TIMEOUT, function() {
                        _pollLoc(locMode, checkFreq, onLocation);
                    }.bindenv(this));
                }
            }
        } else {
            if (onEnabled != null) onEnabled(null);
            if (onLocation != null) {
                imp.wakeup(BG96_GPS_EN_POLLING_TIMEOUT, function() {
                    _pollLoc(locMode, checkFreq, onLocation);
                }.bindenv(this));
            }
        }
    },

    // NOTE Cancels _poll location timer if running
    disableGNSS = function() {
        _checkOS();

        // Always cancel location timer
        _cancelLocTimer();

        if (isGNSSEnabled()) {
            local resp = _session.disable();
            if (resp.status != 0) {
                _log("[BG96_GPS] Error disabling GNSS: " + resp.error);
                return false;
            }
        }

        _session = null;
        return true;
    },

    getLocation = function(opts = {}) {
        _checkOS();

        local poll       = ("poll" in opts) ? opts.poll : false;
        local mode       = ("mode" in opts) ? opts.mode : BG96_GNSS_LOCATION_MODE.ZERO;
        local checkFreq  = ("checkFreq" in opts) ? opts.checkFreq : BG96_GNSS_ON_DEFAULT.GET_LOC_FREQ_SEC;
        local onLocation = ("onLocation" in opts && typeof opts.onLocation == "function") ? opts.onLocation : null;

        // If we have no callback just return an error
        if (onLocation == null) {
            return { "error" : "onLocation callback required" };
        }

        if (poll) {
            _pollLoc(mode, checkFreq, onLocation);
        } else {
            _getLoc(mode, function(loc) {
                if (loc == null) loc = { "error" : "GPS fix not available" };
                onLocation(loc);
            });
        }
    },

    // Enable or disable debug logging
    enableDebugLogging = function(enable) {
        _debug = enable;
    },

    /*
     * PRIVATE FUNCTIONS -- DO NOT CALL DIRECTLY
     */

    // Loop that polls for location, if location data or error (excluding no fix available) is received it is
    // passed to the onLoc callback
    _pollLoc = function(mode, checkFreq, onLoc) {
        // Only allow one schedule timer at a time
        _cancelLocTimer();

        // Schedule next location check
        _locTimer = imp.wakeup(checkFreq, function() {
            _pollLoc(mode, checkFreq, onLoc);
        }.bindenv(this));

        // Fetch and process location
        // Returns `null` if GPS error is no fix now, otherwise returns table with keys fix or error
        _getLoc(mode, function(loc) {
            if (loc != null) {
                // Pass error or location fix to main application
                imp.wakeup(0, function() { onLoc(loc); }.bindenv(this));
            }
        });
    },

    // Sends AT command to get location, mode parameter sets the data lat/lng data format
    // Calls back with null if no fix is available or the response as a table that may contain slots:
        // error (string): The error encountered
        // fix (table/string): response data string if location parsing failed otherwise a table with
        // slots: cog, alt, fixType, time, numSats, lat, lon, spkm, spkn, utc, data, hdop
    _getLoc = function(mode, cb) {
        _session.readposition(function(resp) {
            local data = {};
            if (resp.status != 0) {
                // Look for expected errors
                local errorCode = resp.status.tostring();
                switch (errorCode) {
                    case BG96_AT_ERROR_CODE.GPS_NO_FIX_NOW:
                        _log("[BG96_GPS] GPS fix not available");
                        return cb(null);
                    case BG96_AT_ERROR_CODE.GPS_SESSION_NOT_ACTIVE:
                        _log("[BG96_GPS] GPS not enabled.");
                        return cb(data.error <- "GPS not enabled");
                    default:
                        _log("[BG96_GPS] GPS location request failed with error: " + errorCode);
                        return cb(data.error <- "AT error code: " + errorCode);
                }
            }

            if (resp.status == 0 && "quectel" in resp) {
                data.fix <- _parseLocData(resp.quectel, mode);
            }

            cb(data);
        }.bindenv(this), mode);
    },

    // Cancels location polling timer
    _cancelLocTimer = function() {
        if (_locTimer != null) {
            imp.cancelwakeup(_locTimer);
            _locTimer = null;
        }
    },

    // Format GPS timestamp
    _formatTimeStamp = function(d, utc) {
        // Input d: DDMMYY, utc HHMMSS.S
        // Formatted result: YYYY-MM-DD HH:MM:SS.SZ
        return format("20%s-%s-%s %s:%s:%sZ", d.slice(4),
                                              d.slice(2, 4),
                                              d.slice(0, 2),
                                              utc.slice(0, 2),
                                              utc.slice(2, 4),
                                              utc.slice(4));
    },

    // Parses location data into table based on mode
    _parseLocData = function(parsed, mode) {
        _log("[BG96_GPS] Parsing location data");
        try {
            switch(mode) {
                case BG96_GNSS_LOCATION_MODE.ZERO:
                    // 190629.0,3723.7238N,12206.1395W,1.0,16.0,2,188.18,0.0,0.0,031219,09
                case BG96_GNSS_LOCATION_MODE.TWO:
                    // 190629.0,37.39540,-122.10232,1.0,16.0,2,188.18,0.0,0.0,031219,09
                case BG96_GNSS_LOCATION_MODE.ONE:
                    // 190629.0,3723.723831,N,12206.139526,W,1.0,16.0,2,188.18,0.0,0.0,031219,09
                     return {
                        "utc"     : parsed.utc,
                        "lat"     : parsed.latitude,
                        "lon"     : parsed.longitude,
                        "hdop"    : parsed.hdop,
                        "alt"     : parsed.altitude,
                        "fixType" : parsed.fix,
                        "cog"     : parsed.cog,
                        "spkm"    : parsed.spkm,
                        "spkn"    : parsed.spkn,
                        "date"    : parsed.date,
                        "numSats" : parsed.nsat,
                        "time"    : _formatTimeStamp(parsed.date, parsed.utc),
                    };
                default:
                    throw "Unknown mode";
            }
        } catch(ex) {
            _log("[BG96_GPS] Error parsing GPS data " + ex);
            return parsed;
        }
    },

    // Creates a log if device is online and debug flag is set to true
    _log = function(msg) {
        if (_debug && server.isconnected()) server.log(msg);
    }

    // Check we're running on a correct system
    _checkOS = function() {
        if (_impOSVersion == null) {
            local n = split(imp.getsoftwareversion(), "-");
            _impOSVersion = n[2].tofloat();
        }

        try {
            assert(_impOSVersion >= _minSuppportedImpOS);
        } catch (exp) {
            throw "BG96_GPS 0.1.0 requires impOS 43 or above";
        }
    }
}