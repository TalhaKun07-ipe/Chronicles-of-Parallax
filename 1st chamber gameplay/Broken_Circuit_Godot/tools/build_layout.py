"""Rebuild the editable Godot scene. Python standard library only."""
from pathlib import Path
import json, random

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'chambers/broken_circuit'
random.seed(19)
palette = {
    'void':'140C04', 'deep':'261708', 'shadow':'3B220B', 'stone':'66421F',
    'paver':'785026', 'edge':'9E743B', 'ochre':'C29F5C', 'gold':'D4AF67',
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

nodes.append('[node name="BrokenCircuit" type="Node3D"]\nscript = ExtResource("1")\n')
for name in ['Geometry','Details','Mechanisms','Markers']:
    nodes.append(f'[node name="{name}" type="Node3D" parent="."]\n')
# Floors: the only abyss is too broad to jump and crossed by the first rail.
box('LandingSlab',(-10.4,-.55,0),(5.2,1.1,8),'shadow',True)
box('CourtyardSlab',(4.35,-.55,0),(17.3,1.1,8),'shadow',True)
for xmin,xmax in [(-13,-7.8),(-4.3,13)]:
    x=xmin;ix=0
    while x<xmax-.01:
        width=min(1.65,xmax-x)
        for iz in range(5):
            z=-4+iz*1.6
            box(f'Paver_{str(xmin).replace("-","m")}_{ix}_{iz}',(x+width/2,.006,z+.8),(width-.045,.04,1.55),random.choice(['paver','stone','paver']),parent='Details')
        x+=width;ix+=1
box('LeftBoundary',(-13.2,3,0),(.4,6,8.6),'deep',True,visible=False)
box('RightBoundary',(13.2,3,0),(.4,6,8.6),'deep',True,visible=False)
for z in [-4.3,4.3]:
    box('BoundaryBack' if z<0 else 'BoundaryFront',(0,4,z),(27,8,.5),'deep',True,visible=False)
    box('RimBack' if z<0 else 'RimFront',(0,-.03,z),(26.5,.24,.4),'edge')
# Gate closes the entire depth of the chamber. Bottom slot is 0.46m high.
box('SlottedGate',(-6.05,2.33,0),(.8,3.74,8.0),'stone',True)
for z in [-3.7,3.7]:
    box('GatePier'+str(z),(-6.05,2.0,z),(1.3,4,0.65),'shadow',True)
    box('GateCap'+str(z),(-6.05,4.12,z),(1.65,.24,.95),'ochre')
box('GateLintel',(-6.05,4.1,0),(1.05,.22,8),'edge')
for z in [-2.8,-1.4,0,1.4,2.8]:
    box('GateStripe'+str(z),(-6.47,2.3,z),(.035,2.8,.07),'edge',parent='Details')
box('MainConduit',(-6.2,.14,0),(7.6,.07,.12),'rail',parent='Mechanisms')
for x in [-10,-2.4]:
    box('RailDock'+str(x),(x,.04,0),(1.25,.05,1.35),'shadow',parent='Details')
    for z in [-.6,.6]: box('DockTrim'+str(x)+str(z),(x,.075,z),(1.2,.03,.04),'gold',parent='Details')
# Charged monolith blocks a flat route; room around both sides is walkable in 3D.
box('Monolith',(.5,2.15,0),(2.6,4.3,2.4),'stone',True)
box('MonolithFoot',(.5,.13,0),(2.85,.26,2.65),'shadow',True)
box('MonolithCrown',(.5,4.37,0),(2.9,.2,2.7),'ochre')
box('MonolithInset',(.5,2.3,1.212),(1.8,3.3,.03),'shadow',parent='Details')
for y in [1.0,3.6]: box('MonolithBand'+str(y),(.5,y,1.237),(1.55,.055,.03),'edge',parent='Details')
for x in [.05,.5,.95]: box('RuneStroke'+str(x),(x,2.3,1.24),(.06,1.55,.035),'ochre',parent='Details')
box('RuneCrown',(.5,3.12,1.24),(.94,.09,.035),'gold',parent='Details')
# A broken circuit is a literal floor line around the pillar to the hidden socket.
for name,pos,size in [
 ('TraceApproach',(-1.7,.035,0),(1.2,.035,.05)),
 ('TraceTurn',(-1.1,.035,-1.25),(.05,.035,2.5)),
 ('TraceBack',(.05,.035,-2.5),(2.3,.035,.05)),
 ('TraceToStairs',(2.2,.035,-2.5),(1.8,.035,.05))]: box(name,pos,size,'gold',parent='Details')
box('ReceiverBase',(.5,.25,-2.5),(.72,.5,.72),'shadow',True,parent='Mechanisms')
box('ReceiverSocket',(.5,.53,-2.5),(.46,.06,.46),'rune_off',parent='Mechanisms',group='bc_receiver')
# Climb: each rise is 0.85m (6.5m/s jump with gravity18 reaches1.174m).
for i,(x,top) in enumerate([(3.4,.85),(5.3,1.7),(7.2,2.55),(9.1,3.4)]):
    box(f'RunicStep{i+1}',(x,top-.14,-2.5),(1.35,.28,1.4),'rune_off',True,parent='Mechanisms',group='bc_steps')
    box(f'StepRune{i+1}',(x,top+.015,-2.5),(.78,.025,.06),'gold',parent=f'Mechanisms/RunicStep{i+1}')
    # Child coordinates must be relative to the moving/colored platform.
    nodes[-2]=nodes[-2].replace(v((x,top+.015,-2.5)),v((0,.155,0)))
box('UpperBalcony',(11.65,4.02,-2.5),(2.7,.46,2.1),'stone',True)
box('BalconyLip',(11.65,4.2,-1.43),(2.8,.14,.14),'ochre')
box('DoorRecess',(11.7,5.38,-3.49),(1.6,2.25,.1),'void')
for x in [10.72,12.68]:
    box('ExitPillar'+str(x),(x,5.38,-3.46),(.32,2.4,.5),'edge')
    box('ExitCapital'+str(x),(x,6.6,-3.46),(.5,.2,.65),'ochre')
box('ExitLintel',(11.7,6.65,-3.46),(2.4,.28,.5),'gold')
box('ExitSeal',(11.7,5.45,-3.41),(.12,1.4,.04),'rune_off',parent='Mechanisms',group='bc_exit_seal')
# Ruin dressing is kept on the perimeter, away from silhouettes and landing edges.
for i,x in enumerate([-12,-9,-3,3,7.7,12.8]):
    h=[5.5,3.0,4.6,5.6,4.8,6.0][i]
    box(f'BackPillar{i}',(x,h/2,-4.75),(.85,h,.9),'deep')
    box(f'BackPillarCap{i}',(x,h,-4.75),(1.15,.23,1.1),'stone')
    box(f'BackPillarBase{i}',(x,.2,-4.75),(1.2,.4,1.25),'shadow')
    for y in [.9,2.1,3.3]:
        if y<h: box(f'PillarBand{i}_{y}',(x,y,-4.27),(.65,.055,.025),'edge',parent='Details')
for i in range(26):
    x=random.choice([-1,1])*random.uniform(2.5,12.8);z=random.choice([-3.85,3.8])
    if -7.9<x<-4.25:continue
    box(f'Rubble{i}',(x,.12,z),(random.uniform(.2,.55),random.uniform(.12,.4),random.uniform(.15,.5)),'shadow',parent='Details')
# Optional discovery: a small watch echo in the front alcove; no required timer.
box('EchoPlinth',(3.8,.2,2.65),(.85,.4,.85),'shadow',True,parent='Mechanisms')
box('EchoGlyph',(3.8,.43,2.65),(.35,.035,.35),'ochre',parent='Mechanisms',group='bc_echo')
for name,pos in {
 'Spawn':(-11.3,.05,0),'RailStart':(-10,.2,0),'RailEnd':(-2.4,.2,0),
 'Charge':(-3.1,.65,0),'Receiver':(.5,.6,-2.5),
 'CourtyardCheckpoint':(-2.6,.05,0),'ClimbCheckpoint':(2.5,.05,-2.5),
 'Exit':(11.6,4.3,-2.5),'Echo':(3.8,.65,2.65),
}.items(): marker(name,pos)

scene='[gd_scene load_steps=%d format=3]\n\n[ext_resource type="Script" path="res://chambers/broken_circuit/scripts/chamber.gd" id="1"]\n\n'%(len(resources)+2)
scene+='\n'.join(resources)+'\n'+'\n'.join(nodes)
(OUT/'BrokenCircuit.tscn').write_text(scene)
(ROOT/'docs/layout.json').write_text(json.dumps({'units':'meters','axes':{'x':'progression right','y':'up','z':'depth; rear is negative'},'palette':palette,'boxes':boxes},indent=2))
print('Built editable layout:',len(boxes),'boxes;',len(cache),'shared meshes')
