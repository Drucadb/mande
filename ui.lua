--[[
    OrionLib CS2 Edition
    Redesign moderno estilo Counter-Strike 2
    - Sem telemetria / sem reporter Sirius
    - Bugs corrigidos (Bind, Colorpicker, SaveCfg)
    - Visual dark + accent amarelo CS2
    - Fontes condensadas e bordas retas
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════
--  TEMA CS2
-- ═══════════════════════════════════════════════════════════
local OrionLib = {
    Elements = {},
    ThemeObjects = {},
    Connections = {},
    Flags = {},
    Themes = {
        CS2 = {
            Main        = Color3.fromRGB(14, 16, 18),
            Second      = Color3.fromRGB(26, 29, 33),
            Stroke      = Color3.fromRGB(45, 49, 54),
            Divider     = Color3.fromRGB(45, 49, 54),
            Text        = Color3.fromRGB(230, 232, 235),
            TextDark    = Color3.fromRGB(140, 145, 150),
            Accent      = Color3.fromRGB(245, 184, 0),
            AccentDark  = Color3.fromRGB(180, 134, 0),
            Danger      = Color3.fromRGB(220, 60, 60),
            Success     = Color3.fromRGB(90, 200, 120),
        },
        Dark = {
            Main        = Color3.fromRGB(20, 20, 20),
            Second      = Color3.fromRGB(30, 30, 30),
            Stroke      = Color3.fromRGB(55, 55, 55),
            Divider     = Color3.fromRGB(55, 55, 55),
            Text        = Color3.fromRGB(235, 235, 235),
            TextDark    = Color3.fromRGB(150, 150, 150),
            Accent      = Color3.fromRGB(120, 120, 255),
            AccentDark  = Color3.fromRGB(80, 80, 200),
            Danger      = Color3.fromRGB(220, 60, 60),
            Success     = Color3.fromRGB(90, 200, 120),
        },
    },
    SelectedTheme = "CS2",
    Folder = nil,
    SaveCfg = false,
}

local ACCENT = OrionLib.Themes[OrionLib.SelectedTheme].Accent
local ACCENT_DARK = OrionLib.Themes[OrionLib.SelectedTheme].AccentDark
local DANGER = OrionLib.Themes[OrionLib.SelectedTheme].Danger
local SUCCESS = OrionLib.Themes[OrionLib.SelectedTheme].Success

-- ═══════════════════════════════════════════════════════════
--  SCREENGUI
-- ═══════════════════════════════════════════════════════════
local Orion = Instance.new("ScreenGui")
Orion.Name = "OrionCS2"
Orion.ResetOnSpawn = false
Orion.IgnoreGuiInset = true

if gethui then
    Orion.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(Orion)
    Orion.Parent = game.CoreGui
else
    Orion.Parent = game.CoreGui
end

-- Limpa instâncias antigas
local parentGui = Orion.Parent
for _, v in ipairs(parentGui:GetChildren()) do
    if v.Name == Orion.Name and v ~= Orion then
        v:Destroy()
    end
end

function OrionLib:IsRunning()
    return Orion.Parent ~= nil
end

local function AddConnection(Signal, Func)
    if not OrionLib:IsRunning() then return end
    local c = Signal:Connect(Func)
    table.insert(OrionLib.Connections, c)
    return c
end

task.spawn(function()
    while OrionLib:IsRunning() do
        task.wait(0.5)
    end
    for _, c in ipairs(OrionLib.Connections) do
        pcall(function() c:Disconnect() end)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════════════════════════
local function Create(Name, Props, Children)
    local obj = Instance.new(Name)
    for k, v in pairs(Props or {}) do
        obj[k] = v
    end
    for _, child in ipairs(Children or {}) do
        child.Parent = obj
    end
    return obj
end

local function SetProps(Element, Props)
    for k, v in pairs(Props or {}) do
        Element[k] = v
    end
    return Element
end

local function SetChildren(Element, Children)
    for _, child in ipairs(Children or {}) do
        child.Parent = Element
    end
    return Element
end

local function Round(Number, Factor)
    if Factor == 0 then return Number end
    return math.floor((Number / Factor) + 0.5) * Factor
end

local function AddDraggingFunctionality(DragPoint, Main)
    pcall(function()
        local Dragging, DragInput, MousePos, FramePos = false
        DragPoint.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1
               or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                MousePos = Input.Position
                FramePos = Main.Position
                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)
        DragPoint.InputChanged:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement
               or Input.UserInputType == Enum.UserInputType.Touch then
                DragInput = Input
            end
        end)
        UserInputService.InputChanged:Connect(function(Input)
            if Input == DragInput and Dragging then
                local Delta = Input.Position - MousePos
                TweenService:Create(Main, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(
                        FramePos.X.Scale, FramePos.X.Offset + Delta.X,
                        FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y
                    )
                }):Play()
            end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════
--  ELEMENTOS BASE
-- ═══════════════════════════════════════════════════════════
local function CreateElement(Name, Func)
    OrionLib.Elements[Name] = Func
end
local function MakeElement(Name, ...)
    return OrionLib.Elements[Name](...)
end

CreateElement("Corner", function(r)
    return Create("UICorner", { CornerRadius = UDim.new(0, r or 2) })
end)

CreateElement("Stroke", function(Color, Thickness, Transparency)
    return Create("UIStroke", {
        Color = Color or OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
        Thickness = Thickness or 1,
        Transparency = Transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end)

CreateElement("List", function(Scale, Offset)
    return Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(Scale or 0, Offset or 0),
    })
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
    return Create("UIPadding", {
        PaddingBottom = UDim.new(0, Bottom or 4),
        PaddingLeft   = UDim.new(0, Left or 4),
        PaddingRight  = UDim.new(0, Right or 4),
        PaddingTop    = UDim.new(0, Top or 4),
    })
end)

CreateElement("TFrame", function()
    return Create("Frame", { BackgroundTransparency = 1 })
end)

CreateElement("Frame", function(Color)
    return Create("Frame", {
        BackgroundColor3 = Color or Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    })
end)

CreateElement("RoundFrame", function(Color, Radius)
    return Create("Frame", {
        BackgroundColor3 = Color or Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, { Create("UICorner", { CornerRadius = UDim.new(0, Radius or 2) }) })
end)

CreateElement("Button", function()
    return Create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
end)

CreateElement("ScrollFrame", function(Color, Width)
    return Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = Width or 4,
        ScrollBarImageColor3 = Color or ACCENT,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
    })
end)

CreateElement("Label", function(Text, TextSize, Transparency)
    return Create("TextLabel", {
        Text = Text or "",
        TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
        TextTransparency = Transparency or 0,
        TextSize = TextSize or 14,
        Font = Enum.Font.GothamMedium,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true,
    })
end)

CreateElement("Image", function(ID)
    return Create("ImageLabel", {
        Image = ID or "",
        BackgroundTransparency = 1,
    })
end)

-- ═══════════════════════════════════════════════════════════
--  TEMA DINÂMICO
-- ═══════════════════════════════════════════════════════════
local function ReturnProperty(Object)
    if Object:IsA("Frame") or Object:IsA("TextButton") then return "BackgroundColor3" end
    if Object:IsA("ScrollingFrame") then return "ScrollBarImageColor3" end
    if Object:IsA("UIStroke") then return "Color" end
    if Object:IsA("TextLabel") or Object:IsA("TextBox") then return "TextColor3" end
    if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then return "ImageColor3" end
end

local function AddThemeObject(Object, Type)
    OrionLib.ThemeObjects[Type] = OrionLib.ThemeObjects[Type] or {}
    table.insert(OrionLib.ThemeObjects[Type], Object)
    local prop = ReturnProperty(Object)
    if prop then
        Object[prop] = OrionLib.Themes[OrionLib.SelectedTheme][Type]
    end
    return Object
end

function OrionLib:SetTheme(Name)
    if not OrionLib.Themes[Name] then return end
    OrionLib.SelectedTheme = Name
    for typeName, objects in pairs(OrionLib.ThemeObjects) do
        for _, obj in ipairs(objects) do
            if obj.Parent then
                local prop = ReturnProperty(obj)
                if prop then
                    obj[prop] = OrionLib.Themes[Name][typeName]
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
--  CONFIG SAVE / LOAD
-- ═══════════════════════════════════════════════════════════
local function PackColor(c) return {R=c.R*255, G=c.G*255, B=c.B*255} end
local function UnpackColor(c) return Color3.fromRGB(c.R, c.G, c.B) end

local function LoadCfg(Config)
    local ok, Data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(Config)
    end)
    if not ok then return end
    for k, v in pairs(Data) do
        local flag = OrionLib.Flags[k]
        if flag and flag.Set then
            task.spawn(function()
                if flag.Type == "Colorpicker" then
                    flag:Set(UnpackColor(v))
                else
                    flag:Set(v)
                end
            end)
        end
    end
