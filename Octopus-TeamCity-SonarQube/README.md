# ![logo][] PowerShell

## The purpose of this ARM templates and PowerShell scripts are to install and configure Octopus, TeamCity and Sonarqube

[logo]: https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/ps_black_64.svg?sanitize=true

## To start deployment we need to execute PowerShell script 'deploy-menu.ps1'

Execute script:

```sh
PS C:\Octopus-TeamCity-SonarQube> .\deploy-menu.ps1
```

From the following output, we can see the menu. We need just to choose the number of what we need then, input number and press `Enter` button. Number `4` means all in one. If we enter `Q` script will exit silently.

```sh
        Execute Volvo DCOM tasks

                Main Menu

Running as: jamal.shahverdiyev

                        1 - Installation and configuration of Octopus
                        2 - Installation and configuration of TeamCity
                        3 - Installation and configuration of SonarQube
                        4 - Installation and configuration of all Environments.
                        5 - Installation and configuration of all Environments from one ARM template.
                        Q --- Quit And Exit

NOTICE:
An extra warning.

                Enter Menu Option Number:
```

When you will input some number from the menu, it will call the main script for installation/configuration from their folders. But, if you want to understand how it is working in details, please read `Readme.md` files inside of this folders.