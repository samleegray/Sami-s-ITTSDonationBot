ITTsDonationBot = ZO_CallbackObject:New()
ITTsDonationBot.name = "ITTsDonationBot"
ITTsDonationBotListener = {}
local db = {}
local LAM2 = LibAddonMenu2
local LH = LibHistoire
local logger = LibDebugLogger( "ITTDB" )
logger:SetEnabled( true )
local chat = LibChatMessage( "ITTsDonationBot", "ITTs-DB" )
local apiVersion = GetAPIVersion()
local SECONDS_IN_HOUR = 60 * 60
local SECONDS_IN_DAY = SECONDS_IN_HOUR * 24
local SECONDS_IN_WEEK = SECONDS_IN_DAY * 7
local worldName = GetWorldName()

local defaults = {
    settings = {
        [ worldName ] = {
            guilds = {
                { name = "Guild Slot #1", id = 0, disabled = true, selected = false },
                { name = "Guild Slot #2", id = 0, disabled = true, selected = false },
                { name = "Guild Slot #3", id = 0, disabled = true, selected = false },
                { name = "Guild Slot #4", id = 0, disabled = true, selected = false },
                { name = "Guild Slot #5", id = 0, disabled = true, selected = false }
            },
            guildsCache = {
                { name = "Guild Slot #1", id = 0, disabled = true, selected = false },
                { name = "Guild Slot #2", id = 0, disabled = true, selected = false },
                { name = "Guild Slot #3", id = 0, disabled = true, selected = false },
                { name = "Guild Slot #4", id = 0, disabled = true, selected = false },
                { name = "Guild Slot #5", id = 0, disabled = true, selected = false }
            },
            notifications = {
                chat = true,
                screen = true
            },
            querySelection = 1,
            queryTimeframe = "Last Week"
        }
    },
    tooltip = {},
    lottoBlacklist = "Type Names here"
}

local function inter( s, tab )
    return (s:gsub(
        "($%b{})",
        function( w )
            return tab[ w:sub( 3, -2 ) ] or w
        end
    ))
end

-- Gets the start date to be used for the report queries.
-- If none is already stored, it will be set to the current time.
local function GetStartDate()
    if not db.startDate then
        db.startDate = GetTimeStamp()
    end
    return db.startDate
end

-- Gets the end date to be used for the report queries.
-- If none is already stored, it will be set to the current time.
local function GetEndDate()
    if not db.endDate then
        db.endDate = GetTimeStamp()
    end
    return db.endDate
end

-- Gets the first place winning percentage to be used for lotto calculations.
-- If none is already stored, it will be set to 0.5 (50%).
local function GetFirstPlaceWinningPercentage()
    if not db.firstPlaceWinningPercentage then
        db.firstPlaceWinningPercentage = 0.5
    end
    return db.firstPlaceWinningPercentage
end

-- Gets the second place winning percentage to be used for lotto calculations.
-- If none is already stored, it will be set to 0.0 (0%).
local function GetSecondPlaceWinningPercentage()
    if not db.secondPlaceWinningPercentage then
        db.secondPlaceWinningPercentage = 0.0
    end
    return db.secondPlaceWinningPercentage
end

-- Gets the third place winning percentage to be used for lotto calculations.
-- If none is already stored, it will be set to 0.0 (0%).
local function GetThirdPlaceWinningPercentage()
    if not db.thirdPlaceWinningPercentage then
        db.thirdPlaceWinningPercentage = 0.0
    end
    return db.thirdPlaceWinningPercentage
end

function ITTsDonationBot:parse( str, args )
    local phrase = ""
    local template = ITTsDonationBot.i18n[ "ITTDB_" .. str ]

    if template ~= nil then
        phrase = inter( template, args )
    end

    return phrase
end

-- --------------------
-- Commands
-- --------------------
local function CMD_CacheTooltips( guildIndex )
    if guildIndex then
        guildIndex = tonumber( guildIndex )

        if guildIndex == nil then
            guildIndex = 0
        end

        if guildIndex < 1 or guildIndex > 5 then
            chat:Print( ITTsDonationBot:parse( "CMD_NO_GUILDS" ) )
        else
            local guildId = GetGuildId( guildIndex )

            if ITTsDonationBot:IsGuildEnabled( guildId ) then
                ITTsDonationBot:ReCacheTooltips( guildId )
                chat:Print( ITTsDonationBot:parse( "CMD_GENERATED" ) )
            else
                chat:Print( ITTsDonationBot:parse( "CMD_NO_GUILDS" ) )
            end
        end
    else
        chat:Print( ITTsDonationBot:parse( "CMD_NO_GUILDS" ) )
    end
