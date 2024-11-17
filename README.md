# PowerShell Utility Scripts

Welcome to the **PowerShell Utility Scripts** repository! This collection includes a variety of useful PowerShell scripts designed to enhance productivity, automate tasks, and optimize system performance. Each script serves a unique purpose, from system cleanup to managing OneDrive storage.

---

## 📜 Scripts Included

### 1. **Scheduled System Cleanup**
**Description**: Cleans up temporary files, empties the recycle bin, and clears browser caches for major browsers (Edge, Chrome, Firefox).  
**Usage**: Keep your system clean and optimized with a simple execution or schedule.

---

### 2. **Automated Backup of Important Folders**
**Description**: Copies files from predefined folders (e.g., Documents) to a specified destination (external drive or cloud storage) while preserving folder structure.  
**Usage**: Ideal for automating regular backups and protecting critical data.

---

### 3. **Manage Startup Apps**
**Description**: Lists and allows the removal of startup applications from the registry and startup folder.  
**Usage**: Simplify your boot process and optimize system performance by managing unnecessary startup programs.

---

### 4. **Automated Shutdown or Sleep Mode**
**Description**: Automatically shuts down, restarts, or puts the system into sleep mode after inactivity or at a scheduled time.  
**Usage**: Save power and secure your workstation during downtime.

---

### 5. **System Health Check**
**Description**: Monitors and reports on CPU, RAM, and disk usage, providing a summary of system performance.  
**Usage**: Use it to keep track of system resource usage or identify performance bottlenecks.

---

### 6. **Empty Clipboard History**
**Description**: Clears the current clipboard content and removes clipboard history for added security.  
**Usage**: Protect sensitive data by ensuring clipboard contents are not stored locally.

---

### 7. **Auto-Lock Screen After Inactivity**
**Description**: Locks the screen after a period of inactivity or at a specified scheduled time.  
**Usage**: Ideal for enhancing security in shared or unattended environments.

---

### 8. **Remove Local Version from OneDrive**
**Description**: Removes locally synced OneDrive files, keeping them stored only in the cloud.  
**Usage**: Free up disk space while keeping your files accessible online.

---

### 9. **Disk Usage Analyzer**
**Description**: Scans specified directories and generates a report of folder sizes, sorted by size.  
**Usage**: Quickly identify space-hogging folders to manage disk space effectively.

---

### 10. **Network Speed Test Utility**
**Description**: Tests network upload and download speeds using a public API and logs results for future comparison.  
**Usage**: Measure and track your network performance over time.

---

### 11. **Windows Services Manager**
**Description**: Lists running, stopped, or disabled services and allows users to start, stop, or restart selected services interactively.  
**Usage**: Manage critical Windows services efficiently.

---

## 🚀 How to Use These Scripts

### Running the Scripts
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/PowerShell-Utility-Scripts.git
   cd PowerShellUtilityScripts
   ```
2. Execute the desired script:
   ```powershell
   ./ScriptName.ps1
   ```

---

### Scheduling Scripts with Task Scheduler
You can automate the execution of these scripts using Windows Task Scheduler:

1. **Open Task Scheduler**:
   - Press `Win + R`, type `taskschd.msc`, and press Enter.

2. **Create a New Task**:
   - Click on `Create Task` in the right-hand menu.

3. **Configure General Settings**:
   - Provide a name for the task.
   - Select `Run whether user is logged on or not`.
   - Check `Run with highest privileges`.

4. **Set the Trigger**:
   - Add a new trigger (e.g., daily or at a specific time).

5. **Set the Action**:
   - Choose `Start a Program` and set:
     - **Program/script**: `powershell.exe`
     - **Add arguments**: `-ExecutionPolicy Bypass -File "C:\Path\To\ScriptName.ps1"`

6. **Save the Task**:
   - Click OK, and provide your credentials if prompted.

The script will now run automatically based on the schedule.

---

## 🤝 Contributing

Contributions are welcome! If you have ideas for new scripts, enhancements, or bug fixes, feel free to:

1. Fork this repository.
2. Create a new branch for your changes.
3. Submit a pull request with a detailed explanation.

### Suggestions or Issues?
Open an [issue](https://github.com/kasuken/PowerShell-Utility-Scripts/issues) to report bugs or suggest new features.

---

## 📝 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## ⭐ Acknowledgments

Thank you for using these PowerShell scripts! If you find this repository helpful, please give it a star 🌟 and share it with others.

---