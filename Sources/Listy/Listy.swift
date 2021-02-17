//
//  Listy.swift
//
//  Created by Franklyn Weber on 29/01/2021.
//

import SwiftUI
import UniformTypeIdentifiers
import FWCommonProtocols
import ButtonConfig


public struct Listy<DataSource: ListyDataSource>: View {
    
    typealias ItemViewModel = DataSource.ListyItemType.ViewModelType
    
    @StateObject private var dataSource: DataSource
    
    @State internal var currentlyDraggedItem: ItemViewModel?
    @State private var changedView = false
    @State internal var draggingFinished = true
    
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
    @Binding private var contentOffset: CGFloat
    
    internal var contentInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    internal var rowPadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    internal var leftBarButtonItem: BarButtonType?
    internal var rightBarButtonItem: BarButtonType?
    internal var itemTapAction: ((String) -> ())?
    internal var itemContextMenuItems: [ListyContextMenuItem] = []
    internal var titleBarContextMenuItems: [ListyContextMenuItem] = []
    internal var deleteItem: ((String) -> ())?
    
    var scrollViewOffset: Binding<CGFloat> {
        Binding<CGFloat>(
            get: {
                return 0
            },
            set: {
                
                contentOffset = $0
                
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
    
    private let id: String
    
    public enum BarButtonType {
        case button(iconName: SystemImageNaming, action: () -> ())
        case menu(menuItems: [ButtonConfig], iconName: SystemImageNaming)
        
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
                        .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8))
                }
                
                return AnyView(button)

            case .menu(let menuItems, let iconName):
                
                let menu = Menu {
                    ForEach(menuItems) { menuItem in
                        menuItem.item()
                    }
                } label: {
                    Image(systemName: iconName.systemImageName)
                        .resizable()
                        .frame(width: 22, height: 22)
                        .font(Font.title3.weight(.light))
                        .accentColor(Color(color))
                        .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8))
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
                .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8))
            
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
        _contentOffset = Binding<CGFloat>(get: { 0 }, set: { _ in })
        
        id = viewModel.id
    }
    
    public var body: some View {
        
        VStack {
            
            DoIf($draggingFinished) {
                if draggingFinished && ListyUpdateCoordinator.shouldForceUpdate {
                    dataSource.updateWithReorderedItems()
                    ListyUpdateCoordinator.shouldForceUpdate = false
                }
            } else: {
                ListyUpdateCoordinator.shouldForceUpdate = true
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
                                .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        } else {
                            BarButtonType.emptyButton
                                .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
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
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                        } else {
                            BarButtonType.emptyButton
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                        }
                    }
                }
            }
            
            BindableOffsetScrollView(forId: dataSource.id, axes: Axis.Set.vertical, showIndicators: true, contentOffset: scrollViewOffset) {
                
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
                                
//                                GeometryReader { geometry in
                                    
                                    DataSource.ListyItemType(viewModel: listItemViewModel, itemContextMenuItems: itemContextMenuItems)
                                        .dragged($currentlyDraggedItem)
//                                        .offset(x: swipeDelete.itemId == listItemViewModel.id ? min(swipeDelete.offset, 0) : 0)
//                                        .opacity(swipeDeletedId == listItemViewModel.id ? 0 : 1)
                                        .onTapGesture {
                                            if initialSwipeOffset == 0 {
                                                itemTapAction?(listItemViewModel.id)
                                            }
                                            currentlyDraggedItem = nil
//                                            swipeDidEnd()
                                        }
//                                        .gesture(swipeToDeleteGesture(with: geometry, forItemWithId: listItemViewModel.id))
                                    
//                                    if swipeDelete.itemId == listItemViewModel.id {
//                                        swipeToDeleteView(geometry: geometry)
//                                            .animation(.easeOut(duration: 0.2))
//                                    }
//                                }
                                
                                Spacer()
                                
                                if allowsRowDragToReorder, dataSource.listItemViewModels.count > 1 {
                                    
                                    Image(systemName: "line.horizontal.3")
                                        .foregroundColor(Color(.systemGray))
                                        .opacity(0.5)
                                        .padding(EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5))
                                        .contentShape(Rectangle())
                                        .onDrag {
                                            
                                            if draggingFinished {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            }
                                            
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
        .onDisappear {
            ScrollViewOffsetTracker.removeTracker(forId: id)
        }
    }
    
    private func titleBarMenuItems() -> ForEach<[ListyContextMenuItem], String, AnyView> {
        
        return ForEach(titleBarContextMenuItems) { menuItem in
            menuItem.item(itemId: "")
        }
    }
}


fileprivate class ListyUpdateCoordinator {
    static var shouldForceUpdate = true
}


// MARK: - for modifiers
extension Listy {
    
    // Bindings are wrappers around vars which are always private, so we can't modify them outside this file regardless of their access
    
    internal func setTitle(_ title: Binding<String>, color: Binding<UIColor>? = nil) -> Self {
        var copy = self
        copy._title = title
        if let color = color {
            copy._titleColor = color
        }
        return copy
    }
    
    internal func setTitleBarColor(_ color: Binding<UIColor>) -> Self {
        var copy = self
        copy._titleBarColor = color
        return copy
    }
    
    internal func setAllowsRowDragToReorder(_ allowsRowDragToReorder: Binding<Bool>) -> Self {
        var copy = self
        copy._allowsRowDragToReorder = allowsRowDragToReorder
        return copy
    }
    
    internal func setRefresh(_ refresh: Binding<Bool>) -> Self {
        var copy = self
        copy._refresh = refresh
        return copy
    }
    
    internal func setContentOffset(_ contentOffset: Binding<CGFloat>) -> Self {
        var copy = self
        copy._contentOffset = contentOffset
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
