Shader "Unlit/LightShaftsRayMarching"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _NewShadowMapTexture("Shadow Map", 2D) = "white"{}
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

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            #define NUM_SAMPLES 128
            #define NUM_SAMPLES_RCP 0.0078125
            #define TAU 0.0001
            #define PHI 10000000.0

            #define PI_RCP 0.318309886183

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD1;
                float4 wPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NewShadowMapTexture;
            float4 _NewShadowMapTexture_ST;

            float4x4 _LightViewMatrix;
            float4x4 _LightProjectionMatrix;
            float3 _CameraForward;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float4 executeRaymarching(float3 VLI, float3 rayPositionLVS, float3 invViewDirLVS, float stepSize, float l, float2 screenUv)
            {
                float3 newRayPositionLVS = rayPositionLVS + stepSize * invViewDirLVS;

                float phi = 90.0f;

                float4 rayPosClipSpace = mul(UNITY_MATRIX_P, float4(rayPositionLVS, 1.0f));

                float2 rayPosUv = rayPosClipSpace.xy / rayPosClipSpace.w * 0.5f + 0.5f;

                float shadowTerm = rayPosClipSpace.z < tex2D(_NewShadowMapTexture, rayPosUv).r;

                float d = length(rayPositionLVS);
                float dRcp = rcp(d);

                float intens = TAU * (shadowTerm * (PHI * 0.25 * PI_RCP) * dRcp * dRcp) * exp(-d * TAU) * exp(-l * TAU) * stepSize;

                return float4(intens, newRayPositionLVS.xyz);
            }

            float4 frag(v2f i) : SV_Target
            {
                float raymarchDistanceLimit = 999999.0f;

            /*[...]*/

            float4 posLVS = mul(_LightProjectionMatrix, mul(_LightViewMatrix, i.wPos));
            float4 cameraPosLVS = mul(_LightProjectionMatrix, mul(_LightViewMatrix, float4(_WorldSpaceCameraPos.xyz, 1.0f)));
            float raymarchDistance = trunc(clamp(length(cameraPosLVS.xyz - posLVS.xyz), 0.0f, raymarchDistanceLimit));

            float stepSize = raymarchDistance * NUM_SAMPLES_RCP;

            float3 rayPositionLVS = posLVS;

            float3 VLI = 0.0f;

            float3 invViewDir = -_CameraForward;
            float p = raymarchDistance;
            float2 screenUv = i.screenPos.xy / i.screenPos.w * 0.5f + 0.5f;
            int k = 0;
            for (int j = 0; j < NUM_SAMPLES; ++j)
            {
                float4 result = executeRaymarching(VLI, rayPositionLVS, invViewDir, stepSize, p, screenUv);
                p -= stepSize;
                VLI += float3(result.x, result.x, result.x);
                rayPositionLVS += result.yzw;
            }

            float3 col = tex2D(_MainTex, i.uv).rgb * _LightColor0.rgb * VLI;
            return float4(col, 1.0f);
        }
    ENDCG
}
    }
}