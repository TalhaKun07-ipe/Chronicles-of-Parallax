"""Rebuild the editable Godot scene for Degrees of Escape Chamber 1 (The Broken Circuit).
Python standard library only.
Generates an 8-section connected obstacle course (Sections A-H, X in [-18, 104], Y up to 5.8m).
"""
from pathlib import Path
import json, random

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'chambers/broken_circuit'
random.seed(19)

palette = {
    'cavern': '554A38', 'void': '140C04', 'deep': '261708', 'shadow': '3B220B', 'stone': '685039',
    'paver': '635B47', 'edge': '9E743B', 'ochre': 'C29F5C', 'gold': 'D4AF67',
    'light': 'EBD8B0', 'rail': '70B9AF', 'rune_off': '564125', 'rune_on': 'D9B779',
}

resources = []
nodes = []
boxes = []
cache = {}

def v(a):
    return 'Vector3(%s)' % ', '.join(str(round(x, 4)) for x in a)

def color(h):
    return 'Color(%s, 1)' % ', '.join(str(round(int(h[i:i+2], 16) / 255, 4)) for i in (0, 2, 4))

for name, h in palette.items():
    glow = name in ['rail', 'light', 'rune_on']
    resources.append(f'[sub_resource type="StandardMaterial3D" id="mat_{name}"]\nalbedo_color = {color(h)}\nroughness = 1.0\n' + ('shading_mode = 0\n' if glow else ''))

def box(name, pos, size, mat='stone', solid=False, parent='Geometry', group='', visible=True):
    key = tuple(size)
    if key not in cache:
        idx = len(cache)
        cache[key] = idx
        resources.append(f'[sub_resource type="BoxMesh" id="mesh_{idx}"]\nsize = {v(size)}\n')
        resources.append(f'[sub_resource type="BoxShape3D" id="shape_{idx}"]\nsize = {v(size)}\n')
    i = cache[key]
    path = f'{parent}/{name}'
    cls = 'AnimatableBody3D' if group == 'moving_platforms' else ('StaticBody3D' if solid else 'Node3D')
    groups = f' groups=["{group}"]' if group else ''
    sync = 'sync_to_physics = true\n' if group == 'moving_platforms' else ''
    nodes.append(f'[node name="{name}" type="{cls}" parent="{parent}"{groups}]\nposition = {v(pos)}\n{sync}')
    if visible:
        nodes.append(f'[node name="Mesh" type="MeshInstance3D" parent="{path}"]\nmesh = SubResource("mesh_{i}")\nmaterial_override = SubResource("mat_{mat}")\n')
    if solid:
        nodes.append(f'[node name="Collision" type="CollisionShape3D" parent="{path}"]\nshape = SubResource("shape_{i}")\n')
    boxes.append(dict(name=name, position=pos, size=size, material=mat, solid=solid, visible=visible, group=group))

def marker(name, pos):
    nodes.append(f'[node name="{name}" type="Marker3D" parent="Markers"]\nposition = {v(pos)}\n')

# World-space masonry materials
for index, name in enumerate(palette):
    if name in ['stone', 'paver', 'shadow', 'deep']:
        resources[index] = f'[sub_resource type="ShaderMaterial" id="mat_{name}"]\nshader = ExtResource("2")\nshader_parameter/stone_color = {color(palette[name])}\n'

nodes.append('[node name="BrokenCircuit" type="Node3D"]\nscript = ExtResource("1")\n')
for name in ['Geometry', 'Details', 'Mechanisms', 'Markers']:
    nodes.append(f'[node name="{name}" type="Node3D" parent="."]\n')

def masonry(name, x1, x2, z1, z2, top, bottom=-6.5, group='', material='stone'):
    parent = 'Mechanisms' if group else 'Geometry'
    height = max(0.1, top - bottom)
    center = ((x1 + x2) / 2, bottom + height / 2, (z1 + z2) / 2)
    box(name, center, (x2 - x1, height, z2 - z1), material, True, parent=parent, group=group)
    nodes[-2] += f'scale = {v((1, max(0.01, height - .1) / height, 1))}\nposition = Vector3(0, -0.05, 0)\n'
    root = f'{parent}/{name}'
    box('Coping', (0, height / 2 - .05, 0), (x2 - x1 + .08, .10, z2 - z1 + .08), 'paver', parent=root)
    box('FrontBand', (0, height / 2 - .20, (z2 - z1) / 2 + .012), (x2 - x1, .055, .035), 'ochre', parent=root)
    return root

