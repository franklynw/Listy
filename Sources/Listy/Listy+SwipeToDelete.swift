//
//  Listy+SwipeToDelete.swift
//  
//
//  Created by Franklyn Weber on 05/02/2021.
//

import SwiftUI


extension Listy {
    
    struct SwipeDelete {
        let itemId: String
        let offset: CGFloat
    }
    
    func swipeToDeleteView(geometry: GeometryProxy) -> AnyView {
        
        let textWidth = deleteTextWidth()
        let rightEdge = geometry.size.width + textWidth / 2
        let x = rightEdge + swipeDelete.offset + initialSwipeOffset + textPadding
        let adjustedX: CGFloat
        
        if x < geometry.size.width * 0.4 {
            // if we drag far enough left, the "Delete" needs to fly to the left edge of the red bar
            adjustedX = x
        } else {
            // otherwise it needs to be pinned to the right edge
            adjustedX = max(rightEdge - textWidth - textPadding, x)
        }
        
        let rectangle = ZStack {
            
            Rectangle()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .foregroundColor(.red)
                .offset(x: swipeDelete.offset + geometry.size.width + initialSwipeOffset)
            
            Text(NSLocalizedString("Delete", comment: "Delete"))
                .font(.body)
                .foregroundColor(.white)
                .position(x: adjustedX, y: geometry.size.height / 2)
        }
        .clipped()
        .onTapGesture {
            deleteFromList(swipeDelete.itemId)
        }
        
        return AnyView(rectangle)
    }
    
    func swipeToDeleteGesture(with geometry: GeometryProxy, forItemWithId id: String) -> _EndedGesture<_ChangedGesture<DragGesture>> {
        
        let gesture = DragGesture()
            .onChanged { gesture in
                currentlyDraggedItem = nil
                swipeDidChange(gesture, geometry: geometry, forItemWithId: id)
            }
            .onEnded { _ in
                
                guard deleteItem != nil, !swipeCommitted else {
                    return
                }
                
                swipeDidEnd()
            }
        
        return gesture
    }
    
    private func swipeDidChange(_ gesture: DragGesture.Value, geometry: GeometryProxy, forItemWithId id: String) {
        
        guard deleteItem != nil, !swipeCommitted else {
            return
        }
        
        let translation = gesture.translation.width
        
        if gesture.predictedEndTranslation.width < geometry.size.width * -2 && translation < geometry.size.width / -3 {
            
            // fast swipe to delete
            
            swipeCommitted = true
            swipeDelete = SwipeDelete(itemId: id, offset: -geometry.size.width)
            
            // delay it for a tiny bit so the Delete graphic has time to be seen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                deleteFromList(id)
            }
            
            return
        }
        
        swipeDelete = SwipeDelete(itemId: id, offset: translation)
        draggingFinished = false
        
        if translation + initialSwipeOffset < geometry.size.width * -0.95 {
            swipeCommitted = true
            deleteFromList(id)
        }
    }
    
    internal func swipeDidEnd() {
        
        let id = swipeDelete.itemId
        
        if swipeCommitted {
            
            swipeDelete = SwipeDelete(itemId: id, offset: 0)
            draggingFinished = true
            swipeCommitted = false
            initialSwipeOffset = 0
            
        } else {
            
            let textWidth = deleteTextWidth()
            
            if swipeDelete.offset > -textWidth {
                swipeCommitted = true
                swipeDidEnd()
                return
            }
            
            initialSwipeOffset = -textWidth - textPadding * 2
            swipeDelete = SwipeDelete(itemId: id, offset: 0)
        }
    }
    
    private func deleteFromList(_ id: String) {
        
        withAnimation(nil) {
            swipeDeletedId = id
        }
        
        // this feels a little hacky, but we need the swipeDeletedId to be the id of the item being deleted, until it has finished animated
        // then it needs to be nil so that the behaviour of the list goes back to normal. There's no animation completion in SwiftUI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            swipeDeletedId = nil
        }
        
        deleteItem?(id)
        swipeDidEnd()
    }
    
    private func deleteTextWidth() -> CGFloat {
        
        // is there a better way of doing this?
        
        let deleteText = NSLocalizedString("Delete", comment: "Delete")
        let label = UILabel()
        label.font = UIFont.preferredFont(style: .body)
        label.text = deleteText
        
        return label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
    }
}
