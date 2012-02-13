require "spirograph"

pncl(ranc())
pnsz(2)
--    +-------------------------- radius of equator circle
--    |    +--------------------- radius of the bicycle wheel circle
--    |    |    +---------------- (optional) position of the drawing point
--    |    |    |   +------------ (optional) resolution of the graph
--    |    |    |   |    +------- (optional) delay in seconds
--    |    |    |   |    |     +- (optional) show spirograph circles
--    v    v    v   v    v     v
spiro(180,-90, -20, 360, 0.01, true)
wait()

-- What would you change to draw a triangle?
