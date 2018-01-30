//
//  MBEDemoTwo.swift
//  SwiftMetalDemo
//
//  Created by Warren Moore on 10/23/14.
//  Copyright (c) 2014 Warren Moore. All rights reserved.
//

import UIKit
import AudioKit

class MBEDemoTwoViewController : MBEDemoViewController {
    var depthStencilState: MTLDepthStencilState! = nil
    var vertexBuffer: MTLBuffer! = nil
    var indexBuffer: MTLBuffer! = nil
    var uniformBuffer: MTLBuffer! = nil
    var depthTexture: MTLTexture! = nil
    var rotationAngle: Float = 0
    
    
    //AUDIO KIT
    var fft: AKFFTTap!
    var amplitudeTracker: AKAmplitudeTracker!
    var sizeCoef: Float = 1
    var maxCoef: Float = 2
    var minCoef: Float = 0.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //init AUDIO KIT
        let mic = AKMicrophone()
        fft = AKFFTTap(mic)
        amplitudeTracker = AKAmplitudeTracker(mic)
        
        // Turn the volume all the way down on the output of amplitude tracker
        let noAudioOutput = AKMixer(amplitudeTracker)
        noAudioOutput.volume = 0
        
        AudioKit.output = noAudioOutput
        AudioKit.start()
    }
    
    override func buildPipeline() {
        let library = device.newDefaultLibrary()!
        let fragmentFunction = library.makeFunction(name: "fragment_demo_two")
        let vertexFunction = library.makeFunction(name: "vertex_demo_two")
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.stride * 4
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.attributes[2].offset = MemoryLayout<Float>.stride * 8
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stride = MemoryLayout<SPH_Vertex>.stride
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        let error: NSErrorPointer? = nil
        pipeline = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        if (pipeline == nil) {
            print("Error occurred when creating pipeline \(String(describing: error))")
        }
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        commandQueue = device.makeCommandQueue()
    }
    
    override func buildResources() {
        let (vertexBuffer, indexBuffer) = SphereGenerator.sphereWithRadius(0.8, stacks: 10, slices: 50, device: device)
        self.vertexBuffer = vertexBuffer
        self.indexBuffer = indexBuffer
        uniformBuffer = device.makeBuffer(length: MemoryLayout<SPH_Matrix4x4>.stride * 2, options: [])
    }
    
    override func resize() {
        super.resize()
        
        let layerSize = metalLayer.drawableSize
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float,
                                                                              width: Int(layerSize.width),
                                                                              height: Int(layerSize.height),
                                                                              mipmapped: false)
        depthTextureDescriptor.storageMode = .private
        depthTextureDescriptor.usage = .renderTarget
        depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)
    }
    
    override func draw() {
        if let drawable = metalLayer.nextDrawable() {
            let yAxis = SPH_Vector4(x: 0, y: -1, z: 0, w: 0)
            var modelViewMatrix = SPH_Matrix4x4.rotationAboutAxis(yAxis, byAngle: rotationAngle)
            modelViewMatrix = SPH_Matrix4x4.scale(byFactor: self.sizeCoef)
            modelViewMatrix.W.z = -2.5
            
            let aspect = Float(metalLayer.drawableSize.width) / Float(metalLayer.drawableSize.height)
            
            let projectionMatrix = SPH_Matrix4x4.perspectiveProjection(aspect, fieldOfViewY: 100, near: 0.1, far: 100.0)
            
            let matrices = [projectionMatrix, modelViewMatrix]
            memcpy(uniformBuffer.contents(), matrices, MemoryLayout<SPH_Matrix4x4>.stride * 2)
            
            let commandBuffer = commandQueue.makeCommandBuffer()
            
            let passDescriptor = MTLRenderPassDescriptor()
            passDescriptor.colorAttachments[0].texture = drawable.texture
            passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.6, 0.5, 1)
            passDescriptor.colorAttachments[0].loadAction = .clear
            passDescriptor.colorAttachments[0].storeAction = .store
            
            passDescriptor.depthAttachment.texture = depthTexture
            passDescriptor.depthAttachment.clearDepth = 1
            passDescriptor.depthAttachment.loadAction = .clear
            passDescriptor.depthAttachment.storeAction = .dontCare
            
            let indexCount = indexBuffer.length / MemoryLayout<UInt16>.stride
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
            if userToggle {
                commandEncoder.setTriangleFillMode(.lines)
            }
            commandEncoder.setRenderPipelineState(pipeline)
            commandEncoder.setDepthStencilState(depthStencilState)
            commandEncoder.setCullMode(.back)
            commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
            commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
            commandEncoder.drawIndexedPrimitives(type: .triangle,
                                                  indexCount: indexCount,
                                                  indexType: .uint16,
                                                  indexBuffer: indexBuffer,
                                                  indexBufferOffset: 0)
            
            commandEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
            
            rotationAngle += 0.005
            
            let currentAmplitude: Float = Float(self.amplitudeTracker.amplitude * 25)
            let fftData = self.fft.fftData
            let count = 250
            
            let lowMax = fftData[0 ... (count / 2) - 1].max() ?? 0
            let hiMax = fftData[count / 2 ... count - 1].max() ?? 0
            let hiMin = fftData[count / 2 ... count - 1].min() ?? 0
            
            let lowMaxIndex = fftData.index(of: lowMax) ?? 0
            let hiMaxIndex = fftData.index(of: hiMax) ?? 0
            let hiMinIndex = fftData.index(of: hiMin) ?? 0

            let lowMaxIndexR = Float(lowMaxIndex)
            let hiMaxIndexR = Float(hiMaxIndex - count / 2)
            let hiMinIndexR = Float(hiMinIndex - count / 2)
            
            let sizeCoef = (lowMaxIndexR  * currentAmplitude)
            switch sizeCoef {
            case -100...1:
                //very slow
                self.sizeCoef -= 0.1
            case 1...2:
                //slow
                self.sizeCoef -= 0.01
            case 2...3:
                //medium
                break
            case 3...4:
                //fast
                self.sizeCoef += 0.01
                break
            case 4...100:
                //very fast
                self.sizeCoef += 0.1
            default:
                break
            }
            if self.sizeCoef < minCoef {
                self.sizeCoef = minCoef
            } else if self.sizeCoef > maxCoef {
                self.sizeCoef = maxCoef
            }
            print("LooP: \n{\tamplitude: \(currentAmplitude);\n\tlowMaxIndex: \(lowMaxIndex)\n\thiMax: \(hiMax); hiMaxIndex: \(hiMaxIndexR)\n\thiMin: \(hiMin); hiMinIndex: \(hiMinIndexR);\n\tsizeCoef: \(sizeCoef); globalSizeCoef: \(self.sizeCoef)\n}")
            
        }
    }
}


