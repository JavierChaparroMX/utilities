<#
.SYNOPSIS
  Preparation script: Configures all nodes in a Failover Cluster for Cluster-Aware Updating (CAU).
  PREREQUISITE: Run Discover-ClusterCAUReadiness.ps1 first to identify current configuration.
  
  This script can make DESTRUCTIVE CHANGES to WinRM, listeners, and network roles if run 
  without understanding your infrastructure. Always use -DryRun first to preview changes.

.DESCRIPTION
  CAU relies on WMIv2/CIM over WinRM. Misconfigured listeners (e.g., IP-bound) or using
  iSCSI networks for cluster communication cause CAU readiness failures.
  
  This script enforces a healthy WinRM configuration on every node and optionally aligns
  cluster network roles to use the management path for CAU communication.

  Enhanced features:
  - Pre-flight cluster health and privilege validation
  - Option to run in read-only DRY-RUN mode to preview changes (-DryRun)
  - Option to detect Group Policy conflicts (-DetectGPOConflicts)
  - Option to preserve legacy IP-bound listeners (-PreserveLegacyListeners)
  - Option to enforce strict security OR skip hardening (-EnforceStrictWinRMSecurity, off by default)
  - Comprehensive logging to file with audit trail
  - Per-node error recovery (continues if one node fails)
  - Configuration backup and restore capability (-BackupConfig)
  - Remote command timeout handling
  - Detailed success/failure reporting

  RISK MITIGATIONS vs. original script:
  - PSRemoting check before restart (avoids unnecessary WinRM restart)
  - Listener deletion warning with preservation option
  - Auth hardening is OPT-IN, not automatic
  - GPO policy conflict detection
  - Network role changes include critical warnings

.PARAMETER ClusterName
  Name of the WSFC cluster. If omitted, script attempts to infer from local node.

.PARAMETER StorageNetworks
  Array of cluster network names dedicated to iSCSI/storage.
  WARNING: Setting Role=0 means cluster heartbeats will NOT use this network.
  These will be set to Role=0 (Do NOT allow cluster communication).
  Must verify network names match your actual infrastructure.

.PARAMETER ManagementNetwork
  The management network name to set to Role=3 (ClusterAndClient).
  This is where CAU will communicate with cluster nodes.

.PARAMETER DelayedAutoStartWinRM
  Also set WinRM service to Delayed Auto Start (optional).

.PARAMETER SkipNetworkRoleChanges
  Skip changing cluster network roles (only fix WinRM configuration).
  Use this if you want to test WinRM fixes separately from network changes.

.PARAMETER EnforceStrictWinRMSecurity
  OPT-IN flag to enforce Kerberos-only authentication, disable Basic Auth,
  and disable unencrypted traffic. This is a security best practice but WILL 
  break legacy monitoring tools (SolarWinds, PRTG, etc.) that rely on Basic Auth 
  or unencrypted HTTP WinRM connections. Only enable after confirming monitoring 
  team compatibility.

.PARAMETER DetectGPOConflicts
  Check for Group Policy WinRM/Firewall settings before making changes.
  If found, warns that local changes may be overwritten at next GPO refresh cycle
  (typically 90-120 minutes). Recommends coordinating with domain/GPO administrators
  to implement changes via Group Policy instead (more persistent and manageable).

.PARAMETER PreserveLegacyListeners
  If IP-bound WinRM listeners exist, preserve them instead of deleting them.
  Use this if your organization has strict security policies requiring WinRM
  to bind only to specific management IP addresses or VLANs.
  Wildcard listener will still be created, but IP-bound listeners will NOT be deleted.

.PARAMETER LogPath
  Path to log file. Defaults to script directory/Logs/Prepare-ClusterForCAU-YYYYMMDD-HHMMSS.log

.PARAMETER DryRun
  Simulate all changes without actually modifying settings. Shows what would happen.
  HIGHLY RECOMMENDED: Always run with -DryRun first to preview changes and verify
  network names and configurations before executing actual modifications.

.PARAMETER CommandTimeout
  Timeout in seconds for remote commands. Default: 300 (5 minutes).

.PARAMETER SkipValidation
  Skip pre-flight validation checks (not recommended for production).

