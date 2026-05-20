Describe "Set-CustomProperty" {
	BeforeAll {
		$script:RepoName = "test-repo"
		$script:Owner = "test-owner"
		$script:Token = "fake-token"
		$script:PropertyName = "env"
		$script:PropertyValue = "production"
		$script:MockApiUrl  = "http://127.0.0.1:3000"
		. "$PSScriptRoot/../action.ps1"
	}
	
	BeforeEach {
        $env:GITHUB_OUTPUT = New-TemporaryFile
        $env:MOCK_API = $script:MockApiUrl
    }
	
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Item Env:MOCK_API -ErrorAction SilentlyContinue
    }

	Context "Success Cases" {
		It "unit: Set-CustomProperty succeeds with HTTP 204" {
			Mock Invoke-WebRequest {
				[PSCustomObject]@{ StatusCode = 204 }
			}
	
			Set-CustomProperty -RepoName $RepoName -Owner $Owner -Token $Token -PropertyName $PropertyName -PropertyValue $PropertyValue
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=success"
		}
	}

	Context "HTTP Failure Cases" {
		It "unit: Set-CustomProperty fails with HTTP 403" {
			Mock Invoke-WebRequest {
				[PSCustomObject]@{ StatusCode = 403 }
			}
	
			Set-CustomProperty -RepoName $RepoName -Owner $Owner -Token $Token -PropertyName $PropertyName -PropertyValue $PropertyValue
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$pattern = "^error-message=Error: Failed to set '$PropertyName' custom property to '$PropertyValue'. HTTP Status:"
				($output | Where-Object { $_ -match $pattern }) | Should -Not -BeNullOrEmpty
		}	
	}


	Context "Parameter Validation Failure Cases" {
		It "unit: Set-CustomProperty fails with empty RepoName" {
			Set-CustomProperty -RepoName "" -Owner $Owner -Token $Token -PropertyName $PropertyName -PropertyValue $PropertyValue
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Should -Contain "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided."
		}
	
		It "unit: Set-CustomProperty fails with empty Owner" {
			Set-CustomProperty -RepoName $RepoName -Owner "" -Token $Token -PropertyName $PropertyName -PropertyValue $PropertyValue
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Should -Contain "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided."
		}
	
		It "unit: Set-CustomProperty fails with empty Token" {
			Set-CustomProperty -RepoName $RepoName -Owner $Owner -Token "" -PropertyName $PropertyName -PropertyValue $PropertyValue
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Should -Contain "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided."
		}
	
		It "unit: Set-CustomProperty fails with empty PropertyName" {
			Set-CustomProperty -RepoName $RepoName -Owner $Owner -Token $Token -PropertyName "" -PropertyValue $PropertyValue
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Should -Contain "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided."
		}
	
		It "unit: Set-CustomProperty fails with empty PropertyValue" {
			Set-CustomProperty -RepoName $RepoName -Owner $Owner -Token $Token -PropertyName $PropertyName -PropertyValue ""
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Should -Contain "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided."
		}	
	}

	Context "Exception Failure Cases" {
		It "unit: Set-CustomProperty fails with exception" {
			Mock Invoke-WebRequest { throw "API Error" }
	
			Set-CustomProperty -RepoName $RepoName -Owner $Owner -Token $Token -PropertyName $PropertyName -PropertyValue $PropertyValue
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$pattern = "^error-message=Error: Failed to set '$PropertyName' custom property to '$PropertyValue' in $Owner/$RepoName\. Exception:"
				($output | Where-Object { $_ -match $pattern }) | Should -Not -BeNullOrEmpty
		}		
	}
}
