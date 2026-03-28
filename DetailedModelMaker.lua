-- Roblox Detailed Model Maker
-- Fresh Roblox Studio plugin for prompt-based detailed model generation with Cube 3D.

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local GenerationService = game:GetService("GenerationService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local TOOLBAR = plugin:CreateToolbar("Detailed Models")
local OPEN_BUTTON = TOOLBAR:CreateButton(
	"Detailed Model",
	"Generate detailed Roblox models from a text prompt",
	""
)
OPEN_BUTTON.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Left,
	true,
	false,
	430,
	640,
	360,
	480
)

local widget = plugin:CreateDockWidgetPluginGui("DetailedModelMakerWidget", widgetInfo)
widget.Title = "Detailed Model Maker"
widget.Enabled = false

local previewWidgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	true,
	false,
	520,
	420,
	360,
	260
)

local previewWidget = plugin:CreateDockWidgetPluginGui("DetailedModelPreviewWidget", previewWidgetInfo)
previewWidget.Title = "Model Preview"
previewWidget.Enabled = false

local settingsWidgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	true,
	false,
	420,
	620,
	320,
	420
)

local settingsWidget = plugin:CreateDockWidgetPluginGui("DetailedModelSettingsWidget", settingsWidgetInfo)
settingsWidget.Title = "Detailed Model Settings"
settingsWidget.Enabled = false

local guideWidgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	true,
	false,
	450,
	640,
	340,
	460
)

local guideWidget = plugin:CreateDockWidgetPluginGui("DetailedModelGuideWidget", guideWidgetInfo)
guideWidget.Title = "Detailed Model Guide"
guideWidget.Enabled = false

PREVIEW_LIGHTING_PRESETS = {
	Studio = {
		ambient = Color3.fromRGB(188, 198, 214),
		lightColor = Color3.fromRGB(255, 244, 230),
		lightDirection = Vector3.new(-1, -1.2, -0.8),
		info = "Balanced studio lighting",
	},
	Neutral = {
		ambient = Color3.fromRGB(164, 174, 188),
		lightColor = Color3.fromRGB(244, 246, 255),
		lightDirection = Vector3.new(-0.5, -1, -0.5),
		info = "Neutral surface inspection",
	},
	Dramatic = {
		ambient = Color3.fromRGB(100, 112, 134),
		lightColor = Color3.fromRGB(255, 221, 188),
		lightDirection = Vector3.new(1.1, -0.7, -0.25),
		info = "High-contrast form emphasis",
	},
	Outdoor = {
		ambient = Color3.fromRGB(155, 177, 197),
		lightColor = Color3.fromRGB(255, 250, 236),
		lightDirection = Vector3.new(-0.8, -1.4, 0.2),
		info = "Daylight-style readability",
	},
}

PREVIEW_BACKGROUND_PRESETS = {
	Cool = {
		top = Color3.fromRGB(82, 103, 142),
		bottom = Color3.fromRGB(58, 75, 104),
		stroke = Color3.fromRGB(123, 157, 207),
		info = "Cool blueprint backdrop",
	},
	Charcoal = {
		top = Color3.fromRGB(62, 67, 76),
		bottom = Color3.fromRGB(35, 39, 46),
		stroke = Color3.fromRGB(129, 138, 156),
		info = "Dark contrast backdrop",
	},
	Light = {
		top = Color3.fromRGB(223, 231, 240),
		bottom = Color3.fromRGB(190, 203, 219),
		stroke = Color3.fromRGB(111, 134, 162),
		info = "Light silhouette check",
	},
	Sand = {
		top = Color3.fromRGB(187, 169, 140),
		bottom = Color3.fromRGB(128, 112, 90),
		stroke = Color3.fromRGB(224, 200, 157),
		info = "Warm material backdrop",
	},
}

local SETTINGS = {
	prompt = "DetailedModelMaker_Prompt",
	size = "DetailedModelMaker_Size",
	maxTriangles = "DetailedModelMaker_MaxTriangles",
	textures = "DetailedModelMaker_Textures",
	includeBase = "DetailedModelMaker_IncludeBase",
	anchored = "DetailedModelMaker_Anchored",
	schema = "DetailedModelMaker_Schema",
	colliderMode = "DetailedModelMaker_ColliderMode",
	seed = "DetailedModelMaker_Seed",
	collisionPreview = "DetailedModelMaker_CollisionPreview",
	collisionSimpleMaxParts = "DetailedModelMaker_CollisionSimpleMaxParts",
	collisionSimpleOccupancy = "DetailedModelMaker_CollisionSimpleOccupancy",
	collisionSimpleDominantShare = "DetailedModelMaker_CollisionSimpleDominantShare",
	collisionDetailedPartThreshold = "DetailedModelMaker_CollisionDetailedPartThreshold",
	collisionDetailedPartThresholdSecondary = "DetailedModelMaker_CollisionDetailedPartThresholdSecondary",
	collisionDetailedOccupancy = "DetailedModelMaker_CollisionDetailedOccupancy",
	collisionDetailedOccupancySecondary = "DetailedModelMaker_CollisionDetailedOccupancySecondary",
	collisionDetailedElongation = "DetailedModelMaker_CollisionDetailedElongation",
	theme = "DetailedModelMaker_Theme",
	themeVariant = "DetailedModelMaker_ThemeVariant",
	themeTone = "DetailedModelMaker_ThemeTone",
	themeContrast = "DetailedModelMaker_ThemeContrast",
	themeTypography = "DetailedModelMaker_ThemeTypography",
	cacheEnabled = "DetailedModelMaker_CacheEnabled",
	autoOpenPreview = "DetailedModelMaker_AutoOpenPreview",
	showAdvancedCollisionTuning = "DetailedModelMaker_ShowAdvancedCollisionTuning",
	confirmStoreAll = "DetailedModelMaker_ConfirmStoreAll",
	promptHistory = "DetailedModelMaker_PromptHistory",
	experimentalNegativePrompt = "DetailedModelMaker_ExperimentalNegativePrompt",
	experimentalStyleBias = "DetailedModelMaker_ExperimentalStyleBias",
	experimentalPreviewMode = "DetailedModelMaker_ExperimentalPreviewMode",
	experimentalGroundSnap = "DetailedModelMaker_ExperimentalGroundSnap",
}

local THEMES = {
	Slate = {
		backgroundTop = Color3.fromRGB(42, 52, 72),
		backgroundBottom = Color3.fromRGB(24, 31, 44),
		panelTop = Color3.fromRGB(58, 71, 97),
		panelBottom = Color3.fromRGB(35, 44, 60),
		panelStroke = Color3.fromRGB(102, 126, 168),
		panelStrongTop = Color3.fromRGB(74, 94, 129),
		panelStrongBottom = Color3.fromRGB(52, 66, 92),
		panelStrongStroke = Color3.fromRGB(123, 157, 207),
		viewportTop = Color3.fromRGB(82, 103, 142),
		viewportBottom = Color3.fromRGB(58, 75, 104),
		viewportStroke = Color3.fromRGB(123, 157, 207),
		inputTop = Color3.fromRGB(74, 90, 119),
		inputBottom = Color3.fromRGB(56, 68, 90),
		inputBase = Color3.fromRGB(54, 66, 88),
		inputStroke = Color3.fromRGB(110, 137, 176),
		inputText = Color3.fromRGB(248, 250, 255),
		inputPlaceholder = Color3.fromRGB(188, 200, 219),
		buttonStroke = Color3.fromRGB(33, 45, 65),
		buttons = {
			secondary = Color3.fromRGB(90, 110, 140),
			success = Color3.fromRGB(48, 143, 99),
			warning = Color3.fromRGB(156, 111, 62),
			purple = Color3.fromRGB(126, 84, 148),
			accent = Color3.fromRGB(67, 126, 141),
			danger = Color3.fromRGB(112, 83, 83),
			info = Color3.fromRGB(84, 107, 146),
			teal = Color3.fromRGB(57, 128, 116),
			active = Color3.fromRGB(48, 143, 99),
			muted = Color3.fromRGB(86, 99, 125),
		},
	},
	Sunrise = {
		backgroundTop = Color3.fromRGB(78, 63, 74),
		backgroundBottom = Color3.fromRGB(47, 38, 49),
		panelTop = Color3.fromRGB(112, 87, 96),
		panelBottom = Color3.fromRGB(74, 58, 68),
		panelStroke = Color3.fromRGB(189, 151, 145),
		panelStrongTop = Color3.fromRGB(146, 109, 116),
		panelStrongBottom = Color3.fromRGB(101, 74, 82),
		panelStrongStroke = Color3.fromRGB(222, 180, 160),
		viewportTop = Color3.fromRGB(161, 125, 110),
		viewportBottom = Color3.fromRGB(111, 85, 76),
		viewportStroke = Color3.fromRGB(230, 190, 160),
		inputTop = Color3.fromRGB(139, 108, 111),
		inputBottom = Color3.fromRGB(103, 80, 87),
		inputBase = Color3.fromRGB(97, 76, 82),
		inputStroke = Color3.fromRGB(205, 165, 151),
		inputText = Color3.fromRGB(255, 246, 240),
		inputPlaceholder = Color3.fromRGB(235, 207, 197),
		buttonStroke = Color3.fromRGB(78, 53, 51),
		buttons = {
			secondary = Color3.fromRGB(114, 130, 181),
			success = Color3.fromRGB(63, 168, 108),
			warning = Color3.fromRGB(201, 141, 78),
			purple = Color3.fromRGB(171, 95, 141),
			accent = Color3.fromRGB(74, 158, 169),
			danger = Color3.fromRGB(176, 98, 94),
			info = Color3.fromRGB(99, 132, 184),
			teal = Color3.fromRGB(72, 164, 141),
			active = Color3.fromRGB(63, 168, 108),
			muted = Color3.fromRGB(113, 117, 152),
		},
	},
	Meadow = {
		backgroundTop = Color3.fromRGB(43, 63, 57),
		backgroundBottom = Color3.fromRGB(24, 39, 35),
		panelTop = Color3.fromRGB(63, 92, 82),
		panelBottom = Color3.fromRGB(39, 57, 51),
		panelStroke = Color3.fromRGB(118, 159, 135),
		panelStrongTop = Color3.fromRGB(84, 119, 106),
		panelStrongBottom = Color3.fromRGB(53, 76, 68),
		panelStrongStroke = Color3.fromRGB(152, 196, 164),
		viewportTop = Color3.fromRGB(86, 125, 112),
		viewportBottom = Color3.fromRGB(59, 86, 77),
		viewportStroke = Color3.fromRGB(167, 207, 178),
		inputTop = Color3.fromRGB(79, 111, 100),
		inputBottom = Color3.fromRGB(57, 82, 73),
		inputBase = Color3.fromRGB(52, 76, 68),
		inputStroke = Color3.fromRGB(131, 177, 151),
		inputText = Color3.fromRGB(246, 252, 248),
		inputPlaceholder = Color3.fromRGB(195, 216, 203),
		buttonStroke = Color3.fromRGB(28, 49, 43),
		buttons = {
			secondary = Color3.fromRGB(88, 121, 151),
			success = Color3.fromRGB(53, 157, 101),
			warning = Color3.fromRGB(176, 128, 70),
			purple = Color3.fromRGB(128, 102, 164),
			accent = Color3.fromRGB(54, 143, 145),
			danger = Color3.fromRGB(145, 92, 87),
			info = Color3.fromRGB(83, 120, 159),
			teal = Color3.fromRGB(56, 145, 123),
			active = Color3.fromRGB(53, 157, 101),
			muted = Color3.fromRGB(89, 112, 117),
		},
	},
	Midnight = {
		backgroundTop = Color3.fromRGB(28, 34, 56),
		backgroundBottom = Color3.fromRGB(15, 19, 33),
		panelTop = Color3.fromRGB(42, 52, 82),
		panelBottom = Color3.fromRGB(24, 31, 51),
		panelStroke = Color3.fromRGB(88, 109, 168),
		panelStrongTop = Color3.fromRGB(59, 73, 114),
		panelStrongBottom = Color3.fromRGB(34, 43, 69),
		panelStrongStroke = Color3.fromRGB(120, 145, 214),
		viewportTop = Color3.fromRGB(70, 87, 136),
		viewportBottom = Color3.fromRGB(44, 56, 89),
		viewportStroke = Color3.fromRGB(133, 159, 227),
		inputTop = Color3.fromRGB(65, 79, 122),
		inputBottom = Color3.fromRGB(45, 55, 85),
		inputBase = Color3.fromRGB(39, 48, 74),
		inputStroke = Color3.fromRGB(101, 124, 186),
		inputText = Color3.fromRGB(244, 247, 255),
		inputPlaceholder = Color3.fromRGB(176, 188, 223),
		buttonStroke = Color3.fromRGB(23, 30, 52),
		buttons = {
			secondary = Color3.fromRGB(81, 104, 176),
			success = Color3.fromRGB(52, 161, 113),
			warning = Color3.fromRGB(190, 137, 78),
			purple = Color3.fromRGB(131, 95, 187),
			accent = Color3.fromRGB(63, 139, 173),
			danger = Color3.fromRGB(156, 88, 102),
			info = Color3.fromRGB(92, 117, 184),
			teal = Color3.fromRGB(60, 154, 143),
			active = Color3.fromRGB(52, 161, 113),
			muted = Color3.fromRGB(84, 99, 145),
		},
	},
	Sandstone = {
		backgroundTop = Color3.fromRGB(84, 73, 62),
		backgroundBottom = Color3.fromRGB(52, 44, 38),
		panelTop = Color3.fromRGB(118, 101, 83),
		panelBottom = Color3.fromRGB(77, 64, 53),
		panelStroke = Color3.fromRGB(184, 161, 128),
		panelStrongTop = Color3.fromRGB(148, 127, 101),
		panelStrongBottom = Color3.fromRGB(100, 83, 67),
		panelStrongStroke = Color3.fromRGB(223, 197, 153),
		viewportTop = Color3.fromRGB(158, 136, 106),
		viewportBottom = Color3.fromRGB(109, 91, 71),
		viewportStroke = Color3.fromRGB(234, 208, 161),
		inputTop = Color3.fromRGB(140, 120, 97),
		inputBottom = Color3.fromRGB(102, 86, 70),
		inputBase = Color3.fromRGB(92, 78, 64),
		inputStroke = Color3.fromRGB(200, 175, 136),
		inputText = Color3.fromRGB(255, 247, 235),
		inputPlaceholder = Color3.fromRGB(228, 207, 178),
		buttonStroke = Color3.fromRGB(64, 51, 37),
		buttons = {
			secondary = Color3.fromRGB(109, 129, 179),
			success = Color3.fromRGB(77, 161, 99),
			warning = Color3.fromRGB(202, 147, 66),
			purple = Color3.fromRGB(155, 104, 170),
			accent = Color3.fromRGB(73, 150, 161),
			danger = Color3.fromRGB(174, 101, 86),
			info = Color3.fromRGB(104, 130, 183),
			teal = Color3.fromRGB(74, 157, 136),
			active = Color3.fromRGB(77, 161, 99),
			muted = Color3.fromRGB(123, 115, 103),
		},
	},
	Ice = {
		backgroundTop = Color3.fromRGB(205, 223, 238),
		backgroundBottom = Color3.fromRGB(166, 189, 211),
		panelTop = Color3.fromRGB(230, 239, 248),
		panelBottom = Color3.fromRGB(190, 208, 225),
		panelStroke = Color3.fromRGB(121, 154, 184),
		panelStrongTop = Color3.fromRGB(240, 246, 252),
		panelStrongBottom = Color3.fromRGB(205, 221, 235),
		panelStrongStroke = Color3.fromRGB(108, 145, 178),
		viewportTop = Color3.fromRGB(210, 226, 240),
		viewportBottom = Color3.fromRGB(178, 198, 218),
		viewportStroke = Color3.fromRGB(104, 142, 175),
		inputTop = Color3.fromRGB(248, 251, 255),
		inputBottom = Color3.fromRGB(215, 229, 241),
		inputBase = Color3.fromRGB(219, 232, 243),
		inputStroke = Color3.fromRGB(116, 149, 176),
		inputText = Color3.fromRGB(34, 54, 73),
		inputPlaceholder = Color3.fromRGB(92, 120, 143),
		buttonStroke = Color3.fromRGB(95, 126, 155),
		buttons = {
			secondary = Color3.fromRGB(112, 149, 196),
			success = Color3.fromRGB(77, 170, 125),
			warning = Color3.fromRGB(210, 155, 84),
			purple = Color3.fromRGB(149, 116, 187),
			accent = Color3.fromRGB(76, 164, 181),
			danger = Color3.fromRGB(195, 114, 114),
			info = Color3.fromRGB(96, 141, 198),
			teal = Color3.fromRGB(69, 170, 158),
			active = Color3.fromRGB(77, 170, 125),
			muted = Color3.fromRGB(124, 143, 166),
		},
	},
	Ember = {
		backgroundTop = Color3.fromRGB(88, 42, 35),
		backgroundBottom = Color3.fromRGB(51, 24, 21),
		panelTop = Color3.fromRGB(126, 63, 52),
		panelBottom = Color3.fromRGB(80, 40, 34),
		panelStroke = Color3.fromRGB(208, 126, 91),
		panelStrongTop = Color3.fromRGB(154, 78, 61),
		panelStrongBottom = Color3.fromRGB(102, 50, 42),
		panelStrongStroke = Color3.fromRGB(233, 150, 104),
		viewportTop = Color3.fromRGB(164, 86, 65),
		viewportBottom = Color3.fromRGB(111, 57, 45),
		viewportStroke = Color3.fromRGB(240, 158, 109),
		inputTop = Color3.fromRGB(147, 74, 60),
		inputBottom = Color3.fromRGB(106, 52, 43),
		inputBase = Color3.fromRGB(96, 48, 40),
		inputStroke = Color3.fromRGB(220, 138, 101),
		inputText = Color3.fromRGB(255, 244, 236),
		inputPlaceholder = Color3.fromRGB(235, 190, 171),
		buttonStroke = Color3.fromRGB(74, 32, 27),
		buttons = {
			secondary = Color3.fromRGB(105, 124, 179),
			success = Color3.fromRGB(74, 165, 96),
			warning = Color3.fromRGB(221, 152, 59),
			purple = Color3.fromRGB(154, 95, 179),
			accent = Color3.fromRGB(76, 157, 165),
			danger = Color3.fromRGB(197, 102, 86),
			info = Color3.fromRGB(102, 131, 187),
			teal = Color3.fromRGB(72, 163, 141),
			active = Color3.fromRGB(74, 165, 96),
			muted = Color3.fromRGB(126, 103, 110),
		},
	},
	Wasteland = {
		backgroundTop = Color3.fromRGB(53, 73, 54),
		backgroundBottom = Color3.fromRGB(24, 36, 28),
		panelTop = Color3.fromRGB(76, 108, 73),
		panelBottom = Color3.fromRGB(42, 60, 45),
		panelStroke = Color3.fromRGB(137, 193, 118),
		panelStrongTop = Color3.fromRGB(95, 132, 86),
		panelStrongBottom = Color3.fromRGB(58, 82, 56),
		panelStrongStroke = Color3.fromRGB(178, 224, 140),
		viewportTop = Color3.fromRGB(93, 135, 87),
		viewportBottom = Color3.fromRGB(54, 80, 53),
		viewportStroke = Color3.fromRGB(183, 228, 146),
		inputTop = Color3.fromRGB(87, 121, 78),
		inputBottom = Color3.fromRGB(56, 78, 56),
		inputBase = Color3.fromRGB(47, 66, 47),
		inputStroke = Color3.fromRGB(156, 209, 128),
		inputText = Color3.fromRGB(236, 255, 224),
		inputPlaceholder = Color3.fromRGB(178, 210, 168),
		buttonStroke = Color3.fromRGB(22, 36, 25),
		buttons = {
			secondary = Color3.fromRGB(97, 127, 92),
			success = Color3.fromRGB(67, 160, 93),
			warning = Color3.fromRGB(185, 139, 72),
			purple = Color3.fromRGB(118, 99, 149),
			accent = Color3.fromRGB(71, 149, 114),
			danger = Color3.fromRGB(153, 96, 85),
			info = Color3.fromRGB(95, 139, 113),
			teal = Color3.fromRGB(73, 153, 128),
			active = Color3.fromRGB(67, 160, 93),
			muted = Color3.fromRGB(96, 112, 90),
		},
	},
	NukaGlow = {
		backgroundTop = Color3.fromRGB(28, 51, 79),
		backgroundBottom = Color3.fromRGB(14, 25, 42),
		panelTop = Color3.fromRGB(47, 82, 121),
		panelBottom = Color3.fromRGB(24, 42, 66),
		panelStroke = Color3.fromRGB(111, 202, 218),
		panelStrongTop = Color3.fromRGB(64, 107, 149),
		panelStrongBottom = Color3.fromRGB(32, 56, 83),
		panelStrongStroke = Color3.fromRGB(132, 232, 237),
		viewportTop = Color3.fromRGB(79, 133, 177),
		viewportBottom = Color3.fromRGB(41, 71, 104),
		viewportStroke = Color3.fromRGB(141, 238, 239),
		inputTop = Color3.fromRGB(62, 102, 145),
		inputBottom = Color3.fromRGB(35, 59, 89),
		inputBase = Color3.fromRGB(28, 49, 73),
		inputStroke = Color3.fromRGB(122, 215, 224),
		inputText = Color3.fromRGB(241, 252, 255),
		inputPlaceholder = Color3.fromRGB(174, 216, 225),
		buttonStroke = Color3.fromRGB(16, 28, 45),
		buttons = {
			secondary = Color3.fromRGB(80, 117, 181),
			success = Color3.fromRGB(58, 180, 129),
			warning = Color3.fromRGB(230, 152, 69),
			purple = Color3.fromRGB(145, 100, 190),
			accent = Color3.fromRGB(69, 194, 201),
			danger = Color3.fromRGB(204, 96, 105),
			info = Color3.fromRGB(104, 164, 215),
			teal = Color3.fromRGB(63, 182, 164),
			active = Color3.fromRGB(58, 180, 129),
			muted = Color3.fromRGB(84, 106, 135),
		},
	},
	Bonfire = {
		backgroundTop = Color3.fromRGB(69, 49, 40),
		backgroundBottom = Color3.fromRGB(31, 22, 18),
		panelTop = Color3.fromRGB(101, 73, 58),
		panelBottom = Color3.fromRGB(55, 39, 31),
		panelStroke = Color3.fromRGB(210, 158, 110),
		panelStrongTop = Color3.fromRGB(129, 91, 67),
		panelStrongBottom = Color3.fromRGB(78, 53, 40),
		panelStrongStroke = Color3.fromRGB(240, 189, 129),
		viewportTop = Color3.fromRGB(141, 103, 76),
		viewportBottom = Color3.fromRGB(83, 60, 47),
		viewportStroke = Color3.fromRGB(247, 198, 136),
		inputTop = Color3.fromRGB(120, 86, 63),
		inputBottom = Color3.fromRGB(74, 53, 40),
		inputBase = Color3.fromRGB(63, 45, 35),
		inputStroke = Color3.fromRGB(224, 171, 118),
		inputText = Color3.fromRGB(255, 245, 232),
		inputPlaceholder = Color3.fromRGB(222, 197, 165),
		buttonStroke = Color3.fromRGB(36, 25, 20),
		buttons = {
			secondary = Color3.fromRGB(108, 124, 170),
			success = Color3.fromRGB(79, 167, 101),
			warning = Color3.fromRGB(223, 155, 69),
			purple = Color3.fromRGB(154, 104, 175),
			accent = Color3.fromRGB(76, 160, 167),
			danger = Color3.fromRGB(191, 102, 86),
			info = Color3.fromRGB(109, 141, 194),
			teal = Color3.fromRGB(77, 164, 142),
			active = Color3.fromRGB(79, 167, 101),
			muted = Color3.fromRGB(123, 105, 93),
		},
	},
}

local THEME_CATEGORY_ORDER = {
	"Studio & Utility",
	"Post-Apocalypse",
	"Sandbox & Survival",
	"Sci-Fi & Shooters",
	"Fantasy & RPG",
	"Horror & Atmosphere",
	"Competitive & Hero",
	"Racing & Action",
	"Arcade & Indie",
}

local THEME_CATEGORIES = {
	["Roblox Dark"] = "Studio & Utility",
	["Roblox Light"] = "Studio & Utility",
	["Studio Ash"] = "Studio & Utility",
	["Monochrome"] = "Studio & Utility",
	["Paper"] = "Studio & Utility",
	["Ivory"] = "Studio & Utility",
	["Mint Chip"] = "Studio & Utility",
	["Ocean"] = "Studio & Utility",
	["Deep Sea"] = "Studio & Utility",
	["Glacier"] = "Studio & Utility",
	["Harbor"] = "Studio & Utility",
	["Azure"] = "Studio & Utility",
	["Skyline"] = "Studio & Utility",
	["Neon Cyan"] = "Studio & Utility",
	["Lime Punch"] = "Studio & Utility",
	["Radioactive"] = "Studio & Utility",
	["Sunset"] = "Studio & Utility",
	["Coral"] = "Studio & Utility",
	["Rose Gold"] = "Studio & Utility",
	["Sakura"] = "Studio & Utility",
	["Plum"] = "Studio & Utility",
	["Royal"] = "Studio & Utility",
	["Lavender"] = "Studio & Utility",
	["Grape Soda"] = "Studio & Utility",
	["Copper"] = "Studio & Utility",
	["Bronze"] = "Studio & Utility",
	["Amber"] = "Studio & Utility",
	["Honey"] = "Studio & Utility",
	["Desert Bloom"] = "Studio & Utility",
	["Forest"] = "Studio & Utility",
	["Moss"] = "Studio & Utility",
	["Pine"] = "Studio & Utility",
	["Emerald"] = "Studio & Utility",
	["Toxic"] = "Studio & Utility",
	["Candy"] = "Studio & Utility",
	["Bubblegum"] = "Studio & Utility",
	["Cotton Candy"] = "Studio & Utility",
	["Arcade"] = "Studio & Utility",
	["Synthwave"] = "Studio & Utility",
	["Vapor"] = "Studio & Utility",
	["Cyberpunk"] = "Studio & Utility",
	["Laser Grid"] = "Studio & Utility",
	["Retro CRT"] = "Studio & Utility",
	["Terminal Green"] = "Studio & Utility",
	["Hacker Blue"] = "Studio & Utility",
	["Noir"] = "Studio & Utility",
	["Dracula"] = "Studio & Utility",
	["Mocha"] = "Studio & Utility",
	["Coffeehouse"] = "Studio & Utility",
	["Cocoa"] = "Studio & Utility",
	["Rust"] = "Studio & Utility",
	["Lava"] = "Studio & Utility",
	["Emberglass"] = "Studio & Utility",
	["Volcano"] = "Studio & Utility",
	["Sand"] = "Studio & Utility",
	["Dune"] = "Studio & Utility",
	["Canyon"] = "Studio & Utility",
	["Terracotta"] = "Studio & Utility",
	["Clay"] = "Studio & Utility",
	["Arctic Sun"] = "Studio & Utility",
	["Polar Night"] = "Studio & Utility",
	["Aurora"] = "Studio & Utility",
	["Galaxy"] = "Studio & Utility",
	["Nebula"] = "Studio & Utility",
	["Comet"] = "Studio & Utility",
	["Starlight"] = "Studio & Utility",
	["Solarized Dark"] = "Studio & Utility",
	["Solarized Light"] = "Studio & Utility",
	["Bookworm"] = "Studio & Utility",
	["Blueprint"] = "Studio & Utility",
	["Construction"] = "Studio & Utility",
	["Toybox"] = "Studio & Utility",
	["Plastic"] = "Studio & Utility",
	["Obsidian"] = "Studio & Utility",
	["Wasteland"] = "Post-Apocalypse",
	["NukaGlow"] = "Post-Apocalypse",
	["Bonfire"] = "Fantasy & RPG",
}

function rgb(red, green, blue)
	return Color3.fromRGB(red, green, blue)
end

function getThemeLuminance(color)
	return color.R * 0.299 + color.G * 0.587 + color.B * 0.114
end

function createThemeFromSeed(seed)
	local bgTop = seed[2]
	local bgBottom = seed[3]
	local primary = seed[4]
	local accent = seed[5]
	local success = seed[6]
	local warning = seed[7]
	local isLight = ((getThemeLuminance(bgTop) + getThemeLuminance(bgBottom)) * 0.5) > 0.58
	local baseText = isLight and rgb(31, 40, 50) or rgb(244, 247, 255)
	local shadowTone = isLight and rgb(255, 255, 255) or rgb(16, 20, 28)
	local panelTop = bgTop:Lerp(primary, isLight and 0.16 or 0.24)
	local panelBottom = bgBottom:Lerp(primary, isLight and 0.1 or 0.18)
	local strongTop = primary:Lerp(accent, 0.16)
	local strongBottom = panelBottom:Lerp(primary, 0.22)
	local stroke = primary:Lerp(accent, 0.35)
	local inputTop = panelTop:Lerp(shadowTone, isLight and 0.55 or 0.1)
	local inputBottom = panelBottom:Lerp(shadowTone, isLight and 0.38 or 0.08)
	local inputBase = inputBottom:Lerp(bgBottom, isLight and 0.18 or 0.12)
	local placeholder = baseText:Lerp(shadowTone, isLight and 0.45 or 0.35)

	return {
		backgroundTop = bgTop,
		backgroundBottom = bgBottom,
		panelTop = panelTop,
		panelBottom = panelBottom,
		panelStroke = stroke,
		panelStrongTop = strongTop,
		panelStrongBottom = strongBottom,
		panelStrongStroke = stroke:Lerp(accent, 0.3),
		viewportTop = strongTop:Lerp(accent, 0.18),
		viewportBottom = strongBottom:Lerp(primary, 0.12),
		viewportStroke = stroke:Lerp(baseText, isLight and 0.08 or 0.12),
		inputTop = inputTop,
		inputBottom = inputBottom,
		inputBase = inputBase,
		inputStroke = stroke:Lerp(primary, 0.25),
		inputText = baseText,
		inputPlaceholder = placeholder,
		buttonStroke = panelBottom:Lerp(shadowTone, isLight and 0.32 or 0.45),
		typography = {
			title = Enum.Font.GothamBold,
			body = Enum.Font.Gotham,
			input = Enum.Font.Gotham,
			button = Enum.Font.GothamBold,
			mono = Enum.Font.Code,
		},
		buttons = {
			secondary = primary,
			success = success,
			warning = warning,
			purple = accent:Lerp(rgb(155, 110, 205), 0.45),
			accent = accent,
			danger = warning:Lerp(rgb(196, 92, 106), 0.5),
			info = primary:Lerp(accent, 0.25),
			teal = accent:Lerp(rgb(66, 177, 167), 0.55),
			active = success,
			muted = panelBottom:Lerp(baseText, isLight and 0.18 or 0.22),
		},
	}
end

local THEME_VARIANT_ORDER = {"Default", "Soft", "Vivid", "Noir"}
local THEME_TONE_ORDER = {"Default", "Cool", "Warm", "Verdant", "Neon"}
local THEME_CONTRAST_ORDER = {"Balanced", "Soft", "Punchy"}
local THEME_TYPOGRAPHY_ORDER = {"Theme Default", "Studio Sans", "Editorial", "Arcade", "Sci-Fi", "Monospace"}

function normalizeThemeChoice(value, order, fallback)
	local selected = tostring(value or "")
	for _, option in ipairs(order) do
		if option == selected then
			return option
		end
	end
	return fallback or order[1]
end