end

local function SaveCfg(Name)
    if not OrionLib.SaveCfg then return end
    if not writefile then return end
    local Data = {}
    for k, v in pairs(OrionLib.Flags) do
        if v.Save then
            if v.Type == "Colorpicker" then
                Data[k] = PackColor(v.Value)
            else
                Data[k] = v.Value
            end
        end
    end
    pcall(function()
        writefile(OrionLib.Folder .. "/" .. Name .. ".txt",
                  game:GetService("HttpService"):JSONEncode(Data))
    end)
end

-- ═══════════════════════════════════════════════════════════
--  NOTIFICAÇÕES
-- ═══════════════════════════════════════════════════════════
local NotificationHolder = SetChildren(
    SetProps(MakeElement("TFrame"), {
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 320, 1, -20),
        AnchorPoint = Vector2.new(1, 1),
        Parent = Orion,
    }),
    {
        SetProps(MakeElement("List"), {
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        }),
    }
)

function OrionLib:MakeNotification(cfg)
    task.spawn(function()
        cfg.Name = cfg.Name or "NOTIFICAÇÃO"
        cfg.Content = cfg.Content or ""
        cfg.Time = cfg.Time or 5
        cfg.Icon = cfg.Icon or "rbxassetid://14978048121"

        local parent = SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = NotificationHolder,
        })

        local frame = SetChildren(SetProps(MakeElement("Frame"), {
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(1, 40, 0, 0),
            ClipsDescendants = true,
        }), {
            Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
            Create("UIStroke", { Color = OrionLib.Themes[OrionLib.SelectedTheme].Stroke, Thickness = 1 }),
            SetProps(MakeElement("Frame"), {
                Size = UDim2.new(0, 3, 1, 0),
                BackgroundColor3 = ACCENT,
                BorderSizePixel = 0,
            }),
            SetProps(MakeElement("Padding"), {}),
            SetProps(MakeElement("Image", cfg.Icon), {
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 14, 0, 14),
                ImageColor3 = ACCENT,
            }),
            SetProps(MakeElement("Label", string.upper(cfg.Name), 13), {
                Size = UDim2.new(1, -50, 0, 18),
                Position = UDim2.new(0, 42, 0, 12),
                Font = Enum.Font.GothamBlack,
                TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
            }),
            SetProps(MakeElement("Label", cfg.Content, 12), {
                Size = UDim2.new(1, -56, 0, 0),
                Position = UDim2.new(0, 42, 0, 32),
                Font = Enum.Font.GothamMedium,
                TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark,
                TextWrapped = true,
                AutomaticSize = Enum.AutomaticSize.Y,
            }),
            SetProps(MakeElement("Frame"), {
                Size = UDim2.new(1, 0, 0, 12),
                Position = UDim2.new(0, 0, 1, -12),
                BackgroundTransparency = 1,
            }),
        })

        TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0),
        }):Play()

        task.wait(cfg.Time)

        TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 40, 0, 0),
        }):Play()
        task.wait(0.4)
        parent:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════════════════════════
