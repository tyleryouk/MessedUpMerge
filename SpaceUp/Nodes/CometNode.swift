

import SpriteKit

private struct KeyForAction {
  static let moveFromPositionAction = "moveFromPositionAction"
  static let rotationAction = "rotationAction"
  static let glowAction = "glowAction"
}

class CometNode: SKSpriteNode {
  // MARK: - Immutable vars
  var sphere: SKSpriteNode
  var glow: SKSpriteNode
  let type: CometType
  
  // MARK: - Vars
  private var sphereHighlight: SphereHighlightNode?
  weak var emitter: CometEmitter?
  var enabled: Bool = true
  var physicsFrame = CGRectZero
  
  private lazy var explodeAnimateAction: SKAction = {
    let texture0: SKTexture
    
    switch self.type {
    case .Slow:
      texture0 = SKTexture(imageNamed: TextureFileName.CrackedLarge)

    case .Fast:
      texture0 = SKTexture(imageNamed: TextureFileName.CrackedSmall)

    default:
      texture0 = SKTexture(imageNamed: TextureFileName.CrackedMedium)
    }
    
    let textures = [
      texture0,
      SKTexture(imageNamed: TextureFileName.CrackedRed)
    ] + texturesWithName(TextureFileName.Explosion, fromIndex: 1, toIndex: 5)
    
    return SKAction.animateWithTextures(textures, timePerFrame: 1/20)
  }()

