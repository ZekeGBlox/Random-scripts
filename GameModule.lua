if not LPH_OBFUSCATED then
    LPH_NO_VIRTUALIZE = function(f) return f end;
    LPH_JIT = function(f) return f end;
    LPH_CRASH = function() while true do end end;
end;

local Services = loadstring(game:HttpGet("https://zekehub.com/scripts/Utility/Services.lua"))();

local Players, Workspace, ReplicatedStorage = Services:Get('Players', 'Workspace', 'ReplicatedStorage');
local LocalPlayer = Players.LocalPlayer;
local CurrentCamera = Workspace.CurrentCamera;

local GameModules = {};

do -- bad business [1168263273]
    local TS = nil;
    local storedClient = nil;
    local storedShared = nil;
    
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
        
        local function GetCharacterBody(player)
            if TS and TS.Characters then
                local char = TS.Characters:GetCharacter(player);
                if char and char.Body and char.Body.Parent then
                    return char.Body;
                end;
            end;
            return nil;
        end;
        
        GameModules[1168263273] = {
            Name = "Bad Business",
            
            getCharacter = function(player)
                return GetCharacterBody(player);
            end,
            
            getHealth = function(character)
                if not character then return 0, 100; end;
                local humanoid = character:FindFirstChildOfClass("Humanoid");
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
                local character = GetCharacterBody(player);
                if not character then return "Unarmed"; end;
                
                if TS and TS.Items then
                    for item, controller in next, TS.Items:GetControllers() do
                        if controller.Equipped and controller.Owner == player then
                            local config = TS.Items:GetConfig(item);
                            if config and config.Name then
                                return config.Name;
                            end;
                            return item.Name or "Unknown";
                        end;
                    end;
                end;
                
                local tool = character:FindFirstChildOfClass("Tool");
                if tool then return tool.Name; end;
                return "Unarmed";
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
                    
                    local character = GetCharacterBody(player);
                    if not character then continue; end;
                    
                    local humanoid = character:FindFirstChildOfClass("Humanoid");
                    if not humanoid or humanoid.Health <= 0 then continue; end;
                    
                    if shared.teamCheck then
                        local localTeam = TS.Teams:GetPlayerTeam(LocalPlayer);
                        local playerTeam = TS.Teams:GetPlayerTeam(player);
                        if localTeam and playerTeam and localTeam == playerTeam then continue; end;
                    end;
                    
                    local targetPart = character:FindFirstChild(shared.hitbox or "Head") or character:FindFirstChild("Head");
                    if not targetPart then continue; end;
                    
                    local worldDistance = (CurrentCamera.CFrame.Position - targetPart.Position).Magnitude;
                    if worldDistance > (shared.maxDistance or 500) then continue; end;
                    
                    local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(targetPart.Position);
                    if not onScreen then continue; end;
                    
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude;
                    
                    if shared.visibleCheck then
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
                        if Toggles.silentAimEnabled and Toggles.silentAimEnabled.Value then
                            local chance = math.random(0, 100);
                            if chance <= (Options.silentAimHitChance and Options.silentAimHitChance.Value or 100) then
                                thisModule.getClosestPlayer(Client, Shared);
                                
                                if Client.silentTarget.part then
                                    local origin = args[2];
                                    local bulletSpeed = GetBulletSpeed();
                                    local velocity = Client.silentTarget.part.AssemblyLinearVelocity or Vector3.zero;
                                    local distance = (Client.silentTarget.part.Position - origin).Magnitude;
                                    local timeToTarget = distance / bulletSpeed;
                                    local predictedPos = Client.silentTarget.part.Position + (velocity * timeToTarget);
                                    args[3] = (predictedPos - origin).Unit;
                                end;
                            end;
                        end;
                    end;
                    
                    local result = hooks(self, unpack(args));
                    
                    if result and type(result) == "table" then
                        if Toggles.noGravity and Toggles.noGravity.Value then
                            if result.Gravity then
                                result.Gravity = 0;
                            end;
                        end;
                        if Toggles.bulletSpeed and Toggles.bulletSpeed.Value then
                            if result.Velocity then
                                result.Velocity = result.Velocity.Unit * (result.Velocity.Magnitude * (Options.bulletSpeedMultiplier and Options.bulletSpeedMultiplier.Value or 10));
                            end;
                        end;
                    end;
                    
                    return result;
                end));
                
                if TS.Camera and TS.Camera.Recoil and TS.Camera.Recoil.Fire then
                    hookManager:hook("BB_RecoilFire", TS.Camera.Recoil.Fire, LPH_NO_VIRTUALIZE(function(self, ...)
                        if Toggles.noRecoil and Toggles.noRecoil.Value then return; end;
                        return hooks(self, ...);
                    end));
                end;
                
                if TS.Input and TS.Input.Reticle and TS.Input.Reticle.LookVector then
                    hookManager:hook("BB_LookVector", TS.Input.Reticle.LookVector, LPH_NO_VIRTUALIZE(function(self, ...)
                        local args = {...};
                        if Toggles.noSpread and Toggles.noSpread.Value then
                            if #args > 0 then
                                args[1] = 0;
                            end;
                        end;
                        return hooks(self, unpack(args));
                    end));
                end;
                
                if TS.Input and TS.Input.Reticle and TS.Input.Reticle.Choke then
                    hookManager:hook("BB_Choke", TS.Input.Reticle.Choke, LPH_NO_VIRTUALIZE(function(self, ...)
                        if Toggles.noSpread and Toggles.noSpread.Value then
                            return Vector3.zero;
                        end;
                        return hooks(self, ...);
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
            end,
        };
    end;
end;

return GameModules;
