//
//  File.swift
//  
//
//  Created by Nathan Harris on 9/16/20.
//

import Context
import NIO

public protocol EventLoopContextCarrier: Context {
    var eventLoop: EventLoop { get }
}

extension ChannelHandlerContext: EventLoopContextCarrier { }
