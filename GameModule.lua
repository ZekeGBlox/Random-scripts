if not LPH_OBFUSCATED then
    loadstring(game:HttpGet("https://zekehub.com/scripts/Utility/luraphsdk.lua"))()
end

local Services = loadstring(game:HttpGet("https://zekehub.com/scripts/Utility/Services.lua"))();
local HookManager = loadstring(game:HttpGet("https://zekehub.com/scripts/Utility/HookManager.lua"))();
local HookAssigner = loadstring(game:HttpGet("https://zekehub.com/scripts/Utility/HookAssigner.lua"))();

local Players, Workspace, ReplicatedStorage = Services:Get('Players', 'Workspace', 'ReplicatedStorage');
local LocalPlayer = Players.LocalPlayer;
local CurrentCamera = Workspace.CurrentCamera;

local GameModules = {};

--[[
    =====================================
    HOW TO CREATE A CUSTOM MODULE
    =====================================
    
    1. Create a new entry in GameModules using the game's GameId as the key
    2. The module should contain:
        - Name: string (display name)
        - getCharacter(player): function that returns the player's character
        - getHealth(character): function that returns health, maxHealth
        - isFriendly(player): function that returns true if player is on same team
        - getWeapon(player): function that returns equipped weapon name
        - getClosestPlayer(): function that finds closest valid target (optional, uses default if not provided)
        - setupHooks(Client, Shared, hookManager, hooks): function to setup game-specific hooks
        - buildUI(Tabs, Client, Shared): function to add custom UI elements
        - Unload(): function to cleanup hooks when script unloads
    
    IMPORTANT:
    - If setupHooks is defined, the default silent aim will NOT be used
    - Your hooks should handle silent aim logic for that specific game
    - Always use hookManager:hook() for hooks so they can be properly disposed
    - Always implement Unload() to call hookManager:dispose()
    
    EXAMPLE USAGE:
    
    GameModules[YOUR_GAME_ID] = {
        Name = "Your Game Name",
        
        getCharacter = function(player)
            return player.Character;
        end,
        
        getHealth = function(character)
            local humanoid = character and character:FindFirstChildOfClass("Humanoid");
            if humanoid then return humanoid.Health, humanoid.MaxHealth; end;
            return 100, 100;
        end,
        
        isFriendly = function(player)
            return player.Team and player.Team == LocalPlayer.Team;
        end,
        
        getWeapon = function(player)
            local character = player.Character;
            if character then
                local tool = character:FindFirstChildOfClass("Tool");
                if tool then return tool.Name; end;
            end;
            return "Unarmed";
        end,
        
        setupHooks = function(Client, Shared, hookManager, hooks)
            -- Your hook logic here
            -- Use hookManager:hook("HookName", targetFunction, hookFunction)
            -- In hook function, call original with: hooks("HookName", self, ...)
        end,
        
        buildUI = function(Tabs, Client, Shared)
            -- Add custom UI elements
            local customGroup = Tabs.Main:AddLeftGroupbox("Custom Features");
            customGroup:AddToggle("customFeature", {Text = "Custom Feature"});
        end,
        
        Unload = function()
            hookManager:dispose();
        end,
    };
]]

