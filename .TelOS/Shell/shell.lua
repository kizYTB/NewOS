local function termclear()
    term.clear()
    term.setCursorPos(1, 1)
end

local function customShell()
    termclear() -- Efface l'écran
    print("--------------------------")
    print("Pour avoir de l'aide, ")
    print("faite /help dans")
    print("votre computer.")
    print("--------------------------")

    -- Ici, vous pouvez appeler un programme spécifique sans afficher le shell.
    -- Remplacez "votre_programme" par le nom du programme que vous souhaitez exécuter.
    local success, message = shell.run("shell")
    
    -- Si vous souhaitez afficher un message d'erreur en cas d'échec, décommentez la ligne suivante

    termclear() -- Efface l'écran avant de quitter
end

customShell() -- Lancer votre shell personnalisé
