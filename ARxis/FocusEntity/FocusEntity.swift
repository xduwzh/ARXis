//
//  FocusEntity.swift
//  FocusEntity
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

import Foundation
import RealityKit
#if canImport(RealityFoundation)
import RealityFoundation
import SwiftUI
#endif

#if os(macOS) || targetEnvironment(simulator)
#warning("FocusEntity: This package is only fully available with physical iOS devices")
#endif

#if canImport(ARKit)
import ARKit
#endif
import Combine

public protocol HasFocusEntity: Entity {}

public extension HasFocusEntity {
    var focus: FocusEntityComponent {
        get { self.components[FocusEntityComponent.self] ?? .classic }
        set { self.components[FocusEntityComponent.self] = newValue }
    }
    var isOpen: Bool {
        get { self.focus.isOpen }
        set { self.focus.isOpen = newValue }
    }
    internal var segments: [FocusEntity.Segment] {
        get { self.focus.segments }
        set { self.focus.segments = newValue }
    }
    #if canImport(ARKit)
    var allowedRaycast: ARRaycastQuery.Target {
        get { self.focus.allowedRaycast }
        set { self.focus.allowedRaycast = newValue }
    }
    #endif
}

public protocol FocusEntityDelegate: AnyObject {
    /// Called when the FocusEntity is now in world space
    func toTrackingState()

    /// Called when the FocusEntity is tracking the camera
    func toInitializingState()

    /// When the tracking state of the FocusEntity updates. This will be called every update frame.
    /// - Parameters:
    ///   - focusEntity: FocusEntity object whose tracking state has changed.
    ///   - trackingState: New tracking state of the focus entity.
    ///   - oldState: Old tracking state of the focus entity.
    func focusEntity(
        _ focusEntity: FocusEntity,
        trackingUpdated trackingState: FocusEntity.State,
        oldState: FocusEntity.State
    )

    /// When the plane this focus entity is tracking changes. If the focus entity moves around within one plane anchor there will be no calls.
    /// - Parameters:
    ///   - focusEntity: FocusEntity object whose anchor has changed.
    ///   - planeChanged: New anchor the focus entity is tracked to.
    ///   - oldPlane: Previous anchor the focus entity is tracked to.
    func focusEntity(
        _ focusEntity: FocusEntity,
        planeChanged: ARPlaneAnchor?,
        oldPlane: ARPlaneAnchor?
    )
}

public extension FocusEntityDelegate {
    func toTrackingState() {}
    func toInitializingState() {}
    func focusEntity(
        _ focusEntity: FocusEntity, trackingUpdated trackingState: FocusEntity.State, oldState: FocusEntity.State
    ) {}
    func focusEntity(_ focusEntity: FocusEntity, planeChanged: ARPlaneAnchor?, oldPlane: ARPlaneAnchor?) {}
}

/**
 An `Entity` which is used to provide uses with visual cues about the status of ARKit world tracking.
 */
open class FocusEntity: Entity, HasAnchoring, HasFocusEntity {

    internal weak var arView: ARView?

    /// For moving the FocusEntity to a whole new ARView
    /// - Parameter view: The destination `ARView`
    public func moveTo(view: ARView) {
        let wasUpdating = self.isAutoUpdating
        self.setAutoUpdate(to: false)
        self.arView = view
        view.scene.addAnchor(self)
        if wasUpdating {
            self.setAutoUpdate(to: true)
        }
    }

    /// Destroy this FocusEntity and its references to any ARViews
    /// Without calling this, your ARView could stay in memory.
    public func destroy() {
        self.setAutoUpdate(to: false)
        self.delegate = nil
        self.arView = nil
        for child in children {
            child.removeFromParent()
        }
        self.removeFromParent()
    }

    private var updateCancellable: Cancellable?
    public private(set) var isAutoUpdating: Bool = false

    /// Auto update the focus entity using `SceneEvents.Update`.
    /// - Parameter autoUpdate: Should update the entity or not.
    public func setAutoUpdate(to autoUpdate: Bool) {
        guard autoUpdate != self.isAutoUpdating,
              !(autoUpdate && self.arView == nil)
        else { return }
        self.updateCancellable?.cancel()
        if autoUpdate {
            #if canImport(ARKit)
            self.updateCancellable = self.arView?.scene.subscribe(
                to: SceneEvents.Update.self, self.updateFocusEntity
            )
            #endif
        }
        self.isAutoUpdating = autoUpdate
    }
    public weak var delegate: FocusEntityDelegate?

