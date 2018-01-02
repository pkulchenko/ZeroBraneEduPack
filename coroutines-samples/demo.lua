-- Simulate crash in coroutine ID 2 at 99.99%. Run for 20 seconds
local info = {crash = {0.9999, 2}, time = 20, tablen = 10000, thrcnt = 4, out = {}, obj = {}, data = {}}

-- Thread factory
local function newRoutine(id, t, n, all, terr)
  return coroutine.create(function(t, n, terr)
    for i = 1, n do
      if(terr and next(terr)) then
        marg = tonumber(terr[1])
        maid = tonumber(terr[2])
        if(marg > 0 and marg < 1 and maid > 1) then
         if(id == maid and (i > (marg * n))) then n = t..n end 
        end
      end
      t[i] = (i ^ i / i * (i - 64))
      all[id] = ("%10.4f"):format(100*(i/n)).."% "
      print(unpack(all))
      coroutine.yield()
    end
  end)
end

-- Allocate stuff
for id = 1, info.thrcnt do
  info.data[id] = {}
  info.obj[id] = newRoutine(id, info.data[id], info.tablen, info.out)
end

-- Resume the paused coroutines
clk, dead, crash, endt, exit = os.clock(), 0, 0, 0, false
while((os.clock() - clk) < info.time and not exit) do
  dead = 0
  for id = 1, #info.obj do
    local rut = info.obj[id]
    if(rut) then
      local sta = coroutine.status(rut)
      if(sta == "suspended") then
        local suc = coroutine.resume(rut, info.data[id], info.tablen, info.crash)
        if(not suc) then crash, info.obj[id] = (crash + 1)
          -- Remove the crashed toutine
          print("Thre has been an error executing coroutine #"..id)
          if((dead + crash) >= info.thrcnt) then
              endt, exit = (os.clock() - clk), true; break end
        end
      elseif(sta == "dead") then dead = dead + 1
        if((dead + crash) >= info.thrcnt) then
            endt, exit = (os.clock() - clk), true; break end
      elseif(sta == "running") then 
        -- Nothing to be controlled here cince the current thread is running
      end
    end
  end
end

print("")
if(info.thrcnt == dead) then
  print("All "..dead.." threads completed in "..endt.." of "..info.time.." seconds")
else
  print("Completed "..dead.." of "..info.thrcnt.." threads in "..endt.." of "..info.time.." seconds")
end
