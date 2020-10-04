@echo off

REM -------------------------------------------------------------------------------------------------------
REM  Remove Existing file list and Creating new one based on the SQL files available including sub folders
REM --------------------------------------------------------------------------------------------------------

IF EXIST list.txt DEL /Q .\list.txt

for /f %%i in ('dir *.sql /s /b 2^> nul ^| find "" /v /c') do set FileCount=%%i

IF "%FileCount%"=="0" (
echo There is no SQL files to execute on current and sub directory.
echo.
goto commonexit
)

IF NOT "%FileCount%"=="0" (
dir *.sql /b /s /a-d >> list.txt
echo.
)


REM ----------------------------------------------------------------------------------
REM                 Collecting Server, Database and Credential
REM ----------------------------------------------------------------------------------

SET server=%1
set catalog=%2
set authen=%3
set user=%4
set password=%5
set _sqllist=%6

@If "%1" == "" set /p server= Please enter the server name:
@If "%2" == "" set /p catalog= Please enter the database name:
@If "%3" == "" set /p authen= Is the Server supports windows Authentication(Y/N):

IF "%authen%"=="N" goto credential
IF "%authen%"=="Y" goto prompt_sqllist
Echo Invalid Entry..!
goto commonexit

:credential
@If "%4" == "" set /p user= Please enter the Username:
@If "%5" == "" set /p password= Please enter the password:
goto prompt_sqllist


REM ----------------------------------------------------------------------------------
REM       Assigning Customized order file list 
REM ----------------------------------------------------------------------------------

:prompt_sqllist
echo.
SET /P filelist=Already SQL files list generated as list.txt in the directory. Do you want to execute the same order(Y/N):
IF "%filelist%"=="Y" (
SET _sqllist=list.txt
echo.
goto fileprocess
)

IF "%filelist%"=="N" (
@If "%6" == "" SET /P _sqllist=Please specify the customized order list file name:
echo.
goto fileprocess
)


REM ----------------------------------------------------------------------------------
REM       Executing SQL files from the directory
REM ----------------------------------------------------------------------------------

:fileprocess
IF "%_sqllist%"=="EXIT" GOTO:EOF
IF "%_sqllist%"=="" GOTO:sub_nosqllist
IF NOT EXIST %_sqllist% GOTO:sub_nofile

rem : remove previous log files
rem mkdir %mypath%\%catalog%
IF EXIST .\output\%catalog% RMDIR /S /Q .\output\%catalog%
IF NOT EXIST .\output\%catalog% mkdir .\output\%catalog%
rem CLS

IF "%authen%"=="N" (
for /f "tokens=*" %%f in (%_sqllist%) do (
    ECHO Executing file "%%f"
    For %%A in ("%%f") do (
         sqlcmd -S %server% -U %user% -P %password% -d %catalog% -i "%%f" >.\output\%catalog%\%%~nxA.log
 )
   )
)

IF "%authen%"=="Y" (
for /f "tokens=*" %%f in (%_sqllist%) do (
    ECHO Executing file "%%f"
    For %%A in ("%%f") do (
           sqlcmd -S %server% -d %catalog% -i "%%f" >.\output\%catalog%\%%~nxA.log
         )
   )
)

rem : clear variables

SET _sqllist=
echo.
ECHO Process completed. Please verify the results in output folder.
echo.
GOTO commonexit

:sub_nosqllist
ECHO Server List file name not supplied
GOTO commonexit

:sub_nofile
ECHO SQL file does not exist
GOTO :prompt_sqlfile

:commonexit
pause