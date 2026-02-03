-- Kalas i will split these into multiple files later on LOL once i make the bundler for it
if not LPH_OBFUSCATED then
    LPH_NO_VIRTUALIZE = function(f) return f end;
    LPH_JIT = function(f) return f end;
    LPH_CRASH = function() while true do end end;
end;

local Services = loadstring(game:HttpGet("https://zekehub.com/scripts/Utility/Services.lua"))();

local Players, Workspace, ReplicatedStorage, RunService = Services:Get('Players', 'Workspace', 'ReplicatedStorage', 'RunService');
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
        - getClosestPlayer(Client, Shared): function that finds closest valid target
        - setupHooks(Client, Shared, hookManager, hooks): function to setup game-specific hooks
        - buildUI(Tabs, Client, Shared): function to add custom UI elements
        - Unload(): function to cleanup when script unloads
    
    IMPORTANT:
    - If setupHooks is defined, the default silent aim will NOT be used
    - Your hooks should handle silent aim logic for that specific game
    - Always use hookManager:hook() for hooks so they can be properly disposed
    
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
        end,
        
        buildUI = function(Tabs, Client, Shared)
            local customGroup = Tabs.Main:AddLeftGroupbox("Custom Features");
            customGroup:AddToggle("customFeature", {Text = "Custom Feature"});
        end,
        
        Unload = function()
        end,
    };
]]

