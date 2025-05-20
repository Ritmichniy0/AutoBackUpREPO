$savePath = "$env:USERPROFILE\AppData\LocalLow\semiwork\Repo\saves"
$backupFolder = "$PSScriptRoot\back"

if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder | Out-Null
}

function Show-Menu {
    $menu = @{
        '1' = 'Сделать резервную копию'
        '2' = 'Восстановить из резервной копии'
        '0' = 'Выход'
    }

    foreach ($key in $menu.Keys) {
        Write-Host "$key - $($menu[$key])"
    }
}

function Backup-Saves {
    $folders = Get-ChildItem -Path $savePath -Directory | Where-Object { $_.Name -like "REPO_SAVE_*" }
    if ($folders.Count -eq 0) {
        Write-Host "Нет папок для резервного копирования."
        return
    }

    Write-Host "Выберите папку для архивации:"
    for ($i = 0; $i -lt $folders.Count; $i++) {
        Write-Host "$($i+1) - $($folders[$i].Name)"
    }
    Write-Host "A - Архивировать все"
    $choice = Read-Host "Ваш выбор"

    if ($choice -eq 'A') {
        foreach ($folder in $folders) {
            Archive-Folder $folder.FullName
        }
    } elseif ($choice -as [int] -and $choice -ge 1 -and $choice -le $folders.Count) {
        Archive-Folder $folders[$choice - 1].FullName
    } else {
        Write-Host "Неверный выбор."
    }
}

function Archive-Folder($folderPath) {
    $folderName = Split-Path $folderPath -Leaf
    $zipPath = Join-Path $backupFolder "$folderName.zip"

    if (Test-Path $zipPath) {
        $overwrite = Read-Host "Архив $folderName.zip уже существует. Перезаписать? (Y/N)"
        if ($overwrite -ne 'Y') {
            Write-Host "Пропущено: $folderName"
            return
        }
        Remove-Item $zipPath -Force
    }

    Compress-Archive -Path "$folderPath\*" -DestinationPath $zipPath -Force
    Write-Host "Архив создан: $zipPath"
}

function Restore-Backup {
    $zips = Get-ChildItem -Path $backupFolder -Filter "*.zip"
    if ($zips.Count -eq 0) {
        Write-Host "Нет архивов для восстановления."
        return
    }

    Write-Host "Выберите архив для восстановления:"
    for ($i = 0; $i -lt $zips.Count; $i++) {
        Write-Host "$($i+1) - $($zips[$i].Name)"
    }
    $choice = Read-Host "Ваш выбор"

    if ($choice -as [int] -and $choice -ge 1 -and $choice -le $zips.Count) {
        $zip = $zips[$choice - 1]
        $folderName = [System.IO.Path]::GetFileNameWithoutExtension($zip.Name)
        $extractPath = Join-Path $savePath $folderName

        if (Test-Path $extractPath) {
            $overwrite = Read-Host "Папка $folderName уже существует. Перезаписать? (Y/N)"
            if ($overwrite -ne 'Y') {
                Write-Host "Восстановление отменено."
                return
            }
            Remove-Item $extractPath -Recurse -Force
        }

        $tempPath = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempPath | Out-Null

        Expand-Archive -Path $zip.FullName -DestinationPath $tempPath -Force

        Move-Item -Path "$tempPath\*" -Destination $extractPath

        Remove-Item $tempPath -Recurse -Force

        Write-Host "Архив восстановлен в: $extractPath"
    } else {
        Write-Host "Неверный выбор."
    }
}

do {
    Show-Menu
    $action = Read-Host "Введите номер действия"
    switch ($action) {
        '1' { Backup-Saves }
        '2' { Restore-Backup }
        '0' { break }
        default { Write-Host "Неверный выбор. Повторите попытку." }
    }
} while ($true)
