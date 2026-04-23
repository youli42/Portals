using UnityEngine;
using UnityEditor;

public class URPMaterialConverter
{
    [MenuItem("Tools/Convert Standard Shader to URP Lit")]
    static void ConvertStandardToURPLit()
    {
        string[] guids = AssetDatabase.FindAssets("t:Material");
        foreach (string guid in guids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            Material mat = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (mat != null && mat.shader.name == "Standard")
            {
                mat.shader = Shader.Find("Universal Render Pipeline/Lit");
                Debug.Log($"✅ Converted: {mat.name}");
            }
        }
        AssetDatabase.SaveAssets();
        Debug.Log("🎉 All materials converted to URP/Lit.");
    }
}