shader_type spatial;

uniform float expansion_progress : hint_range(0.0, 1.0) = 0.0;
uniform float max_width_multiplier = 2.0;
uniform vec4 beam_color : source_color = vec4(1.0, 0, 0, 1.0);
uniform float emission_strength = 2.0;

void vertex() {
    // Get the original position
    vec3 original_position = VERTEX;
    
    // Only modify the width (x and y coordinates, assuming z is length)
    // We don't touch the z coordinate so length scaling from code works
    float width_factor = 1.0 + expansion_progress * (max_width_multiplier - 1.0);
    VERTEX.x *= width_factor;
    VERTEX.y *= width_factor;
}

void fragment() {
    // Set the color and emission based on expansion
    ALBEDO = beam_color.rgb;
    EMISSION = beam_color.rgb * emission_strength * (1.0 + expansion_progress);
    
    // Optional: Add some glow variation based on expansion
    float glow_intensity = expansion_progress * 0.5 + 0.5;
    EMISSION *= glow_intensity;
}