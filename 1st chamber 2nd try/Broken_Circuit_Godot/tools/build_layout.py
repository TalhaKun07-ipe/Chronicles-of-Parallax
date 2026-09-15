"""Rebuild the editable Godot scene. Python standard library only."""
from pathlib import Path
import json, random

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'chambers/broken_circuit'
random.seed(19)
palette = {
    'cavern':'554A38', 'void':'140C04', 'deep':'261708', 'shadow':'3B220B', 'stone':'685039',
    'paver':'635B47', 'edge':'9E743B', 'ochre':'C29F5C', 'gold':'D4AF67',
    'light':'EBD8B0', 'rail':'70B9AF', 'rune_off':'564125', 'rune_on':'D9B779',
}
resources=[]; nodes=[]; boxes=[]; cache={}
def v(a): return 'Vector3(%s)' % ', '.join(str(round(x,4)) for x in a)
def color(h): return 'Color(%s, 1)' % ', '.join(str(round(int(h[i:i+2],16)/255,4)) for i in (0,2,4))
for name,h in palette.items():
    glow=name in ['rail','light','rune_on']
    resources.append(f'[sub_resource type="StandardMaterial3D" id="mat_{name}"]\nalbedo_color = {color(h)}\nroughness = 1.0\n'+ ('shading_mode = 0\n' if glow else ''))
def box(name,pos,size,mat='stone',solid=False,parent='Geometry',group='',visible=True):
    key=tuple(size)
    if key not in cache:
        idx=len(cache);cache[key]=idx
        resources.append(f'[sub_resource type="BoxMesh" id="mesh_{idx}"]\nsize = {v(size)}\n')
        resources.append(f'[sub_resource type="BoxShape3D" id="shape_{idx}"]\nsize = {v(size)}\n')
    i=cache[key]; path=f'{parent}/{name}'
    cls='StaticBody3D' if solid else 'Node3D'
    groups=f' groups=["{group}"]' if group else ''
    nodes.append(f'[node name="{name}" type="{cls}" parent="{parent}"{groups}]\nposition = {v(pos)}\n')
    if visible:
        nodes.append(f'[node name="Mesh" type="MeshInstance3D" parent="{path}"]\nmesh = SubResource("mesh_{i}")\nmaterial_override = SubResource("mat_{mat}")\n')
    if solid:
        nodes.append(f'[node name="Collision" type="CollisionShape3D" parent="{path}"]\nshape = SubResource("shape_{i}")\n')
    boxes.append(dict(name=name,position=pos,size=size,material=mat,solid=solid,visible=visible,group=group))
def marker(name,pos): nodes.append(f'[node name="{name}" type="Marker3D" parent="Markers"]\nposition = {v(pos)}\n')

# World-space masonry remains crisp in either perspective; no baked camera art.
for index,name in enumerate(palette):
    if name in ['stone','paver','shadow','deep']:
        resources[index]=f'[sub_resource type="ShaderMaterial" id="mat_{name}"]\nshader = ExtResource("2")\nshader_parameter/stone_color = {color(palette[name])}\n'

nodes.append('[node name="BrokenCircuit" type="Node3D"]\nscript = ExtResource("1")\n')
for name in ['Geometry','Details','Mechanisms','Markers']:
    nodes.append(f'[node name="{name}" type="Node3D" parent="."]\n')

def masonry(name,x1,x2,z1,z2,top,bottom=-5,group='',material='stone'):
    parent='Mechanisms' if group else 'Geometry'
    center=((x1+x2)/2,(top+bottom)/2,(z1+z2)/2)
    box(name,center,(x2-x1,top-bottom,z2-z1),material,True,parent=parent,group=group)
    # Body mesh ends below the coping: no coplanar top faces / z-fighting.
    nodes[-2] += f'scale = {v((1,(top-bottom-.1)/(top-bottom),1))}\nposition = Vector3(0,-0.05,0)\n'
    root=f'{parent}/{name}'
    box('Coping',(0,(top-bottom)/2-.05,0),(x2-x1+.08,.10,z2-z1+.08),'paver',parent=root)
    box('FrontBand',(0,(top-bottom)/2-.20,(z2-z1)/2+.012),(x2-x1,.055,.035),'ochre',parent=root)
    return root

