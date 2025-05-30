using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.Interaction.Toolkit.Interactables;
using UnityEngine.XR.Interaction.Toolkit.Interactors;

namespace VRFPSKit
{
    /// <summary>
    /// Shoots a physical bullet projectile, as opposed to say shotgun pellets
    /// </summary>
    public class BulletShooter : MonoBehaviour
    {
        public BallisticProfile ballisticProfile;
        [Space]
        public GameObject bulletPrefab;
        public Transform bulletSpawn;

        /// <summary>
        /// Calls for server to shoot a bullet with specified properties
        /// </summary>
        /// <param name="cartridge">Specifies bullet properties</param>
        public void ShootBullet(Cartridge cartridge, Vector3 bulletPosition, Quaternion bulletRotation)
        {
            GameObject obj = Instantiate(bulletPrefab, bulletPosition, bulletRotation);
            Bullet bullet = obj.GetComponent<Bullet>();

            BulletIgnoreCollision(bullet);
            
            //Track which BulletShooter shot the bullet
            bullet.shooter = this;
            
            //Apply bullet properties
            bullet.bulletType = cartridge.bulletType;
            if (ballisticProfile == null)
                Debug.LogWarning($"BulletShooter on {gameObject.name} does not have a ballistic profile assigned, using bullet default");
            else
                bullet.ballisticProfile = ballisticProfile;
        }

        /// <summary>
        /// Calls to shoot a bullet with specified properties
        /// </summary>
        /// <param name="cartridge">Specifies bullet properties</param>
        /// <param name="bulletSpawnPosition">Client sends bullet spawn position</param>
        /// <param name="bulletSpawnRotation">Client sends bullet spawn rotation</param>
        private void FirearmShootEvent(Cartridge cartridge, Vector3 bulletSpawnPosition, Quaternion bulletSpawnRotation)
        {
            int projectileAmount = 1;
            
            //Prevent null error
            if (ballisticProfile) projectileAmount = ballisticProfile.projectileAmount;
            
            for (int i = 0; i < projectileAmount; i++)
                ShootBullet(cartridge, bulletSpawnPosition, bulletSpawnRotation);
        }
        
        private void Awake()
        {
            //Listen to Firearm's Shoot event (which is when we should spawn a bullet)
            //Also Send bullet spawn orientation on the server
            GetComponentInParent<Firearm>().ShootEvent += cartridge => 
                FirearmShootEvent(cartridge, bulletSpawn.position, bulletSpawn.rotation);
        }

        private void BulletIgnoreCollision(Bullet bullet)
        {
            foreach (var bulletCollider in bullet.GetComponentsInChildren<Collider>())
            {
                foreach (var firearmCollider in GetComponentsInChildren<Collider>())
                    Physics.IgnoreCollision(bulletCollider, firearmCollider);
                
                foreach (var attachmentSocket in GetComponentsInChildren<XRBaseInteractor>())
                    foreach (var attachment in attachmentSocket.interactablesSelected)
                        foreach (var attachmentCollider in attachment.transform.GetComponentsInChildren<Collider>())
                            Physics.IgnoreCollision(bulletCollider, attachmentCollider);
            }
        }

        public Player TryGetOwningPlayer()
        {
            XRGrabInteractable firearmGrabbable = GetComponentInParent<XRGrabInteractable>();
            if (!firearmGrabbable) return null;
            if (!firearmGrabbable.isSelected) return null;
            XRBaseInteractor selector = (XRBaseInteractor)firearmGrabbable.interactorsSelecting[0];
            Player player = selector.GetComponentInParent<Player>();
            if (!player) return null;
            
            return player;
        }

        /// <summary>
        /// Draw a cone that represents the maximum projectile spread angle
        /// </summary>
        private void OnDrawGizmosSelected()
        {
            if (!ballisticProfile) return;
            float gizmosLineLength = 15;
            
            Gizmos.color = Color.red;

            if (ballisticProfile.randomSpreadAngle == 0)
                Gizmos.DrawLine(bulletSpawn.position, bulletSpawn.position + (bulletSpawn.forward*gizmosLineLength));
            else
            {
                //Draw a cone representing the random spread angle
                int lineAmount = 25;
                
                //Divide a circle in to x steps, and then iterate with a fixed angle interval for the whole circle
                for (float radianAngle = 0; radianAngle < Mathf.PI * 2; radianAngle += Mathf.PI * 2 / lineAmount)
                {
                    Quaternion circularOffsetDirection = Quaternion.Euler(Mathf.Sin(radianAngle) * ballisticProfile.randomSpreadAngle,
                        Mathf.Cos(radianAngle) * ballisticProfile.randomSpreadAngle, 0);
                    Vector3 localLineDirection = circularOffsetDirection * Vector3.forward;
                    Vector3 worldLineDirection = bulletSpawn.TransformDirection(localLineDirection);
                    Vector3 lineEndPoint = bulletSpawn.position + worldLineDirection * gizmosLineLength;
                    
                    Gizmos.DrawLine(bulletSpawn.position, lineEndPoint);
                }
            }
        }
    }
}