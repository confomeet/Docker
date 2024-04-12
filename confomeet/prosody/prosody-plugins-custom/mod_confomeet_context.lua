local jwt = require('luajwtjitsi');

module:log("info", "confomeet_context module loaded");

local function parse_bool_claim(claim_name, claimsTable)
    if claimsTable[claim_name] == true then  -- this also correctly check for null value
        return true;
    end
    return false;
end

module:hook_global("jitsi-authentication-token-verified", function(event)
    local session, claims = event.session, event.claims;
    local ctx = {}
    ctx.autoLobby = parse_bool_claim("autoLobby", claims);
    ctx.moderator = parse_bool_claim("moderator", claims);
    ctx.autoRec = parse_bool_claim("autoRec", claims);
    ctx.singleAccess = parse_bool_claim("singleAccess", claims);

    if session.jitsi_meet_context_user ~= nil then
        if session.jitsi_meet_context_user.id ~= nil and session.jitsi_meet_context_user.email ~= nil then
            ctx.anonymous = false;
            ctx.user_id = session.jitsi_meet_context_user.id;
            ctx.user_email = session.jitsi_meet_context_user.email;
        else
            ctx.anonymous = true;
            ctx.user_id = "";
            ctx.user_email = "";
        end
        ctx.user_groupId = session.jitsi_meet_context_user.groupId or "<empty_group_id>";
        local part_guid = session.jitsi_meet_context_user.participantGuid;
        if part_guid == nil or type(part_guid) ~= 'string' then
            module:log("warn", "participang_id is missing <empty_participant_id>");
            part_guid = "<empty_participant_id>"
        end
        ctx.participant_guid = part_guid;
    end
    session.confomeet_context = ctx;
end)
