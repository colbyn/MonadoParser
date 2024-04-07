//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/6/24.
//

import Foundation

extension IO {
    public struct Lines<Prefix, Content> {
        /// The startings tokens of each line.
        let lineStarts: [Prefix]
        /// The parsed sub-content.
        let content: Content
    }
}
