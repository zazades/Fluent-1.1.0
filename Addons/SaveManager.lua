local HttpService = game:GetService("HttpService")

local SaveManager = {} do
    SaveManager.Folder = "FluentSettings"
    SaveManager.Ignore = {}
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object)
                return { type = "Toggle", idx = idx, value = object.Value }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValue(data.value)
                end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type = "Slider", idx = idx, value = tostring(object.Value) }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValue(data.value)
                end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return { type = "Dropdown", idx = idx, value = object.Value, multi = object.Multi }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValue(data.value)
                end
            end,
        },
        Colorpicker = {
            Save = function(idx, object)
                return { type = "Colorpicker", idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
                end
            end,
        },
        Keybind = {
            Save = function(idx, object)
                return { type = "Keybind", idx = idx, mode = object.Mode, key = object.Value }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] then
                    SaveManager.Options[idx]:SetValue(data.key, data.mode)
                end
            end,
        },
        Input = {
            Save = function(idx, object)
                return { type = "Input", idx = idx, text = object.Value }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] and type(data.text) == "string" then
                    SaveManager.Options[idx]:SetValue(data.text)
                end
            end,
        },
    }

    function SaveManager:SetIgnoreIndexes(list)
        for _, key in next, list do
            self.Ignore[key] = true
        end
    end

    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function SaveManager:Save(name)
        if not name then
            return false, "No config file is selected"
        end
    
        local fullPath = self.Folder .. "/settings/" .. name .. ".json"
        local data = { objects = {} }
    
        -- Save each option based on its type
        for idx, option in next, SaveManager.Options do
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end
    
            table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
        end
    
        -- Encode data to JSON
        local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if not success then
            return false, "Failed to encode data"
        end
    
        -- Write the encoded data to a file
        local writeSuccess, writeError = pcall(writefile, fullPath, encoded)
        if not writeSuccess then
            return false, "Failed to write file: " .. writeError
        end
    
        return true
    end

   function SaveManager:Load(name)
        if not name then
            return false, "No config file is selected"
        end

        local file = self.Folder .. "/settings/" .. name .. ".json"
        if not isfile(file) then return false, "Invalid file" end

        local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(file))
        if not success then return false, "Decode error" end

        for _, option in next, decoded.objects do
            if self.Parser[option.type] then
                task.spawn(function()
                    self.Parser[option.type].Load(option.idx, option)
                end) -- task.spawn() so the config loading won't get stuck.
            end
        end

        -- Implement pagination or lazy loading for dropdown values
        local loadedValues = decoded.objects -- Assume this contains your 1500+ CFrames

        -- Define pagination variables
        local pageSize = 50 -- Number of items per page
        local currentPage = 1
        local totalPages = math.ceil(#loadedValues / pageSize)

        -- Function to load a specific page of values
        local function loadPage(page)
            local startIndex = (page - 1) * pageSize + 1
            local endIndex = math.min(page * pageSize, #loadedValues)
            local pageValues = {}

            for i = startIndex, endIndex do
                table.insert(pageValues, loadedValues[i].idx) -- Use whatever identifier you need for dropdown
            end

            return pageValues
        end

        -- Function to update the dropdown with the current page values
        local function updateDropdown()
            local pageValues = loadPage(currentPage)
            -- Assuming Dropdown is your dropdown object
            Dropdown:SetValues(pageValues)
        end

        -- Implement next and previous page functions
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

        -- Initial update
        updateDropdown()

        -- Bind pagination functions to UI elements or buttons
        -- Assuming you have buttons or some method to trigger pagination
        -- nextButton.MouseButton1Click:Connect(nextPage)
        -- prevButton.MouseButton1Click:Connect(previousPage)

        return true
    end

    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            "InterfaceTheme", "AcrylicToggle", "TransparentToggle", "MenuKeybind"
        })
    end

    function SaveManager:BuildFolderTree()
        local paths = {
            self.Folder,
            self.Folder .. "/settings"
        }

        for i = 1, #paths do
            local str = paths[i]
            if not isfolder(str) then
                makefolder(str)
            end
        end
    end

    function SaveManager:RefreshConfigList()
        local list = listfiles(self.Folder .. "/settings")
        local out = {}

        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == ".json" then
                local name = file:match("([^/\\]+)%.json$")
                if name ~= "options" then
                    table.insert(out, name)
                end
            end
        end

        return out
    end

    function SaveManager:SetLibrary(library)
        self.Library = library
        self.Options = library.Options
    end

    function SaveManager:LoadAutoloadConfig()
        if isfile(self.Folder .. "/settings/autoload.txt") then
            local name = readfile(self.Folder .. "/settings/autoload.txt")

            local success, err = self:Load(name)
            if not success then
                return self.Library:Notify({
                    Title = "Interface",
                    Content = "Config loader",
                    SubContent = "Failed to load autoload config: " .. err,
                    Duration = 7
                })
            end

            self.Library:Notify({
                Title = "Interface",
                Content = "Config loader",
                SubContent = string.format("Auto loaded config %q", name),
                Duration = 7
            })
        end
    end

    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, "Must set SaveManager.Library")

        local section = tab:AddSection("Configuration")
        section:AddInput("SaveManager_ConfigName", { Title = "Config name" })
        section:AddDropdown("SaveManager_ConfigList", { Title = "Config list", Values = self:RefreshConfigList(), AllowNull = true })

        section:AddButton({
            Title = "Create config",
            Callback = function()
                local name = SaveManager.Options.SaveManager_ConfigName.Value

                if name:gsub(" ", "") == "" then
                    return self.Library:Notify({
                        Title = "Interface",
                        Content = "Config loader",
                        SubContent = "Invalid config name (empty)",
                        Duration = 7
                    })
                end

                local success, err = self:Save(name)
                if not success then
                    return self.Library:Notify({
                        Title = "Interface",
                        Content = "Config loader",
                        SubContent = "Failed to save config: " .. err,
                        Duration = 7
                    })
                end

                self.Library:Notify({
                    Title = "Interface",
                    Content = "Config loader",
                    SubContent = string.format("Created config %q", name),
                    Duration = 7
                })

                SaveManager.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                SaveManager.Options.SaveManager_ConfigList:SetValue(nil)
            end
        })

        section:AddButton({
            Title = "Load config",
            Callback = function()
                local name = SaveManager.Options.SaveManager_ConfigList.Value

                local success, err = self:Load(name)
                if not success then
                    return self.Library:Notify({
                        Title = "Interface",
                        Content = "Config loader",
                        SubContent = "Failed to load config: " .. err,
                        Duration = 7
                    })
                end

                self.Library:Notify({
                    Title = "Interface",
                    Content = "Config loader",
                    SubContent = string.format("Loaded config %q", name),
                    Duration = 7
                })
            end
        })

        section:AddButton({
            Title = "Overwrite config",
            Callback = function()
                local name = SaveManager.Options.SaveManager_ConfigList.Value

                local success, err = self:Save(name)
                if not success then
                    return self.Library:Notify({
                        Title = "Interface",
                        Content = "Config loader",
                        SubContent = "Failed to overwrite config: " .. err,
                        Duration = 7
                    })
                end

                self.Library:Notify({
                    Title = "Interface",
                    Content = "Config loader",
                    SubContent = string.format("Overwrote config %q", name),
                    Duration = 7
                })
            end
        })

        section:AddButton({
            Title = "Refresh list",
            Callback = function()
                SaveManager.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
                SaveManager.Options.SaveManager_ConfigList:SetValue(nil)
            end
        })

        local AutoloadButton
        AutoloadButton = section:AddButton({
            Title = "Set as autoload",
            Description = "Current autoload config: none",
            Callback = function()
                local name = SaveManager.Options.SaveManager_ConfigList.Value
                writefile(self.Folder .. "/settings/autoload.txt", name)
                AutoloadButton:SetDesc("Current autoload config: " .. name)
                self.Library:Notify({
                    Title = "Interface",
                    Content = "Config loader",
                    SubContent = string.format("Set %q to auto load", name),
                    Duration = 7
                })
            end
        })

        if isfile(self.Folder .. "/settings/autoload.txt") then
            local name = readfile(self.Folder .. "/settings/autoload.txt")
            AutoloadButton:SetDesc("Current autoload config: " .. name)
        end

        SaveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
    end

    SaveManager:BuildFolderTree()
end

return SaveManager
