Param (
	[Parameter(Mandatory=$True)]
	[string]$mysql_server,
    [Parameter(Mandatory=$True)]
	[string]$mysql_database,
	[Parameter(Mandatory=$True)]
	[string]$mysql_user,
    [Parameter(Mandatory=$True)]
	[string]$mysql_password,
    [Parameter(Mandatory=$True)]
	[string]$release_version
)

[system.reflection.assembly]::LoadWithPartialName("MySql.Data")    

write-host "Create coonection to" + $mysql_database

# Connect to MySQL database
$projectPath = split-path -parent $MyInvocation.MyCommand.Definition

$oConnection = New-Object -TypeName MySql.Data.MySqlClient.MySqlConnection
$oConnection.ConnectionString = "SERVER=$mysql_server;DATABASE=$mysql_database;UID=$mysql_user;PWD=$mysql_password"

try
{
    $oConnection.Open()
}
catch
{
    write-warning ("Could not open a connection to Database $sMySQLDB on Host $sMySQLHost. Error: "+$Error[0].ToString())
}


#write-host "Running backup script against database"
$mysqlpath = "C:\Program Files\MySQL\MySQL Server 8.0\bin"
$backuppath = $projectPath + "\DatabaseBackup\" 
$errorLog = $projectPath + "\DatabaseBackup\error_dump.log"
$config = $projectPath + "\config.cfg"
$date = Get-Date 
$timestamp = "" + $date.day + $date.month + $date.year + "_" + $date.hour + $date.minute 
$backupfile = $backuppath + $mysql_database + "_" + $timestamp +".sql" 
$backupzipfile = $backuppath + $mysql_database + "_" + $timestamp +".zip" 
CD $mysqlpath 
.\mysqldump.exe --defaults-extra-file=$config --log-error=$errorLog  --result-file=$backupfile --databases $mysql_database
Compress-Archive -Path $backupfile -DestinationPath $backupzipfile 
Del $backupfile
#------------------------------------------------------------


#Data insertion preperation
$oMySQLTransaction=$oConnection.BeginTransaction()
$oMYSQLCommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$oMYSQLCommand.Connection=$oConnection
$oMYSQLCommand.Transaction=$oMYSQLTransaction
$oMYSQLCommand.CommandText = "SET autocommit = 0";
$iRows=$oMYSQLCommand.executeNonQuery();
#----------------------------------------------------------------------

# Do some Inserts or updates here and commit your changes
try
{
    $sqlScriptPath  = $projectPath + "\SqlScripts"
    Get-ChildItem -Path $sqlScriptPath -recurse -Filter *.sql | 
    Foreach-Object {
        $content = Get-Content $_.FullName

        Write-Output $_.FullName
        Write-Output $content        
        
        $oMYSQLCommand.CommandText =$content
        $oMYSQLCommand.executeNonQuery()

    }    

    $oMySQLTransaction.Commit()


    $movescript = 'mv SqlScripts\' + $release_version + ' SqlScriptsArchive'
    cd $projectPath
    Invoke-Expression $movescript

    $arrReleaseVersion= $release_version.Split(".")
    $newReleaseVersion = $arrReleaseVersion[0] + '.' + $arrReleaseVersion[1] + '.' + ([int]$arrReleaseVersion[2]  + 1 )   
    cd SqlScripts
    mkdir $newReleaseVersion
    cd $newReleaseVersion
    New-Item Instrunctions.txt
    cd ..
    cd ..

    git add .
    git commit -m "Version management"
    git push origin master -q

}
catch
{
    write-warning ("ERROR occured while commit")
    $oMySQLTransaction.Rollback()
}
finally
{
    $oMySqlCommand.Connection.Close()
}
##-----------------------------------------------------------------------