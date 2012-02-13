require "spirograph"

pncl("#A0A0A0")
--    +-------------------- radius of equator circle
--    |    +--------------- radius of the bicycle wheel circle
--    |    |    +---------- (optional) position of the drawing point (reflector)
--    |    |    |   +------ (optional) resolution of the graph
--    v    v    v   v    v- (optional) optional delay in seconds
spiro(60,  34,  60, 360, 0.0)
spiro(60,  79,  60, 360, 0.0)
wait()
