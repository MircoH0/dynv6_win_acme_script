param(
    [string]$op,
    [string]$zone,
    [string]$name,
    [string]$token
)
[string]$dynv6_httpkey
[string]$dynv6_root="https://dynv6.com/api/v2/zones"
$type='TXT'
$dynv6_headers

function cut_name
{
    param([string]$name)
    return $name.split(".")[0]
}

function get_zoneid
{
    param([string]$zone)
    $zone_result=Invoke-RestMethod -Uri $dynv6_root -Headers $dynv6_headers
    foreach ($zoneitem in $zone_result){
        if ($zoneitem.name -eq $zone){
            return $zoneitem.id
        }
    }
}

function get_recordid
{
    param(
        [string]$zoneid,
        [string]$rec_name
    )
    $record_result=Invoke-RestMethod -Uri $dynv6_root'/'$zoneid'/'records -Headers $dynv6_headers
    foreach ($recorditem in $record_result){
        if ($recorditem.name -eq $rec_name){
            return $recorditem.id
        }
    }
}

function create_record
{
    param(
        [string]$rec_name,
        [string]$rec_data,
        [string]$type,
        [int]$zoneid
    )
    $request_dict=@{
        name=$rec_name;
        data=$rec_data;
        type=$type
    }
    Write-Output "Creating $rec_name ..."
    Invoke-RestMethod -Uri "$dynv6_root/$zoneid/records" -Method Post -Headers $dynv6_headers -Body $request_dict
}

function delete_record
{
    param(
        [int]$rec_id,
        [int]$zoneid
    )
    Write-Output "Deleteing $name ..."
    Invoke-RestMethod -Uri "$dynv6_root/$zoneid/records/$rec_id" -Method Delete -Headers $dynv6_headers
}

if ((Test-Path .\dynv6_key.txt) -eq $True){
    $dynv6_httpkey=Get-Content .\dynv6_key.txt
    $dynv6_headers=@{Authorization="Bearer $dynv6_httpkey"}
}else{
    Write-Error "Can't find dynv6_key.txt"
    exit
}

$name=cut_name $name
$zoneid=get_zoneid $zone

if ($op -eq "create"){
    if ($zoneid -ne $null){
        create_record $name $token $type $zoneid
    }
}elseif ($op -eq "delete"){
    if ($zoneid -ne $null){
        $rec_id=get_recordid $zoneid $name
        if ($rec_id -ne $null){
            delete_record $rec_id $zoneid
        }
    }
}