end

-- --------------------
-- Event Callbacks
-- --------------------
local function OnPlayerActivated( eventCode )
    EVENT_MANAGER:UnregisterForEvent( ITTsDonationBot.name, eventCode )

    ITTsDonationBot:Initialize()
end

local function CreateWithdrawRecords(world_name)
    ITTsDonationBotData.withdraw_records = {}
    ITTsDonationBotData.withdraw_records[ worldName ] = {}
end

local function ITTsDonationBot_OnAddOnLoaded( eventCode, addOnName )
    if addOnName == ITTsDonationBot.name then
        db = ZO_SavedVars:NewAccountWide( "ITTsDonationBotSettings", 1, nil, defaults )

        if not ITTsDonationBotData then
            ITTsDonationBotData = {}
        end
        if not ITTsDonationBotData.records then
            ITTsDonationBotData.records = {}
        end
        if not ITTsDonationBotData.records[ worldName ] then
            ITTsDonationBotData.records[ worldName ] = {}
        end
        if not ITTsDonationBotData.records[ worldName ].lastEvent then
            ITTsDonationBotData.records[ worldName ].lastEvent = 1413120020
        end
        for k, v in pairs( ITTsDonationBotData.records[ worldName ] ) do
            --logger:Debug(k)
            if not ITTsDonationBotData.records[ worldName ][ k ] then
                ITTsDonationBotData.records[ worldName ][ k ] = {}
            end
            if not ITTsDonationBotData.records[ worldName ][ k ] then
                ITTsDonationBotData.records[ worldName ][ k ] = {}
            end
        end

        local panelData, optionsData = ITTsDonationBot:MakeSettings(defaults, db, worldName)

        LAM2:RegisterAddonPanel( "ITTsDonationBotOptions", panelData )
        LAM2:RegisterOptionControls( "ITTsDonationBotOptions", optionsData )

        ITTsDonationBot.db = db

        EVENT_MANAGER:RegisterForEvent( ITTsDonationBot.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated )
        EVENT_MANAGER:UnregisterForEvent( ITTsDonationBot.name, eventCode )

        SLASH_COMMANDS[ "/itt-donation-cache" ] = CMD_CacheTooltips
    end
end
-- --------------------
-- Methods
-- --------------------
function ITTsDonationBot:Initialize()
    ITTsDonationBotData.withdraw_total_amount = 0
    EVENT_MANAGER:RegisterForEvent(
        ITTsDonationBot.name,
        EVENT_GUILD_SELF_JOINED_GUILD,
        function( _, _, newGuildId )
            ITTsDonationBot:CheckGuildPermissions( newGuildId )
        end
    )

    EVENT_MANAGER:RegisterForEvent(
        ITTsDonationBot.name,
        EVENT_GUILD_SELF_LEFT_GUILD,
        function()
            ITTsDonationBot:CheckGuildPermissions()
        end
    )

    if not db.tooltip[ worldName ] then
        db.tooltip[ worldName ] = {}
    end
    if not ITTsDonationBotData.hasConvertedLegacyRecords and apiVersion >= 101041 then
        ITTsDonationBot:ConvertLegacyData()
        ITTsDonationBotData.hasConvertedLegacyRecords = true
    end



    self:CheckGuildPermissions()

    ITTsDonationBot.Roster:Enable()
    ITTsDonationBot.SetupListeners()
    if not ITTsDonationBotData.hasScannedEverything then
        ITTsDonationBot:SetupFullScan()
        ITTsDonationBotData.hasScannedEverything = true
    end
    if db.records ~= nil and db.records[ worldName ] ~= nil then
        zo_callLater(
            function()
                chat:Print( ITTsDonationBot:parse( "TRANSFER_REMINDER" ) )
            end,
            5000
        )
    end
end

