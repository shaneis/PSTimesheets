function Measure-TimeSheet {
    [CmdletBinding()]

    param (
        # Timesheet to measure
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [PSTypeName('TimeSheet')] $TimeSheet
    )

    begin {
        $sheets = [System.Collections.Generic.List[PSObject]]::new()
    }

    process {
        foreach ($sheet in $TimeSheet) {
            $null = $sheets.Add($sheet)
        }
    }

    end {
        Write-PSFMessage -Level Verbose -Message 'Grouping timesheet subjects'
        $subjects = $Sheets |
        Where-Object Action -eq 'End' |
        Group-Object -Property Subject

        Write-PSFMessage -Level Verbose -Message 'Calculating sheet duration'
        $subjects |
        ForEach-Object -Process {
            $durationSecs = ($_.Group.Duration |
                Measure-Object -Property TotalSeconds -Sum).Sum
            
            $durationAggSecs = ($_.Group.DurationToNearest15 |
                Measure-Object -Property TotalSeconds -Sum).Sum

            [PSCustomObject]@{
                Subject             = $_.Name
                Date                = $_.Group[0].Date.Date
                TotalDuration       = New-TimeSpan -Seconds $durationSecs
                TotalDuration15Mins = New-TimeSpan -Seconds $durationAggSecs
            }
        }
    }
}
