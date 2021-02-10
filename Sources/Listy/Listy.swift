//
//  Listy.swift
//
//  Created by Franklyn Weber on 29/01/2021.
//

import SwiftUI
import UniformTypeIdentifiers
import FWCommonProtocols


public struct Listy<DataSource: ListyDataSource>: View {
    
    typealias ItemViewModel = DataSource.ListyItemType.ViewModelType
    
    @StateObject private var dataSource: DataSource
    
    @State internal var currentlyDraggedItem: ItemViewModel?
    @State private var changedView = false
    @State internal var draggingFinished = false
    
    @State private var titleScale: CGFloat = 0.9
    @State private var barOpacity: Double = 0
    @State private var smallTitleOpacity: Double = 0
    @State private var largeTitleOpacity: Double = 1
    @State internal var swipeDelete = SwipeDelete(itemId: "", offset: 0)
    @State internal var swipeDeletedId: String?
    @State internal var swipeCommitted = false
    @State internal var initialSwipeOffset: CGFloat = 0
    
    internal let textPadding: CGFloat = 8
    
    @Binding private var refresh: Bool
    @Binding private var allowsRowDragToReorder: Bool
    @Binding private var titleBarColor: UIColor
    @Binding private var title: String
    @Binding private var titleColor: UIColor
    
    private var contentInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    private var rowPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    private var leftBarButtonItem: BarButtonType?
    private var rightBarButtonItem: BarButtonType?
    private var itemTapAction: ((String) -> ())?
    private var itemContextMenuItems: [ListyContextMenuItem] = []
    private var titleBarContextMenuItems: [ListyContextMenuItem] = []
    internal var deleteItem: ((String) -> ())?
    
    var scrollViewOffset: Binding<CGFloat> {
        Binding<CGFloat>(
            get: {
                return 0
            },
            set: {
                
                let scale = min(max(minTitleScale, -$0 / titleScaleMultiplier + minTitleScale), 1)
                titleScale = scale
                
                let opacity = min(max($0 / mainTitleDisappearedDistance, 0), 1)
                barOpacity = Double(opacity)
                smallTitleOpacity = $0 >= mainTitleDisappearedDistance ? 1 : 0
                largeTitleOpacity = 1 - smallTitleOpacity
                
                swipeDidEnd()
            }
        )
    }
    
    private let titleInitialOffset: CGFloat = 15
    private let spaceForLargeTitle: CGFloat = largeTitleSpace / 2
    private let titleScaleMultiplier: CGFloat = 500
    private let minTitleScale: CGFloat = 0.9
    private let mainTitleDisappearedDistance: CGFloat = 26
    private let smallTitleFadeSpeed: CGFloat = 4
    
    public enum BarButtonType {
        case button(iconName: SystemImageNaming, action: () -> ())
        case menu(menuItems: [ListyContextMenuItem], iconName: SystemImageNaming)
        
        func button(_ color: UIColor) -> AnyView {

            switch self {
            case .button(let iconName, let action):

                let button = Button {
                    action()
                } label: {
                    Image(systemName: iconName.systemImageName)
                        .resizable()
                        .frame(width: 22, height: 22)
                        .font(Font.title3.weight(.light))
                        .accentColor(Color(color))
                }
                
                return AnyView(button)

            case .menu(let menuItems, let iconName):
                
                let menu = Menu {
                    ForEach(menuItems) { menuItem in
                        menuItem.item(itemId: "")
                    }
                } label: {
                    Image(systemName: iconName.systemImageName)
                        .resizable()
                        .frame(width: 22, height: 22)
                        .font(Font.title3.weight(.light))
                        .accentColor(Color(color))
                }

                return AnyView(menu)
            }
        }
        
        static var emptyButton: AnyView {
            
            let image = Image(systemName: "")
                .resizable()
                .frame(width: 22, height: 22)
                .font(Font.title3.weight(.light))
                .opacity(0)
            
            return AnyView(image)
        }
    }
    
    
    public init(_ viewModel: DataSource) {
        _dataSource = StateObject(wrappedValue: viewModel)
        _refresh = Binding<Bool>(get: { false }, set: { _ in })
        _allowsRowDragToReorder = Binding<Bool>(get: { false }, set: { _ in })
        _titleBarColor = Binding<UIColor>(get: { .clear }, set: { _ in })
        _title = Binding<String>(get: { "" }, set: { _ in })
        _titleColor = Binding<UIColor>(get: { .label }, set: { _ in })
    }
    
