// A Very Bad Cornell Box Raytracer
//
// Matt Keeter, 2020
// matt.j.keeter@gmail.com
//
// MIT / Apache Version 2

struct Uniforms {
    iResolution: vec2<f32>,
    iTime: f32,
};

@group(0) @binding(0) var<uniform> uniforms: Uniforms;

const ID_BACK = 1;
const ID_TOP = 2;
const ID_LEFT = 3;
const ID_RIGHT = 4;
const ID_BOTTOM = 5;
const ID_LIGHT = 6;
const ID_SPHERE = 7;
const ID_FRONT = 8;

////////////////////////////////////////////////////////////////////////////////
// RNGs
// http://byteblacksmith.com/improvements-to-the-canonical-one-liner-glsl-rand-for-opengl-es-2-0/
fn rand(co: vec2<f32>) -> f32 {
    let a = 12.9898;
    let b = 78.233;
    let c = 43758.5453;
    let dt = dot(co, vec2<f32>(a, b));
    let sn = dt % 3.1415926;
    return fract(sin(sn) * c);
}

fn rand3(seed: vec3<f32>) -> vec3<f32> {
    let x = rand(vec2<f32>(seed.z, rand(seed.xy)));
    let y = rand(vec2<f32>(seed.y, rand(seed.xz)));
    let z = rand(vec2<f32>(seed.x, rand(seed.yz)));
    return 2.0 * (vec3<f32>(x, y, z) - 0.5);
}

fn rand3_sphere(seed_in: vec3<f32>) -> vec3<f32> {
    var seed = seed_in;
    loop {
        let v = rand3(seed);
        if (length(v) <= 1.0) {
            return normalize(v);
        }
        seed = seed + vec3<f32>(0.1, 1.0, 10.0);
    }
}

////////////////////////////////////////////////////////////////////////////////
// SHAPES
const SPHERE_CENTER: vec3<f32> = vec3<f32>(-0.4, -0.5, -0.5);

fn plane(norm: vec3<f32>, off: f32, start: vec3<f32>, dir: vec3<f32>) -> vec4<f32> {
    let d = (off - dot(norm, start)) / dot(norm, dir);
    if (d > 0.0) {
        return vec4<f32>(start + d * dir, 1.0);
    } else {
        return vec4<f32>(0.0);
    }
}

fn rear(start: vec3<f32>, dir: vec3<f32>) -> vec4<f32> {
    let p = plane(vec3<f32>(0.0, 0.0, 1.0), -1.0, start, dir);
    if (p.w != 0.0 && abs(p.x) < 1.0 && abs(p.y) < 1.0) {
        return vec4<f32>(p.xyz, f32(ID_BACK));
    } else {
        return vec4<f32>(0.0);
    }
}
fn front(start: vec3<f32>, dir: vec3<f32>) -> vec4<f32> {
    let p = plane(vec3<f32>(0.0, 0.0, -1.0), -1.0, start, dir);
    if (p.w != 0.0 && abs(p.x) < 1.0 && abs(p.y) < 1.0) {
        return vec4<f32>(p.xyz, f32(ID_FRONT));
    } else {
        return vec4<f32>(0.0);
    }
}

fn top(start: vec3<f32>, dir: vec3<f32>) -> vec4<f32> {
    let p = plane(vec3<f32>(0.0, 1.0, 0.0), 1.0, start, dir);
    if (p.w != 0.0 && abs(p.x) < 1.0 && abs(p.z) < 1.0) {
        return vec4<f32>(p.xyz, f32(ID_TOP));
    } else {
        return vec4<f32>(0.0);
    }
}

fn light(start: vec3<f32>, dir: vec3<f32>) -> vec4<f32> {
    let p = plane(vec3<f32>(0.0, 1.0, 0.0), 1.0, start, dir);
    if (p.w != 0.0 && abs(p.x) < 0.3 && abs(p.z) < 0.3) {
        return vec4<f32>(p.xyz, f32(ID_LIGHT));
    } else {
        return vec4<f32>(0.0);
    }
}