function OrionLib:Init()
    if not OrionLib.SaveCfg then return end
    if not isfile then return end
    pcall(function()
        local path = OrionLib.Folder .. "/" .. game.GameId .. ".txt"
        if isfile(path) then
            LoadCfg(readfile(path))
            OrionLib:MakeNotification({
                Name = "Config",
                Content = "Configuração auto-carregada para o jogo " .. game.GameId,
                Time = 4,
            })
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  WINDOW CS2
-- ═══════════════════════════════════════════════════════════
function OrionLib:MakeWindow(cfg)
    cfg = cfg or {}
    cfg.Name         = cfg.Name or "ORION HUB"
    cfg.ConfigFolder = cfg.ConfigFolder or cfg.Name
    cfg.SaveConfig   = cfg.SaveConfig or false
    cfg.IntroEnabled = (cfg.IntroEnabled == nil) and true or cfg.IntroEnabled
    cfg.IntroText    = cfg.IntroText or "CONNECTING..."
    cfg.CloseCallback= cfg.CloseCallback or function() end
    OrionLib.Folder  = cfg.ConfigFolder
    OrionLib.SaveCfg = cfg.SaveConfig

    if cfg.SaveConfig and makefolder and isfolder then
        if not isfolder(cfg.ConfigFolder) then
            makefolder(cfg.ConfigFolder)
        end
    end

    local Minimized = false
    local UIHidden = false
    local FirstTab = true

    -- ═══ CORPO DA JANELA ═══
    local Main = AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
        Parent = Orion,
        Position = UDim2.new(0.5, -300, 0.5, -175),
        Size = UDim2.new(0, 600, 0, 350),
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }), {
        Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
        AddThemeObject(MakeElement("Stroke", nil, 2, 0), "Stroke"),
    }), "Main")

    -- ═══ TOP BAR ═══
    local TopBar = AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
        Parent = Main,
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
        BorderSizePixel = 0,
    }), {
        SetProps(MakeElement("Frame"), {
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = ACCENT,
            BorderSizePixel = 0,
        }),
    }), "Second")

    SetProps(MakeElement("Frame"), {
        Parent = TopBar,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 14, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
    }).Parent = TopBar

    local logoInner = SetProps(MakeElement("Frame"), {
        Parent = TopBar,
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 20, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
        BorderSizePixel = 0,
    })

    local Title = SetProps(MakeElement("Label", string.upper(cfg.Name), 16), {
        Parent = TopBar,
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.new(0, 50, 0, 0),
        Font = Enum.Font.GothamBlack,
        TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
    })

    local Subtitle = SetProps(MakeElement("Label", "v1.0 • CS2 EDITION", 10), {
        Parent = TopBar,
        Size = UDim2.new(1, -120, 0, 14),
        Position = UDim2.new(0, 50, 1, -18),
        Font = Enum.Font.GothamBold,
        TextColor3 = ACCENT,
        TextTransparency = 0.15,
    })

    local BtnHolder = SetProps(MakeElement("TFrame"), {
        Parent = TopBar,
        Size = UDim2.new(0, 74, 1, 0),
        Position = UDim2.new(1, -74, 0, 0),
    })

    local function MakeIconBtn(icon, color, xPos)
        local btn = SetChildren(SetProps(MakeElement("Button"), {
            Parent = BtnHolder,
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0, xPos, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
        }), {
            SetProps(MakeElement("Image", icon), {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                ImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark,
            }),
        })
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn:FindFirstChildOfClass("ImageLabel"),
                TweenInfo.new(0.15), {ImageColor3 = color}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn:FindFirstChildOfClass("ImageLabel"),
                TweenInfo.new(0.15), {ImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark}):Play()
        end)
        return btn
    end

    local MinimizeBtn = MakeIconBtn("rbxassetid://10734898355", ACCENT, 4)
    local CloseBtn    = MakeIconBtn("rbxassetid://10747384394", DANGER, 40)

    local DragPoint = SetProps(MakeElement("TFrame"), {
        Parent = TopBar,
        Size = UDim2.new(1, -160, 1, 0),
        Position = UDim2.new(0, 50, 0, 0),
        BackgroundTransparency = 1,
    })
    AddDraggingFunctionality(DragPoint, Main)

    -- ═══ SIDEBAR ═══
    local Sidebar = AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
        Parent = Main,
        Size = UDim2.new(0, 150, 1, -46),
        Position = UDim2.new(0, 0, 0, 46),
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
        BorderSizePixel = 0,
    }), {
        SetProps(MakeElement("Frame"), {
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(1, -1, 0, 0),
            BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
            BorderSizePixel = 0,
        }),
    }), "Second")

    local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", ACCENT, 3), {
        Parent = Sidebar,
        Size = UDim2.new(1, 0, 1, -50),
        Position = UDim2.new(0, 0, 0, 0),
    }), {
        MakeElement("List", 0, 2),
        MakeElement("Padding", 8, 8, 8, 8),
    }), "Divider")

    AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
    end)

    local Footer = AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
        Parent = Sidebar,
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 1, -50),
        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
        BorderSizePixel = 0,
    }), {
        SetProps(MakeElement("Frame"), {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
            BorderSizePixel = 0,
        }),
        SetProps(MakeElement("Image", "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=150&height=150&format=png"), {
            Parent = Sidebar,
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0, 10, 1, -40),
            ImageColor3 = Color3.new(1, 1, 1),
        }),
        SetProps(MakeElement("Label", LocalPlayer.DisplayName, 12), {
            Parent = Sidebar,
            Size = UDim2.new(1, -50, 0, 14),
            Position = UDim2.new(0, 48, 1, -35),
            Font = Enum.Font.GothamBold,
            TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
        }),
        SetProps(MakeElement("Label", "@" .. LocalPlayer.Name, 10), {
            Parent = Sidebar,
            Size = UDim2.new(1, -50, 0, 12),
            Position = UDim2.new(0, 48, 1, -20),
            Font = Enum.Font.GothamMedium,
            TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark,
        }),
    }), "Second")

    -- ═══ INTRO ═══
    local function LoadSequence()
        Main.Visible = false
        local bg = SetProps(MakeElement("Frame"), {
            Parent = Orion,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })

        local box = SetProps(MakeElement("Frame"), {
            Parent = bg,
            Size = UDim2.new(0, 260, 0, 100),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 3) }).Parent = box
        local stroke = MakeElement("Stroke", ACCENT, 2, 1)
        stroke.Parent = box

        local logo = SetProps(MakeElement("Frame"), {
            Parent = box,
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0.5, 0, 0, 20),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = ACCENT,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 2) }).Parent = logo

        local txt = SetProps(MakeElement("Label", cfg.IntroText, 14), {
            Parent = box,
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 1, -38),
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.GothamBlack,
            TextColor3 = ACCENT,
            TextTransparency = 1,
        })

        local bar = SetProps(MakeElement("Frame"), {
            Parent = box,
            Size = UDim2.new(0.6, 0, 0, 2),
            Position = UDim2.new(0.5, 0, 1, -14),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = ACCENT,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })

        TweenService:Create(bg, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play()
        TweenService:Create(box, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
        TweenService:Create(logo, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
        task.wait(0.5)
        TweenService:Create(txt, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
        TweenService:Create(bar, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
        task.wait(1.5)
        TweenService:Create(bg, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(box, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
        TweenService:Create(logo, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(txt, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(bar, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        task.wait(0.35)
        bg:Destroy()
        Main.Visible = true
    end

    if cfg.IntroEnabled then
        LoadSequence()
    end

    -- ═══ EVENTOS DE JANELA ═══
    AddConnection(CloseBtn.MouseButton1Click, function()
        Main.Visible = false
        UIHidden = true
        OrionLib:MakeNotification({
            Name = "Interface Oculta",
            Content = "Aperte RightShift para reabrir",
            Time = 4,
        })
        cfg.CloseCallback()
    end)

    AddConnection(UserInputService.InputBegan, function(Input)
        if Input.KeyCode == Enum.KeyCode.RightShift and UIHidden then
            Main.Visible = true
            UIHidden = false
        end
    end)

    AddConnection(MinimizeBtn.MouseButton1Click, function()
        Minimized = not Minimized
        if Minimized then
            TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                Size = UDim2.new(0, 260, 0, 46),
            }):Play()
            Sidebar.Visible = false
            for _, v in ipairs(Main:GetChildren()) do
                if v.Name == "ItemContainer" then v.Visible = false end
            end
        else
            TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                Size = UDim2.new(0, 600, 0, 350),
            }):Play()
            Sidebar.Visible = true
            for _, v in ipairs(Main:GetChildren()) do
                if v.Name == "ItemContainer" and v:GetAttribute("Active") then
                    v.Visible = true
                end
            end
        end
    end)

    -- ═══ API DE TABS ═══
    local TabFunction = {}

    function TabFunction:MakeTab(TabConfig)
        TabConfig = TabConfig or {}
        TabConfig.Name = TabConfig.Name or "TAB"
        TabConfig.Icon = TabConfig.Icon or ""

        local TabBtn = SetChildren(SetProps(MakeElement("Button"), {
            Parent = TabHolder,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 0.85,
            BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
        }), {
            Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
            SetProps(MakeElement("Frame"), {
                Size = UDim2.new(0, 3, 1, 0),
                BackgroundColor3 = ACCENT,
                BorderSizePixel = 0,
                Visible = false,
                Name = "AccentBar",
            }),
            SetProps(MakeElement("Label", string.upper(TabConfig.Name), 12), {
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                Font = Enum.Font.GothamBold,
                TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark,
                Name = "Title",
            }),
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 2) }).Parent = TabBtn.AccentBar

        local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", ACCENT, 4), {
            Size = UDim2.new(1, -150, 1, -46),
            Position = UDim2.new(0, 150, 0, 46),
            Parent = Main,
            Visible = false,
            Name = "ItemContainer",
        }), {
            MakeElement("List", 0, 8),
            MakeElement("Padding", 20, 16, 16, 16),
        }), "Divider")

        AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 40)
        end)

        if FirstTab then
            FirstTab = false
            TabBtn.AccentBar.Visible = true
            TabBtn.Title.TextColor3 = ACCENT
            TabBtn.Title.Font = Enum.Font.GothamBlack
            Container.Visible = true
            Container:SetAttribute("Active", true)
        end

        AddConnection(TabBtn.MouseButton1Click, function()
            for _, t in ipairs(TabHolder:GetChildren()) do
                if t:IsA("TextButton") then
                    t.Title.TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark
                    t.Title.Font = Enum.Font.GothamBold
                    t.AccentBar.Visible = false
                end
            end
            for _, c in ipairs(Main:GetChildren()) do
                if c.Name == "ItemContainer" then
                    c.Visible = false
                    c:SetAttribute("Active", false)
                end
            end
            TabBtn.AccentBar.Visible = true
            TabBtn.Title.TextColor3 = ACCENT
            TabBtn.Title.Font = Enum.Font.GothamBlack
            Container.Visible = true
            Container:SetAttribute("Active", true)
        end)

        -- ═══ ELEMENTOS ═══
        local function GetElements(Parent)
            local E = {}

            function E:AddLabel(Text)
                local card = AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                    Parent = Parent,
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
                    BorderSizePixel = 0,
                }), {
                    Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SetProps(MakeElement("Frame"), {
                        Size = UDim2.new(0, 3, 1, 0),
                        BackgroundColor3 = ACCENT,
                        BorderSizePixel = 0,
                    }),
                    AddThemeObject(SetProps(MakeElement("Label", Text, 13), {
                        Size = UDim2.new(1, -20, 1, 0),
                        Position = UDim2.new(0, 14, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content",
                    }), "Text"),
                }), "Second")
                local F = {}
                function F:Set(t) card.Content.Text = t end
                return F
            end

            function E:AddParagraph(Text, Content)
                local card = AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                    Parent = Parent,
                    Size = UDim2.new(1, 0, 0, 60),
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
                    BorderSizePixel = 0,
                }), {
                    Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    AddThemeObject(SetProps(MakeElement("Label", string.upper(Text), 12), {
                        Size = UDim2.new(1, -24, 0, 14),
                        Position = UDim2.new(0, 14, 0, 10),
                        Font = Enum.Font.GothamBlack,
                        TextColor3 = ACCENT,
                        Name = "Title",
                    }), "Text"),
                    AddThemeObject(SetProps(MakeElement("Label", "", 12), {
                        Size = UDim2.new(1, -24, 0, 0),
                        Position = UDim2.new(0, 14, 0, 28),
                        Font = Enum.Font.GothamMedium,
                        Name = "Content",
                        TextWrapped = true,
                    }), "TextDark"),
                }), "Second")
                card.Content:GetPropertyChangedSignal("Text"):Connect(function()
                    card.Content.Size = UDim2.new(1, -24, 0, card.Content.TextBounds.Y)
                    card.Size = UDim2.new(1, 0, 0, card.Content.TextBounds.Y + 40)
                end)
                card.Content.Text = Content
                local F = {}
                function F:Set(t) card.Content.Text = t end
                return F
            end

            function E:AddButton(Cfg)
                Cfg = Cfg or {}
                Cfg.Name = Cfg.Name or "Button"
                Cfg.Callback = Cfg.Callback or function() end

                local click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 5,
                })

                local btn = AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                    Parent = Parent,
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
                    BorderSizePixel = 0,
                }), {
                    Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SetProps(MakeElement("Frame"), {
                        Size = UDim2.new(0, 3, 1, 0),
                        BackgroundColor3 = ACCENT,
                        BorderSizePixel = 0,
                        Name = "AccentBar",
                    }),
                    SetProps(MakeElement("Label", string.upper(Cfg.Name), 13), {
                        Size = UDim2.new(1, -20, 1, 0),
                        Position = UDim2.new(0, 14, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content",
                    }),
                    click,
                }), "Second")
                Create("UICorner", { CornerRadius = UDim.new(0, 2) }).Parent = btn.AccentBar

                AddConnection(click.MouseEnter, function()
                    TweenService:Create(btn, TweenInfo.new(0.15), {
                        BackgroundColor3 = Color3.fromRGB(34, 38, 43),
                    }):Play()
                    TweenService:Create(btn.AccentBar, TweenInfo.new(0.15), {
                        Size = UDim2.new(0, 5, 1, 0),
                    }):Play()
                end)
                AddConnection(click.MouseLeave, function()
                    TweenService:Create(btn, TweenInfo.new(0.15), {
                        BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
                    }):Play()
                    TweenService:Create(btn.AccentBar, TweenInfo.new(0.15), {
                        Size = UDim2.new(0, 3, 1, 0),
                    }):Play()
                end)
                AddConnection(click.MouseButton1Click, function()
                    task.spawn(Cfg.Callback)
                end)
                return { Set = function(_, t) btn.Content.Text = string.upper(t) end }
            end

            function E:AddToggle(Cfg)
                Cfg = Cfg or {}
                Cfg.Name = Cfg.Name or "Toggle"
                Cfg.Default = Cfg.Default or false
                Cfg.Callback = Cfg.Callback or function() end
                Cfg.Flag = Cfg.Flag
                Cfg.Save = Cfg.Save or false

                local Toggle = {Value = Cfg.Default, Type = "Toggle", Save = Cfg.Save}

                local click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 5,
                })

                local box = SetProps(MakeElement("Frame"), {
                    Size = UDim2.new(0, 34, 0, 18),
                    Position = UDim2.new(1, -20, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
                    BorderSizePixel = 0,
                })
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = box

                local knob = SetProps(MakeElement("Frame"), {
                    Parent = box,
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 2, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                    BorderSizePixel = 0,
                })
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = knob

                local frame = AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                    Parent = Parent,
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
                    BorderSizePixel = 0,
                }), {
                    Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SetProps(MakeElement("Label", string.upper(Cfg.Name), 13), {
                        Size = UDim2.new(1, -70, 1, 0),
                        Position = UDim2.new(0, 14, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content",
                    }),
                    box,
                    click,
                }), "Second")

                function Toggle:Set(Value)
                    self.Value = Value
                    TweenService:Create(box, TweenInfo.new(0.2), {
                        BackgroundColor3 = Value and ACCENT or OrionLib.Themes[OrionLib.SelectedTheme].Stroke,
                    }):Play()
                    TweenService:Create(knob, TweenInfo.new(0.2), {
                        Position = Value and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                        BackgroundColor3 = Value and Color3.new(1, 1, 1) or Color3.fromRGB(200, 200, 200),
                    }):Play()
                    Cfg.Callback(self.Value)
                end

                AddConnection(click.MouseButton1Click, function()
                    Toggle:Set(not Toggle.Value)
                    SaveCfg(game.GameId)
                end)

                Toggle:Set(Cfg.Default)
                if Cfg.Flag then OrionLib.Flags[Cfg.Flag] = Toggle end
                return Toggle
            end

            function E:AddSlider(Cfg)
                Cfg = Cfg or {}
                Cfg.Name = Cfg.Name or "Slider"
                Cfg.Min = Cfg.Min or 0
                Cfg.Max = Cfg.Max or 100
                Cfg.Increment = Cfg.Increment or 1
                Cfg.Default = Cfg.Default or 50
                Cfg.Callback = Cfg.Callback or function() end
                Cfg.ValueName = Cfg.ValueName or ""
                Cfg.Flag = Cfg.Flag
                Cfg.Save = Cfg.Save or false

                local Slider = {Value = Cfg.Default, Type = "Slider", Save = Cfg.Save}
                local Dragging = false

                local bar = SetProps(MakeElement("Frame"), {
                    Size = UDim2.new(1, -28, 0, 20),
                    Position = UDim2.new(0, 14, 0, 30),
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
                    BorderSizePixel = 0,
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 2) }).Parent = bar

                local fill = SetProps(MakeElement("Frame"), {
                    Parent = bar,
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = ACCENT,
                    BorderSizePixel = 0,
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 2) }).Parent = fill

                local valueLabel = SetProps(MakeElement("Label", "", 12), {
                    Parent = bar,
                    Size = UDim2.new(1, -8, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Font = Enum.Font.GothamBold,
                    TextColor3 = Color3.new(1, 1, 1),
                    Name = "Value",
                })

                local frame = AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                    Parent = Parent,
                    Size = UDim2.new(1, 0, 0, 60),
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
                    BorderSizePixel = 0,
                }), {
                    Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SetProps(MakeElement("Label", string.upper(Cfg.Name), 13), {
                        Size = UDim2.new(1, -28, 0, 18),
                        Position = UDim2.new(0, 14, 0, 8),
                        Font = Enum.Font.GothamBold,
                        Name = "Content",
                    }),
                    bar,
                }), "Second")

                bar.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1
                       or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true
                    end
                end)
                bar.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1
                       or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = false
                        SaveCfg(game.GameId)
                    end
                end)

                AddConnection(UserInputService.InputChanged, function(Input)
                    if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement
                       or Input.UserInputType == Enum.UserInputType.Touch) then
                        local x = math.clamp(
                            (Input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                        Slider:Set(Cfg.Min + (Cfg.Max - Cfg.Min) * x)
                    end
                end)

                function Slider:Set(Value)
                    self.Value = math.clamp(Round(Value, Cfg.Increment), Cfg.Min, Cfg.Max)
                    local pct = (self.Value - Cfg.Min) / (Cfg.Max - Cfg.Min)
                    TweenService:Create(fill, TweenInfo.new(0.1), {Size = UDim2.fromScale(pct, 1)}):Play()
                    bar.Value.Text = tostring(self.Value) .. " " .. Cfg.ValueName
                    Cfg.Callback(self.Value)
                end

                Slider:Set(Cfg.Default)
                if Cfg.Flag then OrionLib.Flags[Cfg.Flag] = Slider end
                return Slider
            end

            function E:AddDropdown(Cfg)
                Cfg = Cfg or {}
                Cfg.Name = Cfg.Name or "Dropdown"
                Cfg.Options = Cfg.Options or {}
                Cfg.Default = Cfg.Default or ""
                Cfg.Callback = Cfg.Callback or function() end
                Cfg.Flag = Cfg.Flag
                Cfg.Save = Cfg.Save or false

                local Dropdown = {
                    Value = Cfg.Default,
                    Options = Cfg.Options,
                    Buttons = {},
                    Toggled = false,
                    Type = "Dropdown",
                    Save = Cfg.Save,
                }
                if not table.find(Dropdown.Options, Dropdown.Value) then
                    Dropdown.Value = Dropdown.Options[1] or "..."
                end

                local list = MakeElement("List", 0, 2)
                local container = SetProps(MakeElement("ScrollFrame", ACCENT, 3), {
                    Parent = Parent,
                    Position = UDim2.new(0, 0, 0, 38),
                    Size = UDim2.new(1, 0, 1, -38),
                    Visible = false,
                })
                list.Parent = container
                container:SetAttribute("DropdownContainer", true)

                local click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 5,
                })

                local header = SetChildren(SetProps(MakeElement("Frame"), {
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true,
                    Name = "F",
                }), {
                    SetProps(MakeElement("Label", string.upper(Cfg.Name), 13), {
                        Size = UDim2.new(1, -140, 1, 0),
                        Position = UDim2.new(0, 14, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content",
                    }),
                    SetProps(MakeElement("Label", Dropdown.Value, 12), {
                        Size = UDim2.new(0, 100, 1, 0),
                        Position = UDim2.new(1, -134, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Font = Enum.Font.GothamBold,
                        TextColor3 = ACCENT,
                        Name = "Selected",
                    }),
                    SetProps(MakeElement("Image", "rbxassetid://10709790948"), {
                        Size = UDim2.new(0, 14, 0, 14),
                        Position = UDim2.new(1, -18, 0.5, 0),
                        AnchorPoint = Vector2.new(1, 0.5),
                        ImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark,
                        Name = "Arrow",
                    }),
                    click,
                })

                local frame = AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                    Parent = Parent,
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                }), {
                    Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    header,
                    container,
                }), "Second")

                list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    container.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 4)
                end)

                local function refreshOptions()
                    for _, v in pairs(Dropdown.Buttons) do v:Destroy() end
                    Dropdown.Buttons = {}
                    for _, opt in ipairs(Dropdown.Options) do
                        local btn = SetChildren(SetProps(MakeElement("Button"), {
                            Parent = container,
                            Size = UDim2.new(1, -8, 0, 26),
                            Position = UDim2.new(0, 4, 0, 0),
                            BackgroundTransparency = 0.85,
                            BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
                        }), {
                            Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                            SetProps(MakeElement("Label", opt, 12), {
                                Size = UDim2.new(1, -8, 1, 0),
                                Position = UDim2.new(0, 8, 0, 0),
                                Font = Enum.Font.GothamMedium,
                                Name = "Title",
                                TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
                            }),
                        })
                        btn.MouseButton1Click:Connect(function()
                            Dropdown:Set(opt)
                            SaveCfg(game.GameId)
                        end)
                        btn.MouseEnter:Connect(function()
                            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.6}):Play()
                        end)
                        btn.MouseLeave:Connect(function()
                            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.85}):Play()
                        end)
                        Dropdown.Buttons[opt] = btn
                    end
                end

                function Dropdown:Refresh(Options, Delete)
                    Dropdown.Options = Options
                    if Delete then
                        for _, v in pairs(Dropdown.Buttons) do v:Destroy() end
                        Dropdown.Buttons = {}
                    end
                    refreshOptions()
                end

                function Dropdown:Set(Value)
                    if not table.find(Dropdown.Options, Value) then
                        Dropdown.Value = "..."
                        header.Selected.Text = Dropdown.Value
                        return
                    end
                    Dropdown.Value = Value
                    header.Selected.Text = Value
                    Cfg.Callback(Value)
                end

                click.MouseButton1Click:Connect(function()
                    Dropdown.Toggled = not Dropdown.Toggled
                    container.Visible = Dropdown.Toggled
                    TweenService:Create(header.Arrow, TweenInfo.new(0.15), {
                        Rotation = Dropdown.Toggled and 180 or 0,
                    }):Play()
                    local h = Dropdown.Toggled and (math.min(#Dropdown.Options, 5) * 28 + 38) or 38
                    TweenService:Create(frame, TweenInfo.new(0.15), {
                        Size = UDim2.new(1, 0, 0, h),
                    }):Play()
                end)

                refreshOptions()
                Dropdown:Set(Dropdown.Value)
                if Cfg.Flag then OrionLib.Flags[Cfg.Flag] = Dropdown end
                return Dropdown
            end

            function E:AddBind(Cfg)
                Cfg = Cfg or {}
                Cfg.Name = Cfg.Name or "Bind"
                Cfg.Default = Cfg.Default or Enum.KeyCode.Unknown
                Cfg.Callback = Cfg.Callback or function() end
                Cfg.Flag = Cfg.Flag
                Cfg.Save = Cfg.Save or false

                local Bind = {Value = Cfg.Default.Name, Binding = false, Type = "Bind", Save = Cfg.Save}

                local click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 5,
                })

                local keyLabel = SetProps(MakeElement("Label", "NONE", 12), {
                    Size = UDim2.new(0, 60, 0, 20),
                    Position = UDim2.new(1, -20, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Font = Enum.Font.GothamBlack,
                    TextColor3 = ACCENT,
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
                    BackgroundTransparency = 0,
                    Name = "Key",
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 2) }).Parent = keyLabel

                local frame = AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                    Parent = Parent,
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
                    BorderSizePixel = 0,
                }), {
                    Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SetProps(MakeElement("Label", string.upper(Cfg.Name), 13), {
                        Size = UDim2.new(1, -80, 1, 0),
                        Position = UDim2.new(0, 14, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content",
                    }),
                    keyLabel,
                    click,
                }), "Second")

                click.MouseButton1Click:Connect(function()
                    if Bind.Binding then return end
                    Bind.Binding = true
                    keyLabel.Text = "[...]"
                    keyLabel.TextColor3 = DANGER
                end)

                local blacklist = {
                    [Enum.KeyCode.Unknown]=true, [Enum.KeyCode.W]=true, [Enum.KeyCode.A]=true,
                    [Enum.KeyCode.S]=true, [Enum.KeyCode.D]=true, [Enum.KeyCode.Up]=true,
                    [Enum.KeyCode.Down]=true, [Enum.KeyCode.Left]=true, [Enum.KeyCode.Right]=true,
                    [Enum.KeyCode.Tab]=true, [Enum.KeyCode.Backspace]=true, [Enum.KeyCode.Escape]=true,
                }

                AddConnection(UserInputService.InputBegan, function(Input)
                    if UserInputService:GetFocusedTextBox() then return end
                    if Bind.Binding then
                        local key = nil
                        if not blacklist[Input.KeyCode] and Input.KeyCode ~= Enum.KeyCode.Unknown then
                            key = Input.KeyCode
                        elseif Input.UserInputType == Enum.UserInputType.MouseButton1
                            or Input.UserInputType == Enum.UserInputType.MouseButton2
                            or Input.UserInputType == Enum.UserInputType.MouseButton3 then
                            key = Input.UserInputType
                        end
                        if key then
                            Bind:Set(key)
                            SaveCfg(game.GameId)
                        end
                    elseif (Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value) then
                        Cfg.Callback()
                    end
                end)

                function Bind:Set(Key)
                    self.Binding = false
                    if typeof(Key) == "EnumItem" then
                        self.Value = Key.Name
                    else
                        self.Value = tostring(Key)
                    end
                    keyLabel.Text = string.upper(self.Value)
                    keyLabel.TextColor3 = ACCENT
                    keyLabel.Size = UDim2.new(0, math.max(50, keyLabel.TextBounds.X + 16), 0, 20)
                end

                Bind:Set(Cfg.Default)
                if Cfg.Flag then OrionLib.Flags[Cfg.Flag] = Bind end
                return Bind
            end

            function E:AddTextbox(Cfg)
                Cfg = Cfg or {}
                Cfg.Name = Cfg.Name or "Textbox"
                Cfg.Default = Cfg.Default or ""
                Cfg.Callback = Cfg.Callback or function() end

                local txt = SetProps(MakeElement("TextBox"), {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = Cfg.Default,
                    TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text,
                    PlaceholderText = "...",
                    PlaceholderColor3 = OrionLib.Themes[OrionLib.SelectedTheme].TextDark,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ClearTextOnFocus = false,
                })

                local box = SetProps(MakeElement("Frame"), {
                    Size = UDim2.new(0, 120, 0, 24),
                    Position = UDim2.new(1, -14, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Main,
                    BorderSizePixel = 0,
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 2) }).Parent = box
                txt.Parent = box

                local frame = AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                    Parent = Parent,
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
                    BorderSizePixel = 0,
                }), {
                    Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SetProps(MakeElement("Label", string.upper(Cfg.Name), 13), {
                        Size = UDim2.new(1, -150, 1, 0),
                        Position = UDim2.new(0, 14, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content",
                    }),
                    box,
                }), "Second")

                txt.FocusLost:Connect(function()
                    Cfg.Callback(txt.Text)
                end)
                return { Set = function(_, v) txt.Text = v end }
            end

            function E:AddColorpicker(Cfg)
                Cfg = Cfg or {}
                Cfg.Name = Cfg.Name or "Colorpicker"
                Cfg.Default = Cfg.Default or Color3.fromRGB(255, 255, 255)
                Cfg.Callback = Cfg.Callback or function() end
                Cfg.Flag = Cfg.Flag
                Cfg.Save = Cfg.Save or false

                local h, s, v = Cfg.Default:ToHSV()
                local Picker = {Value = Cfg.Default, Type = "Colorpicker", Save = Cfg.Save}

                local colorBox = SetProps(MakeElement("Frame"), {
                    Size = UDim2.new(0, 22, 0, 22),
                    Position = UDim2.new(1, -14, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Cfg.Default,
                    BorderSizePixel = 0,
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 2) }).Parent = colorBox

                local click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 5,
                })

                local hueBar = SetProps(MakeElement("Frame"), {
                    Size = UDim2.new(1, -28, 0, 14),
                    Position = UDim2.new(0, 14, 0, 44),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 2) }).Parent = hueBar
                Create("UIGradient", {
                    Parent = hueBar,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
                    }),
                })

                local hueKnob = SetProps(MakeElement("Frame"), {
                    Parent = hueBar,
                    Size = UDim2.new(0, 6, 1, 0),
                    Position = UDim2.new(h, 0, 0, 0),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                })

                local satVal = SetProps(MakeElement("Frame"), {
                    Size = UDim2.new(1, -28, 0, 60),
                    Position = UDim2.new(0, 14, 0, 66),
                    BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                    BorderSizePixel = 0,
                    Visible = false,
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 2) }).Parent = satVal

                local satGrad = Create("UIGradient", {
                    Parent = satVal,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
                    }),
                    Rotation = 0,
                })

                local frame = AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                    Parent = Parent,
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                }), {
                    Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SetProps(MakeElement("Frame"), {
                        Size = UDim2.new(1, 0, 0, 34),
                        BackgroundTransparency = 1,
                        ClipsDescendants = true,
                        Name = "F",
                    }),
                    colorBox,
                    click,
                }), "Second")

                frame.F.Parent = frame
                colorBox.Parent = frame.F
                click.Parent = frame.F
                SetProps(MakeElement("Label", string.upper(Cfg.Name), 13), {
                    Parent = frame.F,
                    Size = UDim2.new(1, -80, 1, 0),
                    Position = UDim2.new(0, 14, 0, 0),
                    Font = Enum.Font.GothamBold,
                    Name = "Content",
                })
                hueBar.Parent = frame
                satVal.Parent = frame
                hueKnob.Parent = hueBar

                local hueConn, svConn

                click.MouseButton1Click:Connect(function()
                    Picker.Toggled = not Picker.Toggled
                    local targetH = Picker.Toggled and 180 or 34
                    satVal.Visible = Picker.Toggled
                    TweenService:Create(frame, TweenInfo.new(0.2), {
                        Size = UDim2.new(1, 0, 0, targetH),
                    }):Play()
                end)

                hueBar.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if hueConn then hueConn:Disconnect() end
                        hueConn = RunService.RenderStepped:Connect(function()
                            local x = math.clamp((Mouse.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                            hueKnob.Position = UDim2.new(x, 0, 0, 0)
                            h = x
                            satVal.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                            Picker:Set(Color3.fromHSV(h, s, v))
                            SaveCfg(game.GameId)
                        end)
                    end
                end)
                hueBar.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and hueConn then
                        hueConn:Disconnect(); hueConn = nil
                    end
                end)

                satVal.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if svConn then svConn:Disconnect() end
                        svConn = RunService.RenderStepped:Connect(function()
                            local x = math.clamp((Mouse.X - satVal.AbsolutePosition.X) / satVal.AbsoluteSize.X, 0, 1)
                            local y = math.clamp((Mouse.Y - satVal.AbsolutePosition.Y) / satVal.AbsoluteSize.Y, 0, 1)
                            s = x
                            v = 1 - y
                            Picker:Set(Color3.fromHSV(h, s, v))
                            SaveCfg(game.GameId)
                        end)
                    end
                end)
                satVal.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and svConn then
                        svConn:Disconnect(); svConn = nil
                    end
                end)

                function Picker:Set(Value)
                    self.Value = Value
                    colorBox.BackgroundColor3 = Value
                    Cfg.Callback(Value)
                end

                Picker:Set(Cfg.Default)
                if Cfg.Flag then OrionLib.Flags[Cfg.Flag] = Picker end
                return Picker
            end

            return E
        end

        -- seções + elementos
        local ElementFunction = {}

        function ElementFunction:AddSection(SectionCfg)
            SectionCfg = SectionCfg or {}
            SectionCfg.Name = SectionCfg.Name or "SECTION"

            local sec = SetProps(MakeElement("TFrame"), {
                Size = UDim2.new(1, 0, 0, 26),
                Parent = Container,
            })

            local title = SetProps(MakeElement("Label", string.upper(SectionCfg.Name), 11), {
                Parent = sec,
                Size = UDim2.new(1, -12, 0, 16),
                Position = UDim2.new(0, 0, 0, 2),
                Font = Enum.Font.GothamBlack,
                TextColor3 = ACCENT,
                TextTransparency = 0.2,
            })

            local holder = SetProps(MakeElement("TFrame"), {
                Parent = sec,
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 24),
                Name = "Holder",
            })
            MakeElement("List", 0, 6).Parent = holder

            holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                sec.Size = UDim2.new(1, 0, 0, holder.UIListLayout.AbsoluteContentSize.Y + 30)
                holder.Size = UDim2.new(1, 0, 0, holder.UIListLayout.AbsoluteContentSize.Y)
            end)

            local SectionFn = {}
            for k, v in pairs(GetElements(holder)) do SectionFn[k] = v end
            return SectionFn
        end

        for k, v in pairs(GetElements(Container)) do ElementFunction[k] = v end
        return ElementFunction
    end

    return TabFunction
end

function OrionLib:Destroy()
    for _, c in ipairs(OrionLib.Connections) do
        pcall(function() c:Disconnect() end)
    end
    Orion:Destroy()
end

return OrionLib