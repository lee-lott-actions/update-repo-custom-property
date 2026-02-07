BeforeAll {
	$script:RepoName = "test-repo"
	$script:Owner = "test-owner"
	$script:Token = "fake-token"
	$script:PropertyName = "env"
	$script:PropertyValue = "production"

	. "$PSScriptRoot/../action.ps1"
}

Describe "Set-CustomProperty" {
	BeforeEach {
		$env:GITHUB_OUTPUT = [System.IO.Path]::GetTempFileName()
	}

	AfterEach {
		if (Test-Path $env:GITHUB_OUTPUT) {
			Remove-Item $env:GITHUB_OUTPUT -Force
		}
	}

	It "succeeds with HTTP 204" {
		Mock Invoke-WebRequest {
			[PSCustomObject]@{ StatusCode = 204 }
		}

		Set-CustomProperty -RepoName $RepoName -Owner $Owner -Token $Token -PropertyName $PropertyName -PropertyValue $PropertyValue

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=success"
	}

	It "fails with HTTP 403" {
		Mock Invoke-WebRequest {
			[PSCustomObject]@{ StatusCode = 403 }
		}

		Set-CustomProperty -RepoName $RepoName -Owner $Owner -Token $Token -PropertyName $PropertyName -PropertyValue $PropertyValue

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Error: Failed to set '$PropertyName' custom property to '$PropertyValue'. HTTP Status"
	}

	It "fails with empty repo_name" {
		Set-CustomProperty -RepoName "" -Owner $Owner -Token $Token -PropertyName $PropertyName -PropertyValue $PropertyValue

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided."
	}

	It "fails with empty owner" {
		Set-CustomProperty -RepoName $RepoName -Owner "" -Token $Token -PropertyName $PropertyName -PropertyValue $PropertyValue

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided."
	}

	It "fails with empty token" {
		Set-CustomProperty -RepoName $RepoName -Owner $Owner -Token "" -PropertyName $PropertyName -PropertyValue $PropertyValue

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided."
	}

	It "fails with empty property_name" {
		Set-CustomProperty -RepoName $RepoName -Owner $Owner -Token $Token -PropertyName "" -PropertyValue $PropertyValue

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided."
	}

	It "fails with empty property_value" {
		Set-CustomProperty -RepoName $RepoName -Owner $Owner -Token $Token -PropertyName $PropertyName -PropertyValue ""

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided."
	}
	
	It "writes result=failure and error-message on exception (catch block)" {
		Mock Invoke-WebRequest { throw "API Error" }

		Set-CustomProperty -RepoName $RepoName -Owner $Owner -Token $Token -PropertyName $PropertyName -PropertyValue $PropertyValue

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$pattern = "^error-message=Error: Failed to set '$PropertyName' custom property to '$PropertyValue' in $Owner/$RepoName\. Exception:"
		($output | Where-Object { $_ -match $pattern }) | Should -Not -BeNullOrEmpty
	}	
}
