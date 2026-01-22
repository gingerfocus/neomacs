/*
 * "Seascape" by Alexander Alekseev aka TDM - 2014
 * License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 * Contact: tdmaav@gmail.com
 *
 * Originally at https://www.shadertoy.com/view/Ms2SD1
 */

struct Uniforms {
    iResolution: vec2<f32>,
    iTime: f32,
    iMouse: vec4<f32>,
};

@group(0) @binding(0) var<uniform> uniforms: Uniforms;

const NUM_STEPS = 8;
const PI = 3.141592;
const EPSILON = 1e-3;
const AA = false;

// sea
const ITER_GEOMETRY = 3;
const ITER_FRAGMENT = 5;
const SEA_HEIGHT = 0.6;
const SEA_CHOPPY = 4.0;
const SEA_SPEED = 0.8;
const SEA_FREQ = 0.16;
const SEA_BASE = vec3<f32>(0.0, 0.09, 0.18);
const SEA_WATER_COLOR = vec3<f32>(0.8, 0.9, 0.6) * 0.6;
const octave_m = mat2x2<f32>(1.6, 1.2, -1.2, 1.6);

// math
fn fromEuler(ang: vec3<f32>) -> mat3x3<f32> {
    let a1 = vec2<f32>(sin(ang.x), cos(ang.x));
    let a2 = vec2<f32>(sin(ang.y), cos(ang.y));
    let a3 = vec2<f32>(sin(ang.z), cos(ang.z));
    var m: mat3x3<f32>;
    m[0] = vec3<f32>(a1.y * a3.y + a1.x * a2.x * a3.x, a1.y * a2.x * a3.x + a3.y * a1.x, -a2.y * a3.x);
    m[1] = vec3<f32>(-a2.y * a1.x, a1.y * a2.y, a2.x);
    m[2] = vec3<f32>(a3.y * a1.x * a2.x + a1.y * a3.x, a1.x * a3.x - a1.y * a3.y * a2.x, a2.y * a3.y);
    return m;
}

