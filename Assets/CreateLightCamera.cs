namespace MC.Godrays
{
    using UnityEngine;
    using UnityEngine.Rendering;

    public class CreateLightCamera : MonoBehaviour
    {
        #region Public Variables
        public Camera _LightShaftsCamera;
        public RenderTexture _LightShaftsTexture;

        #endregion Public Variables

        #region Inspector Variables
        [SerializeField] private GameObject _Environment;
        [SerializeField] private Camera _MainCamera;
        [SerializeField] private GameObject _LightCamera;

        [SerializeField] private Light _DirectionalLight;
        [SerializeField] private Material _ShadowMaterial;
        [SerializeField] private Material _DepthMaterial;

        [SerializeField] private float _FarPlane = 100.0f;
        [SerializeField] private float _Size = 1000.0f;

        [SerializeField] private Shader _LightShaftsShader;

        [SerializeField] private int _Resolution = 512;

        #endregion Inspector Variables

        #region Unity Methods

        private void Start()
        {
            _LightShaftsShader = Shader.Find("Unlit/DepthShader");

            _LightShaftsTexture = new RenderTexture(_Resolution, _Resolution, 24, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear)
            {
                enableRandomWrite = true
            };
            _LightShaftsTexture.Create();
            CreateCameraInLightSpace();
            _LightShaftsCamera.depthTextureMode = DepthTextureMode.Depth;

            _DepthBufferForLightCamera = new CommandBuffer
            {
                name = "Depth buffer for light camera"
            };

            _LightShaftsCamera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, _DepthBufferForLightCamera);
        }

        private void Update()
        {
            _LightShaftsCamera.transform.position = new Vector3(_MainCamera.transform.position.x, 0.0f, _MainCamera.transform.position.z);

            _LightShaftsCamera.transform.forward = _DirectionalLight.transform.forward;
            _LightShaftsCamera.transform.position -= _DirectionalLight.transform.forward * 0.5f * _FarPlane;
            _DepthBufferForLightCamera.Clear();

            _DepthBufferForLightCamera.SetRenderTarget(_LightShaftsTexture);
            _DepthBufferForLightCamera.ClearRenderTarget(true, true, Color.black);
            foreach (var renderer in _Environment.GetComponentsInChildren<Renderer>())
            {
                if (renderer.enabled)
                {
                    _DepthBufferForLightCamera.DrawRenderer(renderer, _DepthMaterial);
                }
            }

            _LightShaftsCamera.Render();

            _ShadowMaterial.SetTexture(_ShadowMapTextureId, _LightShaftsTexture);
            _ShadowMaterial.SetMatrix(_LightViewMatrixId, _LightShaftsCamera.worldToCameraMatrix);
            _ShadowMaterial.SetMatrix(_lightProjectionMatrixId, _LightShaftsCamera.projectionMatrix);
            _ShadowMaterial.SetFloat(_ShadowMapSizeId, _Resolution);
        }

        #endregion Unity Methods

        #region Private Variables
        private static readonly int _ShadowMapTextureId = Shader.PropertyToID("_NewShadowMapTexture");
        private static readonly int _LightViewMatrixId = Shader.PropertyToID("_LightViewMatrix");
        private static readonly int _lightProjectionMatrixId = Shader.PropertyToID("_LightProjectionMatrix");
        private static readonly int _ShadowMapSizeId = Shader.PropertyToID("_ShadowMapSize");

        private CommandBuffer _DepthBufferForLightCamera;

        #endregion Private Variables

        #region Private Methods

        private void CreateCameraInLightSpace()
        {
            _LightCamera = new GameObject("LightShaftsCamera");

            var cam = _LightCamera.AddComponent<Camera>();
            var renderLightShafts = _LightCamera.AddComponent<RenderLightShafts>();

            renderLightShafts.LightShaftsMaterial = new Material(_LightShaftsShader);

            cam.CopyFrom(_MainCamera);

            cam.orthographic = true;

            cam.transform.position = _DirectionalLight.transform.position;
            cam.transform.rotation = _DirectionalLight.transform.rotation;

            cam.farClipPlane = _FarPlane;
            cam.nearClipPlane = 0.01f;

            cam.orthographicSize = _Size * 0.5f;

            cam.aspect = 1.0f;
            cam.enabled = false;

            _LightShaftsCamera = cam;
        }

        #endregion Private Methods
    }
}