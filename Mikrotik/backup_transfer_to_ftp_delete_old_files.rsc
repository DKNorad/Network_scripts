### FTP server parameters
:local ftpServer "host";
:local username "ftp_user";
:local password "ftp";

### Get date and time
:local date [/system/clock/get date];
:local time ([:pick [/system/clock/get time] 0 2] . "-" . [:pick [/system/clock/get time] 3 5] . "-" . [:pick [/system/clock/get time] 6 8]);
:local dateTime ($date . "_" . $time);

### Specify file names
:local hostname [/system/identity/get name];
:local localFilename "auto_backup_$hostname_$dateTime";
:local remoteFilename "auto_backup_$hostname_$dateTime";

### Enabled for Debug
#:log info "$localFilename";
#:log info "$remoteFilename";
#:log info "$hostname";
#:log info "$dateTime";

### Stating the Backup
:log info "[BACKUP SCRIPT] STARTING BACKUP";

### Create backup file and export the config.
export compact file="$localFilename"
/system/backup/ save name="$remoteFilename"
:log info "[BACKUP SCRIPT] Backup Created Successfully"

### Upload backup file to FTP server.
/tool fetch address=$ftpServer src-path="$localFilename.backup" user=$username mode=ftp password=$password dst-path="$remoteFilename.backup" upload=y>
:log info "[BACKUP SCRIPT] Config Uploaded Successfully"

### Upload config file to FTP server.
/tool fetch address=$ftpServer src-path="$localFilename.rsc" user=$username mode=ftp password=$password dst-path="$remoteFilename.rsc" upload=yes;
:log info "[BACKUP SCRIPT] Backup Uploaded Successfully"

:log info "[BACKUP SCRIPT] BACKUP FINISHED";

### Check number of saved backups
:local filename;
:local fileCount 0;
:local posix ("^auto_backup_" . $hostname . "_.*?\\.rsc");
:local oldestFile;
:local fileName;


# loop through the files
:foreach FILE in=[/file find where name~$posix ] do={
   :set fileCount ($fileCount + 1);
}

# If the backup files are more than 14
:if ($fileCount > 14) do={
   :foreach FILE in=[/file find where name~$posix ] do={
       :local new [/file get $FILE creation-time];
       :local year [:pick $new 0 4];
       :local month [:pick $new 5 7];
       :local day [:pick $new 8 10];
       :local hour [:pick $new 11 13];
       :local minute [:pick $new 14 16];
       :local sec [:pick $new 17 19];
       :local timeCalc ($year . $month . $day . $hour . $minute . $sec);

       # if new date/time is less than (older) or hasn't been set
       :if ($timeCalc < $oldestFile || [:len $oldestFile] = 0) do={
           :set fileName [/file get $FILE name];
               :set oldestFile $timeCalc;
       }
   }
}

:if ([:len $oldestFile] > 0) do={
   :local fileNameNoExt [:pick $fileName 0 39];
   /file remove [find name="$fileNameNoExt.rsc"];
   /file remove [find name="$fileNameNoExt.backup"];
   :log info "[BACKUP SCRIPT] 14 backup files was exceeded and the oldest file - [$fileNameNoExt] was delete.";
}
