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
                float3 viewPos : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NewShadowMapTexture;
            float4 _NewShadowMapTexture_ST;

            sampler2D _CameraDepthTexture;

            float4x4 _LightViewMatrix;
            float4x4 _LightProjectionMatrix;
            float3 _CameraForward;
            float3 _FogColor;
            float3 _SunColor;

            float _StepSize;

            int _NumOfSamples;
            int _FrameNumber;
            float _LightShaftsStrength;
            float _FogStrength;
            float _FogDistortionDensity;
            float _FogDensityStrength;



            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewPos = mul(UNITY_MATRIX_V, o.wPos).xyz;
                o.vert = v.vertex;

                float2 uv = o.screenPos.xy / o.screenPos.w;

                return o;
            }



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

            float random(in float3 uv)
            {
                return frac(sin(dot(uv, float3(13.5345f, 33.534534f, 43.5343f))) * 4542628.545f);
            }


            float ssmooth(float x)
            {
                return x * x * (3.0f - 2.0f * x);
            }

            float3 modUv(float3 uv, in float freq)
            {
                return float3(uv.x % freq, uv.y % freq, uv.z % freq);
            }

            float simpleNoise(in float3 uv, in float freq)
            {
                float3 iuv = floor(uv * freq);
                float3 fuv = frac(uv * freq);

                float x = random(modUv(iuv + float3(0.0f, 0.0f, 0.0f), freq));
                float x1 = random(modUv(iuv + float3(1.0f, 0.0f, 0.0f), freq));

                float y = random(modUv(iuv + float3(0.0f, 1.0f, 0.0f), freq));
                float y1 = random(modUv(iuv + float3(1.0f, 1.0f, 0.0f), freq));

                float x2 = random(modUv(iuv + float3(0.0f, 0.0f, 1.0f), freq));
                float x3 = random(modUv(iuv + float3(1.0f, 0.0f, 1.0f), freq));

                float y2 = random(modUv(iuv + float3(0.0f, 1.0f, 1.0f), freq));
                float y3 = random(modUv(iuv + float3(1.0f, 1.0f, 1.0f), freq));



                float a = lerp(x, x1, ssmooth(fuv.x));

                float b = lerp(y, y1, ssmooth(fuv.x));

                float c = lerp(x2, x3, ssmooth(fuv.x));

                float d = lerp(y2, y3, ssmooth(fuv.x));

                float ab = lerp(a, b, ssmooth(fuv.y));

                float cd = lerp(c, d, ssmooth(fuv.y));


                return lerp(ab, cd, ssmooth(fuv.z));
            }

            float fbm(in float3 uv, in float density)
            {
                float sum = 0.00;
                float amp = 0.7;

                for (int i = 0; i < 6; ++i)
                {
                    sum += simpleNoise(uv, density) * amp;
                    uv += uv * 1.2;
                    amp *= 0.4;
                }

                return sum;
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

                float fogPerlinDistortion = 0.0f;
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
                    
                    float3 pos = p * _FogDensityStrength + float3(0.0f, 0.0f, _Time.y * 0.005f);
                    fogPerlinDistortion += exp(-fbm(pos + fbm(pos, _FogDistortionDensity), _FogDistortionDensity));

                }

                percentage /= _NumOfSamples;

                float3 col = tex2D(_MainTex, i.uv).rgb;

                float fogAmount = (1.0f - exp(-cameraDepth * _FogStrength)) ;
                float sunAmount = max(dot(rayDirection, _WorldSpaceLightPos0.xyz), 0.0f);

                float3 fogColor = lerp(_FogColor, _SunColor, pow(sunAmount, 4.0f));

                col = lerp(col, fogColor, fogAmount* fogPerlinDistortion / _NumOfSamples);
                col = lerp(col, 0.0f, pow(percentage, _LightShaftsStrength) * saturate(fogAmount) * sunAmount * smoothstep(0.0f, 0.5f, dot(_WorldSpaceLightPos0.xyz, float3(0.0f, 1.0f, 0.0f))));
                return float4(col, 1.0f);
            }
    ENDCG
}
    }
}