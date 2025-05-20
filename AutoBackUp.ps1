$savePath = "$env:USERPROFILE\AppData\LocalLow\semiwork\Repo\saves"
$backupFolder = "$PSScriptRoot\back"

if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder | Out-Null
}

function Show-Menu {
    $menu = @{
        '1' = '������� ��������� �����'
        '2' = '������������ �� ��������� �����'
        '0' = '�����'
    }

    foreach ($key in $menu.Keys) {
        Write-Host "$key - $($menu[$key])"
    }
}

function Backup-Saves {
    $folders = Get-ChildItem -Path $savePath -Directory | Where-Object { $_.Name -like "REPO_SAVE_*" }
    if ($folders.Count -eq 0) {
        Write-Host "��� ����� ��� ���������� �����������."
        return
    }

    Write-Host "�������� ����� ��� ���������:"
    for ($i = 0; $i -lt $folders.Count; $i++) {
        Write-Host "$($i+1) - $($folders[$i].Name)"
    }
    Write-Host "A - ������������ ���"
    $choice = Read-Host "��� �����"

    if ($choice -eq 'A') {
        foreach ($folder in $folders) {
            Archive-Folder $folder.FullName
        }
    } elseif ($choice -as [int] -and $choice -ge 1 -and $choice -le $folders.Count) {
        Archive-Folder $folders[$choice - 1].FullName
    } else {
        Write-Host "�������� �����."
    }
}

function Archive-Folder($folderPath) {
    $folderName = Split-Path $folderPath -Leaf
    $zipPath = Join-Path $backupFolder "$folderName.zip"

    if (Test-Path $zipPath) {
        $overwrite = Read-Host "����� $folderName.zip ��� ����������. ������������? (Y/N)"
        if ($overwrite -ne 'Y') {
            Write-Host "���������: $folderName"
            return
        }
        Remove-Item $zipPath -Force
    }

    Compress-Archive -Path "$folderPath\*" -DestinationPath $zipPath -Force
    Write-Host "����� ������: $zipPath"
}

function Restore-Backup {
    $zips = Get-ChildItem -Path $backupFolder -Filter "*.zip"
    if ($zips.Count -eq 0) {
        Write-Host "��� ������� ��� ��������������."
        return
    }

    Write-Host "�������� ����� ��� ��������������:"
    for ($i = 0; $i -lt $zips.Count; $i++) {
        Write-Host "$($i+1) - $($zips[$i].Name)"
    }
    $choice = Read-Host "��� �����"

    if ($choice -as [int] -and $choice -ge 1 -and $choice -le $zips.Count) {
        $zip = $zips[$choice - 1]
        $folderName = [System.IO.Path]::GetFileNameWithoutExtension($zip.Name)
        $extractPath = Join-Path $savePath $folderName

        if (Test-Path $extractPath) {
            $overwrite = Read-Host "����� $folderName ��� ����������. ������������? (Y/N)"
            if ($overwrite -ne 'Y') {
                Write-Host "�������������� ��������."
                return
            }
            Remove-Item $extractPath -Recurse -Force
        }

        $tempPath = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempPath | Out-Null

        Expand-Archive -Path $zip.FullName -DestinationPath $tempPath -Force

        Move-Item -Path "$tempPath\*" -Destination $extractPath

        Remove-Item $tempPath -Recurse -Force

        Write-Host "����� ������������ �: $extractPath"
    } else {
        Write-Host "�������� �����."
    }
}

do {
    Show-Menu
    $action = Read-Host "������� ����� ��������"
    switch ($action) {
        '1' { Backup-Saves }
        '2' { Restore-Backup }
        '0' { break }
        default { Write-Host "�������� �����. ��������� �������." }
    }
} while ($true)