function ITTsDonationBot:CheckGuildPermissions( newGuildId )
    for i = 1, 5 do
        local guildId = GetGuildId( i )
        local control = _G[ "ITTsDonationBotSettingsGuild" .. tostring( i ) ]

        if guildId > 0 then
            local guildName = GetGuildName( guildId )
            local cachedSetting = db.settings[ worldName ].guilds[ i ].selected

            if guildId ~= db.settings[ worldName ].guildsCache[ i ].id then
                for inc = 1, 5 do
                    if db.settings[ worldName ].guildsCache[ inc ].id == guildId then
                        cachedSetting = db.settings[ worldName ].guildsCache[ inc ].selected
                    end
                end
            end

            db.settings[ worldName ].guilds[ i ].name = guildName
            db.settings[ worldName ].guilds[ i ].id = guildId
            db.settings[ worldName ].guilds[ i ].disabled = not DoesPlayerHaveGuildPermission( guildId,
                GUILD_PERMISSION_BANK_VIEW_GOLD )

            if DoesPlayerHaveGuildPermission( guildId, GUILD_PERMISSION_BANK_VIEW_GOLD ) then
                if newGuildId and db.settings[ worldName ].guilds[ i ].id == newGuildId then
                    db.settings[ worldName ].guilds[ i ].selected = true
                    db.settings[ worldName ].guilds[ i ].disabled = false
                elseif "Guild Slot #" .. tostring( i ) == db.settings[ worldName ].guildsCache[ i ].name then
                    db.settings[ worldName ].guilds[ i ].selected = true
                    db.settings[ worldName ].guilds[ i ].disabled = false
                end
            else
                db.settings[ worldName ].guilds[ i ].selected = false
                db.settings[ worldName ].guilds[ i ].disabled = true
            end
        else
            db.settings[ worldName ].guilds[ i ].name = "Guild Slot #" .. tostring( i )
            db.settings[ worldName ].guilds[ i ].id = 0
            db.settings[ worldName ].guilds[ i ].disabled = true
            db.settings[ worldName ].guilds[ i ].selected = false
        end

        if control then
            control.label:SetText( db.settings[ worldName ].guilds[ i ].name )
            control:UpdateValue()
            control:UpdateDisabled()
        end

        if db.settings[ worldName ].guilds[ i ].selected then
            if not ITTsDonationBotData.records[ worldName ][ db.settings[ worldName ].guilds[ i ].id ] then
                ITTsDonationBotData.records[ worldName ][ db.settings[ worldName ].guilds[ i ].id ] = {}
            end
        end
    end

    ZO_DeepTableCopy( db.settings[ worldName ].guilds, db.settings[ worldName ].guildsCache )
end

function ITTsDonationBot:HasTooltipInfo( guildId, displayName )
    local value = false

    if db.tooltip[ worldName ][ guildId ] and db.tooltip[ worldName ][ guildId ][ displayName ] then
        if db.tooltip[ worldName ][ guildId ][ displayName ].total and db.tooltip[ worldName ][ guildId ][ displayName ].total > 0 then
            value = true
        end
    end

    return value
end

