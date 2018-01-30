//
//  MBEDemoViewController.swift
//  SwiftMetalDemo
//
//  Created by Warren Moore on 11/4/14.
//  Copyright (c) 2014 Warren Moore. All rights reserved.
//

import UIKit
import Metal

class MBEMetalHostingView: UIView {
    override class var layerClass: Swift.AnyClass {
        return CAMetalLayer.self
    }
}

class MBEDemoViewController : UIViewController {
    var metalLayer: CAMetalLayer! = nil
    let device = MTLCreateSystemDefaultDevice()!
    var pipeline: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    
    var timer: CADisplayLink! = nil
    var userToggle: Bool = false
    
    override func loadView() {
        view = MBEMetalHostingView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        metalLayer = view.layer as! CAMetalLayer
        
        view.backgroundColor = UIColor.white
        
        initializeMetal()
        buildPipeline()
        buildResources()
        startDisplayTimer()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(MBEDemoViewController.tapGesture))
        view.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewDidLayoutSubviews() {
        self.resize()
    }
    
    @objc func tapGesture() {
        userToggle = !userToggle
    }
    
    func initializeMetal() {
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        
        commandQueue = device.makeCommandQueue()
    }
    
    func buildPipeline() {
    }
    
    func buildResources() {
    }
    
    func startDisplayTimer() {
        timer = CADisplayLink(target: self, selector: #selector(MBEDemoViewController.redraw))
        timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    func resize() {
        if let window = view.window {
            let scale = window.screen.nativeScale
            let viewSize = view.bounds.size
            let layerSize = viewSize
            
            view.contentScaleFactor = scale
            metalLayer.drawableSize = CGSize(width: layerSize.width * scale, height: layerSize.height * scale)
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    deinit {
        timer.invalidate()
    }
    
    @objc func redraw() {
        autoreleasepool {
            self.draw()
        }
    }
    
    func draw() {
    }
}

