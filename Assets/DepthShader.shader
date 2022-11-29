Shader "Unlit/DepthShader"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Cull Back
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
                float depth : TEXCOORD2;
                float3 viewVector : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.depth = -mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, v.vertex)).z;
                // We want [0,1] linear depth, so that 0.5 is half way between near and far.
                COMPUTE_EYEDEPTH(o.depth);
                o.depth = (o.depth - _ProjectionParams.y) / (_ProjectionParams.z - _ProjectionParams.y);
                o.screenPos = ComputeScreenPos(o.vertex);
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2.0f - 1.0f, 0.0f, -1.0f));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector, 0.0f));
                return o;
            }

            sampler2D _CameraDepthTexture;

            float4 frag(v2f i) : SV_Target
            {
                float2 screenUv = i.screenPos.xy / i.screenPos.w * 0.5f + 0.5f;
                float cameraDepth = LinearEyeDepth(tex2D(_CameraDepthTexture, screenUv).r) * length(i.viewVector);
                float depth = i.screenPos.z / i.screenPos.w;
                return float4(depth, depth, depth, 1.0f);
            }
            ENDCG
        }
    }
}