function ITTsDonationBot:CreateTooltipInfo( guildId, displayName )
    if ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ] then
        local store = ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ]
        local latestDonations = {}
        local indexCheck = 1

        local today = self:QueryValues( guildId, displayName, self:GetTimestampOfDayStart( 0 ), GetTimeStamp() )
        local thisWeek = self:QueryValues( guildId, displayName, self:GetTraderWeekStart(), self:GetTraderWeekEnd() )
        local lastWeek = self:QueryValues( guildId, displayName, self:GetTraderWeekStart() - SECONDS_IN_WEEK,
            self:GetTraderWeekStart() )
        local priorWeek =
            self:QueryValues(
                guildId,
                displayName,
                ITTsDonationBot:GetTraderWeekStart() - (SECONDS_IN_WEEK * 2),
                ITTsDonationBot:GetTraderWeekStart() - SECONDS_IN_WEEK
            )

        local summary = {
            log = {},
            today = today,
            thisWeek = thisWeek,
            lastWeek = lastWeek,
            priorWeek = priorWeek,
            total = 0
        }

        local keyset = {}
        local n = 0

        for k, v in pairs( store ) do
            n = n + 1
            keyset[ n ] = k

            if v.amount then
                summary.total = summary.total + v.amount
            end
        end
        table.sort(
            keyset,
            function( a, b )
                return a > b
            end
        )

        for i = 1, 5 do
            if keyset[ i ] then
                local timeStamp = keyset[ i ]
                local value = store[ timeStamp ]

                -- formatedTime = os.date("*t", value.timestamp)

                -- local hour = formatedTime.hour
                -- local min = formatedTime.min
                -- local day = formatedTime.day
                -- local month = formatedTime.month

                -- if hour < 10 then hour = '0'..tostring(hour) end
                -- if min < 10 then min = '0'..tostring(min) end
                -- if day < 10 then min = '0'..tostring(day) end
                -- if month < 10 then min = '0'..tostring(month) end

                -- local timeString = os.date('%x',value.timestamp)
                -- local timeString = os.date(value.timestamp,'%d'..sep..'%m'..sep..'%Y %H:%M')

                local sep = "/"

                if GetCVar( "language.2" ) == "de" then
                    sep = "."
                end

                -- timeString = day..sep..month..sep..formatedTime.year..' '..hour..':'..min
                local timeString = os.date( "%d" .. sep .. "%m" .. sep .. "%Y %H:%M", timeStamp )

                summary.log[ 6 - i ] = { amount = value.amount, time = timeString }
            else
                summary.log[ 6 - i ] = { none = true }
            end
        end

        if not db.tooltip[ worldName ][ guildId ] then
            db.tooltip[ worldName ][ guildId ] = {}
        end
        if not db.tooltip[ worldName ][ guildId ][ displayName ] then
            db.tooltip[ worldName ][ guildId ][ displayName ] = {}
        end

        db.tooltip[ worldName ][ guildId ][ displayName ] = summary
    end
end

function ITTsDonationBot:GetTooltipCache( guildId, displayName )
    local tooltipData = {}

    if db.tooltip[ worldName ][ guildId ] and db.tooltip[ worldName ][ guildId ][ displayName ] then
        tooltipData = db.tooltip[ worldName ][ guildId ][ displayName ]
    end

    return tooltipData
end

function ITTsDonationBot:SaveEvent( guildId, eventType, eventTime, param1, param2, eventId )
    local id = Id64ToString( eventId )

    local secsSinceEvent = GetTimeStamp() - eventTime

    if ITTsDonationBotData.records[ worldName ].lastEvent ~= nil then
        if eventTime > ITTsDonationBotData.records[ worldName ].lastEvent then
            ITTsDonationBotData.records[ worldName ].lastEvent = eventTime
        end
    else
        ITTsDonationBotData.records[ worldName ].lastEvent = eventTime
    end
    eventTime = tostring( eventTime )
    if eventType == GUILD_EVENT_BANKGOLD_ADDED and ITTsDonationBot:IsGuildEnabled( guildId ) then
        local amount = param2
        local displayName = param1
        if ITTsDonationBotData ~= nil then
            if not ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ] then
                ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ] = {}
            end
        end

        if secsSinceEvent < SECONDS_IN_DAY then
            if not ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ][ eventTime ] then
                self:DisplayNotifications( guildId, displayName, amount, secsSinceEvent )
            end
        end

        if not ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ][ eventTime ] then
            ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ][ eventTime ] = {
                amount = amount,
                eventId = eventId,
            }
            self:CreateTooltipInfo( guildId, displayName )
            logger:Warn( "Re-caching tooltip for %s in guild %d", displayName, guildId )
        elseif
            ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ][ eventTime ] and
            not ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ][ eventTime ].eventId
        then
            ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ][ eventTime ] = {
                amount = amount,
                eventId = eventId,
            }
        end
    elseif eventType == GUILD_EVENT_BANKGOLD_REMOVED then
        local amount = param2
        local displayName = param1

        ITTsDonationBotData.withdraw_total_amount = ITTsDonationBotData.withdraw_total_amount + amount

        if not ITTsDonationBotData.withdraw_records[ worldName ][ guildId ][ displayName ][ eventTime ] then
            ITTsDonationBotData.withdraw_records[ worldName ][ guildId ][ displayName ][ eventTime ] = {
                amount = amount,
                eventId = eventId,
            }
            self:CreateTooltipInfo( guildId, displayName )
            logger:Warn( "Re-caching tooltip for %s in guild %d", displayName, guildId )
        elseif
            ITTsDonationBotData.withdraw_records[ worldName ][ guildId ][ displayName ][ eventTime ] and
            not ITTsDonationBotData.withdraw_records[ worldName ][ guildId ][ displayName ][ eventTime ].eventId
        then
            ITTsDonationBotData.withdraw_records[ worldName ][ guildId ][ displayName ][ eventTime ] = {
                amount = amount,
                eventId = eventId,
            }
        end
    end
