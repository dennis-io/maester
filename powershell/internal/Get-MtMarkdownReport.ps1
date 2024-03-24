<#
 .Synopsis
  Generates a markdown report using the Maester test results format.

 .Description
    This markdown report can be used in GitHub actions to display the test results in a formatted way.

 .Example
    $pesterResults = Invoke-Pester -PassThru
    $maesterResults = ConvertTo-MtMaesterResults -PesterResults $pesterResults
    Get-MtMarkdownReport $maesterResults
#>

Function Get-MtMarkdownReport {
    [CmdletBinding()]
    param(
        # The Maester test results returned from `Invoke-Pester -PassThru | ConvertTo-MtMaesterResults`
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [psobject] $MaesterResults
    )
    $passedIcon = '<img src="https://maester.dev/img/test-result/pill-passed.png" height="25" alt="Passed"/>'
    $failedIcon = '<img src="https://maester.dev/img/test-result/pill-fail.png" height="25" alt="Failed"/>'
    $notRunIcon = '<img src="https://maester.dev/img/test-result/pill-notrun.png" height="25" alt="Not Run"/>'

    function GetTestSummary() {
        $summary = @'
|Test|Status|
|-|:-:|

'@
        foreach ($test in $MaesterResults.Tests) {
            $status = $notRunIcon
            if ($test.Result -eq 'Passed') {
                $status = $passedIcon
            } elseif ($test.Result -eq 'Failed') {
                $status = $failedIcon
            }

            $summary += "| $($test.Name) | $status |`n"
        }
        return $summary
    }

    function GetTestDetails() {

        foreach ($test in $MaesterResults.Tests) {
            $status = $notRunIcon
            if ($test.Result -eq 'Passed') {
                $status = $passedIcon
            } elseif ($test.Result -eq 'Failed') {
                $status = $failedIcon
            }

            $details += "`n## $($test.Name)"
            $details += "`n$status"

            if (![string]::IsNullOrEmpty($test.ResultDetail)) {
                # Test author has provided details
                $details += "`n`n#### Overview`n`n$($test.ResultDetail.TestDescription)"
                $details += "`n#### Test Results`n`n$($test.ResultDetail.TestResult)"
            } else {
                # Test author has not provided details, use default code in script
                $details += "`n`n#### Test`n`n$($test.ScriptBlock.Trim())"
                $details += "`n`n#### Reason for failure`n`n$($test.ErrorRecord)"
            }

            if (![string]::IsNullOrEmpty($test.HelpUrl)) { $details += "`n`n[Learn more]($($test.HelpUrl))" }
            if (![string]::IsNullOrEmpty($test.Tag)) {
                $tags = '`{0}`' -f ($test.Tag -join '` `')
                $details += "`n`n**Tag**: $tags"
            }

            if (![string]::IsNullOrEmpty($test.Block)) {
                $category = '`{0}`' -f ($test.Block -join '` `')
                $details += "`n`n**Category**: $category"
            }


            if (![string]::IsNullOrEmpty($test.ScriptBlockFile)) { $details += "`n`n**Source**: ``$($test.ScriptBlockFile)```n`n" }
        }
        return $details
    }

    $markdownFilePath = Join-Path -Path $PSScriptRoot -ChildPath '../assets/ReportTemplate.md'
    $templateMarkdown = Get-Content -Path $markdownFilePath -Raw

    $templateMarkdown = $templateMarkdown -replace '%TenandId%', $MaesterResults.TenantId
    $templateMarkdown = $templateMarkdown -replace '%TenantName%', $MaesterResults.TenantName
    $templateMarkdown = $templateMarkdown -replace '%TestDate%', $MaesterResults.ExecutedAt
    $templateMarkdown = $templateMarkdown -replace '%TotalCount%', $MaesterResults.TotalCount
    $templateMarkdown = $templateMarkdown -replace '%PassedCount%', $MaesterResults.PassedCount
    $templateMarkdown = $templateMarkdown -replace '%FailedCount%', $MaesterResults.FailedCount
    $templateMarkdown = $templateMarkdown -replace '%NotRunCount%', $MaesterResults.NotRunCount

    $templateMarkdown = $templateMarkdown -replace '%TestSummary%', (GetTestSummary)
    $templateMarkdown = $templateMarkdown -replace '%TestDetails%', (GetTestDetails)

    return $templateMarkdown
}