# Terrain extends past the camera in every playable screen. These are terrain
# masses, not a floating board. Only the two intentional rifts interrupt it.
masonry('ArrivalEarth',-40,-3,-22,22,0,-7,material='paver')
masonry('SanctumEarth',1,40,-22,22,0,-7,material='paver')
masonry('FarEarth',44,80,-22,22,0,-7,material='paver')
for name,x1,x2 in [('Arrival',-14,-3),('Court',1,40),('Exit',44,50)]:
    for z in [-8.25,8.25]:
        masonry(name+('BackWall' if z<0 else 'FrontWall'),x1,x2,z-.3,z+.3,1.65,0)
box('WestLimit',(-14.5,.825,0),(1,1.65,17),'deep',True)
box('EastLimit',(50.5,4,0),(1,8,17),'deep',True)
box('CavernBackdrop',(20,5,-14),(120,14,1),'cavern')
# Natural-looking perimeter pillars and ruined walls fill the background.
for i,x in enumerate(range(-18,57,5)):
    h=[5.8,4.7,7.1,5.2][i%4]
    masonry(f'RuinPier{i}',x-.55,x+.55,-10.5,-9.4,h,0,'', 'shadow')
    if i%3!=1: masonry(f'RuinWall{i}',x+.55,x+4.45,-10.3,-9.8,3.4,0,'','deep')
for i in range(100):
    x=random.uniform(-15,50);z=random.choice([-7.7,7.7])+random.uniform(-.12,.12)
    if -3<x<1 or 40<x<44:continue
    box(f'Rubble{i}',(x,.14,z),(random.uniform(.2,.65),random.uniform(.12,.38),random.uniform(.2,.5)),'shadow',parent='Details')

# 01 / Arrival court: a touch plate tells the player what it controls.
box('WakePlate',(-9,.045,0),(1.2,.09,1.2),'ochre',parent='Mechanisms')
box('WakePlateInset',(-9,.1,0),(.85,.035,.85),'rune_off',parent='Mechanisms')
for x in [-12,-6]:
    masonry('ArrivalButtress'+str(x),x-.5,x+.5,-4,-2.4,2.5,0)
box('FirstConduit',(-1.25,.18,0),(8.5,.06,.12),'rail',parent='Mechanisms')
# Passage in a full-depth bulkhead: 0.46m clear under its door.
masonry('FirstGate',-1.5,-.7,-8,8,4.2,.46)
for z in [-7.6,7.6]:masonry('FirstGatePier'+str(z),-1.8,-.4,z-.4,z+.4,4.8,0)
for x in [-5.5,3]:
    box('RailDock'+str(x),(x,.04,0),(1.5,.08,1.5),'shadow',parent='Details')
    for z in [-.7,.7]:box('DockLine'+str(x)+str(z),(x,.09,z),(1.5,.035,.06),'gold',parent='Details')

# 02 / Receiver court: two wide aisles and a blocked central sightline.
masonry('Monolith',6,9,-1,4,3.7,0)
masonry('SidePier',11,12.5,1.5,6,2.2,0)
for z in [4.015,-1.015]:
    for x in [6.6,7.5,8.4]:box('Inscription'+str(x)+str(z),(x,2.0,z),(.065,1.8,.03),'ochre',parent='Details')
for name,pos,size in [
 ('TraceFront',(4.6,.09,0),(2.5,.035,.07)),
 ('TraceBack',(5.6,.09,-2.0),(.07,.035,4.0)),
 ('TraceSocket',(6.5,.09,-4.0),(1.8,.035,.07)),
 ('TraceClimb',(11.3,.09,-4.0),(5.5,.035,.07))]:box(name,pos,size,'gold',parent='Details')
box('ReceiverBase',(7.5,.30,-4),(.8,.6,.8),'shadow',True,parent='Mechanisms')
box('ReceiverSocket',(7.5,.625,-4),(.52,.05,.52),'rune_off',parent='Mechanisms')
box('EchoPlinth',(4,.25,4.8),(1,.5,1),'stone',True,parent='Mechanisms')
box('EchoGlyph',(4,.53,4.8),(.6,.045,.6),'gold',parent='Mechanisms')

