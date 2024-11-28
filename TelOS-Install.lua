local run = shell.run

local function Bootloader()
	run("cd","/.bootloader/OS/")
	run("wget","https://kiz-data.jtheberg.fr/CCMC/OS/sc/.NewOS/bootloaderconfigfile/NewOS.json")
end

local function NewOS()
    run("cd","/")
    run("mkdir",".NewOS")

    run("cd","/.NewOS")

    run("mkdir","Commands","Conf","debug","Prog","Shell","Up","pkg")
	
    run("wget","https://kiz-data.jtheberg.fr/CCMC/OS/sc/.NewOS/boot.lua","boot.lua")
end

local function Components()
    run("cd","/.NewOS")
	
    run("cd","Commands/")    
    run("wget","https://kiz-data.jtheberg.fr/CCMC/OS/sc/.NewOS/Commands/help.lua","help.lua")

    run("cd","debug/")
    run("wget","https://kiz-data.jtheberg.fr/CCMC/OS/sc/.NewOS/debug/","debug.lua")
    run("mkdir","commands")
    run("cd","commands")
    run("wget","https://kiz-data.jtheberg.fr/CCMC/OS/sc/.NewOS/debug/commands/reset.lua","reset.lua")

    run("cd","/.NewOS/Conf/")
    run("wget","https://kiz-data.jtheberg.fr/CCMC/OS/sc/.NewOS/Conf/version.txt","version.txt")

    run("cd","/.NewOS/Prog")
    run("wget","https://kiz-data.jtheberg.fr/CCMC/OS/sc/.NewOS/Prog/firewolf.lua","firewolf.lua")
    run("wget","https://kiz-data.jtheberg.fr/CCMC/OS/sc/.NewOS/Prog/ide.lua","ide.lua")
    run("wget","https://kiz-data.jtheberg.fr/CCMC/OS/sc/.NewOS/Prog/music.lua","music.lua")

    run("cd","/.NewOS/Shell/")
    run("wget","https://kiz-data.jtheberg.fr/CCMC/OS/sc/.NewOS/Shell/shell.lua","shell.lua")
	
    run("cd","/.NewOS/pkg/")
    run("wget","https://raw.githubusercontent.com/kizYTB/CC-pkg/refs/heads/main/lib-pkg.lua")
	sleep(2)
	run("cd","/.NewOS/Up")
	run("wget","https://kiz-data.jtheberg.fr/CCMC/OS/sc/.NewOS/Up/up.lua","up.lua")
	run("wget","https://kiz-data.jtheberg.fr/CCMC/OS/sc/.NewOS/Up/install.lua","install.lua")
end

Bootloader()
NewOS()
Components()

os.reboot()