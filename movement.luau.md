

-- Notes:

--- Assistant was made to fix some faults, but not to make the script.



local Movement = {};

Movement.\_\_index = Movement;



-- Sources

--- Services

local UserInputService: UserInputService = game:GetService("UserInputService");



--- References

local Player: Player = game:GetService("Players").LocalPlayer;



function Movement.new(character)

&nbsp; local self = setmetatable({}, Movement);



&nbsp; local Character: Model = character or Player.CharacterAdded:Wait();

&nbsp; local Humanoid: Humanoid = Character:WaitForChild("Humanoid");

&nbsp; local HumanoidRootPart: Part = Character:WaitForChild("HumanoidRootPart");

&nbsp; local Head: Part = Character:WaitForChild("Head");

&nbsp; local StaminaValues: Folder = Character:WaitForChild("StaminaValues", 1) or nil;

&nbsp; local CharAnimations: Folder =  Character:WaitForChild("MovementAnims", 1) or script:WaitForChild("Movement"); -- Default Animations

&nbsp; local Animator: Animator = Humanoid:WaitForChild("Animator");

&nbsp; local AnimationConfigurations: Folder = script:WaitForChild("Configurations");

&nbsp; local AbilityConfigurations: Folder = script:FindFirstChild("AbilityConfigurations") or nil;

&nbsp; local Camera: Camera = workspace.CurrentCamera;

&nbsp; local Interface = script:WaitForChild("Interface");



&nbsp; local NeckAttachment: Motor6D =  Character:WaitForChild("Torso"):WaitForChild("Neck"); NeckAttachment.MaxVelocity = 1 / 3;



&nbsp; -- Internal Storage

&nbsp; --- Containers

&nbsp; local anims: {AnimationTrack} = {};

&nbsp; local footsteps: {Sound} = {};



&nbsp; -- Declarables



&nbsp; --- Constants

&nbsp; local Constants: Folder = AnimationConfigurations:WaitForChild("Constants");

&nbsp; ----- Note: The ones without a comment are self-explanatory.

&nbsp; ---- Stamina Constants

&nbsp; local SPEED\_CHANGE\_ALPHA: number = Constants:WaitForChild("WALKSPEED\_ALPHA").Value -- smooth walkspeed transition

&nbsp; local WALK\_SPEED: NumberValue = StaminaValues and StaminaValues:WaitForChild("WALK\_SPEED") or Instance.new("NumberValue"); 

&nbsp; WALK\_SPEED.Value = (WALK\_SPEED.Value ~= 0 and WALK\_SPEED.Value) or 8;

&nbsp; local RUN\_SPEED: NumberValue = StaminaValues and StaminaValues:WaitForChild("RUN\_SPEED") or Instance.new("NumberValue");

&nbsp; RUN\_SPEED.Value = (RUN\_SPEED.Value ~= 0 and RUN\_SPEED.Value) or 24;

&nbsp; local STAMINA\_DRAIN: NumberValue = StaminaValues and StaminaValues:WaitForChild("STAMINA\_DRAIN") or Instance.new("NumberValue");

&nbsp; STAMINA\_DRAIN.Value = (STAMINA\_DRAIN.Value ~= 0 and STAMINA\_DRAIN.Value) or 10;

&nbsp; local STAMINA\_GAIN: NumberValue = StaminaValues and StaminaValues:WaitForChild("STAMINA\_GAIN") or Instance.new("NumberValue");

&nbsp; STAMINA\_GAIN.Value = (STAMINA\_GAIN.Value ~= 0 and STAMINA\_GAIN.Value) or 10;

&nbsp; local STAMINA\_MAX: NumberValue = StaminaValues and StaminaValues:WaitForChild("STAMINA\_MAX") or Instance.new("NumberValue");

&nbsp; STAMINA\_MAX.Value = (STAMINA\_MAX.Value ~= 0 and STAMINA\_MAX.Value) or 100;