# 03 / Broad 2D masonry terraces. Traversal uses edges, never center-to-center
# jumps. Each new height has several meters of stable ground to investigate.
terraces=[('RunicTerrace1',15,19.5,.85),('RunicTerrace2',20.5,25.5,1.70),('RunicTerrace3',26.5,32,2.55)]
for name,x1,x2,top in terraces:
    parent=masonry(name,x1,x2,-5.6,-2.4,top,-2.5,'bc_steps')
    for x in [-1.0,0,1.0]:
        box('Rune'+str(x),(x,(top+2.5)/2+.08,0),(.14,.025,.7),'gold',parent=parent)
# Catch ground beneath the climb remains at Y=0; no losing the circuit on a miss.

# 04 / Upper gallery: expand, move toward the foreground and stand on a plate.
masonry('UpperGallery',32,40,-6,5.5,2.55,-2.5)
masonry('GalleryDivider',34.7,35.6,-6,-.3,5.4,2.55)
masonry('GalleryBackRail',32,40,-6.3,-6.0,4.2,2.55)
box('UpperPlate',(37,2.62,2),(1.4,.14,1.4),'ochre',parent='Mechanisms')
box('UpperPlateInset',(37,2.71,2),(1,.04,1),'rune_off',parent='Mechanisms')
box('UpperConduit',(41.75,2.73,2),(7.5,.06,.14),'rail',parent='Mechanisms')
box('Shutter',(42,3.42,2),(.45,1.74,2.2),'stone',True,parent='Mechanisms')
box('ShutterIndicator',(41.74,3.5,2),(.055,.8,.17),'ochre',parent='Mechanisms')
# Fixed low lintel makes the upper crossing a line-only route.
masonry('UpperLintel',41.6,42.4,.5,3.5,5.0,3.02)
masonry('UpperGateBack',41.6,42.4,-8,.5,5.0,0)
masonry('UpperGateFront',41.6,42.4,3.5,8,5.0,0)
for x in [38,45.5]:box('UpperDock'+str(x),(x,2.58,2),(1.3,.06,1.5),'gold',parent='Details')

# 05 / A substantial exit terrace, with a lit portal embedded in real masonry.
masonry('ExitTerrace',44,50,-5.5,5.5,2.55,-3)
masonry('ExitSanctumBack',44,50,-5.8,-5.5,6.3,2.55)
box('DoorRecess',(48,3.75,-.25),(2,2.4,.10),'void')
for x in [46.8,49.2]:masonry('ExitPillar'+str(x),x-.2,x+.2,-.5,0,5.2,2.55)
box('ExitLintel',(48,5.25,-.25),(2.9,.35,.7),'ochre')
box('ExitSeal',(48,3.7,-.17),(.14,1.7,.05),'rune_off',parent='Mechanisms')

markers={
 'Spawn':(-11.5,.08,0),'RailStart':(-5.5,.2,0),'RailEnd':(3,.2,0),
 'Charge':(2.2,.65,0),'Receiver':(7.5,.6,-4),'CourtyardCheckpoint':(3,.08,0),
 'ClimbCheckpoint':(13.5,.08,-4),'GalleryCheckpoint':(33,2.63,-4),
 'UpperRailStart':(38,2.75,2),'UpperRailEnd':(45.5,2.75,2),
 'Exit':(48,2.63,1.0),'Echo':(4,.65,4.8),'UpperPlate':(37,2.65,2),
}
for name,pos in markers.items():marker(name,pos)

scene='[gd_scene load_steps=%d format=3]\n\n[ext_resource type="Script" path="res://chambers/broken_circuit/scripts/chamber.gd" id="1"]\n[ext_resource type="Shader" path="res://chambers/broken_circuit/stone.gdshader" id="2"]\n\n'%(len(resources)+3)
scene+='\n'.join(resources)+'\n'+'\n'.join(nodes)
(OUT/'BrokenCircuit.tscn').write_text(scene)
data={'revision':2,'units':'meters','footprint':{'x':[-14,50],'z':[-8,8]},'palette':palette,'markers':markers,'terraces':terraces,'boxes':boxes}
(ROOT/'docs/layout.json').write_text(json.dumps(data,indent=2))
print('Built course:',len(boxes),'pieces; playable footprint 64m x 16m')
