import SwiftUI
import FamilyControls

struct CreateModeView: View {
    @State private var modeName: String = ""
    @State private var selection = FamilyActivitySelection()
    @State private var showAppPicker = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "1C1C1E"))
                            .frame(width: 34, height: 34)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Text("Create mode")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Apps Selected")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "1C1C1E"))
                        Spacer()
                        Text("\(selection.applicationTokens.count)/100")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    )
                    
                    HStack {
                        TextField("e.g. Work, Family Time", text: $modeName)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    )
                    
                    Button(action: {
                        showAppPicker = true
                    }) {
                        Text("Select Apps")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showAppPicker) {
            AppPickerSheet(selection: $selection)
        }
    }
}

struct AppPickerSheet: View {
    @Binding var selection: FamilyActivitySelection
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F3F0")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    FamilyActivityPicker(selection: $selection)
                        .frame(maxHeight: .infinity)
                    
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
        }
    }
}

#Preview {
    CreateModeView()
}

