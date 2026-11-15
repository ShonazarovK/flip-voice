import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"
    case uzbek = "uz"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        case .uzbek: return "O'zbekcha"
        }
    }
}

@MainActor
public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    @AppStorage("selected_app_language") public var currentLanguage: AppLanguage = .english
    
    private init() {
        // Detect default from system if first launch
        if UserDefaults.standard.string(forKey: "selected_app_language") == nil {
            let preferred = Locale.preferredLanguages.first ?? "en"
            if preferred.hasPrefix("ru") {
                currentLanguage = .russian
            } else if preferred.hasPrefix("uz") {
                currentLanguage = .uzbek
            } else {
                currentLanguage = .english
            }
        }
    }
    
    public func localized(_ key: LocalizedKey) -> String {
        switch currentLanguage {
        case .english:
            return englishStrings[key] ?? key.rawValue
        case .russian:
            return russianStrings[key] ?? englishStrings[key] ?? key.rawValue
        case .uzbek:
            return uzbekStrings[key] ?? englishStrings[key] ?? key.rawValue
        }
    }
}

public enum LocalizedKey: String {
    case tabStudio = "tab_studio"
    case tabEditor = "tab_editor"
    case tabChallenge = "tab_challenge"
    case tabLibrary = "tab_library"
    case tabSettings = "tab_settings"
    
    case recordTapToStart = "record_tap_to_start"
    case recording = "recording"
    case paused = "paused"
    case stopAndEdit = "stop_and_edit"
    case importAudio = "import_audio"
    case permissionNeeded = "permission_needed"
    case permissionDesc = "permission_desc"
    case openSettings = "open_settings"
    
    case play = "play"
    case pause = "pause"
    case reverse = "reverse"
    case forward = "forward"
    case playbackSpeed = "playback_speed"
    case pitchShift = "pitch_shift"
    case semitones = "semitones"
    case reset = "reset"
    case loop = "loop"
    case trimAudio = "trim_audio"
    case fadeIn = "fade_in"
    case fadeOut = "fade_out"
    case saveToLibrary = "save_to_library"
    case exportShare = "export_share"
    
    case challengeTitle = "challenge_title"
    case challengeSubtitle = "challenge_subtitle"
    case step1Record = "step1_record"
    case step2ListenReversed = "step2_listen_reversed"
    case step3Imitate = "step3_imitate"
    case step4Reveal = "step4_reveal"
    case yourOriginal = "your_original"
    case reversedPhrase = "reversed_phrase"
    case yourImitation = "your_imitation"
    case flippedResult = "flipped_result"
    
    case libraryEmpty = "library_empty"
    case libraryEmptySub = "library_empty_sub"
    case searchRecordings = "search_recordings"
    case sortBy = "sort_by"
    case deleteConfirm = "delete_confirm"
    case delete = "delete"
    case cancel = "cancel"
    case rename = "rename"
    
    case settingsExportFormat = "settings_export_format"
    case settingsLanguage = "settings_language"
    case settingsTheme = "settings_theme"
    case themeSystem = "theme_system"
    case themeLight = "theme_light"
    case themeDark = "theme_dark"
    case privacyPolicy = "privacy_policy"
    case rateApp = "rate_app"
    case feedback = "feedback"
    case about = "about"
    case version = "version"
    case offlineGuarantee = "offline_guarantee"
}

