import SwiftUI
import FamilyControls

struct OnboardingStep3: View {
    @StateObject var model = SelectionModel()
    @State private var appInfo: [String: (name: String, color: Color)] = [:]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F3F0")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Text("\(model.selection.applicationTokens.count) distractions selected")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: "1D1D1F"))
                        .padding(.top, 40)
                    
                    if !model.selection.applicationTokens.isEmpty {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(0..<model.selection.applicationTokens.count, id: \.self) { index in
                                    AppRow(index: index)
                                    
                                    if index < model.selection.applicationTokens.count - 1 {
                                        Divider()
                                            .padding(.leading, 62)
                                    }
                                }
                            }
                            .background(Color(hex: "F5F3F0"))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            
                        }) {
                            Text("Complete setup")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color(hex: "1D1D1F"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(hex: "E5E5EA"))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                        
                        Button(action: {
                            
                        }) {
                            Text("Edit apps")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color(hex: "1D1D1F"))
                        }
                    }
                    .padding(.bottom, 40)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: BackButton())
        }
    }
}

struct AppRow: View {
    let index: Int
    
    private var colors: [Color] {
        [Color(hex: "E8B5A0"), Color(hex: "FF6B6B"), Color(hex: "4ECDC4"), Color(hex: "0A66C2"), Color(hex: "E1306C")]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(colors[index % colors.count])
                .frame(width: 50, height: 50)
            
            Text("App \(index + 1)")
                .font(.system(size: 17))
                .foregroundColor(Color(hex: "1D1D1F"))
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

struct BackButton: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "1D1D1F"))
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
        }
    }
}

#Preview {
    OnboardingStep3()
}
