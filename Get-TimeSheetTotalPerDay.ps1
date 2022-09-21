function Get-TimeSheetTotalPerDay {
    <#
    .SYNOPSIS
        Returns total aggregated data for TimeSheets.
    .DESCRIPTION
        Parses passed in dates or days, aggregates the timesheet files found
        and returns the data.
    .EXAMPLE
        PS C:\> Get-TimeSheetTotalPerDay -Directory $HOME | Format-Table

        Subject               SubjectDuration SubjectDurationAgg Date                Duration DurationAgg
        -------               --------------- ------------------ ----                -------- -----------
        Call with PM: Issue   00:45:00        00:45:00           28/07/2022 00:00:00 05:18:00 05:45:00
        Coffee Break          00:49:00        00:45:00           28/07/2022 00:00:00 05:18:00 05:45:00
        Daily Checks          01:08:00        01:15:00           28/07/2022 00:00:00 05:18:00 05:45:00
        Daily Standup         00:53:00        01:00:00           28/07/2022 00:00:00 05:18:00 05:45:00
        Dedicated Code Review 00:15:00        00:15:00           28/07/2022 00:00:00 05:18:00 05:45:00
        Prep for Upgrade      00:24:00        00:30:00           28/07/2022 00:00:00 05:18:00 05:45:00
        Review Upgrade plan   00:28:00        00:30:00           28/07/2022 00:00:00 05:18:00 05:45:00
        Update Meeting        00:36:00        00:45:00           28/07/2022 00:00:00 05:18:00 05:45:00
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByDays')]
    [OutputType('TimeSheetTotalPerDay')]

    param (
        # How many days back in the timesheets we want to parse.
        [Parameter(
            Position = 0,
            ValueFromPipelineByPropertyName,
            ValueFromPipeline,
            ParameterSetName = 'ByDays'
        )]
        [ValidateNotNullOrEmpty()]
        [int] $DaysBack = 0,

        # Parse a timesheet of a particular date.
        [Parameter(
            Position = 0,
            ValueFromPipelineByPropertyName,
            ValueFromPipeline,
            Mandatory,
            ParameterSetName = 'ByDate'
        )]
        [datetime] $Date = (Get-Date)
    )

    begin {
        $funcsToImport = 'Get-TimeSheet', 'Measure-TimeSheet'

        foreach ($func in $funcsToImport) {
            if (Get-ChildItem -Path "Function:\$func" -ErrorAction SilentlyContinue) {continue}
            Write-PSFMessage -Message "Importing function: $func" -Level Verbose

            try {
                . "$PSScriptRoot\$($func).ps1"
            } catch {
                Write-PSFMessage -Message "Issue importing function: $func" -Level PSFMessage -Level Warning -Message
                break
            }
        }

        $DaysTotal = [System.Collections.Generic.List[PSObject]]::new()
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByDays') {
            Write-PSFMessage -Message "Gathering timesheet by days" -Level Verbose

            foreach ($DayBack in ($DaysBack..0)) {
                $TargetDate = ([datetime]::Today).AddDays(-$DayBack)

                try {
                    $TimeSheet = Get-TimeSheet -FileDate $TargetDate
                } catch {
                    Write-PSFMessage -Level Warning -Message "Cannot import timesheet: $TargetDate"
                }

                if (-not $TimeSheet) { continue }

                $DaysTotal.Add(($TimeSheet | Measure-TimeSheet))
                $TimeSheet = $null
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByDate') {
            Write-PSFMessage -Message "Gathering timesheet by date" -Level Verbose

            try {
                $TimeSheet = Get-TimeSheet -FileDate $Date
            } catch {
                Write-PSFMessage -Level Warning -Message "Cannot import timesheet: $Date"
            }

            $DaysTotal.Add(($TimeSheet | Measure-TimeSheet))
        }

        foreach ($Total in $DaysTotal.GetEnumerator()) {
            $MeasuredSeconds = ($Total.TotalDuration.TotalSeconds | Measure-Object -Sum).Sum
            $TotalSeconds    = New-TimeSpan -Seconds $MeasuredSeconds

            $MeasuredAggdSeconds = ($Total.TotalDuration15Mins.TotalSeconds | Measure-Object -Sum).Sum
            $TotalAggSeconds     = New-TimeSpan -Seconds $MeasuredAggdSeconds

            foreach ($DayTotal in $Total) {
                [PSCustomObject] @{
                    PSTypeName         = 'TimeSheetTotalPerDay'
                    Subject            = $DayTotal.Subject
                    SubjectDuration    = $DayTotal.TotalDuration
                    SubjectDurationAgg = $DayTotal.TotalDuration15Mins
                    Date               = $DayTotal.Date
                    Duration           = $TotalSeconds
                    DurationAgg        = $TotalAggSeconds
                }
            }
        }
    }
}
