//
//  Listy.DragDelegate.swift
//
//  Created by Franklyn Weber on 01/02/2021.
//

import SwiftUI


extension Listy {
    
    struct DraggingDelegate<DataSource: ListyDataSource>: DropDelegate {
        
        typealias ItemViewModel = DataSource.ListyItemType.ViewModelType
        
        let item: ItemViewModel
        let dataSource: DataSource
        
        @Binding var viewModels: [ItemViewModel]
        @Binding var currentlyDraggedItem: ItemViewModel?
        @Binding var changedView: Bool
        @Binding var draggingFinished: Bool

        
        func dropEntered(info: DropInfo) {
            
            changedView = true
            
            guard let currentlyDraggedItem = currentlyDraggedItem, item != currentlyDraggedItem else {
                return
            }
            guard let from = viewModels.firstIndex(of: currentlyDraggedItem), let to = viewModels.firstIndex(of: item) else {
                return
            }
            guard viewModels[to].id != currentlyDraggedItem.id else {
                return
            }
            
            let moveTo = to > from ? to + 1 : to
            
            viewModels.move(fromOffsets: IndexSet(integer: from), toOffset: moveTo)
        }

        func dropUpdated(info: DropInfo) -> DropProposal? {
            return DropProposal(operation: .move)
        }

        func performDrop(info: DropInfo) -> Bool {
            
            changedView = false
            currentlyDraggedItem = nil
            draggingFinished = true
            
            return true
        }
    }


    struct DraggingFailedDelegate<DataSource: ListyDataSource>: DropDelegate {

        typealias ItemViewModel = DataSource.ListyItemType.ViewModelType

        @Binding var currentlyDraggedItem: ItemViewModel?
        @Binding var changedView: Bool
        @Binding var draggingFinished: Bool
        
        
        func performDrop(info: DropInfo) -> Bool {
            
            changedView = false
            currentlyDraggedItem = nil
            draggingFinished = true
            
            return true
        }
    }
}
