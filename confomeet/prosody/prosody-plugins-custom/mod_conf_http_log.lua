-- Moduld should be enabled in MUC component
-- Component "conference.myevent33.ru" "muc"
--     conference_logger_url = "http://backend:5000/api/v1/ConfEvent/AddProsodyEvent"
--     modules_enabled = {
--         "confomeet_context";
--         "conf_http_log";
--     }
--
-- Implementation relies on data injected to user session by confomeet_context module.
--

local http = require "net.http";
local json = require "util.json";
local timer = require "util.timer";
local async = require "util.async";
local jid_split = require "prosody.util.jid".prepped_split
local conference_logger_url = module:get_option_string("conference_logger_url");
assert(conference_logger_url, "Missing required config option 'conference_logger_url'");

module:log("info", "Loading module conf_http_log with conference_logger_url='%s'", conference_logger_url)

local PROSODY_EVENT_ROOM_CREATED = "room_created";
local PROSODY_EVENT_OCCUPANT_JOINED = "occupant_joined";
local PROSODY_EVENT_OCCUPANT_LEAVING = "occupant_leaving";
local PROSODY_EVENT_ROOM_DESTROYED = "end_call_for_all";
local PROSODY_EVENT_ROOM_FINISHED = "room_destroyed"
local PROSODY_EVENT_USER_LEAVING_LOBBY = "occupant_leaving_lobby";

local handle_stanza = nil;

local function occupant_joined(event)
    local room, session = event.room, event.origin;

    if session.confomeet_context == nil then
        module:log("debug", "Ignored non confomeet occupant join: room=%s   jid=%s", room.jid, event.occupant.jid);
        return
    end

    local participant_guid = event.origin.confomeet_context.participant_guid;
    local meeting_id = jid_split(event.room.jid)
    module:log("info", "Processing muc-occupant-join of %s (aka %s) to %s", event.occupant.jid, participant_guid, room.jid);

    if room._data.persistent then
            return; -- Don't monitor persistent rooms
    end

    local real_participants_count = 0;

    for _, occupant in room:each_occupant() do
            -- don't count jicofo's admin account (focus)
            if string.sub(occupant.nick,-string.len("/focus")) ~= "/focus" and occupant.jid ~= event.occupant.jid then
                    real_participants_count = real_participants_count + 1;
            end
    end

    module:log("debug", "Real room participants count before join: %d", real_participants_count);

    if real_participants_count == 1 and not string.match(tostring(event.stanza), "/focus") then
        handle_stanza(event.stanza, PROSODY_EVENT_ROOM_CREATED, meeting_id);
        -- FIXME: this needs to be replaces with some outgoing message queue.
        local wait, done = async.waiter();
        timer.add_task(1, function ()
            done();
        end);
        wait();
    end
    handle_stanza(event.stanza, PROSODY_EVENT_OCCUPANT_JOINED, meeting_id, participant_guid);
end

handle_stanza = function(st, type, meeting_id, participant_guid)
    local message=tostring(st);

    if type == "occupant_leaving" or type == "room_destroyed" then
        message= message..participant_guid;
    end

    local request_body = json.encode({
        to = st.attr.to;
        from = st.attr.from;
        kind = st.name;
        type = type;
        meetingId = meeting_id;
        participang_guid = participant_guid;
        message = message;
    });


    http.request(conference_logger_url, {
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
            module:log("warn", "Failed to save event %s  http status code=%d,  details=%s", type, code, error_details);
        end
    end);
end

local function occupant_pre_leave(event)
    local room, session = event.room, event.origin;

    if session.confomeet_context == nil then
        module:log("debug", "Ignored non confomeet occupant join: room=%s   jid=%s", room.jid, event.occupant.jid);
        return
    end

    local participant_guid = session.confomeet_context.participant_guid;

    module:log("info", "Processing muc-occupant-pre-leave of %s (aka %s) from %s", event.occupant.jid, participant_guid, room.jid);

    local meeting_id = jid_split(room.jid);

    handle_stanza(event.stanza, PROSODY_EVENT_OCCUPANT_LEAVING, meeting_id, participant_guid)

    if room._data.persistent then
        return; -- Don't monitor persistent rooms
    end

    local participant_count = 0;
    for _, occupant in room:each_occupant() do
            -- don't count jicofo's admin account (focus)
        local is_jicofo = string.sub(occupant.nick,-string.len("/focus")) == "/focus";
        local is_jibri = string.match(tostring(occupant.bare_jid), "recorder@recorder");
        if not is_jibri and not is_jicofo then
                    participant_count = participant_count + 1;
        end
    end

    module:log("debug", "occupant count before destroy %s", tostring(participant_count));

    if participant_count ~= 1 then -- Leaving user is not a last real participant
        return;
    end;

    local wait, done = async.waiter();
    timer.add_task(1, function ()
        done();
    end);
    wait();
    handle_stanza(event.stanza, PROSODY_EVENT_ROOM_FINISHED, meeting_id, participant_guid);
end

module:hook("muc-occupant-pre-leave", occupant_pre_leave, -100);
module:hook("muc-occupant-joined", occupant_joined, -100);