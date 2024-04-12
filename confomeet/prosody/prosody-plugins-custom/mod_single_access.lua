local jwt = require "luajwtjitsi";
local st = require "util.stanza";
local async = require "util.async";

module:log('info', 'single access module loaded');

local function filter_access(event)
  local origin_session, room = event.origin, event.room;
  if origin_session.confomeet_context == nil then
    module:log("debug", "Ignore non confomeet user %s prejoin to %s", event.occupant.jid, room.jid);
    return;
  end

  if not origin_session.confomeet_context.singleAccess or origin_session.confomeet_context.moderator then
    return
  end

  module:log('info', 'Running single access checks for %s (aka %s) in room %s', event.occupant.nick, origin_session.confomeet_context.participant_guid, room.jid);

  local occupant_uuid = origin_session.confomeet_context.participant_guid

  for _, user in room:each_occupant() do
          -- filter focus as we keep it as hidden participant
    if string.sub(user.nick,-string.len("/focus"))~="/focus" then

      local get_session_info = async.runner( function(user)
      local session = user.sessions[user.jid];

      local identity_tag = session:get_child('identity');
        if identity_tag then

          local user_tag = identity_tag:get_child('user');
          local id_tag = user_tag:get_child('id');
          local user_uuid = id_tag:get_text();

          if user_uuid == occupant_uuid then
            module:log('info', 'Duplicate access for user_uuid (%s)', user_uuid);

              origin_session.send(st.error_reply(event.stanza, "cancel", "duplicate-access", "duplicate access"));

              room:set_affiliation(true, event.occupant.bare_jid, 'member');
              room:set_affiliation(true, event.occupant.bare_jid, 'outcast');
              origin_session.send(st.error_reply(event.stanza, "cancel", "service-unavailable"));
              return
          end

        end
      end)
      get_session_info:run(user);

    end
  end
end

module:hook("muc-occupant-pre-join", filter_access);
