"""Vector plan of the expanded obstacle course; standard library only."""
from pathlib import Path
from html import escape
r=Path(__file__).resolve().parents[1];s=[]
def rect(x,y,w,h,c,stroke='none',rx=0):s.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}" stroke="{stroke}" rx="{rx}"/>')
def text(x,y,t,size=15,c='#ebd8b0',weight=400,anchor='start'):s.append(f'<text x="{x}" y="{y}" fill="{c}" font-size="{size}" font-weight="{weight}" text-anchor="{anchor}">{escape(t)}</text>')
def line(pts,c='#d4af67',width=3,dash=''):s.append('<polyline points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="none" stroke="{c}" stroke-width="{width}" stroke-linejoin="round" stroke-dasharray="{dash}"/>')
X=lambda x:90+(x+14)*17.2
Z=lambda z:198+(z+8)*15
W=lambda x1,z1,x2,z2,c,stroke='none':rect(X(x1),Z(z1),(x2-x1)*17.2,(z2-z1)*15,c,stroke)
def badge(x,z,n,c='#ebd8b0'):
 s.append(f'<circle cx="{X(x)}" cy="{Z(z)}" r="13" fill="{c}" stroke="#140c04" stroke-width="2"/>');text(X(x),Z(z)+5,str(n),13,'#140c04',700,'middle')
s.append('<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1030" viewBox="0 0 1280 1030"><style>text{font-family:DejaVu Sans,sans-serif}</style>')
rect(0,0,1280,1030,'#140c04');rect(42,32,5,72,'#c29f5c')
text(64,45,'DEGREES OF ESCAPE / CHAMBER 01 / REVISION 2',13,'#c29f5c',600)
text(64,83,'THE EXPANDED OBSTACLE COURSE',32,'#ebd8b0',700)
text(64,111,'Broad terraces. Depth exploration. Two crossings. One continuous ascent.',16,'#aa8952')
rect(64,136,1152,340,'#24180d','#513619',7)
text(84,164,'PLAN / 64m × 16m PLAYABLE FOOTPRINT',13,'#c29f5c',700)
text(1195,164,'Rear: negative Z  /  Heights in metres',12,'#aa8952',400,'end')
W(-14,-8,50,8,'#49371f','#9e743b')
for x in range(-12,50,4):line([(X(x),Z(-8)),(X(x),Z(8))],'#594428',1)
for z in [-4,0,4]:line([(X(-14),Z(z)),(X(50),Z(z))],'#594428',1)
for x1,x2 in [(-3,1),(40,44)]:W(x1,-8,x2,8,'#0c0905');text(X((x1+x2)/2),424,'4m rift',10,'#c29f5c',400,'middle')
W(-1.5,-8,-.7,8,'#9e743b','#d4af67');W(6,-1,9,4,'#261708','#c29f5c');W(11,1.5,12.5,6,'#261708','#9e743b')
for x1,x2,top in [(15,19.5,.85),(20.5,25.5,1.7),(26.5,32,2.55)]:
 W(x1,-5.6,x2,-2.4,'#775b32','#ebd8b0');text(X((x1+x2)/2),Z(-6.5),str(top)+'m',10,'#ebd8b0',400,'middle')
