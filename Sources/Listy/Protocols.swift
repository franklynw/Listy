//
//  Protocols.swift
//  Listy
//
//  Created by Franklyn Weber on 01/02/2021.
//

import SwiftUI


public protocol ListyDataSource: ObservableObject {
    associatedtype ListyItemType: ListyIdentifiableView
    var listItemViewModels: [ListyItemType.ViewModelType] { get set }
    func updateWithReorderedItems()
}

public protocol ListyItemViewModel: ObservableObject, Equatable, Identifiable where ID == String {}

public protocol ListyIdentifiableView: View, Hashable, Identifiable {
    associatedtype ViewModelType: ListyItemViewModel
    init(viewModel: ViewModelType, itemContextMenuItems: [ListyContextMenuItem])
    func dragged(_ currentlyDraggedItem: Binding<ViewModelType?>) -> Self
}
