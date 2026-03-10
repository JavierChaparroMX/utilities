# Cluster-Aware Updating (CAU) Preparation Scripts

Two companion scripts to safely prepare a Windows Server Failover Cluster for Cluster-Aware Updating (CAU).

## Overview

CAU requires proper WinRM configuration (WMIv2/CIM communication) and correctly configured cluster network roles. These scripts provide a **safe, deliberate two-step process**:

1. **Discover-ClusterCAUReadiness.ps1** - Safe read-only audit (no risk)
2. **Prepare-ClusterForCAU.ps1** - Configured changes (with safeguards)

## Why Two Scripts?

The discovery script was created to address production safety concerns:

- **Risk Mitigation**: Understand current state before making changes
- **Team Coordination**: Identify GPO policies, monitoring tools, and network configurations that need coordination
- **Decision Support**: Export reports in CSV/JSON for analysis and discussion with infrastructure teams
- **Transparency**: No "surprise" destructive changes; show what will change first via dry-run

## Quick Start Workflow

```powershell
# Step 1: Run discovery (safe, non-destructive)
.\Discover-ClusterCAUReadiness.ps1 -ClusterName "PROD-Cluster"

# Step 2: Review reports in the generated Discovery-Reports folder
#   - Node-Discovery-Summary.csv (overview of all nodes)
#   - Node-Discovery-Full.json (detailed per-node configuration)
#   - Cluster-Networks.csv (network topology)
#   - Discovery-Report.txt (analysis and recommendations)

# Step 3: Coordinate with teams
#   - GPO administrators (if Group Policy WinRM policies found)
#   - Monitoring team (if legacy monitoring agents detected)
#   - Network administrators (verify network names/roles)

# Step 4: Dry-run preparation (preview without changes)
.\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" -DryRun -DetectGPOConflicts

# Step 5: Production run (conservative, preserving legacy configs)
.\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" `
  -StorageNetworks "10.0.10.X (Storage1)","10.0.20.X (Storage2)" `
  -ManagementNetwork "10.0.1.X (Management)" `
  -PreserveLegacyListeners `
  -BackupConfig
```

## Script Details

### Discover-ClusterCAUReadiness.ps1

**Status**: SAFE - Read-only, no modifications

**Purpose**: Audit current cluster configuration for CAU readiness

**What It Reports**:
- WinRM service status and startup type on each node
- WinRM listeners (address binding, transport, port)
- WinRM authentication settings (Basic, Kerberos, etc.)
- Firewall rules (WinRM-In, Remote Shutdown)
- Active PowerShell remoting sessions
- PowerShell execution policy
- Group Policy WinRM/Firewall policies (if present)
- Monitoring agents (SCOM, Datadog, SolarWinds, PRTG, Telegraf, Prometheus)
- WS-Management connectivity test results
- Cluster network roles and descriptions

**Output Formats**:
- `Node-Discovery-Summary.csv` - Quick comparison across nodes
- `Node-Discovery-Full.json` - Complete per-node details
- `Cluster-Networks.csv` - Network topology
- `Discovery-Report.txt` - Analysis, warnings, and recommendations

**Usage**:
```powershell
# Full discovery with all checks
.\Discover-ClusterCAUReadiness.ps1 -ClusterName "PROD-Cluster"

# Quick discovery (skip GPO and monitoring checks)
.\Discover-ClusterCAUReadiness.ps1 -ClusterName "PROD-Cluster" `
  -SkipGPOAnalysis -SkipMonitoringDetection

# Custom output location
.\Discover-ClusterCAUReadiness.ps1 -ClusterName "PROD-Cluster" `
  -OutputPath "C:\Reports\CAU-Audit"
```

### Prepare-ClusterForCAU.ps1

**Status**: MODIFYING - Makes configuration changes (with safeguards)

**Purpose**: Configure cluster nodes for CAU functionality

**Key Safeguards**:
- Pre-flight validation (admin privileges, module availability, node health)
- Dry-run mode to preview changes without executing (-DryRun)
- Backup capability to preserve original config (-BackupConfig)
- PSRemoting pre-check to avoid unnecessary service restarts
- Listener preservation option for legacy security policies (-PreserveLegacyListeners)
- Opt-in authentication hardening (-EnforceStrictWinRMSecurity, off by default)
- GPO conflict detection and warnings (-DetectGPOConflicts)
- Comprehensive logging with timestamps and status tracking

