FROM debian:11-slim as pluginBuilder

WORKDIR /tmp

ARG JITSI_RELEASE=stable
ARG FREP_VERSION=1.3.11

RUN apt-get update && \
    apt-get install -y apt-transport-https apt-utils ca-certificates gnupg wget git && \
    git config --global url."https://github.com/".insteadOf git://github.com/ && \
    wget -qO - https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz | tar xfz - -C / && \
    wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | gpg --dearmour > /etc/apt/trusted.gpg.d/jitsi.gpg && \
    wget -qO /usr/bin/frep https://github.com/subchen/frep/releases/download/v$FREP_VERSION/frep-$FREP_VERSION-linux-amd64 && \
    echo "deb https://download.jitsi.org $JITSI_RELEASE/" > /etc/apt/sources.list.d/jitsi.list && \
    echo "deb http://ftp.debian.org/debian bullseye-backports main" > /etc/apt/sources.list.d/backports.list && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    mkdir -p /prosody-plugins

RUN git clone https://github.com/nvonahsen/jitsi-token-moderation-plugin.git && \
    cp  jitsi-token-moderation-plugin/*.lua /prosody-plugins/ && \
    #git clone https://github.com/jitsi/jitsi-meet.git && \
    #cp -r jitsi-meet/resources/prosody-plugins/* /prosody-plugins/ && \
    git clone https://github.com/jitsi-contrib/prosody-plugins.git && \
    cp -r prosody-plugins/* /prosody-plugins/ && rm -rf *

COPY prosody-plugins/ /prosody-plugins/

RUN  chmod -R 644 /prosody-plugins

RUN apt-get install -y \
      lua5.2 \
      liblua5.2-dev \
      libsasl2-dev \
      libssl-dev \
      luarocks \
      libreadline-dev \
      git \
      gcc && \
    luarocks install cyrussasl 1.1.0-1 && \
    luarocks install net-url 0.9-1 && \
    luarocks install luajwtjitsi 2.0-0 \
    luarocks install lua-cjson

ARG XMPP_DOMAIN
ENV XMPP_DOMAIN=$XMPP_DOMAIN
RUN mkdir /certs
WORKDIR /certs
RUN apt-get install -y openssl
RUN openssl req -x509 -nodes -days 3650 -subj "/C=CA/ST=QC/O=Company, Inc./CN=${XMPP_DOMAIN}" \
    -addext "subjectAltName=DNS:${XMPP_DOMAIN}" -newkey rsa:2048 \
    -keyout ${XMPP_DOMAIN}.key -out ${XMPP_DOMAIN}.crt

RUN openssl req -x509 -nodes -days 3650 -subj "/C=CA/ST=QC/O=Company, Inc./CN=auth.${XMPP_DOMAIN}" \
    -addext "subjectAltName=DNS:auth.${XMPP_DOMAIN}" -newkey rsa:2048 \
    -keyout auth.${XMPP_DOMAIN}.key -out auth.${XMPP_DOMAIN}.crt



FROM debian:11-slim
ARG UGID=3458
ENV UGID=$UGID

ARG XMPP_DOMAIN
ENV XMPP_DOMAIN=$XMPP_DOMAIN

ARG JITSI_RELEASE=stable
ARG FREP_VERSION=1.3.11

ARG TZ
ENV TZ=$TZ
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN groupadd --gid ${UGID} prosody && \
    useradd --uid ${UGID} --gid prosody  prosody

RUN apt-get update && \
    apt-get install -y apt-transport-https apt-utils ca-certificates gnupg wget git && \
    wget -qO - https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz | tar xfz - -C / && \
    wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | gpg --dearmour > /etc/apt/trusted.gpg.d/jitsi.gpg && \
    wget -qO /usr/bin/frep https://github.com/subchen/frep/releases/download/v$FREP_VERSION/frep-$FREP_VERSION-linux-amd64 && \
    echo "deb https://download.jitsi.org $JITSI_RELEASE/" > /etc/apt/sources.list.d/jitsi.list && \
    echo "deb http://ftp.debian.org/debian bullseye-backports main" > /etc/apt/sources.list.d/backports.list && \
    apt-get update && \
    apt-get dist-upgrade -y

RUN apt-get update -y && apt-get upgrade -y &&  \
    apt-get install -y wget

RUN wget -qO /etc/apt/trusted.gpg.d/prosody.gpg https://prosody.im/files/prosody-debian-packages.key && \
    echo "deb http://packages.prosody.im/debian bullseye main" > /etc/apt/sources.list.d/prosody.list && \
    apt-get update && \
    apt-get install -y \
      gettext-base s6 \
      prosody-0.11 \
      libssl1.1 \
      libldap-common \
      sasl2-bin \
      libsasl2-modules-ldap \
      lua-basexx \
      lua-ldap \
      lua-sec \
      patch && \
    apt-get update && \
    apt-get -d install -y jitsi-meet-prosody=1.0.6776-1 && \
    dpkg -x /var/cache/apt/archives/jitsi-meet-prosody*.deb /tmp/pkg && \
    mv /tmp/pkg/usr/share/jitsi-meet/prosody-plugins /prosody-plugins && \
    #apt-cleanup && \
    rm -rf /tmp/pkg /var/cache/apt 
    # patch -d /usr/lib/prosody/modules/muc -p0 < /prosody-plugins/muc_owner_allow_kick.patch

RUN cd && \
    #apt-get update -y && \
    #apt-get install s6 gettext-base gcc unzip lua5.2  liblua5.2 liblua5.2-dev libsasl2-dev luarocks -y && \
    #extrepo enable prosody && \
    #luarocks install basexx && \
    #wget -c https://launchpad.net/~rael-gc/+archive/ubuntu/rvm/+files/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb && \
    #wget -c https://launchpad.net/~rael-gc/+archive/ubuntu/rvm/+files/libssl1.0-dev_1.0.2n-1ubuntu5.3_amd64.deb && \
    #dpkg -i libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb && \
    #dpkg -i libssl1.0-dev_1.0.2n-1ubuntu5.3_amd64.deb && \
    #luarocks install luacrypto && \
    #mkdir src && \
    #cd src && \
    #luarocks download lua-cjson && \
    #luarocks unpack lua-cjson-2.1.0.6-1.src.rock && \
    #cd lua-cjson-2.1.0.6-1/lua-cjson && \
    #sed -i 's/lua_objlen/lua_rawlen/g' lua_cjson.c && \
    #sed -i 's|$(PREFIX)/include|/usr/include/lua5.2|g' Makefile && \
    #luarocks make && \
    #cd && \
    #apt install git cmake liblua5.1-0-dev -y && \
    #git clone https://github.com/evanlabs/luacrypto && \
    #cd luacrypto && \
    #luarocks make && \
    #cd && \
    #luarocks install luajwtjitsi && \
    #cd && \
    #apt-get update -y && \
    #apt-get upgrade -y && \
    #apt-get install prosody -y && \
    #apt-get -y autoremove && apt-get clean && \
    #chown root:prosody /etc/prosody/certs/localhost.key && \
    #chmod 644 /etc/prosody/certs/localhost.key && \
    #luarocks install cyrussasl 1.1.0-1 && \
    #luarocks install net-url 0.9-1 && \
    #luarocks install luajwtjitsi 2.0-0 && \
    #rm -r libssl1* && \
    mkdir -p /var/run/prosody -p && chown prosody: /var/run/prosody


WORKDIR /

COPY --from=pluginBuilder /usr/local/lib/lua /usr/local/lib/lua
COPY --from=pluginBuilder /usr/local/share/lua /usr/local/share/lua

COPY --from=pluginBuilder /prosody-plugins/ /prosody-plugins/
RUN cp -rf /prosody-plugins/* /usr/lib/prosody/modules/
COPY --from=pluginBuilder /certs/ /certs/
COPY files/ /

ARG PROSODY_ACCEPTED_ISSUERS
ENV PROSODY_ACCEPTED_ISSUERS=$PROSODY_ACCEPTED_ISSUERS

ARG PROSODY_ACCEPTED_AUDIENCES
ENV PROSODY_ACCEPTED_AUDIENCES=$PROSODY_ACCEPTED_AUDIENCES

ARG PROSODY_APP_ID
ENV PROSODY_APP_ID=$PROSODY_APP_ID

ARG PROSODY_APP_SECRET
ENV PROSODY_APP_SECRET=$PROSODY_APP_SECRET

ARG JICOFO_AUTH_PASSWORD
ENV JICOFO_AUTH_PASSWORD=$JICOFO_AUTH_PASSWORD

ARG JVB_USERNAME
ENV JVB_USERNAME=$JVB_USERNAME

ARG JVB_AUTH_PASS
ENV JVB_AUTH_PASS=$JVB_AUTH_PASS

ARG JIBRI_RECORDER_PASSWORD
ENV JIBRI_RECORDER_PASSWORD=$JIBRI_RECORDER_PASSWORD

ARG JIBRI_XMPP_PASSWORD
ENV JIBRI_XMPP_PASSWORD=$JIBRI_XMPP_PASSWORD

ARG JIGASI_XMPP_USER
ENV JIGASI_XMPP_USER=$JIGASI_XMPP_USER

ARG JIGASI_XMPP_PASSWORD
ENV JIGASI_XMPP_PASSWORD=$JIGASI_XMPP_PASSWORD

RUN apt install dnsutils -y
RUN cp /config/prosody.cfg.lua /etc/prosody/prosody.cfg.lua && \
    mkdir -p /etc/prosody/conf.d && \
    envsubst '${XMPP_DOMAIN},${PROSODY_ACCEPTED_ISSUERS},${PROSODY_ACCEPTED_AUDIENCES},${PROSODY_APP_ID},${PROSODY_APP_SECRET}' < /config/conf.d/site.cfg.lua > /etc/prosody/conf.d/site.cfg.lua && \
    chown -R root:prosody /etc/prosody/conf.d && \
    chown -R prosody: /certs && chmod -R 755 /certs && \
    chown prosody: /run.sh && chmod 550 /run.sh && \
    prosodyctl --config /etc/prosody/conf.d/site.cfg.lua register focus auth.${XMPP_DOMAIN} ${JICOFO_AUTH_PASSWORD} && \
    prosodyctl --config /etc/prosody/conf.d/site.cfg.lua register ${JVB_USERNAME} auth.${XMPP_DOMAIN} ${JVB_AUTH_PASS} && \
    prosodyctl --config /etc/prosody/conf.d/site.cfg.lua mod_roster_command subscribe focus.${XMPP_DOMAIN} focus@auth.${XMPP_DOMAIN} && \
    prosodyctl --config /etc/prosody/conf.d/site.cfg.lua register jibri auth.${XMPP_DOMAIN} ${JIBRI_XMPP_PASSWORD} && \
    prosodyctl --config /etc/prosody/conf.d/site.cfg.lua register recorder recorder.${XMPP_DOMAIN} ${JIBRI_RECORDER_PASSWORD} && \
    #prosodyctl --config /etc/prosody/conf.d/site.cfg.lua register ${JIGASI_XMPP_USER} auth.${XMPP_DOMAIN} ${JIGASI_XMPP_PASSWORD} && \
    mv /etc/prosody/conf.d/site.cfg.lua /config/conf.d/site.cfg.lua.tmp
CMD ["/run.sh"]

