Shader "Matsu/Hologram"
{
    Properties
    {
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _Color ("Base Color", Color) = (0.25,0.5,0.5,1)
        _Alpha ("Alpha", Range(0, 1)) = 0.8
        _ScanMinBrightness("Scan Min Brightness", Range(0, 1)) = 0.9
        _ScanSpeed("Scan Speed", Float) = 0.01
        _ScanWidth("Scan Width", Range(0.001, 0.1)) = 0.01
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" }

        Pass
        {
            Name "Hologram"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha //出力色のAlpha値を使って背景色と通常の半透明合成を行う、という意味
            ZWrite Off //半透明描画のためこのオブジェクトの深度をDepth Bufferへ書き込まない、という意味

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float4 _BaseMap_ST;
            float _Alpha;
            float _ScanMinBrightness;
            float _ScanSpeed;
            float _ScanWidth;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float4 tex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                float4 finalColor = tex * _Color;

                float scanY = IN.uv.y + _Time.y * _ScanSpeed;
                float scanY_repeat = frac(scanY/(_ScanWidth*2)); //fracで少数部分を求める
                float lineMask = step(0.5, scanY_repeat); //step(edge,x)はx<edgeなら0、それ以外なら1になる関数、
                float brightness = lerp(_ScanMinBrightness, 1.0, lineMask); //暗い側の明るさと元の明るさを切り替える
                finalColor.rgb *= brightness;

                finalColor.a = _Alpha;
                return finalColor;
            }
            ENDHLSL
        }
    }
}
