import SwiftUI

struct LoadingOverlayView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Loading details...")
                    .foregroundColor(.white)
                    .padding(.top, 20)
            }
        }
    }
}//
//  LoadingOverlayView.swift
//  PowerScale
//
//  Created by Khalil White on 3/13/25.
//

