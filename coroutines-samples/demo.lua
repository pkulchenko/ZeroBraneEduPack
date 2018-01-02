-- General inforamtion storage table
-- crash   > Controls thread crashes. Currently at 99.99% crashing thread ID 2
-- time    > How much time the simulation is run for
-- tablen  > The amount of work to be done
-- thrcnt  > How many threads are allocated to do the job in question
-- out     > Stores the output cometion ration in %
-- obj     > The /thread/ object being allocated/created
-- data    > Table which contents are being modified
local info = {crash = {0.9999, 2}, time = 20, tablen = 10000, thrcnt = 4, out = {}, obj = {}, data = {}}

-- Thread factory
local function newRoutine(id, t, n, all, terr)
  return coroutine.create(function(t, n, terr)
    for i = 1, n do
      if(terr and next(terr)) then -- This controls the thread crashing
        marg = tonumber(terr[1])
        maid = tonumber(terr[2])
        if(marg > 0 and marg < 1 and maid > 1) then
         if(id == maid and (i > (marg * n))) then n = t..n end 
        end
      end
      t[i] = (i ^ i / i * (i - 64))
      all[id] = ("%10.4f"):format(100*(i/n)).."%"
      print(unpack(all)) -- Printout out output
      coroutine.yield() -- Make sure to pause this thread for others to do some work
    end
  end)
end

-- Allocate stuff
for id = 1, info.thrcnt do
  info.data[id] = {} -- Allocate the data needed and create threads to fill it
  info.obj[id] = newRoutine(id, info.data[id], info.tablen, info.out, info.crash)
end

-- 
clk, dead, crash, endt, exit = os.clock(), 0, 0, 0, false
while((os.clock() - clk) < info.time and not exit) do
  dead = 0
  for id = 1, #info.obj do
    local rut = info.obj[id]
    if(rut) then
      local sta = coroutine.status(rut)
      if(sta == "suspended") then -- The thread waits to be resumed by the handler
        local suc = coroutine.resume(rut, info.data[id], info.tablen, info.crash)
        if(not suc) then crash, info.obj[id] = (crash + 1)
          -- Remove the crashed routine
          print("There has been an error executing coroutine #"..id)
          if((dead + crash) >= info.thrcnt) then
              endt, exit = (os.clock() - clk), true; break end
        end -- If the thread is dead dont do anyting besides going to the next one
      elseif(sta == "dead") then dead = dead + 1
        if((dead + crash) >= info.thrcnt) then -- Complete all the work
            endt, exit = (os.clock() - clk), true; break end
      elseif(sta == "running") then 
        -- Nothing to be controlled here since the current thread is running
      end
    end
  end
end

print("")
if(info.thrcnt == dead) then
  print("All "..dead.." threads completed in "..endt.." of "..info.time.." seconds")
else
  print("Completed "..dead.." of "..info.thrcnt.." threads in "..((endt~=0) and (endt.." of ") or "")..info.time.." seconds")
end
