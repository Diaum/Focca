import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentEmail: String?
    
    private let userDefaults = UserDefaults.standard
    private let authKey = "user_is_authenticated"
    private let emailKey = "user_email"
    
    private init() {
        let savedAuth = userDefaults.bool(forKey: authKey)
        isAuthenticated = savedAuth
        currentEmail = userDefaults.string(forKey: emailKey)
        
        Task {
            await checkAuthenticationStatus()
        }
    }
    
    func checkAuthenticationStatus() async {
        isLoading = true
        
        do {
            if let session = try await SupabaseManager.shared.getCurrentSession() {
                await MainActor.run {
                    isAuthenticated = true
                    currentEmail = session.user.email
                    saveAuthState(email: session.user.email)
                    isLoading = false
                }
                
                // Se não há cache local, força busca do banco
                if !TimerStorage.shared.hasLocalCache() {
                    Task {
                        await TimerStorage.shared.fetchAndCacheFromDatabase()
                    }
                }
                
                Task {
                    await AwardManager.shared.refreshAwards()
                }
            } else {
                await MainActor.run {
                    isAuthenticated = userDefaults.bool(forKey: authKey)
                    currentEmail = userDefaults.string(forKey: emailKey)
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                isAuthenticated = userDefaults.bool(forKey: authKey)
                currentEmail = userDefaults.string(forKey: emailKey)
                isLoading = false
            }
        }
    }
    
    func sendOtp(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await SupabaseManager.shared.sendOtp(email: email)
            currentEmail = email
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func verifyOtp(email: String, code: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await SupabaseManager.shared.verifyOtp(email: email, code: code)
            isAuthenticated = true
            currentEmail = session.user.email
            saveAuthState(email: session.user.email)
            
            // Força busca do banco após login para popular cache
            Task {
                await TimerStorage.shared.fetchAndCacheFromDatabase()
            }
            
            Task {
                await AwardManager.shared.refreshAwards()
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func signOut() async {
        isLoading = true
        
        do {
            try await SupabaseManager.shared.signOut()
            clearAuthState()
            isAuthenticated = false
            currentEmail = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func saveAuthState(email: String?) {
        userDefaults.set(true, forKey: authKey)
        if let email = email {
            userDefaults.set(email, forKey: emailKey)
        }
    }
    
    private func clearAuthState() {
        userDefaults.removeObject(forKey: authKey)
        userDefaults.removeObject(forKey: emailKey)
        userDefaults.set(false, forKey: "hasCompletedOnboarding")
        userDefaults.set("", forKey: "onboarding_completed_email")
    }
}

