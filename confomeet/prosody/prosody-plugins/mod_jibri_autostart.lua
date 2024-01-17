local LOGLEVEL = "info"

local async = require "util.async";
local is_admin = require "core.usermanager".is_admin
local is_healthcheck_room = module:require "util".is_healthcheck_room
local timer = require "util.timer"
local st = require "util.stanza"
local uuid = require "util.uuid".generate
local jwt = require "luajwtjitsi";
local http = require "net.http";
local json = require "util.json";
--local url = module:get_option_string("Recording_Request_logger_url");
local url = "https://callpp.infostrategic.com/meet/api/v1/Recording/AddVideoRecording"


--assert(url, "Missing required config option 'Recording_Request_logger_url'");

--module:log("info","conference_logger_url: %s",url)

module:log(LOGLEVEL, "JIBRI AUTOSTART PLUGIN LOADED")

local http_error_map = {
    [0]   = { "cancel", "remote-server-timeout", "Connection failure" };
    -- 4xx
    [400] = { "modify", "bad-request" };
    [401] = { "auth", "not-authorized" };
    [402] = { "auth", "forbidden", "Payment required" };
    [403] = { "auth", "forbidden" };
    [404] = { "cancel", "item-not-found" };
    [410] = { "cancel", "gone" };
    -- 5xx
    [500] = { "cancel", "internal-server-error" };
    [501] = { "cancel", "feature-not-implemented" };
    [502] = { "cancel", "remote-server-timeout", "Bad gateway" };
    [503] = { "wait", "remote-server-timeout", "Service temporarily unavailable" };
    [504] = { "wait", "remote-server-timeout", "Gateway timeout" };
}

-- -----------------------------------------------------------------------------
function handle_Recording_Request_logger(event)
    local stanza = event.stanza;
    local occupant_auth_token = event.origin.auth_token;
        if occupant_auth_token == nil then return end
local date = os.date("%Y-%m-%d-%H-%M-%S")
        local data, err = jwt.decode(occupant_auth_token);
        -- local wait, done = async.waiter();
        -- timer.add_task(5, function ()
        --     done();
        -- end);
        -- wait();
        -- meetingId = data.context.user.groupId;
        local request_body = json.encode({
            recordingfileName = data.room.."_"..date
        });
    
     module:log("info","the  request_body is %s",request_body)
         http.request(url, {
             body = request_body;
             headers = {
                 ["Content-Type"] = "application/json";
             };
         }, function (response_text, code, response)
             module:log("info", "the  response_text is %s , and the code is %s ,  and the response is %s", response_text,code,response);
    
             if stanza.attr.type == "error" then return; end -- Avoid error loops, don't reply to error stanzas
             module:log("info", "Response code: %s", code );
             if code == 200 and response_text and response.headers["content-type"] == "application/json" then
                 local response_data = json.decode(response_text);
    
             elseif code >= 200 and code <= 299 then
                 return;
             else
                 -- module:send(error_reply(stanza, code));
             end
             return;
         end);
        return;
    end
    -- -----------------------------------------------------------------------------
    local function _is_admin(jid)
        return is_admin(jid, module.host)
    end
    
    -- -----------------------------------------------------------------------------
    local function _start_recording(event,room, session, occupant_jid)
        --handle_Recording_Request_logger(event);
        -- dont start recording if already triggered
        if room.is_recorder_triggered then
            return
        end
    --    handle_Recording_Request_logger(event);
        -- get occupant current status
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
    module:log("info","iq is %s",iq);
    end
    
    -- -----------------------------------------------------------------------------
    module:hook("muc-occupant-joined", function (event)
        local room = event.room
        local session = event.origin
        local occupant = event.occupant
    
        local occupant_auth_token = event.origin.auth_token;
        if occupant_auth_token == nil then return end
    
        local data, err = jwt.decode(occupant_auth_token)
    
        if data == nil or data.autoRec == nil or not data.autoRec then return end
    
        if is_healthcheck_room(room.jid) or _is_admin(occupant.jid) then
            return
        end
    
        -- wait for the affiliation to set then start recording if applicable
        timer.add_task(3, function()
            _start_recording(event,room, session, occupant.jid)
        end)
    end)
    
    