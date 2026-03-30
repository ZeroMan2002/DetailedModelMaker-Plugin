-- Roblox Detailed Model Maker
-- Fresh Roblox Studio plugin for prompt-based detailed model generation with Cube 3D.

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local GenerationService = game:GetService("GenerationService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local TOOLBAR_ICON = "rbxassetid://108716578848650"
local PLUGIN_VERSION = "2026.03.30"
local PLUGIN_GITHUB_REPO = "ZeroMan2002/DetailedModelMaker-Plugin"
local PLUGIN_GITHUB_REPO_URL = "https://github.com/" .. PLUGIN_GITHUB_REPO
local PLUGIN_GITHUB_RELEASES_URL = PLUGIN_GITHUB_REPO_URL .. "/releases"
local PLUGIN_GITHUB_LATEST_RELEASE_API = "https://api.github.com/repos/" .. PLUGIN_GITHUB_REPO .. "/releases/latest"

local themeAudioState = {
	initialized = false,
	lastButtonAt = 0,
	soundSerial = 0,
}

local TOOLBAR = plugin:CreateToolbar("Detailed Models")
local OPEN_BUTTON = TOOLBAR:CreateButton(
	"Detailed Model",
	"Generate detailed Roblox models from a text prompt",
	TOOLBAR_ICON
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
	variationCount = "DetailedModelMaker_VariationCount",
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
	uiAudioEnabled = "DetailedModelMaker_UiAudioEnabled",
	uiAudioVolume = "DetailedModelMaker_UiAudioVolume",
	themeChangeAudioEnabled = "DetailedModelMaker_ThemeChangeAudioEnabled",
	themeChangeAudioVolume = "DetailedModelMaker_ThemeChangeAudioVolume",
	variationCompletionAudioEnabled = "DetailedModelMaker_VariationCompletionAudioEnabled",
	showAdvancedCollisionTuning = "DetailedModelMaker_ShowAdvancedCollisionTuning",
	confirmStoreAll = "DetailedModelMaker_ConfirmStoreAll",
	promptHistory = "DetailedModelMaker_PromptHistory",
	promptFavorites = "DetailedModelMaker_PromptFavorites",
	namePattern = "DetailedModelMaker_NamePattern",
	batchLayout = "DetailedModelMaker_BatchLayout",
	experimentalNegativePrompt = "DetailedModelMaker_ExperimentalNegativePrompt",
	experimentalScenePrompt = "DetailedModelMaker_ExperimentalScenePrompt",
	experimentalScenePromptEnabled = "DetailedModelMaker_ExperimentalScenePromptEnabled",
	experimentalStyleBias = "DetailedModelMaker_ExperimentalStyleBias",
	experimentalPreviewMode = "DetailedModelMaker_ExperimentalPreviewMode",
	experimentalGroundSnap = "DetailedModelMaker_ExperimentalGroundSnap",
	updateLatestReleaseTag = "DetailedModelMaker_UpdateLatestReleaseTag",
	updateLatestReleaseUrl = "DetailedModelMaker_UpdateLatestReleaseUrl",
	updateLatestReleasePublishedAt = "DetailedModelMaker_UpdateLatestReleasePublishedAt",
	updateLastCheckedAt = "DetailedModelMaker_UpdateLastCheckedAt",
	updateLastStatus = "DetailedModelMaker_UpdateLastStatus",
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
	{{"Matrix", rgb(18, 37, 24), rgb(3, 10, 5), rgb(56, 196, 96), rgb(162, 255, 174), rgb(49, 173, 104), rgb(112, 233, 146)}, "Sci-Fi & Shooters"},
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

function clampUnitNumber(value, fallback)
	local numeric = tonumber(value)
	if numeric == nil then
		numeric = fallback or 0
	end
	if numeric < 0 then
		return 0
	elseif numeric > 1 then
		return 1
	end
	return numeric
end

function legacyAudioSettingToEnabled(value, defaultEnabled)
	if type(value) == "number" then
		return value > 0
	end
	local mode = tostring(value or "")
	if mode == "Off" then
		return false
	elseif mode == "Low" or mode == "Medium" or mode == "High" then
		return true
	end
	return defaultEnabled == nil and true or (defaultEnabled == true)
end

function legacyAudioSettingToLevel(value, defaultLevel)
	if type(value) == "number" then
		return clampUnitNumber(value, defaultLevel or 0.72)
	end
	local mode = tostring(value or "")
	if mode == "Low" then
		return 0.35
	elseif mode == "High" then
		return 1
	elseif mode == "Off" then
		return defaultLevel or 0.72
	end
	return 0.72
end

local collisionPreviewEnabled = getBooleanSetting(SETTINGS.collisionPreview, false)
local cacheEnabled = getBooleanSetting(SETTINGS.cacheEnabled, false)
local autoOpenPreviewEnabled = getBooleanSetting(SETTINGS.autoOpenPreview, false)
local storedUiAudioVolumeSetting = getSetting(SETTINGS.uiAudioVolume, "Medium")
local storedThemeAudioVolumeSetting = getSetting(SETTINGS.themeChangeAudioVolume, "Medium")
local uiAudioEnabled = getBooleanSetting(SETTINGS.uiAudioEnabled, legacyAudioSettingToEnabled(storedUiAudioVolumeSetting, true))
local uiAudioVolumeLevel = legacyAudioSettingToLevel(storedUiAudioVolumeSetting, 0.72)
local themeChangeAudioEnabled = getBooleanSetting(SETTINGS.themeChangeAudioEnabled, legacyAudioSettingToEnabled(storedThemeAudioVolumeSetting, true))
local themeChangeAudioVolumeLevel = legacyAudioSettingToLevel(storedThemeAudioVolumeSetting, 0.72)
local variationCompletionAudioEnabled = getBooleanSetting(SETTINGS.variationCompletionAudioEnabled, true)
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
	name = tostring(getSetting(SETTINGS.theme, "Meadow")),
	current = nil,
	variant = normalizeThemeChoice(getSetting(SETTINGS.themeVariant, "Soft"), THEME_VARIANT_ORDER, "Soft"),
	tone = normalizeThemeChoice(getSetting(SETTINGS.themeTone, "Default"), THEME_TONE_ORDER, "Default"),
	contrast = normalizeThemeChoice(getSetting(SETTINGS.themeContrast, "Soft"), THEME_CONTRAST_ORDER, "Soft"),
	typography = normalizeThemeChoice(getSetting(SETTINGS.themeTypography, "Studio Sans"), THEME_TYPOGRAPHY_ORDER, "Studio Sans"),
}
if not THEMES[themeState.name] then
	themeState.name = "Meadow"
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

function setCornerRadius(instance, radius)
	if not instance then
		return
	end
	local corner = instance:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Parent = instance
	end
	corner.CornerRadius = UDim.new(0, radius or 10)
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
		playThemeUiSound("button_press", button)
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

function determineProceduralness(themeName, category)
	local score = 0.4
	local lowerThemeName = string.lower(themeName or "")
	if string.find(lowerThemeName, "matrix", 1, true)
		or string.find(lowerThemeName, "terminal", 1, true)
		or string.find(lowerThemeName, "neon", 1, true) then
		score = score + 0.25
	end
	if string.find(lowerThemeName, "blueprint", 1, true)
		or string.find(lowerThemeName, "arcade", 1, true) then
		score = score + 0.15
	end
	if category == "Sci-Fi & Shooters" or category == "Arcade & Indie" then
		score = score + 0.2
	end
	if category == "Studio & Utility" then
		score = score - 0.1
	end
	if string.len(lowerThemeName) > 12 then
		score = score + 0.05
	end
	return math.min(math.max(score, 0), 1)
end

function getButtonAppearanceProfile(themeName, role)
	local category = getThemeCategory(themeName)
	local lowerThemeName = string.lower(themeName or "")
	local lowerCategory = string.lower(category or "")
	local lowerRole = string.lower(tostring(role or "secondary"))
	local proceduralness = determineProceduralness(themeName, category)
	local conceptTag = "utility"
	if string.find(lowerThemeName, "matrix", 1, true) then
		conceptTag = "matrix"
	elseif string.find(lowerThemeName, "fallout", 1, true)
		or string.find(lowerThemeName, "terminal", 1, true)
		or string.find(lowerThemeName, "solarized", 1, true)
		or string.find(lowerThemeName, "monochrome", 1, true)
		or string.find(lowerThemeName, "blueprint", 1, true) then
		conceptTag = "terminal"
	elseif string.find(lowerThemeName, "arcade", 1, true)
		or string.find(lowerThemeName, "neon", 1, true)
		or string.find(lowerThemeName, "retro", 1, true)
		or string.find(lowerThemeName, "crt", 1, true)
		or string.find(lowerThemeName, "laser", 1, true)
		or string.find(lowerThemeName, "carnival", 1, true)
		or string.find(lowerThemeName, "toybox", 1, true)
		or string.find(lowerThemeName, "mario", 1, true)
		or string.find(lowerThemeName, "persona", 1, true) then
		conceptTag = "arcade"
	elseif string.find(lowerThemeName, "cyber", 1, true)
		or string.find(lowerThemeName, "synth", 1, true)
		or string.find(lowerThemeName, "hacker", 1, true)
		or string.find(lowerThemeName, "galaxy", 1, true)
		or string.find(lowerThemeName, "nebula", 1, true)
		or string.find(lowerThemeName, "prism", 1, true)
		or string.find(lowerThemeName, "future", 1, true)
		or string.find(lowerThemeName, "mass effect", 1, true)
		or string.find(lowerThemeName, "destiny", 1, true)
		or string.find(lowerThemeName, "portal", 1, true)
		or string.find(lowerThemeName, "helldivers", 1, true) then
		conceptTag = "cyber"
	elseif string.find(lowerThemeName, "forest", 1, true)
		or string.find(lowerThemeName, "moss", 1, true)
		or string.find(lowerThemeName, "pine", 1, true)
		or string.find(lowerThemeName, "jade", 1, true)
		or string.find(lowerThemeName, "aurora", 1, true)
		or string.find(lowerThemeName, "rainforest", 1, true)
		or string.find(lowerThemeName, "seafoam", 1, true)
		or string.find(lowerThemeName, "mint", 1, true)
		or string.find(lowerThemeName, "animal", 1, true)
		or string.find(lowerThemeName, "stardew", 1, true)
		or string.find(lowerThemeName, "terraria", 1, true)
		or string.find(lowerThemeName, "sea of thieves", 1, true) then
		conceptTag = "nature"
	elseif string.find(lowerThemeName, "noir", 1, true)
		or string.find(lowerThemeName, "obsidian", 1, true)
		or string.find(lowerThemeName, "dracula", 1, true)
		or string.find(lowerThemeName, "silent", 1, true)
		or string.find(lowerThemeName, "dead", 1, true)
		or string.find(lowerThemeName, "biohazard", 1, true)
		or string.find(lowerThemeName, "fog", 1, true)
		or string.find(lowerThemeName, "diablo", 1, true)
		or string.find(lowerThemeName, "ember", 1, true)
		or string.find(lowerThemeName, "lava", 1, true)
		or string.find(lowerThemeName, "doom", 1, true) then
		conceptTag = "horror"
	elseif string.find(lowerThemeName, "royal", 1, true)
		or string.find(lowerThemeName, "skyrim", 1, true)
		or string.find(lowerThemeName, "witcher", 1, true)
		or string.find(lowerThemeName, "zelda", 1, true)
		or string.find(lowerThemeName, "genshin", 1, true)
		or string.find(lowerThemeName, "starlight", 1, true)
		or string.find(lowerThemeName, "elden", 1, true)
		or string.find(lowerThemeName, "monster", 1, true)
		or string.find(lowerThemeName, "warcraft", 1, true)
		or string.find(lowerThemeName, "sapphire", 1, true) then
		conceptTag = "fantasy"
	elseif string.find(lowerThemeName, "valorant", 1, true)
		or string.find(lowerThemeName, "apex", 1, true)
		or string.find(lowerThemeName, "fortnite", 1, true)
		or string.find(lowerThemeName, "rainbow", 1, true)
		or string.find(lowerThemeName, "counter", 1, true)
		or string.find(lowerThemeName, "battlefield", 1, true)
		or string.find(lowerThemeName, "call of duty", 1, true)
		or string.find(lowerThemeName, "steel", 1, true)
		or string.find(lowerThemeName, "construction", 1, true)
		or string.find(lowerThemeName, "halo", 1, true) then
		conceptTag = "tactical"
	elseif string.find(lowerThemeName, "rocket", 1, true)
		or string.find(lowerThemeName, "speed", 1, true)
		or string.find(lowerThemeName, "turismo", 1, true)
		or string.find(lowerThemeName, "sunset", 1, true)
		or string.find(lowerThemeName, "turbo", 1, true)
		or string.find(lowerThemeName, "gran", 1, true)
		or string.find(lowerThemeName, "boardwalk", 1, true)
		or string.find(lowerThemeName, "harbor", 1, true)
		or string.find(lowerThemeName, "marina", 1, true)
		or string.find(lowerThemeName, "lagoon", 1, true) then
		conceptTag = "speed"
	elseif string.find(lowerCategory, "sci-fi", 1, true) then
		conceptTag = "cyber"
	elseif string.find(lowerCategory, "sandbox", 1, true) then
		conceptTag = "nature"
	elseif string.find(lowerCategory, "horror", 1, true) then
		conceptTag = "horror"
	elseif string.find(lowerCategory, "fantasy", 1, true) then
		conceptTag = "fantasy"
	elseif string.find(lowerCategory, "competitive", 1, true) then
		conceptTag = "tactical"
	elseif string.find(lowerCategory, "racing", 1, true) then
		conceptTag = "speed"
	elseif string.find(lowerCategory, "arcade", 1, true) then
		conceptTag = "arcade"
	end
	local key = lowerThemeName .. ":" .. lowerRole
	local hash = 0
	for index = 1, #key do
		hash = (hash + string.byte(key, index) * (index + 3)) % 100000
	end

	local profile = {
		conceptTag = conceptTag,
		proceduralness = proceduralness,
		cornerRadius = 8 + (hash % 7),
		strokeThickness = 1 + ((hash % 2 == 0) and 0 or 0.35),
		textInsetX = 6 + (hash % 3),
		textInsetY = 3 + (hash % 2),
		textureDensity = 0.9 + ((hash % 13) / 25),
		overlayBias = ((hash % 17) / 100),
		bevelDepth = 0.12 + ((hash % 8) / 100),
		textShadowOffsetX = 0,
		textShadowOffsetY = 1,
		textShadowTransparency = 0.78,
	}

	if conceptTag == "matrix" then
		profile.cornerRadius = 4
		profile.strokeThickness = 1.3
		profile.textInsetX = 8
		profile.textInsetY = 4
		profile.textureDensity = 1.35
		profile.textShadowOffsetX = 1
		profile.textShadowOffsetY = 0
		profile.textShadowTransparency = 0.86
	elseif conceptTag == "terminal" then
		profile.cornerRadius = string.find(lowerThemeName, "blueprint", 1, true) and 6 or 5
		profile.strokeThickness = 1.2
		profile.textInsetX = 8
		profile.textInsetY = 4
		profile.textureDensity = 1.2
		profile.textShadowOffsetX = 1
		profile.textShadowOffsetY = 0
		profile.textShadowTransparency = 0.84
	elseif conceptTag == "arcade" then
		profile.cornerRadius = 12 + (hash % 4)
		profile.strokeThickness = 1.5
		profile.textInsetX = 7
		profile.textInsetY = 3
		profile.textureDensity = 1.25
		profile.textShadowOffsetX = 1
		profile.textShadowOffsetY = 1
		profile.textShadowTransparency = 0.7
	elseif conceptTag == "cyber" then
		profile.cornerRadius = 7 + (hash % 3)
		profile.strokeThickness = 1.25
		profile.textureDensity = 1.2
		profile.textShadowOffsetX = 1
		profile.textShadowOffsetY = 0
		profile.textShadowTransparency = 0.8
	elseif conceptTag == "nature" then
		profile.cornerRadius = 14 + (hash % 5)
		profile.strokeThickness = 1
		profile.textureDensity = 0.92
		profile.textShadowOffsetY = 1
		profile.textShadowTransparency = 0.82
	elseif conceptTag == "horror" then
		profile.cornerRadius = 6 + (hash % 4)
		profile.strokeThickness = 1.45
		profile.textureDensity = 1.1
		profile.textShadowOffsetX = 1
		profile.textShadowOffsetY = 2
		profile.textShadowTransparency = 0.64
	elseif conceptTag == "fantasy" then
		profile.cornerRadius = 13 + (hash % 4)
		profile.strokeThickness = 1.15
		profile.textureDensity = 1.06
		profile.textShadowOffsetY = 1
		profile.textShadowTransparency = 0.74
	elseif conceptTag == "tactical" then
		profile.cornerRadius = 7 + (hash % 2)
		profile.strokeThickness = 1.35
		profile.textInsetX = 8
		profile.textureDensity = 1.08
		profile.textShadowOffsetX = 1
		profile.textShadowOffsetY = 1
		profile.textShadowTransparency = 0.8
	elseif conceptTag == "speed" then
		profile.cornerRadius = 9 + (hash % 3)
		profile.strokeThickness = 1.25
		profile.textureDensity = 1.18
		profile.textShadowOffsetX = 1
		profile.textShadowOffsetY = 1
		profile.textShadowTransparency = 0.76
	end

	if lowerRole == "warning" or lowerRole == "danger" then
		profile.strokeThickness += 0.2
		profile.textureDensity += 0.06
	elseif lowerRole == "muted" then
		profile.strokeThickness = math.max(1, profile.strokeThickness - 0.15)
		profile.textureDensity = math.max(0.82, profile.textureDensity - 0.08)
	elseif lowerRole == "active" or lowerRole == "success" then
		profile.textureDensity += 0.08
	end

	if themeState.variant == "Soft" then
		profile.cornerRadius += 3
		profile.strokeThickness = math.max(1, profile.strokeThickness - 0.15)
		profile.textShadowTransparency = math.min(0.92, profile.textShadowTransparency + 0.08)
	elseif themeState.variant == "Vivid" then
		profile.strokeThickness += 0.2
		profile.textureDensity += 0.08
		profile.textShadowTransparency = math.max(0.55, profile.textShadowTransparency - 0.08)
	elseif themeState.variant == "Noir" then
		profile.cornerRadius = math.max(4, profile.cornerRadius - 1)
		profile.textShadowTransparency = math.max(0.58, profile.textShadowTransparency - 0.05)
	end

	if themeState.contrast == "Punchy" then
		profile.strokeThickness += 0.2
	elseif themeState.contrast == "Soft" then
		profile.cornerRadius += 2
	end

	profile.cornerRadius = math.clamp(math.floor(profile.cornerRadius + 0.5), 4, 20)
	profile.strokeThickness = math.clamp(profile.strokeThickness, 1, 2.2)
	profile.textInsetX = math.clamp(math.floor(profile.textInsetX + 0.5), 5, 10)
	profile.textInsetY = math.clamp(math.floor(profile.textInsetY + 0.5), 2, 5)
	profile.textureDensity = math.clamp(profile.textureDensity, 0.8, 1.45)
	profile.textShadowOffsetX = math.clamp(math.floor(profile.textShadowOffsetX + 0.5), 0, 2)
	profile.textShadowOffsetY = math.clamp(math.floor(profile.textShadowOffsetY + 0.5), 0, 2)
	profile.textShadowTransparency = math.clamp(profile.textShadowTransparency, 0.55, 0.92)
	return profile
end

function getButtonTextureProfile(themeName, role)
	local category = getThemeCategory(themeName)
	local lowerThemeName = string.lower(themeName or "")
	local proceduralness = determineProceduralness(themeName, category)
	local appearance = getButtonAppearanceProfile(themeName, role)
	local key = lowerThemeName .. ":" .. tostring(role or "secondary")
	local hash = 0
	for index = 1, #key do
		hash = (hash + string.byte(key, index) * index) % 100000
	end

	local baseIntensity = 0.22 + ((hash % 20) / 100)
	local baseBand = 0.36 + ((hash % 28) / 100)
	local baseSide = 0.06 + ((hash % 6) / 100)
	local profile = {
		style = "sheen",
		intensity = math.clamp(baseIntensity * (0.75 + proceduralness * 0.5) * appearance.textureDensity, 0.08, 0.78),
		bandScale = math.clamp(baseBand * (0.85 + proceduralness * 0.3) * (0.92 + appearance.textureDensity * 0.12), 0.3, 0.82),
		sideScale = math.clamp(baseSide * (0.8 + proceduralness * 0.4) * (0.94 + appearance.textureDensity * 0.08), 0.05, 0.24),
		density = appearance.textureDensity,
		appearance = appearance,
	}

	if string.find(lowerThemeName, "matrix", 1, true) then
		profile.style = "matrix"
		profile.intensity = 0.34
		profile.bandScale = 0.62
		profile.sideScale = 0.08
	elseif string.find(lowerThemeName, "fallout", 1, true) or string.find(lowerThemeName, "terminal", 1, true) then
		profile.style = "pipboy"
		profile.intensity = 0.32
		profile.bandScale = 0.54
		profile.sideScale = 0.12
	elseif string.find(lowerThemeName, "blueprint", 1, true) then
		profile.style = "grid"
		profile.intensity = 0.2
		profile.bandScale = 0.48
	elseif string.find(lowerThemeName, "arcade", 1, true) or string.find(lowerThemeName, "neon", 1, true) then
		profile.style = "arcade"
		profile.intensity = 0.3
		profile.bandScale = 0.58
	elseif category == "Fantasy & RPG" then
		profile.style = "sigil"
	elseif category == "Horror & Atmosphere" then
		profile.style = "scratch"
	elseif category == "Racing & Action" then
		profile.style = "chevron"
	elseif category == "Competitive & Hero" then
		profile.style = "split"
	elseif category == "Studio & Utility" then
		profile.style = "brushed"
	else
		local styles = {"sheen", "brushed", "grid", "split", "chevron"}
		profile.style = styles[(hash % #styles) + 1]
	end

	return profile
end

function styleButtonTextureLayer(button, baseColor)
	local overlay = button and button:FindFirstChild("ThemeTextureOverlay")
	if not overlay then
		return
	end

	baseColor = baseColor or Color3.fromRGB(92, 110, 148)
	local role = button:GetAttribute("ThemeRole") or "secondary"
	local profile = getButtonTextureProfile(themeState.name, role)
	local appearance = profile.appearance or getButtonAppearanceProfile(themeState.name, role)
	local accent = baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.18 + profile.intensity * 0.26)
	local accentColor = accent
	local glowColor = baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.26 + profile.intensity * 0.38)
	local subtle = baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.12 + profile.intensity * 0.08)
	local shadow = baseColor:Lerp(Color3.fromRGB(0, 0, 0), 0.3)
	local widthScale = math.clamp(profile.bandScale * 0.6 * appearance.textureDensity, 0.2, 0.82)
	local sideScale = math.clamp(profile.sideScale * 0.7 * (0.9 + appearance.textureDensity * 0.1), 0.03, 0.18)
	local overlayTrans = math.clamp(0.72 - profile.intensity * 0.25 - appearance.overlayBias * 0.4, 0.36, 0.88)

	local function setFrame(name, size, position, color, transparency, rotation)
		local frame = overlay:FindFirstChild(name)
		if not frame then
			return
		end
		if not color then
			return
		end
		frame.Visible = true
		frame.Size = size
		frame.Position = position
		frame.BackgroundColor3 = color
		frame.BackgroundTransparency = transparency
		if rotation ~= nil then
			frame.Rotation = rotation
		end
	end

	local function hide(name)
		local frame = overlay:FindFirstChild(name)
		if frame then
			frame.Visible = false
		end
	end

	for _, child in ipairs(overlay:GetChildren()) do
		if child:IsA("Frame") then
			child.Visible = false
		end
	end

	if profile.style == "matrix" then
		setFrame("TopBand", UDim2.new(widthScale * 0.6, 0, 0, 1), UDim2.new(0.1, 0, 0.22, 0), accent, overlayTrans)
		setFrame("BottomBand", UDim2.new(widthScale * 0.6, 0, 0, 1), UDim2.new(0.1, 0, 0.78, 0), accent, overlayTrans)
		setFrame("Line1", UDim2.new(1, -18, 0, 1), UDim2.new(0, 8, 0.3, 0), subtle, overlayTrans + 0.05)
		setFrame("Line2", UDim2.new(1, -18, 0, 1), UDim2.new(0, 8, 0.55, 0), subtle, overlayTrans + 0.05)
		setFrame("Line3", UDim2.new(1, -18, 0, 1), UDim2.new(0, 8, 0.8, 0), subtle, overlayTrans + 0.05)
		setFrame("Dot1", UDim2.new(0, 3, 0, 3), UDim2.new(0.18, 0, 0.32, 0), accentColor, overlayTrans + 0.2)
		setFrame("Dot2", UDim2.new(0, 3, 0, 3), UDim2.new(0.55, 0, 0.32, 0), accentColor, overlayTrans + 0.2)
	elseif profile.style == "pipboy" then
		setFrame("LeftAccent", UDim2.new(0, 5, 1, -10), UDim2.new(0.05, 0, 0, 6), accent, overlayTrans + 0.05)
		setFrame("TopBand", UDim2.new(widthScale * 0.7, 0, 0, 1), UDim2.new(0.12, 0, 0.16, 0), accent, overlayTrans + 0.08)
		setFrame("BottomBand", UDim2.new(widthScale * 0.7, 0, 0, 1), UDim2.new(0.18, 0, 0.78, 0), accent, overlayTrans + 0.08)
		setFrame("Line2", UDim2.new(1, -16, 0, 1), UDim2.new(0, 8, 0.5, -1), subtle, overlayTrans + 0.1)
		setFrame("Dot1", UDim2.new(0, 4, 0, 4), UDim2.new(0.28, 0, 0.44, 0), glowColor, overlayTrans + 0.15)
		setFrame("Dot2", UDim2.new(0, 4, 0, 4), UDim2.new(0.48, 0, 0.44, 0), glowColor, overlayTrans + 0.15)
		setFrame("Dot3", UDim2.new(0, 4, 0, 4), UDim2.new(0.68, 0, 0.44, 0), glowColor, overlayTrans + 0.15)
	elseif profile.style == "grid" then
		setFrame("Line1", UDim2.new(1, -12, 0, 1), UDim2.new(0, 6, 0.32, 0), subtle, overlayTrans + 0.04)
		setFrame("Line2", UDim2.new(1, -12, 0, 1), UDim2.new(0, 6, 0.58, 0), subtle, overlayTrans + 0.04)
		setFrame("Line3", UDim2.new(1, -12, 0, 1), UDim2.new(0, 6, 0.84, 0), subtle, overlayTrans + 0.04)
		setFrame("VLine1", UDim2.new(0, 1, 1, -10), UDim2.new(0.35, 0, 0, 4), subtle, overlayTrans + 0.08)
		setFrame("VLine2", UDim2.new(0, 1, 1, -10), UDim2.new(0.65, 0, 0, 4), subtle, overlayTrans + 0.08)
	elseif profile.style == "arcade" then
		setFrame("Sheen", UDim2.new(0, 30, 1.1, 0), UDim2.new(0.2, 0, 0.5, 0), accent, overlayTrans + 0.1, 16)
		setFrame("TopBand", UDim2.new(widthScale * 0.9, 0, 0, 1), UDim2.new(0.1, 0, 0.18, 0), accent, overlayTrans + 0.05)
		setFrame("Dot1", UDim2.new(0, 5, 0, 5), UDim2.new(0.22, 0, 0.38, 0), glowColor, overlayTrans + 0.08)
		setFrame("Dot2", UDim2.new(0, 5, 0, 5), UDim2.new(0.45, 0, 0.38, 0), glowColor, overlayTrans + 0.08)
		setFrame("Dot3", UDim2.new(0, 5, 0, 5), UDim2.new(0.68, 0, 0.38, 0), glowColor, overlayTrans + 0.08)
	elseif profile.style == "sigil" then
		setFrame("TopBand", UDim2.new(widthScale * 0.88, 0, 0, 2), UDim2.new(0.12, 0, 0.18, 0), accent, overlayTrans + 0.05)
		setFrame("BottomBand", UDim2.new(widthScale * 0.88, 0, 0, 2), UDim2.new(0.12, 0, 0.76, 0), accent, overlayTrans + 0.08)
		setFrame("Dot1", UDim2.new(0, 6, 0, 6), UDim2.new(0.5, -3, 0.5, -3), accent, overlayTrans + 0.12)
		setFrame("VLine1", UDim2.new(0, 1, 0, 12), UDim2.new(0.5, 0, 0.28, 0), subtle, overlayTrans + 0.1)
	elseif profile.style == "scratch" then
		setFrame("Sheen", UDim2.new(0, 10, 1.3, 0), UDim2.new(0.28, 0, 0.5, 0), accent, overlayTrans + 0.12, 24)
		setFrame("LeftAccent", UDim2.new(0, 2, 1, -10), UDim2.new(0.18, 0, 0, 5), subtle, overlayTrans + 0.08)
		setFrame("RightAccent", UDim2.new(0, 2, 1, -12), UDim2.new(0.72, 0, 0, 6), subtle, overlayTrans + 0.1)
	elseif profile.style == "chevron" then
		setFrame("LeftAccent", UDim2.new(0, 8, 1, -8), UDim2.new(0.06, 0, 0, 5), accent, overlayTrans + 0.05)
		setFrame("Sheen", UDim2.new(0, 16, 1.2, 0), UDim2.new(0.24, 0, 0.5, 0), accent, overlayTrans + 0.12, 24)
		setFrame("TopBand", UDim2.new(widthScale * 0.7, 0, 0, 2), UDim2.new(0.22, 0, 0.18, 0), accent, overlayTrans + 0.08)
	elseif profile.style == "split" then
		setFrame("LeftAccent", UDim2.new(0, 5, 1, -8), UDim2.new(0, 5, 0, 4), accent, overlayTrans + 0.06)
		setFrame("VLine1", UDim2.new(0, 1, 1, -10), UDim2.new(0.5, 0, 0, 5), subtle, overlayTrans + 0.08)
		setFrame("TopBand", UDim2.new(widthScale * 0.76, 0, 0, 2), UDim2.new(0.12, 0, 0.18, 0), accent, overlayTrans + 0.08)
	elseif profile.style == "brushed" then
		setFrame("Line1", UDim2.new(1, -14, 0, 1), UDim2.new(0, 7, 0.3, 0), subtle, overlayTrans + 0.04)
		setFrame("Line2", UDim2.new(1, -14, 0, 1), UDim2.new(0, 7, 0.54, 0), subtle, overlayTrans + 0.06)
		setFrame("TopBand", UDim2.new(widthScale * 0.66, 0, 0, 2), UDim2.new(0.14, 0, 0.18, 0), accent, overlayTrans + 0.06)
	else
		setFrame("Sheen", UDim2.new(0, 18, 1.1, 0), UDim2.new(0.32, 0, 0.5, 0), accent, overlayTrans + 0.1, 12)
		setFrame("TopBand", UDim2.new(widthScale * 0.85, 0, 0, 1), UDim2.new(0.1, 0, 0.18, 0), accent, overlayTrans + 0.08)
	end

	if appearance.conceptTag == "nature" then
		setFrame("Dot4", UDim2.new(0, 4, 0, 4), UDim2.new(0.78, 0, 0.64, 0), glowColor, overlayTrans + 0.14)
	elseif appearance.conceptTag == "horror" then
		setFrame("RightAccent", UDim2.new(0, 2, 1, -8), UDim2.new(0.82, 0, 0, 4), shadow, overlayTrans + 0.06)
	elseif appearance.conceptTag == "tactical" then
		setFrame("RightAccent", UDim2.new(0, 4, 1, -8), UDim2.new(1, -9, 0, 4), accent, overlayTrans + 0.07)
	elseif appearance.conceptTag == "speed" then
		setFrame("Sheen", UDim2.new(0, 22, 1.15, 0), UDim2.new(0.42, 0, 0.5, 0), accent, overlayTrans + 0.08, 22)
	end

	local textLabel = button:FindFirstChild("ThemeTextLabel")
	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

function applyButtonShapeProfile(button)
	if not button then
		return
	end
	local role = button:GetAttribute("ThemeRole") or "secondary"
	local profile = getButtonAppearanceProfile(themeState.name, role)
	setCornerRadius(button, profile.cornerRadius)
	button.ClipsDescendants = true
	button.TextTransparency = 1
	button.TextStrokeTransparency = 1

	local stroke = createStroke(button, themeState.current.buttonStroke)
	if stroke then
		stroke.Thickness = profile.strokeThickness
	end

	local textLabel = button:FindFirstChild("ThemeTextLabel")
	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.Size = UDim2.new(1, -(profile.textInsetX * 2), 1, -(profile.textInsetY * 2))
		textLabel.Position = UDim2.new(0, profile.textInsetX, 0, profile.textInsetY)
	end

	local shadowLabel = button:FindFirstChild("ThemeTextShadow")
	if shadowLabel and shadowLabel:IsA("TextLabel") and textLabel and textLabel:IsA("TextLabel") then
		shadowLabel.Size = textLabel.Size
		shadowLabel.Position = UDim2.new(0, profile.textInsetX + profile.textShadowOffsetX, 0, profile.textInsetY + profile.textShadowOffsetY)
	end

	local overlay = button:FindFirstChild("ThemeTextureOverlay")
	if overlay and overlay:IsA("Frame") then
		setCornerRadius(overlay, math.max(2, profile.cornerRadius - 1))
	end

	button:SetAttribute("ThemeCornerRadius", profile.cornerRadius)
	button:SetAttribute("ThemeTextureDensity", profile.textureDensity)
end

function applyThemeToButton(entry)
	local button = entry.instance
	if not button or not button.Parent then
		return
	end
	local typography = themeState.current.typography or {}
	local role = button:GetAttribute("ThemeRole") or entry.role or "secondary"
	local baseColor = themeState.current.buttons[role] or themeState.current.buttons.secondary
	baseColor = baseColor or Color3.fromRGB(94, 110, 128)
	local appearance = getButtonAppearanceProfile(themeState.name, role)
	applyButtonShapeProfile(button)
	tweenThemeBackground(button, baseColor)
	tweenThemeTextColor(button, Color3.fromRGB(255, 255, 255))
	button.Font = typography.button or entry.defaultFont or Enum.Font.GothamBold
	tweenThemeStroke(button, themeState.current.buttonStroke)
	addVerticalGradient(
		button,
		baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.12 + ((button:GetAttribute("ThemeTextureDensity") or 1) - 1) * 0.06),
		baseColor:Lerp(Color3.fromRGB(0, 0, 0), 0.14 + (themeState.contrast == "Punchy" and 0.03 or 0))
	)
	styleButtonTextureLayer(button, baseColor)

	local textLabel = button:FindFirstChild("ThemeTextLabel")
	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextTransparency = 0
	end

	local shadowLabel = button:FindFirstChild("ThemeTextShadow")
	if shadowLabel and shadowLabel:IsA("TextLabel") and textLabel and textLabel:IsA("TextLabel") then
		local wrapped = false
		local availableWidth = math.max(textLabel.AbsoluteSize.X, 1)
		local measured = nil
		pcall(function()
			measured = game:GetService("TextService"):GetTextSize(
				button.Text or "",
				textLabel.TextSize,
				textLabel.Font,
				Vector2.new(availableWidth, 1000)
			)
		end)
		if measured and measured.Y > (textLabel.TextSize * 1.45) then
			wrapped = true
		elseif string.find(button.Text or "", "\n", 1, true) then
			wrapped = true
		end

		shadowLabel.TextColor3 = baseColor:Lerp(Color3.fromRGB(0, 0, 0), wrapped and 0.58 or 0.72)
		shadowLabel.TextTransparency = wrapped and 1 or appearance.textShadowTransparency
		if wrapped then
			shadowLabel.Position = textLabel.Position
		end
	end
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
	syncGenerationActivityTheme()
	if themeAudioState.initialized then
		playThemeUiSound("theme_change")
	else
		themeAudioState.initialized = true
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
	themeState.variant = "Soft"
	themeState.tone = "Default"
	themeState.contrast = "Soft"
	themeState.typography = "Studio Sans"
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

function createSettingsSubgroup(parent, title, description, topColor, bottomColor, strokeColor)
	local group = Instance.new("Frame")
	group.Size = UDim2.new(1, 0, 0, 0)
	group.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	group.BorderSizePixel = 0
	group.AutomaticSize = Enum.AutomaticSize.Y
	group.Parent = parent
	styleCard(
		group,
		topColor or Color3.fromRGB(52, 64, 87),
		bottomColor or Color3.fromRGB(31, 39, 53),
		strokeColor or Color3.fromRGB(102, 126, 168),
		false
	)

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

	local titleLabel = createLabel(title, 14, Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), 20)
	enableAutoHeightLabel(titleLabel, 20)
	titleLabel.Parent = group

	local descriptionLabel = createLabel(
		description,
		12,
		Enum.Font.Gotham,
		Color3.fromRGB(171, 183, 199),
		22
	)
	enableAutoHeightLabel(descriptionLabel, 22)
	descriptionLabel.Parent = group

	return group, titleLabel, descriptionLabel
end

