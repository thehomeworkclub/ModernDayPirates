using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Serialization;

namespace VRFPSKit
{
    [RequireComponent(typeof(Damageable))]
    public class DamageableInvisibleOnDeath : MonoBehaviour
    {
        private Damageable _damageable;
        private Quaternion _defaultRotation;

        // Start is called before the first frame update
        private void Start()
        {
            _damageable = GetComponent<Damageable>();
        }

        // Update is called once per frame
        void Update()
        {
            foreach(var renderer in GetComponentsInChildren<MeshRenderer>())
                //Set visibility on clients based on whether damageable is destroyed
                renderer.enabled = (_damageable.health > 0);
        }
    }
}