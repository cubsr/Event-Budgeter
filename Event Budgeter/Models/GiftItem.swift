//
//  GiftItem.swift
//  Event Budgeter
//

import Foundation
import SwiftData

@Model
final class GiftItem {
    var name: String
    var cost: Decimal
    var notes: String
    var purchaseDate: Date
    var status: ItemStatus
    var photoData: Data?
    var storeName: String
    var itemURL: String

    @Relationship(deleteRule: .nullify, inverse: \EventPerson.giftItems)
    var assignments: [EventPerson]

    init(
        name: String,
        cost: Decimal,
        notes: String = "",
        purchaseDate: Date = .now,
        status: ItemStatus = .need,
        photoData: Data? = nil,
        storeName: String = "",
        itemURL: String = ""
    ) {
        self.name = name
        self.cost = cost
        self.notes = notes
        self.purchaseDate = purchaseDate
        self.status = status
        self.photoData = photoData
        self.storeName = storeName
        self.itemURL = itemURL
        self.assignments = []
    }
}
