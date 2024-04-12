-- Token moderation
-- this module checks the claim session.confomeet_contex.moderator.
-- If it is true the user is added to the room as an owner, otherwise user affiliation is set to member.
-- Note this may well break other affiliation based features like banning or login-based admins
local log = module._log;
local jid_bare = require "util.jid".bare;
local um_is_admin = require "core.usermanager".is_admin;

local function is_admin(jid)
        return um_is_admin(jid, module.host);
end

log('info', 'Loaded token moderation plugin');
-- Hook into room creation to add this wrapper to every new room

module:hook("muc-room-created", function(event)
        if string.match(event.room.jid, "jicofo[-]health[-]check") then
            return
        end

        log('info', 'Room %s created, adding token moderation code', event.room.jid);
        local room = event.room
        local _set_affiliation = room.set_affiliation;
        room.set_affiliation = function(room, actor, jid, affiliation, reason);
            if actor == "token_plugin" then
                return _set_affiliation(room, true, jid, affiliation, reason);
            elseif affiliation == "owner" then
                log('debug', 'set_affiliation: room=%s, actor=%s, jid=%s, affiliation=%s, reason=%s', room, actor, jid, affiliation, reason);
                if string.match(tostring(actor), "focus@") then
                   log('debug', 'set_affiliation not acceptable, focus user');
                   return nil, "modify", "not-acceptable";
                else
                    return _set_affiliation(room, actor, jid, affiliation, reason);
                end;
            else
                return _set_affiliation(room, actor, jid, affiliation, reason);
            end;
        end;
    end);

local function on_muc_occupant_joined(event)
    local room, session, occupant = event.room, event.origin, event.occupant;

    if session.confomeet_context == nil then
        log("debug", "Ignored muc-occupant-joined to %s because %s is not a confomeet participant", room.jid, occupant.jid);
        return;
    end

    log('info', 'Confomeet occupant joined, checking moderator grant of %s (aka %s) in %s', occupant.jid, session.confomeet_context.participant_guid, room.jid);

    local jid = jid_bare(event.stanza.attr.from);
    if session.confomeet_context.moderator or is_admin(jid_bare(jid)) then
        room:set_affiliation("token_plugin", jid, "owner");
    else
        room:set_affiliation("token_plugin", jid, "member");
    end
end;

module:hook("muc-occupant-joined", on_muc_occupant_joined)
