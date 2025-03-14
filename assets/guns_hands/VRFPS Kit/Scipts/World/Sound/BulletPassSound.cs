using UnityEngine;

namespace VRFPSKit
{
    [RequireComponent(typeof(AudioSource))]
    public class BulletPassSound : MonoBehaviour
    {
        public float minimumVelocity = SpeedOfSound.Value;
        [Tooltip("Can be used to make whiz sounds be played earlier")] 
        public float bulletOffset = 0;
        
        private Vector3 _lastListenerPositionLocal;
        private Vector3 _lastFramePosition;
        private static AudioListener _cachedListener;
        
        // Update is called once per frame
        void FixedUpdate()
        {
            AudioListener listener = GetListener();
            if (listener == null) return;

            // Get the listener position in local space
            Vector3 listenerPositionLocal = transform.InverseTransformPoint(_cachedListener.transform.position);
            
            //Check if just passed listener
            if(listenerPositionLocal.z - bulletOffset < 0 && _lastListenerPositionLocal.z - bulletOffset > 0)
                if (EstimateVelocity() > minimumVelocity)
                {
                    GetComponent<AudioSource>().PlayDelayedBySpeedOfSound();
                    
                    //Deparent the audio source so sound doesn't keep traveling
                    transform.parent = null; 
                    Destroy(gameObject, 5);
                }
                    
            _lastListenerPositionLocal = listenerPositionLocal;
            _lastFramePosition = transform.position;
        }
        
        /// <summary>
        /// We need to estimate velocity by measuring how far we've traveled since last frame as we can't
        /// Use RigidBody.velocity in multiplayer
        /// </summary>
        /// <returns></returns>
        /// TODO WARNING can be null if listener is null
        private float EstimateVelocity() => Vector3.Distance(_lastFramePosition, transform.position) / Time.fixedDeltaTime;
        
        private static AudioListener GetListener()
        {
            if(_cachedListener == null) _cachedListener = Object.FindAnyObjectByType<AudioListener>();

            return _cachedListener;
        }
    }
}