    // MARK: - Types
    public enum State: Equatable {
        case initializing
        #if canImport(ARKit)
        case tracking(raycastResult: ARRaycastResult, camera: ARCamera?)
        #endif
    }

    // MARK: - Properties

    /// The most recent position of the focus square based on the current state.
    var lastPosition: SIMD3<Float>? {
        switch state {
        case .initializing: return nil
        #if canImport(ARKit)
        case .tracking(let raycastResult, _): return raycastResult.worldTransform.translation
        #endif
        }
    }

    #if canImport(ARKit)
    fileprivate func entityOffPlane(_ raycastResult: ARRaycastResult, _ camera: ARCamera?) {
        self.onPlane = false
        displayOffPlane(for: raycastResult)
    }
    #endif

    /// Current state of ``FocusEntity``.
    public var state: State = .initializing {
        didSet {
            guard state != oldValue else { return }

            switch state {
            case .initializing:
                if oldValue != .initializing {
                    displayAsBillboard()
                    self.delegate?.toInitializingState()
                }
            #if canImport(ARKit)
            case let .tracking(raycastResult, camera):
                let stateChanged = oldValue == .initializing
                if stateChanged && self.anchor != nil {
                    self.anchoring = AnchoringComponent(.world(transform: Transform.identity.matrix))
                }
                let planeAnchor = raycastResult.anchor as? ARPlaneAnchor
                if let planeAnchor = planeAnchor {
                    entityOnPlane(for: raycastResult, planeAnchor: planeAnchor)
                } else {
                    entityOffPlane(raycastResult, camera)
                }
                defer { currentPlaneAnchor = planeAnchor }
                if stateChanged {
                    self.delegate?.toTrackingState()
                }
            #endif
            }
            self.delegate?.focusEntity(self, trackingUpdated: state, oldState: oldValue)
        }
    }

    /// Whether FocusEntity is on a plane or not.
    public internal(set) var onPlane: Bool = false
    /// Indicates if the square is currently being animated.
    public internal(set) var isAnimating = false
    /// Indicates if the square is currently changing its alignment.
    public internal(set) var isChangingAlignment = false

    /// A camera anchor used for placing the focus entity in front of the camera.
    internal var cameraAnchor: AnchorEntity!

    #if canImport(ARKit)
    /// The focus square's current alignment.
    internal var currentAlignment: ARPlaneAnchor.Alignment?

    /// The current plane anchor if the focus square is on a plane.
    public internal(set) var currentPlaneAnchor: ARPlaneAnchor? {
        didSet {
            if (oldValue == nil && self.currentPlaneAnchor == nil) || (currentPlaneAnchor == oldValue) {
                return
            }
            self.delegate?.focusEntity(self, planeChanged: currentPlaneAnchor, oldPlane: oldValue)
        }
    }

    /// The focus square's most recent alignments.
    internal var recentFocusEntityAlignments: [ARPlaneAnchor.Alignment] = []

    /// Previously visited plane anchors.
    internal var anchorsOfVisitedPlanes: Set<ARAnchor> = []
    #endif

    /// The focus square's most recent positions.
    internal var recentFocusEntityPositions: [SIMD3<Float>] = []

    /// The primary node that controls the position of other `FocusEntity` nodes.
    internal let positioningEntity = Entity()

    internal var fillPlane: ModelEntity?

    public var scaleEntityBasedOnDistance = true {
        didSet {
            if self.scaleEntityBasedOnDistance == false {
                self.scale = .one
            }
        }
    }

    // MARK: - Initialization

    /// Create a new ``FocusEntity`` instance.
    /// - Parameters:
    ///   - arView: ARView containing the scene where the FocusEntity should be added.
    ///   - style: Style of the ``FocusEntity``.
    public convenience init(on arView: ARView, style: FocusEntityComponent.Style) {
        self.init(on: arView, focus: FocusEntityComponent(style: style))
    }

