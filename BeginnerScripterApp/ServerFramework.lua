--[[

	This is a script I've written to apply for the beginner scripter role.
	The program is an economy system in which the player can work to earn money
	and use that money to buy items. Although there is no phsyicality to it,
	the system still exists and if need be, has the possibility of being integrated physically.
	
	PROGRAM BY: Cxotral (@Danger_Xavier)
	Discord: longnosedmonkey

]]

local Players = game:GetService("Players")
local ProfileService = require(game.ServerScriptService.ProfileService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes
local buyRemote = ReplicatedStorage.ItemBuy
local workRemote = ReplicatedStorage.Work
local setupRemote = ReplicatedStorage.Setup

-- ProfileService Setup
local ProfileStore = ProfileService.GetProfileStore(
	"_TestData",  -- Data store name
	{
		Money = 100  -- Default starting money
	}
)

local playerProfiles = {}  -- Table to hold player profiles

-- Currency Management
local function GetMoney(player)
	local profile = playerProfiles[player]
	if profile then
		return profile.Data.Money
	else
		warn("Player does not have any money, or there was an error in recovering the amount of the player's money.")
	end
end

local function AddMoney(player, amount)
	local profile = playerProfiles[player]
	if profile then
		profile.Data.Money = profile.Data.Money + amount
		-- Update leaderstat
		local moneyValue = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
		if moneyValue then
			moneyValue.Value = profile.Data.Money
		end
	end
end

local function SubtractMoney(player, amount)
	local profile = playerProfiles[player]
	if profile and profile.Data.Money >= amount then
		profile.Data.Money = profile.Data.Money - amount
		-- Update leaderstat
		local moneyValue = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
		if moneyValue then
			moneyValue.Value = profile.Data.Money
		end
		return true
	else
		return false
	end
end

-- Shop Management
local shopItems = {
	["Sword"] = 50,
	["Shield"] = 30,
	["Potion"] = 10
}

local function GetItems()
	return shopItems
end

local function BuyItem(player, itemName)
	if shopItems[itemName] then
		local price = shopItems[itemName]
		if SubtractMoney(player, price) then
			print(player.Name .. " bought a " .. itemName)
			return true
		else
			print(player.Name .. " lacks funds for " .. itemName)
			return false
		end
	end
end

-- Job Management
local jobs = {
	["Miner"] = 20,  -- Pays 20 per job cycle
	["Farmer"] = 15,
	["Builder"] = 25
}

local function GetJobs()
	return jobs
end

local function Work(player, jobName)
	if jobs[jobName] then
		wait(10)  -- Simulate work time
		local pay = jobs[jobName]
		AddMoney(player, pay)
		print(player.Name .. " earned " .. pay .. " from " .. jobName)
	end
end

-- Event Management
local events = {
	{name = "Sale", effect = function() print("Shop prices halved!") end},
	{name = "Bonus", effect = function(player) AddMoney(player, 10) end}
}

local function TriggerRandomEvent()
	local event = events[math.random(1, #events)]
	event.effect()
	print("Event: " .. event.name)
end

-- ProfileService: Handle Player Joining
local function onPlayerAdded(player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId, "ForceLoad")
	if profile then
		profile:Reconcile()  -- Fill in missing data with template
		profile:ListenToRelease(function()
			playerProfiles[player] = nil
			player:Kick()  -- Kick player if profile is released (e.g., another server took over)
		end)
		if player:IsDescendantOf(Players) then
			playerProfiles[player] = profile

			-- Create leaderstats
			local leaderstats = Instance.new("Folder")
			leaderstats.Name = "leaderstats"
			leaderstats.Parent = player

			local moneyValue = Instance.new("IntValue")
			moneyValue.Name = "Money"
			moneyValue.Value = profile.Data.Money
			moneyValue.Parent = leaderstats
			
			local jobs = GetJobs()
			local items = GetItems()
			setupRemote:FireClient(player, jobs, items, "JobSetup")
			setupRemote:FireClient(player, jobs, items, "ShopSetup")
		else
			profile:Release()
		end
	else
		player:Kick("Failed to load profile!")
	end
end

-- ProfileService: Handle Player Leaving
local function onPlayerRemoving(player)
	local profile = playerProfiles[player]
	if profile then
		profile:Release()
	end
end

-- Connect Player Events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- UI Interaction functions
local function onBuyItem(player, itemName)
	BuyItem(player, itemName)
end

local function onWork(player, jobName)
	Work(player, jobName)
end

-- Connect UI button events
workRemote.OnServerEvent:Connect(onWork)
buyRemote.OnServerEvent:Connect(onBuyItem)

-- Random Event Loop
spawn(function()
	while true do
		wait(60)  -- Trigger event every minute
		TriggerRandomEvent()
	end
end)