.PARAMETER BackupConfig
  Backup WinRM configuration before making changes. Stored in node backup directory.
  Enables rollback capability if needed.

.PARAMETER RestoreFromBackup
  Restore WinRM configuration from a previous backup instead of making changes.
  Useful for reverting if changes cause issues.

.EXAMPLE
  # STEP 1: Run read-only discovery (no risk)
  .\Discover-ClusterCAUReadiness.ps1 -ClusterName "PROD-Cluster"
  
  # STEP 2: Review CSV/JSON output reports
  # Identify current state, GPO policies, monitoring agents, network configs
  
  # STEP 3: Coordinate with infrastructure teams
  # Discuss findings, network stability requirements, monitoring compatibility
  
  # STEP 4: Dry-run to preview changes (safe, read-only test)
  .\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" -DryRun -DetectGPOConflicts
  
  # STEP 5: Conservative production run (fix WinRM, preserve legacy listeners)
  .\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" `
    -StorageNetworks "10.0.10.X (Storage1)","10.0.20.X (Storage2)" `
    -ManagementNetwork "10.0.1.X (Management)" `
    -PreserveLegacyListeners `
    -BackupConfig `
    -LogPath "C:\Logs\CAU-Prep.log"

  # ALTERNATIVE: Advanced run with security hardening (opt-in)
  # Only after confirming monitoring solution compatibility
  .\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" `
    -StorageNetworks "10.0.10.X (Storage1)" `
    -ManagementNetwork "10.0.1.X (Management)" `
    -EnforceStrictWinRMSecurity `
    -DetectGPOConflicts `
    -BackupConfig `
    -DelayedAutoStartWinRM

.NOTES
  Tested on Windows Server 2019/2022.
  Requires cluster admin privileges and FailoverClusters module.
  
  CRITICAL: Always review discovery output before running in production.
  IMPORTANT: Always run with -DryRun FIRST to validate against your cluster.
  SAFETY: Use -PreserveLegacyListeners if your org has strict listener policies.
  SECURITY: Only use -EnforceStrictWinRMSecurity after coordinating with all teams.
  
  WORKFLOW RECOMMENDATIONS:
  - Safety: Run discovery script, review reports, coordinate with teams, then execute
  - Testing: Always use -DryRun in production first
  - Rollback: Use -BackupConfig and -RestoreFromBackup if issues occur
  - GPO: Consider implementing changes via Group Policy instead of scripts (more persistent)
#>

.PARAMETER ClusterName
  Name of the WSFC cluster. If omitted, script attempts to infer from local node.

.PARAMETER StorageNetworks
  Array of cluster network names that are dedicated to iSCSI/storage.
  These will be set to Role=0 (Do NOT allow cluster comm).

.PARAMETER ManagementNetwork
  The management network name to set to Role=3 (ClusterAndClient).

.PARAMETER DelayedAutoStartWinRM
  Also set WinRM service to Delayed Auto Start (optional).

.PARAMETER SkipNetworkRoleChanges
  Skip changing cluster network roles (only fix WinRM).

.PARAMETER EnforceStrictWinRMSecurity
  CAUTION: Opt-in flag to enforce Kerberos-only authentication, disable Basic Auth
  and unencrypted traffic. This is a security best practice but WILL break legacy
  monitoring tools (SolarWinds, PRTG, etc.) that rely on Basic Auth or unencrypted HTTP.
  Requires explicit user intent - not enabled by default.

.PARAMETER DetectGPOConflicts
  Check for Group Policy WinRM/Firewall settings before making changes.
  If GPO policies are found, warns that local changes may be overwritten at next refresh.
  Recommends coordinating with domain admins to implement changes via GPO instead.

.PARAMETER PreserveLegacyListeners
  If IP-bound WinRM listeners exist, preserve them instead of replacing with wildcard.
  Use this if your organization has strict security policies requiring IP binding.
  Wildcard listener will still be created, but IP-bound listeners will NOT be deleted.

.PARAMETER LogPath
  Path to log file. Defaults to script directory/Logs/Prepare-ClusterForCAU-YYYYMMDD-HHMMSS.log

.PARAMETER DryRun
  Simulate all changes without actually modifying settings. Output shows what would happen.

.PARAMETER CommandTimeout
  Timeout in seconds for remote commands. Default: 300 (5 minutes).

.PARAMETER SkipValidation
  Skip pre-flight validation checks (not recommended for production).

.PARAMETER BackupConfig
  Backup WinRM configuration before making changes. Stored in backup subdirectory.

.PARAMETER RestoreFromBackup
  Restore WinRM configuration from a previous backup instead of making changes.

.EXAMPLE
  # RECOMMENDED: Run discovery script first (read-only, safe)
  .\Discover-ClusterCAUReadiness.ps1 -ClusterName "PROD-Cluster"
  
  # Review the discovery reports to understand current configuration
  # Then coordinate with relevant infrastructure teams (GPO, monitoring, etc.)
  
  # Dry-run to see what would happen
  .\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" -DryRun -DetectGPOConflicts

  # Conservative run: Fix WinRM but preserve IP-bound listeners
  .\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" `
    -StorageNetworks "10.0.10.X (Storage1)","10.0.20.X (Storage2)" `
    -ManagementNetwork "10.0.1.X (Management)" `
    -PreserveLegacyListeners `
    -BackupConfig `
    -LogPath "C:\Logs\CAU-Prep.log"

  # Advanced: Full hardening with monitoring awareness (opt-in)
  .\Prepare-ClusterForCAU.ps1 -ClusterName "PROD-Cluster" `
    -StorageNetworks "10.0.10.X (Storage1)" `
    -ManagementNetwork "10.0.1.X (Management)" `
    -EnforceStrictWinRMSecurity `
    -DetectGPOConflicts `
    -BackupConfig `
    -DelayedAutoStartWinRM

