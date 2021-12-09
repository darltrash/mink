#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
uniform vec4 color1;
uniform vec4 color2;

vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
    return mix(color1, color2, texture_coords.y);
}
#endif