do -- bad business [1168263273]
    local moduleHookManager = HookManager;
    local moduleHooks = HookAssigner:Start(moduleHookManager);
    local TS = nil;
    
    pcall(function()
        local TSModule = require(ReplicatedStorage:WaitForChild("TS", 5));
        if TSModule then
            for _, v in next, getupvalues(TSModule) do
                if typeof(v) == 'table' and getrawmetatable(v) and typeof(rawget(getrawmetatable(v), '__index')) == 'function' then
                    TS = getupvalue(getrawmetatable(v).__index, 1);
                end;
            end;
        end;
    end);
    
    if TS then
        local function GetBulletSpeed()
            if TS and TS.Items then
                for item, controller in next, TS.Items:GetControllers() do
                    if controller.Equipped then
                        local config = TS.Items:GetConfig(item);
                        if config and config.Projectile and config.Projectile.Speed then
                            return config.Projectile.Speed;
                        end;
                    end;
                end;
            end;
            return 2000;
        end;
        
        GameModules[1168263273] = {
            Name = "Bad Business",
            
            getCharacter = function(player)
                if TS and TS.Characters then
                    local char = TS.Characters:GetCharacter(player);
                    if char and char.Body then return char.Body; end;
                end;
                return player.Character;
            end,
            
            getHealth = function(character)
                local humanoid = character and character:FindFirstChildOfClass("Humanoid");
                if humanoid then return humanoid.Health, humanoid.MaxHealth; end;
                return 100, 100;
            end,
            
            isFriendly = function(player)
                if TS and TS.Teams then
                    local localTeam = TS.Teams:GetPlayerTeam(LocalPlayer);
                    local playerTeam = TS.Teams:GetPlayerTeam(player);
                    return localTeam and playerTeam and localTeam == playerTeam;
                end;
                return player.Team and player.Team == LocalPlayer.Team;
            end,
            
            getWeapon = function(player)
                if TS and TS.Items then
                    for item, controller in next, TS.Items:GetControllers() do
                        if controller.Equipped and controller.Owner == player then
                            return item.Name or "Unknown";
                        end;
                    end;
                end;
                return "Unarmed";
            end,
            
            getClosestPlayer = function(Client, Shared)
                local center = CurrentCamera.ViewportSize / 2;
                local closestPlayer, closestDistance, closestPart = nil, Shared.fovRadius, nil;
                
                for _, player in next, Players:GetPlayers() do
                    if player == LocalPlayer then continue; end;
                    
                    local character = nil;
                    if TS and TS.Characters then
                        local char = TS.Characters:GetCharacter(player);
                        if char and char.Body then character = char.Body; end;
                    end;
                    if not character then character = player.Character; end;
                    if not character then continue; end;
                    
                    local humanoid = character:FindFirstChildOfClass("Humanoid");
                    if not humanoid or humanoid.Health <= 0 then continue; end;
                    
                    if Shared.teamCheck then
                        if TS and TS.Teams then
                            local localTeam = TS.Teams:GetPlayerTeam(LocalPlayer);
                            local playerTeam = TS.Teams:GetPlayerTeam(player);
                            if localTeam and playerTeam and localTeam == playerTeam then continue; end;
                        end;
                    end;
                    
                    local targetPart = character:FindFirstChild(Shared.hitbox) or character:FindFirstChild("Head");
                    if not targetPart then continue; end;
                    
                    local worldDistance = (CurrentCamera.CFrame.Position - targetPart.Position).Magnitude;
                    if worldDistance > Shared.maxDistance then continue; end;
                    
                    local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(targetPart.Position);
                    if not onScreen then continue; end;
                    
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude;
                    
                    if Shared.visibleCheck then
                        local params = RaycastParams.new();
                        params.FilterType = Enum.RaycastFilterType.Exclude;
                        params.FilterDescendantsInstances = {CurrentCamera, LocalPlayer.Character, character};
                        local result = Workspace:Raycast(CurrentCamera.CFrame.Position, (targetPart.Position - CurrentCamera.CFrame.Position).Unit * 5000, params);
                        if result then continue; end;
                    end;
                    
                    if distance < closestDistance then 
                        closestDistance = distance; 
                        closestPlayer = player; 
                        closestPart = targetPart; 
                    end;
                end;
                
                Client.silentTarget.player = closestPlayer;
                Client.silentTarget.part = closestPart;
                Client.silentTarget.distance = closestDistance;
                return closestPlayer;
            end,
            
            setupHooks = function(Client, Shared, hookManager, hooks)
                if TS.Projectiles and TS.Projectiles.InitProjectile then
                    moduleHookManager:hook("BB_InitProjectile", TS.Projectiles.InitProjectile, LPH_NO_VIRTUALIZE(function(self, projectileType, position, direction, owner, ...)
                        if typeof(position) ~= "Vector3" or typeof(direction) ~= "Vector3" then
                            return moduleHooks("BB_InitProjectile", self, projectileType, position, direction, owner, ...);
                        end;
                        
                        local newDirection = direction;
                        
                        if owner == LocalPlayer then
                            if Toggles.silentAimEnabled and Toggles.silentAimEnabled.Value then
                                local chance = math.random(0, 100);
                                if chance <= (Options.silentAimHitChance and Options.silentAimHitChance.Value or 100) then
                                    GameModules[1168263273].getClosestPlayer(Client, Shared);
                                    
                                    if Client.silentTarget.part then
                                        local targetPos = Client.silentTarget.part.Position;
                                        
                                        if Shared.prediction then
                                            local bulletSpeed = GetBulletSpeed();
                                            local velocity = Client.silentTarget.part.AssemblyLinearVelocity or Vector3.zero;
                                            local dist = (targetPos - position).Magnitude;
                                            local timeToTarget = dist / bulletSpeed;
                                            targetPos = targetPos + (velocity * timeToTarget);
                                        end;
                                        
                                        newDirection = (targetPos - position).Unit;
                                    end;
                                end;
                            end;
                        end;
                        
                        return moduleHooks("BB_InitProjectile", self, projectileType, position, newDirection, owner, ...);
                    end));
                end;
                
                if TS.Camera and TS.Camera.Recoil and TS.Camera.Recoil.Fire then
                    moduleHookManager:hook("BB_RecoilFire", TS.Camera.Recoil.Fire, LPH_NO_VIRTUALIZE(function(self, ...)
                        if Toggles.noRecoil and Toggles.noRecoil.Value then return; end;
                        return moduleHooks("BB_RecoilFire", self, ...);
                    end));
                end;
                
                if TS.Input and TS.Input.Reticle and TS.Input.Reticle.Choke then
                    moduleHookManager:hook("BB_Choke", TS.Input.Reticle.Choke, LPH_NO_VIRTUALIZE(function(self, ...)
                        if Toggles.noSpread and Toggles.noSpread.Value then return Vector3.zero; end;
                        return moduleHooks("BB_Choke", self, ...);
                    end));
                end;
                
                if TS.Input and TS.Input.Reticle and TS.Input.Reticle.LookVector then
                    moduleHookManager:hook("BB_LookVector", TS.Input.Reticle.LookVector, LPH_NO_VIRTUALIZE(function(self, choke, ...)
                        if Toggles.noSpread and Toggles.noSpread.Value then
                            choke = 0;
                        end;
                        return moduleHooks("BB_LookVector", self, choke, ...);
                    end));
                end;
            end,
            
            buildUI = function(Tabs, Client, Shared)
                local gunModsGroup = Tabs.Main:AddLeftGroupbox("Gun Mods");
                gunModsGroup:AddToggle("noRecoil", {Text = "No Recoil"});
                gunModsGroup:AddToggle("noSpread", {Text = "No Spread"});
            end,
            
            Unload = function()
                moduleHookManager:dispose();
            end,
        };
    end;
