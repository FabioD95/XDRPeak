// XDRPeak — Peak XDR brightness for your Mac display.
// Copyright (C) 2026 Fabio Del Rio
// SPDX-License-Identifier: GPL-3.0-or-later
// This file is part of XDRPeak. See LICENSE for full terms.
//

import Cocoa
import MetalKit

/// Places a 1×1 HDR pixel in the top-left corner of the screen so macOS
/// switches the display into EDR mode. The pixel is invisible to the user
/// but tells the window server "there's HDR content on screen", which
/// unlocks brightness beyond the 100-nit SDR ceiling.
///
/// Technique: BrightIntosh by Niklas Rousset.
final class HDRPixelTrigger {

    private var window: NSWindow?
    private var metalView: HDRPixelView?
    private let screen: NSScreen

    init(screen: NSScreen) {
        self.screen = screen
    }

    func show() {
        let rect = NSRect(
            x: screen.frame.origin.x,
            y: screen.frame.origin.y + screen.frame.height - 1,
            width: 1, height: 1
        )

        let win = NSWindow(
            contentRect: rect,
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.hasShadow = false
        win.backgroundColor = .clear
        win.ignoresMouseEvents = true
        win.level = .screenSaver
        win.canHide = false
        win.isReleasedWhenClosed = false
        win.hidesOnDeactivate = false
        win.collectionBehavior = [.stationary, .ignoresCycle, .canJoinAllSpaces]

        let view = HDRPixelView(frame: NSRect(x: 0, y: 0, width: 1, height: 1), screen: screen)
        win.contentView = view
        win.orderFrontRegardless()

        window = win
        metalView = view
    }

    func close() {
        window?.close()
        window = nil
        metalView = nil
    }
}

/// 1×1 `MTKView` that renders an EDR-valued clear color. The numeric clear
/// value comes from the screen's actual EDR capabilities; the formula matches
/// BrightIntosh's:
///
///     factor = max(maxEDR / max(maxRenderedEDR, 1.0) - 1.0, 1.0)
private final class HDRPixelView: MTKView, MTKViewDelegate {

    private let edrColorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
    private var commandQueue: MTLCommandQueue?

    init(frame: CGRect, screen: NSScreen) {
        super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
        commandQueue = device?.makeCommandQueue()

        delegate = self
        autoResizeDrawable = false
        drawableSize = CGSize(width: 1, height: 1)
        colorPixelFormat = .rgba16Float
        colorspace = edrColorSpace
        preferredFramesPerSecond = 5

        if let layer = layer as? CAMetalLayer {
            layer.wantsExtendedDynamicRangeContent = true
            layer.isOpaque = false
            layer.pixelFormat = .rgba16Float
        }

        updateClearColor(for: screen)
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func updateClearColor(for screen: NSScreen) {
        let maxEDR = screen.maximumExtendedDynamicRangeColorComponentValue
        let maxRendered = screen.maximumReferenceExtendedDynamicRangeColorComponentValue
        let factor = max(maxEDR / max(maxRendered, 1.0) - 1.0, 1.0)
        clearColor = MTLClearColorMake(Double(factor), Double(factor), Double(factor), 1.0)
    }

    func draw(in view: MTKView) {
        guard let queue = commandQueue,
              let descriptor = view.currentRenderPassDescriptor,
              let buffer = queue.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        // No geometry — clearColor IS the HDR pixel.
        encoder.endEncoding()
        if let drawable = view.currentDrawable {
            buffer.present(drawable)
        }
        buffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
}