# Continuous deep cavern backdrop and subterranean floor
box('CavernBackdrop', (42, 6, -15), (150, 24, 1.2), 'cavern')
box('CavernAbyssFloor', (42, -7.5, 0), (150, 2.0, 40), 'deep', True)
box('WestLimitWall', (-32, 3.5, 0), (1.5, 9.0, 20), 'deep', True)
box('EastLimitWall', (105, 6.5, 0), (1.5, 12.0, 20), 'deep', True)

# Ruined colonnade along the rear cavern perimeter
for i, x in enumerate(range(-16, 102, 6)):
    h = [7.5, 6.2, 8.8, 6.8][i % 4]
    masonry(f'RuinCol{i}', x - .55, x + .55, -11.5, -10.4, h, 0, '', 'shadow')
    if i % 3 != 1:
        masonry(f'RuinPerimeterWall{i}', x + .55, x + 5.45, -11.2, -10.7, 4.5, 0, '', 'deep')

# =========================================================================
# SECTION A: Arrival & Safe Orientation (X in [-18, -10], Y=0)
# =========================================================================
masonry('ArrivalCourt', -18.5, -10.0, -5.5, 5.5, 0.0, -6.5, material='paver')
masonry('ArrivalBackWall', -18.5, -10.0, -6.2, -5.5, 5.5, 0.0, material='stone')
masonry('ArrivalFrontWall', -18.5, -10.0, 5.5, 6.2, 0.45, -6.5, group='fg_walls', material='stone')

# Raised stone ledge at X=-10 requiring a 2D jump
masonry('LedgeStepA', -10.0, -7.5, -4.0, 4.0, 0.80, -6.5, material='stone')

# =========================================================================
# SECTION B: The Broken Stair - 2D Introduction (4 Ascending Jumps)
# =========================================================================
# Deep rift below X in [-7.5, 4.8]. Step piers ascending:
masonry('StairB1', -6.3, -4.2, -2.5, 2.5, 1.20, -6.5, material='stone')
masonry('StairB2', -2.7, -0.7, -2.5, 2.5, 1.60, -6.5, material='stone')
masonry('StairB3', 1.0, 3.0, -2.5, 2.5, 2.00, -6.5, material='stone')
# Broad resting terrace at the top of the stair
masonry('TerraceBTop', 4.8, 9.5, -5.5, 5.5, 2.40, -6.5, material='paver')
masonry('SectionBBackWall', -10.0, 9.5, -6.2, -5.5, 6.0, 0.8, material='stone')
masonry('SectionBFrontWall', -10.0, 4.8, 5.5, 6.2, 0.45, -6.5, group='fg_walls', material='stone')

# =========================================================================
# SECTION C: The Offset Passage - 3D Depth Routing (X in [8, 18])
# =========================================================================
# Massive barrier monolith at forward depth Z in [-2.0, 5.5], height 2.40 -> 7.0 (4.6m tall!)
masonry('BarrierMonolithC', 9.5, 11.2, -2.0, 5.5, 7.0, 2.40, material='deep')
# Open rear depth aisle (Z in [-5.5, -2.5]) at Y=2.40
masonry('OffsetAisleC', 9.5, 17.0, -5.5, -2.0, 2.40, -6.5, material='paver')
masonry('OffsetBackWallC', 9.5, 17.0, -6.2, -5.5, 6.5, 2.4, material='stone')
# Guiding floor traces along the offset corridor
for z in [-4.5, -3.5, -2.5]:
    box(f'AisleTrace{z}', (13.2, 2.42, z), (6.0, 0.02, 0.08), 'gold', parent='Details')

# =========================================================================
# SECTION D: The Narrow Conduit - 1D Passage (X in [16, 28])
# =========================================================================
# Conduit docks
box('ConduitDockDStart', (16.5, 2.42, -4.0), (1.5, 0.06, 1.5), 'shadow', parent='Details')
box('ConduitLineDStart', (16.5, 2.46, -4.0), (1.5, 0.02, 0.12), 'gold', parent='Details')

