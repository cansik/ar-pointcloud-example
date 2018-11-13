//
//  ViewController.swift
//  ARPointCloudRenderer
//
//  Created by Florian Bruggisser on 13.11.18.
//  Copyright © 2018 Florian Bruggisser. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    let pc = PointCloud()
    var currentPointCloud = SCNNode()
    
    var lastNode : SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // show feature points
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // allows the user to manipulate the camera
        //sceneView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
        sceneView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(recognizer:))))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor.transparentWhite
        
        var planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.name = "plane"
        
        update(&planeNode, withGeometry: plane, type: .static)
        
        lastNode = node
        node.addChildNode(planeNode)
    }
    
    func update(_ node: inout SCNNode, withGeometry geometry: SCNGeometry, type: SCNPhysicsBodyType) {
        let shape = SCNPhysicsShape(geometry: geometry, options: nil)
        let physicsBody = SCNPhysicsBody(type: type, shape: shape)
        node.physicsBody = physicsBody
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        pc.load(file: "crossroad-filtered.ply")
        //pc.load(file: "forest-3-highres_filtered.ply")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    @objc func handlePinch(recognizer: UIPinchGestureRecognizer)
    {
        let sceneView = recognizer.view as! ARSCNView
        
        if recognizer.state == .began || recognizer.state == .changed {
            let scale = Float(recognizer.scale)
            
            let newscalex = scale * self.currentPointCloud.scale.x
            let newscaley = scale * self.currentPointCloud.scale.y
            let newscalez = scale * self.currentPointCloud.scale.z
            
            self.currentPointCloud.scale = SCNVector3(newscalex, newscaley, newscalez)
            recognizer.scale = 1.0
        }
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer){
        let sceneView = recognizer.view as! ARSCNView
        
        guard let node = lastNode as? SCNNode else { return }
        
        currentPointCloud.removeFromParentNode()
        currentPointCloud = pc.getNode(useColor: true)
        currentPointCloud.scale = SCNVector3(2.0, 2.0, 2.0)
        node.addChildNode(currentPointCloud)
        
        // todo: now working
        let touchLocation = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(touchLocation, options: [:])
        if !hitResults.isEmpty {
            print("found \(hitResults.count)")
            let tappedNode = hitResults.first?.node
            
            guard let node = tappedNode as? SCNNode else { return }
            print("trans \(node.name): w:\(node.worldPosition) l:\(node.position) s:\(node.simdPosition)")
        }
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentWhite: UIColor {
        return UIColor.white.withAlphaComponent(0.20)
    }
    
    open class var transparentBlue: UIColor {
        return UIColor.blue.withAlphaComponent(0.30)
    }
}
