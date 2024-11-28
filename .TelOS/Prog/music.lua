local playlistFile = "playlist.txt"

-- Fonction pour lire le fichier de playlist
local function loadPlaylist()
    local playlist = {}
    if fs.exists(playlistFile) then
        local file = fs.open(playlistFile, "r")
        for line in file.readLine do
            table.insert(playlist, line)
        end
        file.close()
    end
    return playlist
end

-- Fonction pour sauvegarder la playlist
local function savePlaylist(playlist)
    local file = fs.open(playlistFile, "w")
    for _, link in ipairs(playlist) do
        file.writeLine(link)
    end
    file.close()
end

-- Fonction pour afficher la playlist
local function showPlaylist(playlist)
    print("Liste des musiques disponibles :")
    for i, link in ipairs(playlist) do
        print(i .. ". " .. link)
    end
end

-- Fonction pour ajouter un lien de musique
local function addMusic(playlist)
    print("Entrez le lien de la musique :")
    local link = read()
    table.insert(playlist, link)
    savePlaylist(playlist)
    print("Musique ajoutée à la playlist.")
end

-- Fonction pour jouer une musique via shell.run
local function playMusic(url)
    shell.run("speaker", "play", url)
end

-- Fonction pour sélectionner et jouer une musique
local function selectAndPlayMusic(playlist)
    showPlaylist(playlist)
    print("Sélectionnez un numéro de musique à jouer :")
    local choice = tonumber(read())
    if playlist[choice] then
        playMusic(playlist[choice])
    else
        print("Numéro invalide.")
    end
end

-- Menu principal
local function mainMenu()
    local playlist = loadPlaylist()

    while true do
        term.clear()
        term.setCursorPos(1,1)
        print("1. Afficher la playlist")
        print("2. Ajouter une musique")
        print("3. Jouer une musique")
        print("4. Quitter")

        local choice = read()

        if choice == "1" then
            showPlaylist(playlist)
        elseif choice == "2" then
            addMusic(playlist)
        elseif choice == "3" then
            selectAndPlayMusic(playlist)
        elseif choice == "4" then
            print("Au revoir !")
            break
        else
            print("Choix invalide, réessayez.")
        end
    end
end

-- Exécuter le menu principal
mainMenu()