**What It Configures**:
- WinRM service (enable, set to Automatic startup, optionally Delayed)
- WinRM listeners (normalize to wildcard Address=*, optionally preserve IP-bound)
- WinRM authentication (optionally enforce Kerberos-only, disable Basic)
- Firewall rules (enable WinRM HTTP-In and Remote Shutdown)
- Cluster network roles (set storage networks to Role=0, management to Role=3)

**Usage Examples**:

```powershell
# Dry-run: Preview what would change (ALWAYS run this first)
.\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" -DryRun -DetectGPOConflicts

# Conservative production run (preserve legacy listeners, backup config)
.\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" `
  -StorageNetworks "10.0.10.X (Storage1)","10.0.20.X (Storage2)" `
  -ManagementNetwork "10.0.1.X (Management)" `
  -PreserveLegacyListeners `
  -BackupConfig `
  -LogPath "C:\Logs\CAU-Prep.log"

# Advanced: Full hardening (only after team coordination)
.\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" `
  -StorageNetworks "10.0.10.X (Storage1)" `
  -ManagementNetwork "10.0.1.X (Management)" `
  -EnforceStrictWinRMSecurity `
  -DetectGPOConflicts `
  -BackupConfig `
  -DelayedAutoStartWinRM

# WinRM only (skip network role changes)
.\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" `
  -SkipNetworkRoleChanges `
  -DryRun

# Restore from backup (if needed)
.\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" `
  -RestoreFromBackup