fn hash(p: vec2<f32>) -> f32 {
    let h = dot(p, vec2<f32>(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

fn noise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);
    return -1.0 + 2.0 * mix(mix(hash(i + vec2<f32>(0.0, 0.0)), hash(i + vec2<f32>(1.0, 0.0)), u.x),
                           mix(hash(i + vec2<f32>(0.0, 1.0)), hash(i + vec2<f32>(1.0, 1.0)), u.x), u.y);
}

// lighting
fn diffuse(n: vec3<f32>, l: vec3<f32>, p: f32) -> f32 {
    return pow(dot(n, l) * 0.4 + 0.6, p);
}

fn specular(n: vec3<f32>, l: vec3<f32>, e: vec3<f32>, s: f32) -> f32 {
    let nrm = (s + 8.0) / (PI * 8.0);
    return pow(max(dot(reflect(e, n), l), 0.0), s) * nrm;
}

// sky
fn getSkyColor(e: vec3<f32>) -> vec3<f32> {
    var mut_e = e;
    mut_e.y = (max(mut_e.y, 0.0) * 0.8 + 0.2) * 0.8;
    return vec3<f32>(pow(1.0 - mut_e.y, 2.0), 1.0 - mut_e.y, 0.6 + (1.0 - mut_e.y) * 0.4) * 1.1;
}

// sea
fn sea_octave(uv_in: vec2<f32>, choppy: f32) -> f32 {
    var uv = uv_in;
    uv = uv + noise(uv);
    var wv = 1.0 - abs(sin(uv));
    let swv = abs(cos(uv));
    wv = mix(wv, swv, wv);
    return pow(1.0 - pow(wv.x * wv.y, 0.65), choppy);
}

fn map(p: vec3<f32>) -> f32 {
    var freq = SEA_FREQ;
    var amp = SEA_HEIGHT;
    var choppy = SEA_CHOPPY;
    var uv = p.xz;
    uv.x = uv.x * 0.75;

    let SEA_TIME = 1.0 + uniforms.iTime * SEA_SPEED;

    var d = 0.0;
    var h = 0.0;
    for (var i = 0; i < ITER_GEOMETRY; i = i + 1) {
        d = sea_octave((uv + SEA_TIME) * freq, choppy);
        d = d + sea_octave((uv - SEA_TIME) * freq, choppy);
        h = h + d * amp;
        uv = octave_m * uv;
        freq = freq * 1.9;
        amp = amp * 0.22;
        choppy = mix(choppy, 1.0, 0.2);
    }
    return p.y - h;
}

fn map_detailed(p: vec3<f32>) -> f32 {
    var freq = SEA_FREQ;
    var amp = SEA_HEIGHT;
    var choppy = SEA_CHOPPY;
    var uv = p.xz;
    uv.x = uv.x * 0.75;

    let SEA_TIME = 1.0 + uniforms.iTime * SEA_SPEED;

    var d = 0.0;
    var h = 0.0;
    for (var i = 0; i < ITER_FRAGMENT; i = i + 1) {
        d = sea_octave((uv + SEA_TIME) * freq, choppy);
        d = d + sea_octave((uv - SEA_TIME) * freq, choppy);
        h = h + d * amp;
        uv = octave_m * uv;
        freq = freq * 1.9;
        amp = amp * 0.22;
        choppy = mix(choppy, 1.0, 0.2);
    }
    return p.y - h;
}

fn getSeaColor(p: vec3<f32>, n: vec3<f32>, l: vec3<f32>, eye: vec3<f32>, dist: vec3<f32>) -> vec3<f32> {
    var fresnel = clamp(1.0 - dot(n, -eye), 0.0, 1.0);
    fresnel = pow(fresnel, 3.0) * 0.5;

    let reflected = getSkyColor(reflect(eye, n));
    let refracted = SEA_BASE + diffuse(n, l, 80.0) * SEA_WATER_COLOR * 0.12;

    var color = mix(refracted, reflected, fresnel);

    let atten = max(1.0 - dot(dist, dist) * 0.001, 0.0);
    color = color + SEA_WATER_COLOR * (p.y - SEA_HEIGHT) * 0.18 * atten;

    color = color + vec3<f32>(specular(n, l, eye, 60.0));

    return color;
}

// tracing
fn getNormal(p: vec3<f32>, eps: f32) -> vec3<f32> {
    var n: vec3<f32>;
    n.y = map_detailed(p);
    n.x = map_detailed(vec3<f32>(p.x + eps, p.y, p.z)) - n.y;
    n.z = map_detailed(vec3<f32>(p.x, p.y, p.z + eps)) - n.y;
    n.y = eps;
    return normalize(n);
}

fn heightMapTracing(ori: vec3<f32>, dir: vec3<f32>, p: ptr<function, vec3<f32>>) -> f32 {
    var tm = 0.0;
    var tx = 1000.0;
    let hx = map(ori + dir * tx);
    if (hx > 0.0) {
        return tx;
    }
    let hm = map(ori + dir * tm);
    var tmid = 0.0;
    for (var i = 0; i < NUM_STEPS; i = i + 1) {
        tmid = mix(tm, tx, hm / (hm - hx));
        *p = ori + dir * tmid;
        let hmid = map(*p);
        if (hmid < 0.0) {
            tx = tmid;
        } else {
            tm = tmid;
        }
    }
    return tmid;
}

fn getPixel(coord: vec2<f32>, time: f32) -> vec3<f32> {
    var uv = coord / uniforms.iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x = uv.x * uniforms.iResolution.x / uniforms.iResolution.y;

    // ray
    let ang = vec3<f32>(sin(time * 3.0) * 0.1, sin(time) * 0.2 + 0.3, time);
    let ori = vec3<f32>(0.0, 3.5, time * 5.0);
    var dir = normalize(vec3<f32>(uv.x, uv.y, -2.0));
    dir.z = dir.z + length(uv) * 0.14;
    dir = fromEuler(ang) * normalize(dir);

    // tracing
    var p: vec3<f32>;
    heightMapTracing(ori, dir, &p);
    let dist = p - ori;
    let n = getNormal(p, dot(dist, dist) * (0.1 / uniforms.iResolution.x));
    let light = normalize(vec3<f32>(0.0, 1.0, 0.8));

    // color
    return mix(getSkyColor(dir), getSeaColor(p, n, light, dir, dist), pow(smoothstep(0.0, -0.02, dir.y), 0.2));
}

// main
@fragment
fn mainImage(@builtin(position) fragCoord: vec4<f32>) -> @location(0) vec4<f32> {
    let time = uniforms.iTime * 0.3 + uniforms.iMouse.x * 0.01;

    var color: vec3<f32>;
    if (AA) {
        color = vec3<f32>(0.0);
        for (var i = -1; i <= 1; i = i + 1) {
            for (var j = -1; j <= 1; j = j + 1) {
                let uv = fragCoord.xy + vec2<f32>(f32(i), f32(j)) / 3.0;
                color = color + getPixel(uv, time);
            }
        }
        color = color / 9.0;
    } else {
        color = getPixel(fragCoord.xy, time);
    }

    // post
    return vec4<f32>(pow(color, vec3<f32>(0.65)), 1.0);
}
