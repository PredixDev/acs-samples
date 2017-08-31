package com.ge.predix.acs.sample.alarms;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

import com.ge.predix.acs.spring.security.config.AcsClientContext;
import com.ge.predix.acs.spring.security.config.EnvBasedAcsClientConfigurationProvider;

@Primary
@Component
public class SampleAppConfigurationProvider extends EnvBasedAcsClientConfigurationProvider {

    @Autowired
    private SampleAppCloudConfig sampleAppEnv;

    @Override
    public String getAcsPolicyEvaluationClientId(final AcsClientContext acsClientContext) {
        return super.getAcsPolicyEvaluationClientId(acsClientContext);
    }

    @Override
    public String getAcsPolicyEvaluationClientSecret(final AcsClientContext acsClientContext) {
        return super.getAcsPolicyEvaluationClientSecret(acsClientContext);
    }

    @Override
    public String getAcsPolicyEvaluationTokenURL(final AcsClientContext acsClientContext) {
        return this.sampleAppEnv.getUaaIssuerId();
    }

    @Override
    public String getAcsURL(final AcsClientContext acsClientContext) {
        return super.getAcsURL(acsClientContext);
    }

    @Override
    public String getAcsZoneID(final AcsClientContext acsClientContext) {
        return super.getAcsZoneID(acsClientContext);
    }

}
