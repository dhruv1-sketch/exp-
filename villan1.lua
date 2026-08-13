-- ====================================================================
-- AUTO-PLACER WITH RELAXED TIMER MATCHING & CONSOLE LOGGING
-- ====================================================================

local CONFIG = {
    DELAY_BETWEEN_PLACEMENTS = 1.0, -- Seconds between placements (gives time to earn cash)
    REPLICA_ID = 81,
}

local player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Finds any time string (like "00:00", "0:00", " 00:01 ") anywhere in TopGameHUD
local function getCleanTimeText()
    local success, result = pcall(function()
        local topHUD = player.PlayerGui:FindFirstChild("TopGameHUD")
        if not topHUD then return nil end

        for _, descendant in ipairs(topHUD:GetDescendants()) do
            if descendant:IsA("TextLabel") and descendant.Text ~= "" then
                local foundTime = string.match(descendant.Text, "%d+:%d+")
                if foundTime then
                    return foundTime
                end
            end
        end
        return nil
    end)
    return success and result or nil
end

local placementQueue = {
    { type = "Place", slot = 4, cframe = CFrame.new(2988.361328125, 1961.7806396484, 2978.9357910156, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    { type = "Place", slot = 4, cframe = CFrame.new(2991.724609375, 1961.7806396484, 2981.6875, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    { type = "Place", slot = 4, cframe = CFrame.new(2990.1306152344, 1961.7806396484, 2984.3981933594, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    { type = "Place", slot = 1, cframe = CFrame.new(2994.1862792969, 1961.7805175781, 2979.0048828125, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    { type = "Place", slot = 5, cframe = CFrame.new(2992.1403808594, 1961.7807617188, 2928.5305175781, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    { type = "Place", slot = 2, cframe = CFrame.new(2982.1555175781, 1961.7807617188, 2920.9675292969, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    { type = "Place", slot = 2, cframe = CFrame.new(2984.7573242188, 1961.7807617188, 2919.7546386719, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    { type = "Place", slot = 3, cframe = CFrame.new(2991.0207519531, 1961.7802734375, 2889.4750976562, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    { type = "Place", slot = 6, cframe = CFrame.new(2991.0632324219, 1961.7802734375, 2885.8647460938, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    { type = "Place", slot = 6, cframe = CFrame.new(2994.0913085938, 1961.7801513672, 2888.8212890625, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
}

task.spawn(function()
    print("[Auto-Placer]: Active. Open F9 to view live clock detection.")
    local matchCount = 0

    while true do
        print("[Auto-Placer]: Waiting for match start...")
        
        -- Loop until clock hits 00:00 or 00:01
        while true do
            local currentTime = getCleanTimeText()
            
            if currentTime then
                if currentTime == "00:00" or currentTime == "0:00" or currentTime == "00:01" or currentTime == "0:01" then
                    matchCount = matchCount + 1
                    print(string.format("[Auto-Placer]: MATCH #%d START DETECTED! (Clock read: '%s')", matchCount, currentTime))
                    task.wait(1) -- Buffer delay
                    break
                end
            else
                warn("[Auto-Placer]: Timer text label not found in TopGameHUD yet...")
            end
            
            task.wait(1)
        end

        -- Execute actions
        local remote = ReplicatedStorage.RemoteEvents:FindFirstChild("ReplicaSignal")
        if remote then
            for index, action in ipairs(placementQueue) do
                if action.type == "Place" then
                    remote:FireServer(CONFIG.REPLICA_ID, "PlaceGameUnit", action.slot, action.cframe)
                    print(string.format("  -> Placed Slot %d (%d/%d)", action.slot, index, #placementQueue))
                elseif action.type == "Priority" then
                    remote:FireServer(CONFIG.REPLICA_ID, "ChangeGameUnitAutoUpgradePriority", action.value)
                    print(string.format("  -> Priority set to %s", action.value))
                end

                task.wait(CONFIG.DELAY_BETWEEN_PLACEMENTS)
            end
            print("[Auto-Placer]: Placements done. Waiting for match to end...")
        else
            warn("[Auto-Placer Error]: ReplicaSignal remote missing!")
        end

        -- Wait 20 seconds before checking for 00:00 again to avoid re-triggering in the same game
        task.wait(20)
    end
end)
