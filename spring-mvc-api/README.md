# ACS Sample Application

## Overview

This sample application shows how to enforce authentication and/or authorization for certain resources. In the context of this application, *authentication* means validating the Bearer JWT token passed in the Authorization header while *authorization* means using the ACS service to determine if a given *subject* can access a given *resource* by doing a specific *action*.

Specifically, the sample application demonstrates how to authorize access to Spring MVC RESTful endpoints using ACS by:

* Configuring attributes in ACS for users of the sample application
* Configuring policies in ACS for access control decisions
* Configuring Spring Security to delegate access decisions to ACS
* Invoking the protected application endpoints to demonstrate policy enforcement based on ACS

## Technical details

### Services involved

* **UAA:** Authenticates clients and users of the sample application

### Clients involved

Refer to [`application.properties`](src/main/resources/application.properties) for descriptions of the OAuth 2 clients and users involved in the sample application

### Resources involved

* The `/greeting` endpoint: An unprotected resource
* The `/alarm/{id}` endpoint: A resource protected by ACS as follows:
  * The `GET` HTTP method is supported for all users
  * The `DELETE` HTTP method is only allowed for users with the `admin` role, as configured in ACS (see [`the configureACS() method in ACSPolicyManager.java`](src/main/java/com/ge/predix/acs/sample/alarms/ACSPolicyManager.java))

The sample application configures ACS to protect the `/alarm/{id}` resource by:

* Creating a policy set from the content in the [`role-based-policy.json`](src/main/resources/role-based-policy.json) file.  This policy set defines 2 policies to control access to resources based on the `operator` and `admin` roles.
* Assigning the `operator` role to the user named `alarms-user`.
* Assigning the `admin` role to the user named `alarms-admin`.

# Running the sample application

## Setting proxies *(optional)*

If you're behind a proxy, set the proxy options used by JVMs:

```bash
$ export http_proxy='<http_proxy_host>:<http_proxy_port>'
$ export https_proxy='<https_proxy_host>:<https_proxy_port>'
$ export no_proxy='<comma_separated_hosts>'
$ export JVM_PROXY_OPTS="-Dhttp.proxyHost='<http_proxy_host>' -Dhttp.proxyPort='<http_proxy_port>' -Dhttps.proxyHost='<https_proxy_host>' -Dhttps.proxyPort='<https_proxy_port>' -Dhttp.nonProxyHosts='<pipe_separated_hosts>'"
```

For example:

```bash
$ export http_proxy='proxy.company.com:80'
$ export https_proxy='proxy.company.com:80'
$ export no_proxy='localhost,127.0.0.1,*.company.com'
$ export JVM_PROXY_OPTS="-Dhttp.proxyHost='proxy.company.com' -Dhttp.proxyPort='80' -Dhttps.proxyHost='proxy.company.com' -Dhttps.proxyPort='80' -Dhttp.nonProxyHosts='localhost|127.0.0.1|*.company.com'"
```

## Provisioning UAA and ACS service instances

The sample application requires binding to instances of the UAA and ACS services. They can be provisioned as follows:

1. Login to your Cloud Foundry organization and space.

  For example:

  ```bash
  $ cf login -a https://api.system.aws-usw02-pr.ice.predix.io
  ```

1. Run the following script:

  ```bash
  $ ./provision.sh
  ```

  The `provision.sh` script accomplishes the following tasks in your CF org/space:

  * Creates a UAA service instance for exclusive use by the sample application
  * Creates an ACS service instance for exclusive use by the sample application
  * Creates the necessary OAuth 2 clients and users in the above UAA instance (that are used by the sample application).

1. Note down the UAA access token URL that the script outputs towards the end of its run (referred to as `<uaa_issuer_id>` in the rest of this doc):

  ```
  UAA instance is provisioned. You can now obtain access tokens from it using the following URL: <uaa_issuer_id>
  ```

After the script completes, you can continue and push the sample application to your org by confirming with `y`:

```
Provisioning complete. Would you like to push the sample application to your Cloud Foundry org/space? [y/n]: y
```

## Building and pushing the sample application to Cloud Foundry

Build and push the sample application to Cloud Foundry:

```bash
$ ./push-sample-app.sh
```

Note down the URL to the sample application that the script outputs at the end of its run (referred to as `<acs_sample_url>` in the rest of this doc):

```
The ACS sample application is now accessible at: <acs_sample_url>
```

After the script completes, you can continue and run integration tests against the sample application by confirming with `y`:

```
The ACS sample application has been successfully pushed to Cloud Foundry. Would you like to run integration tests? [y/n]: y
```

## Accessing resources in the sample application

### Command line examples for accessing protected resources

#### No authentication

Access the unprotected `/greeting` resource as follows using the ACS sample URL mentioned above:

```bash
$ curl -v -X GET '<acs_sample_url>/greeting'
```

A successful response looks like:

```
Hello !!!
```

#### Authenticated as a non-admin user (`alarms-user`)

