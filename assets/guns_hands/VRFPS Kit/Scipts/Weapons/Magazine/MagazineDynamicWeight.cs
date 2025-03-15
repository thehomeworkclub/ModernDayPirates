using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace VRFPSKit
{
    [RequireComponent(typeof(Rigidbody), typeof(Magazine))]
    public class MagazineDynamicWeight : MonoBehaviour
    {
        [Header("Enter weight of magazine when empty in RigidBody component")]
        [Space]
        [Tooltip("Enter the weight of each round")]
        public float roundWeight;
        
        private float _emptyWeight;
        
        private Rigidbody _rigidbody;
        private Magazine _magazine;
        
        void Awake()
        {
            _rigidbody = GetComponent<Rigidbody>();
            _magazine = GetComponent<Magazine>();
            
            _emptyWeight = _rigidbody.mass;
        }

        // Update is called once per frame
        void Update()
        {
            _rigidbody.mass = _emptyWeight + roundWeight * _magazine.cartridges.Count;
        }
    }
}
