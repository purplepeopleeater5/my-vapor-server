import Fluent
import Vapor

/// A recipe owned by a user.
final class Recipe: Model, Content {
    static let schema = "recipes"

    //––– Primary key –––
    @ID(key: .id)
    var id: UUID?

    //––– Optional link to the owning user –––
    @OptionalParent(key: "userID")
    var owner: User?

    //––– Scalar attributes –––
    @Field(key: "id1")
    var remoteID: String

    @Field(key: "title1")
    var title: String

    @Field(key: "description1")
    var description: String

    @Field(key: "cookTime1")
    var cookTime: String

    @Field(key: "prepTime1")
    var prepTime: String

    @Field(key: "servings1")
    var servings: String

    @Field(key: "imageURL1")
    var imageURL: String

    @Field(key: "domainURL1")
    var domainURL: String

    @Field(key: "nutritionalInfo1")
    var nutritionalInfo: String

    @Field(key: "rating1")
    var rating: Double

    @Field(key: "ratingCount1")
    var ratingCount: Double

    @Field(key: "note1")
    var note: String

    @Field(key: "isMealPlanInstance")
    var isMealPlanInstance: Bool

    @Field(key: "isNoteOrSection")
    var isNoteOrSection: Bool

    @Field(key: "isPinned")
    var isPinned: Bool

    @Field(key: "isPinnedCount")
    var pinnedCount: Int

    @Field(key: "dateAdded")
    var dateAdded: Date

    //––– Relationship fields as String‑arrays –––
    @Field(key: "ingredients")
    var ingredients: [String]

    @Field(key: "methods")
    var methods: [String]

    @Field(key: "categories")
    var categories: [String]

    @Field(key: "cuisines")
    var cuisines: [String]

    //––– Fluent requires an empty init –––
    init() {}

    /// Convenience initializer if you want to build one in code
    init(
        id: UUID? = nil,
        ownerID: UUID? = nil,
        remoteID: String,
        title: String,
        description: String,
        cookTime: String,
        prepTime: String,
        servings: String,
        imageURL: String,
        domainURL: String,
        nutritionalInfo: String,
        rating: Double,
        ratingCount: Double,
        note: String,
        isMealPlanInstance: Bool,
        isNoteOrSection: Bool,
        isPinned: Bool,
        pinnedCount: Int,
        dateAdded: Date,
        ingredients: [String],
        methods: [String],
        categories: [String],
        cuisines: [String]
    ) {
        self.id = id
        if let ownerID = ownerID {
            self.$owner.id = ownerID
        }
        self.remoteID           = remoteID
        self.title              = title
        self.description        = description
        self.cookTime           = cookTime
        self.prepTime           = prepTime
        self.servings           = servings
        self.imageURL           = imageURL
        self.domainURL          = domainURL
        self.nutritionalInfo    = nutritionalInfo
        self.rating             = rating
        self.ratingCount        = ratingCount
        self.note               = note
        self.isMealPlanInstance = isMealPlanInstance
        self.isNoteOrSection    = isNoteOrSection
        self.isPinned           = isPinned
        self.pinnedCount        = pinnedCount
        self.dateAdded          = dateAdded
        self.ingredients        = ingredients
        self.methods            = methods
        self.categories         = categories
        self.cuisines           = cuisines
    }
}