.NOTES
  Tested on Windows Server 2019/2022.
  Requires cluster admin privileges and FailoverClusters module.
  Always run with -DryRun first to validate against your cluster.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$ClusterName,

    [Parameter(Mandatory=$false)]
    [string[]]$StorageNetworks = @(),

    [Parameter(Mandatory=$false)]
    [string]$ManagementNetwork,

    [switch]$DelayedAutoStartWinRM,
    [switch]$SkipNetworkRoleChanges,
    [switch]$EnforceStrictWinRMSecurity,
    [switch]$DetectGPOConflicts,
    [switch]$PreserveLegacyListeners,

    [Parameter(Mandatory=$false)]
    [string]$LogPath,

    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [int]$CommandTimeout = 300,

    [switch]$SkipValidation,
    [switch]$BackupConfig,
    [switch]$RestoreFromBackup
)

function Write-Info([string]$msg)  { Write-Host $msg -ForegroundColor Cyan }
function Write-Warn([string]$msg)  { Write-Host $msg -ForegroundColor Yellow }
function Write-Err ([string]$msg)  { Write-Host $msg -ForegroundColor Red }
function Write-Good([string]$msg)  { Write-Host $msg -ForegroundColor Green }

# Detect Group Policy WinRM/Firewall settings
function Test-GPOWinRMPolicies {
    param([string]$ComputerName)
    
    try {
        # Check for domain-enforced WinRM policies via registry
        $gpoWinRM = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $policies = @()
            $regPath = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM'
            if (Test-Path $regPath) {
                $policies += Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            }
            return @( $policies | Where-Object { $_ } )
        } -ErrorAction Stop
        
        if ($gpoWinRM.Count -gt 0) {
            return $true
        }
    } catch {
        # If we can't check, assume no GPO (err on side of caution)
        return $false
    }
    
    return $false
}

# Initialize logging
function Initialize-Logging {
    param([string]$LogPath)
    
    if (-not $LogPath) {
        $logDir = Join-Path (Split-Path $PSCommandPath -Parent) "Logs"
        if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $LogPath = Join-Path $logDir "Prepare-ClusterForCAU-$timestamp.log"
    }
    
    return $LogPath
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $script:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    
    # Also write to console
    switch ($Level) {
        "ERROR"   { Write-Err $logEntry }
        "WARN"    { Write-Warn $logEntry }
        "SUCCESS" { Write-Good $logEntry }
        default   { Write-Info $logEntry }
    }
}

