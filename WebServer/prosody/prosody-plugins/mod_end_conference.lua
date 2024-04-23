local jid_split = require 'util.jid'.split;
local jid_bare = require 'util.jid'.bare;
local json = require 'util.json';
local st = require 'util.stanza';
local jwt = require "luajwtjitsi";


local http = require "net.http";
local timer = require "util.timer";
local async = require "util.async";
local url = module:get_option_string("conference_logger_url");
assert(url, "Missing required config option 'conference_logger_url'");

module:log("info","conference_logger_url: %s",url)


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


function get_user_info(session)



    local identity_tag = session:get_child('identity');

    local user_tag = identity_tag:get_child('user');
    local id_tag = user_tag:get_child('id');
    local user_uuid = id_tag:get_text();
    local groupId_tag= user_tag:get_child('groupId');
    local user_groupId = groupId_tag:get_text();
    local email_tag = user_tag:get_child('email');
    local user_email = email_tag:get_text();
    local user_object = {
        email=user_email,
        groupId=user_groupId
    }

    return user_object
end

function handle_stanza(st, type,Id,email, by)

    local message=tostring(st);

    if type == "occupant_leaving" then
        message= message..email;
    else
        message= by..message..email;
    end

    local request_body = json.encode({
        to = st.attr.from;
        from = st.attr.to;
        kind = st.name;
        type = type;
        meetingId = Id;
        message = message;
    });


    http.request(url, {
        body = request_body;
        headers = {
            ["Content-Type"] = "application/json";
        };
    }, function (response_text, code, response)

            module:log("info", "the  response_text is %s , and the code is %s ,  and the response is %s", response_text,code,response);

            if st.attr.type == "error" then return; end -- Avoid error loops, don't reply to error stanzas

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


--
local get_room_by_name_and_subdomain = module:require 'util'.get_room_by_name_and_subdomain;

local END_CONFERENCE_REASON = 'The meeting has been terminated';

-- Since this file serves as both the host module and the component, we rely on the assumption that
-- end_conference_component var would only be define for the host and not in the end_conference component

local end_conference_component = module:get_option_string('end_conference_component');

if end_conference_component then

    -- Advertise end conference so client can pick up the address and use it
    module:add_identity('component', 'end_conference', end_conference_component);

    return;  -- nothing left to do if called as host module

end

-- What follows is logic for the end_conference component

module:depends("jitsi_session");

local muc_component_host = module:get_option_string('muc_component');

if muc_component_host == nil then
    module:log('error', 'No muc_component specified. No muc to operate on!');
    return;
end

module:log('info', 'Starting end_conference for %s', muc_component_host);


-- receives messages from clients to the component to end a conference
function on_message(event)
    local session = event.origin;

    -- Check the type of the incoming stanza to avoid loops:
    if event.stanza.attr.type == 'error' then
        return; -- We do not want to reply to these, so leave.
    end

    if not session or not session.jitsi_web_query_room then
        return false;
    end

    local moderation_command = event.stanza:get_child('end_conference');

    if moderation_command then
        -- get room name with tenant and find room
        local room = get_room_by_name_and_subdomain(session.jitsi_web_query_room, session.jitsi_web_query_prefix);

        if not room then
            module:log('warn', 'No room found found for %s/%s',
                    session.jitsi_web_query_prefix, session.jitsi_web_query_room);
            return false;
        end

        -- check that the participant requesting is a moderator and is an occupant in the room
        local from = event.stanza.attr.from;
        local occupant = room:get_occupant_by_real_jid(from);
        if not occupant then
            module:log('warn', 'No occupant %s found for %s', from, room.jid);
            return false;
        end
        if occupant.role ~= 'moderator' then
            module:log('warn', 'Occupant %s is not moderator and not allowed this operation for %s', from, room.jid);
            return false;
        end
        -- if is_owner_present(room,from) then return false end
    local  moderatorCount = 0  ;

    for _, p in room:each_occupant() do
        local aff= room:get_affiliation(p.bare_jid);

        if aff == 'owner' or aff == 'moderator' then
            moderatorCount = moderatorCount + 1
        end

    end

    local ID = "";
    local Email = "";
    local ModeratorSession = "";
    local info;

    if not string.match(tostring(occupant.bare_jid), "recorder@recorder") then
        if moderatorCount > 2 then

            room:set_affiliation(true, occupant.jid, "outcast");

            session = occupant.sessions[occupant.jid];
            
            info = get_user_info(session);

            handle_stanza(session,"occupant_leaving",info.groupId,info.email,Email);

            return false

        else

            session = occupant.sessions[occupant.jid];

            info = get_user_info(session);

            ID = info.groupId;
            Email = info.email;
            ModeratorSession = session;

        end
end

    for _, p in room:each_occupant() do
        if not string.match(tostring(p.bare_jid), "recorder@recorder") then

            if string.sub(p.nick,-string.len("/focus"))~="/focus" then


                local session = p.sessions[p.jid];

                info = get_user_info(session);

                handle_stanza(session,"occupant_leaving",info.groupId,info.email,Email);

            end
        end
    end

    -- destroy the room
    room:destroy(nil, END_CONFERENCE_REASON);

    local wait, done = async.waiter();
    timer.add_task(1, function ()
        done();
    end);
    wait();


    handle_stanza(ModeratorSession, "end_call_for_all",ID,Email,Email);
    module:log('info', 'Room %s destroyed by occupant %s', room.jid, from);
    
    return true;

    end

    -- return error
    return false
end



-- we will receive messages from the clients
module:hook('message/host', on_message);

