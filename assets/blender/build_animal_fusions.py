"""Build five original stylized animal-fusion collectibles in Blender.

Run with:
  blender.exe --background --python assets/blender/build_animal_fusions.py

The script writes a Blender scene, one FBX per character, and a preview render.
"""

import math
import os
import bpy
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "assets", "characters")
os.makedirs(OUT_DIR, exist_ok=True)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.collections, bpy.data.materials, bpy.data.meshes, bpy.data.curves):
        for data in list(datablocks):
            if datablocks == bpy.data.collections and data.name == "Collection":
                continue
            if data.users == 0:
                datablocks.remove(data)


clear_scene()
scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 1600
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.film_transparent = False
scene.world.color = (0.12, 0.16, 0.2)
scene.render.image_settings.color_mode = "RGBA"
scene.view_settings.view_transform = "AgX"
scene.render.filepath = os.path.join(OUT_DIR, "animal_fusions_preview.png")


def material(name, color, metallic=0.0, roughness=0.42):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


MAT = {
    "capy": material("Capybara | warm cinnamon", (0.49, 0.27, 0.13)),
    "capy_light": material("Capybara | muzzle cream", (0.83, 0.62, 0.38)),
    "croc": material("Crocodile | lagoon green", (0.15, 0.48, 0.29)),
    "croc_light": material("Crocodile | mint belly", (0.46, 0.72, 0.39)),
    "orange": material("Orange | citrus", (1.0, 0.35, 0.045)),
    "leaf": material("Leaf | bright green", (0.2, 0.65, 0.12)),
    "navy": material("Owlshark | midnight blue", (0.07, 0.23, 0.48)),
    "blue": material("Owlshark | ocean blue", (0.10, 0.48, 0.78)),
    "cream": material("Owlshark | feather cream", (0.95, 0.88, 0.68)),
    "gold": material("Beak and feet | golden orange", (1.0, 0.48, 0.06)),
    "black": material("Pupils and nostrils | soft black", (0.018, 0.025, 0.035), roughness=0.25),
    "white": material("Eye shine | white", (1.0, 0.98, 0.87), roughness=0.2),
    "frog": material("Giraffrog | spring green", (0.17, 0.66, 0.22)),
    "frog_light": material("Giraffrog | lime belly", (0.6, 0.86, 0.22)),
    "spots": material("Giraffrog | sunny spots", (1.0, 0.68, 0.08)),
    "pink": material("Snaxolotl | bubblegum pink", (0.95, 0.36, 0.58)),
    "pink_light": material("Snaxolotl | gill tips", (1.0, 0.65, 0.72)),
    "shell": material("Snaxolotl | pistachio shell", (0.48, 0.72, 0.32)),
    "shell_light": material("Snaxolotl | shell spiral", (0.96, 0.74, 0.25)),
    "tiger": material("Pengtiger | pumpkin orange", (1.0, 0.36, 0.045)),
    "stripe": material("Tiger | espresso stripes", (0.12, 0.055, 0.035)),
    "plinth": material("Showcase | deep teal", (0.025, 0.12, 0.16), metallic=0.2),
    "plinth_gold": material("Showcase | warm brass", (0.95, 0.62, 0.12), metallic=0.55, roughness=0.24),
}


def collection(name, parent=None):
    col = bpy.data.collections.new(name)
    (parent or scene.collection).children.link(col)
    return col


def link_object(obj, col):
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    col.objects.link(obj)
    return obj


def smooth(obj):
    if obj.type == "MESH":
        for face in obj.data.polygons:
            face.use_smooth = True


def add_uv(col, name, loc, scale, mat, segments=24, rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=loc)
    obj = link_object(bpy.context.object, col)
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    smooth(obj)
    return obj


def add_cone(col, name, loc, radius, depth, mat, rotation=(0, 0, 0), vertices=16):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=0.0, depth=depth, location=loc)
    obj = link_object(bpy.context.object, col)
    obj.name = name
    obj.rotation_euler = rotation
    obj.data.materials.append(mat)
    smooth(obj)
    return obj


def add_cylinder(col, name, loc, radius, depth, mat, rotation=(0, 0, 0), vertices=20):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rotation)
    obj = link_object(bpy.context.object, col)
    obj.name = name
    obj.data.materials.append(mat)
    smooth(obj)
    bevel = obj.modifiers.new("Soft toy edges", "BEVEL")
    bevel.width = min(radius * 0.18, depth * 0.12)
    bevel.segments = 2
    obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    return obj