function cycleThemeChoice(value, order)
	local current = normalizeThemeChoice(value, order, order[1])
	for index, option in ipairs(order) do
		if option == current then
			return order[(index % #order) + 1]
		end
	end
	return order[1]
end

function cloneThemeDefinition(theme)
	local copy = cloneTable(theme)
	copy.buttons = cloneTable(theme.buttons or {})
	copy.typography = cloneTable(theme.typography or {})
	return copy
end

function desaturateColor(color, amount)
	local luminance = getThemeLuminance(color)
	return color:Lerp(Color3.new(luminance, luminance, luminance), amount)
end

function applyColorMap(theme, mapper)
	local colorKeys = {
		"backgroundTop",
		"backgroundBottom",
		"panelTop",
		"panelBottom",
		"panelStroke",
		"panelStrongTop",
		"panelStrongBottom",
		"panelStrongStroke",
		"viewportTop",
		"viewportBottom",
		"viewportStroke",
		"inputTop",
		"inputBottom",
		"inputBase",
		"inputStroke",
		"inputText",
		"inputPlaceholder",
		"buttonStroke",
	}

	for _, key in ipairs(colorKeys) do
		if typeof(theme[key]) == "Color3" then
			theme[key] = mapper(theme[key], key)
		end
	end

	for key, value in pairs(theme.buttons or {}) do
		if typeof(value) == "Color3" then
			theme.buttons[key] = mapper(value, "button:" .. key)
		end
	end
end

function applyThemeVariant(theme, variant)
	if variant == "Soft" then
		applyColorMap(theme, function(color, key)
			if key == "inputText" then
				return color
			end
			local nextColor = color:Lerp(Color3.fromRGB(255, 255, 255), 0.08)
			if string.find(key, "Stroke", 1, true) then
				nextColor = nextColor:Lerp(Color3.fromRGB(255, 255, 255), 0.08)
			end
			return nextColor
		end)
	elseif variant == "Vivid" then
		local accent = theme.buttons.accent or theme.viewportStroke or theme.panelStrongStroke
		applyColorMap(theme, function(color, key)
			if key == "inputText" or key == "inputPlaceholder" then
				return color
			end
			local strength = 0.06
			if string.find(key, "viewport", 1, true) or string.find(key, "panelStrong", 1, true) or string.find(key, "button:", 1, true) then
				strength = 0.18
			elseif string.find(key, "Stroke", 1, true) then
				strength = 0.12
			end
			return color:Lerp(accent, strength)
		end)
	elseif variant == "Noir" then
		applyColorMap(theme, function(color, key)
			if key == "inputText" then
				return color
			end
			local amount = string.find(key, "button:", 1, true) and 0.3 or 0.58
			return desaturateColor(color, amount)
		end)
	end
end

function applyThemeTone(theme, tone)
	local tintTarget
	local tintStrength = 0
	if tone == "Cool" then
		tintTarget = Color3.fromRGB(108, 175, 255)
		tintStrength = 0.12
	elseif tone == "Warm" then
		tintTarget = Color3.fromRGB(255, 184, 122)
		tintStrength = 0.12
	elseif tone == "Verdant" then
		tintTarget = Color3.fromRGB(110, 196, 148)
		tintStrength = 0.12
	elseif tone == "Neon" then
		tintTarget = Color3.fromRGB(80, 255, 208)
		tintStrength = 0.2
	end

	if tintTarget and tintStrength > 0 then
		applyColorMap(theme, function(color, key)
			if key == "inputText" then
				return color
			end
			local strength = tintStrength
			if string.find(key, "button:", 1, true) or string.find(key, "viewport", 1, true) then
				strength = tintStrength + 0.06
			end
			return color:Lerp(tintTarget, strength)
		end)
	end
end

function applyThemeContrast(theme, contrast)
	if contrast == "Soft" then
		applyColorMap(theme, function(color, key)
			if key == "inputText" then
				return color:Lerp(theme.backgroundTop, 0.08)
			end
			if key == "inputPlaceholder" then
				return color:Lerp(theme.inputBase, 0.18)
			end
			return color:Lerp(Color3.fromRGB(128, 128, 128), 0.12)
		end)
	elseif contrast == "Punchy" then
		applyColorMap(theme, function(color, key)
			if key == "inputText" then
				return color:Lerp(Color3.fromRGB(255, 255, 255), 0.05)
			end
			if key == "inputPlaceholder" then
				return color:Lerp(theme.inputText, 0.12)
			end
			local brighten = string.find(key, "button:", 1, true) or string.find(key, "viewport", 1, true)
			return brighten and color:Lerp(Color3.fromRGB(255, 255, 255), 0.08) or color:Lerp(Color3.fromRGB(0, 0, 0), 0.08)
		end)
	end
end

function applyThemeTypographyOverride(theme, typographyMode)
	local titleFont = theme.typography.title or Enum.Font.GothamBold
	local bodyFont = theme.typography.body or Enum.Font.Gotham
	local inputFont = theme.typography.input or Enum.Font.Gotham
	local buttonFont = theme.typography.button or Enum.Font.GothamBold
	local monoFont = theme.typography.mono or Enum.Font.Code

	if typographyMode == "Studio Sans" then
		titleFont = Enum.Font.SourceSansBold
		bodyFont = Enum.Font.SourceSans
		inputFont = Enum.Font.SourceSans
		buttonFont = Enum.Font.SourceSansBold
	elseif typographyMode == "Editorial" then
		titleFont = Enum.Font.Bodoni
		bodyFont = Enum.Font.Garamond
		inputFont = Enum.Font.Garamond
		buttonFont = Enum.Font.Bodoni
	elseif typographyMode == "Arcade" then
		titleFont = Enum.Font.Arcade
		bodyFont = Enum.Font.Arcade
		inputFont = Enum.Font.Code
		buttonFont = Enum.Font.Arcade
	elseif typographyMode == "Sci-Fi" then
		titleFont = Enum.Font.SciFi
		bodyFont = Enum.Font.SciFi
		inputFont = Enum.Font.Code
		buttonFont = Enum.Font.SciFi
	elseif typographyMode == "Monospace" then
		titleFont = Enum.Font.Code
		bodyFont = Enum.Font.Code
		inputFont = Enum.Font.Code
		buttonFont = Enum.Font.Code
	end

	theme.typography = {
		title = titleFont,
		body = bodyFont,
		input = inputFont,
		button = buttonFont,
		mono = monoFont,
	}
end

function buildStyledTheme(themeName, variant, tone, contrast, typographyMode)
	local baseTheme = THEMES[themeName]
	if not baseTheme then
		return nil
	end
	local styledTheme = cloneThemeDefinition(baseTheme)
	applyThemeVariant(styledTheme, variant)
	applyThemeTone(styledTheme, tone)
	applyThemeContrast(styledTheme, contrast)
	applyThemeTypographyOverride(styledTheme, typographyMode)
	return styledTheme
end

function assignThemeTypography(themeName, theme)
	local typography = theme.typography or {}
	local lowerName = string.lower(themeName)
	local titleFont = Enum.Font.GothamBold
	local bodyFont = Enum.Font.Gotham
	local inputFont = Enum.Font.Gotham
	local buttonFont = Enum.Font.GothamBold

	if string.find(lowerName, "roblox") or string.find(lowerName, "studio") or string.find(lowerName, "plastic") then
		titleFont = Enum.Font.SourceSansBold
		bodyFont = Enum.Font.SourceSans
		inputFont = Enum.Font.SourceSans
		buttonFont = Enum.Font.SourceSansBold
	elseif string.find(lowerName, "paper") or string.find(lowerName, "ivory") or string.find(lowerName, "bookworm") then
		titleFont = Enum.Font.Garamond
		bodyFont = Enum.Font.Garamond
		inputFont = Enum.Font.Garamond
		buttonFont = Enum.Font.Garamond
	elseif string.find(lowerName, "royal") or string.find(lowerName, "lavender") or string.find(lowerName, "starlight") then
		titleFont = Enum.Font.Bodoni
		bodyFont = Enum.Font.Garamond
		inputFont = Enum.Font.Garamond
		buttonFont = Enum.Font.Bodoni
	elseif string.find(lowerName, "arcade") or string.find(lowerName, "retro") or string.find(lowerName, "laser") then
		titleFont = Enum.Font.Arcade
		bodyFont = Enum.Font.Arcade
		inputFont = Enum.Font.Code
		buttonFont = Enum.Font.Arcade
	elseif string.find(lowerName, "cyber") or string.find(lowerName, "synth") or string.find(lowerName, "neon") or string.find(lowerName, "hacker") then
		titleFont = Enum.Font.SciFi
		bodyFont = Enum.Font.SciFi
		inputFont = Enum.Font.Code
		buttonFont = Enum.Font.SciFi
	elseif string.find(lowerName, "forest") or string.find(lowerName, "moss") or string.find(lowerName, "pine") or string.find(lowerName, "jade") then
		titleFont = Enum.Font.Highway
		bodyFont = Enum.Font.Gotham
		inputFont = Enum.Font.Gotham
		buttonFont = Enum.Font.Highway
	elseif string.find(lowerName, "candy") or string.find(lowerName, "bubblegum") or string.find(lowerName, "toybox") or string.find(lowerName, "carnival") then
		titleFont = Enum.Font.Cartoon
		bodyFont = Enum.Font.Cartoon
		inputFont = Enum.Font.Gotham
		buttonFont = Enum.Font.Cartoon
	elseif string.find(lowerName, "dracula") or string.find(lowerName, "noir") or string.find(lowerName, "obsidian") then
		titleFont = Enum.Font.Antique
		bodyFont = Enum.Font.Garamond
		inputFont = Enum.Font.Code
		buttonFont = Enum.Font.Antique
	elseif string.find(lowerName, "terminal") or string.find(lowerName, "solarized") or string.find(lowerName, "blueprint") or string.find(lowerName, "monochrome") then
		titleFont = Enum.Font.Code
		bodyFont = Enum.Font.Code
		inputFont = Enum.Font.Code
		buttonFont = Enum.Font.Code
	elseif string.find(lowerName, "sunset") or string.find(lowerName, "ember") or string.find(lowerName, "volcano") or string.find(lowerName, "canyon") then
		titleFont = Enum.Font.Fantasy
		bodyFont = Enum.Font.Garamond
		inputFont = Enum.Font.Garamond
		buttonFont = Enum.Font.Fantasy
	end

	typography.title = titleFont
	typography.body = bodyFont
	typography.input = inputFont
	typography.button = buttonFont
	typography.mono = Enum.Font.Code
	theme.typography = typography
	return theme
end

function getThemeCategory(themeName)
	return THEME_CATEGORIES[themeName] or "Studio & Utility"
end

for _, seed in ipairs({
	{"Roblox Dark", rgb(39, 41, 48), rgb(24, 26, 31), rgb(89, 133, 255), rgb(0, 162, 255), rgb(0, 200, 140), rgb(235, 170, 48)},
	{"Roblox Light", rgb(242, 244, 248), rgb(222, 227, 235), rgb(45, 123, 229), rgb(0, 162, 255), rgb(18, 180, 120), rgb(231, 158, 37)},
	{"Studio Ash", rgb(55, 58, 66), rgb(36, 38, 44), rgb(112, 122, 146), rgb(151, 163, 189), rgb(72, 160, 104), rgb(194, 145, 72)},
	{"Monochrome", rgb(65, 67, 72), rgb(31, 33, 37), rgb(140, 145, 153), rgb(208, 213, 221), rgb(120, 170, 132), rgb(201, 166, 99)},
	{"Paper", rgb(247, 243, 234), rgb(226, 219, 205), rgb(171, 143, 99), rgb(122, 97, 72), rgb(104, 158, 111), rgb(207, 156, 66)},
	{"Ivory", rgb(250, 247, 241), rgb(233, 227, 217), rgb(194, 164, 122), rgb(125, 111, 146), rgb(112, 173, 136), rgb(214, 157, 74)},
	{"Mint Chip", rgb(228, 245, 236), rgb(196, 225, 213), rgb(88, 168, 129), rgb(73, 150, 136), rgb(49, 180, 116), rgb(220, 176, 82)},
	{"Ocean", rgb(39, 73, 103), rgb(20, 42, 64), rgb(74, 144, 226), rgb(56, 189, 248), rgb(46, 178, 124), rgb(232, 178, 73)},
	{"Deep Sea", rgb(18, 50, 62), rgb(8, 24, 31), rgb(36, 133, 163), rgb(58, 201, 216), rgb(40, 163, 118), rgb(214, 152, 64)},
	{"Glacier", rgb(213, 232, 242), rgb(182, 206, 219), rgb(105, 151, 192), rgb(118, 198, 223), rgb(79, 178, 134), rgb(216, 171, 92)},
	{"Harbor", rgb(82, 97, 118), rgb(56, 69, 88), rgb(118, 150, 186), rgb(102, 184, 197), rgb(73, 157, 122), rgb(205, 152, 81)},
	{"Azure", rgb(49, 87, 155), rgb(24, 45, 91), rgb(92, 154, 255), rgb(80, 208, 255), rgb(61, 196, 142), rgb(243, 192, 86)},
	{"Skyline", rgb(192, 224, 252), rgb(159, 193, 232), rgb(81, 132, 214), rgb(97, 175, 255), rgb(73, 180, 130), rgb(232, 168, 76)},
	{"Neon Cyan", rgb(17, 28, 41), rgb(5, 11, 19), rgb(28, 160, 198), rgb(0, 245, 255), rgb(48, 210, 142), rgb(255, 194, 63)},
	{"Lime Punch", rgb(34, 54, 31), rgb(14, 25, 12), rgb(118, 210, 48), rgb(191, 255, 64), rgb(74, 209, 116), rgb(255, 196, 72)},
	{"Radioactive", rgb(41, 44, 16), rgb(18, 19, 6), rgb(164, 223, 28), rgb(235, 255, 84), rgb(75, 202, 118), rgb(255, 171, 41)},
	{"Sunset", rgb(101, 69, 102), rgb(60, 38, 57), rgb(255, 130, 92), rgb(255, 187, 102), rgb(83, 191, 122), rgb(250, 165, 70)},
	{"Coral", rgb(255, 220, 214), rgb(242, 188, 181), rgb(238, 121, 105), rgb(255, 157, 134), rgb(87, 183, 126), rgb(236, 167, 82)},
	{"Rose Gold", rgb(250, 226, 223), rgb(230, 194, 188), rgb(199, 141, 132), rgb(228, 178, 160), rgb(112, 173, 130), rgb(210, 158, 93)},
	{"Sakura", rgb(252, 233, 243), rgb(242, 206, 225), rgb(232, 145, 184), rgb(255, 183, 209), rgb(103, 191, 132), rgb(242, 181, 89)},
	{"Plum", rgb(72, 48, 86), rgb(38, 24, 45), rgb(142, 95, 188), rgb(203, 122, 255), rgb(73, 176, 124), rgb(224, 161, 68)},
	{"Royal", rgb(39, 44, 103), rgb(21, 24, 55), rgb(88, 111, 228), rgb(146, 123, 255), rgb(58, 178, 125), rgb(237, 183, 68)},
	{"Lavender", rgb(236, 229, 252), rgb(214, 205, 241), rgb(158, 131, 224), rgb(206, 173, 255), rgb(106, 183, 136), rgb(228, 177, 86)},
	{"Grape Soda", rgb(86, 44, 110), rgb(45, 21, 61), rgb(176, 96, 231), rgb(244, 115, 255), rgb(66, 189, 127), rgb(236, 174, 66)},
	{"Copper", rgb(103, 66, 50), rgb(56, 34, 24), rgb(194, 124, 80), rgb(238, 156, 99), rgb(82, 170, 115), rgb(228, 165, 72)},
	{"Bronze", rgb(116, 91, 49), rgb(62, 46, 23), rgb(194, 150, 70), rgb(227, 184, 92), rgb(88, 166, 117), rgb(236, 173, 64)},
	{"Amber", rgb(92, 67, 26), rgb(45, 31, 10), rgb(221, 158, 42), rgb(255, 204, 87), rgb(80, 180, 119), rgb(255, 178, 50)},
	{"Honey", rgb(252, 233, 176), rgb(235, 206, 125), rgb(214, 162, 49), rgb(255, 204, 72), rgb(97, 177, 116), rgb(229, 152, 46)},
	{"Desert Bloom", rgb(232, 201, 164), rgb(197, 162, 121), rgb(197, 109, 88), rgb(230, 148, 120), rgb(114, 174, 116), rgb(218, 164, 82)},
	{"Forest", rgb(33, 62, 43), rgb(15, 30, 20), rgb(64, 138, 87), rgb(105, 201, 120), rgb(53, 184, 109), rgb(214, 162, 70)},
	{"Moss", rgb(78, 96, 53), rgb(42, 52, 28), rgb(127, 160, 76), rgb(173, 207, 100), rgb(66, 178, 118), rgb(211, 163, 67)},
	{"Pine", rgb(19, 49, 44), rgb(7, 21, 19), rgb(54, 123, 110), rgb(89, 180, 150), rgb(42, 168, 114), rgb(214, 159, 71)},
	{"Emerald", rgb(19, 74, 61), rgb(7, 34, 28), rgb(32, 176, 120), rgb(67, 222, 158), rgb(27, 188, 126), rgb(228, 181, 76)},
	{"Toxic", rgb(32, 41, 24), rgb(13, 17, 9), rgb(121, 214, 48), rgb(86, 255, 130), rgb(63, 208, 119), rgb(243, 174, 54)},
	{"Candy", rgb(255, 216, 233), rgb(250, 186, 213), rgb(255, 116, 180), rgb(255, 146, 214), rgb(74, 202, 136), rgb(243, 190, 90)},
	{"Bubblegum", rgb(255, 224, 246), rgb(248, 196, 226), rgb(240, 100, 176), rgb(255, 153, 232), rgb(84, 194, 146), rgb(245, 179, 97)},
	{"Cotton Candy", rgb(234, 241, 255), rgb(250, 218, 240), rgb(112, 174, 255), rgb(255, 159, 210), rgb(92, 196, 152), rgb(245, 191, 99)},
	{"Arcade", rgb(28, 26, 63), rgb(10, 9, 26), rgb(61, 119, 255), rgb(255, 92, 170), rgb(39, 210, 141), rgb(255, 194, 61)},
	{"Synthwave", rgb(51, 22, 83), rgb(18, 8, 35), rgb(236, 86, 154), rgb(82, 215, 255), rgb(62, 214, 156), rgb(255, 183, 68)},
	{"Vapor", rgb(202, 187, 244), rgb(157, 140, 206), rgb(103, 145, 255), rgb(255, 139, 195), rgb(90, 194, 165), rgb(243, 179, 91)},
	{"Cyberpunk", rgb(28, 23, 16), rgb(10, 8, 5), rgb(255, 183, 0), rgb(0, 240, 255), rgb(44, 209, 133), rgb(255, 145, 40)},
	{"Laser Grid", rgb(22, 10, 33), rgb(6, 3, 14), rgb(175, 82, 255), rgb(0, 255, 214), rgb(53, 212, 146), rgb(255, 191, 71)},
	{"Retro CRT", rgb(31, 44, 20), rgb(9, 14, 7), rgb(102, 221, 98), rgb(157, 255, 150), rgb(68, 196, 109), rgb(220, 171, 77)},
	{"Terminal Green", rgb(15, 28, 18), rgb(5, 11, 7), rgb(56, 197, 81), rgb(140, 255, 181), rgb(44, 175, 106), rgb(198, 163, 70)},
	{"Hacker Blue", rgb(15, 24, 35), rgb(5, 10, 16), rgb(46, 167, 255), rgb(129, 224, 255), rgb(48, 182, 121), rgb(211, 172, 77)},
	{"Noir", rgb(30, 30, 34), rgb(12, 12, 14), rgb(103, 103, 114), rgb(196, 196, 201), rgb(73, 165, 119), rgb(194, 149, 80)},
	{"Dracula", rgb(38, 32, 56), rgb(17, 14, 27), rgb(167, 139, 250), rgb(255, 121, 198), rgb(80, 196, 145), rgb(242, 190, 81)},
	{"Mocha", rgb(88, 70, 62), rgb(46, 35, 31), rgb(156, 117, 96), rgb(212, 163, 124), rgb(91, 168, 122), rgb(204, 152, 77)},
	{"Coffeehouse", rgb(130, 104, 83), rgb(83, 62, 48), rgb(191, 142, 95), rgb(232, 186, 133), rgb(105, 172, 123), rgb(221, 168, 77)},
	{"Cocoa", rgb(110, 80, 73), rgb(61, 44, 40), rgb(180, 125, 112), rgb(229, 167, 150), rgb(100, 167, 122), rgb(215, 161, 83)},
	{"Rust", rgb(112, 49, 38), rgb(59, 23, 18), rgb(193, 87, 68), rgb(240, 130, 97), rgb(88, 172, 112), rgb(223, 156, 66)},
	{"Lava", rgb(67, 18, 20), rgb(24, 5, 7), rgb(221, 72, 51), rgb(255, 123, 71), rgb(72, 175, 109), rgb(255, 172, 44)},
	{"Emberglass", rgb(88, 28, 26), rgb(34, 10, 11), rgb(255, 99, 78), rgb(255, 151, 102), rgb(94, 187, 125), rgb(244, 173, 58)},
	{"Volcano", rgb(58, 33, 29), rgb(20, 12, 10), rgb(198, 76, 56), rgb(241, 143, 86), rgb(77, 180, 120), rgb(231, 162, 51)},
	{"Sand", rgb(239, 223, 189), rgb(218, 198, 162), rgb(193, 153, 99), rgb(226, 183, 121), rgb(109, 173, 124), rgb(218, 157, 70)},
	{"Dune", rgb(212, 188, 152), rgb(181, 157, 122), rgb(174, 136, 88), rgb(206, 161, 107), rgb(104, 169, 117), rgb(210, 149, 72)},
	{"Canyon", rgb(165, 108, 83), rgb(115, 72, 53), rgb(214, 128, 90), rgb(239, 170, 118), rgb(102, 170, 118), rgb(227, 163, 73)},
	{"Terracotta", rgb(194, 128, 104), rgb(156, 98, 78), rgb(209, 112, 90), rgb(233, 153, 124), rgb(104, 171, 121), rgb(226, 165, 76)},
	{"Clay", rgb(169, 120, 110), rgb(129, 88, 80), rgb(184, 111, 101), rgb(220, 146, 136), rgb(102, 168, 124), rgb(212, 157, 84)},
	{"Arctic Sun", rgb(239, 244, 236), rgb(214, 225, 213), rgb(149, 174, 118), rgb(247, 198, 110), rgb(96, 174, 129), rgb(223, 170, 86)},
	{"Polar Night", rgb(24, 35, 61), rgb(11, 16, 28), rgb(103, 132, 201), rgb(145, 217, 255), rgb(67, 184, 132), rgb(222, 174, 76)},
	{"Aurora", rgb(27, 51, 60), rgb(10, 20, 25), rgb(74, 130, 191), rgb(86, 239, 173), rgb(56, 192, 143), rgb(223, 175, 80)},
	{"Galaxy", rgb(34, 28, 57), rgb(12, 9, 22), rgb(102, 88, 201), rgb(121, 194, 255), rgb(71, 186, 136), rgb(224, 176, 76)},
	{"Nebula", rgb(54, 26, 74), rgb(21, 8, 31), rgb(180, 83, 217), rgb(94, 182, 255), rgb(72, 192, 142), rgb(243, 183, 74)},
	{"Comet", rgb(27, 29, 45), rgb(9, 10, 17), rgb(124, 153, 255), rgb(189, 233, 255), rgb(74, 187, 136), rgb(220, 171, 76)},
	{"Starlight", rgb(230, 233, 248), rgb(204, 210, 232), rgb(136, 152, 216), rgb(188, 168, 255), rgb(105, 180, 137), rgb(226, 176, 86)},
	{"Solarized Dark", rgb(12, 43, 52), rgb(3, 22, 29), rgb(38, 139, 210), rgb(181, 137, 0), rgb(42, 161, 152), rgb(203, 75, 22)},
	{"Solarized Light", rgb(253, 246, 227), rgb(238, 232, 213), rgb(38, 139, 210), rgb(211, 54, 130), rgb(42, 161, 152), rgb(181, 137, 0)},
	{"Bookworm", rgb(243, 236, 224), rgb(224, 214, 195), rgb(119, 90, 56), rgb(166, 117, 84), rgb(100, 161, 120), rgb(204, 152, 68)},
	{"Blueprint", rgb(33, 55, 89), rgb(13, 25, 46), rgb(84, 143, 224), rgb(137, 211, 255), rgb(72, 184, 137), rgb(236, 187, 84)},
	{"Construction", rgb(82, 77, 56), rgb(41, 38, 26), rgb(236, 183, 58), rgb(242, 218, 125), rgb(87, 173, 117), rgb(255, 155, 47)},
	{"Toybox", rgb(245, 236, 213), rgb(225, 213, 182), rgb(219, 91, 86), rgb(92, 152, 255), rgb(72, 194, 124), rgb(244, 190, 71)},
	{"Plastic", rgb(233, 236, 241), rgb(212, 217, 224), rgb(114, 127, 154), rgb(162, 174, 196), rgb(95, 176, 126), rgb(226, 172, 80)},
	{"Obsidian", rgb(24, 26, 30), rgb(9, 11, 13), rgb(94, 107, 125), rgb(143, 154, 170), rgb(72, 165, 120), rgb(196, 149, 77)},
	{"Frostbite", rgb(202, 229, 252), rgb(166, 197, 228), rgb(77, 136, 211), rgb(100, 230, 255), rgb(75, 191, 148), rgb(241, 186, 88)},
	{"Seafoam", rgb(212, 246, 235), rgb(179, 226, 210), rgb(91, 191, 155), rgb(110, 226, 198), rgb(74, 181, 137), rgb(229, 178, 89)},
	{"Peach", rgb(255, 233, 218), rgb(247, 204, 181), rgb(243, 145, 96), rgb(255, 183, 142), rgb(95, 183, 133), rgb(236, 161, 71)},
	{"Lemonade", rgb(253, 250, 198), rgb(242, 232, 140), rgb(227, 198, 70), rgb(255, 228, 120), rgb(102, 180, 127), rgb(226, 156, 52)},
	{"Cherry Cola", rgb(87, 31, 42), rgb(39, 11, 18), rgb(184, 61, 89), rgb(247, 129, 129), rgb(81, 176, 120), rgb(229, 164, 74)},
	{"Blackberry", rgb(67, 35, 89), rgb(31, 15, 43), rgb(135, 78, 194), rgb(201, 116, 255), rgb(77, 184, 132), rgb(230, 174, 72)},
	{"Lagoon", rgb(27, 83, 89), rgb(10, 37, 40), rgb(51, 169, 173), rgb(117, 234, 208), rgb(57, 192, 138), rgb(233, 183, 72)},
	{"Marina", rgb(51, 98, 134), rgb(24, 49, 75), rgb(70, 157, 230), rgb(88, 205, 255), rgb(74, 188, 137), rgb(238, 187, 78)},
	{"Prism", rgb(245, 238, 255), rgb(221, 211, 240), rgb(102, 128, 255), rgb(255, 128, 194), rgb(90, 195, 151), rgb(244, 191, 90)},
	{"Carnival", rgb(255, 235, 181), rgb(246, 192, 124), rgb(235, 88, 80), rgb(102, 171, 255), rgb(62, 198, 116), rgb(241, 184, 53)},
	{"Pastel Pop", rgb(247, 233, 255), rgb(229, 212, 247), rgb(123, 171, 255), rgb(255, 167, 201), rgb(112, 201, 151), rgb(251, 205, 111)},
	{"Ink", rgb(26, 31, 45), rgb(10, 14, 22), rgb(79, 107, 161), rgb(132, 168, 214), rgb(67, 169, 127), rgb(210, 165, 84)},
	{"Cloud", rgb(243, 247, 252), rgb(219, 226, 235), rgb(140, 158, 184), rgb(171, 191, 220), rgb(111, 182, 138), rgb(224, 178, 90)},
	{"Storm", rgb(80, 87, 99), rgb(46, 51, 60), rgb(116, 131, 155), rgb(154, 178, 199), rgb(82, 171, 128), rgb(211, 162, 84)},
	{"Rainforest", rgb(26, 63, 46), rgb(10, 25, 18), rgb(57, 146, 90), rgb(96, 209, 134), rgb(46, 183, 121), rgb(222, 171, 70)},
	{"Boardwalk", rgb(80, 102, 128), rgb(52, 66, 84), rgb(197, 151, 96), rgb(122, 188, 219), rgb(85, 172, 125), rgb(228, 169, 75)},
	{"Steel", rgb(92, 101, 116), rgb(58, 65, 77), rgb(127, 145, 168), rgb(160, 179, 200), rgb(89, 171, 127), rgb(214, 164, 84)},
	{"Titanium", rgb(200, 207, 217), rgb(176, 184, 195), rgb(119, 132, 153), rgb(157, 171, 191), rgb(94, 174, 132), rgb(220, 170, 89)},
	{"Jade", rgb(27, 78, 60), rgb(10, 36, 28), rgb(55, 174, 125), rgb(90, 221, 176), rgb(43, 185, 128), rgb(224, 176, 77)},
	{"Ruby", rgb(91, 22, 39), rgb(39, 8, 17), rgb(205, 66, 104), rgb(255, 121, 153), rgb(78, 178, 125), rgb(232, 169, 73)},
	{"Sapphire", rgb(24, 53, 111), rgb(9, 21, 52), rgb(59, 119, 225), rgb(117, 176, 255), rgb(77, 184, 133), rgb(236, 183, 77)},
} ) do
	THEMES[seed[1]] = assignThemeTypography(seed[1], createThemeFromSeed(seed))
end

for _, entry in ipairs({
	{{"Fallout 4 Terminal", rgb(39, 62, 41), rgb(15, 24, 17), rgb(112, 209, 108), rgb(174, 247, 150), rgb(70, 182, 109), rgb(206, 166, 82)}, "Post-Apocalypse"},
	{{"Minecraft Grass", rgb(87, 126, 67), rgb(48, 74, 35), rgb(110, 173, 86), rgb(149, 205, 97), rgb(76, 176, 106), rgb(198, 152, 76)}, "Sandbox & Survival"},
	{{"Fortnite Neon", rgb(58, 73, 126), rgb(27, 33, 71), rgb(88, 147, 255), rgb(111, 239, 255), rgb(72, 201, 149), rgb(255, 181, 72)}, "Competitive & Hero"},
	{{"Grand Theft Auto Sunset", rgb(105, 66, 104), rgb(55, 32, 57), rgb(244, 127, 96), rgb(255, 177, 120), rgb(87, 185, 127), rgb(236, 160, 77)}, "Racing & Action"},
	{{"Red Dead Dust", rgb(119, 86, 63), rgb(67, 47, 34), rgb(176, 128, 85), rgb(222, 172, 111), rgb(93, 160, 111), rgb(205, 148, 74)}, "Racing & Action"},
	{{"Skyrim Frost", rgb(192, 205, 222), rgb(132, 150, 171), rgb(102, 134, 174), rgb(191, 221, 255), rgb(88, 176, 136), rgb(221, 176, 89)}, "Fantasy & RPG"},
	{{"Elden Ring Gold", rgb(75, 67, 46), rgb(34, 29, 18), rgb(190, 152, 69), rgb(248, 210, 120), rgb(98, 170, 116), rgb(220, 154, 63)}, "Fantasy & RPG"},
	{{"Dark Souls Ember", rgb(83, 47, 36), rgb(36, 20, 16), rgb(191, 92, 63), rgb(241, 154, 96), rgb(90, 168, 119), rgb(220, 155, 61)}, "Fantasy & RPG"},
	{{"Cyberpunk 2077", rgb(32, 31, 20), rgb(13, 12, 8), rgb(255, 210, 49), rgb(55, 239, 255), rgb(72, 194, 151), rgb(255, 145, 39)}, "Sci-Fi & Shooters"},
	{{"Halo UNSC", rgb(67, 91, 85), rgb(32, 45, 41), rgb(114, 148, 136), rgb(168, 213, 196), rgb(81, 174, 126), rgb(208, 163, 76)}, "Sci-Fi & Shooters"},
	{{"Doom Eternal", rgb(88, 30, 27), rgb(32, 9, 10), rgb(211, 73, 48), rgb(255, 130, 78), rgb(89, 182, 115), rgb(250, 164, 51)}, "Sci-Fi & Shooters"},
	{{"Call of Duty Tactical", rgb(64, 70, 66), rgb(28, 32, 30), rgb(129, 140, 132), rgb(175, 190, 182), rgb(80, 162, 117), rgb(197, 154, 75)}, "Sci-Fi & Shooters"},
	{{"Battlefield Steel", rgb(71, 79, 92), rgb(29, 34, 43), rgb(116, 141, 173), rgb(156, 196, 221), rgb(76, 171, 126), rgb(214, 168, 80)}, "Sci-Fi & Shooters"},
	{{"Apex Legends", rgb(93, 57, 52), rgb(40, 23, 21), rgb(219, 92, 74), rgb(255, 166, 132), rgb(88, 176, 126), rgb(239, 169, 71)}, "Competitive & Hero"},
	{{"Overwatch Hero", rgb(230, 232, 238), rgb(190, 198, 213), rgb(79, 118, 203), rgb(255, 168, 71), rgb(85, 181, 132), rgb(231, 151, 56)}, "Competitive & Hero"},
	{{"Valorant Strike", rgb(71, 49, 61), rgb(30, 20, 27), rgb(236, 91, 102), rgb(111, 218, 222), rgb(77, 181, 132), rgb(222, 167, 81)}, "Competitive & Hero"},
	{{"Counter-Strike Orange", rgb(97, 88, 67), rgb(44, 40, 29), rgb(201, 145, 71), rgb(240, 187, 113), rgb(92, 165, 122), rgb(216, 151, 58)}, "Competitive & Hero"},
	{{"Rainbow Six Siege", rgb(59, 63, 77), rgb(21, 24, 31), rgb(111, 134, 179), rgb(176, 196, 224), rgb(79, 171, 127), rgb(208, 162, 79)}, "Competitive & Hero"},
	{{"Destiny 2 Traveler", rgb(224, 229, 238), rgb(174, 185, 205), rgb(126, 147, 193), rgb(220, 241, 255), rgb(94, 178, 132), rgb(233, 182, 85)}, "Sci-Fi & Shooters"},
	{{"Mass Effect Omni", rgb(35, 48, 69), rgb(15, 23, 34), rgb(85, 137, 232), rgb(85, 220, 255), rgb(70, 189, 145), rgb(236, 177, 76)}, "Sci-Fi & Shooters"},
	{{"Dead Space Hull", rgb(64, 57, 50), rgb(27, 23, 20), rgb(128, 122, 112), rgb(97, 178, 221), rgb(87, 166, 126), rgb(198, 152, 75)}, "Horror & Atmosphere"},
	{{"Resident Evil Biohazard", rgb(66, 42, 35), rgb(23, 13, 11), rgb(162, 92, 80), rgb(210, 171, 127), rgb(85, 156, 111), rgb(196, 144, 67)}, "Horror & Atmosphere"},
	{{"Silent Hill Fog", rgb(128, 132, 129), rgb(84, 89, 86), rgb(157, 165, 160), rgb(205, 214, 210), rgb(103, 169, 126), rgb(192, 152, 82)}, "Horror & Atmosphere"},
	{{"The Witcher 3", rgb(74, 79, 66), rgb(35, 38, 29), rgb(157, 162, 107), rgb(210, 203, 129), rgb(88, 165, 120), rgb(212, 158, 64)}, "Fantasy & RPG"},
	{{"Zelda Sky Slate", rgb(143, 185, 173), rgb(84, 114, 108), rgb(104, 169, 156), rgb(181, 233, 217), rgb(84, 179, 132), rgb(226, 179, 83)}, "Fantasy & RPG"},
	{{"Mario Odyssey", rgb(224, 60, 60), rgb(126, 26, 27), rgb(255, 97, 86), rgb(255, 198, 73), rgb(76, 188, 129), rgb(246, 166, 52)}, "Arcade & Indie"},
	{{"Animal Crossing", rgb(188, 220, 176), rgb(129, 170, 114), rgb(117, 177, 108), rgb(241, 235, 176), rgb(83, 185, 132), rgb(226, 176, 88)}, "Sandbox & Survival"},
	{{"Stardew Valley", rgb(105, 143, 111), rgb(59, 92, 65), rgb(125, 181, 115), rgb(235, 203, 111), rgb(91, 182, 129), rgb(213, 159, 76)}, "Sandbox & Survival"},
	{{"Terraria Cavern", rgb(74, 82, 106), rgb(34, 38, 53), rgb(104, 151, 196), rgb(122, 225, 171), rgb(81, 180, 133), rgb(229, 171, 77)}, "Sandbox & Survival"},
	{{"Hades Infernal", rgb(86, 28, 41), rgb(31, 10, 18), rgb(210, 69, 94), rgb(255, 176, 87), rgb(77, 172, 120), rgb(230, 156, 62)}, "Arcade & Indie"},
	{{"Hollow Knight", rgb(79, 86, 111), rgb(35, 39, 54), rgb(124, 142, 194), rgb(215, 227, 255), rgb(88, 173, 129), rgb(225, 177, 85)}, "Arcade & Indie"},
	{{"Celeste Summit", rgb(74, 110, 173), rgb(40, 63, 108), rgb(112, 167, 255), rgb(255, 140, 177), rgb(91, 189, 141), rgb(237, 180, 85)}, "Arcade & Indie"},
	{{"Portal Test Chamber", rgb(218, 222, 224), rgb(176, 182, 188), rgb(89, 132, 227), rgb(242, 171, 54), rgb(97, 180, 134), rgb(231, 157, 55)}, "Sci-Fi & Shooters"},
	{{"Half-Life Lambda", rgb(112, 95, 61), rgb(62, 52, 31), rgb(217, 146, 62), rgb(241, 184, 98), rgb(95, 167, 124), rgb(218, 145, 52)}, "Sci-Fi & Shooters"},
	{{"BioShock Rapture", rgb(33, 61, 81), rgb(13, 24, 35), rgb(64, 146, 191), rgb(228, 182, 96), rgb(77, 172, 129), rgb(203, 151, 69)}, "Horror & Atmosphere"},
	{{"Assassins Creed", rgb(188, 191, 197), rgb(131, 136, 144), rgb(154, 161, 177), rgb(228, 233, 239), rgb(93, 176, 130), rgb(214, 165, 84)}, "Fantasy & RPG"},
	{{"Far Cry Tropic", rgb(84, 134, 121), rgb(45, 77, 70), rgb(110, 177, 150), rgb(255, 196, 117), rgb(88, 187, 135), rgb(224, 159, 78)}, "Racing & Action"},
	{{"Monster Hunter", rgb(109, 96, 73), rgb(53, 45, 32), rgb(178, 151, 97), rgb(219, 196, 142), rgb(102, 168, 121), rgb(205, 154, 66)}, "Fantasy & RPG"},
	{{"League of Legends", rgb(44, 59, 91), rgb(18, 25, 41), rgb(197, 158, 66), rgb(110, 181, 255), rgb(84, 182, 136), rgb(220, 168, 72)}, "Competitive & Hero"},
	{{"Dota 2 Ancient", rgb(82, 40, 41), rgb(29, 14, 15), rgb(172, 64, 72), rgb(94, 190, 109), rgb(72, 175, 120), rgb(219, 163, 77)}, "Competitive & Hero"},
	{{"Genshin Impact", rgb(214, 231, 244), rgb(171, 193, 219), rgb(116, 157, 227), rgb(255, 214, 150), rgb(96, 183, 145), rgb(234, 175, 85)}, "Fantasy & RPG"},
	{{"World of Warcraft", rgb(82, 61, 43), rgb(33, 23, 16), rgb(194, 157, 82), rgb(109, 171, 232), rgb(92, 169, 122), rgb(223, 157, 63)}, "Fantasy & RPG"},
	{{"Persona 5 Phantom", rgb(92, 17, 21), rgb(30, 5, 8), rgb(220, 34, 52), rgb(246, 244, 244), rgb(85, 174, 126), rgb(222, 156, 63)}, "Arcade & Indie"},
	{{"Final Fantasy VII", rgb(38, 74, 102), rgb(17, 36, 53), rgb(103, 169, 212), rgb(203, 231, 255), rgb(87, 180, 136), rgb(220, 174, 84)}, "Fantasy & RPG"},
	{{"Diablo IV Ash", rgb(78, 32, 27), rgb(28, 9, 8), rgb(167, 69, 57), rgb(215, 148, 97), rgb(89, 161, 117), rgb(207, 143, 58)}, "Fantasy & RPG"},
	{{"Sea of Thieves", rgb(49, 104, 100), rgb(22, 50, 48), rgb(94, 177, 168), rgb(205, 230, 170), rgb(83, 181, 132), rgb(228, 177, 79)}, "Sandbox & Survival"},
	{{"Rocket League", rgb(35, 71, 133), rgb(15, 33, 71), rgb(78, 149, 255), rgb(80, 227, 255), rgb(79, 195, 144), rgb(255, 170, 60)}, "Racing & Action"},
	{{"Need for Speed", rgb(38, 38, 47), rgb(12, 12, 16), rgb(94, 119, 255), rgb(255, 91, 169), rgb(71, 192, 148), rgb(255, 186, 69)}, "Racing & Action"},
	{{"Gran Turismo", rgb(217, 221, 228), rgb(176, 183, 196), rgb(93, 123, 207), rgb(221, 74, 64), rgb(86, 177, 133), rgb(228, 171, 79)}, "Racing & Action"},
	{{"Helldivers 2", rgb(80, 82, 55), rgb(33, 35, 23), rgb(161, 172, 96), rgb(241, 210, 88), rgb(91, 167, 117), rgb(211, 155, 62)}, "Sci-Fi & Shooters"},
}) do
	local seed, category = entry[1], entry[2]
	THEMES[seed[1]] = assignThemeTypography(seed[1], createThemeFromSeed(seed))
	THEME_CATEGORIES[seed[1]] = category
end

for themeName, theme in pairs(THEMES) do
	assignThemeTypography(themeName, theme)
end

function getSetting(key, fallback)
	local success, value = pcall(function()
		return plugin:GetSetting(key)
	end)
	if success and value ~= nil then
		return value
	end
	return fallback
end

function setSetting(key, value)
	pcall(function()
		plugin:SetSetting(key, value)
	end)
end

function parseNumber(text, fallback, minimum, maximum)
	local value = tonumber(text)
	if not value then
		return fallback
	end
	value = math.floor(value + 0.5)
	if minimum then
		value = math.max(minimum, value)
	end
	if maximum then
		value = math.min(maximum, value)
	end
	return value
end

function parseDecimal(text, fallback, minimum, maximum)
	local value = tonumber(text)
	if not value then
		return fallback
	end
	if minimum then
		value = math.max(minimum, value)
	end
	if maximum then
		value = math.min(maximum, value)
	end
	return value
end

function parseBoolean(text, fallback)
	local value = string.lower(string.gsub(text or "", "%s+", ""))
	if value == "true" or value == "yes" or value == "on" or value == "1" then
		return true
	end
	if value == "false" or value == "no" or value == "off" or value == "0" then
		return false
	end
	return fallback
end

function getBooleanSetting(key, fallback)
	local value = getSetting(key, fallback)
	if type(value) == "boolean" then
		return value
	end
	return parseBoolean(tostring(value or ""), fallback)
end

function cloneTable(tbl)
	local copy = {}
	for key, value in pairs(tbl) do
		copy[key] = value
	end
	return copy
end

local defaultCollisionHeuristics = {
	simpleMaxParts = 4,
	simpleOccupancy = 0.55,
	simpleDominantShare = 0.45,
	detailedPartThreshold = 18,
	detailedPartThresholdSecondary = 10,
	detailedOccupancy = 0.18,
	detailedOccupancySecondary = 0.32,
	detailedElongation = 6,
}

local collisionHeuristicPresets = {
	medium = {
		simpleMaxParts = 6,
		simpleOccupancy = 0.5,
		simpleDominantShare = 0.4,
		detailedPartThreshold = 24,
		detailedPartThresholdSecondary = 14,
		detailedOccupancy = 0.22,
		detailedOccupancySecondary = 0.36,
		detailedElongation = 8,
	},
	high = cloneTable(defaultCollisionHeuristics),
	ultra = {
		simpleMaxParts = 5,
		simpleOccupancy = 0.58,
		simpleDominantShare = 0.5,
		detailedPartThreshold = 14,
		detailedPartThresholdSecondary = 8,
		detailedOccupancy = 0.14,
		detailedOccupancySecondary = 0.28,
		detailedElongation = 5,
	},
}

local collisionHeuristicsConfig = cloneTable(defaultCollisionHeuristics)

local collisionPreviewEnabled = getBooleanSetting(SETTINGS.collisionPreview, false)
local cacheEnabled = getBooleanSetting(SETTINGS.cacheEnabled, false)
local autoOpenPreviewEnabled = getBooleanSetting(SETTINGS.autoOpenPreview, false)
local showAdvancedCollisionTuning = getBooleanSetting(SETTINGS.showAdvancedCollisionTuning, false)
local confirmStoreAllEnabled = getBooleanSetting(SETTINGS.confirmStoreAll, true)
local collisionPreviewHighlights = {}
local lastCollisionSources = nil
local lastRequestedColliderMode = "ai"
local collisionInfoLabel
local collisionPreviewButton
local collisionHighlightColor = Color3.fromRGB(43, 156, 233)

local normalizeColliderMode
local resolveColliderMode
local clearCollisionHighlights
local refreshCollisionHighlights
local updateCollisionPreviewButton
local setCollisionPreviewEnabled
local createCollisionProxies
local collisionTuningFrame
local updateResponsiveLayouts
local themeRegistry = {
	roots = {},
	cards = {},
	labels = {},
	textBoxes = {},
	buttons = {},
}
local themeUi = {}
local ui = {}
ui.settingsSearchEntries = {}
ui.settingsSearchSections = {}
ui.settingsSearchShortcuts = {}
ui.guideStepButtons = {}
ui.guideFocusGroups = {}
local themeState = {
	name = tostring(getSetting(SETTINGS.theme, "Midnight")),
	current = nil,
	variant = normalizeThemeChoice(getSetting(SETTINGS.themeVariant, "Default"), THEME_VARIANT_ORDER, "Default"),
	tone = normalizeThemeChoice(getSetting(SETTINGS.themeTone, "Default"), THEME_TONE_ORDER, "Default"),
	contrast = normalizeThemeChoice(getSetting(SETTINGS.themeContrast, "Balanced"), THEME_CONTRAST_ORDER, "Balanced"),
	typography = normalizeThemeChoice(getSetting(SETTINGS.themeTypography, "Theme Default"), THEME_TYPOGRAPHY_ORDER, "Theme Default"),
}
if not THEMES[themeState.name] then
	themeState.name = "Midnight"
end
themeState.current = buildStyledTheme(
	themeState.name,
	themeState.variant,
	themeState.tone,
	themeState.contrast,
	themeState.typography
) or THEMES[themeState.name]

function createCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = instance
end

local THEME_TWEEN_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local THEME_GRADIENT_TWEEN_INFO = TweenInfo.new(0.32, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local BUTTON_HOVER_TWEEN_INFO = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BUTTON_PRESS_TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local GUIDE_FOCUS_IN_TWEEN_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local GUIDE_FOCUS_OUT_TWEEN_INFO = TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function tweenProperties(instance, tweenInfo, properties)
	if not instance then
		return nil
	end
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

function tweenGradientOffset(instance, startOffset, endOffset)
	local gradient = instance and instance:FindFirstChildOfClass("UIGradient")
	if not gradient then
		return
	end
	gradient.Offset = startOffset
	tweenProperties(gradient, THEME_GRADIENT_TWEEN_INFO, {
		Offset = endOffset,
	})
end

function tweenThemeBackground(instance, color)
	if not instance then
		return
	end
	tweenProperties(instance, THEME_TWEEN_INFO, {
		BackgroundColor3 = color,
	})
	tweenGradientOffset(instance, Vector2.new(0, -0.06), Vector2.new(0, 0))
end

function tweenThemeStroke(instance, color)
	local stroke = instance and instance:FindFirstChildOfClass("UIStroke")
	if not stroke then
		return
	end
	tweenProperties(stroke, THEME_TWEEN_INFO, {
		Color = color,
	})
end

function tweenThemeTextColor(instance, color)
	if not instance or not instance:IsA("TextLabel") and not instance:IsA("TextButton") and not instance:IsA("TextBox") then
		return
	end
	tweenProperties(instance, THEME_TWEEN_INFO, {
		TextColor3 = color,
	})
end

function tweenThemePlaceholderColor(instance, color)
	if not instance or not instance:IsA("TextBox") then
		return
	end
	tweenProperties(instance, THEME_TWEEN_INFO, {
		PlaceholderColor3 = color,
	})
end

function getButtonScale(button)
	local scale = button:FindFirstChild("ThemeButtonScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "ThemeButtonScale"
		scale.Scale = 1
		scale.Parent = button
	end
	return scale
end

function getButtonMotionState(button)
	local hovered = button:GetAttribute("ThemeHovered") == true
	local pressed = button:GetAttribute("ThemePressed") == true
	if pressed then
		return 0.97
	end
	if hovered then
		return 1.025
	end
	return 1
end

function refreshButtonMotion(button)
	if not button then
		return
	end
	local scale = getButtonScale(button)
	local targetScale = getButtonMotionState(button)
	local tweenInfo = button:GetAttribute("ThemePressed") == true and BUTTON_PRESS_TWEEN_INFO or BUTTON_HOVER_TWEEN_INFO
	tweenProperties(scale, tweenInfo, {
		Scale = targetScale,
	})
end

function attachButtonThemeMotion(button)
	if not button or button:GetAttribute("ThemeMotionBound") == true then
		return
	end
	button:SetAttribute("ThemeMotionBound", true)
	button:SetAttribute("ThemeHovered", false)
	button:SetAttribute("ThemePressed", false)
	getButtonScale(button)

	button.MouseEnter:Connect(function()
		button:SetAttribute("ThemeHovered", true)
		refreshButtonMotion(button)
	end)

	button.MouseLeave:Connect(function()
		button:SetAttribute("ThemeHovered", false)
		button:SetAttribute("ThemePressed", false)
		refreshButtonMotion(button)
	end)

	button.MouseButton1Down:Connect(function()
		button:SetAttribute("ThemePressed", true)
		refreshButtonMotion(button)
	end)

	button.MouseButton1Up:Connect(function()
		button:SetAttribute("ThemePressed", false)
		refreshButtonMotion(button)
	end)
end

function addVerticalGradient(instance, topColor, bottomColor)
	local gradient = instance:FindFirstChildOfClass("UIGradient")
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Rotation = 90
		gradient.Parent = instance
	end
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	return gradient
end

function createStroke(instance, color)
	local stroke = instance:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Parent = instance
	end
	stroke.Color = color or Color3.fromRGB(62, 70, 86)
	return stroke
end

function createShadow(instance, transparency, size)
	local shadow = Instance.new("Frame")
	shadow.Name = instance.Name .. "_Shadow"
	shadow.BackgroundColor3 = Color3.fromRGB(18, 28, 44)
	shadow.BackgroundTransparency = transparency or 0.72
	shadow.BorderSizePixel = 0
	shadow.Size = UDim2.new(1, size or 6, 1, size or 6)
	shadow.Position = UDim2.new(0, math.floor((size or 6) * -0.5), 0, 4)
	shadow.ZIndex = math.max(instance.ZIndex - 1, 0)
	shadow.Parent = instance

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = shadow
end

function styleCard(instance, topColor, bottomColor, strokeColor, includeShadow)
	createCorner(instance, 12)
	addVerticalGradient(instance, topColor, bottomColor)
	createStroke(instance, strokeColor or Color3.fromRGB(70, 88, 115))
	if includeShadow ~= false then
		createShadow(instance, 0.72, 8)
	end
	table.insert(themeRegistry.cards, {
		instance = instance,
		role = "panel",
		includeShadow = includeShadow,
	})
end

function countGuiChildren(parent)
	local count = 0
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") and not string.match(child.Name, "_Shadow$") then
			count += 1
		end
	end
	return count
end

function applyAdaptiveGrid(parent, layout, maxColumns, minCellWidth, rowHeight, paddingX, paddingY, verticalInset)
	local width = parent.AbsoluteSize.X
	if width <= 0 then
		return
	end

	local availableWidth = math.max(width - 20, minCellWidth)
	local columns = math.clamp(math.floor((availableWidth + paddingX) / (minCellWidth + paddingX)), 1, maxColumns)
	layout.FillDirectionMaxCells = columns
	layout.CellPadding = UDim2.new(0, paddingX, 0, paddingY)
	layout.CellSize = UDim2.new(1 / columns, -math.ceil(((columns - 1) * paddingX) / columns), 0, rowHeight)

	local itemCount = countGuiChildren(parent)
	local rows = math.max(1, math.ceil(itemCount / columns))
	local totalHeight = rows * rowHeight + math.max(0, rows - 1) * paddingY + verticalInset
	parent.Size = UDim2.new(1, 0, 0, totalHeight)
end

function applyThemeToRoot(entry)
	local instance = entry.instance
	if not instance or not instance.Parent then
		return
	end
	tweenThemeBackground(instance, themeState.current.backgroundBottom)
	addVerticalGradient(instance, themeState.current.backgroundTop, themeState.current.backgroundBottom)
end

function applyThemeToCard(entry)
	local instance = entry.instance
	if not instance or not instance.Parent then
		return
	end

	local topColor = themeState.current.panelTop
	local bottomColor = themeState.current.panelBottom
	local strokeColor = themeState.current.panelStroke
	if entry.role == "panelStrong" then
		topColor = themeState.current.panelStrongTop
		bottomColor = themeState.current.panelStrongBottom
		strokeColor = themeState.current.panelStrongStroke
	elseif entry.role == "viewport" then
		topColor = themeState.current.viewportTop
		bottomColor = themeState.current.viewportBottom
		strokeColor = themeState.current.viewportStroke
	end

	tweenThemeBackground(instance, bottomColor)
	addVerticalGradient(instance, topColor, bottomColor)
	createStroke(instance, strokeColor)
	tweenThemeStroke(instance, strokeColor)
end

function applyThemeToLabel(entry)
	local label = entry.instance
	if not label or not label.Parent then
		return
	end
	local typography = themeState.current.typography or {}
	local role = entry.fontRole or "body"
	label.Font = typography[role] or entry.defaultFont or Enum.Font.Gotham
end

function applyThemeToTextBox(entry)
	local box = entry.instance
	if not box or not box.Parent then
		return
	end
	local typography = themeState.current.typography or {}
	tweenThemeBackground(box, themeState.current.inputBase)
	tweenThemeTextColor(box, themeState.current.inputText)
	tweenThemePlaceholderColor(box, themeState.current.inputPlaceholder)
	box.Font = typography[entry.fontRole or "input"] or entry.defaultFont or Enum.Font.Gotham
	createStroke(box, themeState.current.inputStroke)
	tweenThemeStroke(box, themeState.current.inputStroke)
	addVerticalGradient(box, themeState.current.inputTop, themeState.current.inputBottom)
end

function applyThemeToButton(entry)
	local button = entry.instance
	if not button or not button.Parent then
		return
	end
	local typography = themeState.current.typography or {}
	local role = button:GetAttribute("ThemeRole") or entry.role or "secondary"
	local baseColor = themeState.current.buttons[role] or themeState.current.buttons.secondary
	tweenThemeBackground(button, baseColor)
	tweenThemeTextColor(button, Color3.fromRGB(255, 255, 255))
	button.Font = typography.button or entry.defaultFont or Enum.Font.GothamBold
	createStroke(button, themeState.current.buttonStroke)
	tweenThemeStroke(button, themeState.current.buttonStroke)
	addVerticalGradient(
		button,
		baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.12),
		baseColor:Lerp(Color3.fromRGB(0, 0, 0), 0.14)
	)
end

function applyTheme(themeName)
	if not THEMES[themeName] then
		return
	end
	themeState.name = themeName
	setSetting(SETTINGS.theme, themeName)
	themeState.current = buildStyledTheme(
		themeState.name,
		themeState.variant,
		themeState.tone,
		themeState.contrast,
		themeState.typography
	) or THEMES[themeName]

	for _, entry in ipairs(themeRegistry.roots) do
		applyThemeToRoot(entry)
	end
	for _, entry in ipairs(themeRegistry.cards) do
		applyThemeToCard(entry)
	end
	for _, entry in ipairs(themeRegistry.labels) do
		applyThemeToLabel(entry)
	end
	for _, entry in ipairs(themeRegistry.textBoxes) do
		applyThemeToTextBox(entry)
	end
	for _, entry in ipairs(themeRegistry.buttons) do
		applyThemeToButton(entry)
	end
end

function setThemeVariant(variant)
	themeState.variant = normalizeThemeChoice(variant, THEME_VARIANT_ORDER, "Default")
	setSetting(SETTINGS.themeVariant, themeState.variant)
	applyTheme(themeState.name)
end

function setThemeTone(tone)
	themeState.tone = normalizeThemeChoice(tone, THEME_TONE_ORDER, "Default")
	setSetting(SETTINGS.themeTone, themeState.tone)
	applyTheme(themeState.name)
end

function setThemeContrast(contrast)
	themeState.contrast = normalizeThemeChoice(contrast, THEME_CONTRAST_ORDER, "Balanced")
	setSetting(SETTINGS.themeContrast, themeState.contrast)
	applyTheme(themeState.name)
end

function setThemeTypography(typographyMode)
	themeState.typography = normalizeThemeChoice(typographyMode, THEME_TYPOGRAPHY_ORDER, "Theme Default")
	setSetting(SETTINGS.themeTypography, themeState.typography)
	applyTheme(themeState.name)
end

function resetThemeStyling()
	themeState.variant = "Default"
	themeState.tone = "Default"
	themeState.contrast = "Balanced"
	themeState.typography = "Theme Default"
	setSetting(SETTINGS.themeVariant, themeState.variant)
	setSetting(SETTINGS.themeTone, themeState.tone)
	setSetting(SETTINGS.themeContrast, themeState.contrast)
	setSetting(SETTINGS.themeTypography, themeState.typography)
	applyTheme(themeState.name)
end

function setButtonThemeRole(button, role)
	if not button then
		return
	end
	button:SetAttribute("ThemeRole", role)
	for _, entry in ipairs(themeRegistry.buttons) do
		if entry.instance == button then
			entry.role = role
			applyThemeToButton(entry)
			break
		end
	end
end

function createLabel(text, size, font, color, height)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, height or 20)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Font = font or Enum.Font.Gotham
	label.TextSize = size or 14
	label.TextColor3 = color or Color3.fromRGB(229, 233, 240)
	label.TextStrokeTransparency = 1
	table.insert(themeRegistry.labels, {
		instance = label,
		defaultFont = label.Font,
		fontRole = label.Font == Enum.Font.Code and "mono" or (label.Font == Enum.Font.GothamBold and "title" or "body"),
	})
	return label
end

function createSectionTitle(text)
	return createLabel(text, 13, Enum.Font.GothamBold, Color3.fromRGB(243, 246, 250), 18)
end

function enableAutoHeightLabel(label, minHeight)
	if not label then
		return label
	end
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Size = UDim2.new(1, 0, 0, minHeight or 0)
	return label
end

function registerSettingsSection(sectionId, header, keywords, helperLabel)
	ui.settingsSearchSections[sectionId] = {
		header = header,
		helper = helperLabel,
		keywords = string.lower(keywords or ""),
	}
end

function registerSettingsSearchEntry(instance, keywords, sectionId, includeText)
	table.insert(ui.settingsSearchEntries, {
		instance = instance,
		keywords = string.lower(keywords or ""),
		sectionId = sectionId,
		includeText = includeText == true,
		respectContentVisibility = instance:GetAttribute("RespectContentVisibility") == true,
	})
end

function registerSettingsShortcut(title, target, keywords, sectionId)
	table.insert(ui.settingsSearchShortcuts, {
		title = title,
		target = target,
		keywords = string.lower(keywords or title or ""),
		sectionId = sectionId,
	})
end

function createSettingsItem(title, description)
	local parent = ui.activeSettingsGroup or ui.settingsPanel
	local titleLabel = createSectionTitle(title)
	titleLabel.Parent = parent

	local descriptionLabel = createLabel(
		description,
		12,
		Enum.Font.Gotham,
		Color3.fromRGB(157, 168, 183),
		24
	)
	enableAutoHeightLabel(descriptionLabel, 24)
	descriptionLabel.Parent = parent

	return titleLabel, descriptionLabel
end

function createSettingsGroup(title, description)
	local group = Instance.new("Frame")
	group.Size = UDim2.new(1, 0, 0, 0)
	group.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	group.BorderSizePixel = 0
	group.AutomaticSize = Enum.AutomaticSize.Y
	group.Parent = ui.settingsPanel
	styleCard(group, Color3.fromRGB(58, 71, 97), Color3.fromRGB(35, 44, 60), Color3.fromRGB(102, 126, 168), false)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = group

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Parent = group

	local titleLabel = createLabel(title, 16, Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), 22)
	enableAutoHeightLabel(titleLabel, 22)
	titleLabel.Parent = group

	local descriptionLabel = createLabel(
		description,
		12,
		Enum.Font.Gotham,
		Color3.fromRGB(171, 183, 199),
		24
	)
	enableAutoHeightLabel(descriptionLabel, 24)
	descriptionLabel.Parent = group

	return group, titleLabel, descriptionLabel
end

function scrollSettingsTargetIntoView(target)
	if not ui.settingsRoot or not target or not target.Parent then
		return
	end
	local relativeY = target.AbsolutePosition.Y - ui.settingsRoot.AbsolutePosition.Y + ui.settingsRoot.CanvasPosition.Y
	local nextY = math.max(relativeY - 18, 0)
	ui.settingsRoot.CanvasPosition = Vector2.new(0, nextY)
	if target:IsA("TextBox") then
		target:CaptureFocus()
	end
end

function refreshSettingsSearch()
	if not ui.settingsSearchBox then
		return
	end

	local query = string.lower((ui.settingsSearchBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
	local sectionMatch = {}
	local sectionVisibleCounts = {}

	for sectionId, section in pairs(ui.settingsSearchSections) do
		sectionMatch[sectionId] = query ~= "" and string.find(section.keywords, query, 1, true) ~= nil
		sectionVisibleCounts[sectionId] = 0
	end

	for _, entry in ipairs(ui.settingsSearchEntries) do
		local entryText = entry.includeText and string.lower(tostring(entry.instance.Text or "")) or ""
		local contentVisible = entry.respectContentVisibility ~= true or entry.instance:GetAttribute("HasVisibleContent") == true
		local matched = query == ""
			or sectionMatch[entry.sectionId]
			or string.find(entry.keywords, query, 1, true) ~= nil
			or (entryText ~= "" and string.find(entryText, query, 1, true) ~= nil)
		entry.instance.Visible = matched and contentVisible
		if matched then
			sectionVisibleCounts[entry.sectionId] = (sectionVisibleCounts[entry.sectionId] or 0) + 1
		end
	end

	for sectionId, section in pairs(ui.settingsSearchSections) do
		local showSection = sectionId == "search" or query == "" or sectionMatch[sectionId] or (sectionVisibleCounts[sectionId] or 0) > 0
		if section.container then
			section.container.Visible = showSection
		end
		if section.header then
			section.header.Visible = showSection
		end
		if section.helper then
			section.helper.Visible = showSection
		end
	end

	if ui.settingsSearchResultsFrame then
		local matches = {}
		if query ~= "" then
			for _, shortcut in ipairs(ui.settingsSearchShortcuts) do
				if shortcut.target and shortcut.target.Parent and string.find(shortcut.keywords, query, 1, true) ~= nil then
					table.insert(matches, shortcut)
				end
			end
		end

		for index, button in ipairs(ui.settingsSearchResultButtons or {}) do
			local match = matches[index]
			if match then
				button.Text = match.title
				button.Visible = true
				button:SetAttribute("TargetIndex", index)
			else
				button.Text = ""
				button.Visible = false
				button:SetAttribute("TargetIndex", 0)
			end
		end
		ui.settingsSearchResultsFrame.Visible = query ~= "" and #matches > 0
		ui.settingsSearchEmptyLabel.Visible = query ~= "" and #matches == 0
	end
end

function createTextBox(height, placeholder, defaultText, font)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, height)
	box.BackgroundColor3 = Color3.fromRGB(54, 66, 88)
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.PlaceholderText = placeholder
	box.Text = defaultText or ""
	box.Font = font or Enum.Font.Gotham
	box.TextSize = 15
	box.TextColor3 = Color3.fromRGB(248, 250, 255)
	box.TextStrokeTransparency = 1
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Top
	box.PlaceholderColor3 = Color3.fromRGB(188, 200, 219)
	createCorner(box, 10)
	createStroke(box, Color3.fromRGB(110, 137, 176))
	addVerticalGradient(box, Color3.fromRGB(74, 90, 119), Color3.fromRGB(56, 68, 90))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = box
	table.insert(themeRegistry.textBoxes, {
		instance = box,
		defaultFont = box.Font,
		fontRole = box.Font == Enum.Font.Code and "mono" or "input",
	})
	return box
end

function createSmallBox(placeholder, defaultText)
	local box = createTextBox(40, placeholder, defaultText, Enum.Font.Gotham)
	box.TextYAlignment = Enum.TextYAlignment.Center
	local padding = box:FindFirstChildOfClass("UIPadding")
	if padding then
		padding.PaddingTop = UDim.new(0, 0)
		padding.PaddingBottom = UDim.new(0, 0)
	end
	return box
end

function createButton(text, color, themeRole)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 34)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextStrokeTransparency = 1
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.TextWrapped = true
	createCorner(button, 10)
	createStroke(button, Color3.fromRGB(33, 45, 65))
	addVerticalGradient(
		button,
		color:Lerp(Color3.fromRGB(255, 255, 255), 0.12),
		color:Lerp(Color3.fromRGB(0, 0, 0), 0.14)
	)
	button:SetAttribute("ThemeRole", themeRole or "secondary")
	table.insert(themeRegistry.buttons, {
		instance = button,
		role = themeRole or "secondary",
		defaultFont = button.Font,
	})
	attachButtonThemeMotion(button)
	return button
end

function generateRandomSeed()
	local random = Random.new()
	return tostring(random:NextInteger(10000000, 99999999))
end

function loadPromptHistory()
	local stored = getSetting(SETTINGS.promptHistory, {})
	if type(stored) ~= "table" then
		return {}
	end
	local history = {}
	for _, entry in ipairs(stored) do
		if type(entry) == "string" and string.gsub(entry, "%s+", "") ~= "" then
			table.insert(history, entry)
		end
	end
	return history
end

local recentPromptHistory = loadPromptHistory()
local pendingStoreAllConfirmation = false
local generationTexturesEnabled = getBooleanSetting(SETTINGS.textures, true)
local generationIncludeBaseEnabled = getBooleanSetting(SETTINGS.includeBase, true)
local generationAnchoredEnabled = getBooleanSetting(SETTINGS.anchored, true)
local experimentalStyleBias = tostring(getSetting(SETTINGS.experimentalStyleBias, "Off"))
local experimentalPreviewMode = tostring(getSetting(SETTINGS.experimentalPreviewMode, "Balanced"))
local experimentalGroundSnap = getBooleanSetting(SETTINGS.experimentalGroundSnap, false)

function computeCacheKey(text)
	local hashA = 5381
	local hashB = 52711
	for index = 1, #text do
		local byte = string.byte(text, index)
		hashA = (hashA * 33 + byte) % 2147483647
		hashB = (hashB * 131 + byte) % 2147483647
	end
	return string.format("Cache_%d_%d", hashA, hashB)
end

function buildVisualCacheKey(request)
	return computeCacheKey(table.concat({
		request.effectivePrompt or request.prompt or "",
		tostring(request.targetSize or ""),
		tostring((request.inputs and request.inputs.MaxTriangles) or request.maxTriangles or ""),
		tostring(request.textures or ""),
		tostring(request.schemaName or ""),
	}, "|"))
end

function getVisualCacheFolder()
	local folder = ServerStorage:FindFirstChild("DetailedModelVisualCache")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "DetailedModelVisualCache"
		folder.Parent = ServerStorage
	end
	return folder
end

function loadCachedVisualModel(request)
	if not cacheEnabled then
		return nil
	end
	local cachedModel = getVisualCacheFolder():FindFirstChild(buildVisualCacheKey(request))
	if cachedModel then
		return cachedModel:Clone()
	end
	return nil
end

function storeCachedVisualModel(request, generatedModel)
	if not cacheEnabled or not generatedModel then
		return
	end
	local cacheKey = buildVisualCacheKey(request)
	local cacheFolder = getVisualCacheFolder()
	local existing = cacheFolder:FindFirstChild(cacheKey)
	if existing then
		existing:Destroy()
	end
	local cachedModel = generatedModel:Clone()
	cachedModel.Name = cacheKey
	cachedModel.Parent = cacheFolder
end

function clearVisualCache()
	local cacheFolder = ServerStorage:FindFirstChild("DetailedModelVisualCache")
	if not cacheFolder then
		return 0
	end
	local removed = 0
	for _, child in ipairs(cacheFolder:GetChildren()) do
		child:Destroy()
		removed += 1
	end
	return removed
end

function pushPromptHistory(prompt)
	local trimmed = tostring(prompt or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then
		return
	end
	local updated = {trimmed}
	for _, entry in ipairs(recentPromptHistory) do
		if entry ~= trimmed then
			table.insert(updated, entry)
		end
		if #updated >= 5 then
			break
		end
	end
	recentPromptHistory = updated
	setSetting(SETTINGS.promptHistory, recentPromptHistory)
end

local root = Instance.new("ScrollingFrame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
root.BorderSizePixel = 0
root.AutomaticCanvasSize = Enum.AutomaticSize.Y
root.CanvasSize = UDim2.new()
root.ScrollBarThickness = 6
root.Parent = widget
addVerticalGradient(root, Color3.fromRGB(42, 52, 72), Color3.fromRGB(24, 31, 44))
table.insert(themeRegistry.roots, {instance = root})

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = root

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = root

function scrollMainTargetIntoView(target)
	if not root or not target or not target.Parent then
		return
	end
	local relativeY = target.AbsolutePosition.Y - root.AbsolutePosition.Y + root.CanvasPosition.Y
	local nextY = math.max(relativeY - 18, 0)
	root.CanvasPosition = Vector2.new(0, nextY)
end

function pulseGuideFocusTarget(target)
	if not target or not target.Parent then
		return
	end

	local focusStroke = target:FindFirstChild("GuideFocusStroke")
	if not focusStroke then
		focusStroke = Instance.new("UIStroke")
		focusStroke.Name = "GuideFocusStroke"
		focusStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		focusStroke.Thickness = 0
		focusStroke.Transparency = 1
		focusStroke.Color = Color3.fromRGB(170, 255, 109)
		focusStroke.Parent = target
	end

	focusStroke.Enabled = true
	focusStroke.Color = Color3.fromRGB(170, 255, 109)
	focusStroke.Thickness = 0
	focusStroke.Transparency = 1

	tweenProperties(focusStroke, GUIDE_FOCUS_IN_TWEEN_INFO, {
		Thickness = 4,
		Transparency = 0.05,
	})

	task.delay(0.18, function()
		if not focusStroke or not focusStroke.Parent then
			return
		end
		local fadeTween = tweenProperties(focusStroke, GUIDE_FOCUS_OUT_TWEEN_INFO, {
			Thickness = 1,
			Transparency = 1,
		})
		if fadeTween then
			fadeTween.Completed:Connect(function()
				if focusStroke and focusStroke.Parent then
					focusStroke.Enabled = false
				end
			end)
		end
	end)
end

function focusGuideStep(stepId)
	local targets = ui.guideFocusGroups[stepId]
	if type(targets) ~= "table" or #targets == 0 then
		return
	end

	widget.Enabled = true
	local firstTarget = nil
	for _, target in ipairs(targets) do
		if target and target.Parent then
			firstTarget = target
			break
		end
	end
	if firstTarget then
		scrollMainTargetIntoView(firstTarget)
	end

	for index, target in ipairs(targets) do
		task.delay((index - 1) * 0.14, function()
			pulseGuideFocusTarget(target)
		end)
	end
end

do
	local promptTitle = createSectionTitle("Prompt")
	promptTitle.LayoutOrder = 14
	promptTitle.Parent = root
end

ui.promptBox = createTextBox(
	140,
	"Example: detailed medieval castle gate with banners, stone wear, and iron hinges",
	tostring(getSetting(SETTINGS.prompt, "detailed sci-fi hover bike with exposed turbines and glowing panels")),
	Enum.Font.Code
)
ui.promptBox.MultiLine = true
ui.promptBox.TextWrapped = true
ui.promptBox.LayoutOrder = 15
ui.promptBox.Parent = root

do
	local detailTitle = createSectionTitle("Detail Level")
	detailTitle.LayoutOrder = 1
	detailTitle.Parent = root
end

ui.presetFrame = Instance.new("Frame")
ui.presetFrame.Size = UDim2.new(1, 0, 0, 80)
ui.presetFrame.BackgroundTransparency = 1
ui.presetFrame.LayoutOrder = 2
ui.presetFrame.Parent = root

ui.presetLayout = Instance.new("UIGridLayout")
ui.presetLayout.CellPadding = UDim2.new(0, 8, 0, 8)
ui.presetLayout.CellSize = UDim2.new(0.5, -4, 0, 36)
ui.presetLayout.Parent = ui.presetFrame

ui.mediumButton = createButton("Medium", Color3.fromRGB(90, 110, 140), "secondary")
ui.mediumButton.Parent = ui.presetFrame

ui.highButton = createButton("High", Color3.fromRGB(48, 143, 99), "success")
ui.highButton.Parent = ui.presetFrame

ui.ultraButton = createButton("Ultra", Color3.fromRGB(196, 73, 96), "danger")
ui.ultraButton.Parent = ui.presetFrame

themeUi.title = createSectionTitle("UI Theme")
themeUi.title.LayoutOrder = 3
themeUi.title.Parent = root

themeUi.selectorFrame = Instance.new("Frame")
themeUi.selectorFrame.Size = UDim2.new(1, 0, 0, 0)
themeUi.selectorFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
themeUi.selectorFrame.BorderSizePixel = 0
themeUi.selectorFrame.AutomaticSize = Enum.AutomaticSize.Y
themeUi.selectorFrame.LayoutOrder = 4
themeUi.selectorFrame.Parent = root
styleCard(themeUi.selectorFrame, Color3.fromRGB(52, 64, 87), Color3.fromRGB(34, 43, 60), Color3.fromRGB(111, 139, 180), false)

local themeSelectorPadding = Instance.new("UIPadding")
themeSelectorPadding.PaddingTop = UDim.new(0, 10)
themeSelectorPadding.PaddingBottom = UDim.new(0, 10)
themeSelectorPadding.PaddingLeft = UDim.new(0, 10)
themeSelectorPadding.PaddingRight = UDim.new(0, 10)
themeSelectorPadding.Parent = themeUi.selectorFrame

local themeSelectorLayout = Instance.new("UIListLayout")
themeSelectorLayout.Padding = UDim.new(0, 8)
themeSelectorLayout.FillDirection = Enum.FillDirection.Vertical
themeSelectorLayout.SortOrder = Enum.SortOrder.LayoutOrder
themeSelectorLayout.Parent = themeUi.selectorFrame

themeUi.helperLabel = createLabel(
	"UI Theme only changes the plugin interface. It does not affect the generated model style.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(171, 183, 199),
	24
)
enableAutoHeightLabel(themeUi.helperLabel, 24)
themeUi.helperLabel.LayoutOrder = 1
themeUi.helperLabel.Parent = themeUi.selectorFrame

themeUi.currentThemeLabel = createLabel("", 13, Enum.Font.GothamBold, Color3.fromRGB(235, 240, 248), 22)
enableAutoHeightLabel(themeUi.currentThemeLabel, 22)
themeUi.currentThemeLabel.LayoutOrder = 2
themeUi.currentThemeLabel.Parent = themeUi.selectorFrame

themeUi.categoryLabel = createLabel("", 11, Enum.Font.Gotham, Color3.fromRGB(157, 168, 183), 20)
enableAutoHeightLabel(themeUi.categoryLabel, 20)
themeUi.categoryLabel.LayoutOrder = 3
themeUi.categoryLabel.Parent = themeUi.selectorFrame

themeUi.controlsRow = Instance.new("Frame")
themeUi.controlsRow.Size = UDim2.new(1, 0, 0, 72)
themeUi.controlsRow.BackgroundTransparency = 1
themeUi.controlsRow.LayoutOrder = 4
themeUi.controlsRow.Parent = themeUi.selectorFrame

themeUi.dropdownButton = createButton("Browse UI Themes", Color3.fromRGB(67, 126, 141), "accent")
themeUi.dropdownButton.Size = UDim2.new(0.82, -4, 1, 0)
themeUi.dropdownButton.Parent = themeUi.controlsRow

themeUi.utilityButtonsFrame = Instance.new("Frame")
themeUi.utilityButtonsFrame.Size = UDim2.new(0.18, -4, 1, 0)
themeUi.utilityButtonsFrame.Position = UDim2.new(0.82, 8, 0, 0)
themeUi.utilityButtonsFrame.BackgroundTransparency = 1
themeUi.utilityButtonsFrame.Parent = themeUi.controlsRow

local themeUtilityLayout = Instance.new("UIListLayout")
themeUtilityLayout.Padding = UDim.new(0, 4)
themeUtilityLayout.FillDirection = Enum.FillDirection.Vertical
themeUtilityLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
themeUtilityLayout.VerticalAlignment = Enum.VerticalAlignment.Top
themeUtilityLayout.Parent = themeUi.utilityButtonsFrame

ui.guideButton = createButton("?", Color3.fromRGB(84, 107, 146), "info")
ui.guideButton.Size = UDim2.new(1, 0, 0, 34)
ui.guideButton.TextSize = 18
ui.guideButton.Parent = themeUi.utilityButtonsFrame

ui.settingsButton = createButton("⚙", Color3.fromRGB(123, 101, 72), "warning")
ui.settingsButton.Size = UDim2.new(1, 0, 0, 34)
ui.settingsButton.TextSize = 16
ui.settingsButton.Parent = themeUi.utilityButtonsFrame

themeUi.optionsFrame = Instance.new("Frame")
themeUi.optionsFrame.Size = UDim2.new(1, 0, 0, 244)
themeUi.optionsFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
themeUi.optionsFrame.BorderSizePixel = 0
themeUi.optionsFrame.Visible = false
themeUi.optionsFrame.LayoutOrder = 5
themeUi.optionsFrame.Parent = themeUi.selectorFrame
styleCard(themeUi.optionsFrame, Color3.fromRGB(52, 64, 87), Color3.fromRGB(34, 43, 60), Color3.fromRGB(111, 139, 180), false)

local settingsRoot = Instance.new("ScrollingFrame")
settingsRoot.Size = UDim2.fromScale(1, 1)
settingsRoot.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
settingsRoot.BorderSizePixel = 0
settingsRoot.AutomaticCanvasSize = Enum.AutomaticSize.Y
settingsRoot.CanvasSize = UDim2.new()
settingsRoot.ScrollBarThickness = 6
settingsRoot.Parent = settingsWidget
ui.settingsRoot = settingsRoot
addVerticalGradient(settingsRoot, Color3.fromRGB(42, 52, 72), Color3.fromRGB(24, 31, 44))
table.insert(themeRegistry.roots, {instance = settingsRoot})

local settingsRootPadding = Instance.new("UIPadding")
settingsRootPadding.PaddingTop = UDim.new(0, 12)
settingsRootPadding.PaddingBottom = UDim.new(0, 12)
settingsRootPadding.PaddingLeft = UDim.new(0, 12)
settingsRootPadding.PaddingRight = UDim.new(0, 12)
settingsRootPadding.Parent = settingsRoot

local settingsRootLayout = Instance.new("UIListLayout")
settingsRootLayout.Padding = UDim.new(0, 10)
settingsRootLayout.FillDirection = Enum.FillDirection.Vertical
settingsRootLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsRootLayout.Parent = settingsRoot

local guideRoot = Instance.new("ScrollingFrame")
guideRoot.Size = UDim2.fromScale(1, 1)
guideRoot.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
guideRoot.BorderSizePixel = 0
guideRoot.AutomaticCanvasSize = Enum.AutomaticSize.Y
guideRoot.CanvasSize = UDim2.new()
guideRoot.ScrollBarThickness = 6
guideRoot.Parent = guideWidget
addVerticalGradient(guideRoot, Color3.fromRGB(42, 52, 72), Color3.fromRGB(24, 31, 44))
table.insert(themeRegistry.roots, {instance = guideRoot})

local guideRootPadding = Instance.new("UIPadding")
guideRootPadding.PaddingTop = UDim.new(0, 12)
guideRootPadding.PaddingBottom = UDim.new(0, 12)
guideRootPadding.PaddingLeft = UDim.new(0, 12)
guideRootPadding.PaddingRight = UDim.new(0, 12)
guideRootPadding.Parent = guideRoot

local guideRootLayout = Instance.new("UIListLayout")
guideRootLayout.Padding = UDim.new(0, 10)
guideRootLayout.FillDirection = Enum.FillDirection.Vertical
guideRootLayout.SortOrder = Enum.SortOrder.LayoutOrder
guideRootLayout.Parent = guideRoot

local settingsPanelTitle = createLabel("Plugin Settings", 18, Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), 24)
settingsPanelTitle.Parent = settingsRoot

local settingsPanelSubtitle = createLabel(
	"Search, review, and adjust plugin behavior and experimental controls in one place.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(171, 183, 199),
	24
)
enableAutoHeightLabel(settingsPanelSubtitle, 24)
settingsPanelSubtitle.Parent = settingsRoot

local guidePanelTitle = createLabel("Guidebook", 18, Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), 24)
guidePanelTitle.Parent = guideRoot

local guidePanelSubtitle = createLabel(
	"Use this as the in-plugin walkthrough for building a model from prompt to final stored asset.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(171, 183, 199),
	24
)
enableAutoHeightLabel(guidePanelSubtitle, 24)
guidePanelSubtitle.Parent = guideRoot

do
	local function createGuideCard(topColor, bottomColor, strokeColor)
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 0)
		card.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
		card.BorderSizePixel = 0
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.Parent = guideRoot
		styleCard(card, topColor, bottomColor, strokeColor, false)

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 10)
		padding.PaddingBottom = UDim.new(0, 10)
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.Parent = card

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.Parent = card
		return card
	end

	local function addBadge(parent, text, color, role)
		local badge = createButton(text, color, role)
		badge.AutoButtonColor = false
		badge.Active = false
		badge.Selectable = false
		badge.Size = UDim2.new(0, math.max(76, #text * 7 + 24), 0, 28)
		badge.TextSize = 11
		badge.Parent = parent
		return badge
	end

	local function addGuideHero()
		local hero = createGuideCard(Color3.fromRGB(75, 114, 96), Color3.fromRGB(31, 53, 45), Color3.fromRGB(134, 201, 168))

		local title = createLabel("Visual Workflow", 18, Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), 24)
		enableAutoHeightLabel(title, 24)
		title.Parent = hero

		local subtitle = createLabel(
			"Read the plugin left-to-right as a production lane: shape the request, inspect it, then commit the version you want to keep.",
			12,
			Enum.Font.Gotham,
			Color3.fromRGB(209, 226, 217),
			24
		)
		enableAutoHeightLabel(subtitle, 24)
		subtitle.Parent = hero

		local flowRow = Instance.new("Frame")
		flowRow.Size = UDim2.new(1, 0, 0, 0)
		flowRow.BackgroundTransparency = 1
		flowRow.AutomaticSize = Enum.AutomaticSize.Y
		flowRow.Parent = hero

		local flowLayout = Instance.new("UIListLayout")
		flowLayout.Padding = UDim.new(0, 6)
		flowLayout.FillDirection = Enum.FillDirection.Vertical
		flowLayout.Parent = flowRow

		local steps = {
			{"step_prompt", "1", "Preset + Prompt", "Choose detail level, then describe the object clearly."},
			{"step_inputs", "2", "Tune Inputs", "Size, triangles, textures, schema, collider mode, seed."},
			{"step_preview", "3", "Preview", "Check silhouette, scale, bounds, lighting, and collision."},
			{"step_generate", "4", "Generate", "Run the full-quality version once the preview direction is right."},
			{"step_store", "5", "Store", "Keep only the versions you want available in play mode."},
		}

		for _, step in ipairs(steps) do
			local stepCard = Instance.new("Frame")
			stepCard.Size = UDim2.new(1, 0, 0, 0)
			stepCard.BackgroundColor3 = Color3.fromRGB(25, 45, 37)
			stepCard.BorderSizePixel = 0
			stepCard.AutomaticSize = Enum.AutomaticSize.Y
			stepCard.Parent = flowRow
			styleCard(stepCard, Color3.fromRGB(54, 85, 71), Color3.fromRGB(28, 47, 39), Color3.fromRGB(117, 182, 152), false)

			local stepPadding = Instance.new("UIPadding")
			stepPadding.PaddingTop = UDim.new(0, 8)
			stepPadding.PaddingBottom = UDim.new(0, 8)
			stepPadding.PaddingLeft = UDim.new(0, 8)
			stepPadding.PaddingRight = UDim.new(0, 8)
			stepPadding.Parent = stepCard

			local stepLayout = Instance.new("UIListLayout")
			stepLayout.Padding = UDim.new(0, 4)
			stepLayout.FillDirection = Enum.FillDirection.Vertical
			stepLayout.Parent = stepCard

			local headerRow = Instance.new("Frame")
			headerRow.Size = UDim2.new(1, 0, 0, 28)
			headerRow.BackgroundTransparency = 1
			headerRow.Parent = stepCard

			local stepBadge = addBadge(headerRow, "STEP " .. step[2], Color3.fromRGB(62, 162, 109), "success")
			stepBadge.Position = UDim2.new(0, 0, 0, 0)
			stepBadge.Active = true
			stepBadge.Selectable = true
			stepBadge.AutoButtonColor = true
			ui.guideStepButtons[step[1]] = stepBadge

			local stepTitle = createLabel(step[3], 14, Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), 22)
			stepTitle.Size = UDim2.new(1, -110, 0, 22)
			stepTitle.Position = UDim2.new(0, 100, 0, 2)
			stepTitle.Parent = headerRow

			local body = createLabel(step[4], 12, Enum.Font.Gotham, Color3.fromRGB(202, 220, 210), 22)
			enableAutoHeightLabel(body, 22)
			body.Parent = stepCard
		end
	end

	local function addGuideFeature(title, accentColor, role, summary, items)
		local card = createGuideCard(
			accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.16),
			accentColor:Lerp(Color3.fromRGB(18, 22, 28), 0.72),
			accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.22)
		)

		local headerRow = Instance.new("Frame")
		headerRow.Size = UDim2.new(1, 0, 0, 30)
		headerRow.BackgroundTransparency = 1
		headerRow.Parent = card

		local badge = addBadge(headerRow, title, accentColor, role)
		badge.Position = UDim2.new(0, 0, 0, 0)

		local summaryLabel = createLabel(summary, 12, Enum.Font.Gotham, Color3.fromRGB(216, 223, 232), 24)
		enableAutoHeightLabel(summaryLabel, 24)
		summaryLabel.Parent = card

		local itemList = Instance.new("Frame")
		itemList.Size = UDim2.new(1, 0, 0, 0)
		itemList.BackgroundTransparency = 1
		itemList.AutomaticSize = Enum.AutomaticSize.Y
		itemList.Parent = card

		local itemLayout = Instance.new("UIListLayout")
		itemLayout.Padding = UDim.new(0, 6)
		itemLayout.FillDirection = Enum.FillDirection.Vertical
		itemLayout.Parent = itemList

		for _, item in ipairs(items) do
			local itemRow = Instance.new("Frame")
			itemRow.Size = UDim2.new(1, 0, 0, 0)
			itemRow.BackgroundColor3 = Color3.fromRGB(23, 28, 36)
			itemRow.BorderSizePixel = 0
			itemRow.AutomaticSize = Enum.AutomaticSize.Y
			itemRow.Parent = itemList
			styleCard(itemRow, Color3.fromRGB(48, 56, 70), Color3.fromRGB(27, 32, 40), Color3.fromRGB(90, 104, 128), false)

			local itemPadding = Instance.new("UIPadding")
			itemPadding.PaddingTop = UDim.new(0, 8)
			itemPadding.PaddingBottom = UDim.new(0, 8)
			itemPadding.PaddingLeft = UDim.new(0, 8)
			itemPadding.PaddingRight = UDim.new(0, 8)
			itemPadding.Parent = itemRow

			local itemRowLayout = Instance.new("UIListLayout")
			itemRowLayout.Padding = UDim.new(0, 4)
			itemRowLayout.FillDirection = Enum.FillDirection.Vertical
			itemRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
			itemRowLayout.Parent = itemRow

			local nameLabel = createLabel(item[1], 13, Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), 20)
			enableAutoHeightLabel(nameLabel, 20)
			nameLabel.LayoutOrder = 1
			nameLabel.Parent = itemRow

			local descLabel = createLabel(item[2], 12, Enum.Font.Gotham, Color3.fromRGB(177, 188, 203), 22)
			enableAutoHeightLabel(descLabel, 22)
			descLabel.LayoutOrder = 2
			descLabel.Parent = itemRow
		end
	end

	local function addGuideTipStrip()
		local strip = createGuideCard(Color3.fromRGB(107, 86, 54), Color3.fromRGB(53, 38, 23), Color3.fromRGB(201, 160, 98))

		local title = createLabel("Fast Fixes", 16, Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), 22)
		enableAutoHeightLabel(title, 22)
		title.Parent = strip

		local tips = {
			"If shape is wrong: describe silhouette earlier in the prompt.",
			"If output is noisy: lower complexity, shorten the brief, or raise prompt clarity.",
			"If unwanted parts appear: use Negative Prompt and keep the seed fixed.",
			"If the model feels too generic: specify materials, era, function, and wear.",
		}

		for _, tip in ipairs(tips) do
			local tipRow = createLabel("• " .. tip, 12, Enum.Font.Gotham, Color3.fromRGB(231, 217, 193), 20)
			enableAutoHeightLabel(tipRow, 20)
			tipRow.Parent = strip
		end
	end

	local function addGuideImportantNotice()
		local notice = createGuideCard(Color3.fromRGB(133, 74, 62), Color3.fromRGB(58, 29, 24), Color3.fromRGB(224, 129, 112))

		local badgeRow = Instance.new("Frame")
		badgeRow.Size = UDim2.new(1, 0, 0, 30)
		badgeRow.BackgroundTransparency = 1
		badgeRow.Parent = notice

		local badge = addBadge(badgeRow, "IMPORTANT", Color3.fromRGB(176, 98, 94), "danger")
		badge.Position = UDim2.new(0, 0, 0, 0)

		local title = createLabel("Textures and Collision After Generation", 16, Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), 22)
		enableAutoHeightLabel(title, 22)
		title.Parent = notice

		local body = createLabel(
			"Because the mesh is generated first and texture application happens later when the stored asset is loaded into a live server, you should do one manual collision pass before storing the model. After generation, open the generated MeshPart or mesh-based parts, set CollisionFidelity to Precise, and only then store the model back into ServerStorage. If you skip this step, the live server may use the wrong collision shape even if the rendered model looks correct.",
			12,
			Enum.Font.Gotham,
			Color3.fromRGB(239, 211, 205),
			32
		)
		enableAutoHeightLabel(body, 32)
		body.Parent = notice

		local stepsTitle = createLabel("Recommended sequence", 13, Enum.Font.GothamBold, Color3.fromRGB(255, 231, 226), 20)
		enableAutoHeightLabel(stepsTitle, 20)
		stepsTitle.Parent = notice

		local steps = {
			"1. Generate the model.",
			"2. Inspect the generated mesh parts in Studio.",
			"3. Set CollisionFidelity to Precise on the generated mesh parts.",
			"4. Store the model only after that manual collision update is done.",
		}

		for _, stepText in ipairs(steps) do
			local stepLabel = createLabel(stepText, 12, Enum.Font.Gotham, Color3.fromRGB(239, 211, 205), 20)
			enableAutoHeightLabel(stepLabel, 20)
			stepLabel.Parent = notice
		end
	end

	addGuideHero()
	addGuideImportantNotice()
	addGuideFeature(
		"Main Canvas",
		Color3.fromRGB(79, 133, 177),
		"info",
		"These are the controls you touch most while shaping a request.",
		{
			{"Prompt Box", "Write the object first, then materials, style, silhouette, and standout details."},
			{"Detail Presets", "Medium is safest for exploration, High is a balanced default, Ultra pushes density harder."},
			{"Size + Triangles", "Use size for overall scale and triangles for complexity ceiling."},
			{"Textures / Base / Anchored", "These switches control extra surface richness, whether a base is included, and whether output stays fixed in place."},
		}
	)
	addGuideFeature(
		"Generation Controls",
		Color3.fromRGB(62, 162, 109),
		"success",
		"Think of these as the request launch buttons and repeatability controls.",
		{
			{"Schema", "Defines the Roblox generation schema name used in the request."},
			{"Collider Mode", "Decides how collision proxies are generated for the result."},
			{"Seed", "Reuse a seed to stay near a previous look or leave it blank for a fresh variation."},
			{"Preview vs Generate", "Preview is for inspection; Generate is for the full version you intend to keep."},
		}
	)
	addGuideFeature(
		"Preview Window",
		Color3.fromRGB(126, 84, 148),
		"purple",
		"Use the preview panel like a turntable and validation station before you commit.",
		{
			{"Camera Controls", "Rotate, zoom, reset, and switch between front, side, top, and isometric views."},
			{"Look Dev", "Swap lighting and background presets to check readability under different conditions."},
			{"Validation Overlays", "Toggle origin marker, bounds overlay, and collision opacity to inspect technical fit."},
			{"Auto Rotate", "Useful for catching awkward silhouettes or collision shapes from multiple angles."},
		}
	)
	addGuideFeature(
		"Storage + Settings",
		Color3.fromRGB(201, 141, 78),
		"warning",
		"These controls manage what gets kept and how the plugin behaves over time.",
		{
			{"Store Selected / Store All", "Only store the versions you actually want available during play mode."},
			{"Show Stored Models", "Review what has already been saved back to runtime storage."},
			{"Settings Gear", "Open cache, behavior, collision tuning, theme styling, and experimental options."},
			{"Question Mark Guide", "Open this panel whenever you want a quick UI refresher instead of reading raw settings text."},
		}
	)
	addGuideTipStrip()
