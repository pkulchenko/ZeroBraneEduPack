require "spirograph"

pncl(ranc())
--    +-------------------- radius of equator circle
--    |    +--------------- radius of the bicycle wheel circle
--    |    |    +---------- (optional) position of the drawing point (reflector)
--    |    |    |   +------ (optional) resolution of the graph
--    v    v    v   v    v- (optional) optional delay in seconds
spiro(125, 23, 53, 360, 0.001)
wait()

-- Try varying the equator circle radius to make a smaller donut
-- Try changing the bicycle wheel radius to positive numbers
