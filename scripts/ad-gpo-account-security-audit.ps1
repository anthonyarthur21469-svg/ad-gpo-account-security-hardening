<#
.SYNOPSIS
    Active Directory Group Policy & Account Security Hardening
    Environment: DC01, arthurlab.test (Windows Server 2025, Hyper-V)

.DESCRIPTION
    Consolidated PowerShell commands from a hands-on AD security project covering:
      1. Domain password/lockout policy baseline and hardening
      2. Lockout enforcement and account recovery testing
      3. OU-scoped Group Policy creation
      4. Group Policy Modeling / RSoP positive and negative scope validation
      5. GPO troubleshooting (Security Filtering misconfiguration + remediation)
      6. Security policy auditing and HTML reporting

    Run interactively, section by section, on a domain controller with the
    ActiveDirectory and GroupPolicy PowerShell modules available. Not intended
    to be run start-to-finish unattended -- several steps are destructive
    tests (deliberate lockouts, deliberate misconfiguration) meant to be
    observed and verified at each stage.

.NOTES
    Author: Anthony Arthur
    Full write-up with screenshots: ../README.md
#>

# ---------------------------------------------------------------------------
# 1. Baseline Assessment
# ---------------------------------------------------------------------------

# Step 2 - Audit the default domain password policy
Get-ADDefaultDomainPasswordPolicy

# ---------------------------------------------------------------------------
# 2. Password and Account Lockout Hardening
# ---------------------------------------------------------------------------

# Step 4/5 - Minimum password length was raised to 14 characters via
# Group Policy Management Editor (Default Domain Policy). Verify the change:
Get-ADDefaultDomainPasswordPolicy | Select-Object `
    MinPasswordLength, ComplexityEnabled, PasswordHistoryCount, MaxPasswordAge

# Step 7/8 - Lockout threshold (5 attempts), duration (10 min), and
# observation window (10 min) were configured via Group Policy Management
# Editor. Built-in Administrator lockout was disabled. Verify the change:
Get-ADDefaultDomainPasswordPolicy | Select-Object `
    LockoutThreshold, LockoutDuration, LockoutObservationWindow

# ---------------------------------------------------------------------------
# 3. Lockout Enforcement and Recovery Test
# ---------------------------------------------------------------------------

# Step 9 - Establish baseline for the test account before testing
Get-ADUser sjohnson -Properties Enabled, LockedOut | Select-Object Name, Enabled, LockedOut

# Step 10 - Simulate repeated failed authentication (run in a separate
# cmd/PowerShell window; enter an incorrect password 5+ times)
runas /user:ARTHURLAB\sjohnson cmd

# Step 11 - Confirm the account locked out as expected
Get-ADUser sjohnson -Properties LockedOut | Select-Object Name, LockedOut

# Step 12 - Recover the account and verify
Unlock-ADAccount -Identity sjohnson
Get-ADUser sjohnson -Properties LockedOut | Select-Object Name, LockedOut

# ---------------------------------------------------------------------------
# 4/5/6. OU-Scoped GPO, RSoP Modeling, Negative Scope Test, Troubleshooting
# ---------------------------------------------------------------------------
# Steps 13-29 were performed in Group Policy Management Console / Group
# Policy Management Editor (GUI): creating and linking "HR User Security
# Policy" to the Human Resources OU, enabling "Prohibit access to Control
# Panel and PC settings," running Group Policy Modeling for Sarah Johnson
# (positive scope) and David Wilson (negative scope), then deliberately
# breaking and restoring Security Filtering to practice diagnosis. See the
# README for the full walkthrough and screenshots. Supporting verification
# commands used along the way:

# Step 17 - Confirm a user's OU placement
Get-ADUser sjohnson | Select-Object Name, DistinguishedName

# Step 22 - Verify a newly created test identity
Get-ADUser dwilson -Properties Department, Title, Enabled | Select-Object `
    Name, SamAccountName, Department, Title, Enabled, DistinguishedName

# ---------------------------------------------------------------------------
# 7. Security Policy Auditing and Reporting
# ---------------------------------------------------------------------------

# Step 30 - Inventory all domain GPOs
Get-GPO -All | Select-Object DisplayName, GpoStatus, CreationTime, ModificationTime

# Step 31 - Generate an HTML report for a specific GPO
Get-GPOReport -Name "HR User Security Policy" -ReportType Html -Path "C:\HR-GPO-Report.html"
Get-Item "C:\HR-GPO-Report.html" | Select-Object Name, Length, LastWriteTime

# Step 32 - Final domain security audit (closing evidence)
Get-ADDefaultDomainPasswordPolicy | Select-Object `
    MinPasswordLength, ComplexityEnabled, PasswordHistoryCount, MaxPasswordAge, `
    LockoutThreshold, LockoutDuration, LockoutObservationWindow
