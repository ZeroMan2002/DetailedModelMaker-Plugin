# Detailed Model Maker

Detailed Model Maker is a Roblox Studio plugin for prompt-driven detailed model generation with built-in previewing, collision workflows, runtime storage handoff, animated theming, and an in-plugin guidebook.

## Purpose

The plugin is designed to turn model generation into a full Studio workflow instead of a one-click black box:

- define a request with prompt, size, triangles, schema, collider mode, and seed
- preview the result before committing
- inspect collision and runtime-readiness
- store models intentionally for play-mode regeneration
- guide the user through the workflow inside Studio itself

## Core Features

- Prompt-driven detailed model generation
- Medium / High / Ultra detail presets
- Dedicated preview widget with orbit, zoom, view presets, lighting, and background controls
- Collision setup with `ai`, `simple`, `medium`, and `detailed` modes
- Runtime storage pipeline for generated models
- Editable pull-back flow for stored models
- Searchable settings panel
- Theme selector with styling variants, tone, contrast, and typography overrides
- Animated theme transitions and button motion
- Built-in guidebook with step highlighting and important workflow notes

## Project Files

- `DetailedModelMaker.lua`
  Main Roblox Studio plugin source
- `docs.html`
  Standalone documentation page
- `index.html`
  GitHub Pages-friendly entry page
- `LICENSE`
  MIT license

## Installation

Copy the plugin file into your Roblox plugins directory:

```text
C:\Users\ZeroManYT\AppData\Local\Roblox\Plugins\DetailedModelMaker.lua
```

Then restart Roblox Studio and open it from the `Plugins` toolbar.

## Recommended Workflow

1. Choose a detail preset.
2. Write the prompt and tune generation inputs.
3. Generate a preview.
4. Inspect scale, readability, and collision assumptions.
5. Generate the final model.
6. Manually verify collision settings on generated mesh parts.
7. Store the model only after technical checks are finished.

## Important Collision Note

Because the generated mesh and the stored/live runtime path are not the same stage, visual correctness is not always the same as runtime collision correctness.

Before storing generated models for live-server use:

```text
Set CollisionFidelity = Precise
```

on the generated mesh parts that need accurate collision.

If you skip that pass, the stored/live result may use the wrong collision shape even if the Studio result looks correct.

## GitHub Setup

If you already created a GitHub repository, publish this folder with:

```powershell
Set-Location 'C:\Users\ZeroManYT\DetailedModelMaker-Plugin'
git add .
git commit -m "Initial commit: Detailed Model Maker plugin and docs"
git branch -M main
git remote add origin https://github.com/<your-username>/DetailedModelMaker-Plugin.git
git push -u origin main
```

## GitHub Pages

This repo now includes `index.html`, so if you enable GitHub Pages for the repository root, the documentation page can be served directly as the project site.

## License

This project is licensed under the MIT License. See `LICENSE`.