fn bottom(start: vec3<f32>, dir: vec3<f32>) -> vec4<f32> {
    let p = plane(vec3<f32>(0.0, -1.0, 0.0), 1.0, start, dir);
    if (p.w != 0.0 && abs(p.x) < 1.0 && abs(p.z) < 1.0) {
        return vec4<f32>(p.xyz, f32(ID_BOTTOM));
    } else {
        return vec4<f32>(0.0);
    }
}

fn left(start: vec3<f32>, dir: vec3<f32>) -> vec4<f32> {
    let p = plane(vec3<f32>(1.0, 0.0, 0.0), -1.0, start, dir);
    if (p.w != 0.0 && abs(p.y) < 1.0 && abs(p.z) < 1.0) {
        return vec4<f32>(p.xyz, f32(ID_LEFT));
    } else {
        return vec4<f32>(0.0);
    }
}

fn right(start: vec3<f32>, dir: vec3<f32>) -> vec4<f32> {
    let p = plane(vec3<f32>(-1.0, 0.0, 0.0), -1.0, start, dir);
    if (p.w != 0.0 && abs(p.y) < 1.0 && abs(p.z) < 1.0) {
        return vec4<f32>(p.xyz, f32(ID_RIGHT));
    } else {
        return vec4<f32>(0.0);
    }
}

fn sphere(start: vec3<f32>, dir: vec3<f32>) -> vec4<f32> {
    let center = SPHERE_CENTER;
    let r = 0.5;
    let delta = center - start;
    let d = dot(delta, dir);
    let nearest = start + dir * d;
    let min_distance = length(center - nearest);
    if (min_distance < r) {
        let q = sqrt(min_distance * min_distance + r * r);
        return vec4<f32>(nearest - q * dir, f32(ID_SPHERE));
    } else {
        return vec4<f32>(0.0);
    }
}

fn norm(pos: vec4<f32>) -> vec3<f32> {
    switch (i32(pos.w)) {
        case ID_TOP: { return vec3<f32>(0.0, -1.0, 0.0); }
        case ID_BACK: { return vec3<f32>(0.0, 0.0, 1.0); }
        case ID_LEFT: { return vec3<f32>(1.0, 0.0, 0.0); }
        case ID_RIGHT: { return vec3<f32>(-1.0, 0.0, 0.0); }
        case ID_LIGHT: { return vec3<f32>(0.0, -1.0, 0.0); }
        case ID_BOTTOM: { return vec3<f32>(0.0, 1.0, 0.0); }
        case ID_SPHERE: { return normalize(pos.xyz - SPHERE_CENTER); }
        case ID_FRONT: { return vec3<f32>(0.0, 0.0, -1.0); }
        default: { return vec3<f32>(0.0); }
    }
}

// Returns the two coordinates which matter, for use in randomization
fn compress(pos: vec4<f32>) -> vec2<f32> {
    switch (i32(pos.w)) {
        case ID_TOP, ID_LIGHT, ID_BOTTOM: { return pos.xz; }
        case ID_FRONT, ID_BACK: { return pos.xy; }
        case ID_LEFT, ID_RIGHT: { return pos.yz; }
        case ID_SPHERE: { return pos.yz; }
        default: { return vec2<f32>(0.0); }
    }
}

fn rand3_norm(pos: vec4<f32>, seed: i32) -> vec3<f32> {
    // Pick a random direction uniformly on the sphere,
    // then tweak it so that the normal is > 0
    let dir = rand3_sphere(vec3<f32>(f32(seed), compress(pos)));
    if (dot(dir, norm(pos)) < 0.0) {
        return -dir;
    } else {
        return dir;
    }
}


