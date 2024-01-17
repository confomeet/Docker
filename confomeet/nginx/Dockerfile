FROM node:16-bullseye-slim as builderNode


ARG XMPP_DOMAIN
ENV XMPP_DOMAIN=$XMPP_DOMAIN



ARG ADMIN_FRONTEND_GIT_USER
ENV ADMIN_FRONTEND_GIT_USER=${ADMIN_FRONTEND_GIT_USER}
ARG ADMIN_FRONTEND_GIT_PASS
ENV ADMIN_FRONTEND_GIT_PASS=${ADMIN_FRONTEND_GIT_PASS}

ARG ADMIN_FRONTEND_BRANCH
ENV ADMIN_FRONTEND_BRANCH=${ADMIN_FRONTEND_BRANCH}

ARG CCMS_BASE_URL
ENV CCMS_BASE_URL=${CCMS_BASE_URL}

RUN apt-get update -y && apt-get upgrade -y && apt-get install git make gettext-base -y 


COPY lib-jitsi-meet /opt/lib-jitsi-meet
RUN cd /opt/lib-jitsi-meet && \
    npm update && npm install && npm run build

COPY jitsi-meet /opt/jitsi-meet
RUN cd /opt/jitsi-meet && \
npm cache clean --force &&\
    #npm update &&  \
    npm install

RUN cd /opt/jitsi-meet && \
    make -i && \
    ls -al /opt/jitsi-meet/libs



ENV NODE_ENV=production

RUN cd /opt && \
    git clone https://${ADMIN_FRONTEND_GIT_USER}:${ADMIN_FRONTEND_GIT_PASS}@code.event33.ru/confomeet/ConfOMeetFrontEnd.git && \
    cd ConfOMeetFrontEnd && \
    git checkout ${ADMIN_FRONTEND_BRANCH} && \
     yarn install --network-timeout 1000000 && yarn build

COPY conf /conf
RUN envsubst '${XMPP_DOMAIN}' < /conf/conf.d/site.conf > /conf/conf.d/site.conf.tmp && \
    mv -f /conf/conf.d/site.conf.tmp /conf/conf.d/site.conf

    
COPY www /www
RUN envsubst '${XMPP_DOMAIN},${CCMS_BASE_URL}' < /www/config.js > /www/config.js.js  && \
    mv -f /www/config.js.js /www/site.config.js && \
    cp -rf /www/* /opt/jitsi-meet/
#--------------------------------------------------------------------------------------------
FROM nginx:1.20-alpine

COPY --from=builderNode /opt/jitsi-meet /var/www/jitsi-meet
COPY --from=builderNode /conf /etc/nginx/
COPY --from=builderNode /opt/ConfOMeetFrontEnd/build /var/www/admin_front

ARG XMPP_DOMAIN
ENV XMPP_DOMAIN=$XMPP_DOMAIN

RUN apk upgrade --update-cache && \
        apk add openssl && \
        rm -rf /var/cache/apk/*

RUN mkdir /etc/nginx/crt && \
    openssl req -x509 -nodes -days 3650 -subj "/C=CA/ST=QC/O=Company, Inc./CN=${XMPP_DOMAIN}" \
    -addext "subjectAltName=DNS:${XMPP_DOMAIN}" -newkey rsa:2048 \
    -keyout /etc/nginx/crt/site.key -out /etc/nginx/crt/site.crt

COPY crt /etc/nginx/crt
