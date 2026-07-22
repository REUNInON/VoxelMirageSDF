void RaymarchSDF_float
(
    float3 LocalPos, 
    float3 ViewDir, 
    UnityTexture3D SDFVolume,
    float VoxelRes, 
    float3 BaseColor, 
    float MaxVoxelSize, 
    float ThicknessMult, 
    float BaseThreshold, 
    float RayQuality, 
    float3 Light,
    out float3 OutColor, 
    out float Alpha
)
{
    float3 rayPos = LocalPos;
    float alpha = 0.0;
    float3 color = float3(0, 0, 0);

    const int STEP_COUNT = 200;

    float gridSize = clamp(VoxelRes, 0.005, MaxVoxelSize);
    float thickness = BaseThreshold + (gridSize * ThicknessMult);
    float stepSize = RayQuality / (float)STEP_COUNT; 

    [loop]
    for(int i = 0; i < STEP_COUNT; i++) 
    {
        float3 uvw = rayPos + 0.5; 
        
        if(uvw.x < 0 || uvw.x > 1 || uvw.y < 0 || uvw.y > 1 || uvw.z < 0 || uvw.z > 1) break;

        float3 gridUVW = floor(uvw / gridSize) * gridSize;
        
        float3 snappedUVW = lerp(uvw, gridUVW, 1);

        float sdf = SDFVolume.tex.SampleLevel(SDFVolume.samplerstate, snappedUVW, 0.0).r;

        if(sdf < thickness) 
        {
            alpha = 1.0;
            
            // ===============
            // LIGHTING SYSTEM
            // ===============
            float e = 0.01;
            float nx = SDFVolume.tex.SampleLevel(SDFVolume.samplerstate, snappedUVW + float3(e, 0, 0), 0).r - 
                       SDFVolume.tex.SampleLevel(SDFVolume.samplerstate, snappedUVW - float3(e, 0, 0), 0).r;
            float ny = SDFVolume.tex.SampleLevel(SDFVolume.samplerstate, snappedUVW + float3(0, e, 0), 0).r - 
                       SDFVolume.tex.SampleLevel(SDFVolume.samplerstate, snappedUVW - float3(0, e, 0), 0).r;
            float nz = SDFVolume.tex.SampleLevel(SDFVolume.samplerstate, snappedUVW + float3(0, 0, e), 0).r - 
                       SDFVolume.tex.SampleLevel(SDFVolume.samplerstate, snappedUVW - float3(0, 0, e), 0).r;
            
            float3 normal = normalize(float3(nx, ny, nz));
            float3 lightDir = normalize(Light);
            float ndotl = max(dot(normal, lightDir), 0.1); 
            
            color = BaseColor * ndotl * (1.0 - (float(i) / (float)STEP_COUNT));
            break;
        }

        rayPos -= ViewDir * stepSize; 
    }

    OutColor = color;
    Alpha = alpha;
}