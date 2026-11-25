/*
--------------------------------------------------------------------------------

  Photon Shader by SixthSurge

  program/gbuffers_armor_glint:
  Handle enchantment glint

--------------------------------------------------------------------------------
*/

#include "/include/global.glsl"

layout(location = 0) out vec4 frag_color;

#if MC_VERSION >= 260100
/* RENDERTARGETS: 13 */
#else
/* RENDERTARGETS: 3 */
#endif

in vec2 uv;

#if MC_VERSION >= 260100 && defined IS_IRIS
in vec2 light_levels;
flat in vec3 light_color;
flat in vec3 ambient_color;
#endif

// ------------
//   Uniforms
// ------------

uniform sampler2D gtexture;

uniform vec2 taa_offset;
uniform vec2 view_pixel_size;

#if MC_VERSION >= 260100 && defined IS_IRIS
uniform float nightVision;
#endif

const float lod_bias = log2(taau_render_scale);

#include "/include/utility/color.glsl"

#if MC_VERSION >= 260100 && defined IS_IRIS
#include "/include/lighting/colors/blocklight_color.glsl"
#include "/include/utility/fast_math.glsl"

// Since 26.1 the glint is added to the translucent layer after lighting
// (previously it was added to the albedo in deferred shading and lit with the
// surface). Unlit, it outshone the item it covers, washing the item out to a
// pale, see-through look, and auto exposure made it glow at night and in caves.
// Light it like a surface instead: a trimmed get_diffuse_lighting with no
// shadows, SSS or directional shading, which this pass has no data for.
vec3 get_glint_lighting(vec2 light_levels) {
    float blocklight = light_levels.x;
    float skylight = light_levels.y;

    vec3 lighting = vec3(0.0);

#if defined WORLD_OVERWORLD || defined WORLD_END
    // Sunlight/moonlight, averaged over the faces of the item
    lighting += light_color * (0.5 * pow4(skylight));
#endif

    // Skylight
#if defined WORLD_OVERWORLD
    lighting += ambient_color * sqr(skylight);
#elif defined WORLD_NETHER
    lighting += 16.0 *
        mix(ambient_color, vec3(dot(ambient_color, luminance_weights_rec2020)), 0.5);
#else
    lighting += ambient_color;
#endif

    // Blocklight
    float blocklight_falloff = pow8(blocklight) + 0.18 * sqr(blocklight) +
        0.16 * dampen(blocklight);
    blocklight_falloff *= smoothstep(0.0, 0.125, blocklight);
    lighting += blocklight_falloff * (blocklight_scale * blocklight_color);

#if defined WORLD_OVERWORLD
    // Cave lighting
    lighting += 0.15 * CAVE_LIGHTING_I * (1.0 - sqr(skylight));
    lighting += nightVision * 1.5;
#endif

    return lighting * rcp_pi;
}
#endif

void main() {
#if defined TAA && defined TAAU
    vec2 coord = gl_FragCoord.xy * view_pixel_size * rcp(taau_render_scale);
    if (clamp01(coord) != coord) {
        discard;
    }
#endif

    vec3 armor_glint = texture(gtexture, uv, lod_bias).rgb;

#if MC_VERSION >= 260100 && defined IS_IRIS
    // Translucent layer: lit glint, added on top of the lit surface. The glint
    // is squared like the inline glint of 26.3+ (gbuffers_all_solid), which
    // adds sqr(glint) to the albedo, so both versions look the same
    frag_color.rgb = (srgb_eotf_inv(sqr(armor_glint)) * rec709_to_working_color) *
        get_glint_lighting(light_levels) * ENCHANTMENT_GLINT_BRIGHTNESS;
    frag_color.a = 0.0;
#elif defined IS_IRIS
    // New overlay handling
    frag_color.rgb = (srgb_eotf_inv(armor_glint) * rec709_to_working_color) *
        ENCHANTMENT_GLINT_BRIGHTNESS;
    frag_color.a = 0.0;
#else
    // Old overlay handling
    // alpha of 0 <=> enchantment glint
    frag_color.rgb = armor_glint;
    frag_color.a = 0.0 / 255.0;
#endif
}