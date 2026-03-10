<#
.SYNOPSIS
  Identifies orphaned virtual machines in a Windows Failover Cluster.

.DESCRIPTION
  Scans all cluster nodes and identifies VMs that exist on the Hyper-V host but are not
  registered as cluster resources. Orphaned VMs are those running outside the cluster's
  management and may cause resource conflicts or prevent proper cluster operations.

  This script:
  - Queries each cluster node for all VMs via remote invocation
  - Compares VMs against registered cluster groups
  - Reports orphaned VMs with their current state
  - Exports results to a text file for auditing

.PARAMETER None
  This script operates on the local cluster context and does not require parameters.

.OUTPUTS
  - Console output with formatted results
  - OrphanedVMs.txt file in the script directory with detailed report

.EXAMPLE
  .\FindOrphanedVMs.ps1
  
  Output shows all orphaned VMs grouped by node with current execution state.

.NOTES
  Author: Cluster Administrator
  Tested: Windows Server 2019/2022 with Hyper-V
  
  Requires:
  - Cluster admin privileges
  - FailoverClusters module
  - Remote invocation enabled on all cluster nodes (WinRM)
  
  Common causes of orphaned VMs:
  - Failed cluster role import
  - Manual VM migration without cluster awareness
  - Incomplete cluster role deletion
  - Hyper-V sync issues after cluster maintenance

.LINK
  Get-Cluster
  Get-ClusterNode
  Get-ClusterGroup
  Get-VM
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Get the cluster name
try {
    $cluster = Get-Cluster -ErrorAction Stop
    $clusterName = $cluster.Name
    Write-Host "Cluster detected: $clusterName" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Not running on a cluster node or cluster is unavailable: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get all nodes in the cluster
try {
    $clusterNodes = Get-ClusterNode -Cluster $clusterName -ErrorAction Stop
    Write-Host "Found $($clusterNodes.Count) node(s) in cluster`n" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: Unable to retrieve cluster nodes: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Initialize a string builder for the output
$output = [System.Text.StringBuilder]::new()
[void]$output.AppendLine("ORPHANED VMS REPORT")
[void]$output.AppendLine("Cluster: $clusterName")
[void]$output.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$output.AppendLine("=" * 80)
[void]$output.AppendLine("")

$totalOrphaned = 0

foreach ($node in $clusterNodes) {
    [void]$output.AppendLine("Node: $($node.Name)")
    [void]$output.AppendLine("--------------------")
    
    Write-Host "Processing node: $($node.Name)" -ForegroundColor Yellow
    
    # Get VMs on the current node with their state mapped to human-readable format
    try {
        $nodeVMs = Invoke-Command -ComputerName $node.Name -ScriptBlock {
            Get-VM -ErrorAction SilentlyContinue | ForEach-Object {
                # Map numeric state values to descriptive status strings
                $status = switch ($_.State) {
                    0 { "Other" }
                    1 { "Running" }
                    2 { "Off" }
                    3 { "Stopping" }
                    4 { "Saved" }
                    5 { "Paused" }
                    6 { "Starting" }
                    7 { "Reset" }
                    8 { "Saving" }
                    9 { "Pausing" }
                    10 { "Resuming" }
                    11 { "FastSaved" }
                    12 { "FastSaving" }
                    13 { "ForceShutdown" }
                    14 { "ForceReboot" }
                    default { "Unknown" }
                }
                [PSCustomObject]@{
                    Name = $_.Name
                    State = $status
                    Id = $_.Id
                }
            }
        } -ErrorAction Stop
    } catch {
        Write-Host "  WARNING: Could not retrieve VMs from $($node.Name): $($_.Exception.Message)" -ForegroundColor Yellow
        [void]$output.AppendLine("ERROR: Could not retrieve VMs from this node - $($_.Exception.Message)")
        [void]$output.AppendLine("")
        continue
    }
    
    # Get all cluster-managed VMs (cluster groups) on the current node
    try {
        $clusterVMs = Get-ClusterGroup -Cluster $clusterName -ErrorAction Stop | `
            Where-Object { $_.OwnerNode.Name -eq $node.Name } | `
            Select-Object Name
    } catch {
        Write-Host "  WARNING: Could not retrieve cluster groups: $($_.Exception.Message)" -ForegroundColor Yellow
        [void]$output.AppendLine("ERROR: Could not retrieve cluster groups - $($_.Exception.Message)")
        [void]$output.AppendLine("")
        continue
    }
    
    # Identify orphaned VMs (exist on host but not in cluster)
    $orphanedVMs = $nodeVMs | Where-Object { $_.Name -notin $clusterVMs.Name }
    
    # Report results for this node
    if ($orphanedVMs.Count -eq 0) {
        [void]$output.AppendLine("Status: No orphaned VMs found")
        Write-Host "  ✓ No orphaned VMs" -ForegroundColor Green
    } else {
        [void]$output.AppendLine("Status: Found $($orphanedVMs.Count) orphaned VM(s)")
        Write-Host "  ⚠ Found $($orphanedVMs.Count) orphaned VM(s)" -ForegroundColor Red
        foreach ($vm in $orphanedVMs) {
            $vmInfo = "  ✗ Orphaned VM: $($vm.Name) - State: $($vm.State)"
            Write-Host $vmInfo -ForegroundColor Red
            [void]$output.AppendLine("  - VM Name: $($vm.Name)")
            [void]$output.AppendLine("    State: $($vm.State)")
            [void]$output.AppendLine("    VM ID: $($vm.Id)")
            $totalOrphaned += 1
        }
    }
    
    [void]$output.AppendLine("")  # Add a blank line between nodes
}

# Add summary section
[void]$output.AppendLine("=" * 80)
[void]$output.AppendLine("SUMMARY")
[void]$output.AppendLine("--------")
[void]$output.AppendLine("Total Orphaned VMs Found: $totalOrphaned")
[void]$output.AppendLine("")
[void]$output.AppendLine("REMEDIATION NOTES:")
[void]$output.AppendLine("- For orphaned VMs that should be cluster-managed:")
[void]$output.AppendLine("  1. Verify VM configuration files on the host")
[void]$output.AppendLine("  2. Use 'Add-ClusterVirtualMachineRole' to add VM to cluster")
[void]$output.AppendLine("  3. Configure appropriate HA policies")
[void]$output.AppendLine("")
[void]$output.AppendLine("- For orphaned VMs that should be removed:")
[void]$output.AppendLine("  1. Stop the VM (Stop-VM)")
[void]$output.AppendLine("  2. Delete the VM (Remove-VM)")
[void]$output.AppendLine("  3. Clean up storage if needed")

# Display results in console
Write-Host "`n" -NoNewline
Write-Host $output.ToString()

# Export results to a text file with timestamp
try {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $scriptDir = Split-Path -Parent $PSCommandPath
    $outputPath = Join-Path $scriptDir "OrphanedVMs_$timestamp.txt"
    
    $output.ToString() | Out-File -FilePath $outputPath -Encoding utf8 -ErrorAction Stop
    Write-Host "`nResults exported to: $outputPath" -ForegroundColor Green
    
    # Summary statistics
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Total Cluster Nodes Scanned: $($clusterNodes.Count)"
    Write-Host "  Total Orphaned VMs Found: $totalOrphaned"
    if ($totalOrphaned -gt 0) {
        Write-Host "  Action Required: Yes" -ForegroundColor Yellow
    } else {
        Write-Host "  Action Required: No" -ForegroundColor Green
    }
} catch {
    Write-Host "ERROR: Failed to export results to file: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}