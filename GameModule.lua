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

do -- bad business [1168263273]
    local TS = nil;
    local storedClient = nil;
    local storedShared = nil;
    local storedESP = nil;
    local espObjects = {};
    local chamObjects = {};
    local characterTrackingConnection = nil;
    
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
        
        local function CreateEspForCharacter(player, charModel, ESP)
            if not charModel or not charModel.Parent then return; end;
            if player == LocalPlayer then return; end;
            
            local body = charModel:FindFirstChild("Body");
            if not body then return; end;
            
            if espObjects[player] then
                espObjects[player]:Destruct();
                espObjects[player] = nil;
            end;
            if chamObjects[player] then
                chamObjects[player]:Destruct();
                chamObjects[player] = nil;
            end;
            
            local isFriendly = IsFriendly(player);
            
            local function getOptions()
                local teamType = isFriendly and "friendly" or "enemy";
                local baseOptions = ESP.teamSettings[teamType];
                return {
                    enabled = baseOptions.enabled,
                    box = baseOptions.box,
                    boxColor = baseOptions.boxColor,
                    boxOutline = baseOptions.boxOutline,
                    boxOutlineColor = baseOptions.boxOutlineColor,
                    boxFill = baseOptions.boxFill,
                    boxFillColor = baseOptions.boxFillColor,
                    healthBar = baseOptions.healthBar,
                    healthyColor = baseOptions.healthyColor,
                    dyingColor = baseOptions.dyingColor,
                    healthBarOutline = baseOptions.healthBarOutline,
                    healthBarOutlineColor = baseOptions.healthBarOutlineColor,
                    healthText = baseOptions.healthText,
                    healthTextColor = baseOptions.healthTextColor,
                    healthTextOutline = baseOptions.healthTextOutline,
                    healthTextOutlineColor = baseOptions.healthTextOutlineColor,
                    box3d = baseOptions.box3d,
                    box3dColor = baseOptions.box3dColor,
                    name = baseOptions.name,
                    nameColor = baseOptions.nameColor,
                    nameOutline = baseOptions.nameOutline,
                    nameOutlineColor = baseOptions.nameOutlineColor,
                    weapon = baseOptions.weapon,
                    weaponColor = baseOptions.weaponColor,
                    weaponOutline = baseOptions.weaponOutline,
                    weaponOutlineColor = baseOptions.weaponOutlineColor,
                    weaponText = GetWeaponForPlayer(player),
                    distance = baseOptions.distance,
                    distanceColor = baseOptions.distanceColor,
                    distanceOutline = baseOptions.distanceOutline,
                    distanceOutlineColor = baseOptions.distanceOutlineColor,
                    tracer = baseOptions.tracer,
                    tracerOrigin = baseOptions.tracerOrigin,
                    tracerColor = baseOptions.tracerColor,
                    tracerOutline = baseOptions.tracerOutline,
                    tracerOutlineColor = baseOptions.tracerOutlineColor,
                    offScreenArrow = baseOptions.offScreenArrow,
                    offScreenArrowColor = baseOptions.offScreenArrowColor,
                    offScreenArrowSize = baseOptions.offScreenArrowSize,
                    offScreenArrowRadius = baseOptions.offScreenArrowRadius,
                    offScreenArrowOutline = baseOptions.offScreenArrowOutline,
                    offScreenArrowOutlineColor = baseOptions.offScreenArrowOutlineColor,
                    chams = baseOptions.chams,
                    chamsVisibleOnly = baseOptions.chamsVisibleOnly,
                    chamsFillColor = baseOptions.chamsFillColor,
                    chamsOutlineColor = baseOptions.chamsOutlineColor,
                };
            end;
            
            ESP.getHealth = function(character)
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
            end;
            
            espObjects[player] = ESP.AddInstanceEsp(body, getOptions);
            
            if ESP.InstanceChamObject then
                chamObjects[player] = ESP.InstanceChamObject.new(body, ESP, getOptions);
            end;
            
            local healthValue = charModel:FindFirstChild("Health");
            if healthValue then
                local conn;
                conn = healthValue.Changed:Connect(function(newHealth)
                    if newHealth <= 0 then
                        if espObjects[player] then
                            espObjects[player]:Destruct();
                            espObjects[player] = nil;
                        end;
                        if chamObjects[player] then
                            chamObjects[player]:Destruct();
                            chamObjects[player] = nil;
                        end;
                        conn:Disconnect();
                    end;
                end);
            end;
        end;
        
        local function SetupCharacterTracking(ESP)
            storedESP = ESP;
            
            if TS and TS.Characters then
                local charactersFolder = nil;
                pcall(function()
                    for _, folder in next, Workspace:GetChildren() do
                        if folder.Name == "Characters" or folder.Name == "characters" then
                            charactersFolder = folder;
                            break;
                        end;
                    end;
                end);
                
                for _, player in next, Players:GetPlayers() do
                    if player ~= LocalPlayer then
                        local charModel = GetCharacterModel(player);
                        if charModel then
                            CreateEspForCharacter(player, charModel, ESP);
                        end;
                    end;
                end;
                
                characterTrackingConnection = RunService.Heartbeat:Connect(function()
                    for _, player in next, Players:GetPlayers() do
                        if player ~= LocalPlayer then
                            local charModel = GetCharacterModel(player);
                            local body = charModel and charModel:FindFirstChild("Body");
                            
                            if body and body.Parent then
                                if not espObjects[player] or not espObjects[player].instance or not espObjects[player].instance.Parent then
                                    CreateEspForCharacter(player, charModel, ESP);
                                end;
                            else
                                if espObjects[player] then
                                    espObjects[player]:Destruct();
                                    espObjects[player] = nil;
                                end;
                                if chamObjects[player] then
                                    chamObjects[player]:Destruct();
                                    chamObjects[player] = nil;
                                end;
                            end;
                        end;
                    end;
                end);
            end;
        end;
        
        GameModules[1168263273] = {
            Name = "Bad Business",
            useCustomEsp = true,
            
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
                local center = CurrentCamera.ViewportSize / 2;
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
                    
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude;
                    
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
            
            setupEsp = function(ESP)
                SetupCharacterTracking(ESP);
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
                if characterTrackingConnection then
                    characterTrackingConnection:Disconnect();
                    characterTrackingConnection = nil;
                end;
                
                for player, obj in next, espObjects do
                    if obj and obj.Destruct then
                        obj:Destruct();
                    end;
                end;
                table.clear(espObjects);
                
                for player, obj in next, chamObjects do
                    if obj and obj.Destruct then
                        obj:Destruct();
                    end;
                end;
                table.clear(chamObjects);
                
                storedClient = nil;
                storedShared = nil;
                storedESP = nil;
            end,
        };
    end;
end;

return GameModules;
