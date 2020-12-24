# get domains File
Add-Type -AssemblyName System.Windows.Forms
$fileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('personal') 
    Filter           = 'txt (*.txt)|*.txt'
    Title            = 'select domains file'
}
$null = $fileBrowser.ShowDialog()
$domainsInputFile = $fileBrowser.filename
# set data directory to source directory
$fileBrowser.InitialDirectory = $fileBrowser.FileName
$dataDirectory = Split-Path $fileBrowser.filename -parent 
$dataDirectory += '\'
# set domains
$modelDomain = 'presentdordrecht.nl'
$domains = @($modelDomain)
$domains += get-content $DomainsInputFile
# set dns record type for domain.
$DNSTypes = @('MX', 'SOA', 'TXT', 'NS')
# set subdomains@DNSTYPE
$subDomains = @(
    '_dmarc@TXT',
    '_sip._tls@SRV',
    '_sipfederationtls._tcp@SRV',
    'autodiscover@CNAME',
    'enterpriseenrollment@CNAME',
    'enterpriseregistration@CNAME',
    'ftp@A',
    'imap@A',
    'lyncdiscover@CNAME',
    'mail@A',
    'pop@A',
    'sip@CNAME',
    'smtp@A',
    'www@A',
    'x._domainkey@TXT'
)
# set filename structure
$filePrefix = "DNSRetrieval"
$fileOutputPrefix = "Output"
$fileErrorPrefix = "ERROR"
# set DNS Servers to use
$DNSServerList = @('8.8.8.8', '8.8.4.4')
# delete old output files
$allOutputFiles = $dataDirectory + $filePrefix + $fileOutputPrefix + "*"
Remove-Item  $allOutputFiles
# delete old ERROR files
$allErrorFiles = $dataDirectory + $filePrefix + $fileErrorPrefix + "*"
Remove-Item  $allErrorFiles
# check domain exists and get A record
$domainsExist = @()
$domainErrorLog = @('Domain')
$domainNotConformLog = @('Domain')
$domainExistsFile = $dataDirectory + $filePrefix + $fileOutputPrefix + "DomainExists.csv"
$domainExistsNotFile = $dataDirectory + $filePrefix + $fileOutputPrefix + "DomainExistsNot.csv"
$domainExistsNotConformFile = $dataDirectory + $filePrefix + $fileOutputPrefix + "DomainExistsNotConform.csv"

foreach ($domain in $domains) {
    try {        
        $dnsRecord = Resolve-DnsName "$domain" -Type A -Server $DNSServerList -ErrorAction Stop
        $domainsExist += $domain
        try {
            $dnsRecord | Export-Csv $domainExistsFile -NoTypeInformation -append -Delimiter ";"
        }
        catch {
            $NotConformLog += $domain + $dnsRecord.Type
            Write-Output "=$domain=$dnsRecord.Type============not conform ModelDomain =================== " $dnsRecord
        }
    }
    catch {
        $domainErrorLog += "$domain"
    }
}
$domainErrorLog | Out-File $domainExistsNotFile
$domainNotConformLog | Out-File $domainExistsNotConformFile

$DomainTypeExistsNotFile = $dataDirectory + $filePrefix + $fileOutputPrefix + "DomainTypeExistsNot.csv"
$DomainTypeExistsNotConformFile = $dataDirectory + $filePrefix + $fileOutputPrefix + "DomainTypeExistsNotConform.csv"

$DomainTypeErrorLog = @('Domain;Type')
$DomainTypeNotConformLog = @('Domain;Type')

foreach ($DNSType in $DNSTypes) {
    $DomainTypeWithoutPoint = $DNSType.replace('.', '')
    $DomainTypeExistsFile = $dataDirectory + $filePrefix + $fileOutputPrefix + "DomainTypeExists-" + $DomainTypeWithoutPoint + ".csv"
    foreach ($domain in $domainsExist) {
        try {        
            $dnsRecord = 
            Resolve-DnsName $domain -Type $DNSType -Server $DNSServerList -ErrorAction Stop
            try {
                $dnsRecord | Export-Csv $DomainTypeExistsFile -NoTypeInformation -append -Delimiter ";"
            }
            catch {
                $DomainTypeNotConformLog += "$domain;$DNSType;"
                Write-Output "=$domain=$DNSType==============not conform ModelDomain =================== " $dnsRecord
            }
        }
        catch {
            $DomainTypeErrorLog += "$domain;$DNSType;" + $dnsRecord.Type
        }
    }
}

$DomainTypeErrorLog | Out-File $DomainTypeExistsNotFile
$DomainTypeNotConformLog | Out-File $DomainTypeExistsNotConformFile

$subDomainExistsNotFile = $dataDirectory + $filePrefix + $fileOutputPrefix + "SubDomainExistsNot.csv"
$subDomainExistsNotConformFile = $dataDirectory + $filePrefix + $fileOutputPrefix + "SubDomainExistsNotConform.csv"

$subDomainErrorLog = @("domain;subDomain")
$subDomainNotConformLog = @("domain;subDomain")

foreach ($subDomainDNSType in $subDomains) {
    $subDomainDNSTypeSplit = $subDomainDNSType.split('@')
    $subDomain = $subDomainDNSTypeSplit[0]
    $DNSType = $subDomainDNSTypeSplit[1]
    $subDomainWithoutPoint = $subDomain.replace('.', '')
    $subDomainExistsFile = $dataDirectory + $filePrefix + $fileOutputPrefix + "SubDomainExists-" + $subDomainWithoutPoint + ".csv"
    foreach ($domain in $domainsExist) {
        try {        
            $dnsRecord = 
            Resolve-DnsName "$subDomain.$domain" -Type $DNSType -Server $DNSServerList -ErrorAction Stop
            try {
                $dnsRecord |Select-Object * | Export-Csv $subDomainExistsFile -NoTypeInformation -append -Delimiter ";"
            }
            catch {
                $subDomainNotConformLog += "$domain;$subDomain"
                Write-Output "=$subDomain.$domain=$DNSType=============not conform ModelDomain =================== " $dnsRecord
            }
        }
        catch {
            $subDomainErrorLog += "$domain;$subDomain"
        }
    }
}

$subDomainErrorLog | Out-File $subDomainExistsNotFile
$subDomainNotConformLog | Out-File $subDomainExistsNotConformFile

write-output "script has finished running"
