"""Generate an exact, vector chamber plan; no third-party Python packages."""
from pathlib import Path
from html import escape
ROOT=Path(__file__).resolve().parents[1]
s=[]
def add(x):s.append(x)
def rect(x,y,w,h,fill,stroke='none',rx=0):
    add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}"/>')
def text(x,y,t,size=16,fill='#ebd8b0',weight=400,anchor='start'):
    add(f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}" font-weight="{weight}" text-anchor="{anchor}">{escape(t)}</text>')
def path(points,stroke,width=3,dash=''):
    d=' '.join(f'{x},{y}' for x,y in points)
    add(f'<polyline points="{d}" fill="none" stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round" stroke-dasharray="{dash}"/>')
def dot(x,y,label,fill='#ebd8b0'):
    add(f'<circle cx="{x}" cy="{y}" r="14" fill="{fill}" stroke="#140c04" stroke-width="3"/>')
    text(x,y+5,str(label),14,'#140c04',700,'middle')
X=lambda x:100+(x+13)*41.5
Z=lambda z:188+(z+4)*34
def worldrect(x1,z1,x2,z2,fill,stroke='none'):
    rect(X(x1),Z(z1),(x2-x1)*41.5,(z2-z1)*34,fill,stroke)
add('<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1080" viewBox="0 0 1280 1080">')
add('<style>text{font-family:DejaVu Sans,sans-serif}</style>')
rect(0,0,1280,1080,'#140c04')
rect(40,35,5,64,'#c29f5c')
text(64,47,'DEGREES OF ESCAPE / FIRST PLAYABLE CHAMBER',13,'#c29f5c',600)
text(64,85,'THE BROKEN CIRCUIT',36,'#ebd8b0',700)
text(64,111,'Carry a spark. Restore the path. Climb toward the light.',17,'#aa8952')
text(1216,65,'GODOT 4',14,'#c29f5c',700,'end')
text(1216,89,'1D + 2D + 3D',14,'#ebd8b0',400,'end')
rect(64,135,1152,372,'#1e1309','#513619',8)
text(86,162,'PLAN / LOOKING DOWN',13,'#c29f5c',700)
text(1194,162,'Rear = negative Z     •     Floor Y = 0m',13,'#aa8952',400,'end')
worldrect(-13,-4,13,4,'#493017','#8c6532')
for x in range(-12,13,2):path([(X(x),Z(-4)),(X(x),Z(4))],'#563a1c',1)
for z in [-2,0,2]:path([(X(-13),Z(z)),(X(13),Z(z))],'#563a1c',1)
worldrect(-7.8,-4,-4.3,4,'#0d0803')
for z in [-3,-1,1,3]:text(X(-7.55),Z(z),'////',11,'#443019')
worldrect(-6.45,-4,-5.65,4,'#9e743b','#d4af67')
for z in [-3.5,-2,-.5,1,2.5]:path([(X(-6.4),Z(z)),(X(-5.7),Z(z))],'#c29f5c',2)
text(X(-6.05),Z(4)+23,'3.5m chasm',12,'#c29f5c',400,'middle')
worldrect(-10.6,-.6,-9.4,.6,'#261708','#c29f5c')
worldrect(-3,-.6,-1.8,.6,'#261708','#c29f5c')
path([(X(-10),Z(0)),(X(-2.4),Z(0))],'#70b9af',5)
add(f'<path d="M {X(-3.1)} {Z(0)-9} l 7 9 l -7 9 l -7 -9 Z" fill="#ebd8b0"/>')
worldrect(-.925,-1.325,1.925,1.325,'#261708','#9e743b')
worldrect(-.8,-1.2,1.8,1.2,'#66421f','#c29f5c')
text(X(.5),Z(0)-4,'MONOLITH',11,'#ebd8b0',700,'middle')
text(X(.5),Z(0)+14,'4.3m tall',10,'#c29f5c',400,'middle')
path([(X(-2.4),Z(0)),(X(-1.7),Z(0)),(X(-1.7),Z(-2.5)),(X(-.3),Z(-2.5)),(X(-.3),Z(-3.3)),(X(2.4),Z(-3.3)),(X(2.4),Z(-2.5))],'#d4af67',3)
worldrect(.14,-2.86,.86,-2.14,'#140c04','#d4af67')
dot(X(.5),Z(-2.5),3,'#d4af67')
text(X(.5)-8,Z(-1.55),'F',12,'#ebd8b0',700)
for i,x in enumerate([3.4,5.3,7.2,9.1]):
    worldrect(x-.675,-3.2,x+.675,-1.8,'#3b2d19','#d9b779')
    text(X(x),Z(-2.5)+19,f'{.85*(i+1):.2f}m',10,'#ebd8b0',600,'middle')
