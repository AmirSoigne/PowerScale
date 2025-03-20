// SectionDivider.swift

import SwiftUI

struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 1)
            .padding(.vertical, 15)
    }
}
