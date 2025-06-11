import SwiftUI

struct OnboardingView: View {
    
    @StateObject private var manager = OnboardingManager()
    @State private var showBtn = false
    
    let action: () -> Void
    var body: some View {
        ZStack {
            
            Color.waterBackground.ignoresSafeArea()
            if !manager.items.isEmpty {
                
                TabView {
                    ForEach(manager.items) { item in
                        OnboardingInfoView(item: item)
                            .onAppear {
                                if item == manager.items.last {
                                    withAnimation(.spring().delay(0.25)) {
                                        showBtn = true
                                    }
                                }
                            }
                            .overlay(alignment: .bottom) {
                                if showBtn {
                                    Button("Continue") {
                                        action()
                                    }
                                    .buttonStyle(CustomButtonStyle())
                                    .frame(width: .infinity)
                                    .offset(y: 50) // Matches the height of the button
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
        .onAppear {
            manager.load()
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews:
        some View {
            OnboardingView(){}
        }
}
