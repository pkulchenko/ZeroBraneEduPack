require "spirograph"

pncl("#F0A0A0")
--    +-------------------- radius of equator circle
--    |    +--------------- radius of the bicycle wheel circle
--    |    |    +---------- (optional) position of the drawing point (reflector)
--    |    |    |   +------ (optional) resolution of the graph
--    v    v    v   v    v- (optional) optional delay in seconds
spiro(18,  65,  72,  60, 0.01)
wait()

-- Try varying the radius of the bicycle wheel
-- Try varying the value of the resolution using small numbers (2-20)
