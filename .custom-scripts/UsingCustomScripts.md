# Using Custom Scripts

# Using .custom-scripts:
1. Clone this repo
2. Checkout the appropriate branch, for example: `dev`
3. Identify the absolute path to the script you care about, for example: `C:\<pathToRepository>\ai-playbook\.custom-scripts\bin\<theBashScript>`
4. Navigate to the directory where you want custom-scripts defined, for example: `%USERPROFILE%\.custom-scripts`
5. Create a file in that custom-script location that has NO extension
6. Ensure that the custom-scripts directory is on your PATH
7. Add the following instructions to that custom script:

```bash
#!/usr/bin/env bash
bash "<absolutePathToBashScript>" "$@"
```