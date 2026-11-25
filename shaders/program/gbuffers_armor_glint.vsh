/*
--------------------------------------------------------------------------------

  Photon Shader by SixthSurge

  program/gbuffers_armor_glint:
  Handle enchantment glint

--------------------------------------------------------------------------------
*/

#include "/include/global.glsl"

out vec2 uv;

#if MC_VERSION >= 260100 && defined IS_IRIS
// The glint is drawn into the translucent layer after lighting, so it is lit
// here like the surface under it (see gbuffers_armor_glint.fsh)
out vec2 light_levels;
flat out vec3 light_color;
flat out vec3 ambient_color;

uniform sampler2D colortex4; // Sky map, lighting colors

uniform ivec2 eyeBrightnessSmooth;
#endif

uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform vec3 cameraPosition;

uniform float near;
uniform float far;

uniform ivec2 atlasSize;

uniform float frameTimeCounter;
uniform float rainStrength;

uniform vec2 taa_offset;
uniform vec3 light_dir;

#include "/include/utility/space_conversion.glsl"
#include "/include/vertex/displacement.glsl"

void main() {
    uv = mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.xy +
        gl_TextureMatrix[0][3].xy;

#if MC_VERSION >= 260100 && defined IS_IRIS
    light_levels = clamp01(gl_MultiTexCoord1.xy * rcp(240.0));

    // The glint render type is drawn full-bright, so its own lightmap carries
    // no information: use the light at the player instead, which is right for
    // held items and worn armor in first person, and close enough for the
    // entities around the player
    if (min_of(light_levels) > 0.99) {
        light_levels = clamp01(vec2(eyeBrightnessSmooth) * rcp(240.0));
    }

    light_color = texelFetch(colortex4, ivec2(191, 0), 0).rgb;
#if defined WORLD_OVERWORLD && defined SH_SKYLIGHT
    ambient_color = texelFetch(colortex4, ivec2(191, 11), 0).rgb;
#else
    ambient_color = texelFetch(colortex4, ivec2(191, 1), 0).rgb;
#endif
#endif

    vec3 pos = transform(gl_ModelViewMatrix, gl_Vertex.xyz);
    pos = view_to_scene_space(pos);
    pos = pos + cameraPosition;
    pos = animate_vertex(pos, false, 1.0, 0);
    pos = pos - cameraPosition;

    vec3 view_pos = scene_to_view_space(pos);
    vec4 clip_pos = project(gl_ProjectionMatrix, view_pos);

#if defined TAA && defined TAAU
    clip_pos.xy = clip_pos.xy * taau_render_scale +
        clip_pos.w * (taau_render_scale - 1.0);
    clip_pos.xy += taa_offset * clip_pos.w;
#elif defined TAA
    clip_pos.xy += taa_offset * clip_pos.w * 0.66;
#endif

    gl_Position = clip_pos;
}
