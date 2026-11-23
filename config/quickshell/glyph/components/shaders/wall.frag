#version 440
// wallpaper: image with LED dot matrix (dots 1) or photo (dots 0), mono — matching theme tone (lo…hi), otherwise full color.
// Transition — wave from origin: cell decides as a whole, before wavefront srcA, behind wavefront srcB. At crest, cell is always a dot,
// expands and brightens — photo disintegrates into matrix and reassembles anew. Side without image is transparent (underneath: grid
// and home sphere), crest runs across it anyway
// compile: qsb --qt6 -o wall.frag.qsb wall.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;   // px
    vec2 origin; // px, wave origin
    vec2 cropA;  // visible texture fraction along x/y (PreserveAspectCrop)
    vec2 cropB;
    vec4 lo;     // dark tone end
    vec4 hi;     // bright tone end
    vec4 bg;
    float pitch;  // dot pitch, px
    float dots;   // 0 photo … 1 dots
    float mono;   // 0 color … 1 tone
    float bright; // 0 … 1: from background to image
    float wave;   // 0 … 1
    float hasA;
    float hasB;
};
layout(binding = 1) uniform sampler2D srcA;
layout(binding = 2) uniform sampler2D srcB;

void main() {
    vec2 p = qt_TexCoord0 * size;
    vec2 c = (floor(p / pitch) + 0.5) * pitch;

    // wavefront of width 'band' travels from origin to far corner; k — 0 still old … 1 already new
    float band = pitch * 14.0;
    float far = length(max(origin, size - origin)) + band;
    float k = clamp((wave * far - distance(c, origin)) / band, 0.0, 1.0);
    float crest = 1.0 - abs(2.0 * k - 1.0);
    bool isB = k > 0.5;
    float has = isB ? hasB : hasA;

    // d: 0 — own pixel, 1 — cell center: between them image in cell compresses toward center (smooth pixelation)
    float d = max(dots, crest);
    vec2 uv = mix(p, c, d) / size - 0.5;
    vec4 t = isB ? texture(srcB, uv * cropB + 0.5) : texture(srcA, uv * cropA + 0.5);
    vec3 rgb = t.rgb + bg.rgb * (1.0 - t.a); // transparent in image — blend onto background
    float l = dot(rgb, vec3(0.299, 0.587, 0.114));
    vec3 col = has > 0.5 ? mix(bg.rgb, mix(rgb, mix(lo.rgb, hi.rgb, l), mono), bright) : bg.rgb;
    col = mix(col, hi.rgb, 0.4 * crest);

    // dot: radius from "entire cell" (photo) to .3 pitch (like Dm), expands at crest
    float r = pitch * mix(0.75, 0.3, d) * (1.0 + 0.55 * crest);
    float m = 1.0 - smoothstep(r - 0.6, r + 0.6, distance(p, c));
    float a = has > 0.5 ? 1.0 : m * crest;
    fragColor = vec4(mix(bg.rgb, col, m) * a, a) * qt_Opacity;
}