end

ui.settingsPanel = Instance.new("Frame")
ui.settingsPanel.Size = UDim2.new(1, 0, 0, 0)
ui.settingsPanel.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
ui.settingsPanel.BorderSizePixel = 0
ui.settingsPanel.AutomaticSize = Enum.AutomaticSize.Y
ui.settingsPanel.Parent = settingsRoot
styleCard(ui.settingsPanel, Color3.fromRGB(52, 64, 87), Color3.fromRGB(34, 43, 60), Color3.fromRGB(111, 139, 180), false)

do
	local settingsPanelPadding = Instance.new("UIPadding")
	settingsPanelPadding.PaddingTop = UDim.new(0, 8)
	settingsPanelPadding.PaddingBottom = UDim.new(0, 8)
	settingsPanelPadding.PaddingLeft = UDim.new(0, 8)
	settingsPanelPadding.PaddingRight = UDim.new(0, 8)
	settingsPanelPadding.Parent = ui.settingsPanel

	local settingsPanelLayout = Instance.new("UIListLayout")
	settingsPanelLayout.Padding = UDim.new(0, 8)
	settingsPanelLayout.FillDirection = Enum.FillDirection.Vertical
	settingsPanelLayout.Parent = ui.settingsPanel
end

ui.settingsSearchBox = createSmallBox("Search settings or experiments", "")
local settingsSearchGroup, settingsSearchTitle, settingsSearchHelp = createSettingsGroup(
	"Search Settings",
	"Type a setting name, behavior, or experimental feature to filter the panel below."
)
settingsSearchGroup.LayoutOrder = 1
registerSettingsSection("search", settingsSearchTitle, "search settings experiments filter find locate", settingsSearchHelp)
ui.settingsSearchSections.search.container = settingsSearchGroup
ui.settingsSearchBox.Parent = settingsSearchGroup

