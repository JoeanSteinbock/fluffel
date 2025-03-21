import SpriteKit
import AVFoundation

// 删除不再使用的Direction枚举，使用FluffelTypes.swift中的MovementDirection代替
// enum Direction {
//     case left, right, up, down
// }

class FluffelScene: SKScene {
    var fluffel: Fluffel?
    private var lastMoveTime: TimeInterval = 0
    private var moveDelay: TimeInterval = 0.01 // 控制移动流畅度
    
    // 无聊状态相关
    private var lastActivityTime: TimeInterval = 0
    private let boredThreshold: TimeInterval = 10.0 // 10秒无活动后触发无聊状态
    private var isCheckingBoredom = false
    
    // 添加一个防止重复触发说话功能的标志
    private var isSpeakingInProgress = false
    private var speakingDebounceTimer: Timer?
    
    // 添加连续点击计数和最后点击时间记录
    private var consecutiveClicks: Int = 0
    private var lastClickTime: TimeInterval = 0
    
    // 调试状态
    private var isDebugMode = false
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        _ = FluffelPixabayPlaylists.shared.getAllCategories()
        
        // 设置场景属性
        backgroundColor = .clear
        
        // 创建 Fluffel
        fluffel = Fluffel()
        if let fluffel = fluffel {
            // 为Fluffel节点设置名称，以便可以通过名称查找
            fluffel.name = "fluffel"
            
            // 确保 Fluffel 在场景中央
            fluffel.position = CGPoint(x: size.width / 2, y: size.height / 2)
            addChild(fluffel)
            
            // 使用正常比例
            fluffel.setScale(1.0)
            
            // 让 Fluffel 微笑，看起来更友好
            fluffel.smile()
            
            // 偶尔眨眨眼睛，看起来更自然
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let fluffel = self?.fluffel else { return }
                fluffel.blink()
            }
            
            // 定期眨眼
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
                guard let self = self, let fluffel = self.fluffel else {
                    timer.invalidate()
                    return
                }
                