# Substantial stone bulkhead with narrow horizontal slit at X in [20.0, 21.0]
masonry('BulkheadPierLeftD', 20.0, 21.0, -6.5, -4.5, 7.5, 2.4, material='stone')
masonry('BulkheadPierRightD', 20.0, 21.0, -3.5, 6.0, 7.5, 2.4, group='fg_walls', material='stone')
# Lintel creating 0.45m slit above rail
masonry('BulkheadLintelD', 19.8, 21.2, -4.5, -3.5, 7.5, 2.98, material='stone')

# Glowing cyan conduit rail passing through the slit across the 6m rift
box('FirstConduit', (21.0, 2.58, -4.0), (9.0, 0.06, 0.12), 'rail', parent='Mechanisms')

# Destination dock and entry landing for Section E
box('ConduitDockDEnd', (25.5, 2.42, -4.0), (1.5, 0.06, 1.5), 'shadow', parent='Details')
box('ConduitLineDEnd', (25.5, 2.46, -4.0), (1.5, 0.02, 0.12), 'gold', parent='Details')
masonry('GalleryEntryTerrace', 24.5, 29.5, -5.5, -2.2, 2.40, -6.5, material='paver')

# =========================================================================
# SECTION E: The Fractured Gallery - Extended 2D Parkour (X in [29, 50])
# =========================================================================
masonry('GalleryBackWall', 24.5, 50.0, -6.2, -5.5, 7.0, 2.4, material='stone')

# Fractured stepping platforms over deep chasm on plane Z=-4.0:
masonry('GalleryPillarE1', 31.0, 33.2, -5.2, -2.8, 2.80, -6.5, material='stone')
masonry('GalleryPillarE2', 34.8, 37.0, -5.2, -2.8, 3.20, -6.5, material='stone')

# Moving Platform E3 oscillating between X=38.5 and X=41.5 at Y=3.20
# (Created in Mechanisms as AnimatableBody3D / moving block)
box('MovingPlatform', (40.0, 3.12, -4.0), (2.4, 0.25, 2.2), 'paver', solid=True, parent='Mechanisms', group='moving_platforms')
box('MovingPlatformTrim', (40.0, 3.22, -4.0), (2.46, 0.04, 2.26), 'gold', parent='Mechanisms')

masonry('GalleryPillarE4', 43.5, 45.8, -5.2, -2.8, 3.20, -6.5, material='stone')
# Resting landing at entrance to Relay Court
masonry('RelayCourtLanding', 47.5, 52.0, -5.5, 5.0, 3.00, -6.5, material='paver')

# =========================================================================
# SECTION F: The Relay Court - Interactive Dimension Puzzle (X in [50, 68])
# =========================================================================
masonry('RelayCourtFloor', 50.0, 66.0, -5.5, 5.5, 3.00, -6.5, material='paver')
masonry('RelayBackWall', 50.0, 68.0, -6.2, -5.5, 7.5, 3.0, material='stone')
masonry('RelayFrontWall', 50.0, 68.0, 5.5, 6.2, 3.45, -6.5, group='fg_walls', material='stone')

# 1. Security Grille Wall separating Spark at Z=+3.5
masonry('GrillePierLeftF', 53.0, 54.0, 1.0, 2.8, 7.0, 3.0, material='deep')
masonry('GrillePierRightF', 53.0, 54.0, 4.2, 6.0, 7.0, 3.0, group='fg_walls', material='deep')
# Grille lintel creating narrow conduit slit at Z=+3.5
masonry('GrilleLintelF', 52.8, 54.2, 2.8, 4.2, 7.0, 3.55, group='fg_walls', material='stone')
box('RelayConduit', (54.5, 3.18, 3.5), (6.0, 0.06, 0.12), 'rail', parent='Mechanisms')
box('RelayDockStart', (51.5, 3.02, 3.5), (1.4, 0.05, 1.4), 'shadow', parent='Details')
box('RelayDockEnd', (57.5, 3.02, 3.5), (1.4, 0.05, 1.4), 'shadow', parent='Details')

# 2. Central Dividing Wall (X in [57.5, 60.5], Z in [-1.0, 2.0])
masonry('RelayCentralWall', 57.5, 60.5, -1.0, 2.0, 7.0, 3.0, material='deep')