&nbsp; local extra\_speed: NumberValue = StaminaValues and StaminaValues:WaitForChild("ExtraSpeed") or Instance.new("NumberValue");

&nbsp; extra\_speed.Value = 0; -- was originally 8 but changed it for convenience

&nbsp; 

&nbsp; local WAIT\_TIME: number = 0.1; -- put this at a low number for smoothness, higher for performance

&nbsp; local STAMINA\_REGEN\_COOLDOWN: number = 1.9; -- seconds to wait after depletion

&nbsp; 

&nbsp; ---- Ability Constants

&nbsp; local DASH\_COOLDOWN: number = 30;

&nbsp; local DASH\_SOUND: Sound = Instance.new("Sound");

&nbsp; DASH\_SOUND.SoundId = "rbxassetid://103660195159597"; DASH\_SOUND.Parent = Character.PrimaryPart;

&nbsp; local DASH\_SPEED: number = 60;

&nbsp; local DASH\_LENGTH: number = 3 / 2; -- calculate for the for loop in its respective function

&nbsp; local PUNCH\_COOLDOWN: number = 30;

&nbsp; local PUNCH\_SOUND: Sound = Instance.new("Sound");

&nbsp; PUNCH\_SOUND.SoundId = "rbxassetid://123796710194563"; PUNCH\_SOUND.Parent = Character.PrimaryPart;

&nbsp; local PUNCH\_DAMAGE: number = 20;

&nbsp; 

&nbsp; ---- Animation Constants

&nbsp; local IDLE\_FADE\_OFF: number = Constants:WaitForChild("IDLE\_FADE\_OFF").Value;

&nbsp; local WALK\_FADE\_OFF: number = Constants:WaitForChild("WALK\_FADE\_OFF").Value;

&nbsp; local RUN\_FADE\_OFF: number = Constants:WaitForChild("RUN\_FADE\_OFF").Value;

&nbsp; local LEANING\_ALPHA: number = Constants:WaitForChild("LEANING\_ALPHA").Value;

&nbsp; local HEAD\_HORIZONTAL\_MAX: number = .7;

&nbsp; local HEAD\_VERTICAL\_MAX: number = .5;

&nbsp; local ORIG\_ROOT\_JOINT: CFrame = HumanoidRootPart.RootJoint.C0;

&nbsp; local ORIG\_NECK\_JOINT: CFrame = NeckAttachment.C0;

&nbsp; 

&nbsp; --- Variables

&nbsp; ---- OOP Variables

&nbsp; local currentInstance;

&nbsp; 

&nbsp; ---- Ability Variables

&nbsp; local isActionable: boolean = true;

&nbsp; local canDash: boolean = true;

&nbsp; local currentDashCooldown: number = 0;

&nbsp; local canPunch: boolean = true;

&nbsp; local currentPunchCooldown: number = 0;

&nbsp; 

&nbsp; ---- Stamina Variables

&nbsp; local currentlyRunning: boolean = false;

&nbsp; local currentStamina: number = STAMINA\_MAX.Value;

&nbsp; local displayedStamina: number = STAMINA\_MAX.Value;

&nbsp; local displayedSpeed: number = WALK\_SPEED.Value;

&nbsp; local canRegenStamina: boolean = true;

&nbsp; local stopLoop: boolean = false;

&nbsp; local regenAvailableTime: number = 0; -- timestamp when stamina regen is allowed



&nbsp; ---- Animation Variables

&nbsp; local currentSound: Sound;

&nbsp; local previewAngleX: number = 0;

&nbsp; local previewAngleY: number = 0;

&nbsp; local previewHeadRot: Vector3;

&nbsp; local displayedAngleX: number = 0;

&nbsp; local displayedAngleY: number = 0;

&nbsp; local displayedHeadRot: Vector3;

&nbsp; local direction: Vector3;

&nbsp; local velocity: Vector3;

&nbsp; 

&nbsp; -- Interface

