//
//  Protocols.swift
//  Listy
//
//  Created by Franklyn Weber on 01/02/2021.
//

import SwiftUI


public protocol ListyDataSource: ObservableObject, Identifiable where ID == String {
    associatedtype ListyItemType: ListyIdentifiableView
    var listItemViewModels: [ListyItemType.ViewModelType] { get set }
    func updateWithReorderedItems()
}

public protocol ListyItemViewModel: ObservableObject, Equatable, Identifiable where ID == String {}

public protocol ListyIdentifiableView: View, Hashable, Identifiable {
    associatedtype ViewModelType: ListyItemViewModel
    init(viewModel: ViewModelType, itemContextMenu: [ListyContextMenuSection])
    func dragged(_ currentlyDraggedItem: Binding<ViewModelType?>) -> Self
}