    /// Create a new ``FocusEntity`` instance using the full ``FocusEntityComponent`` object.
    /// - Parameters:
    ///   - arView: ARView containing the scene where the FocusEntity should be added.
    ///   - focus: Main component for the ``FocusEntity``
    public required init(on arView: ARView, focus: FocusEntityComponent) {
        self.arView = arView
        super.init()
        self.focus = focus
        self.name = "FocusEntity"
        self.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        self.addChild(self.positioningEntity)

        cameraAnchor = AnchorEntity(.camera)
        arView.scene.addAnchor(cameraAnchor)

        // Start the focus square as a billboard.
        displayAsBillboard()
        self.delegate?.toInitializingState()
        arView.scene.addAnchor(self)
        self.setAutoUpdate(to: true)
        switch self.focus.style {
        case .colored(_, _, _, let mesh):
            let fillPlane = ModelEntity(mesh: mesh)
            self.positioningEntity.addChild(fillPlane)
            self.fillPlane = fillPlane
            self.coloredStateChanged()
        case .classic:
            guard let classicStyle = self.focus.classicStyle
            else { return }
            self.setupClassic(classicStyle)
        }
    }

    required public init() {
        fatalError("init() has not been implemented")
    }

    // MARK: - Appearance

    /// Hides the focus square.
    func hide() {
        self.isEnabled = false
    }

    /// Displays the focus square parallel to the camera plane.
    private func displayAsBillboard() {
        self.onPlane = false
        #if canImport(ARKit)
        self.currentAlignment = .none
        #endif
        stateChangedSetup()
    }

    /// Places the focus entity in front of the camera instead of on a plane.
    private func putInFrontOfCamera() {
        // Works better than arView.ray()
        let newPosition = cameraAnchor.convert(position: [0, 0, -1], to: nil)
        recentFocusEntityPositions.append(newPosition)
        updatePosition()
        // --//
        // Make focus entity face the camera with a smooth animation.
        var newRotation = arView?.cameraTransform.rotation ?? simd_quatf()
        newRotation *= simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        performAlignmentAnimation(to: newRotation)
    }

    #if canImport(ARKit)
    /// Called when a surface has been detected.
    private func displayOffPlane(for raycastResult: ARRaycastResult) {
        self.stateChangedSetup()
        let position = raycastResult.worldTransform.translation
        if self.currentAlignment != .none {
            // It is ready to move over to a new surface.
            recentFocusEntityPositions.append(position)
            performAlignmentAnimation(to: raycastResult.worldTransform.orientation)
        } else {
            putInFrontOfCamera()
        }
        updateTransform(raycastResult: raycastResult)
    }

    /// Called when a plane has been detected.
    private func entityOnPlane(
        for raycastResult: ARRaycastResult, planeAnchor: ARPlaneAnchor
    ) {
        self.onPlane = true
        self.stateChangedSetup(newPlane: !anchorsOfVisitedPlanes.contains(planeAnchor))
        anchorsOfVisitedPlanes.insert(planeAnchor)
        let position = raycastResult.worldTransform.translation
        if self.currentAlignment != .none {
            // It is ready to move over to a new surface.
            recentFocusEntityPositions.append(position)
        } else {
            putInFrontOfCamera()
        }
        updateTransform(raycastResult: raycastResult)
    }
    #endif

    /// Called whenever the state of the focus entity changes
    ///
    /// - Parameter newPlane: If the entity is directly on a plane, is it a new plane to track
    public func stateChanged(newPlane: Bool = false) {
        switch self.focus.style {
        case .colored:
            self.coloredStateChanged()
        case .classic:
            if self.onPlane {
                self.onPlaneAnimation(newPlane: newPlane)
            } else { self.offPlaneAniation() }
        }
    }

    private func stateChangedSetup(newPlane: Bool = false) {
        guard !isAnimating else { return }
        self.stateChanged(newPlane: newPlane)
    }

    #if canImport(ARKit)
    public func updateFocusEntity(event: SceneEvents.Update? = nil) {
        // Perform hit testing only when ARKit tracking is in a good state.
        guard let camera = self.arView?.session.currentFrame?.camera,
              case .normal = camera.trackingState,
              let result = self.smartRaycast()
        else {
            // We should place the focus entity in front of the camera instead of on a plane.
            putInFrontOfCamera()
            self.state = .initializing
            return
        }

        self.state = .tracking(raycastResult: result, camera: camera)
    }
    #endif
}
