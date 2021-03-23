/*
 * BG96_GPS library
 * Copyright 2021 Twilio
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

enum BG96_RESET_MODE {
    COLD_START          = 0, //	Delete all assistance data except gpsOneXTRA data. Enforce a cold start after starting GNSS
    HOT_START           = 1, // Do not delete any data. Perform hot start if the conditions are permitted after starting GNSS
    WARM_START          = 2, // Delete some related data. Perform warm start if the conditions are permitted after starting GNSS
    DELETE_DATA         = 3  // Delete the gpsOneXTRA assistance data injected into GNSS engine
}

// Stale location data is often returned immediately after power up
const BG96_GPS_EN_POLLING_TIMEOUT = 3;

/*
 * Library
 */
BG96_GPS <- {

    VERSION   = "0.2.0",

    /*
     * PUBLIC PROPERTIES
     */
    onNotify = null,
    debug = true,

    /*
     * PRIVATE FUNCTIONS
     */
    _locTimer = null,
    _session   = null,
    _minSuppportedImpOS = 43.0,
    _impOSVersion = null,
    _pollTimer = null,

    /*
     * PUBLIC FUNCTIONS
     */
    isGNSSEnabled = function() {
        _checkOS();

        if (_session == null) return false;

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

        // FROM 0.1.8
        // Retain the main notification callback
        if (onEnabled != null) onNotify = onEnabled;

        if (!isGNSSEnabled()) {
            if (_session == null) {
                try {
                    // Open the session to the modem
                    _session = hardware.gnss.open(function(t) {
                        if (t.ready == 1) {
                            enableGNSS(opts);
                        } else {
                            _notify("Session could not be opened", 0);
                        }
                    }.bindenv(this));
                } catch(err) {
                    // Throw caused by modem not yet ready when we open,
                    // so pause a couple of seconds and re-try
                    _notify("Modem not yet ready -- backing off for " + retryTime + "s", 0);
                    imp.wakeup(retryTime, function() {
                        enableGNSS(opts);
                    }.bindenv(this));
                }
                return;
            }

            if (assistData) {
                _session.assist.load(function(t) {
                    if (t.status != 0) {
                        _notify("Assist data not loaded: " + t.message, t.status);
                    } else {
                        // Prep for re-entry into function
                        opts.assistData = null;
                        if (!("useAssist" in opts)) opts.useAssist <- true;
                        enableGNSS(opts);
                    }
                }.bindenv(this), assistData);
                return;
            }

            if (useAssist) {
                // FROM 0.1.5 -- check we have assist data before proceeding
                // This will be the case if 'enableGNSS()' called with 'useAssist' set true,
                // but 'assistData' is null or passed bad data
                local t = _session.assist.read();
                if (t.status == 0) {
                    // There is assist data present, so proceed to enable
                    // NOTE This is best to do after a read()
                    t = _session.assist.enable();
                    if (t.status != 0) {
                        _notify("Could not enable assist", t.status);
                    } else {
                        /*
                            TODO NXTGN issue:
                            session.enable() returns status 509 if called right after session.assist.enable()
                        */
                    }
                } else {
                    _notify("Assist data not present", t.status);
                }
            }

            local resp = _session.enable(gnssMode, posTime, accuracy, numFixes, checkFreq);
            if (resp.status != 0) {
                local status = resp.status.tostring();
                if (status != BG96_AT_ERROR_CODE.GPS_SESSION_IS_ONGOING) {
                    _notify("Error enabling GNSS", resp.status);
                    return;
                }

                // Retry after 'retryTime'
                imp.wakeup(retryTime, function() {
                    enableGNSS(opts);
                }.bindenv(this));
                return;
            }
        }

        _notify("GNSS enabled");
        if (onLocation != null) {
            // If there is no delay returns stale loc on first 2 (1sec) requests
            _cancelPollTimer();
            _pollTimer = imp.wakeup(BG96_GPS_EN_POLLING_TIMEOUT, function() {
                _pollLoc(locMode, checkFreq, onLocation);
            }.bindenv(this));
        }
    },

    // NOTE Cancels _poll location timer if running
    disableGNSS = function() {
        _checkOS();

        // Always cancel location timers
        _cancelLocTimer();
        _cancelPollTimer();

        if (isGNSSEnabled()) {
            local resp = _session.disable();
            if (resp.status != 0) {
                _notify("Could not disable GNSS", resp.status);
                return false;
            }
        }

        // Zap the session
        _session = null;
        return true;
    },

    getLocation = function(opts = {}) {
        _checkOS();

        local poll       = ("poll" in opts) ? opts.poll : false;
        local mode       = ("mode" in opts) ? opts.mode : BG96_GNSS_LOCATION_MODE.ZERO;
        local checkFreq  = ("checkFreq" in opts) ? opts.checkFreq : BG96_GNSS_ON_DEFAULT.GET_LOC_FREQ_SEC;
        local onLocation = ("onLocation" in opts && typeof opts.onLocation == "function") ? opts.onLocation : null;
        local waitFix    = ("waitFix" in opts) ? opts.waitFix : false;

        // Make sure we're enabled
        if (isGNSSEnabled()) {
            if (poll) {
                _pollLoc(mode, checkFreq, onLocation);
            } else {
                _getLoc(mode, function(loc) {
                    if (loc == null) {
                        loc = waitFix ? {"fix" : "GPS fix not yet available"} : {"error" : "GPS fix not available"};
                    }
                    if (onLocation) onLocation(loc);
                });
            }
        } else {
            if (onLocation) onLocation({"error" : "GNSS not enabled"});
        }
    },

    // Is the assist data good?
    isAssistDataValid = function() {
        _checkOS();

        if (_session != null) {
            local t = _session.assist.read();
            local valid = (t.status == 0);
            if (valid) {
                _log("[BG96_GPS] Assist data is valid for " + _getValidTime(t.injecteddatatime) + " minutes");
                _log("[BG96_GPS] Assist data became valid on " + t.injecteddatatime);
            }
            return (valid ? {"time": _getValidTime(t.injecteddatatime), "valid": valid} : {"valid": valid});
        } else {
            return {"error": "GNSS not enabled"};
        }
    },

    // Delete any existing assist data
    deleteAssistData = function(mode = BG96_RESET_MODE.DELETE_DATA) {
        _checkOS();

        if (_session == null) {
            // We have to make a session in order to delete the assist data
            try {
                _session = hardware.gnss.open(function(t) {
                    if (t.ready == 1) _deleteAssist(mode);
                }.bindenv(this));
            } catch(err) {
                _notify("Modem not yet ready -- backing off for " + retryTime + "s", 0);
                imp.wakeup(retryTime, function() {
                    deleteAssistData(mode);
                }.bindenv(this));
            }
        } else {
            // We have a session, but GNSS may be enabled
            if (isGNSSEnabled()) {
                // GNSS enabled, so disable before deleting
                local resp = _session.disable();
                if (resp.status != 0) {
                    _notify("Could not delete assist data", resp.status);
                } else {
                    // GNSS now disabled, so we can proceed with deletion
                    _deleteAssist(mode);
                }
            }
        }
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
        try {
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
        } catch(err) {
            cb({"error":err});
        }
    },

    // Cancels location polling timer
    _cancelLocTimer = function() {
        if (_locTimer != null) {
            imp.cancelwakeup(_locTimer);
            _locTimer = null;
        }
    },

    _cancelPollTimer = function() {
        if (_pollTimer != null) {
            imp.cancelwakeup(_pollTimer);
            _pollTimer = null;
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
    _log = function(msg, isError = false) {
        if (debug && server.isconnected()) {
            if (isError) {
                server.error(msg);
            } else {
                server.log(msg);
            }
        }
    },

    // General notification poster
    _notify = function(msg, code = 999) {
        if (onNotify != null) {
            msg = "[BG96 GPS] " + msg;
            if (code == 999) {
                onNotify({"event": msg});
            } else {
                onNotify({"error": msg, "errcode": code});
            }
        }
    },

    // Check we're running on a correct system
    _checkOS = function() {
        if (_impOSVersion == null) {
            local n = split(imp.getsoftwareversion(), "-");
            _impOSVersion = n[2].tofloat();
        }

        try {
            assert(_impOSVersion >= _minSuppportedImpOS);
        } catch (exp) {
            throw "BG96_GPS 0.1.x requires impOS 43 or above";
        }
    },

    // FROM 0.1.5
    // Get assist data remaining validity period in mins
    // 'uploadDate' is <= now, format: YYYY/MM/DD,hh:mm:ss
    // Returns -99 on error
    _getValidTime = function(uploadDate, now = null) {
        local ps = split(uploadDate, ",");
        if (ps.len() != 2) return -99;
        local ds = split(ps[0], "/");
        local ts = split(ps[1], ":");
        if (now == null) now = date();
        local dd = 0;

        // A valid upload date can't be more than 7 days (10080 mins) ago
        if (now.day < 7 && ds[2].tointeger() > now.day) {
            // Flip into the previous month
            local ms = [31,28,31,30,31,30,31,31,30,31,30,31];
            local n = ms[ds[1].tointeger() - 1];
            if (ds[1].tointeger() == 2 && ((now.year % 4 == 0) && ((now.year % 100 > 0) || (now.year % 400 == 0)))) n += 1;
            dd = now.day - ds[2].tointeger() + n;
        } else {
            dd = now.day - ds[2].tointeger();
        }

        // Return now - uploadDate in minutes
        dd *= 1440;
        local mu = ts[1].tointeger() + 60 * ts[0].tointeger();
        local mn = now.min + 60 * now.hour;
        return dd + mn - mu;
    },

    // FROM 0.1.5
    _deleteAssist = function(mode) {
        local t = _session.assist.reset(mode);
        if (t.status == 0) {
            _notify("Assist data deleted");
        } else {
            _notify("Could not delete assist data", t.status);
        }
    }

}