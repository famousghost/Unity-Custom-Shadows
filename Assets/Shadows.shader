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

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

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
                return o;
            }

            sampler2D _NewShadowMapTexture;

            float4 frag(v2f i) : SV_Target
            {
                float2 screenUv = i.screenPos.xy / i.screenPos.w * 0.5f + 0.5f;
                float closestDepth = tex2D(_NewShadowMapTexture, screenUv);
                float currentDepth = i.screenPos.z;

                float bias = 0.005f;

                float shadow = currentDepth + bias > closestDepth ? 1.0f : 0.2f;
                float4 col = tex2D(_MainTex, i.uv) * shadow;
                return col;
            }
            ENDCG
        }
    }
}