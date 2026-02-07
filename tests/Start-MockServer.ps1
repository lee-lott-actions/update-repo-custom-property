param(
    [int]$Port = 3000
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()

Write-Host "Mock server listening on http://127.0.0.1:$Port..." -ForegroundColor Green

try {
    while ($listener.IsListening) {
        $context  = $listener.GetContext()
        $request  = $context.Request
        $response = $context.Response

        $path   = $request.Url.LocalPath
        $method = $request.HttpMethod

        Write-Host "Mock intercepted: $method $path" -ForegroundColor Cyan

        $statusCode = 200
        $responseJson = $null
        $sendJson = $true

        # HealthCheck endpoint: GET /HealthCheck
        if ($method -eq "GET" -and $path -eq "/HealthCheck") {
            $statusCode = 200
            $responseJson = @{ status = "ok" } | ConvertTo-Json
        }
        # PATCH /repos/:owner/:repo_name/properties/values
        elseif ($method -eq "PATCH" -and $path -match '^/repos/([^/]+)/([^/]+)/properties/values$') {
            $owner = $Matches[1]
            $repoName = $Matches[2]

            Write-Host "Mock intercepted: PATCH /repos/$owner/$repoName/properties/values" -ForegroundColor Cyan

            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $requestBody = $reader.ReadToEnd()
            $reader.Close()

            Write-Host "Request body: $requestBody"

            $bodyObj = $null
            try { $bodyObj = $requestBody | ConvertFrom-Json } catch { $bodyObj = $null }

            $valid = $false
            if ($null -ne $bodyObj -and
                $null -ne $bodyObj.properties -and
                ($bodyObj.properties -is [System.Collections.IEnumerable]) -and
                @($bodyObj.properties).Count -gt 0) {

                $first = @($bodyObj.properties)[0]
                if ($null -ne $first.property_name -and -not [string]::IsNullOrEmpty([string]$first.property_name) -and
                    $null -ne $first.value -and -not [string]::IsNullOrEmpty([string]$first.value)) {
                    $valid = $true
                }
            }

            if ($valid) {
                # GitHub API returns 204 No Content for successful property updates
                $statusCode = 204
                $sendJson = $false
            }
            else {
                $statusCode = 400
                $responseJson = @{ message = "Invalid request: properties array with property_name and value is required" } | ConvertTo-Json -Compress
            }
        }
        else {
            $statusCode = 404
            $responseJson = @{ message = "Not Found" } | ConvertTo-Json -Compress
        }

        # Send response
        $response.StatusCode = $statusCode

        if ($sendJson) {
            $response.ContentType = "application/json"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        else {
            # 204 No Content
            $response.ContentLength64 = 0
        }

        $response.Close()
    }
}
finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Mock server stopped." -ForegroundColor Yellow
}