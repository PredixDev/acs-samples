@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
SET CURRENT_DIR=%cd%
ECHO CURRENT_DIR=!CURRENT_DIR!
SET FILE_NAME=%0
SET BRANCH=master
SET SKIP_SETUP=FALSE
SET CF_URL=

:GETOPTS
    IF /I [%1] == [--skip-setup] SET SKIP_SETUP=TRUE
    REM Here we call SHIFT twice to remove the switch and value since these are not needed by the .sh script
    IF /I [%1] == [-b] SET BRANCH=%2& SHIFT & SHIFT
    IF /I [%1] == [--branch] SET BRANCH=%2& SHIFT & SHIFT
    IF /I [%1] == [--cf-url] SET CF_URL=%2& SHIFT & SHIFT
    IF /I [%1] == [--cf-user] SET CF_USER=%2& SHIFT & SHIFT
    IF /I [%1] == [--cf-password] SET CF_PASSWORD=%2& SHIFT & SHIFT
    IF /I [%1] == [--cf-org] SET CF_ORG=%2& SHIFT & SHIFT
    IF /I [%1] == [--cf-space] SET CF_SPACE=%2& SHIFT & SHIFT

    SET QUICKSTART_ARGS=!QUICKSTART_ARGS! %1
    SHIFT & IF NOT [%1]==[] GOTO :GETOPTS
GOTO :AFTERGETOPTS

CALL :GETOPTS %*
:AFTERGETOPTS

ECHO SKIP_SETUP=!SKIP_SETUP!

IF [!BRANCH!]==[] (
    ECHO Usage: %FILE_NAME% -b/--branch ^(branch^)
    EXIT /b 1
)

SET IZON_BAT=https://raw.githubusercontent.com/PredixDev/izon/!BRANCH!/izon.bat
SET TUTORIAL=https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1475^&tag^=1719^&journey^=Predix%%20UI%%20Seed^&resources^=1475,1569,1523
SET REPO_NAME=PredixDev/acs-samples/master
SET SHELL_SCRIPT_NAME=quickstart-acs-samples.sh
SET APP_NAME=Access Control Service (ACS) Samples
SET TOOLS=Cloud Foundry CLI, Git, Java, Maven, Predix CLI, Python2
SET TOOLS_SWITCHES=/cf /git /java /maven /predixcli /python2
SET SHELL_SCRIPT_URL=https://raw.githubusercontent.com/!REPO_NAME!/scripts/!SHELL_SCRIPT_NAME!
SET VERSION_JSON_URL=https://raw.githubusercontent.com/!REPO_NAME!/version.json

GOTO START

:CHECK_DIR
    IF NOT "!CURRENT_DIR!" == "!CURRENT_DIR:System32=!" (
        ECHO.
        ECHO.
        ECHO Exiting tutorial. Looks like you are in the system32 directory, please change directories, e.g. \Users\your-login-name .
        EXIT /b 1
    )
GOTO :EOF

:CHECK_FAIL
    IF NOT !errorlevel! EQU 0 (
        CALL :MANUAL
    )
GOTO :EOF

:MANUAL
    ECHO.
    ECHO.
    ECHO Exiting tutorial. 
GOTO :EOF

:CHECK_PERMISSIONS
    ECHO Administrative permissions required. Detecting permissions...

    net session >nul 2>&1
    IF !errorLevel! EQU 0 (
        ECHO Success: Administrative permissions confirmed.
    ) ELSE (
        ECHO Failure: Current permissions inadequate. This script installs tools so ensure that you are launching the Command Prompt window by right-clicking and choosing 'Run as Administrator'.
        EXIT /b 1
    )
GOTO :EOF

