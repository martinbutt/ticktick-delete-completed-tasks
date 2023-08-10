# Delete Completed Tasks - Ticktick

This `bash` script allows you to delete your completed tasks from Ticktick.

## Preparation
This script uses the undocumented Ticktick v2 API. This authenticates using a cookie from a web session. Log into ticktick.com/webapp, open the broswer DevTools and select the 'Network' tab. Now use the web interface to add a task. Back in the DevTools you will see an entry under the 'Network' tab for a POST request to 'task'. Under the 'request headers' you will see the `t` cookie. Copy just the value of this (without the 't=' at the begining or the semicolon at the end). Pass this value as the `-c` parameter to the script. 

## Usage
```
Usage: delete-completed-tasks.sh -c <cookie_value> [-b <backup_file>] [-v] [-h]

Options:
  -c <cookie_value>  Value of the 't' cookie from an authenticated web session
  -b <backup_file>   Location of a backup file to append deleted tasks to (optional)
  -v                 Show verbose output (optional)
  -h                 Shows this message
```

### Backing up your tasks
Before you begin, it is recommended to backup your tasks. https://ticktick.com/webapp/#settings/backup

The script can backup the tasks it is deleting to a local file using the `-b` parameter.

### Estimated run time

### Sync conflicts
It is recommended to not use Ticktick while the script is running, as this may result in sync conflicts and data loss.

# Notes
Copy the curl from this page https://api.ticktick.com/api/v2/project/all/completedInAll/

The script take a long time - refresh this page to look for changes to make sure it is running https://api.ticktick.com/api/v2/project/all/completedInAll/
