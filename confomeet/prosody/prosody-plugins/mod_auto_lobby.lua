local jid_bare = require 'util.jid'.bare;
local jwt = require "luajwtjitsi";
local jid_split = require 'util.jid'.split;

module:log('info', 'AUTO LOBBY PLUGIN ENABLED');

local whitelist = module:get_option_set('muc_lobby_whitelist', {});
local main_muc_component_config = module:get_option_string('main_muc');
if main_muc_component_config == nil then
    module:log('error', 'auto lobby is not enabled missing main_muc config');
    return;
end

function process_host_module(name, callback)
  local function process_host(host)
      if host == name then
          callback(module:context(host), host);
      end
  end

  if prosody.hosts[name] == nil then
      module:log('debug', 'No host/component found, will wait for it: %s', name);
      prosody.events.add_handler('host-activated', process_host);
  else
      process_host(name);
  end
end

process_host_module(main_muc_component_config, function(host_module, host)
  host_module:hook('muc-room-created', function (event)
    prosody.events.fire_event('create-lobby-room', event);
  end);

  host_module:hook('muc-occupant-pre-join', function (event)
    local room = event.room;
    local invitee = event.stanza.attr.from;
    local invitee_bare_jid = jid_bare(invitee);

    local _, invitee_domain = jid_split(invitee);
    local whitelistJoin = false;

    -- whitelist participants
    if whitelist:contains(invitee_domain) or whitelist:contains(invitee_bare_jid) then
        whitelistJoin = true;
    end

    --[[local password = join:get_child_text('password', MUC_NS);
    if password and room:get_password() and password == room:get_password() then
        whitelistJoin = true;
    end]]

    if whitelistJoin then
        local affiliation = room:get_affiliation(invitee);
        if not affiliation or affiliation == 0 then
            event.occupant.role = 'participant';
            room:set_affiliation(true, invitee_bare_jid, 'member');
            room:save();
            return;
        end
    end

    local occupant_auth_token = event.origin.auth_token;
    if occupant_auth_token == nil then return end

    local data, err = jwt.decode(occupant_auth_token);

    if not data.moderator and data.autoLobby then return end

    local affiliation = room:get_affiliation(invitee);

    if not affiliation or affiliation == 0 then
      event.occupant.role = 'participant';
      room:set_affiliation(true, invitee_bare_jid, 'member');
      room:save();
    end
  end);
end);