private let englishStrings: [LocalizedKey: String] = [
    .tabStudio: "Studio",
    .tabEditor: "Audio Lab",
    .tabChallenge: "Challenge",
    .tabLibrary: "Library",
    .tabSettings: "Settings",
    
    .recordTapToStart: "Tap to Record",
    .recording: "Recording...",
    .paused: "Paused",
    .stopAndEdit: "Finish & Edit",
    .importAudio: "Import Audio File",
    .permissionNeeded: "Microphone Access Required",
    .permissionDesc: "FlipVoice needs access to your microphone to record audio for playback and reversal effects.",
    .openSettings: "Open Settings",
    
    .play: "Play",
    .pause: "Pause",
    .reverse: "Reverse",
    .forward: "Forward",
    .playbackSpeed: "Speed",
    .pitchShift: "Pitch Shift",
    .semitones: "semitones",
    .reset: "Reset",
    .loop: "Loop",
    .trimAudio: "Trim Audio",
    .fadeIn: "Fade In",
    .fadeOut: "Fade Out",
    .saveToLibrary: "Save to Library",
    .exportShare: "Export & Share",
    
    .challengeTitle: "Backwards Talk Challenge",
    .challengeSubtitle: "Can you speak backwards and make it sound normal?",
    .step1Record: "Step 1: Record a short phrase",
    .step2ListenReversed: "Step 2: Listen to it in reverse",
    .step3Imitate: "Step 3: Record your imitation",
    .step4Reveal: "Step 4: Flip your imitation back!",
    .yourOriginal: "Your Original",
    .reversedPhrase: "Reversed (What to imitate)",
    .yourImitation: "Your Imitation",
    .flippedResult: "Flipped Result (How close are you?)",
    
    .libraryEmpty: "No Saved Audio Yet",
    .libraryEmptySub: "Record or import audio in the Studio to start experimenting.",
    .searchRecordings: "Search recordings...",
    .sortBy: "Sort by",
    .deleteConfirm: "Are you sure you want to delete this recording?",
    .delete: "Delete",
    .cancel: "Cancel",
    .rename: "Rename",
    
    .settingsExportFormat: "Default Export Format",
    .settingsLanguage: "App Language",
    .settingsTheme: "Theme",
    .themeSystem: "System Default",
    .themeLight: "Light Mode",
    .themeDark: "Dark Mode",
    .privacyPolicy: "Privacy Policy",
    .rateApp: "Rate FlipVoice",
    .feedback: "Send Feedback",
    .about: "About FlipVoice",
    .version: "Version",
    .offlineGuarantee: "100% Offline & Private. No data leaves your device."
]

private let russianStrings: [LocalizedKey: String] = [
    .tabStudio: "Студия",
    .tabEditor: "Аудио Лаб",
    .tabChallenge: "Челлендж",
    .tabLibrary: "Библиотека",
    .tabSettings: "Настройки",
    
    .recordTapToStart: "Нажмите для записи",
    .recording: "Запись...",
    .paused: "Пауза",
    .stopAndEdit: "Завершить и открыть",
    .importAudio: "Импортировать аудио",
    .permissionNeeded: "Требуется доступ к микрофону",
    .permissionDesc: "FlipVoice необходим доступ к микрофону для записи звука и создания эффектов реверса.",
    .openSettings: "Открыть настройки",
    
    .play: "Воспроизвести",
    .pause: "Пауза",
    .reverse: "Задом наперёд",
    .forward: "Вперёд",
    .playbackSpeed: "Скорость",
    .pitchShift: "Высота тона",
    .semitones: "полутонов",
    .reset: "Сброс",
    .loop: "Зациклить",
    .trimAudio: "Обрезка звука",
    .fadeIn: "Нарастание",
    .fadeOut: "Затухание",
    .saveToLibrary: "Сохранить в медиатеку",
    .exportShare: "Экспорт и поделиться",
    
    .challengeTitle: "Челлендж наоборот",
    .challengeSubtitle: "Сможете повторить фразу задом наперёд так, чтобы она звучала нормально?",
    .step1Record: "Шаг 1: Запишите короткую фразу",
    .step2ListenReversed: "Шаг 2: Послушайте её задом наперёд",
    .step3Imitate: "Шаг 3: Запишите вашу имитацию",
    .step4Reveal: "Шаг 4: Разверните вашу запись обратно!",
    .yourOriginal: "Оригинал",
    .reversedPhrase: "Реверс (что нужно повторить)",
    .yourImitation: "Ваша попытка",
    .flippedResult: "Результат (насколько похоже?)",
    
    .libraryEmpty: "Пока нет сохранённых записей",
    .libraryEmptySub: "Запишите или импортируйте аудио в Студии.",
    .searchRecordings: "Поиск записей...",
    .sortBy: "Сортировка",
    .deleteConfirm: "Вы уверены, что хотите удалить эту запись?",
    .delete: "Удалить",
    .cancel: "Отмена",
    .rename: "Переименовать",
    
    .settingsExportFormat: "Формат экспорта",
    .settingsLanguage: "Язык приложения",
    .settingsTheme: "Оформление",
    .themeSystem: "Как в системе",
    .themeLight: "Светлая тема",
    .themeDark: "Тёмная тема",
    .privacyPolicy: "Политика конфиденциальности",
    .rateApp: "Оценить FlipVoice",
    .feedback: "Обратная связь",
    .about: "О приложении FlipVoice",
    .version: "Версия",
    .offlineGuarantee: "100% оффлайн и приватно. Никакие данные не покидают устройство."
]