ui.settingsSearchResultsFrame = Instance.new("Frame")
ui.settingsSearchResultsFrame.Size = UDim2.new(1, 0, 0, 0)
ui.settingsSearchResultsFrame.BackgroundTransparency = 1
ui.settingsSearchResultsFrame.AutomaticSize = Enum.AutomaticSize.Y
ui.settingsSearchResultsFrame.Visible = false
ui.settingsSearchResultsFrame.Parent = settingsSearchGroup

local settingsSearchResultsLayout = Instance.new("UIListLayout")
settingsSearchResultsLayout.Padding = UDim.new(0, 6)
settingsSearchResultsLayout.FillDirection = Enum.FillDirection.Vertical
settingsSearchResultsLayout.Parent = ui.settingsSearchResultsFrame

ui.settingsSearchResultButtons = {}
for _ = 1, 6 do
	local resultButton = createButton("", Color3.fromRGB(67, 126, 141), "accent")
	resultButton.Size = UDim2.new(1, 0, 0, 34)
	resultButton.Visible = false
	resultButton.Parent = ui.settingsSearchResultsFrame
	table.insert(ui.settingsSearchResultButtons, resultButton)
end

ui.settingsSearchEmptyLabel = createLabel(
	"No matching setting shortcuts found.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(157, 168, 183),
	20
)
enableAutoHeightLabel(ui.settingsSearchEmptyLabel, 20)
ui.settingsSearchEmptyLabel.Visible = false
ui.settingsSearchEmptyLabel.Parent = settingsSearchGroup

local settingsGroup, settingsSectionTitle, settingsSectionHelp = createSettingsGroup(
	"Settings",
	"Core plugin behavior, cache, preview defaults, and prompt history tools."
)
settingsGroup.LayoutOrder = 2
registerSettingsSection("settings", settingsSectionTitle, "settings cache behavior preview history core options", settingsSectionHelp)
ui.settingsSearchSections.settings.container = settingsGroup
ui.activeSettingsGroup = settingsGroup

local cacheTitle = createSectionTitle("Generation Cache")
cacheTitle.Size = UDim2.new(1, 0, 0, 18)
cacheTitle.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(cacheTitle, "generation cache cached models preview generate reuse", "settings")

local cacheToggleTitle, cacheToggleHelp = createSettingsItem(
	"Reuse Cached Results",
	"Reuses identical preview and generate requests so repeated runs can open faster."
)
registerSettingsSearchEntry(cacheToggleTitle, "reuse cached results cache enable disable generation preview", "settings")
registerSettingsSearchEntry(cacheToggleHelp, "reuse cached results cache enable disable generation preview", "settings")

ui.cacheToggleButton = createButton("Cache: Off", Color3.fromRGB(86, 99, 125), "muted")
ui.cacheToggleButton.Size = UDim2.new(1, 0, 0, 34)
ui.cacheToggleButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(ui.cacheToggleButton, "cache enable disable cached models generation cache", "settings", true)
registerSettingsShortcut("Reuse Cached Results", ui.cacheToggleButton, "cache reuse cached results enable disable generation preview", "settings")

local clearCacheTitle, clearCacheHelp = createSettingsItem(
	"Clear Cached Results",
	"Deletes saved preview and generation cache entries so future runs are rebuilt from scratch."
)
registerSettingsSearchEntry(clearCacheTitle, "clear cached results cache delete reset", "settings")
registerSettingsSearchEntry(clearCacheHelp, "clear cached results cache delete reset", "settings")

ui.clearCacheButton = createButton("Clear Cached Models", Color3.fromRGB(156, 111, 62), "warning")
ui.clearCacheButton.Size = UDim2.new(1, 0, 0, 34)
ui.clearCacheButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(ui.clearCacheButton, "clear cached models cache delete cached previews", "settings", true)
registerSettingsShortcut("Clear Cached Results", ui.clearCacheButton, "clear cache cached models delete cached previews reset", "settings")

do
	local cacheHelp = createLabel(
		"Reuses identical preview/generate requests so repeated runs can skip Roblox generation. First-time requests are unchanged.",
		12,
		Enum.Font.Gotham,
		Color3.fromRGB(157, 168, 183),
		40
	)
	enableAutoHeightLabel(cacheHelp, 24)
	cacheHelp.Parent = ui.activeSettingsGroup
	registerSettingsSearchEntry(cacheHelp, "cache help reuses identical preview generate requests", "settings")

	local behaviorTitle = createSectionTitle("Behavior")
	behaviorTitle.Size = UDim2.new(1, 0, 0, 18)
	behaviorTitle.Parent = ui.activeSettingsGroup
	registerSettingsSearchEntry(behaviorTitle, "behavior preview advanced collision confirmation", "settings")
end

local autoPreviewTitle, autoPreviewHelp = createSettingsItem(
	"Open Preview After Generate",
	"Automatically opens the preview panel after a full model generation finishes."
)
registerSettingsSearchEntry(autoPreviewTitle, "auto open preview after generate preview panel", "settings")
registerSettingsSearchEntry(autoPreviewHelp, "auto open preview after generate preview panel", "settings")

ui.autoOpenPreviewButton = createButton("Auto-open Preview: Off", Color3.fromRGB(86, 99, 125), "muted")
ui.autoOpenPreviewButton.Size = UDim2.new(1, 0, 0, 34)
ui.autoOpenPreviewButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(ui.autoOpenPreviewButton, "auto open preview preview window behavior", "settings", true)
registerSettingsShortcut("Open Preview After Generate", ui.autoOpenPreviewButton, "auto open preview after generate preview panel", "settings")

local advancedCollisionTitle, advancedCollisionHelp = createSettingsItem(
	"Show Advanced Collision Tuning",
	"Shows the extra collision heuristic inputs in the main panel for fine-tuning collider behavior."
)
registerSettingsSearchEntry(advancedCollisionTitle, "show advanced collision tuning heuristics collider inputs", "settings")
registerSettingsSearchEntry(advancedCollisionHelp, "show advanced collision tuning heuristics collider inputs", "settings")

ui.showAdvancedCollisionButton = createButton("Advanced Collision Tuning: Off", Color3.fromRGB(86, 99, 125), "muted")
ui.showAdvancedCollisionButton.Size = UDim2.new(1, 0, 0, 34)
ui.showAdvancedCollisionButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(ui.showAdvancedCollisionButton, "advanced collision tuning heuristics collider settings", "settings", true)
registerSettingsShortcut("Show Advanced Collision Tuning", ui.showAdvancedCollisionButton, "advanced collision tuning heuristics collider settings", "settings")

local confirmStoreAllTitle, confirmStoreAllHelp = createSettingsItem(
	"Require Confirmation for Store All",
	"Adds a safety confirmation before storing every generated model back into runtime storage."
)
registerSettingsSearchEntry(confirmStoreAllTitle, "require confirmation store all models safety", "settings")
registerSettingsSearchEntry(confirmStoreAllHelp, "require confirmation store all models safety", "settings")

ui.confirmStoreAllButton = createButton("Confirm Store All: Off", Color3.fromRGB(86, 99, 125), "muted")
ui.confirmStoreAllButton.Size = UDim2.new(1, 0, 0, 34)
ui.confirmStoreAllButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(ui.confirmStoreAllButton, "confirm store all models safety behavior", "settings", true)
registerSettingsShortcut("Require Confirmation for Store All", ui.confirmStoreAllButton, "confirm store all models safety behavior", "settings")

do
	local historyTitle = createSectionTitle("Recent Prompts")
	historyTitle.Size = UDim2.new(1, 0, 0, 18)
	historyTitle.Parent = ui.activeSettingsGroup
	registerSettingsSearchEntry(historyTitle, "recent prompts history prompt recall", "settings")
end

local historyLogTitle, historyLogHelp = createSettingsItem(
	"Prompt History Log",
	"Shows your most recent prompts in a console-style log for quick reference."
)
registerSettingsSearchEntry(historyLogTitle, "prompt history log recent prompts console", "settings")
registerSettingsSearchEntry(historyLogHelp, "prompt history log recent prompts console", "settings")

ui.historyLogBox = createTextBox(
	120,
	"Recent prompts will appear here",
	"",
	Enum.Font.Code
)
ui.historyLogBox.MultiLine = true
ui.historyLogBox.TextWrapped = true
ui.historyLogBox.TextEditable = false
ui.historyLogBox.ClearTextOnFocus = false
ui.historyLogBox.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(ui.historyLogBox, "prompt history log recent prompts console", "settings", true)
registerSettingsShortcut("Prompt History Log", ui.historyLogBox, "prompt history log recent prompts console", "settings")

local themeStyleGroup, themeStyleTitle, themeStyleHelp = createSettingsGroup(
	"Theme Styling Lab",
	"Push the selected UI theme into softer, louder, warmer, cooler, or different typography directions without switching the base preset."
)
themeStyleGroup.LayoutOrder = 3
registerSettingsSection("theme_style", themeStyleTitle, "theme style styling lab ui preset variant tone contrast typography fonts", themeStyleHelp)
ui.settingsSearchSections.theme_style.container = themeStyleGroup
ui.activeSettingsGroup = themeStyleGroup

local themeVariantTitle, themeVariantHelp = createSettingsItem(
	"Theme Variant",
	"Cycles structural styling presets that soften, intensify, or desaturate the selected base theme."
)
registerSettingsSearchEntry(themeVariantTitle, "theme variant default soft vivid noir structural styling", "theme_style")
registerSettingsSearchEntry(themeVariantHelp, "theme variant default soft vivid noir structural styling", "theme_style")

themeUi.variantButton = createButton("Theme Variant: Default", Color3.fromRGB(90, 110, 140), "secondary")
themeUi.variantButton.Size = UDim2.new(1, 0, 0, 34)
themeUi.variantButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(themeUi.variantButton, "theme variant default soft vivid noir structural styling", "theme_style", true)
registerSettingsShortcut("Theme Variant", themeUi.variantButton, "theme variant default soft vivid noir structural styling", "theme_style")

local themeToneTitle, themeToneHelp = createSettingsItem(
	"Theme Tone",
	"Applies a global color bias to the current UI theme for cooler, warmer, greener, or neon-leaning palettes."
)
registerSettingsSearchEntry(themeToneTitle, "theme tone cool warm verdant neon color bias palette", "theme_style")
registerSettingsSearchEntry(themeToneHelp, "theme tone cool warm verdant neon color bias palette", "theme_style")

themeUi.toneButton = createButton("Theme Tone: Default", Color3.fromRGB(67, 126, 141), "accent")
themeUi.toneButton.Size = UDim2.new(1, 0, 0, 34)
themeUi.toneButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(themeUi.toneButton, "theme tone cool warm verdant neon color bias palette", "theme_style", true)
registerSettingsShortcut("Theme Tone", themeUi.toneButton, "theme tone cool warm verdant neon color bias palette", "theme_style")

local themeContrastTitle, themeContrastHelp = createSettingsItem(
	"Theme Contrast",
	"Adjusts how calm or punchy the interface separation feels without changing the active base theme."
)
registerSettingsSearchEntry(themeContrastTitle, "theme contrast soft balanced punchy calm strong separation", "theme_style")
registerSettingsSearchEntry(themeContrastHelp, "theme contrast soft balanced punchy calm strong separation", "theme_style")

themeUi.contrastButton = createButton("Theme Contrast: Balanced", Color3.fromRGB(84, 107, 146), "info")
themeUi.contrastButton.Size = UDim2.new(1, 0, 0, 34)
themeUi.contrastButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(themeUi.contrastButton, "theme contrast soft balanced punchy calm strong separation", "theme_style", true)
registerSettingsShortcut("Theme Contrast", themeUi.contrastButton, "theme contrast soft balanced punchy calm strong separation", "theme_style")

local themeTypographyTitle, themeTypographyHelp = createSettingsItem(
	"Theme Typography",
	"Swaps the UI font direction so the same color theme can feel more utilitarian, editorial, arcade, or technical."
)
registerSettingsSearchEntry(themeTypographyTitle, "theme typography fonts studio sans editorial arcade scifi mono", "theme_style")
registerSettingsSearchEntry(themeTypographyHelp, "theme typography fonts studio sans editorial arcade scifi mono", "theme_style")

themeUi.typographyButton = createButton("Theme Typography: Theme Default", Color3.fromRGB(57, 128, 116), "teal")
themeUi.typographyButton.Size = UDim2.new(1, 0, 0, 34)
themeUi.typographyButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(themeUi.typographyButton, "theme typography fonts studio sans editorial arcade scifi mono", "theme_style", true)
registerSettingsShortcut("Theme Typography", themeUi.typographyButton, "theme typography fonts studio sans editorial arcade scifi mono", "theme_style")

themeUi.stylingSummaryLabel = createLabel("", 12, Enum.Font.Gotham, Color3.fromRGB(157, 168, 183), 34)
enableAutoHeightLabel(themeUi.stylingSummaryLabel, 34)
themeUi.stylingSummaryLabel.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(themeUi.stylingSummaryLabel, "theme styling summary variant tone contrast typography current", "theme_style", true)

themeUi.resetStylingButton = createButton("Reset Theme Styling", Color3.fromRGB(123, 101, 72), "warning")
themeUi.resetStylingButton.Size = UDim2.new(1, 0, 0, 34)
themeUi.resetStylingButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(themeUi.resetStylingButton, "reset theme styling variant tone contrast typography", "theme_style", true)
registerSettingsShortcut("Reset Theme Styling", themeUi.resetStylingButton, "reset theme styling variant tone contrast typography", "theme_style")

