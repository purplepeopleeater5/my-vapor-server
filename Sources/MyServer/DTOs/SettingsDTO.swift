import Vapor

struct SettingsDTO: Content {
    let id: UUID?
    let alwaysShowPinned: Bool?
    let appColor: String?
    let automaticallyImportFeed: Bool?
    let automaticallyImportWeb: Bool?
    let calorieGoal: Int?
    let calorieGoalColor: String?
    let countdownSoundName: String?
    let countdownSoundVolume: Double?
    let customSoundFile: Data?
    let customSoundURL: String?
    let detectWebsiteFromLinks: Bool?
    let isMicrophoneOn: Bool?
    let isTTSON: Bool?
    let itemsPerRow: Int?
    let limitDiscoverFeed: Bool?
    let rating: Int?
    let rowStyle: String?
    let selectedDisplayMode: String?
    let selectedSortOption: String?
    let showCaloriesCount: Bool?
    let sortByCategories: Bool?
    let startupView: String?
    let syncGroceriesWithMealPlan: Bool?
    let syncMealPlanWithGroceries: Bool?
    let timeLimit: String?
    let timerSoundChoice: String?
}
