# Path to the CSV file and log files
$csvPath = "C:\path\to\users.csv"
$logFilePath = "C:\path\to\user_update_log.txt"
$errorLogFilePath = "C:\path\to\user_update_error_log.txt"

# Define the attribute mappings
$UserPrincipalNameAttr = "UserPrincipalName"
$MobilePhoneAttr = "MobilePhone"
$BusinessPhonesAttr = "BusinessPhones"

# Function to log messages
function Write-Log {
    param (
        [string]$message,
        [string]$type = "INFO",
        [string]$logType = "general"  # 'general' or 'error'
    )
    
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$type] $message"
    
    if ($logType -eq "general") {
        Add-Content -Path $logFilePath -Value $logMessage
    } elseif ($logType -eq "error") {
        Add-Content -Path $errorLogFilePath -Value $logMessage
    }

    Write-Host $message
}

# Function to validate CSV structure
function Validate-Csv {
    param (
        [array]$csv
    )
    
    if ($csv.Count -eq 0) {
        Write-Log "The CSV file is empty or could not be loaded." "ERROR" "error"
        return $false
    }

    # Check for required columns
    $requiredColumns = @($UserPrincipalNameAttr, $MobilePhoneAttr, $BusinessPhonesAttr)
    foreach ($column in $requiredColumns) {
        if (-not $csv[0].PSObject.Properties.Match($column)) {
            Write-Log "Missing required column: $column" "ERROR" "error"
            return $false
        }
    }
    
    return $true
}

# Check if an EntraID session is active, if not, prompt for login
try {
    Get-MgContext -ErrorAction Stop
    Write-Log "EntraID session is active." "INFO"
} catch {
    Write-Log "No active EntraID session found. Initiating login..." "INFO"
    Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All"
}

# Import users from CSV and validate data
$users = Import-Csv -Path $csvPath
if ($users -eq $null -or $users.Count -eq 0) {
    Write-Log "Failed to load CSV or CSV is empty." "ERROR" "error"
    exit
}

if (-not (Validate-Csv -csv $users)) {
    Write-Log "Invalid CSV structure. Exiting script." "ERROR"
    exit
}

# Initialize counters
$successfulUpdates = 0
$failedUpdates = 0
$retryCount = 3  # Number of retry attempts in case of transient failures

foreach ($user in $users) {
    if (-not $user.$UserPrincipalNameAttr -or -not $user.$MobilePhoneAttr -or -not $user.$BusinessPhonesAttr) {
        Write-Log "User data missing for $($user.$UserPrincipalNameAttr). Skipping this user." "WARNING" "error"
        $failedUpdates++
        continue
    }

    Write-Log "Processing user: $($user.$UserPrincipalNameAttr)"

    # Retry logic for updating user properties
    $attempt = 0
    $success = $false
    while ($attempt -lt $retryCount -and -not $success) {
        try {
            Update-MgUser -UserId $user.$UserPrincipalNameAttr -MobilePhone $user.$MobilePhoneAttr -BusinessPhones @($user.$BusinessPhonesAttr)
            Write-Log "Successfully updated user properties for $($user.$UserPrincipalNameAttr)" "SUCCESS"
            $successfulUpdates++
            $success = $true
        } catch {
            $attempt++
            if ($attempt -lt $retryCount) {
                Write-Log "Failed to update properties for $($user.$UserPrincipalNameAttr). Attempt $attempt of $retryCount. Retrying..." "WARNING" "error"
                Start-Sleep -Seconds (5 * $attempt)  # Exponential backoff
            } else {
                Write-Log "Failed to update properties for $($user.$UserPrincipalNameAttr) after $retryCount attempts. Error: $_" "ERROR" "error"
                $failedUpdates++
            }
        }
    }

}

# Final report
Write-Log "========================"
Write-Log "Script execution summary:"
Write-Log "Total successful updates: $successfulUpdates" "SUCCESS"
Write-Log "Total failed updates: $failedUpdates" "ERROR"
Write-Log "========================"

# Output summary to console as well
Write-Host "========================"
Write-Host "Script execution summary:" -ForegroundColor Cyan
Write-Host "Total successful updates: $successfulUpdates" -ForegroundColor Green
Write-Host "Total failed updates: $failedUpdates" -ForegroundColor Red
Write-Host "========================"

# Provide a summary of failed attempts from the error log for post-analysis
if ($failedUpdates -gt 0) {
    Write-Host "Detailed error log available at: $errorLogFilePath" -ForegroundColor Yellow
}