  // MARK: - Init
    init(type: CometType, isReversed: Bool = false, currentScore: Int) {
    self.type = type
        
    let radius: CGFloat
        switch type {
            case .Slow:
        
            sphere = SKSpriteNode(imageNamed: TextureFileName.CometLarge)
            glow = SKSpriteNode(imageNamed: TextureFileName.CometLargeGlow)
            glow.anchorPoint = CGPoint(x: 0.68, y: 0.38)
            
            if (currentScore > 90 && currentScore <= 190) {
                sphere = SKSpriteNode(imageNamed: TextureFileName.CometLarge2)
                glow = SKSpriteNode(imageNamed: TextureFileName.CometLargeGlow2)
                glow.anchorPoint = CGPoint(x: 0.68, y: 0.38) //JUST ADDED
            } else if (currentScore > 190) {
                sphere = SKSpriteNode(imageNamed: TextureFileName.CometLarge3)
                glow = SKSpriteNode(imageNamed: TextureFileName.CometLargeGlow3)
                glow.anchorPoint = CGPoint(x: 0.68, y: 0.38) //JUST ADDED
            }
        
          radius = 99
      
        case .Fast:
            sphere = SKSpriteNode(imageNamed: TextureFileName.CometSmall)
            glow = SKSpriteNode(imageNamed: TextureFileName.CometSmallGlow)
            glow.anchorPoint = CGPoint(x: 0.68, y: 0.38)
            
            if (currentScore > 90 && currentScore <= 190) {
                sphere = SKSpriteNode(imageNamed: TextureFileName.CometSmall2)
                glow = SKSpriteNode(imageNamed: TextureFileName.CometSmallGlow2)
                glow.anchorPoint = CGPoint(x: 0.68, y: 0.38) //JUST ADDED
            } else if (currentScore > 190) {
                sphere = SKSpriteNode(imageNamed: TextureFileName.CometSmall3)
                glow = SKSpriteNode(imageNamed: TextureFileName.CometSmallGlow3)
                glow.anchorPoint = CGPoint(x: 0.68, y: 0.38) //JUST ADDED
            }
            
            radius = 36
      
        case .Award:
            sphere = SKSpriteNode(imageNamed: TextureFileName.CometStar)
            glow = SKSpriteNode(imageNamed: TextureFileName.CometStarGlow)
            
            if (currentScore > 90 && currentScore <= 190) {
                sphere = SKSpriteNode(imageNamed: TextureFileName.CometStar2)
                glow = SKSpriteNode(imageNamed: TextureFileName.CometStarGlow2)
            } else if (currentScore > 190) {
                sphere = SKSpriteNode(imageNamed: TextureFileName.CometStar3)
                glow = SKSpriteNode(imageNamed: TextureFileName.CometStarGlow3)
            }
            radius = 25

        default: //Regular
            sphere = SKSpriteNode(imageNamed: TextureFileName.CometMedium)
            glow = SKSpriteNode(imageNamed: TextureFileName.CometMediumGlow)
            
            if (currentScore > 90 && currentScore <= 190) {
                sphere = SKSpriteNode(imageNamed: TextureFileName.CometMedium2)
                glow = SKSpriteNode(imageNamed: TextureFileName.CometMediumGlow2)
            } else if (currentScore > 190) {
                sphere = SKSpriteNode(imageNamed: TextureFileName.CometMedium3)
                glow = SKSpriteNode(imageNamed: TextureFileName.CometMediumGlow3)
            }
            
            glow.anchorPoint = CGPoint(x: 0.68, y: 0.38)
            radius = 63
    }

    physicsFrame = CGRect(x: radius, y: radius, width: radius * 2, height: radius * 2)

    super.init(texture: nil, color: UIColor.clearColor(), size: sphere.texture!.size())
    
    // Sphere
    addChild(sphere)

    // Glow
    glow.zPosition = 1
    glow.blendMode = SKBlendMode.Screen
    
    if isReversed {
      glow.xScale = -1
      glow.yScale = -1
    }
    
    addChild(glow)
    
    // Highlight
    if type != .Award {
      sphereHighlight = SphereHighlightNode(radius: radius)
      addChild(sphereHighlight!)
    }

    // Physics
    physicsBody = SKPhysicsBody(circleOfRadius: physicsFrame.width / 2)
    physicsBody!.categoryBitMask = type == .Award ? PhysicsCategory.Award : PhysicsCategory.Comet
    physicsBody!.collisionBitMask = 0
    physicsBody!.contactTestBitMask = PhysicsCategory.Player
    physicsBody!.affectedByGravity = false
    physicsBody!.usesPreciseCollisionDetection = true
    
    // Animate
    animate()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Movement
  func moveFromPosition(position: CGPoint, toPosition: CGPoint, duration: NSTimeInterval, completion: (() -> Void)?) {
    self.position = position
    
    let action = SKAction.sequence([
      SKAction.moveTo(toPosition, duration: duration, timingMode: .Linear),
      SKAction.runBlock { completion?() }
    ])
    
    runAction(action, withKey: KeyForAction.moveFromPositionAction)
  }
  
  func cancelMovement() {
    removeActionForKey(KeyForAction.moveFromPositionAction)
  }
  
  // MARK: - Removal
  func removeFromEmitter() {
    enabled = false
    emitter?.removeComet(self)
  }

  func explodeAndRemove() {
    if let parent = parent {
      // Add explosion effect
      let explosion = SKSpriteNode(imageNamed: TextureFileName.CrackedRed)
      let glow = SKEmitterNode(fileNamed: EffectFileName.ExplosionGlow)!
      
      explosion.position = position
      parent.addChild(explosion)
      
      explosion.runAction(SKAction.sequence([
        explodeAnimateAction,
        SKAction.runBlock { explosion.removeFromParent() }
      ]))

      glow.position = position
      glow.alpha = 0.5
      glow.advanceSimulationTime(0.6)
      parent.addChild(glow)
      
      parent.afterDelay(3) { [weak glow] in
        glow?.removeFromParent()
      }
    }
    
    // Remove itself
    removeFromEmitter()
  }
  
  // MARK: - Animate
  func animate() {
    let rotationAction = SKAction.rotateByAngle(CGFloat(M_PI) * 2, duration: 6)
    let glowAction = SKAction.sequence([
      SKAction.fadeAlphaTo(1, duration: 0.6),
      SKAction.fadeAlphaTo(0.5, duration: 0.6)
    ])
    
    glowAction.timingMode = SKActionTimingMode.EaseInEaseOut
    
    sphere.runAction(SKAction.repeatActionForever(rotationAction), withKey: KeyForAction.rotationAction)
    glow.runAction(SKAction.repeatActionForever(glowAction), withKey: KeyForAction.glowAction)
  }
  
  func stopAnimate() {
    sphere.removeActionForKey(KeyForAction.rotationAction)
    glow.removeActionForKey(KeyForAction.glowAction)
  }
}
