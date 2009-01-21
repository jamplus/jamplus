float4x4 wvp : WorldViewProjection;

struct vertexOutput
{
   float4 position : POSITION0;
   float4 color : COLOR;
};

vertexOutput simpleVS(float4 position : POSITION,
                float4 color : COLOR)
{
    vertexOutput OUT;
    OUT.position = mul(position, wvp);
    OUT.color = float4(1.0, 1.0, 0.0, 1.0);
    return OUT;
}

technique simple
{
    pass p0
    {
        VertexShader = compile vs_1_1 simpleVS();
    }
}
