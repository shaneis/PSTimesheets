$Funcs = Get-ChildItem -Path $PSScriptRoot\*.ps1

foreach ($Func in $Funcs) {
    . $Func.FullName
}

Export-ModuleMember -Function *