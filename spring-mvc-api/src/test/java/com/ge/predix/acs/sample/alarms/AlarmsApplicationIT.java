package com.ge.predix.acs.sample.alarms;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.client.OAuth2RestTemplate;
import org.springframework.security.oauth2.common.exceptions.OAuth2Exception;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.testng.AbstractTestNGSpringContextTests;
import org.springframework.web.client.RestTemplate;
import org.testng.Assert;
import org.testng.annotations.Test;

/*
 * Copyright (c) 2015 General Electric Company. All rights reserved.
 *
 * The copyright to the computer software herein is the property of
 * General Electric Company. The software may be used and/or copied only
 * with the written permission of General Electric Company or in accordance
 * with the terms and conditions stipulated in the agreement/contract
 * under which the software has been supplied.
 */

/**
 * Test to validate ACS Sample is functional.
 *
 * @author 212319607
 */
@Test
@ContextConfiguration("classpath:test-spring-context.xml")
public class AlarmsApplicationIT extends AbstractTestNGSpringContextTests {

    @Value("${nonAdminUserName}")
    private String nonAdminUserName;

    @Value("${adminUserName}")
    private String adminUserName;

    @Value("${nonAdminUserPassword}")
    private String nonAdminUserPassword;

    @Value("${adminUserPassword}")
    private String adminUserPassword;

    @Value("${clientId}")
    private String clientId;

    @Value("${clientSecret}")
    private String clientSecret;

    @Autowired
    private OAuth2RestTemplate nonAdminTemplate;

    @Autowired
    private OAuth2RestTemplate adminTemplate;

    @Value("${sampleUrl}")
    private String sampleUrl;

    /**
     * This page is unprotected.
     */
    public void getUnprotectedGreetingPage() {
        Assert.assertTrue(
                new RestTemplate().getForObject(this.sampleUrl + "/greeting", String.class).contains("Hello"));
    }

    /**
     * This page requires authentication, no authorization.
     */
    public void getAboutPage() {
        Assert.assertTrue(this.nonAdminTemplate.getForObject(this.sampleUrl + "/about", String.class)
                .contains("acs-sample"));

    }

    /**
     * This page requires authentication and authorization from ACS. User must have 'operator' role or above to
     * perform HTTP GET call
     */
    public void getAlarmPageWithNonAdminUser() {
        ResponseEntity<String> response = this.nonAdminTemplate.exchange(this.sampleUrl + "/alarm/45",
                HttpMethod.GET, new HttpEntity<>(null, getHeadersWithZone()), String.class);

        Assert.assertTrue(response.getBody().contains("45"));
    }

    /**
     * This is expected to fail , per policy configuration (role-based-policy.json).
     */
    public void deleteAlarmWithNonAdminUser() {
        try {
            this.nonAdminTemplate.exchange(this.sampleUrl + "/alarm/45", HttpMethod.DELETE,
                    new HttpEntity<>(null, getHeadersWithZone()), String.class);
            Assert.fail("Delete Alarm by non-admin user did not throw exception");
        } catch (OAuth2Exception e) {
            // This is expected to fail because no authentication token is sent in the request.
            // Note: e.getHttpErrorCode returns the wrong error code in this case (400).
            Assert.assertTrue(e.toString().contains("403"));
        }
    }

    public void deleteAlarmWithAdminUser() {
        this.adminTemplate.exchange(this.sampleUrl + "/alarm/45", HttpMethod.DELETE,
                new HttpEntity<>(null, getHeadersWithZone()), String.class);
    }

    public void getAlarmWithAdminUser() {
        ResponseEntity<String> response = this.adminTemplate.exchange(this.sampleUrl + "/alarm/45",
                HttpMethod.GET, new HttpEntity<>(null, getHeadersWithZone()), String.class);
        Assert.assertTrue(response.getBody().contains("45"));
    }

    private HttpHeaders getHeadersWithZone() {
        HttpHeaders headers = new HttpHeaders();
        headers.add("Predix-Zone-Id", "1b1580f8-fd8e-4a0f-be45-8896bf239761");
        return headers;
    }
}
