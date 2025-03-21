using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.XR.Interaction.Toolkit;
using UnityEngine.XR.Interaction.Toolkit.Interactables;
using UnityEngine.XR.Interaction.Toolkit.Interactors;

namespace VRFPSKit.Input
{
    /// <summary>
    /// Struct that lets us store one input action per hand, and later
    /// get the action that corresponds to the hand that is holding an object
    /// </summary>
    [Serializable]
    public struct XRHeldInputAction
    {
        public InputActionReference leftHandAction;
        public InputActionReference rightHandAction;

        /// <summary>
        /// Get the input action that corresponds to the hand that is holding an object
        /// </summary>
        /// <param name="heldObject">The held interactable that you want input on</param>
        /// <returns></returns>
        public InputAction GetActionForPrimaryHand(XRBaseInteractable heldObject) => GetActionForInteractorIndex(heldObject, 0);
        
        /// <summary>
        /// Get the input action that corresponds to the secondary hand that is holding an object
        /// </summary>
        /// <param name="heldObject">The held interactable that you want input on</param>
        /// <returns></returns>
        public InputAction GetActionForSecondaryHand(XRBaseInteractable heldObject) => GetActionForInteractorIndex(heldObject, 1);
        
        
        /// <summary>
        /// Get the input action that corresponds to the hand that is holding an object
        /// </summary>
        /// <param name="heldObject">The held interactable that you want input on</param>
        /// <param name="interactorIndex">Index of the interactor you want input from</param>
        /// <returns></returns>
        public InputAction GetActionForInteractorIndex(XRBaseInteractable heldObject, int interactorIndex)
        {
            if (interactorIndex >= heldObject.interactorsSelecting.Count) return null;
            if (heldObject.interactorsSelecting[interactorIndex] is not XRDirectInteractor hand) return null;

            //Make sure controls are enabled
            if(!rightHandAction.asset.enabled)
                rightHandAction.asset.Enable();
            if(!leftHandAction.asset.enabled)
                leftHandAction.asset.Enable();
            
            switch (hand.handedness)
            {
                case InteractorHandedness.Left:
                    return leftHandAction.action;
                case InteractorHandedness.Right:
                    return rightHandAction.action;
                default:
                    Debug.LogWarning($"XRDirectInteractor.handedness is not set on '{hand.gameObject.name}', XRHeldInputAction can't decide which input to use");
                    return null;
            }
        }
    }
}