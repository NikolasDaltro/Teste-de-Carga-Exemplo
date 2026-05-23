param (
    [string] $target_host = 'www.example.com',
    [string] $target_path = '/',
    [string] $protocol = 'https',
    [int] $threads = 10,
    [int] $requests = 20,
    [int] $delay_ms = 0,
    [int] $port = 0
)

if (-not ($target_host -and $target_path -and $protocol)) {
    Write-Error 'Os parâmetros target_host, target_path e protocol são obrigatórios.'
    exit 1
}

if ($port -gt 0) {
    $uri = $protocol + '://' + $target_host + ':' + $port + $target_path
} else {
    $uri = $protocol + '://' + $target_host + $target_path
}
Write-Output "Executando teste de carga em: $uri"
Write-Output "Threads: $threads | Requests por thread: $requests | Delay entre requests (ms): $delay_ms"

$jobs = @()
for ($t = 1; $t -le $threads; $t++) {
    $jobs += Start-Job -ArgumentList $t, $uri, $requests, $delay_ms -ScriptBlock {
        param($threadId, $uri, $requests, $delayMs)
        $results = @()
        for ($i = 1; $i -le $requests; $i++) {
            $start = Get-Date
            try {
                $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 30
                $status = $response.StatusCode
            } catch {
                $status = 'ERROR'
            }
            $duration = (Get-Date) - $start
            $results += [pscustomobject]@{
                Thread = $threadId
                Request = $i
                Status = $status
                DurationMs = [math]::Round($duration.TotalMilliseconds, 0)
                Uri = $uri
                Timestamp = (Get-Date).ToString('o')
            }
            if ($delayMs -gt 0) { Start-Sleep -Milliseconds $delayMs }
        }
        return $results
    }
}

Write-Output "Aguardando conclusão de $threads jobs..."
Wait-Job -Job $jobs
$allResults = $jobs | Receive-Job
$summaryPath = Join-Path -Path (Get-Location) -ChildPath 'results-powershell.csv'
$allResults | Export-Csv -Path $summaryPath -NoTypeInformation -Encoding UTF8

$stats = $allResults | Group-Object -Property Status | Sort-Object Count -Descending
Write-Output "Teste concluído. Resultados salvos em: $summaryPath"
Write-Output 'Resumo de status:'
$stats | ForEach-Object { Write-Output "  $($_.Name): $($_.Count)" }

Remove-Job -Job $jobs | Out-Null
