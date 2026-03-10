<#
.SYNOPSIS
  Generates a cluster-wide RAM utilization report for all nodes.

.DESCRIPTION
  Connects to each node in the failover cluster and gathers memory statistics including:
  - Total physical RAM per node (in GB)
  - Current memory usage percentage
  - Cluster-wide total RAM and average usage
  
  This script is useful for capacity planning, bottleneck identification, and
  memory pressure trending in failover cluster environments.

.PARAMETER ClusterName
  The name of the failover cluster to report on. If not specified, will be prompted
  for input. Can also detect local cluster if run from a cluster node.

.OUTPUTS
  - Formatted console table with per-node breakdown
  - Cluster totals and average utilization percentages

.EXAMPLE
  .\Cluster RAM Report.ps1
  
  Prompts for cluster name and displays RAM report.

.EXAMPLE
  .\Cluster RAM Report.ps1 -ClusterName "PROD-Cluster"
  
  Directly generates report for PROD-Cluster.

.NOTES
  Author: Cluster Administrator
  Tested: Windows Server 2019/2022
  
  Requirements:
  - Cluster admin privileges
  - WMI access to all cluster nodes
  - 32-bit integer limits mean max reportable ~4TB per node
  
  Performance:
  - Queries all nodes sequentially (can be up to 5-10 seconds per node)
  - Total runtime typically 30-60 seconds for small/medium clusters
  
  Data sources:
  - Win32_ComputerSystem (total physical memory)
  - Win32_PerfFormattedData_PerfOS_Memory (committed bytes percentage)

.LINK
  Get-ClusterNode
  Get-WmiObject
  Win32_ComputerSystem
  Win32_PerfFormattedData_PerfOS_Memory
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage="Name of the failover cluster")]
    [string]$ClusterName
)

$ErrorActionPreference = 'Stop'

# Helper function to format bytes to human-readable format
function Format-Bytes {
    param([double]$Bytes)
    $sizes = 'B', 'KB', 'MB', 'GB', 'TB'
    $order = 0
    while ($Bytes -ge 1024 -and $order -lt $sizes.Count - 1) {
        $order++
        $Bytes = $Bytes / 1024
    }
    return "{0:N2} {1}" -f $Bytes, $sizes[$order]
}

# Determine cluster name
if ([string]::IsNullOrEmpty($ClusterName)) {
    try {
        # Try to detect local cluster
        $localCluster = Get-Cluster -ErrorAction SilentlyContinue
        if ($localCluster) {
            $ClusterName = $localCluster.Name
            Write-Host "Detected local cluster: $ClusterName" -ForegroundColor Green
        } else {
            # Prompt user for cluster name
            $ClusterName = Read-Host "Enter the cluster name"
        }
    } catch {
        $ClusterName = Read-Host "Enter the cluster name"
    }
}

if ([string]::IsNullOrEmpty($ClusterName)) {
    Write-Host "ERROR: Cluster name is required." -ForegroundColor Red
    exit 1
}

# Get cluster nodes
try {
    Write-Host "Connecting to cluster: $ClusterName" -ForegroundColor Cyan
    $clusterNodes = @(Get-ClusterNode -Cluster $ClusterName -ErrorAction Stop | Select-Object -ExpandProperty Name)
    Write-Host "Found $($clusterNodes.Count) node(s)`n" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Unable to connect to cluster '$ClusterName': $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Collect memory data from all nodes
$memoryData = @()
$totalRAM = 0
$totalUsage = 0
$failedNodes = @()

Write-Host "Gathering memory statistics..." -ForegroundColor Yellow

foreach ($nodeName in $clusterNodes) {
    try {
        # Get total physical memory
        $computerSystem = Get-WmiObject -ComputerName $nodeName -Class Win32_ComputerSystem `
            -ErrorAction Stop -AsJob | Wait-Job | Receive-Job
        $ramGB = $computerSystem.TotalPhysicalMemory / 1GB
        
        # Get memory usage percentage
        $memoryStats = Get-WmiObject -ComputerName $nodeName `
            -Class Win32_PerfFormattedData_PerfOS_Memory -ErrorAction Stop
        $usagePercent = $memoryStats.PercentCommittedBytesInUse
        
        $memoryData += [PSCustomObject]@{
            Node = $nodeName
            RAM_GB = [math]::Round($ramGB, 2)
            Usage_Percent = if ($usagePercent) { $usagePercent } else { 0 }
            Status = if ($null -eq $usagePercent) { "WARNING: No data" } else { "OK" }
        }
        
        $totalRAM += $ramGB
        if ($usagePercent) { $totalUsage += $usagePercent }
        
        Write-Host "  ✓ $nodeName`: $(Format-Bytes ($ramGB * 1GB)) @ $usagePercent%" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ $nodeName`: ERROR - $($_.Exception.Message)" -ForegroundColor Red
        $failedNodes += $nodeName
        $memoryData += [PSCustomObject]@{
            Node = $nodeName
            RAM_GB = "N/A"
            Usage_Percent = "N/A"
            Status = "ERROR: $($_.Exception.Message)"
        }
    }
}

# Display results
Write-Host "`n" + ("=" * 80)
Write-Host "CLUSTER MEMORY REPORT: $ClusterName" -ForegroundColor Cyan
Write-Host ("=" * 80) + "`n"

$memoryData | Format-Table -AutoSize -Property Node, RAM_GB, Usage_Percent, Status

# Display cluster totals
Write-Host "`nCLUSTER TOTALS:" -ForegroundColor Cyan
Write-Host "  Total RAM: $(Format-Bytes ($totalRAM * 1GB))"
Write-Host "  Nodes Scanned Successfully: $($clusterNodes.Count - $failedNodes.Count)/$($clusterNodes.Count)"

if ($clusterNodes.Count - $failedNodes.Count -gt 0) {
    $avgUsage = [math]::Round($totalUsage / ($clusterNodes.Count - $failedNodes.Count), 2)
    Write-Host "  Average Usage: $avgUsage%"
} else {
    Write-Host "  Average Usage: Unable to calculate (no nodes responded)" -ForegroundColor Yellow
}

# Alert on high memory usage
$highMemoryNodes = $memoryData | Where-Object { $_.Usage_Percent -ge 85 }
if ($highMemoryNodes.Count -gt 0) {
    Write-Host "`nWARNING: High memory usage detected on:" -ForegroundColor Yellow
    foreach ($node in $highMemoryNodes) {
        Write-Host "  - $($node.Node): $($node.Usage_Percent)% (threshold: 85%)" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n" + ("=" * 80)
if ($failedNodes.Count -eq 0) {
    Write-Host "Status: All nodes queried successfully" -ForegroundColor Green
} else {
    Write-Host "Status: $($failedNodes.Count) node(s) failed: $($failedNodes -join ', ')" -ForegroundColor Red
}