path([(X(2.4),Z(-2.5)),(X(11.6),Z(-2.5))],'#ebd8b0',3,'5 7')
worldrect(10.3,-3.55,13,-1.45,'#9e743b','#ebd8b0')
rect(X(10.8),Z(-3.4),1.8*41.5,7,'#ebd8b0')
dot(X(11.6),Z(-2.5),4)
text(X(11.6),Z(-.7),'EXIT +4.25m',11,'#ebd8b0',700,'middle')
text(X(7),Z(-3.55),'2D FOOTHOLDS',10,'#ebd8b0',600,'middle')
worldrect(3.375,2.225,4.225,3.075,'#261708','#c29f5c')
text(X(4.5),Z(2.65)+4,'Optional watch echo / F',12,'#c29f5c')
dot(X(-11.3),Z(0),1)
dot(X(-3.1),Z(1.35),2,'#70b9af')
text(X(-11.3),Z(1.0),'SPAWN',11,'#ebd8b0',600,'middle')
text(90,489,'26m wide × 8m deep',12,'#aa8952')
path([(760,485),(792,485)],'#70b9af',4);text(800,489,'1D rail',12,'#aa8952')
path([(887,485),(919,485)],'#d4af67',3);text(927,489,'3D path',12,'#aa8952')
path([(1020,485),(1052,485)],'#ebd8b0',3,'4 5');text(1060,489,'2D climb',12,'#aa8952')
cards=[
 ('01','ARRIVAL',['See the doorway above.','All spatial forms are ready.','Experiment on safe ground.']),
 ('02','THE LOW GATE',['Fold into 1D at the socket.','Slide over the chasm.','Collect the spark on the way.']),
 ('03','THE HIDDEN SOCKET',['Expand and explore depth.','Follow gold behind the pillar.','Press F to restore the circuit.']),
 ('04','THE ASCENT',['Find the rear approach.','2D makes the steps solid.','Climb to the upper doorway.']),
]
for i,(n,title,lines) in enumerate(cards):
    x=64+i*292
    rect(x,530,276,155,'#24180d','#513619',6)
    text(x+16,558,n,14,'#c29f5c',700)
    text(x+16,582,title,15,'#ebd8b0',700)
    for j,line in enumerate(lines):text(x+16,610+j*23,line,13,'#ba9a65')
rect(64,714,818,295,'#1e1309','#513619',8)
text(86,744,'CLIMB ELEVATION / LOCK DEPTH AT Z = -2.5m',13,'#c29f5c',700)
xx=lambda x:105+(x-2)*70
yy=lambda y:957-y*38
path([(95,yy(0)),(842,yy(0))],'#66421f',3)
for i,(x,h) in enumerate([(3.4,.85),(5.3,1.7),(7.2,2.55),(9.1,3.4)]):
    rect(xx(x-.675),yy(h),1.35*70,.28*38,'#d9b779')
    text(xx(x),yy(h)-10,f'{h:.2f}m',12,'#ebd8b0',400,'middle')
    path([(xx(x),yy(h)+14),(xx(x),yy(0))],'#513619',1,'3 5')
rect(xx(10.3),yy(4.25),140,.46*38,'#9e743b','#ebd8b0')
text(xx(11.3),yy(4.25)-10,'4.25m / EXIT',12,'#ebd8b0',600,'middle')
text(95,990,'0.85m rises   •   1.35m-wide steps   •   Safe courtyard below',13,'#ba9a65')
rect(904,714,312,295,'#24180d','#513619',8)
text(926,744,'THE RULES STAY CONSISTENT',13,'#c29f5c',700)
for i,(a,b) in enumerate([
 ('1D / A LINE','Only available on the conduit.'),
 ('2D / A PLANE','Keeps your current depth.'),
 ('3D / A VOLUME','Walk around the obstruction.'),
 ('PROGRESS STAYS','A fall does not drain the socket.'),
]):
    y=778+i*57;text(926,y,a,12,'#ebd8b0',700);text(926,y+19,b,12,'#ba9a65')
text(64,1044,'SEPIA STONE / GOLD CIRCUITS / CHROME JOHN ROD',12,'#c29f5c',600)
text(1216,1044,'Editable Godot geometry · Actual physics-tested route',12,'#aa8952',400,'end')
add('</svg>')
(ROOT/'docs/first_chamber_layout.svg').write_text('\n'.join(s))
