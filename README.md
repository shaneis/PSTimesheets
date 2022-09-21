# PSTimesheets

Since I learnt that you can press F5 in Notepad and it adds the current timestamp, I realised that it could be handy to track work time.
Or map F5 to do the same thing with `strftime()` in vim/neovim
    
    " Insert mode insert "
    inoremap <F5> <C-R>=strftime('%H:%M %d/%m/%Y')<CR>
    
It just needs parsing, collating, and measuring. 

PSTimesheets aims to do that.

### Example TimeSheet File

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

### Using the commands

Saving the above in a directory with the format yyyyMMdd.txt, the code should parse the data.

Getting the timesheets uses `Get-TimeSheet`:

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
    
Measuring the timesheets defaults to 15 minute boundaries, using `Measure-TimeSheet`:

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
    
Getting a running total for the day can be done using `Get-TimeSheetTotalPerDay`:

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

