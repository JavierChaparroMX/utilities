$ClusterName = Read-Host "Enter the cluster name"

$nodeNames = (Get-ClusterNode -Cluster $ClusterName) | Select-Object -ExpandProperty Name
$totalRAM = 0
$totalUsage = 0
Write-Host "Node RAM:   Usage %"
foreach ($name in $nodeNames) {
    $ram = (Get-WmiObject -ComputerName $name -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    $usage = (Get-WmiObject -ComputerName $name -Class Win32_PerfFormattedData_PerfOS_Memory).PercentCommittedBytesInUse
    Write-Host "${name}: ${ram} GB   ${usage}%"
    $totalRAM += $ram
    $totalUsage += $usage
}
Write-Host "Total RAM: $($totalRAM) GB   Total Usage: $(($totalUsage / $nodeNames.Count))%"