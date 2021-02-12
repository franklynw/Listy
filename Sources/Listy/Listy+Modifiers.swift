//
//  Listy+Modifiers.swift
//  
//
//  Created by Franklyn Weber on 12/02/2021.
//

import SwiftUI


extension Listy {
    
    /// A title for the list. If none is provided, the list appears a just a list. If it is provided, the title works in an identical way to a NavigationController's large title
    /// which resizes to small & centres at the top in a "navBar" when the user scrolls up
    /// - Parameters:
    ///   - title: a binding to a String var used for the title
    ///   - color: a binding to a UIColor var used for the title's text colour
    public func title(_ title: Binding<String>, color: Binding<UIColor>? = nil) -> Self {
        return setTitle(title, color: color)
    }
    
    /// The colour to use for the "navBar" which will appear if he user scrolls up (only if a title is set)
    /// - Parameter color: a binding to a UIColor var used for the titleBar's colour
    public func titleBarColor(_ color: Binding<UIColor>) -> Self {
        return setTitleBarColor(color)
    }
    
    /// Long-pressing on the title will present a context menu if items are provided here
    /// - Parameter items: context menu items to present
    public func titleMenuItems(_ items: [ListyContextMenuItem]) -> Self {
        var copy = self
        copy.titleBarContextMenuItems = items
        return copy
    }
    
    /// Set this for a left "barButtonItem" to appear (requires that "title" is not nil)
    /// - Parameters:
    ///   - buttonItem: the buttonItem to use, can be a button or a menu
    public func leftBarItem(_ buttonItem: BarButtonType) -> Self {
        var copy = self
        copy.leftBarButtonItem = buttonItem
        return copy
    }
    
    /// Set this for a right "barButtonItem" to appear (requires that "title" is not nil)
    /// - Parameters:
    ///   - buttonItem: the buttonItem to use, can be a button or a menu
    public func rightBarItem(_ buttonItem: BarButtonType) -> Self {
        var copy = self
        copy.rightBarButtonItem = buttonItem
        return copy
    }
    
    /// If set to true, each list item will have a "reorder" icon for dragging to reorder
    /// - Parameter allowsRowDragToReorder: a binding to a Bool var which determines whether the items can be dragged to reorder
    public func allowsRowDragToReorder(_ allowsRowDragToReorder: Binding<Bool>) -> Self {
        return setAllowsRowDragToReorder(allowsRowDragToReorder)
    }
    
    /// The action which will be invoked after dragging & reordering
    /// - Parameter action: a closure with moved from & moved to parameters
    /// - NOTE: ** Not yet implemented **
    public func onMove(_ action: @escaping (Int, Int) -> ()) -> Self {
        return self
    }
    
    /// The action which will be invoked after swiping to delete
    /// - Parameter action: a closure with the item id parameter
    /// - NOTE: Swipe to delete doesn't appear unless this action has been provided
    public func onDelete(_ action: @escaping (String) -> ()) -> Self {
        var copy = self
        copy.deleteItem = action
        return copy
    }
    
    /// The action which will be invoked when the user taps a row
    /// - Parameter tapAction: a closure with the item identifier parameter
    public func onTapped(_ tapAction: @escaping (String) -> ()) -> Self {
        var copy = self
        copy.itemTapAction = tapAction
        return copy
    }
    
    /// Set this to make a context menu appear if the user long-presses on a list item
    /// - Parameter items: the context menu items
    public func itemContextMenuItems(_ items: [ListyContextMenuItem]) -> Self {
        var copy = self
        copy.itemContextMenuItems = items
        return copy
    }
    
    /// Applies an inset to the list content
    /// - Parameter contentInsets: an EdgeInsets value
    public func contentInsets(_ contentInsets: EdgeInsets) -> Self {
        var copy = self
        copy.contentInsets = contentInsets
        return copy
    }
    
    /// Applies an inset to the rows of the list
    /// - Parameter contentInsets: an EdgeInsets value
    public func rowPadding(_ rowPadding: EdgeInsets) -> Self {
        var copy = self
        copy.rowPadding = rowPadding
        return copy
    }
    
    /// Provides the vertical content offset of the scrollView
    /// - Parameter contentOffset: a binding to a CGFloat var
    public func observeContentOffset(_ contentOffset: Binding<CGFloat>) -> Self {
        return setContentOffset(contentOffset)
    }
    
    /// Used to force a refresh of the list contents
    /// - Parameter refresh: a binding to a Bool var - the refresh will happen whenever this value is toggled (slightly hacky I know...)
    public func refresh(_ refresh: Binding<Bool>) -> Self {
        return setRefresh(refresh)
    }
}
