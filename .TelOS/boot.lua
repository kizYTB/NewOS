-- URL du fichier de version et du programme à télécharger
local versionURL = "https://kiz-data.jtheberg.fr/CCMC/OS/conf/versions.txt"  -- URL du fichier contenant le numéro de version actuel
local currentVersion = "1.10"  -- Modifiez cela avec la version actuelle de votre programme

-- Fonction pour récupérer le contenu d'une URL
local function httpGet(url)
    local response = http.get(url)  -- Essaie de récupérer l'URL
    if response then
        local content = response.readAll()  -- Lit le contenu de la réponse
        response.close()  -- Ferme la connexion
        return content:gsub("%s+", "")  -- Nettoie le contenu (supprime les espaces)
    else
        error("Error " .. url)  -- Gère l'erreur de connexion
        print("no possible to start error code : 0x000001")
    end
end

-- Fonction pour vérifier si une mise à jour est disponible
local function checkForUpdate()
    local latestVersion = httpGet(versionURL)  -- Récupère la version la plus récente à partir de versions.txt

    -- Compare la version actuelle avec la version récupérée
    if latestVersion ~= currentVersion then
        shell.run("/.TelOS/Up/up.lua")
        sleep(3)
        return true  -- Retourne vrai si une mise à jour est disponible
    else
        return false  -- Retourne faux si aucune mise à jour
    end
end

-- Fonction pour télécharger et exécuter le programme de mise à jour
local function downloadAndRunUpdate()
end

-- Obtenir la largeur et la hauteur du terminal
local w, h = term.getSize()

-- Texte de base
local text = "Starting . . ."
local newMessage = "TelOS : OK"
local updateMessage = "Check for update."

-- Créer une ligne de bordure pleine avec des underscores
local border = string.rep("_", w)

-- Position du texte centré
local yPos = math.floor(h / 2)

-- Fonction pour afficher l'animation avec des points
local function loadingAnimation(message)
    for i = 1, 3 do
        -- Effacer l'écran
        term.clear()

        -- Afficher la première ligne de bordure
        term.setCursorPos(1, 1)
        term.write(border)

        -- Afficher le message centré avec des points
        local messageXPos = math.floor((w - #message - i) / 2)  -- Ajuste la position du message
        term.setCursorPos(messageXPos, yPos)
        term.write(message .. string.rep(".", i))

        -- Afficher la deuxième ligne de bordure
        term.setCursorPos(1, h)
        term.write(border)

        -- Attendre 0.5 seconde
        sleep(0.5)
    end
end

-- Fonction pour afficher un message centré
local function showMessageCentered(message)
    term.clear()

    -- Afficher la première ligne de bordure
    term.setCursorPos(1, 1)
    term.write(border)

    -- Afficher le message centré
    local messageXPos = math.floor((w - #message) / 2)
    term.setCursorPos(messageXPos, yPos)
    term.write(message)

    -- Afficher la deuxième ligne de bordure
    term.setCursorPos(1, h)
    term.write(border)
end

-- Fonction pour lancer le shell modifié
local function LaunchShell()
    sleep(1)
    shell.run("bg", "/.TelOS/Shell/shell.lua")
end

local function ProgSet()
    shell.setAlias("/help","/.TelOS/Commands/help.lua")
    shell.setAlias("/ide","/.TelOS/Prog/ide.lua")
    shell.setAlias("/music","/.TelOS/Prog/music.lua")
    shell.setAlias("/firewolf","/.TelOS/Prog/firewolf.lua")
    shell.setAlias("/TelOS DEBUG","/.TelOS/debug/debug.lua")
    shell.setAlias("/pkg","/.TelOS/pkg/lib-pkg.lua")
end

-- Programme principal
showMessageCentered(text)  -- Afficher le message de démarrage
sleep(2)  -- Attendre un moment pour que l'utilisateur puisse lire le message

showMessageCentered(updateMessage)  -- Afficher le message de vérification de mise à jour
sleep(2)  -- Attendre un moment pour que l'utilisateur puisse lire le message

local updateNeeded = checkForUpdate()  -- Vérifie s'il y a une mise à jour disponible

if updateNeeded then  -- Si une mise à jour est trouvée, télécharge et exécute le fichier de mise à jour
    downloadAndRunUpdate()  
end

-- Afficher l'animation pour le nouveau message
loadingAnimation(newMessage)  -- Afficher l'animation
showMessageCentered(newMessage)
ProgSet()  -- Afficher le nouveau message centré
LaunchShell()  -- Lancer le shell modifié
ProgSet()
-- Entrer dans une boucle infinie pour rester sur le programme
while true do
    sleep(1)  -- Attendre pour ne pas surcharger le processeur
end
