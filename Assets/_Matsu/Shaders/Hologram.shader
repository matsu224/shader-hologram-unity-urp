Shader "Matsu/Hologram"
{
    Properties
    {
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _Color ("Base Color", Color) = (0.25,0.5,0.5,1)
        _Alpha ("Alpha", Range(0, 1)) = 0.7
        _ScanMinBrightness("Scan Min Brightness", Range(0, 1)) = 0.9
        _ScanSpeed("Scan Speed", Float) = 0.1
        _ScanWidth("Scan Width", Range(0.001, 0.1)) = 0.02
        _FresnelPower("Fresnel Power", Range(0.5, 8.0)) = 4.0
        _FresnelStrength("Fresnel Strength", Range(0.0, 5.0)) = 5.0
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                
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
            float _FresnelPower;
            float _FresnelStrength;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float4 tex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                float4 finalColor = tex * _Color;

                //スキャンライン
                //float scanY = IN.uv.y + _Time.y * _ScanSpeed; //UV基準
                float scanY = IN.positionWS.y + _Time.y * _ScanSpeed; //WS基準
                float scanY_repeat = frac(scanY/(_ScanWidth*2)); //fracで少数部分を求める
                float lineMask = step(0.5, scanY_repeat); //step(edge,x)はx<edgeなら0、それ以外なら1になる関数
                float brightness = lerp(_ScanMinBrightness, 1.0, lineMask); //lerpで線形補間、lineMaskから暗い側の明るさと元の明るさに変換
                finalColor.rgb *= brightness;

                //フレネル効果
                float3 normal = normalize(IN.normalWS); //再度正規化する、vert->flagで補間されてしまっているため？
                float3 viewDir = normalize(_WorldSpaceCameraPos - IN.positionWS);
                //float fresnel = 1.0 - saturate(dot(normal, viewDir)); //saturateで0~1に制限
                float fresnel = pow(1.0 - saturate(dot(normal, viewDir)), _FresnelPower); //SampleNPRを参考に輪郭を絞る
                //finalColor.rgb += fresnel; //これだと輪郭が真っ白になってしまう
                finalColor.rgb += finalColor.rgb * fresnel * _FresnelStrength; //元の色合いを保ちながら明るくする //※AIに相談

                //透明度設定
                finalColor.a = _Alpha;

                return finalColor;
            }
            ENDHLSL
        }
    }
}

//関数はwebやAIを使って調査&使用した（コメントで説明がついている箇所）
//その他実装方法のアイデアなどは適宜webサイトなどを参考にした