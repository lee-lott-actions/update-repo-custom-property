function Set-CustomProperty {
  param(
    [string]$RepoName,
    [string]$Owner,
    [string]$Token,
    [string]$PropertyName,
    [string]$PropertyValue
  )

  # Validate required inputs
  if ([string]::IsNullOrEmpty($RepoName) -or
      [string]::IsNullOrEmpty($PropertyName) -or
      [string]::IsNullOrEmpty($PropertyValue) -or
      [string]::IsNullOrEmpty($Owner) -or
      [string]::IsNullOrEmpty($Token)) {

    Write-Host "Error: Missing required parameters"
    Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided."
    Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
    return
  }

  Write-Host "Setting '$PropertyName' custom property to '$PropertyValue' for repository: $Owner/$RepoName"

  # Use MOCK_API if set, otherwise default to GitHub API
  $apiBaseUrl = $env:MOCK_API
  if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }

  $uri = "$apiBaseUrl/repos/$Owner/$RepoName/properties/values"

  $headers = @{
    Authorization  = "Bearer $Token"
    Accept         = "application/vnd.github.v3+json"
    "Content-Type" = "application/json"
    "User-Agent"   = "pwsh-action"
  }

  $bodyObject = @{
    properties = @(
      @{
        property_name = $PropertyName
        value         = $PropertyValue
      }
    )
  }
  $body = $bodyObject | ConvertTo-Json -Depth 10 -Compress

  try {
    $response = Invoke-WebRequest -Uri $uri -Method Patch -Headers $headers -Body $body

	if($response.StatusCode -eq 204) {
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
		Write-Host "Successfully set '$PropertyName' custom property to '$PropertyValue' in $Owner/$RepoName"
	}
	else {
		$errorMsg = "Error: Failed to set '$PropertyName' custom property to '$PropertyValue'. HTTP Status: $($response.StatusCode)"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
		Write-Host $errorMsg
	}
  }
  catch {
    $errorMsg = "Error: Failed to set '$PropertyName' custom property to '$PropertyValue' in $Owner/$RepoName. Exception: $($_.Exception.Message)"
    Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
    Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
    Write-Host $errorMsg
  }
}