//
//  GZImageLayoutViewDelegates.swift
//  Flingy
//
//  Created by Grady Zhuo on 2/13/15.
//  Copyright (c) 2015 Grady Zhuo. All rights reserved.
//

import Foundation

protocol GZImageLayoutViewDelegate{
    func layoutViewDidChangeHighlightPosition(layoutView:GZImageLayoutView, didChangeToPosition position:GZPosition?)
}