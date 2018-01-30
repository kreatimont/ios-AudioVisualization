//
//  SphereGenerator.swift
//  SwiftMetalDemo
//
//  Created by Warren Moore on 11/4/14.
//  Copyright (c) 2014 Warren Moore. All rights reserved.
//

import Metal

struct SphereGenerator
{
    static func sphereWithRadius(_ radius: Float, stacks: Int, slices: Int, device: MTLDevice) -> (MTLBuffer, MTLBuffer)
    {
        let pi = Float.pi
        let twoPi = pi * 2
        let deltaPhi = pi / Float(stacks)
        let deltaTheta = twoPi / Float(slices)
        
        var vertices = [SPH_Vertex]()
        var indices = [UInt16]()
        
        var phi = Float.pi / 2
        for _ in 0...stacks
        {
            var theta:Float = 0
            for slice in 0...slices
            {
                let x = cos(theta) * cos(phi)
                let y = sin(phi)
                let z = sin(theta) * cos(phi)
                
                let position = SPH_Vector4(x: radius * x, y: radius * y, z: radius * z, w: 1)
                let normal = SPH_Vector4(x: x, y: y, z: z, w: 0)
                let texCoords = SPH_TexCoords(u: 1 - Float(slice) / Float(slices), v: 1 - (sin(phi) + 1) * 0.5)
                
                let vertex = SPH_Vertex(position: position, normal: normal, texCoords: texCoords)
                
                vertices.append(vertex)
                
                theta += deltaTheta
            }
            
            phi += deltaPhi
        }
        
        for stack in 0...stacks
        {
            for slice in 0..<slices
            {
                let i0 = UInt16(slice + stack * slices)
                let i1 = i0 + 1
                let i2 = i0 + UInt16(slices)
                let i3 = i2 + 1
                
                indices.append(i0)
                indices.append(i2)
                indices.append(i3)
                
                indices.append(i0)
                indices.append(i3)
                indices.append(i1)
            }
        }
        
        let vertexBuffer = device.makeBuffer(bytes: vertices, length:MemoryLayout<SPH_Vertex>.stride * vertices.count, options:[])
        
        let indexBuffer = device.makeBuffer(bytes: indices, length:MemoryLayout<UInt16>.stride * indices.count, options:[])
        
        return (vertexBuffer, indexBuffer)
    }
}