local experimentalGroup, experimentalTitle, experimentalHelp = createSettingsGroup(
	"Experimental Settings",
	"Active but more volatile controls for stronger prompt steering, faster previews, or alternate placement behavior."
)
experimentalGroup.LayoutOrder = 4
registerSettingsSection("experimental", experimentalTitle, "experimental future ideas upcoming options tests", experimentalHelp)
ui.settingsSearchSections.experimental.container = experimentalGroup
ui.activeSettingsGroup = experimentalGroup

local experimentalNegativePromptTitle = createSectionTitle("Negative Prompt")
experimentalNegativePromptTitle.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(experimentalNegativePromptTitle, "negative prompt exclude avoid blocklist no wheels no damage", "experimental")

local experimentalNegativePromptHelp = createLabel(
	"Add words or phrases you want the generator to avoid. Example: wheels, weapons, broken parts.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(157, 168, 183),
	24
)
enableAutoHeightLabel(experimentalNegativePromptHelp, 24)
experimentalNegativePromptHelp.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(experimentalNegativePromptHelp, "negative prompt avoid excluded blocked words", "experimental")

ui.experimentalNegativePromptBox = createTextBox(
	58,
	"What should the model avoid?",
	tostring(getSetting(SETTINGS.experimentalNegativePrompt, "")),
	Enum.Font.Gotham
)
ui.experimentalNegativePromptBox.TextWrapped = true
ui.experimentalNegativePromptBox.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(ui.experimentalNegativePromptBox, "negative prompt avoid exclude forbidden words phrases", "experimental", true)
registerSettingsShortcut("Negative Prompt", ui.experimentalNegativePromptBox, "negative prompt avoid exclude forbidden words phrases", "experimental")

local styleBiasTitle, styleBiasHelp = createSettingsItem(
	"Style Bias",
	"Cycles through prompt bias modes that push the result toward a more specific overall look."
)
registerSettingsSearchEntry(styleBiasTitle, "style bias realistic stylized hard surface organic toy", "experimental")
registerSettingsSearchEntry(styleBiasHelp, "style bias realistic stylized hard surface organic toy", "experimental")

ui.experimentalStyleBiasButton = createButton("Style Bias: Off", Color3.fromRGB(90, 110, 140), "secondary")
ui.experimentalStyleBiasButton.Size = UDim2.new(1, 0, 0, 34)
ui.experimentalStyleBiasButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(ui.experimentalStyleBiasButton, "style bias realistic stylized hard surface organic toy", "experimental", true)
registerSettingsShortcut("Style Bias", ui.experimentalStyleBiasButton, "style bias realistic stylized hard surface organic toy", "experimental")

local previewModeTitle, previewModeHelp = createSettingsItem(
	"Preview Quality Mode",
	"Controls how aggressive preview simplification is before the final generation step."
)
registerSettingsSearchEntry(previewModeTitle, "preview quality mode fast balanced high quality decimation", "experimental")
registerSettingsSearchEntry(previewModeHelp, "preview quality mode fast balanced high quality decimation", "experimental")

ui.experimentalPreviewModeButton = createButton("Preview Mode: Balanced", Color3.fromRGB(84, 107, 146), "info")
ui.experimentalPreviewModeButton.Size = UDim2.new(1, 0, 0, 34)
ui.experimentalPreviewModeButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(ui.experimentalPreviewModeButton, "preview mode fast balanced high quality decimation preview only", "experimental", true)
registerSettingsShortcut("Preview Quality Mode", ui.experimentalPreviewModeButton, "preview mode fast balanced high quality decimation preview only", "experimental")

local groundSnapTitle, groundSnapHelp = createSettingsItem(
	"Ground Snap at Origin",
	"Places the generated model so its base sits on the ground plane at origin instead of only centering the pivot."
)
registerSettingsSearchEntry(groundSnapTitle, "ground snap origin placement center pivot align ground", "experimental")
registerSettingsSearchEntry(groundSnapHelp, "ground snap origin placement center pivot align ground", "experimental")

ui.experimentalGroundSnapButton = createButton("Ground Snap at Origin: Off", Color3.fromRGB(57, 128, 116), "teal")
ui.experimentalGroundSnapButton.Size = UDim2.new(1, 0, 0, 34)
ui.experimentalGroundSnapButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(ui.experimentalGroundSnapButton, "ground snap origin placement center pivot align ground", "experimental", true)
registerSettingsShortcut("Ground Snap at Origin", ui.experimentalGroundSnapButton, "ground snap origin placement center pivot align ground", "experimental")

ui.activeSettingsGroup = nil

themeUi.optionsPadding = Instance.new("UIPadding")
themeUi.optionsPadding.PaddingTop = UDim.new(0, 8)
themeUi.optionsPadding.PaddingBottom = UDim.new(0, 8)
themeUi.optionsPadding.PaddingLeft = UDim.new(0, 8)
themeUi.optionsPadding.PaddingRight = UDim.new(0, 8)
themeUi.optionsPadding.Parent = themeUi.optionsFrame

themeUi.searchBox = createSmallBox("Search UI themes", "")
themeUi.searchBox.Parent = themeUi.optionsFrame

themeUi.optionsScroll = Instance.new("ScrollingFrame")
themeUi.optionsScroll.Size = UDim2.new(1, 0, 0, 180)
themeUi.optionsScroll.Position = UDim2.new(0, 0, 0, 48)
themeUi.optionsScroll.BackgroundTransparency = 1
themeUi.optionsScroll.BorderSizePixel = 0
themeUi.optionsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
themeUi.optionsScroll.CanvasSize = UDim2.new()
themeUi.optionsScroll.ScrollBarThickness = 6
themeUi.optionsScroll.Parent = themeUi.optionsFrame

themeUi.optionsLayout = Instance.new("UIListLayout")
themeUi.optionsLayout.Padding = UDim.new(0, 6)
themeUi.optionsLayout.FillDirection = Enum.FillDirection.Vertical
themeUi.optionsLayout.Parent = themeUi.optionsScroll

themeUi.optionButtons = {}
themeUi.categoryHeaders = {}
themeUi.optionOrder = {}
local categoryBuckets = {}
for _, categoryName in ipairs(THEME_CATEGORY_ORDER) do
	categoryBuckets[categoryName] = {}
end
for themeName in pairs(THEMES) do
	local categoryName = getThemeCategory(themeName)
	if not categoryBuckets[categoryName] then
		categoryBuckets[categoryName] = {}
		table.insert(THEME_CATEGORY_ORDER, categoryName)
	end
	table.insert(categoryBuckets[categoryName], themeName)
end
for _, categoryName in ipairs(THEME_CATEGORY_ORDER) do
	local bucket = categoryBuckets[categoryName]
	if bucket and #bucket > 0 then
		table.sort(bucket)
		local headerLabel = createSectionTitle(categoryName)
		headerLabel.Parent = themeUi.optionsScroll
		themeUi.categoryHeaders[categoryName] = headerLabel
		table.insert(themeUi.optionOrder, {kind = "header", category = categoryName})
		for _, themeName in ipairs(bucket) do
			local optionButton = createButton(themeName, Color3.fromRGB(90, 110, 140), "secondary")
			optionButton.Parent = themeUi.optionsScroll
			themeUi.optionButtons[themeName] = optionButton
			table.insert(themeUi.optionOrder, {kind = "theme", category = categoryName, name = themeName})
		end
	end
end

do
	local settingsTitle = createSectionTitle("Generation Basics")
	settingsTitle.LayoutOrder = 5
	settingsTitle.Parent = root
end

ui.settingsFrame = Instance.new("Frame")
ui.settingsFrame.Size = UDim2.new(1, 0, 0, 126)
ui.settingsFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
ui.settingsFrame.BorderSizePixel = 0
ui.settingsFrame.LayoutOrder = 6
ui.settingsFrame.Parent = root
styleCard(ui.settingsFrame, Color3.fromRGB(52, 64, 87), Color3.fromRGB(34, 43, 60), Color3.fromRGB(111, 139, 180), false)

do
	local settingsPadding = Instance.new("UIPadding")
	settingsPadding.PaddingTop = UDim.new(0, 10)
	settingsPadding.PaddingBottom = UDim.new(0, 10)
	settingsPadding.PaddingLeft = UDim.new(0, 10)
	settingsPadding.PaddingRight = UDim.new(0, 10)
	settingsPadding.Parent = ui.settingsFrame
end

ui.settingsLayout = Instance.new("UIGridLayout")
ui.settingsLayout.CellPadding = UDim2.new(0, 8, 0, 8)
ui.settingsLayout.CellSize = UDim2.new(0.5, -4, 0, 34)
ui.settingsLayout.Parent = ui.settingsFrame

ui.sizeBox = createSmallBox("Model size in studs (example: 24)", tostring(getSetting(SETTINGS.size, 24)))
ui.sizeBox.Parent = ui.settingsFrame

ui.trianglesBox = createSmallBox("Triangle budget / mesh detail cap", tostring(getSetting(SETTINGS.maxTriangles, 20000)))
ui.trianglesBox.Parent = ui.settingsFrame

ui.texturesToggleButton = createButton("Textures: On", Color3.fromRGB(86, 99, 125), "active")
ui.texturesToggleButton.Parent = ui.settingsFrame

ui.includeBaseToggleButton = createButton("Generated Base: On", Color3.fromRGB(86, 99, 125), "active")
ui.includeBaseToggleButton.Parent = ui.settingsFrame

ui.anchoredToggleButton = createButton("Anchored: On", Color3.fromRGB(86, 99, 125), "active")
ui.anchoredToggleButton.Parent = ui.settingsFrame

local settingsHelp = createLabel(
	"Size controls overall scale. Triangle budget controls surface complexity. Textures adds generated materials. Anchored decides whether the new model is fixed in place.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(157, 168, 183),
	40
)
settingsHelp.LayoutOrder = 7
enableAutoHeightLabel(settingsHelp, 24)
settingsHelp.Parent = root

local colliderModeTitle = createSectionTitle("Collision Setup")
colliderModeTitle.LayoutOrder = 8
colliderModeTitle.Parent = root

ui.colliderModeBox = createSmallBox(
	"Collision mode: ai, simple, medium, or detailed",
	tostring(getSetting(SETTINGS.colliderMode, "ai"))
)
ui.colliderModeBox.LayoutOrder = 9
ui.colliderModeBox.Parent = root

local colliderModeHelp = createLabel(
	"Choose how solid the generated model feels in gameplay. ai chooses automatically, simple uses broad blockers, medium groups nearby shapes, and detailed keeps tighter collision volumes.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(157, 168, 183),
	46
)
colliderModeHelp.LayoutOrder = 10
enableAutoHeightLabel(colliderModeHelp, 24)
colliderModeHelp.Parent = root

local schemaTitle = createSectionTitle("Model Schema")
schemaTitle.LayoutOrder = 11
schemaTitle.Parent = root

ui.schemaBox = createSmallBox("Roblox schema name (default: Body1)", tostring(getSetting(SETTINGS.schema, "Body1")))
ui.schemaBox.LayoutOrder = 12
ui.schemaBox.Parent = root

local schemaHelp = createLabel(
	"Schema tells Roblox what kind of generated structure to target. Leave it as Body1 unless you already know you need a different predefined schema.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(157, 168, 183),
	34
)
schemaHelp.LayoutOrder = 13
enableAutoHeightLabel(schemaHelp, 24)
schemaHelp.Parent = root

local seedTitle = createSectionTitle("Variation Seed")
seedTitle.LayoutOrder = 14
seedTitle.Parent = root

ui.seedFrame = Instance.new("Frame")
ui.seedFrame.Size = UDim2.new(1, 0, 0, 34)
ui.seedFrame.BackgroundTransparency = 1
ui.seedFrame.LayoutOrder = 15
ui.seedFrame.Parent = root

ui.seedBox = createSmallBox("Leave blank for random, or enter text/number to repeat a variation", tostring(getSetting(SETTINGS.seed, "")))
ui.seedBox.Size = UDim2.new(0.68, -4, 1, 0)
ui.seedBox.Parent = ui.seedFrame

ui.randomSeedButton = createButton("Random Seed", Color3.fromRGB(90, 110, 140), "secondary")
ui.randomSeedButton.Size = UDim2.new(0.32, -4, 1, 0)
ui.randomSeedButton.Position = UDim2.new(0.68, 8, 0, 0)
ui.randomSeedButton.Parent = ui.seedFrame

local seedHelp = createLabel(
	"Use the same seed to get a similar variation again. Change or clear it when you want a new result from the same prompt.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(157, 168, 183),
	34
)
seedHelp.LayoutOrder = 16
enableAutoHeightLabel(seedHelp, 24)
seedHelp.Parent = root

ui.tipsLabel = createLabel(
	"Medium is the faster balanced preset, High is the default full-detail mode, and Ultra keeps the 20,000 triangle cap but pushes size and collision detail harder. If one object is selected, the result is inserted there; otherwise it goes to Workspace.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(157, 168, 183),
	34
)
ui.tipsLabel.LayoutOrder = 17
enableAutoHeightLabel(ui.tipsLabel, 24)
ui.tipsLabel.Parent = root

ui.buttonFrame = Instance.new("Frame")
ui.buttonFrame.Size = UDim2.new(1, 0, 0, 88)
ui.buttonFrame.BackgroundTransparency = 1
ui.buttonFrame.LayoutOrder = 18
ui.buttonFrame.Parent = root

ui.buttonLayout = Instance.new("UIGridLayout")
ui.buttonLayout.CellPadding = UDim2.new(0, 8, 0, 8)
ui.buttonLayout.CellSize = UDim2.new(0.333, -6, 0, 34)
ui.buttonLayout.Parent = ui.buttonFrame

ui.previewButton = createButton("Preview", Color3.fromRGB(73, 92, 128), "info")
ui.previewButton.Parent = ui.buttonFrame

ui.generateButton = createButton("Generate", Color3.fromRGB(49, 155, 106), "success")
ui.generateButton.Parent = ui.buttonFrame

ui.runtimeButton = createButton("Store Selected Model", Color3.fromRGB(156, 111, 62), "warning")
ui.runtimeButton.Parent = ui.buttonFrame

ui.runtimeAllButton = createButton("Store All Models", Color3.fromRGB(126, 84, 148), "purple")
ui.runtimeAllButton.Parent = ui.buttonFrame

ui.toggleStorageButton = createButton("Show Stored Models", Color3.fromRGB(67, 126, 141), "accent")
ui.toggleStorageButton.Parent = ui.buttonFrame

ui.guideFocusGroups.step_prompt = {ui.presetFrame, ui.promptBox}
ui.guideFocusGroups.step_inputs = {ui.settingsFrame, ui.colliderModeBox, ui.schemaBox, ui.seedFrame}
ui.guideFocusGroups.step_preview = {ui.previewButton}
ui.guideFocusGroups.step_generate = {ui.generateButton}
ui.guideFocusGroups.step_store = {ui.runtimeButton, ui.runtimeAllButton, ui.toggleStorageButton}

local previewRoot = Instance.new("ScrollingFrame")
previewRoot.Size = UDim2.fromScale(1, 1)
previewRoot.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
previewRoot.BorderSizePixel = 0
previewRoot.AutomaticCanvasSize = Enum.AutomaticSize.Y
previewRoot.CanvasSize = UDim2.new()
previewRoot.ScrollBarThickness = 6
previewRoot.Parent = previewWidget
addVerticalGradient(previewRoot, Color3.fromRGB(43, 53, 73), Color3.fromRGB(24, 31, 44))
table.insert(themeRegistry.roots, {instance = previewRoot})

local previewPadding = Instance.new("UIPadding")
previewPadding.PaddingTop = UDim.new(0, 12)
previewPadding.PaddingBottom = UDim.new(0, 12)
previewPadding.PaddingLeft = UDim.new(0, 12)
previewPadding.PaddingRight = UDim.new(0, 12)
previewPadding.Parent = previewRoot

local previewLayout = Instance.new("UIListLayout")
previewLayout.Padding = UDim.new(0, 10)
previewLayout.FillDirection = Enum.FillDirection.Vertical
previewLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
previewLayout.VerticalAlignment = Enum.VerticalAlignment.Top
previewLayout.SortOrder = Enum.SortOrder.LayoutOrder
previewLayout.Parent = previewRoot

local previewHeader = Instance.new("Frame")
previewHeader.Size = UDim2.new(1, 0, 0, 96)
previewHeader.BackgroundTransparency = 1
previewHeader.LayoutOrder = 1
previewHeader.Parent = previewRoot

local previewTitle = createLabel("Generated Preview", 18, Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), 24)
previewTitle.Size = UDim2.new(1, 0, 0, 24)
previewTitle.Parent = previewHeader

local previewSubtitle = createLabel("Drag to orbit, zoom in or out, or enable auto-rotate.", 12, Enum.Font.Gotham, Color3.fromRGB(161, 173, 191), 22)
previewSubtitle.Position = UDim2.new(0, 0, 0, 28)
enableAutoHeightLabel(previewSubtitle, 22)
previewSubtitle.Parent = previewHeader

ui.closePreviewButton = createButton("Close Preview", Color3.fromRGB(112, 83, 83), "danger")
ui.closePreviewButton.Size = UDim2.new(1, 0, 0, 34)
ui.closePreviewButton.Position = UDim2.new(0, 0, 0, 58)
ui.closePreviewButton.Parent = previewHeader

local previewInfoFrame = Instance.new("Frame")
previewInfoFrame.Size = UDim2.new(1, 0, 0, 0)
previewInfoFrame.BackgroundColor3 = Color3.fromRGB(21, 27, 38)
previewInfoFrame.BorderSizePixel = 0
previewInfoFrame.AutomaticSize = Enum.AutomaticSize.Y
previewInfoFrame.LayoutOrder = 2
previewInfoFrame.Parent = previewRoot
styleCard(previewInfoFrame, Color3.fromRGB(74, 94, 129), Color3.fromRGB(52, 66, 92), Color3.fromRGB(123, 157, 207), false)
themeRegistry.cards[#themeRegistry.cards].role = "panelStrong"

local previewInfoPadding = Instance.new("UIPadding")
previewInfoPadding.PaddingTop = UDim.new(0, 10)
previewInfoPadding.PaddingBottom = UDim.new(0, 10)
previewInfoPadding.PaddingLeft = UDim.new(0, 12)
previewInfoPadding.PaddingRight = UDim.new(0, 12)
previewInfoPadding.Parent = previewInfoFrame

ui.previewInfoLabel = createLabel(
	"Press Preview to generate a visual preview in this window.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(189, 199, 214),
	36
)
enableAutoHeightLabel(ui.previewInfoLabel, 24)
ui.previewInfoLabel.Parent = previewInfoFrame

ui.previewViewport = Instance.new("ViewportFrame")
ui.previewViewport.Size = UDim2.new(1, 0, 0, 320)
ui.previewViewport.BackgroundColor3 = Color3.fromRGB(28, 35, 49)
ui.previewViewport.BorderSizePixel = 0
ui.previewViewport.LayoutOrder = 3
ui.previewViewport.Parent = previewRoot
createCorner(ui.previewViewport, 12)
createStroke(ui.previewViewport, Color3.fromRGB(86, 104, 136))
addVerticalGradient(ui.previewViewport, Color3.fromRGB(82, 103, 142), Color3.fromRGB(58, 75, 104))
createShadow(ui.previewViewport, 0.75, 8)
table.insert(themeRegistry.cards, {instance = ui.previewViewport, role = "viewport", includeShadow = true})

ui.previewWorldModel = Instance.new("WorldModel")
ui.previewWorldModel.Parent = ui.previewViewport

ui.previewCamera = Instance.new("Camera")
ui.previewCamera.Parent = ui.previewViewport
ui.previewViewport.CurrentCamera = ui.previewCamera
ui.previewViewport.Ambient = PREVIEW_LIGHTING_PRESETS.Studio.ambient
ui.previewViewport.LightColor = PREVIEW_LIGHTING_PRESETS.Studio.lightColor
ui.previewViewport.LightDirection = PREVIEW_LIGHTING_PRESETS.Studio.lightDirection

local previewStatsFrame = Instance.new("Frame")
previewStatsFrame.Size = UDim2.new(1, 0, 0, 0)
previewStatsFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
previewStatsFrame.BorderSizePixel = 0
previewStatsFrame.AutomaticSize = Enum.AutomaticSize.Y
previewStatsFrame.LayoutOrder = 4
previewStatsFrame.Parent = previewRoot
styleCard(previewStatsFrame, Color3.fromRGB(60, 73, 98), Color3.fromRGB(38, 48, 66), Color3.fromRGB(102, 126, 168), false)

local previewStatsPadding = Instance.new("UIPadding")
previewStatsPadding.PaddingTop = UDim.new(0, 10)
previewStatsPadding.PaddingBottom = UDim.new(0, 10)
previewStatsPadding.PaddingLeft = UDim.new(0, 12)
previewStatsPadding.PaddingRight = UDim.new(0, 12)
previewStatsPadding.Parent = previewStatsFrame

local previewStatsLayout = Instance.new("UIListLayout")
previewStatsLayout.Padding = UDim.new(0, 6)
previewStatsLayout.FillDirection = Enum.FillDirection.Vertical
previewStatsLayout.Parent = previewStatsFrame

local previewStatsTitle = createSectionTitle("Preview Stats")
previewStatsTitle.Parent = previewStatsFrame

ui.previewStatsLabel = createLabel(
	"No preview loaded yet.\nGenerate a preview to inspect bounds, parts, and request settings.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(189, 199, 214),
	72
)
enableAutoHeightLabel(ui.previewStatsLabel, 24)
ui.previewStatsLabel.Parent = previewStatsFrame

local previewControls = Instance.new("Frame")
previewControls.Size = UDim2.new(1, 0, 0, 216)
previewControls.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
previewControls.BorderSizePixel = 0
previewControls.LayoutOrder = 5
previewControls.Parent = previewRoot
styleCard(previewControls, Color3.fromRGB(60, 73, 98), Color3.fromRGB(38, 48, 66), Color3.fromRGB(102, 126, 168), false)

local previewControlsPadding = Instance.new("UIPadding")
previewControlsPadding.PaddingTop = UDim.new(0, 10)
previewControlsPadding.PaddingBottom = UDim.new(0, 10)
previewControlsPadding.PaddingLeft = UDim.new(0, 10)
previewControlsPadding.PaddingRight = UDim.new(0, 10)
previewControlsPadding.Parent = previewControls

local previewControlsLayout = Instance.new("UIGridLayout")
previewControlsLayout.CellPadding = UDim2.new(0, 8, 0, 8)
previewControlsLayout.CellSize = UDim2.new(0.5, -4, 0, 40)
previewControlsLayout.Parent = previewControls

ui.rotateLeftButton = createButton("Left", Color3.fromRGB(84, 107, 146), "info")
ui.rotateLeftButton.Parent = previewControls

ui.rotateRightButton = createButton("Right", Color3.fromRGB(84, 107, 146), "info")
ui.rotateRightButton.Parent = previewControls

ui.rotateUpButton = createButton("Up", Color3.fromRGB(84, 107, 146), "info")
ui.rotateUpButton.Parent = previewControls

ui.rotateDownButton = createButton("Down", Color3.fromRGB(84, 107, 146), "info")
ui.rotateDownButton.Parent = previewControls

ui.zoomInButton = createButton("Zoom In", Color3.fromRGB(57, 128, 116), "teal")
ui.zoomInButton.Parent = previewControls

ui.zoomOutButton = createButton("Zoom Out", Color3.fromRGB(57, 128, 116), "teal")
ui.zoomOutButton.Parent = previewControls

ui.autoRotateButton = createButton("Auto Rotate: Off", Color3.fromRGB(86, 99, 125), "muted")
ui.autoRotateButton.Parent = previewControls

ui.resetViewButton = createButton("Reset View", Color3.fromRGB(123, 101, 72), "warning")
ui.resetViewButton.Parent = previewControls

local previewDisplayControls = Instance.new("Frame")
previewDisplayControls.Size = UDim2.new(1, 0, 0, 308)
previewDisplayControls.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
previewDisplayControls.BorderSizePixel = 0
previewDisplayControls.LayoutOrder = 6
previewDisplayControls.Parent = previewRoot
styleCard(previewDisplayControls, Color3.fromRGB(60, 73, 98), Color3.fromRGB(38, 48, 66), Color3.fromRGB(102, 126, 168), false)

local previewDisplayPadding = Instance.new("UIPadding")
previewDisplayPadding.PaddingTop = UDim.new(0, 10)
previewDisplayPadding.PaddingBottom = UDim.new(0, 10)
previewDisplayPadding.PaddingLeft = UDim.new(0, 10)
previewDisplayPadding.PaddingRight = UDim.new(0, 10)
previewDisplayPadding.Parent = previewDisplayControls

local previewDisplayTitle = createSectionTitle("View and Display")
previewDisplayTitle.Parent = previewDisplayControls

local previewDisplayGrid = Instance.new("Frame")
previewDisplayGrid.Size = UDim2.new(1, 0, 0, 192)
previewDisplayGrid.BackgroundTransparency = 1
previewDisplayGrid.Position = UDim2.new(0, 0, 0, 28)
previewDisplayGrid.Parent = previewDisplayControls

local previewDisplayLayout = Instance.new("UIGridLayout")
previewDisplayLayout.CellPadding = UDim2.new(0, 8, 0, 8)
previewDisplayLayout.CellSize = UDim2.new(0.333, -6, 0, 40)
previewDisplayLayout.Parent = previewDisplayGrid

ui.previewFrontButton = createButton("Front View", Color3.fromRGB(84, 107, 146), "info")
ui.previewFrontButton.Parent = previewDisplayGrid

ui.previewSideButton = createButton("Side View", Color3.fromRGB(84, 107, 146), "info")
ui.previewSideButton.Parent = previewDisplayGrid

ui.previewTopButton = createButton("Top View", Color3.fromRGB(84, 107, 146), "info")
ui.previewTopButton.Parent = previewDisplayGrid

ui.previewIsoButton = createButton("Isometric", Color3.fromRGB(84, 107, 146), "info")
ui.previewIsoButton.Parent = previewDisplayGrid

ui.previewLightingButton = createButton("Lighting: Studio", Color3.fromRGB(90, 110, 140), "secondary")
ui.previewLightingButton.Parent = previewDisplayGrid

ui.previewBackgroundButton = createButton("Background: Cool", Color3.fromRGB(90, 110, 140), "secondary")
ui.previewBackgroundButton.Parent = previewDisplayGrid

ui.previewRotateSpeedButton = createButton("Rotate Speed: Normal", Color3.fromRGB(57, 128, 116), "teal")
ui.previewRotateSpeedButton.Parent = previewDisplayGrid

ui.previewOriginMarkerButton = createButton("Origin Marker: On", Color3.fromRGB(57, 128, 116), "active")
ui.previewOriginMarkerButton.Parent = previewDisplayGrid

ui.previewBoundsButton = createButton("Bounds Overlay: Off", Color3.fromRGB(86, 99, 125), "muted")
ui.previewBoundsButton.Parent = previewDisplayGrid

ui.previewCollisionOpacityButton = createButton("Collision Opacity: Medium", Color3.fromRGB(123, 101, 72), "warning")
ui.previewCollisionOpacityButton.Parent = previewDisplayGrid

ui.previewRefreshButton = createButton("Refresh Stats", Color3.fromRGB(67, 126, 141), "accent")
ui.previewRefreshButton.Parent = previewDisplayGrid

local previewDisplayHint = createLabel(
	"Use presets to inspect silhouette, scale, and collider readability without re-generating the model.",
	11,
	Enum.Font.Gotham,
	Color3.fromRGB(171, 183, 199),
	36
)
enableAutoHeightLabel(previewDisplayHint, 24)
previewDisplayHint.Position = UDim2.new(0, 0, 0, 224)
previewDisplayHint.Parent = previewDisplayControls

local collisionInfoFrame = Instance.new("Frame")
collisionInfoFrame.Size = UDim2.new(1, 0, 0, 0)
collisionInfoFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
collisionInfoFrame.BorderSizePixel = 0
collisionInfoFrame.AutomaticSize = Enum.AutomaticSize.Y
collisionInfoFrame.LayoutOrder = 7
collisionInfoFrame.Parent = previewRoot
styleCard(collisionInfoFrame, Color3.fromRGB(60, 73, 98), Color3.fromRGB(38, 48, 66), Color3.fromRGB(102, 126, 168), false)

local collisionInfoLayout = Instance.new("UIListLayout")
collisionInfoLayout.Padding = UDim.new(0, 6)
collisionInfoLayout.FillDirection = Enum.FillDirection.Vertical
collisionInfoLayout.VerticalAlignment = Enum.VerticalAlignment.Top
collisionInfoLayout.Parent = collisionInfoFrame

collisionInfoLabel = createLabel("Collider mode: auto (awaiting generation)", 12, Enum.Font.Gotham, Color3.fromRGB(178, 201, 255), 24)
collisionInfoLabel.Size = UDim2.new(1, -8, 0, 0)
collisionInfoLabel.AutomaticSize = Enum.AutomaticSize.Y
collisionInfoLabel.Position = UDim2.new(0, 4, 0, 4)
collisionInfoLabel.Parent = collisionInfoFrame

collisionPreviewButton = createButton("Show Collision Preview", Color3.fromRGB(57, 128, 116), "teal")
collisionPreviewButton.Size = UDim2.new(1, -8, 0, 34)
collisionPreviewButton.Parent = collisionInfoFrame
collisionPreviewButton.MouseButton1Click:Connect(function()
	setCollisionPreviewEnabled(not collisionPreviewEnabled)
end)

local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, 0, 0, 116)
statusFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
statusFrame.BorderSizePixel = 0
statusFrame.LayoutOrder = 13
statusFrame.Parent = root
styleCard(statusFrame, Color3.fromRGB(58, 71, 97), Color3.fromRGB(35, 44, 60), Color3.fromRGB(102, 126, 168), false)

local statusPadding = Instance.new("UIPadding")
statusPadding.PaddingTop = UDim.new(0, 10)
statusPadding.PaddingBottom = UDim.new(0, 10)
statusPadding.PaddingLeft = UDim.new(0, 10)
statusPadding.PaddingRight = UDim.new(0, 10)
statusPadding.Parent = statusFrame

ui.statusLabel = createLabel(
	"Ready. Write a prompt and generate a detailed model.",
	13,
	Enum.Font.Gotham,
	Color3.fromRGB(233, 236, 240),
	96
)
ui.statusLabel.Parent = statusFrame

local collisionTuningTitle = createSectionTitle("Collision Tuning")
collisionTuningTitle.LayoutOrder = 19
collisionTuningTitle.Parent = root

collisionTuningFrame = Instance.new("Frame")
collisionTuningFrame.Size = UDim2.new(1, 0, 0, 228)
collisionTuningFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
collisionTuningFrame.BorderSizePixel = 0
collisionTuningFrame.LayoutOrder = 20
collisionTuningFrame.Visible = showAdvancedCollisionTuning
collisionTuningFrame.Parent = root
styleCard(collisionTuningFrame, Color3.fromRGB(58, 71, 97), Color3.fromRGB(35, 44, 60), Color3.fromRGB(102, 126, 168), false)

local collisionTuningPadding = Instance.new("UIPadding")
collisionTuningPadding.PaddingTop = UDim.new(0, 10)
collisionTuningPadding.PaddingBottom = UDim.new(0, 10)
collisionTuningPadding.PaddingLeft = UDim.new(0, 10)
collisionTuningPadding.PaddingRight = UDim.new(0, 10)
collisionTuningPadding.Parent = collisionTuningFrame

local collisionTuningLayout = Instance.new("UIGridLayout")
collisionTuningLayout.CellPadding = UDim2.new(0, 8, 0, 8)
collisionTuningLayout.CellSize = UDim2.new(0.5, -4, 0, 34)
collisionTuningLayout.Parent = collisionTuningFrame

local collisionHeuristicInputs = {}

function registerCollisionHeuristicInput(name, settingKey, placeholder, fallback, parser, minimum, maximum)
	local stored = getSetting(settingKey, fallback)
	local defaultText = tostring(stored or fallback)
	local box = createSmallBox(placeholder, defaultText)
	box.Parent = collisionTuningFrame
	collisionHeuristicInputs[#collisionHeuristicInputs + 1] = {
		name = name,
		settingKey = settingKey,
		parser = parser,
		fallback = fallback,
		minimum = minimum,
		maximum = maximum,
		box = box,
	}
	box.FocusLost:Connect(function()
		local value = parser(box.Text, fallback, minimum, maximum)
		box.Text = tostring(value)
		setSetting(settingKey, value)
		collisionHeuristicsConfig[name] = value
	end)
end

registerCollisionHeuristicInput("simpleMaxParts", SETTINGS.collisionSimpleMaxParts, "Simple mode: max part count", defaultCollisionHeuristics.simpleMaxParts, parseNumber, 1, 64)
registerCollisionHeuristicInput("simpleOccupancy", SETTINGS.collisionSimpleOccupancy, "Simple mode: minimum space filled", defaultCollisionHeuristics.simpleOccupancy, parseDecimal, 0, 1)
registerCollisionHeuristicInput("simpleDominantShare", SETTINGS.collisionSimpleDominantShare, "Simple mode: largest part share", defaultCollisionHeuristics.simpleDominantShare, parseDecimal, 0, 1)
registerCollisionHeuristicInput("detailedPartThreshold", SETTINGS.collisionDetailedPartThreshold, "Detailed mode: part count trigger", defaultCollisionHeuristics.detailedPartThreshold, parseNumber, 4, 128)
registerCollisionHeuristicInput("detailedOccupancy", SETTINGS.collisionDetailedOccupancy, "Detailed mode: max space filled", defaultCollisionHeuristics.detailedOccupancy, parseDecimal, 0, 1)
registerCollisionHeuristicInput("detailedOccupancySecondary", SETTINGS.collisionDetailedOccupancySecondary, "Detailed mode: backup occupancy max", defaultCollisionHeuristics.detailedOccupancySecondary, parseDecimal, 0, 1)
registerCollisionHeuristicInput("detailedElongation", SETTINGS.collisionDetailedElongation, "Detailed mode: shape length trigger", defaultCollisionHeuristics.detailedElongation, parseDecimal, 1, 24)
registerCollisionHeuristicInput("detailedPartThresholdSecondary", SETTINGS.collisionDetailedPartThresholdSecondary, "Detailed mode: backup part trigger", defaultCollisionHeuristics.detailedPartThresholdSecondary, parseNumber, 4, 64)

function refreshCollisionHeuristicsFromInputs()
	for _, entry in ipairs(collisionHeuristicInputs) do
		local value = entry.parser(entry.box.Text, entry.fallback, entry.minimum, entry.maximum)
		entry.box.Text = tostring(value)
		collisionHeuristicsConfig[entry.name] = value
		setSetting(entry.settingKey, value)
	end
end

function applyCollisionHeuristicPreset(presetName)
	local preset = collisionHeuristicPresets[presetName]
	if not preset then
		return
	end

	for _, entry in ipairs(collisionHeuristicInputs) do
		local value = preset[entry.name]
		if value ~= nil then
			entry.box.Text = tostring(value)
			collisionHeuristicsConfig[entry.name] = value
			setSetting(entry.settingKey, value)
		end
	end
end

refreshCollisionHeuristicsFromInputs()

local busy = false

