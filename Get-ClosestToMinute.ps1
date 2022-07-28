function Get-ClosestToMinute {
    [CmdletBinding()]

    param (
        # Starting timespan to be rounded to the nearest X minute
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('InitialTimeSpan', 'ts')]
        [timespan] $TimeSpan,

        # The minute to round the timespan to
        [Parameter(ValueFromPipeline)]
        [Alias('NearestMinute')]
        [int] $Minute = 15,

        # If we're outside the boundary, we aim to go to the next/prev $Minute
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_ -ge 0 -and $_ -le $Minute })]
        [Alias('IncreaseBoundary')]
        [int] $Boundary = 5
    )

    process {
        $newTS = $TimeSpan
        $minuteMod = $TimeSpan.Minutes % $Minute
        $tsMod = New-TimeSpan -Minutes $minuteMod
        $tsIncrease = New-TimeSpan -Minutes ($Minute - $minuteMod)
        $halfNearestMinute = $Minute / 2

        Write-PSFMessage -Level Verbose -Message "Calculating new timespan for $newTS"
        $newTS = if ($minuteMod -gt $Boundary -and $newTS.TotalMinutes -ge $Boundary) {
            $newTS.Add($tsIncrease)
        }
        elseif ($minuteMod -le $halfNearestMinute -and $newTS.TotalMinutes -ge $halfNearestMinute) {
            $newTS.Subtract($tsMod)
        }
        else {
            $newTS.Add($tsIncrease)
        }

        [PSCustomObject]@{
            InitialTimespan = $TimeSpan
            NearestMinute   = $Minute
            Boundary        = $Boundary
            NewTimespan     = $newTS
        }
    }
}
