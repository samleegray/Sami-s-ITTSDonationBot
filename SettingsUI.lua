-- --------------------
-- Create Settings
-- --------------------
function ITTsDonationBot:MakeSettings( defaults, db, worldName )
    local optionsData = {}
    local guildLotto = 1
    local lottotTicketValue = 1000

    local panelData = {
        type = "panel",
        name = ITTsDonationBot:parse( "NAME" ),
        author = "|c00a313Ghostbane|r & |c268074JN Slevin|r",
        version = "2.1.0",
        website = "https://www.esoui.com/downloads/info2765-ITTsDonationBotITTDB.html"
    }

    optionsData[ #optionsData + 1 ] = {
        type = "header",
        name = ITTsDonationBot:parse( "HEADER_GUILDS" )
    }


    local function getGuildNameTable()
        local tb = {}
        local guildMap = ITTsDonationBot:GetGuildMap()
        for i = 1, GetNumGuilds() do
            local guildId = GetGuildId( i )
            if
                ZO_IsElementInNumericallyIndexedTable( guildMap, guildId ) then
                tb[ #tb + 1 ] = ITTsDonationBot.CreateGuildLink( GetGuildId( i ) )
            end
        end

        return tb
    end

    local function getGuildIndexTable()
        local tb = {}
        local guildMap = ITTsDonationBot:GetGuildMap()
        for i = 1, GetNumGuilds() do
            local guildId = GetGuildId( i )
            if
                ZO_IsElementInNumericallyIndexedTable( guildMap, guildId ) then
                tb[ #tb + 1 ] = i
            end
        end

        return tb
    end


    optionsData[ #optionsData + 1 ] = {
        type = "description",
        title = "",
        text = ITTsDonationBot:parse( "SETTINGS_DESC" )
    }

    for i = 1, 5 do
        optionsData[ #optionsData + 1 ] = {
            type = "checkbox",
            name = function()
                return db.settings[ worldName ].guilds[ i ].name
            end,
            tooltip = function()
                if db.settings[ worldName ].guilds[ i ].disabled then
                    return ITTsDonationBot:parse( "SETTINGS_SCAN_ERROR" )
                else
                    return ITTsDonationBot:parse( "SETTINGS_SCAN_PROMPT",
                        { guild = db.settings[ worldName ].guilds[ i ].name } )
                end
            end,
            disabled = function()
                return db.settings[ worldName ].guilds[ i ].disabled
            end,
            getFunc = function()
                return db.settings[ worldName ].guilds[ i ].selected
            end,
            setFunc = function( value )
                db.settings[ worldName ].guilds[ i ].selected = value
            end,
            default = defaults.settings[ worldName ].guilds[ i ].selected,
            reference = "ITTsDonationBotSettingsGuild" .. tostring( i )
        }
    end

    optionsData[ #optionsData + 1 ] = {
        type = "description",
        title = "",
        text = ITTsDonationBot:parse( "SETTINGS_SCAN_INFO" )
    }

    optionsData[ #optionsData + 1 ] = {
        type = "header",
        name = ITTsDonationBot:parse( "HEADER_NOTIFY" )
    }

    optionsData[ #optionsData + 1 ] = {
        type = "description",
        title = "",
        text = ITTsDonationBot:parse( "SETTINGS_NOTIFY" )
    }

    optionsData[ #optionsData + 1 ] = {
        type = "checkbox",
        name = ITTsDonationBot:parse( "SETTINGS_CHAT" ),
        getFunc = function()
            return db.settings[ worldName ].notifications.chat
        end,
        setFunc = function( value )
            db.settings[ worldName ].notifications.chat = value
        end,
        default = defaults.settings[ worldName ].notifications.chat
    }

    optionsData[ #optionsData + 1 ] = {
        type = "checkbox",
        name = ITTsDonationBot:parse( "SETTINGS_SCREEN" ),
        getFunc = function()
            if ITT_DonationBotSettingsLogo and _desc then
                makeITTDescription()
                local _desc = true
            end

            return db.settings[ worldName ].notifications.screen
        end,
        setFunc = function( value )
            db.settings[ worldName ].notifications.screen = value
        end,
        default = defaults.settings[ worldName ].notifications.screen
    }

    local function GetTicketsForPlayer( guildId, displayName )
        local ticketCost = tonumber( lottotTicketValue )
        local ticketCount = 0
        local amounts = ITTsDonationBot:QueryIndividualValues( guildId, displayName, GetStartDate(), GetEndDate() )
        for i = 1, #amounts do
            local amount = amounts[i]
            if amount == ticketCost then
                ticketCount = ticketCount + 1
            end
        end

        return ticketCount
    end

    local function ITT_LottoGenerate()
        local guildId = GetGuildId( guildLotto )
        local nameList = ""
        local amountList = ""
        local nameList2 = ""
        local amountList2 = ""
        local rowCount = 0
        local potAmount = 0
        local sortedNames = {}
        local ticketCost = tonumber( lottotTicketValue )

        if not ITTsDonationBot:IsGuildEnabled( guildId ) then
            return false
        end

        for i = 1, GetNumGuildMembers( guildId ) do
            local displayName = GetGuildMemberInfo( guildId, i )
            local name = string.gsub( displayName, "@", "" )

            if not PlainStringFind( string.lower( db.lottoBlacklist ), string.lower( name ) ) then
                -- local totalAmount = ITTsDonationBot:QueryValues( guildId, displayName, startDate, endDate )
                local ticketCount = GetTicketsForPlayer( guildId, displayName )

                if ticketCount > 0 then
                    -- Update the pot amount and row count
                    potAmount = potAmount + ( ticketCount * ticketCost )
                    rowCount = rowCount + 1

                    -- Add the name and ticket count to the sorted names table
                    sortedNames[ #sortedNames + 1 ] = { name = name, tickets = ticketCount }
                end
            end
        end

        -- Sort the names alphabetically
        table.sort( sortedNames, function(a, b)
            return string.lower(a.name) < string.lower(b.name)
        end)

        -- Iterate through the sorted names and create the lists
        for i = 1, #sortedNames do
            local name = sortedNames[i].name
            local tickets = sortedNames[i].tickets

            if i <= 250 then
                nameList = nameList .. name .. "\n"
                amountList = amountList .. tostring( tickets ) .. "\n"
            else
                nameList2 = nameList2 .. name .. "\n"
                amountList2 = amountList2 .. tostring( tickets ) .. "\n"
            end
        end

        -- Get the winning amount.
        local firstPlaceWinningAmount = potAmount * GetFirstPlaceWinningPercentage()

        -- Update the text boxes
        ITT_LottoTotalPot.editbox:SetText( firstPlaceWinningAmount )

        ITT_LottoNameList.editbox:SetText( nameList )
        ITT_LottoAmountList.editbox:SetText( amountList )

        if rowCount > 250 then
            ITT_LottoNameList2.editbox:SetText( nameList2 )
            ITT_LottoAmountList2.editbox:SetText( amountList2 )
        end
    end

    local lottoOptions = {}

    lottoOptions[ #lottoOptions + 1 ] = {
        type = "description",
        title = "",
        text = ITTsDonationBot:parse( "SETTINGS_LOTTO_DESC" )
    }

    lottoOptions[ #lottoOptions + 1 ] = {
        type = "dropdown",
        name = ITTsDonationBot:parse( "SETTINGS_LOTTO_SELECT" ),
        tooltip = ITTsDonationBot:parse( "SETTINGS_LOTTO_GUILD" ),
        choices = getGuildNameTable(),
        choicesValues = getGuildIndexTable(),
        getFunc = function()
            return getGuildIndexTable()[ 1 ]
        end,
        setFunc = function( var )
            guildLotto = var
        end,

        width = "half",
        isExtraWide = true
    }

    lottoOptions[ #lottoOptions + 1 ] = {
        type = "editbox",
        name = ITTsDonationBot:parse( "SETTINGS_LOTTO_VALUE" ),
        tooltip = ITTsDonationBot:parse( "SETTINGS_LOTTO_EXAMPLE" ),
        getFunc = function()
            return lottotTicketValue
        end,
        setFunc = function( text )
            lottotTicketValue = text
        end,
        width = "half", --or "half" (optional)
        isExtraWide = true
    }

    lottoOptions[ #lottoOptions + 1 ] = {

        type = "editbox",
        name = "Lotto blacklist",
        tooltip = "Blacklist names to be ignored in the list. Seperate each name with a comma",
        getFunc = function() return db.lottoBlacklist end,
        setFunc = function( text ) db.lottoBlacklist = text end,
        isMultiline = true, --boolean
        width = "full",     --or "half" (optional)
        isExtraWide = true,
        default = "",       --(optional)
    }

    lottoOptions[ #lottoOptions + 1 ] = {
        type = "datepicker",
        name = "Start Date",
        width = "half",
        getFunc = function() return GetStartDate() end,
        setFunc = function( date ) db.startDate = date end,
    }

    lottoOptions[ #lottoOptions + 1 ] = {
        type = "datepicker",
        name = "End Date",
        width = "half",
        getFunc = function() return GetEndDate() end,
        setFunc = function( date ) db.endDate = date end,
    }

    lottoOptions[ #lottoOptions + 1 ] = {
        type = "button",
        name = ITTsDonationBot:parse( "SETTINGS_LOTTO_GENERATE" ),
        tooltip = ITTsDonationBot:parse( "SETTINGS_LOTTO_GENERATE_COL" ),
        func = ITT_LottoGenerate,
        width = "full"
    }

    lottoOptions[ #lottoOptions + 1 ] = {
        type = "description",
        title = "",
        text = [[ ]]
    }

    lottoOptions[ #lottoOptions + 1 ] = {
        type = "editbox",
        name = ITTsDonationBot:parse( "SETTINGS_LOTTO_NAMES" ),
        tooltip = ITTsDonationBot:parse( "SETTINGS_LOTTO_INFO_1" ),
        getFunc = function()
            return ITTsDonationBot:parse( "SETTINGS_LOTTO_INFO_5" )
        end,
        setFunc = function( text )
            print( text )
        end,
        isMultiline = true,
        width = "half",
        isExtraWide = true,
        reference = "ITT_LottoNameList"
    }

    lottoOptions[ #lottoOptions + 1 ] = {
        type = "editbox",
        name = ITTsDonationBot:parse( "SETTINGS_LOTTO_TICKETS" ),
        tooltip = ITTsDonationBot:parse( "SETTINGS_LOTTO_INFO_2" ),
        getFunc = function()
            return ITTsDonationBot:parse( "SETTINGS_LOTTO_INFO_6" )
        end,
        setFunc = function( text )
            print( text )
        end,
        isMultiline = true,
        width = "half",
        isExtraWide = true,
        reference = "ITT_LottoAmountList"
    }

    lottoOptions[ #lottoOptions + 1 ] = {
        type = "editbox",
        name = "",
        tooltip = ITTsDonationBot:parse( "SETTINGS_LOTTO_INFO_3" ),
        getFunc = function()
            return ITTsDonationBot:parse( "SETTINGS_LOTTO_INFO_5" )
        end,
        setFunc = function( text )
            print( text )
        end,
        isMultiline = true,
        width = "half",
        isExtraWide = true,
        reference = "ITT_LottoNameList2"
    }

    lottoOptions[ #lottoOptions + 1 ] = {
        type = "editbox",
        name = "",
        tooltip = ITTsDonationBot:parse( "SETTINGS_LOTTO_INFO_4" ),
        getFunc = function()
            return ITTsDonationBot:parse( "SETTINGS_LOTTO_INFO_6" )
        end,
        setFunc = function( text )
            print( text )
        end,
        isMultiline = true,
        width = "half",
        isExtraWide = true,
        reference = "ITT_LottoAmountList2"
    }

    lottoOptions[ #lottoOptions + 1 ] = {
        type = "editbox",
        name = "Winner Percentage",
        tooltip = "Percentage of total pot to give to the winner. Decimal or value less than 100.",
        getFunc = function()
            return ITTsDonationBot:parse( "SETTINGS_LOTTO_WINNER_PERCENT" )
        end,
        setFunc = function( number )
            if number < 1 then
                winnerPercent = number
            else
                winnerPercent = number / 100
            end
        end,
        width = "half",
        isExtraWide = true,
        textType = "TEXT_TYPE_NUMERIC",
        reference = "ITT_LottoWinnerPercent"
    }

    lottoOptions[ #lottoOptions + 1 ] = {
        type = "editbox",
        name = "Total Pot",
        tooltip = "Total pot of gold",
        getFunc = function()
            return ITTsDonationBot:parse( "SETTINGS_LOTTO_TOTAL_POT" )
        end,
        setFunc = function( text )
            print( text )
        end,
        width = "half",
        isExtraWide = true,
        reference = "ITT_LottoTotalPot"
    }

    optionsData[ #optionsData + 1 ] = {
        type = "submenu",
        name = ITTsDonationBot:parse( "SETTINGS_LOTTO_NAME" ),
        -- tooltip = "$$$", --(optional)
        controls = lottoOptions
    }
    local ITTLibHistoireOptions = {}
    optionsData[ #optionsData + 1 ] = {
        type = "submenu",
        name = ITTsDonationBot:parse( "LH_OPTIONS" ),
        controls = ITTLibHistoireOptions
    }
    ITTLibHistoireOptions[ #ITTLibHistoireOptions + 1 ] = {
        type = "header",
        name = ITTsDonationBot:parse( "LH_OPTION2_DESC" ),
        width = "full"
    }
    ITTLibHistoireOptions[ #ITTLibHistoireOptions + 1 ] = {
        type = "description",
        text = ITTsDonationBot:parse( "LH_OPTION2_WARN" ),
        width = "half"
    }
    ITTLibHistoireOptions[ #ITTLibHistoireOptions + 1 ] = {
        type = "button",
        name = "Scan",
        func = function()
            return ITTsDonationBot:SetupFullScan()
        end,
        width = "half", --or "full" (optional)
        warning = ITTsDonationBot:parse( "LH_OPTION2_ENTRY" ),
        isDangerous = true
    }
    local ITTImportOptions = {}

    optionsData[ #optionsData + 1 ] = {
        type = "submenu",
        name = ITTsDonationBot:parse( "TRANSFER_OPTIONS" ),
        controls = ITTImportOptions,
        reference = "ITTImportMenu"
    }

    optionsData[ #optionsData + 1 ] = {
        type = "description",
        title = "",
        text = [[ ]]
    }

    optionsData[ #optionsData + 1 ] = {
        type = "texture",
        image = "ITTsDonationBot/itt-logo.dds",
        imageWidth = "192",
        imageHeight = "192",
        reference = "ITT_DonationBotSettingsLogo"
    }
    ITTImportOptions[ #ITTImportOptions + 1 ] = {
        type = "header",
        name = ITTsDonationBot:parse( "TRANSFER_TITLE" ),
        width = "full"
    }
    ITTImportOptions[ #ITTImportOptions + 1 ] = {
        type = "description",
        text = ITTsDonationBot:parse( "TRANSFER_DESC" ),
        width = "half"
    }
    ITTImportOptions[ #ITTImportOptions + 1 ] = {
        type = "button",
        name = "Import",
        tooltip = ITTsDonationBot:parse( "TRANSFER_WARN" ),
        func = function()
            return ITTsDonationBot:TransferData(), ITTImportMenu:SetHidden( true )
        end,
        width = "half", --or "full" (optional)
        warning = ITTsDonationBot:parse( "TRANSFER_WARN_2" ),
        isDangerous = true
    }
    local _desc = true

    local function makeITTDescription()
        local ITTDTitle = WINDOW_MANAGER:CreateControl( "ITTsDonationBotSettingsLogoTitle", ITT_DonationBotSettingsLogo,
            CT_LABEL )
        ITTDTitle:SetFont( "$(BOLD_FONT)|$(KB_18)|soft-shadow-thin" )
        ITTDTitle:SetText( "|Cfcba03INDEPENDENT TRADING TEAM" )
        ITTDTitle:SetDimensions( 240, 31 )
        ITTDTitle:SetHorizontalAlignment( 1 )
        ITTDTitle:SetAnchor( TOP, ITT_DonationBotSettingsLogo, BOTTOM, 0, 40 )

        local ITTDLabel = WINDOW_MANAGER:CreateControl( "ITTsDonationBotSettingsLogoTitleServer",
            ITTsDonationBotSettingsLogoTitle, CT_LABEL )
        ITTDLabel:SetFont( "$(MEDIUM_FONT)|$(KB_16)|soft-shadow-thick" )
        ITTDLabel:SetText( "|C646464PC EU" )
        ITTDLabel:SetDimensions( 240, 21 )
        ITTDLabel:SetHorizontalAlignment( 1 )
        ITTDLabel:SetAnchor( TOP, ITTsDonationBotSettingsLogoTitle, BOTTOM, 0, -5 )

        ITT_HideMePls:SetHidden( true )

        if db.records == nil then
            ITTImportMenu:SetHidden( true )
        end
    end

    optionsData[ #optionsData + 1 ] = {
        type = "checkbox",
        name = "HideMePls",
        getFunc = function()
            if ITT_DonationBotSettingsLogo ~= nil and _desc then
                makeITTDescription()
                _desc = false
            end

            return false
        end,
        setFunc = function( value )
            return false
        end,
        default = false,
        disabled = true,
        reference = "ITT_HideMePls"
    }

    return panelData, optionsData
end