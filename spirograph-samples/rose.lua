require "spirograph"

pncl("#F0A0A0")
--    +-------------------- radius of equator circle
--    |    +--------------- radius of the bicycle wheel circle
--    |    |    +---------- (optional) position of the drawing point (reflector)
--    |    |    |   +------ (optional) resolution of the graph
--    v    v    v   v    v- (optional) optional delay in seconds
spiro(60,  15,  45, 360, 0.01)
wait()

-- Try varying one of the radiuses to get 3, 5, or 6 leaves
-- Try changing the bicycle wheel radius sign to get different leaf shapes
