function Get-ClosestToMinute {
    <#
    .synopsis
    Returns an object with a timespan that is rounded to the nearest x minute.
    
    .description
    Returns an object with a timespan that is rounded to the nearest x minute,
    specified by the -minute parameter, and rounding up or down depending on
    the value passed to the -boundary parameter.
    
    .example
    PS C:\> Get-ClosestToMinute -timespan '00:12'

    initialtimespan nearestminute boundary newtimespan
    --------------- ------------- -------- -----------
           00:12:00            15        5    00:15:00

    .EXAMPLE
    PS C:\> Get-ClosestToMinute -timespan 01:12 -minute 30 -boundary 20
    
    initialtimespan nearestminute boundary newtimespan
    --------------- ------------- -------- -----------
           01:12:00            30       20    01:00:00

    #>
    [cmdletbinding()]

    param (
        # starting timespan to be rounded to the nearest x minute
        [parameter(
            mandatory,
            valuefrompipeline,
            valuefrompipelinebypropertyname
        )]
        [alias('initialtimespan', 'ts')]
        [timespan] $timespan,

        # the minute to round the timespan to
        [parameter(valuefrompipeline)]
        [alias('nearestminute')]
        [int] $minute = 15,

        # if we're outside the boundary, we aim to go to the next/prev $minute
        [parameter(valuefrompipelinebypropertyname)]
        [validatenotnullorempty()]
        [validatescript({ $_ -ge 0 -and $_ -le $minute })]
        [alias('increaseboundary')]
        [int] $boundary = 5
    )

    process {
        $newts = $timespan
        $minutemod = $timespan.minutes % $minute
        $tsmod = new-timespan -minutes $minutemod
        $tsincrease = new-timespan -minutes ($minute - $minutemod)
        $halfnearestminute = $minute / 2

        write-psfmessage -level verbose -message "calculating new timespan for $newts"
        $newts = if ($minutemod -gt $boundary -and $newts.totalminutes -ge $boundary) {
            $newts.add($tsincrease)
        }
        elseif ($minutemod -le $halfnearestminute -and $newts.totalminutes -ge $halfnearestminute) {
            $newts.subtract($tsmod)
        }
        else {
            $newts.add($tsincrease)
        }

        [pscustomobject]@{
            initialtimespan = $timespan
            nearestminute   = $minute
            boundary        = $boundary
            newtimespan     = $newts
        }
    }
}
