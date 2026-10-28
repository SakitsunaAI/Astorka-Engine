import Foundation

public struct MetalShaders {
    public static let sourceCode = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexIn {
        float2 position;
        float2 uv;
        float4 color;
    };

    struct VertexOut {
        float4 position [[position]];
        float2 uv;
        float4 color;
    };

    struct FrameUniforms {
        float2 viewportSize;
        float time;
        int postProcessMode; // 0: Normal, 1: CRT Retro, 2: Chromatic Aberration, 3: Holographic / Glow
    };

    vertex VertexOut vertex_main(
        constant VertexIn *vertices [[buffer(0)]],
        constant FrameUniforms &uniforms [[buffer(1)]],
        uint vertexID [[vertex_id]])
    {
        VertexOut out;
        float2 pos = vertices[vertexID].position;
        // Convert screen coordinates to (-1, 1) NDC space
        float2 ndc = (pos / (uniforms.viewportSize * 0.5)) - float2(1.0, 1.0);
        ndc.y = -ndc.y; // Flip Metal Y-axis

        out.position = float4(ndc, 0.0, 1.0);
        out.uv = vertices[vertexID].uv;
        out.color = vertices[vertexID].color;
        return out;
    }

    fragment float4 fragment_main(
        VertexOut in [[stage_in]],
        texture2d<float> colorTexture [[texture(0)]],
        sampler textureSampler [[sampler(0)]],
        constant FrameUniforms &uniforms [[buffer(1)]])
    {
        float4 texColor = colorTexture.sample(textureSampler, in.uv);
        float4 baseColor = texColor * in.color;

        // Post-Processing Effects
        if (uniforms.postProcessMode == 1) {
            // CRT Scanlines and curvature
            float scanline = sin(in.uv.y * uniforms.viewportSize.y * 1.5) * 0.08;
            baseColor.rgb -= scanline;
        } else if (uniforms.postProcessMode == 2) {
            // Chromatic Aberration (card impacts / explosions)
            float2 offset = float2(0.003, 0.0);
            float r = colorTexture.sample(textureSampler, in.uv + offset).r;
            float g = texColor.g;
            float b = colorTexture.sample(textureSampler, in.uv - offset).b;
            baseColor.rgb = float3(r, g, b) * in.color.rgb;
        } else if (uniforms.postProcessMode == 3) {
            // Holographic Card Foil Effect (Balatro style)
            float wave = sin(in.uv.x * 12.0 + in.uv.y * 8.0 + uniforms.time * 4.0) * 0.5 + 0.5;
            float3 holo = float3(0.5 + 0.5 * sin(wave * 6.28), 0.5 + 0.5 * sin(wave * 6.28 + 2.0), 0.5 + 0.5 * sin(wave * 6.28 + 4.0));
            baseColor.rgb += holo * 0.25;
        }

        return baseColor;
    }
    """
}
