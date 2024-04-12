local is_healthcheck_room = module:require "util".is_healthcheck_room
local timer = require "util.timer"
local st = require "util.stanza"
local uuid = require "util.uuid".generate
local http = require "net.http";
local json = require "util.json";
local jid_split = require("util.jid").split;

local recording_logger_url = module:get_option_string("recording_logger_url");

module:log("info", "Loading jibri_autostart plugin");

local function log_recording_started(meeting_id)
    if recording_logger_url == nil or recording_logger_url == "" then
        module:log("warn", "recording_logger_url is not set, backend won't get a notifiction about recording start");
    end
    local request_body = json.encode({
        meetingId = meeting_id
    });

    http.request(recording_logger_url, {
        body = request_body;
        headers = {
            ["Content-Type"] = "application/json";
        };
    }, function (response_body, code, response)
        module:log("debug", "the  response_text is %s , and the code is %s ,  and the response is %s", response_body, code, response);
        if code >= 200 and code <= 299 then
            return;
        else
            local api_result = json.decode(response_body);
            local error_details = "";
            if api_result ~= nil and api_result.message ~= nil then
                error_details = api_result.message;
            end
            module:log("warn", "Failed to log recording start: http status code=%d,  details=%s", code, error_details);
        end
    end);
end

local function start_recording(event,room, session, occupant_jid)
    if room.is_recorder_triggered then
        return
    end

    local occupant = room:get_occupant_by_real_jid(occupant_jid)

    -- check recording permission
    if occupant.role ~= "moderator" then
        return
    elseif
        session.jitsi_meet_context_features ~= nil and
        session.jitsi_meet_context_features["recording"] ~= true
    then
        return
    end

    module:log("info", "Starting recording: room=%s", room.jid);

    -- start recording
    local iq = st.iq({
        type = "set",
        id = uuid() .. ":sendIQ",
        from = occupant_jid,
        to = room.jid .. "/focus"
        })
        :tag("jibri", {
            xmlns = "http://jitsi.org/protocol/jibri",
            action = "start",
            recording_mode = "file",
            app_data = '{"file_recording_metadata":{"share":true}}'})

    module:send(iq)
    room.is_recorder_triggered = true
    local meeting_id = jid_split(room.jid);
    log_recording_started(meeting_id);
end

module:hook("muc-occupant-joined", function (event)
    local room = event.room
    local session = event.origin
    local occupant = event.occupant

    if is_healthcheck_room(room.jid) then
        return;
    end

    if session.confomeet_context == nil then
        module:log("info", "Ignored muc-occupant-joined to room=%s because %s is not a confomeet participant", room.jid, occupant.jid);
        return;
    end

    if not session.confomeet_context.autoRec then return end

    -- wait for the affiliation to set then start recording if applicable
    timer.add_task(3, function()
        start_recording(event,room, session, occupant.jid)
    end)
end)