end

-- -----------
-- LibHistoire
--! Thank you Sharlikran
-- -----------
function ITTsDonationBot:QueueListener( guildId )
    -- returns nil when not ready, so it doesn't exist
    ITTsDonationBotListener[ guildId ] = LH:CreateGuildHistoryListener( guildId, GUILD_HISTORY_BANK )
    -- If nil it's not assigned so do it again until it doesn't return nil
    if not ITTsDonationBotListener[ guildId ] then
        -- Debug LibHistoireListener not ready
        logger:Debug( "not ready" )
        zo_callLater(
            function()
                ITTsDonationBot:QueueListener( guildId )
            end,
            1000
        )
    else
        logger:Debug( "ready" )
        -- Once it isn't nil then create the rest of the listener
        ITTsDonationBot:CreateListener( guildId )
    end
end

function ITTsDonationBot:CreateListener( guildId )
    local lastEvent = 1413120020
    d("sami test2")
    if ITTsDonationBotData ~= nil then
        if ITTsDonationBotData.records[ worldName ] then
            if ITTsDonationBotData.records[ worldName ][ "lastEvent" ] then
                lastEvent = ITTsDonationBotData.records[ worldName ][ "lastEvent" ]
            end
        end
    end
    local setAfterTimeStamp = (ZO_ONE_DAY_IN_SECONDS * 2)
    ITTsDonationBotListener[ guildId ]:SetAfterEventTime( setAfterTimeStamp )

    ITTsDonationBotListener[ guildId ]:SetNextEventCallback(
        function( eventType, eventId, eventTime, param1, param2, param3, param4, param5, param6 )
            logger:Debug(
                "event for guild: %s, type: %s, time: %s, param1: %s, param2: %s, param3: %s, param4: %s, param5: %s, param6: %s",
                GetGuildName( guildId ), tostring( eventType ), tostring( eventTime ), tostring( param1 ), tostring( param2 ),
                tostring( param3 ), tostring( param4 ), tostring( param5 ), tostring( param6 ) )

            self:SaveEvent( guildId, eventType, eventTime, param1, param2, eventId )
        end
    )

    ITTsDonationBotListener[ guildId ]:SetIterationCompletedCallback(
        function()
            logger:Warn( "D O N E" )
        end
    )
    -- bankListener:SetStopOnLastEvent(true)
    ITTsDonationBotListener[ guildId ]:Start()
end

function ITTsDonationBot:SetupFullScan()
    local guilds = self:GetGuildMap()
    for i = 1, #guilds do
        local guildId = guilds[ i ]
        ITTsDonationBot:ScanEntireLH( guildId )
    end
end

function ITTsDonationBot:ScanEntireLH( guildId )
    ITTsDonationBotData.withdraw_total_amount = 0
    ITTsDonationBotListener[ guildId ]:Stop()

    ITTsDonationBotListener[ guildId ]:SetAfterEventTime( 1413120020 )
    ITTsDonationBotListener[ guildId ]:SetEventCallback(
        function( eventType, eventId, eventTime, param1, param2, param3, param4, param5, param6 )
            self:SaveEvent( guildId, eventType, eventTime, param1, param2, eventId )
        end
    )

    ITTsDonationBotListener[ guildId ]:Start()
    ITTsDonationBot:ReCacheTooltips( guildId )
end

function ITTsDonationBot:ScanSpecifcRange( guildId, startTime, endTime )
    ITTsDonationBotListener[ guildId ]:Stop()
    ITTsDonationBotListener[ guildId ]:SetTimeFrame( startTime, endTime )
    ITTsDonationBotListener[ guildId ]:SetEventCallback(
        function( eventType, eventId, eventTime, param1, param2, param3, param4, param5, param6 )
            self:SaveEvent( guildId, eventType, eventTime, param1, param2, eventId )
        end
    )
    ITTsDonationBotListener[ guildId ]:Start()
end

