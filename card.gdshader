shader_type canvas_item;

uniform float gradient_strength : hint_range(0.0, 1.0) = 1.0;
uniform float softness : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    float uv_x = UV.x;
    
    // Gradiente de izquierda a derecha
    float gradient = uv_x;
    
    // Aplicar suavizado si se desea
    if (softness > 0.0) {
        gradient = smoothstep(0.0, 1.0, gradient);
    }
    
    gradient *= gradient_strength;
    
    // Modificar el canal alpha como máscara
    COLOR.a *= gradient;
}