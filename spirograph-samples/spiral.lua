require "spirograph"

pncl("#A0A0A0")
--    +-------------------- radius of equator circle
--    |    +--------------- radius of the bicycle wheel circle
--    |    |    +---------- (optional) position of the drawing point (reflector)
--    |    |    |   +------ (optional) resolution of the graph
--    v    v    v   v    v- (optional) optional delay in seconds
spiro(5,   80,  80, 360, 0.0)
fill("#FF0000")
wait()

-- Try changing the equator circle radius to larger values
-- Try vary the bicycle whell circle radius; for example, try 78
-- You may want to set a delay to 0 as some spirals may be long and slow
