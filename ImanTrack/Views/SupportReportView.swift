import SwiftUI
import PhotosUI
import UIKit

enum SupportCategory: String, CaseIterable, Identifiable {
    case fehler = "Fehler melden"
    case vorschlag = "Verbesserung"
    case feedback = "Feedback"
    
    var id: String { self.rawValue }
    
    func localizedTitle(for lang: String) -> String {
        switch self {
        case .fehler:
            return L10n.tr("support_category_bug", lang)
        case .vorschlag:
            return L10n.tr("support_category_feature", lang)
        case .feedback:
            return L10n.tr("support_category_feedback", lang)
        }
    }
}

struct SupportReportView: View {
    @Environment(\.dismiss) private var dismiss
    
    let language: String
    
    // EmailJS Access Keys (Generiert auf https://emailjs.com für yahya.ai.agent@gmail.com)
    @AppStorage("emailjs_service_id") private var emailJsServiceId: String = "service_hgtmcvi"
    @AppStorage("emailjs_template_id") private var emailJsTemplateId: String = "template_ii1hhma"
    @AppStorage("emailjs_public_key") private var emailJsPublicKey: String = "q9-tSdMJF0IHnrSSz"
    
    @State private var selectedCategory: SupportCategory = .fehler
    @State private var userEmailText: String = ""
    @State private var messageText: String = ""
    @FocusState private var isMessageEditorFocused: Bool
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Card 1: Kategorie
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.tr("support_category", language))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Picker(L10n.tr("support_select_topic", language), selection: $selectedCategory) {
                                ForEach(SupportCategory.allCases) { category in
                                    Text(category.localizedTitle(for: language)).tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.islamicGreen)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                        
                        // Card 2: E-Mail für Rückfragen (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.tr("support_email_label", language))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 10) {
                                Image(systemName: "envelope")
                                    .foregroundColor(Theme.islamicGreen)
                                TextField("name@example.com", text: $userEmailText)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .font(.body)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                        
                        // Card 3: Deine Nachricht
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.tr("support_message_label", language))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .topLeading) {
                                if messageText.isEmpty {
                                    Text(L10n.tr("support_message_placeholder", language))
                                        .font(.body)
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                }
                                TextEditor(text: $messageText)
                                    .focused($isMessageEditorFocused)
                                    .frame(minHeight: 120)
                                    .font(.body)
                                    .scrollContentBackground(.hidden)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                        
                        // Card 4: Anhang (Optional)
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.tr("support_image_label", language))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack {
                                    Image(systemName: "paperclip")
                                        .foregroundColor(Theme.islamicGreen)
                                    Text(selectedImageData == nil ? L10n.tr("support_attach_image", language) : L10n.tr("support_change_image", language))
                                        .foregroundColor(Theme.islamicGreen)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                            }
                            .onChange(of: selectedPhotoItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        await MainActor.run {
                                            selectedImageData = data
                                        }
                                    }
                                }
                            }
                            
                            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                                HStack(spacing: 12) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                        .clipped()
                                    
                                    Button(role: .destructive, action: {
                                        selectedImageData = nil
                                        selectedPhotoItem = nil
                                    }) {
                                        Label(L10n.tr("support_remove_image", language), systemImage: "trash")
                                            .font(.subheadline)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                        
                        // Section 4: Absenden
                        VStack(spacing: 12) {
                            Button(action: sendViaEmailJS) {
                                HStack {
                                    Spacer()
                                    if isSubmitting {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(L10n.tr("support_send_button", language))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .frame(height: 48)
                                .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting ? Color.gray.opacity(0.5) : Theme.islamicGreen)
                                .cornerRadius(12)
                            }
                            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                            
                            Text(L10n.tr("support_footer_info", language))
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.tr("settings_support_header", language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("close", language)) {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if isSuccess {
                            dismiss()
                        }
                    }
                )
            }
        }
    }
    
    private func sendViaEmailJS() {
        guard !isSubmitting else { return }
        isSubmitting = true
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.1.0"
        let osVersion = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        
        var imageBase64String = ""
        if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
            imageBase64String = resizeAndCompressImage(uiImage)
        }
        
        let userEmailTrimmed = userEmailText.trimmingCharacters(in: .whitespacesAndNewlines)
        let replyToAddress = userEmailTrimmed.isEmpty ? "yahya.ai.agent@gmail.com" : userEmailTrimmed
        let senderDisplayName = userEmailTrimmed.isEmpty ? "ImanTrack User (Anonym)" : userEmailTrimmed
        
        let fullFormattedMessage = """
        ----------------------------------
        📌 KATEGORIE: \(selectedCategory.localizedTitle(for: language))
        📧 ANTWORT-EMAIL: \(userEmailTrimmed.isEmpty ? "Keine angegeben (Anonym)" : userEmailTrimmed)
        
        ----------------------------------
        💬 NACHRICHT:
        \(messageText)
        
        ----------------------------------
        📱 SYSTEM-INFO:
        App: ImanTrack (v\(appVersion))
        iOS: \(osVersion)
        Gerät: \(model)
        """
        
        let templateParams: [String: String] = [
            "from_name": senderDisplayName,
            "reply_to": replyToAddress,
            "user_email": userEmailTrimmed.isEmpty ? "Nicht angegeben" : userEmailTrimmed,
            "category": selectedCategory.localizedTitle(for: language),
            "message": fullFormattedMessage,
            "user_message": messageText,
            "app_version": appVersion,
            "os_version": osVersion,
            "device_model": model,
            "image_base64": imageBase64String
        ]
        
        let jsonBody: [String: Any] = [
            "service_id": emailJsServiceId,
            "template_id": emailJsTemplateId,
            "user_id": emailJsPublicKey,
            "template_params": templateParams
        ]
        
        guard let url = URL(string: "https://api.emailjs.com/api/v1.0/email/send") else {
            isSubmitting = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://imantrack.app", forHTTPHeaderField: "Origin")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            self.isSubmitting = false
            self.alertTitle = L10n.tr("error", language)
            self.alertMessage = error.localizedDescription
            self.showAlert = true
            return
        }
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    await MainActor.run {
                        self.isSubmitting = false
                        self.isSuccess = true
                        self.alertTitle = L10n.tr("support_sent_success_title", language)
                        self.alertMessage = L10n.tr("support_sent_success_desc", language)
                        self.showAlert = true
                    }
                } else {
                    let responseStr = String(data: data, encoding: .utf8) ?? ""
                    await MainActor.run {
                        self.isSubmitting = false
                        self.isSuccess = false
                        self.alertTitle = L10n.tr("support_sent_error_title", language)
                        self.alertMessage = String(format: L10n.tr("support_sent_error_desc", language), responseStr)
                        self.showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isSubmitting = false
                    self.isSuccess = false
                    self.alertTitle = L10n.tr("support_connection_error", language)
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                }
            }
        }
    }
    
    private func resizeAndCompressImage(_ uiImage: UIImage) -> String {
        let maxDimension: CGFloat = 600
        let size = uiImage.size
        let aspectWidth = maxDimension / size.width
        let aspectHeight = maxDimension / size.height
        let scale = min(aspectWidth, aspectHeight, 1.0)
        
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        var quality: CGFloat = 0.4
        var compressedData = resizedImage.jpegData(compressionQuality: quality)
        var base64String = compressedData?.base64EncodedString() ?? ""
        
        while base64String.count > 38_000 && quality > 0.1 {
            quality -= 0.08
            if let data = resizedImage.jpegData(compressionQuality: quality) {
                compressedData = data
                base64String = data.base64EncodedString()
            }
        }
        
        if base64String.count > 40_000 {
            let smallerDimension: CGFloat = 400
            let scale2 = min(smallerDimension / size.width, smallerDimension / size.height, 1.0)
            let size2 = CGSize(width: size.width * scale2, height: size.height * scale2)
            let renderer2 = UIGraphicsImageRenderer(size: size2)
            let image2 = renderer2.image { _ in
                uiImage.draw(in: CGRect(origin: .zero, size: size2))
            }
            if let data2 = image2.jpegData(compressionQuality: 0.3) {
                base64String = data2.base64EncodedString()
            }
        }
        
        return "data:image/jpeg;base64," + base64String
    }
}
