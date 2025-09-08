# ⚡ PowerShell Utility Scripts

<p align="center">
  <a href="https://learn.microsoft.com/powershell/">
    <img src="https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg?logo=powershell" alt="PowerShell">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">
  </a>
  <a href="https://github.com/kasuken/PowerShell-Utility-Scripts/stargazers">
    <img src="https://img.shields.io/github/stars/kasuken/PowerShell-Utility-Scripts?style=social" alt="GitHub stars">
  </a>
</p>


A curated collection of **PowerShell scripts** to boost productivity, automate repetitive tasks, and optimize system performance.
From cleaning up your PC to generating system reports — this repo has you covered.

<p align="center">
   <img width="800" alt="PowerShell Utility Scripts" src="https://github.com/user-attachments/assets/e9fb2a5a-886d-4924-aea8-ef29f3768699" />
</p>

---

## 📜 Scripts Overview

| #  | Script                                    | Description                                                                        | Usage                                              |
| -- | ----------------------------------------- | ---------------------------------------------------------------------------------- | -------------------------------------------------- |
| 1  | **Scheduled System Cleanup**              | Cleans up temporary files, recycle bin, and browser caches.                        | Keep your system clean and optimized.              |
| 2  | **Automated Backup of Important Folders** | Copies predefined folders (e.g., Documents) to external/cloud destinations.        | Automate backups to protect critical data.         |
| 3  | **Manage Startup Apps**                   | Lists and removes startup applications from registry & startup folders.            | Optimize boot time by disabling unnecessary apps.  |
| 4  | **Automated Shutdown or Sleep Mode**      | Shuts down, restarts, or sleeps the system after inactivity or at scheduled times. | Save energy and secure your system.                |
| 5  | **System Health Check**                   | Monitors CPU, RAM, and disk usage with a performance report.                       | Identify bottlenecks and monitor resources.        |
| 6  | **Empty Clipboard History**               | Clears current clipboard contents and history.                                     | Protect sensitive data.                            |
| 7  | **Auto-Lock Screen After Inactivity**     | Locks the screen after inactivity or at a scheduled time.                          | Enhance security on shared systems.                |
| 8  | **Remove Local Version from OneDrive**    | Removes synced OneDrive files, keeping them only online.                           | Free up disk space without losing files.           |
| 9  | **Disk Usage Analyzer**                   | Scans directories and reports folder sizes.                                        | Find space-hogging folders easily.                 |
| 10 | **Network Speed Test Utility**            | Tests and logs upload/download speeds via API.                                     | Track network performance over time.               |
| 11 | **Windows Services Manager**              | Lists services and allows interactive start/stop/restart.                          | Manage Windows services efficiently.               |
| 12 | **Clear Microsoft Teams Cache**           | Deletes Teams cache folders.                                                       | Fix Teams issues (admin rights required).          |
| 13 | **Large Files Finder**                    | Finds large files with filters and optional CSV export.                            | Free up space by locating big files.               |
| 14 | **Windows Update Checker & Installer**    | Checks/downloads/installs Windows Updates (with reboot option).                    | Keep Windows secure and up to date.                |
| 15 | **Wi-Fi Password Viewer**                 | Retrieves stored Wi-Fi SSIDs and passwords.                                        | Recover or document Wi-Fi credentials.             |
| 16 | **System Information Report Generator**   | Creates detailed system reports in Markdown.                                       | Use for audits, troubleshooting, or documentation. |

---

## 🚀 Getting Started

### 🔹 Run a Script

```powershell
# Clone this repository
git clone https://github.com/kasuken/PowerShell-Utility-Scripts.git
cd PowerShell-Utility-Scripts

# Execute the desired script
./ScriptName.ps1
```

---

### ⏰ Automate with Task Scheduler

You can schedule scripts to run automatically with **Task Scheduler**:

1. Press `Win + R`, type `taskschd.msc`, and press Enter.
2. Select **Create Task**.
3. In **General**:

   * Name the task.
   * Select **Run whether user is logged on or not**.
   * Check **Run with highest privileges**.
4. In **Triggers**:

   * Add a new trigger (e.g., Daily at 9 AM).
5. In **Actions**:

   * Program/script: `powershell.exe`
   * Arguments:

     ```powershell
     -ExecutionPolicy Bypass -File "C:\Path\To\ScriptName.ps1"
     ```
6. Save, provide credentials, and you’re done! ✅

---

## 🤝 Contributing

Contributions are always welcome! 💡

* Fork this repo
* Create a feature branch
* Commit your changes
* Submit a Pull Request

Got an idea for a new script? Open an [issue](https://github.com/kasuken/PowerShell-Utility-Scripts/issues).

---

## 📝 License

This project is licensed under the **MIT License**.
See the [LICENSE](LICENSE) file for more details.

---

## ⭐ Acknowledgments

Thanks for checking out **PowerShell Utility Scripts**!
If you find this project helpful, please give it a ⭐ and share it with others.

---

<p align="center">
  <img src="https://img.shields.io/badge/Made%20with%20💙%20in-PowerShell-5391FE?logo=powershell&logoColor=white&style=for-the-badge" alt="Made with 💙 in PowerShell">
</p>
