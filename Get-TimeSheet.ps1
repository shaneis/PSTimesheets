function Get-TimeSheet {
    [CmdletBinding()]

    param (
        # The date of the timesheet file
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [datetime] $FileDate = (Get-Date),

        # The directory that stores timesheet files
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript({ Test-Path -Path $_ })]
        [Alias('TimeSheetDirectory')]
        [string] $Directory = (
            Split-Path -Path $PSScriptRoot -Parent |
            Split-Path -Parent |
            Join-Path -ChildPath 'TimeSheets'
        )
    )

    process {
        $dateFormatted = Get-Date -Date $FileDate -Format FileDate

        Write-PSFMessage -Level Verbose -Message 'Finding timesheets'
        try {
            $gciParams = @{
                Path        = $Directory
                Filter      = "*$($dateFormatted)*"
                ErrorAction = 'Stop'
            }
            $timeSheets = Get-ChildItem @gciParams
        }
        catch {
            Write-PSFMessage -Level Warning -Message "Cannot find timesheets matching $dateFormatted in $Directory"
            break
        }

        Write-PSFMessage -Level Verbose -Message "Parsing timesheets"
        $contents = foreach ($timeSheet in $timeSheets) {
            foreach ($content in Get-Content -Path $timeSheet) {
                if ([string]::IsNullOrEmpty($content)) { continue }

                $Date, $Action, $Subject = $content.Split(' - ', 3)

                # Deal with `-as [datetime]` not working properly...
                $Date = [datetime]::ParseExact(
                    $Date,
                    'HH:mm dd/MM/yyyy',
                    $null
                )
                
                [PSCustomObject]@{
                    Date    = $Date -as [datetime]
                    Action  = $Action
                    Subject = $Subject
                }
            }
        }

        Write-PSFMessage -Level Verbose -Message 'Adding Duration property'
        $prevDate = ($contents | Sort-Object -Property Date)[0].Date

        foreach ($row in $contents) {
            $duration = $row.Date - $prevDate

            if (-not (Test-Path -Path Function:\Get-ClosestToMinute)) {
                $funcImport = '{0}{1}{2}.ps1' -f @(
                    $PSScriptRoot,
                    [IO.Path]::DirectorySeparatorChar,
                    'Get-ClosestToMinute'
                    )
                Write-PSFMessage -Level Verbose -Message "Importing function from $funcImport"

                try {
                    . $funcImport
                }
                catch {
                    Write-PSFMessage -Level Warning -Message "Error importing function from $funcImport"
                }
            }

            $durationAgg = Get-ClosestToMinute -InitialTimeSpan $duration

            [PSCustomObject]@{
                PSTypeName          = 'TimeSheet'
                Date                = $row.Date
                Subject             = $row.Subject
                Action              = $row.Action
                Duration            = $duration
                DurationToNearest15 = $durationAgg.newTimeSpan
            }

            $prevDate = $row.Date
        }
    }
}
