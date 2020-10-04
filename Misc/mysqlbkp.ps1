#Set-ExecutionPolicy -ExecutionPolicy Bypass
$mysqlpath = "C:\Program Files\MySQL\MySQL Server 8.0\bin"
$backuppath = "E:\data\mysqldbbackup\"
$7zippath = "C:\Program Files (x86)\7-Zip"
$config = "E:\data\config.cnf"
$database = "blog"
$errorLog = "E:\data\error_dump.log"
$mymail = "recipient@testing.com"
$date = Get-Date
$timestamp = "" + $date.day + $date.month + $date.year + "_" + $date.hour + $date.minute
$backupfile = $backuppath + $database + "_" + $timestamp +".sql"
$backupzip = $backuppath + $database + "_" + $timestamp +".zip"


try
{

CD $mysqlpath

.\mysqldump.exe --defaults-extra-file=$config --log-error=$errorLog  --result-file=$backupfile  --databases $database /c

CD $7zippath

.\7z.exe a -tzip $backupzip $backupfile

Del $backupfile

CD $backuppath
$oldbackups = gci *.zip*

for($i=0; $i -lt $oldbackups.count; $i++){
    if ($oldbackups[$i].CreationTime -lt $date.AddDays(-3)){
        $oldbackups[$i] | Remove-Item -Confirm:$false
    }
}
Send-MailMessage -to $mymail -From "eg@bkp.com" -Subject "Success suject" -Body "MSG body for success" -SmtpServer 127.0.0.1
}
catch
{
Send-MailMessage -to $mymail -From "eg@bkp.com" -Subject "Failuer subject" -Body "MSG body for failuer" -SmtpServer 127.0.0.1
}