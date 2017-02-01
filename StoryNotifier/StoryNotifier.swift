//
//  StoryNotifier.swift
//  StoryNotifier
//
//  Created by CenoX on 2016. 12. 29..
//  Copyright © 2016년 Team Vanilla. All rights reserved.
//

import Cocoa

class StoryNotifier: NSApplication {
    override func sendEvent(_ event: NSEvent) {
        if event.type == NSEventType.keyDown {
            
            if (event.modifierFlags.contains(NSEventModifierFlags.command)) {
                switch event.charactersIgnoringModifiers!.lowercased() {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return }
                case "a":
                    if NSApp.sendAction(#selector(NSText.selectAll(_:)), to:nil, from:self) { return }
                default:
                    break
                }
            }
        }
        return super.sendEvent(event)
    }
}
