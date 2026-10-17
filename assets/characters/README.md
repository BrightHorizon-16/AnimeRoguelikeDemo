# Blender animal-fusion collectibles

Editable source: `Funny_Animal_Fusions.blend`  
Source generator: `../blender/build_animal_fusions.py`  
Preview: `animal_fusions_preview.png`

Each FBX is centered at its own origin, with feet at ground level and its face
pointing along local -Y. The meshes are separated by colored feature so Studio's
3D Importer can keep the forms and colors. These files are source assets; Rojo
does not load FBX or BLEND files as live Roblox instances.

## Characters

- **Capy-gator** — capybara and crocodile; a tiny orange rides on its head.
- **Hootfin** — owl and shark; it has feather flippers, a dorsal fin, and tiny
  shark teeth.
- **Giraffrog** — giraffe and frog; a long neck ends in a pair of bulging frog
  eyes, with a fly perched on the nose.
- **Pengtiger** — penguin and tiger; orange stripes, flippers, webbed feet, and
  a very serious fish badge.
- **Snaxolotl** — axolotl and snail; frilly gills, eyestalks, and a spiral shell.

## Studio import

The game spin awards one of these five names into the player's inventory. To
bring the actual Blender meshes into Studio, use **Home → 3D Importer** and
import the FBX files one at a time. Review the scale and material preview in the
importer before accepting. Save the imported Models as `.rbxm` files; Rojo can
then map those Roblox Models into ReplicatedStorage so the game can display the
owned characters. No models are uploaded to a Roblox account by this asset
generation step.

To rebuild the Blender scene and exports from source:

```powershell
& 'C:\Games\blender-5.1.2-windows-x64\blender.exe' --background --factory-startup --python assets\blender\build_animal_fusions.py
```