1. Get an access token for `alarms-user` using the OAuth resource owner password credentials grant type:

  ```bash
  $ curl -v -X POST '<uaa_issuer_id>' -H 'Content-Type: application/x-www-form-urlencoded' -d 'client_id=alarms-app&client_secret=alarms-app-secret&grant_type=password&username=alarms-user&password=alarms-user-pwd&response_type=token'
  ```

  A successful response looks like:

  ```
  {
      "access_token": "<access_token>",
      "expires_in": 43199,
      "jti": "34532ec2c0274ad388a93252bfa81ade",
      "refresh_token": "e2992ae1751747ad9e92fb8cd4d86e38-r",
      "scope": "predix-acs.zones.224ea7ce-f698-4db6-82fb-99950f275686.user",
      "token_type": "bearer"
  }
  ```

  Note down the value of `<access_token>` since it will be used in later calls.

1. Perform an authorized operation (i.e. retrieving an alarm resource) using the access token retrieved above:

  ```bash
  $ curl -v -X GET '<acs_sample_url>/alarm/54' -H 'Authorization: Bearer <access_token>'
  ```

  A successful response looks like:

  ```
  {
      "id": "54",
      "message": "Alarm with alarm id : 54"
  }
  ```

  Note that leaving off the Authorization header will fail with an `HTTP 401 Unauthorized` error and a response body similar to the following will be returned:

  ```
  {
      "error": "unauthorized",
      "error_description": "An Authentication object was not found in the SecurityContext"
  }
  ```

1. Perform an unauthorized operation (i.e. deleting an alarm resource) using the access token retrieved above:

  ```bash
  $ curl -v -X DELETE '<acs_sample_url>/alarm/54' -H 'Authorization: Bearer <access_token>'
  ```

  You should get an `HTTP 403 Forbidden` error with a response body similar to the following:

  ```
  {
      "error": "Forbidden",
      "message": "Access is denied",
      "path": "/alarm/54",
      "status": 403,
      "timestamp": 1486588464292
  }
  ```

#### Authenticated as an admin user (`alarms-admin`)

1. Get an access token for `alarms-admin` using the OAuth resource owner password credentials grant type:

  ```bash
  $ curl -v -X POST '<uaa_issuer_id>' -H 'Content-Type: application/x-www-form-urlencoded' -d 'client_id=alarms-app&client_secret=alarms-app-secret&grant_type=password&username=alarms-admin&password=alarms-admin-pwd&response_type=token'
  ```

  A successful response looks like:

  ```
  {
      "access_token": "<access_token>",
      "expires_in": 43199,
      "jti": "69291075f5344763837c7dd5f7b58d6b",
      "refresh_token": "6c3f4aea623d41a986e85f3fd4cc338a-r",
      "scope": "predix-acs.zones.224ea7ce-f698-4db6-82fb-99950f275686.user",
      "token_type": "bearer"
  }
  ```

  Note down the value of `<access_token>` since it will be used in later calls.

1. The previously unauthorized operation (i.e. deleting an alarm resource) should now succeed using the `<access_token>` for the admin user retrieved above:

  ```bash
  $ curl -v -X DELETE '<acs_sample_url>/alarm/54' -H 'Authorization: Bearer <access_token>'
  ```

  A successful response looks like:

  ```
  < HTTP/1.1 200 OK
  < Content-Length: 0
  < Date: Wed, 08 Feb 2017 21:25:19 GMT
  < Server: Apache-Coyote/1.1
  < Set-Cookie: __VCAP_ID__=05175434e1e84a89b232cd9517a7868452b8b864b9f3453b83cf012bfb30f296; Path=/; HttpOnly
  < Set-Cookie: JSESSIONID=97835BF8061B983C18E9DAE74E48C119; Path=/; HttpOnly
  < X-Vcap-Request-Id: 4f2924a7-2796-4e90-754b-e35cada07796
  ```

  Note that since this is a sample application, the alarm resource isn't actually deleted (i.e. subsequent GETs on this alarm will still succeed).

### Java examples for accessing protected resources

#### Integration tests

Refer to the TestNG-based integration tests in [`AlarmsApplicationIT.java`](src/test/java/com/ge/predix/acs/sample/alarms/AlarmsApplicationIT.java) for how to access resources in the sample application as admin and non-admin users. The `OAuth2RestTemplate` beans that allow these tests to make OAuth calls to the sample application endpoints are found in [`test-spring-context.xml`](src/test/resources/test-spring-context.xml).

#### Spring Security extensions

In Java-related applications, Spring Security extensions can aid in using ACS for authorizing access to resources, esp. HTTP-specific ones like RESTful endpoints. Refer to [`alarms-app-context.xml`](src/main/resources/alarms-app-context.xml) for more information on how they're integrated into the sample application.

## Running integration tests

Integration tests that exercise the sample application can be run as follows:

```bash
$ ./run-integration-tests.sh
```

## Cleaning up

After you feel sufficiently comfortable with ACS and wish to clean up your CF space, run:

```bash
$ ./deprovision.sh
```

The `deprovision.sh` script accomplishes the following tasks in your CF org/space:

* Deletes the ACS service instance
* Deletes the UAA service instance
* Deletes the ACS sample application itself

[![Analytics](https://ga-beacon.appspot.com/UA-82773213-1/acs-samples/readme?pixel)](https://github.com/PredixDev)
