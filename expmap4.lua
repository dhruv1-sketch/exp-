local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicaSignal = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ReplicaSignal")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

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

local unitsToPlace = {
    {id = 1, cframe = CFrame.new(2905.6977539062, 1946.3754882812, 2407.0695800781, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {id = 2, cframe = CFrame.new(2911.1064453125, 1946.3754882812, 2407.5207519531, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {id = 3, cframe = CFrame.new(2906.8527832031, 1946.3754882812, 2410.4816894531, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {id = 4, cframe = CFrame.new(2903.5534667969, 1946.3754882812, 2399.4926757812, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {id = 5, cframe = CFrame.new(2907.1518554688, 1946.3754882812, 2398.3837890625, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
    {id = 6, cframe = CFrame.new(2907.7680664062, 1946.3754882812, 2419.9230957031, 1, 0, 0, 0, 1, 0, 0, 0, 1)}
}

task.spawn(function()
    while true do
        print("[Automation]: Waiting for match start (00:00 or 00:01)...")
        while true do
            local currentTime = getCleanTimeText()
            if currentTime == "00:00" or currentTime == "0:00" or currentTime == "00:01" or currentTime == "0:01" then
                print("[Automation]: Match started! Running routines...")
                task.wait(1)
                break
            end
            task.wait(1)
        end

        local matchActive = true

        -- Routine 1: Place units every 10 seconds for the first 3 minutes
        task.spawn(function()
            local startTime = tick()
            local duration = 180
            local interval = 10

            while matchActive and (tick() - startTime < duration) do
                print("[Automation] Placing game units sequence...")
                for _, unit in ipairs(unitsToPlace) do
                    if not matchActive then break end
                    pcall(function()
                        ReplicaSignal:FireServer(82, "PlaceGameUnit", unit.id, unit.cframe)
                    end)
                    task.wait(0.2)
                end
                task.wait(interval - (#unitsToPlace * 0.2))
            end
        end)

        -- Routine 2: Fire the "Continue" event every 1 minute
        task.spawn(function()
            while matchActive do
                pcall(function()
                    print("[Automation] Firing Continue event...")
                    ReplicaSignal:FireServer(68, "Continue")
                end)
                task.wait(60)
            end
        end)

        -- Routine 3: Fire the "Interacted" event every 1 minute
        task.spawn(function()
            while matchActive do
                pcall(function()
                    print("[Automation] Firing Interacted event...")
                    ReplicaSignal:FireServer(506, "Interacted")
                end)
                task.wait(60)
            end
        end)

        -- Monitor for match end (00:00) to reset everything
        local hasLeftStartWindow = false
        while true do
            local currentTime = getCleanTimeText()
            if currentTime and currentTime ~= "00:00" and currentTime ~= "0:00" and currentTime ~= "00:01" and currentTime ~= "0:01" then
                hasLeftStartWindow = true
            end

            if hasLeftStartWindow and currentTime and (currentTime == "00:00" or currentTime == "0:00") then
                print("[Automation]: Match timer hit 00:00! Restarting script for next match...")
                matchActive = false
                task.wait(3)
                break
            end
            task.wait(1)
        end
    end
end)
