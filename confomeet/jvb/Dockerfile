#FROM jitsi/jvb
FROM debian:bullseye-slim

ARG JVB_PORT
ARG JVB_USERNAME
ARG JVB_MUC_NICKNAME
ARG JVB_AUTH_NAME
ARG JVB_AUTH_PASS
ARG JVB_LOCAL_ADDRESS
ARG JVB_PUBLIC_ADDRESS
ARG STUN_ADDRESSES
ARG XMPP_DOMAIN

ENV JVB_PORT=$JVB_PORT
ENV JVB_USERNAME=$JVB_USERNAME
ENV JVB_MUC_NICKNAME=$JVB_MUC_NICKNAME
ENV JVB_AUTH_NAME=$JVB_AUTH_NAME
ENV JVB_AUTH_PASS=$JVB_AUTH_PASS
ENV JVB_LOCAL_ADDRESS=$JVB_LOCAL_ADDRESS
ENV JVB_PUBLIC_ADDRESS=$JVB_PUBLIC_ADDRESS
ENV STUN_ADDRESSES=$STUN_ADDRESSES
ENV XMPP_DOMAIN=$XMPP_DOMAIN

RUN apt-get update && apt-get upgrade -y && apt-get -y install curl gpg gettext-base vim

RUN curl https://download.jitsi.org/jitsi-key.gpg.key | sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg' && \
    echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null

RUN apt-get update && \
    apt-get -y install jitsi-videobridge2=2.3-41-ga8d8a786-1 s6 && apt-get -y autoremove && apt-get clean

ADD files/ /

RUN envsubst  < /config/jvb.conf > /tmp/jvb.conf && \
    mv -f /tmp/jvb.conf /config/jvb.conf && \
    envsubst  < /config/sip-communicator.properties > /tmp/sip-communicator.properties && \
    mv -f /tmp/sip-communicator.properties /config/sip-communicator.properties && \
    chown -R jvb: /config && chmod -R 775 /config && \
    chmod 755 /run.sh

CMD ["/run.sh"]
