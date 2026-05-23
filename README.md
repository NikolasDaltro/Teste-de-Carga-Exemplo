# Teste de Carga Automatizado

Teste de carga simples que roda direto no VS Code. Sem dependências externas necessárias.

## Como usar

### Via VS Code

1. Abra a pasta em VS Code
2. Pressione `Ctrl + Shift + P`
3. Digite `Run Task`
4. Escolha:
   - **Run Load Test (Default)** - exemplo.com com 10 threads
   - **Run Load Test (Custom URL)** - google.com com 20 threads

### Via Terminal

```powershell
powershell -ExecutionPolicy Bypass -File run-load-test.ps1 -target https://seu-site.com -threads 50 -requestsPerThread 20
```

## Parâmetros

- `-target` - URL (padrão: https://www.example.com)
- `-threads` - Threads simultâneas (padrão: 10)
- `-requestsPerThread` - Requisições por thread (padrão: 5)
- `-timeout` - Timeout em segundos (padrão: 30)

## Resultados

Salvo em `load-test-results.csv` com:
- ThreadId, Request, Status, DurationMs, Error, Timestamp

Resumo exibido no terminal com estatísticas completas.


## Observação sobre execução

- O script PowerShell pode ser executado mesmo sem JMeter.

## Nota

Este plano é genérico e pode ser usado para qualquer URL de teste. 
