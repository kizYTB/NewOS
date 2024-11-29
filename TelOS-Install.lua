local run = shell.run

local function Bootloader()
	run("cd","/.bootloader/OS/")
	run("wget","https://raw.githubusercontent.com/kizYTB/NewOS/refs/heads/main/.TelOS/bootloader_config_file/TelOS.json")

    run("cd","/.bootloader/")

    run("rm","/.bootloader/boot.lua")

    run("wget","https://raw.githubusercontent.com/kizYTB/NewOS/refs/heads/main/TelOS-Bootloader/boot.lua","boot.lua")

    run("cd","/.bootloader/Logo/")

    run("rm","logo.nfp")

    run("wget","https://raw.githubusercontent.com/kizYTB/NewOS/refs/heads/main/TelOS-Bootloader/logo.nfp")
end

local function NewOS()
    run("cd","/")
    run("mkdir",".TelOS")

    run("cd","/.TelOS")

    run("mkdir","Commands","Conf","debug","Prog","Shell","Up","pkg")
	
    run("wget","https://raw.githubusercontent.com/kizYTB/NewOS/refs/heads/main/.TelOS/boot.lua","boot.lua")
end

local function Components()
    run("cd","/.TelOS")
	
    run("cd","Commands/")    
    run("wget","https://raw.githubusercontent.com/kizYTB/NewOS/refs/heads/main/.TelOS/Commands/help.lua","help.lua")

    run("cd","/.TelOS/Prog")
    run("wget","https://raw.githubusercontent.com/kizYTB/NewOS/refs/heads/main/.TelOS/Prog/firewolf.lua","firewolf.lua")
    run("wget","https://raw.githubusercontent.com/kizYTB/NewOS/refs/heads/main/.TelOS/Prog/ide.lua")
    run("wget","https://raw.githubusercontent.com/kizYTB/NewOS/refs/heads/main/.TelOS/Prog/music.lua","music.lua")

    run("cd","/.TelOS/Shell/")
    run("wget","https://raw.githubusercontent.com/kizYTB/NewOS/refs/heads/main/.TelOS/Shell/shell.lua","shell.lua")
	
    run("cd","/.TelOS/pkg/")
    run("wget","https://raw.githubusercontent.com/kizYTB/CC-pkg/refs/heads/main/lib-pkg.lua")
	sleep(2)
	run("cd","/.TelOS/Up")
	run("wget","https://raw.githubusercontent.com/kizYTB/NewOS/refs/heads/main/.TelOS/Up/up.lua","up.lua")
	run("wget","https://raw.githubusercontent.com/kizYTB/NewOS/refs/heads/main/.TelOS/Up/install.lua","install.lua")
end

Bootloader()
NewOS()
Components()

os.reboot()