end;

--[[
    =====================================
    EXAMPLE MODULE TEMPLATE (COMMENTED)
    =====================================
    
    Copy and modify this template for new games:
    
    do -- your game [GAME_ID]
        local moduleHookManager = HookManager;
        local moduleHooks = HookAssigner:Start(moduleHookManager);
        
        -- Get game-specific modules here
        local SomeGameModule = nil;
        pcall(function()
            SomeGameModule = require(path.to.module);
        end);
        
        if SomeGameModule then
            GameModules[YOUR_GAME_ID] = {
                Name = "Your Game Name",
                
                getCharacter = function(player)
                    -- Return the player's character
                    -- Modify this for games with custom character systems
                    return player.Character;
                end,
                
                getHealth = function(character)
                    -- Return health, maxHealth
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid");
                    if humanoid then return humanoid.Health, humanoid.MaxHealth; end;
                    return 100, 100;
                end,
                
                isFriendly = function(player)
                    -- Return true if player is friendly/teammate
                    return player.Team and player.Team == LocalPlayer.Team;
                end,
                
                getWeapon = function(player)
                    -- Return equipped weapon name
                    local character = player.Character;
                    if character then
                        local tool = character:FindFirstChildOfClass("Tool");
                        if tool then return tool.Name; end;
                    end;
                    return "Unarmed";
                end,
                
                getClosestPlayer = function(Client, Shared)
                    -- Optional: Custom target finding logic
                    -- If not provided, uses DefaultModule.getClosestPlayer
                    -- Must update Client.silentTarget.player, Client.silentTarget.part, Client.silentTarget.distance
                end,
                
                setupHooks = function(Client, Shared, hookManager, hooks)
                    -- Setup your game-specific hooks here
                    -- Use moduleHookManager:hook("HookName", target, callback)
                    -- Call original with: moduleHooks("HookName", self, ...)
                    
                    -- Example:
                    -- moduleHookManager:hook("MyHook", SomeGameModule.SomeFunction, function(self, ...)
                    --     if Toggles.silentAimEnabled and Toggles.silentAimEnabled.Value then
                    --         -- Modify args for silent aim
                    --     end;
                    --     return moduleHooks("MyHook", self, ...);
                    -- end);
                end,
                
                buildUI = function(Tabs, Client, Shared)
                    -- Add custom UI elements for this game
                    local customGroup = Tabs.Main:AddLeftGroupbox("Game Features");
                    customGroup:AddToggle("customToggle", {Text = "Custom Toggle"});
                    customGroup:AddSlider("customSlider", {Text = "Custom Slider", Min = 0, Max = 100, Default = 50, Rounding = 0});
                end,
                
                Unload = function()
                    moduleHookManager:dispose();
                end,
            };
        end;
    end;
]]

return GameModules;
