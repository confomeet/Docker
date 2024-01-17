#!/bin/bash

JAVA_SYS_PROPS="-Dconfig.file=/etc/jitsi/jicofo/jicofo.conf -Dnet.java.sip.communicator.SC_HOME_DIR_LOCATION=/etc/jitsi -Dnet.java.sip.communicator.SC_HOME_DIR_NAME=jicofo -Dnet.java.sip.communicator.SC_LOG_DIR_LOCATION=/var/log/jitsi -Djava.util.logging.config.file=/etc/jitsi/jicofo/logging.properties"

DAEMON=/usr/share/jicofo/jicofo.sh
DAEMON_DIR=/usr/share/jicofo/
DAEMON_OPTS="--domain=\"${XMPP_DOMAIN}\" --host=\"prosody\" --user_name=\"focus\" --user_domain=\"auth.${XMPP_DOMAIN}\" --user_password=\"${JICOFO_AUTH_PASSWORD}\""

exec s6-setuidgid jicofo /bin/bash -c "cd $DAEMON_DIR; JAVA_SYS_PROPS=\"$JAVA_SYS_PROPS\" exec $DAEMON $DAEMON_OPTS"

#exec sleep 1h