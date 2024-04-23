local async = require "util.async";
local timer = require "util.timer";
local st = require "util.stanza";

local delay = module:get_option_number("close_room_delay", 30);
local focus_jid = module:get_option_string("focus_user_jid", "focus@auth.meet.jitsi");

module:log("info","room_auto_close module loaded");

function is_owner_present(event)
	local leaver = event.occupant.bare_jid;
	local mods = event.room:each_affiliation("owner");
	for mod in mods do
		module:log("debug", "owner found: %s", tostring(mod));
		if mod ~= leaver and mod ~= focus_jid then
			-- there is still a moderator in this room, dont kick participants
			module:log("debug", "still a moderator present: %s", mod);
			return true;
		end
	end
	return false;
end

local async_destroy = async.runner(function (event)
	local room = event.room;
	local wait, done = async.waiter();
	timer.add_task(delay, function ()
		done();
	end);
	wait(); -- Wait here until done() is called
	if is_owner_present(event) then
		return
	end
	--room:broadcast_message(
		--st.message({
			--from = event.origin.host;
			--type = "groupchat"
		--}):tag("subject"):text("The call is over"):up()
	--);
	room:destroy();
	module:log("debug", "room destroyed.");
end);

module:hook("muc-occupant-left", function(event)
	local barejid = event.occupant.bare_jid;
	local role =  event.room:get_affiliation(barejid);
	module:log("debug", "occupant with role %s left: %s", role, barejid);
	if role == "owner" and barejid ~= focus_jid  and not is_owner_present(event) then
		async_destroy:run(event);
	end
end,150)
