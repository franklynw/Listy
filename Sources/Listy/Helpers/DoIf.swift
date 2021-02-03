//
//  DoIf.swift
//
//  Created by Franklyn Weber on 30/01/2021.
//

import SwiftUI


struct DoIf: View {
    
    private var binding: Binding<Bool>
    private let action: () -> ()
    private let otherAction: (() -> ())?
    
    
    init(_ isTrue: Binding<Bool>, _ action: @escaping () -> ()) {
        binding = isTrue
        self.action = action
        self.otherAction = nil
    }
    
    init(_ isTrue: Binding<Bool>, _ action: @escaping () -> (), else otherAction: @escaping () -> ()) {
        binding = isTrue
        self.action = action
        self.otherAction = otherAction
    }
    
    var body: some View {
        
        return If(binding) { () -> EmptyView in
            self.action()
            return EmptyView()
        } else: { () -> EmptyView in
            self.otherAction?()
            return EmptyView()
        }
    }
}


struct DoIfLet<T>: View {
    
    private var binding: Binding<T?>
    private let action: (T) -> ()
    private let otherAction: (() -> ())?
    
    
    init(_ item: Binding<T?>, _ action: @escaping (T) -> ()) {
        binding = item
        self.action = action
        self.otherAction = nil
    }
    
    init(_ item: Binding<T?>, _ action: @escaping (T) -> (), else otherAction: @escaping () -> ()) {
        binding = item
        self.action = action
        self.otherAction = otherAction
    }
    
    var body: some View {
        
        return IfLet(binding) { item -> EmptyView in
            self.action(item)
            return EmptyView()
        } else: { () -> EmptyView in
            self.otherAction?()
            return EmptyView()
        }
    }
}
