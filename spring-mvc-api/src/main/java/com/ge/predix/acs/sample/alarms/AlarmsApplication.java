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

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.ImportResource;

/**
 * @author 212304931
 */
@ComponentScan
@ImportResource(value = "classpath:alarms-app-context.xml")
@EnableAutoConfiguration
public class AlarmsApplication {

    private String applicationId;

    public String getApplicationId() {
        return this.applicationId;
    }

    public void setApplicationId(final String applicationId) {
        this.applicationId = applicationId;
    }

    public static void main(final String[] args) {
        SpringApplication.run(AlarmsApplication.class, args);
    }
}
