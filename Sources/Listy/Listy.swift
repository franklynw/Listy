//
//  Listy.swift
//
//  Created by Franklyn Weber on 29/01/2021.
//

import SwiftUI
import UniformTypeIdentifiers
import SwiftUITrackableScrollView


public struct Listy<DataSource: ListyDataSource>: View {
    
    typealias ItemViewModel = DataSource.ListyItemType.ViewModelType
    
    @StateObject private var dataSource: DataSource
    
    @State private var currentlyDraggedItem: ItemViewModel?
    @State private var changedView = false
    @State private var draggingFinished = false
    
    @State private var titleScale: CGFloat = 0.9
    @State private var barOpacity: Double = 0
    @State private var smallTitleOpacity: Double = 0
    @State private var largeTitleOpacity: Double = 1
    
    @Binding private var refresh: Bool
    @Binding private var allowsRowDragToReorder: Bool
    @Binding private var titleBarColor: UIColor
    @Binding private var title: String
    @Binding private var titleColor: UIColor
    
    private var leftBarButtonAction: (() -> ())?
    private var leftBarButtonImageName: String?
    private var rightBarButtonAction: (() -> ())?
    private var rightBarButtonImageName: String?
    private var itemTapAction: ((String) -> ())?
    private var itemContextMenuItems: [ListyContextMenuItem] = []
    private var titleBarContextMenuItems: [ListyContextMenuItem] = []
    
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
            }
        )
    }
    
    
    private let titleInitialOffset: CGFloat = 15
    private let spaceForLargeTitle: CGFloat = largeTitleSpace / 2
    private let titleScaleMultiplier: CGFloat = 500
    private let minTitleScale: CGFloat = 0.9
    private let mainTitleDisappearedDistance: CGFloat = 26
    private let smallTitleFadeSpeed: CGFloat = 4
    
    
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
                        .frame(height: 44)
                        .overlay(
                            Rectangle()
                                .foregroundColor(Color(titleBarColor))
                        )
                    
                    HStack {
                        
                        Button {
                            leftBarButtonAction?()
                        } label: {
                            Image(systemName: leftBarButtonAction == nil ? "gearshape" : leftBarButtonImageName!)
                                .resizable()
                                .frame(width: 22, height: 22)
                                .opacity(leftBarButtonAction == nil ? 0 : 1)
                                .font(Font.title3.weight(.light))
                                .accentColor(Color(titleColor))
                        }
                        .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 8))
                        
                        Spacer()
                        
                        Text(title)
                            .customFont(name: "Helvetica", weight: .semibold, relativeTo: .title3, maxSize: 24)
                            .foregroundColor(Color(titleColor))
                            .opacity(smallTitleOpacity)
                            .animation(.linear)
                            .contextMenu(menuItems: { titleBarMenuItems() })
                        
                        Spacer()
                        
                        Button {
                            rightBarButtonAction?()
                        } label: {
                            Image(systemName: rightBarButtonAction == nil ? "gearshape" : rightBarButtonImageName!)
                                .resizable()
                                .frame(width: 22, height: 22)
                                .opacity(rightBarButtonAction == nil ? 0 : 1)
                                .font(Font.title3.weight(.light))
                                .accentColor(Color(titleColor))
                        }
                        .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 12))
                    }
                }
            }
            
            TrackableScrollView(Axis.Set.vertical, showIndicators: true, contentOffset: scrollViewOffset) {
                
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
                
                ForEach(dataSource.listItemViewModels) { listItemViewModel in
                    
                    HStack {
                        
                        DataSource.ListyItemType(viewModel: listItemViewModel, itemContextMenuItems: itemContextMenuItems)
                            .dragged($currentlyDraggedItem)
                            .onTapGesture {
                                currentlyDraggedItem = nil
                                itemTapAction?(listItemViewModel.id)
                            }
                            
                        Spacer()
                                
                        if allowsRowDragToReorder {
                            
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
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                .id(refresh)
            }
            .onDrop(of: [UTType.text], delegate: DraggingFailedDelegate<DataSource>(currentlyDraggedItem: $currentlyDraggedItem, changedView: $changedView, draggingFinished: $draggingFinished))
            .offset(y: _title.wrappedValue.isEmpty ? 0 : -8)
        }
        .lineLimit(1)
    }
    
    private func titleBarMenuItems() -> ForEach<[ListyContextMenuItem], String, TupleView<(If, If)>> {
        
        return ForEach(titleBarContextMenuItems) { menuItem in
            If(menuItem.itemType.isButton) {
                menuItem.button(itemId: "")
            }
            If(menuItem.itemType.isMenu) {
                menuItem.menu(itemId: "")
            }
        }
    }
}


extension Listy {
    
    public func title(_ title: Binding<String>, color: Binding<UIColor>? = nil) -> Self {
        var copy = self
        copy._title = title
        if let color = color {
            copy._titleColor = color
        }
        return copy
    }
    
    public func titleBarColor(_ color: Binding<UIColor>) -> Self {
        var copy = self
        copy._titleBarColor = color
        return copy
    }
    
    public func titleMenuItems(_ items: [ListyContextMenuItem]) -> Self {
        var copy = self
        copy.titleBarContextMenuItems = items
        return copy
    }
    
    public func leftBarItem(imageSystemName: String, action: @escaping () -> ()) -> Self {
        var copy = self
        copy.leftBarButtonImageName = imageSystemName
        copy.leftBarButtonAction = action
        return copy
    }
    
    public func rightBarItem(imageSystemName: String, action: @escaping () -> ()) -> Self {
        var copy = self
        copy.rightBarButtonImageName = imageSystemName
        copy.rightBarButtonAction = action
        return copy
    }
    
    public func allowsRowDragToReorder(_ allowsRowDragToReorder: Binding<Bool>) -> Self {
        var copy = self
        copy._allowsRowDragToReorder = allowsRowDragToReorder
        return copy
    }
    
    public func onMove(_ action: @escaping (Int, Int) -> ()) -> Self {
        return self
    }
    
    public func onTapped(_ tapAction: @escaping (String) -> ()) -> Self {
        var copy = self
        copy.itemTapAction = tapAction
        return copy
    }
    
    public func itemContextMenuItems(_ items: [ListyContextMenuItem]) -> Self {
        var copy = self
        copy.itemContextMenuItems = items
        return copy
    }
    
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
