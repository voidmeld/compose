--!strict

local ScriptStore = require(script.ScriptStore)
local ComposeRoblox = require(script.compose.roblox)
local DesignEditor = require(script.compose["design-editor"])

local selection = game:GetService "Selection"
local storage = game:GetService "ReplicatedStorage"

local MARKER = "local _design"

local function builtIn(): DesignEditor.Kit
	return DesignEditor.kit("Roblox", function(): DesignEditor.Workspace
		local runtime = ComposeRoblox.createRuntime()
		local environment = ComposeRoblox.designEnvironment()
		return {
			runtime = runtime,
			environment = environment,
			library = DesignEditor.robloxLibrary(runtime, environment),
			root = "Stack",
			dispose = function()
				runtime:dispose()
			end,
		}
	end)
end

local function provided(module: Instance): DesignEditor.Kit?
	if not (module:IsA "ModuleScript" and string.find(module.Source, "composeDesign", 1, true)) then
		return nil
	end
	local loaded, exported = pcall(require, module)
	if not loaded or type(exported) ~= "table" then
		return nil
	end
	local factory = exported.composeDesign
	if type(factory) ~= "function" then
		return nil
	end
	local made, kit = pcall(factory)
	if not made or type(kit) ~= "table" or type(kit.name) ~= "string" or type(kit.edit) ~= "function" then
		return nil
	end
	return kit :: DesignEditor.Kit
end

local function findKit(): DesignEditor.Kit
	for _, child in storage:GetChildren() do
		local kit = provided(child)
		if kit then
			return kit
		end
		if child:IsA "Folder" then
			for _, inner in child:GetChildren() do
				local nested = provided(inner)
				if nested then
					return nested
				end
			end
		end
	end
	return builtIn()
end

local function chosenDesign(): ModuleScript?
	for _, chosen in selection:Get() do
		if chosen:IsA "ModuleScript" and string.find(chosen.Source, MARKER, 1, true) then
			return chosen
		end
	end
	return nil
end

local function defaultDesign(): ModuleScript
	local folder: Instance = storage:FindFirstChild "Designs" or Instance.new "Folder"
	if folder.Parent == nil then
		folder.Name = "Designs"
		folder.Parent = storage
	end
	local found = folder:FindFirstChild "Screen"
	if found and found:IsA "ModuleScript" then
		return found
	end
	local module = Instance.new "ModuleScript"
	module.Name = "Screen"
	module.Parent = folder
	return module
end

local toolbar = plugin:CreateToolbar "Compose"
local button = toolbar:CreateButton("ComposeDesign", "Design a screen as a Luau module", "", "Design")
button.ClickableWhenViewportHidden = true
local widget = plugin:CreateDockWidgetPluginGuiAsync(
	"ComposeDesign.Editor.v1",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 1280, 850, 1050, 600)
)
widget.Title = "Compose Design"
widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local current: ModuleScript? = nil
local close: (() -> ())? = nil

local function open(target: ModuleScript)
	if close then
		close()
		close = nil
	end
	local kit = findKit()
	local editor = kit.edit(widget, target.Name, ScriptStore(target))
	current = target
	widget.Title = `Compose Design · {kit.name} · {target:GetFullName()}`
	close = function()
		current = nil
		editor.dispose()
	end
end

local function show()
	button:SetActive(widget.Enabled)
	if widget.Enabled and close == nil then
		open(chosenDesign() or defaultDesign())
	elseif not widget.Enabled and close ~= nil then
		close()
		close = nil
	end
end

local connections = {
	widget:GetPropertyChangedSignal("Enabled"):Connect(show),
	button.Click:Connect(function()
		widget.Enabled = not widget.Enabled
	end),
	selection.SelectionChanged:Connect(function()
		local chosen = chosenDesign()
		if widget.Enabled and chosen and chosen ~= current then
			open(chosen)
		end
	end),
}

plugin.Unloading:Connect(function()
	for _, connection in connections do
		connection:Disconnect()
	end
	if close then
		close()
	end
	widget:Destroy()
	toolbar:Destroy()
end)
show()
