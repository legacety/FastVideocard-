script_author('legacy.')
script_version("1.01")

local sampev = require("samp.events")

local active = false
local houseIndex = 0
local houseCount = 0
local withdrawActive = false
local totalBTC = 0
local totalASC = 0
local awaitingFinalProfit = false

local dialogQueue = {}
local dialogDelayTimer = os.clock()

function main()
    repeat wait(0) until isSampAvailable()
    sampAddChatMessage("{C285FF} [ Fast Videocard ] {FFFFFF} �������� | ���������: {C285FF}/bitc{FFFFFF} | �����: {FFD700}legacy.", -1)

    sampRegisterChatCommand('bitc', function()
        active = true
        houseIndex = 0
        withdrawActive = false
        totalBTC = 0
        totalASC = 0
        awaitingFinalProfit = false
        sampSendChat("/flashminer")
    end)

    while true do
        wait(0)
        if #dialogQueue > 0 and os.clock() - dialogDelayTimer >= 0.1 then
            local dialogInfo = table.remove(dialogQueue, 1)
            sampSendDialogResponse(dialogInfo.id, dialogInfo.button, dialogInfo.listitem, dialogInfo.input)
            dialogDelayTimer = os.clock()
        end
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if id == 7238 and title:find('����� ����') then
        if active then
            local lines = {}
            for line in text:gmatch("[^\r\n]+") do
                table.insert(lines, line)
            end

            houseCount = #lines - 1

            if houseCount > 0 then
                if houseIndex == 0 then
                    sampAddChatMessage(string.format("{C285FF} [ Fast Videocard ] {FFFFFF} ������� �����: {FFD700}%d{FFFFFF}", houseCount), -1)
                end

                table.insert(dialogQueue, {id=id, button=1, listitem=houseIndex, input=""})
                withdrawActive = true
                houseIndex = houseIndex + 1

                if houseIndex >= houseCount then
                    active = false
                    awaitingFinalProfit = true
                end
            else
                sampAddChatMessage("{C285FF} [ Fast Videocard ] {FFFFFF} {FF0000}������: {FFFFFF}���� �� ������� � �������.", -1)
                active = false
            end
        end
        return true
    end

    if id == 25245 and title:find("���") and button1 == "�������" then
        table.insert(dialogQueue, {id=id, button=0, listitem=0, input=""})
        return true
    end

    if not withdrawActive then return true end

    local function findLineAndRespond(pattern, checkFunc, listboxId)
        local found = false
        for line in string.gmatch(text, "[^\r\n]+") do
            if line:find(pattern) and checkFunc(line) then
                table.insert(dialogQueue, {id=id, button=1, listitem=listboxId, input=line})
                found = true
                return true
            end
            listboxId = listboxId + 1
        end
        return false
    end

    if title:find('{BFBBBA}�������� ����������') then
        if not text:find('%d+%.%d%d%d%d%d%d') then
            withdrawActive = false
            if not active and awaitingFinalProfit then
                showFinalProfit()
            end
            table.insert(dialogQueue, {id=id, button=0, listitem=0, input=""})
            return true
        end
        if not findLineAndRespond('%d+%.%d%d%d%d%d%d', function(line)
            return tonumber(line:match("(%d+)%.%d%d%d%d%d%d")) > 0
        end, -1) then
            withdrawActive = false
            if not active and awaitingFinalProfit then
                showFinalProfit()
            end
            table.insert(dialogQueue, {id=id, button=0, listitem=0, input=""})
        end
        return true

    elseif title:find('{BFBBBA}������') then
        if not findLineAndRespond('%d+%.%d%d%d%d%d%d', function(line)
            return tonumber(line:match("(%d+)%.%d%d%d%d%d%d")) > 0
        end, 0) then
            table.insert(dialogQueue, {id=id, button=0, listitem=0, input=""})
        end
        return true

    elseif title:find('{BFBBBA}����� ������� ����������') then
        table.insert(dialogQueue, {id=id, button=1, listitem=0, input=""})
        return true

    elseif title:find("{BFBBBA}���������� � ����������") or title:find("������� ������� ��������") then
        table.insert(dialogQueue, {id=id, button=0, listitem=0, input=""})
        withdrawActive = false
        
        if not active and awaitingFinalProfit then
            showFinalProfit()
        end

        return true
    end

    return true
end

function sampev.onServerMessage(color, text)
    local btcAmount = text:match("�� ������ {ffffff}(%d+)%sBTC")
    local ascAmount = text:match("�� ������ {ffffff}(%d+)%sASC")
    local itemBTC = text:match("��� ��� �������� ������� 'Bitcoin %(BTC%)'")
    local itemASC = text:match("��� ��� �������� ������� 'Arizona Coin %(ASC%)'")

    if text:find("� ���� ���� ��� ������� � ����������� ��� �� ��� �� ��������") then
        if houseIndex < houseCount then
            sampSendChat("/flashminer")
        else
            active = false
            awaitingFinalProfit = true
            showFinalProfit()
        end
        return false
    end

    if btcAmount then
        totalBTC = totalBTC + tonumber(btcAmount)
        return false
    end

    if ascAmount then
        totalASC = totalASC + tonumber(ascAmount)
        return false
    end

    if itemBTC then
        totalBTC = totalBTC + 1
        return false
    end

    if itemASC then
        totalASC = totalASC + 1
        return false
    end
end

function showFinalProfit()
    awaitingFinalProfit = false
    sampAddChatMessage(string.format('{C285FF} [ Fast Videocard ] {FFFFFF} ���� ��������! ��������: {00BFFF}%d BTC{FFFFFF}, {DAA520}%d ASC', totalBTC, totalASC), -1)
end
