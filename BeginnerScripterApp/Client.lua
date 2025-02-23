-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local money = leaderstats.Money

-- UI variables
local mainGui = script.Parent
local templateObj = mainGui.Template

local shopFrame = mainGui.Shop
local workFrame = mainGui.Work
local workingNotif = mainGui.WorkingNotif
local moneyFrame = mainGui.MoneyDisplay

local moneyCount = moneyFrame.MoneyCount

-- Remotes
local buyRemote = ReplicatedStorage.ItemBuy
local workRemote = ReplicatedStorage.Work
local setupRemote = ReplicatedStorage.Setup

-- Setup the buttons for jobs and shop items
local function uiSetup(jobs, items, eventType)
	if eventType == "JobSetup" then
		for jobName, pay in pairs(jobs) do
			local newBtn = templateObj:Clone()
			newBtn.Text = jobName .. ": $" .. pay
			newBtn.Parent = workFrame.Container
			newBtn.Visible = true

			-- Connect button click to work event
			newBtn.MouseButton1Click:Connect(function()
				workRemote:FireServer(jobName)
				workingNotif.Notification.Text = "Please wait for your payment as you work " .. jobName
				
				workingNotif.Visible = true
				local tween = TweenService:Create(workingNotif, TweenInfo.new(.4), {Position = UDim2.new(0.5, 0, 0.02, 0)})
				tween:Play()
				
				task.wait(10)
				
				workingNotif.Visible = true
				local tween2 = TweenService:Create(workingNotif, TweenInfo.new(.4), {Position = UDim2.new(0.5, 0, -0.3, 0)})
				tween2:Play()
				tween2.Completed:Wait()
				
				workingNotif.Visible = false
			end)
		end

	elseif eventType == "ShopSetup" then
		for shopItem, cost in pairs(items) do
			local newBtn = templateObj:Clone()
			newBtn.Text = shopItem .. ": $" .. cost
			newBtn.Parent = shopFrame.Container
			newBtn.Visible = true

			-- Connect button click to buy event
			newBtn.MouseButton1Click:Connect(function()
				buyRemote:FireServer(shopItem)
			end)
		end
	end
end

-- Call setup function once the player has joined (Activated through main servers script)
setupRemote.OnClientEvent:Connect(uiSetup)

-- Set the money display's value to the player's actual money amount
RunService.RenderStepped:Connect(function()
	moneyCount.Text = "$" .. money.Value
end)