<#
.SYNOPSIS
  Discovery script: Audits all nodes in a Failover Cluster to identify CAU readiness,
  infrastructure alignment, and configuration gaps WITHOUT making any changes.
  Companion to Prepare-ClusterForCAU.ps1 - RUN THIS FIRST before any modifications.

.DESCRIPTION
  This read-only script safely inventories all cluster node configurations:
  - WinRM configuration (service status, listeners, authentication, firewall)
  - Active PSRemoting sessions
  - PowerShell execution policy per node
  - Cluster network roles and usage patterns
  - Group Policy WinRM/Firewall settings (to detect conflicts)
  - Monitoring agents and legacy tool detection (SolarWinds, PRTG, SCOM, etc.)
  
  Output enables informed decision-making before running destructive changes in the 
  preparation script. Generates CSV and JSON reports for analysis and coordination 
  with infrastructure teams.
  
  STATUS: SAFE - No modifications are made to any system. Can be run multiple times
  in production environments without risk.

.PARAMETER ClusterName
  Name of the WSFC cluster. If omitted, script attempts to infer from local node.

.PARAMETER OutputPath
  Path to save CSV/JSON discovery reports. Defaults to script directory/Discovery-Reports-YYYYMMDD-HHMMSS

.PARAMETER CommandTimeout
  Timeout in seconds for remote commands. Default: 300 (5 minutes).

.PARAMETER SkipGPOAnalysis
  Skip checking for Group Policy WinRM/Firewall settings (faster scan if GPO analysis not needed).

.PARAMETER SkipMonitoringDetection
  Skip detection of monitoring agents (faster scan if monitoring detection not needed).

.EXAMPLE
  # Quick discovery of local cluster (basic assessment)
  .\Discover-ClusterCAUReadiness.ps1

  # Full discovery of named cluster with all checks
  .\Discover-ClusterCAUReadiness.ps1 -ClusterName "PROD-Cluster"

  # Save detailed reports to custom location
  .\Discover-ClusterCAUReadiness.ps1 -ClusterName "PROD-Cluster" -OutputPath "C:\Audit\Cluster-CAU"
  
  # Faster scan (skip GPO and monitoring detection)
  .\Discover-ClusterCAUReadiness.ps1 -ClusterName "PROD-Cluster" -SkipGPOAnalysis -SkipMonitoringDetection

.NOTES
  Tested on Windows Server 2019/2022.
  Requires cluster admin/domain user privileges and FailoverClusters module.
  Safe to run multiple times in production.
  
  WORKFLOW:
  1. Run this discovery script
  2. Review exported CSV/JSON reports
  3. Identify deviations and analyze findings
  4. Coordinate with relevant teams (GPO admins, monitoring teams, etc.)
  5. Then run Prepare-ClusterForCAU.ps1 with appropriate parameters
  
  This ensures transparent decision-making and prevents unintended consequences.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ClusterName,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath,

    [Parameter(Mandatory=$false)]
    [int]$CommandTimeout = 300,

    [switch]$SkipGPOAnalysis,
    [switch]$SkipMonitoringDetection
)

function Write-Info([string]$msg)  { Write-Host $msg -ForegroundColor Cyan }
function Write-Warn([string]$msg)  { Write-Host $msg -ForegroundColor Yellow }
function Write-Err ([string]$msg)  { Write-Host $msg -ForegroundColor Red }
function Write-Good([string]$msg)  { Write-Host $msg -ForegroundColor Green }

# Initialize output directory
function Initialize-OutputDirectory {
    param([string]$OutputPath)
    
    if (-not $OutputPath) {
        $scriptDir = Split-Path $PSCommandPath -Parent
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $OutputPath = Join-Path $scriptDir "Discovery-Reports-$timestamp"
    }
    
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    return $OutputPath
}

