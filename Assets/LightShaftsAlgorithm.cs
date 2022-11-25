namespace MC.Godrays
{
    using UnityEngine;

    public class LightShaftsAlgorithm : MonoBehaviour
    {
        #region Inspector Variables
        [SerializeField] private CreateLightCamera _CreateLightCamera;
        [SerializeField] private Material _LightShaftsRaymarchingMaterial;
        [SerializeField] private int _NumOfSamples;
        [Range(1.0f, 5.0f)]
        [SerializeField] private float _LightShaftsStrength;

        #endregion Inspector Variables

        #region Unity Methods
        private void Start()
        {
            Camera.main.depthTextureMode = DepthTextureMode.Depth;
        }

        private void Update()
        {
            _LightShaftsRaymarchingMaterial.SetTexture(_ShadowMapTextureId, _CreateLightCamera._LightShaftsTexture);
            var cam = _CreateLightCamera._LightShaftsCamera;
            _LightShaftsRaymarchingMaterial.SetMatrix(_LightViewMatrixId, cam.worldToCameraMatrix);
            _LightShaftsRaymarchingMaterial.SetMatrix(_lightProjectionMatrixId, GL.GetGPUProjectionMatrix(cam.projectionMatrix, false));
            _LightShaftsRaymarchingMaterial.SetVector(_CameraForwardId, _CreateLightCamera.transform.forward);
            _LightShaftsRaymarchingMaterial.SetInt(_NumOfSamplesId, _NumOfSamples);
            _LightShaftsRaymarchingMaterial.SetInt(_FrameNumberId, Time.frameCount);
            _LightShaftsRaymarchingMaterial.SetFloat(_LightShaftsStrengthId, 1.0f / _LightShaftsStrength);
            
        }

        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {

            Graphics.Blit(source, destination, _LightShaftsRaymarchingMaterial);
        }

        #endregion Unity Methods

        #region Private Variables
        private static readonly int _ShadowMapTextureId = Shader.PropertyToID("_NewShadowMapTexture");
        private static readonly int _LightViewMatrixId = Shader.PropertyToID("_LightViewMatrix");
        private static readonly int _lightProjectionMatrixId = Shader.PropertyToID("_LightProjectionMatrix");
        private static readonly int _CameraForwardId = Shader.PropertyToID("_CameraForward");
        private static readonly int _NumOfSamplesId = Shader.PropertyToID("_NumOfSamples");
        private static readonly int _FarPlaneId = Shader.PropertyToID("_FarPlane");
        private static readonly int _FrameNumberId = Shader.PropertyToID("_FrameNumber");
        private static readonly int _LightShaftsStrengthId = Shader.PropertyToID("_LightShaftsStrength");

        #endregion Private Variables
    }
}