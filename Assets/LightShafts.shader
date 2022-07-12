Shader "Unlit/LightShafts"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _NumSteps("Number of steps", Int) = 1
        _DepthStrength("Depth Strength", Float) = 1.0
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            LOD 100

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #define TAU 0.0001
                #define PHI 10000000.0
                #define PI_RCP 0.318309886
                #include "UnityCG.cginc"
                #include "UnityLightingCommon.cginc"

                struct appdata
                {
                    float4 vertex : POSITION;
                };

                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    float4 screenPos : TEXCOORD4;
                };

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.screenPos = ComputeScreenPos(o.vertex);
                    return o;
                }

                int _NumSteps;
                float _DepthStrength;

                void executeRaymarching(inout float3 rayPosition, inout float3 VLI, float3 invViewDir, float stepSize, float l)
                {
                    rayPosition += stepSize * invViewDir;

                    float d = length(rayPosition);
                    float dRcp = rcp(d);

                    float3 intens = TAU * (PHI * 0.25f * PI_RCP * dRcp * dRcp) * exp(-d * TAU) * exp(-l * TAU) * stepSize;

                    VLI += intens;
                }

                sampler2D _CameraDepthTexture;

                float4 frag(v2f i) : SV_Target
                {
                    /*const float raymarchDistanceLimit = 999999.0f;
                    const float sampleSize = 1.0f / _NumSteps;
                    float3 cameraVS = mul(UNITY_MATRIX_V, float4(_WorldSpaceCameraPos.xyz, 1.0f)).xyz;
                    float raymarchDistance = trunc(clamp(length(cameraVS - i.vPos.xyz), 0.0f, raymarchDistanceLimit));
                    float3 invViewDir = normalize(cameraVS - i.vPos.xyz);

                    float stepSize = raymarchDistance * sampleSize;

                    float3 rayPosition = i.vPos.xyz;

                    float3 VLI = 0.0f;

                    for (float l = raymarchDistance; l > stepSize; l -= stepSize)
                    {
                        executeRaymarching(rayPosition, VLI, invViewDir, stepSize, l);
                    }*/

                    float depth = tex2D(_CameraDepthTexture, i.screenPos.xy / i.screenPos.w) * _DepthStrength;
                    float4 col = float4(depth, depth, depth, 1.0f);
                    return col;
                }
                ENDCG
            }
        }
}