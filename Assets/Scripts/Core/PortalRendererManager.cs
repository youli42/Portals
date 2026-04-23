using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PortalRendererManager : MonoBehaviour
{
    Portal[] portals;

    void OnEnable()
    {
        portals = FindObjectsOfType<Portal>();
        // 注册 SRP 的摄像机渲染前回调，替代 OnPreCull
        RenderPipelineManager.beginCameraRendering += OnBeginCameraRendering;
    }

    void OnDisable()
    {
        // 注销，防止内存泄漏或报错
        RenderPipelineManager.beginCameraRendering -= OnBeginCameraRendering;
    }

    void OnBeginCameraRendering(ScriptableRenderContext context, Camera camera)
    {
        // **必须排除传送门摄像机，只在主摄像机渲染前执行**
        // 否则 RenderSingleCamera 会再次触发此事件，导致无限递归
        if (camera != Camera.main)
        {
            return;
        }

        // 1. 准备阶段
        for (int i = 0; i < portals.Length; i++)
        {
            portals[i].PrePortalRender();
        }

        // 2. 渲染阶段（传入 context）
        for (int i = 0; i < portals.Length; i++)
        {
            portals[i].Render(context);
        }

        // 3. 收尾阶段
        for (int i = 0; i < portals.Length; i++)
        {
            portals[i].PostPortalRender();
        }
    }
}