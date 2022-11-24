// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/Shadows"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque"}
        LOD 100
            Cull Back
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float4 screenPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4x4 _LightViewMatrix;
            float4x4 _LightProjectionMatrix;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = mul(_LightProjectionMatrix, mul(_LightViewMatrix, mul(unity_ObjectToWorld, v.vertex)));
                o.normal = normalize(mul(unity_ObjectToWorld, v.normal));
                return o;
            }

            sampler2D _NewShadowMapTexture;
            float4 _NewShadowMapTexture_ST;

            float _ShadowMapSize;

            float4 frag(v2f i) : SV_Target
            {
                float2 screenUv = i.screenPos.xy / i.screenPos.w * 0.5f + 0.5f;
                float shadow = 0.0f;

                float currentDepth = i.screenPos.z / i.screenPos.w;

                float cosTheta = clamp(dot(normalize(_WorldSpaceLightPos0.xyz), i.normal), 0.0f, 1.0f);

                float bias = 0.0005f * tan(acos(cosTheta));
                bias = clamp(bias, 0.0f, 0.01f);

                for (int x = -1; x <= 1; ++x)
                {
                    for (int y = -1; y <= 1; ++y)
                    {
                        float closestDepth = tex2D(_NewShadowMapTexture, screenUv + float2(x, y) * 1.0f / _ShadowMapSize).r;
                        shadow += (currentDepth - bias) > closestDepth ? 1.0f : 0.2f;
                    }
                }

                shadow /= 9.0f;

                float4 col = tex2D(_MainTex, i.uv) * shadow;
                return col;
            }
            ENDCG
        }
    }
}