&nbsp; --- Info Billboard

&nbsp; local infoBillboard: BillboardGui = Interface:WaitForChild("InfoBillboard"):Clone();

&nbsp; infoBillboard.Adornee = Character.PrimaryPart;

&nbsp; infoBillboard.Parent = Character;

&nbsp; ---- Stamina

&nbsp; local staminaBar: Frame = infoBillboard:WaitForChild("StaminaBar");

&nbsp; local staminaVisualizer: Frame = staminaBar:WaitForChild("StaminaVisualizer");

&nbsp; local staminaAmount: TextLabel = staminaBar:WaitForChild("StaminaAmount");

&nbsp; ---- Health

&nbsp; local healthBar: Frame = infoBillboard:WaitForChild("HealthBar");

&nbsp; local healthVisualizer: Frame = healthBar:WaitForChild("HealthVisualizer");

&nbsp; local healthAmount: TextLabel = healthBar:WaitForChild("HealthLabel");

&nbsp; ---- Abilities

&nbsp; local abilitiesFrame: Frame = infoBillboard:WaitForChild("Abilities");

&nbsp; local dashFrame: Frame = abilitiesFrame:WaitForChild("Template"):Clone();

&nbsp; local labelCooldownDash: TextLabel = dashFrame:WaitForChild("LabelCooldown");

&nbsp; dashFrame.Name = "Dash"; dashFrame.Parent = abilitiesFrame; dashFrame.Visible = true;

&nbsp; 

&nbsp; local punchFrame: Frame = abilitiesFrame:WaitForChild("Template"):Clone();

&nbsp; local labelName: TextLabel = punchFrame:WaitForChild("LabelName");

&nbsp; local labelCooldownPunch: TextLabel = punchFrame:WaitForChild("LabelCooldown");

&nbsp; punchFrame.Name = "Punch"; punchFrame.Parent = abilitiesFrame; labelName.Text = "Punch"; punchFrame:WaitForChild("Display").Image = "rbxassetid://13050670424"; punchFrame.Visible = true; 

&nbsp; 

&nbsp; -- Helper Functions

&nbsp; 

&nbsp; --- Dash Ability

&nbsp; local function initDash(): ()

&nbsp;   if (not canDash and not isActionable) then return end; -- buffer

&nbsp;   isActionable = false; canDash = false; currentDashCooldown = DASH\_COOLDOWN;

&nbsp;   local preservedGain: number, preservedDrain: number = STAMINA\_GAIN.Value, STAMINA\_DRAIN.Value;

&nbsp;   do -- Main Ability

&nbsp;     anims\["Dash"]:Play();

&nbsp;     DASH\_SOUND:Play();

&nbsp;     extra\_speed.Value = -24;

&nbsp;     STAMINA\_GAIN.Value = 0; STAMINA\_DRAIN.Value = 0;

&nbsp;     for i = 1, DASH\_LENGTH \* 20 do

&nbsp;       local lookVector: Vector3 = Character.PrimaryPart.CFrame.LookVector;

&nbsp;       Character.PrimaryPart.AssemblyLinearVelocity = lookVector \* DASH\_SPEED;

&nbsp;       task.wait(0.05);

&nbsp;     end;

&nbsp;   end;

&nbsp;  

&nbsp;   do -- After effect

&nbsp;     extra\_speed.Value = -6;

&nbsp;     STAMINA\_DRAIN.Value = preservedDrain \* 2;

&nbsp;     anims\["Dash"]:Stop();

&nbsp;     task.wait(1.5);

&nbsp;     STAMINA\_GAIN.Value = preservedGain;

&nbsp;     STAMINA\_DRAIN.Value = preservedDrain;

&nbsp;     extra\_speed.Value = 0;

&nbsp;     task.wait(1);

&nbsp;     isActionable = true;

&nbsp;     preservedGain, preservedDrain = nil;

&nbsp;   end;

&nbsp; end;

&nbsp; 

