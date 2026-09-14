Shader "Matsu/Hologram"
{
    Properties
    {
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _Color ("Base Color", Color) = (0.25,0.5,0.5,1)
        _Alpha ("Alpha", Range(0, 1)) = 0.7
        _ScanBrightness("Scan Brightness", Range(0, 2.0)) = 0.9
        _ScanSpeed("Scan Speed", Float) = 0.1
        _ScanWidth("Scan Width", Range(0.001, 0.1)) = 0.02
        _ScanBrightness2("Scan Brightness 2", Range(0, 2.0)) = 1.1
        _ScanSpeed2("Scan Speed 2", Float) = 0.6
        _ScanWidth2("Scan Width 2", Range(0.001, 2.0)) = 0.1
        _FresnelPower("Fresnel Power", Range(0.5, 8.0)) = 4.0
        _FresnelStrength("Fresnel Strength", Range(0.0, 5.0)) = 5.0
        [Header(Vertex Glitch)]
        _GlitchBandHeight("Glitch Band Height", Range(0.001, 2.0)) = 0.05
        _GlitchInterval("Glitch Interval (Seconds)", Range(0.01, 10.0)) = 2.0
        _GlitchDuration("Glitch Duration (Seconds)", Range(0.0, 1.0)) = 0.2
        _GlitchStrength("Glitch Strength", Range(0.0, 0.1)) = 0.02 //大きくしすぎると三角形が引き伸ばされて不自然になる？ため小さい値を推奨（微小な揺れ程度）
        _GlitchUpdateRate("Glitch Updates Per Second", Range(1, 60)) = 10
        _GlitchThreshold("Glitch Band Threshold", Range(0, 1)) = 0.9
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
            float _ScanBrightness;
            float _ScanSpeed;
            float _ScanWidth;
            float _ScanBrightness2;
            float _ScanSpeed2;
            float _ScanWidth2;
            float _FresnelPower;
            float _FresnelStrength;
            float _GlitchBandHeight;
            float _GlitchInterval;
            float _GlitchDuration;
            float _GlitchStrength;
            float _GlitchUpdateRate;
            float _GlitchThreshold;
            CBUFFER_END

            float2 random2( float2 p ) { //MetaballNoise.hlslから引用
                return frac(sin(float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3))))*43758.5453);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                //ノイズ(揺れ) //WebサイトやTreeDeformを参考に、詰まったところをAIに相談しつつ作成 //※AIに相談
                float band = floor(IN.positionOS.y / _GlitchBandHeight); //帯の番号
                float cycle = floor(_Time.y / _GlitchInterval); //現在が何周期目か
                float active = 1.0 - step(_GlitchDuration, _Time.y - cycle * _GlitchInterval); //各周期の開始から指定した発生時間だけ有効 //実装をシンプルにするためノイズの発生は固定周期・秒数
                float selected = step(_GlitchThreshold, random2(float2(band, cycle)).x); //ノイズが発生する帯の選択（周期ごと）
                float tick = floor(_Time.y * _GlitchUpdateRate);
                float shake = random2(float2(band, tick)).y * 2.0 - 1.0; //-1~1の範囲のノイズを加える
                float offset = shake * _GlitchStrength * active * selected;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionHCS.x += offset * OUT.positionHCS.w; //wを掛けて透視除算後のずれ幅を一定にする必要がある //※AIに相談

                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float4 tex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                float4 finalColor = tex * _Color;

                //スキャンライン1
                float scanY = IN.positionWS.y - _Time.y * _ScanSpeed; //WS基準 //UV基準のIN.uv.yだと不都合が起こる場合がある
                float scanY_repeat = frac(scanY/(_ScanWidth*2)); //fracで少数部分を求める
                float lineMask = step(0.5, scanY_repeat); //step(edge,x)はx<edgeなら0、それ以外なら1になる関数
                float brightness = lerp(_ScanBrightness, 1.0, lineMask); //lerpで線形補間、lineMaskから暗い側の明るさと元の明るさに変換
                finalColor.rgb *= brightness;
                //スキャンライン2
                float scanY2 = IN.positionWS.y - _Time.y * _ScanSpeed2;
                float scanY_repeat2 = frac(scanY2/(_ScanWidth2*2));
                float lineMask2 = step(0.5, scanY_repeat2);
                float brightness2 = lerp(_ScanBrightness2, 1.0, lineMask2);
                finalColor.rgb *= brightness2;

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

//関数はwebやAIを使って調査&使用した（コメントで説明がついている組み込み関数など）
//その他実装方法のアイデアなどは適宜webサイトなどを参考にした
