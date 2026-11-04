[CmdletBinding()]
param(
    [string]$BaseUrl = 'http://127.0.0.1:8000/api/v1/',
    [ValidateRange(1, 2147483647)][int]$CategoriaId = 8,
    [ValidateLength(1, 150)][string]$Buscar = 'farmacia',
    [ValidateRange(2, 20)][int]$Repeticiones = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$baseUri = [Uri]($BaseUrl.TrimEnd('/') + '/')
if (-not $baseUri.IsAbsoluteUri -or $baseUri.Scheme -notin @('http', 'https') -or
    $baseUri.UserInfo -or $baseUri.Query -or $baseUri.Fragment) {
    throw 'BaseUrl debe ser una URL HTTP/HTTPS de la API, sin credenciales ni parametros.'
}

function Get-Mediana {
    param([double[]]$Valores)
    $ordenados = @($Valores | Sort-Object)
    if ($ordenados.Count -eq 0) { return $null }
    $mitad = [int][Math]::Floor($ordenados.Count / 2)
    if ($ordenados.Count % 2 -eq 1) { return [Math]::Round($ordenados[$mitad], 2) }
    return [Math]::Round(($ordenados[$mitad - 1] + $ordenados[$mitad]) / 2, 2)
}

function Invoke-Medicion {
    param([string]$Nombre, [string]$Ruta, [bool]$TodasPaginas, [int]$Iteracion)
    $ciclo = [Diagnostics.Stopwatch]::StartNew()
    $httpMs = 0.0
    $bytes = 0L
    $peticiones = 0
    $registros = 0
    $pagina = 1
    $ultima = 1
    $total = $null
    $estado = 'OK'
    $errorDetalle = $null
    $ids = New-Object 'System.Collections.Generic.HashSet[long]'
    try {
        do {
            $uri = [Uri]::new($baseUri, $Ruta + '&page=' + $pagina)
            $http = [Diagnostics.Stopwatch]::StartNew()
            $peticiones++
            try {
                $respuesta = Invoke-WebRequest -Uri $uri.AbsoluteUri -Method Get -UseBasicParsing `
                    -Headers @{ Accept = 'application/json' } -TimeoutSec 30 -ErrorAction Stop
            }
            finally {
                $http.Stop()
                $httpMs += $http.Elapsed.TotalMilliseconds
            }
            $contenido = [string]$respuesta.Content
            $bytes += [Text.Encoding]::UTF8.GetByteCount($contenido)
            $datos = $contenido | ConvertFrom-Json
            if ($null -eq $datos.PSObject.Properties['meta'] -or $null -eq $datos.PSObject.Properties['data']) {
                throw 'La respuesta no contiene data/meta.'
            }
            $actual = [int]$datos.meta.current_page
            $ultimaActual = [int]$datos.meta.last_page
            $totalActual = [int]$datos.meta.total
            if ($actual -ne $pagina -or $ultimaActual -lt $pagina -or $totalActual -lt 0) {
                throw 'Paginacion invalida.'
            }
            if ($null -eq $total) {
                $total = $totalActual
                $ultima = $ultimaActual
                if ($ultima -gt [Math]::Max(1, $total)) { throw 'Paginacion inconsistente.' }
            }
            elseif ($total -ne $totalActual -or $ultima -ne $ultimaActual) {
                throw 'El catalogo cambio durante la medicion; repetir sin editar datos.'
            }
            $filas = @($datos.data)
            if ($TodasPaginas -and $filas.Count -eq 0 -and $total -gt 0) {
                throw 'Una pagina esta vacia; carga incompleta.'
            }
            foreach ($fila in $filas) {
                if (-not $ids.Add([long]$fila.id)) { throw 'ID repetido durante la carga.' }
            }
            $registros += $filas.Count
            $pagina++
        } while ($TodasPaginas -and $pagina -le $ultima)
        if ($TodasPaginas -and $registros -ne $total) { throw 'El total recibido esta incompleto.' }
    }
    catch {
        $estado = 'ERROR'
        $errorDetalle = $_.Exception.Message
    }
    finally { $ciclo.Stop() }
    [pscustomobject]@{
        Caso = $Nombre
        Iteracion = $Iteracion
        Estado = $estado
        HTTPms = [Math]::Round($httpMs, 2)
        CicloMs = [Math]::Round($ciclo.Elapsed.TotalMilliseconds, 2)
        Peticiones = $peticiones
        Registros = $registros
        Total = $total
        BytesJsonUtf8 = $bytes
        Error = $errorDetalle
    }
}

$texto = [Uri]::EscapeDataString($Buscar)
$casos = @(
    [pscustomobject]@{ Nombre = 'Listado_20'; Ruta = 'lugares?per_page=20'; Todas = $false },
    [pscustomobject]@{ Nombre = 'Mapa_pagina_100'; Ruta = 'lugares?per_page=100'; Todas = $false },
    [pscustomobject]@{ Nombre = 'Busqueda_nombre'; Ruta = "lugares?per_page=20&buscar=$texto"; Todas = $false },
    [pscustomobject]@{ Nombre = 'Filtro_categoria'; Ruta = "lugares?per_page=20&categoria_id=$CategoriaId"; Todas = $false },
    [pscustomobject]@{ Nombre = 'Mapa_catalogo_completo'; Ruta = 'lugares?per_page=100'; Todas = $true }
)

Write-Host "API: $($baseUri.AbsoluteUri)"
Write-Host "GET secuenciales. $Repeticiones repeticiones por caso. Categoria: $CategoriaId; busqueda: $Buscar."
Write-Host 'Mantener Laravel encendido y evitar editar lugares durante la medicion.'
$mediciones = @(
    foreach ($caso in $casos) {
        Write-Host "Midiendo $($caso.Nombre)..."
        for ($i = 1; $i -le $Repeticiones; $i++) {
            Invoke-Medicion -Nombre $caso.Nombre -Ruta $caso.Ruta -TodasPaginas $caso.Todas -Iteracion $i
        }
    }
)
$resumen = @(
    foreach ($caso in $casos) {
        $filas = @($mediciones | Where-Object { $_.Caso -eq $caso.Nombre })
        $correctas = @($filas | Where-Object { $_.Estado -eq 'OK' })
        $posteriores = @($correctas | Where-Object { $_.Iteracion -gt 1 })
        $primeraMs = $null
        $kib = $null
        $registros = $null
        $peticiones = $null
        if ($filas[0].Estado -eq 'OK') { $primeraMs = $filas[0].HTTPms }
        if ($correctas.Count -gt 0) {
            $kib = [Math]::Round(($correctas | Measure-Object -Property BytesJsonUtf8 -Average).Average / 1024, 2)
            $registros = $correctas[0].Registros
            $peticiones = $correctas[0].Peticiones
        }
        [pscustomobject]@{
            Caso = $caso.Nombre
            OK = $correctas.Count
            Fallos = $filas.Count - $correctas.Count
            PrimeraHTTPms = $primeraMs
            MedianaHTTPms = Get-Mediana -Valores @($posteriores | ForEach-Object { $_.HTTPms })
            MedianaCicloMs = Get-Mediana -Valores @($posteriores | ForEach-Object { $_.CicloMs })
            KiBJson = $kib
            Registros = $registros
            Peticiones = $peticiones
        }
    }
)
$carpeta = Join-Path $PSScriptRoot 'resultados'
New-Item -ItemType Directory -Path $carpeta -Force | Out-Null
$salida = Join-Path $carpeta ('api_lugares_' + (Get-Date -Format 'yyyyMMdd_HHmmss_fff') + '.json')
$reporte = [pscustomobject]@{
    GeneradoUTC = (Get-Date).ToUniversalTime().ToString('o')
    BaseUrl = $baseUri.AbsoluteUri
    CategoriaId = $CategoriaId
    Buscar = $Buscar
    Repeticiones = $Repeticiones
    Resumen = $resumen
    Mediciones = $mediciones
}
$reporte | ConvertTo-Json -Depth 8 | Set-Content -Path $salida -Encoding UTF8
$resumen | Format-Table -AutoSize | Out-Host
Write-Host "Resultado: $salida"
Write-Host 'HTTPms incluye cliente HTTP local y lectura de respuesta. CicloMs agrega parseo/validacion en PowerShell.'
Write-Host 'La primera medicion no garantiza cache fria. Las medianas excluyen la primera y los errores.'
if (@($mediciones | Where-Object { $_.Estado -eq 'ERROR' }).Count -gt 0) {
    Write-Warning 'Hubo fallos; revisar Mediciones en el JSON. No interpretar fallos como tiempos exitosos.'
    exit 1
}
