//
//  ListyContextMenuItem.swift
//
//  Created by Franklyn Weber on 30/01/2021.
//

import SwiftUI


public struct ListyContextMenuItem: Identifiable {
    
    public let id: String
    let title: String
    let iconName: String?
    let shouldAppear: ((String) -> Bool)
    let action: ((String) -> ())?
    
    let itemType: MenuItemType
    
    public enum MenuItemType: Equatable {
        case button
        case menu(subMenuItems: (String) -> [ListyContextMenuItem])
        
        public static func == (lhs: MenuItemType, rhs: MenuItemType) -> Bool {
            switch (lhs, rhs) {
            case (.button, .button), (.menu, .menu):
                return true
            default:
                return false
            }
        }
        
        var isButton: Bool {
            if case .button = self {
                return true
            }
            return false
        }
        var isMenu: Bool {
            if case .menu = self {
                return true
            }
            return false
        }
        
        func subMenuItems(parentId: String) -> [ListyContextMenuItem] {
            switch self {
            case .button:
                return []
            case .menu(let subMenuItems):
                return subMenuItems(parentId)
            }
        }
    }
    
    
    public init(title: String, systemImage: String? = nil, shouldAppear: ((String) -> Bool)? = nil, action: @escaping (String) -> ()) {
        id = UUID().uuidString
        itemType = .button
        self.title = title
        self.iconName = systemImage
        self.shouldAppear = shouldAppear ?? { _ in return true }
        self.action = action
    }
    
    public init(title: String, systemImage: String? = nil, shouldAppear: ((String) -> Bool)? = nil, subMenuItems: @escaping (String) -> [ListyContextMenuItem]) {
        id = UUID().uuidString
        itemType = .menu(subMenuItems: subMenuItems)
        self.title = title
        self.iconName = systemImage
        self.shouldAppear = shouldAppear ?? { _ in return true }
        action = nil
    }
    
    func button(itemId: String) -> AnyView {
        
        if shouldAppear(itemId) == true {
            
            let button = Button(action: {
                self.action?(itemId)
            }) {
                Text(self.title)
                
                if let iconName = iconName {
                    Image(systemName: iconName)
                }
            }
            
            return AnyView(button)
        }
        
        return AnyView(EmptyView())
    }
    
    func menu(itemId: String) -> AnyView {
        
        if shouldAppear(itemId) {
            
            let menu = Menu {
                ForEach(self.itemType.subMenuItems(parentId: itemId)) { menuItem in
                    If(menuItem.itemType.isButton) {
                        menuItem.button(itemId: itemId)
                    }
                    If(menuItem.itemType.isMenu) {
                        menuItem.menu(itemId: itemId)
                    }
                }
            } label: {
                Label(self.title, systemImage: iconName ?? "chevron.right")
            }
            
            return AnyView(menu)
        }
        
        return AnyView(EmptyView())
    }
}
