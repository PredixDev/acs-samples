/*
 * Copyright (c) 2015 General Electric Company. All rights reserved.
 *
 * The copyright to the computer software herein is the property of
 * General Electric Company. The software may be used and/or copied only
 * with the written permission of General Electric Company or in accordance
 * with the terms and conditions stipulated in the agreement/contract
 * under which the software has been supplied.
 */

package com.ge.predix.acs.sample.alarms;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AlarmsController {
    private static final Logger LOGGER = LoggerFactory.getLogger(AlarmsController.class);

    @RequestMapping(value = "/greeting", method = RequestMethod.GET)
    public String greeting() {
        return "Hello !!!\n";
    }

    @RequestMapping(value = "/alarm/{alarmId}", method = RequestMethod.GET)
    public Alarm getAlarm(@PathVariable("alarmId") final String alarmId) {
        LOGGER.info("getAlarm invoked for id : " + alarmId);

        return new Alarm(alarmId);
    }

    @RequestMapping(value = "/about", method = RequestMethod.GET)
    public String about() {
        return "acs-sample version 2.0 !!!\n";
    }

    @RequestMapping(value = "/alarm/{alarmId}", method = RequestMethod.DELETE)
    public void deleteAlarm() {
        // do nothing
    }

}