do -- bad business [1168263273]
    if game.GameId == 1168263273 then
        local TS = nil;
        local storedClient = nil;
        local storedShared = nil;

        do -- anti-crash
            local sc = game:GetService("ScriptContext"); 
            for _, c in next, getconnections(sc.Error) do
                if type(c.Function) == "function" then
                    for i, v in next, debug.getupvalues(c.Function) do
                        if type(v) == "number" and tostring(v):find("%.") then
                            task.spawn(function()
                                while task.wait(1) do debug.setupvalue(c.Function, i, os.clock()) end;
                            end);
                        end;
                    end;
                end;
            end;
        end;

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
                if not TS.Items then return 2000; end;
                for item, controller in next, TS.Items:GetControllers() do
                    if controller.Equipped then
                        local config = TS.Items:GetConfig(item);
                        if config and config.Projectile and config.Projectile.Speed then
                            return config.Projectile.Speed;
                        end;
                    end;
                end;
                return 2000;
            end;
            
            local function GetCharacterModel(player)
                if not TS or not TS.Characters then return nil; end;
                local char = nil;
                pcall(function()
                    char = TS.Characters:GetCharacter(player);
                end);
                if not char or not char.Parent then return nil; end;
                return char;
            end;
            
            local function GetCharacterBody(player)
                local char = GetCharacterModel(player);
                if not char then return nil; end;
                local body = char:FindFirstChild("Body");
                if body and body.Parent then
                    return body;
                end;
                return nil;
            end;
            
            local function GetHealthFromModel(charModel)
                if not charModel then return 0, 100; end;
                local health = charModel:FindFirstChild("Health");
                if health then
                    local currentHealth = health.Value or 0;
                    local maxHealthObj = health:FindFirstChild("MaxHealth");
                    local maxHealthValue = maxHealthObj and maxHealthObj.Value or 100;
                    return currentHealth, maxHealthValue;
                end;
                return 100, 100;
            end;
            
            local function IsFriendly(player)
                if TS and TS.Teams then
                    local success, result = pcall(function()
                        local localTeam = TS.Teams:GetPlayerTeam(LocalPlayer);
                        local playerTeam = TS.Teams:GetPlayerTeam(player);
                        return localTeam and playerTeam and localTeam == playerTeam;
                    end);
                    if success then return result; end;
                end;
                return player.Team and player.Team == LocalPlayer.Team;
            end;
            
            local function GetWeaponForPlayer(player)
                if TS and TS.Items then
                    local success, result = pcall(function()
                        for item, controller in next, TS.Items:GetControllers() do
                            if controller.Equipped and controller.Owner == player then
                                local config = TS.Items:GetConfig(item);
                                if config and config.Name then
                                    return config.Name;
                                end;
                                return item.Name or "Unknown";
                            end;
                        end;
                        return "Unarmed";
                    end);
                    if success then return result; end;
                end;
                return "Unarmed";
            end;
            
            GameModules[1168263273] = {
                Name = "Bad Business",
                
                getCharacter = function(player)
                    return GetCharacterBody(player);
                end,
                
                getHealth = function(character)
                    if not character then return 0, 100; end;
                    if character.Name == "Body" and character.Parent then
                        return GetHealthFromModel(character.Parent);
                    end;
                    if character:FindFirstChild("Health") then
                        return GetHealthFromModel(character);
                    end;
                    if character.Parent and character.Parent:FindFirstChild("Health") then
                        return GetHealthFromModel(character.Parent);
                    end;
                    return 100, 100;
                end,
                
                isFriendly = function(player)
                    return IsFriendly(player);
                end,
                
                getWeapon = function(player)
                    return GetWeaponForPlayer(player);
                end,
                
                getClosestPlayer = function(Client, Shared)
                    local client = Client or storedClient;
                    local shared = Shared or storedShared;
                    if not client or not shared then return nil; end;
                    
                    CurrentCamera = Workspace.CurrentCamera;
                    local mousePos = game:GetService("UserInputService"):GetMouseLocation();
                    local closestPlayer, closestDistance, closestPart = nil, shared.fovRadius or 150, nil;
                    
                    for _, player in next, Players:GetPlayers() do
                        if player == LocalPlayer then continue; end;
                        
                        local body = GetCharacterBody(player);
                        if not body then continue; end;
                        
                        local charModel = body.Parent;
                        local health, _ = GetHealthFromModel(charModel);
                        if health <= 0 then continue; end;
                        
                        if shared.teamCheck and IsFriendly(player) then continue; end;
                        
                        local targetPart = body:FindFirstChild(shared.hitbox or "Head") or body:FindFirstChild("Head") or body:FindFirstChild("Chest");
                        if not targetPart then continue; end;
                        
                        local worldDistance = (CurrentCamera.CFrame.Position - targetPart.Position).Magnitude;
                        if worldDistance > (shared.maxDistance or 500) then continue; end;
                        
                        local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(targetPart.Position);
                        if not onScreen then continue; end;
                        
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude;
                        
                        if distance > (shared.fovRadius or 150) then continue; end;
                        
                        if shared.visibleCheck then
                            local myChar = GetCharacterModel(LocalPlayer);
                            local params = RaycastParams.new();
                            params.FilterType = Enum.RaycastFilterType.Exclude;
                            params.FilterDescendantsInstances = {CurrentCamera, LocalPlayer.Character, charModel, myChar};
                            local result = Workspace:Raycast(CurrentCamera.CFrame.Position, (targetPart.Position - CurrentCamera.CFrame.Position).Unit * worldDistance, params);
                            if result then continue; end;
                        end;
                        
                        if distance < closestDistance then
                            closestDistance = distance;
                            closestPlayer = player;
                            closestPart = targetPart;
                        end;
                    end;
                    
                    client.silentTarget.player = closestPlayer;
                    client.silentTarget.part = closestPart;
                    client.silentTarget.distance = closestDistance;
                    return closestPlayer;
                end,
                
                setupHooks = function(Client, Shared, hookManager, hooks)
                    storedClient = Client;
                    storedShared = Shared;
                    
                    local thisModule = GameModules[1168263273];
                    
                    hookManager:hook("BB_InitProjectile", TS.Projectiles.InitProjectile, LPH_NO_VIRTUALIZE(function(self, ...)
                        local args = {...};
                        
                        if #args >= 4 and args[4] == LocalPlayer then
                            if Toggles and Toggles.silentAimEnabled and Toggles.silentAimEnabled.Value then
                                local hitChance = 100;
                                if Options and Options.silentAimHitChance then
                                    hitChance = Options.silentAimHitChance.Value or 100;
                                end;
                                
                                local chance = math.random(0, 100);
                                if chance <= hitChance then
                                    thisModule.getClosestPlayer(Client, Shared);
                                    
                                    if Client.silentTarget.part then
                                        local origin = args[2];
                                        local bulletSpeed = GetBulletSpeed();
                                        local targetPart = Client.silentTarget.part;
                                        local velocity = targetPart.AssemblyLinearVelocity or Vector3.zero;
                                        local distance = (targetPart.Position - origin).Magnitude;
                                        local timeToTarget = distance / bulletSpeed;
                                        local predictedPos = targetPart.Position + (velocity * timeToTarget);
                                        args[3] = (predictedPos - origin).Unit;
                                    end;
                                end;
                            end;
                        end;
                        
                        local result = hooks.BB_InitProjectile(self, unpack(args));
                        
                        if result and type(result) == "table" then
                            if Toggles and Toggles.noGravity and Toggles.noGravity.Value then
                                result.Gravity = 0;
                            end;
                            if Toggles and Toggles.bulletSpeed and Toggles.bulletSpeed.Value then
                                if result.Velocity then
                                    local multiplier = 10;
                                    if Options and Options.bulletSpeedMultiplier then
                                        multiplier = Options.bulletSpeedMultiplier.Value or 10;
                                    end;
                                    result.Velocity = result.Velocity.Unit * (result.Velocity.Magnitude * multiplier);
                                end;
                            end;
                        end;
                        
                        return result;
                    end));
                    
                    if TS.Camera and TS.Camera.Recoil and TS.Camera.Recoil.Fire then
                        hookManager:hook("BB_RecoilFire", TS.Camera.Recoil.Fire, LPH_NO_VIRTUALIZE(function(self, ...)
                            if Toggles and Toggles.noRecoil and Toggles.noRecoil.Value then return; end;
                            return hooks.BB_RecoilFire(self, ...);
                        end));
                    end;
                    
                    if TS.Input and TS.Input.Reticle and TS.Input.Reticle.LookVector then
                        hookManager:hook("BB_LookVector", TS.Input.Reticle.LookVector, LPH_NO_VIRTUALIZE(function(self, ...)
                            local args = {...};
                            if Toggles and Toggles.noSpread and Toggles.noSpread.Value then
                                if #args > 0 then
                                    args[1] = 0;
                                end;
                            end;
                            return hooks.BB_LookVector(self, unpack(args));
                        end));
                    end;
                    
                    if TS.Input and TS.Input.Reticle and TS.Input.Reticle.Choke then
                        hookManager:hook("BB_Choke", TS.Input.Reticle.Choke, LPH_NO_VIRTUALIZE(function(self, ...)
                            if Toggles and Toggles.noSpread and Toggles.noSpread.Value then
                                return Vector3.zero;
                            end;
                            return hooks.BB_Choke(self, ...);
                        end));
                    end;
                end,
                
                buildUI = function(Tabs, Client, Shared)
                    local gunModsGroup = Tabs.Main:AddLeftGroupbox("Gun Mods");
                    gunModsGroup:AddToggle("noRecoil", {Text = "No Recoil"});
                    gunModsGroup:AddToggle("noSpread", {Text = "No Spread"});
                    gunModsGroup:AddToggle("noGravity", {Text = "No Bullet Drop"});
                    gunModsGroup:AddToggle("bulletSpeed", {Text = "Bullet Speed"});
                    local bulletSpeedSettings = gunModsGroup:AddDependencyBox();
                    bulletSpeedSettings:AddSlider("bulletSpeedMultiplier", {Text = "Multiplier", Min = 1, Max = 20, Default = 10, Rounding = 0});
                    bulletSpeedSettings:SetupDependencies({{Toggles.bulletSpeed, true}});
                end,
                
                Unload = function()
                    storedClient = nil;
                    storedShared = nil;
                end,
            };
        end;
    end;
