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

$domainsExist = @()
$ErrorLog = @()
$NotConformLog = @()

# check domain exists
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
        $errorlog += "$domain"
    }
}
$ErrorLog | Out-File $domainExistsNotFile
$ErrorLog = @()
$NotConformLog | Out-File $domainExistsNotConformFile
$NotConformLog = @()



# foreach ($subDomain in $subDomains) {
#     foreach ($domain in $domainsExist) {
#         try {        
#             $dnsRecord = 
#             Resolve-DnsName "$subDomain.$domain" -Type A -Server $DNSServerList -ErrorAction Stop
#             try {
#                 $dnsRecord | Export-Csv "E:\languages\PowerShell\dnsRetrieval_ouput_$subDomain.csv" -NoTypeInformation -append -Delimiter ";"
#             }
#             catch {
#                 $NotConformLog += "$domain.$subDomain " + $dnsRecord.Type
#                 <#                write " ==================not to file =================== " $dnsRecord#>
            
#             }
#         }
#         catch {
#             $errorlog += "$subDomain.$domain"
#         }
#     }
# }

# $ErrorLog | Out-File "E:\languages\PowerShell\dnsRetrieval_ouput_Domains_not_found.csv"
# $NotConformLog | Out-File "E:\languages\PowerShell\dnsRetrieval_ouput_Domains_not_conform_first_domain.csv"

write-output "script has finished running"
