#UAA provisioning for alarms app
uaac target <uaac>
uaac token client get admin -s <pwd>
uaac client add alarms-policy-app -s alarms-policy-app-secret \
--scope *.zones.admin acs.attributes.read acs.attributes.write acs.policies.read acs.policies.write predix_acs.zones.alarms.user uaa.resource \
--authorized_grant_types client_credentials implicit password refresh_token \
--authorities acs.policies.read acs.policies.write predix_acs.zones.alarms.user uaa.resource acs.attributes.read acs.attributes.write acs.zones.admin


uaac user add alarms-policy-admin --email alarms-policy-admin@sample.com -p alarms-policy-admin-pwd
uaac member add acs.policies.read alarms-policy-admin
uaac member add acs.policies.write alarms-policy-admin
uaac member add acs.attributes.read alarms-policy-admin
uaac member add acs.attributes.write alarms-policy-admin
uaac member add acs.zones.admin alarms-policy-admin
uaac member add predix_acs.zones.alarms.user alarms-policy-admin
uaac user get alarms-policy-admin


uaac user add alarms-user --email alarms-user@example.com -p alarms-user-pwd
uaac member add predix_acs.zones.alarms.user alarms-user

uaac user add alarms-admin --email alarms-admin@example.com -p alarms-admin-user-pwd
uaac member add predix_acs.zones.alarms.user alarms-admin

uaac client add alarms-app -s alarms-app-secret --authorized_grant_types password --scope "predix_acs.zones.alarms.user"

#client for viewing / updating groups
uaac token owner get cli-client acs-admin-user -s <pwd> -p <pwd>