W(32,-6,40,5.5,'#86683b','#d4af67');W(34.7,-6,35.6,-.3,'#261708','#ebd8b0')
W(44,-5.5,50,5.5,'#86683b','#d4af67');W(41.6,-8,42.4,.5,'#775b32');W(41.6,3.5,42.4,8,'#775b32')
line([(X(-11.5),Z(0)),(X(-5.5),Z(0))],'#d4af67')
line([(X(-5.5),Z(0)),(X(3),Z(0))],'#70b9af',4)
route=[(3,0),(5,-4),(6.6,-4),(6.6,-5),(13.6,-5),(14.3,-4)]
line([(X(x),Z(z)) for x,z in route])
line([(X(14.3),Z(-4)),(X(33.2),Z(-4))],'#ebd8b0',3,'4 5')
line([(X(33.2),Z(-4)),(X(34),Z(2)),(X(38.5),Z(2))],'#d4af67')
line([(X(38),Z(2)),(X(45.5),Z(2))],'#70b9af',4)
line([(X(45.5),Z(2)),(X(48),Z(1))],'#d4af67')
for x,z,n,c in [(-9,0,1,'#d4af67'),(7.5,-4,2,'#d4af67'),(22.5,-4,3,'#ebd8b0'),(37,2,4,'#d4af67'),(48,1,5,'#ebd8b0')]:badge(x,z,n,c)
W(3.5,4.3,4.5,5.3,'#c29f5c');text(X(5.1),Z(5)+4,'optional echo',10,'#c29f5c')
text(84,460,'X → progression    Y ↑ height',11,'#aa8952')
line([(750,456),(774,456)],'#70b9af',4);text(780,460,'1D rail',11,'#aa8952')
line([(878,456),(902,456)],'#d4af67',3);text(908,460,'3D route',11,'#aa8952')
line([(1030,456),(1054,456)],'#ebd8b0',3,'4 5');text(1060,460,'2D climb',11,'#aa8952')
items=[('01 / ARRIVAL','Wake the rail',['Stand on the brass plate.','Explore the broad court.','Flatten at the first dock.']),('02 / RECEIVER','Find depth',['Carry the spark across.','Go behind the masonry.','Power the rear receiver.']),('03 / TERRACES','Climb the plane',['Switch to 2D at Z=−4.','Jump the one-metre gaps.','Walk across each landing.']),('04 / GALLERY','Expand again',['The divider blocks 2D.','Walk around it in 3D.','Step on the upper plate.']),('05 / CROSSING','Read the shutter',['Wait for the opening.','Slide along the upper rail.','Expand and reach the exit.'])]
for i,(a,b,lines) in enumerate(items):
 x=64+i*233;rect(x,497,220,161,'#24180d','#513619',6);text(x+14,523,a,12,'#c29f5c',700);text(x+14,548,b,16,'#ebd8b0',700)
 for j,t in enumerate(lines):text(x+14,576+22*j,t,11,'#ba9a65')
rect(64,684,770,280,'#24180d','#513619',7);text(86,714,'TERRACE ELEVATION / JUMP FROM THE EDGES',13,'#c29f5c',700)
XX=lambda x:100+(x-14)*35;YY=lambda y:915-y*43
for x1,x2,h in [(15,19.5,.85),(20.5,25.5,1.7),(26.5,32,2.55)]:
 rect(XX(x1),YY(h),(x2-x1)*35,915-YY(h),'#785d35','#c29f5c');rect(XX(x1),YY(h),(x2-x1)*35,5,'#ebd8b0');text(XX((x1+x2)/2),YY(h)-11,str(x2-x1)+'m wide',12,'#ebd8b0',400,'middle')
line([(85,915),(805,915)],'#9e743b',2);text(86,944,'1m gaps  ·  0.85m rises  ·  3.2m depth  ·  Ground below catches misses',12,'#ba9a65')
rect(856,684,360,280,'#24180d','#513619',7);text(878,714,'GAMEPLAY CAMERA',13,'#c29f5c',700)
for i,(a,b) in enumerate([('3D / EXPLORE','−45° yaw · −30° pitch'),('2D / PLATFORM','Flat side view · preserve depth'),('CLOSE BY DEFAULT','Size 5.2 · tracks John in X/Y/Z'),('UPPER SHUTTER','3.0s open · 1.8s closed')]):
 y=750+i*53;text(878,y,a,12,'#ebd8b0',700);text(878,y+20,b,12,'#ba9a65')
text(64,997,'ACTUAL GODOT GEOMETRY / 45-CHECK PHYSICS ROUTE',12,'#c29f5c',600);text(1216,997,'Sepia sanctum · Chrome John Rod · Spatial forms available from the start',11,'#aa8952',400,'end')
s.append('</svg>');(r/'docs/first_chamber_layout.svg').write_text('\n'.join(s))
