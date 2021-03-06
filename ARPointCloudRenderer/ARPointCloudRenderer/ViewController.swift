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

class ViewController: UIViewController, ARSCNViewDelegate, UITableViewDataSource, UITableViewDelegate {

    
    // ui vars
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet var loadInfoView: UIView!
    
    @IBOutlet var loadInfoLabel: UILabel!
    
    @IBOutlet var loadInfoProgressbar: UIProgressView!
    
    @IBOutlet var selectPointCloudTableView: UITableView!
    
    @IBOutlet var pointSizeSlider: UISlider!
    
    // local vars
    var currentPointCloud = SCNNode()
    
    var lastNode : SCNNode?
    
    var pointCloudFiles = ["Test", "Test2"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        // show pointcloud selection
        showPointCloudSelectionView()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // show feature points
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // add gesture recognizer
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
        sceneView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(recognizer:))))
        
        let screenEdgeRec = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleScreenEdge(recognizer:)))
        screenEdgeRec.edges = UIRectEdge.left
        sceneView.addGestureRecognizer(screenEdgeRec)
        
        // add events
        pointSizeSlider.addTarget(self, action: #selector(valueChangedOfSlider(slider:)), for: .valueChanged)
    }
    
    func showPointCloudSelectionView()
    {
        let pcs = Bundle.main.paths(forResourcesOfType: "scn", inDirectory: "")
        pointCloudFiles = pcs
        
        self.view.addSubview(self.selectPointCloudTableView)
        self.selectPointCloudTableView.center = self.view.center
        self.selectPointCloudTableView.layer.cornerRadius = 5
        self.selectPointCloudTableView.dataSource = self
    }
    
    func loadPointCloud(fileName : String)
    {
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                self.view.addSubview(self.loadInfoView)
                self.loadInfoView.center = self.view.center
                self.loadInfoView.layer.cornerRadius = 5
                
                self.sceneView.isHidden = true
                self.loadInfoView.isHidden = false
                self.loadInfoLabel.text = "loading \((fileName as NSString).lastPathComponent)..."
            }
            
            measure (name: "Load", {
                let scene = try? SCNScene(url: URL(fileURLWithPath: fileName))
                self.currentPointCloud = scene!.rootNode.childNode(withName: "cloud", recursively: true)!
            })
            
            DispatchQueue.main.async {
                self.loadInfoView.isHidden = true
                self.sceneView.isHidden = false
                self.loadInfoView.removeFromSuperview()
            }
        }
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
    
    func runARScene()
    {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        runARScene()
        sceneView.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
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
        
        guard let node = lastNode else { return }
        
        // removed child nodes
        node.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        
        currentPointCloud.removeFromParentNode()
        node.addChildNode(currentPointCloud)
        
        currentPointCloud.geometry!.elements.forEach { (e : SCNGeometryElement) in
            e.maximumPointScreenSpaceRadius = 5.0
            e.pointSize = 5.0
        }
        
        sceneView.debugOptions = []
    }
    
    @objc func handleScreenEdge(recognizer: UIScreenEdgePanGestureRecognizer) {
        // show settings
        print("showing settings...")
    }
    
    @IBAction func settingsButtonPressed()
    {
       // show chooser
        showPointCloudSelectionView()
    }

    @objc func valueChangedOfSlider(slider: UISlider)
    {
        print(slider.value)
        
        // change pointcloud size
        currentPointCloud.geometry!.elements.forEach { (e : SCNGeometryElement) in
            e.maximumPointScreenSpaceRadius = CGFloat(slider.value)
            e.pointSize = CGFloat(slider.value)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let path = pointCloudFiles[indexPath.row]
        self.selectPointCloudTableView.removeFromSuperview()
        
        // load pointcloud
        loadPointCloud(fileName: path)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pointCloudFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell", for: indexPath)
        let fileName = pointCloudFiles[indexPath.row]
        cell.textLabel?.text = "\((fileName as NSString).lastPathComponent)"
        return cell
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

protocol StateSelector {
    func didSelectState(state: String)
}