```

## Important Parameters

### Discover-ClusterCAUReadiness.ps1

| Parameter | Purpose | Default |
|-----------|---------|---------|
| `-ClusterName` | Target cluster name | Local cluster |
| `-OutputPath` | Report output directory | `.\Discovery-Reports-YYYYMMDD-HHMMSS` |
| `-SkipGPOAnalysis` | Skip GPO policy check | False (check policies) |
| `-SkipMonitoringDetection` | Skip monitoring tool detection | False (detect tools) |

### Prepare-ClusterForCAU.ps1

| Parameter | Purpose | Default | Risk Level |
|-----------|---------|---------|------------|
| `-ClusterName` | Target cluster name | Local cluster | Low |
| `-DryRun` | Preview without changes | False | None (safe) |
| `-StorageNetworks` | Networks to set Role=0 | None | Critical |
| `-ManagementNetwork` | Network to set Role=3 | None | Critical |
| `-PreserveLegacyListeners` | Keep IP-bound listeners | False (delete) | Mitigates risk |
| `-EnforceStrictWinRMSecurity` | Harden auth settings | False (skip hardening) | High |
| `-DetectGPOConflicts` | Check for GPO policies | False | Low |
| `-BackupConfig` | Backup before changes | False | Low (supportive) |
| `-DelayedAutoStartWinRM` | Set WinRM delayed start | False | Low |
| `-SkipNetworkRoleChanges` | Skip network changes | False | Low |

## Critical Warnings

### Network Role Changes ⚠️

**DANGER**: Setting a network's role to `0` (Do NOT allow cluster communication) means cluster heartbeats WILL NOT use that network. 

- If you specify the wrong network name, cluster nodes lose quorum immediately
- Cluster partitions and **all hosted workloads go offline instantly**
- Always verify network names match your infrastructure
- Always use `-DryRun` first to preview
- Run discovery script to confirm network topology before specifying `-StorageNetworks`

### Authentication Hardening ⚠️

`-EnforceStrictWinRMSecurity` will **break legacy monitoring tools** that rely on:
- Basic Authentication (HTTP)
- Unencrypted traffic

Before enabling:
1. Identify all monitoring agents (discovery script detects them)
2. Verify compatibility with Kerberos-only auth
3. Coordinate with monitoring team
4. Plan for tool configuration updates or replacement

### Group Policy Conflicts ⚠️

If domain enforces WinRM settings via GPO:
- Local script changes will be overwritten at next GPO refresh (90-120 min)
- This creates a "yo-yo" effect where settings revert unpredictably
- **Better approach**: Update GPO policies instead of running scripts locally
- Coordinate with GPO/domain administrators

### Metadata Inconsistency ⚠️

Windows may present network adapters differently per node:
- Network names might vary by node
- IP addresses might be asymmetric
- Run discovery script to confirm consistency before using `-StorageNetworks`

## Reverting Changes

### Option 1: Restore from Backup
```powershell
.\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" -RestoreFromBackup
```

### Option 2: Manual Revert Network Roles
```powershell
$network = Get-ClusterNetwork -Name "10.0.10.X (Storage1)"
$network.Role = 3  # Or appropriate role value
```

### Option 3: Re-enable IP-Bound Listeners
```powershell
# On affected node, recreate IP-bound listener if deleted
New-Item -Path 'WSMan:\localhost\Listener' -Transport HTTP -Address 10.0.1.100 -Force
```

## Troubleshooting

### Discovery Script Slow?
- Use `-SkipGPOAnalysis` to skip Group Policy checks
- Use `-SkipMonitoringDetection` to skip monitoring agent scan

### Discovery Script Missing Data?
- Check output CSV/JSON files in generated Discovery-Reports folder
- Verify nodes are reachable (`Test-Connection`)
- Verify you have cluster admin privileges
- Check `-CommandTimeout` if nodes respond slowly

### Preparation Script Fails on Node?
- Check node is reachable and responding
- Verify node is cluster member (`Get-ClusterNode`)
- Check for Group Policy WinRM locks (use `-DetectGPOConflicts`)
- Review log file for specific error messages

### WinRM Still Not Working After Script?
- Run discovery script to capture current state
- Verify wildcard listener exists: `Get-ChildItem 'WSMan:\localhost\Listener'`
- Confirm firewall rules enabled: `Get-NetFirewallRule -DisplayGroup "Windows Remote Management"`
- Test WSMan: `Test-WsMan -ComputerName <nodename>`

## Logs and Backup Locations

- **Preparation logs**: `.\Logs\Prepare-ClusterForCAU-YYYYMMDD-HHMMSS.log`
- **Backup configs**: `C:\Windows\System32\config\systemprofile\backup\WinRM-Config-YYYYMMDD-HHMMSS.xml` (on each node)
- **Discovery reports**: `.\Discovery-Reports-YYYYMMDD-HHMMSS\` (in script directory by default)

## Best Practices

1. **Always run discovery first** - Understand current state before changes
2. **Always use dry-run** - Preview changes before executing
3. **Backup before production run** - Use `-BackupConfig` for quick rollback
4. **Coordinate with teams** - Review discovery reports with infrastructure teams
5. **Test in non-prod first** - Run scripts in dev/test environments first
6. **Document changes** - Keep discovery reports for audit trail
7. **Monitor after changes** - Watch cluster health for CAU readiness
8. **Consider GPO** - Implement persistent changes via Group Policy instead of scripts

## FAQ

**Q: Can I run both scripts on production clusters?**
A: Yes. Discovery is always safe. Preparation should be dry-run first, then scheduled during maintenance window.

**Q: What if a node has GPO WinRM policies?**
A: Use `-DetectGPOConflicts` to identify. Coordinate with GPO admins to update policies instead of overriding locally.

**Q: What if I have legacy monitoring that needs Basic Auth?**
A: Use discovery script to identify agents, then do NOT use `-EnforceStrictWinRMSecurity`. Coordinate with monitoring team on Kerberos migration plan.

**Q: Can I run this script across multiple clusters?**
A: Yes, but run discovery and dry-run separately for each cluster to understand differences.

**Q: What if network names are different on each node?**
A: Discovery script identifies this. Review discovery reports carefully. You may need to manually adjust each node.

**Q: How long do changes persist after script runs?**
A: WinRM changes persist permanently. Network role changes persist permanently. Unless overridden by GPO or manual revert.

## Support and Troubleshooting

- Review script inline comments for detailed explanations
- Check `-LogPath` output for detailed execution trace
- Run discovery script to capture baseline before changes
- Use backup/restore capability to rollback if needed
- Coordinate with infrastructure teams when GPO, monitoring, or network questions arise
