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

import java.util.Map;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.EnvironmentAware;
import org.springframework.core.env.AbstractEnvironment;
import org.springframework.core.env.Environment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.PropertySource;
import org.springframework.stereotype.Component;

/**
 * ACS configuration component for ACS service URI.
 *
 * @author 212304931
 */
@Component("sampleAppCloudConfig")
@SuppressWarnings("nls")
class SampleAppCloudConfig implements EnvironmentAware {

    private static final Logger LOGGER = LoggerFactory.getLogger(SampleAppCloudConfig.class);

    private String uaaUri;

    private String uaaIssuerId;

    private String acsUri;

    private String acsHeaderValue;

    @Value("${uaaServiceInstanceName}")
    private String uaaServiceInstanceName;

    @Value("${acsServiceInstanceName}")
    private String acsServiceInstanceName;

    @Override
    public void setEnvironment(final Environment environment) {
        if (null == getVcapPropertySource(environment)) {
            LOGGER.info("Could not detect VCAP_SERVICES. Are you running this locally?");
        }

        String uaaVcapPropertyUriKey = String.format("vcap.services.%s.credentials.uri", this.uaaServiceInstanceName);
        this.uaaUri = getProperty(environment, uaaVcapPropertyUriKey, "http://localhost:8080/uaa");

        String uaaVcapPropertyIssuerIdKey = String.format("vcap.services.%s.credentials.issuerId",
                this.uaaServiceInstanceName);
        this.uaaIssuerId = getProperty(environment, uaaVcapPropertyIssuerIdKey,
                "http://localhost:8080/uaa/oauth/token");

        String acsVcapPropertyUriKey = String.format("vcap.services.%s.credentials.uri", this.acsServiceInstanceName);
        this.acsUri = getProperty(environment, acsVcapPropertyUriKey, "http://localhost:8181");

        String acsVcapPropertyHeaderKey = String.format("vcap.services.%s.credentials.zone.http-header-value",
                this.acsServiceInstanceName);
        this.acsHeaderValue = getProperty(environment, acsVcapPropertyHeaderKey, "test-zone");
    }

    public String getUaaUri() {
        return this.uaaUri;
    }

    public String getUaaIssuerId() {
        return this.uaaIssuerId;
    }

    public String getAcsUri() {
        return this.acsUri;
    }

    public String getAcsHeaderValue() {
        return this.acsHeaderValue;
    }

    private String getProperty(final Environment environment, final String key, final String defaultValue) {
        String value = environment.getProperty(key);

        if (StringUtils.isEmpty(value)) {
            value = defaultValue;
            logNoVcapProperty(environment, key, value);

            // If there is no vcap property and no default value throw an exception.
            if (null == value) {
                throw new IllegalStateException(String.format(
                        "Could not find property '%s' in VCAP_SERVICES and no default value was specified.", key));
            }
        } else {
            LOGGER.info(String.format("Found VCAP_SERVICES property for '%s' for your ACS service instance %s", key,
                    value));
        }
        return value;
    }

    private void logNoVcapProperty(final Environment environment, final String key, final String value) {
        if (LOGGER.isDebugEnabled()) {
            PropertySource<?> propertySource = getVcapPropertySource(environment);
            String debugMessage;
            if (null == propertySource) {
                debugMessage = String.format("Could not detect VCAP_SERVICES."
                        + "Using the user provided value '%s' for property '%s' instead.", value, key);
            } else {
                debugMessage = String.format(
                        "Could not find the '%s' property in VCAP_SERVICES '%s'."
                                + "Using the user provided value '%s' instead.",
                        key, getVcapMap(propertySource), value);
            }
            LOGGER.debug(debugMessage);
        } else {
            String message = String.format("Could not find the '%s' property in VCAP_SERVICES."
                    + "Using the user provided value '%s' instead.", key, value);
            LOGGER.info(message);
        }
    }

    private Map<String, Object> getVcapMap(final PropertySource<?> source) {
        MapPropertySource mapSource = (MapPropertySource) source;
        return mapSource.getSource();
    }

    private PropertySource<?> getVcapPropertySource(final Environment environment) {
        AbstractEnvironment absEnv = (AbstractEnvironment) environment;
        PropertySource<?> source = absEnv.getPropertySources().get("vcap");
        return source;
    }
}
