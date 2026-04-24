Shader "Demo/CloudTest_URP"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Emission ("Emission", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque" 
            "Queue" = "Geometry" 
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 200

        Pass
        {
            Name "UniversalForward"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                float2 uv          : TEXCOORD1;
                float3 normalWS    : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _Color;
                half4 _Emission;
                half _Glossiness;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                float3 basePositionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 offset = sin(_Time.x + input.positionOS.xyz + basePositionWS * 0.1) * 0.2;
                float3 animatedPositionOS = input.positionOS.xyz + offset;

                output.positionWS = TransformObjectToWorld(animatedPositionOS);
                output.positionCS = TransformObjectToHClip(animatedPositionOS);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                half3 albedo = baseMap.rgb * _Color.rgb;
                
                half3 ambient = SampleSH(input.normalWS);

                Light mainLight = GetMainLight(TransformWorldToShadowCoord(input.positionWS));
                half3 lightDir = normalize(mainLight.direction);
                half3 normalWS = normalize(input.normalWS);
                
                // 修复：使用跨版本的纯数学方式计算观察方向
                // 摄像机位置减去顶点位置，然后归一化
                half3 viewDirWS = normalize(GetCameraPositionWS() - input.positionWS);

                half NdotL = saturate(dot(normalWS, lightDir));
                half3 diffuse = mainLight.color * NdotL * mainLight.shadowAttenuation;

                float3 halfVector = normalize(lightDir + viewDirWS);
                float NdotH = saturate(dot(normalWS, halfVector));
                
                float shininess = exp2(10.0 * _Glossiness + 1.0);
                half3 specular = mainLight.color * pow(NdotH, shininess) * _Glossiness * mainLight.shadowAttenuation;

                half3 finalColor = albedo * (ambient + diffuse) + specular + _Emission.rgb;
                
                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            HLSLPROGRAM
            #pragma vertex vert_shadow
            #pragma fragment frag_shadow

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // 修复：彻底移除 Shadows.hlsl 的引用，避免 URP 7.x 的宏依赖冲突

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            Varyings vert_shadow(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                float3 basePositionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 offset = sin(_Time.x + input.positionOS.xyz + basePositionWS * 0.1) * 0.2;
                float3 animatedPositionOS = input.positionOS.xyz + offset;
                
                float4 positionCS = TransformObjectToHClip(animatedPositionOS);
                
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                
                output.positionCS = positionCS;
                return output;
            }

            half4 frag_shadow(Varyings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}