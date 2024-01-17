local http = require "net.http";
local json = require "util.json";
local timer = require "util.timer";
local jwt = require "luajwtjitsi";
local async = require "util.async";
local url = module:get_option_string("conference_logger_url");
assert(url, "Missing required config option 'conference_logger_url'");

local focus_jid = module:get_option_string("focus_user_jid", "focus@auth.meet.jitsi");
module:log("info","focus_jid             is            %s",focus_jid)
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

local function fetching_meeting_Id(event,type)
    local meetingId;
    local room = event.room;

    if type == "occupant_joined" then
        local occupant_auth_token = event.origin.auth_token;
        if occupant_auth_token == nil then return end
        local data, err = jwt.decode(occupant_auth_token);
        meetingId = data.context.user.groupId;
        return meetingId;
    end
end


function on_message_bare(event)
    if event.stanza.attr.type == "error" then
        return;
    elseif event.stanza.attr.type == "groupchat" then
        handle_stanza(event, event.stanza.attr.type);
    else
        handle_stanza(event, event.stanza.attr.type);
    end
end


function on_message_full(event)
    if event.stanza == nil then
        --conf_log_message_event('nil_msg', '', '', tostring(event))
    elseif event.stanza.attr.type == "error" then
        return;
    elseif event.stanza.attr.type == "groupchat" then
        return;
    elseif event.stanza.attr.type == "chat" then
        handle_stanza(event, event.stanza.attr.type);
    else
        --conf_log_message_event('unknown_msg', '', '', tostring(event))
    end
end

function occupant_joined(event)
    local Id = fetching_meeting_Id(event,"occupant_joined");

    local room = event.room;

    if room._data.persistent then
            return; -- Don't monitor persistent rooms
    end

    local participant_count = 0;

    for _, occupant in room:each_occupant() do
            -- don't count jicofo's admin account (focus)
            if string.sub(occupant.nick,-string.len("/focus")) ~= "/focus" then
                    participant_count = participant_count + 1;
            end
    end

    module:log("info", "occupant count before create %s", tostring(participant_count));

        if participant_count == 1 and not string.match(tostring(event.stanza), "/focus") then

            handle_stanza(event.stanza, "room_created",Id,"");
            local wait, done = async.waiter();
            timer.add_task(1, function ()
                    done();
            end);
            wait();

            handle_stanza(event.stanza, "occupant_joined",Id,"");


        else
            
            if not string.match(tostring(event.stanza), "recorder@recorder") then

                if string.sub(event.occupant.nick,-string.len("/focus")) ~= "/focus" then
                   handle_stanza(event.stanza, "occupant_joined",Id,"");
               end
               
            end
        end
end


function fetching_user_email(event)
    local userEmail;
    local room = event.room;

        local occupant_auth_token = event.origin.auth_token;
        if occupant_auth_token == nil then return end
        local data, err = jwt.decode(occupant_auth_token);
        userEmail = data.context.user.email;
        return userEmail;
end


function handle_stanza(st, type,Id,email)

    local message=tostring(st);

    if type == "occupant_leaving" or type == "room_destroyed" then
    message= message..email;
    end

    local request_body = json.encode({
        to = st.attr.to;
        from = st.attr.from;
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
     --   module:log("info", "the  request_body is %s ", request_body);
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



module:hook("muc-occupant-pre-leave", function(event)

    local room=event.room;
    local str=event.stanza;
    local occupant_auth_token = event.origin.auth_token;
    if occupant_auth_token == nil then return end
    local data, err = jwt.decode(occupant_auth_token);
    local email= fetching_user_email(event);


    local Id = data.context.user.groupId;

    if not string.match(tostring(event.stanza), "recorder@recorder") then
        if string.sub(event.occupant.nick,-string.len("/focus")) ~= "/focus" then

            handle_stanza(str,"occupant_leaving",Id,email);

        end
    end

        if room._data.persistent then
                    return; -- Don't monitor persistent rooms
            end

        local participant_count = 0;
        for _, occupant in room:each_occupant() do
                -- don't count jicofo's admin account (focus)
            if not string.match(tostring(occupant.bare_jid), "recorder@recorder") then
                if string.sub(occupant.nick,-string.len("/focus")) ~= "/focus" then
                        participant_count = participant_count + 1;
                end
            end
        end

        module:log("info", "occupant count before destroy %s", tostring(participant_count));

            if participant_count ~= 1 then
                    return;
        end;

        local wait, done = async.waiter();
        timer.add_task(1, function ()
            done();
        end);
        wait();
        handle_stanza(str, "room_destroyed",Id,email);

    end, -100);

--module:hook("message/bare", on_message_bare);
--module:hook("message/full", on_message_full);
--module:hook("muc-room-created", room_created, -100);
module:hook("muc-occupant-joined", occupant_joined, -100);
--module:hook("muc-occupant-pre-leave", occupant_leaving,-100);
--module:hook("muc-occupant-leave", occupant_leaving,-100);
--module:hook("muc-room-destroyed", room_destroyed,-100);
