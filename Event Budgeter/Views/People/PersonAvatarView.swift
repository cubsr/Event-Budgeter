//
//  PersonAvatarView.swift
//  Event Budgeter
//

import SwiftUI

struct PersonAvatarView: View {
    let person: Person
    var size: CGFloat = 36

    var body: some View {
        Group {
            if let data = person.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color(hex: person.colorHex))
                    .overlay {
                        Text(person.initials)
                            .foregroundStyle(.white)
                            .font(.system(size: size * 0.35))
                            .fontWeight(.semibold)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
