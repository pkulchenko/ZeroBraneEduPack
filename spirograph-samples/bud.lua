require "spirograph"

pncl("#A0A0A0")
--    +-------------------- radius of equator circle
--    |    +--------------- radius of the bicycle wheel circle
--    |    |    +---------- (optional) position of the drawing point (reflector)
--    |    |    |   +------ (optional) resolution of the graph
--    v    v    v   v    v- (optional) optional delay in seconds
spiro(60, -15, -90, 360, 0.01)
wait()

-- Try changing radius to go from 4 petals to 3 or 6
