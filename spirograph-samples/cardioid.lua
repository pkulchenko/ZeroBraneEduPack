require "spirograph"

--    +-------------------------- radius of equator circle
--    |    +--------------------- radius of the bicycle wheel circle
--    |    |    +---------------- (optional) position of the drawing point
--    |    |    |   +------------ (optional) resolution of the graph
--    |    |    |   |    +------- (optional) delay in seconds
--    |    |    |   |    |     +- (optional) show spirograph circles
--    v    v    v   v    v     v
spiro(60,  60,  60, 360, 0.01)
wait()

-- Try varying radius of the bicycle wheel using prime numbers around 60
-- How could you get a cardioid oriented differently?
