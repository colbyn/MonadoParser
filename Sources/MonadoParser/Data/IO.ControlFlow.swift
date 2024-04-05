//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/5/24.
//

import Foundation
import PrettyTree

extension IO {
    public enum ControlFlow {
        case `continue`
        case `break`
    }
    public typealias ControlFlowParser = Parser<ControlFlow>
}

extension IO.ControlFlow {
    public var isContinue: Bool {
        switch self {
        case .continue: return true
        default: return false
        }
    }
    public var isBreak: Bool {
        switch self {
        case .break: return true
        default: return false
        }
    }
}

// MARK: - DEBUG -
extension IO.ControlFlow: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .continue: return .value("ControlFlow.continue")
        case .break: return .value("ControlFlow.break")
        }
    }
}