# 3. Receiver Pedestal at X=62.0, Z=-3.5
box('ReceiverBase', (62.0, 3.30, -3.5), (0.8, 0.6, 0.8), 'shadow', True, parent='Mechanisms')
box('ReceiverSocket', (62.0, 3.625, -3.5), (0.52, 0.05, 0.52), 'rune_off', parent='Mechanisms')
for x in [56.0, 58.0, 60.0]:
    box(f'ReceiverTrace{x}', (x, 3.02, -3.5), (1.2, 0.02, 0.08), 'gold', parent='Details')

# 4. Runic Ascent Bridge (unsealed when circuit completed)
masonry('RunicBridge', 64.0, 68.0, -5.2, -1.8, 3.60, -6.5, group='bc_steps', material='stone')
for x in [64.8, 66.2, 67.4]:
    box(f'RuneF{x}', (x, 3.62, -3.5), (0.8, 0.025, 0.4), 'gold', parent='Mechanisms')

# =========================================================================
# SECTION G: The Interwoven Ascent - Multi-Dimensional Finale (X in [68, 88])
# =========================================================================
# Terrace G1 on rear lane Z=-3.5
masonry('TerraceG1', 68.5, 72.5, -5.2, -1.8, 4.20, -6.5, material='paver')

# 3D Transversal Walkway across depth from Z=-3.5 to Z=+2.5 at Y=4.20
masonry('TransversalWalkwayG', 69.5, 72.5, -2.0, 3.5, 4.20, -6.5, material='paver')
for z in [-1.0, 0.5, 2.0]:
    box(f'WalkwayGTrace{z}', (71.0, 4.22, z), (0.08, 0.02, 0.8), 'gold', parent='Details')

# Solid blocking pillar stopping 2D forward route on rear lane
masonry('BlockingPillarG', 72.5, 74.0, -5.2, -1.8, 8.5, 4.2, material='deep')

# Terrace G2 on front lane Z=+2.5
masonry('TerraceG2', 73.5, 76.5, 1.2, 4.0, 4.80, -6.5, group='fg_walls', material='stone')
# High Conduit Dock Terrace
masonry('HighConduitDockG', 78.0, 80.5, 1.2, 4.0, 5.20, -6.5, group='fg_walls', material='stone')

# High Gate Bulkhead with narrow slit over HighConduit rail at X=82.5
masonry('HighGatePierLeftG', 82.0, 83.0, -1.0, 1.8, 9.0, 5.2, material='stone')
masonry('HighGatePierRightG', 82.0, 83.0, 3.2, 6.0, 9.0, 5.2, group='fg_walls', material='stone')
masonry('HighGateLintelG', 81.8, 83.2, 1.8, 3.2, 9.0, 5.75, group='fg_walls', material='stone')

# Elevated High Conduit Rail across chasm (Y=5.35, Z=2.5)
box('HighConduit', (82.5, 5.35, 2.5), (6.5, 0.06, 0.12), 'rail', parent='Mechanisms')
box('HighDockStart', (79.5, 5.22, 2.5), (1.2, 0.05, 1.2), 'shadow', parent='Details')
box('HighDockEnd', (85.5, 5.22, 2.5), (1.2, 0.05, 1.2), 'shadow', parent='Details')

# Stepping stone G4 and Grand Threshold
masonry('HighConduitExitDockG', 84.5, 86.2, 1.2, 3.8, 5.20, -6.5, group='fg_walls', material='stone')
masonry('SteppingStoneG4', 86.5, 88.5, 1.2, 3.8, 5.50, -6.5, group='fg_walls', material='stone')
masonry('GuardianThreshold', 89.5, 93.0, -5.5, 5.5, 5.80, -6.5, material='paver')

# =========================================================================
# SECTION H: Guardian Hall & Exit (X in [90, 104], Y=5.80)
# =========================================================================
masonry('GuardianHallFloor', 92.5, 103.5, -5.5, 5.5, 5.80, -6.5, material='paver')
masonry('GuardianHallBackWall', 89.5, 104.0, -6.2, -5.5, 9.8, 5.8, material='stone')
masonry('GuardianHallFrontWall', 89.5, 104.0, 5.5, 6.2, 6.25, -6.5, group='fg_walls', material='stone')

# Decorative arena ruin pillars
for x, z in [(94.0, -3.5), (94.0, 3.5), (99.0, -3.5), (99.0, 3.5)]:
    masonry(f'ArenaPillar{x}_{z}', x - 0.45, x + 0.45, z - 0.45, z + 0.45, 8.5, 5.8, '', 'shadow')

