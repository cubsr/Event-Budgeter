//
//  GiftIdea.swift
//  Event Budgeter
//
//  A reusable gift idea / template, independent of any event or person.
//  Concrete tracked purchases live on PurchaseItem.
//

import Foundation
import SwiftData

@Model
final class GiftIdea {
    var name: String
    var cost: Decimal
    var notes: String
    var photoData: Data?
    var storeName: String
    var itemURL: String
    var isCashGift: Bool = false

    @Relationship(inverse: \Person.giftIdeas)
    var people: [Person] = []

    init(
        name: String,
        cost: Decimal = 0,
        notes: String = "",
        photoData: Data? = nil,
        storeName: String = "",
        itemURL: String = "",
        isCashGift: Bool = false,
        people: [Person] = []
    ) {
        self.name = name
        self.cost = cost
        self.notes = notes
        self.photoData = photoData
        self.storeName = storeName
        self.itemURL = itemURL
        self.isCashGift = isCashGift
        self.people = people
    }
}
