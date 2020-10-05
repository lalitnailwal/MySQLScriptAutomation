Write-Host ""
Write-Host "****************************************************************** "
Write-Host "******  Welcome to packaging Evolution SPDB build packets  ******* "
Write-Host "****************************************************************** "
Write-Host ""


$SPDB = "SPDBPackets"
$Output = "Output"
$DeploymentDocs = "DeploymentDocs"

$Work = "Work"
$Evo = "Work\Evo"
$DocGen = "Work\DocGen"
$WebForms = "Work\WebForms"
$HDRIVE = "\\172.16.46.8\Library\Evolution\Installation_Media"
	
$confirmationSPDB = Read-Host "Downloaded SPDB packets to 'SPDBPackets' folder ? (y/n) "

if ( $confirmationSPDB -match "[nN]" ) {
Write-Host ""
Read-Host "Exiting packaging, Press any key to close the window "
Exit
}

Write-Host ""
$confirmationREADME = Read-Host "Updated README.pdf document in 'Output' folder ? (y/n) "

if ($confirmationREADME -match "[nN]" ) {
Write-Host ""
Read-Host "Exiting packaging, Press any key to close the window "
Exit
}
Write-Host ""
$buildNoEE = Read-Host "Please enter Evolution Build No "
$buildDone = "N"


#
# Clean up Work Folder
#
Write-Host ""
Write-Host "Cleaning up Work space ...."
Remove-Item $Work\* -Force -Recurse
Write-Host ""
#
# Evolution build
#
$confirmationEE = Read-Host "Build Evolution (e.g. 2.1.1.2) ? (y/n) "
if ( $confirmationEE -match "[yY]" ) { 
  # proceed

  Write-Host 'Building Evolution  ' - $buildNoEE

  # unzip packet
  Expand-Archive -Path $SPDB\$buildNoEE.zip -DestinationPath $Work
  Write-Host ""
  Write-Host "Copying from " $Work\$buildNoEE\* to $Evo
  Copy-Item $Work\$buildNoEE\ $Evo -Recurse -Force -Container
  
  Remove-Item $Output\Setup_EE*.exe -Force
  
  # build setup.exe
  Write-Host ""
  iscc Evo-New-New.iss /fSetup_EE_$buildNoEE
  $buildDone = "Y"
  Write-Host "__________________________________________ "
}

#
# DocGen build
#
Write-Host ""
$confirmationDocGen = Read-Host "Build DocGen ? (y/n) "
if ( $confirmationDocGen -match "[yY]" ) { 
  # Read build no
  $buildNoDocGen = Read-Host "Please enter DocGen Build Version No (e.g. 4.0.0)"
  Write-Host 'Building Doc Gen ....'
 
  # unzip packet
  Expand-Archive -Path $SPDB\DocumentGeneration_$buildNoDocGen*.zip -DestinationPath $Work
  Write-Host "Copying from " $Work\DocumentGen\* to $DocGen
  Copy-Item $Work\DocumentGen*\ $DocGen -Recurse -Container
 
  Remove-Item $Output\Setup_DocGen*.exe -Force
   
  # build setup.exe
  iscc DocGen-New.iss /fSetup_DocGen_$buildNoDocGen

  $buildDone = "Y"
  Write-Host "__________________________________________ "
}
#
# WebForm build
#
Write-Host ""
$confirmationDocGen = Read-Host "Build WebForm ? (y/n) "
if ( $confirmationDocGen -match "[yY]" ) { 
  # proceed
  $buildNoWFM = Read-Host "Please enter WebForms Build Version No (e.g. 1.0.8) "
  Write-Host 'Building Web Form ....'
  
  
  # unzip packet - WebForm4.0_1.0.1_20171130.zip
  Expand-Archive -Path $SPDB\WebForms*.zip -DestinationPath $Work
  Write-Host "Copying from " $Work\WebForms\* to $WebForms
  Copy-Item $Work\WebForms*\ $WebForms -Recurse -Container
  
  Remove-Item $Output\Setup_WFM*.exe -Force
  
  # build setup.exe
  iscc WebForm-New-New.iss /fSetup_WebForm_$buildNoWFM
  $buildDone = "Y"
  Write-Host "__________________________________________ "
}

#
# All Done - zip it now
#
Write-Host ""

if ($buildDone -match "[yY]") {
	Write-Host "Zipping the packet..."
	Remove-Item $Output\*EE*.zip -Force
	Remove-Item $Output\*README*.pdf -Force
	
	# Copy sql scripts
	Copy-Item $SPDB\*.txt $Output -Recurse -Container
	Copy-Item $DeploymentDocs\*.pdf $Output -Recurse -Container
	
	Compress-Archive -Path $Output -DestinationPath $Output\EE_$buildNoEE.zip
	Write-Host "Resulting zip packet is : " $Output\EE_$buildNoEE.zip
	Write-Host ""
	
	Write-Host "Build Finished ......"
}
Write-Host ""
$confirmationHDrive = Read-Host "Copy packet to H drive ? (y/n) "
if ($confirmationHDrive -match "[yY]") {
	Write-Host "Copying packets H drive .."
	Copy-Item $Output\EE_$buildNoEE.zip $HDRIVE\BuildPackets -Recurse -Container
	Copy-Item $SPDB\*.txt $HDRIVE\BuildDBScripts -Recurse -Container
	Copy-Item $SPDB\*DML*.txt $HDRIVE\DMLSQLScripts -Recurse -Container
}
Write-Host ""
Read-Host "Press any key to close the window "

