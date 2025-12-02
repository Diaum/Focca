import Foundation
import CoreNFC
import Combine

class NFCReaderManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var isReading = false
    @Published var nfcReadSuccess = false
    @Published var nfcError: String?
    
    private var session: NFCNDEFReaderSession?
    private var onSuccess: (() -> Void)?
    private var onError: ((String) -> Void)?
    
    func startReading(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            onError("NFC não está disponível neste dispositivo")
            return
        }
        
        self.onSuccess = onSuccess
        self.onError = onError
        self.isReading = true
        self.nfcReadSuccess = false
        self.nfcError = nil
        
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Aproxime o dispositivo de uma tag NFC para ativar o bloqueio"
        session?.begin()
    }
    
    func stopReading() {
        session?.invalidate()
        session = nil
        isReading = false
    }
    
    // MARK: - NFCNDEFReaderSessionDelegate
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // NFC tag foi lida com sucesso
        DispatchQueue.main.async {
            self.nfcReadSuccess = true
            self.isReading = false
            self.onSuccess?()
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isReading = false
            
            if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorUserCanceled:
                    // Usuário cancelou, não é um erro
                    self.nfcError = nil
                    return
                case .readerSessionInvalidationErrorSystemIsBusy:
                    self.nfcError = "Sistema ocupado. Tente novamente."
                case .readerSessionInvalidationErrorSessionTimeout:
                    self.nfcError = "Tempo esgotado. Aproxime a tag novamente."
                default:
                    self.nfcError = "Erro ao ler NFC: \(error.localizedDescription)"
                }
            } else {
                self.nfcError = "Erro ao ler NFC: \(error.localizedDescription)"
            }
            
            if let errorMessage = self.nfcError {
                self.onError?(errorMessage)
            }
        }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // Sessão ativa, aguardando tag
    }
}

