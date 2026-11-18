param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('pruebas', 'desarrollo')]
    [string]$Destino
)

$ErrorActionPreference = 'Stop'
$baseEsperada = if ($Destino -eq 'pruebas') { 'ahora_local_test' } else { 'ahora_local' }
$baseAnterior = [Environment]::GetEnvironmentVariable('DB_DATABASE', 'Process')
$directorioBackend = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Push-Location $directorioBackend
try {
    $env:DB_DATABASE = $baseEsperada
    & php artisan config:clear
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo limpiar la configuración cacheada de Laravel.' }

    $driver = (& php artisan tinker --execute='echo DB::connection()->getDriverName();' 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $driver -ne 'pgsql') {
        throw "La conexión no es PostgreSQL (detectado: $driver). No se modificó el esquema."
    }

    $baseReal = (& php artisan tinker --execute='echo DB::connection()->getDatabaseName();' 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $baseReal -ne $baseEsperada) {
        throw "Base detectada '$baseReal'; se esperaba '$baseEsperada'. No se ejecutaron migraciones."
    }

    Write-Host "Conexión verificada: PostgreSQL / $baseReal"
    if ($Destino -eq 'desarrollo') {
        $confirmacion = Read-Host '¿Confirmas que tienes respaldo de ahora_local y deseas aplicar las dos migraciones? (SI)'
        if ($confirmacion -cne 'SI') {
            Write-Host 'Operación cancelada sin aplicar migraciones.'
            exit 0
        }
    }

    $migraciones = @(
        'database/migrations/2026_11_18_000001_add_chat_timeout_to_users_table.php',
        'database/migrations/2026_11_18_000002_create_chat_moderaciones_table.php'
    )

    foreach ($migracion in $migraciones) {
        if (-not (Test-Path $migracion)) { throw "No existe la migración: $migracion" }
        & php artisan migrate --path=$migracion --force
        if ($LASTEXITCODE -ne 0) { throw "Falló la migración $migracion. Revisa el resultado antes de continuar." }
    }

    Write-Host "Esquema del chat actualizado en $baseEsperada. No se eliminaron registros."
}
finally {
    if ($null -eq $baseAnterior) {
        Remove-Item Env:DB_DATABASE -ErrorAction SilentlyContinue
    } else {
        $env:DB_DATABASE = $baseAnterior
    }
    Pop-Location
}
