if not LPH_OBFUSCATED then
    loadstring(game:HttpGet("https://zekehub.com/scripts/Utility/luraphsdk.lua"))()
end

local Services = loadstring(game:HttpGet("https://zekehub.com/scripts/Utility/Services.lua"))();

local Players, Workspace, ReplicatedStorage = Services:Get('Players', 'Workspace', 'ReplicatedStorage');
local LocalPlayer = Players.LocalPlayer;
local CurrentCamera = Workspace.CurrentCamera;

local GameModules = {};

do -- bad business [1168263273]
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
                    print("GOT HERE 1");
                    print("hookManager:", hookManager);
                    print("hooks:", hooks);
                    print("TS:", TS);
                    print("TS.Projectiles:", TS and TS.Projectiles);
                local thisModule = GameModules[1168263273];
                
                hookManager:hook("BB_InitProjectile", TS.Projectiles.InitProjectile, LPH_NO_VIRTUALIZE(function(self, projectileType, position, direction, owner, ...)
                    if typeof(position) ~= "Vector3" or typeof(direction) ~= "Vector3" then
                        return hooks.BB_InitProjectile(self, projectileType, position, direction, owner, ...);
                    end;
                    
                    local newDirection = direction;
                    
                    if owner == LocalPlayer then
                        if Toggles.silentAimEnabled and Toggles.silentAimEnabled.Value then
                            local chance = math.random(0, 100);
                            if chance <= (Options.silentAimHitChance and Options.silentAimHitChance.Value or 100) then
                                thisModule.getClosestPlayer(Client, Shared);
                                
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
                    
                    return hooks.BB_InitProjectile(self, projectileType, position, newDirection, owner, ...);
                end));
                
                if TS.Camera and TS.Camera.Recoil and TS.Camera.Recoil.Fire then
                    hookManager:hook("BB_RecoilFire", TS.Camera.Recoil.Fire, LPH_NO_VIRTUALIZE(function(self, ...)
                        if Toggles.noRecoil and Toggles.noRecoil.Value then return; end;
                        return hooks.BB_RecoilFire(self, ...);
                    end));
                end;
                
                if TS.Input and TS.Input.Reticle and TS.Input.Reticle.Choke then
                    hookManager:hook("BB_Choke", TS.Input.Reticle.Choke, LPH_NO_VIRTUALIZE(function(self, ...)
                        if Toggles.noSpread and Toggles.noSpread.Value then return Vector3.zero; end;
                        return hooks.BB_Choke(self, ...);
                    end));
                end;
                
                if TS.Input and TS.Input.Reticle and TS.Input.Reticle.LookVector then
                    hookManager:hook("BB_LookVector", TS.Input.Reticle.LookVector, LPH_NO_VIRTUALIZE(function(self, choke, ...)
                        if Toggles.noSpread and Toggles.noSpread.Value then
                            choke = 0;
                        end;
                        return hooks.BB_LookVector(self, choke, ...);
                    end));
                end;
            end,
            
            buildUI = function(Tabs, Client, Shared)
                local gunModsGroup = Tabs.Main:AddLeftGroupbox("Gun Mods");
                gunModsGroup:AddToggle("noRecoil", {Text = "No Recoil"});
                gunModsGroup:AddToggle("noSpread", {Text = "No Spread"});
            end,
            
            Unload = function()
            end,
        };
    end;
end;

return GameModules;