function createVolumeSlider(accentColor, onChanged, titleText, descriptionText)
	local slider = {}

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, (titleText or descriptionText) and 78 or 42)
	frame.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	frame.BorderSizePixel = 0
	styleCard(
		frame,
		accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.1),
		accentColor:Lerp(Color3.fromRGB(18, 22, 30), 0.78),
		accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.2),
		false
	)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = frame

	local barTopInset = 0
	if titleText or descriptionText then
		local titleLabel = createLabel(titleText or "", 12, Enum.Font.GothamBold, Color3.fromRGB(240, 245, 250), 18)
		titleLabel.Size = UDim2.new(1, -64, 0, 18)
		titleLabel.Position = UDim2.new(0, 0, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.TextYAlignment = Enum.TextYAlignment.Top
		titleLabel.Parent = frame
		slider.titleLabel = titleLabel

		local descriptionLabel = createLabel(descriptionText or "", 11, Enum.Font.Gotham, Color3.fromRGB(179, 191, 208), 18)
		descriptionLabel.Size = UDim2.new(1, -64, 0, 30)
		descriptionLabel.Position = UDim2.new(0, 0, 0, 18)
		descriptionLabel.BackgroundTransparency = 1
		descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
		descriptionLabel.Parent = frame
		slider.descriptionLabel = descriptionLabel
		barTopInset = 34
	end

	local valueLabel = createLabel("72%", 11, Enum.Font.GothamBold, Color3.fromRGB(235, 240, 248), 16)
	valueLabel.Size = UDim2.new(0, 52, 0, 16)
	valueLabel.Position = UDim2.new(1, -52, 0, barTopInset)
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = frame

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -64, 0, 10)
	bar.Position = UDim2.new(0, 0, 0, barTopInset + 3)
	bar.BackgroundColor3 = Color3.fromRGB(31, 38, 52)
	bar.BorderSizePixel = 0
	bar.Active = true
	bar.Parent = frame
	createCorner(bar, 999)

	local barStroke = createStroke(bar, accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.16))
	if barStroke then
		barStroke.Transparency = 0.35
	end

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.72, 0, 1, 0)
	fill.BackgroundColor3 = accentColor
	fill.BorderSizePixel = 0
	fill.Active = false
	fill.Parent = bar
	createCorner(fill, 999)
	addVerticalGradient(
		fill,
		accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.14),
		accentColor:Lerp(Color3.fromRGB(0, 0, 0), 0.12)
	)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0.72, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(245, 247, 250)
	knob.BorderSizePixel = 0
	knob.Active = false
	knob.Parent = bar
	createCorner(knob, 999)
	local knobStroke = createStroke(knob, accentColor:Lerp(Color3.fromRGB(0, 0, 0), 0.25))
	if knobStroke then
		knobStroke.Thickness = 1.2
	end

	slider.frame = frame
	slider.bar = bar
	slider.fill = fill
	slider.knob = knob
	slider.valueLabel = valueLabel
	slider.dragging = false
	slider.value = 0.72

	function slider:setValue(value)
		self.value = clampUnitNumber(value, self.value)
		self.fill.Size = UDim2.new(self.value, 0, 1, 0)
		self.knob.Position = UDim2.new(self.value, 0, 0.5, 0)
		self.valueLabel.Text = ("%d%%"):format(math.floor(self.value * 100 + 0.5))
	end

	local function updateFromPosition(positionX)
		local barPosition = slider.bar.AbsolutePosition.X
		local barWidth = math.max(slider.bar.AbsoluteSize.X, 1)
		local alpha = clampUnitNumber((positionX - barPosition) / barWidth, slider.value)
		slider:setValue(alpha)
		if onChanged then
			onChanged(alpha)
		end
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slider.dragging = true
			updateFromPosition(input.Position.X)
		end
	end)

	bar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slider.dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if slider.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateFromPosition(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slider.dragging = false
		end
	end)

	return slider
end

function createInlineSettingsControl(title, description, accentColor)
	local baseColor = accentColor or Color3.fromRGB(84, 107, 146)

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 0)
	card.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	card.BorderSizePixel = 0
	card.AutomaticSize = Enum.AutomaticSize.Y
	styleCard(
		card,
		baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.12),
		baseColor:Lerp(Color3.fromRGB(18, 22, 30), 0.8),
		baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.24),
		false
	)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Parent = card

	local titleLabel = createLabel(title or "", 12, Enum.Font.GothamBold, Color3.fromRGB(240, 245, 250), 18)
	titleLabel.Size = UDim2.new(1, 0, 0, 18)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Top
	titleLabel.Parent = card

	local descriptionLabel = createLabel(description or "", 11, Enum.Font.Gotham, Color3.fromRGB(179, 191, 208), 18)
	descriptionLabel.Size = UDim2.new(1, 0, 0, 0)
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
	descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
	descriptionLabel.TextWrapped = true
	descriptionLabel.AutomaticSize = Enum.AutomaticSize.Y
	descriptionLabel.Parent = card

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 0, 0)
	content.BackgroundTransparency = 1
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.Parent = card

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0, 0)
	contentLayout.FillDirection = Enum.FillDirection.Vertical
	contentLayout.Parent = content

	return card, titleLabel, descriptionLabel, content
end