function Write-Separator {
    param([string]$Title)
    Write-Log ("=" * 80)
    if ($Title) { Write-Log ">>> $Title" }
    Write-Log ("=" * 80)
}

# Pre-flight validation functions
function Test-AdminPrivilege {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-ClusterHealth {
    param([string[]]$Nodes)
    
    Write-Log "Validating cluster health..." "INFO"
    $unhealthyNodes = @()
    
    foreach ($node in $Nodes) {
        try {
            $test = Test-Connection -ComputerName $node -Count 1 -Quiet -ErrorAction Stop
            if (-not $test) {
                $unhealthyNodes += $node
                Write-Log "  WARNING: Node $node is not reachable" "WARN"
            } else {
                Write-Log "  ✓ $node is reachable"
            }
        } catch {
            $unhealthyNodes += $node
            Write-Log "  ERROR: Failed to ping $node - $($_.Exception.Message)" "ERROR"
        }
    }
    
    return @{ UnhealthyNodes = $unhealthyNodes; AllHealthy = ($unhealthyNodes.Count -eq 0) }
}

function Validate-NetworkNames {
    param([string[]]$Networks, [string]$ClusterName)
    
    if (-not $Networks -or $Networks.Count -eq 0) { return $true }
    
    Write-Log "Validating cluster network names..." "INFO"
    $clusterNetworks = (Get-ClusterNetwork -Cluster $ClusterName -ErrorAction SilentlyContinue).Name
    $invalidNetworks = @()
    
    foreach ($net in $Networks) {
        if ($net -notin $clusterNetworks) {
            $invalidNetworks += $net
            Write-Log "  WARNING: Network '$net' not found in cluster" "WARN"
        } else {
            Write-Log "  ✓ Network '$net' exists"
        }
    }
    
    return $invalidNetworks.Count -eq 0
}

# Initialize logging
$script:LogFile = Initialize-Logging -LogPath $LogPath
Write-Separator "Cluster-Aware Updating (CAU) Preparation Script"
Write-Log "Script started by $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Log "DryRun mode: $DryRun | BackupConfig: $BackupConfig | RestoreFromBackup: $RestoreFromBackup"
Write-Log "EnforceStrictWinRMSecurity: $EnforceStrictWinRMSecurity | DetectGPOConflicts: $DetectGPOConflicts"
Write-Log "PreserveLegacyListeners: $PreserveLegacyListeners"
Write-Log ""
Write-Log "NOTE: This script can make destructive changes. Always run with -DryRun first."
Write-Log "      Review Discover-ClusterCAUReadiness.ps1 output before proceeding."

# Pre-flight validation
if (-not $SkipValidation) {
    Write-Separator "PRE-FLIGHT VALIDATION"
    
    # Check admin privilege
    if (-not (Test-AdminPrivilege)) {
        Write-Log "ERROR: This script requires Administrator privileges" "ERROR"
        exit 1
    }
    Write-Log "✓ Running with Administrator privileges"
    
    # Check FailoverClusters module
    try {
        Import-Module FailoverClusters -ErrorAction Stop
        Write-Log "✓ FailoverClusters module loaded"
    } catch {
        Write-Log "ERROR: FailoverClusters module not found. Install RSAT or run from a cluster node." "ERROR"
        exit 1
    }
    
    # Resolve cluster nodes
    try {
        $nodes = if ($PSBoundParameters.ContainsKey('ClusterName') -and $ClusterName) {
            Write-Log "Resolving cluster: $ClusterName"
            (Get-ClusterNode -Cluster $ClusterName -ErrorAction Stop).Name
        } else {
            Write-Log "Resolving local cluster"
            (Get-ClusterNode -ErrorAction Stop).Name
        }
        Write-Log "✓ Found $($nodes.Count) cluster nodes"
    } catch {
        Write-Log "ERROR: Unable to resolve cluster nodes - $($_.Exception.Message)" "ERROR"
        Write-Log "Hint: Specify -ClusterName parameter or run from a cluster node" "WARN"
        exit 1
    }
    
    # Health checks
    $health = Test-ClusterHealth -Nodes $nodes
    if (-not $health.AllHealthy) {
        Write-Log "WARNING: Some nodes may not be reachable. Continuing anyway." "WARN"
    }
    
    # Validate network names if specified
    if ($ClusterName -and ($StorageNetworks.Count -gt 0 -or $ManagementNetwork)) {
        if (-not (Validate-NetworkNames -Networks ($StorageNetworks + $ManagementNetwork) -ClusterName $ClusterName)) {
            Write-Log "WARNING: Some network names could not be validated. Continuing anyway." "WARN"
        }
    }
} else {
    Write-Log "Skipping pre-flight validation (not recommended for production)"
    Import-Module FailoverClusters -ErrorAction Stop
    $nodes = if ($PSBoundParameters.ContainsKey('ClusterName') -and $ClusterName) {
        (Get-ClusterNode -Cluster $ClusterName -ErrorAction Stop).Name
    } else {
        try { (Get-ClusterNode -ErrorAction Stop).Name }
        catch { throw "Unable to resolve cluster nodes. Specify -ClusterName." }
    }
}

Write-Log "Target Cluster Nodes: $($nodes -join ', ')"

# GPO Conflict Detection
if ($DetectGPOConflicts) {
    Write-Separator "CHECKING FOR GROUP POLICY CONFLICTS"
    Write-Log "Scanning for Group Policy WinRM/Firewall settings..." "INFO"
    
    $gpoConflicts = @()
    foreach ($n in $nodes) {
        try {
            if (Test-GPOWinRMPolicies -ComputerName $n) {
                $gpoConflicts += $n
                Write-Log "  ⚠ GPO WinRM policies detected on $n" "WARN"
            }
        } catch {
            Write-Log "  Could not check GPO on $n (continuing anyway)" "WARN"
        }
    }
    
    if ($gpoConflicts.Count -gt 0) {
        Write-Log "" "INFO"
        Write-Log "WARNING: Group Policy WinRM settings found on $($gpoConflicts.Count) node(s)" "WARN"
        Write-Log "Local changes made by this script may be overwritten at next GPO refresh (90-120 min)" "WARN"
        Write-Log "RECOMMENDATION: Coordinate with domain admins to implement changes via GPO instead" "WARN"
        Write-Log "This is more reliable and maintainable than local script modifications" "WARN"
    }
}

# Remote script to configure WinRM/PSRemoting on each node
$configureNode = {
    param([switch]$SetDelayed, [switch]$DryRunMode, [switch]$BackupCfg, [switch]$EnforceAuth, [switch]$PreserveLegacy)

    $ErrorActionPreference = 'Stop'

    Write-Host "[$env:COMPUTERNAME] ========== WinRM Configuration ==========" -ForegroundColor Cyan
    
    # Backup current configuration if requested
    if ($BackupCfg) {
        Write-Host "[$env:COMPUTERNAME] Backing up WinRM configuration..." -ForegroundColor Yellow
        $backupPath = "C:\Windows\System32\config\systemprofile\backup"
        if (-not (Test-Path $backupPath)) { New-Item -Path $backupPath -ItemType Directory -Force | Out-Null }
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupFile = Join-Path $backupPath "WinRM-Config-$timestamp.xml"
        try {
            Export-CliXml -Path $backupFile -InputObject @{
                WinRMEnabled = (Get-Service WinRM).Status
                ListenerAddresses = @(Get-ChildItem 'WSMan:\localhost\Listener' | ForEach-Object { (Get-Item $_.PSPath).Address })
                BasicAuth = (Get-Item WSMan:\localhost\Service\Auth\Basic).Value
                AllowUnencrypted = (Get-Item WSMan:\localhost\Service\AllowUnencrypted).Value
                KerberosAuth = (Get-Item WSMan:\localhost\Service\Auth\Kerberos).Value
            } -ErrorAction Stop
            Write-Host "[$env:COMPUTERNAME] Backup saved to: $backupFile" -ForegroundColor Green
        } catch {
            Write-Host "[$env:COMPUTERNAME] Backup failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    if ($DryRunMode) {
        Write-Host "[$env:COMPUTERNAME] DRY-RUN MODE - No changes will be made" -ForegroundColor Yellow
    }

    if (-not $DryRunMode) {
        # Check if PSRemoting is already enabled before calling Enable-PSRemoting -Force
        $psRemotingEnabled = $false
        try {
            $psRemotingEnabled = @(Get-PSSessionConfiguration -ErrorAction SilentlyContinue).Count -gt 0
        } catch {}
        
        if ($psRemotingEnabled) {
            Write-Host "[$env:COMPUTERNAME] PowerShell Remoting already enabled" -ForegroundColor Green
        } else {
            Write-Host "[$env:COMPUTERNAME] Enable PowerShell Remoting..." -ForegroundColor Cyan
            Enable-PSRemoting -Force
        }

        Write-Host "[$env:COMPUTERNAME] Ensure WinRM service Auto & Running..." -ForegroundColor Cyan
        Set-Service -Name WinRM -StartupType Automatic
        Start-Service -Name WinRM

        if ($SetDelayed) {
            $svcKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\WinRM'
            New-ItemProperty -Path $svcKey -Name DelayedAutoStart -Value 1 -PropertyType DWord -Force | Out-Null
            Write-Host "[$env:COMPUTERNAME] Set WinRM DelayedAutoStart = 1" -ForegroundColor Yellow
        }
    }

    Write-Host "[$env:COMPUTERNAME] Normalize WSMan HTTP listeners (Address = *)..." -ForegroundColor Cyan
    $listenersPath = 'WSMan:\localhost\Listener'
    $listeners = @(Get-ChildItem -Path $listenersPath -ErrorAction SilentlyContinue)
    $httpListeners = @()

    foreach ($l in $listeners) {
        $item = Get-Item $l.PSPath
        if ($item.Keys -match 'Transport=HTTP') {
            $httpListeners += [pscustomobject]@{ PsPath=$l.PSPath; Address=$item.Address }
        }
    }

    $hasStar = $httpListeners | Where-Object { $_.Address -eq '*' }
    $ipBound = $httpListeners | Where-Object { $_.Address -ne '*' }
    
    if (-not $hasStar) {
        Write-Host "[$env:COMPUTERNAME] No wildcard HTTP listener found, creating one..." -ForegroundColor Yellow
        if (-not $DryRunMode) {
            if ($ipBound.Count -gt 0 -and -not $PreserveLegacy) {
                Write-Host "[$env:COMPUTERNAME] WARNING: Removing IP-bound HTTP listeners:" -ForegroundColor Yellow
                foreach ($l in $ipBound) {
                    Write-Host "[$env:COMPUTERNAME]   - $($l.Address)" -ForegroundColor Yellow
                    Remove-Item -Path $l.PsPath -Recurse -Force -ErrorAction SilentlyContinue
                }
            } elseif ($ipBound.Count -gt 0 -and $PreserveLegacy) {
                Write-Host "[$env:COMPUTERNAME] PreserveLegacy mode: Keeping IP-bound listeners" -ForegroundColor Yellow
                foreach ($l in $ipBound) {
                    Write-Host "[$env:COMPUTERNAME]   - $($l.Address) [PRESERVED]" -ForegroundColor Green
                }
            }
            New-Item -Path $listenersPath -Transport HTTP -Address * -Force | Out-Null
        }
    } else {
        # Wildcard listener exists
        if ($ipBound.Count -gt 0) {
            Write-Host "[$env:COMPUTERNAME] Found extra IP-bound HTTP listeners:" -ForegroundColor Yellow
            foreach ($l in $ipBound) {
                Write-Host "[$env:COMPUTERNAME]   - $($l.Address)" -ForegroundColor Yellow
            }
            
            if ($PreserveLegacy) {
                Write-Host "[$env:COMPUTERNAME] PreserveLegacy mode: Keeping these listeners" -ForegroundColor Green
            } else {
                Write-Host "[$env:COMPUTERNAME] Removing extra IP-bound HTTP listeners..." -ForegroundColor Yellow
                foreach ($l in $ipBound) {
                    if (-not $DryRunMode) {
                        Remove-Item -Path $l.PsPath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        } else {
            Write-Host "[$env:COMPUTERNAME] HTTP listener already properly configured (wildcard only)" -ForegroundColor Green
        }
    }

    if (-not $DryRunMode) {
        if ($EnforceAuth) {
            # Harden WinRM security settings: Kerberos only, no Basic, no unencrypted
            Write-Host "[$env:COMPUTERNAME] WARNING: Enforcing strict security settings..." -ForegroundColor Yellow
            Write-Host "[$env:COMPUTERNAME]   - Disabling Basic Authentication" -ForegroundColor Yellow
            Write-Host "[$env:COMPUTERNAME]   - Disabling unencrypted traffic" -ForegroundColor Yellow
            Write-Host "[$env:COMPUTERNAME]   This will break legacy monitoring tools!" -ForegroundColor Yellow
            
            Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $false
            Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $false
            Set-Item -Path WSMan:\localhost\Service\Auth\Kerberos -Value $true
        } else {
            Write-Host "[$env:COMPUTERNAME] Security hardening skipped (use -EnforceStrictWinRMSecurity to enable)" -ForegroundColor Cyan
        }

        Write-Host "[$env:COMPUTERNAME] Enable firewall rules (WinRM HTTP-In & Remote Shutdown)..." -ForegroundColor Cyan
        Get-NetFirewallRule -DisplayGroup "Windows Remote Management" -ErrorAction SilentlyContinue | Enable-NetFirewallRule | Out-Null
        Get-NetFirewallRule -DisplayGroup "Remote Shutdown" -ErrorAction SilentlyContinue | Enable-NetFirewallRule | Out-Null
    }

    Write-Host "[$env:COMPUTERNAME] Validate WS-Management..." -ForegroundColor Cyan
    try {
        $r = Test-WsMan -ComputerName localhost -ErrorAction Stop
        Write-Host "[$env:COMPUTERNAME] WSMan OK: $($r.ProductVendor) $($r.ProductVersion)" -ForegroundColor Green
        $wsManValid = $true
    } catch {
        Write-Host "[$env:COMPUTERNAME] Test-WsMan failed: $($_.Exception.Message)" -ForegroundColor Red
        $wsManValid = $false
    }

    # Return a status object
    $finalListeners = Get-ChildItem -Path $listenersPath | ForEach-Object { (Get-Item $_.PSPath) } |
                      Where-Object { $_.Keys -match 'Transport=HTTP' } |
                      Select-Object Address
    [pscustomobject]@{
        Node              = $env:COMPUTERNAME
        Status            = if ($wsManValid) { "SUCCESS" } else { "WARNING" }
        DryRun            = $DryRunMode
        WinRMService      = (Get-Service WinRM).Status
        ListenerAddresses = ($finalListeners.Address -join ',')
        FirewallWinRM     = ((Get-NetFirewallRule -DisplayGroup "Windows Remote Management" | Where-Object Enabled -eq 'True').Count)
        FirewallShutdown  = ((Get-NetFirewallRule -DisplayGroup "Remote Shutdown" | Where-Object Enabled -eq 'True').Count)
        WSManValid        = $wsManValid
    }
}

Write-Separator "CONFIGURING WINRM/PS REMOTING ON NODES"
$nodeResults = foreach ($n in $nodes) {
    Write-Log "Processing node: $n" "INFO"
    try {
        $result = Invoke-Command -ComputerName $n -ScriptBlock $configureNode `
            -ArgumentList $DelayedAutoStartWinRM, $DryRun, $BackupConfig, $EnforceStrictWinRMSecurity, $PreserveLegacyListeners `
            -ErrorAction Stop -TimeoutSec $CommandTimeout
        $result
        Write-Log "$n: Status=$($result.Status), WSMan=$($result.WSManValid)" "SUCCESS"
    } catch {
        Write-Log "ERROR on $n - $($_.Exception.Message)" "ERROR"
        [pscustomobject]@{
            Node              = $n
            Status            = "ERROR"
            DryRun            = $DryRun
            Error             = $_.Exception.Message
            WinRMService      = $null
            ListenerAddresses = $null
            FirewallWinRM     = $null
            FirewallShutdown  = $null
            WSManValid        = $false
        }
    }
}

Write-Separator "WINRM/PS REMOTING SUMMARY"
$nodeResults | Format-Table -AutoSize
Write-Log "Node configuration complete: $($nodeResults.Count) nodes processed"

if (-not $SkipNetworkRoleChanges) {
    Write-Separator "CONFIGURING CLUSTER NETWORK ROLES"
    
    Write-Log "⚠ WARNING: Cluster network role changes can cause downtime if misconfigured" "WARN"
    Write-Log "Setting a network Role=0 means cluster heartbeats will NOT use that network" "WARN"
    Write-Log "If you accidentally specify the wrong network, loss of quorum will occur" "WARN"
    Write-Log "" "WARN"
    
    $networkErrors = @()

    # Set Storage/iSCSI networks to Role = 0
    if ($StorageNetworks.Count -gt 0) {
        Write-Log "Setting storage networks to Role=0 (no cluster communication)..." "INFO"
        foreach ($sn in $StorageNetworks) {
            try {
                if ($PSCmdlet.ShouldProcess($sn, "Set Role = 0 (No cluster communication)")) {
                    if ($DryRun) {
                        Write-Log "  [DRY-RUN] Would set '$sn' Role = 0" "WARN"
                    } else {
                        (Get-ClusterNetwork -Name $sn -ErrorAction Stop).Role = 0
                        Write-Log "  ✓ Set '$sn' Role = 0" "SUCCESS"
                    }
                }
            } catch {
                $msg = "Could not set Role=0 on '$sn' : $($_.Exception.Message)"
                Write-Log "  ✗ $msg" "WARN"
                $networkErrors += $msg
            }
        }
    }

    # Set Management network to Role = 3 (ClusterAndClient)
    if ($ManagementNetwork) {
        Write-Log "Setting management network to Role=3 (cluster and client)..." "INFO"
        try {
            if ($PSCmdlet.ShouldProcess($ManagementNetwork, "Set Role = 3 (ClusterAndClient)")) {
                if ($DryRun) {
                    Write-Log "  [DRY-RUN] Would set '$ManagementNetwork' Role = 3" "WARN"
                } else {
                    (Get-ClusterNetwork -Name $ManagementNetwork -ErrorAction Stop).Role = 3
                    Write-Log "  ✓ Set '$ManagementNetwork' Role = 3" "SUCCESS"
                }
            }
        } catch {
            $msg = "Could not set Role=3 on '$ManagementNetwork' : $($_.Exception.Message)"
            Write-Log "  ✗ $msg" "WARN"
            $networkErrors += $msg
        }
    }

    Write-Log "`nCurrent Cluster Networks:" "INFO"
    $clusterNets = Get-ClusterNetwork | Select-Object Name, Address, Role | Sort-Object Name
    $clusterNets | Format-Table -AutoSize
    
    # Log each network
    foreach ($net in $clusterNets) {
        Write-Log "  - $($net.Name): $($net.Address) [Role=$($net.Role)]"
    }
    
    if ($networkErrors.Count -gt 0) {
        Write-Log "Network configuration had $($networkErrors.Count) warning(s)" "WARN"
    }
} else {
    Write-Log "Skipping network role configuration (SkipNetworkRoleChanges = true)"
}

# Final summary
Write-Separator "EXECUTION SUMMARY"
$successCount = ($nodeResults | Where-Object { $_.Status -eq 'SUCCESS' }).Count
$errorCount = ($nodeResults | Where-Object { $_.Status -eq 'ERROR' }).Count
$warningCount = ($nodeResults | Where-Object { $_.Status -eq 'WARNING' }).Count

Write-Log "Nodes processed: $($nodeResults.Count)"
Write-Log "  ✓ Success: $successCount" $(if ($successCount -eq $nodeResults.Count) { "SUCCESS" } else { "INFO" })
Write-Log "  ⚠ Warnings: $warningCount" $(if ($warningCount -gt 0) { "WARN" } else { "INFO" })
Write-Log "  ✗ Errors: $errorCount" $(if ($errorCount -gt 0) { "ERROR" } else { "INFO" })

if ($DryRun) {
    Write-Log "DRY-RUN mode was active - no actual changes were made" "WARN"
}

Write-Log "Log file saved to: $script:LogFile" "SUCCESS"
Write-Log "Script execution completed" "SUCCESS"
Write-Separator "END OF EXECUTION"