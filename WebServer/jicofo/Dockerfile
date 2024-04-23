FROM debian:bullseye-slim

ARG XMPP_DOMAIN
ENV XMPP_DOMAIN=$XMPP_DOMAIN

ARG JICOFO_AUTH_PASSWORD
ENV JICOFO_AUTH_PASSWORD=$JICOFO_AUTH_PASSWORD

COPY files/ /

RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install gpg wget -y && \
    echo 'deb https://download.jitsi.org stable/' >> /etc/apt/sources.list.d/jitsi-stable.list && \
    wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | apt-key add - && \
    apt-get update -y && \
    apt-get install -y jicofo=1.0-940-1 s6  gettext-base

RUN envsubst '${XMPP_DOMAIN}'  < /config/sip-communicator.properties > /etc/jitsi/jicofo/sip-communicator.properties
RUN envsubst '${XMPP_DOMAIN}' < /config/jicofo.conf > /etc/jitsi/jicofo/jicofo.conf
RUN cp /config/logging.properties /etc/jitsi/jicofo/logging.properties
RUN envsubst '${XMPP_DOMAIN},${JICOFO_AUTH_PASSWORD}' < /run.sh.tpl > /run.sh && chmod 500 /run.sh && chown jicofo: /run.sh


CMD ["/run.sh"]
