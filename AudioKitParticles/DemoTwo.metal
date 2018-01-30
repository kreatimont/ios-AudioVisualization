//
//  DemoTwo.metal
//  MetalSwift
//
//  Created by Warren Moore on 10/23/14.
//  Copyright (c) 2014 Warren Moore. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

constant float3 lightDirection(0.57735, 0.57735, 0.57735);

struct TexturedInVertex
{
    float4 position [[attribute(0)]];
    float4 normal [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};

struct TexturedColoredOutVertex
{
    float4 position [[position]];
    float3 normal;
};

struct Uniforms
{
    float4x4 projectionMatrix;
    float4x4 modelViewMatrix;
};

vertex TexturedColoredOutVertex vertex_demo_two(TexturedInVertex vert [[stage_in]],
                                                constant Uniforms &uniforms [[buffer(1)]])
{
    float4x4 MV = uniforms.modelViewMatrix;
    float3x3 normalMatrix(MV[0].xyz, MV[1].xyz, MV[2].xyz);
    float4 modelNormal = vert.normal;
    
    TexturedColoredOutVertex outVertex;
    outVertex.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * vert.position;
    outVertex.normal = normalMatrix * modelNormal.xyz;
    
    return outVertex;
}

fragment half4 fragment_demo_two(TexturedColoredOutVertex vert [[stage_in]])
{
    float diffuseIntensity = saturate(dot(normalize(vert.normal), lightDirection));
    return half4(diffuseIntensity, diffuseIntensity, diffuseIntensity, 1);
}
