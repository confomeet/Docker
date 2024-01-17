asap_accepted_issuers = ${PROSODY_ACCEPTED_ISSUERS}
asap_accepted_audiences = ${PROSODY_ACCEPTED_AUDIENCES}
-- domain mapper options, must at least have domain base set to use the mapper
muc_mapper_domain_base = "${XMPP_DOMAIN}";
main_muc = "conference.${XMPP_DOMAIN}";

--external_service_secret = "wvOuZOhMtvIG2VUk";
--external_services = {
--     { type = "stun", host = "${XMPP_DOMAIN}", port = 3478 },
--     { type = "turn", host = "${XMPP_DOMAIN}", port = 3478, transport = "udp", secret = true, ttl = 86400, algorithm = "turn" },
--     { type = "turns", host = "${XMPP_DOMAIN}", port = 5349, transport = "tcp", secret = true, ttl = 86400, algorithm = "turn" }
--};

cross_domain_bosh = false;
consider_bosh_secure = true;
https_ports = { }; -- Remove this line to prevent listening on port 5284

-- https://ssl-config.mozilla.org/#server=haproxy&version=2.1&config=intermediate&openssl=1.1.0g&guideline=5.4
ssl = {
    protocol = "tlsv1_2+";
    ciphers = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384"
}

unlimited_jids = {
    "focus@auth.${XMPP_DOMAIN}",
    "jvb@auth.${XMPP_DOMAIN}"
}

VirtualHost "${XMPP_DOMAIN}"
    -- enabled = false -- Remove this line to enable this host
    authentication = "token"
    -- authentication = "anonymous"
    -- Properties below are modified by jitsi-meet-tokens package config
    -- and authentication above is switched to "token"
    app_id="${PROSODY_APP_ID}"
    app_secret="${PROSODY_APP_SECRET}"
    -- Assign this host a certificate for TLS, otherwise it would use the one
    -- set in the global section (if any).
    -- Note that old-style SSL on port 5223 only supports one certificate, and will always
    -- use the global one.
    ssl = {
        key = "/certs/${XMPP_DOMAIN}.key";
        certificate = "/certs/${XMPP_DOMAIN}.crt";
    }
    av_moderation_component = "avmoderation.${XMPP_DOMAIN}"
    speakerstats_component = "speakerstats.${XMPP_DOMAIN}"
    conference_duration_component = "conferenceduration.${XMPP_DOMAIN}"
    end_conference_component = "endconference.${XMPP_DOMAIN}"
    -- we need bosh
    modules_enabled = {
        "bosh";
        --"pubsub";
        "ping"; -- Enable mod_ping
        "speakerstats";
        --"external_services";
        "conference_duration";
        "muc_lobby_rooms";
        "room_metadata";
        "end_conference";
        "av_moderation";
        "presence_identity";
    }
    lobby_muc = "lobby.${XMPP_DOMAIN}"
    room_metadata_component = "metadata.${XMPP_DOMAIN}"
    main_muc = "conference.${XMPP_DOMAIN}"
    conference_logger_url = "http://${admin_backend}/api/v1/ConfEvent/AddProsodyEvent"


Component "conference.${XMPP_DOMAIN}" "muc"
    restrict_room_creation = true
    storage = "memory"
    modules_enabled = {
        "muc_meeting_id";
        "muc_domain_mapper";
        "polls";
        "token_verification";
        --"token_moderation";
        -- "room_auto_close";
        --"auto_lobby";
        "kick_back_to_lobby";
        "jibri_autostart";
        "grant_moderator_rights";
        "conf_http_log";
        "jibri_kick_members";
        --"muc_status";
        --"conf_log";
        "single_access";
    }
    admins = { "focus@auth.${XMPP_DOMAIN}"}
    muc_room_locking = false
    muc_room_default_public_jids = true
    muc_lobby_whitelist = { "recorder.${XMPP_DOMAIN}" }
    close_room_delay = 30
    focus_user_jid = "focus@auth.${XMPP_DOMAIN}"
    conference_logger_url = "http://${admin_backend}/api/v1/ConfEvent/AddProsodyEvent"

-- internal muc component
Component "internal.auth.${XMPP_DOMAIN}" "muc"
    storage = "memory"
    modules_enabled = {
        "ping";
    }
    admins = { "focus@auth.${XMPP_DOMAIN}", "jvb@auth.${XMPP_DOMAIN}" ,"jigasi@auth.${XMPP_DOMAIN}" }
    muc_room_locking = false
    muc_room_default_public_jids = true
    muc_room_cache_size = 1000

VirtualHost "auth.${XMPP_DOMAIN}"
    ssl = {
        key = "/certs/auth.${XMPP_DOMAIN}.key";
        certificate = "/certs/auth.${XMPP_DOMAIN}.crt";
    }
    modules_enabled = {
        "limits_exception";
    }
    authentication = "internal_hashed"

-- Proxy to jicofo's user JID, so that it doesn't have to register as a component.
Component "focus.${XMPP_DOMAIN}" "client_proxy"
    target_address = "focus@auth.${XMPP_DOMAIN}"

Component "speakerstats.${XMPP_DOMAIN}" "speakerstats_component"
    muc_component = "conference.${XMPP_DOMAIN}"

Component "conferenceduration.${XMPP_DOMAIN}" "conference_duration_component"
    muc_component = "conference.${XMPP_DOMAIN}"

Component "avmoderation.${XMPP_DOMAIN}" "av_moderation_component"
    muc_component = "conference.${XMPP_DOMAIN}"

Component "lobby.${XMPP_DOMAIN}" "muc"
    storage = "memory"
    restrict_room_creation = true
    muc_room_locking = false
    muc_room_default_public_jids = true

Component "metadata.${XMPP_DOMAIN}" "room_metadata_component"
    muc_component = "conference.${XMPP_DOMAIN}"    

Component "endconference.${XMPP_DOMAIN}" "end_conference"
    muc_component = "conference.${XMPP_DOMAIN}"
    conference_logger_url = "http://${admin_backend}/api/v1/ConfEvent/AddProsodyEvent"

VirtualHost "recorder.${XMPP_DOMAIN}"
  modules_enabled = {
    "ping";
  }
  authentication = "internal_plain"