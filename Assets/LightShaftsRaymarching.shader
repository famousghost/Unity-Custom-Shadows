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

                float2 uv = o.screenPos.xy / o.screenPos.w;

                return o;
            }

            int _NumOfSamples;
            int _FrameNumber;
            float _LightShaftsStrength;

            float InterleavedGradientNoise(float2 pixel, int frame)
            {
                pixel += (float(frame) * 5.588238f);
                return frac(52.9829189f * frac(0.06711056f * float(pixel.x) + 0.00583715f * float(pixel.y)));
            }

            float screenClampToBorder(in float2 screenUv)
            {
                const float x = step(0.01f, screenUv.x) * (1.0f - step(0.999f, screenUv.x));
                const float y = step(0.01f, screenUv.y) * (1.0f - step(0.999f, screenUv.y));

                return saturate(x * y);
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 screenUv = i.screenPos.xy / i.screenPos.w;

                float3 rayOrigin = _WorldSpaceCameraPos.xyz;

                float3 viewVector = mul(unity_CameraInvProjection, float4(i.uv * 2.0f - 1.0f, 0.0f, -1.0f));
                viewVector = mul(unity_CameraToWorld, float4(viewVector, 0.0f));

                float3 rayDirection = normalize(viewVector);
                float cameraDepth = LinearEyeDepth(tex2D(_CameraDepthTexture, screenUv).r) * length(viewVector);

                float percentage = 0.0f;
                float depth = 0.0f;

                float randomOffset = InterleavedGradientNoise(screenUv * _ScreenParams.xy, _FrameNumber);

                for (int j = 0; j < _NumOfSamples; ++j)
                {
                    float3 p = rayOrigin + rayDirection * cameraDepth * ((float(j) + randomOffset) / _NumOfSamples);

                    float4 posLVS = mul(_LightProjectionMatrix, mul(_LightViewMatrix, float4(p, 1.0f)));

                    float2 lightScreenPos = posLVS.xy / posLVS.w * 0.5f + 0.5f;
                    float shadowMapDepth = tex2D(_NewShadowMapTexture, lightScreenPos).r * screenClampToBorder(lightScreenPos);
                    float currentDepth = posLVS.z / posLVS.w;
                    if (currentDepth < shadowMapDepth && shadowMapDepth > 0.0f)
                    {
                        percentage += 1.0f;
                    }
                }

                percentage /= _NumOfSamples;

                float3 col = lerp(tex2D(_MainTex, i.uv).rgb, 0.0f, pow(percentage, _LightShaftsStrength));
                return float4(col, 1.0f);
            }
    ENDCG
}
    }
}