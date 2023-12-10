# Загрузка файла с конфигом
$Config = gc C:\powershell\config.txt

# Создаю объект со свойсвами и переменную, хранящую номер техники
$event_cfg = [PSCustomObject]@{Id = $null; Journal = $null; Field = $null; Pattern = $null}
$techniq = $null

# Функция, которая одновременно парсит и сверяет свойства события
Function MyCompare
{
    Param ($event)
    
    ForEach ($one in $Config)
    {  
        # Первым парсим id конфига и сверяем его с id события
        if ($one -like "*id*")
        {
            $event_cfg.Id = $one.Substring($one.IndexOf(":")+2)
        } 
        # Парсим поле
        if ($one -like "*field*")
        {
            $event_cfg.Field = $one.Remove($one.Length-1).Substring($one.IndexOf(":")+3)
        }
        # Парсим паттерн - проделанная техника
        if ($one -like "*pattern*")
        {
            $event_cfg.Pattern = $one.Remove($one.Length-1).Substring($one.IndexOf(":")+3)
        }
        # Последним парсим название лога в конфиге, где выполняется главная проверка проделанной техники
        if ($one -like "*journal*")
        {
            $event_cfg.Journal = $one.Substring($one.IndexOf(":")+2)

            # Сравниваем по названию лога и полю
            if( 
	            ($event.Id -eq $event_cfg.Id) -and
	            ($event.LogName -eq $event_cfg.Journal) -and 
                (($event_cfg.Field -like $event.Message) -or -not[bool]$event_cfg.Field))
                { Write-Host("Сработала техника: ", $techniq) }
        }
        # Если наткнулись на "event" в конфиге, то обнуляем все свойства объекта (нужно например в отсутствии какого-то свойства в конфиге)
        if ($one -like "*event*")
        {
            $event_cfg.Field = $null
            $event_cfg.Id = $null
            $event_cfg.Journal = $null
            $event_cfg.Pattern = $null
        }
        # Парсим номер техники
        if ($one -like "t*")
        {
            $techniq = $one.Remove($one.Length-1).Substring(1)
        }
    }
}
$startTime = (Get-Date).AddHours(-1) 
$endTime = Get-Date 
$cred = Get-Credential -Credential admin
$compname = "192.168.43.230"

$logs = Get-WinEvent -ComputerName $compname -Credential $cred -ListLog * 2>$null

foreach ($log in $logs) 
{
    
    
    $events = Get-WinEvent -ComputerName $compname -Credential $cred -FilterHashtable @{LogName = $log.LogName; StartTime=$startTime; EndTime=$endTime} 2>$null
    foreach($event in $events)
        {
             MyCompare -event $event
        }
}