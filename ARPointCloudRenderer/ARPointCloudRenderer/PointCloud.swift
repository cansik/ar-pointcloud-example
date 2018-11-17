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
        
        progressEvent.raise(data: 0.0)
        
        // Open file
        do {
            let data = try String(contentsOfFile: file, encoding: .ascii)
            var lines = data.components(separatedBy: "\n")
            
            // Read header
            while !lines.isEmpty {
                let line = lines.removeFirst()
                if line.hasPrefix("element vertex ") {
                    n = Int(line.components(separatedBy: " ")[2])!
                    continue
                }
                if line.hasPrefix("end_header") {
                    break
                }
            }
            
            pointCloud = Array(repeating: PointCloudVertex(x: 0,y: 0,z: 0,r: 0,g: 0,b: 0), count: n)
            
            var nextProgressStep = 0
            let minProgressStep = Int(Float(n) * 0.01)
            
            // Read data
            DispatchQueue.concurrentPerform(iterations: n - 1) { (i) in
                let line = lines[i]
                let elements = line.components(separatedBy: " ")
                var vertex = pointCloud[i]
                
                vertex.x = Float(elements[0])!
                vertex.y = Float(elements[1])!
                vertex.z = Float(elements[2])!
                
                vertex.r = Float(elements[3])! / 255.0
                vertex.g = Float(elements[4])! / 255.0
                vertex.b = Float(elements[5])! / 255.0
                
                if(i >= nextProgressStep)
                {
                    let progress = Float(i) / Float(n)
                    progressEvent.raise(data: progress)
                    nextProgressStep += minProgressStep
                }
            }
            
            print("Point cloud data loaded: \(n) points")
            progressEvent.raise(data: 1.0)
        } catch {
            print(error)
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
        
        elements.maximumPointScreenSpaceRadius = 5.0
        elements.minimumPointScreenSpaceRadius = 1.0
        elements.pointSize = 2.0
        
        let pointsGeometry = SCNGeometry(sources: [positionSource, colorSource], elements: [elements])
        return SCNNode(geometry: pointsGeometry)
    }
}
