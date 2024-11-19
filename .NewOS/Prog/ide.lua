--[[

ed v0.3
by KinoftheFlames

ed is an IDE intended to replace the native file editor "edit".
The goal of this program is to make editting lua programs for ComputerCraft as fluid as possible.

For more info and to report any bugs: http://www.computercraft.info/forums2/index.php?/topic/4270-wip-in-game-ideedit-program/
								   or goo.gl/8YjYr
								   or adf.ly/D9MQy
CONTROLS:
F1 - Menu
F3 - Save
F4 - Exit
F5 - Run
F6 - Run with arguments
F12 - Help

CHANGELOG for v0.3:
This feels like a big update to me, because a couple major goals were reached, and ed is officially over 1,000 lines of code! Woo!

Disclaimer:
Until I can think of a good way to represent menus in the turtle's screen, consider ed to be terminal-only support.
You can still do most things on turtles, but menu text will run off screen and you won't be able to see what settings you are changing.
However you are still able to edit the settings manually by opening up the settings file after going into the settings menu once to generate the file.

Changes:
- Added insertion/overwrite toggle
- Added status bar (optional) with the following information (which is all optional):
   -- Current line number
   -- Total line count (off by default)
   -- Insert/overwrite toggle display
- Added debugging. The file no longer needs to be force-saved to run it, and if there are any run-time errors ed will move the cursor to the error line and display the error.
- You can now run ed from ed as recursively as you'd like and everything should work properly (yo dawg!)
- Added auto-tabbing
- Trying to edit files in non-existant directories now creates those directories
- Added settings menu, you can finally customize the UI without editing the code!.
   -- Press F1 to access it, then use the arrow keys and space/enter to interact.
- Settings will automatically save on menu exit and load with the program - change it once and you're good! Settings are saved to ".ed_settings" and will overwrite all files and directories (sorry!)
- Added help screen (F12) that shows users the controls. By default "F12 = help" is shown in the status bar so no one is left wondering how to save, exit, etc, their first time.

]]

--argument handling
local arg = { ... }
if #arg == 0 then --verify argument exists
	print("Syntax: editor <path>")
	error()
end
if fs.isDir(arg[1]) then --verift not a directory
	print("Error: cannot edit a directory as a file")
	error()
end

--debug
local bDebug = true --display debugging info if true
local bClearDebug = false --determines if debug is cleared from screen every loop or not
local sDebugText = "" --debug text shown if debugging is on

--constants
local VERSION = "v0.3"
local SCREEN_ORIGIN = 1 --top left of screen
local SCREEN_WIDTH, SCREEN_HEIGHT = term.getSize() --width and height of screen
local TIMER_INTERVAL = 300.0 --in seconds (DO NOT SET TO 0, that would be infinite)
local SETTINGS_FILEPATH = ".ed_settings" --where user settings are located

--settings (defaults)
local bShowLineNum = true --toggle visibility of line numbers
local bShowLineNumSep = true --toggle visibility of line numbers seperator
local bShowStatusBar = true --toggle visibility of the line of information at the bottom of the screen
	--toggle visibility of individual status information
	local bStatus_lineNum = true
	local bStatus_lineCount = false
	local bStatus_insert = true
	local bStatus_help = true
local bShowMessages = true --toggle displaying of messages at the bottom of the screen
local nMinLineDigitsVisible = 1 --[POS] defines how much area for the line numbers is displayed at minimum (program will expand space as needed)
local nSpacesPerTab = 3 --[POS] defines how many visual spaces are in a tab

--toggles
local bInsert = true --insert text if true, override text if false

--flags
local bUnsavedChanges = false --tracks whether the file in the editor has been changed since last saved, helps with exit before saving confirmation
local bConfirmingExit = false --if the user tries to exit without saving, this requires them to try again before succeeding

--variables
local bRunning = true --false when the program exits
local sFilepath = arg[1] --path to the file being editted
local tFile = { } --table of lines for the file being editted
local xMin, yMin = SCREEN_ORIGIN, SCREEN_ORIGIN --min values for file display
local xMax, yMax = SCREEN_WIDTH, SCREEN_HEIGHT --max values for file display
local xFile, yFile = 1, 1 --the location of the cursor in the text file
local xScroll, yScroll = 0, 0 --amount file is scrolled on screen
local sStatus = "" --text displayed for the status bar at the bottom of the screen
local sMessage = "" --message displayed at the bottom of the screen until next input
local sArguments = "" --stores the last arguments used, bringing them up again when run w/ arguments is called
local sError = "" --stores error information from failed program execution for debugging
local tTimer --timer for main loop and time-based events

