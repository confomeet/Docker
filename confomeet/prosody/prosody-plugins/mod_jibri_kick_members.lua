local LOGLEVEL = "debug"

local it = require "util.iterators"
local st = require "util.stanza"
module:log(LOGLEVEL, "loaded")


module:hook("muc-occupant-left", function (event)
    local room, occupant = event.room, event.occupant

	if string.match(tostring(event.stanza), "recorder@recorder") then
            -- don't destroy room, this will cause an issue
            -- kick all participants
            for _, p in room:each_occupant() do
                    if room:get_affiliation(p.jid) ~= "owner" then
                        room:set_affiliation(false, p.jid, "outcast")
                        module:log(LOGLEVEL, "kick the occupant, %s", p.jid)
                    end
            end

            module:log(LOGLEVEL, "the party finished")
    end
end)