private let uzbekStrings: [LocalizedKey: String] = [
    .tabStudio: "Studiya",
    .tabEditor: "Ovoz Lab",
    .tabChallenge: "Chellenj",
    .tabLibrary: "Kutubxona",
    .tabSettings: "Sozlamalar",
    
    .recordTapToStart: "Yozish uchun bosing",
    .recording: "Yozilmoqda...",
    .paused: "To'xtatildi",
    .stopAndEdit: "Tugatish va tahrirlash",
    .importAudio: "Audio fayl yuklash",
    .permissionNeeded: "Mikrofon ruxsati kerak",
    .permissionDesc: "FlipVoice ovozni yozib olish va teskari aylantirish uchun mikrofonga ruxsat talab qiladi.",
    .openSettings: "Sozlamalarni ochish",
    
    .play: "Ijro",
    .pause: "Pauza",
    .reverse: "Teskari",
    .forward: "Oldinga",
    .playbackSpeed: "Tezlik",
    .pitchShift: "Ovoz balandligi (Pitch)",
    .semitones: "yarim ton",
    .reset: "Tiklash",
    .loop: "Takrorlash",
    .trimAudio: "Kesish",
    .fadeIn: "Sekin kuchayish",
    .fadeOut: "Sekin pasayish",
    .saveToLibrary: "Kutubxonaga saqlash",
    .exportShare: "Eksport va ulashish",
    
    .challengeTitle: "Teskari so'zlash chellenji",
    .challengeSubtitle: "So'zlarni teskari aytib, qaytarganda to'g'ri chiqara olasizmi?",
    .step1Record: "1-qadam: Qisqa ibora yozing",
    .step2ListenReversed: "2-qadam: Teskarisini eshiting",
    .step3Imitate: "3-qadam: O'xshatib yozib oling",
    .step4Reveal: "4-qadam: Yozganingizni teskari aylantiring!",
    .yourOriginal: "Asl ovozingiz",
    .reversedPhrase: "Teskari variant",
    .yourImitation: "Sizning urinishingiz",
    .flippedResult: "Natija (qanchalik to'g'ri chiqdi?)",
    
    .libraryEmpty: "Saqlangan yozuvlar yo'q",
    .libraryEmptySub: "Studiyada audio yozing yoki fayl yuklang.",
    .searchRecordings: "Qidirish...",
    .sortBy: "Saralash",
    .deleteConfirm: "Rostdan ham ushbu yozuvni o'chirmoqchimisiz?",
    .delete: "O'chirish",
    .cancel: "Bekor qilish",
    .rename: "Nomini o'zgartirish",
    
    .settingsExportFormat: "Eksport formati",
    .settingsLanguage: "Ilova tili",
    .settingsTheme: "Mavzu",
    .themeSystem: "Tizim sozlamasi",
    .themeLight: "Yorug' mavzu",
    .themeDark: "Qorong'u mavzu",
    .privacyPolicy: "Maxfiylik siyosati",
    .rateApp: "Baholash",
    .feedback: "Fikr-mulohaza",
    .about: "FlipVoice haqida",
    .version: "Versiya",
    .offlineGuarantee: "100% oflayn va maxfiy. Ma'lumotlar qurilmangizda saqlanadi."
]

