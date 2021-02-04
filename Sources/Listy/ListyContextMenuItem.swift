//
//  ListyContextMenuItem.swift
//
//  Created by Franklyn Weber on 30/01/2021.
//

import SwiftUI
import FWCommonProtocols


public struct ListyContextMenuItem: Identifiable {
    
    public let id: String
    
    let title: String
    let iconName: SystemImageNaming?
    let shouldAppear: ((String) -> Bool)
    let action: ((String) -> ())?
    let itemType: MenuItemType
    
    enum MenuItemType: Equatable {
        case button
        case menu(subMenuItems: (String) -> [ListyContextMenuItem])
        
        static func == (lhs: MenuItemType, rhs: MenuItemType) -> Bool {
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
    
    
    /// Initialiser for a button item
    /// - Parameters:
    ///   - title: the menu item's title
    ///   - systemImage: a systemImage to use for the icon - if nil, no icon will appear
    ///   - shouldAppear: a closure to control whether or not the menu item should appear
    ///   - action: the action invoked when the item is selected
    /// - Returns: a ListyContextMenuItem instance
    public init(title: String, systemImage: SystemImageNaming? = nil, shouldAppear: ((String) -> Bool)? = nil, action: @escaping (String) -> ()) {
        id = UUID().uuidString
        itemType = .button
        self.title = title
        self.iconName = systemImage
        self.shouldAppear = shouldAppear ?? { _ in return true }
        self.action = action
    }
    
    /// Initialiser for a sub-menu item
    /// - Parameters:
    ///   - title: the menu item's title
    ///   - systemImage: a systemImage to use for the icon - if nil, no icon will appear
    ///   - shouldAppear: a closure to control whether or not the menu item should appear
    ///   - subMenuItems: the sub-menu items which will apeear when this item is selected
    /// - Returns: a ListyContextMenuItem instance
    public init(title: String, systemImage: SystemImageNaming? = nil, shouldAppear: ((String) -> Bool)? = nil, subMenuItems: @escaping (String) -> [ListyContextMenuItem]) {
        id = UUID().uuidString
        itemType = .menu(subMenuItems: subMenuItems)
        self.title = title
        self.iconName = systemImage
        self.shouldAppear = shouldAppear ?? { _ in return true }
        action = nil
    }
    
    /// The view for this menuItem
    /// - Parameter itemId: the item's id
    /// - Returns: an AnyView instance, either a button row or a sub-menu row
    public func item(itemId: String) -> AnyView {
        
        if shouldAppear(itemId) == true {
            
            switch itemType {
            case .button:
                
                let button = Button(action: {
                    self.action?(itemId)
                }) {
                    Text(self.title)
                    
                    if let iconName = iconName {
                        Image(systemName: iconName.systemImageName)
                    }
                }
                
                return AnyView(button)
                
            case .menu(let subMenuItems):
                
                let menu = Menu {
                    ForEach(subMenuItems(itemId)) { menuItem in
                        menuItem.item(itemId: itemId)
                    }
                } label: {
                    Label(self.title, systemImage: iconName?.systemImageName ?? "chevron.right")
                }
                
                return AnyView(menu)
            }
            
        }
        
        return AnyView(EmptyView())
    }
}
