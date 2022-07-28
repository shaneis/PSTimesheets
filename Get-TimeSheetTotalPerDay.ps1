function Get-TimeSheetTotalPerDay {
    [CmdletBinding(DefaultParameterSetName = 'ByDays')]
    [OutputType('TimeSheetTotalPerDay')]

    param (
        [Parameter(
            Position = 0,
            ValueFromPipelineByPropertyName,
            ValueFromPipeline,
            ParameterSetName = 'ByDays'
        )]
        [ValidateNotNullOrEmpty()]
        [int] $DaysBack = 0,

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
