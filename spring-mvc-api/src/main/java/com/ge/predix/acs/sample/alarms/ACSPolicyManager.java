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

import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.HashSet;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.security.oauth2.client.OAuth2RestTemplate;
import org.springframework.security.oauth2.client.token.grant.password.ResourceOwnerPasswordResourceDetails;
import org.springframework.web.client.RestClientException;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ge.predix.acs.model.Attribute;
import com.ge.predix.acs.model.PolicySet;
import com.ge.predix.acs.rest.BaseSubject;

/**
 * 
 * Creates the following items which are necessary to run the sample successfully.
 * 
 * 1) the ACS policy set
 * 2) the subject attributes
 * 
 */
public class ACSPolicyManager {

    private static final Logger LOGGER = LoggerFactory.getLogger(ACSPolicyManager.class);

    @Autowired
    @Qualifier("acsPolicyAdmin")
    private OAuth2RestTemplate acsPolicyAdminTemplate;

    @Autowired
    private SampleAppCloudConfig sampleAppEnv;

    @Value("${nonAdminUserName}")
    private String nonAdminUserName;

    @Value("${adminUserName}")
    private String adminUserName;

    @Value("${clientId}")
    private String clientId;

    @Value("${clientSecret}")
    private String clientSecret;

    private static final String POLICY_SET_URI = "/policy-set/";
    private static final String V1 = "/v1";

    private String policySetId;

    private String getAcsUri() {
        return this.sampleAppEnv.getAcsUri();
    }

    private String getUaaIssuerId() {
        return this.sampleAppEnv.getUaaIssuerId();
    }

    private String getAcsHeaderValue() {
        return this.sampleAppEnv.getAcsHeaderValue();
    }

    public void configureACS() throws RestClientException, URISyntaxException {
        try {
            setTestPolicy();
        } catch (Exception e) {
            LOGGER.error("Failed to configure the policy src/main/resources/role-based-policy.json", e);
        }
        // Assign roles used by policy to admin and non-admin user
        assignRoleToSubject(this.nonAdminUserName, "operator");
        assignRoleToSubject(this.adminUserName, "admin");
    }

    private void setTestPolicy() throws Exception {

        byte[] policyContent = new byte[2 * 1024];
        InputStream policy = getClass().getClassLoader().getResourceAsStream("role-based-policy.json");
        try {
            policy.read(policyContent);
        } finally {
            policy.close();
        }

        PolicySet policySet = new ObjectMapper().readValue(policyContent, PolicySet.class);
        this.policySetId = policySet.getName();
        this.acsPolicyAdminTemplate.put(new URI(getAcsUri() + V1 + POLICY_SET_URI + this.policySetId),
                new HttpEntity<>(policySet, getHeadersWithZone()));
    }

    private HttpHeaders getHeadersWithZone() {
        HttpHeaders headers = new HttpHeaders();
        headers.add("Predix-Zone-Id", getAcsHeaderValue());
        return headers;
    }

    private BaseSubject assignRoleToSubject(final String subjectId, final String roleName)
            throws RestClientException, URISyntaxException {
        BaseSubject subject = new BaseSubject();
        subject.setSubjectIdentifier(subjectId);
        String subjectUri = "/subject/" + subjectId;

        Attribute role = new Attribute();
        role.setIssuer("https://acs.attributes.int");
        role.setName("role");
        role.setValue(roleName);
        Set<Attribute> attributes = new HashSet<>();
        attributes.add(role);
        subject.setAttributes(attributes);

        this.acsPolicyAdminTemplate.put(new URI(getAcsUri() + V1 + subjectUri),
                new HttpEntity<>(subject, getHeadersWithZone()));

        return subject;
    }

    public OAuth2RestTemplate getAcsPolicyAdminTemplate() {
        if (this.acsPolicyAdminTemplate == null) {
            ResourceOwnerPasswordResourceDetails resource = new ResourceOwnerPasswordResourceDetails();
            resource.setAccessTokenUri(getUaaIssuerId());
            resource.setClientId(this.clientId);
            resource.setClientSecret(this.clientSecret);
            this.acsPolicyAdminTemplate = new OAuth2RestTemplate(resource);
        }

        return this.acsPolicyAdminTemplate;
    }

    public void cleanupACSConfiguration() {
        this.acsPolicyAdminTemplate.exchange(getAcsUri() + V1 + POLICY_SET_URI + this.policySetId, HttpMethod.DELETE,
                new HttpEntity<>(getHeadersWithZone()), String.class);
        this.acsPolicyAdminTemplate.exchange(getAcsUri() + V1 + "/subject/" + this.nonAdminUserName, HttpMethod.DELETE,
                new HttpEntity<>(getHeadersWithZone()), String.class);
        this.acsPolicyAdminTemplate.exchange(getAcsUri() + V1 + "/subject/" + this.adminUserName, HttpMethod.DELETE,
                new HttpEntity<>(getHeadersWithZone()), String.class);
        this.acsPolicyAdminTemplate.delete(getAcsUri() + V1 + "/zone/alarms");
    }

}
