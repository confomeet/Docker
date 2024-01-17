local jwt = require "luajwtjitsi";
local st = require "util.stanza";
local async = require "util.async";
local update_presence_identity = module:require "util".update_presence_identity;

local main_muc_component_config = module:get_option_string('main_muc');
if main_muc_component_config == nil then
    module:log('error', 'single access module is not enabled missing main_muc config');
    return;
end

module:log('info', 'single access module loaded');



function filter_access(event)

  module:log('info', 'filter_access function is loaded');
  module:log('info', 'event it is %s',tostring(event));

  local origin, room, stanza = event.origin, event.room,  event.stanza;

  local occupant_auth_token = origin.auth_token;

  if occupant_auth_token == nil then return end


  local data, err = jwt.decode(occupant_auth_token);

  module:log('info', 'data it is %s',data);

  if data == nil or
  data.context == nil or
  data.context.user == nil or
  data.context.user.id == nil
  then return end

  if data.singleAccess == nil or not data.singleAccess then return end
  if data.moderator == nil then return end
  if data.moderator == false then

    local occupant_uuid = data.context.user.id
    local occupant_email = data.context.user.email


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
            local email_tag = user_tag:get_child('email');
            local user_email = email_tag:get_text();
            module:log('info', 'user_uuid it is %s',user_uuid);

            if user_uuid == occupant_uuid or user_email == occupant_email then
              module:log('info', 'Duplicate access for user_uuid (%s)', user_uuid);

                origin.send(st.error_reply(event.stanza, "cancel", "duplicate-access", "duplicate access"));

                room:set_affiliation(true, event.occupant.bare_jid, 'member');
                room:set_affiliation(true, event.occupant.bare_jid, 'outcast');
                origin.send(st.error_reply(event.stanza, "cancel", "service-unavailable"));
                return
            end

          end
        end)
        get_session_info:run(user);

      end
    end
  end
end

module:hook("muc-occupant-pre-join", function(event)
     filter_access(event);
end);
