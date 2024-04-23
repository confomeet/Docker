#FROM jitsi/jvb
FROM debian:bullseye-slim

ARG JVB_PORT
ARG XMPP_HOSTNAME
ARG JVB_USERNAME
ARG JVB_MUC_NICKNAME
ARG JVB_AUTH_NAME
ARG JVB_AUTH_PASS
ARG JVB_LOCAL_ADDRESS
ARG JVB_PUBLIC_ADDRESS
ARG STUN_ADDRESSES

ENV JVB_PORT=$JVB_PORT
ENV XMPP_HOSTNAME=$XMPP_HOSTNAME
ENV JVB_USERNAME=$JVB_USERNAME
ENV JVB_MUC_NICKNAME=$JVB_MUC_NICKNAME
ENV JVB_AUTH_NAME=$JVB_AUTH_NAME
ENV JVB_AUTH_PASS=$JVB_AUTH_PASS
ENV JVB_LOCAL_ADDRESS=$JVB_LOCAL_ADDRESS
ENV JVB_PUBLIC_ADDRESS=$JVB_PUBLIC_ADDRESS
ENV STUN_ADDRESSES=$STUN_ADDRESSES

ADD files/ /

RUN chmod 500 /run.sh && apt-get update && apt-get upgrade -y && apt-get -y install curl gpg gettext-base

RUN envsubst  < /config/jvb.conf > /tmp/jvb.conf && \
    mv -f /tmp/jvb.conf /config/jvb.conf

RUN envsubst  < /config/sip-communicator.properties > /tmp/sip-communicator.properties && \
    mv -f /tmp/sip-communicator.properties /config/sip-communicator.properties

RUN curl https://download.jitsi.org/jitsi-key.gpg.key | sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
RUN echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null


RUN apt-get -y remove curl gpg gettext-base && apt-get update && \
    apt-get -y install jitsi-videobridge2=2.2-63-g252d14bc-1 s6 && apt-get -y autoremove && apt-get clean && \
    chown -R jvb: /config && chmod -R 775 /config


CMD ["/run.sh"]
