
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace VRFPSKit
{
    public class CollisionSound : MonoBehaviour
    {
        //By default, we only want to play collision sounds when colliding with the environment ("Default" layer)
        public LayerMask collisionMask = 1 << 0;
        public AudioSource source;

        private void OnCollisionEnter(Collision collision)
        {
            //Only play sound if collisionMask contains collider layer
            if (!DoesMaskContainLayer(collision.gameObject.layer, collisionMask)) return;
            if (!source) return;
            float collisionSpeed = collision.impulse.magnitude / GetComponent<Rigidbody>().mass;
            if (collisionSpeed < .5f) return;
            
            //TODO are collisions triggered on clients? 
            source.Play();
        }

        bool DoesMaskContainLayer(int layer, LayerMask layerMask)
        {
            return (layerMask.value & (1 << layer)) != 0;
        }
    }
}