def add_curve(col, name, points, radius, mat, cyclic=False):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 16
    curve.bevel_depth = radius
    curve.bevel_resolution = 3
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, co in zip(spline.points, points):
        point.co = (*co, 1)
    spline.use_cyclic_u = cyclic
    obj = bpy.data.objects.new(name, curve)
    col.objects.link(obj)
    curve.materials.append(mat)
    return obj


def add_eyes(col, x, y, z, spacing, radius, pupil_mat=MAT["black"]):
    for side in (-1, 1):
        ex = x + side * spacing
        add_uv(col, "Eye white", (ex, y, z), (radius, radius * 0.48, radius), MAT["white"])
        add_uv(col, "Pupil", (ex + 0.025, y - radius * 0.42, z - 0.01), (radius * 0.47, radius * 0.24, radius * 0.5), pupil_mat, 20, 12)
        add_uv(col, "Eye sparkle", (ex + 0.055, y - radius * 0.62, z + radius * 0.22), (radius * 0.14, radius * 0.08, radius * 0.14), MAT["white"], 16, 8)


def add_legs(col, mat, xspread=0.43, yspread=0.38, z=0.34, foot_mat=None):
    for x in (-xspread, xspread):
        for y in (-yspread, yspread):
            add_uv(col, "Stubby leg", (x, y, z), (0.24, 0.26, 0.34), mat)
            add_uv(col, "Little foot", (x, y - 0.1, 0.12), (0.27, 0.33, 0.14), foot_mat or mat)


def build_capygator(col):
    add_legs(col, MAT["capy"], 0.45, 0.38, 0.36)
    add_uv(col, "Round capybara body", (0, 0.08, 1.22), (0.78, 0.82, 0.91), MAT["capy"])
    add_uv(col, "Crocodile belly", (0, -0.45, 0.94), (0.52, 0.35, 0.42), MAT["croc_light"])
    add_uv(col, "Capybara head", (0, -0.55, 1.94), (0.62, 0.58, 0.56), MAT["capy"])
    add_uv(col, "Long croc snout", (0, -1.04, 1.78), (0.48, 0.68, 0.29), MAT["croc"])
    add_uv(col, "Croc lower jaw", (0, -1.0, 1.56), (0.46, 0.58, 0.13), MAT["croc_light"])
    for side in (-1, 1):
        add_uv(col, "Nostril", (side * 0.22, -1.57, 1.91), (0.07, 0.055, 0.045), MAT["black"], 16, 8)
        add_uv(col, "Tiny ear", (side * 0.53, -0.47, 2.27), (0.16, 0.12, 0.19), MAT["capy"])
        add_cone(col, "Croc back scute", (side * 0.3, 0.42, 1.94), 0.14, 0.27, MAT["croc"], rotation=(0, 0, math.pi / 2), vertices=8)
    for y in (-0.02, 0.27, 0.56):
        add_cone(col, "Crocodile spine ridge", (0, y, 2.02), 0.13, 0.26, MAT["croc"], vertices=8)
    add_eyes(col, 0, -0.88, 2.19, 0.27, 0.17)
    # Capybaras famously carry fruit. This one keeps a tiny orange perched on its head.
    add_uv(col, "The emergency orange", (0, -0.28, 2.56), (0.24, 0.24, 0.23), MAT["orange"])
    add_uv(col, "Orange leaf", (0.11, -0.27, 2.76), (0.16, 0.07, 0.055), MAT["leaf"])
    add_uv(col, "Orange stem", (0, -0.26, 2.78), (0.035, 0.035, 0.09), MAT["capy"])


