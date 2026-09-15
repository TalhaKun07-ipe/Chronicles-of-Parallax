shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform vec4 stone_color : source_color = vec4(0.43,0.29,0.14,1.0);
uniform vec4 mortar_color : source_color = vec4(0.11,0.075,0.038,1.0);
varying vec3 world_vertex;
varying vec3 world_normal;
float grain(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() {
 world_vertex=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
 bool top=abs(world_normal.y)>0.7;
 vec2 uv=top ? world_vertex.xz : (abs(world_normal.x)>0.7 ? world_vertex.zy : world_vertex.xy);
 uv=floor(uv*24.0)/24.0;
 vec2 size=top ? vec2(1.65,1.65) : vec2(1.5,0.62);
 float row=floor(uv.y/size.y);
 uv.x+=mod(row,2.0)*size.x*0.5;
 vec2 cell=floor(uv/size);
 vec2 edge=fract(uv/size);
 float chipped=grain(floor(uv*16.0));
 float seam=step(edge.x,0.025+step(0.89,chipped)*0.025)+step(edge.y,0.06);
 float rim=step(0.91,edge.y)*(1.0-step(0.84,chipped));
 float variation=mix(0.82,1.08,grain(cell));
 vec3 color=stone_color.rgb*variation;
 color=mix(color,mortar_color.rgb,clamp(seam,0.0,1.0));
 color+=rim*stone_color.rgb*0.14;
 float fleck=step(0.985,grain(floor(uv*12.0)));
 color=mix(color,mortar_color.rgb,fleck*0.5);
 ALBEDO=color;
 ROUGHNESS=1.0;
}