function ITTsDonationBot.SetupListeners()
    local guilds = ITTsDonationBot:GetGuildMap()

    for i = 1, #guilds do
        if ITTsDonationBotListener[ guilds[ i ] ] == nil then
            ITTsDonationBotListener[ guilds[ i ] ] = {}
        end
        ITTsDonationBot:QueueListener( guilds[ i ] )
    end
end

function ITTsDonationBot.YellWhenDone( guildId, category )
    logger:Warn( "History Scan finished for " .. GetGuildName( guildId ) .. "!" )
end

--LH:RegisterCallback(LH.callback.INITIALIZED, ITTsDonationBot.SetupListeners)
LH:RegisterCallback( LH.callback.HISTORY_RESCAN_ENDED, ITTsDonationBot.YellWhenDone )

-- -------------
-- Notifications
-- -------------
function ITTsDonationBot:DisplayNotifications( guildId, displayName, amount, seconds )
    local memberIndex = GetGuildMemberIndexFromDisplayName( guildId, displayName )
    local _, _, rankIndex = GetGuildMemberInfo( guildId, memberIndex )
    local iconIndex = GetGuildRankIconIndex( guildId, rankIndex )
    local rankIcon = GetGuildRankLargeIcon( iconIndex )
    local shoutMsg =
        ITTsDonationBot:parse(
            "NOTIFICATION",
            {
                user = "|t35:35:" .. rankIcon .. "|t|Caaff00" .. displayName .. "|CFFFFFF",
                amount = "|Cfce803" ..
                    ZO_LocalizeDecimalNumber( amount ) .. " |t25:25:EsoUI/Art/currency/currency_gold.dds|t|CFFFFFF",
                guild = "|cffa600" .. ITTsDonationBot.CreateGuildLink( guildId ) .. "|CFFFFFF",
                time = "|cFFFFFF" .. ZO_FormatDurationAgo( seconds )
            }
        )

    displayName = ZO_LinkHandler_CreatePlayerLink( displayName )

    local msg =
        ITTsDonationBot:parse(
            "NOTIFICATION",
            {
                user = "|t23:23:" .. rankIcon .. "|t|Caaff00" .. displayName .. "|CFFFFFF",
                amount = "|Cfce803" ..
                    ZO_LocalizeDecimalNumber( amount ) .. " |t14:14:EsoUI/Art/currency/currency_gold.dds|t|CFFFFFF",
                guild = "|cffa600" .. ITTsDonationBot.CreateGuildLink( guildId ) .. "|CFFFFFF",
                time = "|cFFFFFF" .. ZO_FormatDurationAgo( seconds )
            }
        )

    if db.settings[ worldName ].notifications.chat then
        chat:Print( msg )
    end

    if db.settings[ worldName ].notifications.screen then
        local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams( CSA_CATEGORY_SMALL_TEXT, SOUNDS.TELVAR_TRANSACT )
        params:SetCSAType( CENTER_SCREEN_ANNOUNCE_TYPE_POI_DISCOVERED )
        params:SetText( shoutMsg )
        CENTER_SCREEN_ANNOUNCE:AddMessageWithParams( params )
    end

    zo_callLater(
        function()
            LibGuildRoster:Refresh()
        end,
        2000
    )
end

function ITTsDonationBot:ReCacheTooltips( guildId )
    if ITTsDonationBotData.records[ worldName ][ guildId ] then
        for k, v in pairs( ITTsDonationBotData.records[ worldName ][ guildId ] ) do
            self:CreateTooltipInfo( guildId, k )
        end
    end
end

function ITTsDonationBot:GetGuildMap()
    local guilds = {}

    for i = 1, 5 do
        if db.settings[ worldName ].guilds[ i ].selected and not db.settings[ worldName ].guilds[ i ].disabled then
            guilds[ #guilds + 1 ] = db.settings[ worldName ].guilds[ i ].id
        end
    end

    return guilds
end

function ITTsDonationBot:IsGuildEnabled( guildId )
    local list = self:GetGuildMap()
    local condition = false

    for i = 1, #list do
        if guildId == list[ i ] then
            condition = true
            break
        end
    end

    return condition
end

function ITTsDonationBot:QueryValues( guildId, displayName, startTime, endTime )
    local value = 0

    if ITTsDonationBotData.records[ worldName ][ guildId ] and ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ] then
        for key, record in pairs( ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ] ) do
            local timeStamp = tonumber( key )
            if timeStamp and timeStamp > startTime and timeStamp < endTime then
                value = record.amount + value
            end
        end
    end

    return value
