class GNSSTestCase extends ImpTestCase {

    function testGetValidTime() {

        local testDate = "2021/02/14,16:00:00"
        local result = BG96_GPS._getValidTime(testDate);
        this.info(result);
        this.assertLess(result, 10080);

        testDate = "2021/02/08,18:00:00"
        result = BG96_GPS._getValidTime(testDate);
        this.info(result);
        this.assertLess(result, 10080);

        testDate = "2021/02/15,13:00:00"
        result = BG96_GPS._getValidTime(testDate);
        this.info(result);
        this.assertLess(result, 10080);

        testDate = "2021/02/08,15:43:00"
        result = BG96_GPS._getValidTime(testDate);
        this.info(result);
        this.assertLess(result, 10080);

        local td = {"day": 2, "min": 57, "hour": 16, "year": 2021}
        testDate = "2021/01/27,15:43:00"
        result = BG96_GPS._getValidTime(testDate, td);
        this.info(result);
        this.assertLess(result, 10080);

    }

}