end;

do -- base battles [1865489894]
    if game.GameId == 1865489894 then
        local Libraries = ReplicatedStorage:WaitForChild("Libraries", 5);
        local Weapon = require(Libraries:WaitForChild("Weapon"));
        local Global = require(Libraries:WaitForChild("Global"));
        local Gameplay = require(Libraries:WaitForChild("Gameplay"));
        
        local function GetPlayerTeam(player)
            return Global.Teams and Global.Teams[player];
        end;
        
        local function PredictPosition(targetPart, origin)
            local velocity = targetPart.AssemblyLinearVelocity or Vector3.zero;
            local distance = (targetPart.Position - origin).Magnitude;
            local equippedWeapon = Weapon.GetEquippedWeapon(LocalPlayer);
            local projectileSpeed = equippedWeapon and equippedWeapon.config and equippedWeapon.config.projectileVelocity or 1000;
            local timeToHit = distance / projectileSpeed;
            return targetPart.Position + (velocity * timeToHit);
        end;
        
        GameModules[1865489894] = {
            Name = "Base Battles",
            
            getCharacter = function(player)
                return player.Character;
            end,
            
            getHealth = function(character)
                local humanoid = character and character:FindFirstChildOfClass("Humanoid");
                if humanoid then return humanoid.Health, humanoid.MaxHealth; end;
                return 100, 100;
            end,
            
            isFriendly = function(player)
                return GetPlayerTeam(player) == GetPlayerTeam(LocalPlayer);
            end,
            
            getWeapon = function(player)
                local equipped = Weapon.GetEquippedWeapon(player);
                if equipped and equipped.config then return equipped.config.Name or "Unknown"; end;
                return "Unarmed";
            end,
            
            getClosestPlayer = function(Client, Shared)
                local mousePos = game:GetService("UserInputService"):GetMouseLocation();
                local closestPlayer, closestDistance, closestPart = nil, Shared.fovRadius, nil;
                
                for _, player in next, Players:GetPlayers() do
                    if player == LocalPlayer then continue; end;
                    local character = player.Character;
                    if not character then continue; end;
                    
                    local humanoid = character:FindFirstChildOfClass("Humanoid");
                    if not humanoid or humanoid.Health <= 0 then continue; end;
                    if Shared.teamCheck and GetPlayerTeam(player) == GetPlayerTeam(LocalPlayer) then continue; end;
                    
                    local targetPart = character:FindFirstChild(Shared.hitbox) or character:FindFirstChild("Head");
                    if not targetPart then continue; end;
                    
                    local worldDistance = (CurrentCamera.CFrame.Position - targetPart.Position).Magnitude;
                    if worldDistance > Shared.maxDistance then continue; end;
                    
                    local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(targetPart.Position);
                    if not onScreen then continue; end;
                    
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude;
                    if distance > Shared.fovRadius then continue; end;
                    
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
                local thisModule = GameModules[1865489894];
                
                hookManager:hook("BaseBattles_CastMouseRay", Gameplay.CastMouseRay, LPH_NO_VIRTUALIZE(function(distance, ignoreList, ignoreFunc, bloom)
                    local result = hooks.BaseBattles_CastMouseRay(distance, ignoreList, ignoreFunc, bloom);
                    
                    if Toggles.silentAimEnabled and Toggles.silentAimEnabled.Value then
                        if math.random(0, 100) <= (Options.silentAimHitChance and Options.silentAimHitChance.Value or 100) then
                            thisModule.getClosestPlayer(Client, Shared);
                            if Client.silentTarget.part then
                                local origin = Workspace.CurrentCamera.CFrame.Position;
                                return { Position = PredictPosition(Client.silentTarget.part, origin) };
                            end;
                        end;
                    end;
                    
                    return result;
                end));
                
                hookManager:hook("BaseBattles_GetDir", Gameplay.GetDir, LPH_NO_VIRTUALIZE(function(player, bloom, originCFrame, ignoreList)
                    local origin, direction = hooks.BaseBattles_GetDir(player, bloom, originCFrame, ignoreList);
                    
                    if player == LocalPlayer and Toggles.silentAimEnabled and Toggles.silentAimEnabled.Value then
                        if math.random(0, 100) <= (Options.silentAimHitChance and Options.silentAimHitChance.Value or 100) then
                            thisModule.getClosestPlayer(Client, Shared);
                            if Client.silentTarget.part then
                                direction = (PredictPosition(Client.silentTarget.part, origin) - origin).Unit;
                            end;
                        end;
                    end;
                    
                    return origin, direction;
                end));
            end,
            
            buildUI = function(Tabs, Client, Shared)
            end,
            
            Unload = function()
            end,
        };
    end;