function createSettingsOptionRow(title, accentColor)
	local baseColor = accentColor or Color3.fromRGB(84, 107, 146)

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 52)
	card.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	card.BorderSizePixel = 0
	card.Parent = ui.activeSettingsGroup
	styleCard(
		card,
		baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.1),
		baseColor:Lerp(Color3.fromRGB(18, 22, 30), 0.82),
		baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.2),
		false
	)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = card

	local titleLabel = createLabel(title or "", 12, Enum.Font.GothamBold, Color3.fromRGB(240, 245, 250), 18)
	titleLabel.Size = UDim2.new(1, -138, 1, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.Parent = card

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(0, 128, 1, 0)
	content.Position = UDim2.new(1, -128, 0, 0)
	content.BackgroundTransparency = 1
	content.Parent = card

	return card, titleLabel, content
end

function createActivityBarDecor(barFrame)
	if not barFrame then
		return
	end

	local overlay = Instance.new("Frame")
	overlay.Name = "ThemeBarOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 3
	overlay.Parent = barFrame

	local topLine = Instance.new("Frame")
	topLine.Name = "TopLine"
	topLine.Size = UDim2.new(1, -8, 0, 1)
	topLine.Position = UDim2.new(0, 4, 0, 2)
	topLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	topLine.BackgroundTransparency = 0.78
	topLine.BorderSizePixel = 0
	topLine.ZIndex = 3
	topLine.Parent = overlay

	local bottomLine = Instance.new("Frame")
	bottomLine.Name = "BottomLine"
	bottomLine.Size = UDim2.new(1, -8, 0, 1)
	bottomLine.Position = UDim2.new(0, 4, 1, -3)
	bottomLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bottomLine.BackgroundTransparency = 0.82
	bottomLine.BorderSizePixel = 0
	bottomLine.ZIndex = 3
	bottomLine.Parent = overlay

	local glyphLabel = createLabel("", 10, Enum.Font.Code, Color3.fromRGB(232, 240, 248), 12)
	glyphLabel.Name = "GlyphLabel"
	glyphLabel.Size = UDim2.new(0, 130, 1, 0)
	glyphLabel.Position = UDim2.new(1, -132, 0, 1)
	glyphLabel.BackgroundTransparency = 1
	glyphLabel.TextXAlignment = Enum.TextXAlignment.Right
	glyphLabel.TextYAlignment = Enum.TextYAlignment.Center
	glyphLabel.ZIndex = 4
	glyphLabel.Parent = overlay

	local sceneLabel = createLabel("", 10, Enum.Font.Code, Color3.fromRGB(232, 240, 248), 12)
	sceneLabel.Name = "SceneLabel"
	sceneLabel.Size = UDim2.new(0, 120, 1, 0)
	sceneLabel.Position = UDim2.new(0, 8, 0, 1)
	sceneLabel.BackgroundTransparency = 1
	sceneLabel.TextXAlignment = Enum.TextXAlignment.Left
	sceneLabel.TextYAlignment = Enum.TextYAlignment.Center
	sceneLabel.ZIndex = 4
	sceneLabel.Parent = overlay

	local pulseNode = Instance.new("Frame")
	pulseNode.Name = "PulseNode"
	pulseNode.Size = UDim2.new(0, 10, 0, 10)
	pulseNode.AnchorPoint = Vector2.new(0.5, 0.5)
	pulseNode.Position = UDim2.new(0, 0, 0.5, 0)
	pulseNode.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	pulseNode.BackgroundTransparency = 0.16
	pulseNode.BorderSizePixel = 0
	pulseNode.ZIndex = 4
	pulseNode.Parent = overlay
	createCorner(pulseNode, 999)

	local segments = {}
	for index = 1, 12 do
		local segment = Instance.new("Frame")
		segment.Name = "Segment" .. index
		segment.Size = UDim2.new(0, 6, 1, -6)
		segment.AnchorPoint = Vector2.new(0.5, 0.5)
		segment.Position = UDim2.new((index - 0.5) / 12, 0, 0.5, 0)
		segment.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		segment.BackgroundTransparency = 0.86
		segment.BorderSizePixel = 0
		segment.ZIndex = 3
		segment.Parent = overlay
		createCorner(segment, 3)
		segments[index] = segment
	end

	barFrame:SetAttribute("ThemeBarDecorReady", true)
end

function ensureActivityBarDecor(barFrame)
	if not barFrame then
		return nil
	end
	if barFrame:GetAttribute("ThemeBarDecorReady") ~= true then
		createActivityBarDecor(barFrame)
	end
	local overlay = barFrame:FindFirstChild("ThemeBarOverlay")
	if not overlay then
		return nil
	end
	local segments = {}
	for index = 1, 12 do
		segments[index] = overlay:FindFirstChild("Segment" .. index)
	end
	return {
		overlay = overlay,
		topLine = overlay:FindFirstChild("TopLine"),
		bottomLine = overlay:FindFirstChild("BottomLine"),
		glyphLabel = overlay:FindFirstChild("GlyphLabel"),
		sceneLabel = overlay:FindFirstChild("SceneLabel"),
		pulseNode = overlay:FindFirstChild("PulseNode"),
		segments = segments,
	}
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
		padding.PaddingTop = UDim.new(0, 2)
		padding.PaddingBottom = UDim.new(0, 2)
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
	button.TextTransparency = 1
	button.ClipsDescendants = true
	createCorner(button, 10)
	createStroke(button, Color3.fromRGB(33, 45, 65))
	addVerticalGradient(
		button,
		color:Lerp(Color3.fromRGB(255, 255, 255), 0.12),
		color:Lerp(Color3.fromRGB(0, 0, 0), 0.14)
	)

	local textureOverlay = Instance.new("Frame")
	textureOverlay.Name = "ThemeTextureOverlay"
	textureOverlay.Size = UDim2.new(1, 0, 1, 0)
	textureOverlay.BackgroundTransparency = 1
	textureOverlay.BorderSizePixel = 0
	textureOverlay.Active = false
	textureOverlay.ZIndex = 1
	textureOverlay.Parent = button
	createCorner(textureOverlay, 9)

	local topBand = Instance.new("Frame")
	topBand.Name = "TopBand"
	topBand.BackgroundTransparency = 1
	topBand.BorderSizePixel = 0
	topBand.ZIndex = 1
	topBand.Parent = textureOverlay

	local bottomBand = Instance.new("Frame")
	bottomBand.Name = "BottomBand"
	bottomBand.BackgroundTransparency = 1
	bottomBand.BorderSizePixel = 0
	bottomBand.ZIndex = 1
	bottomBand.Parent = textureOverlay

	local leftAccent = Instance.new("Frame")
	leftAccent.Name = "LeftAccent"
	leftAccent.BackgroundTransparency = 1
	leftAccent.BorderSizePixel = 0
	leftAccent.ZIndex = 1
	leftAccent.Parent = textureOverlay

	local rightAccent = Instance.new("Frame")
	rightAccent.Name = "RightAccent"
	rightAccent.BackgroundTransparency = 1
	rightAccent.BorderSizePixel = 0
	rightAccent.ZIndex = 1
	rightAccent.Parent = textureOverlay

	local sheen = Instance.new("Frame")
	sheen.Name = "Sheen"
	sheen.AnchorPoint = Vector2.new(0.5, 0.5)
	sheen.BackgroundTransparency = 1
	sheen.BorderSizePixel = 0
	sheen.ZIndex = 1
	sheen.Rotation = 16
	sheen.Parent = textureOverlay

	local line1 = Instance.new("Frame")
	line1.Name = "Line1"
	line1.BackgroundTransparency = 1
	line1.BorderSizePixel = 0
	line1.ZIndex = 1
	line1.Parent = textureOverlay

	local line2 = Instance.new("Frame")
	line2.Name = "Line2"
	line2.BackgroundTransparency = 1
	line2.BorderSizePixel = 0
	line2.ZIndex = 1
	line2.Parent = textureOverlay

	local line3 = Instance.new("Frame")
	line3.Name = "Line3"
	line3.BackgroundTransparency = 1
	line3.BorderSizePixel = 0
	line3.ZIndex = 1
	line3.Parent = textureOverlay

	local vline1 = Instance.new("Frame")
	vline1.Name = "VLine1"
	vline1.BackgroundTransparency = 1
	vline1.BorderSizePixel = 0
	vline1.ZIndex = 1
	vline1.Parent = textureOverlay

	local vline2 = Instance.new("Frame")
	vline2.Name = "VLine2"
	vline2.BackgroundTransparency = 1
	vline2.BorderSizePixel = 0
	vline2.ZIndex = 1
	vline2.Parent = textureOverlay

	for index = 1, 4 do
		local dot = Instance.new("Frame")
		dot.Name = "Dot" .. index
		dot.BackgroundTransparency = 1
		dot.BorderSizePixel = 0
		dot.ZIndex = 1
		dot.Parent = textureOverlay
		createCorner(dot, 2)
	end

	local shadowLabel = Instance.new("TextLabel")
	shadowLabel.Name = "ThemeTextShadow"
	shadowLabel.Size = UDim2.new(1, -12, 1, -6)
	shadowLabel.Position = UDim2.new(0, 7, 0, 4)
	shadowLabel.BackgroundTransparency = 1
	shadowLabel.Text = button.Text
	shadowLabel.TextColor3 = Color3.fromRGB(24, 28, 36)
	shadowLabel.TextStrokeTransparency = 1
	shadowLabel.TextWrapped = true
	shadowLabel.TextXAlignment = Enum.TextXAlignment.Center
	shadowLabel.TextYAlignment = Enum.TextYAlignment.Center
	shadowLabel.Font = button.Font
	shadowLabel.TextSize = button.TextSize
	shadowLabel.ZIndex = 2
	shadowLabel.Parent = button

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "ThemeTextLabel"
	textLabel.Size = UDim2.new(1, -12, 1, -6)
	textLabel.Position = UDim2.new(0, 6, 0, 3)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = button.Text
	textLabel.TextColor3 = button.TextColor3
	textLabel.TextStrokeTransparency = 1
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.Font = button.Font
	textLabel.TextSize = button.TextSize
	textLabel.ZIndex = 2
	textLabel.Parent = button

	button:GetPropertyChangedSignal("Text"):Connect(function()
		shadowLabel.Text = button.Text
		textLabel.Text = button.Text
	end)
	button:GetPropertyChangedSignal("TextColor3"):Connect(function()
		textLabel.TextColor3 = button.TextColor3
	end)
	button:GetPropertyChangedSignal("Font"):Connect(function()
		shadowLabel.Font = button.Font
		textLabel.Font = button.Font
	end)
	button:GetPropertyChangedSignal("TextSize"):Connect(function()
		shadowLabel.TextSize = button.TextSize
		textLabel.TextSize = button.TextSize
	end)
	button:GetPropertyChangedSignal("Visible"):Connect(function()
		shadowLabel.Visible = button.Visible
		textLabel.Visible = button.Visible
	end)

	button:SetAttribute("ThemeRole", themeRole or "secondary")
	table.insert(themeRegistry.buttons, {
		instance = button,
		role = themeRole or "secondary",
		defaultFont = button.Font,
	})
	applyButtonShapeProfile(button)
	styleButtonTextureLayer(button, color)
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

function loadPromptFavorites()
	local stored = getSetting(SETTINGS.promptFavorites, {})
	if type(stored) ~= "table" then
		return {}
	end
	local favorites = {}
	for _, entry in ipairs(stored) do
		if type(entry) == "string" and string.gsub(entry, "%s+", "") ~= "" then
			table.insert(favorites, entry)
		end
		if #favorites >= 6 then
			break
		end
	end
	return favorites
end

local recentPromptHistory = loadPromptHistory()
local favoritePrompts = loadPromptFavorites()
local pendingStoreAllConfirmation = false
local generationTexturesEnabled = getBooleanSetting(SETTINGS.textures, true)
local generationIncludeBaseEnabled = getBooleanSetting(SETTINGS.includeBase, true)
local generationAnchoredEnabled = getBooleanSetting(SETTINGS.anchored, true)
local generationNamePattern = tostring(getSetting(SETTINGS.namePattern, "Prompt"))
local generationBatchLayout = tostring(getSetting(SETTINGS.batchLayout, "Folder Only"))
local experimentalStyleBias = tostring(getSetting(SETTINGS.experimentalStyleBias, "Off"))
local experimentalScenePromptEnabled = getBooleanSetting(SETTINGS.experimentalScenePromptEnabled, false)
local experimentalPreviewMode = tostring(getSetting(SETTINGS.experimentalPreviewMode, "Balanced"))
local experimentalGroundSnap = getBooleanSetting(SETTINGS.experimentalGroundSnap, false)
local pluginUpdateState = {
	currentVersion = PLUGIN_VERSION,
	latestVersion = tostring(getSetting(SETTINGS.updateLatestReleaseTag, "Not checked")),
	latestUrl = tostring(getSetting(SETTINGS.updateLatestReleaseUrl, PLUGIN_GITHUB_RELEASES_URL)),
	publishedAt = tostring(getSetting(SETTINGS.updateLatestReleasePublishedAt, "")),
	lastCheckedAt = tostring(getSetting(SETTINGS.updateLastCheckedAt, "")),
	lastStatus = tostring(getSetting(SETTINGS.updateLastStatus, "Not checked yet.")),
	checking = false,
	updateAvailable = false,
}

function normalizeVersionTag(tag)
	local cleaned = tostring(tag or ""):gsub("^%s+", ""):gsub("%s+$", "")
	cleaned = cleaned:gsub("^v", ""):gsub("^V", "")
	return cleaned
end

function parseVersionSegments(tag)
	local cleaned = normalizeVersionTag(tag)
	if cleaned == "" then
		return nil
	end
	local segments = {}
	for piece in cleaned:gmatch("%d+") do
		segments[#segments + 1] = tonumber(piece) or 0
	end
	if #segments == 0 then
		return nil
	end
	return segments
end

function isLatestReleaseNewer(currentVersion, latestVersion)
	local currentSegments = parseVersionSegments(currentVersion)
	local latestSegments = parseVersionSegments(latestVersion)
	if not currentSegments or not latestSegments then
		return normalizeVersionTag(currentVersion) ~= "" and normalizeVersionTag(currentVersion) ~= normalizeVersionTag(latestVersion)
	end
	local maxCount = math.max(#currentSegments, #latestSegments)
	for index = 1, maxCount do
		local currentValue = currentSegments[index] or 0
		local latestValue = latestSegments[index] or 0
		if latestValue > currentValue then
			return true
		elseif latestValue < currentValue then
			return false
		end
	end
	return false
end

function updatePluginUpdateStateAvailability()
	pluginUpdateState.updateAvailable = pluginUpdateState.latestVersion ~= "Not checked"
		and pluginUpdateState.latestVersion ~= "No release published"
		and isLatestReleaseNewer(pluginUpdateState.currentVersion, pluginUpdateState.latestVersion)
end

function refreshPluginUpdateUi()
	updatePluginUpdateStateAvailability()
	if ui.currentVersionLabel then
		ui.currentVersionLabel.Text = "Current Plugin Version: " .. pluginUpdateState.currentVersion
	end
	if ui.latestVersionLabel then
		local latestLine = "Latest GitHub Release: " .. tostring(pluginUpdateState.latestVersion or "Not checked")
		if pluginUpdateState.publishedAt ~= "" then
			latestLine ..= " | Published: " .. pluginUpdateState.publishedAt
		end
		ui.latestVersionLabel.Text = latestLine
	end
	if ui.updateStatusLabel then
		local lines = {tostring(pluginUpdateState.lastStatus or "Not checked yet.")}
		if pluginUpdateState.lastCheckedAt ~= "" then
			lines[#lines + 1] = "Last checked: " .. pluginUpdateState.lastCheckedAt
		end
		ui.updateStatusLabel.Text = table.concat(lines, "\n")
	end
	if ui.updateReleaseUrlBox then
		ui.updateReleaseUrlBox.Text = tostring(pluginUpdateState.latestUrl or PLUGIN_GITHUB_RELEASES_URL)
	end
	if ui.checkUpdatesButton then
		ui.checkUpdatesButton.Text = pluginUpdateState.checking and "Checking GitHub..." or "Check GitHub Release"
		setButtonThemeRole(ui.checkUpdatesButton, pluginUpdateState.checking and "warning" or "info")
	end
	if ui.updateReleaseButton then
		ui.updateReleaseButton.Text = pluginUpdateState.updateAvailable and "Update Available: Manual Install Required" or "Release Install Is Manual"
		setButtonThemeRole(ui.updateReleaseButton, pluginUpdateState.updateAvailable and "warning" or "secondary")
	end
end

function checkLatestPluginRelease()
	if pluginUpdateState.checking then
		return
	end
	pluginUpdateState.checking = true
	pluginUpdateState.lastStatus = "Checking GitHub releases..."
	refreshPluginUpdateUi()

	local success, responseOrError = pcall(function()
		return HttpService:RequestAsync({
			Url = PLUGIN_GITHUB_LATEST_RELEASE_API,
			Method = "GET",
			Headers = {
				Accept = "application/vnd.github+json",
			},
		})
	end)

	pluginUpdateState.checking = false
	pluginUpdateState.lastCheckedAt = os.date("%Y-%m-%d %H:%M")
	setSetting(SETTINGS.updateLastCheckedAt, pluginUpdateState.lastCheckedAt)

	if not success then
		pluginUpdateState.lastStatus = "Update check failed. Enable HTTP requests in Studio and verify GitHub access."
		setSetting(SETTINGS.updateLastStatus, pluginUpdateState.lastStatus)
		refreshPluginUpdateUi()
		setStatus("GitHub update check failed: " .. tostring(responseOrError), "error")
		return
	end

	local response = responseOrError
	if not response.Success then
		if response.StatusCode == 404 then
			pluginUpdateState.latestVersion = "No release published"
			pluginUpdateState.latestUrl = PLUGIN_GITHUB_RELEASES_URL
			pluginUpdateState.publishedAt = ""
			pluginUpdateState.lastStatus = "No GitHub release is published for this repository yet."
			setStatus(pluginUpdateState.lastStatus, "info")
		else
			pluginUpdateState.lastStatus = ("GitHub update check returned %s %s."):format(tostring(response.StatusCode), tostring(response.StatusMessage or ""))
			setStatus(pluginUpdateState.lastStatus, "error")
		end
		setSetting(SETTINGS.updateLatestReleaseTag, pluginUpdateState.latestVersion)
		setSetting(SETTINGS.updateLatestReleaseUrl, pluginUpdateState.latestUrl)
		setSetting(SETTINGS.updateLatestReleasePublishedAt, pluginUpdateState.publishedAt)
		setSetting(SETTINGS.updateLastStatus, pluginUpdateState.lastStatus)
		refreshPluginUpdateUi()
		return
	end

	local decodedSuccess, releaseData = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)
	if not decodedSuccess or type(releaseData) ~= "table" then
		pluginUpdateState.lastStatus = "GitHub returned an unreadable release response."
		setSetting(SETTINGS.updateLastStatus, pluginUpdateState.lastStatus)
		refreshPluginUpdateUi()
		setStatus(pluginUpdateState.lastStatus, "error")
		return
	end

	pluginUpdateState.latestVersion = tostring(releaseData.tag_name or releaseData.name or "Unknown")
	pluginUpdateState.latestUrl = tostring(releaseData.html_url or PLUGIN_GITHUB_RELEASES_URL)
	pluginUpdateState.publishedAt = tostring(releaseData.published_at or "")
	updatePluginUpdateStateAvailability()
	if pluginUpdateState.updateAvailable then
		pluginUpdateState.lastStatus = ("Latest release %s is newer than installed version %s. Download and replace the local plugin file manually."):format(pluginUpdateState.latestVersion, pluginUpdateState.currentVersion)
		setStatus(pluginUpdateState.lastStatus, "info")
	else
		pluginUpdateState.lastStatus = ("Installed version %s matches or exceeds the latest published release %s."):format(pluginUpdateState.currentVersion, pluginUpdateState.latestVersion)
		setStatus(pluginUpdateState.lastStatus, "success")
	end

	setSetting(SETTINGS.updateLatestReleaseTag, pluginUpdateState.latestVersion)
	setSetting(SETTINGS.updateLatestReleaseUrl, pluginUpdateState.latestUrl)
	setSetting(SETTINGS.updateLatestReleasePublishedAt, pluginUpdateState.publishedAt)
	setSetting(SETTINGS.updateLastStatus, pluginUpdateState.lastStatus)
	refreshPluginUpdateUi()
end

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

function isFavoritePrompt(prompt)
	local trimmed = tostring(prompt or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then
		return false
	end
	for _, entry in ipairs(favoritePrompts) do
		if entry == trimmed then
			return true
		end
	end
	return false
end

function addFavoritePrompt(prompt)
	local trimmed = tostring(prompt or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then
		return false
	end

	local updated = {trimmed}
	for _, entry in ipairs(favoritePrompts) do
		if entry ~= trimmed then
			updated[#updated + 1] = entry
		end
		if #updated >= 6 then
			break
		end
	end

	favoritePrompts = updated
	setSetting(SETTINGS.promptFavorites, favoritePrompts)
	return true
end

function removeFavoritePrompt(prompt)
	local trimmed = tostring(prompt or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local updated = {}
	local removed = false
	for _, entry in ipairs(favoritePrompts) do
		if entry == trimmed then
			removed = true
		else
			updated[#updated + 1] = entry
		end
	end
	if removed then
		favoritePrompts = updated
		setSetting(SETTINGS.promptFavorites, favoritePrompts)
	end
	return removed
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

function focusGuideTarget(targetSpec)
	if type(targetSpec) ~= "table" then
		return
	end

	if targetSpec.stepId then
		focusGuideStep(targetSpec.stepId)
		return
	end

	local panel = targetSpec.panel or "main"
	local target = targetSpec.target
	if not target or not target.Parent then
		return
	end

	if panel == "settings" then
		widget.Enabled = true
		setSettingsPanelOpen(true)
		task.defer(function()
			if target and target.Parent then
				scrollSettingsTargetIntoView(target)
				pulseGuideFocusTarget(target)
			end
		end)
		return
	elseif panel == "preview" then
		previewWidget.Enabled = true
	else
		widget.Enabled = true
		settingsWidget.Enabled = false
	end

	if panel == "main" then
		scrollMainTargetIntoView(target)
	end
	pulseGuideFocusTarget(target)
end

do
	ui.promptTitle = createSectionTitle("Prompt")
	ui.promptTitle.LayoutOrder = 14
	ui.promptTitle.Parent = root
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

ui.scenePromptTitle = createSectionTitle("Scene Direction")
ui.scenePromptTitle.LayoutOrder = 16
ui.scenePromptTitle.Visible = experimentalScenePromptEnabled
ui.scenePromptTitle.Parent = root

ui.scenePromptBox = createTextBox(
	96,
	"Scene brief: ruined harbor at dawn with fishing boats, wet stone docks, crates, gulls, and layered fog",
	tostring(getSetting(SETTINGS.experimentalScenePrompt, "")),
	Enum.Font.Code
)
ui.scenePromptBox.MultiLine = true
ui.scenePromptBox.TextWrapped = true
ui.scenePromptBox.LayoutOrder = 17
ui.scenePromptBox.Visible = experimentalScenePromptEnabled
ui.scenePromptBox.Parent = root

ui.scenePromptHelp = createLabel(
	"Experimental. Treats the main prompt as required scene elements and this box as the overall scene brief so preview and generation attempt a full contextual setup.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(157, 168, 183),
	30
)
ui.scenePromptHelp.LayoutOrder = 18
ui.scenePromptHelp.Visible = experimentalScenePromptEnabled
enableAutoHeightLabel(ui.scenePromptHelp, 24)
ui.scenePromptHelp.Parent = root

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
ui.guideRoot = guideRoot
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
ui.guidePanelTitle = guidePanelTitle

local guidePanelSubtitle = createLabel(
	"Use this as the in-plugin walkthrough for building a model from prompt to final stored asset.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(171, 183, 199),
	24
)
enableAutoHeightLabel(guidePanelSubtitle, 24)
guidePanelSubtitle.Parent = guideRoot
ui.guidePanelSubtitle = guidePanelSubtitle

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

function clearProceduralGuidebook()
	if not ui.guideRoot then
		return
	end
	for _, child in ipairs(ui.guideRoot:GetChildren()) do
		if child ~= ui.guidePanelTitle
			and child ~= ui.guidePanelSubtitle
			and not child:IsA("UIListLayout")
			and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

function createProceduralGuideCard(topColor, bottomColor, strokeColor)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 0)
	card.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	card.BorderSizePixel = 0
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Parent = ui.guideRoot
	card:SetAttribute("ProceduralGuidebookNode", true)
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

function addProceduralGuideBadge(parent, text, color, role)
	local badge = createButton(text, color, role)
	badge.AutoButtonColor = false
	badge.Active = false
	badge.Selectable = false
	badge.Size = UDim2.new(0, math.max(84, #text * 7 + 24), 0, 28)
	badge.TextSize = 11
	badge.Parent = parent
	return badge
end

function addProceduralGuideFeature(title, accentColor, role, summary, items)
	if not items or #items == 0 then
		return
	end
	local card = createProceduralGuideCard(
		accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.16),
		accentColor:Lerp(Color3.fromRGB(18, 22, 28), 0.72),
		accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.22)
	)

	local headerRow = Instance.new("Frame")
	headerRow.Size = UDim2.new(1, 0, 0, 30)
	headerRow.BackgroundTransparency = 1
	headerRow.Parent = card

	local badge = addProceduralGuideBadge(headerRow, title, accentColor, role)
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

		local itemLayoutInner = Instance.new("UIListLayout")
		itemLayoutInner.Padding = UDim.new(0, 4)
		itemLayoutInner.FillDirection = Enum.FillDirection.Vertical
		itemLayoutInner.SortOrder = Enum.SortOrder.LayoutOrder
		itemLayoutInner.Parent = itemRow

		local targetSpec = item[3]
		if targetSpec then
			local actionRow = Instance.new("Frame")
			actionRow.Size = UDim2.new(1, 0, 0, 28)
			actionRow.BackgroundTransparency = 1
			actionRow.LayoutOrder = 1
			actionRow.Parent = itemRow

			local focusButton = createButton("Show Me", accentColor, role)
			focusButton.Size = UDim2.new(0, 110, 1, 0)
			focusButton.Parent = actionRow
			focusButton.MouseButton1Click:Connect(function()
				focusGuideTarget(targetSpec)
			end)
		end

		local nameLabel = createLabel(item[1], 13, Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), 20)
		enableAutoHeightLabel(nameLabel, 20)
		nameLabel.LayoutOrder = targetSpec and 2 or 1
		nameLabel.Parent = itemRow

		local descLabel = createLabel(item[2], 12, Enum.Font.Gotham, Color3.fromRGB(177, 188, 203), 22)
		enableAutoHeightLabel(descLabel, 22)
		descLabel.LayoutOrder = targetSpec and 3 or 2
		descLabel.Parent = itemRow
	end
end

function rebuildGuidebook()
	if not ui.guideRoot then
		return
	end

	clearProceduralGuidebook()

	local stepItems = {}
	local orderedSteps = {
		{"step_prompt", "STEP 1", "Preset + Prompt", "Use the detail preset buttons and prompt box to define the model direction before touching the technical controls."},
		{"step_inputs", "STEP 2", "Tune Inputs", "Adjust size, triangle budget, schema, collider mode, seed, and generation toggles to shape cost, look, and repeatability."},
		{"step_preview", "STEP 3", "Preview", "Use preview first when available so you can validate silhouette, lighting, bounds, and collision before full generation."},
		{"step_generate", "STEP 4", "Generate", "Run the full generation pass once the request looks correct or regenerate the selected output when iterating."},
		{"step_store", "STEP 5", "Store", "Store only the variants you want available during play mode and use the storage tools to review or prune outputs."},
	}
	for _, step in ipairs(orderedSteps) do
		if ui.guideFocusGroups[step[1]] and #ui.guideFocusGroups[step[1]] > 0 then
			stepItems[#stepItems + 1] = {step[2] .. " " .. step[3], step[4], {stepId = step[1]}}
		end
	end
	addProceduralGuideFeature(
		"Workflow",
		Color3.fromRGB(75, 114, 96),
		"success",
		"This walkthrough is assembled from the actual interactive areas currently present in the plugin.",
		stepItems
	)

	local requestItems = {}
	if ui.promptBox then
		requestItems[#requestItems + 1] = {"Prompt Box", "Describe the object, major materials, silhouette, and standout details. The live request preview reflects the current input state.", {panel = "main", target = ui.promptBox}}
	end
	if ui.scenePromptBox and ui.scenePromptBox.Visible then
		requestItems[#requestItems + 1] = {"Scene Direction", "Add optional scene context when you want preview and generation to attempt a broader described environment around the subject.", {panel = "main", target = ui.scenePromptBox}}
	end
	if ui.mediumButton and ui.highButton and ui.ultraButton then
		requestItems[#requestItems + 1] = {"Detail Presets", "Medium, High, and Ultra provide quick triangle/detail starting points for exploration versus heavier output.", {panel = "main", target = ui.presetFrame}}
	end
	if ui.sizeBox and ui.trianglesBox then
		requestItems[#requestItems + 1] = {"Scale + Complexity", "Size controls overall scale while MaxTriangles sets the complexity ceiling for generation and preview budgets.", {panel = "main", target = ui.sizeBox}}
	end
	if ui.texturesToggleButton or ui.includeBaseToggleButton or ui.anchoredToggleButton then
		requestItems[#requestItems + 1] = {"Generation Toggles", "Texture generation, base inclusion, and anchored output are available directly on the main canvas for fast iteration.", {panel = "main", target = ui.texturesToggleButton or ui.includeBaseToggleButton or ui.anchoredToggleButton}}
	end
	addProceduralGuideFeature(
		"Request Setup",
		Color3.fromRGB(79, 133, 177),
		"info",
		"These controls define what gets sent to Roblox when you preview or generate.",
		requestItems
	)

	local actionItems = {}
	if ui.schemaBox then
		actionItems[#actionItems + 1] = {"Schema", "The schema field controls which Roblox generation schema name is used for the request.", {panel = "main", target = ui.schemaBox}}
	end
	if ui.colliderModeBox then
		actionItems[#actionItems + 1] = {"Collider Mode", "Collider mode determines how collision proxies are produced and how collision preview behaves.", {panel = "main", target = ui.colliderModeBox}}
	end
	if ui.seedBox or ui.randomSeedButton then
		actionItems[#actionItems + 1] = {"Seed Controls", "Reuse the current seed for consistency or randomize it for a new variation family.", {panel = "main", target = ui.seedBox or ui.randomSeedButton}}
	end
	if ui.previewButton then
		actionItems[#actionItems + 1] = {"Preview Button", "Preview uses the lighter preview budget so you can inspect candidates before committing to the full pass.", {panel = "main", target = ui.previewButton}}
	end
	if ui.generateButton or ui.regenerateSelectedButton then
		actionItems[#actionItems + 1] = {"Generate Actions", "Generate creates the full output, while Regenerate Selected reuses saved metadata from an existing generated model.", {panel = "main", target = ui.generateButton or ui.regenerateSelectedButton}}
	end
	addProceduralGuideFeature(
		"Generation Actions",
		Color3.fromRGB(62, 162, 109),
		"success",
		"The plugin exposes both exploratory and commit-stage generation tools.",
		actionItems
	)

	local previewItems = {}
	if ui.previewGenerateCurrentButton or ui.previewGenerateSelectedButton or ui.previewGenerateAllButton then
		previewItems[#previewItems + 1] = {"Preview Variant Actions", "Generate the current variant, selected variants, or the full preview batch directly from the preview panel.", {panel = "preview", target = ui.previewGenerateCurrentButton or ui.previewGenerateSelectedButton or ui.previewGenerateAllButton}}
	end
	if ui.previewFrontButton and ui.previewSideButton and ui.previewTopButton and ui.previewIsoButton then
		previewItems[#previewItems + 1] = {"Camera Presets", "Front, side, top, and isometric views help verify readability and bounding fit quickly.", {panel = "preview", target = ui.previewFrontButton}}
	end
	if ui.previewLightingButton or ui.previewBackgroundButton or ui.previewRotateSpeedButton then
		previewItems[#previewItems + 1] = {"Look Development", "Lighting, background, and auto-rotation speed controls let you inspect the result under multiple viewing conditions.", {panel = "preview", target = ui.previewLightingButton or ui.previewBackgroundButton or ui.previewRotateSpeedButton}}
	end
	if ui.previewOriginMarkerButton or ui.previewBoundsButton or ui.previewCollisionOpacityButton or collisionPreviewButton then
		previewItems[#previewItems + 1] = {"Validation Overlays", "Origin, bounds, collision opacity, and collision preview tools are available for technical inspection before storing or shipping a model.", {panel = "preview", target = ui.previewOriginMarkerButton or ui.previewBoundsButton or ui.previewCollisionOpacityButton or collisionPreviewButton}}
	end
	addProceduralGuideFeature(
		"Preview Panel",
		Color3.fromRGB(126, 84, 148),
		"purple",
		"The preview window acts as a turntable, comparison gallery, and technical validation station.",
		previewItems
	)

	local storageItems = {}
	if ui.runtimeButton or ui.runtimeAllButton then
		storageItems[#storageItems + 1] = {"Runtime Storage", "Store Selected Model and Store All Models move approved outputs into the runtime regeneration workflow.", {panel = "main", target = ui.runtimeButton or ui.runtimeAllButton}}
	end
	if ui.toggleStorageButton then
		storageItems[#storageItems + 1] = {"Stored Model Review", "Show Stored Models reveals what has already been saved into the runtime storage pipeline.", {panel = "main", target = ui.toggleStorageButton}}
	end
	if ui.cacheToggleButton or ui.clearCacheButton then
		storageItems[#storageItems + 1] = {"Cache Controls", "The settings panel exposes cache reuse and cache clearing so identical requests can be reused or fully rebuilt.", {panel = "settings", target = ui.cacheToggleButton or ui.clearCacheButton}}
	end
	addProceduralGuideFeature(
		"Storage + Iteration",
		Color3.fromRGB(201, 141, 78),
		"warning",
		"These tools control what persists beyond the current experiment and how much iteration history you keep around.",
		storageItems
	)

	local settingsItems = {}
	local orderedSections = {"settings", "prompt_tools", "theme_style", "experimental"}
	for _, sectionId in ipairs(orderedSections) do
		local section = ui.settingsSearchSections[sectionId]
		if section and section.header then
			local titleText = tostring(section.header.Text or sectionId)
			local detailText = section.helper and tostring(section.helper.Text or "") or ""
			if detailText == "" then
				detailText = "Open the settings panel to review the controls in this section."
			end
			settingsItems[#settingsItems + 1] = {titleText, detailText, {panel = "settings", target = section.header}}
		end
	end
	addProceduralGuideFeature(
		"Settings Map",
		Color3.fromRGB(84, 107, 146),
		"info",
		"The guidebook reads the current settings sections so it can explain the same groups available in the settings panel.",
		settingsItems
	)

	local experimentItems = {}
	if ui.experimentalStyleBiasButton then
		experimentItems[#experimentItems + 1] = {tostring(ui.experimentalStyleBiasButton.Text), "Bias the output direction toward categories like realistic, stylized, hard-surface, organic, or toy-like forms when supported.", {panel = "settings", target = ui.experimentalStyleBiasButton}}
	end
	if ui.experimentalPreviewModeButton then
		experimentItems[#experimentItems + 1] = {tostring(ui.experimentalPreviewModeButton.Text), "Change how aggressive preview simplification should be, trading speed against fidelity.", {panel = "settings", target = ui.experimentalPreviewModeButton}}
	end
	if ui.experimentalGroundSnapButton then
		experimentItems[#experimentItems + 1] = {tostring(ui.experimentalGroundSnapButton.Text), "Place generated output with its base aligned to the ground plane instead of centering the pivot at the origin.", {panel = "settings", target = ui.experimentalGroundSnapButton}}
	end
	if #experimentItems > 0 then
		addProceduralGuideFeature(
			"Experimental Controls",
			Color3.fromRGB(133, 74, 62),
			"warning",
			"Experimental tools are generated from the controls currently exposed in the experimental settings section.",
			experimentItems
		)
	end
end

function clearProceduralSettingsOverview()
	if not ui.settingsProceduralFrame then
		return
	end
	for _, child in ipairs(ui.settingsProceduralFrame:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

function createProceduralSettingsCard(topColor, bottomColor, strokeColor)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 0)
	card.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	card.BorderSizePixel = 0
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Parent = ui.settingsProceduralFrame
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

function addProceduralSettingsFeature(title, accentColor, role, summary, items)
	if not ui.settingsProceduralFrame or not items or #items == 0 then
		return
	end

	local card = createProceduralSettingsCard(
		accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.16),
		accentColor:Lerp(Color3.fromRGB(18, 22, 28), 0.72),
		accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.22)
	)

	local headerRow = Instance.new("Frame")
	headerRow.Size = UDim2.new(1, 0, 0, 30)
	headerRow.BackgroundTransparency = 1
	headerRow.Parent = card

	local badge = createButton(title, accentColor, role)
	badge.AutoButtonColor = false
	badge.Active = false
	badge.Selectable = false
	badge.Size = UDim2.new(0, math.max(110, #title * 7 + 24), 0, 28)
	badge.TextSize = 11
	badge.Parent = headerRow

	local summaryLabel = createLabel(summary, 12, Enum.Font.Gotham, Color3.fromRGB(216, 223, 232), 24)
	enableAutoHeightLabel(summaryLabel, 24)
	summaryLabel.Parent = card

	for _, item in ipairs(items) do
		local itemRow = Instance.new("Frame")
		itemRow.Size = UDim2.new(1, 0, 0, 0)
		itemRow.BackgroundColor3 = Color3.fromRGB(23, 28, 36)
		itemRow.BorderSizePixel = 0
		itemRow.AutomaticSize = Enum.AutomaticSize.Y
		itemRow.Parent = card
		styleCard(itemRow, Color3.fromRGB(48, 56, 70), Color3.fromRGB(27, 32, 40), Color3.fromRGB(90, 104, 128), false)

		local itemPadding = Instance.new("UIPadding")
		itemPadding.PaddingTop = UDim.new(0, 8)
		itemPadding.PaddingBottom = UDim.new(0, 8)
		itemPadding.PaddingLeft = UDim.new(0, 8)
		itemPadding.PaddingRight = UDim.new(0, 8)
		itemPadding.Parent = itemRow

		local itemLayout = Instance.new("UIListLayout")
		itemLayout.Padding = UDim.new(0, 4)
		itemLayout.FillDirection = Enum.FillDirection.Vertical
		itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
		itemLayout.Parent = itemRow

		local target = item.target
		if target and target.Parent then
			local actionRow = Instance.new("Frame")
			actionRow.Size = UDim2.new(1, 0, 0, 28)
			actionRow.BackgroundTransparency = 1
			actionRow.LayoutOrder = 1
			actionRow.Parent = itemRow

			local focusButton = createButton("Show Me", accentColor, role)
			focusButton.Size = UDim2.new(0, 110, 1, 0)
			focusButton.Parent = actionRow
			focusButton.MouseButton1Click:Connect(function()
				scrollSettingsTargetIntoView(target)
				pulseGuideFocusTarget(target)
			end)
		end

		local nameLabel = createLabel(item.title or "Setting", 13, Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), 20)
		enableAutoHeightLabel(nameLabel, 20)
		nameLabel.LayoutOrder = target and 2 or 1
		nameLabel.Parent = itemRow

		local descLabel = createLabel(item.description or "", 12, Enum.Font.Gotham, Color3.fromRGB(177, 188, 203), 22)
		enableAutoHeightLabel(descLabel, 22)
		descLabel.LayoutOrder = target and 3 or 2
		descLabel.Parent = itemRow
	end
end

function rebuildProceduralSettingsOverview()
	if not ui.settingsProceduralFrame then
		return
	end

	clearProceduralSettingsOverview()

	local overviewTitle = createLabel("Settings Navigator", 18, Enum.Font.GothamBold, Color3.fromRGB(245, 247, 250), 24)
	enableAutoHeightLabel(overviewTitle, 24)
	overviewTitle.Parent = ui.settingsProceduralFrame

	local overviewHelp = createLabel(
		"This settings layer is assembled from the live controls below so it stays aligned with the actual plugin state.",
		12,
		Enum.Font.Gotham,
		Color3.fromRGB(171, 183, 199),
		24
	)
	enableAutoHeightLabel(overviewHelp, 24)
	overviewHelp.Parent = ui.settingsProceduralFrame

	local coreItems = {}
	if ui.cacheToggleButton then
		coreItems[#coreItems + 1] = {title = tostring(ui.cacheToggleButton.Text), description = "Reuse identical preview and generation requests instead of rebuilding every time.", target = ui.cacheToggleButton}
	end
	if ui.clearCacheButton then
		coreItems[#coreItems + 1] = {title = tostring(ui.clearCacheButton.Text), description = "Flush stored preview and generation cache entries and force clean rebuilds.", target = ui.clearCacheButton}
	end
	if ui.autoOpenPreviewButton then
		coreItems[#coreItems + 1] = {title = tostring(ui.autoOpenPreviewButton.Text), description = "Control whether the preview dock opens automatically after full generation.", target = ui.autoOpenPreviewButton}
	end
	if ui.uiAudioToggleButton then
		coreItems[#coreItems + 1] = {title = tostring(ui.uiAudioToggleButton.Text), description = "Toggle smaller UI sound effects and adjust their loudness with the slider.", target = ui.uiAudioToggleButton}
	end
	if ui.themeChangeAudioToggleButton then
		coreItems[#coreItems + 1] = {title = tostring(ui.themeChangeAudioToggleButton.Text), description = "Toggle theme-change audio and tune how strong theme transition cues feel.", target = ui.themeChangeAudioToggleButton}
	end
	if ui.showAdvancedCollisionButton then
		coreItems[#coreItems + 1] = {title = tostring(ui.showAdvancedCollisionButton.Text), description = "Expose or hide the extra collision heuristic controls in the main panel.", target = ui.showAdvancedCollisionButton}
	end
	if ui.confirmStoreAllButton then
		coreItems[#coreItems + 1] = {title = tostring(ui.confirmStoreAllButton.Text), description = "Require a confirmation before storing every generated result into runtime storage.", target = ui.confirmStoreAllButton}
	end
	if ui.historyLogBox then
		coreItems[#coreItems + 1] = {title = "Prompt History Log", description = "Review the recent prompt log without leaving the settings area.", target = ui.historyLogBox}
	end
	addProceduralSettingsFeature(
		"Core Settings",
		Color3.fromRGB(84, 107, 146),
		"info",
		"Core behavior, cache, audio, confirmation, and history tools are summarized from the current settings controls.",
		coreItems
	)

	local promptItems = {}
	if ui.favoritePromptButton then
		promptItems[#promptItems + 1] = {title = tostring(ui.favoritePromptButton.Text), description = "Store the current prompt into the reusable prompt library.", target = ui.favoritePromptButton}
	end
	if ui.unfavoritePromptButton then
		promptItems[#promptItems + 1] = {title = tostring(ui.unfavoritePromptButton.Text), description = "Remove the currently loaded prompt from favorites.", target = ui.unfavoritePromptButton}
	end
	if ui.favoritePromptButtons and ui.favoritePromptButtons[1] then
		promptItems[#promptItems + 1] = {title = "Favorite Prompt Slots", description = "Quick-load the prompts you saved into the favorite slots.", target = ui.favoritePromptButtons[1]}
	end
	if ui.recentPromptButtons and ui.recentPromptButtons[1] then
		promptItems[#promptItems + 1] = {title = "Recent Prompt Reloads", description = "Reload one of the most recent prompts directly back into the main canvas.", target = ui.recentPromptButtons[1]}
	end
	if ui.namePatternButton then
		promptItems[#promptItems + 1] = {title = tostring(ui.namePatternButton.Text), description = "Choose how generated outputs are named when batches are created.", target = ui.namePatternButton}
	end
	if ui.batchLayoutButton then
		promptItems[#promptItems + 1] = {title = tostring(ui.batchLayoutButton.Text), description = "Change how variation batches are arranged or grouped after generation.", target = ui.batchLayoutButton}
	end
	addProceduralSettingsFeature(
		"Prompt Library",
		Color3.fromRGB(57, 128, 116),
		"success",
		"Reusable prompts, reload shortcuts, naming, and batch organization are built from the current prompt tooling controls.",
		promptItems
	)

	local themeItems = {}
	if themeUi.variantButton then
		themeItems[#themeItems + 1] = {title = tostring(themeUi.variantButton.Text), description = "Shift the active theme toward softer, louder, or darker structural styling.", target = themeUi.variantButton}
	end
	if themeUi.toneButton then
		themeItems[#themeItems + 1] = {title = tostring(themeUi.toneButton.Text), description = "Apply a global tonal bias such as cool, warm, verdant, or neon.", target = themeUi.toneButton}
	end
	if themeUi.contrastButton then
		themeItems[#themeItems + 1] = {title = tostring(themeUi.contrastButton.Text), description = "Control how separated and punchy the interface feels.", target = themeUi.contrastButton}
	end
	if themeUi.typographyButton then
		themeItems[#themeItems + 1] = {title = tostring(themeUi.typographyButton.Text), description = "Swap typography direction without changing the base theme preset.", target = themeUi.typographyButton}
	end
	if themeUi.resetStylingButton then
		themeItems[#themeItems + 1] = {title = tostring(themeUi.resetStylingButton.Text), description = "Reset the styling stack back to the base theme defaults.", target = themeUi.resetStylingButton}
	end
	addProceduralSettingsFeature(
		"Theme Styling",
		Color3.fromRGB(126, 84, 148),
		"purple",
		"The current theme lab options are pulled from the live styling controls below.",
		themeItems
	)

	local experimentalItems = {}
	if ui.experimentalNegativePromptBox then
		experimentalItems[#experimentalItems + 1] = {title = "Negative Prompt", description = "Tell the generator what to avoid when shaping the final result.", target = ui.experimentalNegativePromptBox}
	end
	if ui.experimentalScenePromptButton then
		experimentalItems[#experimentalItems + 1] = {title = tostring(ui.experimentalScenePromptButton.Text), description = "Expose an extra scene-direction field in the main panel for broader environment attempts.", target = ui.experimentalScenePromptButton}
	end
	if ui.experimentalStyleBiasButton then
		experimentalItems[#experimentalItems + 1] = {title = tostring(ui.experimentalStyleBiasButton.Text), description = "Bias the generated result toward a particular visual family.", target = ui.experimentalStyleBiasButton}
	end
	if ui.experimentalPreviewModeButton then
		experimentalItems[#experimentalItems + 1] = {title = tostring(ui.experimentalPreviewModeButton.Text), description = "Trade preview speed against fidelity before running the final pass.", target = ui.experimentalPreviewModeButton}
	end
	if ui.experimentalGroundSnapButton then
		experimentalItems[#experimentalItems + 1] = {title = tostring(ui.experimentalGroundSnapButton.Text), description = "Align the generated model base to the ground plane at origin.", target = ui.experimentalGroundSnapButton}
	end
	addProceduralSettingsFeature(
		"Experimental",
		Color3.fromRGB(133, 74, 62),
		"warning",
		"Experimental controls are generated from whichever advanced options are currently exposed in the settings panel.",
		experimentalItems
	)

	local licensingItems = {
		{
			title = "Plugin Ownership",
			description = "This plugin implementation, interface, workflow, and tool design belong to the plugin creator. This section does not claim ownership over Roblox platform technology."
		},
		{
			title = "Roblox Cube 3D Attribution",
			description = "Model generation relies on Roblox generation technology, including Cube 3D capabilities and related Roblox services, which remain Roblox technology and are governed by Roblox platform terms."
		},
		{
			title = "Rights + Responsibility",
			description = "Prompt content, generated assets, trademark usage, and platform deployment remain subject to Roblox terms, community standards, and any applicable third-party rights."
		},
	}
	addProceduralSettingsFeature(
		"Licensing + Attribution",
		Color3.fromRGB(171, 137, 93),
		"warning",
		"Ownership and attribution notes for the plugin implementation and the Roblox-powered generation stack it uses.",
		licensingItems
	)
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

ui.settingsProceduralFrame = Instance.new("Frame")
ui.settingsProceduralFrame.Size = UDim2.new(1, 0, 0, 0)
ui.settingsProceduralFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
ui.settingsProceduralFrame.BorderSizePixel = 0
ui.settingsProceduralFrame.AutomaticSize = Enum.AutomaticSize.Y
ui.settingsProceduralFrame.LayoutOrder = 2
ui.settingsProceduralFrame.Visible = false
ui.settingsProceduralFrame.Parent = ui.settingsPanel
styleCard(ui.settingsProceduralFrame, Color3.fromRGB(61, 74, 101), Color3.fromRGB(37, 45, 61), Color3.fromRGB(118, 141, 186), false)

do
	local settingsProceduralPadding = Instance.new("UIPadding")
	settingsProceduralPadding.PaddingTop = UDim.new(0, 10)
	settingsProceduralPadding.PaddingBottom = UDim.new(0, 10)
	settingsProceduralPadding.PaddingLeft = UDim.new(0, 10)
	settingsProceduralPadding.PaddingRight = UDim.new(0, 10)
	settingsProceduralPadding.Parent = ui.settingsProceduralFrame

	local settingsProceduralLayout = Instance.new("UIListLayout")
	settingsProceduralLayout.Padding = UDim.new(0, 8)
	settingsProceduralLayout.FillDirection = Enum.FillDirection.Vertical
	settingsProceduralLayout.Parent = ui.settingsProceduralFrame
end

do
	local settingsGroup, settingsSectionTitle, settingsSectionHelp = createSettingsGroup(
		"Settings",
		"Core plugin behavior, cache, preview defaults, and prompt history tools."
	)
	settingsGroup.LayoutOrder = 3
	registerSettingsSection("settings", settingsSectionTitle, "settings cache behavior preview history core options", settingsSectionHelp)
	ui.settingsSearchSections.settings.container = settingsGroup
	ui.activeSettingsGroup = settingsGroup

	do
		local cacheGroup, cacheGroupTitle, cacheGroupHelp = createSettingsSubgroup(
			settingsGroup,
			"Cache & Rebuild",
			"Reuse saved results for speed, or clear them when you need a clean rebuild.",
			Color3.fromRGB(79, 96, 131),
			Color3.fromRGB(38, 47, 64),
			Color3.fromRGB(120, 146, 193)
		)
		registerSettingsSearchEntry(cacheGroupTitle, "cache rebuild cached models preview generate reuse clear", "settings")
		registerSettingsSearchEntry(cacheGroupHelp, "cache rebuild cached models preview generate reuse clear", "settings")
		ui.activeSettingsGroup = cacheGroup

		local cacheToggleCard, cacheToggleTitle, cacheToggleContent = createSettingsOptionRow(
			"Reuse Cached Results",
			Color3.fromRGB(93, 119, 164)
		)
		registerSettingsSearchEntry(cacheToggleTitle, "reuse cached results cache enable disable generation preview", "settings")

		ui.cacheToggleButton = createButton("Cache: Off", Color3.fromRGB(86, 99, 125), "muted")
		ui.cacheToggleButton.Size = UDim2.new(1, 0, 1, 0)
		ui.cacheToggleButton.Parent = cacheToggleContent
		registerSettingsSearchEntry(ui.cacheToggleButton, "cache enable disable cached models generation cache", "settings", true)
		registerSettingsShortcut("Reuse Cached Results", ui.cacheToggleButton, "cache reuse cached results enable disable generation preview", "settings")

		local clearCacheCard, clearCacheTitle, clearCacheContent = createSettingsOptionRow(
			"Clear Cached Results",
			Color3.fromRGB(166, 117, 66)
		)
		registerSettingsSearchEntry(clearCacheTitle, "clear cached results cache delete reset", "settings")

		ui.clearCacheButton = createButton("Clear Cached Models", Color3.fromRGB(156, 111, 62), "warning")
		ui.clearCacheButton.Size = UDim2.new(1, 0, 1, 0)
		ui.clearCacheButton.Parent = clearCacheContent
		registerSettingsSearchEntry(ui.clearCacheButton, "clear cached models cache delete cached previews", "settings", true)
		registerSettingsShortcut("Clear Cached Results", ui.clearCacheButton, "clear cache cached models delete cached previews reset", "settings")
	end

	do
		local behaviorGroup, behaviorGroupTitle, behaviorGroupHelp = createSettingsSubgroup(
			settingsGroup,
			"Behavior & Workflow",
			"Control preview opening and whether advanced tuning tools are exposed during day-to-day use.",
			Color3.fromRGB(76, 91, 118),
			Color3.fromRGB(34, 42, 57),
			Color3.fromRGB(109, 131, 173)
		)
		registerSettingsSearchEntry(behaviorGroupTitle, "behavior workflow preview advanced collision tuning controls", "settings")
		registerSettingsSearchEntry(behaviorGroupHelp, "behavior workflow preview advanced collision tuning controls", "settings")
		ui.activeSettingsGroup = behaviorGroup

		local autoPreviewCard, autoPreviewTitle, autoPreviewContent = createSettingsOptionRow(
			"Open Preview After Generate",
			Color3.fromRGB(95, 117, 163)
		)
		registerSettingsSearchEntry(autoPreviewTitle, "auto open preview after generate preview panel", "settings")

		ui.autoOpenPreviewButton = createButton("Auto-open Preview: Off", Color3.fromRGB(86, 99, 125), "muted")
		ui.autoOpenPreviewButton.Size = UDim2.new(1, 0, 1, 0)
		ui.autoOpenPreviewButton.Parent = autoPreviewContent
		registerSettingsSearchEntry(ui.autoOpenPreviewButton, "auto open preview preview window behavior", "settings", true)
		registerSettingsShortcut("Open Preview After Generate", ui.autoOpenPreviewButton, "auto open preview after generate preview panel", "settings")

		local advancedCollisionCard, advancedCollisionTitle, advancedCollisionContent = createSettingsOptionRow(
			"Show Advanced Collision Tuning",
			Color3.fromRGB(95, 117, 163)
		)
		registerSettingsSearchEntry(advancedCollisionTitle, "show advanced collision tuning heuristics collider inputs", "settings")

		ui.showAdvancedCollisionButton = createButton("Advanced Collision Tuning: Off", Color3.fromRGB(86, 99, 125), "muted")
		ui.showAdvancedCollisionButton.Size = UDim2.new(1, 0, 1, 0)
		ui.showAdvancedCollisionButton.Parent = advancedCollisionContent
		registerSettingsSearchEntry(ui.showAdvancedCollisionButton, "advanced collision tuning heuristics collider settings", "settings", true)
		registerSettingsShortcut("Show Advanced Collision Tuning", ui.showAdvancedCollisionButton, "advanced collision tuning heuristics collider settings", "settings")
	end

	do
		local audioGroup, audioGroupTitle, audioGroupHelp = createSettingsSubgroup(
			settingsGroup,
			"Audio",
			"Toggle interface sounds on or off and tune the loudness for UI feedback and theme-change cues separately.",
			Color3.fromRGB(71, 101, 124),
			Color3.fromRGB(34, 47, 58),
			Color3.fromRGB(103, 150, 182)
		)
		registerSettingsSearchEntry(audioGroupTitle, "audio sound sfx ui theme volume slider toggle", "settings")
		registerSettingsSearchEntry(audioGroupHelp, "audio sound sfx ui theme volume slider toggle", "settings")
		ui.activeSettingsGroup = audioGroup

		local uiAudioToggleCard, uiAudioToggleTitle, uiAudioToggleContent = createSettingsOptionRow(
			"UI Audio",
			Color3.fromRGB(84, 107, 146)
		)
		registerSettingsSearchEntry(uiAudioToggleTitle, "ui audio on off sound effects click toggle", "settings")

		ui.uiAudioToggleButton = createButton("UI Audio: On", Color3.fromRGB(84, 107, 146), "info")
		ui.uiAudioToggleButton.Size = UDim2.new(1, 0, 1, 0)
		ui.uiAudioToggleButton.Parent = uiAudioToggleContent
		registerSettingsSearchEntry(ui.uiAudioToggleButton, "ui audio on off sound effects click toggle", "settings", true)

		ui.uiAudioSlider = createVolumeSlider(Color3.fromRGB(84, 107, 146), function(value)
			uiAudioVolumeLevel = value
			setSetting(SETTINGS.uiAudioVolume, uiAudioVolumeLevel)
			updateSettingsButton()
		end, "UI Audio Level", "Sets how loud button clicks and smaller interface sound effects feel.")
		ui.uiAudioSlider.frame.Parent = ui.activeSettingsGroup
		if ui.uiAudioSlider.titleLabel then
			registerSettingsSearchEntry(ui.uiAudioSlider.titleLabel, "ui audio volume sound effects click volume mute low medium high", "settings")
		end
		if ui.uiAudioSlider.descriptionLabel then
			registerSettingsSearchEntry(ui.uiAudioSlider.descriptionLabel, "ui audio volume sound effects click volume mute low medium high", "settings")
		end
		registerSettingsSearchEntry(ui.uiAudioSlider.frame, "ui audio volume slider sound effects click loudness", "settings")
		registerSettingsShortcut("UI Audio Volume", ui.uiAudioSlider.frame, "ui audio volume slider sound effects click loudness", "settings")

		local themeAudioToggleCard, themeAudioToggleTitle, themeAudioToggleContent = createSettingsOptionRow(
			"Theme Change Audio",
			Color3.fromRGB(57, 128, 116)
		)
		registerSettingsSearchEntry(themeAudioToggleTitle, "theme change audio on off sound switch toggle", "settings")

		ui.themeChangeAudioToggleButton = createButton("Theme Change Audio: On", Color3.fromRGB(57, 128, 116), "teal")
		ui.themeChangeAudioToggleButton.Size = UDim2.new(1, 0, 1, 0)
		ui.themeChangeAudioToggleButton.Parent = themeAudioToggleContent
		registerSettingsSearchEntry(ui.themeChangeAudioToggleButton, "theme change audio on off sound switch toggle", "settings", true)

		ui.themeChangeAudioSlider = createVolumeSlider(Color3.fromRGB(57, 128, 116), function(value)
			themeChangeAudioVolumeLevel = value
			setSetting(SETTINGS.themeChangeAudioVolume, themeChangeAudioVolumeLevel)
			updateSettingsButton()
		end, "Theme Audio Level", "Sets how loud theme swaps and styling-change sounds feel.")
		ui.themeChangeAudioSlider.frame.Parent = ui.activeSettingsGroup
		if ui.themeChangeAudioSlider.titleLabel then
			registerSettingsSearchEntry(ui.themeChangeAudioSlider.titleLabel, "theme change volume sound audio theme switch mute low medium high", "settings")
		end
		if ui.themeChangeAudioSlider.descriptionLabel then
			registerSettingsSearchEntry(ui.themeChangeAudioSlider.descriptionLabel, "theme change volume sound audio theme switch mute low medium high", "settings")
		end
		registerSettingsSearchEntry(ui.themeChangeAudioSlider.frame, "theme change volume slider sound audio switch loudness", "settings")
		registerSettingsShortcut("Theme Change Volume", ui.themeChangeAudioSlider.frame, "theme change volume slider sound audio switch loudness", "settings")

		local completionAudioCard, completionAudioTitle, completionAudioContent = createSettingsOptionRow(
			"Completion Audio",
			Color3.fromRGB(96, 140, 90)
		)
		registerSettingsSearchEntry(completionAudioTitle, "variation completion audio done complete finished dramatic sound toggle", "settings")

		ui.variationCompletionAudioToggleButton = createButton("Variation Completion Audio: On", Color3.fromRGB(96, 140, 90), "active")
		ui.variationCompletionAudioToggleButton.Size = UDim2.new(1, 0, 1, 0)
		ui.variationCompletionAudioToggleButton.Parent = completionAudioContent
		registerSettingsSearchEntry(ui.variationCompletionAudioToggleButton, "variation completion audio done complete finished dramatic sound toggle", "settings", true)
		registerSettingsShortcut("Variation Completion Audio", ui.variationCompletionAudioToggleButton, "variation completion audio done complete finished dramatic sound toggle", "settings")
	end

	do
		local safetyGroup, safetyGroupTitle, safetyGroupHelp = createSettingsSubgroup(
			settingsGroup,
			"Safety",
			"Add confirmation around bulk runtime-storage actions so destructive batch operations are less accidental.",
			Color3.fromRGB(112, 90, 64),
			Color3.fromRGB(50, 39, 27),
			Color3.fromRGB(171, 137, 93)
		)
		registerSettingsSearchEntry(safetyGroupTitle, "safety confirmation store all runtime bulk actions", "settings")
		registerSettingsSearchEntry(safetyGroupHelp, "safety confirmation store all runtime bulk actions", "settings")
		ui.activeSettingsGroup = safetyGroup

		local confirmStoreAllCard, confirmStoreAllTitle, confirmStoreAllContent = createSettingsOptionRow(
			"Require Confirmation for Store All",
			Color3.fromRGB(171, 137, 93)
		)
		registerSettingsSearchEntry(confirmStoreAllTitle, "require confirmation store all models safety", "settings")

		ui.confirmStoreAllButton = createButton("Confirm Store All: Off", Color3.fromRGB(86, 99, 125), "muted")
		ui.confirmStoreAllButton.Size = UDim2.new(1, 0, 1, 0)
		ui.confirmStoreAllButton.Parent = confirmStoreAllContent
		registerSettingsSearchEntry(ui.confirmStoreAllButton, "confirm store all models safety behavior", "settings", true)
		registerSettingsShortcut("Require Confirmation for Store All", ui.confirmStoreAllButton, "confirm store all models safety behavior", "settings")
	end

	do
		local historyGroup, historyGroupTitle, historyGroupHelp = createSettingsSubgroup(
			settingsGroup,
			"Prompt History",
			"Review recent prompts inside settings so you can recover ideas or rerun older request directions quickly.",
			Color3.fromRGB(78, 94, 114),
			Color3.fromRGB(34, 42, 54),
			Color3.fromRGB(112, 134, 166)
		)
		registerSettingsSearchEntry(historyGroupTitle, "recent prompts history prompt recall log", "settings")
		registerSettingsSearchEntry(historyGroupHelp, "recent prompts history prompt recall log", "settings")
		ui.activeSettingsGroup = historyGroup

		local historyLogCard, historyLogTitle, historyLogHelp, historyLogContent = createInlineSettingsControl(
			"Prompt History Log",
			"Shows your most recent prompts in a console-style log for quick reference.",
			Color3.fromRGB(111, 134, 166)
		)
		historyLogCard.Parent = ui.activeSettingsGroup
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
		ui.historyLogBox.Parent = historyLogContent
		registerSettingsSearchEntry(ui.historyLogBox, "prompt history log recent prompts console", "settings", true)
		registerSettingsShortcut("Prompt History Log", ui.historyLogBox, "prompt history log recent prompts console", "settings")
	end

	do
		local updatesGroup, updatesGroupTitle, updatesGroupHelp = createSettingsSubgroup(
			settingsGroup,
			"Updates & Version",
			"Shows the installed plugin build, checks the GitHub repository for the latest published release, and explains the manual update path.",
			Color3.fromRGB(82, 104, 138),
			Color3.fromRGB(36, 47, 64),
			Color3.fromRGB(132, 167, 214)
		)
		registerSettingsSearchEntry(updatesGroupTitle, "updates version github release updater repository current version latest release", "settings")
		registerSettingsSearchEntry(updatesGroupHelp, "updates version github release updater repository current version latest release", "settings")
		ui.activeSettingsGroup = updatesGroup

		local currentVersionCard, currentVersionTitle, currentVersionHelp, currentVersionContent = createInlineSettingsControl(
			"Installed Version",
			"The local plugin build string currently embedded in this file.",
			Color3.fromRGB(112, 146, 198)
		)
		currentVersionCard.Parent = ui.activeSettingsGroup
		registerSettingsSearchEntry(currentVersionTitle, "installed version current plugin version local build", "settings")
		registerSettingsSearchEntry(currentVersionHelp, "installed version current plugin version local build", "settings")

		ui.currentVersionLabel = createLabel("", 12, Enum.Font.GothamBold, Color3.fromRGB(230, 238, 247), 22)
		enableAutoHeightLabel(ui.currentVersionLabel, 22)
		ui.currentVersionLabel.Parent = currentVersionContent
		registerSettingsSearchEntry(ui.currentVersionLabel, "installed version current plugin version local build", "settings", true)

		local latestReleaseCard, latestReleaseTitle, latestReleaseHelp, latestReleaseContent = createInlineSettingsControl(
			"Latest GitHub Release",
			"Queries the configured repository release feed. This checker does not overwrite the local plugin file automatically.",
			Color3.fromRGB(96, 129, 178)
		)
		latestReleaseCard.Parent = ui.activeSettingsGroup
		registerSettingsSearchEntry(latestReleaseTitle, "latest github release update checker release feed repository", "settings")
		registerSettingsSearchEntry(latestReleaseHelp, "latest github release update checker release feed repository", "settings")

		ui.latestVersionLabel = createLabel("", 12, Enum.Font.GothamBold, Color3.fromRGB(234, 240, 248), 34)
		enableAutoHeightLabel(ui.latestVersionLabel, 34)
		ui.latestVersionLabel.Parent = latestReleaseContent
		registerSettingsSearchEntry(ui.latestVersionLabel, "latest github release update checker release feed repository", "settings", true)

		ui.updateStatusLabel = createLabel("", 11, Enum.Font.Code, Color3.fromRGB(184, 199, 219), 36)
		enableAutoHeightLabel(ui.updateStatusLabel, 36)
		ui.updateStatusLabel.Parent = latestReleaseContent
		registerSettingsSearchEntry(ui.updateStatusLabel, "update status github check result manual install", "settings", true)

		ui.checkUpdatesButton = createButton("Check GitHub Release", Color3.fromRGB(84, 107, 146), "info")
		ui.checkUpdatesButton.Size = UDim2.new(1, 0, 0, 34)
		ui.checkUpdatesButton.Parent = ui.activeSettingsGroup
		registerSettingsSearchEntry(ui.checkUpdatesButton, "check github release updates latest version updater", "settings", true)
		registerSettingsShortcut("Check GitHub Release", ui.checkUpdatesButton, "check github release updates latest version updater", "settings")

		ui.updateReleaseButton = createButton("Release Install Is Manual", Color3.fromRGB(123, 101, 72), "secondary")
		ui.updateReleaseButton.Size = UDim2.new(1, 0, 0, 34)
		ui.updateReleaseButton.Parent = ui.activeSettingsGroup
		registerSettingsSearchEntry(ui.updateReleaseButton, "manual install update release latest github", "settings", true)

		local releaseUrlCard, releaseUrlTitle, releaseUrlHelp, releaseUrlContent = createInlineSettingsControl(
			"Release URL",
			"Copy this link manually to open the GitHub release page outside Studio when an update is available.",
			Color3.fromRGB(112, 129, 160)
		)
		releaseUrlCard.Parent = ui.activeSettingsGroup
		registerSettingsSearchEntry(releaseUrlTitle, "release url github repository manual install link", "settings")
		registerSettingsSearchEntry(releaseUrlHelp, "release url github repository manual install link", "settings")

		ui.updateReleaseUrlBox = createTextBox(
			58,
			"GitHub release URL",
			PLUGIN_GITHUB_RELEASES_URL,
			Enum.Font.Code
		)
		ui.updateReleaseUrlBox.TextWrapped = true
		ui.updateReleaseUrlBox.TextEditable = false
		ui.updateReleaseUrlBox.ClearTextOnFocus = false
		ui.updateReleaseUrlBox.Parent = releaseUrlContent
		registerSettingsSearchEntry(ui.updateReleaseUrlBox, "release url github repository manual install link", "settings", true)
	end

	ui.activeSettingsGroup = settingsGroup
end

do
	local promptToolsGroup, promptToolsTitle, promptToolsHelp = createSettingsGroup(
		"Prompt Library",
		"Save reusable prompts, reload favorite briefs quickly, and control naming/layout defaults for generated batches."
	)
	promptToolsGroup.LayoutOrder = 4
	registerSettingsSection("prompt_tools", promptToolsTitle, "prompt favorites saved prompts naming layout regenerate batch", promptToolsHelp)
	ui.settingsSearchSections.prompt_tools.container = promptToolsGroup
	ui.activeSettingsGroup = promptToolsGroup

	ui.favoritePromptButton = createButton("Favorite Current Prompt", Color3.fromRGB(57, 128, 116), "teal")
	ui.favoritePromptButton.Size = UDim2.new(1, 0, 0, 34)
	ui.favoritePromptButton.Parent = ui.activeSettingsGroup
	registerSettingsSearchEntry(ui.favoritePromptButton, "favorite current prompt save prompt library bookmark", "prompt_tools", true)
	registerSettingsShortcut("Favorite Current Prompt", ui.favoritePromptButton, "favorite current prompt save prompt library bookmark", "prompt_tools")

ui.unfavoritePromptButton = createButton("Remove Current Favorite", Color3.fromRGB(123, 101, 72), "warning")
ui.unfavoritePromptButton.Size = UDim2.new(1, 0, 0, 34)
ui.unfavoritePromptButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(ui.unfavoritePromptButton, "remove current favorite prompt unfavorite bookmark", "prompt_tools", true)
registerSettingsShortcut("Remove Current Favorite", ui.unfavoritePromptButton, "remove current favorite prompt unfavorite bookmark", "prompt_tools")

local favoritesTitle = createSectionTitle("Favorite Prompts")
favoritesTitle.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(favoritesTitle, "favorite prompts saved prompt library reuse", "prompt_tools")

ui.favoritePromptButtons = {}
for index = 1, 3 do
	local button = createButton(("Favorite %d"):format(index), Color3.fromRGB(90, 110, 140), "secondary")
	button.Size = UDim2.new(1, 0, 0, 34)
	button.Parent = ui.activeSettingsGroup
	ui.favoritePromptButtons[index] = button
	registerSettingsSearchEntry(button, "favorite prompt saved prompt reuse load", "prompt_tools", true)
end

local recentTitle = createSectionTitle("Quick Reload Recent")
recentTitle.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(recentTitle, "recent prompts quick reload rerun history", "prompt_tools")

ui.recentPromptButtons = {}
for index = 1, 3 do
	local button = createButton(("Recent %d"):format(index), Color3.fromRGB(84, 107, 146), "info")
	button.Size = UDim2.new(1, 0, 0, 34)
	button.Parent = ui.activeSettingsGroup
	ui.recentPromptButtons[index] = button
	registerSettingsSearchEntry(button, "recent prompt quick reload rerun history", "prompt_tools", true)
end

ui.namePatternButton = createButton("Name Pattern: Prompt", Color3.fromRGB(67, 126, 141), "accent")
ui.namePatternButton.Size = UDim2.new(1, 0, 0, 34)
ui.namePatternButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(ui.namePatternButton, "name pattern output naming prompt seed index", "prompt_tools", true)
registerSettingsShortcut("Output Name Pattern", ui.namePatternButton, "name pattern output naming prompt seed index", "prompt_tools")

	ui.batchLayoutButton = createButton("Batch Layout: Folder Only", Color3.fromRGB(90, 110, 140), "secondary")
	ui.batchLayoutButton.Size = UDim2.new(1, 0, 0, 34)
	ui.batchLayoutButton.Parent = ui.activeSettingsGroup
	registerSettingsSearchEntry(ui.batchLayoutButton, "batch layout row grid folder placement arrange variations", "prompt_tools", true)
	registerSettingsShortcut("Batch Layout", ui.batchLayoutButton, "batch layout row grid folder placement arrange variations", "prompt_tools")
end

do
	local themeStyleGroup, themeStyleTitle, themeStyleHelp = createSettingsGroup(
		"Theme Styling Lab",
		"Push the selected UI theme into softer, louder, warmer, cooler, or different typography directions without switching the base preset."
	)
	themeStyleGroup.LayoutOrder = 5
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
end

do
	local experimentalGroup, experimentalTitle, experimentalHelp = createSettingsGroup(
		"Experimental Settings",
		"Active but more volatile controls for stronger prompt steering, faster previews, or alternate placement behavior."
	)
	experimentalGroup.LayoutOrder = 6
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

local scenePromptToggleTitle, scenePromptToggleHelp = createSettingsItem(
	"Scene Direction Prompt",
	"Shows an extra prompt field in the main panel for full scene-composition attempts that infer the needed individual assets from context."
)
registerSettingsSearchEntry(scenePromptToggleTitle, "scene direction prompt scene attempt environment prompt extra field", "experimental")
registerSettingsSearchEntry(scenePromptToggleHelp, "scene direction prompt scene attempt environment prompt extra field", "experimental")

ui.experimentalScenePromptButton = createButton("Scene Direction Prompt: Off", Color3.fromRGB(123, 101, 72), "warning")
ui.experimentalScenePromptButton.Size = UDim2.new(1, 0, 0, 34)
ui.experimentalScenePromptButton.Parent = ui.activeSettingsGroup
registerSettingsSearchEntry(ui.experimentalScenePromptButton, "scene direction prompt scene attempt environment prompt extra field", "experimental", true)
registerSettingsShortcut("Scene Direction Prompt", ui.experimentalScenePromptButton, "scene direction prompt scene attempt environment prompt extra field", "experimental")

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
end

do
	local licensingGroup, licensingTitle, licensingHelp = createSettingsGroup(
		"Licensing & Attribution",
		"States ownership of the plugin implementation and attributes Roblox platform generation technology appropriately."
	)
	licensingGroup.LayoutOrder = 7
	registerSettingsSection("licensing", licensingTitle, "licensing attribution ownership roblox cube 3d legal rights creator author implementation", licensingHelp)
	ui.settingsSearchSections.licensing.container = licensingGroup
	ui.activeSettingsGroup = licensingGroup

	local pluginOwnershipTitle, pluginOwnershipHelp = createSettingsItem(
		"Plugin Ownership",
		"This plugin implementation, interface, workflow design, and surrounding tool logic belong to the plugin creator. This notice does not claim ownership over Roblox platform technology."
	)
	registerSettingsSearchEntry(pluginOwnershipTitle, "plugin ownership creator author implementation interface workflow tool logic rights", "licensing")
	registerSettingsSearchEntry(pluginOwnershipHelp, "plugin ownership creator author implementation interface workflow tool logic rights", "licensing")

	local robloxAttributionTitle, robloxAttributionHelp = createSettingsItem(
		"Roblox Cube 3D Attribution",
		"Model generation in this plugin relies on Roblox generation technology, including Cube 3D capabilities and related Roblox services. Those underlying generation technologies remain Roblox technology and are governed by Roblox platform terms."
	)
	registerSettingsSearchEntry(robloxAttributionTitle, "roblox cube 3d attribution technology generation service roblox platform", "licensing")
	registerSettingsSearchEntry(robloxAttributionHelp, "roblox cube 3d attribution technology generation service roblox platform", "licensing")

	local rightsTitle, rightsHelp = createSettingsItem(
		"Rights + Responsibility",
		"Prompt content, generated assets, trademarks, branding references, and platform usage remain subject to Roblox terms, community standards, and any applicable third-party rights in the source material or resulting content."
	)
	registerSettingsSearchEntry(rightsTitle, "rights responsibility generated assets prompts trademarks branding third-party content", "licensing")
	registerSettingsSearchEntry(rightsHelp, "rights responsibility generated assets prompts trademarks branding third-party content", "licensing")
end

ui.activeSettingsGroup = nil
rebuildProceduralSettingsOverview()

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

ui.seedTitle = createSectionTitle("Variation Seed")
ui.seedTitle.LayoutOrder = 19
ui.seedTitle.Parent = root

ui.seedFrame = Instance.new("Frame")
ui.seedFrame.Size = UDim2.new(1, 0, 0, 40)
ui.seedFrame.BackgroundTransparency = 1
ui.seedFrame.LayoutOrder = 20
ui.seedFrame.Parent = root

ui.seedBox = createSmallBox("Leave blank for random, or enter text/number to repeat a variation", tostring(getSetting(SETTINGS.seed, "")))
ui.seedBox.Size = UDim2.new(0.5, -8, 1, 0)
ui.seedBox.Parent = ui.seedFrame

ui.variationCountBox = createSmallBox("Variations", tostring(getSetting(SETTINGS.variationCount, 1)))
ui.variationCountBox.Size = UDim2.new(0.18, -8, 1, 0)
ui.variationCountBox.Position = UDim2.new(0.5, 8, 0, 0)
ui.variationCountBox.Parent = ui.seedFrame

ui.randomSeedButton = createButton("Random Seed", Color3.fromRGB(90, 110, 140), "secondary")
ui.randomSeedButton.Size = UDim2.new(0.32, -16, 1, 0)
ui.randomSeedButton.Position = UDim2.new(0.68, 16, 0, 0)
ui.randomSeedButton.Parent = ui.seedFrame

ui.seedHelp = createLabel(
	"Use the same seed to reproduce a direction. Raise Variations to batch-generate several candidates from one prompt; numbered seeds are stepped automatically.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(157, 168, 183),
	34
)
ui.seedHelp.LayoutOrder = 21
enableAutoHeightLabel(ui.seedHelp, 24)
ui.seedHelp.Parent = root

ui.tipsLabel = createLabel(
	"Medium is the faster balanced preset, High is the default full-detail mode, and Ultra keeps the 20,000 triangle cap but pushes size and collision detail harder. If one object is selected, the result is inserted there; otherwise it goes to Workspace.",
	12,
	Enum.Font.Gotham,
	Color3.fromRGB(157, 168, 183),
	34
)
ui.tipsLabel.LayoutOrder = 22
enableAutoHeightLabel(ui.tipsLabel, 24)
ui.tipsLabel.Parent = root

ui.buttonFrame = Instance.new("Frame")
ui.buttonFrame.Size = UDim2.new(1, 0, 0, 130)
ui.buttonFrame.BackgroundTransparency = 1
ui.buttonFrame.LayoutOrder = 23
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

ui.regenerateSelectedButton = createButton("Regenerate Selected", Color3.fromRGB(57, 128, 116), "teal")
ui.regenerateSelectedButton.Parent = ui.buttonFrame

ui.guideFocusGroups.step_prompt = {ui.presetFrame, ui.promptBox}
ui.guideFocusGroups.step_inputs = {ui.settingsFrame, ui.colliderModeBox, ui.schemaBox, ui.seedFrame}
ui.guideFocusGroups.step_preview = {ui.previewButton}
ui.guideFocusGroups.step_generate = {ui.generateButton, ui.regenerateSelectedButton}
ui.guideFocusGroups.step_store = {ui.runtimeButton, ui.runtimeAllButton, ui.toggleStorageButton}

local previewRoot = Instance.new("ScrollingFrame")
previewRoot.Size = UDim2.fromScale(1, 1)
previewRoot.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
previewRoot.BorderSizePixel = 0
previewRoot.AutomaticCanvasSize = Enum.AutomaticSize.Y
previewRoot.CanvasSize = UDim2.new()
previewRoot.ScrollBarThickness = 6
previewRoot.Parent = previewWidget
ui.previewRoot = previewRoot
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

ui.previewCompareFrame = Instance.new("Frame")
ui.previewCompareFrame.Size = UDim2.new(1, 0, 0, 308)
ui.previewCompareFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
ui.previewCompareFrame.BorderSizePixel = 0
ui.previewCompareFrame.LayoutOrder = 3
ui.previewCompareFrame.Visible = false
ui.previewCompareFrame.Parent = previewRoot
styleCard(ui.previewCompareFrame, Color3.fromRGB(63, 87, 112), Color3.fromRGB(36, 49, 65), Color3.fromRGB(112, 153, 196), false)

local previewComparePadding = Instance.new("UIPadding")
previewComparePadding.PaddingTop = UDim.new(0, 10)
previewComparePadding.PaddingBottom = UDim.new(0, 10)
previewComparePadding.PaddingLeft = UDim.new(0, 10)
previewComparePadding.PaddingRight = UDim.new(0, 10)
previewComparePadding.Parent = ui.previewCompareFrame

ui.previewCompareTitleLabel = createSectionTitle("Preview Gallery")
ui.previewCompareTitleLabel.Parent = ui.previewCompareFrame

ui.previewCompareHintLabel = createLabel(
	"All generated preview variants appear here. Left-click a card to focus it in the main preview. Right-click a card to select it for batch actions.",
	11,
	Enum.Font.Gotham,
	Color3.fromRGB(186, 206, 227),
	28
)
enableAutoHeightLabel(ui.previewCompareHintLabel, 24)
ui.previewCompareHintLabel.Position = UDim2.new(0, 0, 0, 24)
ui.previewCompareHintLabel.Parent = ui.previewCompareFrame

ui.previewCompareGrid = Instance.new("ScrollingFrame")
ui.previewCompareGrid.Size = UDim2.new(1, 0, 0, 244)
ui.previewCompareGrid.BackgroundTransparency = 1
ui.previewCompareGrid.BorderSizePixel = 0
ui.previewCompareGrid.CanvasSize = UDim2.new()
ui.previewCompareGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
ui.previewCompareGrid.ScrollBarThickness = 6
ui.previewCompareGrid.Position = UDim2.new(0, 0, 0, 52)
ui.previewCompareGrid.Parent = ui.previewCompareFrame

ui.previewCompareLayout = Instance.new("UIGridLayout")
ui.previewCompareLayout.CellPadding = UDim2.new(0, 8, 0, 8)
ui.previewCompareLayout.CellSize = UDim2.new(0.5, -4, 0, 148)
ui.previewCompareLayout.Parent = ui.previewCompareGrid

local previewInfoFrame = Instance.new("Frame")
previewInfoFrame.Size = UDim2.new(1, 0, 0, 0)
previewInfoFrame.BackgroundColor3 = Color3.fromRGB(21, 27, 38)
previewInfoFrame.BorderSizePixel = 0
previewInfoFrame.AutomaticSize = Enum.AutomaticSize.Y
previewInfoFrame.LayoutOrder = 4
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

ui.previewActivityFrame = Instance.new("Frame")
ui.previewActivityFrame.Size = UDim2.new(1, 0, 0, 0)
ui.previewActivityFrame.BackgroundColor3 = Color3.fromRGB(26, 34, 48)
ui.previewActivityFrame.BorderSizePixel = 0
ui.previewActivityFrame.AutomaticSize = Enum.AutomaticSize.Y
ui.previewActivityFrame.LayoutOrder = 2
ui.previewActivityFrame.Visible = false
ui.previewActivityFrame.Parent = previewRoot
styleCard(ui.previewActivityFrame, Color3.fromRGB(88, 121, 179), Color3.fromRGB(45, 60, 86), Color3.fromRGB(143, 198, 255), false)
table.insert(themeRegistry.cards, {instance = ui.previewActivityFrame, role = "panelStrong"})

local previewActivityPadding = Instance.new("UIPadding")
previewActivityPadding.PaddingTop = UDim.new(0, 8)
previewActivityPadding.PaddingBottom = UDim.new(0, 8)
previewActivityPadding.PaddingLeft = UDim.new(0, 10)
previewActivityPadding.PaddingRight = UDim.new(0, 10)
previewActivityPadding.Parent = ui.previewActivityFrame

local previewActivityLayout = Instance.new("UIListLayout")
previewActivityLayout.Padding = UDim.new(0, 5)
previewActivityLayout.FillDirection = Enum.FillDirection.Vertical
previewActivityLayout.Parent = ui.previewActivityFrame

ui.previewActivityTitleLabel = createSectionTitle("Preview Activity")
ui.previewActivityTitleLabel.Parent = ui.previewActivityFrame

ui.previewActivityStatusLabel = createLabel(
	"Generating preview...",
	13,
	Enum.Font.GothamBold,
	Color3.fromRGB(224, 233, 247),
	22
)
enableAutoHeightLabel(ui.previewActivityStatusLabel, 22)
ui.previewActivityStatusLabel.Parent = ui.previewActivityFrame

ui.previewActivityMetaLabel = createLabel(
	"Elapsed 0s  |  Batch ETA estimating...  |  Cache hits 0",
	11,
	Enum.Font.Gotham,
	Color3.fromRGB(176, 197, 226),
	20
)
enableAutoHeightLabel(ui.previewActivityMetaLabel, 20)
ui.previewActivityMetaLabel.Parent = ui.previewActivityFrame

ui.previewActivityBarFrame = Instance.new("Frame")
ui.previewActivityBarFrame.Size = UDim2.new(1, 0, 0, 14)
ui.previewActivityBarFrame.BackgroundColor3 = Color3.fromRGB(20, 28, 40)
ui.previewActivityBarFrame.BorderSizePixel = 0
ui.previewActivityBarFrame.Parent = ui.previewActivityFrame
createCorner(ui.previewActivityBarFrame, 8)
createStroke(ui.previewActivityBarFrame, Color3.fromRGB(95, 136, 204))

ui.previewActivityBarFill = Instance.new("Frame")
ui.previewActivityBarFill.Size = UDim2.new(0, 0, 1, 0)
ui.previewActivityBarFill.BackgroundColor3 = Color3.fromRGB(109, 187, 255)
ui.previewActivityBarFill.BorderSizePixel = 0
ui.previewActivityBarFill.Parent = ui.previewActivityBarFrame
createCorner(ui.previewActivityBarFill, 8)
addVerticalGradient(ui.previewActivityBarFill, Color3.fromRGB(170, 227, 255), Color3.fromRGB(92, 150, 255))

ui.previewActivityBarSweep = Instance.new("Frame")
ui.previewActivityBarSweep.Size = UDim2.new(0, 42, 1, -4)
ui.previewActivityBarSweep.Position = UDim2.new(0, -42, 0, 2)
ui.previewActivityBarSweep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ui.previewActivityBarSweep.BackgroundTransparency = 0.65
ui.previewActivityBarSweep.BorderSizePixel = 0
ui.previewActivityBarSweep.Parent = ui.previewActivityBarFrame
createCorner(ui.previewActivityBarSweep, 8)
createActivityBarDecor(ui.previewActivityBarFrame)

ui.previewActivityDetailLabel = createLabel(
	"Preview progress is estimated from completed variations.",
	11,
	Enum.Font.Code,
	Color3.fromRGB(189, 208, 232),
	44
)
enableAutoHeightLabel(ui.previewActivityDetailLabel, 44)
ui.previewActivityDetailLabel.Parent = ui.previewActivityFrame

ui.previewViewport = Instance.new("ViewportFrame")
ui.previewViewport.Size = UDim2.new(1, 0, 0, 320)
ui.previewViewport.BackgroundColor3 = Color3.fromRGB(28, 35, 49)
ui.previewViewport.BorderSizePixel = 0
ui.previewViewport.LayoutOrder = 5
ui.previewViewport.Parent = previewRoot
createCorner(ui.previewViewport, 12)
createStroke(ui.previewViewport, Color3.fromRGB(86, 104, 136))
addVerticalGradient(ui.previewViewport, Color3.fromRGB(82, 103, 142), Color3.fromRGB(58, 75, 104))
createShadow(ui.previewViewport, 0.75, 8)

ui.previewWorldModel = Instance.new("WorldModel")
ui.previewWorldModel.Parent = ui.previewViewport

ui.previewCamera = Instance.new("Camera")
ui.previewCamera.Parent = ui.previewViewport
ui.previewViewport.CurrentCamera = ui.previewCamera
ui.previewViewport.Ambient = PREVIEW_LIGHTING_PRESETS.Studio.ambient
ui.previewViewport.LightColor = PREVIEW_LIGHTING_PRESETS.Studio.lightColor
ui.previewViewport.LightDirection = PREVIEW_LIGHTING_PRESETS.Studio.lightDirection

ui.previewSelectedFrame = Instance.new("ScrollingFrame")
ui.previewSelectedFrame.Size = UDim2.new(1, 0, 0, 320)
ui.previewSelectedFrame.BackgroundColor3 = Color3.fromRGB(28, 35, 49)
ui.previewSelectedFrame.BorderSizePixel = 0
ui.previewSelectedFrame.LayoutOrder = 5
ui.previewSelectedFrame.CanvasSize = UDim2.new()
ui.previewSelectedFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ui.previewSelectedFrame.ScrollBarThickness = 6
ui.previewSelectedFrame.Visible = false
ui.previewSelectedFrame.Parent = previewRoot
createCorner(ui.previewSelectedFrame, 12)
createStroke(ui.previewSelectedFrame, Color3.fromRGB(86, 104, 136))
addVerticalGradient(ui.previewSelectedFrame, Color3.fromRGB(82, 103, 142), Color3.fromRGB(58, 75, 104))
createShadow(ui.previewSelectedFrame, 0.75, 8)

local previewSelectedPadding = Instance.new("UIPadding")
previewSelectedPadding.PaddingTop = UDim.new(0, 10)
previewSelectedPadding.PaddingBottom = UDim.new(0, 10)
previewSelectedPadding.PaddingLeft = UDim.new(0, 10)
previewSelectedPadding.PaddingRight = UDim.new(0, 10)
previewSelectedPadding.Parent = ui.previewSelectedFrame

ui.previewSelectedLayout = Instance.new("UIGridLayout")
ui.previewSelectedLayout.CellPadding = UDim2.new(0, 8, 0, 8)
ui.previewSelectedLayout.CellSize = UDim2.new(0.5, -4, 0, 132)
ui.previewSelectedLayout.Parent = ui.previewSelectedFrame

local previewStatsFrame = Instance.new("Frame")
previewStatsFrame.Size = UDim2.new(1, 0, 0, 0)
previewStatsFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
previewStatsFrame.BorderSizePixel = 0
previewStatsFrame.AutomaticSize = Enum.AutomaticSize.Y
previewStatsFrame.LayoutOrder = 6
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

local previewActions = Instance.new("Frame")
previewActions.Size = UDim2.new(1, 0, 0, 168)
previewActions.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
previewActions.BorderSizePixel = 0
previewActions.LayoutOrder = 7
previewActions.Parent = previewRoot
styleCard(previewActions, Color3.fromRGB(64, 91, 74), Color3.fromRGB(38, 54, 44), Color3.fromRGB(112, 176, 137), false)

local previewActionsPadding = Instance.new("UIPadding")
previewActionsPadding.PaddingTop = UDim.new(0, 10)
previewActionsPadding.PaddingBottom = UDim.new(0, 10)
previewActionsPadding.PaddingLeft = UDim.new(0, 10)
previewActionsPadding.PaddingRight = UDim.new(0, 10)
previewActionsPadding.Parent = previewActions

local previewActionsTitle = createSectionTitle("Preview Actions")
previewActionsTitle.Parent = previewActions

ui.previewActionHintLabel = createLabel(
	"Use the preview gallery above: left-click cards to toggle selection, then right-click a variant to preview it here.",
	11,
	Enum.Font.Gotham,
	Color3.fromRGB(196, 221, 201),
	30
)
enableAutoHeightLabel(ui.previewActionHintLabel, 24)
ui.previewActionHintLabel.Position = UDim2.new(0, 0, 0, 24)
ui.previewActionHintLabel.Parent = previewActions

local previewActionsGrid = Instance.new("Frame")
previewActionsGrid.Size = UDim2.new(1, 0, 0, 88)
previewActionsGrid.BackgroundTransparency = 1
previewActionsGrid.Position = UDim2.new(0, 0, 0, 58)
previewActionsGrid.Parent = previewActions

local previewActionsLayout = Instance.new("UIGridLayout")
previewActionsLayout.CellPadding = UDim2.new(0, 8, 0, 8)
previewActionsLayout.CellSize = UDim2.new(0.5, -4, 0, 40)
previewActionsLayout.Parent = previewActionsGrid

ui.previewGenerateCurrentButton = createButton("Generate Current", Color3.fromRGB(49, 155, 106), "success")
ui.previewGenerateCurrentButton.Parent = previewActionsGrid

ui.previewGenerateSelectedButton = createButton("Generate Selected", Color3.fromRGB(57, 128, 116), "teal")
ui.previewGenerateSelectedButton.Parent = previewActionsGrid

ui.previewGenerateAllButton = createButton("Generate All", Color3.fromRGB(84, 107, 146), "info")
ui.previewGenerateAllButton.Parent = previewActionsGrid

ui.previewSelectAllTabsButton = createButton("Select All", Color3.fromRGB(123, 101, 72), "warning")
ui.previewSelectAllTabsButton.Parent = previewActionsGrid

local previewControls = Instance.new("Frame")
previewControls.Size = UDim2.new(1, 0, 0, 216)
previewControls.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
previewControls.BorderSizePixel = 0
previewControls.LayoutOrder = 8
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
previewDisplayControls.LayoutOrder = 9
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
collisionInfoFrame.LayoutOrder = 10
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

ui.activityFrame = Instance.new("Frame")
ui.activityFrame.Size = UDim2.new(1, 0, 0, 0)
ui.activityFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
ui.activityFrame.BorderSizePixel = 0
ui.activityFrame.AutomaticSize = Enum.AutomaticSize.Y
ui.activityFrame.LayoutOrder = 14
ui.activityFrame.Visible = false
ui.activityFrame.Parent = root
styleCard(ui.activityFrame, Color3.fromRGB(71, 97, 142), Color3.fromRGB(38, 50, 71), Color3.fromRGB(124, 173, 255), false)
table.insert(themeRegistry.cards, {instance = ui.activityFrame, role = "panelStrong"})

local activityPadding = Instance.new("UIPadding")
activityPadding.PaddingTop = UDim.new(0, 10)
activityPadding.PaddingBottom = UDim.new(0, 10)
activityPadding.PaddingLeft = UDim.new(0, 10)
activityPadding.PaddingRight = UDim.new(0, 10)
activityPadding.Parent = ui.activityFrame

local activityLayout = Instance.new("UIListLayout")
activityLayout.Padding = UDim.new(0, 6)
activityLayout.FillDirection = Enum.FillDirection.Vertical
activityLayout.Parent = ui.activityFrame

ui.activityTitleLabel = createSectionTitle("Generation Activity")
ui.activityTitleLabel.Parent = ui.activityFrame

ui.activityStatusLabel = createLabel(
	"Waiting for a request.",
	13,
	Enum.Font.GothamBold,
	Color3.fromRGB(214, 226, 245),
	24
)
enableAutoHeightLabel(ui.activityStatusLabel, 24)
ui.activityStatusLabel.Parent = ui.activityFrame

ui.activityMetaLabel = createLabel(
	"Batch time remaining will appear once the first result finishes.",
	11,
	Enum.Font.Gotham,
	Color3.fromRGB(169, 191, 223),
	22
)
enableAutoHeightLabel(ui.activityMetaLabel, 22)
ui.activityMetaLabel.Parent = ui.activityFrame

ui.activityBarFrame = Instance.new("Frame")
ui.activityBarFrame.Size = UDim2.new(1, 0, 0, 16)
ui.activityBarFrame.BackgroundColor3 = Color3.fromRGB(23, 31, 46)
ui.activityBarFrame.BorderSizePixel = 0
ui.activityBarFrame.Parent = ui.activityFrame
createCorner(ui.activityBarFrame, 8)
createStroke(ui.activityBarFrame, Color3.fromRGB(86, 120, 176))

ui.activityBarFill = Instance.new("Frame")
ui.activityBarFill.Size = UDim2.new(0, 0, 1, 0)
ui.activityBarFill.BackgroundColor3 = Color3.fromRGB(92, 179, 255)
ui.activityBarFill.BorderSizePixel = 0
ui.activityBarFill.Parent = ui.activityBarFrame
createCorner(ui.activityBarFill, 8)
addVerticalGradient(ui.activityBarFill, Color3.fromRGB(143, 223, 255), Color3.fromRGB(77, 131, 255))

ui.activityBarSweep = Instance.new("Frame")
ui.activityBarSweep.Size = UDim2.new(0, 42, 1, -4)
ui.activityBarSweep.Position = UDim2.new(0, -42, 0, 2)
ui.activityBarSweep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ui.activityBarSweep.BackgroundTransparency = 0.65
ui.activityBarSweep.BorderSizePixel = 0
ui.activityBarSweep.Parent = ui.activityBarFrame
createCorner(ui.activityBarSweep, 8)
createActivityBarDecor(ui.activityBarFrame)

ui.activityDetailLabel = createLabel(
	"Preview batches and full generation both use this live tracker.",
	11,
	Enum.Font.Code,
	Color3.fromRGB(185, 203, 231),
	44
)
enableAutoHeightLabel(ui.activityDetailLabel, 44)
ui.activityDetailLabel.Parent = ui.activityFrame

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

local generationActivityState = {
	active = false,
	mode = "Generate",
	startedAt = 0,
	totalSteps = 0,
	processedSteps = 0,
	currentStep = 0,
	currentLabel = "",
	detail = "",
	cacheHits = 0,
}

function stringContainsAny(source, patterns)
	for _, pattern in ipairs(patterns) do
		if string.find(source, pattern, 1, true) then
			return true
		end
	end
	return false
end

function smoothstep(alpha)
	alpha = math.clamp(alpha or 0, 0, 1)
	return alpha * alpha * (3 - (2 * alpha))
end

function fract(value)
	return value - math.floor(value)
end

function triangleWave(value)
	return 1 - math.abs((fract(value) * 2) - 1)
end

function computeGenerationSimulationProgress(profile, now, elapsed, baseProgress, totalSteps, activePulse)
	local progress = baseProgress
	local pulseAmplitude = (profile.pulseAmplitude or 0.8) * (1 / math.max(totalSteps, 1)) * 0.8
	local pulseWave = activePulse and ((math.sin(now * (profile.pulseFrequency or 3)) + 1) * 0.5) or 0
	local pulseProgress = pulseWave * pulseAmplitude
	local jitter = 0
	local motion = profile.progressMotion or "steady"

	if motion == "glitch" then
		local burst = triangleWave(now * 1.6 + (profile.seedOffset or 0))
		progress += pulseProgress * 0.6 + burst * (0.35 / math.max(totalSteps, 1))
		jitter = (triangleWave(now * 9.5 + (profile.seedOffset or 0) * 2.1) - 0.5) * (profile.microJitter or 0)
	elseif motion == "scan" then
		progress += pulseProgress * 0.45
		progress += smoothstep(triangleWave(now * 0.35 + elapsed * 0.06)) * (0.12 / math.max(totalSteps, 1))
		jitter = math.sin(now * 2.4 + (profile.seedOffset or 0)) * (profile.microJitter or 0)
	elseif motion == "staged" then
		local staged = smoothstep(triangleWave(now * 0.45 + (profile.seedOffset or 0)))
		progress += pulseProgress * 0.3
		progress += staged * (0.16 / math.max(totalSteps, 1))
	elseif motion == "combo" then
		local combo = smoothstep(triangleWave(now * 1.9 + (profile.seedOffset or 0)))
		progress += pulseProgress * 1.15
		progress += combo * (0.22 / math.max(totalSteps, 1))
		jitter = (triangleWave(now * 8.5) - 0.5) * (profile.microJitter or 0)
	elseif motion == "surge" then
		local surge = smoothstep(triangleWave(now * 0.8 + (profile.seedOffset or 0)))
		progress += pulseProgress * 0.65
		progress += surge * (0.2 / math.max(totalSteps, 1))
	elseif motion == "creep" then
		local creep = smoothstep(math.clamp(fract(now * 0.18 + (profile.seedOffset or 0) * 0.13) * 1.15, 0, 1))
		progress += pulseProgress * 0.18
		progress += creep * (0.09 / math.max(totalSteps, 1))
		jitter = math.sin(now * 1.7) * (profile.microJitter or 0)
	elseif motion == "drift" then
		progress += pulseProgress * 0.4
		progress += (math.sin(now * 0.95 + (profile.seedOffset or 0)) * 0.5 + 0.5) * (0.12 / math.max(totalSteps, 1))
	elseif motion == "lockstep" then
		local steps = math.max(profile.quantizeSteps or (totalSteps * 3), totalSteps)
		progress += pulseProgress * 0.25
		progress = math.floor(math.clamp(progress, 0, 1) * steps) / steps
	elseif motion == "grow" then
		local organic = smoothstep(math.clamp(fract(elapsed * 0.22 + (profile.seedOffset or 0) * 0.07) * 1.1, 0, 1))
		progress += pulseProgress * 0.5
		progress += organic * (0.14 / math.max(totalSteps, 1))
	else
		progress += pulseProgress
	end

	progress += jitter
	return math.clamp(progress, profile.progressFloor or 0.04, 1)
end

function computeGenerationShimmerOffset(profile, barWidth, shimmerSpan, now, elapsed)
	local width = math.max(barWidth, shimmerSpan, 1)
	local speed = profile.sweepSpeed or 120
	local mode = profile.shimmerMode or "linear"

	if mode == "burst" then
		local travel = width + shimmerSpan
		local burstPhase = fract(now * speed * 0.014 + (profile.seedOffset or 0) * 0.17)
		return math.floor((burstPhase * burstPhase) * travel) - shimmerSpan
	elseif mode == "step" then
		local steps = math.max(profile.quantizeSteps or 12, 2)
		local travel = width - shimmerSpan
		local phase = math.floor(fract(now * speed * 0.01) * steps) / steps
		return math.floor(math.max(travel, 1) * phase)
	elseif mode == "surge" then
		local travel = width - shimmerSpan
		local phase = smoothstep(triangleWave(now * speed * 0.01 + elapsed * 0.04))
		return math.floor(math.max(travel, 1) * phase)
	elseif mode == "drift" then
		local travel = width - shimmerSpan
		local phase = math.sin(now * speed * 0.006 + (profile.seedOffset or 0)) * 0.5 + 0.5
		return math.floor(math.max(travel, 1) * phase)
	end

	local travel = width + shimmerSpan
	local offset = math.floor((now * speed) % travel) - shimmerSpan
	if profile.barDirection == "reverse" then
		return (barWidth - offset) - shimmerSpan
	elseif profile.barDirection == "pingpong" then
		local pingRange = math.max(barWidth - shimmerSpan, 1)
		local pingValue = math.abs(((now * speed * 0.02) % 2) - 1)
		return math.floor(pingRange * pingValue)
	end
	return offset
end

function getThemeConceptTag(lowerThemeName, lowerCategory)
	local conceptRules = {
		{tag = "matrix", patterns = {"matrix"}},
		{tag = "terminal", patterns = {"fallout", "terminal", "solarized", "monochrome", "blueprint"}},
		{tag = "arcade", patterns = {"arcade", "neon", "retro", "crt", "laser", "carnival", "toybox", "mario", "persona"}},
		{tag = "cyber", patterns = {"cyber", "synth", "hacker", "galaxy", "nebula", "prism", "future", "mass effect", "destiny", "portal", "helldivers"}},
		{tag = "nature", patterns = {"forest", "moss", "pine", "jade", "aurora", "rainforest", "seafoam", "mint", "animal", "stardew", "terraria", "sea of thieves"}},
		{tag = "horror", patterns = {"noir", "obsidian", "dracula", "silent", "dead", "biohazard", "fog", "diablo", "ember", "lava", "doom"}},
		{tag = "fantasy", patterns = {"royal", "skyrim", "witcher", "zelda", "genshin", "starlight", "elden", "monster", "warcraft", "sapphire"}},
		{tag = "tactical", patterns = {"valorant", "apex", "fortnite", "rainbow", "counter", "battlefield", "call of duty", "steel", "construction", "halo"}},
		{tag = "speed", patterns = {"rocket", "speed", "turismo", "sunset", "turbo", "gran", "boardwalk", "harbor", "marina", "lagoon"}},
	}

	for _, rule in ipairs(conceptRules) do
		if stringContainsAny(lowerThemeName, rule.patterns) then
			return rule.tag
		end
	end

	if string.find(lowerCategory, "sci-fi", 1, true) then
		return "cyber"
	elseif string.find(lowerCategory, "sandbox", 1, true) then
		return "nature"
	elseif string.find(lowerCategory, "horror", 1, true) then
		return "horror"
	elseif string.find(lowerCategory, "fantasy", 1, true) then
		return "fantasy"
	elseif string.find(lowerCategory, "competitive", 1, true) then
		return "tactical"
	elseif string.find(lowerCategory, "racing", 1, true) then
		return "speed"
	elseif string.find(lowerCategory, "arcade", 1, true) then
		return "arcade"
	end

	return "utility"
end

function getConceptFrameSet(conceptTag)
	if conceptTag == "matrix" then
		return {" 101", " 110", " 001", " 111"}
	elseif conceptTag == "terminal" then
		return {" [=   ]", " [==  ]", " [=== ]", " [====]"}
	elseif conceptTag == "arcade" then
		return {" x1", " x2", " x4", " x8"}
	elseif conceptTag == "nature" then
		return {" .", " ..", " ...", " ...."}
	elseif conceptTag == "horror" then
		return {" _", " __", " ___", " __"}
	elseif conceptTag == "fantasy" then
		return {" *", " **", " ***", " **"}
	elseif conceptTag == "tactical" then
		return {" <>", " <<", " >>", " <>"}
	elseif conceptTag == "speed" then
		return {" /", " //", " ///", " //"}
	elseif conceptTag == "cyber" then
		return {" <>", " <>", " >>", " <>"}
	end
	return {" .", " ..", " ...", ""}
end

function getConceptAsciiFrameSet(conceptTag)
	if conceptTag == "matrix" then
		return {
			"[01] [10] [11]",
			"[10] [11] [01]",
			"[11] [01] [10]",
			"[01] [11] [00]",
		}
	elseif conceptTag == "terminal" then
		return {
			"> scan  [=   ]",
			"> route [==  ]",
			"> link  [=== ]",
			"> exec  [====]",
		}
	elseif conceptTag == "arcade" then
		return {
			"<+> SCORE x01",
			"<<>> SCORE x02",
			"<##> SCORE x04",
			"<@@> SCORE x08",
		}
	elseif conceptTag == "nature" then
		return {
			" .  /\\  . ",
			" . /\\/\\ . ",
			" ./\\/\\/\\. ",
			" . \\/\\/ . ",
		}
	elseif conceptTag == "horror" then
		return {
			" .:: SHIVER ::. ",
			" ::.. SHIVER ..:: ",
			" .:: ECHO ::. ",
			" ::.. ECHO ..:: ",
		}
	elseif conceptTag == "fantasy" then
		return {
			" <*> rune weave <*> ",
			" <+> sigil cast <+> ",
			" <*> relic pulse <*> ",
			" <+> aether hum <+> ",
		}
	elseif conceptTag == "tactical" then
		return {
			"[LOCK] >> <<",
			"[SCAN] || ||",
			"[TRACK] == ==",
			"[READY] >> <<",
		}
	elseif conceptTag == "speed" then
		return {
			"// apex burn //",
			"/// overtake ///",
			"//// redline ////",
			"/// launch ///",
		}
	elseif conceptTag == "cyber" then
		return {
			"<net> :: uplink ::",
			"<sig> == pulse ==",
			"<sys> >> sync <<",
			"<io>  :: flux ::",
		}
	end

	return {
		"[ build .   ]",
		"[ build ..  ]",
		"[ build ... ]",
		"[ build ....]",
	}
end

function getAnimatedAsciiPanel(profile, now, progress)
	local frames = profile.asciiFrames or getConceptAsciiFrameSet("utility")
	local frameIndex = (math.floor(now * (profile.asciiRate or 4.5)) % #frames) + 1
	local currentFrame = frames[frameIndex]
	local width = math.max(profile.asciiWidth or 16, #currentFrame)
	local filled = math.clamp(math.floor(width * progress + 0.5), 0, width)
	local empty = math.max(width - filled, 0)
	local meter = "[" .. string.rep("#", filled) .. string.rep(".", empty) .. "]"
	local label = string.upper(profile.conceptTag or "UTILITY")
	return string.format("%s\n%s\n%s", currentFrame, meter, label)
end

function getConceptBarGlyphSet(conceptTag)
	if conceptTag == "matrix" then
		return {"0x1F", "0x2A", "0x3C", "0x5D"}
	elseif conceptTag == "terminal" then
		return {"SYS", "I/O", "MEM", "CLK"}
	elseif conceptTag == "arcade" then
		return {"1UP", "2UP", "BONUS", "x8"}
	elseif conceptTag == "nature" then
		return {"BLOOM", "ROOT", "CANOPY", "GROW"}
	elseif conceptTag == "horror" then
		return {"ECHO", "VEIL", "ASH", "SHADE"}
	elseif conceptTag == "fantasy" then
		return {"RUNE", "SIGIL", "AETHER", "RELIC"}
	elseif conceptTag == "tactical" then
		return {"LOCK", "TRACK", "SYNC", "MARK"}
	elseif conceptTag == "speed" then
		return {"APEX", "RUSH", "DRIVE", "REDLINE"}
	elseif conceptTag == "cyber" then
		return {"NET", "PULSE", "LINK", "SYNC"}
	end
	return {"BUILD", "SIM", "FLOW", "DONE"}
end

function getConceptBarSceneFrames(conceptTag)
	if conceptTag == "matrix" then
		return {
			"0101//CODE",
			"1011//RAIN",
			"0010//GRID",
			"1110//SYNC",
		}
	elseif conceptTag == "terminal" then
		return {
			">boot  ::",
			">parse ::",
			">route ::",
			">exec  ::",
		}
	elseif conceptTag == "arcade" then
		return {
			"<*> bonus",
			"<#> combo",
			"<@> x4 up",
			"<$> clear",
		}
	elseif conceptTag == "nature" then
		return {
			"/\\ sprout",
			"/\\\\ bloom",
			"|| root ",
			"~~ grove",
		}
	elseif conceptTag == "horror" then
		return {
			".. ash ..",
			":: veil :",
			".. echo .",
			": shade :",
		}
	elseif conceptTag == "fantasy" then
		return {
			"<*> rune ",
			"<+> sigil",
			"{*} relic",
			"{+} aethr",
		}
	elseif conceptTag == "tactical" then
		return {
			"[ ] lock",
			"[x] scan",
			"[=] track",
			"[>] ready",
		}
	elseif conceptTag == "speed" then
		return {
			"// launch",
			"/// apex ",
			"//// rush",
			"/// burn ",
		}
	elseif conceptTag == "cyber" then
		return {
			"<> uplink",
			"== pulse ",
			">> sync  ",
			":: flux  ",
		}
	end
	return {
		"[ build ]",
		"[ shape ]",
		"[ refine]",
		"[ final ]",
	}
end

function getConceptPhraseBank(conceptTag)
	if conceptTag == "matrix" then
		return {
			titles = {"Construct", "Simulation", "Code Stream"},
			previewTitles = {"Matrix Preview", "Construct Preview"},
			detailPrefix = "code-rain: ",
			phases = {"Decrypting source stream", "Tracing construct wireframe", "Resolving green-code lattice", "Compiling simulation shell", "Rendering residual self-image"},
		}
	elseif conceptTag == "terminal" then
		return {
			titles = {"Terminal Fabrication", "Pip-Boy Fabrication", "Drafting Bay"},
			previewTitles = {"Terminal Preview", "Pip-Boy Preview", "Blueprint Preview"},
			detailPrefix = "sys: ",
			phases = {"Booting fabrication shell", "Parsing build directives", "Routing assembly logs", "Calibrating output channel", "Writing final payload"},
		}
	elseif conceptTag == "arcade" then
		return {
			titles = {"Arcade Fabrication", "Bonus Fabrication", "Attract Mode"},
			previewTitles = {"Arcade Preview", "Bonus Preview"},
			detailPrefix = "bonus: ",
			phases = {"Loading attract mode", "Spawning combo geometry", "Stacking bonus layers", "Charging neon pass", "Flashing finish state"},
		}
	elseif conceptTag == "nature" then
		return {
			titles = {"Growth Pass", "Canopy Build", "Organic Assembly"},
			previewTitles = {"Growth Preview", "Canopy Preview"},
			detailPrefix = "bloom: ",
			phases = {"Seeding form", "Growing outer silhouette", "Branching support shapes", "Settling surface rhythm", "Finishing natural pass"},
		}
	elseif conceptTag == "horror" then
		return {
			titles = {"Hull Forge", "Ash Pass", "Shadow Assembly"},
			previewTitles = {"Hull Preview", "Shadow Preview"},
			detailPrefix = "echo: ",
			phases = {"Pulling shape from shadow", "Creeping across silhouette", "Stitching fractured surfaces", "Settling pressure points", "Locking final shell"},
		}
	elseif conceptTag == "fantasy" then
		return {
			titles = {"Relic Forge", "Arcane Assembly", "Mythic Build"},
			previewTitles = {"Relic Preview", "Arcane Preview"},
			detailPrefix = "aether: ",
			phases = {"Invoking base form", "Etching ornate silhouette", "Balancing layered structure", "Infusing finish accents", "Sealing final relic"},
		}
	elseif conceptTag == "tactical" then
		return {
			titles = {"Strike Fabrication", "Tactical Pass", "Loadout Build"},
			previewTitles = {"Strike Preview", "Tactical Preview"},
			detailPrefix = "ops: ",
			phases = {"Marking target geometry", "Locking tactical profile", "Stacking utility structure", "Clearing final checks", "Deploying result"},
		}
	elseif conceptTag == "speed" then
		return {
			titles = {"Velocity Build", "Sprint Fabrication", "Overtake Pass"},
			previewTitles = {"Velocity Preview", "Sprint Preview"},
			detailPrefix = "pace: ",
			phases = {"Launching first pass", "Drafting fast silhouette", "Tightening apex geometry", "Charging finish line", "Crossing final state"},
		}
	elseif conceptTag == "cyber" then
		return {
			titles = {"Signal Forge", "Cyber Assembly", "Neural Pass"},
			previewTitles = {"Signal Preview", "Cyber Preview"},
			detailPrefix = "signal: ",
			phases = {"Initializing signal path", "Weaving luminous scaffolds", "Snapping modular structure", "Amplifying surface energy", "Syncing final output"},
		}
	end

	return {
		titles = {"Generation", "Fabrication", "Build Pass"},
		previewTitles = {"Preview", "Build Preview"},
		detailPrefix = nil,
		phases = {"Drafting shapes", "Refining silhouette", "Balancing structure", "Resolving surfaces", "Finalizing result"},
	}
end

function getThemeUiSoundProfile()
	local lowerThemeName = string.lower(themeState.name or "")
	local lowerCategory = string.lower(getThemeCategory(themeState.name) or "")
	local conceptTag = getThemeConceptTag(lowerThemeName, lowerCategory)
	local profile = {
		conceptTag = conceptTag,
		soundId = "rbxasset://sounds/electronicpingshort.wav",
		buttonSpeed = 1,
		buttonVolume = 0.12,
		buttonTimePosition = 0,
		changeSpeed = 1.1,
		changeVolume = 0.2,
		changeTimePosition = 0,
		changeEcho = false,
	}

	if conceptTag == "matrix" then
		profile.buttonSpeed = 0.86
		profile.buttonVolume = 0.14
		profile.buttonTimePosition = 0.02
		profile.changeSpeed = 0.92
		profile.changeVolume = 0.24
		profile.changeEcho = true
	elseif conceptTag == "terminal" then
		profile.buttonSpeed = 0.78
		profile.buttonVolume = 0.13
		profile.buttonTimePosition = 0.01
		profile.changeSpeed = 0.84
		profile.changeVolume = 0.22
		profile.changeEcho = true
	elseif conceptTag == "arcade" then
		profile.buttonSpeed = 1.34
		profile.buttonVolume = 0.16
		profile.changeSpeed = 1.46
		profile.changeVolume = 0.24
		profile.changeEcho = true
	elseif conceptTag == "cyber" then
		profile.buttonSpeed = 1.18
		profile.buttonVolume = 0.15
		profile.changeSpeed = 1.28
		profile.changeVolume = 0.24
		profile.changeEcho = true
	elseif conceptTag == "nature" then
		profile.buttonSpeed = 0.96
		profile.buttonVolume = 0.1
		profile.changeSpeed = 1.02
		profile.changeVolume = 0.18
	elseif conceptTag == "horror" then
		profile.buttonSpeed = 0.68
		profile.buttonVolume = 0.1
		profile.buttonTimePosition = 0.03
		profile.changeSpeed = 0.74
		profile.changeVolume = 0.18
	elseif conceptTag == "fantasy" then
		profile.buttonSpeed = 1.08
		profile.buttonVolume = 0.11
		profile.changeSpeed = 1.16
		profile.changeVolume = 0.2
		profile.changeEcho = true
	elseif conceptTag == "tactical" then
		profile.buttonSpeed = 0.9
		profile.buttonVolume = 0.12
		profile.changeSpeed = 1
		profile.changeVolume = 0.2
	elseif conceptTag == "speed" then
		profile.buttonSpeed = 1.24
		profile.buttonVolume = 0.14
		profile.changeSpeed = 1.38
		profile.changeVolume = 0.22
	end

	if themeState.variant == "Soft" then
		profile.buttonVolume *= 0.85
		profile.changeVolume *= 0.85
		profile.buttonSpeed *= 0.96
	elseif themeState.variant == "Vivid" then
		profile.buttonVolume *= 1.12
		profile.changeVolume *= 1.12
		profile.buttonSpeed *= 1.04
	elseif themeState.variant == "Noir" then
		profile.buttonSpeed *= 0.93
		profile.changeSpeed *= 0.93
	end

	if themeState.tone == "Warm" then
		profile.buttonSpeed *= 0.97
		profile.changeSpeed *= 0.97
	elseif themeState.tone == "Cool" then
		profile.buttonSpeed *= 1.02
		profile.changeSpeed *= 1.03
	elseif themeState.tone == "Neon" then
		profile.buttonSpeed *= 1.06
		profile.changeSpeed *= 1.08
		profile.changeEcho = true
	end

	if themeState.contrast == "Punchy" then
		profile.buttonVolume *= 1.08
		profile.changeVolume *= 1.1
	elseif themeState.contrast == "Soft" then
		profile.buttonVolume *= 0.9
		profile.changeVolume *= 0.9
	end

	return profile
end

function clampNumber(value, minValue, maxValue)
	if value < minValue then
		return minValue
	elseif value > maxValue then
		return maxValue
	end
	return value
end

function getButtonSfxIntent(sourceButton)
	if not sourceButton then
		return "generic"
	end

	local role = string.lower(tostring(sourceButton:GetAttribute("ThemeRole") or "secondary"))
	local combined = string.lower(table.concat({
		tostring(sourceButton.Text or ""),
		tostring(sourceButton.Name or ""),
		tostring(sourceButton:GetAttribute("ThemeSfxHint") or ""),
	}, " "))

	local function contains(pattern)
		return string.find(combined, pattern, 1, true) ~= nil
	end

	if role == "warning" or role == "danger" or contains("clear") or contains("reset") then
		return "warning"
	elseif contains("generate") or contains("build") or contains("create") or contains("regenerate") or contains("runtime") then
		return "generate"
	elseif contains("preview") or contains("focus") or contains("refresh") or contains("view") or contains("rotate") or contains("zoom") then
		return "preview"
	elseif contains("toggle") or contains("show") or contains("hide") or contains("enable") or contains("disable") or contains("include") or contains("anchored") or contains("texture") or contains("audio volume") or contains("opacity") then
		return "toggle"
	elseif contains("theme") or contains("style") or contains("typography") or contains("tone") or contains("contrast") then
		return "theme"
	elseif contains("settings") or contains("guide") or contains("search") or contains("browse") or contains("open") or contains("close") then
		return "navigation"
	elseif contains("random") or contains("seed") or contains("favorite") or contains("experimental") then
		return "utility"
	elseif contains("select") or contains("keep") or contains("confirm") or contains("store") or contains("collision") then
		return "confirm"
	end

	if role == "active" or role == "success" then
		return "confirm"
	elseif role == "muted" then
		return "toggle"
	elseif role == "accent" or role == "teal" or role == "info" then
		return "navigation"
	end

	return "generic"
end

function getProceduralButtonSoundSignature(sourceButton, profile)
	local intent = getButtonSfxIntent(sourceButton)
	local signature = {
		intent = intent,
		soundId = profile.soundId,
		primarySpeed = profile.buttonSpeed,
		primaryVolume = profile.buttonVolume,
		primaryTimePosition = profile.buttonTimePosition,
		layers = {},
	}

	local role = sourceButton and string.lower(tostring(sourceButton:GetAttribute("ThemeRole") or "secondary")) or "secondary"
	local conceptTag = profile.conceptTag

	if intent == "generate" then
		signature.primarySpeed *= 0.94
		signature.primaryVolume *= 1.18
		signature.primaryTimePosition += 0.012
		table.insert(signature.layers, {delay = 0.04, speed = 1.12, volume = 0.58, timeOffset = 0.024})
		if conceptTag == "speed" or conceptTag == "arcade" or conceptTag == "cyber" then
			table.insert(signature.layers, {delay = 0.075, speed = 1.24, volume = 0.42, timeOffset = 0.036})
		end
	elseif intent == "preview" then
		signature.primarySpeed *= 1.08
		signature.primaryVolume *= 0.96
		signature.primaryTimePosition += 0.018
		table.insert(signature.layers, {delay = 0.03, speed = 1.18, volume = 0.34, timeOffset = 0.03})
	elseif intent == "toggle" then
		signature.primarySpeed *= 1.02
		signature.primaryVolume *= 0.82
		signature.primaryTimePosition += 0.006
		table.insert(signature.layers, {delay = 0.028, speed = 0.94, volume = 0.24, timeOffset = 0.01})
	elseif intent == "theme" then
		signature.primarySpeed *= 1.06
		signature.primaryVolume *= 1.02
		signature.primaryTimePosition += 0.02
		table.insert(signature.layers, {delay = 0.05, speed = 1.16, volume = 0.38, timeOffset = 0.034})
		if conceptTag == "fantasy" or conceptTag == "cyber" or conceptTag == "arcade" then
			table.insert(signature.layers, {delay = 0.09, speed = 1.28, volume = 0.24, timeOffset = 0.04})
		end
	elseif intent == "navigation" then
		signature.primarySpeed *= 1.14
		signature.primaryVolume *= 0.88
		signature.primaryTimePosition += 0.016
	elseif intent == "utility" then
		signature.primarySpeed *= 1.12
		signature.primaryVolume *= 0.92
		signature.primaryTimePosition += 0.014
		table.insert(signature.layers, {delay = 0.024, speed = 1.26, volume = 0.22, timeOffset = 0.02})
	elseif intent == "confirm" then
		signature.primarySpeed *= 0.98
		signature.primaryVolume *= 1.04
		signature.primaryTimePosition += 0.01
		table.insert(signature.layers, {delay = 0.036, speed = 1.08, volume = 0.32, timeOffset = 0.022})
	elseif intent == "warning" then
		signature.primarySpeed *= 0.82
		signature.primaryVolume *= 1.08
		signature.primaryTimePosition += 0.028
		table.insert(signature.layers, {delay = 0.055, speed = 0.72, volume = 0.4, timeOffset = 0.04})
	end

	if role == "warning" or role == "danger" then
		signature.primarySpeed *= 0.94
		signature.primaryVolume *= 1.08
	elseif role == "active" or role == "success" then
		signature.primarySpeed *= 1.03
		signature.primaryVolume *= 1.04
	elseif role == "muted" then
		signature.primaryVolume *= 0.82
	end

	if conceptTag == "matrix" or conceptTag == "terminal" then
		signature.primarySpeed *= 0.95
		signature.primaryTimePosition += 0.004
	elseif conceptTag == "nature" then
		signature.primaryVolume *= 0.9
		signature.primarySpeed *= 0.97
	elseif conceptTag == "horror" then
		signature.primarySpeed *= 0.88
		signature.primaryVolume *= 0.94
		signature.primaryTimePosition += 0.012
	elseif conceptTag == "speed" or conceptTag == "arcade" then
		signature.primarySpeed *= 1.06
	end

	signature.primarySpeed = clampNumber(signature.primarySpeed, 0.58, 1.7)
	signature.primaryVolume = clampNumber(signature.primaryVolume, 0, 0.32)
	signature.primaryTimePosition = clampNumber(signature.primaryTimePosition, 0, 0.12)

	for _, layer in ipairs(signature.layers) do
		layer.speed = clampNumber(signature.primarySpeed * layer.speed, 0.58, 1.85)
		layer.volume = clampNumber(signature.primaryVolume * layer.volume, 0, 0.22)
		layer.timePosition = clampNumber(signature.primaryTimePosition + (layer.timeOffset or 0), 0, 0.14)
	end

	return signature
end

function playThemeUiSoundLayer(soundId, baseName, timePosition, playbackSpeed, volume, delaySeconds)
	if volume <= 0 then
		return
	end

	themeAudioState.soundSerial = (themeAudioState.soundSerial % 12) + 1
	local soundName = string.format("%s_%d", baseName, themeAudioState.soundSerial)
	local sound = ensureThemeUiSound(soundName)
	sound.SoundId = soundId
	sound.TimePosition = timePosition
	sound.PlaybackSpeed = playbackSpeed
	sound.Volume = volume

	local function startPlayback()
		if sound.Volume > 0 then
			sound:Play()
		end
	end

	if delaySeconds and delaySeconds > 0 then
		task.delay(delaySeconds, startPlayback)
	else
		startPlayback()
	end
end

function ensureThemeUiSound(soundName)
	local existing = widget:FindFirstChild(soundName)
	if existing and existing:IsA("Sound") then
		return existing
	end

	local sound = Instance.new("Sound")
	sound.Name = soundName
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.Parent = widget
	return sound
end

function playThemeUiSound(kind, sourceButton)
	local profile = getThemeUiSoundProfile()
	local now = os.clock()
	if kind == "button_press" and now - themeAudioState.lastButtonAt < 0.045 then
		return
	end
	if kind == "button_press" then
		themeAudioState.lastButtonAt = now
	end

	if kind == "theme_change" then
		local sound = ensureThemeUiSound("ThemeChangeSound")
		sound.SoundId = profile.soundId
		sound.TimePosition = profile.changeTimePosition
		sound.PlaybackSpeed = profile.changeSpeed
		sound.Volume = profile.changeVolume * getAudioVolumeMultiplier(themeChangeAudioEnabled, themeChangeAudioVolumeLevel)
		if sound.Volume <= 0 then
			return
		end
		sound:Play()

		if profile.changeEcho then
			local echoSpeed = sound.PlaybackSpeed * (profile.conceptTag == "horror" and 0.92 or 1.08)
			local echoVolume = sound.Volume * 0.5
			task.delay(0.05, function()
				local echoSound = ensureThemeUiSound("ThemeChangeEchoSound")
				echoSound.SoundId = profile.soundId
				echoSound.TimePosition = sound.TimePosition
				echoSound.PlaybackSpeed = echoSpeed
				echoSound.Volume = echoVolume
				if echoSound.Volume > 0 then
					echoSound:Play()
				end
			end)
		end
		return
	end

	local volumeMultiplier = getAudioVolumeMultiplier(uiAudioEnabled, uiAudioVolumeLevel)
	local signature = getProceduralButtonSoundSignature(sourceButton, profile)
	local primaryVolume = signature.primaryVolume * volumeMultiplier
	if primaryVolume <= 0 then
		return
	end

	playThemeUiSoundLayer(
		signature.soundId,
		"ThemeButtonSound",
		signature.primaryTimePosition,
		signature.primarySpeed,
		primaryVolume,
		0
	)

	for _, layer in ipairs(signature.layers) do
		playThemeUiSoundLayer(
			signature.soundId,
			"ThemeButtonLayerSound",
			layer.timePosition,
			layer.speed,
			layer.volume * volumeMultiplier,
			layer.delay
		)
	end

	if signature.intent == "theme" and profile.changeEcho then
		local echoSpeed = signature.primarySpeed * (profile.conceptTag == "horror" and 0.94 or 1.1)
		local echoVolume = primaryVolume * 0.34
		task.delay(0.05, function()
			local echoSound = ensureThemeUiSound("ThemeButtonThemeEchoSound")
			echoSound.SoundId = signature.soundId
			echoSound.TimePosition = signature.primaryTimePosition
			echoSound.PlaybackSpeed = echoSpeed
			echoSound.Volume = echoVolume
			if echoSound.Volume > 0 then
				echoSound:Play()
			end
		end)
	end
end

function playGenerationCompletionSound(kind)
	if not variationCompletionAudioEnabled then
		return
	end

	local volumeMultiplier = getCompletionAudioVolumeMultiplier()
	if volumeMultiplier <= 0 then
		return
	end

	local profile = getThemeUiSoundProfile()
	local concept = string.lower(profile.conceptTag or "")
	local soundId = "rbxasset://sounds/electronicpingshort.wav"
	local baseTimePosition = 0.01
	local baseVolume = clampNumber(0.26 * volumeMultiplier, 0.12, 0.5)
	if baseVolume <= 0 then
		return
	end

	if kind == "batch_complete" then
		local firstNoteSpeed = concept == "horror" and 0.84 or (concept == "nature" and 0.98 or 1.02)
		local secondNoteSpeed = concept == "horror" and 1.0 or (concept == "arcade" and 1.34 or 1.26)
		playThemeUiSoundLayer(soundId, "ThemeBatchCompleteTaSound", baseTimePosition, firstNoteSpeed, baseVolume * 0.92, 0)
		playThemeUiSoundLayer(soundId, "ThemeBatchCompleteTaTaSound", baseTimePosition, secondNoteSpeed, baseVolume * 1.18, 0.18)
		return
	end

	local completionSpeed = concept == "terminal" and 1.1 or (concept == "nature" and 0.96 or 1.04)
	playThemeUiSoundLayer(soundId, "ThemeVariationCompleteSound", baseTimePosition, completionSpeed, baseVolume * 0.86, 0)
	playThemeUiSoundLayer(soundId, "ThemeVariationCompleteLiftSound", baseTimePosition, completionSpeed * 1.16, baseVolume * 0.62, 0.06)
end

function getGenerationActivityThemeProfile()
	local lowerThemeName = string.lower(themeState.name or "")
	local lowerCategory = string.lower(getThemeCategory(themeState.name) or "")
	local themeHash = 0
	for index = 1, #lowerThemeName do
		themeHash = (themeHash + string.byte(lowerThemeName, index) * index) % 100000
	end
	local conceptTag = getThemeConceptTag(lowerThemeName, lowerCategory)
	local conceptBank = getConceptPhraseBank(conceptTag)
	local defaultTitle = conceptBank.titles[(themeHash % #conceptBank.titles) + 1]
	local defaultPreviewTitle = conceptBank.previewTitles[(themeHash % #conceptBank.previewTitles) + 1]
	local profile = {
		titlePrefix = defaultTitle,
		previewTitlePrefix = defaultPreviewTitle,
		animationStyle = "sweep",
		phases = conceptBank.phases,
		fillTop = (themeState.current.buttons.info or Color3.fromRGB(143, 223, 255)):Lerp(Color3.fromRGB(255, 255, 255), 0.28),
		fillBottom = themeState.current.buttons.active or Color3.fromRGB(77, 131, 255),
		sweepTransparency = 0.65,
		sweepSpan = 42,
		sweepSpeed = 120,
		quantizeSteps = nil,
		suffixFrames = getConceptFrameSet(conceptTag),
		detailPrefix = conceptBank.detailPrefix,
		barDirection = "forward",
		pulseFrequency = 3,
		pulseAmplitude = 0.8,
		microJitter = 0,
		progressMotion = "steady",
		progressFloor = 0.04,
		shimmerMode = "linear",
		phaseRate = 1.5,
		seedOffset = (themeHash % 4096) / 4096,
		font = themeState.current.typography and themeState.current.typography.body or Enum.Font.Gotham,
		titleFont = themeState.current.typography and themeState.current.typography.title or Enum.Font.GothamBold,
		asciiFrames = getConceptAsciiFrameSet(conceptTag),
		asciiRate = 4.5,
		asciiWidth = 18,
		barVisualStyle = "solid",
		barGlyphFrames = getConceptBarGlyphSet(conceptTag),
		barSceneFrames = getConceptBarSceneFrames(conceptTag),
		barSegmentCount = 12,
		barNodeSize = 10,
	}

	if conceptTag == "matrix" then
		profile.animationStyle = "matrix"
		profile.fillTop = Color3.fromRGB(148, 255, 169)
		profile.fillBottom = Color3.fromRGB(34, 176, 86)
		profile.sweepTransparency = 0.28
		profile.sweepSpan = 14
		profile.sweepSpeed = 210
		profile.quantizeSteps = 28
		profile.font = Enum.Font.Code
		profile.titleFont = Enum.Font.Code
		profile.progressMotion = "glitch"
		profile.pulseAmplitude = 0.55
		profile.microJitter = 0.016
		profile.shimmerMode = "burst"
		profile.phaseRate = 2.2
		profile.asciiRate = 8.5
		profile.asciiWidth = 16
		profile.barVisualStyle = "matrix"
		profile.barSegmentCount = 12
		profile.barNodeSize = 8
	elseif conceptTag == "terminal" then
		profile.fillTop = Color3.fromRGB(164, 255, 146)
		profile.fillBottom = Color3.fromRGB(78, 201, 103)
		profile.sweepTransparency = 0.22
		profile.sweepSpan = 18
		profile.sweepSpeed = 72
		profile.animationStyle = string.find(lowerThemeName, "blueprint", 1, true) and "grid" or "pipboy"
		profile.quantizeSteps = 12
		profile.barDirection = "pingpong"
		profile.font = Enum.Font.Code
		profile.titleFont = Enum.Font.Code
		profile.progressMotion = string.find(lowerThemeName, "blueprint", 1, true) and "staged" or "scan"
		profile.pulseAmplitude = 0.38
		profile.microJitter = 0.005
		profile.shimmerMode = "step"
		profile.phaseRate = string.find(lowerThemeName, "blueprint", 1, true) and 0.9 or 1.1
		profile.asciiRate = 4
		profile.asciiWidth = 14
		profile.barVisualStyle = string.find(lowerThemeName, "blueprint", 1, true) and "grid" or "readout"
		profile.barNodeSize = 9
		if string.find(lowerThemeName, "blueprint", 1, true) then
			profile.pulseAmplitude = 0.34
			profile.microJitter = 0.003
			profile.detailPrefix = "[grid] "
			profile.suffixFrames = {" /", " -", " \\", " |"}
		elseif string.find(lowerThemeName, "fallout", 1, true) then
			profile.titlePrefix = "Pip-Boy Fabrication"
			profile.previewTitlePrefix = "Pip-Boy Preview"
			profile.detailPrefix = "PIP-OS: "
		end
	elseif conceptTag == "arcade" then
		profile.animationStyle = "arcade"
		profile.sweepSpan = 56
		profile.sweepSpeed = 168
		profile.pulseFrequency = 9
		profile.progressMotion = "combo"
		profile.pulseAmplitude = 1.05
		profile.microJitter = 0.018
		profile.shimmerMode = "surge"
		profile.phaseRate = 2
		profile.asciiRate = 7
		profile.asciiWidth = 15
		profile.barVisualStyle = "arcade"
		profile.barNodeSize = 12
	else
		local animationStyles = {
			utility = {"sweep", "beacon", "ladder", "ripple", "pulse", "strobe"},
			cyber = {"beacon", "pulse", "strobe", "ripple"},
			nature = {"ripple", "pulse", "sweep", "beacon"},
			horror = {"strobe", "pulse", "beacon", "ladder"},
			fantasy = {"ripple", "sweep", "pulse", "beacon"},
			tactical = {"ladder", "beacon", "strobe", "sweep"},
			speed = {"beacon", "sweep", "ladder", "pulse"},
		}
		local stylePool = animationStyles[conceptTag] or animationStyles.utility
		profile.animationStyle = stylePool[(themeHash % #stylePool) + 1]
		profile.sweepSpan = 22 + (themeHash % 35)
		profile.sweepSpeed = 72 + (themeHash % 120)
		profile.sweepTransparency = 0.32 + ((themeHash % 30) / 100)
		profile.pulseFrequency = 2 + (themeHash % 6)
		if profile.animationStyle == "ladder" then
			profile.quantizeSteps = 8 + (themeHash % 17)
			profile.suffixFrames = {" [=   ]", " [==  ]", " [=== ]", " [====]"}
		elseif profile.animationStyle == "beacon" then
			profile.barDirection = (themeHash % 2 == 0) and "forward" or "reverse"
			profile.suffixFrames = {" <>", " <<", " >>", " <>"}
		elseif profile.animationStyle == "ripple" then
			profile.barDirection = "pingpong"
			profile.suffixFrames = {" ~", " ~~", " ~~~", " ~~"}
		elseif profile.animationStyle == "pulse" then
			profile.suffixFrames = {" .", " ..", " ...", " ...."}
		elseif profile.animationStyle == "strobe" then
			profile.quantizeSteps = 10 + (themeHash % 10)
			profile.suffixFrames = {" [*]", " [ ]", " [*]", " [ ]"}
		else
			profile.suffixFrames = {" .", " ..", " ...", ""}
		end
	end

	if profile.progressMotion == "steady" then
		if conceptTag == "cyber" then
			profile.progressMotion = "surge"
			profile.pulseAmplitude = 0.92
			profile.microJitter = 0.01
			profile.shimmerMode = "surge"
			profile.phaseRate = 1.8
		elseif conceptTag == "nature" then
			profile.progressMotion = "grow"
			profile.pulseAmplitude = 0.56
			profile.microJitter = 0.004
			profile.shimmerMode = "drift"
			profile.phaseRate = 1.2
		elseif conceptTag == "horror" then
			profile.progressMotion = "creep"
			profile.pulseAmplitude = 0.24
			profile.microJitter = 0.007
			profile.shimmerMode = "drift"
			profile.phaseRate = 0.8
		elseif conceptTag == "fantasy" then
			profile.progressMotion = "drift"
			profile.pulseAmplitude = 0.48
			profile.microJitter = 0.004
			profile.shimmerMode = "drift"
			profile.phaseRate = 1
		elseif conceptTag == "tactical" or conceptTag == "speed" then
			profile.progressMotion = "lockstep"
			profile.pulseAmplitude = 0.46
			profile.microJitter = 0.006
			profile.shimmerMode = "step"
			profile.phaseRate = conceptTag == "speed" and 2 or 1.7
			profile.quantizeSteps = profile.quantizeSteps or (10 + (themeHash % 8))
		end
	end

	if profile.barVisualStyle == "solid" then
		if conceptTag == "cyber" then
			profile.barVisualStyle = "circuit"
		elseif conceptTag == "nature" then
			profile.barVisualStyle = "organic"
		elseif conceptTag == "horror" then
			profile.barVisualStyle = "ember"
		elseif conceptTag == "fantasy" then
			profile.barVisualStyle = "runes"
		elseif conceptTag == "tactical" then
			profile.barVisualStyle = "target"
		elseif conceptTag == "speed" then
			profile.barVisualStyle = "velocity"
		end
	end

	if themeState.variant == "Soft" then
		profile.pulseAmplitude *= 0.78
		profile.microJitter *= 0.55
		profile.sweepSpeed *= 0.9
		profile.asciiRate *= 0.9
	elseif themeState.variant == "Vivid" then
		profile.pulseAmplitude *= 1.18
		profile.microJitter += 0.004
		profile.sweepSpeed *= 1.08
		profile.asciiRate *= 1.08
	elseif themeState.variant == "Noir" then
		profile.pulseAmplitude *= 0.86
		profile.microJitter *= 0.65
	end

	if themeState.contrast == "Punchy" then
		profile.pulseAmplitude *= 1.12
		profile.sweepSpeed *= 1.05
	elseif themeState.contrast == "Soft" then
		profile.pulseAmplitude *= 0.82
		profile.microJitter *= 0.72
	end

	if themeState.tone == "Neon" then
		profile.microJitter += 0.004
		profile.sweepSpeed *= 1.07
		profile.asciiRate *= 1.06
	elseif themeState.tone == "Warm" then
		profile.phaseRate *= 0.94
	elseif themeState.tone == "Cool" then
		profile.phaseRate *= 1.04
	end

	return profile
end

function syncGenerationActivityTheme()
	local profile = getGenerationActivityThemeProfile()
	local themedGroups = {
		{
			title = ui.activityTitleLabel,
			status = ui.activityStatusLabel,
			meta = ui.activityMetaLabel,
			detail = ui.activityDetailLabel,
			barFrame = ui.activityBarFrame,
			barFill = ui.activityBarFill,
			barSweep = ui.activityBarSweep,
		},
		{
			title = ui.previewActivityTitleLabel,
			status = ui.previewActivityStatusLabel,
			meta = ui.previewActivityMetaLabel,
			detail = ui.previewActivityDetailLabel,
			barFrame = ui.previewActivityBarFrame,
			barFill = ui.previewActivityBarFill,
			barSweep = ui.previewActivityBarSweep,
		},
	}

	for _, group in ipairs(themedGroups) do
		if group.title then
			local decor = ensureActivityBarDecor(group.barFrame)
			group.title.Font = profile.titleFont
			group.status.Font = profile.font
			group.meta.Font = profile.font
			group.detail.Font = profile.font
			createStroke(group.barFrame, themeState.current.viewportStroke)
			tweenThemeStroke(group.barFrame, themeState.current.viewportStroke)
			tweenThemeBackground(group.barFrame, themeState.current.inputBase)
			tweenThemeBackground(group.barFill, profile.fillBottom)
			addVerticalGradient(group.barFill, profile.fillTop, profile.fillBottom)
			group.barSweep.BackgroundTransparency = profile.sweepTransparency
			if decor and decor.glyphLabel then
				decor.glyphLabel.Font = profile.font == Enum.Font.Code and Enum.Font.Code or Enum.Font.GothamBold
				decor.glyphLabel.TextColor3 = profile.fillTop:Lerp(Color3.fromRGB(255, 255, 255), 0.38)
			end
			if decor and decor.sceneLabel then
				decor.sceneLabel.Font = Enum.Font.Code
				decor.sceneLabel.TextColor3 = profile.fillTop:Lerp(Color3.fromRGB(255, 255, 255), 0.2)
			end
			if decor and decor.topLine then
				decor.topLine.BackgroundColor3 = profile.fillTop
			end
			if decor and decor.bottomLine then
				decor.bottomLine.BackgroundColor3 = profile.fillBottom
			end
			if decor and decor.pulseNode then
				decor.pulseNode.BackgroundColor3 = profile.fillTop
				decor.pulseNode.Size = UDim2.new(0, profile.barNodeSize or 10, 0, profile.barNodeSize or 10)
			end
			if decor and decor.segments then
				for _, segment in ipairs(decor.segments) do
					if segment then
						segment.BackgroundColor3 = profile.fillTop
					end
				end
			end
		end
	end
end

function formatDuration(seconds)
	seconds = math.max(0, math.floor((seconds or 0) + 0.5))
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60
	if minutes > 0 then
		return ("%dm %02ds"):format(minutes, remainingSeconds)
	end
	return ("%ds"):format(remainingSeconds)
end

function refreshGenerationActivityUi()
	if not ui.activityFrame or not ui.previewActivityFrame then
		return
	end
	if not generationActivityState.active then
		ui.activityFrame.Visible = false
		ui.previewActivityFrame.Visible = false
		return
	end

	local now = os.clock()
	local elapsed = math.max(0, now - generationActivityState.startedAt)
	local totalSteps = math.max(generationActivityState.totalSteps, 1)
	local completedSteps = math.clamp(generationActivityState.processedSteps, 0, totalSteps)
	local profile = getGenerationActivityThemeProfile()
	local phaseName = profile.phases[(math.floor(now * (profile.phaseRate or 1.5)) % #profile.phases) + 1]
	local baseProgress = completedSteps / totalSteps
	local activePulse = generationActivityState.currentStep > completedSteps and completedSteps < totalSteps
	local displayProgress = computeGenerationSimulationProgress(profile, now, elapsed, baseProgress, totalSteps, activePulse)
	local statusSuffix = ""
	local detailSegments = {
		generationActivityState.currentLabel ~= "" and generationActivityState.currentLabel or "Waiting for Roblox to return the next result.",
		phaseName,
		generationActivityState.detail ~= "" and generationActivityState.detail or "Live progress is estimated from completed variations.",
	}
	if profile.detailPrefix then
		detailSegments[2] = profile.detailPrefix .. detailSegments[2]
	end

	if profile.animationStyle == "matrix" then
		statusSuffix = profile.suffixFrames[(math.floor(now * 8) % #profile.suffixFrames) + 1]
		displayProgress = math.clamp(math.floor(displayProgress * profile.quantizeSteps) / profile.quantizeSteps, 0.04, 1)
		detailSegments[1] = "[" .. string.rep("0", (math.floor(now * 10) % 3) + 1) .. "] " .. detailSegments[1]
	elseif profile.animationStyle == "pipboy" then
		statusSuffix = profile.suffixFrames[(math.floor(now * 3.5) % #profile.suffixFrames) + 1]
		displayProgress = math.clamp(math.floor(displayProgress * profile.quantizeSteps) / profile.quantizeSteps, 0.04, 1)
		detailSegments[1] = string.format("STAT %02d %%  %s", math.floor(displayProgress * 100), detailSegments[1])
	elseif profile.animationStyle == "terminal" then
		statusSuffix = profile.suffixFrames[(math.floor(now * 4) % #profile.suffixFrames) + 1]
		displayProgress = math.clamp(math.floor(displayProgress * profile.quantizeSteps) / profile.quantizeSteps, 0.04, 1)
		detailSegments[1] = (math.floor(now * 6) % 2 == 0 and "> " or ">> ") .. detailSegments[1]
	elseif profile.animationStyle == "grid" then
		statusSuffix = profile.suffixFrames[(math.floor(now * 5) % #profile.suffixFrames) + 1]
	elseif profile.animationStyle == "arcade" then
		statusSuffix = profile.suffixFrames[(math.floor(now * 7) % #profile.suffixFrames) + 1]
	elseif profile.animationStyle == "ladder" or profile.animationStyle == "strobe" then
		statusSuffix = profile.suffixFrames[(math.floor(now * 5) % #profile.suffixFrames) + 1]
		displayProgress = math.clamp(math.floor(displayProgress * profile.quantizeSteps) / profile.quantizeSteps, 0.04, 1)
	elseif profile.animationStyle == "beacon" then
		statusSuffix = profile.suffixFrames[(math.floor(now * 4) % #profile.suffixFrames) + 1]
	elseif profile.animationStyle == "ripple" then
		statusSuffix = profile.suffixFrames[(math.floor(now * 6) % #profile.suffixFrames) + 1]
		displayProgress = math.clamp(displayProgress + (math.sin(now * profile.pulseFrequency) * 0.03), 0.04, 1)
	elseif profile.animationStyle == "pulse" then
		statusSuffix = profile.suffixFrames[(math.floor(now * 4) % #profile.suffixFrames) + 1]
	else
		statusSuffix = profile.suffixFrames[(math.floor(now * 2.5) % #profile.suffixFrames) + 1]
	end
	local averageSecondsPerStep = completedSteps > 0 and (elapsed / completedSteps) or nil
	local remainingSteps = math.max(totalSteps - completedSteps, 0)
	local etaText = averageSecondsPerStep and formatDuration(remainingSteps * averageSecondsPerStep) or "estimating..."
	local asciiPanel = getAnimatedAsciiPanel(profile, now, displayProgress)
	local shimmerSpan = profile.sweepSpan or 42
	local usePreviewPanel = generationActivityState.mode == "Preview"
	local targetFrame = usePreviewPanel and ui.previewActivityFrame or ui.activityFrame
	local targetTitleLabel = usePreviewPanel and ui.previewActivityTitleLabel or ui.activityTitleLabel
	local targetStatusLabel = usePreviewPanel and ui.previewActivityStatusLabel or ui.activityStatusLabel
	local targetMetaLabel = usePreviewPanel and ui.previewActivityMetaLabel or ui.activityMetaLabel
	local targetDetailLabel = usePreviewPanel and ui.previewActivityDetailLabel or ui.activityDetailLabel
	local targetBarFill = usePreviewPanel and ui.previewActivityBarFill or ui.activityBarFill
	local targetBarSweep = usePreviewPanel and ui.previewActivityBarSweep or ui.activityBarSweep
	local targetBarFrame = usePreviewPanel and ui.previewActivityBarFrame or ui.activityBarFrame
	local targetBarDecor = ensureActivityBarDecor(targetBarFrame)
	local shimmerOffset = computeGenerationShimmerOffset(profile, targetBarFrame.AbsoluteSize.X, shimmerSpan, now, elapsed)

	ui.activityFrame.Visible = not usePreviewPanel
	ui.previewActivityFrame.Visible = usePreviewPanel
	targetFrame.Visible = true
	targetTitleLabel.Text = usePreviewPanel and profile.previewTitlePrefix or profile.titlePrefix
	if usePreviewPanel then
		local currentIndex = math.min(generationActivityState.currentStep, totalSteps)
		local previewMetaParts = {
			detailSegments[2],
			("Elapsed %s"):format(formatDuration(elapsed)),
			("ETA %s"):format(etaText),
		}
		if generationActivityState.cacheHits > 0 then
			previewMetaParts[#previewMetaParts + 1] = ("Cache %d"):format(generationActivityState.cacheHits)
		end

		targetStatusLabel.Text = totalSteps > 1
			and ("Preview variant %d of %d"):format(currentIndex, totalSteps)
			or "Building preview"
		targetMetaLabel.Text = table.concat(previewMetaParts, "  |  ")
		targetDetailLabel.Text = ""
		targetDetailLabel.Visible = false
	else
		targetStatusLabel.Text = ("%s  |  %d/%d%s"):format(
			detailSegments[1],
			math.min(generationActivityState.currentStep, totalSteps),
			totalSteps,
			statusSuffix
		)
		targetMetaLabel.Text = ("%s  |  Elapsed %s  |  ETA %s  |  Cache %d"):format(
			detailSegments[2],
			formatDuration(elapsed),
			etaText,
			generationActivityState.cacheHits
		)
		targetDetailLabel.Text = asciiPanel
		targetDetailLabel.Visible = true
	end
	targetBarFill.Size = UDim2.new(displayProgress, 0, 1, 0)
	targetBarSweep.Position = UDim2.new(0, shimmerOffset, 0, 2)
	if targetBarDecor and targetBarDecor.glyphLabel then
		local glyphFrames = profile.barGlyphFrames or {"BUILD"}
		targetBarDecor.glyphLabel.Text = glyphFrames[(math.floor(now * (profile.phaseRate or 1.5) * 2) % #glyphFrames) + 1]
	end
	if targetBarDecor and targetBarDecor.sceneLabel then
		local sceneFrames = profile.barSceneFrames or {"[ build ]"}
		targetBarDecor.sceneLabel.Text = sceneFrames[(math.floor(now * (profile.phaseRate or 1.5) * 2.2) % #sceneFrames) + 1]
	end
	if targetBarDecor and targetBarDecor.pulseNode then
		local nodeAlpha = math.clamp(displayProgress, 0, 1)
		targetBarDecor.pulseNode.Position = UDim2.new(nodeAlpha, 0, 0.5, 0)
		targetBarDecor.pulseNode.BackgroundTransparency = profile.barVisualStyle == "ember" and 0.28 or 0.14
	end
	if targetBarDecor and targetBarDecor.segments then
		local activeSegments = math.max(1, math.floor((profile.barSegmentCount or #targetBarDecor.segments) * displayProgress + 0.5))
		for index, segment in ipairs(targetBarDecor.segments) do
			if segment then
				segment.Visible = index <= (profile.barSegmentCount or #targetBarDecor.segments)
				if segment.Visible then
					local alpha = index / math.max(profile.barSegmentCount or #targetBarDecor.segments, 1)
					local isActive = index <= activeSegments
					if profile.barVisualStyle == "matrix" then
						segment.BackgroundTransparency = isActive and (0.18 + ((index + math.floor(now * 10)) % 3) * 0.12) or 0.9
						segment.Size = UDim2.new(0, 4, 1, -4 - ((index + math.floor(now * 8)) % 3))
					elseif profile.barVisualStyle == "readout" or profile.barVisualStyle == "grid" then
						segment.BackgroundTransparency = isActive and 0.24 or 0.88
						segment.Size = UDim2.new(0, 3, 1, -4)
					elseif profile.barVisualStyle == "arcade" then
						segment.BackgroundTransparency = isActive and (0.08 + ((math.floor(now * 8) + index) % 2) * 0.08) or 0.9
						segment.Size = UDim2.new(0, 7, 1, -4)
					elseif profile.barVisualStyle == "organic" then
						segment.BackgroundTransparency = isActive and 0.28 or 0.92
						segment.Size = UDim2.new(0, 5, 0.42 + (math.sin(now * 2 + index) * 0.18 + 0.18), 0)
						segment.Position = UDim2.new((index - 0.5) / 12, 0, 0.5, 0)
					elseif profile.barVisualStyle == "runes" then
						segment.BackgroundTransparency = isActive and 0.18 or 0.9
						segment.Size = UDim2.new(0, 4, 1, -2)
					elseif profile.barVisualStyle == "target" or profile.barVisualStyle == "velocity" or profile.barVisualStyle == "circuit" then
						segment.BackgroundTransparency = isActive and 0.18 or 0.9
						segment.Size = UDim2.new(0, 5, 1, -4)
					elseif profile.barVisualStyle == "ember" then
						segment.BackgroundTransparency = isActive and (0.22 + (1 - alpha) * 0.18) or 0.92
						segment.Size = UDim2.new(0, 5, 0.55 + ((math.sin(now * 3 + index) + 1) * 0.12), 0)
						segment.Position = UDim2.new((index - 0.5) / 12, 0, 0.5, 0)
					else
						segment.BackgroundTransparency = isActive and 0.2 or 0.9
						segment.Size = UDim2.new(0, 6, 1, -6)
					end
				end
			end
		end
	end
end

function beginGenerationActivity(mode, totalSteps, currentLabel, detail)
	generationActivityState.active = true
	generationActivityState.mode = mode or "Generate"
	generationActivityState.startedAt = os.clock()
	generationActivityState.totalSteps = math.max(tonumber(totalSteps) or 1, 1)
	generationActivityState.processedSteps = 0
	generationActivityState.currentStep = generationActivityState.totalSteps > 0 and 1 or 0
	generationActivityState.currentLabel = currentLabel or ""
	generationActivityState.detail = detail or ""
	generationActivityState.cacheHits = 0
	refreshGenerationActivityUi()
end

function updateGenerationActivity(currentStep, processedSteps, currentLabel, detail, cacheHits)
	if not generationActivityState.active then
		return
	end
	generationActivityState.currentStep = math.max(tonumber(currentStep) or generationActivityState.currentStep, 0)
	generationActivityState.processedSteps = math.max(tonumber(processedSteps) or generationActivityState.processedSteps, 0)
	generationActivityState.currentLabel = currentLabel or generationActivityState.currentLabel
	generationActivityState.detail = detail or generationActivityState.detail
	if cacheHits ~= nil then
		generationActivityState.cacheHits = math.max(tonumber(cacheHits) or generationActivityState.cacheHits, 0)
	end
	refreshGenerationActivityUi()
end

function endGenerationActivity()
	generationActivityState.active = false
	refreshGenerationActivityUi()
end

local previewState = {
	busy = false,
	activeModel = nil,
	activeRequest = nil,
	sessions = {},
	activeSessionIndex = 0,
	selectedSessionIndexes = {},
	orbitYaw = math.rad(45),
	orbitPitch = math.rad(20),
	orbitRadius = 18,
	orbitMinRadius = 8,
	orbitMaxRadius = 60,
	orbitTarget = Vector3.new(),
	dragging = false,
	dragLastPosition = nil,
	dragInput = nil,
	autoRotateEnabled = true,
	autoRotateSpeed = math.rad(24),
	lightingPresetName = "Studio",
	backgroundPresetName = "Light",
	rotateSpeedMode = "Normal",
	showOriginMarker = true,
	showBoundsOverlay = false,
	collisionOpacityMode = "Medium",
	decorationFolder = nil,
	displayButtons = {},
	compareCards = {},
	selectedPreviewCards = {},
}

function registerPreviewDisplayButton(button)
	table.insert(previewState.displayButtons, button)
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
	if previewState.collisionOpacityMode == "Low" then
		return isMeshPart and 0.68 or 0.85
	end
	if previewState.collisionOpacityMode == "High" then
		return isMeshPart and 0.22 or 0.54
	end
	return isMeshPart and 0.45 or 0.72
end

function ensurePreviewDecorationFolder()
	if previewState.decorationFolder and previewState.decorationFolder.Parent == ui.previewWorldModel then
		return previewState.decorationFolder
	end
	previewState.decorationFolder = Instance.new("Folder")
	previewState.decorationFolder.Name = "PreviewDecorations"
	previewState.decorationFolder.Parent = ui.previewWorldModel
	return previewState.decorationFolder
end

function clearPreviewDecorations()
	if previewState.decorationFolder and previewState.decorationFolder.Parent then
		previewState.decorationFolder:Destroy()
	end
	previewState.decorationFolder = nil
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
	ui.previewLightingButton.Text = "Lighting: " .. previewState.lightingPresetName
end

function syncPreviewBackgroundButton()
	ui.previewBackgroundButton.Text = "Background: " .. previewState.backgroundPresetName
end

function syncPreviewRotateSpeedButton()
	ui.previewRotateSpeedButton.Text = "Rotate Speed: " .. previewState.rotateSpeedMode
end

function syncPreviewOriginMarkerButton()
	ui.previewOriginMarkerButton.Text = "Origin Marker: " .. (previewState.showOriginMarker and "On" or "Off")
	setButtonThemeRole(ui.previewOriginMarkerButton, previewState.showOriginMarker and "active" or "muted")
end

function syncPreviewBoundsButton()
	ui.previewBoundsButton.Text = "Bounds Overlay: " .. (previewState.showBoundsOverlay and "On" or "Off")
	setButtonThemeRole(ui.previewBoundsButton, previewState.showBoundsOverlay and "active" or "muted")
end

function syncPreviewCollisionOpacityButton()
	ui.previewCollisionOpacityButton.Text = "Collision Opacity: " .. previewState.collisionOpacityMode
end

function syncPreviewViewportLighting()
	local preset = PREVIEW_LIGHTING_PRESETS[previewState.lightingPresetName] or PREVIEW_LIGHTING_PRESETS.Studio
	ui.previewViewport.Ambient = preset.ambient
	ui.previewViewport.LightColor = preset.lightColor
	ui.previewViewport.LightDirection = preset.lightDirection
	syncPreviewLightingButton()
	syncPreviewGalleryCards()
	syncSelectedPreviewCards()
end

function syncPreviewViewportBackground()
	local preset = PREVIEW_BACKGROUND_PRESETS[previewState.backgroundPresetName] or PREVIEW_BACKGROUND_PRESETS.Cool
	ui.previewViewport.BackgroundColor3 = preset.bottom
	addVerticalGradient(ui.previewViewport, preset.top, preset.bottom)
	createStroke(ui.previewViewport, preset.stroke)
	ui.previewSelectedFrame.BackgroundColor3 = preset.bottom
	addVerticalGradient(ui.previewSelectedFrame, preset.top, preset.bottom)
	createStroke(ui.previewSelectedFrame, preset.stroke)
	syncPreviewBackgroundButton()
	syncPreviewGalleryCards()
	syncSelectedPreviewCards()
end

function syncPreviewRotateSpeed()
	if previewState.rotateSpeedMode == "Slow" then
		previewState.autoRotateSpeed = math.rad(10)
	elseif previewState.rotateSpeedMode == "Fast" then
		previewState.autoRotateSpeed = math.rad(42)
	else
		previewState.autoRotateSpeed = math.rad(24)
	end
	syncPreviewRotateSpeedButton()
end

function updatePreviewDecorations()
	clearPreviewDecorations()
	if not previewState.activeModel then
		return
	end

	local folder = ensurePreviewDecorationFolder()
	local boundsCFrame, boundsSize = getPreviewBounds(previewState.activeModel)
	local pivotPosition = previewState.activeModel:IsA("Model") and previewState.activeModel:GetPivot().Position or boundsCFrame.Position

	if previewState.showOriginMarker then
		local originMarkerFolder = Instance.new("Folder")
		originMarkerFolder.Name = "OriginMarker"
		originMarkerFolder.Parent = folder
		local markerScale = math.max(math.min(math.max(boundsSize.X, boundsSize.Y, boundsSize.Z) * 0.12, 1.8), 0.35)
		createMarkerPart(originMarkerFolder, "OriginX", Vector3.new(markerScale * 2.2, markerScale * 0.16, markerScale * 0.16), CFrame.new(pivotPosition) * CFrame.new(markerScale, 0, 0), Color3.fromRGB(255, 98, 98))
		createMarkerPart(originMarkerFolder, "OriginY", Vector3.new(markerScale * 0.16, markerScale * 2.2, markerScale * 0.16), CFrame.new(pivotPosition) * CFrame.new(0, markerScale, 0), Color3.fromRGB(112, 232, 139))
		createMarkerPart(originMarkerFolder, "OriginZ", Vector3.new(markerScale * 0.16, markerScale * 0.16, markerScale * 2.2), CFrame.new(pivotPosition) * CFrame.new(0, 0, markerScale), Color3.fromRGB(108, 170, 255))
	end

	if previewState.showBoundsOverlay then
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
	if not previewState.activeModel then
		ui.previewStatsLabel.Text = "No preview loaded yet.\nGenerate a preview to inspect bounds, parts, and request settings."
		return
	end

	local boundsCFrame, boundsSize = getPreviewBounds(previewState.activeModel)
	local totalParts = 0
	if previewState.activeModel:IsA("BasePart") then
		totalParts += 1
	end
	for _, descendant in ipairs(previewState.activeModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			totalParts += 1
		end
	end
	local meshParts = countMeshParts(previewState.activeModel)
	local request = previewState.activeRequest
	local lines = {
		("Bounds: %s x %s x %s"):format(formatPreviewNumber(boundsSize.X), formatPreviewNumber(boundsSize.Y), formatPreviewNumber(boundsSize.Z)),
		("Center: %s, %s, %s"):format(formatPreviewNumber(boundsCFrame.Position.X), formatPreviewNumber(boundsCFrame.Position.Y), formatPreviewNumber(boundsCFrame.Position.Z)),
		("Parts: %d total, %d mesh"):format(totalParts, meshParts),
	}

	if request then
		lines[#lines + 1] = ("Request: size %s, max tris %s, textures %s"):format(tostring(request.targetSize), tostring(request.maxTriangles), tostring(request.textures))
		lines[#lines + 1] = ("Base %s, schema %s, seed %s, collider %s"):format(request.includeBase and "on" or "off", request.schemaName, request.seed ~= "" and request.seed or "random", request.colliderMode)
		lines[#lines + 1] = ("Variations: %s"):format(tostring(request.variationCount or 1))
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
	ui.regenerateSelectedButton.AutoButtonColor = not nextBusy
	ui.regenerateSelectedButton.Active = not nextBusy
	if nextBusy then
		ui.generateButton.Text = "Generating..."
	else
		ui.generateButton.Text = "Generate Detailed Model"
	end
end

function clearPreviewDisplay()
	local preservedModel = previewState.activeModel
	previewState.activeModel = nil
	previewState.activeRequest = nil
	clearCollisionHighlights()
	clearPreviewDecorations()
	for _, child in ipairs(ui.previewWorldModel:GetChildren()) do
		if preservedModel and child == preservedModel then
			child.Parent = nil
		else
			child:Destroy()
		end
	end
	syncAutoRotateButton()
	if ui.previewGenerateCurrentButton then
		ui.previewGenerateCurrentButton.Text = "Generate Current"
		setButtonThemeRole(ui.previewGenerateCurrentButton, "success")
	end
	ui.previewInfoLabel.Text = "Press Preview to generate a visual preview in this window."
	updatePreviewStats()
end

function togglePreviewSessionSelection(index)
	if previewState.selectedSessionIndexes[index] then
		previewState.selectedSessionIndexes[index] = nil
	else
		previewState.selectedSessionIndexes[index] = true
	end
	refreshPreviewTabs()
	syncPreviewActionButtons()
end

function getSelectedPreviewSessionCount()
	local total = 0
	for _, isSelected in pairs(previewState.selectedSessionIndexes) do
		if isSelected then
			total += 1
		end
	end
	return total
end

function getSelectedPreviewRequests()
	local requests = {}
	for index, session in ipairs(previewState.sessions) do
		if previewState.selectedSessionIndexes[index] and session and session.request then
			requests[#requests + 1] = buildSingleGenerationRequestFromPreview(session.request)
		end
	end
	return requests
end

function syncPreviewActionButtons()
	local hasCurrent = previewState.activeRequest ~= nil
	local selectedCount = getSelectedPreviewSessionCount()
	local totalSessions = #previewState.sessions
	local hasBatchChoices = totalSessions > 1
	local allSelected = totalSessions > 0 and selectedCount == totalSessions
	local hasPartialSelection = selectedCount > 0 and not allSelected

	if ui.previewGenerateCurrentButton then
		ui.previewGenerateCurrentButton.Visible = hasCurrent
		ui.previewGenerateCurrentButton.Active = hasCurrent and not previewState.busy
		ui.previewGenerateCurrentButton.AutoButtonColor = hasCurrent and not previewState.busy
	end
	if ui.previewGenerateSelectedButton then
		ui.previewGenerateSelectedButton.Visible = hasBatchChoices and hasPartialSelection
		ui.previewGenerateSelectedButton.Text = selectedCount > 0
			and ("Generate Selected (%d)"):format(selectedCount)
			or "Generate Selected"
		ui.previewGenerateSelectedButton.Active = hasBatchChoices and hasPartialSelection and not previewState.busy
		ui.previewGenerateSelectedButton.AutoButtonColor = hasBatchChoices and hasPartialSelection and not previewState.busy
	end
	if ui.previewGenerateAllButton then
		ui.previewGenerateAllButton.Visible = hasBatchChoices
		ui.previewGenerateAllButton.Text = totalSessions > 0
			and ("Generate All (%d)"):format(totalSessions)
			or "Generate All"
		ui.previewGenerateAllButton.Active = hasBatchChoices and not previewState.busy and totalSessions > 0
		ui.previewGenerateAllButton.AutoButtonColor = hasBatchChoices and not previewState.busy and totalSessions > 0
	end
	if ui.previewSelectAllTabsButton then
		ui.previewSelectAllTabsButton.Visible = hasBatchChoices and not allSelected
		ui.previewSelectAllTabsButton.Text = "Select All"
		ui.previewSelectAllTabsButton.Active = hasBatchChoices and not allSelected and not previewState.busy and totalSessions > 0
		ui.previewSelectAllTabsButton.AutoButtonColor = hasBatchChoices and not allSelected and not previewState.busy and totalSessions > 0
	end
	if ui.previewActionHintLabel then
		ui.previewActionHintLabel.Text = hasBatchChoices
			and "Use the preview gallery above: left-click cards to toggle selection, then right-click a variant to preview it here."
			or "Use the preview gallery above: right-click the preview card to focus the single variant, then generate it from here."
	end
end

function clearPreviewComparePanel()
	for _, child in ipairs(ui.previewCompareGrid:GetChildren()) do
		if not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end
	previewState.compareCards = {}
	ui.previewCompareFrame.Visible = false
end

function clearSelectedPreviewPanel()
	for _, child in ipairs(ui.previewSelectedFrame:GetChildren()) do
		if not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	previewState.selectedPreviewCards = {}
	ui.previewSelectedFrame.Visible = false
end

function updateCompareCardCamera(card)
	if not card or not card.model or not card.camera then
		return
	end
	local boundsCFrame, boundsSize = getPreviewBounds(card.model)
	local radius = math.max(boundsSize.X, boundsSize.Y, boundsSize.Z) * 0.9
	local orbitRadius = math.max(radius * 2.2, 8)
	local horizontal = math.cos(previewState.orbitPitch) * orbitRadius
	local offset = Vector3.new(
		math.cos(previewState.orbitYaw) * horizontal,
		math.sin(previewState.orbitPitch) * orbitRadius,
		math.sin(previewState.orbitYaw) * horizontal
	)
	card.camera.CFrame = CFrame.lookAt(boundsCFrame.Position + offset, boundsCFrame.Position)
end

function syncPreviewGalleryCards()
	for _, card in ipairs(previewState.compareCards) do
		if card.viewport then
			card.viewport.Ambient = ui.previewViewport.Ambient
			card.viewport.LightColor = ui.previewViewport.LightColor
			card.viewport.LightDirection = ui.previewViewport.LightDirection
			card.viewport.BackgroundColor3 = ui.previewViewport.BackgroundColor3
			addVerticalGradient(card.viewport, PREVIEW_BACKGROUND_PRESETS[previewState.backgroundPresetName].top, PREVIEW_BACKGROUND_PRESETS[previewState.backgroundPresetName].bottom)
		end
		updateCompareCardCamera(card)
	end
end

function updateSelectedPreviewCardCamera(card)
	if not card or not card.model or not card.camera then
		return
	end
	local boundsCFrame = select(1, getPreviewBounds(card.model))
	local horizontal = math.cos(previewState.orbitPitch) * previewState.orbitRadius
	local cameraOffset = Vector3.new(
		math.cos(previewState.orbitYaw) * horizontal,
		math.sin(previewState.orbitPitch) * previewState.orbitRadius,
		math.sin(previewState.orbitYaw) * horizontal
	)
	card.camera.CFrame = CFrame.lookAt(previewState.orbitTarget + cameraOffset, boundsCFrame.Position)
end

function syncSelectedPreviewCards()
	local preset = PREVIEW_BACKGROUND_PRESETS[previewState.backgroundPresetName] or PREVIEW_BACKGROUND_PRESETS.Cool
	for _, card in ipairs(previewState.selectedPreviewCards) do
		if card.viewport then
			card.viewport.Ambient = ui.previewViewport.Ambient
			card.viewport.LightColor = ui.previewViewport.LightColor
			card.viewport.LightDirection = ui.previewViewport.LightDirection
			card.viewport.BackgroundColor3 = preset.bottom
			addVerticalGradient(card.viewport, preset.top, preset.bottom)
			createStroke(card.viewport, preset.stroke)
		end
		updateSelectedPreviewCardCamera(card)
	end
end

function createSelectedPreviewCard(session, slotIndex)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(22, 30, 42)
	frame.BorderSizePixel = 0
	frame.Parent = ui.previewSelectedFrame
	createCorner(frame, 10)
	createStroke(frame, slotIndex == previewState.activeSessionIndex and Color3.fromRGB(112, 196, 255) or Color3.fromRGB(78, 101, 135))
	addVerticalGradient(frame, Color3.fromRGB(44, 58, 82), Color3.fromRGB(26, 35, 49))

	local title = createLabel(session.label or ("Variant %d"):format(slotIndex), 11, Enum.Font.GothamBold, Color3.fromRGB(239, 244, 250), 20)
	title.Size = UDim2.new(1, -12, 0, 20)
	title.Position = UDim2.new(0, 6, 0, 6)
	title.Parent = frame

	local subtitle = createLabel(slotIndex == previewState.activeSessionIndex and "Focused selection" or "Selected preview", 10, Enum.Font.Gotham, Color3.fromRGB(187, 204, 226), 18)
	subtitle.Size = UDim2.new(1, -12, 0, 18)
	subtitle.Position = UDim2.new(0, 6, 0, 26)
	subtitle.Parent = frame

	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(1, -12, 1, -56)
	viewport.Position = UDim2.new(0, 6, 0, 46)
	viewport.BackgroundColor3 = ui.previewViewport.BackgroundColor3
	viewport.BorderSizePixel = 0
	viewport.Parent = frame
	createCorner(viewport, 8)

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport
	local camera = Instance.new("Camera")
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local clone = session.model:Clone()
	clone.Name = "SelectedPreview"
	clone.Parent = worldModel

	previewState.selectedPreviewCards[#previewState.selectedPreviewCards + 1] = {
		frame = frame,
		model = clone,
		viewport = viewport,
		camera = camera,
	}
end

function updateSelectedPreviewPanel()
	clearSelectedPreviewPanel()
	ui.previewViewport.Visible = true
	ui.previewSelectedFrame.Visible = false
end

function createCompareViewportCard(session, slotIndex)
	local frame = Instance.new("TextButton")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.AutoButtonColor = false
	frame.Text = ""
	frame.BackgroundColor3 = Color3.fromRGB(25, 33, 46)
	frame.BorderSizePixel = 0
	frame.Parent = ui.previewCompareGrid
	local isActive = slotIndex == previewState.activeSessionIndex
	local isSelected = previewState.selectedSessionIndexes[slotIndex] == true
	local strokeColor = Color3.fromRGB(98, 126, 161)
	local topColor = Color3.fromRGB(48, 63, 86)
	local bottomColor = Color3.fromRGB(29, 39, 53)
	if isActive and isSelected then
		strokeColor = Color3.fromRGB(104, 211, 149)
		topColor = Color3.fromRGB(45, 92, 71)
		bottomColor = Color3.fromRGB(26, 54, 42)
	elseif isActive then
		strokeColor = Color3.fromRGB(231, 124, 136)
		topColor = Color3.fromRGB(103, 56, 65)
		bottomColor = Color3.fromRGB(59, 31, 36)
	elseif isSelected then
		strokeColor = Color3.fromRGB(88, 186, 168)
		topColor = Color3.fromRGB(37, 78, 72)
		bottomColor = Color3.fromRGB(23, 49, 45)
	end
	createCorner(frame, 10)
	createStroke(frame, strokeColor)
	addVerticalGradient(frame, topColor, bottomColor)

	local statusText = isActive and (isSelected and "Viewing + Selected" or "Viewing") or (isSelected and "Selected" or "Candidate")
	local title = createLabel(statusText, 10, Enum.Font.GothamBold, Color3.fromRGB(235, 241, 249), 18)
	title.Size = UDim2.new(1, -8, 0, 20)
	title.Position = UDim2.new(0, 4, 0, 4)
	title.Parent = frame

	local subtitle = createLabel(session.label or ("Variant %d"):format(slotIndex), 10, Enum.Font.Gotham, Color3.fromRGB(192, 209, 229), 18)
	subtitle.Size = UDim2.new(1, -8, 0, 18)
	subtitle.Position = UDim2.new(0, 4, 0, 22)
	subtitle.Parent = frame

	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(1, -8, 1, -48)
	viewport.Position = UDim2.new(0, 4, 0, 40)
	viewport.BackgroundColor3 = Color3.fromRGB(18, 24, 34)
	viewport.BorderSizePixel = 0
	viewport.Parent = frame
	createCorner(viewport, 8)
	createStroke(viewport, Color3.fromRGB(79, 105, 141))
	addVerticalGradient(viewport, Color3.fromRGB(69, 90, 126), Color3.fromRGB(38, 52, 76))
	viewport.Ambient = ui.previewViewport.Ambient
	viewport.LightColor = ui.previewViewport.LightColor
	viewport.LightDirection = ui.previewViewport.LightDirection

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport
	local camera = Instance.new("Camera")
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local clone = session.model:Clone()
	clone.Name = "ComparePreview"
	clone.Parent = worldModel

	previewState.compareCards[#previewState.compareCards + 1] = {
		frame = frame,
		model = clone,
		viewport = viewport,
		camera = camera,
	}
	updateCompareCardCamera(previewState.compareCards[#previewState.compareCards])

	frame.MouseButton1Click:Connect(function()
		togglePreviewSessionSelection(slotIndex)
	end)
	frame.MouseButton2Click:Connect(function()
		setActivePreviewSession(slotIndex)
	end)
end

function updatePreviewComparePanel()
	clearPreviewComparePanel()

	if #previewState.sessions == 0 then
		return
	end

	ui.previewCompareFrame.Visible = true
	for index, session in ipairs(previewState.sessions) do
		createCompareViewportCard(session, index)
	end

	ui.previewCompareHintLabel.Text = "All preview variants are visible here. Left-click to toggle selection. Right-click a variant to open it in the main preview."
	syncPreviewGalleryCards()
end

function refreshPreviewTabs()
	updatePreviewComparePanel()
	updateSelectedPreviewPanel()
end

function scrollPreviewTargetIntoView(target)
	if not target or not ui.previewRoot then
		return
	end
	local relativeY = target.AbsolutePosition.Y - ui.previewRoot.AbsolutePosition.Y + ui.previewRoot.CanvasPosition.Y
	local nextY = math.max(relativeY - 16, 0)
	ui.previewRoot.CanvasPosition = Vector2.new(0, nextY)
end

function setActivePreviewSession(index)
	local session = previewState.sessions[index]
	if not session then
		return
	end

	clearPreviewDisplay()
	previewState.activeSessionIndex = index
	previewState.activeModel = session.model
	previewState.activeRequest = session.request
	session.model.Name = "PreviewModel"
	session.model.Parent = ui.previewWorldModel
	captureCollisionData(session.model, session.colliderMode or session.request.colliderMode)
	focusPreviewCamera(session.model)
	updatePreviewStats()
	ui.previewInfoLabel.Text = session.infoText or "Preview ready. Drag to orbit, use zoom, or enable auto-rotate."
	refreshPreviewTabs()
	syncPreviewActionButtons()
	scrollPreviewTargetIntoView(ui.previewViewport)
end

function clearPreviewSessions()
	clearPreviewDisplay()
	for _, session in ipairs(previewState.sessions) do
		if session.model and session.model.Parent == nil then
			session.model:Destroy()
		elseif session.model and session.model.Parent == ui.previewWorldModel then
			session.model.Parent = nil
			session.model:Destroy()
		end
	end
	previewState.sessions = {}
	previewState.activeSessionIndex = 0
	previewState.selectedSessionIndexes = {}
	refreshPreviewTabs()
	syncPreviewActionButtons()
end

function replacePreviewSessions(sessions, activeIndex, statusMessage)
	previewWidget.Enabled = true
	clearPreviewSessions()
	previewState.sessions = sessions or {}
	previewState.activeSessionIndex = 0
	previewState.selectedSessionIndexes = {}
	refreshPreviewTabs()
	if #previewState.sessions == 1 then
		setActivePreviewSession(math.clamp(activeIndex or 1, 1, #previewState.sessions))
	elseif #previewState.sessions > 1 then
		clearPreviewDisplay()
		ui.previewInfoLabel.Text = "Right-click a gallery variant to preview it here. Left-click variants to select the ones you want to generate."
		updatePreviewStats()
		syncPreviewActionButtons()
	end
	setPreviewBusy(false)
	if statusMessage then
		setStatus(statusMessage, "success")
	end
end

function applyPreviewCamera()
	local horizontal = math.cos(previewState.orbitPitch) * previewState.orbitRadius
	local cameraOffset = Vector3.new(
		math.cos(previewState.orbitYaw) * horizontal,
		math.sin(previewState.orbitPitch) * previewState.orbitRadius,
		math.sin(previewState.orbitYaw) * horizontal
	)
	ui.previewCamera.CFrame = CFrame.lookAt(previewState.orbitTarget + cameraOffset, previewState.orbitTarget)
	syncPreviewGalleryCards()
	syncSelectedPreviewCards()
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
	previewState.orbitTarget = cframe.Position
	previewState.orbitMinRadius = math.max(radius * 1.1, 5)
	previewState.orbitMaxRadius = math.max(radius * 6, previewState.orbitMinRadius + 14)
	previewState.orbitRadius = math.clamp(math.max(radius * 2.2, 8), previewState.orbitMinRadius, previewState.orbitMaxRadius)
	previewState.orbitYaw = math.rad(45)
	previewState.orbitPitch = math.rad(20)
	applyPreviewCamera()
	updatePreviewDecorations()
end

function syncAutoRotateButton()
	if previewState.autoRotateEnabled then
		ui.autoRotateButton.Text = "Auto Rotate: On"
		setButtonThemeRole(ui.autoRotateButton, "active")
	else
		ui.autoRotateButton.Text = "Auto Rotate: Off"
		setButtonThemeRole(ui.autoRotateButton, "muted")
	end
end

function setPreviewAutoRotate(enabled)
	previewState.autoRotateEnabled = enabled == true
	syncAutoRotateButton()
end

function beginPreviewDrag(input)
	if not previewState.activeModel or previewState.busy then
		return
	end
	previewState.dragging = true
	previewState.dragInput = input
	previewState.dragLastPosition = input.Position
	setPreviewAutoRotate(false)
end

function endPreviewDrag(input)
	if input and previewState.dragInput and input ~= previewState.dragInput then
		return
	end
	previewState.dragging = false
	previewState.dragInput = nil
	previewState.dragLastPosition = nil
end

function setPreviewCameraPreset(name)
	if not previewState.activeModel then
		return
	end
	if name == "Front" then
		previewState.orbitYaw = math.rad(90)
		previewState.orbitPitch = 0
	elseif name == "Side" then
		previewState.orbitYaw = 0
		previewState.orbitPitch = 0
	elseif name == "Top" then
		previewState.orbitYaw = math.rad(90)
		previewState.orbitPitch = math.rad(80)
	else
		previewState.orbitYaw = math.rad(45)
		previewState.orbitPitch = math.rad(20)
	end
	applyPreviewCamera()
end

function cyclePreviewLightingPreset()
	local order = {"Studio", "Neutral", "Dramatic", "Outdoor"}
	for index, name in ipairs(order) do
		if name == previewState.lightingPresetName then
			previewState.lightingPresetName = order[(index % #order) + 1]
			break
		end
	end
	syncPreviewViewportLighting()
end

function cyclePreviewBackgroundPreset()
	local order = {"Cool", "Charcoal", "Light", "Sand"}
	for index, name in ipairs(order) do
		if name == previewState.backgroundPresetName then
			previewState.backgroundPresetName = order[(index % #order) + 1]
			break
		end
	end
	syncPreviewViewportBackground()
end

function cyclePreviewRotateSpeed()
	local order = {"Slow", "Normal", "Fast"}
	for index, name in ipairs(order) do
		if name == previewState.rotateSpeedMode then
			previewState.rotateSpeedMode = order[(index % #order) + 1]
			break
		end
	end
	syncPreviewRotateSpeed()
end

function setPreviewBusy(nextBusy)
	previewState.busy = nextBusy
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
	for _, button in ipairs(previewState.displayButtons) do
		button.AutoButtonColor = not nextBusy
		button.Active = not nextBusy
	end
	syncPreviewActionButtons()
	if nextBusy then
		ui.previewInfoLabel.Text = "Generating preview..."
	else
		if previewState.activeSessionIndex > 0 and previewState.sessions[previewState.activeSessionIndex] then
			ui.previewInfoLabel.Text = previewState.sessions[previewState.activeSessionIndex].infoText or "Preview ready. Drag to orbit, use zoom, or enable auto-rotate."
		end
	end
end

function nudgePreviewCamera(yawDelta, pitchDelta)
	if not previewState.activeModel then
		return
	end
	previewState.orbitYaw += yawDelta
	previewState.orbitPitch = math.clamp(previewState.orbitPitch + pitchDelta, math.rad(-80), math.rad(80))
	applyPreviewCamera()
end

function zoomPreview(delta)
	if not previewState.activeModel then
		return
	end
	previewState.orbitRadius = math.clamp(previewState.orbitRadius + delta, previewState.orbitMinRadius, previewState.orbitMaxRadius)
	applyPreviewCamera()
end

function resetPreviewCamera()
	if not previewState.activeModel then
		return
	end
	focusPreviewCamera(previewState.activeModel)
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
	if not collisionPreviewEnabled or not previewState.activeModel then
		return
	end

	local previewProxy = createCollisionProxies(previewState.activeModel, true, lastRequestedColliderMode)
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

local function connectPreviewInputSurface(surface)
	surface.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			beginPreviewDrag(input)
		end
	end)

	surface.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			endPreviewDrag(input)
		end
	end)

	surface.InputChanged:Connect(function(input)
		if not previewState.activeModel then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			zoomPreview(-input.Position.Z * math.max(previewState.orbitRadius * 0.12, 1.25))
		end
	end)
end

connectPreviewInputSurface(ui.previewViewport)
connectPreviewInputSurface(ui.previewSelectedFrame)

UserInputService.InputChanged:Connect(function(input)
	if not previewState.dragging or not previewState.activeModel then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	if not previewState.dragLastPosition then
		previewState.dragLastPosition = input.Position
		return
	end

	local delta = input.Position - previewState.dragLastPosition
	previewState.dragLastPosition = input.Position
	previewState.orbitYaw -= delta.X * 0.01
	previewState.orbitPitch = math.clamp(previewState.orbitPitch - delta.Y * 0.008, math.rad(-80), math.rad(80))
	applyPreviewCamera()
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		endPreviewDrag(input)
	end
end)

RunService.Heartbeat:Connect(function(deltaTime)
	refreshGenerationActivityUi()
	if not previewState.autoRotateEnabled or previewState.busy or not previewState.activeModel or not previewWidget.Enabled then
		return
	end
	previewState.orbitYaw += previewState.autoRotateSpeed * deltaTime
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

local MAX_GENERATION_PROMPT_LENGTH = 900

function compactPromptText(text, maxLength)
	local cleaned = tostring(text or ""):gsub("[%c\r\n]+", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if maxLength and maxLength > 0 and #cleaned > maxLength then
		cleaned = cleaned:sub(1, math.max(1, maxLength - 3)):gsub("%s+$", "") .. "..."
	end
	return cleaned
end

function buildCompactScenePrompt(sceneBrief, requiredElements, roleLabel, extraNotes)
	local lines = {
		"scene-build",
		"scene:" .. compactPromptText(sceneBrief, 240),
		"arrangement: compose the scene from separate placed assets that stay visually distinct; do not fuse everything into one object, one texture, or one continuous mass",
	}
	if requiredElements and requiredElements ~= "" then
		lines[#lines + 1] = "needs:" .. compactPromptText(requiredElements, 220)
	end
	if roleLabel and roleLabel ~= "" then
		lines[#lines + 1] = "focus:" .. compactPromptText(roleLabel, 80)
	end
	if extraNotes and extraNotes ~= "" then
		lines[#lines + 1] = compactPromptText(extraNotes, 220)
	end
	return table.concat(lines, "\n")
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

function normalizeAudioVolumeMode(value)
	local mode = tostring(value or "Medium")
	if mode == "Off" or mode == "Low" or mode == "Medium" or mode == "High" then
		return mode
	end
	return "Medium"
end

function getAudioVolumeMultiplier(enabled, level)
	if enabled == false then
		return 0
	end
	level = clampUnitNumber(level, 0.72)
	if level <= 0.35 then
		return (level / 0.35) * 0.45
	elseif level <= 0.72 then
		local alpha = (level - 0.35) / 0.37
		return 0.45 + (0.55 * alpha)
	end
	local alpha = (level - 0.72) / 0.28
	return 1 + (0.35 * alpha)
end

function getCompletionAudioVolumeMultiplier()
	if not variationCompletionAudioEnabled then
		return 0
	end

	local derivedLevel = math.max(
		clampUnitNumber(uiAudioVolumeLevel, 0.72),
		clampUnitNumber(themeChangeAudioVolumeLevel, 0.72) * 0.92,
		0.62
	)
	return getAudioVolumeMultiplier(true, derivedLevel)
end

function buildExperimentalPrompt(prompt)
	local finalPrompt = tostring(prompt or "")
	local negativePrompt = ui.experimentalNegativePromptBox and tostring(ui.experimentalNegativePromptBox.Text or "") or ""
	local scenePrompt = ui.scenePromptBox and tostring(ui.scenePromptBox.Text or "") or ""
	local sceneModeActive = sceneModeLocksPromptModifiers()
	negativePrompt = compactPromptText(negativePrompt, 180)
	scenePrompt = compactPromptText(scenePrompt, 240)

	if experimentalScenePromptEnabled and scenePrompt ~= "" then
		local requiredElements = compactPromptText(finalPrompt, 220)
		finalPrompt = buildCompactScenePrompt(scenePrompt, requiredElements, nil, "Place the separate assets naturally across the scene as if arranged deliberately in the world; do not merge them into one combined object.")
	end

	experimentalStyleBias = normalizeExperimentalStyleBias(experimentalStyleBias)
	if not sceneModeActive and experimentalStyleBias ~= "Off" then
		finalPrompt = ("%s\nstyle-bias:%s"):format(finalPrompt, string.lower(experimentalStyleBias))
	end
	if not sceneModeActive and negativePrompt ~= "" then
		finalPrompt = ("%s\navoid:%s"):format(finalPrompt, negativePrompt)
	end

	return finalPrompt, negativePrompt, scenePrompt
end

function splitSceneAssetHints(mainPrompt, scenePrompt)
	local hints = {}
	local seen = {}
	local combined = ("%s\n%s"):format(tostring(mainPrompt or ""), tostring(scenePrompt or ""))
	combined = combined:gsub("[%c\r\n]+", "\n")

	local function pushHint(text)
		local cleaned = compactPromptText(text, 72)
		cleaned = cleaned:gsub("^and%s+", ""):gsub("^with%s+", ""):gsub("^a%s+", ""):gsub("^an%s+", "")
		if cleaned == "" or #cleaned < 3 then
			return
		end
		local key = string.lower(cleaned)
		if seen[key] then
			return
		end
		seen[key] = true
		hints[#hints + 1] = cleaned
	end

	for rawPart in combined:gmatch("[^\n,;]+") do
		local part = compactPromptText(rawPart, 80)
		local lowered = string.lower(part)
		local splitPatterns = {
			" surrounded by ",
			" next to ",
			" beside ",
			" near ",
			" overlooking ",
			" leading to ",
			" path to ",
			" bridge to ",
			" featuring ",
			" with ",
			" and ",
		}
		local splitApplied = false
		for _, pattern in ipairs(splitPatterns) do
			if string.find(lowered, pattern, 1, true) then
				local startIndex = 1
				while true do
					local foundStart, foundEnd = string.find(lowered, pattern, startIndex, true)
					if not foundStart then
						pushHint(string.sub(part, startIndex))
						break
					end
					pushHint(string.sub(part, startIndex, foundStart - 1))
					startIndex = foundEnd + 1
				end
				splitApplied = true
				break
			end
		end
		if not splitApplied then
			pushHint(part)
		end
	end

	return hints
end

function getScenePlanningHash(text)
	local hash = 2166136261
	for index = 1, #text do
		hash = bit32.bxor(hash, string.byte(text, index))
		hash = (hash * 16777619) % 2147483647
	end
	return hash
end

function getSceneRoleSizeMultiplier(role)
	if role == "landmark" then
		return 0.92
	end
	if role == "terrain" or role == "shoreline" then
		return 0.82
	end
	if role == "support" then
		return 0.68
	end
	if role == "connector" then
		return 0.56
	end
	return 0.42
end

function inferSceneAssetRole(label, scenePrompt)
	local lowered = string.lower(("%s %s"):format(tostring(label or ""), tostring(scenePrompt or "")))
	if string.find(lowered, "shore", 1, true) or string.find(lowered, "coast", 1, true) or string.find(lowered, "water edge", 1, true) or string.find(lowered, "dock", 1, true) then
		return "shoreline", "edge"
	end
	if string.find(lowered, "path", 1, true) or string.find(lowered, "bridge", 1, true) or string.find(lowered, "road", 1, true) or string.find(lowered, "stairs", 1, true) or string.find(lowered, "gate", 1, true) then
		return "connector", "mid"
	end
	if string.find(lowered, "ground", 1, true) or string.find(lowered, "floor", 1, true) or string.find(lowered, "terrain", 1, true) or string.find(lowered, "cliff", 1, true) or string.find(lowered, "courtyard", 1, true) or string.find(lowered, "sand", 1, true) then
		return "terrain", "base"
	end
	if string.find(lowered, "keep", 1, true) or string.find(lowered, "castle", 1, true) or string.find(lowered, "tower", 1, true) or string.find(lowered, "house", 1, true) or string.find(lowered, "temple", 1, true) or string.find(lowered, "landmark", 1, true) then
		return "landmark", "center"
	end
	if string.find(lowered, "tree", 1, true) or string.find(lowered, "boat", 1, true) or string.find(lowered, "wall", 1, true) or string.find(lowered, "pillar", 1, true) or string.find(lowered, "building", 1, true) or string.find(lowered, "furniture", 1, true) then
		return "support", "mid"
	end
	return "scatter", "outer"
end

function addScenePlanEntry(plan, planIndex, label, count, purpose, role, band)
	local cleanedLabel = compactPromptText(label, 64)
	if cleanedLabel == "" then
		return
	end
	local key = string.lower(cleanedLabel)
	local existingIndex = planIndex[key]
	if existingIndex then
		plan[existingIndex].count += math.max(1, math.floor(tonumber(count) or 1))
		return
	end
	local resolvedRole, resolvedBand = inferSceneAssetRole(cleanedLabel, "")
	planIndex[key] = #plan + 1
	plan[#plan + 1] = {
		label = cleanedLabel,
		count = math.max(1, math.floor(tonumber(count) or 1)),
		purpose = purpose or "scene asset",
		role = role or resolvedRole,
		band = band or resolvedBand,
		sizeMultiplier = getSceneRoleSizeMultiplier(role or resolvedRole),
	}
end

function addAtomicSceneEntries(plan, planIndex, specs)
	for _, spec in ipairs(specs or {}) do
		addScenePlanEntry(
			plan,
			planIndex,
			spec.label,
			spec.count or 1,
			spec.purpose or "scene asset",
			spec.role,
			spec.band
		)
	end
end

function expandSceneLabelToAtomicAssets(label, scenePrompt)
	local cleanedLabel = compactPromptText(label, 64)
	local lowered = string.lower(("%s %s"):format(cleanedLabel, tostring(scenePrompt or "")))

	local function entries(...)
		return {...}
	end

	if string.find(lowered, "western town", 1, true) or string.find(lowered, "western", 1, true) then
		return entries(
			{label = "false front facade", count = 1, purpose = "storefront frontage", role = "landmark", band = "center"},
			{label = "timber wall section", count = 2, purpose = "building wall module", role = "support", band = "mid"},
			{label = "porch section", count = 1, purpose = "front porch module", role = "connector", band = "mid"},
			{label = "roof segment", count = 2, purpose = "roof module", role = "support", band = "mid"},
			{label = "boardwalk segment", count = 1, purpose = "street edge module", role = "connector", band = "mid"},
			{label = "fence section", count = 2, purpose = "perimeter module", role = "scatter", band = "outer"},
			{label = "barrel or crate prop", count = 2, purpose = "street prop", role = "scatter", band = "outer"}
		)
	end
	if string.find(lowered, "house", 1, true) or string.find(lowered, "building", 1, true) or string.find(lowered, "facade", 1, true) then
		return entries(
			{label = "wall section", count = 2, purpose = "structural wall module", role = "support", band = "mid"},
			{label = "corner post", count = 2, purpose = "structural support module", role = "support", band = "mid"},
			{label = "roof segment", count = 2, purpose = "roof module", role = "support", band = "mid"},
			{label = "door frame", count = 1, purpose = "entry module", role = "connector", band = "mid"},
			{label = "window frame", count = 2, purpose = "opening module", role = "scatter", band = "outer"}
		)
	end
	if string.find(lowered, "castle", 1, true) or string.find(lowered, "fortress", 1, true) or string.find(lowered, "keep", 1, true) then
		return entries(
			{label = "stone wall segment", count = 2, purpose = "fortified wall module", role = "support", band = "mid"},
			{label = "tower module", count = 1, purpose = "vertical defense module", role = "landmark", band = "center"},
			{label = "gate section", count = 1, purpose = "entry defense module", role = "connector", band = "mid"},
			{label = "roof cap", count = 1, purpose = "roof module", role = "support", band = "mid"},
			{label = "stone stair", count = 1, purpose = "circulation module", role = "connector", band = "mid"}
		)
	end
	if string.find(lowered, "dock", 1, true) or string.find(lowered, "harbor", 1, true) or string.find(lowered, "port", 1, true) then
		return entries(
			{label = "dock deck section", count = 2, purpose = "dock platform module", role = "shoreline", band = "edge"},
			{label = "dock support post", count = 2, purpose = "dock structural module", role = "support", band = "edge"},
			{label = "boat hull", count = 1, purpose = "harbor vessel", role = "support", band = "mid"},
			{label = "crate stack", count = 2, purpose = "cargo prop", role = "scatter", band = "outer"},
			{label = "rope or bollard prop", count = 1, purpose = "dock detail", role = "scatter", band = "outer"}
		)
	end
	if string.find(lowered, "fence", 1, true) then
		return entries(
			{label = "fence section", count = 1, purpose = "repeatable fence module", role = "scatter", band = "outer"},
			{label = "fence post", count = 1, purpose = "fence support module", role = "scatter", band = "outer"}
		)
	end
	if string.find(lowered, "roof", 1, true) then
		return entries(
			{label = "roof segment", count = 1, purpose = "repeatable roof module", role = "support", band = "mid"},
			{label = "roof trim", count = 1, purpose = "roof edge module", role = "scatter", band = "outer"}
		)
	end
	if string.find(lowered, "wall", 1, true) then
		return entries(
			{label = "wall section", count = 1, purpose = "repeatable wall module", role = "support", band = "mid"},
			{label = "corner support", count = 1, purpose = "wall support module", role = "support", band = "mid"}
		)
	end
	if string.find(lowered, "road", 1, true) or string.find(lowered, "street", 1, true) or string.find(lowered, "path", 1, true) or string.find(lowered, "boardwalk", 1, true) then
		return entries(
			{label = cleanedLabel, count = 1, purpose = "ground route module", role = "connector", band = "mid"}
		)
	end
	if string.find(lowered, "ground", 1, true) or string.find(lowered, "terrain", 1, true) or string.find(lowered, "shoreline", 1, true) or string.find(lowered, "sand", 1, true) then
		return entries(
			{label = cleanedLabel, count = 1, purpose = "ground terrain module", role = "terrain", band = "base"}
		)
	end
	return entries(
		{label = cleanedLabel, count = 1, purpose = "single modular scene asset", role = select(1, inferSceneAssetRole(cleanedLabel, scenePrompt)), band = select(2, inferSceneAssetRole(cleanedLabel, scenePrompt))}
	)
end

function inferSceneAssetPlan(mainPrompt, scenePrompt)
	local mainText = compactPromptText(mainPrompt, 220)
	local sceneText = compactPromptText(scenePrompt, 240)
	local combined = string.lower(("%s %s"):format(mainText, sceneText))
	local hash = getScenePlanningHash(combined)
	local plan = {}
	local planIndex = {}

	local function has(...)
		for _, token in ipairs({...}) do
			if string.find(combined, token, 1, true) then
				return true
			end
		end
		return false
	end

	local function add(label, count, purpose, role, band)
		addScenePlanEntry(plan, planIndex, label, count, purpose, role, band)
	end
	local function addExpanded(label)
		addAtomicSceneEntries(plan, planIndex, expandSceneLabelToAtomicAssets(label, scenePrompt))
	end

	if has("castle", "fortress", "keep", "medieval") then
		addExpanded("castle keep")
		addExpanded("outer walls")
		add("courtyard ground", 1, "ground base", "terrain", "base")
		add("stone path", 1, "approach route", "connector", "mid")
	end
	if has("harbor", "dock", "port") then
		addExpanded("dock platforms")
		addExpanded("small boats")
		addExpanded("crate stacks")
	end
	if has("beach", "shore", "coast", "coastal") then
		add("shoreline terrain", 1, "edge terrain", "shoreline", "edge")
		add("sand ground", 1, "terrain base", "terrain", "base")
		add("coastal rocks", 2 + (hash % 2), "shore breakup", "scatter", "outer")
	end
	if has("forest", "woods", "grove", "jungle") then
		addExpanded("tree cluster")
		add("forest ground", 1, "terrain base", "terrain", "base")
		add("rocks and shrubs", 2, "ground breakup", "scatter", "outer")
	end
	if has("village", "town", "settlement") then
		addExpanded(mainText ~= "" and mainText or "town")
		add("main street", 1, "circulation route", "connector", "mid")
		add("market props", 2, "street detail", "scatter", "outer")
	end
	if has("ruin", "ruins", "temple") then
		addExpanded("ruined structure")
		add("broken pillars", 2, "architectural support", "support", "mid")
		add("masonry debris", 2, "scatter detail", "scatter", "outer")
	end
	if has("interior", "room", "hall") then
		add("room shell", 1, "interior envelope", "terrain", "base")
		add("major furniture", 2, "functional assets", "support", "mid")
		add("small decor", 2, "secondary props", "scatter", "outer")
	end
	if has("street", "city", "urban") then
		add("building frontage", 2, "urban walls", "support", "mid")
		add("street surface", 1, "ground plane", "terrain", "base")
		add("street clutter", 2, "secondary props", "scatter", "outer")
	end

	for _, hint in ipairs(splitSceneAssetHints(mainPrompt, scenePrompt)) do
		if #plan >= 8 then
			break
		end
		addAtomicSceneEntries(plan, planIndex, expandSceneLabelToAtomicAssets(hint, scenePrompt))
	end

	local hasLandmark = false
	local hasTerrain = false
	for _, item in ipairs(plan) do
		hasLandmark = hasLandmark or item.role == "landmark"
		hasTerrain = hasTerrain or item.role == "terrain" or item.role == "shoreline"
	end
	if not hasTerrain then
		add("scene ground", 1, "base terrain", "terrain", "base")
	end
	if not hasLandmark and #plan > 0 then
		add(mainText ~= "" and mainText or "main scene feature", 1, "main focal asset", "landmark", "center")
	end
	if #plan == 0 then
		add("scene ground", 1, "base terrain", "terrain", "base")
		add("main scene feature", 1, "focal element", "landmark", "center")
		add("supporting props", 2, "support detail", "scatter", "outer")
	end

	return plan
end

function getSceneRolePromptSpec(role, label, sceneBrief)
	local architectureAvoid = "avoid: full merged diorama, fused scene block, duplicate hero landmark, single combined object"
	if role == "landmark" then
		return {
			note = "Create one major placeable landmark asset only. It should stand on its own as a single object placed into the scene.",
			avoid = "avoid: full scene, surrounding terrain, duplicate landmarks, merged environment block",
		}
	end
	if role == "terrain" or role == "shoreline" then
		return {
			note = "Create one placeable terrain-style asset only, such as ground, shoreline, cliff, floor, or waterfront mass.",
			avoid = "avoid: full scene, buildings plus props all fused together, duplicate landmarks",
		}
	end
	if role == "connector" then
		return {
			note = "Create one placeable connector asset only, such as a path, bridge, stair, road, or gateway approach.",
			avoid = architectureAvoid,
		}
	end
	if role == "support" then
		return {
			note = "Create one medium-size supporting placeable asset that complements the scene without becoming the whole environment.",
			avoid = architectureAvoid,
		}
	end
	return {
		note = "Create one small-to-medium placeable prop or breakup asset only.",
		avoid = architectureAvoid,
	}
end

function buildSceneAssetPrompt(sceneBrief, requiredElements, assetHint, roleSpec, entry)
	local target = compactPromptText(assetHint, 64)
	local theme = compactPromptText(sceneBrief, 90)
	local context = compactPromptText(requiredElements, 90)
	local prompt = target
	if theme ~= "" then
		prompt = ("%s, %s style"):format(prompt, theme)
	end
	if context ~= "" then
		prompt = ("%s, matching %s"):format(prompt, context)
	end
	prompt = ("%s, modular reusable game asset, single object only, no full scene, no full building, isolated clean shape"):format(prompt)
	return prompt
end

function buildSceneAssetRequests(baseRequest)
	local requiredElements = compactPromptText(baseRequest.prompt, 180)
	local sceneBrief = compactPromptText(baseRequest.scenePrompt, 220)
	local assetPlan = inferSceneAssetPlan(baseRequest.prompt, sceneBrief)
	local maxRequests = 12
	local totalWeight = 0
	for _, item in ipairs(assetPlan) do
		totalWeight += (item.sizeMultiplier or 0.5) * math.max(1, item.count or 1)
	end
	totalWeight = math.max(totalWeight, 1)

	local sceneTargetSize = math.max(16, tonumber(baseRequest.targetSize) or 24)
	local triangleBudget = tonumber((baseRequest.inputs and baseRequest.inputs.MaxTriangles) or baseRequest.maxTriangles) or 0
	local requests = {}
	local assetIndex = 0

	for _, entry in ipairs(assetPlan) do
		for itemIndex = 1, math.max(1, entry.count or 1) do
			if #requests >= maxRequests then
				break
			end
			assetIndex += 1
			local assetHint = (entry.count or 1) > 1 and ("%s %d"):format(entry.label, itemIndex) or entry.label
			local roleSpec = getSceneRolePromptSpec(entry.role, assetHint, sceneBrief)
			local assetTargetSize = math.max(8, math.floor(sceneTargetSize * (entry.sizeMultiplier or 0.5)))
			local weightedTriangles = math.floor(triangleBudget * ((entry.sizeMultiplier or 0.5) / totalWeight) * math.max(1, #assetPlan))
			local assetTriangles = math.max(400, math.min(baseRequest.maxTriangles, weightedTriangles))
			local assetPrompt = buildSceneAssetPrompt(sceneBrief, requiredElements, assetHint, roleSpec, entry)
			local effectivePrompt, normalizedSeed = buildSeededPrompt(assetPrompt, ("%s-scene-%d"):format(tostring(baseRequest.seed or ""), assetIndex))
			requests[#requests + 1] = {
				prompt = assetHint,
				targetSize = assetTargetSize,
				maxTriangles = assetTriangles,
				textures = baseRequest.textures,
				includeBase = false,
				anchored = baseRequest.anchored,
				schemaName = baseRequest.schemaName,
				seed = normalizedSeed,
				baseSeed = normalizedSeed,
				variationCount = 1,
				variationIndex = assetIndex,
				negativePrompt = baseRequest.negativePrompt,
				scenePrompt = sceneBrief,
				scenePromptEnabled = false,
				styleBias = baseRequest.styleBias,
				previewMode = baseRequest.previewMode,
				groundSnap = true,
				promptBeforeSeed = assetPrompt,
				effectivePrompt = effectivePrompt,
				colliderMode = baseRequest.colliderMode,
				inputs = {
					TextPrompt = effectivePrompt,
					Size = Vector3.new(assetTargetSize, assetTargetSize, assetTargetSize),
					MaxTriangles = assetTriangles,
					GenerateTextures = baseRequest.textures,
				},
				schema = {
					PredefinedSchema = baseRequest.schemaName,
				},
				sceneAssetIndex = assetIndex,
				sceneAssetCount = math.min(maxRequests, #assetPlan),
				sceneAssetHint = assetHint,
				sceneAssetRole = entry.role,
				sceneAssetBand = entry.band,
				sceneAssetSizeMultiplier = entry.sizeMultiplier or 0.5,
				sceneAssetSequence = itemIndex,
			}
		end
		if #requests >= maxRequests then
			break
		end
	end

	return requests
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

function saveInputs(prompt, targetSize, maxTriangles, textures, includeBase, anchored, schemaName, colliderMode, seed, variationCount)
	setSetting(SETTINGS.prompt, prompt)
	setSetting(SETTINGS.size, targetSize)
	setSetting(SETTINGS.maxTriangles, maxTriangles)
	setSetting(SETTINGS.textures, textures)
	setSetting(SETTINGS.includeBase, includeBase)
	setSetting(SETTINGS.anchored, anchored)
	setSetting(SETTINGS.schema, schemaName)
	setSetting(SETTINGS.colliderMode, colliderMode)
	setSetting(SETTINGS.seed, seed)
	setSetting(SETTINGS.variationCount, variationCount)
	if ui.scenePromptBox then
		setSetting(SETTINGS.experimentalScenePrompt, tostring(ui.scenePromptBox.Text or ""))
	end
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

	local prompt = experimentalScenePromptEnabled and "" or ui.promptBox.Text
	local targetSize = parseNumber(ui.sizeBox.Text, 24, 4, 512)
	local maxTriangles = parseNumber(ui.trianglesBox.Text, 20000, 500, 100000)
	local textures = generationTexturesEnabled
	local includeBase = generationIncludeBaseEnabled
	local anchored = generationAnchoredEnabled
	local schemaName = ui.schemaBox.Text ~= "" and ui.schemaBox.Text or "Body1"
	local seed = ui.seedBox.Text or ""
	local variationCount = parseNumber(ui.variationCountBox.Text, 1, 1, 12)
	local colliderMode = normalizeColliderMode(ui.colliderModeBox.Text)
	local baseAdjustedPrompt = applyBasePreferenceToPrompt(prompt, includeBase)
	local experimentalPrompt, negativePrompt, scenePrompt = buildExperimentalPrompt(baseAdjustedPrompt)
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
		baseSeed = normalizedSeed,
		variationCount = variationCount,
		negativePrompt = negativePrompt,
		scenePrompt = scenePrompt,
		scenePromptEnabled = experimentalScenePromptEnabled,
		styleBias = experimentalStyleBias,
		previewMode = experimentalPreviewMode,
		sceneLayoutMode = "generate",
		groundSnap = experimentalGroundSnap,
		promptBeforeSeed = experimentalPrompt,
		effectivePrompt = seededPrompt,
		colliderMode = colliderMode,
		inputs = inputs,
		schema = schema,
	}
end

function getVariationSeed(baseSeed, variationIndex)
	local cleanedSeed = tostring(baseSeed or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if cleanedSeed == "" then
		return generateRandomSeed()
	end
	if variationIndex <= 1 then
		return cleanedSeed
	end

	local numericSeed = tonumber(cleanedSeed)
	if numericSeed and numericSeed == math.floor(numericSeed) then
		return tostring(numericSeed + variationIndex - 1)
	end

	return ("%s-%d"):format(cleanedSeed, variationIndex)
end

function buildVariationRequests(baseRequest)
	local variationCount = math.max(1, math.floor(tonumber(baseRequest.variationCount) or 1))
	local requests = {}

	for variationIndex = 1, variationCount do
		local variationSeed = getVariationSeed(baseRequest.baseSeed, variationIndex)
		local effectivePrompt, normalizedSeed = buildSeededPrompt(baseRequest.promptBeforeSeed, variationSeed)
		requests[#requests + 1] = {
			prompt = baseRequest.prompt,
			targetSize = baseRequest.targetSize,
			maxTriangles = baseRequest.maxTriangles,
			textures = baseRequest.textures,
			includeBase = baseRequest.includeBase,
			anchored = baseRequest.anchored,
			schemaName = baseRequest.schemaName,
			seed = normalizedSeed,
			baseSeed = baseRequest.baseSeed,
			variationCount = variationCount,
			variationIndex = variationIndex,
			negativePrompt = baseRequest.negativePrompt,
			scenePrompt = baseRequest.scenePrompt,
			scenePromptEnabled = baseRequest.scenePromptEnabled,
			styleBias = baseRequest.styleBias,
			previewMode = baseRequest.previewMode,
			sceneLayoutMode = baseRequest.sceneLayoutMode,
			groundSnap = baseRequest.groundSnap,
			promptBeforeSeed = baseRequest.promptBeforeSeed,
			effectivePrompt = effectivePrompt,
			colliderMode = baseRequest.colliderMode,
			inputs = {
				TextPrompt = effectivePrompt,
				Size = baseRequest.inputs.Size,
				MaxTriangles = baseRequest.inputs.MaxTriangles,
				GenerateTextures = baseRequest.inputs.GenerateTextures,
			},
			schema = {
				PredefinedSchema = baseRequest.schema.PredefinedSchema,
			},
		}
	end

	return requests
end

function buildRequestInputsAndSchema(request)
	local promptBeforeSeed = request.promptBeforeSeed
	if not promptBeforeSeed or promptBeforeSeed == "" then
		local requiredElements = applyBasePreferenceToPrompt(request.prompt, request.includeBase)
		local cleanedScenePrompt = compactPromptText(request.scenePrompt, 240)
		if request.scenePromptEnabled and cleanedScenePrompt ~= "" then
			promptBeforeSeed = buildCompactScenePrompt(
				cleanedScenePrompt,
				compactPromptText(requiredElements, 220),
				nil,
				"Place the separate assets naturally across the scene as if arranged deliberately in the world; do not merge them into one combined object."
			)
		else
			promptBeforeSeed = requiredElements
		end
	end

	local effectivePrompt, normalizedSeed = buildSeededPrompt(promptBeforeSeed, request.seed)
	request.seed = normalizedSeed
	request.baseSeed = request.baseSeed or normalizedSeed
	request.promptBeforeSeed = promptBeforeSeed
	request.effectivePrompt = effectivePrompt
	request.variationCount = math.max(1, math.floor(tonumber(request.variationCount) or 1))
	request.inputs = {
		TextPrompt = effectivePrompt,
		Size = Vector3.new(request.targetSize, request.targetSize, request.targetSize),
		MaxTriangles = request.maxTriangles,
		GenerateTextures = request.textures,
	}
	request.schema = {
		PredefinedSchema = request.schemaName,
	}
	return request
end

function getVariationModelName(prompt, seed, variationIndex, variationCount)
	local baseName = getPromptName(prompt)
	local pattern = tostring(generationNamePattern or "Prompt")
	local parts = {baseName}
	local cleanedSeed = tostring(seed or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local hasMultiple = variationCount and variationCount > 1

	if pattern == "Prompt + Seed" or pattern == "Prompt + Seed + Index" then
		parts[#parts + 1] = cleanedSeed ~= "" and ("S%s"):format(cleanedSeed) or "Random"
	end
	if pattern == "Prompt + Index" or pattern == "Prompt + Seed + Index" or hasMultiple then
		parts[#parts + 1] = ("V%02d"):format(variationIndex or 1)
	end

	local name = table.concat(parts, "_")
	if #name > 72 then
		name = name:sub(1, 72)
	end
	return name
end

function getInstanceBounds(instance)
	if instance:IsA("Model") then
		return instance:GetBoundingBox()
	elseif instance:IsA("BasePart") then
		return instance.CFrame, instance.Size
	end
	return CFrame.new(), Vector3.new(4, 4, 4)
end

function translateInstance(instance, translation)
	if instance:IsA("Model") then
		instance:PivotTo(instance:GetPivot() + translation)
	elseif instance:IsA("BasePart") then
		instance.CFrame += translation
	end
end

function layoutGeneratedBatch(folder)
	if not folder or generationBatchLayout == "Folder Only" then
		return
	end

	local generated = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") or child:IsA("BasePart") then
			generated[#generated + 1] = child
		end
	end
	if #generated <= 1 then
		return
	end

	table.sort(generated, function(left, right)
		return left.Name < right.Name
	end)

	local spacing = 6
	if generationBatchLayout == "Row" then
		local cursorX = 0
		for _, child in ipairs(generated) do
			local boundsCFrame, boundsSize = getInstanceBounds(child)
			local halfWidth = boundsSize.X * 0.5
			local targetX = cursorX + halfWidth
			local targetY = math.max(boundsSize.Y * 0.5, 0)
			local translation = Vector3.new(targetX, targetY, 0) - boundsCFrame.Position
			translateInstance(child, translation)
			cursorX = targetX + halfWidth + spacing
		end
		return
	end

	local columns = math.max(2, math.ceil(math.sqrt(#generated)))
	local cellWidth = 0
	local cellDepth = 0
	for _, child in ipairs(generated) do
		local _, boundsSize = getInstanceBounds(child)
		cellWidth = math.max(cellWidth, boundsSize.X)
		cellDepth = math.max(cellDepth, boundsSize.Z)
	end
	cellWidth += spacing
	cellDepth += spacing

	for index, child in ipairs(generated) do
		local row = math.floor((index - 1) / columns)
		local column = (index - 1) % columns
		local boundsCFrame, boundsSize = getInstanceBounds(child)
		local target = Vector3.new(
			column * cellWidth,
			math.max(boundsSize.Y * 0.5, 0),
			row * cellDepth
		)
		translateInstance(child, target - boundsCFrame.Position)
	end
end

function layoutSceneComposite(container)
	if not container then
		return
	end

	local assets = {}
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Model") or child:IsA("BasePart") then
			assets[#assets + 1] = child
		end
	end
	if #assets <= 1 then
		return
	end

	table.sort(assets, function(left, right)
		local leftIndex = tonumber(left:GetAttribute("DetailedModelSceneAssetIndex") or 0) or 0
		local rightIndex = tonumber(right:GetAttribute("DetailedModelSceneAssetIndex") or 0) or 0
		if leftIndex == rightIndex then
			return left.Name < right.Name
		end
		return leftIndex < rightIndex
	end)

	local desiredSceneSpan = math.max(18, tonumber(container:GetAttribute("DetailedModelTargetSize")) or 24)
	local sceneLayoutMode = tostring(container:GetAttribute("DetailedModelSceneLayoutMode") or "generate")
	local maxWidth = 0
	local maxDepth = 0
	local bands = {
		base = {},
		center = {},
		mid = {},
		edge = {},
		outer = {},
	}

	for _, asset in ipairs(assets) do
		local band = tostring(asset:GetAttribute("DetailedModelSceneAssetBand") or "mid")
		if not bands[band] then
			band = "mid"
		end
		bands[band][#bands[band] + 1] = asset
		local _, boundsSize = getInstanceBounds(asset)
		maxWidth = math.max(maxWidth, boundsSize.X)
		maxDepth = math.max(maxDepth, boundsSize.Z)
	end

	local spreadScale = sceneLayoutMode == "preview" and 1 or 0.58
	local horizontalUnit = math.max(desiredSceneSpan * 0.3 * spreadScale, maxWidth * (sceneLayoutMode == "preview" and 1.1 or 0.7), 5)
	local depthUnit = math.max(desiredSceneSpan * 0.24 * spreadScale, maxDepth * (sceneLayoutMode == "preview" and 1.05 or 0.68), 4)

	local function placeBand(list, baseDepth, widthScale, alternateSides)
		for index, asset in ipairs(list) do
			local boundsCFrame, boundsSize = getInstanceBounds(asset)
			local side = alternateSides and ((index % 2 == 0) and 1 or -1) or 0
			local lane = alternateSides and math.floor((index - 1) / 2) or (index - 1)
			local x
			if alternateSides then
				x = side * horizontalUnit * (0.65 + lane * widthScale)
			else
				local centeredIndex = index - ((#list + 1) / 2)
				x = centeredIndex * horizontalUnit * widthScale
			end
			local z = baseDepth + lane * depthUnit * 0.7
			local target = Vector3.new(x, math.max(boundsSize.Y * 0.5, 0), z)
			translateInstance(asset, target - boundsCFrame.Position)
		end
	end

	placeBand(bands.base, depthUnit * 1.6, 0.95, false)
	placeBand(bands.center, 0, 1.15, false)
	placeBand(bands.mid, depthUnit * 0.85, 1.1, false)
	placeBand(bands.edge, depthUnit * 2.2, 1.2, false)
	placeBand(bands.outer, depthUnit * 1.1, 0.9, true)
end

function stripScenePreviewCollisionContainers(instance)
	if not instance then
		return
	end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("Folder") and string.find(descendant.Name, "_Collision", 1, true) then
			descendant:Destroy()
		end
	end
end

function finalizeSceneComposite(sceneContainer, parentTarget, request)
	sceneContainer.Name = getVariationModelName(
		tostring(request.scenePrompt or request.prompt or "Scene"),
		request.seed,
		request.variationIndex or 1,
		request.variationCount or 1
	)
	sceneContainer.Parent = parentTarget
	sceneContainer:SetAttribute("DetailedModelPrompt", request.prompt)
	sceneContainer:SetAttribute("DetailedModelTargetSize", request.targetSize)
	sceneContainer:SetAttribute("DetailedModelMaxTriangles", request.maxTriangles)
	sceneContainer:SetAttribute("DetailedModelGenerateTextures", request.textures)
	sceneContainer:SetAttribute("DetailedModelIncludeBase", request.includeBase)
	sceneContainer:SetAttribute("DetailedModelAnchored", request.anchored)
	sceneContainer:SetAttribute("DetailedModelSchema", request.schemaName)
	sceneContainer:SetAttribute("DetailedModelSeed", request.seed)
	sceneContainer:SetAttribute("DetailedModelColliderMode", request.colliderMode)
	sceneContainer:SetAttribute("DetailedModelScenePrompt", tostring(request.scenePrompt or ""))
	sceneContainer:SetAttribute("DetailedModelScenePromptEnabled", true)
	sceneContainer:SetAttribute("DetailedModelSceneLayoutMode", tostring(request.sceneLayoutMode or "generate"))
	sceneContainer:SetAttribute("DetailedModelVariationIndex", request.variationIndex or 1)
	sceneContainer:SetAttribute("DetailedModelVariationCount", request.variationCount or 1)
	layoutSceneComposite(sceneContainer)
	if request.groundSnap then
		pcall(function()
			applyGroundSnapAtOrigin(sceneContainer)
		end)
	end
end

function findVariationBatchFolder(instances)
	local folder
	for _, instance in ipairs(instances) do
		local candidate = instance and instance.Parent
		if not candidate or not candidate:IsA("Folder") or not string.find(candidate.Name, "_Variations", 1, true) then
			return nil
		end
		if folder and folder ~= candidate then
			return nil
		end
		folder = candidate
	end
	return folder
end

function finalizeGeneratedModel(generatedModel, parentTarget, request)
	generatedModel.Name = getVariationModelName(request.prompt, request.seed, request.variationIndex or 1, request.variationCount or 1)
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
	generatedModel:SetAttribute("DetailedModelScenePrompt", tostring(request.scenePrompt or ""))
	generatedModel:SetAttribute("DetailedModelScenePromptEnabled", request.scenePromptEnabled == true)
	generatedModel:SetAttribute("DetailedModelScale", getInstanceScale(generatedModel))
	generatedModel:SetAttribute("DetailedModelVariationIndex", request.variationIndex or 1)
	generatedModel:SetAttribute("DetailedModelVariationCount", request.variationCount or 1)
	applyAnchoredState(generatedModel, request.anchored)
	clearGeneratedTextureReferences(generatedModel)
	storeCachedVisualModel(request, generatedModel)
	captureCollisionData(generatedModel, request.colliderMode)
	attachGeneratedCollisionModel(parentTarget, generatedModel, request)

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
end

function generateSingleDetailedModel(request, parentTarget)
	if request.scenePromptEnabled and tostring(request.scenePrompt or ""):gsub("%s+", "") ~= "" then
		local sceneContainer = Instance.new("Model")
		local assetRequests = buildSceneAssetRequests(request)
		local generatedAny = false
		local usedCache = true
		local failedAssetCount = 0
		local firstFailureMessage = nil

		for _, assetRequest in ipairs(assetRequests) do
			local generatedModel = loadCachedVisualModel(assetRequest)
			local success = true
			if not generatedModel then
				usedCache = false
				success, generatedModel = pcall(function()
					return GenerationService:GenerateModelAsync(assetRequest.inputs, assetRequest.schema)
				end)
			end
			if not success then
				failedAssetCount += 1
				if not firstFailureMessage then
					firstFailureMessage = ("%s -> %s"):format(tostring(assetRequest.sceneAssetHint or assetRequest.prompt or "scene asset"), tostring(generatedModel))
				end
				continue
			end
			if typeof(generatedModel) ~= "Instance" then
				failedAssetCount += 1
				if not firstFailureMessage then
					firstFailureMessage = ("%s -> Scene generation returned no model instance."):format(tostring(assetRequest.sceneAssetHint or assetRequest.prompt or "scene asset"))
				end
				continue
			end

			finalizeGeneratedModel(generatedModel, sceneContainer, assetRequest)
			generatedModel:SetAttribute("DetailedModelSceneAssetIndex", assetRequest.sceneAssetIndex or 1)
			generatedModel:SetAttribute("DetailedModelSceneAssetCount", assetRequest.sceneAssetCount or #assetRequests)
			generatedModel:SetAttribute("DetailedModelSceneAssetHint", tostring(assetRequest.sceneAssetHint or ""))
			generatedModel:SetAttribute("DetailedModelSceneAssetRole", tostring(assetRequest.sceneAssetRole or "scatter"))
			generatedModel:SetAttribute("DetailedModelSceneAssetBand", tostring(assetRequest.sceneAssetBand or "mid"))
			generatedModel:SetAttribute("DetailedModelSceneAssetSizeMultiplier", tonumber(assetRequest.sceneAssetSizeMultiplier) or 0.5)
			generatedModel:SetAttribute("DetailedModelSceneAssetSequence", tonumber(assetRequest.sceneAssetSequence) or 1)
			generatedAny = true
		end

		if not generatedAny then
			sceneContainer:Destroy()
			return false, firstFailureMessage or "Scene generation produced no assets."
		end

		finalizeSceneComposite(sceneContainer, parentTarget, request)
		return true, {
			model = sceneContainer,
			usedCache = usedCache,
			partCount = #assetRequests,
			failedAssetCount = failedAssetCount,
			requestedAssetCount = #assetRequests,
			errorMessage = firstFailureMessage,
		}
	end

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
		return false, tostring(generatedModel)
	end
	if typeof(generatedModel) ~= "Instance" then
		return false, "Generation returned no model instance. Response: " .. tostring(generatedModel)
	end

	finalizeGeneratedModel(generatedModel, parentTarget, request)

	return true, {
		model = generatedModel,
		usedCache = usedCache,
		partCount = countParts(generatedModel),
		metadataOrError = metadataOrError,
	}
end

function renderRequestPreview(request)
	local lines = {
		"Preview",
	}
	local cleanedPrompt = tostring(request.prompt or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if cleanedPrompt ~= "" then
		lines[#lines + 1] = "Prompt: " .. cleanedPrompt
	elseif request.scenePromptEnabled and tostring(request.scenePrompt or ""):gsub("%s+", "") ~= "" then
		lines[#lines + 1] = "Prompt: scene-driven"
	end
	if request.scenePromptEnabled and tostring(request.scenePrompt or ""):gsub("%s+", "") ~= "" then
		lines[#lines + 1] = "Scene: " .. tostring(request.scenePrompt)
		local plannedAssets = 0
		for _, item in ipairs(inferSceneAssetPlan(request.prompt, request.scenePrompt)) do
			plannedAssets += item.count
		end
		lines[#lines + 1] = "Scene Assets Planned: " .. tostring(plannedAssets)
	end
	lines[#lines + 1] = "Size: " .. tostring(request.targetSize)
	lines[#lines + 1] = "MaxTriangles: " .. tostring(request.maxTriangles)
	lines[#lines + 1] = "GenerateTextures: " .. tostring(request.textures)
	lines[#lines + 1] = "IncludeBase: " .. tostring(request.includeBase)
	lines[#lines + 1] = "Anchored: " .. tostring(request.anchored)
	lines[#lines + 1] = "Schema: " .. request.schemaName
	lines[#lines + 1] = "Seed: " .. (request.seed ~= "" and request.seed or "random")
	lines[#lines + 1] = "Variations: " .. tostring(request.variationCount or 1)
	lines[#lines + 1] = "ColliderMode: " .. request.colliderMode
	setStatus(
		table.concat(lines, "\n"),
		"info"
	)
end

function validateRequest(request)
	local cleanedPrompt = tostring(request.prompt or ""):gsub("%s+", "")
	local cleanedScenePrompt = tostring(request.scenePrompt or ""):gsub("%s+", "")
	if cleanedPrompt == "" and not (request.scenePromptEnabled and cleanedScenePrompt ~= "") then
		return false, "Enter a prompt before generating."
	end
	local promptText = tostring((request.inputs and request.inputs.TextPrompt) or request.effectivePrompt or request.promptBeforeSeed or "")
	if #promptText > MAX_GENERATION_PROMPT_LENGTH then
		return false, ("Prompt is too long for Roblox generation (%d characters). Shorten the scene direction or the requested elements."):format(#promptText)
	end
	return true
end

function loadModelIntoPreview(model, colliderMode, statusMessage, request)
	replacePreviewSessions({
		{
			model = model,
			request = request,
			colliderMode = colliderMode,
			label = request and getVariationModelName(request.prompt, request.seed, request.variationIndex or 1, request.variationCount or 1) or "Preview",
			infoText = request and request.scenePromptEnabled and tostring(request.scenePrompt or ""):gsub("%s+", "") ~= ""
				and "Scene-directed preview ready. Drag to orbit, use zoom, or enable auto-rotate."
				or "Preview ready. Drag to orbit, use zoom, or enable auto-rotate.",
			generateText = "Generate This Variant",
		},
	}, 1, statusMessage)
end

function generateVisualPreview()
	if busy or previewState.busy then
		return
	end

	local variationCount = parseNumber(ui.variationCountBox.Text, 1, 1, 12)
	if variationCount > 1 then
		local randomSeed = generateRandomSeed()
		ui.seedBox.Text = randomSeed
		setSetting(SETTINGS.seed, randomSeed)
	end

	local request = buildRequest()
	local valid, message = validateRequest(request)
	if not valid then
		setStatus(message, "error")
		return
	end

	previewWidget.Enabled = true
	setPreviewBusy(true)
	local variationRequests = buildVariationRequests(request)
	local previewSessionsToLoad = {}
	local cacheHits = 0
	local failureCount = 0
	beginGenerationActivity(
		"Preview",
		#variationRequests,
		#variationRequests > 1 and ("Preparing %d preview variations"):format(#variationRequests) or "Preparing preview request",
		"Preview timing is estimated from completed variations."
	)

	for index, variationRequest in ipairs(variationRequests) do
		ui.previewInfoLabel.Text = #variationRequests > 1
			and ("Generating preview %d/%d..."):format(index, #variationRequests)
			or "Generating preview..."
		updateGenerationActivity(
			index,
			index - 1,
			#variationRequests > 1 and ("Preview variant %d (%s)"):format(index, variationRequest.seed ~= "" and variationRequest.seed or "random") or "Generating preview",
			"Preview requests use a lighter triangle budget for faster feedback.",
			cacheHits
		)

		variationRequest.inputs.MaxTriangles = getExperimentalPreviewTriangleBudget(variationRequest.maxTriangles)
		local sceneModeActive = variationRequest.scenePromptEnabled and tostring(variationRequest.scenePrompt or ""):gsub("%s+", "") ~= ""
		local cachedPreviewModel = nil
		local generatedModel = nil
		local sceneResult = nil

		if sceneModeActive then
			variationRequest.sceneLayoutMode = "preview"
			local previewBuildFolder = Instance.new("Folder")
			local success, generatedSuccess, resultOrError = pcall(function()
				return generateSingleDetailedModel(variationRequest, previewBuildFolder)
			end)
			sceneResult = success and generatedSuccess and resultOrError or nil
			if not generatedSuccess or not sceneResult or not sceneResult.model then
				local failureDetail = not success and tostring(generatedSuccess)
					or tostring(resultOrError or "Unknown scene preview failure.")
				previewBuildFolder:Destroy()
				failureCount += 1
				updateGenerationActivity(
					index,
					index,
					"Preview failed for this variation",
					("Continuing with the remaining preview requests. %s"):format(failureDetail),
					cacheHits
				)
				continue
			end
			generatedModel = sceneResult.model
			if sceneResult.usedCache then
				cacheHits += 1
				cachedPreviewModel = generatedModel
			end
			stripScenePreviewCollisionContainers(generatedModel)
			generatedModel.Parent = nil
			previewBuildFolder:Destroy()
		else
			cachedPreviewModel = loadCachedVisualModel(variationRequest)
			generatedModel = cachedPreviewModel

			if cachedPreviewModel then
				cacheHits += 1
			else
				local success, generatedOrError = pcall(function()
					return GenerationService:GenerateModelAsync(variationRequest.inputs, variationRequest.schema)
				end)
				if not success or typeof(generatedOrError) ~= "Instance" then
					failureCount += 1
					updateGenerationActivity(index, index, "Preview failed for this variation", "Continuing with the remaining preview requests.", cacheHits)
					continue
				end
				generatedModel = generatedOrError
				storeCachedVisualModel(variationRequest, generatedModel)
			end
		end
		updateGenerationActivity(
			index,
			index,
			#variationRequests > 1 and ("Preview ready for variant %d"):format(index) or "Preview ready",
			sceneResult and sceneResult.failedAssetCount and sceneResult.failedAssetCount > 0
				and ("Built the scene with %d/%d asset failures."):format(sceneResult.failedAssetCount, sceneResult.requestedAssetCount or sceneResult.failedAssetCount)
				or (cachedPreviewModel and "Loaded from cache." or "Fresh preview returned from Roblox."),
			cacheHits
		)
		playGenerationCompletionSound("variation_complete")

		previewSessionsToLoad[#previewSessionsToLoad + 1] = {
			model = generatedModel,
			request = variationRequest,
			colliderMode = variationRequest.colliderMode,
			label = #variationRequests > 1
				and ("Variant %d (%s)"):format(index, variationRequest.seed ~= "" and variationRequest.seed or "random")
				or "Preview",
			infoText = #variationRequests > 1
				and ((variationRequest.scenePromptEnabled and tostring(variationRequest.scenePrompt or ""):gsub("%s+", "") ~= "")
					and ("Scene preview variant %d of %d. Use the gallery cards to compare candidates."):format(index, #variationRequests)
					or ("Previewing variant %d of %d. Use the gallery cards to compare candidates."):format(index, #variationRequests))
				or ((variationRequest.scenePromptEnabled and tostring(variationRequest.scenePrompt or ""):gsub("%s+", "") ~= "")
					and "Scene-directed preview ready. Drag to orbit, use zoom, or enable auto-rotate."
					or "Preview ready. Drag to orbit, use zoom, or enable auto-rotate."),
			generateText = "Generate This Variant",
		}
	end

	if #previewSessionsToLoad == 0 then
		endGenerationActivity()
		setPreviewBusy(false)
		ui.previewInfoLabel.Text = "Preview failed for all requested variations."
		setStatus("Preview generation failed for all requested variations.", "error")
		return
	end

	pushPromptHistory(request.prompt)
	refreshPromptHistoryButtons()
	replacePreviewSessions(
		previewSessionsToLoad,
		1,
		#previewSessionsToLoad > 1
			and ("Opened %d preview variants. Cache hits: %d. Failed: %d."):format(#previewSessionsToLoad, cacheHits, failureCount)
			or (cacheHits > 0 and "Opened a cached visual preview in the preview window." or "Opened a visual preview in the preview window.")
	)
	playGenerationCompletionSound("batch_complete")
	endGenerationActivity()
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
		variationCount = instance:GetAttribute("DetailedModelVariationCount") or 1,
		scenePrompt = tostring(instance:GetAttribute("DetailedModelScenePrompt") or ""),
		scenePromptEnabled = instance:GetAttribute("DetailedModelScenePromptEnabled") == true,
		modelScale = getInstanceScale(instance),
		groundSnap = experimentalGroundSnap,
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

	return buildRequestInputsAndSchema(request)
end

function loadRequestIntoInputs(request)
	if not request then
		return
	end
	ui.promptBox.Text = tostring(request.prompt or "")
	ui.sizeBox.Text = tostring(request.targetSize or 24)
	ui.trianglesBox.Text = tostring(request.maxTriangles or 20000)
	ui.schemaBox.Text = tostring(request.schemaName or "Body1")
	ui.seedBox.Text = tostring(request.seed or "")
	ui.variationCountBox.Text = tostring(request.variationCount or 1)
	ui.colliderModeBox.Text = tostring(request.colliderMode or "ai")
	if ui.scenePromptBox then
		ui.scenePromptBox.Text = tostring(request.scenePrompt or "")
	end
	generationTexturesEnabled = request.textures ~= false
	generationIncludeBaseEnabled = request.includeBase ~= false
	generationAnchoredEnabled = request.anchored ~= false
	syncGenerationBooleanButtons()
	renderRequestPreview(buildRequest())
end

function cycleNamePattern()
	local order = {"Prompt", "Prompt + Seed", "Prompt + Index", "Prompt + Seed + Index"}
	for index, name in ipairs(order) do
		if name == generationNamePattern then
			generationNamePattern = order[(index % #order) + 1]
			setSetting(SETTINGS.namePattern, generationNamePattern)
			return
		end
	end
	generationNamePattern = order[1]
	setSetting(SETTINGS.namePattern, generationNamePattern)
end

function cycleBatchLayout()
	local order = {"Folder Only", "Row", "Grid"}
	for index, name in ipairs(order) do
		if name == generationBatchLayout then
			generationBatchLayout = order[(index % #order) + 1]
			setSetting(SETTINGS.batchLayout, generationBatchLayout)
			return
		end
	end
	generationBatchLayout = order[1]
	setSetting(SETTINGS.batchLayout, generationBatchLayout)
end

function refreshPromptLibraryButtons()
	if ui.favoritePromptButton then
		local currentPrompt = tostring(ui.promptBox and ui.promptBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		local isFavorite = currentPrompt ~= "" and isFavoritePrompt(currentPrompt)
		ui.favoritePromptButton.Text = isFavorite and "Prompt Already Favorited" or "Favorite Current Prompt"
		setButtonThemeRole(ui.favoritePromptButton, isFavorite and "active" or "teal")
		ui.unfavoritePromptButton.Active = isFavorite
		ui.unfavoritePromptButton.AutoButtonColor = isFavorite
		setButtonThemeRole(ui.unfavoritePromptButton, isFavorite and "warning" or "muted")
	end

	for index, button in ipairs(ui.favoritePromptButtons or {}) do
		local prompt = favoritePrompts[index]
		if prompt then
			button.Text = ("Load Favorite %d: %s"):format(index, getPromptName(prompt))
			button.Active = true
			button.AutoButtonColor = true
			setButtonThemeRole(button, "secondary")
		else
			button.Text = ("Favorite %d: Empty"):format(index)
			button.Active = false
			button.AutoButtonColor = false
			setButtonThemeRole(button, "muted")
		end
	end

	for index, button in ipairs(ui.recentPromptButtons or {}) do
		local prompt = recentPromptHistory[index]
		if prompt then
			button.Text = ("Load Recent %d: %s"):format(index, getPromptName(prompt))
			button.Active = true
			button.AutoButtonColor = true
			setButtonThemeRole(button, "info")
		else
			button.Text = ("Recent %d: Empty"):format(index)
			button.Active = false
			button.AutoButtonColor = false
			setButtonThemeRole(button, "muted")
		end
	end

	if ui.namePatternButton then
		ui.namePatternButton.Text = "Name Pattern: " .. generationNamePattern
		setButtonThemeRole(ui.namePatternButton, generationNamePattern == "Prompt" and "accent" or "active")
	end
	if ui.batchLayoutButton then
		ui.batchLayoutButton.Text = "Batch Layout: " .. generationBatchLayout
		setButtonThemeRole(ui.batchLayoutButton, generationBatchLayout == "Folder Only" and "secondary" or "active")
	end
end

function keepSelectedVariationBatch()
	local selection = Selection:Get()
	if #selection == 0 then
		setStatus("Select one or more generated variations first.", "error")
		return
	end

	local folder = findVariationBatchFolder(selection)
	if not folder then
		setStatus("Selected items must come from the same *_Variations folder.", "error")
		return
	end

	local selectedLookup = {}
	for _, instance in ipairs(selection) do
		selectedLookup[instance] = true
	end

	local removed = 0
	ChangeHistoryService:SetWaypoint("Before Keep Selected Variants")
	for _, child in ipairs(folder:GetChildren()) do
		if (child:IsA("Model") or child:IsA("BasePart")) and not selectedLookup[child] then
			child:Destroy()
			removed += 1
		end
	end
	ChangeHistoryService:SetWaypoint("After Keep Selected Variants")
	updateToggleStorageButton()
	setStatus(("Kept %d selected variation(s) and removed %d sibling candidate(s)."):format(#selection, removed), "success")
end

function regenerateSelectedModel()
	local selected = getSingleSelection()
	if not selected or not isGeneratedDetailedModel(selected) then
		setStatus("Select exactly one generated model before using Regenerate Selected.", "error")
		return
	end

	local request = buildRequestFromAttributes(selected)
	if not request then
		setStatus("The selected model is missing saved generation metadata.", "error")
		return
	end

	local selectedParent = selected.Parent or workspace
	local replaceTarget = selected
	loadRequestIntoInputs(request)
	executeDetailedGeneration(request, selectedParent, true, replaceTarget)
end

function buildSingleGenerationRequestFromPreview(request)
	local copy = {}
	for key, value in pairs(request or {}) do
		if key ~= "inputs" and key ~= "schema" then
			copy[key] = value
		end
	end
	copy.variationCount = 1
	copy.variationIndex = 1
	copy.baseSeed = copy.seed
	copy.sceneLayoutMode = "generate"
	return buildRequestInputsAndSchema(copy)
end

function generateActivePreviewVariant()
	if not previewState.activeRequest then
		setStatus("Open a preview variant before generating it.", "error")
		return
	end
	if busy or previewState.busy then
		return
	end

	local request = buildSingleGenerationRequestFromPreview(previewState.activeRequest)
	loadRequestIntoInputs(request)
	executeDetailedGeneration(request, getInsertionParent(), true)
end

function executePreviewGenerationRequests(requests, successMessage)
	if not requests or #requests == 0 then
		setStatus("Select preview variants before generating them.", "error")
		return
	end
	if busy or previewState.busy then
		return
	end

	local parentTarget = getInsertionParent()
	ChangeHistoryService:SetWaypoint("Before Preview Variant Generate")
	setBusyState(true)
	beginGenerationActivity(
		"Generate",
		#requests,
		#requests > 1 and ("Preparing %d preview variants for generation"):format(#requests) or "Preparing selected preview variant",
		"ETA updates after each completed variant."
	)

	local generatedModels = {}
	local outputTarget = parentTarget
	local batchFolder

	if #requests > 1 then
		local batchPrompt = requests[1].prompt or "PreviewBatch"
		batchFolder = Instance.new("Folder")
		batchFolder.Name = getPromptName(batchPrompt) .. "_Variations"
		batchFolder.Parent = parentTarget
		outputTarget = batchFolder
	end

	for index, request in ipairs(requests) do
		ui.generateButton.Text = #requests > 1
			and ("Generating %d/%d..."):format(index, #requests)
			or "Generating..."
		updateGenerationActivity(
			index,
			index - 1,
			#requests > 1 and ("Generating variant %d (%s)"):format(index, request.seed ~= "" and request.seed or "random") or "Generating selected preview variant",
			"Submitting the request to Roblox and waiting for the model to return."
		)

		local success, result = generateSingleDetailedModel(request, outputTarget)
		if not success then
			if batchFolder and #generatedModels == 0 then
				batchFolder:Destroy()
			end
			endGenerationActivity()
			setBusyState(false)
			setStatus("Preview generation failed: " .. tostring(result), "error")
			return
		end
		generatedModels[#generatedModels + 1] = result.model
		updateGenerationActivity(index, index, #requests > 1 and ("Finished variant %d"):format(index) or "Generated selected preview variant", result.usedCache and "Loaded from cache." or "Fresh model generated.")
	end

	if batchFolder then
		layoutGeneratedBatch(batchFolder)
	end

	if requests[1] and requests[1].prompt then
		pushPromptHistory(requests[1].prompt)
		refreshPromptHistoryButtons()
	end
	refreshPromptLibraryButtons()
	Selection:Set(generatedModels)
	ChangeHistoryService:SetWaypoint("After Preview Variant Generate")
	endGenerationActivity()
	setBusyState(false)
	setStatus(successMessage or ("Generated %d preview variant(s)."):format(#generatedModels), "success")
end

function generateSelectedPreviewVariants()
	local requests = getSelectedPreviewRequests()
	if #requests == 0 then
		setStatus("Left-click preview gallery cards to choose the variants you want to generate.", "error")
		return
	end
	for _, request in ipairs(requests) do
		loadRequestIntoInputs(request)
		break
	end
	executePreviewGenerationRequests(requests, ("Generated %d selected preview variant(s)."):format(#requests))
end

function generateAllPreviewVariants()
	local requests = {}
	for _, session in ipairs(previewState.sessions) do
		if session and session.request then
			requests[#requests + 1] = buildSingleGenerationRequestFromPreview(session.request)
		end
	end
	if #requests == 0 then
		setStatus("Open preview variants before generating all of them.", "error")
		return
	end
	loadRequestIntoInputs(requests[1])
	executePreviewGenerationRequests(requests, ("Generated all %d preview variant(s)."):format(#requests))
end

function toggleSelectAllPreviewTabs()
	if #previewState.sessions == 0 then
		setStatus("Open preview variants before selecting them.", "error")
		return
	end

	local selectedCount = getSelectedPreviewSessionCount()
	local allSelected = selectedCount == #previewState.sessions
	previewState.selectedSessionIndexes = {}
	if not allSelected then
		for index = 1, #previewState.sessions do
			previewState.selectedSessionIndexes[index] = true
		end
	end
	refreshPreviewTabs()
	syncPreviewActionButtons()
end

function applyPreset(targetSize, maxTriangles, collisionPresetName)
	ui.sizeBox.Text = tostring(targetSize)
	ui.trianglesBox.Text = tostring(maxTriangles)
	if collisionPresetName then
		applyCollisionHeuristicPreset(collisionPresetName)
	end
	renderRequestPreview(buildRequest())
end

function executeDetailedGeneration(request, parentTarget, skipInputRefresh, replaceTarget)
	saveInputs(
		request.prompt,
		request.targetSize,
		request.maxTriangles,
		request.textures,
		request.includeBase,
		request.anchored,
		request.schemaName,
		request.colliderMode,
		request.seed,
		request.variationCount
	)

	if not skipInputRefresh then
		loadRequestIntoInputs(request)
	end

	local variationRequests = buildVariationRequests(request)
	local generatedModels = {}
	local cacheHits = 0
	local lastResult
	local outputTarget = parentTarget
	local batchFolder

	if #variationRequests > 1 then
		batchFolder = Instance.new("Folder")
		batchFolder.Name = getPromptName(request.prompt) .. "_Variations"
		batchFolder.Parent = parentTarget
		outputTarget = batchFolder
	end

	setBusyState(true)
	beginGenerationActivity(
		"Generate",
		#variationRequests,
		#variationRequests > 1 and ("Preparing %d variations"):format(#variationRequests) or "Preparing generation request",
		"Progress is estimated from completed variations and cache hits."
	)
	setStatus(
		#variationRequests > 1
			and ("Submitting %d variation requests to Roblox Cube 3D..."):format(#variationRequests)
			or "Submitting request to Roblox Cube 3D...",
		"info"
	)
	ChangeHistoryService:SetWaypoint("Before Detailed Model Generate")

	for index, variationRequest in ipairs(variationRequests) do
		ui.generateButton.Text = #variationRequests > 1
			and ("Generating %d/%d..."):format(index, #variationRequests)
			or "Generating..."
		updateGenerationActivity(
			index,
			index - 1,
			#variationRequests > 1 and ("Generating variant %d (%s)"):format(index, variationRequest.seed ~= "" and variationRequest.seed or "random") or "Generating model",
			"Waiting for Roblox Cube 3D to return the next asset.",
			cacheHits
		)

		local success, result = generateSingleDetailedModel(variationRequest, outputTarget)
		if not success then
			if batchFolder and #generatedModels == 0 then
				batchFolder:Destroy()
			end
			endGenerationActivity()
			setBusyState(false)
			setStatus(
				index > 1
					and ("Generation stopped on variation %d/%d after %d success(es): %s"):format(index, #variationRequests, #generatedModels, result)
					or ("Generation failed: %s"):format(result),
				"error"
			)
			return
		end

		generatedModels[#generatedModels + 1] = result.model
		lastResult = {
			request = variationRequest,
			result = result,
		}
		if result.usedCache then
			cacheHits += 1
		end
		updateGenerationActivity(index, index, #variationRequests > 1 and ("Finished variant %d"):format(index) or "Generated model", result.usedCache and "Loaded from cache." or "Fresh model generated.", cacheHits)
	end

	if batchFolder then
		layoutGeneratedBatch(batchFolder)
	end

	if replaceTarget and #variationRequests == 1 and lastResult and lastResult.result and lastResult.result.model then
		pcall(function()
			replaceTarget:Destroy()
		end)
	end

	pushPromptHistory(request.prompt)
	refreshPromptHistoryButtons()
	refreshPromptLibraryButtons()
	Selection:Set(generatedModels)
	ChangeHistoryService:SetWaypoint("After Detailed Model Generate")

	if autoOpenPreviewEnabled and lastResult then
		local previewClone = lastResult.result.model:Clone()
		loadModelIntoPreview(
			previewClone,
			lastResult.request.colliderMode,
			#variationRequests > 1
				and ("Generated %d variations and opened the last result in the preview window."):format(#variationRequests)
				or (lastResult.result.usedCache and "Generated model and opened a cached preview clone." or "Generated model and opened it in the preview window."),
			lastResult.request
		)
	end

	endGenerationActivity()
	setBusyState(false)
	if #variationRequests > 1 then
		setStatus(
			("Generated %d variations for \"%s\". Parent: %s. Cache hits: %d."):format(
				#generatedModels,
				getPromptName(request.prompt),
				outputTarget:GetFullName(),
				cacheHits
			),
			"success"
		)
		return
	end

	if lastResult then
		local metadataNote = lastResult.result.metadataOrError and (" Metadata: " .. tostring(lastResult.result.metadataOrError)) or ""
		local cacheNote = lastResult.result.usedCache and " Loaded from cache." or ""
		setStatus(
			("Generated %s with %d part(s). Parent: %s.%s"):format(
				lastResult.result.model.Name,
				lastResult.result.partCount,
				outputTarget:GetFullName(),
				metadataNote .. cacheNote
			),
			"success"
		)
	end
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

	executeDetailedGeneration(request, getInsertionParent(), true)
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

		if mainWidth < 420 then
			if experimentalScenePromptEnabled then
				ui.seedFrame.Size = UDim2.new(1, 0, 0, 40)
				ui.variationCountBox.Size = UDim2.new(1, 0, 0, 40)
				ui.variationCountBox.Position = UDim2.new(0, 0, 0, 0)
			else
				ui.seedFrame.Size = UDim2.new(1, 0, 0, 136)
				ui.seedBox.Size = UDim2.new(1, 0, 0, 40)
				ui.seedBox.Position = UDim2.new(0, 0, 0, 0)
				ui.variationCountBox.Size = UDim2.new(1, 0, 0, 40)
				ui.variationCountBox.Position = UDim2.new(0, 0, 0, 48)
				ui.randomSeedButton.Size = UDim2.new(1, 0, 0, 40)
				ui.randomSeedButton.Position = UDim2.new(0, 0, 0, 96)
			end
		else
			ui.seedFrame.Size = UDim2.new(1, 0, 0, 40)
			if experimentalScenePromptEnabled then
				ui.variationCountBox.Size = UDim2.new(1, 0, 1, 0)
				ui.variationCountBox.Position = UDim2.new(0, 0, 0, 0)
			else
				ui.seedBox.Size = UDim2.new(0.5, -8, 1, 0)
				ui.seedBox.Position = UDim2.new(0, 0, 0, 0)
				ui.variationCountBox.Size = UDim2.new(0.18, -8, 1, 0)
				ui.variationCountBox.Position = UDim2.new(0.5, 8, 0, 0)
				ui.randomSeedButton.Size = UDim2.new(0.32, -16, 1, 0)
				ui.randomSeedButton.Position = UDim2.new(0.68, 16, 0, 0)
			end
		end
	end

	local previewWidth = previewWidget.AbsoluteSize.X
	if previewWidth > 0 then
		applyAdaptiveGrid(previewControls, previewControlsLayout, 2, 240, 42, 8, 8, 24)
		applyAdaptiveGrid(ui.previewCompareGrid, ui.previewCompareLayout, 2, 180, 148, 8, 8, 0)
		applyAdaptiveGrid(ui.previewSelectedFrame, ui.previewSelectedLayout, 2, 220, 180, 8, 8, 0)
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

function getProceduralToggleLabel(enabled, offText, onText)
	return enabled and onText or offText
end

function getProceduralUiAudioLabel()
	return getProceduralToggleLabel(
		uiAudioEnabled,
		"UI Audio Muted",
		uiAudioVolumeLevel >= 0.72 and "UI Audio Energized" or "UI Audio Enabled"
	)
end

function getProceduralThemeAudioLabel()
	return getProceduralToggleLabel(
		themeChangeAudioEnabled,
		"Theme Audio Muted",
		themeChangeAudioVolumeLevel >= 0.72 and "Theme Audio Cinematic" or "Theme Audio Enabled"
	)
end

function getProceduralVariationCompletionAudioLabel()
	return getProceduralToggleLabel(
		variationCompletionAudioEnabled,
		"Completion Audio Muted",
		"Completion Audio Signifiers Enabled"
	)
end

function getProceduralScenePromptLabel()
	return getProceduralToggleLabel(
		experimentalScenePromptEnabled,
		"Scene Direction Prompt Hidden",
		"Scene Direction Prompt Available"
	)
end

function sceneModeLocksPromptModifiers()
	return experimentalScenePromptEnabled
end

function syncExperimentalScenePromptUi()
	local sceneModeActive = experimentalScenePromptEnabled
	if ui.promptTitle then
		ui.promptTitle.Visible = not sceneModeActive
	end
	if ui.promptBox then
		ui.promptBox.Visible = not sceneModeActive
	end
	if ui.scenePromptTitle then
		ui.scenePromptTitle.Visible = sceneModeActive
	end
	if ui.scenePromptBox then
		ui.scenePromptBox.Visible = sceneModeActive
	end
	if ui.scenePromptHelp then
		ui.scenePromptHelp.Visible = sceneModeActive
	end
	if ui.seedTitle then
		ui.seedTitle.Text = sceneModeActive and "Scene Variations" or "Variation Seed"
	end
	if ui.seedBox then
		ui.seedBox.Visible = not sceneModeActive
	end
	if ui.randomSeedButton then
		ui.randomSeedButton.Visible = not sceneModeActive
	end
	if ui.seedHelp then
		ui.seedHelp.Visible = not sceneModeActive
	end
	if ui.variationCountBox then
		ui.variationCountBox.PlaceholderText = sceneModeActive and "Scene Variations" or "Variations"
	end
end

function updateSettingsButton()
	if not ui.cacheToggleButton then
		return
	end
	ui.cacheToggleButton.Text = getProceduralToggleLabel(cacheEnabled, "Cache Rebuild Mode", "Cache Reuse Enabled")
	setButtonThemeRole(ui.cacheToggleButton, cacheEnabled and "active" or "muted")
	if ui.autoOpenPreviewButton then
		ui.autoOpenPreviewButton.Text = getProceduralToggleLabel(autoOpenPreviewEnabled, "Preview Opens Manually", "Preview Auto-Opens After Generate")
		setButtonThemeRole(ui.autoOpenPreviewButton, autoOpenPreviewEnabled and "active" or "muted")
	end
	if ui.uiAudioToggleButton then
		ui.uiAudioToggleButton.Text = getProceduralUiAudioLabel()
		setButtonThemeRole(ui.uiAudioToggleButton, uiAudioEnabled and "info" or "muted")
	end
	if ui.uiAudioSlider then
		ui.uiAudioSlider:setValue(uiAudioVolumeLevel)
		ui.uiAudioSlider.frame.BackgroundTransparency = uiAudioEnabled and 0 or 0.18
	end
	if ui.themeChangeAudioToggleButton then
		ui.themeChangeAudioToggleButton.Text = getProceduralThemeAudioLabel()
		setButtonThemeRole(ui.themeChangeAudioToggleButton, themeChangeAudioEnabled and "teal" or "muted")
	end
	if ui.themeChangeAudioSlider then
		ui.themeChangeAudioSlider:setValue(themeChangeAudioVolumeLevel)
		ui.themeChangeAudioSlider.frame.BackgroundTransparency = themeChangeAudioEnabled and 0 or 0.18
	end
	if ui.variationCompletionAudioToggleButton then
		ui.variationCompletionAudioToggleButton.Text = getProceduralVariationCompletionAudioLabel()
		setButtonThemeRole(ui.variationCompletionAudioToggleButton, variationCompletionAudioEnabled and "active" or "muted")
	end
	if ui.showAdvancedCollisionButton then
		ui.showAdvancedCollisionButton.Text = getProceduralToggleLabel(
			showAdvancedCollisionTuning,
			"Advanced Collision Tuning Hidden",
			"Advanced Collision Tuning Visible"
		)
		setButtonThemeRole(ui.showAdvancedCollisionButton, showAdvancedCollisionTuning and "active" or "muted")
	end
	if ui.confirmStoreAllButton then
		ui.confirmStoreAllButton.Text = getProceduralToggleLabel(
			confirmStoreAllEnabled,
			"Store All Runs Without Confirmation",
			"Store All Requires Confirmation"
		)
		setButtonThemeRole(ui.confirmStoreAllButton, confirmStoreAllEnabled and "active" or "muted")
	end
	if ui.experimentalStyleBiasButton then
		experimentalStyleBias = normalizeExperimentalStyleBias(experimentalStyleBias)
		if sceneModeLocksPromptModifiers() then
			ui.experimentalStyleBiasButton.Text = "Style Bias Locked By Scene Mode"
			setButtonThemeRole(ui.experimentalStyleBiasButton, "muted")
			ui.experimentalStyleBiasButton.Active = false
			ui.experimentalStyleBiasButton.AutoButtonColor = false
		else
			ui.experimentalStyleBiasButton.Text = experimentalStyleBias == "Off"
				and "Style Bias Neutral"
				or ("Style Bias Favors " .. experimentalStyleBias)
			setButtonThemeRole(ui.experimentalStyleBiasButton, experimentalStyleBias ~= "Off" and "active" or "secondary")
			ui.experimentalStyleBiasButton.Active = true
			ui.experimentalStyleBiasButton.AutoButtonColor = true
		end
	end
	if ui.experimentalPreviewModeButton then
		experimentalPreviewMode = normalizeExperimentalPreviewMode(experimentalPreviewMode)
		if experimentalPreviewMode == "Fast" then
			ui.experimentalPreviewModeButton.Text = "Preview Mode Prioritizes Speed"
		elseif experimentalPreviewMode == "High Quality" then
			ui.experimentalPreviewModeButton.Text = "Preview Mode Prioritizes Fidelity"
		else
			ui.experimentalPreviewModeButton.Text = "Preview Mode Balanced"
		end
		setButtonThemeRole(ui.experimentalPreviewModeButton, experimentalPreviewMode == "Fast" and "warning" or (experimentalPreviewMode == "High Quality" and "active" or "info"))
	end
	if ui.experimentalGroundSnapButton then
		ui.experimentalGroundSnapButton.Text = getProceduralToggleLabel(
			experimentalGroundSnap,
			"Ground Snap Disabled",
			"Ground Snap Anchors To Origin"
		)
		setButtonThemeRole(ui.experimentalGroundSnapButton, experimentalGroundSnap and "active" or "teal")
	end
	if ui.experimentalScenePromptButton then
		ui.experimentalScenePromptButton.Text = getProceduralScenePromptLabel()
		setButtonThemeRole(ui.experimentalScenePromptButton, experimentalScenePromptEnabled and "active" or "warning")
	end
	refreshPluginUpdateUi()
	if ui.experimentalNegativePromptBox then
		local locked = sceneModeLocksPromptModifiers()
		ui.experimentalNegativePromptBox.TextEditable = not locked
		ui.experimentalNegativePromptBox.Active = not locked
		ui.experimentalNegativePromptBox.BackgroundTransparency = locked and 0.18 or 0
		ui.experimentalNegativePromptBox.TextTransparency = locked and 0.2 or 0
		ui.experimentalNegativePromptBox.PlaceholderText = locked
			and "Negative Prompt disabled while scene mode is enabled"
			or "Example: wheels, weapons, broken parts"
	end
	syncExperimentalScenePromptUi()
	if ui.settingsProceduralFrame and settingsWidget and settingsWidget.Enabled then
		rebuildProceduralSettingsOverview()
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
	refreshPromptLibraryButtons()
	refreshSettingsSearch()
end

function setAutoOpenPreviewEnabled(enabled)
	autoOpenPreviewEnabled = enabled and true or false
	setSetting(SETTINGS.autoOpenPreview, autoOpenPreviewEnabled)
	updateSettingsButton()
end

function setUiAudioEnabled(enabled)
	uiAudioEnabled = enabled == true
	setSetting(SETTINGS.uiAudioEnabled, uiAudioEnabled)
	if uiAudioEnabled and uiAudioVolumeLevel <= 0 then
		uiAudioVolumeLevel = 0.72
		setSetting(SETTINGS.uiAudioVolume, uiAudioVolumeLevel)
	end
	updateSettingsButton()
end

function setThemeChangeAudioEnabled(enabled)
	themeChangeAudioEnabled = enabled == true
	setSetting(SETTINGS.themeChangeAudioEnabled, themeChangeAudioEnabled)
	if themeChangeAudioEnabled and themeChangeAudioVolumeLevel <= 0 then
		themeChangeAudioVolumeLevel = 0.72
		setSetting(SETTINGS.themeChangeAudioVolume, themeChangeAudioVolumeLevel)
	end
	updateSettingsButton()
end

function setVariationCompletionAudioEnabled(enabled)
	variationCompletionAudioEnabled = enabled == true
	setSetting(SETTINGS.variationCompletionAudioEnabled, variationCompletionAudioEnabled)
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

function setExperimentalScenePromptEnabled(enabled)
	experimentalScenePromptEnabled = enabled and true or false
	setSetting(SETTINGS.experimentalScenePromptEnabled, experimentalScenePromptEnabled)
	updateSettingsButton()
	updateResponsiveLayouts()
	renderRequestPreview(buildRequest())
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
		rebuildProceduralSettingsOverview()
		refreshSettingsSearch()
	end
end

function setGuidePanelOpen(isOpen)
	themeUi.optionsFrame.Visible = false
	settingsWidget.Enabled = false
	guideWidget.Enabled = isOpen
	if isOpen then
		rebuildGuidebook()
	end
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
		previewState.dragging = false
		previewState.dragLastPosition = nil
		previewState.dragInput = nil
		clearPreviewSessions()
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
ui.previewGenerateCurrentButton.MouseButton1Click:Connect(generateActivePreviewVariant)
ui.previewGenerateSelectedButton.MouseButton1Click:Connect(generateSelectedPreviewVariants)
ui.previewGenerateAllButton.MouseButton1Click:Connect(generateAllPreviewVariants)
ui.previewSelectAllTabsButton.MouseButton1Click:Connect(toggleSelectAllPreviewTabs)

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

ui.checkUpdatesButton.MouseButton1Click:Connect(function()
	checkLatestPluginRelease()
end)

ui.updateReleaseButton.MouseButton1Click:Connect(function()
	setStatus(
		"Automatic self-update is not available from inside Studio. Use the Release URL field in Settings to download the latest GitHub release and replace the local plugin file manually.",
		"info"
	)
end)

ui.autoOpenPreviewButton.MouseButton1Click:Connect(function()
	setAutoOpenPreviewEnabled(not autoOpenPreviewEnabled)
end)

ui.uiAudioToggleButton.MouseButton1Click:Connect(function()
	setUiAudioEnabled(not uiAudioEnabled)
end)

ui.themeChangeAudioToggleButton.MouseButton1Click:Connect(function()
	setThemeChangeAudioEnabled(not themeChangeAudioEnabled)
end)

ui.variationCompletionAudioToggleButton.MouseButton1Click:Connect(function()
	setVariationCompletionAudioEnabled(not variationCompletionAudioEnabled)
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

ui.scenePromptBox.FocusLost:Connect(function()
	local cleaned = tostring(ui.scenePromptBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	ui.scenePromptBox.Text = cleaned
	setSetting(SETTINGS.experimentalScenePrompt, cleaned)
	renderRequestPreview(buildRequest())
end)

ui.experimentalStyleBiasButton.MouseButton1Click:Connect(function()
	if sceneModeLocksPromptModifiers() then
		return
	end
	cycleExperimentalStyleBias()
end)

ui.experimentalPreviewModeButton.MouseButton1Click:Connect(function()
	cycleExperimentalPreviewMode()
end)

ui.experimentalGroundSnapButton.MouseButton1Click:Connect(function()
	setExperimentalGroundSnap(not experimentalGroundSnap)
end)

ui.experimentalScenePromptButton.MouseButton1Click:Connect(function()
	setExperimentalScenePromptEnabled(not experimentalScenePromptEnabled)
end)

themeUi.searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if themeUi.optionsFrame.Visible then
		refreshThemeOptions()
	end
end)

ui.promptBox:GetPropertyChangedSignal("Text"):Connect(function()
	refreshPromptLibraryButtons()
	renderRequestPreview(buildRequest())
end)

ui.scenePromptBox:GetPropertyChangedSignal("Text"):Connect(function()
	renderRequestPreview(buildRequest())
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
ui.regenerateSelectedButton.MouseButton1Click:Connect(regenerateSelectedModel)
ui.closePreviewButton.MouseButton1Click:Connect(function()
	previewWidget.Enabled = false
	clearPreviewSessions()
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
	zoomPreview(-math.max(previewState.orbitRadius * 0.18, 1.5))
end)
ui.zoomOutButton.MouseButton1Click:Connect(function()
	zoomPreview(math.max(previewState.orbitRadius * 0.18, 1.5))
end)
ui.autoRotateButton.MouseButton1Click:Connect(function()
	setPreviewAutoRotate(not previewState.autoRotateEnabled)
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
	previewState.showOriginMarker = not previewState.showOriginMarker
	syncPreviewOriginMarkerButton()
	updatePreviewDecorations()
end)
ui.previewBoundsButton.MouseButton1Click:Connect(function()
	previewState.showBoundsOverlay = not previewState.showBoundsOverlay
	syncPreviewBoundsButton()
	updatePreviewDecorations()
end)
ui.previewCollisionOpacityButton.MouseButton1Click:Connect(function()
	if previewState.collisionOpacityMode == "Low" then
		previewState.collisionOpacityMode = "Medium"
	elseif previewState.collisionOpacityMode == "Medium" then
		previewState.collisionOpacityMode = "High"
	else
		previewState.collisionOpacityMode = "Low"
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

ui.variationCountBox.FocusLost:Connect(function()
	local variationCount = parseNumber(ui.variationCountBox.Text, 1, 1, 12)
	ui.variationCountBox.Text = tostring(variationCount)
	setSetting(SETTINGS.variationCount, variationCount)
	renderRequestPreview(buildRequest())
end)

ui.favoritePromptButton.MouseButton1Click:Connect(function()
	if addFavoritePrompt(ui.promptBox.Text) then
		refreshPromptLibraryButtons()
		setStatus("Saved the current prompt to favorites.", "success")
	else
		setStatus("Write a prompt before saving it to favorites.", "error")
	end
end)

ui.unfavoritePromptButton.MouseButton1Click:Connect(function()
	if removeFavoritePrompt(ui.promptBox.Text) then
		refreshPromptLibraryButtons()
		setStatus("Removed the current prompt from favorites.", "success")
	else
		setStatus("The current prompt is not in favorites.", "error")
	end
end)

for index, button in ipairs(ui.favoritePromptButtons or {}) do
	button.MouseButton1Click:Connect(function()
		local prompt = favoritePrompts[index]
		if prompt then
			ui.promptBox.Text = prompt
			refreshPromptLibraryButtons()
			renderRequestPreview(buildRequest())
			setStatus(("Loaded favorite prompt %d into the editor."):format(index), "success")
		end
	end)
end

for index, button in ipairs(ui.recentPromptButtons or {}) do
	button.MouseButton1Click:Connect(function()
		local prompt = recentPromptHistory[index]
		if prompt then
			ui.promptBox.Text = prompt
			refreshPromptLibraryButtons()
			renderRequestPreview(buildRequest())
			setStatus(("Loaded recent prompt %d into the editor."):format(index), "success")
		end
	end)
end

ui.namePatternButton.MouseButton1Click:Connect(function()
	cycleNamePattern()
	refreshPromptLibraryButtons()
	setStatus("Updated generated model naming pattern.", "success")
end)

ui.batchLayoutButton.MouseButton1Click:Connect(function()
	cycleBatchLayout()
	refreshPromptLibraryButtons()
	setStatus("Updated batch layout behavior for future variation runs.", "success")
end)

applyTheme(themeState.name)
updateThemeSelector()
updateSettingsButton()
updateToggleStorageButton()
refreshPromptHistoryButtons()
refreshPromptLibraryButtons()
refreshThemeOptions()
setThemeMenuOpen(false)
setSettingsPanelOpen(false)
setGuidePanelOpen(false)
updateResponsiveLayouts()
renderRequestPreview(buildRequest())
