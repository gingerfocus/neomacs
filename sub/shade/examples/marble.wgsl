//  Created by S. Guillitte 2015
//  https://www.shadertoy.com/view/MtX3Ws
//
//  Licensed under the
//      Creative Commons Attribution-NonCommercial
//      ShareAlike 3.0 Unported License.

struct Uniforms {
    iResolution: vec2<f32>,
    iTime: f32,
};

@group(0) @binding(0) var<uniform> uniforms: Uniforms;

const ZOOM: f32 = 7.0;

fn csqr(a: vec2<f32>) -> vec2<f32> {
    return vec2<f32>(a.x * a.x - a.y * a.y, 2.0 * a.x * a.y);
}

fn rot(a: f32) -> mat2x2<f32> {
    let c = cos(a);
    let s = sin(a);
    return mat2x2<f32>(c, s, -s, c);
}

fn iSphere(ro: vec3<f32>, rd: vec3<f32>, sph: vec4<f32>) -> vec2<f32> {
    // From iq
    let oc = ro - sph.xyz;
    let b = dot(oc, rd);
    let c = dot(oc, oc) - sph.w * sph.w;
    let h = b * b - c;
    if (h < 0.0) {
        return vec2<f32>(-1.0);
    }
    let h_sqrt = sqrt(h);
    return vec2<f32>(-b - h_sqrt, -b + h_sqrt);
}

fn map(p_in: vec3<f32>) -> f32 {
    var res = 0.0;
    var p = p_in;
    let c = p;
    for (var i = 0; i < 10; i = i + 1) {
        p = 0.7 * abs(p) / dot(p, p) - 0.7;
        p.yz = csqr(p.yz);
        p = p.zxy;
        res = res + exp(-19.0 * abs(dot(p, c)));
    }
    return res / 2.0;
}

fn raymarch(ro: vec3<f32>, rd: vec3<f32>, tminmax: vec2<f32>) -> vec3<f32> {
    var t = tminmax.x;
    let dt = 0.02;
    var col = vec3<f32>(0.0);
    var c = 0.0;
    for (var i = 0; i < 64; i = i + 1) {
        t = t + dt * exp(-2.0 * c);
        if (t > tminmax.y) {
            break;
        }
        c = map(ro + t * rd);

        // Accumulate color
        col = col + 0.1 * vec3<f32>(c * c * c, c * c, c);
    }
    return col;
}

@fragment
fn fs_main(@builtin(position) fragCoord: vec4<f32>) -> @location(0) vec4<f32> {
    let q = fragCoord.xy / uniforms.iResolution.xy;
    var p = -1.0 + 2.0 * q;
    p.x = p.x * uniforms.iResolution.x / uniforms.iResolution.y;

    // Camera
    var ro = ZOOM * vec3<f32>(1.0);
    ro.xz = rot(-0.1 * uniforms.iTime) * ro.xz;

    let ww = normalize(ro);
    let uu = normalize(cross(ww, vec3<f32>(0.0, 1.0, 0.0)));
    let vv = normalize(cross(uu, ww));
    let rd = normalize(p.x * uu + p.y * vv + 4.0 * ww);

    let tmm = iSphere(ro, rd, vec4<f32>(0.0, 0.0, 0.0, 2.0));

    // Raymarch
    var col = raymarch(ro, rd, tmm);

    // Shade
    col = log(1.0 + col) / 2.0;
    return vec4<f32>(col, 1.0);
}
