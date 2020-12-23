Add-Type -AssemblyName System.Windows.Forms
$fileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('desktop') 
    Filter = 'txt (*.txt)|*.txt'
}

$fileBrowser.Title = 'select domains file'
$null = $fileBrowser.ShowDialog()
$domainsInputFile = $fileBrowser.filename

$fileBrowser.InitialDirectory = $fileBrowser.FileName
$dataDirectory = Split-Path $fileBrowser.filename -parent 
$dataDirectory += '\'

$fileBrowser.Title = 'select CNAME SubDomain file'
$null = $fileBrowser.ShowDialog()
$subDomainsInputFile = $fileBrowser.filename

$filePrefix = "DNSRetrieval"
$fileOutputPrefix = "Output"
$fileErrorPrefix = "ERROR"
$DNSServerList = @('8.8.8.8', '8.8.4.4')

$domains = get-content $DomainsInputFile

$subDomains = get-content $subDomainsInputFile

# delete old output files
$allOutputFiles = $dataDirectory + $filePrefix + $fileOutputPrefix + "*.csv"
Remove-Item  $allOutputFiles
# delete old ERROR files
$allErrorFiles = $dataDirectory + $filePrefix + $fileErrorPrefix + "*.log"
Remove-Item  $allErrorFiles

# check domain exists
$domainsExist = @()
$domainErrorLog = @()
$domainNotConformLog = @()
$domainExistsFile = $dataDirectory + $filePrefix + $fileOutputPrefix + "DomainExists.csv"
$domainExistsNotFile =$dataDirectory + $filePrefix + $fileOutputPrefix + "DomainExistsNot.log"
$domainExistsNotConformFile =$dataDirectory + $filePrefix + $fileOutputPrefix + "DomainExistsNotConform.log"

foreach ($domain in $domains) {
    try {        
        $dnsRecord = Resolve-DnsName "$domain" -Type A -Server $DNSServerList -ErrorAction Stop
        $domainsExist += $domain
        try {
            $dnsRecord | Export-Csv $domainExistsFile -NoTypeInformation -append -Delimiter ";"
        }
        catch {
            $NotConformLog += $domain + $dnsRecord.Type
            <# write " ==================not to file =================== " $dnsRecord#>
        
        }
    }
    catch {
        $domainErrorLog += "$domain"
    }
}
$domainErrorLog | Out-File $domainExistsNotFile
$domainNotConformLog | Out-File $domainExistsNotConformFile

$subDomainExistsNotFile =$dataDirectory + $filePrefix + $fileOutputPrefix + "SubDomainExistsNot.log"
$subDomainExistsNotConformFile =$dataDirectory + $filePrefix + $fileOutputPrefix + "SubDomainExistsNotConform.log"

$subDomainErrorLog = @()
$subDomainNotConformLog = @()

foreach ($subDomain in $subDomains) {
    $subDomainWithoutPoint = $subDomain.replace('.','')
    $subDomainExistsFile = $dataDirectory + $filePrefix + $fileOutputPrefix + "SubDomainExists-" + $subDomainWithoutPoint + ".csv"
    foreach ($domain in $domainsExist) {
        try {        
            $dnsRecord = 
            Resolve-DnsName "$subDomain.$domain" -Type A -Server $DNSServerList -ErrorAction Stop
            try {
                $dnsRecord | Export-Csv $subDomainExistsFile -NoTypeInformation -append -Delimiter ";"
            }
            catch {
                $subDomainNotConformLog += "$domain.$subDomain " + $dnsRecord.Type
                <#                write " ==================not to file =================== " $dnsRecord#>
            
            }
        }
        catch {
            $subDomainErrorLog += "$subDomain.$domain"
        }
    }
}

$subDomainErrorLog | Out-File $subDomainExistsNotFile
$subDomainNotConformLog | Out-File $subDomainExistsNotConformFile

write-output "script has finished running"
