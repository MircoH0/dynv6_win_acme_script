param(
    [string]$op,
    [string]$zone,
    [string]$name,
    [string]$token,
    [string]$recordtype='TXT'
)
[string]$dynv6_httpkey
[string]$dynv6_root="https://dynv6.com/api/v2/zones"

$dynv6_headers

function cut_zone
{
    param([string]$zone)
    if ($zone.Split(".").Count -gt 3){
        $cut_zone=$zone.Split(".")[-3]+'.'+$zone.Split(".")[-2]+'.'+$zone.Split(".")[-1]
        return $cut_zone
    }else{
        return $zone
    }
}

function cut_name
{
    param([string]$name)
    return $name.Substring(0,$name.Length-$zone.Length-1)
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
    Write-Error "Can't find zone: $zone"
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
    $request_body=@{
        "type"=$type;
        "name"=$rec_name;
        "data"=$rec_data;
        }
    $request_body=$request_body | ConvertTo-Json -Compress
    echo $request_body
    Write-Output "Createing $rec_name ..."
    Invoke-RestMethod -Uri "$dynv6_root/$zoneid/records" -Method Post -Headers $dynv6_headers -Body $request_body -ContentType 'application/json'
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

$zone=cut_zone $zone
$name=cut_name $name
$zoneid=get_zoneid $zone

if ($op -eq "create"){
    if ($zoneid -ne $null){
        create_record $name $token $recordtype $zoneid
    }
}elseif ($op -eq "delete"){
    if ($zoneid -ne $null){
        $rec_id=get_recordid $zoneid $name
        if ($rec_id -ne $null){
            delete_record $rec_id $zoneid
        }
    }
}
