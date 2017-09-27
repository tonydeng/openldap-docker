#!/bin/sh

# When not limiting the open file descritors limit, the memory consumption of
# slapd is absurdly high. See https://github.com/docker/issues/8231
ulimit -n 8192

set -e
    slapd_config_in_env=`env |grep 'SLAPD_'`

    if [-n "$slapd_config_in_env:+x"]; then
        echo "Info: Container already configured, therefore ignoreing SLAPD_xxx environment variables"
    fi
exec "$@"
