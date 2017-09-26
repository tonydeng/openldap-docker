FROM alpine

MAINTAINER Tony Deng

ENV OPENLDAP_VERSION 2.4.44-r0

RUN apk update \
    && apk add openldap \
    && rm -rf /var/cache/apk/*

EXPOSE 398

VOLUME ["/etc/openldap-dist","/var/lib/openldap"]

COPY modules/ /etc/openldap/modules

ENTRYPOINT ["/entrypoint.sh"]

CMD ["slapd","-d","32789","-u","ldap","-g","ldap"]
