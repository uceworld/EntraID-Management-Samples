# Entra ID Bulk User Phone Update Script

## Overview

This PowerShell script is designed to **bulk update user phone attributes** (Mobile Phone and Business Phone) in **Microsoft Entra ID (formerly Azure AD)** using data from a CSV file. It also provides **robust logging**, **validation**, and **retry logic** to ensure reliable execution and traceability.

---

## Features

- Bulk updates `MobilePhone` and `BusinessPhones` attributes via Microsoft Graph.
- Validates CSV structure before processing.
- Implements retry mechanism with exponential backoff on transient failures.
- Logs all operations to general and error log files.
- Summarizes results with a success/failure report at the end.

---

## Prerequisites

Before using the script, ensure:

- PowerShell 7 or later is installed.
- Microsoft Graph PowerShell SDK is installed (`Microsoft.Graph` module).
- You have the required Microsoft Graph **permissions**:
  - `User.ReadWrite.All`
  - `Group.ReadWrite.All`
- You are authenticated to Microsoft Graph (`Connect-MgGraph`).

---

## Installation

1. **Clone or download this repository** to your local machine.
2. Install the Microsoft Graph module if not already installed:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

## How to Use
1. Download the PowerShell file:
   ```
   BulkUpdate-EntraUserPhones.ps1
   ```
2. Prepare Your CSV File
   Use the sample CSV file (```users.csv```) in the repository to format your data.

3. On the first section of the script, replace ```C:\path\to\``` with the actual path to your users csv file.
   For ```user_update_log.txt``` and ```user_update_error_log.txt```, choose a preferred path to replace their               ```C:\path\to\```, your preferred will determine where the logFile and erorrLogFile would be created.
   ```powershell
   # Path to the CSV file and log files
   $csvPath = "C:\path\to\users.csv"
   $logFilePath = "C:\path\to\user_update_log.txt"
   $errorLogFilePath = "C:\path\to\user_update_error_log.txt"
   ```

5. Run the script:
   ```powershell
   .\BulkUpdate-EntraUserPhones.ps1
   ```
6. Review the Logs:
   After execution, logs will be saved to ```user_update_log.txt``` and ```user_update_error_log.txt``` in your specified directory.


## Example CSV File
Prepare your CSV file (e.g., `users.csv`) with the following headers:

| UserPrincipalName | MobilePhone | BusinessPhones |
|-------------------|-------------|---------------------|
| user1@example.com | +1234567890 | +1987654321;ext=101 |
| user2@example.com | +1234567891 | +1987654322;ext=102 |


## Usage
When executed, the script will:

- Connect to Microsoft Graph (if not already connected)

- Validate the CSV

- Attempt to update users' phone numbers

- Retry failed attempts up to 3 times

- Log all operations and errors

- Output a final summary to the console and log files

## Output
- ```user_update_log.txt``` – General activity log

- ```user_update_error_log.txt``` – Only failed updates and error messages

- Console summary of successful vs. failed updates

## Troubleshooting
- Script fails with permission errors: Ensure your account has the necessary Graph API permissions and is correctly authenticated

- Empty or invalid CSV: Check that all required columns (UserPrincipalName, MobilePhone, BusinessPhones) exist

- Failed updates: Check the error log file for detailed error messages per user

## Contributions
Contributions are welcome! Please see the [Contributing Guidelines](https://github.com/uceworld/EntraID-Management-Samples/blob/main/CONTRIBUTING.md) for more information.

## License
This project is licensed under the MIT License. See the [LICENSE](https://github.com/uceworld/EntraID-Management-Samples/blob/main/LICENSE) file for details.
