# .\build.ps1  - Ejecutar desde: user-service/terraform/

$base = "..\src"

$functions = @{
    "register"       = "$base\register"
    "login"          = "$base\login"
    "get_profile"    = "$base\getprofile"
    "update_profile" = "$base\updateprofile"
    "upload_avatar"  = "$base\uploadavatar"
}

foreach ($zip in $functions.Keys) {
    $src = $functions[$zip]

    if (Test-Path $src) {
        Write-Host "Empaquetando $zip..." -ForegroundColor Cyan
        Compress-Archive -Path "$src\*" -DestinationPath "$zip.zip" -Force
        Write-Host "$zip.zip creado OK" -ForegroundColor Green
    } else {
        Write-Host "No se encontro: $src" -ForegroundColor Red
    }
}

Write-Host "`nListo! Ahora corre: terraform apply" -ForegroundColor Yellow