function setStatus(message, tone)
	ui.statusLabel.Text = message
	if tone == "error" then
		ui.statusLabel.TextColor3 = Color3.fromRGB(255, 153, 153)
	elseif tone == "success" then
		ui.statusLabel.TextColor3 = Color3.fromRGB(152, 225, 180)
	elseif tone == "info" then
		ui.statusLabel.TextColor3 = Color3.fromRGB(176, 205, 255)
	else
		ui.statusLabel.TextColor3 = Color3.fromRGB(233, 236, 240)
	end
end

local previewBusy = false
local activePreviewModel = nil
local activePreviewRequest = nil
local previewOrbitYaw = math.rad(45)
local previewOrbitPitch = math.rad(20)
local previewOrbitRadius = 18
local previewOrbitMinRadius = 8
local previewOrbitMaxRadius = 60
local previewOrbitTarget = Vector3.new()
local previewDragging = false
local previewDragLastPosition = nil
local previewDragInput = nil
local previewAutoRotateEnabled = false
local previewAutoRotateSpeed = math.rad(24)
local previewLightingPresetName = "Studio"
local previewBackgroundPresetName = "Cool"
local previewRotateSpeedMode = "Normal"
local previewShowOriginMarker = true
local previewShowBoundsOverlay = false
local previewCollisionOpacityMode = "Medium"
local previewDecorationFolder = nil
local previewDisplayButtons = {}

function registerPreviewDisplayButton(button)
	table.insert(previewDisplayButtons, button)
	return button
end

registerPreviewDisplayButton(ui.previewFrontButton)
registerPreviewDisplayButton(ui.previewSideButton)
registerPreviewDisplayButton(ui.previewTopButton)
registerPreviewDisplayButton(ui.previewIsoButton)
registerPreviewDisplayButton(ui.previewLightingButton)
registerPreviewDisplayButton(ui.previewBackgroundButton)
registerPreviewDisplayButton(ui.previewRotateSpeedButton)
registerPreviewDisplayButton(ui.previewOriginMarkerButton)
registerPreviewDisplayButton(ui.previewBoundsButton)
registerPreviewDisplayButton(ui.previewCollisionOpacityButton)
registerPreviewDisplayButton(ui.previewRefreshButton)

function formatPreviewNumber(value)
	return string.format("%.2f", value)
end

function getPreviewBounds(instance)
	if not instance then
		return CFrame.new(), Vector3.new(0, 0, 0)
	end
	if instance:IsA("Model") then
		return instance:GetBoundingBox()
	end
	if instance:IsA("BasePart") then
		return instance.CFrame, instance.Size
	end
	return CFrame.new(), Vector3.new(0, 0, 0)
end

function countMeshParts(instance)
	local total = 0
	if instance:IsA("MeshPart") then
		total += 1
	end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("MeshPart") then
			total += 1
		end
	end
	return total
end

function getCollisionHighlightTransparency(isMeshPart)
	if previewCollisionOpacityMode == "Low" then
		return isMeshPart and 0.68 or 0.85
	end
	if previewCollisionOpacityMode == "High" then
		return isMeshPart and 0.22 or 0.54
	end
	return isMeshPart and 0.45 or 0.72
end

function ensurePreviewDecorationFolder()
	if previewDecorationFolder and previewDecorationFolder.Parent == ui.previewWorldModel then
		return previewDecorationFolder
	end
	previewDecorationFolder = Instance.new("Folder")
	previewDecorationFolder.Name = "PreviewDecorations"
	previewDecorationFolder.Parent = ui.previewWorldModel
	return previewDecorationFolder
end

function clearPreviewDecorations()
	if previewDecorationFolder and previewDecorationFolder.Parent then
		previewDecorationFolder:Destroy()
	end
	previewDecorationFolder = nil
end

