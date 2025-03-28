using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Serialization;
using VRFPSKit;
using Object = UnityEngine.Object;

namespace VRFPSKit
{
    /// <summary>
    /// Handles behaviour for the explosion prefab
    /// </summary>
    public class Explosion : MonoBehaviour
    {
        public LayerMask blockingLayers;
        public float killRadius = 4;
        public float damageRadius = 5;
        [FormerlySerializedAs("explosionRadius")] [Space]
        public float physicsRadius = 10;
        public float physicsForce = 5000;
        public float physicsUpwardsModifier = 1;
        

        // Start is called before the first frame update
        public void Start()
        {
            //Explode immediately
            ApplyExplosionDamage();
            ApplyExplosionPhysics();

            //Schedule explosion removal, make sure sound & Particles have time to play
            Invoke(nameof(DestroyObject), 10);
        }

        private void ApplyExplosionDamage()
        {
            List<IDamageReciever> damageables = GetAllDamageableInsideRadius();
            List<IDamageReciever> damageablesWithLineOfSight = LineOfSightFilter(damageables);
            
            //Calculate damage for every Damageable component
            foreach (var damageable in damageablesWithLineOfSight)
            {
                float distanceToCenter = Vector3.Distance(damageable.transform.position, transform.position);
                float damageToApply = CalculateDamage(distanceToCenter);

                damageable.TakeDamage(damageToApply);
            }
        }
        
        public void ApplyExplosionPhysics()
        {
            // Find all colliders within the explosion radius
            Collider[] colliders = Physics.OverlapSphere(transform.position, physicsRadius);
            List<Rigidbody> rigidbodies = new ();
    
            foreach (Collider hit in colliders)
                // Check if the object has a Rigidbody
                if(hit.GetComponentInParent<Rigidbody>() is Rigidbody rb) 
                    rigidbodies.Add(rb);
        
            foreach (Rigidbody rb in rigidbodies)
                // Apply explosion force
                rb.AddExplosionForce(physicsForce, transform.position, physicsRadius, physicsUpwardsModifier);
        }
        

        /// <summary>
        /// Calculates the damage that should be applied based on distance
        /// </summary>
        /// <param name="distance">The distance to the center</param>
        /// <returns>Damage amount</returns>
        private float CalculateDamage(float distance)
        {
            if (distance <= killRadius)
                return 100;
            if (distance > damageRadius)
                return 0;

            //Calculate linear damage falloff after the kill radius
            float distanceFromOuterRadius = damageRadius - distance;
            float damageZoneFalloff01 = distanceFromOuterRadius / (damageRadius - killRadius);

            return damageZoneFalloff01 * 100;
        }
        
        /// <summary>
        /// Returns every object with a Damageable inside of thee radius
        /// </summary>
        /// <returns>List of all Damageables</returns>
        private List<IDamageReciever> GetAllDamageableInsideRadius()
        {
            Collider[] collidersInSphere = Physics.OverlapSphere(transform.position, damageRadius);
            List<IDamageReciever> damageablesInSphere = new();

            foreach (var collider in collidersInSphere)
            {
                IDamageReciever damageable = collider.GetComponentInParent<IDamageReciever>();

                if (damageable == null) continue;
                if (damageablesInSphere.Contains(damageable)) continue;

                damageablesInSphere.Add(damageable);
            }

            return damageablesInSphere;
        }

        /// <summary>
        /// Filters a list of Damageables and removes every entry that
        /// doesn't have a line of sight to the center of the explosion
        /// </summary>
        /// <param name="allDamageables">List to filter</param>
        /// <returns>Filtered list</returns>
        private List<IDamageReciever> LineOfSightFilter(List<IDamageReciever> allDamageables)
        {
            List<IDamageReciever> damageablesWithLineOfSight = new();

            foreach (var damageable in allDamageables)
            {
                float distanceToDamageable = Vector3.Distance(damageable.transform.position, transform.position);
                Vector3 directionOfDamageable = (damageable.transform.position - transform.position).normalized;

                //If sight line is blocked by a collider that doesn't belong to the damageable, don't keep it
                if (Physics.Raycast(transform.position,
                        directionOfDamageable,
                        out var blockingHit,
                        distanceToDamageable,
                        blockingLayers)) //Invert the layer mask with the ~ operator, so we ignore all layers that aren't included in blockingLayers
                {
                    Debug.DrawRay(transform.position, directionOfDamageable * blockingHit.distance, Color.yellow, 3);
                    
                    //As long as we weren't blocked by a child of the damageable, don't keep it
                    if (blockingHit.collider.GetComponentInParent<IDamageReciever>() != damageable) continue;
                }
                    
                Debug.DrawRay(transform.position, directionOfDamageable * distanceToDamageable, Color.red, 3);
                damageablesWithLineOfSight.Add(damageable);
            }

            return damageablesWithLineOfSight;
        }
        
        private void OnDrawGizmos()
        {
            //Draw damage sphere shapes
            Gizmos.color = new Color(1, 0, 0, .3f);
            Gizmos.DrawSphere(transform.position, killRadius);

            Gizmos.color = new Color(1, 0, 0);
            Gizmos.DrawWireSphere(transform.position, damageRadius);
        }
    }
}