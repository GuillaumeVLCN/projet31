Import-Module BurntToast

$imagePath = "C:\imagebu\transferrt.png"
$dossier_reception = "C:\projet\source"
$dossier_analyse_clam = "C:\projet\analyse"
$dossier_mise_a_dispo = "C:\projet\disponible"
$fichier_log = "C:\projet\logs\logs.txt"

function Obtenir_DateHeure {
    return (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
}

function Ecrire_Dans_Log {
    $dateHeure = Obtenir_DateHeure
    "$env:COMPUTERNAME | $($args[0]) | $($args[1]) | $dateHeure | $($args[2])" | Out-File -Append $fichier_log
}

function Notifier {
    param($titre, $message)
    New-BurntToastNotification -Text $titre, $message -AppLogo $imagePath
}

function Traiter_Fichier {
    param($fichier, $dossierUtilisateur)

    $dateHeureString = Obtenir_DateHeure
    $cheminNouveauDossier = Join-Path $dossierUtilisateur.FullName "$($fichier.BaseName)_$dateHeureString"
    New-Item -Path $cheminNouveauDossier -ItemType Directory

    $hashFichier = Get-FileHash -Path $fichier.FullName -Algorithm SHA256
    $nomUtilisateur = $dossierUtilisateur.Name
    "$($hashFichier.Hash)" | Out-File -FilePath (Join-Path $cheminNouveauDossier "hash_fichier.txt")
    $nomUtilisateur | Out-File -FilePath (Join-Path $cheminNouveauDossier "utilisateur.txt")

    Move-Item -Path $fichier.FullName -Destination $cheminNouveauDossier

    # Vérifier si ClamWin est installé et faire l'analyse
    $clamWinPath = "C:\Program Files\ClamWin\bin\ClamWin.exe"
    $clamWinLog = "C:\Users\$env:USERNAME\AppData\Roaming\.clamwin\log\ClamScanLog.txt"
    
    if (Test-Path $clamWinLog) {
        Clear-Content -Path $clamWinLog -ErrorAction SilentlyContinue
    }

    Start-Process -FilePath $clamWinPath -ArgumentList "--mode=scanner --path=$cheminNouveauDossier" -NoNewWindow -PassThru -Wait

    Start-Sleep -Seconds 5
    $logContent = Get-Content -Path $clamWinLog -Raw

    if ($logContent -match "Infected files: 0") {
        Write-Host " Aucun virus détecté."
        Ecrire_Dans_Log $fichier.Name "sain" "fichier_transfere"
    }
    else {
        Write-Host " Virus détecté, suppression du fichier."
        Ecrire_Dans_Log $fichier.Name "VIRUS" "fichier_supprime"
        Remove-Item -Path $cheminNouveauDossier -Recurse -Force
    }

    Notifier -titre "Analyse terminée" -message "Analyse terminée pour le fichier $($fichier.Name)"
}

function Surveiller_Fichiers {
    while ($true) {
        Get-ChildItem -Path $dossier_reception -Directory | ForEach-Object {
            $dossierUtilisateur = $_
            Get-ChildItem -Path $dossierUtilisateur.FullName | ForEach-Object { 
                Traiter_Fichier $_ $dossierUtilisateur 
            }
        }
        Start-Sleep -Seconds 10
    }
}

Surveiller_Fichiers








Import-Module BurntToast

$imagePath = "C:\imagebu\transferrt.png"
$dossier_reception = "C:\projet\source"
$dossier_analyse_clam = "C:\projet\analyse"
$dossier_mise_a_dispo = "C:\projet\disponible"
$fichier_log = "C:\projet\logs\logs.txt"

function Obtenir_DateHeure {
    return (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
}

function Ecrire_Dans_Log {
    $dateHeure = Obtenir_DateHeure
    "$env:COMPUTERNAME | $($args[0]) | $($args[1]) | $dateHeure | $($args[2])" | Out-File -Append $fichier_log
}

function Notifier {
    param($titre, $message)
    New-BurntToastNotification -Text $titre, $message -AppLogo $imagePath
}

function Traiter_Fichier {
    param($fichier, $dossierUtilisateur)

    Write-Host "Traitement du fichier: $($fichier.FullName)"

    $dateHeureString = Obtenir_DateHeure
    $cheminNouveauDossier = Join-Path $dossierUtilisateur.FullName "$($fichier.BaseName)_$dateHeureString"
    New-Item -Path $cheminNouveauDossier -ItemType Directory

    $hashFichier = Get-FileHash -Path $fichier.FullName -Algorithm SHA256
    $nomUtilisateur = $dossierUtilisateur.Name
    "$($hashFichier.Hash)" | Out-File -FilePath (Join-Path $cheminNouveauDossier "hash_fichier.txt")
    $nomUtilisateur | Out-File -FilePath (Join-Path $cheminNouveauDossier "utilisateur.txt")

    Move-Item -Path $fichier.FullName -Destination $cheminNouveauDossier

    # Vérifier si ClamWin est installé et faire l'analyse
    $clamWinPath = "C:\Program Files\ClamWin\bin\ClamWin.exe"
    $clamWinLog = "C:\Users\$env:USERNAME\AppData\Roaming\.clamwin\log\ClamScanLog.txt"
    
    if (-Not (Test-Path $clamWinPath)) {
        Write-Host "ClamWin n'est pas installé à l'emplacement attendu."
        return
    }

    if (Test-Path $clamWinLog) {
        Clear-Content -Path $clamWinLog -ErrorAction SilentlyContinue
    }

    Write-Host "Lancement de l'analyse avec ClamWin..."
    Start-Process -FilePath $clamWinPath -ArgumentList "--mode=scanner --path=$cheminNouveauDossier" -NoNewWindow -PassThru -Wait

    Start-Sleep -Seconds 5
    $logContent = Get-Content -Path $clamWinLog -Raw

    Write-Host "Contenu du log ClamWin: $logContent"

    if ($logContent -match "Infected files: 0") {
        Write-Host "Aucun virus détecté."
        Ecrire_Dans_Log $fichier.Name "sain" "fichier_transfere"
    }
    else {
        Write-Host "Virus détecté, suppression du fichier."
        Ecrire_Dans_Log $fichier.Name "VIRUS" "fichier_supprime"
        Remove-Item -Path $cheminNouveauDossier -Recurse -Force
    }

    Notifier -titre "Analyse terminée" -message "Analyse terminée pour le fichier $($fichier.Name)"
}

function Surveiller_Fichiers {
    while ($true) {
        Write-Host "Vérification des fichiers dans le dossier de réception..."
        $fichiers = Get-ChildItem -Path $dossier_reception -File
        if ($fichiers.Count -eq 0) {
            Write-Host "Aucun fichier trouvé dans le dossier."
        }
        foreach ($fichier in $fichiers) {
            Traiter_Fichier $fichier (Get-Item $dossier_reception)
        }
        Start-Sleep -Seconds 10
    }
}

Surveiller_Fichiers