function createMarkerPart(parent, name, size, cframe, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = 0.15
	part.CastShadow = false
	part.Locked = true
	part.Parent = parent
	return part
end

function syncPreviewLightingButton()
	ui.previewLightingButton.Text = "Lighting: " .. previewLightingPresetName
end

function syncPreviewBackgroundButton()
	ui.previewBackgroundButton.Text = "Background: " .. previewBackgroundPresetName
end

function syncPreviewRotateSpeedButton()
	ui.previewRotateSpeedButton.Text = "Rotate Speed: " .. previewRotateSpeedMode
end

function syncPreviewOriginMarkerButton()
	ui.previewOriginMarkerButton.Text = "Origin Marker: " .. (previewShowOriginMarker and "On" or "Off")
	setButtonThemeRole(ui.previewOriginMarkerButton, previewShowOriginMarker and "active" or "muted")
end

function syncPreviewBoundsButton()
	ui.previewBoundsButton.Text = "Bounds Overlay: " .. (previewShowBoundsOverlay and "On" or "Off")
	setButtonThemeRole(ui.previewBoundsButton, previewShowBoundsOverlay and "active" or "muted")
end

function syncPreviewCollisionOpacityButton()
	ui.previewCollisionOpacityButton.Text = "Collision Opacity: " .. previewCollisionOpacityMode
end

function syncPreviewViewportLighting()
	local preset = PREVIEW_LIGHTING_PRESETS[previewLightingPresetName] or PREVIEW_LIGHTING_PRESETS.Studio
	ui.previewViewport.Ambient = preset.ambient
	ui.previewViewport.LightColor = preset.lightColor
	ui.previewViewport.LightDirection = preset.lightDirection
	syncPreviewLightingButton()
end

function syncPreviewViewportBackground()
	local preset = PREVIEW_BACKGROUND_PRESETS[previewBackgroundPresetName] or PREVIEW_BACKGROUND_PRESETS.Cool
	ui.previewViewport.BackgroundColor3 = preset.bottom
	addVerticalGradient(ui.previewViewport, preset.top, preset.bottom)
	createStroke(ui.previewViewport, preset.stroke)
	syncPreviewBackgroundButton()
end

function syncPreviewRotateSpeed()
	if previewRotateSpeedMode == "Slow" then
		previewAutoRotateSpeed = math.rad(10)
	elseif previewRotateSpeedMode == "Fast" then
		previewAutoRotateSpeed = math.rad(42)
	else
		previewAutoRotateSpeed = math.rad(24)
	end
	syncPreviewRotateSpeedButton()
end

function updatePreviewDecorations()
	clearPreviewDecorations()
	if not activePreviewModel then
		return
	end

	local folder = ensurePreviewDecorationFolder()
	local boundsCFrame, boundsSize = getPreviewBounds(activePreviewModel)
	local pivotPosition = activePreviewModel:IsA("Model") and activePreviewModel:GetPivot().Position or boundsCFrame.Position

	if previewShowOriginMarker then
		local originMarkerFolder = Instance.new("Folder")
		originMarkerFolder.Name = "OriginMarker"
		originMarkerFolder.Parent = folder
		local markerScale = math.max(math.min(math.max(boundsSize.X, boundsSize.Y, boundsSize.Z) * 0.12, 1.8), 0.35)
		createMarkerPart(originMarkerFolder, "OriginX", Vector3.new(markerScale * 2.2, markerScale * 0.16, markerScale * 0.16), CFrame.new(pivotPosition) * CFrame.new(markerScale, 0, 0), Color3.fromRGB(255, 98, 98))
		createMarkerPart(originMarkerFolder, "OriginY", Vector3.new(markerScale * 0.16, markerScale * 2.2, markerScale * 0.16), CFrame.new(pivotPosition) * CFrame.new(0, markerScale, 0), Color3.fromRGB(112, 232, 139))
		createMarkerPart(originMarkerFolder, "OriginZ", Vector3.new(markerScale * 0.16, markerScale * 0.16, markerScale * 2.2), CFrame.new(pivotPosition) * CFrame.new(0, 0, markerScale), Color3.fromRGB(108, 170, 255))
	end

	if previewShowBoundsOverlay then
		local boundsPart = Instance.new("Part")
		boundsPart.Name = "BoundsOverlay"
		boundsPart.Size = Vector3.new(math.max(boundsSize.X, 0.1), math.max(boundsSize.Y, 0.1), math.max(boundsSize.Z, 0.1))
		boundsPart.CFrame = boundsCFrame
		boundsPart.Anchored = true
		boundsPart.CanCollide = false
		boundsPart.CanTouch = false
		boundsPart.CanQuery = false
		boundsPart.Material = Enum.Material.ForceField
		boundsPart.Color = Color3.fromRGB(255, 225, 120)
		boundsPart.Transparency = 0.82
		boundsPart.CastShadow = false
		boundsPart.Locked = true
		boundsPart.Parent = folder
	end
end

function updatePreviewStats()
	if not ui.previewStatsLabel then
		return
	end
	if not activePreviewModel then
		ui.previewStatsLabel.Text = "No preview loaded yet.\nGenerate a preview to inspect bounds, parts, and request settings."
		return
	end

	local boundsCFrame, boundsSize = getPreviewBounds(activePreviewModel)
	local totalParts = 0
	if activePreviewModel:IsA("BasePart") then
		totalParts += 1
	end
	for _, descendant in ipairs(activePreviewModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			totalParts += 1
		end
	end
	local meshParts = countMeshParts(activePreviewModel)
	local request = activePreviewRequest
	local lines = {
		("Bounds: %s x %s x %s"):format(formatPreviewNumber(boundsSize.X), formatPreviewNumber(boundsSize.Y), formatPreviewNumber(boundsSize.Z)),
		("Center: %s, %s, %s"):format(formatPreviewNumber(boundsCFrame.Position.X), formatPreviewNumber(boundsCFrame.Position.Y), formatPreviewNumber(boundsCFrame.Position.Z)),
		("Parts: %d total, %d mesh"):format(totalParts, meshParts),
	}

	if request then
		lines[#lines + 1] = ("Request: size %s, max tris %s, textures %s"):format(tostring(request.targetSize), tostring(request.maxTriangles), tostring(request.textures))
		lines[#lines + 1] = ("Base %s, schema %s, seed %s, collider %s"):format(request.includeBase and "on" or "off", request.schemaName, request.seed ~= "" and request.seed or "random", request.colliderMode)
	end

	ui.previewStatsLabel.Text = table.concat(lines, "\n")
end

function setBusyState(nextBusy)
	busy = nextBusy
	ui.generateButton.AutoButtonColor = not nextBusy
	ui.generateButton.Active = not nextBusy
	ui.previewButton.AutoButtonColor = not nextBusy
	ui.previewButton.Active = not nextBusy
	ui.runtimeButton.AutoButtonColor = not nextBusy
	ui.runtimeButton.Active = not nextBusy
	ui.runtimeAllButton.AutoButtonColor = not nextBusy
	ui.runtimeAllButton.Active = not nextBusy
	ui.toggleStorageButton.AutoButtonColor = not nextBusy
	ui.toggleStorageButton.Active = not nextBusy
	if nextBusy then
		ui.generateButton.Text = "Generating..."
	else
		ui.generateButton.Text = "Generate Detailed Model"
	end
end

function clearPreviewModel()
	activePreviewModel = nil
	activePreviewRequest = nil
	previewAutoRotateEnabled = false
	clearCollisionHighlights()
	clearPreviewDecorations()
	for _, child in ipairs(ui.previewWorldModel:GetChildren()) do
		child:Destroy()
	end
	ui.autoRotateButton.Text = "Auto Rotate: Off"
	setButtonThemeRole(ui.autoRotateButton, "muted")
	ui.previewInfoLabel.Text = "Press Preview to generate a visual preview in this window."
	updatePreviewStats()
end

function applyPreviewCamera()
	local horizontal = math.cos(previewOrbitPitch) * previewOrbitRadius
	local cameraOffset = Vector3.new(
		math.cos(previewOrbitYaw) * horizontal,
		math.sin(previewOrbitPitch) * previewOrbitRadius,
		math.sin(previewOrbitYaw) * horizontal
	)
	ui.previewCamera.CFrame = CFrame.lookAt(previewOrbitTarget + cameraOffset, previewOrbitTarget)
end

function focusPreviewCamera(instance)
	local cframe, size
	if instance:IsA("Model") then
		cframe, size = instance:GetBoundingBox()
	elseif instance:IsA("BasePart") then
		cframe, size = instance.CFrame, instance.Size
	else
		cframe, size = CFrame.new(), Vector3.new(6, 6, 6)
	end

	local radius = math.max(size.X, size.Y, size.Z) * 0.9
	previewOrbitTarget = cframe.Position
	previewOrbitMinRadius = math.max(radius * 1.1, 5)
	previewOrbitMaxRadius = math.max(radius * 6, previewOrbitMinRadius + 14)
	previewOrbitRadius = math.clamp(math.max(radius * 2.2, 8), previewOrbitMinRadius, previewOrbitMaxRadius)
	previewOrbitYaw = math.rad(45)
	previewOrbitPitch = math.rad(20)
	applyPreviewCamera()
	updatePreviewDecorations()
end

function syncAutoRotateButton()
	if previewAutoRotateEnabled then
		ui.autoRotateButton.Text = "Auto Rotate: On"
		setButtonThemeRole(ui.autoRotateButton, "active")
	else
		ui.autoRotateButton.Text = "Auto Rotate: Off"
		setButtonThemeRole(ui.autoRotateButton, "muted")
	end
end

function setPreviewAutoRotate(enabled)
	previewAutoRotateEnabled = enabled and activePreviewModel ~= nil
	syncAutoRotateButton()
end

function beginPreviewDrag(input)
	if not activePreviewModel or previewBusy then
		return
	end
	previewDragging = true
	previewDragInput = input
	previewDragLastPosition = input.Position
	setPreviewAutoRotate(false)
end

function endPreviewDrag(input)
	if input and previewDragInput and input ~= previewDragInput then
		return
	end
	previewDragging = false
	previewDragInput = nil
	previewDragLastPosition = nil
end

function setPreviewCameraPreset(name)
	if not activePreviewModel then
		return
	end
	if name == "Front" then
		previewOrbitYaw = math.rad(90)
		previewOrbitPitch = 0
	elseif name == "Side" then
		previewOrbitYaw = 0
		previewOrbitPitch = 0
	elseif name == "Top" then
		previewOrbitYaw = math.rad(90)
		previewOrbitPitch = math.rad(80)
	else
		previewOrbitYaw = math.rad(45)
		previewOrbitPitch = math.rad(20)
	end
	applyPreviewCamera()
end

function cyclePreviewLightingPreset()
	local order = {"Studio", "Neutral", "Dramatic", "Outdoor"}
	for index, name in ipairs(order) do
		if name == previewLightingPresetName then
			previewLightingPresetName = order[(index % #order) + 1]
			break
		end
	end
	syncPreviewViewportLighting()
end

function cyclePreviewBackgroundPreset()
	local order = {"Cool", "Charcoal", "Light", "Sand"}
	for index, name in ipairs(order) do
		if name == previewBackgroundPresetName then
			previewBackgroundPresetName = order[(index % #order) + 1]
			break
		end
	end
	syncPreviewViewportBackground()
end

function cyclePreviewRotateSpeed()
	local order = {"Slow", "Normal", "Fast"}
	for index, name in ipairs(order) do
		if name == previewRotateSpeedMode then
			previewRotateSpeedMode = order[(index % #order) + 1]
			break
		end
	end
	syncPreviewRotateSpeed()
end

function setPreviewBusy(nextBusy)
	previewBusy = nextBusy
	ui.previewButton.AutoButtonColor = not nextBusy
	ui.previewButton.Active = not nextBusy
	ui.closePreviewButton.AutoButtonColor = not nextBusy
	ui.closePreviewButton.Active = not nextBusy
	ui.rotateLeftButton.AutoButtonColor = not nextBusy
	ui.rotateLeftButton.Active = not nextBusy
	ui.rotateRightButton.AutoButtonColor = not nextBusy
	ui.rotateRightButton.Active = not nextBusy
	ui.rotateUpButton.AutoButtonColor = not nextBusy
	ui.rotateUpButton.Active = not nextBusy
	ui.rotateDownButton.AutoButtonColor = not nextBusy
	ui.rotateDownButton.Active = not nextBusy
	ui.zoomInButton.AutoButtonColor = not nextBusy
	ui.zoomInButton.Active = not nextBusy
	ui.zoomOutButton.AutoButtonColor = not nextBusy
	ui.zoomOutButton.Active = not nextBusy
	ui.autoRotateButton.AutoButtonColor = not nextBusy
	ui.autoRotateButton.Active = not nextBusy
	ui.resetViewButton.AutoButtonColor = not nextBusy
	ui.resetViewButton.Active = not nextBusy
	for _, button in ipairs(previewDisplayButtons) do
		button.AutoButtonColor = not nextBusy
		button.Active = not nextBusy
	end
	if nextBusy then
		ui.previewInfoLabel.Text = "Generating preview..."
	else
		if activePreviewModel then
			ui.previewInfoLabel.Text = "Preview ready. Drag to orbit, use zoom, or enable auto-rotate."
		end
	end
end

function nudgePreviewCamera(yawDelta, pitchDelta)
	if not activePreviewModel then
		return
	end
	previewOrbitYaw += yawDelta
	previewOrbitPitch = math.clamp(previewOrbitPitch + pitchDelta, math.rad(-80), math.rad(80))
	applyPreviewCamera()
end

function zoomPreview(delta)
	if not activePreviewModel then
		return
	end
	previewOrbitRadius = math.clamp(previewOrbitRadius + delta, previewOrbitMinRadius, previewOrbitMaxRadius)
	applyPreviewCamera()
end

function resetPreviewCamera()
	if not activePreviewModel then
		return
	end
	focusPreviewCamera(activePreviewModel)
end

function clearCollisionHighlights()
	for _, highlight in ipairs(collisionPreviewHighlights) do
		if highlight and highlight.Parent then
			highlight:Destroy()
		end
	end
	collisionPreviewHighlights = {}
end

function createCollisionHighlight(source, index)
	if not ui.previewWorldModel then
		return
	end
	local highlight = Instance.new("Part")
	highlight.Name = ("%s_CollisionHighlight_%d"):format(source.name, index)
	highlight.Size = source.size
	highlight.CFrame = source.cframe
	highlight.Anchored = true
	highlight.CanCollide = false
	highlight.CanTouch = false
	highlight.CanQuery = false
	highlight.Transparency = getCollisionHighlightTransparency(false)
	highlight.Material = Enum.Material.Neon
	highlight.Color = collisionHighlightColor
	highlight.Parent = ui.previewWorldModel
	table.insert(collisionPreviewHighlights, highlight)
end

function createCollisionPreviewProxy(proxyPart, index)
	if not ui.previewWorldModel or not proxyPart:IsA("BasePart") then
		return
	end
	local highlight = proxyPart:Clone()
	highlight.Name = ("%s_CollisionPreview_%d"):format(proxyPart.Name, index)
	highlight.Anchored = true
	highlight.CanCollide = false
	highlight.CanTouch = false
	highlight.CanQuery = false
	highlight.Transparency = getCollisionHighlightTransparency(highlight:IsA("MeshPart"))
	highlight.Material = highlight:IsA("MeshPart") and Enum.Material.SmoothPlastic or Enum.Material.Neon
	highlight.Color = collisionHighlightColor
	highlight.CastShadow = false
	highlight.Locked = true
	highlight.Parent = ui.previewWorldModel
	table.insert(collisionPreviewHighlights, highlight)
end

function refreshCollisionHighlights()
	clearCollisionHighlights()
	if not collisionPreviewEnabled or not activePreviewModel then
		return
	end

	local previewProxy = createCollisionProxies(activePreviewModel, true, lastRequestedColliderMode)
	local index = 0
	for _, descendant in ipairs(previewProxy:GetDescendants()) do
		if descendant:IsA("BasePart") then
			index += 1
			createCollisionPreviewProxy(descendant, index)
		end
	end
	if previewProxy then
		previewProxy:Destroy()
	end
end

function updateCollisionPreviewButton()
	if not collisionPreviewButton then
		return
	end
	if collisionPreviewEnabled then
		collisionPreviewButton.Text = "Hide Collision Preview"
		setButtonThemeRole(collisionPreviewButton, "active")
	else
		collisionPreviewButton.Text = "Show Collision Preview"
		setButtonThemeRole(collisionPreviewButton, "teal")
	end
end

function setCollisionPreviewEnabled(enabled)
	collisionPreviewEnabled = enabled
	updateCollisionPreviewButton()
	if not enabled then
		clearCollisionHighlights()
	else
		refreshCollisionHighlights()
	end
	setSetting(SETTINGS.collisionPreview, enabled)
end

function formatDecimal(value)
	if not value then
		return "0.00"
	end
	return string.format("%.2f", value)
end

function updateCollisionInfoLabel(snapshot, requestedMode, autoResolved)
	if not collisionInfoLabel then
		return
	end
	requestedMode = normalizeColliderMode(requestedMode) or "ai"
	local resolvedMode = snapshot and snapshot.resolvedMode or requestedMode
	local autoText = autoResolved and " (auto)" or ""
	if not snapshot then
		collisionInfoLabel.Text = ("Collider mode: %s%s"):format(resolvedMode, autoText)
		return
	end
	collisionInfoLabel.Text = ("Collider mode: %s%s · parts: %d · occupancy: %s"):format(
		resolvedMode,
		autoText,
		snapshot.partCount,
		formatDecimal(snapshot.occupancy)
	)
end

function captureCollisionData(instance, requestedMode)
	local normalizedRequest = normalizeColliderMode(requestedMode)
	local resolvedMode, sources, autoResolved, snapshot = resolveColliderMode(instance, requestedMode)
	lastCollisionSources = sources
	lastRequestedColliderMode = normalizedRequest
	updateCollisionInfoLabel(snapshot, normalizedRequest, autoResolved)
	refreshCollisionHighlights()
end

syncPreviewViewportLighting()
syncPreviewViewportBackground()
syncPreviewRotateSpeed()
syncPreviewOriginMarkerButton()
syncPreviewBoundsButton()
syncPreviewCollisionOpacityButton()
updatePreviewStats()
setCollisionPreviewEnabled(collisionPreviewEnabled)

ui.previewViewport.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		beginPreviewDrag(input)
	end
end)

ui.previewViewport.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		endPreviewDrag(input)
	end
end)

ui.previewViewport.InputChanged:Connect(function(input)
	if not activePreviewModel then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		zoomPreview(-input.Position.Z * math.max(previewOrbitRadius * 0.12, 1.25))
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not previewDragging or not activePreviewModel then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	if not previewDragLastPosition then
		previewDragLastPosition = input.Position
		return
	end

	local delta = input.Position - previewDragLastPosition
	previewDragLastPosition = input.Position
	previewOrbitYaw -= delta.X * 0.01
	previewOrbitPitch = math.clamp(previewOrbitPitch - delta.Y * 0.008, math.rad(-80), math.rad(80))
	applyPreviewCamera()
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		endPreviewDrag(input)
	end
end)

RunService.Heartbeat:Connect(function(deltaTime)
	if not previewAutoRotateEnabled or previewBusy or not activePreviewModel or not previewWidget.Enabled then
		return
	end
	previewOrbitYaw += previewAutoRotateSpeed * deltaTime
	applyPreviewCamera()
end)

function getPromptName(prompt)
	local compact = string.gsub(prompt, "%s+", " ")
	compact = string.gsub(compact, "[^%w%s%-_]", "")
	compact = compact:sub(1, 40)
	compact = compact:gsub("^%s+", ""):gsub("%s+$", "")
	if compact == "" then
		return "DetailedModel"
	end
	return compact
end

function getInsertionParent()
	local selected = Selection:Get()
	if #selected == 1 then
		return selected[1]
	end
	return workspace
end

function applyAnchoredState(instance, anchored)
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = anchored
		end
	end
end

function configureVisualParts(instance, anchored)
	local targets = {instance}
	for _, descendant in ipairs(instance:GetDescendants()) do
		table.insert(targets, descendant)
	end

	for _, target in ipairs(targets) do
		if target:IsA("BasePart") then
			target.Anchored = anchored
			target.CanCollide = false
			target.CanTouch = false
			target.CanQuery = false
			if target:IsA("MeshPart") then
				pcall(function()
					target.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
				end)
			end
		end
	end
end

function normalizeColliderMode(value)
	local mode = string.lower(string.gsub(tostring(value or "medium"), "%s+", ""))
	if mode == "auto" then
		return "ai"
	end
	if mode == "simple" or mode == "medium" or mode == "detailed" or mode == "ai" then
		return mode
	end
	return "ai"
end

function addProxyPart(parent, name, size, cframe, anchored)
	local proxy = Instance.new("Part")
	proxy.Name = name
	proxy.Size = size
	proxy.CFrame = cframe
	proxy.Transparency = 1
	proxy.Color = Color3.new(1, 0, 0)
	proxy.Material = Enum.Material.SmoothPlastic
	proxy.Anchored = anchored
	proxy.CanCollide = true
	proxy.CanTouch = true
	proxy.CanQuery = true
	proxy.CastShadow = false
	proxy.Locked = true
	proxy.Parent = parent
	return proxy
end

function getWorldAABB(cframe, size)
	local px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cframe:GetComponents()
	local half = size * 0.5
	local ex = math.abs(r00) * half.X + math.abs(r01) * half.Y + math.abs(r02) * half.Z
	local ey = math.abs(r10) * half.X + math.abs(r11) * half.Y + math.abs(r12) * half.Z
	local ez = math.abs(r20) * half.X + math.abs(r21) * half.Y + math.abs(r22) * half.Z
	return Vector3.new(px - ex, py - ey, pz - ez), Vector3.new(px + ex, py + ey, pz + ez)
end

function gatherCollisionSources(instance)
	local sources = {}

	local function addSource(name, cframe, size, part)
		local minPoint, maxPoint = getWorldAABB(cframe, size)
		table.insert(sources, {
			name = name,
			cframe = cframe,
			size = size,
			minPoint = minPoint,
			maxPoint = maxPoint,
			part = part,
		})
	end

	if instance:IsA("BasePart") then
		addSource(instance.Name, instance.CFrame, instance.Size, instance)
	end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			addSource(descendant.Name, descendant.CFrame, descendant.Size, descendant)
		end
	end

	return sources
end

function inferColliderModeFromSources(sources, heuristics)
	if #sources <= 1 then
		return "simple"
	end

	local minPoint = sources[1].minPoint
	local maxPoint = sources[1].maxPoint
	local totalVolume = 0
	local largestVolume = 0

	for _, source in ipairs(sources) do
		minPoint = Vector3.new(
			math.min(minPoint.X, source.minPoint.X),
			math.min(minPoint.Y, source.minPoint.Y),
			math.min(minPoint.Z, source.minPoint.Z)
		)
		maxPoint = Vector3.new(
			math.max(maxPoint.X, source.maxPoint.X),
			math.max(maxPoint.Y, source.maxPoint.Y),
			math.max(maxPoint.Z, source.maxPoint.Z)
		)

		local volume = math.max(source.size.X, 0.05) * math.max(source.size.Y, 0.05) * math.max(source.size.Z, 0.05)
		totalVolume += volume
		largestVolume = math.max(largestVolume, volume)
	end

	local bounds = maxPoint - minPoint
	local boundingVolume = math.max(bounds.X, 0.1) * math.max(bounds.Y, 0.1) * math.max(bounds.Z, 0.1)
	local occupancy = math.clamp(totalVolume / boundingVolume, 0, 1)
	local sortedAxes = {math.max(bounds.X, 0.1), math.max(bounds.Y, 0.1), math.max(bounds.Z, 0.1)}
	table.sort(sortedAxes)
	local elongation = sortedAxes[3] / math.max(sortedAxes[1], 0.1)
	local dominantShare = largestVolume / math.max(totalVolume, 0.001)

	heuristics = heuristics or collisionHeuristicsConfig

	if #sources <= heuristics.simpleMaxParts and occupancy >= heuristics.simpleOccupancy and dominantShare >= heuristics.simpleDominantShare then
		return "simple"
	end

	if #sources >= heuristics.detailedPartThreshold or occupancy <= heuristics.detailedOccupancy or elongation >= heuristics.detailedElongation then
		return "detailed"
	end

	if #sources >= heuristics.detailedPartThresholdSecondary and occupancy <= heuristics.detailedOccupancySecondary then
		return "detailed"
	end

	return "medium"
end

function shouldUseMeshCollision(sources, resolvedMode)
	if resolvedMode ~= "simple" then
		return false
	end
	if #sources == 0 then
		return false
	end
	local meshCount = 0
	for _, source in ipairs(sources) do
		if source.part and source.part:IsA("MeshPart") then
			meshCount = meshCount + 1
		end
	end
	return meshCount > 0 and meshCount == #sources
end

function buildCollisionSnapshot(sources, resolvedMode)
	local snapshot = {
		resolvedMode = resolvedMode,
		partCount = #sources,
		occupancy = 0,
		dominantShare = 0,
		elongation = 0,
	}

	if #sources == 0 then
		return snapshot
	end

	local minPoint = sources[1].minPoint
	local maxPoint = sources[1].maxPoint
	local totalVolume = 0
	local largestVolume = 0

	for _, source in ipairs(sources) do
		minPoint = Vector3.new(
			math.min(minPoint.X, source.minPoint.X),
			math.min(minPoint.Y, source.minPoint.Y),
			math.min(minPoint.Z, source.minPoint.Z)
		)
		maxPoint = Vector3.new(
			math.max(maxPoint.X, source.maxPoint.X),
			math.max(maxPoint.Y, source.maxPoint.Y),
			math.max(maxPoint.Z, source.maxPoint.Z)
		)

		local volume = math.max(source.size.X, 0.05) * math.max(source.size.Y, 0.05) * math.max(source.size.Z, 0.05)
		totalVolume += volume
		largestVolume = math.max(largestVolume, volume)
	end

	local bounds = maxPoint - minPoint
	local boundingVolume = math.max(bounds.X, 0.1) * math.max(bounds.Y, 0.1) * math.max(bounds.Z, 0.1)
	local occupancy = math.clamp(totalVolume / boundingVolume, 0, 1)
	local sortedAxes = {math.max(bounds.X, 0.1), math.max(bounds.Y, 0.1), math.max(bounds.Z, 0.1)}
	table.sort(sortedAxes)
	local elongation = sortedAxes[3] / math.max(sortedAxes[1], 0.1)
	local dominantShare = largestVolume / math.max(totalVolume, 0.001)

	snapshot.occupancy = occupancy
	snapshot.elongation = elongation
	snapshot.dominantShare = dominantShare
	return snapshot
end

function buildMeshCollisionFolder(instance, anchored, sources)
	local folder = Instance.new("Folder")
	folder.Name = instance.Name .. "_Collision"
	for index, source in ipairs(sources) do
		local part = source.part
		if part then
			local clone = part:Clone()
			clone.Name = ("%s_MeshCollision_%d"):format(instance.Name, index)
			clone.Transparency = 1
			clone.Anchored = anchored
			clone.CanCollide = true
			clone.CanTouch = true
			clone.CanQuery = true
			clone.CastShadow = false
			clone.Locked = true
			if clone:IsA("MeshPart") then
				pcall(function()
					clone.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
				end)
			end
			clone.Parent = folder
		end
	end
	return folder
end

function resolveColliderMode(instance, colliderMode)
	local normalizedMode = normalizeColliderMode(colliderMode)
	local sources = gatherCollisionSources(instance)
	if normalizedMode ~= "ai" then
		return normalizedMode, sources, false, buildCollisionSnapshot(sources, normalizedMode)
	end

	if #sources == 0 then
		return "medium", sources, true, buildCollisionSnapshot(sources, "medium")
	end

	local resolved = inferColliderModeFromSources(sources, collisionHeuristicsConfig)
	return resolved, sources, true, buildCollisionSnapshot(sources, resolved)
end

function getClosestAABBDistance(first, second)
	local dx = math.max(0, first.minPoint.X - second.maxPoint.X, second.minPoint.X - first.maxPoint.X)
	local dy = math.max(0, first.minPoint.Y - second.maxPoint.Y, second.minPoint.Y - first.maxPoint.Y)
	local dz = math.max(0, first.minPoint.Z - second.maxPoint.Z, second.minPoint.Z - first.maxPoint.Z)
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function buildColliderClusters(sources, colliderMode)
	local thresholdByMode = {
		simple = math.huge,
		medium = 2.5,
		detailed = 0.35,
	}
	local threshold = thresholdByMode[colliderMode] or thresholdByMode.medium
	local parents = {}

	for index = 1, #sources do
		parents[index] = index
	end

	local function find(index)
		while parents[index] ~= index do
			parents[index] = parents[parents[index]]
			index = parents[index]
		end
		return index
	end

	local function union(a, b)
		local rootA = find(a)
		local rootB = find(b)
		if rootA ~= rootB then
			parents[rootB] = rootA
		end
	end

	for left = 1, #sources do
		for right = left + 1, #sources do
			if getClosestAABBDistance(sources[left], sources[right]) <= threshold then
				union(left, right)
			end
		end
	end

	local grouped = {}
	for index, source in ipairs(sources) do
		local root = find(index)
		local group = grouped[root]
		if not group then
			group = {
				minPoint = source.minPoint,
				maxPoint = source.maxPoint,
				count = 0,
			}
			grouped[root] = group
		else
			group.minPoint = Vector3.new(
				math.min(group.minPoint.X, source.minPoint.X),
				math.min(group.minPoint.Y, source.minPoint.Y),
				math.min(group.minPoint.Z, source.minPoint.Z)
			)
			group.maxPoint = Vector3.new(
				math.max(group.maxPoint.X, source.maxPoint.X),
				math.max(group.maxPoint.Y, source.maxPoint.Y),
				math.max(group.maxPoint.Z, source.maxPoint.Z)
			)
		end
		group.count += 1
	end

	local clusters = {}
	for _, group in pairs(grouped) do
		table.insert(clusters, group)
	end
	return clusters
end

function createCollisionProxies(instance, anchored, colliderMode)
	local requestedMode = normalizeColliderMode(colliderMode)
	local resolvedMode, sources, autoResolved, _ = resolveColliderMode(instance, colliderMode)

	if autoResolved and shouldUseMeshCollision(sources, resolvedMode) then
		local meshFolder = buildMeshCollisionFolder(instance, anchored, sources)
		meshFolder:SetAttribute("DetailedModelRequestedColliderMode", requestedMode)
		meshFolder:SetAttribute("DetailedModelResolvedColliderMode", resolvedMode)
		return meshFolder
	end

	local proxyFolder = Instance.new("Folder")
	proxyFolder.Name = instance.Name .. "_Collision"
	proxyFolder:SetAttribute("DetailedModelRequestedColliderMode", requestedMode)
	proxyFolder:SetAttribute("DetailedModelResolvedColliderMode", resolvedMode)

	if resolvedMode == "simple" then
		local cframe, size
		if instance:IsA("Model") then
			cframe, size = instance:GetBoundingBox()
		elseif instance:IsA("BasePart") then
			cframe, size = instance.CFrame, instance.Size
		else
			cframe, size = CFrame.new(), Vector3.new(4, 4, 4)
		end
		addProxyPart(proxyFolder, instance.Name .. "_CollisionProxy", size, cframe, anchored)
		return proxyFolder
	end

	if #sources == 0 then
		return proxyFolder
	end

	local clusters = buildColliderClusters(sources, resolvedMode)
	for index, cluster in ipairs(clusters) do
		local size = cluster.maxPoint - cluster.minPoint
		local center = (cluster.minPoint + cluster.maxPoint) * 0.5
		addProxyPart(
			proxyFolder,
			("%s_CollisionProxy_%d"):format(instance.Name, index),
			Vector3.new(math.max(size.X, 0.1), math.max(size.Y, 0.1), math.max(size.Z, 0.1)),
			CFrame.new(center),
			anchored
		)
	end

	return proxyFolder
end

function countParts(instance)
	local total = 0
	if instance:IsA("BasePart") then
		total += 1
	end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			total += 1
		end
	end
	return total
end

function clearGeneratedTextureReferences(instance)
	local targets = {instance}
	for _, descendant in ipairs(instance:GetDescendants()) do
		table.insert(targets, descendant)
	end

	for _, target in ipairs(targets) do
		if target:IsA("MeshPart") then
			local success, textureContent = pcall(function()
				return target.TextureContent
			end)
			if success and textureContent == Content.none then
				pcall(function()
					target.TextureID = ""
				end)
			end
		end
	end
end

function serializeCFrame(cframe)
	local components = {cframe:GetComponents()}
	for index, value in ipairs(components) do
		components[index] = string.format("%.9g", value)
	end
	return table.concat(components, ",")
end

function getInstancePivot(instance)
	if instance:IsA("Model") then
		return instance:GetPivot()
	end
	if instance:IsA("BasePart") then
		return instance.CFrame
	end
	return CFrame.new()
end

function getInstanceScale(instance)
	if instance and instance:IsA("Model") then
		local success, scale = pcall(function()
			return instance:GetScale()
		end)
		if success and type(scale) == "number" and scale > 0 then
			return scale
		end
	end
	return 1
end

function buildSeededPrompt(prompt, seed)
	local cleanedSeed = tostring(seed or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if cleanedSeed == "" then
		return prompt, ""
	end
	return ("%s\nvariation-seed:%s"):format(prompt, cleanedSeed), cleanedSeed
end

function applyBasePreferenceToPrompt(prompt, includeBase)
	if includeBase then
		return prompt
	end
	return table.concat({
		tostring(prompt or ""),
		"no base",
		"no baseplate",
		"no foundation slab",
		"no pedestal",
		"building only",
	}, "\n")
end

function syncGenerationBooleanButtons()
	if ui.texturesToggleButton then
		ui.texturesToggleButton.Text = generationTexturesEnabled and "Textures: On" or "Textures: Off"
		setButtonThemeRole(ui.texturesToggleButton, generationTexturesEnabled and "active" or "muted")
	end
	if ui.includeBaseToggleButton then
		ui.includeBaseToggleButton.Text = generationIncludeBaseEnabled and "Generated Base: On" or "Generated Base: Off"
		setButtonThemeRole(ui.includeBaseToggleButton, generationIncludeBaseEnabled and "active" or "muted")
	end
	if ui.anchoredToggleButton then
		ui.anchoredToggleButton.Text = generationAnchoredEnabled and "Anchored: On" or "Anchored: Off"
		setButtonThemeRole(ui.anchoredToggleButton, generationAnchoredEnabled and "active" or "muted")
	end
end

function normalizeExperimentalStyleBias(value)
	local mode = tostring(value or "Off")
	local allowed = {
		Off = true,
		Realistic = true,
		Stylized = true,
		["Hard Surface"] = true,
		Organic = true,
		["Toy-like"] = true,
	}
	if allowed[mode] then
		return mode
	end
	return "Off"
end

function normalizeExperimentalPreviewMode(value)
	local mode = tostring(value or "Balanced")
	if mode == "Fast" or mode == "High Quality" or mode == "Balanced" then
		return mode
	end
	return "Balanced"
end

function buildExperimentalPrompt(prompt)
	local finalPrompt = tostring(prompt or "")
	local negativePrompt = ui.experimentalNegativePromptBox and tostring(ui.experimentalNegativePromptBox.Text or "") or ""
	negativePrompt = negativePrompt:gsub("^%s+", ""):gsub("%s+$", "")

	experimentalStyleBias = normalizeExperimentalStyleBias(experimentalStyleBias)
	if experimentalStyleBias ~= "Off" then
		finalPrompt = ("%s\nstyle-bias:%s"):format(finalPrompt, string.lower(experimentalStyleBias))
	end
	if negativePrompt ~= "" then
		finalPrompt = ("%s\navoid:%s"):format(finalPrompt, negativePrompt)
	end

	return finalPrompt, negativePrompt
end

function getExperimentalPreviewTriangleBudget(maxTriangles)
	experimentalPreviewMode = normalizeExperimentalPreviewMode(experimentalPreviewMode)
	if experimentalPreviewMode == "Fast" then
		return math.max(500, math.floor(maxTriangles * 0.45))
	end
	if experimentalPreviewMode == "High Quality" then
		return math.max(500, math.floor(maxTriangles * 1))
	end
	return math.max(500, math.floor(maxTriangles * 0.7))
end

function applyGroundSnapAtOrigin(instance)
	local boundsCFrame, boundsSize
	if instance:IsA("Model") then
		boundsCFrame, boundsSize = instance:GetBoundingBox()
	elseif instance:IsA("BasePart") then
		boundsCFrame, boundsSize = instance.CFrame, instance.Size
	else
		return
	end

	local targetPosition = Vector3.new(0, math.max(boundsSize.Y * 0.5, 0), 0)
	local translation = targetPosition - boundsCFrame.Position
	if instance:IsA("Model") then
		instance:PivotTo(instance:GetPivot() + translation)
	elseif instance:IsA("BasePart") then
		instance.CFrame += translation
	end
end

function saveInputs(prompt, targetSize, maxTriangles, textures, includeBase, anchored, schemaName, colliderMode, seed)
	setSetting(SETTINGS.prompt, prompt)
	setSetting(SETTINGS.size, targetSize)
	setSetting(SETTINGS.maxTriangles, maxTriangles)
	setSetting(SETTINGS.textures, textures)
	setSetting(SETTINGS.includeBase, includeBase)
	setSetting(SETTINGS.anchored, anchored)
	setSetting(SETTINGS.schema, schemaName)
	setSetting(SETTINGS.colliderMode, colliderMode)
	setSetting(SETTINGS.seed, seed)
end

function attachGeneratedCollisionModel(parentTarget, generatedModel, request)
	local collisionModel = createCollisionProxies(generatedModel, request.anchored, request.colliderMode)
	collisionModel.Name = generatedModel.Name .. "_Collision"
	collisionModel:SetAttribute("DetailedModelPrompt", request.prompt)
	collisionModel:SetAttribute("DetailedModelColliderMode", request.colliderMode)

	local existingCollisionModel = generatedModel:FindFirstChild(collisionModel.Name)
	if existingCollisionModel then
		existingCollisionModel:Destroy()
	end

	collisionModel.Parent = generatedModel
	return collisionModel
end

function getGeneratedCollisionContainer(generatedModel)
	if not generatedModel then
		return nil
	end

	local collisionModelName = generatedModel.Name .. "_Collision"
	local child = generatedModel:FindFirstChild(collisionModelName)
	if child then
		return child
	end

	return nil
end

function buildRequest()
	refreshCollisionHeuristicsFromInputs()

	local prompt = ui.promptBox.Text
	local targetSize = parseNumber(ui.sizeBox.Text, 24, 4, 512)
	local maxTriangles = parseNumber(ui.trianglesBox.Text, 20000, 500, 100000)
	local textures = generationTexturesEnabled
	local includeBase = generationIncludeBaseEnabled
	local anchored = generationAnchoredEnabled
	local schemaName = ui.schemaBox.Text ~= "" and ui.schemaBox.Text or "Body1"
	local seed = ui.seedBox.Text or ""
	local colliderMode = normalizeColliderMode(ui.colliderModeBox.Text)
	local baseAdjustedPrompt = applyBasePreferenceToPrompt(prompt, includeBase)
	local experimentalPrompt, negativePrompt = buildExperimentalPrompt(baseAdjustedPrompt)
	local seededPrompt, normalizedSeed = buildSeededPrompt(experimentalPrompt, seed)

	local inputs = {
		TextPrompt = seededPrompt,
		Size = Vector3.new(targetSize, targetSize, targetSize),
		MaxTriangles = maxTriangles,
		GenerateTextures = textures,
	}

	local schema = {
		PredefinedSchema = schemaName,
	}

	return {
		prompt = prompt,
		targetSize = targetSize,
		maxTriangles = maxTriangles,
		textures = textures,
		includeBase = includeBase,
		anchored = anchored,
		schemaName = schemaName,
		seed = normalizedSeed,
		negativePrompt = negativePrompt,
		styleBias = experimentalStyleBias,
		previewMode = experimentalPreviewMode,
		groundSnap = experimentalGroundSnap,
		effectivePrompt = seededPrompt,
		colliderMode = colliderMode,
		inputs = inputs,
		schema = schema,
	}
end

function renderRequestPreview(request)
	setStatus(
		table.concat({
			"Preview",
			"Prompt: " .. request.prompt,
			"Size: " .. tostring(request.targetSize),
			"MaxTriangles: " .. tostring(request.maxTriangles),
			"GenerateTextures: " .. tostring(request.textures),
			"IncludeBase: " .. tostring(request.includeBase),
			"Anchored: " .. tostring(request.anchored),
			"Schema: " .. request.schemaName,
			"Seed: " .. (request.seed ~= "" and request.seed or "random"),
			"ColliderMode: " .. request.colliderMode,
		}, "\n"),
		"info"
	)
end

function validateRequest(request)
	if string.gsub(request.prompt, "%s+", "") == "" then
		return false, "Enter a prompt before generating."
	end
	return true
end

function loadModelIntoPreview(model, colliderMode, statusMessage, request)
	previewWidget.Enabled = true
	clearPreviewModel()
	activePreviewModel = model
	activePreviewRequest = request
	model.Name = "PreviewModel"
	model.Parent = ui.previewWorldModel
	captureCollisionData(model, colliderMode)
	focusPreviewCamera(model)
	updatePreviewStats()
	setPreviewBusy(false)
	setStatus(statusMessage, "success")
end

function generateVisualPreview()
	if busy or previewBusy then
		return
	end

	local request = buildRequest()
	local valid, message = validateRequest(request)
	if not valid then
		setStatus(message, "error")
		return
	end

	previewWidget.Enabled = true
	setPreviewBusy(true)
	request.inputs.MaxTriangles = getExperimentalPreviewTriangleBudget(request.maxTriangles)

	local cachedPreviewModel = loadCachedVisualModel(request)
	if cachedPreviewModel then
		pushPromptHistory(request.prompt)
		refreshPromptHistoryButtons()
		loadModelIntoPreview(cachedPreviewModel, request.colliderMode, "Opened a cached visual preview in the preview window.", request)
		return
	end

	local success, generatedModel = pcall(function()
		return GenerationService:GenerateModelAsync(request.inputs, request.schema)
	end)

	if not success or typeof(generatedModel) ~= "Instance" then
		setPreviewBusy(false)
		ui.previewInfoLabel.Text = "Preview failed: " .. tostring(generatedModel)
		setStatus("Preview generation failed: " .. tostring(generatedModel), "error")
		return
	end

	storeCachedVisualModel(request, generatedModel)
	pushPromptHistory(request.prompt)
	refreshPromptHistoryButtons()
	loadModelIntoPreview(generatedModel, request.colliderMode, "Opened a visual preview in the preview window.", request)
end

function buildRuntimeManagerSource()
	return table.concat({
		"local GenerationService = game:GetService(\"GenerationService\")",
		"local ServerStorage = game:GetService(\"ServerStorage\")",
		"local REQUESTS_FOLDER_NAME = \"DetailedModelRuntimeRequests\"",
		"local STORED_MODELS_FOLDER_NAME = \"DetailedModelStoredModels\"",
		"local OUTPUT_FOLDER_NAME = \"DetailedModelRuntimeOutput\"",
		"",
		"local function applyAnchoredState(instance, anchored)",
		"\tfor _, descendant in ipairs(instance:GetDescendants()) do",
		"\t\tif descendant:IsA(\"BasePart\") then",
		"\t\t\tdescendant.Anchored = anchored",
		"\t\tend",
		"\tend",
		"end",
		"",
		"local function configureVisualParts(instance, anchored)",
		"\tlocal targets = {instance}",
		"\tfor _, descendant in ipairs(instance:GetDescendants()) do",
		"\t\ttable.insert(targets, descendant)",
		"\tend",
		"\tfor _, target in ipairs(targets) do",
		"\t\tif target:IsA(\"BasePart\") then",
		"\t\t\ttarget.Anchored = anchored",
		"\t\t\ttarget.CanCollide = false",
		"\t\t\ttarget.CanTouch = false",
		"\t\t\ttarget.CanQuery = false",
		"\t\tend",
		"\tend",
		"end",
		"",
		"local function normalizeColliderMode(value)",
		"\tlocal mode = string.lower(string.gsub(tostring(value or \"medium\"), \"%s+\", \"\"))",
		"\tif mode == \"auto\" then",
		"\t\treturn \"ai\"",
		"\tend",
		"\tif mode == \"simple\" or mode == \"medium\" or mode == \"detailed\" or mode == \"ai\" then",
		"\t\treturn mode",
		"\tend",
		"\treturn \"ai\"",
		"end",
		"",
		"local function addProxyPart(parent, name, size, cframe, anchored)",
		"\tlocal proxy = Instance.new(\"Part\")",
		"\tproxy.Name = name",
		"\tproxy.Size = size",
		"\tproxy.CFrame = cframe",
		"\tproxy.Transparency = 1",
		"\tproxy.Color = Color3.new(1, 0, 0)",
		"\tproxy.Material = Enum.Material.SmoothPlastic",
		"\tproxy.Anchored = anchored",
		"\tproxy.CanCollide = true",
		"\tproxy.CanTouch = true",
		"\tproxy.CanQuery = true",
		"\tproxy.CastShadow = false",
		"\tproxy.Locked = true",
		"\tproxy.Parent = parent",
		"\treturn proxy",
		"end",
		"",
		"local function getWorldAABB(cframe, size)",
		"\tlocal px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cframe:GetComponents()",
		"\tlocal half = size * 0.5",
		"\tlocal ex = math.abs(r00) * half.X + math.abs(r01) * half.Y + math.abs(r02) * half.Z",
		"\tlocal ey = math.abs(r10) * half.X + math.abs(r11) * half.Y + math.abs(r12) * half.Z",
		"\tlocal ez = math.abs(r20) * half.X + math.abs(r21) * half.Y + math.abs(r22) * half.Z",
		"\treturn Vector3.new(px - ex, py - ey, pz - ez), Vector3.new(px + ex, py + ey, pz + ez)",
		"end",
		"",
		"local function gatherCollisionSources(instance)",
		"\tlocal sources = {}",
		"\tlocal function addSource(name, cframe, size, part)",
		"\t\tlocal minPoint, maxPoint = getWorldAABB(cframe, size)",
		"\t\ttable.insert(sources, {",
		"\t\t\tname = name,",
		"\t\t\tcframe = cframe,",
		"\t\t\tsize = size,",
		"\t\t\tminPoint = minPoint,",
		"\t\t\tmaxPoint = maxPoint,",
		"\t\t\tpart = part,",
		"\t\t})",
		"\tend",
		"\tif instance:IsA(\"BasePart\") then",
		"\t\taddSource(instance.Name, instance.CFrame, instance.Size, instance)",
		"\tend",
		"\tfor _, descendant in ipairs(instance:GetDescendants()) do",
		"\t\tif descendant:IsA(\"BasePart\") then",
		"\t\t\taddSource(descendant.Name, descendant.CFrame, descendant.Size, descendant)",
		"\t\tend",
		"\tend",
		"\treturn sources",
		"end",
		"",
		"local collisionHeuristicsConfig = { simpleMaxParts = 4, simpleOccupancy = 0.55, simpleDominantShare = 0.45, detailedPartThreshold = 18, detailedPartThresholdSecondary = 10, detailedOccupancy = 0.18, detailedOccupancySecondary = 0.32, detailedElongation = 6 }",
		"",
		"local function inferColliderModeFromSources(sources)",
		"\tif #sources <= 1 then",
		"\t\treturn \"simple\"",
		"\tend",
		"\tlocal minPoint = sources[1].minPoint",
		"\tlocal maxPoint = sources[1].maxPoint",
		"\tlocal totalVolume = 0",
		"\tlocal largestVolume = 0",
		"\tfor _, source in ipairs(sources) do",
		"\t\tminPoint = Vector3.new(",
		"\t\t\tmath.min(minPoint.X, source.minPoint.X),",
		"\t\t\tmath.min(minPoint.Y, source.minPoint.Y),",
		"\t\t\tmath.min(minPoint.Z, source.minPoint.Z)",
		"\t\t)",
		"\t\tmaxPoint = Vector3.new(",
		"\t\t\tmath.max(maxPoint.X, source.maxPoint.X),",
		"\t\t\tmath.max(maxPoint.Y, source.maxPoint.Y),",
		"\t\t\tmath.max(maxPoint.Z, source.maxPoint.Z)",
		"\t\t)",
		"\t\tlocal volume = math.max(source.size.X, 0.05) * math.max(source.size.Y, 0.05) * math.max(source.size.Z, 0.05)",
		"\t\ttotalVolume += volume",
		"\t\tlargestVolume = math.max(largestVolume, volume)",
		"\tend",
		"\tlocal bounds = maxPoint - minPoint",
		"\tlocal boundingVolume = math.max(bounds.X, 0.1) * math.max(bounds.Y, 0.1) * math.max(bounds.Z, 0.1)",
		"\tlocal occupancy = math.clamp(totalVolume / boundingVolume, 0, 1)",
		"\tlocal sortedAxes = {math.max(bounds.X, 0.1), math.max(bounds.Y, 0.1), math.max(bounds.Z, 0.1)}",
		"\ttable.sort(sortedAxes)",
		"\tlocal elongation = sortedAxes[3] / math.max(sortedAxes[1], 0.1)",
		"\tlocal dominantShare = largestVolume / math.max(totalVolume, 0.001)",
		"\tlocal heuristics = collisionHeuristicsConfig",
		"\tif #sources <= heuristics.simpleMaxParts and occupancy >= heuristics.simpleOccupancy and dominantShare >= heuristics.simpleDominantShare then",
		"\t\treturn \"simple\"",
		"\tend",
		"\tif #sources >= heuristics.detailedPartThreshold or occupancy <= heuristics.detailedOccupancy or elongation >= heuristics.detailedElongation then",
		"\t\treturn \"detailed\"",
		"\tend",
		"\tif #sources >= heuristics.detailedPartThresholdSecondary and occupancy <= heuristics.detailedOccupancySecondary then",
		"\t\treturn \"detailed\"",
		"\tend",
		"\treturn \"medium\"",
		"end",
		"",
		"local function buildCollisionSnapshot(sources, resolvedMode)",
		"\tlocal snapshot = { resolvedMode = resolvedMode, partCount = #sources, occupancy = 0, dominantShare = 0, elongation = 0 }",
		"\tif #sources == 0 then",
		"\t\treturn snapshot",
		"\tend",
		"\tlocal minPoint = sources[1].minPoint",
		"\tlocal maxPoint = sources[1].maxPoint",
		"\tlocal totalVolume = 0",
		"\tlocal largestVolume = 0",
		"\tfor _, source in ipairs(sources) do",
		"\t\tminPoint = Vector3.new(",
		"\t\t\tmath.min(minPoint.X, source.minPoint.X),",
		"\t\t\tmath.min(minPoint.Y, source.minPoint.Y),",
		"\t\t\tmath.min(minPoint.Z, source.minPoint.Z)",
		"\t\t)",
		"\t\tmaxPoint = Vector3.new(",
		"\t\t\tmath.max(maxPoint.X, source.maxPoint.X),",
		"\t\t\tmath.max(maxPoint.Y, source.maxPoint.Y),",
		"\t\t\tmath.max(maxPoint.Z, source.maxPoint.Z)",
		"\t\t)",
		"\t\tlocal volume = math.max(source.size.X, 0.05) * math.max(source.size.Y, 0.05) * math.max(source.size.Z, 0.05)",
		"\t\ttotalVolume += volume",
		"\t\tlargestVolume = math.max(largestVolume, volume)",
		"\tend",
		"\tlocal bounds = maxPoint - minPoint",
		"\tlocal boundingVolume = math.max(bounds.X, 0.1) * math.max(bounds.Y, 0.1) * math.max(bounds.Z, 0.1)",
		"\tlocal occupancy = math.clamp(totalVolume / boundingVolume, 0, 1)",
		"\tlocal sortedAxes = {math.max(bounds.X, 0.1), math.max(bounds.Y, 0.1), math.max(bounds.Z, 0.1)}",
		"\ttable.sort(sortedAxes)",
		"\tlocal elongation = sortedAxes[3] / math.max(sortedAxes[1], 0.1)",
		"\tlocal dominantShare = largestVolume / math.max(totalVolume, 0.001)",
		"\tsnapshot.occupancy = occupancy",
		"\tsnapshot.elongation = elongation",
		"\tsnapshot.dominantShare = dominantShare",
		"\treturn snapshot",
		"end",
		"",
		"local function shouldUseMeshCollision(sources, resolvedMode)",
		"\tif resolvedMode ~= \"simple\" then",
		"\t\treturn false",
		"\tend",
		"\tif #sources == 0 then",
		"\t\treturn false",
		"\tend",
		"\tlocal meshCount = 0",
		"\tfor _, source in ipairs(sources) do",
		"\t\tif source.part and source.part:IsA(\"MeshPart\") then",
		"\t\t\tmeshCount = meshCount + 1",
		"\t\tend",
		"\tend",
		"\treturn meshCount > 0 and meshCount == #sources",
		"end",
		"",
		"local function buildMeshCollisionFolder(instance, anchored, sources)",
		"\tlocal folder = Instance.new(\"Folder\")",
		"\tfolder.Name = instance.Name .. \"_Collision\"",
		"\tfor index, source in ipairs(sources) do",
		"\t\tlocal part = source.part",
		"\t\tif part then",
		"\t\t\tlocal clone = part:Clone()",
		"\t\t\tclone.Name = (\"%s_MeshCollision_%d\"):format(instance.Name, index)",
		"\t\t\tclone.Transparency = 1",
		"\t\t\tclone.Anchored = anchored",
		"\t\t\tclone.CanCollide = true",
		"\t\t\tclone.CanTouch = true",
		"\t\t\tclone.CanQuery = true",
		"\t\t\tclone.CastShadow = false",
		"\t\t\tclone.Locked = true",
		"\t\t\tclone.Parent = folder",
		"\t\tend",
		"\tend",
		"\treturn folder",
		"end",
		"",
		"local function resolveColliderMode(instance, colliderMode)",
		"\tlocal normalizedMode = normalizeColliderMode(colliderMode)",
		"\tlocal sources = gatherCollisionSources(instance)",
		"\tif normalizedMode ~= \"ai\" then",
		"\t\treturn normalizedMode, sources, false, buildCollisionSnapshot(sources, normalizedMode)",
		"\tend",
		"\tif #sources == 0 then",
		"\t\treturn \"medium\", sources, true, buildCollisionSnapshot(sources, \"medium\")",
		"\tend",
		"\tlocal resolved = inferColliderModeFromSources(sources)",
		"\treturn resolved, sources, true, buildCollisionSnapshot(sources, resolved)",
		"end",
		"",
		"local function getClosestAABBDistance(first, second)",
		"\tlocal dx = math.max(0, first.minPoint.X - second.maxPoint.X, second.minPoint.X - first.maxPoint.X)",
		"\tlocal dy = math.max(0, first.minPoint.Y - second.maxPoint.Y, second.minPoint.Y - first.maxPoint.Y)",
		"\tlocal dz = math.max(0, first.minPoint.Z - second.maxPoint.Z, second.minPoint.Z - first.maxPoint.Z)",
		"\treturn math.sqrt(dx * dx + dy * dy + dz * dz)",
		"end",
		"",
		"local function buildColliderClusters(sources, colliderMode)",
		"\tlocal thresholdByMode = { simple = math.huge, medium = 2.5, detailed = 0.35 }",
		"\tlocal threshold = thresholdByMode[colliderMode] or thresholdByMode.medium",
		"\tlocal parents = {}",
		"\tfor index = 1, #sources do",
		"\t\tparents[index] = index",
		"\tend",
		"\tlocal function find(index)",
		"\t\twhile parents[index] ~= index do",
		"\t\t\tparents[index] = parents[parents[index]]",
		"\t\t\tindex = parents[index]",
		"\t\tend",
		"\t\treturn index",
		"\tend",
		"\tlocal function union(a, b)",
		"\t\tlocal rootA = find(a)",
		"\t\tlocal rootB = find(b)",
		"\t\tif rootA ~= rootB then",
		"\t\t\tparents[rootB] = rootA",
		"\t\tend",
		"\tend",
		"\tfor left = 1, #sources do",
		"\t\tfor right = left + 1, #sources do",
		"\t\t\tif getClosestAABBDistance(sources[left], sources[right]) <= threshold then",
		"\t\t\t\tunion(left, right)",
		"\t\t\tend",
		"\t\tend",
		"\tend",
		"\tlocal grouped = {}",
		"\tfor index, source in ipairs(sources) do",
		"\t\tlocal root = find(index)",
		"\t\tlocal group = grouped[root]",
		"\t\tif not group then",
		"\t\t\tgroup = { minPoint = source.minPoint, maxPoint = source.maxPoint, count = 0 }",
		"\t\t\tgrouped[root] = group",
		"\t\telse",
		"\t\t\tgroup.minPoint = Vector3.new(",
		"\t\t\t\tmath.min(group.minPoint.X, source.minPoint.X),",
		"\t\t\t\tmath.min(group.minPoint.Y, source.minPoint.Y),",
		"\t\t\t\tmath.min(group.minPoint.Z, source.minPoint.Z)",
		"\t\t\t)",
		"\t\t\tgroup.maxPoint = Vector3.new(",
		"\t\t\t\tmath.max(group.maxPoint.X, source.maxPoint.X),",
		"\t\t\t\tmath.max(group.maxPoint.Y, source.maxPoint.Y),",
		"\t\t\t\tmath.max(group.maxPoint.Z, source.maxPoint.Z)",
		"\t\t\t)",
		"\t\tend",
		"\t\tgroup.count += 1",
		"\tend",
		"\tlocal clusters = {}",
		"\tfor _, group in pairs(grouped) do",
		"\t\ttable.insert(clusters, group)",
		"\tend",
		"\treturn clusters",
		"end",
		"",
		"local function createCollisionProxies(instance, anchored, colliderMode)",
		"\tlocal requestedMode = normalizeColliderMode(colliderMode)",
		"\tlocal resolvedMode, sources, autoResolved, _ = resolveColliderMode(instance, colliderMode)",
		"\tif autoResolved and shouldUseMeshCollision(sources, resolvedMode) then",
		"\t\tlocal meshFolder = buildMeshCollisionFolder(instance, anchored, sources)",
		"\t\tmeshFolder:SetAttribute(\"DetailedModelRequestedColliderMode\", requestedMode)",
		"\t\tmeshFolder:SetAttribute(\"DetailedModelResolvedColliderMode\", resolvedMode)",
		"\t\treturn meshFolder",
		"\tend",
		"\tlocal proxyFolder = Instance.new(\"Folder\")",
		"\tproxyFolder.Name = instance.Name .. \"_Collision\"",
		"\tproxyFolder:SetAttribute(\"DetailedModelRequestedColliderMode\", requestedMode)",
		"\tproxyFolder:SetAttribute(\"DetailedModelResolvedColliderMode\", resolvedMode)",
		"\tif resolvedMode == \"simple\" then",
		"\t\tlocal cframe, size",
		"\t\tif instance:IsA(\"Model\") then",
		"\t\t\tcframe, size = instance:GetBoundingBox()",
		"\t\telseif instance:IsA(\"BasePart\") then",
		"\t\t\tcframe, size = instance.CFrame, instance.Size",
		"\t\telse",
		"\t\t\tcframe, size = CFrame.new(), Vector3.new(4, 4, 4)",
		"\t\tend",
		"\t\taddProxyPart(proxyFolder, instance.Name .. \"_CollisionProxy\", size, cframe, anchored)",
		"\t\treturn proxyFolder",
		"\tend",
		"\tif #sources == 0 then",
		"\t\treturn proxyFolder",
		"\tend",
		"\tlocal clusters = buildColliderClusters(sources, resolvedMode)",
		"\tfor index, cluster in ipairs(clusters) do",
		"\t\tlocal size = cluster.maxPoint - cluster.minPoint",
		"\t\tlocal center = (cluster.minPoint + cluster.maxPoint) * 0.5",
		"\t\taddProxyPart(",
		"\t\t\tproxyFolder,",
		"\t\t\tstring.format(\"%s_CollisionProxy_%d\", instance.Name, index),",
		"\t\t\tVector3.new(math.max(size.X, 0.1), math.max(size.Y, 0.1), math.max(size.Z, 0.1)),",
		"\t\t\tCFrame.new(center),",
		"\t\t\tanchored",
		"\t\t)",
		"\tend",
		"\treturn proxyFolder",
		"end",
		"",
		"local function getFolder(name)",
		"\tlocal folder = ServerStorage:FindFirstChild(name)",
		"\tif not folder then",
		"\t\tfolder = Instance.new(\"Folder\")",
		"\t\tfolder.Name = name",
		"\t\tfolder.Parent = ServerStorage",
		"\tend",
		"\treturn folder",
		"end",
		"",
		"local function getValue(request, className, name, fallback)",
		"\tlocal value = request:FindFirstChild(name)",
		"\tif value and value.ClassName == className then",
		"\t\treturn value.Value",
		"\tend",
		"\treturn fallback",
		"end",
		"",
		"local function deserializeCFrame(serialized)",
		"\tlocal components = {}",
		"\tfor piece in string.gmatch(serialized or \"\", \"[^,]+\") do",
		"\t\tcomponents[#components + 1] = tonumber(piece)",
		"\tend",
		"\tif #components == 12 then",
		"\t\treturn CFrame.new(unpack(components))",
		"\tend",
		"\treturn CFrame.new()",
		"end",
		"",
		"local function getInstanceScale(instance)",
		"\tif instance and instance:IsA(\"Model\") then",
		"\t\tlocal success, scale = pcall(function()",
		"\t\t\treturn instance:GetScale()",
		"\t\tend)",
		"\t\tif success and type(scale) == \"number\" and scale > 0 then",
		"\t\t\treturn scale",
		"\t\tend",
		"\tend",
		"\treturn 1",
		"end",
		"",
		"local function applyScale(instance, scale)",
		"\tif instance and instance:IsA(\"Model\") and type(scale) == \"number\" and scale > 0 then",
		"\t\tpcall(function()",
		"\t\t\tinstance:ScaleTo(scale)",
		"\t\tend)",
		"\tend",
		"end",
		"",
		"local function applyPivot(instance, pivot)",
		"\tif instance:IsA(\"Model\") then",
		"\t\tinstance:PivotTo(pivot)",
		"\telseif instance:IsA(\"BasePart\") then",
		"\t\tinstance.CFrame = pivot",
		"\tend",
		"end",
		"",
		"local function applyBasePreferenceToPrompt(prompt, includeBase)",
		"\tif includeBase then",
		"\t\treturn prompt",
		"\tend",
		"\treturn table.concat({",
		"\t\tprompt,",
		"\t\t\"no base\",",
		"\t\t\"no baseplate\",",
		"\t\t\"no foundation slab\",",
		"\t\t\"no pedestal\",",
		"\t\t\"building only\",",
		"\t}, \"\\n\")",
		"end",
		"",
		"local function processRequest(request)",
		"\tlocal prompt = getValue(request, \"StringValue\", \"Prompt\", \"\")",
		"\tif prompt == \"\" then",
		"\t\twarn(\"DetailedModel runtime request missing prompt: \" .. request.Name)",
		"\t\treturn",
		"\tend",
		"",
		"\tlocal size = getValue(request, \"NumberValue\", \"TargetSize\", 24)",
		"\tlocal triangles = getValue(request, \"NumberValue\", \"MaxTriangles\", 20000)",
		"\tlocal textures = getValue(request, \"BoolValue\", \"GenerateTextures\", true)",
		"\tlocal includeBase = getValue(request, \"BoolValue\", \"IncludeBase\", true)",
		"\tlocal anchored = getValue(request, \"BoolValue\", \"Anchored\", true)",
		"\tlocal schemaName = getValue(request, \"StringValue\", \"Schema\", \"Body1\")",
		"\tlocal seed = getValue(request, \"StringValue\", \"Seed\", \"\")",
		"\tlocal colliderMode = normalizeColliderMode(getValue(request, \"StringValue\", \"ColliderMode\", \"ai\"))",
		"\tlocal modelScale = getValue(request, \"NumberValue\", \"ModelScale\", 1)",
		"\tlocal pivot = deserializeCFrame(getValue(request, \"StringValue\", \"Pivot\", \"\"))",
		"",
		"\tlocal outputFolder = workspace:FindFirstChild(OUTPUT_FOLDER_NAME)",
		"\tif not outputFolder then",
		"\t\toutputFolder = Instance.new(\"Folder\")",
		"\t\toutputFolder.Name = OUTPUT_FOLDER_NAME",
		"\t\toutputFolder.Parent = workspace",
		"\tend",
		"\tprompt = applyBasePreferenceToPrompt(prompt, includeBase)",
		"\tlocal seededPrompt = prompt",
		"\tif seed ~= \"\" then",
		"\t\tseededPrompt = string.format(\"%s\\nvariation-seed:%s\", prompt, seed)",
		"\tend",
		"\tlocal inputs = {",
		"\t\tTextPrompt = seededPrompt,",
		"\t\tSize = Vector3.new(size, size, size),",
		"\t\tMaxTriangles = triangles,",
		"\t\tGenerateTextures = textures,",
		"\t}",
		"\tlocal schema = { PredefinedSchema = schemaName }",
		"",
		"\tlocal success, generatedModel = pcall(function()",
		"\t\treturn GenerationService:GenerateModelAsync(inputs, schema)",
		"\tend)",
		"",
		"\tif not success or typeof(generatedModel) ~= \"Instance\" then",
		"\t\twarn(\"DetailedModel runtime generation failed: \" .. tostring(generatedModel))",
		"\t\treturn",
		"\tend",
		"",
		"\tgeneratedModel.Name = request.Name",
		"\tgeneratedModel.Parent = outputFolder",
		"\tapplyAnchoredState(generatedModel, anchored)",
		"\tconfigureVisualParts(generatedModel, anchored)",
		"\tapplyScale(generatedModel, modelScale)",
		"\tapplyPivot(generatedModel, pivot)",
		"\tlocal storedModelsFolder = getFolder(STORED_MODELS_FOLDER_NAME)",
		"\tlocal storedModel = storedModelsFolder:FindFirstChild(request.Name)",
		"\tif storedModel then",
		"\t\tlocal collisionModel = storedModel:Clone()",
		"\t\tcollisionModel.Name = request.Name .. \"_Collision\"",
		"\t\tcollisionModel.Parent = generatedModel",
		"\telse",
		"\t\tlocal proxyFolder = createCollisionProxies(generatedModel, anchored, colliderMode)",
		"\t\tproxyFolder.Name = request.Name .. \"_Collision\"",
		"\t\tproxyFolder.Parent = generatedModel",
		"\tend",
		"end",
		"",
		"local requestsFolder = getFolder(REQUESTS_FOLDER_NAME)",
		"local outputFolder = workspace:FindFirstChild(OUTPUT_FOLDER_NAME)",
		"if not outputFolder then",
		"\toutputFolder = Instance.new(\"Folder\")",
		"\toutputFolder.Name = OUTPUT_FOLDER_NAME",
		"\toutputFolder.Parent = workspace",
		"end",
		"",
		"for _, child in ipairs(outputFolder:GetChildren()) do",
		"\tchild:Destroy()",
		"end",
		"",
		"for _, request in ipairs(requestsFolder:GetChildren()) do",
		"\tprocessRequest(request)",
		"end",
	}, "\n")
end

function setValue(parent, className, name, value)
	local instance = parent:FindFirstChild(name)
	if not instance or instance.ClassName ~= className then
		if instance then
			instance:Destroy()
		end
		instance = Instance.new(className)
		instance.Name = name
		instance.Parent = parent
	end
	instance.Value = value
end

function installRuntimeManagerAndRequest(request, generatedModel)
	local scriptName = "DetailedModelRuntimeGenerate"
	local runtimeScript = ServerScriptService:FindFirstChild(scriptName)
	if not runtimeScript then
		runtimeScript = Instance.new("Script")
		runtimeScript.Name = scriptName
		runtimeScript.Parent = ServerScriptService
	end
	runtimeScript.Source = buildRuntimeManagerSource()

	local requestsFolder = ServerStorage:FindFirstChild("DetailedModelRuntimeRequests")
	if not requestsFolder then
		requestsFolder = Instance.new("Folder")
		requestsFolder.Name = "DetailedModelRuntimeRequests"
		requestsFolder.Parent = ServerStorage
	end

	local requestFolder = requestsFolder:FindFirstChild(generatedModel.Name)
	if not requestFolder then
		requestFolder = Instance.new("Folder")
		requestFolder.Name = generatedModel.Name
		requestFolder.Parent = requestsFolder
	end

	setValue(requestFolder, "StringValue", "Prompt", request.prompt)
	setValue(requestFolder, "NumberValue", "TargetSize", request.targetSize)
	setValue(requestFolder, "NumberValue", "MaxTriangles", request.maxTriangles)
	setValue(requestFolder, "BoolValue", "GenerateTextures", request.textures)
	setValue(requestFolder, "BoolValue", "IncludeBase", request.includeBase)
	setValue(requestFolder, "BoolValue", "Anchored", request.anchored)
	setValue(requestFolder, "StringValue", "Schema", request.schemaName)
	setValue(requestFolder, "StringValue", "Seed", request.seed or "")
	setValue(requestFolder, "StringValue", "ColliderMode", request.colliderMode)
	setValue(requestFolder, "NumberValue", "ModelScale", getInstanceScale(generatedModel))
	setValue(requestFolder, "StringValue", "Pivot", serializeCFrame(getInstancePivot(generatedModel)))

	local storedModelsFolder = ServerStorage:FindFirstChild("DetailedModelStoredModels")
	if not storedModelsFolder then
		storedModelsFolder = Instance.new("Folder")
		storedModelsFolder.Name = "DetailedModelStoredModels"
		storedModelsFolder.Parent = ServerStorage
	end

	local existingCollisionModel = getGeneratedCollisionContainer(generatedModel)
	local storedModel
	if existingCollisionModel then
		storedModel = existingCollisionModel:Clone()
	else
		storedModel = createCollisionProxies(generatedModel, request.anchored, request.colliderMode)
	end
	storedModel.Name = generatedModel.Name
	local existingStoredProxy = storedModelsFolder:FindFirstChild(storedModel.Name)
	if existingStoredProxy then
		existingStoredProxy:Destroy()
	end
	storedModel.Parent = storedModelsFolder

	local backupFolder = ServerStorage:FindFirstChild("DetailedModelPreviewBackups")
	if not backupFolder then
		backupFolder = Instance.new("Folder")
		backupFolder.Name = "DetailedModelPreviewBackups"
		backupFolder.Parent = ServerStorage
	end

	generatedModel.Parent = backupFolder
	return requestFolder
end

function getSingleSelection()
	local selection = Selection:Get()
	if #selection == 1 then
		return selection[1]
	end
	return nil
end

function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

function isGeneratedDetailedModel(instance)
	if not instance then
		return false
	end

	if instance:IsA("Model") or instance:IsA("MeshPart") then
		local promptAttribute = instance:GetAttribute("DetailedModelPrompt")
		return type(promptAttribute) == "string" and promptAttribute ~= ""
	end

	return false
end

function collectGeneratedDetailedModels()
	local results = {}
	local seen = {}

	local function addCandidate(instance)
		if isGeneratedDetailedModel(instance) and not seen[instance] then
			seen[instance] = true
			table.insert(results, instance)
		end
	end

	for _, descendant in ipairs(workspace:GetDescendants()) do
		addCandidate(descendant)
	end

	return results
end

function buildRequestFromAttributes(instance)
	local prompt = instance:GetAttribute("DetailedModelPrompt")
	if type(prompt) ~= "string" or prompt == "" then
		return nil
	end

	local request = {
		prompt = prompt,
		targetSize = instance:GetAttribute("DetailedModelTargetSize") or 24,
		maxTriangles = instance:GetAttribute("DetailedModelMaxTriangles") or 20000,
		textures = instance:GetAttribute("DetailedModelGenerateTextures"),
		includeBase = instance:GetAttribute("DetailedModelIncludeBase"),
		anchored = instance:GetAttribute("DetailedModelAnchored"),
		schemaName = instance:GetAttribute("DetailedModelSchema") or "Body1",
		seed = tostring(instance:GetAttribute("DetailedModelSeed") or ""),
		colliderMode = normalizeColliderMode(instance:GetAttribute("DetailedModelColliderMode") or "ai"),
		modelScale = getInstanceScale(instance),
	}

	if request.textures == nil then
		request.textures = true
	end
	if request.includeBase == nil then
		request.includeBase = true
	end
	if request.anchored == nil then
		request.anchored = true
	end

	return request
end

function applyPreset(targetSize, maxTriangles, collisionPresetName)
	ui.sizeBox.Text = tostring(targetSize)
	ui.trianglesBox.Text = tostring(maxTriangles)
	if collisionPresetName then
		applyCollisionHeuristicPreset(collisionPresetName)
	end
	renderRequestPreview(buildRequest())
end

function generateDetailedModel()
	if busy then
		return
	end
	pendingStoreAllConfirmation = false

	local request = buildRequest()
	local valid, message = validateRequest(request)
	if not valid then
		setStatus(message, "error")
		return
	end

	saveInputs(
		request.prompt,
		request.targetSize,
		request.maxTriangles,
		request.textures,
		request.includeBase,
		request.anchored,
		request.schemaName,
		request.colliderMode,
		request.seed
	)

	local parentTarget = getInsertionParent()
	setBusyState(true)
	setStatus("Submitting request to Roblox Cube 3D...", "info")
	ChangeHistoryService:SetWaypoint("Before Detailed Model Generate")

	local generatedModel = loadCachedVisualModel(request)
	local success = true
	local metadataOrError
	local usedCache = generatedModel ~= nil

	if not generatedModel then
		success, generatedModel, metadataOrError = pcall(function()
			return GenerationService:GenerateModelAsync(request.inputs, request.schema)
		end)
	end

	if not success then
		setBusyState(false)
		setStatus("Generation failed: " .. tostring(generatedModel), "error")
		return
	end

	if typeof(generatedModel) ~= "Instance" then
		setBusyState(false)
		setStatus("Generation returned no model instance. Response: " .. tostring(generatedModel), "error")
		return
	end

	generatedModel.Name = getPromptName(request.prompt)
	generatedModel.Parent = parentTarget
	generatedModel:SetAttribute("DetailedModelPrompt", request.prompt)
	generatedModel:SetAttribute("DetailedModelTargetSize", request.targetSize)
	generatedModel:SetAttribute("DetailedModelMaxTriangles", request.maxTriangles)
	generatedModel:SetAttribute("DetailedModelGenerateTextures", request.textures)
	generatedModel:SetAttribute("DetailedModelIncludeBase", request.includeBase)
	generatedModel:SetAttribute("DetailedModelAnchored", request.anchored)
	generatedModel:SetAttribute("DetailedModelSchema", request.schemaName)
	generatedModel:SetAttribute("DetailedModelSeed", request.seed)
	generatedModel:SetAttribute("DetailedModelColliderMode", request.colliderMode)
	generatedModel:SetAttribute("DetailedModelScale", getInstanceScale(generatedModel))
	applyAnchoredState(generatedModel, request.anchored)
	clearGeneratedTextureReferences(generatedModel)
	storeCachedVisualModel(request, generatedModel)
	captureCollisionData(generatedModel, request.colliderMode)
	attachGeneratedCollisionModel(parentTarget, generatedModel, request)
	pushPromptHistory(request.prompt)
	refreshPromptHistoryButtons()

	if generatedModel:IsA("Model") then
		pcall(function()
			if request.groundSnap then
				applyGroundSnapAtOrigin(generatedModel)
			else
				generatedModel:PivotTo(CFrame.new())
			end
		end)
	elseif request.groundSnap and generatedModel:IsA("BasePart") then
		pcall(function()
			applyGroundSnapAtOrigin(generatedModel)
		end)
	end

	Selection:Set({generatedModel})
	ChangeHistoryService:SetWaypoint("After Detailed Model Generate")

	if autoOpenPreviewEnabled then
		local previewClone = generatedModel:Clone()
	loadModelIntoPreview(previewClone, request.colliderMode, usedCache and "Generated model and opened a cached preview clone." or "Generated model and opened it in the preview window.", request)
	end

	local partCount = countParts(generatedModel)
	local metadataNote = metadataOrError and (" Metadata: " .. tostring(metadataOrError)) or ""
	local cacheNote = usedCache and " Loaded from cache." or ""
	setBusyState(false)
	setStatus(
		("Generated %s with %d part(s). Parent: %s.%s"):format(
			generatedModel.Name,
			partCount,
			parentTarget:GetFullName(),
			metadataNote .. cacheNote
		),
		"success"
	)
end

function fixSelectedForPlay()
	if busy then
		return
	end
	pendingStoreAllConfirmation = false

	local selected = getSingleSelection()
	if not selected then
		setStatus("Select exactly one generated model or mesh before using Store Selected Model.", "error")
		return
	end

	local request = buildRequest()
	if isGeneratedDetailedModel(selected) then
		request = buildRequestFromAttributes(selected) or request
	end
	request.inputs = {
		TextPrompt = request.prompt,
		Size = Vector3.new(request.targetSize, request.targetSize, request.targetSize),
		MaxTriangles = request.maxTriangles,
		GenerateTextures = request.textures,
	}
	request.schema = {
		PredefinedSchema = request.schemaName,
	}
	local valid, message = validateRequest(request)
	if not valid then
		setStatus(message, "error")
		return
	end

	local requestFolder = installRuntimeManagerAndRequest(request, selected)
	setStatus(
		"Added runtime regeneration for " .. requestFolder.Name ..
		". The current preview was moved to ServerStorage/DetailedModelPreviewBackups and a fresh model will be generated during Play.",
		"success"
	)
end

function fixAllForPlay()
	if busy then
		return
	end

	if confirmStoreAllEnabled and not pendingStoreAllConfirmation then
		pendingStoreAllConfirmation = true
		setStatus("Press Store All Models again to confirm storing every generated model.", "info")
		return
	end
	pendingStoreAllConfirmation = false

	local candidates = collectGeneratedDetailedModels()
	if #candidates == 0 then
		setStatus("No generated detailed models were found in Workspace.", "error")
		return
	end

	local fixedCount = 0
	for _, candidate in ipairs(candidates) do
		local request = buildRequestFromAttributes(candidate)
		if request then
			installRuntimeManagerAndRequest(request, candidate)
			fixedCount += 1
		end
	end

	if fixedCount == 0 then
		setStatus("Generated models were found, but none had saved prompt metadata to store for Play.", "error")
		return
	end

	setStatus(
		("Stored %d generated model(s) for runtime regeneration. Previews were moved to ServerStorage/DetailedModelPreviewBackups."):format(fixedCount),
		"success"
	)
end

function toggleStoredModels()
	if busy then
		return
	end
	pendingStoreAllConfirmation = false

	local backupFolder = ServerStorage:FindFirstChild("DetailedModelPreviewBackups")
	local workspaceFolder = workspace:FindFirstChild("DetailedModelEditableModels")

	if backupFolder and #backupFolder:GetChildren() > 0 then
		if not workspaceFolder then
			workspaceFolder = Instance.new("Folder")
			workspaceFolder.Name = "DetailedModelEditableModels"
			workspaceFolder.Parent = workspace
		end

		local movedCount = 0
		for _, child in ipairs(backupFolder:GetChildren()) do
			child.Parent = workspaceFolder
			movedCount += 1
		end

		setStatus(
			("Pulled %d stored model(s) into Workspace/DetailedModelEditableModels for editing. Press Toggle Stored again to store and reapply them."):format(movedCount),
			"success"
		)
		updateToggleStorageButton()
		return
	end

	if not workspaceFolder or #workspaceFolder:GetChildren() == 0 then
		setStatus("No stored models were found in ServerStorage and no editable models were found in Workspace.", "error")
		updateToggleStorageButton()
		return
	end

	backupFolder = getOrCreateFolder(ServerStorage, "DetailedModelPreviewBackups")

	local storedCount = 0
	for _, child in ipairs(workspaceFolder:GetChildren()) do
		local request = buildRequestFromAttributes(child)
		if request then
			installRuntimeManagerAndRequest(request, child)
			storedCount += 1
		else
			child.Parent = backupFolder
		end
	end

	if #workspaceFolder:GetChildren() == 0 then
		workspaceFolder:Destroy()
	end

	if storedCount == 0 then
		setStatus("Editable models were moved back to storage, but none had saved generator metadata for runtime regeneration.", "error")
		updateToggleStorageButton()
		return
	end

	setStatus(
		("Stored %d editable model(s) back into ServerStorage and refreshed their Play-mode runtime regeneration."):format(storedCount),
		"success"
	)
	updateToggleStorageButton()
end

function updateToggleStorageButton()
	if not ui.toggleStorageButton then
		return
	end

	local workspaceFolder = workspace:FindFirstChild("DetailedModelEditableModels")
	local hasEditableModels = workspaceFolder and #workspaceFolder:GetChildren() > 0

	if hasEditableModels then
		ui.toggleStorageButton.Text = "Store All Rendered Models"
		setButtonThemeRole(ui.toggleStorageButton, "warning")
	else
		ui.toggleStorageButton.Text = "Show Stored Models"
		setButtonThemeRole(ui.toggleStorageButton, "accent")
	end
end

function updateResponsiveLayouts()
	local mainWidth = widget.AbsoluteSize.X
	if mainWidth > 0 then
		applyAdaptiveGrid(ui.presetFrame, ui.presetLayout, 3, 92, 36, 8, 8, 0)
		applyAdaptiveGrid(ui.settingsFrame, ui.settingsLayout, 2, 138, 40, 8, 8, 24)
		applyAdaptiveGrid(ui.buttonFrame, ui.buttonLayout, 3, 94, 38, 8, 8, 12)
		applyAdaptiveGrid(collisionTuningFrame, collisionTuningLayout, 2, 138, 40, 8, 8, 24)

		if mainWidth < 330 then
			ui.seedFrame.Size = UDim2.new(1, 0, 0, 88)
			ui.seedBox.Size = UDim2.new(1, 0, 0, 40)
			ui.seedBox.Position = UDim2.new(0, 0, 0, 0)
			ui.randomSeedButton.Size = UDim2.new(1, 0, 0, 40)
			ui.randomSeedButton.Position = UDim2.new(0, 0, 0, 48)
		else
			ui.seedFrame.Size = UDim2.new(1, 0, 0, 40)
			ui.seedBox.Size = UDim2.new(0.68, -4, 1, 0)
			ui.seedBox.Position = UDim2.new(0, 0, 0, 0)
			ui.randomSeedButton.Size = UDim2.new(0.32, -4, 1, 0)
			ui.randomSeedButton.Position = UDim2.new(0.68, 8, 0, 0)
		end
	end

	local previewWidth = previewWidget.AbsoluteSize.X
	if previewWidth > 0 then
		applyAdaptiveGrid(previewControls, previewControlsLayout, 2, 240, 42, 8, 8, 24)
	end
end

function updateThemeSelector()
	themeUi.dropdownButton.Text = "Browse UI Themes"
	if themeUi.currentThemeLabel then
		themeUi.currentThemeLabel.Text = "Current UI Theme: " .. themeState.name
	end
	if themeUi.categoryLabel then
		local isStyled = themeState.variant ~= "Default"
			or themeState.tone ~= "Default"
			or themeState.contrast ~= "Balanced"
			or themeState.typography ~= "Theme Default"
		themeUi.categoryLabel.Text = "Category: " .. getThemeCategory(themeState.name) .. (isStyled and " | Styled" or "")
	end
	for themeName, optionButton in pairs(themeUi.optionButtons) do
		if themeName == themeState.name then
			setButtonThemeRole(optionButton, "active")
		else
			setButtonThemeRole(optionButton, "secondary")
		end
	end
	if themeUi.variantButton then
		themeUi.variantButton.Text = "Theme Variant: " .. themeState.variant
		setButtonThemeRole(themeUi.variantButton, themeState.variant == "Default" and "secondary" or "active")
	end
	if themeUi.toneButton then
		themeUi.toneButton.Text = "Theme Tone: " .. themeState.tone
		setButtonThemeRole(themeUi.toneButton, themeState.tone == "Default" and "accent" or "active")
	end
	if themeUi.contrastButton then
		themeUi.contrastButton.Text = "Theme Contrast: " .. themeState.contrast
		setButtonThemeRole(
			themeUi.contrastButton,
			themeState.contrast == "Punchy" and "warning" or (themeState.contrast == "Soft" and "muted" or "info")
		)
	end
	if themeUi.typographyButton then
		themeUi.typographyButton.Text = "Theme Typography: " .. themeState.typography
		setButtonThemeRole(themeUi.typographyButton, themeState.typography == "Theme Default" and "teal" or "active")
	end
	if themeUi.stylingSummaryLabel then
		themeUi.stylingSummaryLabel.Text = string.format(
			"Current styling stack: %s base + %s variant + %s tone + %s contrast + %s typography.",
			themeState.name,
			themeState.variant,
			themeState.tone,
			themeState.contrast,
			themeState.typography
		)
	end
	if themeUi.resetStylingButton then
		local isDefaultStack = themeState.variant == "Default"
			and themeState.tone == "Default"
			and themeState.contrast == "Balanced"
			and themeState.typography == "Theme Default"
		setButtonThemeRole(themeUi.resetStylingButton, isDefaultStack and "muted" or "warning")
	end
end

function updateSettingsButton()
	if not ui.cacheToggleButton then
		return
	end
	ui.cacheToggleButton.Text = cacheEnabled and "Cache: On" or "Cache: Off"
	setButtonThemeRole(ui.cacheToggleButton, cacheEnabled and "active" or "muted")
	if ui.autoOpenPreviewButton then
		ui.autoOpenPreviewButton.Text = autoOpenPreviewEnabled and "Auto-open Preview: On" or "Auto-open Preview: Off"
		setButtonThemeRole(ui.autoOpenPreviewButton, autoOpenPreviewEnabled and "active" or "muted")
	end
	if ui.showAdvancedCollisionButton then
		ui.showAdvancedCollisionButton.Text = showAdvancedCollisionTuning and "Advanced Collision Tuning: On" or "Advanced Collision Tuning: Off"
		setButtonThemeRole(ui.showAdvancedCollisionButton, showAdvancedCollisionTuning and "active" or "muted")
	end
	if ui.confirmStoreAllButton then
		ui.confirmStoreAllButton.Text = confirmStoreAllEnabled and "Confirm Store All: On" or "Confirm Store All: Off"
		setButtonThemeRole(ui.confirmStoreAllButton, confirmStoreAllEnabled and "active" or "muted")
	end
	if ui.experimentalStyleBiasButton then
		experimentalStyleBias = normalizeExperimentalStyleBias(experimentalStyleBias)
		ui.experimentalStyleBiasButton.Text = "Style Bias: " .. experimentalStyleBias
		setButtonThemeRole(ui.experimentalStyleBiasButton, experimentalStyleBias ~= "Off" and "active" or "secondary")
	end
	if ui.experimentalPreviewModeButton then
		experimentalPreviewMode = normalizeExperimentalPreviewMode(experimentalPreviewMode)
		ui.experimentalPreviewModeButton.Text = "Preview Mode: " .. experimentalPreviewMode
		setButtonThemeRole(ui.experimentalPreviewModeButton, experimentalPreviewMode == "Fast" and "warning" or (experimentalPreviewMode == "High Quality" and "active" or "info"))
	end
	if ui.experimentalGroundSnapButton then
		ui.experimentalGroundSnapButton.Text = experimentalGroundSnap and "Ground Snap at Origin: On" or "Ground Snap at Origin: Off"
		setButtonThemeRole(ui.experimentalGroundSnapButton, experimentalGroundSnap and "active" or "teal")
	end
end

function setCacheEnabled(enabled)
	cacheEnabled = enabled and true or false
	setSetting(SETTINGS.cacheEnabled, cacheEnabled)
	updateSettingsButton()
end

function refreshPromptHistoryButtons()
	if not ui.historyLogBox then
		return
	end
	local lines = {}
	for index, prompt in ipairs(recentPromptHistory) do
		local compact = tostring(prompt or ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
		if compact ~= "" then
			lines[#lines + 1] = string.format("[%d] %s", index, compact)
		end
	end
	ui.historyLogBox.Text = #lines > 0 and table.concat(lines, "\n") or "No recent prompts yet."
	refreshSettingsSearch()
end

function setAutoOpenPreviewEnabled(enabled)
	autoOpenPreviewEnabled = enabled and true or false
	setSetting(SETTINGS.autoOpenPreview, autoOpenPreviewEnabled)
	updateSettingsButton()
end

function setShowAdvancedCollisionTuningEnabled(enabled)
	showAdvancedCollisionTuning = enabled and true or false
	setSetting(SETTINGS.showAdvancedCollisionTuning, showAdvancedCollisionTuning)
	if collisionTuningFrame then
		collisionTuningFrame.Visible = showAdvancedCollisionTuning
	end
	updateSettingsButton()
	updateResponsiveLayouts()
end

function setConfirmStoreAllEnabled(enabled)
	confirmStoreAllEnabled = enabled and true or false
	setSetting(SETTINGS.confirmStoreAll, confirmStoreAllEnabled)
	pendingStoreAllConfirmation = false
	updateSettingsButton()
end

function cycleExperimentalStyleBias()
	local order = {"Off", "Realistic", "Stylized", "Hard Surface", "Organic", "Toy-like"}
	experimentalStyleBias = normalizeExperimentalStyleBias(experimentalStyleBias)
	for index, name in ipairs(order) do
		if name == experimentalStyleBias then
			experimentalStyleBias = order[(index % #order) + 1]
			break
		end
	end
	setSetting(SETTINGS.experimentalStyleBias, experimentalStyleBias)
	updateSettingsButton()
end

function cycleExperimentalPreviewMode()
	local order = {"Fast", "Balanced", "High Quality"}
	experimentalPreviewMode = normalizeExperimentalPreviewMode(experimentalPreviewMode)
	for index, name in ipairs(order) do
		if name == experimentalPreviewMode then
			experimentalPreviewMode = order[(index % #order) + 1]
			break
		end
	end
	setSetting(SETTINGS.experimentalPreviewMode, experimentalPreviewMode)
	updateSettingsButton()
end

function setExperimentalGroundSnap(enabled)
	experimentalGroundSnap = enabled and true or false
	setSetting(SETTINGS.experimentalGroundSnap, experimentalGroundSnap)
	updateSettingsButton()
end

function refreshThemeOptions()
	local query = string.lower(string.gsub(themeUi.searchBox.Text or "", "^%s+", ""))
	query = string.gsub(query, "%s+$", "")
	local visibleCount = 0
	local categoryMatches = {}

	for _, entry in ipairs(themeUi.optionOrder) do
		if entry.kind == "theme" then
			local themeName = entry.name
			local optionButton = themeUi.optionButtons[themeName]
			local searchable = string.lower(themeName .. " " .. entry.category)
			local isVisible = query == "" or string.find(searchable, query, 1, true) ~= nil
			optionButton.Visible = isVisible
			if isVisible then
				visibleCount += 1
				categoryMatches[entry.category] = true
			end
		end
	end

	for categoryName, headerLabel in pairs(themeUi.categoryHeaders) do
		headerLabel.Visible = query == "" or categoryMatches[categoryName] == true
		if headerLabel.Visible then
			visibleCount += 1
		end
	end

	local listHeight = math.min(math.max(visibleCount, 1) * 40 + math.max(visibleCount - 1, 0) * 6, 220)
	themeUi.optionsScroll.Size = UDim2.new(1, 0, 0, listHeight)
	themeUi.optionsFrame.Size = UDim2.new(1, 0, 0, listHeight + 56)
end

function setThemeMenuOpen(isOpen)
	themeUi.optionsFrame.Visible = isOpen
	settingsWidget.Enabled = false
	guideWidget.Enabled = false
	if isOpen then
		refreshThemeOptions()
	end
end

function setSettingsPanelOpen(isOpen)
	if not ui.settingsPanel then
		return
	end
	themeUi.optionsFrame.Visible = false
	settingsWidget.Enabled = isOpen
	guideWidget.Enabled = false
	if isOpen then
		refreshSettingsSearch()
	end
end

function setGuidePanelOpen(isOpen)
	themeUi.optionsFrame.Visible = false
	settingsWidget.Enabled = false
	guideWidget.Enabled = isOpen
end

OPEN_BUTTON.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	OPEN_BUTTON:SetActive(widget.Enabled)
end)

widget:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveLayouts)

previewWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not previewWidget.Enabled then
		setPreviewAutoRotate(false)
		previewDragging = false
		previewDragLastPosition = nil
		previewDragInput = nil
	end
end)

settingsWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
	if settingsWidget.Enabled then
		themeUi.optionsFrame.Visible = false
	end
end)

guideWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
	if guideWidget.Enabled then
		themeUi.optionsFrame.Visible = false
	end
end)

previewWidget:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveLayouts)

syncGenerationBooleanButtons()

ui.previewButton.MouseButton1Click:Connect(function()
	generateVisualPreview()
end)

ui.texturesToggleButton.MouseButton1Click:Connect(function()
	generationTexturesEnabled = not generationTexturesEnabled
	setSetting(SETTINGS.textures, generationTexturesEnabled)
	syncGenerationBooleanButtons()
	renderRequestPreview(buildRequest())
end)

ui.includeBaseToggleButton.MouseButton1Click:Connect(function()
	generationIncludeBaseEnabled = not generationIncludeBaseEnabled
	setSetting(SETTINGS.includeBase, generationIncludeBaseEnabled)
	syncGenerationBooleanButtons()
	renderRequestPreview(buildRequest())
end)

ui.anchoredToggleButton.MouseButton1Click:Connect(function()
	generationAnchoredEnabled = not generationAnchoredEnabled
	setSetting(SETTINGS.anchored, generationAnchoredEnabled)
	syncGenerationBooleanButtons()
	renderRequestPreview(buildRequest())
end)

ui.randomSeedButton.MouseButton1Click:Connect(function()
	ui.seedBox.Text = generateRandomSeed()
	renderRequestPreview(buildRequest())
end)

themeUi.dropdownButton.MouseButton1Click:Connect(function()
	setThemeMenuOpen(not themeUi.optionsFrame.Visible)
end)

ui.settingsButton.MouseButton1Click:Connect(function()
	setSettingsPanelOpen(not settingsWidget.Enabled)
end)

ui.guideButton.MouseButton1Click:Connect(function()
	setGuidePanelOpen(not guideWidget.Enabled)
end)

ui.cacheToggleButton.MouseButton1Click:Connect(function()
	setCacheEnabled(not cacheEnabled)
end)

ui.clearCacheButton.MouseButton1Click:Connect(function()
	local removed = clearVisualCache()
	setStatus(("Cleared %d cached model(s)."):format(removed), "success")
end)

ui.autoOpenPreviewButton.MouseButton1Click:Connect(function()
	setAutoOpenPreviewEnabled(not autoOpenPreviewEnabled)
end)

ui.showAdvancedCollisionButton.MouseButton1Click:Connect(function()
	setShowAdvancedCollisionTuningEnabled(not showAdvancedCollisionTuning)
end)

ui.confirmStoreAllButton.MouseButton1Click:Connect(function()
	setConfirmStoreAllEnabled(not confirmStoreAllEnabled)
end)

themeUi.variantButton.MouseButton1Click:Connect(function()
	setThemeVariant(cycleThemeChoice(themeState.variant, THEME_VARIANT_ORDER))
	updateThemeSelector()
end)

themeUi.toneButton.MouseButton1Click:Connect(function()
	setThemeTone(cycleThemeChoice(themeState.tone, THEME_TONE_ORDER))
	updateThemeSelector()
end)

themeUi.contrastButton.MouseButton1Click:Connect(function()
	setThemeContrast(cycleThemeChoice(themeState.contrast, THEME_CONTRAST_ORDER))
	updateThemeSelector()
end)

themeUi.typographyButton.MouseButton1Click:Connect(function()
	setThemeTypography(cycleThemeChoice(themeState.typography, THEME_TYPOGRAPHY_ORDER))
	updateThemeSelector()
end)

themeUi.resetStylingButton.MouseButton1Click:Connect(function()
	resetThemeStyling()
	updateThemeSelector()
end)

ui.experimentalNegativePromptBox.FocusLost:Connect(function()
	local cleaned = tostring(ui.experimentalNegativePromptBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	ui.experimentalNegativePromptBox.Text = cleaned
	setSetting(SETTINGS.experimentalNegativePrompt, cleaned)
end)

ui.experimentalStyleBiasButton.MouseButton1Click:Connect(function()
	cycleExperimentalStyleBias()
end)

ui.experimentalPreviewModeButton.MouseButton1Click:Connect(function()
	cycleExperimentalPreviewMode()
end)

ui.experimentalGroundSnapButton.MouseButton1Click:Connect(function()
	setExperimentalGroundSnap(not experimentalGroundSnap)
end)

themeUi.searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if themeUi.optionsFrame.Visible then
		refreshThemeOptions()
	end
end)

ui.settingsSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if ui.settingsPanel.Visible then
		refreshSettingsSearch()
	end
end)

for _, resultButton in ipairs(ui.settingsSearchResultButtons or {}) do
	resultButton.MouseButton1Click:Connect(function()
		local query = string.lower((ui.settingsSearchBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
		if query == "" then
			return
		end
		for _, shortcut in ipairs(ui.settingsSearchShortcuts) do
			if shortcut.target and shortcut.target.Parent and string.find(shortcut.keywords, query, 1, true) ~= nil then
				if resultButton.Text == shortcut.title then
					scrollSettingsTargetIntoView(shortcut.target)
					break
				end
			end
		end
	end)
end

for themeName, optionButton in pairs(themeUi.optionButtons) do
	optionButton.MouseButton1Click:Connect(function()
		applyTheme(themeName)
		updateThemeSelector()
		themeUi.searchBox.Text = ""
		setThemeMenuOpen(false)
	end)
end

for stepId, stepButton in pairs(ui.guideStepButtons) do
	stepButton.MouseButton1Click:Connect(function()
		focusGuideStep(stepId)
	end)
end

ui.generateButton.MouseButton1Click:Connect(generateDetailedModel)
ui.runtimeButton.MouseButton1Click:Connect(fixSelectedForPlay)
ui.runtimeAllButton.MouseButton1Click:Connect(fixAllForPlay)
ui.toggleStorageButton.MouseButton1Click:Connect(toggleStoredModels)
ui.closePreviewButton.MouseButton1Click:Connect(function()
	previewWidget.Enabled = false
	clearPreviewModel()
end)
ui.rotateLeftButton.MouseButton1Click:Connect(function()
	nudgePreviewCamera(math.rad(-12), 0)
end)
ui.rotateRightButton.MouseButton1Click:Connect(function()
	nudgePreviewCamera(math.rad(12), 0)
end)
ui.rotateUpButton.MouseButton1Click:Connect(function()
	nudgePreviewCamera(0, math.rad(8))
end)
ui.rotateDownButton.MouseButton1Click:Connect(function()
	nudgePreviewCamera(0, math.rad(-8))
end)
ui.zoomInButton.MouseButton1Click:Connect(function()
	zoomPreview(-math.max(previewOrbitRadius * 0.18, 1.5))
end)
ui.zoomOutButton.MouseButton1Click:Connect(function()
	zoomPreview(math.max(previewOrbitRadius * 0.18, 1.5))
end)
ui.autoRotateButton.MouseButton1Click:Connect(function()
	setPreviewAutoRotate(not previewAutoRotateEnabled)
end)
ui.resetViewButton.MouseButton1Click:Connect(function()
	resetPreviewCamera()
end)
ui.previewFrontButton.MouseButton1Click:Connect(function()
	setPreviewCameraPreset("Front")
end)
ui.previewSideButton.MouseButton1Click:Connect(function()
	setPreviewCameraPreset("Side")
end)
ui.previewTopButton.MouseButton1Click:Connect(function()
	setPreviewCameraPreset("Top")
end)
ui.previewIsoButton.MouseButton1Click:Connect(function()
	setPreviewCameraPreset("Iso")
end)
ui.previewLightingButton.MouseButton1Click:Connect(function()
	cyclePreviewLightingPreset()
end)
ui.previewBackgroundButton.MouseButton1Click:Connect(function()
	cyclePreviewBackgroundPreset()
end)
ui.previewRotateSpeedButton.MouseButton1Click:Connect(function()
	cyclePreviewRotateSpeed()
end)
ui.previewOriginMarkerButton.MouseButton1Click:Connect(function()
	previewShowOriginMarker = not previewShowOriginMarker
	syncPreviewOriginMarkerButton()
	updatePreviewDecorations()
end)
ui.previewBoundsButton.MouseButton1Click:Connect(function()
	previewShowBoundsOverlay = not previewShowBoundsOverlay
	syncPreviewBoundsButton()
	updatePreviewDecorations()
end)
ui.previewCollisionOpacityButton.MouseButton1Click:Connect(function()
	if previewCollisionOpacityMode == "Low" then
		previewCollisionOpacityMode = "Medium"
	elseif previewCollisionOpacityMode == "Medium" then
		previewCollisionOpacityMode = "High"
	else
		previewCollisionOpacityMode = "Low"
	end
	syncPreviewCollisionOpacityButton()
	if collisionPreviewEnabled then
		refreshCollisionHighlights()
	end
end)
ui.previewRefreshButton.MouseButton1Click:Connect(function()
	updatePreviewStats()
	updatePreviewDecorations()
	if collisionPreviewEnabled then
		refreshCollisionHighlights()
	end
end)

ui.mediumButton.MouseButton1Click:Connect(function()
	applyPreset(20, 10000, "medium")
end)

ui.highButton.MouseButton1Click:Connect(function()
	applyPreset(28, 16000, "high")
end)

ui.ultraButton.MouseButton1Click:Connect(function()
	applyPreset(32, 20000, "ultra")
end)

ui.colliderModeBox.FocusLost:Connect(function()
	local normalizedMode = normalizeColliderMode(ui.colliderModeBox.Text)
	ui.colliderModeBox.Text = normalizedMode
	setSetting(SETTINGS.colliderMode, normalizedMode)
	renderRequestPreview(buildRequest())
end)

applyTheme(themeState.name)
updateThemeSelector()
updateSettingsButton()
updateToggleStorageButton()
refreshPromptHistoryButtons()
refreshThemeOptions()
setThemeMenuOpen(false)
setSettingsPanelOpen(false)
setGuidePanelOpen(false)
updateResponsiveLayouts()
renderRequestPreview(buildRequest())