def build_owlshark(col):
    add_legs(col, MAT["navy"], 0.42, 0.38, 0.33, MAT["gold"])
    add_uv(col, "Owlshark body", (0, 0.08, 1.37), (0.75, 0.7, 1.05), MAT["navy"])
    add_uv(col, "Feathered chest", (0, -0.49, 1.35), (0.57, 0.31, 0.69), MAT["cream"])
    add_uv(col, "Shark dorsal fin", (0, 0.18, 2.35), (0.27, 0.37, 0.5), MAT["blue"])
    for side in (-1, 1):
        add_uv(col, "Feathered flipper", (side * 0.91, -0.01, 1.33), (0.42, 0.25, 0.62), MAT["blue"])
        add_cone(col, "Owl ear tuft", (side * 0.46, -0.2, 2.25), 0.23, 0.48, MAT["navy"], rotation=(0, side * 0.25, 0), vertices=10)
        # Three little gill marks make the shark half unmistakable.
        for gill in range(3):
            add_uv(col, "Shark gill", (side * (0.67 + gill * 0.035), -0.12 + gill * 0.16, 1.45 - gill * 0.12), (0.035, 0.07, 0.16), MAT["cream"], 12, 8)
    add_eyes(col, 0, -0.67, 2.03, 0.31, 0.27)
    add_cone(col, "Owl beak", (0, -0.87, 1.72), 0.2, 0.42, MAT["gold"], rotation=(math.pi / 2, 0, 0), vertices=12)
    # A row of tiny teeth gives the owl an unexpectedly sharky smile.
    for x in (-0.3, -0.15, 0, 0.15, 0.3):
        add_cone(col, "Smile tooth", (x, -0.7, 1.03), 0.055, 0.12, MAT["white"], vertices=8)


def build_giraffrog(col):
    add_legs(col, MAT["frog"], 0.51, 0.39, 0.32, MAT["frog_light"])
    add_uv(col, "Frog body", (0, 0.08, 1.0), (0.86, 0.78, 0.69), MAT["frog"])
    add_uv(col, "Frog tummy", (0, -0.51, 0.94), (0.59, 0.31, 0.43), MAT["frog_light"])
    add_uv(col, "Ridiculously long neck", (0, 0.03, 1.92), (0.34, 0.34, 0.83), MAT["frog"])
    add_uv(col, "Giraffe head", (0, -0.04, 2.75), (0.55, 0.5, 0.48), MAT["frog"])
    add_uv(col, "Frog muzzle", (0, -0.48, 2.58), (0.4, 0.32, 0.22), MAT["frog_light"])
    for side in (-1, 1):
        add_uv(col, "Giraffe ossicone", (side * 0.31, 0.01, 3.23), (0.1, 0.1, 0.17), MAT["spots"])
        add_uv(col, "Eye bump", (side * 0.34, -0.28, 3.02), (0.24, 0.23, 0.31), MAT["frog"])
        add_uv(col, "Giraffe spot", (side * 0.28, -0.275, 1.45), (0.15, 0.07, 0.16), MAT["spots"], 16, 10)
        add_uv(col, "Giraffe spot", (side * 0.29, -0.275, 1.88), (0.12, 0.07, 0.12), MAT["spots"], 16, 10)
    add_eyes(col, 0, -0.47, 3.04, 0.34, 0.14)
    add_uv(col, "Nostril", (-0.13, -0.75, 2.62), (0.04, 0.035, 0.035), MAT["black"], 12, 8)
    add_uv(col, "Nostril", (0.13, -0.75, 2.62), (0.04, 0.035, 0.035), MAT["black"], 12, 8)
    add_uv(col, "Fly on nose", (0.24, -0.72, 2.81), (0.07, 0.06, 0.06), MAT["black"], 12, 8)
    # Springy back legs and a tiny tail sell the frog side.
    add_curve(col, "Frog tail", [(0.0, 0.65, 0.83), (0.0, 0.91, 0.93), (0.0, 1.08, 0.81)], 0.09, MAT["frog"])


