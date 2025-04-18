import Fluent
import Vapor

final class SettingsEntity1: Model, Content {
    static let schema = "settings"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "userID")
    var owner: User

    @Field(key: "alwaysShowPinned")
    var alwaysShowPinned: Bool?

    @Field(key: "appColor")
    var appColor: String?

    @Field(key: "automaticallyImportFeed")
    var automaticallyImportFeed: Bool?

    @Field(key: "automaticallyImportWeb")
    var automaticallyImportWeb: Bool?

    @Field(key: "calorieGoal")
    var calorieGoal: Int?

    @Field(key: "calorieGoalColor")
    var calorieGoalColor: String?

    @Field(key: "countdownSoundName")
    var countdownSoundName: String?

    @Field(key: "countdownSoundVolume")
    var countdownSoundVolume: Double?

    @Field(key: "customSoundFile")
    var customSoundFile: Data?

    @Field(key: "customSoundURL")
    var customSoundURL: String?

    @Field(key: "detectWebsiteFromLinks")
    var detectWebsiteFromLinks: Bool?

    @Field(key: "isMicrophoneOn")
    var isMicrophoneOn: Bool?

    @Field(key: "isTTSON")
    var isTTSON: Bool?

    @Field(key: "itemsPerRow")
    var itemsPerRow: Int?

    @Field(key: "limitDiscoverFeed")
    var limitDiscoverFeed: Bool?

    @Field(key: "rating")
    var rating: Int?

    @Field(key: "rowStyle")
    var rowStyle: String?

    @Field(key: "selectedDisplayMode")
    var selectedDisplayMode: String?

    @Field(key: "selectedSortOption")
    var selectedSortOption: String?

    @Field(key: "showCaloriesCount")
    var showCaloriesCount: Bool?

    @Field(key: "sortByCategories")
    var sortByCategories: Bool?

    @Field(key: "startupView")
    var startupView: String?

    @Field(key: "syncGroceriesWithMealPlan")
    var syncGroceriesWithMealPlan: Bool?

    @Field(key: "syncMealPlanWithGroceries")
    var syncMealPlanWithGroceries: Bool?

    @Field(key: "timeLimit")
    var timeLimit: String?

    @Field(key: "timerSoundChoice")
    var timerSoundChoice: String?

    init() {}

    init(
        id: UUID? = nil,
        ownerID: UUID,
        alwaysShowPinned: Bool? = nil,
        appColor: String? = nil,
        automaticallyImportFeed: Bool? = nil,
        automaticallyImportWeb: Bool? = nil,
        calorieGoal: Int? = nil,
        calorieGoalColor: String? = nil,
        countdownSoundName: String? = nil,
        countdownSoundVolume: Double? = nil,
        customSoundFile: Data? = nil,
        customSoundURL: String? = nil,
        detectWebsiteFromLinks: Bool? = nil,
        isMicrophoneOn: Bool? = nil,
        isTTSON: Bool? = nil,
        itemsPerRow: Int? = nil,
        limitDiscoverFeed: Bool? = nil,
        rating: Int? = nil,
        rowStyle: String? = nil,
        selectedDisplayMode: String? = nil,
        selectedSortOption: String? = nil,
        showCaloriesCount: Bool? = nil,
        sortByCategories: Bool? = nil,
        startupView: String? = nil,
        syncGroceriesWithMealPlan: Bool? = nil,
        syncMealPlanWithGroceries: Bool? = nil,
        timeLimit: String? = nil,
        timerSoundChoice: String? = nil
    ) {
        self.id = id
        self.$owner.id = ownerID
        self.alwaysShowPinned = alwaysShowPinned
        self.appColor = appColor
        self.automaticallyImportFeed = automaticallyImportFeed
        self.automaticallyImportWeb = automaticallyImportWeb
        self.calorieGoal = calorieGoal
        self.calorieGoalColor = calorieGoalColor
        self.countdownSoundName = countdownSoundName
        self.countdownSoundVolume = countdownSoundVolume
        self.customSoundFile = customSoundFile
        self.customSoundURL = customSoundURL
        self.detectWebsiteFromLinks = detectWebsiteFromLinks
        self.isMicrophoneOn = isMicrophoneOn
        self.isTTSON = isTTSON
        self.itemsPerRow = itemsPerRow
        self.limitDiscoverFeed = limitDiscoverFeed
        self.rating = rating
        self.rowStyle = rowStyle
        self.selectedDisplayMode = selectedDisplayMode
        self.selectedSortOption = selectedSortOption
        self.showCaloriesCount = showCaloriesCount
        self.sortByCategories = sortByCategories
        self.startupView = startupView
        self.syncGroceriesWithMealPlan = syncGroceriesWithMealPlan
        self.syncMealPlanWithGroceries = syncMealPlanWithGroceries
        self.timeLimit = timeLimit
        self.timerSoundChoice = timerSoundChoice
    }
}
