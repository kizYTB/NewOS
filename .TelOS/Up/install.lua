local run = shell.run

-- Obtenir la largeur et la hauteur du terminal
local w, h = term.getSize()

-- Texte de base
local text = "Instaling update . . ."
local newMessage = "Upsate install succes !"

-- Créer une ligne de bordure pleine avec des underscores
local border = string.rep("_", w)

-- Position du texte centré
local xPos = math.floor((w - #text) / 2)
local yPos = math.floor(h / 2)

-- Fonction pour afficher l'animation avec des points
local function loadingAnimation()
    for i = 1, 3 do
        -- Effacer l'écran
        term.clear()

        -- Afficher la première ligne de bordure
        term.setCursorPos(1, 1)
        term.write(border)

        -- Afficher le texte centré avec des points
        term.setCursorPos(xPos, yPos)
        term.write(text .. string.rep(".", i))

        -- Afficher la deuxième ligne de bordure
        term.setCursorPos(1, h)
        term.write(border)

        -- Attendre 0.5 seconde
        sleep(0.5)
    end
end

-- Fonction pour afficher un autre message
local function showNewMessage()
    term.clear()

    -- Afficher la première ligne de bordure
    term.setCursorPos(1, 1)
    term.write(border)

    -- Afficher le nouveau message centré
    local newMessageXPos = math.floor((w - #newMessage) / 2)
    term.setCursorPos(newMessageXPos, yPos)
    term.write(newMessage)

    -- Afficher la deuxième ligne de bordure
    term.setCursorPos(1, h)
    term.write(border)
end

local function update()
    run("rm","/.bootloader")
    run("rm","/.TelOS")
    run("rm","/.bootloader/OS/TelOS.json")
    run("rm","/startup.lua")
    run("wget","run","https://raw.githubusercontent.com/kizYTB/CC-pkg/refs/heads/main/lib-pkg.lua","install","TelOS")
    term.clear()
end

-- Boucle principale
loadingAnimation()
-- Afficher l'animation
update()

showNewMessage()-- Afficher le nouveau message