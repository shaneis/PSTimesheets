BeforeAll -ScriptBlock {
    $Loc =  Split-Path -Path $PSScriptRoot -Parent
    . $Loc/Get-TimeSheet.ps1
    
}

Describe -Name 'Get-TimeSheet' -Fixture {
    Context -Name 'Testing Parameters' -Fixture {
        BeforeAll -ScriptBlock {
            $Command = Get-Command -Name Get-TimeSheet
        }

        It -Name 'Has the expected parameter: <_>' -TestCases @(
            'FileDate'
            'Directory'
        ) -Test {
            $Command | Should -HaveParameter $_
        }
    }

    Context -Name 'Testing running' -Fixture {
        BeforeAll -Scriptblock {
            Mock -CommandName Get-ChildItem -MockWith {
                '20220728.txt'
            } -Verifiable

            Mock -CommandName Get-Content -MockWith {
                @'
08:37 28/07/2022 - Start - Daily Checks
09:14 28/07/2022 - End - Daily Checks
09:14 28/07/2022 - Start - Daily Standup
10:07 28/07/2022 - End - Daily Standup
10:14 28/07/2022 - Start - Coffee Break
11:03 28/07/2022 - End - Coffee Break
11:03 28/07/2022 - Start - Dedicated Code Review
11:18 28/07/2022 - End - Dedicated Code Review
11:22 28/07/2022 - Start - Daily Checks
11:53 28/07/2022 - End - Daily Checks
11:56 28/07/2022 - Start - Review Upgrade plan
12:24 28/07/2022 - End - Review Upgrade plan
12:35 28/07/2022 - Start - Prep for Upgrade
12:59 28/07/2022 - End - Prep for Upgrade
13:00 28/07/2022 - Start - Call with PM: Issue
13:45 28/07/2022 - End - Call with PM: Issue
14:24 28/07/2022 - Start - Update Meeting
15:00 28/07/2022 - End - Update Meeting
'@ -split "\r?\n"
            }

            $ResultParams = @{
                FileDate = Get-Date -Date '2022-07-28'
            }
            $Result = Get-TimeSheet @ResultParams
        }

        It -Name 'Should return expected subject: <_.Filter>' -TestCases @(
            [PSCustomObject] @{Filter = 'Daily Checks'}
            [PSCustomObject] @{Filter = 'Daily Standup'}
            [PSCustomObject] @{Filter = 'Coffee Break'}
            [PSCustomObject] @{Filter = 'Dedicated Code Review'}
            [PSCustomObject] @{Filter = 'Review Upgrade plan'}
            [PSCustomObject] @{Filter = 'Prep for Upgrade'}
            [PSCustomObject] @{Filter = 'Call with PM: Issue'}
            [PSCustomObject] @{Filter = 'Update Meeting'}
        ) -Test {
            $Result.Subject | Should -Contain $_.Filter
        }

        It -Name 'Should return expected date: <_.Date> for subject: <_.Subject>' -TestCases @(
            [PSCustomObject] @{Date = Get-Date '2022-07-28 08:37'; Subject = 'Daily Checks'}
        ) -Test {
            $TC = $_
            $Result | Where-Object {
                $_.Subject -eq $TC.Subject -and
                $_.Date -eq $TC.Date
            } | Should -Not -BeNullOrEmpty
        }
    }
}