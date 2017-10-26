//
//  GameViewController.swift
//  3D-Demo
//
//  Created by Rumata on 10/25/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion

private let motionManager = CMMotionManager()

class GameViewController: UIViewController {

  private var lightOrbit: SCNNode!
  private var cameraOrbit: SCNNode!
  private let queue = OperationQueue()
  private var scene: SCNScene!
  private var pyramid: SCNNode!

  private var previousPitchAngle: Double = 0
  private var startPitchAngle: Double!

  private let baseAngle = 55 / 180 * Float.pi

  override func viewDidLoad() {
    super.viewDidLoad()

    motionManager.deviceMotionUpdateInterval = 1.0 / 60

    // create a new scene
    scene = SCNScene(named: "art.scnassets/ship.scn")!

    // create and add a light to the scene
    addLight(for: scene)

    // get pyramid
    pyramid = self.scene.rootNode.childNode(withName: "pyramid", recursively: false)!
    pyramid.eulerAngles.x = baseAngle

    //Plane
    let plane = scene.rootNode.childNode(withName: "plane", recursively: false)!
    plane.geometry!.firstMaterial!.diffuse.contentsTransform = SCNMatrix4MakeScale(32, 32, 0)

    // retrieve the SCNView
    let scnView = self.view as! SCNView
    // set the scene to the view
    scnView.scene = scene
    // show statistics such as fps and timing information
    scnView.showsStatistics = true
    // configure the view
    scnView.backgroundColor = UIColor.black

    // add a tap gesture recognizer
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    scnView.addGestureRecognizer(tapGesture)
  }

  func handleTap(_ gestureRecognize: UIGestureRecognizer) {
    let scnView = self.view as! SCNView

    // check what nodes are tapped
    let p = gestureRecognize.location(in: scnView)
    let hitResults = scnView.hitTest(p, options: [:])
    if !hitResults.isEmpty {
      let result: AnyObject = hitResults[0]

      let node = result.node!
      guard node.name == "pyramid" else {
        return
      }

      // rotate it
      SCNTransaction.begin()
      SCNTransaction.animationDuration = 0.5
      node.eulerAngles.x = 0
      SCNTransaction.commit()
    }
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    motionManager.startDeviceMotionUpdates(using: .xTrueNorthZVertical, to: queue) { (motion, error) in
      guard let motion = motion else {
        return
      }

      let pitchAngle = motion.attitude.pitch

      let angleDiff = pitchAngle - self.previousPitchAngle
      guard abs(angleDiff) > (1 / 180 * Double.pi) else {
        return
      }
      self.previousPitchAngle = pitchAngle

      print(angleDiff * 180 / Double.pi)
      DispatchQueue.main.async {
        let correctedAngle = (Float(pitchAngle) - Float.pi / 4) * 2
        let newAngle = max(min(self.baseAngle, correctedAngle), 0)
        if newAngle != self.pyramid.eulerAngles.x {

          self.pyramid.eulerAngles.x = newAngle
        }
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    motionManager.stopDeviceMotionUpdates()
  }

  private func addLight(for scene: SCNScene) {
    let light = SCNLight()
    light.type = .omni
    light.spotOuterAngle = .pi / 40
    light.intensity = 300
    light.castsShadow = true
    let lightNode = SCNNode()
    lightNode.position = SCNVector3(x: 0, y: -0.2, z: 4)
    lightNode.light = light
    lightOrbit = SCNNode()
    lightOrbit.addChildNode(lightNode)
    scene.rootNode.addChildNode(lightOrbit)

    // rotate it (I've left out some animation code here to show just the rotation)
    lightOrbit.eulerAngles.x -= Float.pi / 4
  }
  
}
