Config = {}

do
    Config.lang = 'CN'

    Config.Debug = true

    Config.coalition = {
        Neutual = 0,
        Red = 1,
        Blue = 2,
        All = -1,
    }

    Config.Country = {
        [1] = country.id.CJTF_RED,
        [2] = country.id.CJTF_BLUE,
    }

    Config.drawIndexTabel = Utils.getIndexTable(1,1000,1)

    -----------CaptureZone-----------
    Config.CaptureZone = {}
    Config.CaptureZone.MonitorRepeatTime = 5 --Seconds
    Config.CaptureZone.CaptureTime = 20 --Seconds

    -----------CaptureZone End-------



end