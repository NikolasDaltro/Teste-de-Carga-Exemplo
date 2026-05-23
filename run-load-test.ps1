param (
    [string]$target = 'https://www.example.com',
    [int]$threads = 10,
    [int]$requestsPerThread = 5,
    [int]$timeout = 30
)

Write-Host "===== TESTE DE CARGA =====" -ForegroundColor Green
Write-Host "URL: $target" -ForegroundColor Cyan
Write-Host "Threads: $threads" -ForegroundColor Cyan
Write-Host "Requests por thread: $requestsPerThread" -ForegroundColor Cyan

$resultados = @()
$jobs = @()

for ($t = 1; $t -le $threads; $t++) {
    $job = Start-Job -ArgumentList $t, $target, $requestsPerThread, $timeout -ScriptBlock {
        param($threadId, $url, $numRequests, $timeoutSec)
        $threadResults = @()
        
        for ($i = 1; $i -le $numRequests; $i++) {
            $start = Get-Date
            $statusCode = 0
            $errorMsg = $null
            
            try {
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec $timeoutSec -ErrorAction Stop
                $statusCode = $response.StatusCode
            }
            catch {
                $statusCode = 0
                $errorMsg = $_.Exception.Message
            }
            
            $duration = ((Get-Date) - $start).TotalMilliseconds
            
            $threadResults += [PSCustomObject]@{
                ThreadId = $threadId
                Request = $i
                Status = $statusCode
                DurationMs = [int]$duration
                Error = $errorMsg
                Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
            }
        }
        
        return $threadResults
    }
    
    $jobs += $job
}

Write-Host "Aguardando conclusão de $threads threads..." -ForegroundColor Yellow
$jobs | Wait-Job | Out-Null

foreach ($job in $jobs) {
    $resultado = Receive-Job -Job $job
    $resultados += $resultado
}

Remove-Job -Job $jobs | Out-Null

# Estatísticas
$sucessos = @($resultados | Where-Object { $_.Status -eq 200 })
$erros = @($resultados | Where-Object { $_.Status -ne 200 })
$tempoMedio = ($resultados | Measure-Object -Property DurationMs -Average).Average
$tempoMax = ($resultados | Measure-Object -Property DurationMs -Maximum).Maximum
$tempoMin = ($resultados | Measure-Object -Property DurationMs -Minimum).Minimum
$totalRequests = $resultados.Count

Write-Host "`n===== RESULTADOS =====" -ForegroundColor Green
Write-Host "Total de requisições: $totalRequests" -ForegroundColor Cyan
Write-Host "Sucessos (200): $($sucessos.Count)" -ForegroundColor Green
Write-Host "Erros: $($erros.Count)" -ForegroundColor Red
Write-Host "Tempo médio: $([math]::Round($tempoMedio, 2))ms" -ForegroundColor Cyan
Write-Host "Tempo mínimo: $tempoMin ms" -ForegroundColor Cyan
Write-Host "Tempo máximo: $tempoMax ms" -ForegroundColor Cyan

# Salvar CSV
$csvPath = Join-Path -Path (Get-Location) -ChildPath 'load-test-results.csv'
$resultados | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -Force
Write-Host "`nResultados salvos em: $csvPath" -ForegroundColor Yellow
Write-Host "`nTeste concluído!" -ForegroundColor Green
