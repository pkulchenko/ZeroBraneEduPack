--[[ ~previous;04-save-open.lua~ | ~contents;00-contents.lua~ | ~next;06-output.lua~

! Running programs

It would not be that interesting if you could only edit your programs. You want your programs to *do* something, don't you? You can do that by *running* (or *executing*) your program. 

The page you are reading right now is a script that you can execute. Press @F6@ or go to @Project | Run@ menu at the top of the window to run it. You should see a new window open with a rounded square being drawn.
]]

require "spirograph"
spiro(60, -45, -80, 360, 0.002, true)