//
//  PurchaseItem.swift
//  Event Budgeter
//

import Foundation
import SwiftData

@Model
final class PurchaseItem {
    var name: String
    var cost: Decimal
    var notes: String
    var purchaseDate: Date
    var status: ItemStatus
    var photoData: Data?
    var storeName: String
    var itemURL: String

    var eventPerson: EventPerson?

    init(
        name: String,
        cost: Decimal,
        notes: String = "",
        purchaseDate: Date = .now,
        status: ItemStatus = .need,
        photoData: Data? = nil,
        storeName: String = "",
        itemURL: String = "",
        eventPerson: EventPerson
    ) {
        self.name = name
        self.cost = cost
        self.notes = notes
        self.purchaseDate = purchaseDate
        self.status = status
        self.photoData = photoData
        self.storeName = storeName
        self.itemURL = itemURL
        self.eventPerson = eventPerson
    }
}
