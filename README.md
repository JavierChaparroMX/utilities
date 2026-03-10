# Utilities Repository

A curated collection of useful scripts, tools, and snippets for various system administration, automation, and development tasks.

## Overview

This repository is a growing collection of **production-ready utilities** that solve common operational and administrative challenges. Each tool is self-contained, well-documented, and includes error handling for reliable execution.

**What you'll find:**
- 🔧 System administration tools
- 🐚 PowerShell/Bash scripts
- 📊 Monitoring and diagnostics utilities
- 🔄 Automation & infrastructure management
- 🎬 Media processing and optimization
- 📚 Code snippets and reusable utilities

## Quick Start

```powershell
# View help for any PowerShell script
Get-Help .\ScriptName.ps1 -Full
Get-Help .\ScriptName.ps1 -Examples

# List all available utilities
Get-ChildItem -Recurse -Filter *.ps1 | Select-Object Directory, Name
```

## Folder Organization

Each folder contains tools for a specific domain. Browse the folder structure or start with a domain:

| Folder | Contents |
|--------|----------|
| **Failover Cluster/** | Windows Failover Cluster administration and CAU utilities |
| **Media-optimization-for-websites/** | Web media processing and optimization tools |
| **Root level** | General system administration utilities |

**Each folder has its own `README.md` with detailed information** — start there for domain-specific docs!

## Available Utilities

### Quick Reference

**Root Level:**
- `Cluster RAM Report.ps1` — Cluster memory utilization reporting
- `FindOrphanedVMs.ps1` — Detect unmanaged VMs in Hyper-V

**Failover Cluster/**
- See [Failover Cluster/README.md](Failover%20Cluster/README.md)

**Media-optimization-for-websites/**
- See [Media-optimization-for-websites/README.md](Media-optimization-for-websites/README.md)

## Key Features

Most scripts in this repo include:

✅ **Error Handling** — Comprehensive validation and recovery  
✅ **Logging** — Timestamped audit trails (usually in `Logs/` subfolder)  
✅ **Help Documentation** — Full comment-based help built-in  
✅ **Dry-Run Modes** — Preview changes safely (where applicable)  
✅ **Remote Support** — Many tools support remote execution  

## General Guidelines

### Before Running Any Script

1. ✅ Read the help documentation
   ```powershell
   Get-Help .\ScriptName.ps1 -Full
   ```

2. ✅ Understand the requirements and prerequisites

3. ✅ Test in a non-production environment first

4. ✅ Use `-DryRun` or `-WhatIf` if available (safe preview mode)

5. ✅ Check you have appropriate permissions

### Script Conventions

- Scripts follow PowerShell best practices
- Parameter names are descriptive and consistent
- Error messages are informative and guide remediation
- Logs are always timestamped for auditability
- Complex operations support `-Verbose` for troubleshooting

## Directory Structure

```
utilities/
├── README.md                              ← You are here
├── LICENSE
├── Cluster RAM Report.ps1                 (general utility)
├── FindOrphanedVMs.ps1                    (general utility)
│
├── Failover Cluster/                      (cluster-specific tools)
│   ├── README.md
│   └── CAU/
│       ├── Prepare-ClusterForCAU.ps1
│       ├── Configure UPN locally
│       └── Configure-update-proxy-node
│
└── Media-optimization-for-websites/       (media processing)
    ├── README.md
    ├── DOCUMENTATION.md
    ├── SETUP.md
    ├── package.json
    └── [additional tools]
```

## Adding New Utilities

Have a useful script or snippet to add?

1. **Place it in the appropriate folder** (or create one if a new category)
2. **Add comprehensive help** — Use comment-based help blocks
3. **Include error handling** — Don't let scripts fail silently
4. **Add a `README.md` if creating a new folder category**
5. **Update this main README if it's a major addition**
6. **Test thoroughly** before committing

Example help block:
```powershell
<#
.SYNOPSIS
  Brief one-liner description

.DESCRIPTION
  Longer description of what it does

.PARAMETER ParameterName
  What this parameter does

.EXAMPLE
  How to use it

.NOTES
  Requirements, author, version, etc.
#>
```

## Troubleshooting Tips

**Script help isn't showing:**
```powershell
# Make sure help is up to date
Update-Help
Get-Help .\ScriptName.ps1 -Full
```

**Permission denied errors:**
- Check you have admin/appropriate privileges
- Review the script's requirements section

**Remote execution failures:**
- Verify WinRM/remote invocation is enabled
- Check firewall rules
- Consult the script's troubleshooting section

**Review logs:**
- Timestamped logs usually in a `Logs/` subdirectory
- Errors guide remediation steps

## Contributing & Feedback

Found a bug? Have a script to share? Improvements welcome!

- Test thoroughly in lab first
- Include documentation and help
- Add error handling for edge cases
- Keep scripts focused and reusable

## Resources & Links

- **PowerShell Help:** `Get-Help about_*` (built-in help topics)
- **Microsoft Docs:** [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- **Script Help:** `Get-Help .\ScriptName.ps1 -Full` (any script in this repo)

## License

See [LICENSE](LICENSE) for details.

## Author

**Javier Chaparro**  
Repository: https://github.com/JavierChaparroMX/utilities

---

**Last Updated:** March 2026  
**Repository Purpose:** Collection of useful system administration and automation scripts