&nbsp; -- Punch Ability

&nbsp; local function initPunch(): ()

&nbsp;   if (not canPunch and not isActionable) then return end; -- buffer

&nbsp;   isActionable = false; canPunch = false; currentPunchCooldown = PUNCH\_COOLDOWN;

&nbsp;   anims\["Punch"]:Play();

&nbsp;   PUNCH\_SOUND:Play()

&nbsp;   extra\_speed.Value = -7;

&nbsp;   task.wait(0.3);

&nbsp;   print("i am supposed to release a hitbox");

&nbsp;   task.wait(1.7);

&nbsp;   extra\_speed.Value = 0;

&nbsp;   task.wait(1);

&nbsp;   isActionable = true;

&nbsp; end

&nbsp; 

&nbsp; --- Play a random footstep sound

&nbsp; local function playRandomFootstep(): ()

&nbsp;   currentSound = footsteps\[math.random(1, #footsteps)];

&nbsp;   currentSound:Play();

&nbsp;   currentSound = nil;

&nbsp; end;



&nbsp; --- Register player input

&nbsp; local function registerInput(input: InputObject, gameProcessedEvent: boolean, state: boolean): ()

&nbsp;   if (gameProcessedEvent) then return end;

&nbsp;   if (input.KeyCode == Enum.KeyCode.LeftShift) then

&nbsp;     currentlyRunning = state;

&nbsp;   elseif (input.KeyCode == Enum.KeyCode.C and canDash and isActionable) then

&nbsp;     initDash()

&nbsp;   elseif (input.KeyCode == Enum.KeyCode.V and canPunch and isActionable) then

&nbsp;     initPunch()

&nbsp;   end;

&nbsp; end;



&nbsp; do -- Create visuals

&nbsp;   do ---- Animations

&nbsp;     for \_, v in CharAnimations:GetChildren() do

&nbsp;       if (v:IsA("Animation")) then

&nbsp;         anims\[v.Name] = Animator:LoadAnimation(v);

&nbsp;       end;

&nbsp;     end;

&nbsp;     anims\["Dash"]:AdjustSpeed(2);

&nbsp;   end;



&nbsp;   do ---- Footsteps

&nbsp;     HumanoidRootPart:WaitForChild("Running", 1).Volume = 0; -- disable default walk sfx

&nbsp;     local footstep1: Sound = Instance.new("Sound");

&nbsp;     footstep1.SoundId = "rbxassetid://79867504001965";

&nbsp;     footstep1.Parent = HumanoidRootPart



&nbsp;     local footstep2: Sound = Instance.new("Sound");

&nbsp;     footstep2.SoundId = "rbxassetid://114223000992532";

&nbsp;     footstep2.Parent = HumanoidRootPart;



&nbsp;     local footstep3: Sound = Instance.new("Sound");

&nbsp;     footstep3.SoundId = "rbxassetid://101831533539194";

&nbsp;     footstep3.Parent = HumanoidRootPart;



&nbsp;     local footstep4: Sound = Instance.new("Sound");

&nbsp;     footstep4.SoundId = "rbxassetid://113597545053199";

&nbsp;     footstep4.Parent = HumanoidRootPart;



&nbsp;     local footstep5: Sound = Instance.new("Sound");

&nbsp;     footstep5.SoundId = "rbxassetid://109793629037912";

&nbsp;     footstep5.Parent = HumanoidRootPart;



&nbsp;     table.insert(footsteps, footstep1); table.insert(footsteps, footstep2); table.insert(footsteps, footstep3); table.insert(footsteps, footstep4); table.insert(footsteps, footstep5)

&nbsp;   end;

&nbsp; end;



&nbsp; -- Store connections for cleanup

&nbsp; self.\_connections = {};

&nbsp; self.\_loop = nil;

&nbsp; self.\_stopLoop = false;



&nbsp; -- The Main Function!

&nbsp; self.\_loop = task.spawn(function()

&nbsp;   while (not self.\_stopLoop) do 

&nbsp;     do -- Main Logic

&nbsp;       local now = os.clock();



&nbsp;       -- Check if enough time has passed to allow stamina regen

&nbsp;       if (not canRegenStamina and now >= regenAvailableTime) then

&nbsp;         canRegenStamina = true;

&nbsp;       end;



&nbsp;       if (currentlyRunning) then

&nbsp;         if (HumanoidRootPart.AssemblyLinearVelocity.Magnitude <= 0.2) then -- Standing still while on run state

&nbsp;           if (canRegenStamina) then

&nbsp;             currentStamina += STAMINA\_GAIN.Value \* WAIT\_TIME;

&nbsp;           end;

&nbsp;         else

&nbsp;           currentStamina -= STAMINA\_DRAIN.Value \* WAIT\_TIME;

&nbsp;           if (currentStamina <= 0) then

&nbsp;             currentStamina = 0;

&nbsp;             currentlyRunning = false;

&nbsp;             canRegenStamina = false;

&nbsp;             regenAvailableTime = os.clock() + STAMINA\_REGEN\_COOLDOWN;

&nbsp;           end;

&nbsp;         end;

&nbsp;       else

&nbsp;         if (canRegenStamina) then

&nbsp;           currentStamina += STAMINA\_GAIN.Value \* WAIT\_TIME;

&nbsp;         end;

&nbsp;       end;



&nbsp;       -- Clamp stamina

&nbsp;       if (currentStamina >= STAMINA\_MAX.Value) then

&nbsp;         currentStamina = STAMINA\_MAX.Value;

&nbsp;       elseif (currentStamina <= 0) then

&nbsp;         currentStamina = 0;

&nbsp;       end;

&nbsp;       

&nbsp;       Humanoid.WalkSpeed = displayedSpeed;

&nbsp;     end;



&nbsp;     do -- Visuals

&nbsp;       do -- Animation

&nbsp;         if (not anims\["Dash"].IsPlaying) then

&nbsp;           local velocityMagnitude: number = HumanoidRootPart.AssemblyLinearVelocity.Magnitude;

&nbsp;           anims\["Walk"]:AdjustSpeed(velocityMagnitude / WALK\_SPEED.Value / 2);

&nbsp;           anims\["Run"]:AdjustSpeed(velocityMagnitude / RUN\_SPEED.Value);



&nbsp;           if (velocityMagnitude <= 0.1) then

&nbsp;             if (anims\["Walk"].IsPlaying) then anims\["Walk"]:Stop(WALK\_FADE\_OFF); end;

&nbsp;             if (anims\["Run"].IsPlaying) then anims\["Run"]:Stop(RUN\_FADE\_OFF); end;

&nbsp;             if (not anims\["Idle"].IsPlaying) then anims\["Idle"]:Play(IDLE\_FADE\_OFF); end;

&nbsp;           elseif not currentlyRunning then

&nbsp;             if (not anims\["Walk"].IsPlaying) then anims\["Walk"]:Play(WALK\_FADE\_OFF); end;

&nbsp;             if (anims\["Run"].IsPlaying) then anims\["Run"]:Stop(RUN\_FADE\_OFF); end;

&nbsp;             if (anims\["Idle"].IsPlaying) then anims\["Idle"]:Stop(IDLE\_FADE\_OFF); end;

&nbsp;           elseif currentlyRunning then

&nbsp;             if (anims\["Walk"].IsPlaying) then anims\["Walk"]:Stop(WALK\_FADE\_OFF); end;

&nbsp;             if (not anims\["Run"].IsPlaying) then anims\["Run"]:Play(RUN\_FADE\_OFF); end;

&nbsp;             if (anims\["Idle"].IsPlaying) then anims\["Idle"]:Stop(IDLE\_FADE\_OFF); end;

&nbsp;           end;

&nbsp;         else

&nbsp;           if (anims\["Walk"].IsPlaying) then anims\["Walk"]:Stop(WALK\_FADE\_OFF); end;

&nbsp;           if (anims\["Run"].IsPlaying) then anims\["Run"]:Stop(RUN\_FADE\_OFF); end;

&nbsp;           if (anims\["Idle"].IsPlaying) then anims\["Idle"]:Stop(IDLE\_FADE\_OFF); end;

&nbsp;         end;

&nbsp;       end;



&nbsp;       do -- Leaning Calculations

&nbsp;         velocity = HumanoidRootPart.AssemblyLinearVelocity;

&nbsp;         if (velocity.Magnitude > 2) then

&nbsp;           direction = velocity.Unit;

&nbsp;           previewAngleY = HumanoidRootPart.CFrame.RightVector:Dot(direction) / 8;

&nbsp;           previewAngleX = HumanoidRootPart.CFrame.LookVector:Dot(direction) / 8;

&nbsp;         else

&nbsp;           previewAngleY = 0; previewAngleX = 0;

&nbsp;         end;

&nbsp;       end;



&nbsp;       do -- Head Facing

&nbsp;         local camCF: CFrame = Camera.CFrame;

&nbsp;         local headCF: CFrame = Head.CFrame;

&nbsp;         local torsoLookVec: Vector3 = Character:WaitForChild("Torso").CFrame.LookVector;

&nbsp;         local dist: number = (camCF.Position - headCF.Position).Magnitude;

&nbsp;         local diff: number = headCF.Y - camCF.Y;

&nbsp;         local asin = math.asin(diff / dist);

&nbsp;         local headCross = ((headCF.Position - camCF.Position).Unit:Cross(torsoLookVec)).Y;

&nbsp;         previewHeadRot = NeckAttachment.C0:Lerp(ORIG\_NECK\_JOINT \* CFrame.Angles(

&nbsp;           -1 \* asin \* HEAD\_VERTICAL\_MAX, 0, -1 \* headCross \* HEAD\_HORIZONTAL\_MAX

&nbsp;           ), 0.5);

&nbsp;       end;

&nbsp;     end;



&nbsp;     do -- Finalize values and display

&nbsp;       displayedAngleY = math.lerp(displayedAngleY, previewAngleY \* (extra\_speed.Value / 16 + 1), LEANING\_ALPHA);

&nbsp;       displayedAngleX = math.lerp(displayedAngleX, previewAngleX \* (extra\_speed.Value / 13 + 1), LEANING\_ALPHA);

&nbsp;       displayedHeadRot = previewHeadRot;

&nbsp;       displayedSpeed = math.lerp(Humanoid.WalkSpeed, (currentlyRunning and RUN\_SPEED.Value or WALK\_SPEED.Value) + extra\_speed.Value, SPEED\_CHANGE\_ALPHA);

&nbsp;       displayedStamina = math.round(currentStamina);

&nbsp;       Humanoid.WalkSpeed = displayedSpeed;

&nbsp;       HumanoidRootPart.RootJoint.C0 = ORIG\_ROOT\_JOINT \* CFrame.Angles(displayedAngleX, -displayedAngleY, 0);

&nbsp;       NeckAttachment.C0 = displayedHeadRot;

&nbsp;       staminaAmount.Text = tostring(displayedStamina);

&nbsp;       staminaVisualizer.Size = UDim2.new(1, 0, currentStamina / STAMINA\_MAX.Value, 0);

&nbsp;       labelCooldownDash.Text = tostring(math.round(currentDashCooldown));

&nbsp;       currentDashCooldown -= 1 \* WAIT\_TIME; if (currentDashCooldown < 0) then currentDashCooldown = 0; canDash = true; end;

&nbsp;       labelCooldownPunch.Text = tostring(math.round(currentPunchCooldown));

&nbsp;       currentPunchCooldown -= 1 \* WAIT\_TIME; if (currentPunchCooldown < 0) then currentPunchCooldown = 0; canPunch = true; end;

&nbsp;     end;



&nbsp;     task.wait(WAIT\_TIME);

&nbsp;     -- No more task.spawn for stamina regen needed here!

&nbsp;     -- Removed buggy canRegenStamina reset here ^^

&nbsp;   end;

&nbsp; end);



&nbsp; do -- Connections

&nbsp;   -- Input Conns

&nbsp;   local inputStarted = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)

&nbsp;     registerInput(input, gameProcessedEvent, true);

&nbsp;   end);

