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

        [SerializeField] private float _FogStrength;
        [SerializeField] private float _FogDistortionDensity;
        [SerializeField] private float _FogDensityStrength;


        [SerializeField] private Color _FogColor;
        [SerializeField] private Color _SunColor;
        #endregion Inspector Variables

        #region Unity Methods
        private void Start()
        {
        }

        private void Update()
        {
        }

        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            _LightShaftsRaymarchingMaterial.SetTexture(_ShadowMapTextureId, _CreateLightCamera._LightShaftsTexture);
            var cam = _CreateLightCamera._LightShaftsCamera;
            _LightShaftsRaymarchingMaterial.SetMatrix(_LightViewMatrixId, cam.worldToCameraMatrix);
            _LightShaftsRaymarchingMaterial.SetMatrix(_lightProjectionMatrixId, GL.GetGPUProjectionMatrix(cam.projectionMatrix, false));
            _LightShaftsRaymarchingMaterial.SetVector(_CameraForwardId, _CreateLightCamera.transform.forward);
            _LightShaftsRaymarchingMaterial.SetInt(_NumOfSamplesId, _NumOfSamples);
            _LightShaftsRaymarchingMaterial.SetInt(_FrameNumberId, Time.frameCount);
            _LightShaftsRaymarchingMaterial.SetColor(_FogColorId, _FogColor);
            _LightShaftsRaymarchingMaterial.SetFloat(_LightShaftsStrengthId, 1.0f / _LightShaftsStrength);
            _LightShaftsRaymarchingMaterial.SetFloat(_FogStrengthId, 1.0f / _FogStrength);
            _LightShaftsRaymarchingMaterial.SetColor(_SunColorId, _SunColor);
            _LightShaftsRaymarchingMaterial.SetFloat(_FogDistortionDensityId, _FogDistortionDensity);
            _LightShaftsRaymarchingMaterial.SetFloat(_FogDensityStrengthId, _FogDensityStrength);
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
        private static readonly int _FogColorId = Shader.PropertyToID("_FogColor");
        private static readonly int _FogStrengthId = Shader.PropertyToID("_FogStrength");
        private static readonly int _SunColorId = Shader.PropertyToID("_SunColor");
        private static readonly int _FogDistortionDensityId = Shader.PropertyToID("_FogDistortionDensity");
        private static readonly int _FogDensityStrengthId = Shader.PropertyToID("_FogDensityStrength");
        #endregion Private Variables
    }
}