fn color(pos: vec4<f32>) -> vec3<f32> {
    switch (i32(pos.w)) {
        case ID_TOP, ID_LIGHT, ID_BOTTOM, ID_FRONT, ID_BACK: { return vec3<f32>(1.0); }
        case ID_LEFT: { return vec3<f32>(1.0, 0.3, 0.0); }
        case ID_RIGHT: { return vec3<f32>(0.3, 1.0, 0.0); }
        case ID_SPHERE: { return vec3<f32>(0.3, 0.3, 1.0); }
        default: { return vec3<f32>(1.0); }
    }
}

////////////////////////////////////////////////////////////////////////////////
// The lowest-level building block:
//  Raytraces to the next object in the scene,
//  returning a vec4 of [end, id]
fn trace(start: vec4<f32>, dir: vec3<f32>) -> vec4<f32> {
    var t: vec4<f32>;

    t = sphere(start.xyz, dir);
    if (t.w != 0.0 && t.w != start.w) {
        return t;
    }
    t = light(start.xyz, dir);
    if (t.w != 0.0 && t.w != start.w) {
        return t;
    }
    t = rear(start.xyz, dir);
    if (t.w != 0.0 && t.w != start.w) {
        return t;
    }
    t = top(start.xyz, dir);
    if (t.w != 0.0 && t.w != start.w) {
        return t;
    }
    t = left(start.xyz, dir);
    if (t.w != 0.0 && t.w != start.w) {
        return t;
    }
    t = right(start.xyz, dir);
    if (t.w != 0.0 && t.w != start.w) {
        return t;
    }
    t = bottom(start.xyz, dir);
    if (t.w != 0.0 && t.w != start.w) {
        return t;
    }
    t = front(start.xyz, dir);
    if (t.w != 0.0 && t.w != start.w) {
        return t;
    }
    return vec4<f32>(0.0);
}

////////////////////////////////////////////////////////////////////////////////

fn bounce_last(pos: vec4<f32>) -> vec3<f32> {
    return color(pos) / 15.0;
}

fn bounce2(pos: vec4<f32>) -> vec3<f32> {
    var out_color = vec3<f32>(0.0);
    let my_color = color(pos);
    for (var i = 0; i < 4; i = i + 1) {
        let dir = rand3_norm(pos, i);
        let next = trace(pos, dir);

        var c: vec3<f32>;
        if (next.w == f32(ID_LIGHT)) {
            c = vec3<f32>(1.0);
        } else if (next.w == 0.0) {
            c = vec3<f32>(0.0);
        } else {
            c = bounce_last(next);
        }
        c = c * dot(norm(next), -dir);
        out_color = out_color + c * my_color;
    }
    return out_color / sqrt(4.0);
}

fn bounce1(pos: vec4<f32>) -> vec3<f32> {
    var out_color = vec3<f32>(0.0);
    let my_color = color(pos);
    for (var i = 0; i < 32; i = i + 1) {
        let dir = rand3_norm(pos, i);
        let next = trace(pos, dir);

        var c: vec3<f32>;
        if (next.w == f32(ID_LIGHT)) {
            c = vec3<f32>(1.0);
        } else if (next.w == 0.0) {
            c = vec3<f32>(0.0);
        } else {
            c = bounce2(next);
        }
        c = c * dot(norm(next), -dir);
        out_color = out_color + c * my_color;
    }
    return out_color / sqrt(32.0);
}


@fragment
fn mainImage(@builtin(position) fragCoord: vec4<f32>) -> @location(0) vec4<f32> {
    let pos_xy = (fragCoord.xy / uniforms.iResolution.xy) * 2.0 - 1.0;

    let start = vec3<f32>(pos_xy, 1.0);
    let dir = normalize(vec3<f32>(pos_xy / 3.0, -1.0));

    let pos = trace(vec4<f32>(start, 0.0), dir);
    if (pos.w == f32(ID_LIGHT)) {
        return vec4<f32>(0.8) + vec4<f32>(vec3<f32>(rand(pos.xz)) / 4.0, 1.0);
    } else {
        return vec4<f32>(bounce1(pos) * 2.0, 1.0);
    }
}
