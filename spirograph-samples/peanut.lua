require "spirograph"

pncl(ranc())
pnsz(2)
--    +-------------------- radius of equator circle
--    |    +--------------- radius of the bicycle wheel circle
--    |    |    +---------- (optional) position of the drawing point (reflector)
--    |    |    |   +------ (optional) resolution of the graph
--    v    v    v   v    v- (optional) optional delay in seconds
spiro(180,-90, -20, 360, 0.01)
wait()

-- What would you change to make the peanut horizontal?