def build_pengtiger(col):
    add_uv(col, "Penguin body", (0, 0.08, 1.25), (0.77, 0.7, 1.1), MAT["navy"])
    add_uv(col, "Penguin tummy", (0, -0.48, 1.2), (0.55, 0.28, 0.77), MAT["cream"])
    add_uv(col, "Tiger head", (0, -0.16, 2.18), (0.62, 0.55, 0.58), MAT["tiger"])
    add_uv(col, "Tiger muzzle", (0, -0.62, 1.99), (0.34, 0.25, 0.2), MAT["cream"])
    add_uv(col, "Tiger nose", (0, -0.85, 2.08), (0.11, 0.06, 0.075), MAT["stripe"], 16, 10)
    add_eyes(col, 0, -0.64, 2.34, 0.28, 0.16)
    for side in (-1, 1):
        add_uv(col, "Tiger cheek", (side * 0.49, -0.38, 2.0), (0.19, 0.12, 0.2), MAT["tiger"])
        add_uv(col, "Penguin flipper", (side * 0.92, 0.0, 1.28), (0.28, 0.43, 0.62), MAT["navy"])
        # Tiger stripes arc across the side of the penguin body.
        for z in (0.88, 1.28, 1.68):
            add_uv(col, "Tiger body stripe", (side * 0.62, -0.02, z), (0.12, 0.38, 0.08), MAT["stripe"], 16, 10)
        add_uv(col, "Tiger head stripe", (side * 0.42, -0.54, 2.58), (0.07, 0.09, 0.22), MAT["stripe"], 16, 10)
        add_uv(col, "Tiger brow stripe", (side * 0.2, -0.59, 2.61), (0.07, 0.06, 0.2), MAT["stripe"], 16, 10)
        add_uv(col, "Tiger ear", (side * 0.43, -0.07, 2.63), (0.18, 0.15, 0.21), MAT["tiger"])
        add_uv(col, "Ear inset", (side * 0.43, -0.2, 2.64), (0.09, 0.035, 0.11), MAT["pink"])
    add_cone(col, "Penguin beak", (0, -0.82, 2.16), 0.15, 0.28, MAT["gold"], rotation=(math.pi / 2, 0, 0), vertices=12)
    add_uv(col, "Webbed foot", (-0.3, -0.12, 0.14), (0.3, 0.42, 0.15), MAT["gold"])
    add_uv(col, "Webbed foot", (0.3, -0.12, 0.14), (0.3, 0.42, 0.15), MAT["gold"])
    # A tiny fish badge makes the penguin look very proud of its tiger stripes.
    add_uv(col, "Fish badge", (0, -0.77, 1.25), (0.17, 0.06, 0.09), MAT["gold"], 16, 10)
    add_cone(col, "Fish tail", (0, -0.79, 1.25), 0.08, 0.14, MAT["gold"], rotation=(0, 0, math.pi / 2), vertices=8)


def build_snaxolotl(col):
    add_legs(col, MAT["pink"], 0.44, 0.33, 0.32, MAT["pink_light"])
    add_uv(col, "Axolotl body", (0, 0.15, 1.1), (0.72, 0.84, 0.79), MAT["pink"])
    add_uv(col, "Axolotl belly", (0, -0.48, 0.98), (0.53, 0.33, 0.48), MAT["pink_light"])
    add_uv(col, "Axolotl head", (0, -0.45, 1.98), (0.68, 0.61, 0.61), MAT["pink"])
    add_eyes(col, 0, -0.91, 2.14, 0.32, 0.14)
    # Frilly external gills: three soft lobes on each side.
    for side in (-1, 1):
        for index in range(3):
            z = 2.08 + (index - 1) * 0.21
            add_uv(col, "Frilly axolotl gill", (side * (0.76 + 0.06 * (1 - abs(index - 1))), -0.28, z), (0.25, 0.11, 0.12), MAT["pink_light"])
            add_cone(col, "Gill tip", (side * 0.94, -0.28, z), 0.08, 0.2, MAT["pink"], rotation=(0, side * math.pi / 2, 0), vertices=10)
    # A large spiral shell on the back makes the fusion read as a snail at a glance.
    shell_x = 0.76
    add_uv(col, "Snail shell", (shell_x, 0.45, 1.67), (0.66, 0.42, 0.65), MAT["shell"])
    spiral = []
    for step in range(80):
        t = step / 79
        angle = t * math.pi * 4.6
        radius = 0.04 + t * 0.42
        spiral.append((shell_x + math.cos(angle) * radius, 0.02, 1.67 + math.sin(angle) * radius))
    add_curve(col, "Shell spiral", spiral, 0.055, MAT["shell_light"])
    # Eyestalks with sleepy-looking eyeballs, set forward so the face stays visible.
    for side in (-1, 1):
        add_curve(col, "Snail eyestalk", [(side * 0.3, -0.52, 2.43), (side * 0.38, -0.5, 2.74), (side * 0.43, -0.49, 2.87)], 0.07, MAT["pink"])
        add_uv(col, "Eyestalk bulb", (side * 0.43, -0.49, 2.88), (0.14, 0.13, 0.14), MAT["pink"])
        add_uv(col, "Eyestalk eye", (side * 0.43, -0.61, 2.89), (0.075, 0.045, 0.075), MAT["black"], 16, 10)
    add_curve(col, "Snail tail", [(0, 0.78, 0.78), (0.12, 1.08, 0.82), (0.28, 1.2, 0.98)], 0.13, MAT["pink"])


CHARACTERS = [
    ("Capy-gator", "Capybara + Crocodile", build_capygator),
    ("Hootfin", "Owl + Shark", build_owlshark),
    ("Giraffrog", "Giraffe + Frog", build_giraffrog),
    ("Pengtiger", "Penguin + Tiger", build_pengtiger),
    ("Snaxolotl", "Axolotl + Snail", build_snaxolotl),
]

