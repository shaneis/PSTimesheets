function Get-TimeSheet {
    <#
    .SYNOPSIS
        Gets the contents of the timesheet file and parses it.
    .DESCRIPTION
        Gets the content of the timesheet file with the directory given by the
        -directory parameter, with the format yyyyMMdd.txt, and parses the 
        data.
    .EXAMPLE
        PS C:\> Get-TimeSheet -Directory $HOME | Format-Table

        Date                Subject               Action Duration DurationToNearest15
        ----                -------               ------ -------- -------------------
        28/07/2022 08:37:00 Daily Checks          Start  00:00:00 00:15:00
        28/07/2022 09:14:00 Daily Checks          End    00:37:00 00:45:00
        28/07/2022 09:14:00 Daily Standup         Start  00:00:00 00:15:00
        28/07/2022 10:07:00 Daily Standup         End    00:53:00 01:00:00
        28/07/2022 10:14:00 Coffee Break          Start  00:07:00 00:15:00
        28/07/2022 11:03:00 Coffee Break          End    00:49:00 00:45:00
        28/07/2022 11:03:00 Dedicated Code Review Start  00:00:00 00:15:00
        28/07/2022 11:18:00 Dedicated Code Review End    00:15:00 00:15:00
        28/07/2022 11:22:00 Daily Checks          Start  00:04:00 00:15:00
        28/07/2022 11:53:00 Daily Checks          End    00:31:00 00:30:00
        28/07/2022 11:56:00 Review Upgrade plan   Start  00:03:00 00:15:00
        28/07/2022 12:24:00 Review Upgrade plan   End    00:28:00 00:30:00
        28/07/2022 12:35:00 Prep for Upgrade      Start  00:11:00 00:15:00
        28/07/2022 12:59:00 Prep for Upgrade      End    00:24:00 00:30:00
        28/07/2022 13:00:00 Call with PM: Issue   Start  00:01:00 00:15:00
        28/07/2022 13:45:00 Call with PM: Issue   End    00:45:00 00:45:00
        28/07/2022 14:24:00 Update Meeting        Start  00:39:00 00:45:00
        28/07/2022 15:00:00 Update Meeting        End    00:36:00 00:45:00
    #>
    
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