function Write-Report {
    param([string]$Message, [string]$Level = "INFO", [string]$ReportFile)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Console output
    switch ($Level) {
        "ERROR"   { Write-Err $logEntry }
        "WARN"    { Write-Warn $logEntry }
        "SUCCESS" { Write-Good $logEntry }
        default   { Write-Info $logEntry }
    }
    
    # File output if specified
    if ($ReportFile) {
        Add-Content -Path $ReportFile -Value $logEntry -ErrorAction SilentlyContinue
    }
}

function Write-Separator {
    param([string]$Title, [string]$ReportFile)
    Write-Report ("=" * 80) "INFO" $ReportFile
    if ($Title) { Write-Report ">>> $Title" "INFO" $ReportFile }
    Write-Report ("=" * 80) "INFO" $ReportFile
}

# Test admin privilege
function Test-AdminPrivilege {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Remote discovery script for each node
$discoverNode = {
    param([switch]$SkipGPO, [switch]$SkipMonitoring)
    
    $ErrorActionPreference = 'Continue'
    $nodeInfo = @{}
    $nodeInfo.ComputerName = $env:COMPUTERNAME
    $nodeInfo.Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # === WinRM SERVICE STATUS ===
    try {
        $svc = Get-Service -Name WinRM -ErrorAction Stop
        $nodeInfo.WinRMServiceStatus = $svc.Status.ToString()
        $nodeInfo.WinRMStartupType = $svc.StartupType.ToString()
    } catch {
        $nodeInfo.WinRMServiceStatus = "ERROR: $($_.Exception.Message)"
        $nodeInfo.WinRMStartupType = "UNKNOWN"
    }
    
    # === WinRM LISTENERS ===
    try {
        $listeners = @()
        $listenersPath = 'WSMan:\localhost\Listener'
        $listenerItems = @(Get-ChildItem -Path $listenersPath -ErrorAction SilentlyContinue)
        
        foreach ($l in $listenerItems) {
            $item = Get-Item $l.PSPath -ErrorAction SilentlyContinue
            if ($item) {
                $listeners += [pscustomobject]@{
                    Transport = ($item.Keys | Where-Object { $_ -match 'Transport' })
                    Address   = $item.Address
                    Port      = $item.Port
                    Hostname  = $item.Hostname
                }
            }
        }
        $nodeInfo.WinRMListeners = ($listeners | ConvertTo-Json -Depth 2)
        $nodeInfo.WinRMListenerCount = $listeners.Count
        $nodeInfo.HasWildcardListener = if ($listeners | Where-Object { $_.Address -eq '*' }) { "TRUE" } else { "FALSE" }
        $nodeInfo.HasIPBoundListener = if ($listeners | Where-Object { $_.Address -match '^\d+\.\d+\.\d+\.\d+$' }) { "TRUE" } else { "FALSE" }
    } catch {
        $nodeInfo.WinRMListeners = "ERROR: $($_.Exception.Message)"
        $nodeInfo.WinRMListenerCount = 0
    }
    
    # === WinRM AUTHENTICATION SETTINGS ===
    try {
        $nodeInfo.WinRMAuthBasic = (Get-Item 'WSMan:\localhost\Service\Auth\Basic' -ErrorAction Stop).Value.ToString()
        $nodeInfo.WinRMAuthKerberos = (Get-Item 'WSMan:\localhost\Service\Auth\Kerberos' -ErrorAction Stop).Value.ToString()
        $nodeInfo.WinRMAuthNegotiate = (Get-Item 'WSMan:\localhost\Service\Auth\Negotiate' -ErrorAction Stop).Value.ToString()
        $nodeInfo.WinRMAuthDigest = (Get-Item 'WSMan:\localhost\Service\Auth\Digest' -ErrorAction Stop).Value.ToString()
        $nodeInfo.WinRMAllowUnencrypted = (Get-Item 'WSMan:\localhost\Service\AllowUnencrypted' -ErrorAction Stop).Value.ToString()
    } catch {
        $nodeInfo.WinRMAuthBasic = "ERROR"
        $nodeInfo.WinRMAuthKerberos = "ERROR"
    }
    
    # === FIREWALL RULES ===
    try {
        $fwWinRM = @(Get-NetFirewallRule -DisplayGroup "Windows Remote Management" -ErrorAction SilentlyContinue | Where-Object Enabled -eq 'True').Count
        $fwShutdown = @(Get-NetFirewallRule -DisplayGroup "Remote Shutdown" -ErrorAction SilentlyContinue | Where-Object Enabled -eq 'True').Count
        $nodeInfo.FirewallWinRMEnabled = $fwWinRM
        $nodeInfo.FirewallShutdownEnabled = $fwShutdown
    } catch {
        $nodeInfo.FirewallWinRMEnabled = "ERROR"
        $nodeInfo.FirewallShutdownEnabled = "ERROR"
    }
    
    # === POWERSHELL REMOTING ===
    try {
        $psr = Get-PSSessionConfiguration -ErrorAction SilentlyContinue
        $nodeInfo.PSRemotingEnabled = if ($psr) { "TRUE" } else { "FALSE" }
        $nodeInfo.PSSessionConfigurations = ($psr | Select-Object Name, Enabled | ConvertTo-Json -Depth 1)
    } catch {
        $nodeInfo.PSRemotingEnabled = "ERROR"
    }
    
    # === ACTIVE PS REMOTING SESSIONS ===
    try {
        $activeSessions = @(Get-PSSession -ErrorAction SilentlyContinue | Where-Object Transport -eq 'WSMan')
        $nodeInfo.ActivePSSessionCount = $activeSessions.Count
        $nodeInfo.ActivePSSessions = ($activeSessions | Select-Object ComputerName, State, IdleTimeout | ConvertTo-Json -Depth 1)
    } catch {
        $nodeInfo.ActivePSSessionCount = 0
    }
    
    # === EXECUTION POLICY ===
    try {
        $exPol = Get-ExecutionPolicy
        $nodeInfo.ExecutionPolicy = $exPol.ToString()
    } catch {
        $nodeInfo.ExecutionPolicy = "ERROR"
    }
    
    # === GROUP POLICY (if not skipped) ===
    if (-not $SkipGPO) {
        try {
            $gpResult = gpresult /scope:user /h "$env:TEMP\gpresult-user.html" 2>&1
            $nodeInfo.GPOLastRefresh = "Generated"
            
            # Check for WinRM-related GPO settings via registry
            $gpoWinRM = Get-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\WinRM' -ErrorAction SilentlyContinue
            $nodeInfo.GPOWinRMPoliciesFound = if ($gpoWinRM) { "TRUE" } else { "FALSE" }
            
            $gpoFW = Get-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\WindowsFirewall' -ErrorAction SilentlyContinue
            $nodeInfo.GPOFirewallPoliciesFound = if ($gpoFW) { "TRUE" } else { "FALSE" }
        } catch {
            $nodeInfo.GPOLastRefresh = "ERROR: $($_.Exception.Message)"
        }
    }
    
    # === MONITORING AGENTS (if not skipped) ===
    if (-not $SkipMonitoring) {
        try {
            $agentsFound = @()
            
            # Common monitoring agents
            $agentTests = @{
                "SCOM" = "Get-Service -Name HealthService -ErrorAction SilentlyContinue"
                "Datadog" = "Get-Service -Name 'Datadog Agent' -ErrorAction SilentlyContinue"
                "SolarWinds" = "Get-Process -Name SwisSW* -ErrorAction SilentlyContinue"
                "PRTG" = "Get-Service -Name 'PRTG Agent' -ErrorAction SilentlyContinue"
                "Prometheus" = "Get-Process -Name prometheus* -ErrorAction SilentlyContinue"
                "Telegraf" = "Get-Service -Name Telegraf -ErrorAction SilentlyContinue"
            }
            
            foreach ($agentName in $agentTests.Keys) {
                try {
                    $result = Invoke-Expression $agentTests[$agentName]
                    if ($result) { $agentsFound += $agentName }
                } catch {}
            }
            
            $nodeInfo.MonitoringAgentsDetected = $agentsFound -join ','
        } catch {
            $nodeInfo.MonitoringAgentsDetected = "ERROR"
        }
    }
    
    # === TEST WS-MANAGEMENT ===
    try {
        $wsMan = Test-WsMan -ComputerName localhost -ErrorAction Stop
        $nodeInfo.WSManTest = "SUCCESS - $($wsMan.ProductVendor) $($wsMan.ProductVersion)"
    } catch {
        $nodeInfo.WSManTest = "FAILED - $($_.Exception.Message)"
    }
    
    return $nodeInfo
}

# Main execution
Write-Separator "Cluster CAU Readiness Discovery"
$reportDir = Initialize-OutputDirectory -OutputPath $OutputPath
$masterReportFile = Join-Path $reportDir "Discovery-Report.txt"

Write-Report "Discovery started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO" $masterReportFile
Write-Report "Output directory: $reportDir" "INFO" $masterReportFile
Write-Report "" "INFO" $masterReportFile
Write-Report "This is a READ-ONLY discovery script - no modifications will be made to any system." "INFO" $masterReportFile
Write-Report "" "INFO" $masterReportFile

# Validation
if (-not (Test-AdminPrivilege)) {
    Write-Report "ERROR: This script requires Administrator privileges" "ERROR" $masterReportFile
    exit 1
}
Write-Report "✓ Running with Administrator privileges" "SUCCESS" $masterReportFile

# Load FailoverClusters module
try {
    Import-Module FailoverClusters -ErrorAction Stop
    Write-Report "✓ FailoverClusters module loaded" "SUCCESS" $masterReportFile
} catch {
    Write-Report "ERROR: FailoverClusters module not found" "ERROR" $masterReportFile
    exit 1
}

# Resolve cluster
try {
    $nodes = if ($PSBoundParameters.ContainsKey('ClusterName') -and $ClusterName) {
        Write-Report "Resolving cluster: $ClusterName" "INFO" $masterReportFile
        (Get-ClusterNode -Cluster $ClusterName -ErrorAction Stop).Name
    } else {
        Write-Report "Resolving local cluster" "INFO" $masterReportFile
        (Get-ClusterNode -ErrorAction Stop).Name
    }
    Write-Report "✓ Found $($nodes.Count) cluster nodes: $($nodes -join ', ')" "SUCCESS" $masterReportFile
} catch {
    Write-Report "ERROR: Unable to resolve cluster nodes - $($_.Exception.Message)" "ERROR" $masterReportFile
    exit 1
}

# Discover cluster networks
Write-Separator "CLUSTER NETWORK INVENTORY" $masterReportFile
Write-Report "Phase 1: Discovering cluster network topology and roles" "INFO" $masterReportFile
Write-Report "Purpose: Identify which networks are used for heartbeats, CSV, storage, or management" "INFO" $masterReportFile
try {
    $clusterNets = Get-ClusterNetwork | Select-Object Name, Address, Role, Description
    Write-Report "Found $($clusterNets.Count) cluster networks" "INFO" $masterReportFile
    
    foreach ($net in $clusterNets) {
        $roleDesc = switch ($net.Role) {
            0 { "Do NOT allow cluster communication" }
            1 { "Allow only cluster communication" }
            3 { "Allow cluster and client communication" }
            default { "Unknown ($($net.Role))" }
        }
        Write-Report "  - $($net.Name): $($net.Address) [Role=$($net.Role)] $roleDesc" "INFO" $masterReportFile
    }
    
    $clusterNets | Export-Csv -Path (Join-Path $reportDir "Cluster-Networks.csv") -NoTypeInformation
} catch {
    Write-Report "ERROR querying cluster networks: $($_.Exception.Message)" "ERROR" $masterReportFile
}

# Discover nodes
Write-Separator "NODE DISCOVERY" $masterReportFile
Write-Report "Phase 2: Auditing each node for WinRM, listeners, authentication, and monitoring" "INFO" $masterReportFile
Write-Report "Purpose: Understand current node configuration and identify what needs to change for CAU" "INFO" $masterReportFile
Write-Report "Actions: Non-destructive inventory only - reporting what exists, not modifying" "INFO" $masterReportFile
Write-Report "" "INFO" $masterReportFile
$nodeDiscoveries = @()

foreach ($n in $nodes) {
    Write-Report "Discovering: $n" "INFO" $masterReportFile
    try {
        $discovery = Invoke-Command -ComputerName $n -ScriptBlock $discoverNode `
            -ArgumentList $SkipGPOAnalysis, $SkipMonitoringDetection `
            -ErrorAction Stop -TimeoutSec $CommandTimeout
        
        $nodeDiscoveries += $discovery
        Write-Report "  ✓ Discovery complete" "SUCCESS" $masterReportFile
        
        # Log key findings
        Write-Report "    - WinRM Service: $($discovery.WinRMServiceStatus) (Startup: $($discovery.WinRMStartupType))" "INFO" $masterReportFile
        Write-Report "    - WinRM Listeners: $($discovery.WinRMListenerCount) [Wildcard: $($discovery.HasWildcardListener), IP-bound: $($discovery.HasIPBoundListener)]" "INFO" $masterReportFile
        Write-Report "    - PS Remoting Enabled: $($discovery.PSRemotingEnabled)" "INFO" $masterReportFile
        Write-Report "    - Active Sessions: $($discovery.ActivePSSessionCount)" "INFO" $masterReportFile
        Write-Report "    - WS-Management: $($discovery.WSManTest)" "INFO" $masterReportFile
        
        if ($discovery.MonitoringAgentsDetected) {
            Write-Report "    - Monitoring Agents: $($discovery.MonitoringAgentsDetected)" "WARN" $masterReportFile
        }
        
    } catch {
        Write-Report "  ✗ ERROR: $($_.Exception.Message)" "ERROR" $masterReportFile
    }
}

# Export discovery results
Write-Separator "EXPORTING RESULTS" $masterReportFile
Write-Report "Phase 3: Generating comprehensive reports for analysis" "INFO" $masterReportFile
Write-Report "Formats: CSV (easy comparison), JSON (detailed structure), TXT (human-readable)" "INFO" $masterReportFile
Write-Report "" "INFO" $masterReportFile

if ($nodeDiscoveries.Count -gt 0) {
    # CSV export (flattened)
    $flattened = $nodeDiscoveries | Select-Object @(
        'ComputerName',
        'WinRMServiceStatus',
        'WinRMStartupType',
        'HasWildcardListener',
        'HasIPBoundListener',
        'WinRMAuthBasic',
        'WinRMAuthKerberos',
        'WinRMAllowUnencrypted',
        'PSRemotingEnabled',
        'ActivePSSessionCount',
        'FirewallWinRMEnabled',
        'ExecutionPolicy',
        'GPOWinRMPoliciesFound',
        'MonitoringAgentsDetected',
        'WSManTest'
    )
    
    $flattened | Export-Csv -Path (Join-Path $reportDir "Node-Discovery-Summary.csv") -NoTypeInformation
    Write-Report "✓ Summary exported to Node-Discovery-Summary.csv" "SUCCESS" $masterReportFile
    
    # JSON export (full details)
    $nodeDiscoveries | ConvertTo-Json -Depth 10 | Out-File -Path (Join-Path $reportDir "Node-Discovery-Full.json")
    Write-Report "✓ Full details exported to Node-Discovery-Full.json" "SUCCESS" $masterReportFile
}

# Summary to console and file
Write-Separator "DISCOVERY SUMMARY" $masterReportFile

$summary = @{
    "Total Nodes" = $nodeDiscoveries.Count
    "Nodes with WinRM Running" = ($nodeDiscoveries | Where-Object WinRMServiceStatus -eq 'Running').Count
    "Nodes with PSRemoting Enabled" = ($nodeDiscoveries | Where-Object PSRemotingEnabled -eq 'TRUE').Count
    "Nodes with Wildcard Listener" = ($nodeDiscoveries | Where-Object HasWildcardListener -eq 'TRUE').Count
    "Nodes with IP-Bound Listeners" = ($nodeDiscoveries | Where-Object HasIPBoundListener -eq 'TRUE').Count
    "Nodes with GPO WinRM Policies" = ($nodeDiscoveries | Where-Object GPOWinRMPoliciesFound -eq 'TRUE').Count
    "Nodes with Monitoring Agents" = ($nodeDiscoveries | Where-Object { $_.MonitoringAgentsDetected -and $_.MonitoringAgentsDetected -ne '' }).Count
}

foreach ($key in $summary.Keys) {
    Write-Report "$key`: $($summary[$key])" "INFO" $masterReportFile
}

# Recommendations
Write-Separator "RECOMMENDATIONS" $masterReportFile
Write-Report "Phase 4: Analysis and guidance for CAU preparation" "INFO" $masterReportFile
Write-Report "" "INFO" $masterReportFile

$hasIpBound = $nodeDiscoveries | Where-Object HasIPBoundListener -eq 'TRUE'
if ($hasIpBound.Count -gt 0) {
    Write-Report "⚠ WARNING: $($hasIpBound.Count) node(s) have IP-bound WinRM listeners" "WARN" $masterReportFile
    Write-Report "  - Review if this is intentional for security policy" "WARN" $masterReportFile
    Write-Report "  - Prepare-ClusterForCAU.ps1 will replace these with wildcard listeners" "WARN" $masterReportFile
}

$noWildcard = $nodeDiscoveries | Where-Object HasWildcardListener -eq 'FALSE'
if ($noWildcard.Count -gt 0) {
    Write-Report "ℹ INFO: $($noWildcard.Count) node(s) lack wildcard WinRM listeners (CAU requirement)" "INFO" $masterReportFile
}

$withMonitoring = $nodeDiscoveries | Where-Object { $_.MonitoringAgentsDetected -and $_.MonitoringAgentsDetected -ne '' }
if ($withMonitoring.Count -gt 0) {
    Write-Report "⚠ WARNING: Monitoring agents detected on $($withMonitoring.Count) node(s)" "WARN" $masterReportFile
    Write-Report "  - Before enabling -EnforceStrictWinRMSecurity, verify monitoring solution compatibility" "WARN" $masterReportFile
    Write-Report "  - Legacy monitoring tools may require Basic Auth or unencrypted HTTP access" "WARN" $masterReportFile
    Write-Report "  - Coordinate with monitoring team on preferred authentication method" "WARN" $masterReportFile
}

$withGPO = $nodeDiscoveries | Where-Object GPOWinRMPoliciesFound -eq 'TRUE'
if ($withGPO.Count -gt 0) {
    Write-Report "ℹ INFO: Group Policy WinRM policies found on $($withGPO.Count) node(s)" "INFO" $masterReportFile
    Write-Report "  - Local WinRM changes may be overwritten at next GPO refresh cycle" "INFO" $masterReportFile
    Write-Report "  - Coordinate with GPO/domain administrators to embed changes in policy instead" "INFO" $masterReportFile
}

Write-Report "" "INFO" $masterReportFile
Write-Report "NEXT STEPS:" "INFO" $masterReportFile
Write-Report "1. Review exported CSVs and JSON files in: $reportDir" "INFO" $masterReportFile
Write-Report "2. Identify any deviations from expected configuration" "INFO" $masterReportFile
Write-Report "3. Coordinate with infrastructure teams:" "INFO" $masterReportFile
Write-Report "   - GPO/Domain administrators (if Group Policy WinRM policies are present)" "INFO" $masterReportFile
Write-Report "   - Monitoring/SOC team (for any detected monitoring agents)" "INFO" $masterReportFile
Write-Report "4. When ready, run: Prepare-ClusterForCAU.ps1 -ClusterName '$ClusterName' -DryRun" "INFO" $masterReportFile

Write-Report "" "INFO" $masterReportFile
Write-Report "Discovery completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "SUCCESS" $masterReportFile

Write-Good "`nDiscovery complete. Reports saved to: $reportDir"
Write-Info "Review the exported files to assess CAU readiness before proceeding."
