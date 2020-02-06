#!/bin/sh

CONF_FILE=
if [ "$USE_HTTPS" = "true" ]; then
    CONF_FILE="-c nginx-ssl.conf"
fi

exec nginx $CONF_FILE