                // 眨眼
                fluffel.blink()
            }
            
            print("Fluffel 已添加到场景，位置: \(fluffel.position)")
            
            // 为初次问候设置更长的延迟，确保窗口和Fluffel已完全准备好
            // 这样可以避免在初始化动画过程中出现问题
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // 发送一个窗口调整通知，确保Fluffel窗口有足够空间
                NotificationCenter.default.post(name: .fluffelDidMove, object: self)
                
                // 再等待一小段时间，确保窗口调整完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.makeFluffelSpeak("Hello! I'm Fluffel!")
                }
            }
        } else {
            print("错误: 无法创建 Fluffel")
        }
        
        // 初始化无聊检测
        lastActivityTime = CACurrentMediaTime()
        startBoredCheck()
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // 检查无聊状态
        checkBoredom(currentTime: currentTime)
    }
    
    // 检查是否进入无聊状态
    private func checkBoredom(currentTime: TimeInterval) {
        guard let fluffel = fluffel else { return }
        
        // 只有在正常状态下才检查无聊
        guard fluffel.state != .falling else {
            return  // 不重置计时器，只是跳过检查
        }
        
        // 如果超过无聊阈值时间没有活动，触发随机动画
        if currentTime - lastActivityTime > boredThreshold {
            print("触发无聊动画: 已经 \(currentTime - lastActivityTime) 秒无活动")
            startRandomBoredAnimation()
            lastActivityTime = currentTime // 重置计时器
        }
    }
    
    // 开始随机无聊动画
    private func startRandomBoredAnimation() {
        guard let fluffel = fluffel else { return }
        
        // 随机选择一个动画
        let randomAction = Int.random(in: 0...4)
        
        switch randomAction {
        case 0:
            // 睡觉动画
            fluffel.startSleepingAnimation()
            print("Fluffel 感到无聊，开始睡觉")
            
            // 5秒后停止睡觉
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                fluffel.stopSleepingAnimation()
                self?.lastActivityTime = CACurrentMediaTime()
            }
            
        case 1:
            // 跳舞动画
            fluffel.startDancingAnimation()
            print("Fluffel 感到无聊，开始跳舞")
            
            // 4秒后停止跳舞
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
                fluffel.stopDancingAnimation()
                self?.lastActivityTime = CACurrentMediaTime()
            }
            
        case 2:
            // 兴奋动画
            fluffel.startExcitedAnimation()
            print("Fluffel 感到无聊，变得兴奋")
            
            // 3秒后停止兴奋
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                fluffel.stopExcitedAnimation()
                self?.lastActivityTime = CACurrentMediaTime()
            }
            
        case 3:
            // 滚动动画
            fluffel.roll()
            print("Fluffel 感到无聊，开始滚动")
            
            // 2秒后停止滚动
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                fluffel.stopRolling()
                self?.lastActivityTime = CACurrentMediaTime()
            }
            
        case 4:
            // 眨眼动画
            fluffel.blink()
            print("Fluffel 感到无聊，眨了眨眼")
            
            // 眨眼是瞬时的，不需要停止
            lastActivityTime = CACurrentMediaTime()
            
        default:
            break
        }
    }
    
    // 启动无聊检测
    private func startBoredCheck() {
        guard !isCheckingBoredom else { return }
        isCheckingBoredom = true
    }
    
    // 启动下落动画
    func startFalling() {
        guard let fluffel = fluffel, fluffel.state != .falling else { return }
        
        fluffel.setState(.falling)
        
        // 重置无聊计时器，因为有下落发生
        lastActivityTime = CACurrentMediaTime()
    }
    
    func moveFluffel(direction: MovementDirection) {
        guard let fluffel = fluffel else { return }
        
        let currentTime = CACurrentMediaTime()
        // 添加小延迟避免移动过快
        if currentTime - lastMoveTime < moveDelay {
            return
        }
        lastMoveTime = currentTime
        
        // 设置移动状态
        if fluffel.state == .idle {
            fluffel.setState(.moving)
        }
        
        // 增加移动距离，使移动更明显
        let moveDistance: CGFloat = 8.0
        
        // 根据方向移动 Fluffel - 不再检查边界
        switch direction {
        case .left:
            fluffel.position.x -= moveDistance
            turnFluffelToFace(direction: .left)
        case .right:
            fluffel.position.x += moveDistance
            turnFluffelToFace(direction: .right)
        case .up:
            fluffel.position.y += moveDistance
        case .down:
            fluffel.position.y -= moveDistance
        }
        
        // 重置无聊计时器，因为有移动发生
        lastActivityTime = CACurrentMediaTime()
        
        // 移动后发送通知，以便窗口控制器可以跟随 Fluffel 移动
        NotificationCenter.default.post(name: .fluffelDidMove, object: self)
    }
    
    // 获取 Fluffel 当前位置
    func getFluffelPosition() -> CGPoint? {
        return fluffel?.position
    }
    
    // 获取 Fluffel 的实际大小
    func getFluffelSize() -> CGSize? {
        return fluffel?.size
    }
    
    // 让 Fluffel 朝向移动方向
    private func turnFluffelToFace(direction: MovementDirection) {
        guard let fluffel = fluffel else { return }
        
        // 简单的左右翻转效果
        switch direction {
        case .left:
            fluffel.xScale = -1.0 // 镜像翻转
        case .right:
            fluffel.xScale = 1.0 // 正常方向
        default:
            break // 上下移动不改变朝向
        }
    }
    
    // 在这里添加鼠标点击处理
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        
        // 更健壮的 Fluffel 存在性检查
        guard let fluffel = fluffel else { return }
        
        // 确保点击在 Fluffel 上
        if fluffel.contains(location) {
            // 在主线程中安全地处理点击操作
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 使用场景的isSpeakingInProgress标志而不是局部标志
                // 如果正在说话中，不要再触发新的说话
                if self.isSpeakingInProgress {
                    // 检查点击时间间隔，如果在0.5秒内连续点击则增加计数
                    let currentTime = CACurrentMediaTime()
                    if currentTime - self.lastClickTime < 0.5 {
                        self.consecutiveClicks += 1
                        print("Fluffel正在说话中，连续点击次数: \(self.consecutiveClicks)")
                        
                        // 如果连续点击超过5次，强制重置说话状态
                        if self.consecutiveClicks >= 5 {
                            print("检测到多次快速点击，强制重置说话状态")
                            self.isSpeakingInProgress = false
                            self.consecutiveClicks = 0
                            
                            // 清除任何可能存在的计时器
                            self.speakingDebounceTimer?.invalidate()
                            self.speakingDebounceTimer = nil
                            
                            // 发送通知让气泡窗口关闭
                            NotificationCenter.default.post(
                                name: NSNotification.Name.fluffelDidStopSpeaking,
                                object: nil
                            )
                            
                            return
                        }
                    } else {
                        // 不在连续点击范围内，重置连续点击计数
                        self.consecutiveClicks = 1
                    }
                    
                    // 更新最后点击时间
                    self.lastClickTime = currentTime
                    return
                }
                
                // 如果能走到这里，说明不在说话状态，重置计数器
                self.consecutiveClicks = 1
                self.lastClickTime = CACurrentMediaTime()
                
                // 设置标志，防止重复触发
                self.isSpeakingInProgress = true
                
                // 取消可能存在的定时器
                self.speakingDebounceTimer?.invalidate()
                
                // 使用我们创建的说话演示
                if let appDelegate = NSApp.delegate as? AppDelegate {
                    // 随机选择一个动作：问候、笑话或事实
                    let action = Int.random(in: 0...2)
                    switch action {
                    case 0:
                        appDelegate.speakingDemo?.speakRandomGreeting()
                    case 1:
                        appDelegate.speakingDemo?.tellRandomJoke()
                    case 2:
                        appDelegate.speakingDemo?.shareRandomFact()
                    default:
                        self.makeFluffelSpeak() // 使用原有的方法作为后备
                    }
                } else {
                    // 如果找不到 AppDelegate，仍然使用原有的方法
                    self.makeFluffelSpeak()
                }
                
                // 设置定时器，延迟清除标志
                self.speakingDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    self?.isSpeakingInProgress = false
                }
            }
        }
        
        // 更新最后活动时间
        lastActivityTime = CACurrentMediaTime()
    }
    
    // 让 Fluffel 说话
    func makeFluffelSpeak(_ text: String? = nil) {
        // 在主线程中安全地执行说话逻辑
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let fluffel = self.fluffel else { 
                print("无法让Fluffel说话，Fluffel对象为nil") 
                return 
            }
            
            // 如果正在说话中，不要再触发新的说话
            if self.isSpeakingInProgress {
                return
            }
            
            // 设置标志，防止重复触发
            self.isSpeakingInProgress = true
            
            // 如果没有指定文本，随机选择一句问候语
            let speechText = text ?? FluffelDialogues.shared.getRandomBoredGreeting()
            
            // 根据文本长度调整显示时间
            let duration = min(max(TimeInterval(speechText.count) * 0.15, 2.0), 5.0)
            
            // 让 Fluffel 说话
            fluffel.speak(text: speechText, duration: duration) { [weak self] in
                // 说话结束后重置标志
                DispatchQueue.main.async {
                    self?.isSpeakingInProgress = false
                }
            }
            
            // 设置安全计时器，以防说话完成回调未被调用
            self.speakingDebounceTimer?.invalidate()
            self.speakingDebounceTimer = Timer.scheduledTimer(withTimeInterval: duration + 1.0, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isSpeakingInProgress = false
                }
            }
        }
    }
    
    // 将 Fluffel 重置到第一屏中心
    func resetFluffelToCenter() {
        guard let fluffel = fluffel else { 
            print("无法重置Fluffel位置，Fluffel对象为nil")
            return 
        }
        
        // 停止任何当前动画或状态
        if fluffel.state != .idle {
            fluffel.setState(.idle)
        }
        
        // 创建移动到中心的动画
        let centerPoint = CGPoint(x: size.width / 2, y: size.height / 2)
        let moveAction = SKAction.move(to: centerPoint, duration: 0.5)
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.3)
        let rotateAction = SKAction.rotate(toAngle: 0, duration: 0.3)
        
        // 组合动画
        let groupAction = SKAction.group([moveAction, scaleAction, rotateAction])
        
        // 添加一个小小的弹跳效果
        let bounceUp = SKAction.moveBy(x: 0, y: 10, duration: 0.1)
        let bounceDown = SKAction.moveBy(x: 0, y: -10, duration: 0.1)
        let bounceAction = SKAction.sequence([bounceUp, bounceDown])
        
        // 让 Fluffel 执行动画序列
        fluffel.run(SKAction.sequence([groupAction, bounceAction]))
        
        // 让 Fluffel 说话，表明它已经回到中心
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.makeFluffelSpeak("I'm back!")
        }
        
        // 重置朝向为右侧
        fluffel.xScale = abs(fluffel.xScale)
        
        // 更新最后活动时间
        lastActivityTime = CACurrentMediaTime()
        
        // 发送移动通知
        NotificationCenter.default.post(name: .fluffelDidMove, object: self)
        
        print("Fluffel 已重置到屏幕中心")
    }
    
    // 设置调试模式
    func setDebugMode(_ enabled: Bool) {
        isDebugMode = enabled
    }
    
    // 处理右键点击显示上下文菜单
    override func rightMouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        
        // 更健壮的 Fluffel 存在性检查
        guard let fluffel = fluffel else { return }
        
        // 确保点击在 Fluffel 上
        if fluffel.contains(location) {
            // 在主线程中安全地处理点击操作
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 创建上下文菜单
                self.showContextMenu(at: event.locationInWindow, in: self.view)
            }
        } else {
            // 点击不在 Fluffel 上，调用父类方法
            super.rightMouseDown(with: event)
        }
    }
    
    // 显示上下文菜单
    private func showContextMenu(at location: NSPoint, in view: NSView?) {
        guard let view = view else { return }
        
        // 创建菜单
        let menu = NSMenu(title: "Fluffel Menu")
        
        // 添加交互选项
        menu.addItem(withTitle: "Greeting", action: #selector(AppDelegate.speakGreeting(_:)), keyEquivalent: "g")
        menu.addItem(withTitle: "Joke", action: #selector(AppDelegate.tellJoke(_:)), keyEquivalent: "j")
        menu.addItem(withTitle: "Share facts", action: #selector(AppDelegate.shareFact(_:)), keyEquivalent: "f")
        menu.addItem(withTitle: "Conversation", action: #selector(AppDelegate.startConversation(_:)), keyEquivalent: "c")
        
        // 创建音乐子菜单
        let musicMenu = NSMenu(title: "Listen to music")
        let musicMenuItem = NSMenuItem(title: "Listen to music", action: nil, keyEquivalent: "m")
        musicMenuItem.submenu = musicMenu
        
        // 填充音乐菜单
        populateMusicMenu(musicMenu)
        menu.addItem(musicMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 添加声音选项子菜单
        let voiceMenu = NSMenu(title: "Voice Options")
        let voiceMenuItem = NSMenuItem(title: "Voice Options", action: nil, keyEquivalent: "")
        voiceMenuItem.submenu = voiceMenu
        
        // 添加声音选项
        voiceMenu.addItem(withTitle: "Squeaky", action: #selector(AppDelegate.setVoiceSqueaky(_:)), keyEquivalent: "1")
        voiceMenu.addItem(withTitle: "Deep", action: #selector(AppDelegate.setVoiceDeep(_:)), keyEquivalent: "2")
        voiceMenu.addItem(withTitle: "Chipmunk", action: #selector(AppDelegate.setVoiceChipmunk(_:)), keyEquivalent: "3")
        voiceMenu.addItem(withTitle: "Robot", action: #selector(AppDelegate.setVoiceRobot(_:)), keyEquivalent: "4")
        voiceMenu.addItem(withTitle: "Cute (Default)", action: #selector(AppDelegate.setVoiceCute(_:)), keyEquivalent: "5")
        
        menu.addItem(voiceMenuItem)
        
        // 添加操作选项
        menu.addItem(withTitle: "Reset to center", action: #selector(AppDelegate.resetFluffelToCenter(_:)), keyEquivalent: "r")
        menu.addItem(withTitle: "Test voice", action: #selector(AppDelegate.testTTSFromMenu(_:)), keyEquivalent: "t")
        
        menu.addItem(NSMenuItem.separator())
        
        // 添加API密钥设置选项
        menu.addItem(withTitle: "Set Google Cloud API key", action: #selector(AppDelegate.showApiKeySettings(_:)), keyEquivalent: "k")
        menu.addItem(withTitle: "Fix network permissions", action: #selector(AppDelegate.openNetworkSettings(_:)), keyEquivalent: "n")
        
        menu.addItem(NSMenuItem.separator())
        
        // 添加退出选项
        menu.addItem(withTitle: "Quit", action: #selector(AppDelegate.quitApp(_:)), keyEquivalent: "q")
        
        // 为菜单项设置目标
        for item in menu.items {
            if item.action != nil {
                item.target = NSApp.delegate
            }
        }
        
        // 显示菜单
        NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent!, for: view)
    }
    
    /// 重建音乐菜单 - 供Fluffel类调用
    func rebuildMusicMenu() {
        print("Rebuilding music menu in FluffelScene")
        
        // 获取主菜单
        if let menu = NSApp.mainMenu?.item(withTitle: "Fluffel Menu")?.submenu {
            // 查找音乐菜单项
            if let musicMenuItem = menu.item(withTitle: "Listen to music") {
                // 清空现有子菜单
                if let musicMenu = musicMenuItem.submenu {
                    musicMenu.removeAllItems()
                    
                    // 重新添加音乐类别
                    for category in FluffelPixabayPlaylists.PlaylistCategory.allCases {
                        let categoryItem = NSMenuItem(
                            title: category.rawValue,
                            action: #selector(AppDelegate.showPlaylistWindow(_:)),
                            keyEquivalent: ""
                        )
                        categoryItem.representedObject = category
                        categoryItem.target = NSApp.delegate
                        musicMenu.addItem(categoryItem)
                    }
                    
                    // 添加分隔线和其他音乐选项
                    musicMenu.addItem(NSMenuItem.separator())
                    
                    // 添加随机播放选项
                    let shuffleAllItem = NSMenuItem(
                        title: "Shuffle All Music",
                        action: #selector(AppDelegate.playRandomTrackFromAll(_:)),
                        keyEquivalent: ""
                    )
                    shuffleAllItem.target = NSApp.delegate
                    musicMenu.addItem(shuffleAllItem)
                    
                    // 添加停止音乐选项
                    let stopItem = NSMenuItem(
                        title: "Stop Music",
                        action: #selector(AppDelegate.stopMusic(_:)),
                        keyEquivalent: ""
                    )
                    stopItem.target = NSApp.delegate
                    musicMenu.addItem(stopItem)
                }
            }
        }
    }
    
    /// 填充音乐菜单 - 供showContextMenu方法使用
    private func populateMusicMenu(_ musicMenu: NSMenu) {
        // 添加音乐类别
        for category in FluffelPixabayPlaylists.PlaylistCategory.allCases {
            let categoryItem = NSMenuItem(
                title: category.rawValue,
                action: #selector(AppDelegate.showPlaylistWindow(_:)),
                keyEquivalent: ""
            )
            categoryItem.representedObject = category
            categoryItem.target = NSApp.delegate
            musicMenu.addItem(categoryItem)
        }
        
        // 添加分隔线和其他音乐选项
        musicMenu.addItem(NSMenuItem.separator())
        
        // 添加随机播放选项
        let shuffleAllItem = NSMenuItem(
            title: "Shuffle All Music",
            action: #selector(AppDelegate.playRandomTrackFromAll(_:)),
            keyEquivalent: ""
        )
        shuffleAllItem.target = NSApp.delegate
        musicMenu.addItem(shuffleAllItem)
        
        // 添加停止音乐选项
        let stopItem = NSMenuItem(
            title: "Stop Music",
            action: #selector(AppDelegate.stopMusic(_:)),
            keyEquivalent: ""
        )
        stopItem.target = NSApp.delegate
        musicMenu.addItem(stopItem)
    }
    
    /// 开始播放音乐
    func startPlayingMusic(from url: URL) {
        // 确保 Fluffel 存在
        guard fluffel != nil else {
            print("Error: Cannot play music - Fluffel not found")
            return
        }
        
        print("Attempting to play music from URL: \(url)")
        
        // 停止现有音乐
        stopMusic()
        
        // 注意：macOS 不使用 AVAudioSession API，它是 iOS 专用的
        // 在 macOS 上不需要设置音频会话，系统会自动处理音频
        // 以下代码在 iOS 平台使用，在 macOS 上移除
        /*
        do {
            // 获取音频会话实例
            let session = AVAudioSession.sharedInstance()
            
            // 尝试设置为播放模式
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            print("Successfully configured audio session")
        } catch {
            print("Error setting up audio session: \(error.localizedDescription)")
        }
        */
        
        // 尝试先下载音频文件（如果是网络URL）
        if url.scheme == "http" || url.scheme == "https" {
            print("Downloading audio from network URL: \(url)")
            
            let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error downloading audio file: \(error.localizedDescription)")
                    return
                }
                
                if let data = data, data.count > 0 {
                    print("Successfully downloaded \(data.count) bytes of audio data")
                    self.playAudioFromData(data)
                } else {
                    print("Error: Downloaded audio data is empty")
                }
            }
            
            task.resume()
        } else {
            // 本地文件路径，直接创建播放器
            createAndPlayAudioPlayer(from: url)
        }
    }
    
    /// 从下载的数据播放音频
    private func playAudioFromData(_ data: Data) {
        do {
            let audioPlayer = try AVAudioPlayer(data: data)
            configureAndPlayAudioPlayer(audioPlayer)
        } catch {
            print("Failed to create audio player from downloaded data: \(error.localizedDescription)")
            printDetailedAudioPlayerError(error)
        }
    }
    
    /// 创建并播放音频播放器
    private func createAndPlayAudioPlayer(from url: URL) {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            configureAndPlayAudioPlayer(audioPlayer)
        } catch {
            print("Failed to create audio player from URL: \(error.localizedDescription)")
            printDetailedAudioPlayerError(error)
        }
    }
    
    /// 配置并播放音频播放器
    private func configureAndPlayAudioPlayer(_ audioPlayer: AVAudioPlayer) {
        print("Successfully created AVAudioPlayer instance")
        
        // 准备播放（预加载）
        audioPlayer.prepareToPlay()
        print("Audio player prepared to play")
        
        // 保存到 Fluffel 类的静态属性中
        Fluffel.musicPlayer = audioPlayer
        print("Set Fluffel.musicPlayer reference: \(Fluffel.musicPlayer != nil ? "Success" : "Failed")")
        
        // 设置音频播放器属性
        audioPlayer.volume = 1.0
        audioPlayer.numberOfLoops = 0 // 不循环
        audioPlayer.enableRate = true
        audioPlayer.rate = 1.0
        
        // 检查音频时长
        let duration = audioPlayer.duration
        print("Audio duration: \(duration) seconds")
        
        // 开始播放
        let playResult = audioPlayer.play()
        print("Audio playback started: \(playResult ? "Success" : "Failed")")
        
        if !playResult {
            print("Failed to start playback - checking audio player state")
            print("Is audio player valid: \(audioPlayer.isEqual(Fluffel.musicPlayer) ? "Yes" : "No")")
            print("Audio player current time: \(audioPlayer.currentTime)")
            print("Audio player duration: \(audioPlayer.duration)")
            print("Audio player volume: \(audioPlayer.volume)")
        } else {
            // 播放成功，发送通知
            NotificationCenter.default.post(name: .fluffelWillPlayMusic, object: self)
        }
    }
    
    /// 打印详细的音频播放器错误信息
    private func printDetailedAudioPlayerError(_ error: Error) {
        print("Audio Error Domain: \(error._domain)")
        print("Audio Error Code: \(error._code)")
        
        if let osError = error as? OSStatus {
            print("OSStatus Error: \(osError)")
            
            // 根据常见的错误代码提供更多信息
            switch Int(osError) {
            case -50:
                print("Error: Parameter error - check file format")
            case -43:
                print("Error: File not found")
            case -39:
                print("Error: End of file")
            case -208:
                print("Error: File already exists")
            case -38:
                print("Error: File not open")
            case 2003334207:
                print("Error: Audio format not supported or corrupted file")
            default:
                print("Unknown audio error")
            }
        }
    }
    
    /// 停止 Fluffel 播放音乐
    func stopMusic() {
        // 直接停止音频播放
        Fluffel.musicPlayer?.stop()
        Fluffel.musicPlayer = nil
        
        // 如果有 fluffel 实例，通知它停止动画但不调用其 stopMusic 方法
        if let fluffel = fluffel {
            // 只停止动画，不会引起递归
            fluffel.stopListeningToMusicAnimation()
        }
        
        print("Music playback stopped by FluffelScene")
    }
}

