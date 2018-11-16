//
//  PointCloud.swift
//  MixedReality
//
//  Created by Evgeniy Upenik on 21.05.17.
//  Copyright © 2017 Evgeniy Upenik. All rights reserved.
//

import SceneKit

@objc class PointCloud: NSObject {
    
    var n : Int = 0
    var pointCloud : Array<PointCloudVertex> = []
    
    let progressEvent = Event<Float>()
    
    override init() {
        super.init()
    }
    
    public func load(file : String)
    {
        self.n = 0
        var x, y, z : Double
        (x,y,z) = (0,0,0)
        
        var r, g, b : Int
        (r, g, b) = (0, 0, 0)
        
        progressEvent.raise(data: 0.0)
        
        // Open file
        if let path = Bundle.main.path(forResource: file, ofType: "txt") {
            do {
                let data = try String(contentsOfFile: path, encoding: .ascii)
                var myStrings = data.components(separatedBy: "\n")
                
                // Read header
                while !myStrings.isEmpty {
                    let line = myStrings.removeFirst()
                    if line.hasPrefix("element vertex ") {
                        n = Int(line.components(separatedBy: " ")[2])!
                        continue
                    }
                    if line.hasPrefix("end_header") {
                        break
                    }
                }
                
                pointCloud = Array(repeating: PointCloudVertex(x: 0,y: 0,z: 0,r: 0,g: 0,b: 0), count: n)
                
                // Read data
                for i in 0...(self.n-1) {
                    let line = myStrings[i]
                    let elements = line.components(separatedBy: " ")
                    x = Double(elements[0])!
                    y = Double(elements[1])!
                    z = Double(elements[2])!
                    
                    r = Int(elements[3])!
                    g = Int(elements[4])!
                    b = Int(elements[5])!
                    
                    pointCloud[i].x = Float(x)
                    pointCloud[i].y = Float(y)
                    pointCloud[i].z = Float(z)
                    
                    pointCloud[i].r = Float(r) / 255.0
                    pointCloud[i].g = Float(g) / 255.0
                    pointCloud[i].b = Float(b) / 255.0
                    
                    let progress = Float(i) / Float(n)
                    progressEvent.raise(data: progress)
                }
                
                NSLog("Point cloud data loaded: %d points",n)
                progressEvent.raise(data: 1.0)
            } catch {
                print(error)
            }
        }
    }
    
    public func getNode(useColor : Bool = false) -> SCNNode {
        let vertices = pointCloud.map { (v : PointCloudVertex) -> PointCloudVertex in
            return useColor ? PointCloudVertex(x: v.x, y: v.y, z: v.z, r: v.r, g: v.g, b: v.b)
                : PointCloudVertex(x: v.x, y: v.y, z: v.z, r: 1.0, g: 1.0, b: 1.0)
        }
        
        let node = buildNode(points: vertices)
        NSLog(String(describing: node))
        return node
    }
    
    private func buildNode(points: [PointCloudVertex]) -> SCNNode {
        let vertexData = NSData(
            bytes: points,
            length: MemoryLayout<PointCloudVertex>.size * points.count
        )
        let positionSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.vertex,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let colorSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.color,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: MemoryLayout<Float>.size * 3,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let elements = SCNGeometryElement(
            data: nil,
            primitiveType: .point,
            primitiveCount: points.count,
            bytesPerIndex: MemoryLayout<Int>.size
        )
        
        elements.maximumPointScreenSpaceRadius = 2.0
        elements.minimumPointScreenSpaceRadius = 1.0
        elements.pointSize = 1.0
        
        let pointsGeometry = SCNGeometry(sources: [positionSource, colorSource], elements: [elements])
        
        return SCNNode(geometry: pointsGeometry)
    }
}
