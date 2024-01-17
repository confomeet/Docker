local jid_split = require 'util.jid'.split;
local jid_bare = require 'util.jid'.bare;
local json = require 'util.json';
local st = require 'util.stanza';
local jwt = require "luajwtjitsi";
local focus_jid = module:get_option_string("focus_user_jid", "focus@auth.meet.jitsi");
local whitelist = module:get_option_set('muc_lobby_whitelist', {});
local t = {}
local main_muc_service
local main_muc_component_config = module:get_option_string('main_muc');
if main_muc_component_config == nil then
    module:log('error', 'kick back to lobby is not enabled missing main_muc config');
    return;
end

local http = require "net.http";
local timer = require "util.timer";
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



function is_owner_present(event)
  local mods = event.room:each_affiliation("owner");
  for mod in mods do
    module:log("debug", "owner found: %s", tostring(mod));
    if mod ~= focus_jid then
      -- there is a moderator in this room, dont ask to join
      module:log("debug", "there is  a moderator present: %s", mod);
      return true;
    end
  end
  return false;
end

function handle_stanza(st, type,Id,email,kicker_name)


  local message = tostring(st);

 local message2= kicker_name..message..email;
module:log("info","message kick it is %s",tostring(message))
  local request_body = json.encode({
      to = st.attr.to;
      from = st.attr.from;
      kind = st.name;
      type = type;
      meetingId = Id;
      message = message2;
  });


  http.request(url, {
      body = request_body;
      headers = {
          ["Content-Type"] = "application/json";
      };
  }, function (response_text, code, response)
      module:log("info", "the  response_text is %s , and the code is %s ,  and the response is %s", response_text,code,response);
      module:log("info", "the  request_body is %s ", request_body);
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

function kick_back_to_lobby(event)
  local origin, stanza = event.origin, event.stanza;

  local node, to_domain = jid_split(stanza.attr.to);
  if to_domain ~= main_muc_component_config then return end

  local room = main_muc_service.get_room_from_jid(jid_bare(node .. '@' .. main_muc_component_config));
  if not room then return end

  local kickee_jid = stanza[1].attr.participant;
  if not kickee_jid then return end

  local kicker_affiliation = room.get_affiliation(room, origin.full_jid)
  if kicker_affiliation ~= 'owner' then
    origin.send(st.stanza('kick_back_to_lobby_error'):tag('reason'):text('Access denied'))
    return
  end

  local kickee_affiliation = room.get_affiliation(room, kickee_jid)
  if kickee_affiliation ~= 'member' then
    origin.send(st.stanza('kick_back_to_lobby_error'):tag('reason'):text('You cannot kick this participant'))
    return
  end

  module:log('debug', 'Kick %s to lobby', kickee_jid);

  local kick_message = st.message({
    type = 'groupchat',
    from = stanza.attr.to,
    to = kickee_jid
  })
    :tag('kick-back-to-lobby', { xmlns='jabber:message:kick_back_to_lobby' })
    :text(kickee_jid)
    :up()
    :tag('lobbyroom')
    :text(room._data.lobbyroom)
    :up();
  room:route_stanza(kick_message);
  local kicker_name = "";
  for _, user in room:each_occupant() do
    if user.jid == origin.full_jid then 
      local kicker_session = user.sessions[user.jid];
      local kicker_identity_tag = kicker_session:get_child('identity');
      local user_tag = kicker_identity_tag:get_child('user');
            local name_tag = user_tag:get_child('name');
            local user_name = name_tag:get_text();
            kicker_name = user_name;
    end

    if user.jid == kickee_jid then 
  local session = user.sessions[kickee_jid];

  local identity_tag = session:get_child('identity');

            local user_tag = identity_tag:get_child('user');
            local id_tag = user_tag:get_child('id');
            local user_uuid = id_tag:get_text();
            local groupId_tag= user_tag:get_child('groupId');
            local user_groupId = groupId_tag:get_text();
            local email_tag = user_tag:get_child('email');
            local user_email = email_tag:get_text();
            handle_stanza(stanza,"occupant_leaving_lobby",user_groupId,user_email,kicker_name);
  local kicked={userid=user_uuid,roomid=user_groupId}
  table.insert(t,kicked);
    end
  end
  -- for _,v in pairs(t) do
  --   print('\t',v)
  -- end
  module:log("info","kicker name  is : %s", kicker_name)
  room:set_affiliation(true, kickee_jid, 'outcast');
  room:save();
  
  origin.send(st.stanza('kick_back_to_lobby_success'));
end

function process_main_muc_loaded(main_muc, host_module)
  main_muc_service = main_muc;
  host_module:hook("iq-set/bare/jabber:iq:kick_back_to_lobby", kick_back_to_lobby, 1);
end

function process_host_module(name, callback)
  local function process_host(host)
      if host == name then
          callback(module:context(host), host);
      end
  end

  if prosody.hosts[name] == nil then
      prosody.events.add_handler('host-activated', process_host);
  else
      process_host(name);
  end
end

process_host_module(main_muc_component_config, function(host_module, host)
  local muc_module = prosody.hosts[host].modules.muc;
  if muc_module then
    process_main_muc_loaded(muc_module, host_module);
  else
    prosody.hosts[host].events.add_handler('module-loaded', function(event)
      if (event.module == 'muc') then
        process_main_muc_loaded(prosody.hosts[host].modules.muc, host_module);
      end
    end);
  end
end);


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
    -----
    local occupant_uuid = data.context.user.id
    local affiliation = room:get_affiliation(invitee);
    local user_groupId =  data.context.user.groupId
    for k,v in pairs(t) do
      if occupant_uuid == v.userid and user_groupId == v.roomid and data.moderator ==false then
          --   print('\t',v,occupant_uuid,v.roomid)
          -- table.remove(t,k);
           return
          end
          end


    if not data.moderator and event.occupant.role  == 'participant' then return end
    if data.moderator then
          if not affiliation or affiliation == 0 then
            event.occupant.role = 'participant';
            room:set_affiliation(true, invitee_bare_jid, 'member');
            room:save();
          end
    else
      if not data.autoLobby and is_owner_present(event) and event.occupant.role  == nil then
        module:log("info","participant affiliation it is : %s ",affiliation);
          if not affiliation or affiliation == 0 then
            event.occupant.role = 'participant';
            room:set_affiliation(true, invitee_bare_jid, 'member');
            room:save();
          end
        else
          return
         end
    end
  end);

  host_module:hook('muc-occupant-joined', function (event)
    local occupant_auth_token = event.origin.auth_token;
       if occupant_auth_token == nil then return end
   
       local data, err = jwt.decode(occupant_auth_token);
       -----
       local occupant_uuid = data.context.user.id
       local user_groupId =  data.context.user.groupId
   --    local affiliation = room:get_affiliation(invitee);
       for k,v in pairs(t) do
         if occupant_uuid == v.userid and user_groupId == v.roomid then
              --  print('\t',v,occupant_uuid)
             table.remove(t,k);
              return
             end
             end

   
   end);
   
   
end);