&nbsp;   table.insert(self.\_connections, inputStarted);



&nbsp;   local inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)

&nbsp;     registerInput(input, gameProcessedEvent, false);

&nbsp;   end);

&nbsp;   table.insert(self.\_connections, inputEnded);



&nbsp;   -- Footstep Conns

&nbsp;   local walkConn;

&nbsp;   local runConn;

&nbsp;   if (Constants:WaitForChild("FOOTSTEPS\_ENABLED").Value) then

&nbsp;     walkConn = anims\["Walk"]:GetMarkerReachedSignal("footstep"):Connect(playRandomFootstep);

&nbsp;     runConn = anims\["Run"]:GetMarkerReachedSignal("footstep"):Connect(playRandomFootstep);

&nbsp;     table.insert(self.\_connections, walkConn);

&nbsp;     table.insert(self.\_connections, runConn);

&nbsp;   end;



&nbsp;   -- Used for animation playing, to be used later

&nbsp;   local eventConn = script:WaitForChild("Event").Event:Connect(function(event: string) 

&nbsp;     if (anims\[event]) then

&nbsp;       if (AbilityConfigurations and AbilityConfigurations:FindFirstChild(event)) then

&nbsp;         anims\[event].Looped = false;

&nbsp;         anims\[event].Priority = Enum.AnimationPriority.Action;

&nbsp;         anims\[event]:Play(AbilityConfigurations\[event].FadeTime.Value, AbilityConfigurations\[event].Weight.Value, AbilityConfigurations\[event].Speed.Value);

&nbsp;       else

&nbsp;         anims\[event].Looped = false;

&nbsp;         anims\[event].Priority = Enum.AnimationPriority.Action;

&nbsp;         anims\[event]:Play(0.1, 100, 1);

&nbsp;       end;

&nbsp;     end;

&nbsp;   end);

