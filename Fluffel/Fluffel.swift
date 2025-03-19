import Cocoa
import SpriteKit

// Fluffel 的活动状态
enum FluffelState {
    case idle           // 闲置状态
    case moving         // 正常移动
    case walking        // 行走状态
    case falling        // 下落中
    case sleeping       // 睡眠状态
    case dancing        // 跳舞状态
    case excited        // 兴奋状态
}

class Fluffel: SKNode {
    
    // MARK: - 属性
    
    // 视觉组件
    internal let body: SKShapeNode
    internal let leftEye: SKShapeNode
    internal let rightEye: SKShapeNode
    internal let mouth: SKShapeNode
    internal let leftCheek: SKShapeNode
    internal let rightCheek: SKShapeNode
    internal let leftEar: SKShapeNode
    internal let rightEar: SKShapeNode
    internal let glowEffect: SKShapeNode // 添加发光效果节点
    
    // Fluffel 状态相关变量
    var state: FluffelState = .idle
    
    public let size: CGSize = CGSize(width: 50, height: 50)
    
    // MARK: - 初始化
    
    override init() {
        // 首先创建发光效果，这样它会位于所有部件的下方
        glowEffect = SKShapeNode(circleOfRadius: 28) // 略大于身体
        glowEffect.fillColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.2) // 非常淡的白色
        glowEffect.strokeColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.1)
        glowEffect.lineWidth = 3.0
        glowEffect.blendMode = .add // 使用叠加混合模式使发光效果更明显
        glowEffect.zPosition = -1 // 确保在 Fluffel 下方
        
        // 创建 Fluffel 的圆形身体 (使用更明亮、更可爱的粉色)
        body = SKShapeNode(circleOfRadius: 25)
        body.fillColor = NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.85, alpha: 1.0) // 更明亮的粉色
        body.strokeColor = NSColor(calibratedRed: 0.95, green: 0.7, blue: 0.75, alpha: 1.0) // 柔和的边缘
        body.lineWidth = 1.0
        
        // 创建眼睛 (更大、更友好的眼睛)
        let eyeRadius: CGFloat = 6.0 // 稍微大一点的眼睛
        leftEye = SKShapeNode(circleOfRadius: eyeRadius)
        leftEye.fillColor = .white
        leftEye.strokeColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        leftEye.lineWidth = 0.5
        leftEye.position = CGPoint(x: -10, y: 7) // 稍微上移
        
        // 创建瞳孔 (更大、更可爱的瞳孔)
        let leftPupil = SKShapeNode(circleOfRadius: eyeRadius * 0.65)
        leftPupil.fillColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.3, alpha: 1.0) // 不那么黑的瞳孔
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: 0.5, y: 0) // 居中一点
        leftEye.addChild(leftPupil)
        
        // 添加更大的高光点，增加可爱感
        let leftHighlight = SKShapeNode(circleOfRadius: eyeRadius * 0.3)
        leftHighlight.fillColor = .white
        leftHighlight.strokeColor = .clear
        leftHighlight.position = CGPoint(x: 1.5, y: 1.5)
        leftPupil.addChild(leftHighlight)
        
        // 添加第二个小高光点
        let leftSmallHighlight = SKShapeNode(circleOfRadius: eyeRadius * 0.15)
        leftSmallHighlight.fillColor = .white
        leftSmallHighlight.strokeColor = .clear
        leftSmallHighlight.position = CGPoint(x: -1.0, y: -1.0)
        leftPupil.addChild(leftSmallHighlight)
        
        rightEye = SKShapeNode(circleOfRadius: eyeRadius)
        rightEye.fillColor = .white
        rightEye.strokeColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        rightEye.lineWidth = 0.5
        rightEye.position = CGPoint(x: 10, y: 7) // 稍微上移
        
        // 创建瞳孔
        let rightPupil = SKShapeNode(circleOfRadius: eyeRadius * 0.65)
        rightPupil.fillColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.3, alpha: 1.0) // 不那么黑的瞳孔
        rightPupil.strokeColor = .clear
        rightPupil.position = CGPoint(x: -0.5, y: 0) // 居中一点
        rightEye.addChild(rightPupil)
        
        // 添加更大的高光点
        let rightHighlight = SKShapeNode(circleOfRadius: eyeRadius * 0.3)
        rightHighlight.fillColor = .white
        rightHighlight.strokeColor = .clear
        rightHighlight.position = CGPoint(x: -1.5, y: 1.5)
        rightPupil.addChild(rightHighlight)
        
        // 添加第二个小高光点
        let rightSmallHighlight = SKShapeNode(circleOfRadius: eyeRadius * 0.15)
        rightSmallHighlight.fillColor = .white
        rightSmallHighlight.strokeColor = .clear
        rightSmallHighlight.position = CGPoint(x: 1.0, y: -1.0)
        rightPupil.addChild(rightSmallHighlight)
        
        // 创建嘴巴 (简单直线，后续可以改变形状表达情感)
        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -7, y: -8))
        mouthPath.addLine(to: CGPoint(x: 7, y: -8))
        
        mouth = SKShapeNode(path: mouthPath)
        mouth.strokeColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        mouth.lineWidth = 1.5
        
        // 创建粉红色的脸颊，增添可爱度
        leftCheek = SKShapeNode(circleOfRadius: 5.0) // 稍微大一点的脸颊
        leftCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.7, alpha: 0.3) // 更淡的粉色
        leftCheek.strokeColor = .clear
        leftCheek.position = CGPoint(x: -15, y: -3)
        
        rightCheek = SKShapeNode(circleOfRadius: 5.0)
        rightCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.7, alpha: 0.3)
        rightCheek.strokeColor = .clear
        rightCheek.position = CGPoint(x: 15, y: -3)
        
        // 添加可爱的小耳朵
        leftEar = SKShapeNode(circleOfRadius: 8)
        leftEar.fillColor = NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.8, alpha: 1.0) // 略微明亮一点的颜色
        leftEar.strokeColor = .clear
        leftEar.position = CGPoint(x: -18, y: 18)
        
        rightEar = SKShapeNode(circleOfRadius: 8)
        rightEar.fillColor = NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.8, alpha: 1.0)
        rightEar.strokeColor = .clear
        rightEar.position = CGPoint(x: 18, y: 18)
        
        super.init()
        
        print("Fluffel 初始化开始")
        
        // 添加所有部件到节点，确保发光效果在最底层
        addChild(glowEffect)
        addChild(body)
        addChild(leftEar)
        addChild(rightEar)
        addChild(leftEye)
        addChild(rightEye)
        addChild(mouth)
        addChild(leftCheek)
        addChild(rightCheek)
        
        // 启动基本动画
        startBreathingAnimation()
        
        // 启动发光效果动画
        startGlowAnimation()
        
        print("Fluffel 初始化完成")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 状态管理
    
    // 设置 Fluffel 的状态
    func setState(_ newState: FluffelState) {
        // 在改变状态前清理当前状态
        if state != newState {
            // 移除任何显示的对话气泡
            removeSpeechBubble()
            
            // 根据当前状态执行清理
            switch state {
            case .walking:
                removeAction(forKey: "walkingAction")
            case .falling:
                removeAction(forKey: "fallingAction")
            default:
                break
            }
        }
        
        state = newState
        
        // 根据新状态执行初始化
        switch state {
        case .idle:
            smile()
        default:
            break
        }
    }
}