# Grand Exit Portal Archway
box('DoorRecess', (103.2, 7.2, 0.0), (0.2, 2.8, 2.6), 'void')
masonry('ExitPillarLeft', 102.6, 103.2, -1.8, -1.2, 9.0, 5.8)
masonry('ExitPillarRight', 102.6, 103.2, 1.2, 1.8, 9.0, 5.8)
box('ExitLintel', (102.8, 8.8, 0.0), (0.7, 0.45, 3.6), 'ochre')
box('ExitSeal', (103.0, 7.2, 0.0), (0.08, 2.2, 0.20), 'rune_off', parent='Mechanisms')

# Markers definition across all 8 sections
markers = {
    'Spawn': (-15.0, 0.08, 0.0),
    'Ledge': (-10.0, 0.88, 0.0),
    'StairTop': (6.0, 2.48, 0.0),
    'OffsetCorridor': (13.0, 2.48, -4.0),
    'Rail1Start': (16.5, 2.58, -4.0),
    'Rail1End': (25.5, 2.58, -4.0),
    'GalleryCheckpoint': (26.5, 2.48, -4.0),
    'MovingPlatformPoint': (40.0, 3.28, -4.0),
    'RelayCheckpoint': (49.0, 3.08, 0.0),
    'Charge': (56.0, 3.65, 3.5),
    'Rail2Start': (51.5, 3.18, 3.5),
    'Rail2End': (57.5, 3.18, 3.5),
    'Receiver': (62.0, 3.625, -3.5),
    'AscentCheckpoint': (69.5, 4.28, -3.5),
    'HighRailStart': (79.5, 5.35, 2.5),
    'HighRailEnd': (85.5, 5.35, 2.5),
    'GuardianCheckpoint': (90.0, 5.88, 0.0),
    'GuardianSpawn': (96.0, 6.38, 0.0),
    'Exit': (102.5, 5.88, 0.0),
}
for name, pos in markers.items():
    marker(name, pos)

scene = '[gd_scene load_steps=%d format=3]\n\n[ext_resource type="Script" path="res://chambers/broken_circuit/scripts/chamber.gd" id="1"]\n[ext_resource type="Shader" path="res://chambers/broken_circuit/stone.gdshader" id="2"]\n\n' % (len(resources) + 3)
scene += '\n'.join(resources) + '\n' + '\n'.join(nodes)
(OUT / 'BrokenCircuit.tscn').write_text(scene)

terraces = [
    ('LedgeStepA', -10.0, -7.5, 0.80),
    ('StairB1', -6.3, -4.2, 1.20),
    ('StairB2', -2.7, -0.7, 1.60),
    ('StairB3', 1.0, 3.0, 2.00),
    ('TerraceBTop', 4.8, 9.5, 2.40),
    ('OffsetAisleC', 9.5, 17.0, 2.40),
    ('GalleryEntryTerrace', 24.5, 29.5, 2.40),
    ('GalleryPillarE1', 31.0, 33.2, 2.80),
    ('GalleryPillarE2', 34.8, 37.0, 3.20),
    ('GalleryPillarE4', 43.5, 45.8, 3.20),
    ('RelayCourtLanding', 47.5, 52.0, 3.00),
    ('RelayCourtFloor', 50.0, 66.0, 3.00),
    ('RunicBridge', 64.0, 68.0, 3.60),
    ('TerraceG1', 68.5, 72.5, 4.20),
    ('TransversalWalkwayG', 69.5, 72.5, 4.20),
    ('TerraceG2', 73.5, 76.5, 4.80),
    ('HighConduitDockG', 78.0, 80.5, 5.20),
    ('SteppingStoneG4', 86.5, 88.5, 5.50),
    ('GuardianThreshold', 89.5, 93.0, 5.80),
    ('GuardianHallFloor', 92.5, 103.5, 5.80),
]

data = {
    'revision': 3,
    'units': 'meters',
    'footprint': {'x': [-18, 104], 'z': [-12, 12]},
    'palette': palette,
    'markers': markers,
    'terraces': terraces,
    'boxes': boxes,
}
(ROOT / 'docs').mkdir(exist_ok=True)
(ROOT / 'docs/layout.json').write_text(json.dumps(data, indent=2))
print('Built course: %d pieces across 8 sections (A-H); Chamber 1 Redesign complete' % len(boxes))
