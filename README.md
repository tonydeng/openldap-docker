# OpenLDAP Alpine Docker

[![Docker Stars](https://img.shields.io/docker/stars/wolfdeng/openldap.svg)](https://hub.docker.com/r/wolfdeng/openldap/)
[![Docker Pulls](https://img.shields.io/docker/pulls/wolfdeng/openldap.svg)](https://hub.docker.com/r/wolfdeng/openldap/)
[![Image Size](https://img.shields.io/imagelayers/image-size/wolfdeng/openldap/latest.svg)](https://imagelayers.io/?images=wolfdeng/openldap:latest)
[![Image Layers](https://img.shields.io/imagelayers/layers/wolfdeng/openldap/latest.svg)](https://imagelayers.io/?images=wolfdeng/openldap:latest)

The image is based on alpine.

The Dockerfile inspired by [dinkel/openldap](https://hub.docker.com/r/dinkel/openldap)

## Usage

The most simple form would be to start the application like so (however this is not the recommended way - see below):

```bash
docker run -d -p 389:389 -e SLAPD_PASSWORD={mysecretpassword} -e SLAPD_DOMAIN={ldap.example.org} wolfdeng/openldap
```

To get the full potential this image offers, one should first create a data-only container(See "Data persistence below"), start the OpenLDAP daemon as follows:

```bash
docker run -d --name openldap --volumes-from {your-data-container} wolfdeng/openldap
```

An application talking to OpenLDAP should then `--link` the container:

```bash
docker run -d --link openldap:openldap image-using-openldap
```

The name after the colon in the `--link` section is the hostname where the OpenLDAP daemon is listening to (the port is the default port `389`)

## Configuration(environment variables)

For the first run, one has to set at least the first two environment variables. After the first start of the image (and the initial configuration), these environment variables are not evaluated again

- `SLAPD_PASSWORD` (required) - sets the password for the `admin` user
- `SLAPD_DOMAIN` (required) - sets the DC(Domain Component)parts.E.g. if one sets it to `ldap.example.org`, the generated base DC parts would be `...,dc=ldap,dc=example,dc=org`.
- `SLAPD_ORGANIZATIOn` (defaults to $SLAPD_DOMAIN)  - represents the human readable company name (e.g. `Exammple Inc.`).
- `SLAPD_CONFIG_PASSWORD` - allow passord protected access to the `dn=config` branch. This helps to reconfigure the server without interruption(read the [official documentation](http://www.openldap.org/doc/admin24/guide.html#Configuring%20slapd)).
- `SLAPD_ADDITIONAL_SCHEMAS` - loads additional schemas provided in the `slapd` package that are not installed using the environment variable with comma-separated enties. As of writing these instructions, these are the folowing additional schemas available: `collective`,`corba`,`duaconf`,`dyngroup`,`java`,`misc`,`openldap`,`pmi` and `ppolicy`.
- `SLAPD_ADDITIONAL_MODULES` - comma-separated list of modules to load. it will try to run `.ldif` files with a corresponsing name from the `modules` directory. Currently only `ppolicy` and `memberof` are available.

### Setting up ppolicy

The ppolicy module providers enhanced password management capabilities that are applied to non-rootdn bind attempts in OpenLDAP. In order to it, one has to load both the schema `ppolicy`and the module `ppolicy`:

```bash
-e SLAPD_DOMAIN={ldap.example.org} -e SLAPD_ADDITIONAL_SCHEMAS=ppolicy -e SLAPD_ADDITIONAL_MODULES=ppolicy
```

These is one additional environment variable available:

- `SLAPD_PPOLICY_DN_PREFIX` - (defaults to `cn=default,ou=policies`) sets the dn prefix used in `modules/ppolicy.ldif` for the `olcPPolicyDefauult` attribute. The value used for `olcPPolicyDefault` is derived from `$SLAPD_PPOLICY_DN_PREFIX,(dc Component parts from $SLAPD_DOMAIN)`.

After load the module, you have to load a default password policy, assuming you are on a host that has the client side tools installed (maybe you have to change the hostname as well):

```bash
ldapadd -h localhost -x -c -D 'cn=admin,dc=ldap,dc=example,dc=org' -w [$SLAPD_PASSWORD] -f default-policy.ldif
```

The contents of `default-policy.ldif` should look something like this:

```ldif
# Define password policy
dn: ou=policies,dc=ldap,dc=example,dc=org
objectClass: organizationalUnit
ou: policies

objectClass: applicationProcess
objectClass: pwdPolicy
cn: default
pwdAllowUserChange: TRUE
pwdAttribute: userPassword
pwdCheckQuality: 1
# 7 days
pwdExpireWarning: 604800
pwdFailureCountInterval: 0
pwdGraceAuthNLimit: 0
pwdInHistory: 5
pwdLockout: TRUE
# 30 minutes
pwdLockoutDuration: 1800
# 180 days
pwdMaxAge: 15552000
pwdMaxFailure: 5
pwdMinAge: 0
pwdMinLength: 6
pwdMustChange: TRUE
pwdSafeModify: FALSE
```
See the [docs](http://www.zytrax.com/books/ldap/ch6/ppolicy.html) for descriptions on the available attributes and what they mean.

## Data persistence

The image exposes two directories (VOLUME ["/etc/openldap", "/var/lib/openldap"]). The first holds the "static" configuration while the second holds the actual database. Please make sure that these two directories are saved (in a data-only container or alike) in order to make sure that everything is restored after a restart of the container.
