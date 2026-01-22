// https://www.shadertoy.com/view/XsXSWS
// no licence

fn hash(p: vec2<f32>) -> vec2<f32> {
	var p_var = p;
	p_var = vec2<f32>(dot(p_var, vec2<f32>(127.1, 311.7)), dot(p_var, vec2<f32>(269.5, 183.3)));
	return -1. + 2. * fract(sin(p_var) * 43758.547);
} 

fn noise(p: vec2<f32>) -> f32 {
	let K1: f32 = 0.36602542;
	let K2: f32 = 0.21132487;
	let i: vec2<f32> = floor(p + (p.x + p.y) * K1);
	var a: vec2<f32> = p - i + (i.x + i.y) * K2;
	var o: vec2<f32>; 
    if (a.x > a.y) { o = vec2<f32>(1., 0.); } else { o = vec2<f32>(0., 1.); };
	let b: vec2<f32> = a - o + K2;
	var c: vec2<f32> = a - 1. + 2. * K2;
	let h: vec3<f32> = max(0.5 - vec3<f32>(dot(a, a), dot(b, b), dot(c, c)), vec3<f32>(0.));
	var n: vec3<f32> = h * h * h * h * vec3<f32>(dot(a, hash(i + 0.)), dot(b, hash(i + o)), dot(c, hash(i + 1.)));
	return dot(n, vec3<f32>(70.));
} 

fn fbm(uv_in: vec2<f32>) -> f32 {
	var f: f32;
    var uv = uv_in;
	let m: mat2x2<f32> = mat2x2<f32>(1.6, 1.2, -1.2, 1.6);
	f = 0.5 * noise(uv);
	uv = m * uv;
	f = f + (0.25 * noise(uv));
	uv = m * uv;
	f = f + (0.125 * noise(uv));
	uv = m * uv;
	f = f + (0.0625 * noise(uv));
	uv = m * uv;
	f = 0.5 + 0.5 * f;
	return f;
} 

@vertex
fn vs_main(
    @builtin(vertex_index) in_vertex_index: u32
) -> @builtin(position) vec4<f32> {
    var p = vec2f(0.0, 0.0);
    if (in_vertex_index == 0u) {
        p = vec2f(-0.5, -0.5);
    } else if (in_vertex_index == 1u) {
        p = vec2f(0.5, -0.5);
    } else {
        p = vec2f(0.0, 0.5);
    }
    return vec4f(p, 0.0, 1.0);
}

@fragment
fn fs_main(
    @builtin(position) clip_position: vec4<f32>,
) -> @location(0) vec4f {
    // let R: vec2<f32> = uni.iResolution.xy;
    // let y_inverted_location = vec2<i32>(i32(clip_postion.x), i32(R.y) - i32(clip_postion.y));
    // let location = vec2<i32>(i32(clip_postion.x), i32(clip_postion.y));

    // var fragColor: vec4<f32>;
    // var fragCoord = vec2<f32>(f32(location.x), f32(location.y) );
    // let uv: vec2<f32> = fragCoord.xy / uni.iResolution.xy;
    // var q: vec2<f32> = uv;
    // q.x = q.x * (5.);
    // q.y = q.y * (2.);
    // let strength: f32 = floor(q.x + 1.);
    // let T3: f32 = max(3., 1.25 * strength) * uni.iTime;
    // q.x = (q.x % 1.) - 0.5;
    // q.y = q.y - (0.25);
    // let n: f32 = fbm(strength * q - vec2<f32>(0., T3));
    // let c: f32 = 1. - 16. * pow(max(0., length(q * vec2<f32>(1.8 + q.y * 1.5, 0.75)) - n * max(0., q.y + 0.25)), 1.2);
    // var c1: f32 = n * c * (1.5 - pow(2.5 * uv.y, 4.));
    // c1 = clamp(c1, 0., 1.);
    // let col: vec3<f32> = vec3<f32>(1.5 * c1, 1.5 * c1 * c1 * c1, c1 * c1 * c1 * c1 * c1 * c1);
    // let a: f32 = c * (1. - pow(uv.y, 3.));
    // fragColor = vec4<f32>(mix(vec3<f32>(0.), col, a), 1.);
    // return fragColor;

    var noi: f32 = noise(clip_position.xy);
    return vec4<f32>(noi, noi / 2, 0.0, 1.);
}
