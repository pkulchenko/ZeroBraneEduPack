require "spirograph"

pncl("#F0A0A0")
--    +-------------------- radius of equator circle
--    |    +--------------- radius of the bicycle wheel circle
--    |    |    +---------- (optional) position of the drawing point (reflector)
--    |    |    |   +------ (optional) resolution of the graph
--    v    v    v   v    v- (optional) optional delay in seconds
spiro(60,  59,  60, 180, 0.001)
wait()

-- Try changing the equator circle radius
-- Also try setting the resolution of the graph to small numbers