------------------------
--      EXTERNAL      --
------------------------

--converts a string to a boolean
function toboolean(value)
	if value == "true" then return true end
	if value == "false" then return false end
end



------------------------
--    FILE HANDLING   --
------------------------

--load a file from hdd into editor
function load()
	--error handling file
	if fs.exists(sFilepath) then
		--load file
		local file = fs.open(sFilepath, "r")
		while true do
			local line = file.readLine()
			if line == nil then --if reached end of file
				break end
			
			table.insert(tFile, line)
		end
		file.close()
	else
		table.insert(tFile, "")
	end
end

--save editor's text to a file
function save()
	sMessage = "SAVING..."
	draw()
	
	if bUnsavedChanges then --only save if needed (saves on CPU time)
		--create directory if it doesn't exist
		local dir = string.sub(sFilepath, 1, #sFilepath - #fs.getName(sFilepath))
		if not fs.exists(dir) then
			fs.makeDir(dir) end
		
		--write to file
		local file = fs.open(sFilepath, "w")
		for i,line in ipairs(tFile) do
			file.writeLine(line) end
		file.close()
	end
	
	sMessage = "SAVED to " .. sFilepath
	bUnsavedChanges = false
end

function loadSettings()
	if fs.exists(SETTINGS_FILEPATH) and not fs.isDir(SETTINGS_FILEPATH) then
		file = fs.open(SETTINGS_FILEPATH, "r")
		
		--load settings
		while true do
			local line = file.readLine()
			if line == nil then --EOF
				break end
			local v1, v2 = string.find(line, " = ") --finds delimitter location
			local var = string.sub(line, 1, v1-1) --name of variable
			local value = string.sub(line, v2+1) --value of variable
			
			if var == "bShowLineNum" then bShowLineNum = toboolean(value) end
			if var == "bShowLineNumSep" then bShowLineNumSep = toboolean(value) end
			if var == "bShowStatusBar" then bShowStatusBar = toboolean(value) end
			if var == "bStatus_lineNum" then bStatus_lineNum = toboolean(value) end
			if var == "bStatus_lineCount" then bStatus_lineCount = toboolean(value) end
			if var == "bStatus_insert" then bStatus_insert = toboolean(value) end
			if var == "bStatus_help" then bStatus_help = toboolean(value) end
			if var == "bShowMessages" then bShowMessages = toboolean(value) end
			if var == "nMinLineDigitsVisible" then nMinLineDigitsVisible = tonumber(value) end
			if var == "nSpacesPerTab" then nSpacesPerTab = tonumber(value) end
		end
		
		file.close()
	end
end

function saveSettings()
	if fs.isDir(SETTINGS_FILEPATH) then --if a dir with settings filepath exists, delete it (sorry!)
		fs.delete(SETTINGS_FILEPATH)
	end
	
	file = fs.open(SETTINGS_FILEPATH, "w")
	
	--save settings
	file.writeLine("bShowLineNum = "..tostring(bShowLineNum))
	file.writeLine("bShowLineNumSep = "..tostring(bShowLineNumSep))
	file.writeLine("bShowStatusBar = "..tostring(bShowStatusBar))
	file.writeLine("bStatus_lineNum = "..tostring(bStatus_lineNum))
	file.writeLine("bStatus_lineCount = "..tostring(bStatus_lineCount))
	file.writeLine("bStatus_insert = "..tostring(bStatus_insert))
	file.writeLine("bStatus_help = "..tostring(bStatus_help))
	file.writeLine("bShowMessages = "..tostring(bShowMessages))
	file.writeLine("nMinLineDigitsVisible = "..tostring(nMinLineDigitsVisible))
	file.writeLine("nSpacesPerTab = "..tostring(nSpacesPerTab))
	
	file.close()
	sMessage = "Settings saved"
end


------------------------
--       VISUAL       --
------------------------

--scrolls the screen with the cursor
function scroll()
	alignCursor()
	local x,y = term.getCursorPos()
	
	if y > yMax then
		yScroll = yScroll + (y - yMax)
	elseif y < yMin then
		yScroll = yScroll - (yMin - y)
	end
	if x > xMax then
		xScroll = xScroll + (x - xMax)
	elseif x < xMin then
		xScroll = xScroll - (xMin - x)
	end
end

--brings the visual cursor to the location of the cursor in file
function alignCursor()
	local charsLeftOfCursor = string.sub(tFile[yFile], 1, xFile-1) --chars left of cursor
	local dummy, numTabs = string.gsub(charsLeftOfCursor, "\t", "\t") --gets the number of tabs
	
	local x = xMin + (xFile - 1) - xScroll + numTabs * (nSpacesPerTab - 1)
	local y = yMin + (yFile - 1) - yScroll
	
	term.setCursorPos(x, y)
end

--moves cursor around
function shiftCursor(xShift, yShift)
	--format input for error handling
	if yFile + yShift < 1 then
		yShift = -(yFile - 1)
	elseif yFile + yShift > #tFile then
		yShift = #tFile - yFile
	end
		
	
	--handle left/right movement
	if xFile == 1 and xShift < 0 then --if at start of line and moving left, move to end of above line (if exists)
		if yFile ~= 1 then
			xFile = #tFile[yFile-1] + 1
			yFile = yFile - 1
		end
	elseif xFile > #tFile[yFile] and xShift > 0 then --if at end of line and moving right, move to start of next line (if exists)
		if yFile ~= #tFile then
			xFile = 1
			yFile = yFile + 1
		end
	else --horizontal only movement
		xFile = xFile + xShift--normal move
	end
	
	--handle up/down movement
	if yFile == 1 and yShift < 0 then --if at first line and moving up, move to start of line
		xFile = 1
	elseif yFile == #tFile and yShift > 0 then --if at last line and moving down, move to end of line
		xFile = #tFile[yFile] + 1
	else --vertical only movement
		yFile = yFile + yShift --normal move
		
		--if the cursor is past the end of the last character after having moved, move it to the last character
		if xFile > #tFile[yFile] then
			xFile = 1 + #tFile[yFile]
		end
	end
end

--move cursor to the start of the line
function shiftCursorHome()
	xFile = 1
end

--move cursor to the end of the line (end of text)
function shiftCursorEnd()
	xFile = 1 + #tFile[yFile]
end

--adjusts borders of editable area depending on settings and situational factors
function applyBoundrySettings()
	if bShowLineNum then
		local chars = #tostring(#tFile) --characters in line num area = num of digits of last line
		if nMinLineDigitsVisible > chars then --unless there is a minimum character count to enforce which is greater
			chars = nMinLineDigitsVisible end
		xMin = chars + 2 --adjust boundry for editable area
	else
		xMin = SCREEN_ORIGIN end
	
	if bShowStatusBar then
		yMax = SCREEN_HEIGHT - 1
	else
		yMax = SCREEN_HEIGHT end
end



------------------------
--      DRAWING       --
------------------------

--redraws entire screen
function draw()
	--clear screen
	term.clear()
	
	--draw line numbers
	if bShowLineNum then
		drawLineNum() end
	
	--draw file text
	for i=yMin,yMax do
		if tFile[i+yScroll] ~= nil then --if haven't reached end of file
			term.setCursorPos(xMin, i)
			local modifiedLine = string.gsub(tFile[i+yScroll], "\t", string.rep(" ", nSpacesPerTab)) --replace visual line's tab characters with defined num of spaces
			term.write(string.sub(modifiedLine, 1 + xScroll, xMax - xMin + 1 + xScroll)) --only draw visible text
		end
	end
	
	--draw status bar
	if bShowStatusBar then
		drawStatusBar() end
	
	--draw message
	if bShowMessages then
		drawMessage() end
	
	--draw debug
	if bDebug then
		drawDebug(sDebugText) end
	
	--place visual cursor in correct position
	alignCursor()
end

--draws line numbers and seperator
function drawLineNum()
	applyBoundrySettings()
	local chars = #tostring(#tFile) --characters in line num area = num of digits of last line
	if nMinLineDigitsVisible > chars then --unless there is a minimum character count to enforce which is greater
		chars = nMinLineDigitsVisible end
	
	for i=yMin,yMax do
		local lineNum = i+yScroll --line number of file line being drawn
		if tFile[lineNum] ~= nil then --don't draw line numbers for lines that dont exists in the file
			local numSpaces = chars - #tostring(lineNum) --spaces required to right-align numbers
			
			--draw finally
			term.setCursorPos(SCREEN_ORIGIN, i)
			term.write(string.rep(" ", numSpaces)) --spaces before line number
			term.write(tostring(lineNum)) --line number
			if bShowLineNumSep then
				term.write("|") end --seperator --TODO: add customizable line seperator (single char)
		end
	end
	
	--sDebugText = sDebugText .. " xMin:"..xMin
end

--draw bar with information at the bottom of the screen
function drawStatusBar()
	sStatus = "--< " --paint me like one of your french girls
	
	local charsLeft = SCREEN_WIDTH - 8 --characters available to print
	local nextAdd = "" --next info to add to status bar
	
	--help info
	if bStatus_help then
		nextAdd = "Help:F12"
		charsLeft = addStatus(nextAdd, charsLeft)
	end
	
	--line cursor is on
	if bStatus_lineNum then
		nextAdd = "Ln " .. yFile --cur line
		if bStatus_lineCount then --line count
			nextAdd = nextAdd .. "/" .. #tFile end
		
		charsLeft = addStatus(nextAdd, charsLeft)
	elseif bStatus_lineCount then
		nextAdd = #tFile .. " lines" --line count
		charsLeft = addStatus(nextAdd, charsLeft)
	end
	
	--INS for insert text, OVR for overwrite text
	if bStatus_insert then
		if bInsert then
			nextAdd = "INS"
		else
			nextAdd = "OVR" end
		charsLeft = addStatus(nextAdd, charsLeft)
	end
	
	sStatus = sStatus .. string.rep(" ", charsLeft) --filler
	sStatus = sStatus .. " >--" --paint me like one of your french girls
	
	--draw the bar
	term.setCursorPos(SCREEN_ORIGIN,SCREEN_HEIGHT)
	term.write(sStatus)
end

--push next status on to the status text
function addStatus(sText, nCharsLeft)
	if nCharsLeft >= #sText + 2 then --if status can fit wholly on line
		if #sStatus <= 4 then --if first status added
			sStatus = sStatus .. sText
			nCharsLeft = nCharsLeft - #sText --reduce remaining space for statuses
		else
			sStatus = sStatus .. "  " .. sText
			nCharsLeft = nCharsLeft - (#sText + 2) --reduce remaining space for statuses
		end
	end
	return nCharsLeft
end

--draw general message at the bottom of the screen for one loop
function drawMessage()
	if sMessage == "" then
		return end
	
	--truncates message
	sMessage = string.sub(sMessage, 1, SCREEN_WIDTH - 8)
	
	--add dashes on the side to draw attention
	local fillerDrawn = ((SCREEN_WIDTH - #sMessage)/2)-2 --num dashes on one side
	
	if fillerDrawn < 2 then
		fillerDrawn = 2 end
	
	local printedText = string.rep("-", fillerDrawn) .. "< " .. sMessage .. " >" .. string.rep("-", fillerDrawn + 1)
	
	--display message
	term.setCursorPos(SCREEN_ORIGIN,SCREEN_HEIGHT) --bottom left
	term.write(printedText)
end

--display debug info in bottom right
function drawDebug(sText)
	term.setCursorPos(SCREEN_WIDTH + 1 - #sText, SCREEN_HEIGHT) --set cursor at bottom rightmost while still showing all text
	term.write(sText)
end

--draw menu
function drawMenu(tMenu, nSel)
	--ALL HARD CODED POSITIONS ATM
	local xText,yText = SCREEN_ORIGIN+2, SCREEN_ORIGIN+2
	local xParam, yParam = xText + 40, SCREEN_ORIGIN+2
	
	for i,option in ipairs(tMenu) do
		--write text
		term.setCursorPos(xText, yText + (i-1))
		term.write(option.text)
		
		--write value
		if nSel == i then
			term.setCursorPos(xParam-2, yParam + (i-1))
			term.write("[ " .. tostring(option.value) .. " ]") --draw brackets to indicate selection
		else
			term.setCursorPos(xParam, yParam + (i-1))
			term.write(tostring(option.value))
		end
	end
end

--the background for the menu
function drawMenu_bg()
	local line = ""
	
	--draw top line
	local centerText = " ed "..VERSION.." "
	local nonDashSpace = SCREEN_WIDTH - 2 - #centerText
	local dashes = string.rep("-", nonDashSpace/2)
	line = "o"..dashes..centerText..dashes
		if nonDashSpace % 2 ~= 0 then --handling for odd screen widths
			line = line.."-o"
		else
			line = line.."o" end
	term.setCursorPos(SCREEN_ORIGIN, SCREEN_ORIGIN)
	term.write(line)
	
	--draw inbetween lines
	for i=SCREEN_ORIGIN+1,SCREEN_HEIGHT-1 do
		line = "|"..string.rep(" ", SCREEN_WIDTH-2).."|"
		term.setCursorPos(SCREEN_ORIGIN, i)
		term.write(line)
	end
	
	--draw bottom line
	line = "O"..string.rep("-", SCREEN_WIDTH-2).."O"
	term.setCursorPos(SCREEN_ORIGIN, SCREEN_HEIGHT)
	term.write(line)
end


------------------------
--      DEBUGGING     --
------------------------

--run the program being edited
function run(bArguments)
	local tArguments = {}
	
	--get arugments for program execution
	if bArguments then
		--draw seperator dashes below argument input
		term.setCursorPos(SCREEN_ORIGIN,SCREEN_ORIGIN+1)
		term.write(string.rep("-", SCREEN_WIDTH))
		
		--clear top line and get arguments
		term.setCursorPos(SCREEN_ORIGIN,SCREEN_ORIGIN)
		term.clearLine()
		term.write("Arguments: ")
		sArguments = read(nil, sArguments)
		
		--format arguments (stolen from shell)
		for match in string.gmatch(sArguments, "[^ \t]+") do --grabs each argument, space/tab delimitted
			table.insert(tArguments, match)
		end
	end
	
	--save() --save so its running the program in the editor
	term.clear()
	term.setCursorPos(SCREEN_ORIGIN,SCREEN_ORIGIN)
	--local progSuccess = shell.run(sFilepath, unpack(tArguments)) --OLD WAY (calling without debugging)
	sError = ""
	local progSuccess = runCatchErrors(table.concat(tFile, "\n"), unpack(tArguments))
	
	--formats error info
	if sError and sError ~= "" then
		local s1, s2 = string.find(sError, "%d+:") --the editor
		local errorStart, v = string.find(string.sub(sError, s2), "%d+:") --the executed code
		if errorStart ~= nil then
			sError = string.sub(string.sub(sError, s2), errorStart) --removed editor pre-error text
		else
			sError = string.sub(sError, s1) --removed executed pre-error text (name and colon)
		end
	end
	
	--display whether program succeeded or failed, then prompt to continue
	if progSuccess then
		sMessage = "SUCCESS - Press any key"
	else
		sMessage = "FAILED - Press any key" end
	drawMessage()
	
	while true do
		e, p1 = os.pullEvent()
		if e == "timer" and p1 == tTimer then
			--tTimer = os.startTimer(TIMER_INTERVAL) --reset timer
		elseif e == "key" then
			break end
	end
	os.sleep(0) --if the key pressed produces a "char" event, this prevents it from going to the next input loop
	
	initializeSystem() --reset program systerm-oriented settings (in case they've been changed)
	
	if sError and sError ~= "" then --moves cursor to error line and display error message
		local v1, v2 = string.find(sError, "%d+") --get error line
		local errorLine = tonumber(string.sub(sError, v1, v2))
		xFile = 1
		yFile = errorLine
		sMessage = sError
	else --no error
		sMessage = "" end
end

--specialized function to run a file and catch the runtime errors
--Courtesy of faubiguy
function runCatchErrors( sProgram, ... ) --sProgram is a string containing the current text. Any other arguments are arguments to the program.
    local tArgs = { ... }
    local fnFile, err = loadstring( sProgram )
    if fnFile then
        local tEnv = {["shell"] = shell}
        setmetatable( tEnv, { __index = _G } )
        setfenv( fnFile, tEnv )
        local ok, err = pcall( function()
                fnFile( unpack( tArgs ) )
        end )
        if not ok then
                if err and err ~= "" then
                        print( err )
                        sError = err -- sError is the variable where you want the error
                end
                return false
        end
                sError = "" -- error value set to "" on successful execution
        return true
    end
    if err and err ~= "" then
                print( err )
                sError = err -- Again replace sError with the variable where you want the error
        end
    return false
end

------------------------
--       TYPING       --
------------------------

--inserts characters the user types in
function insertText(sText)
	local removeChar = 0
	if not bInsert then --overwrite the next char instead of inserting if settings say so
		removeChar = 1 end
	
	--insert/overwrite text
	tFile[yFile] = string.sub(tFile[yFile], 1, xFile-1) .. sText .. string.sub(tFile[yFile], xFile + removeChar)
	
	shiftCursor(#sText, 0)
	bUnsavedChanges = true
end

--key press: enter
function key_enter()
	if xFile <= #tFile[yFile] then --if cursor is between characters
		table.insert(tFile, yFile+1, string.sub(tFile[yFile], xFile)) --move remainder of characters to a new line
		tFile[yFile] = string.sub(tFile[yFile], 1, xFile-1) --and delete the moved characters from the previous line
	else --cursor at the end of the line
		table.insert(tFile, yFile+1, "")
	end
	
	--move cursor to begining of line and down
	shiftCursorHome()
	shiftCursor(0,1)
	
	--auto insert tabs equal to number on last line
	local v, numTabs = string.find(tFile[yFile-1], "[\t]+")
	if v ~= 1 or numTabs == nil then --tabs found, but not at the start of the line
		numTabs = 0 end
	insertText(string.rep("\t", numTabs))
	
	bUnsavedChanges = true
end

--key press: backspace
function key_backspace()
	if not (yFile == 1 and xFile == 1) then --if not at the first character in the file
		if xFile == 1 then --if at the start of a line, concatenate line above with this line
			shiftCursor(0,-1)
			shiftCursorEnd()
			
			tFile[yFile] = tFile[yFile] .. tFile[yFile+1] --concat lines
			table.remove(tFile, yFile+1) --remove second line
		else --otherwise just delete one character
			shiftCursor(-1,0)
			tFile[yFile] = string.sub(tFile[yFile], 1, xFile-1) .. string.sub(tFile[yFile], xFile+1)
		end
		bUnsavedChanges = true
	end
end

--key press: delete
function key_delete()
	if not (yFile == #tFile and xFile == #tFile[yFile] + 1) then --if not at the last character in the file
		if xFile > #tFile[yFile] then --if cursor is at the end of the line, concatenate with line below
			tFile[yFile] = tFile[yFile] .. tFile[yFile+1] --concat lines
			table.remove(tFile, yFile+1) --remove second line
		else --otherwise just delete one character
			tFile[yFile] = string.sub(tFile[yFile], 1, xFile-1) .. string.sub(tFile[yFile], xFile+1)
		end
		bUnsavedChanges = true
	end
end



------------------------
--        MENU        --
------------------------

function menuInit_settings()
	local opShowLineNum = {	text = "Show line numbers",
							type = "bool",
							param = nil,
							value = bShowLineNum }
	local opShowLineNumSep = {	text = "Show line number seperator",
								type = "bool",
								param = nil,
								value = bShowLineNumSep }
	local opShowStatusBar = {	text = "Show status bar",
								type = "bool",
								param = nil,
								value = bShowStatusBar }
		local opStatus_lineNum = {	text = "Show status - line number",
									type = "bool",
									param = nil,
									value = bStatus_lineNum }
		local opStatus_lineCount = {	text = "Show status - line count",
										type = "bool",
										param = nil,
										value = bStatus_lineCount }
		local opStatus_insert = {	text = "Show status - insert",
									type = "bool",
									param = nil,
									value = bStatus_insert }
		local opStatus_help = {	text = "Show status - help",
									type = "bool",
									param = nil,
									value = bStatus_help }
	local opShowMessages = {	text = "Show messages",
								type = "bool",
								param = nil,
								value = bShowMessages }
	local opMinLineDigitsVisible = {	text = "Min line num characters shown",
										type = "number",
										param = { 1, nil },
										value = nMinLineDigitsVisible }
	local opSpacesPerTab = {	text = "Spaces per tab",
								type = "number",
								param = { 1, nil },
								value = nSpacesPerTab }
	
	local menu = { 	opShowLineNum,
					opShowLineNumSep,
					opShowStatusBar,
					opStatus_lineNum,
					opStatus_lineCount,
					opStatus_insert,
					opStatus_help,
					opShowMessages,
					opMinLineDigitsVisible,
					opSpacesPerTab }
	
	return menu
end

--top level menu accessed via F1
function menu()
	os.sleep(0) --prevents runover input from accessing the menu
	term.setCursorBlink(false) --HARDCODED
	local tMenu = menuInit_settings() --HARDCODED intializing values
	
	nSel = 1 --index of selected element
	opBack = { 	text = "",
				type = "exit",
				param = nil,
				value = "BACK" }
	table.insert(tMenu, opBack)
	
	--draw
	drawMenu_bg()
	drawMenu(tMenu, nSel)
	
	local bRunning = true
	while bRunning do
		--input
		local e, p1 = os.pullEvent()
		if e == "timer" and p1 == tTimer then --main loop interval timer
			tick()
		else --user input (IMPORTANT distinction)
			if e == "key" then --key input
				if p1 == keys.up then --UP
					if nSel > 1 then
						nSel = nSel - 1 --move selection up
					else
						nSel = #tMenu end --move selection to bottom
						
				elseif p1 == keys.down then --DOWN
					if nSel < #tMenu then
						nSel = nSel + 1 --move selection down
					else
						nSel = 1 end --move selection to top
						
				elseif p1 == keys.left then --LEFT
					if tMenu[nSel].type == "bool" then --if bool
						tMenu[nSel].value = not tMenu[nSel].value --flip bool value
					elseif tMenu[nSel].type == "number" then --if number
						if tMenu[nSel].param[1] == nil then --if no min then decrease number
							tMenu[nSel].value = tMenu[nSel].value - 1
						elseif tMenu[nSel].value > tMenu[nSel].param[1] then --if num is above min then decrease number
							tMenu[nSel].value = tMenu[nSel].value - 1 end
					elseif tMenu[nSel].type == "table" then --if table
						
					end
				elseif p1 == keys.right then --RIGHT
					if tMenu[nSel].type == "bool" then --if bool
						tMenu[nSel].value = not tMenu[nSel].value --flip bool value
					elseif tMenu[nSel].type == "number" then --if number
						if tMenu[nSel].param[2] == nil then --if no max then increase number
							tMenu[nSel].value = tMenu[nSel].value + 1
						elseif tMenu[nSel].value < tMenu[nSel].param[2] then --if num is below max then increase number
							tMenu[nSel].value = tMenu[nSel].value + 1 end
					elseif tMenu[nSel].type == "table" then --if table
						
					end
				
				elseif p1 == keys.enter then --ENTER
					if tMenu[nSel].type == "exit" then --exit menu
						bRunning = false
					elseif tMenu[nSel].type == "bool" then --flip bool value
						tMenu[nSel].value = not tMenu[nSel].value
					end
				
				elseif p1 == keys.space then --SPACE
					if tMenu[nSel].type == "exit" then --exit menu
						bRunning = false
					elseif tMenu[nSel].type == "bool" then --flip bool value
						tMenu[nSel].value = not tMenu[nSel].value
					end
				
				elseif p1 == keys.f1 then --F1
					bRunning = false
				
				elseif p1 == keys.f4 then --F4
					bRunning = false
				end
			end
		end
		
		--draw
		drawMenu_bg()
		drawMenu(tMenu, nSel)
	end
	
	--hardcoded grabbing values
	bShowLineNum = tMenu[1].value
	bShowLineNumSep = tMenu[2].value
	bShowStatusBar = tMenu[3].value
	bStatus_lineNum = tMenu[4].value
	bStatus_lineCount = tMenu[5].value
	bStatus_insert = tMenu[6].value
	bStatus_help = tMenu[7].value
	bShowMessages = tMenu[8].value
	nMinLineDigitsVisible = tMenu[9].value
	nSpacesPerTab = tMenu[10].value
	
	saveSettings()
	
	term.setCursorBlink(true) --HARDCODED (asumes top layer)
	applyBoundrySettings() --HARDCODED (asumes top layer)
	
	os.sleep(0) --prevent carryover input
end

--shows controls to new users
function help()
	term.setCursorBlink(false)
	drawMenu_bg()
	local xText, yText = SCREEN_ORIGIN+2,SCREEN_ORIGIN+2
	local tText = {	"Welcome to ed "..VERSION.."!",
					"ed is an editor/IDE designed to replace \"edit\"",
					"For more info / latest release: goo.gl/8YjYr",
					"                             or adf.ly/D9MQy",
					"Controls:",
					"F1 - Menu",
					"F3 - Save",
					"F4 - Exit",
					"F5 - Run",
					"F6 - Run with arguments",
					"F12 - Help" }
	
	--write out tText
	for i=1, #tText do
		term.setCursorPos(xText, yText + i - 1)
		term.write(tText[i])
	end
	
	term.setCursorPos(xText, SCREEN_HEIGHT-2)
	term.write("Press any key to return to the editor.")
	
	--wait for input
	os.sleep(0) --prevents rollover input
	os.pullEvent()
	term.setCursorBlink(true)
	os.sleep(0) --prevent rollover input
end



------------------------
--        CORE        --
------------------------

--initializes system settings (this is called at startup and after program execution)
function initializeSystem()
	term.setCursorBlink(true)
	alignCursor()
end

--intialization
function intialize()
	load() --load file
	loadSettings() --loads user settings
	
	--setup screen
	applyBoundrySettings()
	draw()
	initializeSystem()
end

--handles user input
function input()
	--wait for key input
	local e, p1 = os.pullEvent()
	
	--timer input
	if e == "timer" and p1 == tTimer then --main loop interval timer
		tick()
	else --user input (IMPORTANT distinction)
		sMessage = "" --clear message
		
		--EXIT if confirmed, otherwise reset confirmation flag
		if bConfirmingExit == true and e == "key" and p1 == keys.f4 then
			exit()
		else
			bConfirmingExit = false end
		
		--character input
		if e == "char" then
			insertText(p1)
		
		--non-character, key input
		elseif e == "key" then
			--DONT USE F2, F10, F11, ALT, ESC
			
			--functions
			if p1 == keys.f1 then --menu
				menu()
			elseif p1 == keys.f3 then --save
				save()
			elseif p1 == keys.f4 then --exit
				exit()
			elseif p1 == keys.f5 then --run program in editor
				run(false)
			elseif p1 == keys.f6 then --run with arguments
				run(true)
			elseif p1 == keys.f12 then --run help
				help()
				
			--movement
			elseif p1 == keys.up then --up
				shiftCursor(0, -1)
			elseif p1 == keys.down then --down
				shiftCursor(0, 1)
			elseif p1 == keys.left then --left
				shiftCursor(-1, 0)
			elseif p1 == keys.right then --right
				shiftCursor(1, 0)
			elseif p1 == keys.home then --home
				shiftCursorHome()
			elseif p1 == keys["end"] then --end
				shiftCursorEnd()
			elseif p1 == keys.pageUp then --pasge up
				shiftCursor(0, -(yMax-yMin))
			elseif p1 == keys.pageDown then --page down
				shiftCursor(0, yMax-yMin)
			
			--removing characters
			elseif p1 == keys.backspace then --backspace
				key_backspace()
			elseif p1 == keys.delete then --delete
				key_delete()
			
			--adding whitespace
			elseif p1 == keys.enter then --enter
				key_enter()
			elseif p1 == keys.tab then --tab
				insertText("\t")
				bUnsavedChanges = true
				
			--insert
			elseif p1 == keys.insert then
				bInsert = not bInsert
			
			end
		end
	end
end

--main timer interval actions
function tick()
	--do interval stuff
	--insertText("HI")
	--sMessage = "TIMER HIT!"
	
	--tTimer = os.startTimer(TIMER_INTERVAL) --reset timer
end

--main loop
function mainLoop()
	--tTimer = os.startTimer(TIMER_INTERVAL) --start interval timer
	
	while bRunning do
		if bClearDebug then
			sDebugText = "" end --clear debug info
		
		input() --get input and respond
		
		--debug info
		local x,y = term.getCursorPos()
		--sDebugText = sDebugText .. " Running:" ..tostring(bRunning)
		--sDebugText = sDebugText .. " File:"..xFile..","..yFile .." Scrn:"..x..","..y
		
		scroll() --shift screen to show cursor
		draw() --update screen
	end
end

--exit program
function exit()
	if bUnsavedChanges and not bConfirmingExit then --if there are unsaved changes, and this warning hasnt displayed yet
		sMessage = "UNSAVED CHANGES - Press F4 to exit"
		bConfirmingExit = true
	else
		bRunning = false end
end

--have the program exit cleanly and tidily
function exitCleanup()
	term.clear()
	term.setCursorPos(SCREEN_ORIGIN,SCREEN_ORIGIN)
end

intialize()
mainLoop()
exitCleanup()