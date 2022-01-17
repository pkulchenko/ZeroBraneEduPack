local matrix  = require("matrix").extend()

print("\nComment the `extend` internal method call to use the matrix library with regular numbers.\n")

local a = {
  {1, 3,-2},
  {3,-5, 6},
  {2, 4, 3}
}

local b = {
  {5},
  {7},
  {8}
} 

local t = {
  {1, 5},
  {2, 6},
  {3, 0},
  {4, 8}
} 

local o = {{7,7}}

local ma = matrix.getNew(a):Print(6, "Start matrix")
local mb = matrix.getNew(b):Print(5, "Vctor-column matrix")
local mx = ma:getSolve(mb):Print(25, "Solved linear equation")
local mt = ma:getNew(t):Print(5, "Rectangle matrix")
local mo = ma:getOnes():Print(5, "Ones matrix")
local ca = ma:getUnit():Print(5, "Unit matrix")
local co = matrix.getNew(o)

ma:getSnip(1,2,1,2):Print(6, "Snipped minor R[1,2] C[1,2]")