&nbsp;   table.insert(self.\_connections, eventConn);

&nbsp;   

&nbsp;   local healthConn = Humanoid.HealthChanged:Connect(function(health: number) 

&nbsp;     healthAmount.Text = tostring(math.round(health));

&nbsp;     healthVisualizer.Size = UDim2.new(1, 0, health / Humanoid.MaxHealth, 0);

&nbsp;   end);

&nbsp;   table.insert(self.\_connections, healthConn);

&nbsp;   

&nbsp;   -- Cleanup upon character death or character change

&nbsp;   local diedConn = Humanoid.Died:Connect(function()

&nbsp;     self:stop();

&nbsp;   end);

&nbsp;   table.insert(self.\_connections, diedConn);

&nbsp; end

&nbsp; workspace.CurrentCamera.CameraSubject = Character:WaitForChild("Humanoid")

&nbsp; print("Running stamina system!");



&nbsp; return self;

end;



function Movement:stop()

&nbsp; -- Stop the main loop

&nbsp; self.\_stopLoop = true;

&nbsp; if (self.\_loop) then

&nbsp;   -- task.cancel is only available in newer Luau, fallback to setting flag

&nbsp;   self.\_loop = nil;

&nbsp; end;

&nbsp; -- Disconnect all connections

&nbsp; for \_, conn in self.\_connections do

&nbsp;   if (conn and conn.Disconnect) then

&nbsp;     conn:Disconnect();

&nbsp;   end;

&nbsp; end;

&nbsp; self.\_connections = {};

end;



return Movement