end

function ITTsDonationBot:QueryIndividualValues( guildId, displayName, startTime, endTime )
    local values = {}

    if ITTsDonationBotData.records[ worldName ][ guildId ] and ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ] then
        for key, record in pairs( ITTsDonationBotData.records[ worldName ][ guildId ][ displayName ] ) do
            local timeStamp = tonumber( key )
            if timeStamp and timeStamp > startTime and timeStamp < endTime then
                values[ #values + 1 ] = record.amount
            end
        end
    end

    return values
end

function ITTsDonationBot:GetTimestampOfDayStart( offset )
    local timeObject = os.date( "*t", os.time() - (24 * offset) * 60 * 60 )
    local hours = timeObject.hour
    local mins = timeObject.min
    local secs = timeObject.sec
    local UTCMidnightOffset = (hours * SECONDS_IN_HOUR) + (mins * 60) + secs
    local recordTimestamp = os.time( timeObject )

    return recordTimestamp - UTCMidnightOffset
end

function ITTsDonationBot:GetTraderWeekEnd()
    local _, time, _ = GetGuildKioskCycleTimes()

    if GetTimeStamp() > time then
        time = time + SECONDS_IN_WEEK
    end

    return time
end

function ITTsDonationBot:GetTraderWeekStart()
    local time = self:GetTraderWeekEnd()

    return time - SECONDS_IN_WEEK
end

-- ---------------
-- CustomGuildLink
-- --------------
function ITTsDonationBot.GetGuildColor( i )
    local r, g, b = GetChatCategoryColor( _G[ "CHAT_CATEGORY_GUILD_" .. tostring( i ) ] )
    local colorObject = ZO_ColorDef:New( r, g, b )

    return {
        rgb = { r, g, b },
        hex = colorObject:ToHex()
    }
end

function ITTsDonationBot.CreateGuildLink( guildId )
    -- local alliance = GetGuildAlliance(guildId)
    local gIndex = ITTsDonationBot.GetGuildIndex( guildId )
    local name = GetGuildName( guildId )
    local color = ITTsDonationBot.GetGuildColor( gIndex )

    local guildLink = "|c" .. color.hex .. "[|H1:gwguild::" .. guildId .. "|h " .. name .. " ]|h|r"

    return guildLink
end

function ITTsDonationBot.HandleClickEvent( rawLink, mouseButton, linkText, linkStyle, linkType, guildId, ... )
    local gIndex = ITTsDonationBot.GetGuildIndex( guildId )
    if linkType == "gwguild" then
        if mouseButton == MOUSE_BUTTON_INDEX_LEFT then
            GUILD_SELECTOR:SelectGuildByIndex( gIndex )
            MAIN_MENU_KEYBOARD:ShowScene( "guildHome" )

            return true
        end

        if mouseButton == MOUSE_BUTTON_INDEX_MIDDLE then
            if DoesPlayerHaveGuildPermission( guildId, GUILD_PERMISSION_MANAGE_APPLICATIONS ) == true then
                GUILD_SELECTOR:SelectGuildByIndex( gIndex )
                MAIN_MENU_KEYBOARD:ShowScene( "guildRecruitmentKeyboard" )

                zo_callLater(
                    function()
                        GUILD_RECRUITMENT_KEYBOARD:ShowApplicationsList()
                    end,
                    250
                )
            else
                zo_callLater(
                    function()
                        MAIN_MENU_KEYBOARD:ShowScene( "guildRoster" )
                    end,
                    50
                )
            end
            return true
        end

        if mouseButton == MOUSE_BUTTON_INDEX_RIGHT then
            ClearMenu()

            AddCustomMenuItem(
                "Show Guild Roster",
                function()
                    GUILD_SELECTOR:SelectGuildByIndex( gIndex )
                    MAIN_MENU_KEYBOARD:ShowScene( "guildRoster" )
                end
            )
            AddCustomMenuItem(
                "Show Guild Ranks",
                function()
                    GUILD_SELECTOR:SelectGuildByIndex( gIndex )
                    MAIN_MENU_KEYBOARD:ShowScene( "guildRanks" )
                end
            )
            if DoesPlayerHaveGuildPermission( guildId, GUILD_PERMISSION_MANAGE_APPLICATIONS ) == true then
                AddCustomMenuItem(
                    "Show Guild Recruitment",
                    function()
                        GUILD_SELECTOR:SelectGuildByIndex( gIndex )
                        MAIN_MENU_KEYBOARD:ShowScene( "guildRecruitmentKeyboard" )
                    end
                )
            end
            if DoesPlayerHaveGuildPermission( guildId, GUILD_PERMISSION_EDIT_HERALDRY ) == true then
                AddCustomMenuItem(
                    "Show Guild Heraldry",
                    function()
                        GUILD_SELECTOR:SelectGuildByIndex( gIndex )
                        MAIN_MENU_KEYBOARD:ShowScene( "guildHeraldry" )
                    end
                )
            end
            AddCustomMenuItem(
                "Show Guild History",
                function()
                    GUILD_SELECTOR:SelectGuildByIndex( gIndex )
                    MAIN_MENU_KEYBOARD:ShowScene( "guildHistory" )
                end
            )
            ShowMenu()
            return true
        end
    end
end

LINK_HANDLER:RegisterCallback( LINK_HANDLER.LINK_MOUSE_UP_EVENT, ITTsDonationBot.HandleClickEvent )

function ITTsDonationBot.GetGuildIndex( guildId )
    local numg = 0

    for gi = 1, GetNumGuilds() do
        local gcheck = GetGuildId( gi )
        local idNum = tonumber( guildId )
        if (idNum == gcheck) then
            return gi
        end
    end
end

-- --------------------
-- Transfer Data
-- --------------------

function ITTsDonationBot:TransferData()
    local guilds = {}
    if db.records == nil then
        d( "none" )
    else
        for guildId, dataTable in pairs( db.records[ worldName ] ) do
            if type( dataTable ) == "table" then
                for playerName, playerEvents in pairs( dataTable ) do
                    for eventId, eventData in pairs( playerEvents ) do
                        if not ITTsDonationBotData.records then
                            ITTsDonationBotData.records = {}
                        end
                        if not ITTsDonationBotData.records[ worldName ] then
                            ITTsDonationBotData.records[ worldName ] = {}
                        end
                        if not ITTsDonationBotData.records[ worldName ][ guildId ] then
                            ITTsDonationBotData.records[ worldName ][ guildId ] = {}
                        end
                        if not ITTsDonationBotData.records[ worldName ][ guildId ][ playerName ] then
                            ITTsDonationBotData.records[ worldName ][ guildId ][ playerName ] = {}
                        end
                        if not ITTsDonationBotData.records[ worldName ][ guildId ][ playerName ][ tostring( eventId ) ] and eventId > 0 then
                            ITTsDonationBotData.records[ worldName ][ guildId ][ playerName ][ tostring( eventId ) ] = {}
                            ITTsDonationBotData.records[ worldName ][ guildId ][ playerName ][ tostring( eventId ) ] = {
                                timestamp = eventData.timestamp,
                                amount = eventData.amount
                            }
                        end
                    end
                end
                ITTsDonationBot:ReCacheTooltips( guildId )
            end
            db.records = nil
        end
    end
end

--Convert old data saved by eventId to new format
-- We do this since the new update has a new format for the eventIds so we might have duplicates
function ITTsDonationBot:ConvertLegacyData()
    local data = ITTsDonationBotData.records[ worldName ]
    local newRecords = {}
    for guildId, guildData in pairs( data ) do
        if type( guildData ) == "table" then
            for playerName, playerEvents in pairs( guildData ) do
                for eventId, eventData in pairs( playerEvents ) do
                    local timeStamp = tostring( eventData.timestamp )

                    if not newRecords[ guildId ] then
                        newRecords[ guildId ] = {}
                    end
                    if not newRecords[ guildId ][ playerName ] then
                        newRecords[ guildId ][ playerName ] = {}
                    end
                    newRecords[ guildId ][ playerName ][ timeStamp ] = {
                        amount = eventData.amount,
                        eventId = eventId
                    }
                end
            end
        end
    end
    ITTsDonationBotData.records[ worldName ] = newRecords -- store new records
end

-- --------------------
-- Attach Listeners
-- --------------------
EVENT_MANAGER:RegisterForEvent( ITTsDonationBot.name, EVENT_ADD_ON_LOADED, ITTsDonationBot_OnAddOnLoaded )
