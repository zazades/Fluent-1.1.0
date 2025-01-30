local RunService = game:GetService("RunService")
local TEXT_WIDTH_CACHE = {} 
local MAX_VISIBLE_DROPDOWNS = 10 
local DROPDOWN_BUFFER = 2 
local elementPool = {} 

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
local Camera = game:GetService("Workspace").CurrentCamera

local Root = script.Parent.Parent
local Creator = require(Root.Creator)
local Flipper = require(Root.Packages.Flipper)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Dropdown"

function Element:New(Idx, Config)
	local Library = self.Library

	local Dropdown = {
		Values = Config.Values,
		Value = Config.Default,
		Multi = Config.Multi,
		Buttons = {},
		Opened = false,
		Type = "Dropdown",
		Callback = Config.Callback or function() end,
	}

	local DropdownFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, false)
	DropdownFrame.DescLabel.Size = UDim2.new(1, -170, 0, 14)

	Dropdown.SetTitle = DropdownFrame.SetTitle
	Dropdown.SetDesc = DropdownFrame.SetDesc

	local DropdownDisplay = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Text = "Value",
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -30, 0, 14),
		Position = UDim2.new(0, 8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	local DropdownIco = New("ImageLabel", {
		Image = "rbxassetid://10709790948",
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundTransparency = 1,
		ThemeTag = {
			ImageColor3 = "SubText",
		},
	})

	local DropdownInner = New("TextButton", {
		Size = UDim2.fromOffset(160, 30),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 0.9,
		Parent = DropdownFrame.Frame,
		ThemeTag = {
			BackgroundColor3 = "DropdownFrame",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),
		New("UIStroke", {
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "InElementBorder",
			},
		}),
		DropdownIco,
		DropdownDisplay,
	})

	local DropdownListLayout = New("UIListLayout", {
		Padding = UDim.new(0, 3),
	})

	local DropdownScrollFrame = New("ScrollingFrame", {
		Size = UDim2.new(1, -5, 1, -10),
		Position = UDim2.fromOffset(5, 5),
		BackgroundTransparency = 1,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 4,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
	}, {
		DropdownListLayout,
	})

	local DropdownHolderFrame = New("Frame", {
		Size = UDim2.fromScale(1, 0.6),
		ThemeTag = {
			BackgroundColor3 = "DropdownHolder",
		},
	}, {
		DropdownScrollFrame,
		New("UICorner", {
			CornerRadius = UDim.new(0, 7),
		}),
		New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "DropdownBorder",
			},
		}),
		New("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=5554236805",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(23, 23, 277, 277),
			Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(30, 30),
			Position = UDim2.fromOffset(-15, -15),
			ImageColor3 = Color3.fromRGB(0, 0, 0),
			ImageTransparency = 0.1,
		}),
	})

	local DropdownHolderCanvas = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(170, 300),
		Parent = self.Library.GUI,
		Visible = false,
	}, {
		DropdownHolderFrame,
		New("UISizeConstraint", {
			MinSize = Vector2.new(170, 0),
		}),
	})
	table.insert(Library.OpenFrames, DropdownHolderCanvas)

	local function RecalculateListPosition()
		local Add = 0
		if Camera.ViewportSize.Y - DropdownInner.AbsolutePosition.Y < DropdownHolderCanvas.AbsoluteSize.Y - 5 then
			Add = DropdownHolderCanvas.AbsoluteSize.Y
				- 5
				- (Camera.ViewportSize.Y - DropdownInner.AbsolutePosition.Y)
				+ 40
		end
		DropdownHolderCanvas.Position =
			UDim2.fromOffset(DropdownInner.AbsolutePosition.X - 1, DropdownInner.AbsolutePosition.Y - 5 - Add)
	end

	local ListSizeX = 0
	local function RecalculateListSize()
		if #Dropdown.Values > 10 then
			DropdownHolderCanvas.Size = UDim2.fromOffset(ListSizeX, 392)
		else
			DropdownHolderCanvas.Size = UDim2.fromOffset(ListSizeX, DropdownListLayout.AbsoluteContentSize.Y + 10)
		end
	end

	local function RecalculateCanvasSize()
		DropdownScrollFrame.CanvasSize = UDim2.fromOffset(0, DropdownListLayout.AbsoluteContentSize.Y)
	end

	RecalculateListPosition()
	RecalculateListSize()

	Creator.AddSignal(DropdownInner:GetPropertyChangedSignal("AbsolutePosition"), RecalculateListPosition)

	Creator.AddSignal(DropdownInner.MouseButton1Click, function()
		Dropdown:Open()
	end)

	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			local AbsPos, AbsSize = DropdownHolderFrame.AbsolutePosition, DropdownHolderFrame.AbsoluteSize
			if
				Mouse.X < AbsPos.X
				or Mouse.X > AbsPos.X + AbsSize.X
				or Mouse.Y < (AbsPos.Y - 20 - 1)
				or Mouse.Y > AbsPos.Y + AbsSize.Y
			then
				Dropdown:Close()
			end
		end
	end)

	local ScrollFrame = self.ScrollFrame
	function Dropdown:Open()
		Dropdown.Opened = true
		ScrollFrame.ScrollingEnabled = false
		DropdownHolderCanvas.Visible = true
		TweenService:Create(
			DropdownHolderFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = UDim2.fromScale(1, 1) }
		):Play()
	end

	function Dropdown:Close()
		Dropdown.Opened = false
		ScrollFrame.ScrollingEnabled = true
		DropdownHolderFrame.Size = UDim2.fromScale(1, 0.6)
		DropdownHolderCanvas.Visible = false
	end

	function Dropdown:Display()
		local Values = Dropdown.Values
		local Str = ""

		if Config.Multi then
			for Idx, Value in next, Values do
				if Dropdown.Value[Value] then
					Str = Str .. Value .. ", "
				end
			end
			Str = Str:sub(1, #Str - 2)
		else
			Str = Dropdown.Value or ""
		end

		DropdownDisplay.Text = (Str == "" and "--" or Str)
	end

	function Dropdown:GetActiveValues()
		if Config.Multi then
			local T = {}

			for Value, Bool in next, Dropdown.Value do
				table.insert(T, Value)
			end

			return T
		else
			return Dropdown.Value and 1 or 0
		end
	end

	function Dropdown:CreateNewDropdownElement()
	    local ButtonSelector = New("Frame", {
	        Size = UDim2.fromOffset(4, 14),
	        BackgroundColor3 = Color3.fromRGB(76, 194, 255),
	        Position = UDim2.fromOffset(-1, 16),
	        AnchorPoint = Vector2.new(0, 0.5),
	        ThemeTag = { BackgroundColor3 = "Accent" },
	    }, {
	        New("UICorner", { CornerRadius = UDim.new(0, 2) }),
	    })
	
	    local ButtonLabel = New("TextLabel", {
	        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
	        Text = "",
	        TextColor3 = Color3.fromRGB(200, 200, 200),
	        TextSize = 13,
	        TextXAlignment = Enum.TextXAlignment.Left,
	        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	        AutomaticSize = Enum.AutomaticSize.Y,
	        BackgroundTransparency = 1,
	        Size = UDim2.fromScale(1, 1),
	        Position = UDim2.fromOffset(10, 0),
	        Name = "ButtonLabel",
	        ThemeTag = { TextColor3 = "Text" },
	    })
	
	    local Button = New("TextButton", {
	        Size = UDim2.new(1, -5, 0, 32),
	        BackgroundTransparency = 1,
	        ZIndex = 23,
	        Text = "",
	        Parent = DropdownScrollFrame,
	        Visible = false,
	        ThemeTag = { BackgroundColor3 = "DropdownOption" },
	    }, {
	        ButtonSelector,
	        ButtonLabel,
	        New("UICorner", { CornerRadius = UDim.new(0, 6) }),
	    })
	
	    return Button
	end
	
	function Dropdown:CreateDropdownElement(Value, Index)
	    local Button = table.remove(elementPool, 1) or self:CreateNewDropdownElement()
	    Button.ButtonLabel.Text = Value
	    Button.Visible = true
	    Button.LayoutOrder = Index
	    return Button
	end
	
	function Dropdown:BuildDropdownList()
	    local Values = Dropdown.Values
	    local ListSizeX = 0
	
	    -- Clear previous elements using object pooling
	    for _, element in ipairs(DropdownScrollFrame:GetChildren()) do
	        if not element:IsA("UIListLayout") then
	            if element.Name == "PooledElement" then
	                element.Visible = false
	                table.insert(elementPool, element)
	            else
	                element:Destroy()
	            end
	        end
	    end
	
	    -- Calculate the number of pages
	    local totalValues = #Values
	    local totalPages = math.ceil(totalValues / VISIBLE_ITEM_COUNT)
	
	    -- Function to load a specific page of values
	    local function loadPage(page)
	        local startIndex = (page - 1) * VISIBLE_ITEM_COUNT + 1
	        local endIndex = math.min(page * VISIBLE_ITEM_COUNT, totalValues)
	        local pageValues = {}
	
	        for i = startIndex, endIndex do
	            table.insert(pageValues, Values[i])
	        end
	
	        return pageValues
	    end
	
	    -- Function to update the dropdown with the current page values
	    local function updateDropdown(page)
	        local pageValues = loadPage(page)
	        for _, value in pairs(pageValues) do
	            local Button = table.remove(elementPool, 1) or self:CreateDropdownElement(value, _)
	            Button.Name = "PooledElement"
	            Button.LayoutOrder = _
	            ListSizeX = math.max(ListSizeX, Button.ButtonLabel.TextBounds.X + 30)
	        end
	        
	        -- Immediate layout calculations
	        DropdownScrollFrame.CanvasSize = UDim2.fromOffset(0, DropdownListLayout.AbsoluteContentSize.Y)
	        DropdownHolderCanvas.Size = UDim2.fromOffset(
	            ListSizeX,
	            math.min(DropdownListLayout.AbsoluteContentSize.Y + 10, 392)
	        )
	    end
	
	    -- Initial update
	    updateDropdown(1)
	
	    -- Handle scrolling to load more items
	    DropdownScrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	        local currentOffset = DropdownScrollFrame.CanvasPosition.Y
	        local totalHeight = DropdownScrollFrame.CanvasSize.Y.Offset
	
	        if currentOffset + DropdownScrollFrame.AbsoluteSize.Y >= totalHeight - 10 then
	            local nextPage = math.ceil(currentOffset / (VISIBLE_ITEM_COUNT * 30)) + 1
	            if nextPage <= totalPages then
	                updateDropdown(nextPage)
	            end
	        end
	    end)
	end
	
	function Dropdown:SetValues(NewValues)
	    if NewValues then
	        Dropdown.Values = NewValues
	    end
	
	    local totalValues = #Dropdown.Values
	    local pageSize = 50 
	    local currentPage = 1
	    local totalPages = math.ceil(totalValues / pageSize)
	
	   
	    local function loadPage(page)
	        local startIndex = (page - 1) * pageSize + 1
	        local endIndex = math.min(page * pageSize, totalValues)
	        local pageValues = {}
	
	        for i = startIndex, endIndex do
	            table.insert(pageValues, Dropdown.Values[i])
	        end
	
	        return pageValues
	    end
	
	    
	    local function updateDropdown()
	        local pageValues = loadPage(currentPage)
	        Dropdown:BuildDropdownList(pageValues)
	    end
	
	  
	    local function nextPage()
	        if currentPage < totalPages then
	            currentPage = currentPage + 1
	            updateDropdown()
	        end
	    end
	
	    local function previousPage()
	        if currentPage > 1 then
	            currentPage = currentPage - 1
	            updateDropdown()
	        end
	    end
	
	   
	    updateDropdown()
	
	end
	function Dropdown:OnChanged(Func)
		Dropdown.Changed = Func
		Func(Dropdown.Value)
	end

	function Dropdown:SetValue(Val)
		if Dropdown.Multi then
			local nTable = {}

			for Value, Bool in next, Val do
				if table.find(Dropdown.Values, Value) then
					nTable[Value] = true
				end
			end

			Dropdown.Value = nTable
		else
			if not Val then
				Dropdown.Value = nil
			elseif table.find(Dropdown.Values, Val) then
				Dropdown.Value = Val
			end
		end

		Dropdown:BuildDropdownList()

		Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
		Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
	end

	function Dropdown:Destroy()
		DropdownFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Dropdown:BuildDropdownList()
	Dropdown:Display()

	local Defaults = {}

	if type(Config.Default) == "string" then
		local Idx = table.find(Dropdown.Values, Config.Default)
		if Idx then
			table.insert(Defaults, Idx)
		end
	elseif type(Config.Default) == "table" then
		for _, Value in next, Config.Default do
			local Idx = table.find(Dropdown.Values, Value)
			if Idx then
				table.insert(Defaults, Idx)
			end
		end
	elseif type(Config.Default) == "number" and Dropdown.Values[Config.Default] ~= nil then
		table.insert(Defaults, Config.Default)
	end

	if next(Defaults) then
		for i = 1, #Defaults do
			local Index = Defaults[i]
			if Config.Multi then
				Dropdown.Value[Dropdown.Values[Index]] = true
			else
				Dropdown.Value = Dropdown.Values[Index]
			end

			if not Config.Multi then
				break
			end
		end

		Dropdown:BuildDropdownList()
		Dropdown:Display()
	end

	Library.Options[Idx] = Dropdown
	return Dropdown
end

return Element
