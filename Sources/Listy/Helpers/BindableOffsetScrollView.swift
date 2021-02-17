//
//  BindableOffsetScrollView.swift
//
//  Created by Franklyn Weber on 29/01/2021
//

import SwiftUI


public struct BindableOffsetScrollView<Content>: View where Content: View {
    
    private let axes: Axis.Set
    private let showIndicators: Bool
    private let content: () -> Content
    
    private let tracker: ScrollViewOffsetTracker
    
    
    public init(forId id: String, axes: Axis.Set = .vertical, showIndicators: Bool = true, contentOffset: Binding<CGFloat>, @ViewBuilder content: @escaping () -> Content) {
        
        self.axes = axes
        self.showIndicators = showIndicators
        self.content = content
        
        tracker = ScrollViewOffsetTracker.tracker(forId: id)
        
        tracker.contentOffset = contentOffset
    }
    
    public var body: some View {
        
        GeometryReader { outsideGeometry in
            
            ScrollView(axes, showsIndicators: showIndicators) {
                
                ZStack(alignment: axes == .vertical ? .top : .leading) {
                    
                    GeometryReader { insideGeometry in
                        Color.clear
                        calculateOffset(fromOutside: outsideGeometry, toInside: insideGeometry)
                    }
                    
                    content()
                }
            }
        }
    }
    
    private func calculateOffset(fromOutside outsideGeometry: GeometryProxy, toInside insideGeometry: GeometryProxy) -> EmptyView {
        
        if axes == .vertical {
            tracker.offset = outsideGeometry.frame(in: .global).minY - insideGeometry.frame(in: .global).minY
        } else {
            tracker.offset = outsideGeometry.frame(in: .global).minX - insideGeometry.frame(in: .global).minX
        }
        
        return EmptyView()
    }
}


internal class ScrollViewOffsetTracker {
    
    private static var trackers: [String: ScrollViewOffsetTracker] = [:]
    
    var contentOffset: Binding<CGFloat>
    
    
    static func tracker(forId id: String) -> ScrollViewOffsetTracker {
        
        if let tracker = trackers[id] {
            return tracker
        }
        
        let tracker = ScrollViewOffsetTracker()
        trackers[id] = tracker
        
        return tracker
    }
    
    static func removeTracker(forId id: String) {
        trackers.removeValue(forKey: id)
    }
    
    private init() {
        contentOffset = Binding<CGFloat>(get: { 0 }, set: { _ in })
    }
    
    var offset: CGFloat = 0 {
        didSet {
            guard offset != oldValue else {
                return
            }
            DispatchQueue.main.async {
                self.contentOffset.wrappedValue = self.offset
            }
        }
    }
}
