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
        
        // is there a better way of doing this?
        
        let deleteText = NSLocalizedString("Delete", comment: "Delete")
        let label = UILabel()
        label.font = UIFont.preferredFont(style: .body)
        label.text = deleteText
        let textPadding: CGFloat = 8
        let textWidth = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
        let textOffset = swipeDelete.offset + (geometry.size.width + textWidth) / 2 + textPadding
        let adjustedTextOffset: CGFloat
        
        if -swipeDelete.offset > geometry.size.width * 0.7 {
            adjustedTextOffset = textOffset
        } else {
            adjustedTextOffset = max(textOffset, textWidth * 2 - textPadding * 1.5)
        }
        
        let rectangle = ZStack {
            
            Rectangle()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .foregroundColor(.red)
                .offset(x: swipeDelete.offset + geometry.size.width)
            
            Text(deleteText)
                .font(.body)
                .foregroundColor(.white)
                .offset(x: adjustedTextOffset)
        }
        .clipped()
        .onTapGesture {
            deleteItem?(swipeDelete.itemId)
        }
        
        return AnyView(rectangle)
    }
    
    func swipeToDeleteGesture(with geometry: GeometryProxy, forItemWithId id: String) -> _EndedGesture<_ChangedGesture<DragGesture>> {
        
        let gesture = DragGesture()
            .onChanged { gesture in
                swipeDidChange(gesture, geometry: geometry, forItemWithId: id)
            }
            .onEnded { _ in
                
                guard deleteItem != nil, !didFastSwipe else {
                    return
                }
                
                swipeDidEnd()
            }
        
        return gesture
    }
    
    private func swipeDidChange(_ gesture: DragGesture.Value, geometry: GeometryProxy, forItemWithId id: String) {
        
        guard let deleteItem = deleteItem, !didFastSwipe else {
            return
        }
        
        let translation = gesture.translation.width
        
        if gesture.predictedEndTranslation.width < geometry.size.width * -2 && translation < geometry.size.width / -3 {
            
            didFastSwipe = true
            swipeDelete = SwipeDelete(itemId: id, offset: -geometry.size.width)
            
            // delay it for a tiny bit so the Delete graphic has time to be seen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                deleteItem(id)
                swipeDidEnd()
            }
            
            return
        }
        
        swipeDelete = SwipeDelete(itemId: id, offset: min(0, translation))
        draggingFinished = false
        
        if translation < geometry.size.width * -0.95 {
            deleteItem(id)
            swipeDidEnd()
        }
    }
    
    private func swipeDidEnd() {
        let id = swipeDelete.itemId
        swipeDelete = SwipeDelete(itemId: id, offset: 0)
        draggingFinished = true
        didFastSwipe = false
    }
}
