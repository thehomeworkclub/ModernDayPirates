using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.Interaction.Toolkit.Interactables;
using UnityEngine.XR.Interaction.Toolkit.Interactors;
using Random = UnityEngine.Random;

namespace VRFPSKit
{
    /// <summary>
    /// TODO
    /// </summary>
    [RequireComponent(typeof(Firearm), typeof(Rigidbody))]
    public class FirearmPhysicsRecoil : MonoBehaviour
    {
        public Vector3 recoil;
        public Vector3 angularRecoil;
        [Space]
        public Vector3 randomRecoil;
        public Vector3 randomAngularRecoil;
        [Space]
        public float resetFactor = 3f;
        public float angularResetFactor = 4f;
        
        private Vector3 _currentRecoilForce;
        private Vector3 _currentAngularRecoil;

        private void Shoot(Cartridge cartridge)
        {
			_currentRecoilForce += recoil + RandomVector3(randomRecoil);
            _currentAngularRecoil += angularRecoil + RandomVector3(randomAngularRecoil);
        }

        private void FixedUpdate()
        {
            if (!GetComponent<XRGrabInteractable>().isSelected)
            {
                _currentRecoilForce = Vector3.zero;
                _currentAngularRecoil = Vector3.zero;
                return;
            }
            //TODO action recoil
            //TODO comments
            //Recoil forces need to be applied continuously as "XRGrabInteractable" velocity tracking will override it
            Vector3 localRecoilForce = transform.TransformDirection(_currentRecoilForce);
            if (localRecoilForce.magnitude > 0.05f)
                GetComponent<Rigidbody>().AddForce(localRecoilForce, ForceMode.VelocityChange);
            
            Vector3 localAngularRecoil = transform.TransformDirection(_currentAngularRecoil);
            if (localAngularRecoil.magnitude > 0.05f) 
                GetComponent<Rigidbody>().AddTorque(localAngularRecoil, ForceMode.VelocityChange);

            _currentRecoilForce *= Mathf.Max(1f - (resetFactor * Time.fixedDeltaTime), 0);
            _currentAngularRecoil *= Mathf.Max(1f - (angularResetFactor * Time.fixedDeltaTime), 0);
            //TODO breaks after dropping weapon and grabbing again
            //TODO apply normal force based on relative hand positions (are attached? where are holding?)
        }

        // Start is called before the first frame update
        void Awake()
        {
            GetComponent<Firearm>().ShootEvent += Shoot;
        }
        
        private Vector3 RandomVector3(Vector3 bounds) => new (Random.Range(-bounds.x, bounds.x), Random.Range(-bounds.y, bounds.y), Random.Range(-bounds.z, bounds.z));
    }
}