character_collections = []
spacing = 3.65
for index, (name, fusion, build) in enumerate(CHARACTERS):
    col = collection(name)
    col["Fusion"] = fusion
    col["Facing"] = "Front is local -Y; feet rest at Z=0"
    bpy.context.view_layer.update()
    build(col)
    x_offset = (index - (len(CHARACTERS) - 1) / 2) * spacing
    for obj in col.objects:
        obj.location.x += x_offset
    character_collections.append((name, fusion, col, x_offset))


# Presentation-only plinths, lights, camera, and name cards live outside the FBX exports.
showcase = collection("Showcase Only - Not Exported")
for name, fusion, col, x_offset in character_collections:
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=1.3, depth=0.28, location=(x_offset, 0, -0.16))
    plinth = link_object(bpy.context.object, showcase)
    plinth.name = name + " | showcase plinth"
    plinth.data.materials.append(MAT["plinth"])
    bevel = plinth.modifiers.new("Rounded display edge", "BEVEL")
    bevel.width = 0.08
    bevel.segments = 3
    plinth.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=1.32, depth=0.07, location=(x_offset, 0, -0.3))
    ring = link_object(bpy.context.object, showcase)
    ring.name = name + " | brass plinth rim"
    ring.data.materials.append(MAT["plinth_gold"])
    text_data = bpy.data.curves.new(name + " | label", "FONT")
    text_data.body = name
    text_data.align_x = "CENTER"
    text_data.size = 0.24
    text_obj = bpy.data.objects.new(name + " | display label", text_data)
    showcase.objects.link(text_obj)
    text_obj.location = (x_offset, -1.4, -0.2)
    text_obj.rotation_euler = (math.radians(90), 0, 0)
    text_data.materials.append(MAT["cream"])


def point_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


bpy.ops.object.camera_add(location=(0, -15.7, 7.6))
camera = link_object(bpy.context.object, showcase)
camera.name = "Showcase Camera"
point_at(camera, (0, 0, 1.45))
camera.data.type = "ORTHO"
camera.data.ortho_scale = 19.2
scene.camera = camera


def area_light(name, loc, power, size, color, target=(0, 0, 1.3)):
    bpy.ops.object.light_add(type="AREA", location=loc)
    light = link_object(bpy.context.object, showcase)
    light.name = name
    light.data.energy = power
    light.data.shape = "DISK"
    light.data.size = size
    light.data.color = color
    point_at(light, target)


area_light("Key | softbox", (1, -8, 11), 1500, 8, (1.0, 0.83, 0.66))
area_light("Fill | sky", (-8, -2, 6), 1000, 7, (0.48, 0.76, 1.0))
area_light("Rim | mint", (3, 5, 8), 1800, 6, (0.43, 1.0, 0.84))

bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -0.37))
floor = link_object(bpy.context.object, showcase)
floor.name = "Showcase floor"
floor.data.materials.append(material("Backdrop | deep lagoon", (0.025, 0.075, 0.095)))

# Save the complete editable Blender scene.
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "Funny_Animal_Fusions.blend"))

# Render a convenient lineup preview.
scene.render.filepath = os.path.join(OUT_DIR, "animal_fusions_preview.png")
bpy.ops.render.render(write_still=True)

# Export each character by itself. Geometry remains separate by part/material,
# so Studio's 3D importer can preserve the color blocking and silhouette pieces.
for name, fusion, col, x_offset in character_collections:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in col.objects:
        obj.location.x -= x_offset
        if obj.type == "CURVE":
            obj.select_set(True)
    curves = [obj for obj in col.objects if obj.type == "CURVE"]
    for curve_obj in curves:
        bpy.ops.object.select_all(action="DESELECT")
        curve_obj.select_set(True)
        bpy.context.view_layer.objects.active = curve_obj
        bpy.ops.object.convert(target="MESH")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in col.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(col.objects))
    safe_name = name.replace("-", "_")
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(OUT_DIR, safe_name + ".fbx"),
        use_selection=True,
        object_types={"MESH"},
        axis_forward="-Z",
        axis_up="Y",
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        bake_anim=False,
        path_mode="COPY",
        embed_textures=True,
    )
    for obj in col.objects:
        obj.location.x += x_offset

print("Built 5 animal fusion models in", OUT_DIR)
