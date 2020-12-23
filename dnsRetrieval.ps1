$programDirectory = "F:\OneDrive\OneDrive - Present Nederland\DNS-Checks\PowerShell\"
$filePrefix = "DNSRetrieval"
$fileInputPrefix = "Input"
$fileOutputPrefix = "Output"
$fileErrorPrefix = "ERROR"
$DNSServerList = @('8.8.8.8', '8.8.4.4')

$domainsInputFile = $ProgramDirectory + $filePrefix + $fileInputPrefix + "DomainNames.txt"
$domains = get-content $DomainsInputFile

$subDomainsInputFile = $ProgramDirectory + $filePrefix + $fileInputPrefix + "SubDomainNames.txt"
$subDomains = get-content $subDomainsInputFile

# delete old output files
$allOutputFiles = $ProgramDirectory + $filePrefix + $fileOutputPrefix + "*.csv"
Remove-Item  $allOutputFiles
# delete old ERROR files
$allErrorFiles = $ProgramDirectory + $filePrefix + $fileErrorPrefix + "*.log"
Remove-Item  $allErrorFiles

# check domain exists
$domainsExist = @()
$domainErrorLog = @()
$domainNotConformLog = @()
$domainExistsFile = $ProgramDirectory + $filePrefix + $fileOutputPrefix + "DomainExists.csv"
$domainExistsNotFile =$ProgramDirectory + $filePrefix + $fileOutputPrefix + "DomainExistsNot.log"
$domainExistsNotConformFile =$ProgramDirectory + $filePrefix + $fileOutputPrefix + "DomainExistsNotConform.log"

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

$subDomainExistsNotFile =$ProgramDirectory + $filePrefix + $fileOutputPrefix + "SubDomainExistsNot.log"
$subDomainExistsNotConformFile =$ProgramDirectory + $filePrefix + $fileOutputPrefix + "SubDomainExistsNotConform.log"

$subDomainErrorLog = @()
$subDomainNotConformLog = @()

foreach ($subDomain in $subDomains) {
    $subDomainExistsFile = $ProgramDirectory + $filePrefix + $fileOutputPrefix + "SubDomainExists-" + $subDomain + "-" +".csv"
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