end;

do -- flick [8795154789]
    if game.GameId == 8795154789 then
        local BulletHandler = require(ReplicatedStorage.ModuleScripts.GunModules.BulletHandler);

        GameModules[8795154789] = {
            Name = "Flick",

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
            
            getClosestPlayer = function(Client, Shared)
                local mousePos = game:GetService("UserInputService"):GetMouseLocation();
                local closestPlayer, closestDistance, closestPart = nil, Shared.fovRadius, nil;
                
                for _, player in next, Players:GetPlayers() do
                    if player == LocalPlayer then continue; end;
                    local character = player.Character;
                    if not character then continue; end;
                    
                    local humanoid = character:FindFirstChildOfClass("Humanoid");
                    if not humanoid or humanoid.Health <= 0 then continue; end;
                    if Shared.teamCheck and player.Team and player.Team == LocalPlayer.Team then continue; end;
                    
                    local targetPart = character:FindFirstChild(Shared.hitbox) or character:FindFirstChild("Head");
                    if not targetPart then continue; end;
                    
                    local worldDistance = (CurrentCamera.CFrame.Position - targetPart.Position).Magnitude;
                    if worldDistance > Shared.maxDistance then continue; end;
                    
                    local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(targetPart.Position);
                    if not onScreen then continue; end;
                    
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude;
                    if distance > Shared.fovRadius then continue; end;
                    
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
                local thisModule = GameModules[8795154789];
                
                hookManager:hook("Flick_BulletFire", BulletHandler.Fire, LPH_NO_VIRTUALIZE(function(data)
                    local info = debug.getinfo(2, "f");
                    if info and info.func then
                        local upvalues = debug.getupvalues(info.func);
                        if upvalues and #upvalues >= 3 then
                            local gunConfig = upvalues[3];
                            if gunConfig and type(gunConfig) == "table" then
                                if Toggles.noSpread and Toggles.noSpread.Value then
                                    gunConfig.spread = 0;
                                end;
                                if Toggles.noRecoil and Toggles.noRecoil.Value then
                                    gunConfig.Recoil = Vector3.zero;
                                end;
                                if Toggles.rapidFire and Toggles.rapidFire.Value then
                                    gunConfig.FireRate = Options.fireRateValue and Options.fireRateValue.Value or 0.001;
                                end;
                                debug.setupvalue(info.func, 3, gunConfig);
                            end;
                        end;
                    end;
                    
                    if Toggles.silentAimEnabled and Toggles.silentAimEnabled.Value then
                        if math.random(0, 100) <= (Options.silentAimHitChance and Options.silentAimHitChance.Value or 100) then
                            thisModule.getClosestPlayer(Client, Shared);
                            if Client.silentTarget.part then
                                data.Direction = (Client.silentTarget.part.Position - data.Origin).Unit;
                            end;
                        end;
                    end;
                    
                    return hooks.Flick_BulletFire(data);
                end));
            end,
            
            buildUI = function(Tabs, Client, Shared)
                local gunModsGroup = Tabs.Main:AddLeftGroupbox("Gun Mods");
                gunModsGroup:AddToggle("noRecoil", {Text = "No Recoil"});
                gunModsGroup:AddToggle("noSpread", {Text = "No Spread"});
                gunModsGroup:AddToggle("rapidFire", {Text = "Rapid Fire"});
                local rapidFireSettings = gunModsGroup:AddDependencyBox();
                rapidFireSettings:AddSlider("fireRateValue", {Text = "Fire Rate", Min = 0.001, Max = 0.5, Default = 0.001, Rounding = 3});
                rapidFireSettings:SetupDependencies({{Toggles.rapidFire, true}});
            end,
            
            Unload = function()
            end,
        };
    end;
end;

--[[
    =====================================
    MODULE TEMPLATE
    =====================================
    
    do -- your game [GAME_ID]
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
            
            getClosestPlayer = function(Client, Shared)
                -- Custom target finding
            end,
            
            setupHooks = function(Client, Shared, hookManager, hooks)
                -- Custom hooks
            end,
            
            buildUI = function(Tabs, Client, Shared)
                -- Custom UI
            end,
            
            Unload = function()
            end,
        };
    end;
]]

return GameModules;
