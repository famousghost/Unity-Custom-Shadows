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
                float4 vert : TEXCOORD3;
                float3 viewVector : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NewShadowMapTexture;
            float4 _NewShadowMapTexture_ST;

            sampler2D _CameraDepthTexture;

            float4x4 _LightViewMatrix;
            float4x4 _LightProjectionMatrix;
            float3 _CameraForward;

            float _StepSize;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                o.vert = v.vertex;
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector, 0));
                return o;
            }

            int _NumOfSamples;

            float4 frag(v2f i) : SV_Target
            {
                float2 screenUv = i.screenPos.xy / i.screenPos.w;

                float3 rayOrigin = _WorldSpaceCameraPos.xyz;
                float3 rayDirection = normalize(i.viewVector);
                float cameraDepth = LinearEyeDepth(tex2D(_CameraDepthTexture, screenUv).r) * length(i.viewVector);

                float stepSize = cameraDepth / _NumOfSamples;

                float percentage = 0.0f;
                float depth = 0.0f;
                for (int j = 0; j < _NumOfSamples; ++j)
                {
                    float3 p = rayOrigin + rayDirection * depth;
                    float4 viewPos = mul(_LightViewMatrix, float4(p, 1.0f));
                    float4 posLVS = mul(_LightProjectionMatrix, viewPos);

                    float2 lightScreenPos = posLVS.xy / posLVS.w * 0.5f + 0.5f;
                    float shadowMapDepth = tex2D(_NewShadowMapTexture, lightScreenPos).r;
                    float currentDepth = posLVS.z / posLVS.w;
                    if (currentDepth < shadowMapDepth)
                    {
                        percentage += 1.0f;
                    }
                    depth += stepSize;
                }

                percentage /= NUM_SAMPLES;

                float3 col = lerp(tex2D(_MainTex, i.uv).rgb, 0.0f, pow(percentage, 0.2f));
                return float4(col, 1.0f);
            }
    ENDCG
}
    }
}