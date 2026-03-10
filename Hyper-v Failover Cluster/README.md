# Failover Cluster Utilities

Tools and scripts for Windows Failover Cluster administration, maintenance, and troubleshooting.

## Overview

This folder contains utilities designed specifically for **Windows Server Failover Clustering** environments. These tools help with:

- Cluster preparation and readiness validation
- Cluster-Aware Updating (CAU) setup and maintenance
- VM and resource management
- Performance monitoring and diagnostics

## Available Scripts

### 🔧 CAU/

**Prepare-ClusterForCAU.ps1** — Enhanced Cluster-Aware Updating preparation  
Prepares all cluster nodes for CAU by fixing WinRM/PowerShell Remoting configuration.

**What it does:**
- Fixes WinRM listeners to use wildcard (`Address=*`)
- Configures Kerberos-only authentication
- Enables Windows Remote Management firewall rules
- Separates iSCSI/storage networks from management networks
- Validates cluster health before making changes
- Creates timestamped backups for rollback
- Provides detailed logging and dry-run mode

**Quick Start:**
```powershell
# Preview changes without applying them
.\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" -DryRun

# Full deployment with backup
.\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" `
  -StorageNetworks "10.0.10.X (Storage1)" `
  -ManagementNetwork "10.0.1.X (Management)" `
  -BackupConfig `
  -DelayedAutoStartWinRM
```

**Help:**
```powershell
Get-Help .\Prepare-ClusterForCAU.ps1 -Full
Get-Help .\Prepare-ClusterForCAU.ps1 -Examples
Get-Help .\Prepare-ClusterForCAU.ps1 -Parameter *
```

**Other CAU scripts:**
- `Configure UPN locally` — Set UPN for local authentication
- `Configure-update-proxy-node` — Configure WSUS/proxy settings

---

### 📊 Root Level Utilities

**Cluster RAM Report.ps1** — Memory utilization reporting  
Generate cluster-wide RAM and usage statistics for capacity planning.

```powershell
.\Cluster\ RAM\ Report.ps1 -ClusterName "PROD-Cluster"
```

**FindOrphanedVMs.ps1** — Identify unmanaged VMs  
Find VMs that exist on Hyper-V hosts but aren't registered as cluster resources.

```powershell
.\FindOrphanedVMs.ps1
```

---

## Common Tasks

### Prepare a Cluster for CAU

1. **Validate cluster health first:**
   ```powershell
   Get-Cluster | Test-Cluster
   ```

2. **Run in dry-run mode:**
   ```powershell
   .\CAU\Prepare-ClusterForCAU.ps1 -ClusterName "MyCluster" -DryRun
   ```

3. **Review the proposed changes**

4. **Deploy with backup:**
   ```powershell
   .\CAU\Prepare-ClusterForCAU.ps1 -ClusterName "MyCluster" -BackupConfig
   ```

5. **Check logs in `Logs/` subdirectory**

### Find and Clean Up Orphaned VMs

```powershell
# Generate report
.\FindOrphanedVMs.ps1

# Review the exported txt file
# Then remediate:
Invoke-Command -ComputerName NodeName -ScriptBlock {
  Stop-VM -Name "OrphanedVM"
  Remove-VM -Name "OrphanedVM"
}
```

### Monitor Cluster Memory

```powershell
# Single report
.\Cluster\ RAM\ Report.ps1 -ClusterName "PROD-Cluster"

# Monitor script (run periodically)
while ($true) {
  .\Cluster\ RAM\ Report.ps1 -ClusterName "PROD-Cluster"
  Start-Sleep -Seconds 300
}
```

---

## Prerequisites

### System Requirements
- Windows Server 2019 or later
- PowerShell 5.1+
- Failover Clustering feature enabled
- Cluster admin privileges
- WinRM enabled on all nodes

### Network Requirements
- Remote invocation (PSRemoting) enabled
- WMI/DCOM accessible between nodes
- Firewall exceptions for WinRM and WMI

### Modules
- `FailoverClusters` — Included with Windows Server

---

## Best Practices

### Before Running Cluster Scripts

1. ✅ **Backup configurations** — Always use `-BackupConfig` for production
2. ✅ **Test in lab first** — Use `-DryRun` to preview changes
3. ✅ **Cluster must be healthy** — Run `Get-Cluster | Test-Cluster`
4. ✅ **Schedule maintenance window** — Avoid peak usage times
5. ✅ **Notify team members** — Document what you're doing

### Error Recovery

If something goes wrong:

1. Check the timestamped log file in `Logs/`
2. Review error messages for remediation guidance
3. If you used `-BackupConfig`, rollback is available
4. Contact cluster admin for manual recovery if needed

---

## Troubleshooting

### "Cluster not found"
```powershell
# Verify cluster context
Get-Cluster
Get-ClusterNode

# Ensure you're running as cluster admin
whoami /all
```

### WinRM connectivity errors
```powershell
# Test WinRM on a node
Test-WsMan -ComputerName <NodeName>

# Check listener configuration
Get-Item WSMan:\localhost\Listener\
```

### "Access denied" errors
- Verify you have cluster admin privileges
- Check UAC (User Access Control) permissions
- Ensure remote invocation is enabled: `Enable-PSRemoting -Force`

### Scripts running slowly
- Scripts query remote nodes sequentially
- Larger clusters naturally take longer
- Check network connectivity to nodes
- Verify WMI performance on nodes

---

## Documentation

Complete documentation is built into each script:

```powershell
# Full help and examples
Get-Help .\prepare-ClusterForCAU.ps1 -Full

# Just examples
Get-Help .\Prepare-ClusterForCAU.ps1 -Examples

# Specific parameter help
Get-Help .\Prepare-ClusterForCAU.ps1 -Parameter ClusterName
```

---

## Related Resources

- [Microsoft Failover Clustering Docs](https://docs.microsoft.com/en-us/windows-server/failover-clustering/)
- [Cluster-Aware Updating Guide](https://docs.microsoft.com/en-us/windows-server/failover-clustering/cluster-aware-updating)
- [PowerShell Remoting](https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/running-remote-commands)
- [WinRM Configuration](https://docs.microsoft.com/en-us/windows/win32/winrm/portal)

---

**Back to:** [Main README](../README.md)
