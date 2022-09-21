function Measure-TimeSheet {
    <#
    .SYNOPSIS
        Measures the timesheets and returns aggregate information.

    .DESCRIPTION
        Measures the timesheets passed in and returns aggregate information,
        i.e. Subject, Date, Total time taken, and Total time taken in 15 min
        increments.

    .EXAMPLE
    PS C:\> Get-TimeSheet -Directory $HOME | Measure-TimeSheet

    Subject               Date                TotalDuration TotalDuration15Mins
    -------               ----                ------------- -------------------
    Call with PM: Issue   28/07/2022 00:00:00 00:45:00      00:45:00
    Coffee Break          28/07/2022 00:00:00 00:49:00      00:45:00
    Daily Checks          28/07/2022 00:00:00 01:08:00      01:15:00
    Daily Standup         28/07/2022 00:00:00 00:53:00      01:00:00
    Dedicated Code Review 28/07/2022 00:00:00 00:15:00      00:15:00
    Prep for Upgrade      28/07/2022 00:00:00 00:24:00      00:30:00
    Review Upgrade plan   28/07/2022 00:00:00 00:28:00      00:30:00
    Update Meeting        28/07/2022 00:00:00 00:36:00      00:45:00
    #>
    
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
