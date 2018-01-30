//
//  GeometricTypes.swift
//  SwiftMetalDemo
//
//  Created by Warren Moore on 11/4/14.
//  Copyright (c) 2014 Warren Moore. All rights reserved.
//

import Foundation

struct SPH_Vector4
{
    var x: Float
    var y: Float
    var z: Float
    var w: Float
}

struct SPH_ColorRGBA
{
    var r: Float
    var g: Float
    var b: Float
    var a: Float
}

struct SPH_TexCoords
{
    var u: Float
    var v: Float
}

struct SPH_ColoredVertex
{
    var position: SPH_Vector4
    var color: SPH_ColorRGBA
}

struct SPH_Vertex
{
    var position: SPH_Vector4
    var normal: SPH_Vector4
    var texCoords: SPH_TexCoords
}

struct SPH_Matrix4x4
{
    var X: SPH_Vector4
    var Y: SPH_Vector4
    var Z: SPH_Vector4
    var W: SPH_Vector4
    
    init()
    {
        X = SPH_Vector4(x: 1, y: 0, z: 0, w: 0)
        Y = SPH_Vector4(x: 0, y: 1, z: 0, w: 0)
        Z = SPH_Vector4(x: 0, y: 0, z: 1, w: 0)
        W = SPH_Vector4(x: 0, y: 0, z: 0, w: 1)
    }
    
    static func rotationAboutAxis(_ axis: SPH_Vector4, byAngle angle: Float) -> SPH_Matrix4x4
    {
        var mat = SPH_Matrix4x4()
        
        let c = cos(angle)
        let s = sin(angle)
        
        mat.X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c
        mat.X.y = axis.x * axis.y * (1 - c) - axis.z * s
        mat.X.z = axis.x * axis.z * (1 - c) + axis.y * s
        
        mat.Y.x = axis.x * axis.y * (1 - c) + axis.z * s
        mat.Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c
        mat.Y.z = axis.y * axis.z * (1 - c) - axis.x * s
        
        mat.Z.x = axis.x * axis.z * (1 - c) - axis.y * s
        mat.Z.y = axis.y * axis.z * (1 - c) + axis.x * s
        mat.Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c
        
        return mat
    }
    
    static func distoredByAmplitude(_ amplitude: Float) -> SPH_Matrix4x4
    {
        var mat = SPH_Matrix4x4()
        
        mat.X.x = mat.X.x * amplitude
        mat.X.y = mat.X.y * amplitude
        mat.X.z = mat.X.z * amplitude
        
        mat.Y.x = mat.Y.x * amplitude
        mat.Y.y = mat.Y.y * amplitude
        mat.Y.z = mat.Y.z * amplitude
        
        mat.Z.x = mat.Z.x * amplitude
        mat.Z.y = mat.Z.y * amplitude
        mat.Z.z = mat.Z.z * amplitude
        
        return mat
    }
    
    static func perspectiveProjection(_ aspect: Float, fieldOfViewY: Float, near: Float, far: Float) -> SPH_Matrix4x4
    {
        var mat = SPH_Matrix4x4()
        
        let fovRadians = fieldOfViewY * Float(.pi / 180.0)
        
        let yScale = 1 / tan(fovRadians * 0.5)
        let xScale = yScale / aspect
        let zRange = far - near
        let zScale = -(far + near) / zRange
        let wzScale = -2 * far * near / zRange
        
        mat.X.x = xScale
        mat.Y.y = yScale
        mat.Z.z = zScale
        mat.Z.w = -1
        mat.W.z = wzScale
        
        return mat;
    }
}

