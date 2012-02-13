require "spirograph"

--    +-------------------- radius of equator circle
--    |    +--------------- radius of the bicycle wheel circle
--    |    |    +---------- (optional) position of the drawing point (reflector)
--    |    |    |   +------ (optional) resolution of the graph
--    v    v    v   v    v- (optional) optional delay in seconds
spiro(60,  60,  60, 360, 0.01)
wait()

-- Try varying radius of the bicycle wheel using prime numbers around 60
-- How could you get a cardioid oriented differently?
