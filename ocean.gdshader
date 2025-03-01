shader_type spatial;

render_mode unshaded;


uniform float amplitude = 1.5;    // Base amplitude multiplier

uniform float speed = 1.0;        // Base speed multiplier

uniform float frequency = 1.26;   // Base frequency for ~5 m wavelength

uniform float noise_factor = 0.5; // Overall noise intensity

uniform vec3 water_color = vec3(0.0, 0.4, 0.8); // Base dark blue color


// Hash function for pseudo-random numbers from a vec2.

float hash(vec2 p) {

    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);

}


// Basic 2D noise for smooth spatial variation.

float noise(vec2 p) {

    vec2 i = floor(p);

    vec2 f = fract(p);

    vec2 u = f * f * (3.0 - 2.0 * f);

    float a = hash(i);

    float b = hash(i + vec2(1.0, 0.0));

    float c = hash(i + vec2(0.0, 1.0));

    float d = hash(i + vec2(1.0, 1.0));

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;

}


void vertex() {

    // Compute a tiled coordinate based on world position:

    // You can use a modulus-like operation to get a repeating pattern.

    // For instance, to repeat every tile_size meters:

    float tile_size = 500.0;

    // Convert the world-space XZ coordinate into a repeating space:

    vec2 world_coords = VERTEX.xz;

    vec2 tiled_coords = fract(world_coords / tile_size) * tile_size;

    

    // Now use `tiled_coords` instead of VERTEX.xz when computing waves:

    float amp1 = amplitude * (0.8 + 0.4 * hash(vec2(1.0, 123.456)));

    float amp2 = amplitude * (0.8 + 0.4 * hash(vec2(2.0, 123.456)));

    float amp3 = amplitude * (0.8 + 0.4 * hash(vec2(3.0, 123.456)));

    float speed1 = speed * (0.8 + 0.4 * hash(vec2(1.0, 654.321)));

    float speed2 = speed * (0.8 + 0.4 * hash(vec2(2.0, 654.321)));

    float speed3 = speed * (0.8 + 0.4 * hash(vec2(3.0, 654.321)));

    float freq1 = frequency * (0.8 + 0.4 * hash(vec2(1.0, 111.222)));

    float freq2 = frequency * (0.8 + 0.4 * hash(vec2(2.0, 111.222)));

    float freq3 = frequency * (0.8 + 0.4 * hash(vec2(3.0, 111.222)));

    

    // Instead of VERTEX.xz, use tiled_coords here (or combine components appropriately)

    float wave1 = sin(tiled_coords.x * freq1 + TIME * speed1);

    float wave2 = sin(tiled_coords.y * freq2 * 1.1 + TIME * speed2 * 1.2);

    float wave3 = sin((tiled_coords.x + tiled_coords.y) * freq3 * 0.9 + TIME * speed3 * 1.5);

    

    // Combine waves as before.

    VERTEX.y += (wave1 * amp1 + wave2 * amp2 + wave3 * amp3) * 0.3;

}



void fragment() {
    // Transform the vertex into world space.
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Use world_pos.xz to create color variation
    vec2 pos_for_color = world_pos.xz * 0.01; // Scale down to control frequency
    float color_noise = noise(pos_for_color);

    // Create a color based on the noise
    vec3 variation_color = mix(vec3(0.1, 0.3, 0.6), vec3(0.2, 0.5, 0.9), color_noise);

    // Mix the base water color with the variation color
    ALBEDO = mix(water_color, variation_color, 0.5); // Adjust the 0.5 for more or less variation
}