    public var body: some View {
        
        VStack {
            
            DoIf($draggingFinished) {
                dataSource.updateWithReorderedItems()
            }
            
            if !title.isEmpty {
                
                ZStack {
                    
                    Rectangle()
                        .foregroundColor(.white)
                        .opacity(barOpacity)
                        .frame(height: 48)
                        .overlay(
                            Rectangle()
                                .foregroundColor(Color(titleBarColor))
                        )
                    
                    HStack {
                        
                        if let leftBarButtonItem = leftBarButtonItem {
                            leftBarButtonItem.button(titleColor)
                                .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 8))
                        } else {
                            BarButtonType.emptyButton
                                .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 8))
                        }
                        
                        Spacer()
                        
                        Text(title)
                            .customFont(name: "Helvetica", weight: .semibold, relativeTo: .title3, maxSize: 24)
                            .foregroundColor(Color(titleColor))
                            .opacity(smallTitleOpacity)
                            .animation(.linear)
                            .contextMenu(menuItems: { titleBarMenuItems() })
                        
                        Spacer()
                        
                        if let rightBarButtonItem = rightBarButtonItem {
                            rightBarButtonItem.button(titleColor)
                                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 12))
                        } else {
                            BarButtonType.emptyButton
                                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 12))
                        }
                    }
                }
            }
            
            TrackableScrollView(Axis.Set.vertical, showIndicators: true, contentOffset: scrollViewOffset) {
                
                VStack {
                    HStack {
                        Text(title)
                            .multilineTextAlignment(.leading)
                            .font(Font.title.weight(.semibold))
                            .foregroundColor(Color(titleColor))
                            .opacity(largeTitleOpacity)
                            .animation(.linear)
                            .scaleEffect(CGSize(width: titleScale, height: titleScale), anchor: .leading)
                            .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 0))
                            .contextMenu(menuItems: { titleBarMenuItems() })
                        
                        Spacer()
                    }
                    
                    VStack {
                        ForEach(dataSource.listItemViewModels) { listItemViewModel in
                            
                            HStack {
                                
                                GeometryReader { geometry in
                                    
                                    DataSource.ListyItemType(viewModel: listItemViewModel, itemContextMenuItems: itemContextMenuItems)
                                        .dragged($currentlyDraggedItem)
                                        .offset(x: swipeDelete.itemId == listItemViewModel.id ? min(swipeDelete.offset, 0) : 0)
                                        .opacity(swipeDeletedId == listItemViewModel.id ? 0 : 1)
                                        .onTapGesture {
                                            if initialSwipeOffset == 0 {
                                                itemTapAction?(listItemViewModel.id)
                                            }
                                            currentlyDraggedItem = nil
                                            swipeDidEnd()
                                        }
                                        .gesture(swipeToDeleteGesture(with: geometry, forItemWithId: listItemViewModel.id))
                                    
                                    if swipeDelete.itemId == listItemViewModel.id {
                                        swipeToDeleteView(geometry: geometry)
                                            .animation(.easeOut(duration: 0.2))
                                    }
                                }
                                
                                Spacer()
                                
                                if allowsRowDragToReorder, dataSource.listItemViewModels.count > 1 {
                                    
                                    Image(systemName: "line.horizontal.3")
                                        .foregroundColor(Color(.systemGray))
                                        .opacity(0.5)
                                        .padding(EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5))
                                        .contentShape(Rectangle())
                                        .onDrag {
                                            draggingFinished = false
                                            withAnimation {
                                                currentlyDraggedItem = listItemViewModel
                                            }
                                            return NSItemProvider(object: listItemViewModel.id as NSString)
                                        }
                                }
                            }
                            .onDrop(of: [UTType.text], delegate: DraggingDelegate<DataSource>(item: listItemViewModel, dataSource: dataSource, viewModels: $dataSource.listItemViewModels, currentlyDraggedItem: $currentlyDraggedItem, changedView: $changedView, draggingFinished: $draggingFinished))
                            
                        }
                        .animation(.default, value: dataSource.listItemViewModels)
                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20) + rowPadding)
                        .id(refresh)
                    }
                }
                .padding(contentInsets)
            }
            .onDrop(of: [UTType.text], delegate: DraggingFailedDelegate<DataSource>(currentlyDraggedItem: $currentlyDraggedItem, changedView: $changedView, draggingFinished: $draggingFinished))
            .offset(y: _title.wrappedValue.isEmpty ? 0 : -8)
        }
        .lineLimit(1)
    }
    
    private func titleBarMenuItems() -> ForEach<[ListyContextMenuItem], String, AnyView> {
        
        return ForEach(titleBarContextMenuItems) { menuItem in
            menuItem.item(itemId: "")
        }
    }
}


extension Listy {
    
    /// A title for the list. If none is provided, the list appears a just a list. If it is provided, the title works in an identical way to a NavigationController's large title
    /// which resizes to small & centres at the top in a "navBar" when the user scrolls up
    /// - Parameters:
    ///   - title: a binding to a String var used for the title
    ///   - color: a binding to a UIColor var used for the title's text colour
    public func title(_ title: Binding<String>, color: Binding<UIColor>? = nil) -> Self {
        var copy = self
        copy._title = title
        if let color = color {
            copy._titleColor = color
        }
        return copy
    }
    
    /// The colour to use for the "navBar" which will appear if he user scrolls up (only if a title is set)
    /// - Parameter color: a binding to a UIColor var used for the titleBar's colour
    public func titleBarColor(_ color: Binding<UIColor>) -> Self {
        var copy = self
        copy._titleBarColor = color
        return copy
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
        var copy = self
        copy._allowsRowDragToReorder = allowsRowDragToReorder
        return copy
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
    
    /// Used to force a refresh of the list contents
    /// - Parameter refresh: a binding to a Bool var - the refresh will happen whenever this value is toggled (slightly hacky I know...)
    public func refresh(_ refresh: Binding<Bool>) -> Self {
        var copy = self
        copy._refresh = refresh
        return copy
    }
}


fileprivate var largeTitleSpace: CGFloat {
    
    let label = UILabel()
    label.font = UIFont.preferredFont(style: .largeTitle)
    label.text = "T"
    
    let height = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).height
    let titleHeight = height * 2.395
    
    return titleHeight
}


fileprivate extension EdgeInsets {
    
    static func +(_ lhs: EdgeInsets, _ rhs: EdgeInsets) -> EdgeInsets {
        EdgeInsets(top: lhs.top + rhs.top, leading: lhs.leading + rhs.leading, bottom: lhs.bottom + rhs.bottom, trailing: lhs.trailing + rhs.trailing)
    }
}
