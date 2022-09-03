BeforeAll -ScriptBlock {
    $Module = . $PSScriptRoot/Get-ClosestToMinute.ps1
}

Describe -Name 'Get-ClosestToMinute' -Fixture {
    Context -Name 'Checking results for 00:00 (Just an entry)' -Fixture {
        BeforeAll -Scriptblock {
            $Result = Get-ClosestToMinute -Timespan '00:00'
        }

        It 'Should return 00:00 intial timespan for 00:00 parameter' -Test {
            $Result.InitialTimeSpan | Should -Be ('00:00:00' -as [timespan])
        }

        It 'Should return 00:15 new timespan for 00:00 parameter' -Test {
            $Result.newTimespan | Should -Be ('00:15:00' -as [timespan])
        }
    }

    Context -Name 'Checking results for 00:08 (Below TimeSpan)' -Fixture {
        BeforeAll -Scriptblock {
            $Result = Get-ClosestToMinute -Timespan '00:08'
        }

        It 'Should return 00:08 intial timespan for 00:08 parameter' -Test {
            $Result.InitialTimeSpan | Should -Be ('00:08:00' -as [timespan])
        }

        It 'Should return 00:15 new timespan for 00:08 parameter' -Test {
            $Result.newTimespan | Should -Be ('00:15:00' -as [timespan])
        }
    }

    Context -Name 'Checking results for 00:17 (Above TimeSpan)' -Fixture {
        BeforeAll -Scriptblock {
            $Result = Get-ClosestToMinute -Timespan '00:17'
        }

        It 'Should return 00:17 intial timespan for 00:17 parameter' -Test {
            $Result.InitialTimeSpan | Should -Be ('00:17:00' -as [timespan])
        }

        It 'Should return 00:15 new timespan for 00:17 parameter' -Test {
            $Result.newTimespan | Should -Be ('00:15:00' -as [timespan])
        }
    }


    Context -Name 'Checking results for 00:21 (Below TimeSpan to increase)' -Fixture {
        BeforeAll -Scriptblock {
            $Result = Get-ClosestToMinute -Timespan '00:21'
        }

        It 'Should return 00:21 intial timespan for 00:21 parameter' -Test {
            $Result.InitialTimeSpan | Should -Be ('00:21:00' -as [timespan])
        }

        It 'Should return 00:30 new timespan for 00:21 parameter' -Test {
            $Result.newTimespan | Should -Be ('00:30:00' -as [timespan])
        }
    }
}