:INIT
    IF NOT "!CURRENT_DIR!" == "!CURRENT_DIR:System32=!" (
        ECHO.
        ECHO.
        ECHO Exiting tutorial. Looks like you are in the system32 directory, please change directories, e.g. \Users\your-login-name .
        EXIT /b 1
    )
    IF NOT "!CURRENT_DIR!" == "!CURRENT_DIR:\scripts=!" (
        ECHO.
        ECHO.
        ECHO Exiting tutorial. Please launch the script from the root dir of the project.
        EXIT /b 1
    )

    ECHO Let's start by verifying that you have the required tools installed.
    SET /p ANSWER="Should we install the required tools if not already installed (!TOOLS!)? [y/n] > "
    IF "!ANSWER!" == "" (
        SET /p ANSWER="Specify [y/n] > "
    )
    SET DO_INSTALL=N
    IF /I "!ANSWER:~0,1!" == "y" SET DO_INSTALL=Y

    IF "!DO_INSTALL!" == "Y" (
        CALL :CHECK_PERMISSIONS
        IF NOT !errorlevel! EQU 0 EXIT /b !errorlevel!

        CALL :GET_DEPENDENCIES

        ECHO Calling setup-windows.bat
        CALL "setup-windows.bat" !TOOLS_SWITCHES!
        IF NOT !errorlevel! EQU 0 (
            ECHO.
            ECHO Unable to install tools. Are you behind a proxy? Perhaps if you go on a regular internet connection ^(and unset all proxy environment variables^), the tools portion of the install will succeed. Please see detailed proxy instructions at https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1565 .
            EXIT /b !errorlevel!
        )
        ECHO.
        ECHO The required tools have been installed. Now you can proceed with the tutorial.
        pause
    )
GOTO :EOF

:GET_DEPENDENCIES
    ECHO Getting dependencies

    ECHO Getting !IZON_BAT!
    powershell -Command "(new-object net.webclient).DownloadFile('!IZON_BAT!','izon.bat')"
    ECHO Getting !VERSION_JSON_URL!
    powershell -Command "(new-object net.webclient).DownloadFile('!VERSION_JSON_URL!','version.json')"
    CALL izon.bat READ_DEPENDENCY local-setup LOCAL_SETUP_URL LOCAL_SETUP_BRANCH %cd%
    ECHO LOCAL_SETUP_BRANCH=!LOCAL_SETUP_BRANCH!
    SET SETUP_WINDOWS=https://raw.githubusercontent.com/PredixDev/local-setup/!LOCAL_SETUP_BRANCH!/setup-windows.bat

    ECHO !SETUP_WINDOWS!
    powershell -Command "(new-object net.webclient).DownloadFile('!SETUP_WINDOWS!','setup-windows.bat')"
GOTO :EOF

:START

CALL :CHECK_DIR

ECHO.
ECHO Welcome to the !APP_NAME! Quick Start.
ECHO --------------------------------------------------------------
ECHO.
ECHO This is an automated script which will guide you through the tutorial.
ECHO.

IF "!SKIP_SETUP!" == "FALSE" (
    CALL :INIT
)

CALL :CHECK_FAIL
IF NOT !errorlevel! EQU 0 EXIT /b !errorlevel!

IF NOT "!CF_URL!" == "" (
    REM This is here so Jenkins can non-interactively log in to the cloud
    cf login -a !CF_URL! -u !CF_USER! -p !CF_PASSWORD! -o !CF_ORG! -s !CF_SPACE!
)

ECHO Getting !SHELL_SCRIPT_URL!
powershell -Command "(new-object net.webclient).DownloadFile('!SHELL_SCRIPT_URL!','!CURRENT_DIR!\!SHELL_SCRIPT_NAME!')"
ECHO Running the !CURRENT_DIR!\!SHELL_SCRIPT_NAME! script using Git-Bash
cd !CURRENT_DIR!
ECHO.
SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
CALL refreshenv
"%PROGRAMFILES%\Git\bin\bash" --login -i  -- "!CURRENT_DIR!\!SHELL_SCRIPT_NAME!" -b !BRANCH! --skip-setup !QUICKSTART_ARGS!
