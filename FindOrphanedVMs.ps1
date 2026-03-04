# Get the cluster name
$clusterName = (Get-Cluster).Name

# Get all nodes in the cluster
$clusterNodes = Get-ClusterNode -Cluster $clusterName

# Initialize a string builder for the output
$output = [System.Text.StringBuilder]::new()

foreach ($node in $clusterNodes) {
    [void]$output.AppendLine("Node: $($node.Name)")
    [void]$output.AppendLine("--------------------")
    
    Write-Host "Processing node: $($node.Name)"
    
    # Get VMs on the current node with their status
    $nodeVMs = Invoke-Command -ComputerName $node.Name -ScriptBlock {
        Get-VM | ForEach-Object {
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
            }
        }
    }
    
    # Get cluster roles (VMs) on the current node
    $clusterVMs = Get-ClusterGroup -Cluster $clusterName | Where-Object { $_.OwnerNode.Name -eq $node.Name } | Select-Object Name
    
    # Find orphaned VMs
    $orphanedVMs = $nodeVMs | Where-Object { $_.Name -notin $clusterVMs.Name }
    
    if ($orphanedVMs.Count -eq 0) {
        [void]$output.AppendLine("No orphaned VMs found on this node.")
    } else {
        foreach ($vm in $orphanedVMs) {
            [void]$output.AppendLine("Orphaned VM: $($vm.Name) - Status: $($vm.State)")
        }
    }
    
    [void]$output.AppendLine("")  # Add a blank line between nodes
}

# Display results in console
Write-Host $output.ToString()

# Export results to a text file
$outputPath = "OrphanedVMs.txt"
$output.ToString() | Out-File -FilePath $outputPath -Encoding utf8
Write-Host "Results exported to $outputPath"