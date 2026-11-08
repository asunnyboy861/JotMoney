import Foundation

struct MerchantProfile {
    let displayName: String
    let categoryKey: String
    let aliases: [String]
}

enum MerchantDictionary {
    static let entries: [MerchantProfile] = build()

    private static func build() -> [MerchantProfile] {
        [
            MerchantProfile(displayName: "Starbucks", categoryKey: DefaultCategoryKey.dining, aliases: ["sbux", "starbux", "starbucks coffee"]),
            MerchantProfile(displayName: "Dunkin", categoryKey: DefaultCategoryKey.dining, aliases: ["dunkin donuts", "dd"]),
            MerchantProfile(displayName: "McDonald's", categoryKey: DefaultCategoryKey.dining, aliases: ["mcdonalds", "mcd", "mc donalds"]),
            MerchantProfile(displayName: "Chipotle", categoryKey: DefaultCategoryKey.dining, aliases: ["chipotle mexican grill"]),
            MerchantProfile(displayName: "Chick-fil-A", categoryKey: DefaultCategoryKey.dining, aliases: ["chickfila", "chick fil a"]),
            MerchantProfile(displayName: "Taco Bell", categoryKey: DefaultCategoryKey.dining, aliases: ["tacobell"]),
            MerchantProfile(displayName: "Subway", categoryKey: DefaultCategoryKey.dining, aliases: []),
            MerchantProfile(displayName: "Panera", categoryKey: DefaultCategoryKey.dining, aliases: ["panera bread"]),
            MerchantProfile(displayName: "Shake Shack", categoryKey: DefaultCategoryKey.dining, aliases: ["shakeshack"]),
            MerchantProfile(displayName: "Five Guys", categoryKey: DefaultCategoryKey.dining, aliases: ["fiveguys"]),
            MerchantProfile(displayName: "In-N-Out", categoryKey: DefaultCategoryKey.dining, aliases: ["in n out", "innout"]),
            MerchantProfile(displayName: "Wendy's", categoryKey: DefaultCategoryKey.dining, aliases: ["wendys"]),
            MerchantProfile(displayName: "Burger King", categoryKey: DefaultCategoryKey.dining, aliases: ["burgerking"]),
            MerchantProfile(displayName: "Popeyes", categoryKey: DefaultCategoryKey.dining, aliases: []),
            MerchantProfile(displayName: "Domino's", categoryKey: DefaultCategoryKey.dining, aliases: ["dominos", "domino's pizza"]),
            MerchantProfile(displayName: "Pizza Hut", categoryKey: DefaultCategoryKey.dining, aliases: ["pizzahut"]),
            MerchantProfile(displayName: "DoorDash", categoryKey: DefaultCategoryKey.dining, aliases: ["doordash", "door dash"]),
            MerchantProfile(displayName: "Uber Eats", categoryKey: DefaultCategoryKey.dining, aliases: ["ubereats", "uber eats"]),
            MerchantProfile(displayName: "Grubhub", categoryKey: DefaultCategoryKey.dining, aliases: ["grub hub"]),
            MerchantProfile(displayName: "Instacart", categoryKey: DefaultCategoryKey.groceries, aliases: ["insta cart"]),
            MerchantProfile(displayName: "Whole Foods", categoryKey: DefaultCategoryKey.groceries, aliases: ["wholefoods", "whole foods market"]),
            MerchantProfile(displayName: "Trader Joe's", categoryKey: DefaultCategoryKey.groceries, aliases: ["trader joes", "traderjoes"]),
            MerchantProfile(displayName: "Costco", categoryKey: DefaultCategoryKey.groceries, aliases: ["cost co"]),
            MerchantProfile(displayName: "Walmart", categoryKey: DefaultCategoryKey.groceries, aliases: ["wal mart"]),
            MerchantProfile(displayName: "Target", categoryKey: DefaultCategoryKey.shopping, aliases: []),
            MerchantProfile(displayName: "Kroger", categoryKey: DefaultCategoryKey.groceries, aliases: []),
            MerchantProfile(displayName: "Safeway", categoryKey: DefaultCategoryKey.groceries, aliases: []),
            MerchantProfile(displayName: "Aldi", categoryKey: DefaultCategoryKey.groceries, aliases: []),
            MerchantProfile(displayName: "Publix", categoryKey: DefaultCategoryKey.groceries, aliases: []),
            MerchantProfile(displayName: "Sprouts", categoryKey: DefaultCategoryKey.groceries, aliases: ["sprouts farmers market"]),
            MerchantProfile(displayName: "Uber", categoryKey: DefaultCategoryKey.transport, aliases: ["uber ride"]),
            MerchantProfile(displayName: "Lyft", categoryKey: DefaultCategoryKey.transport, aliases: []),
            MerchantProfile(displayName: "Shell", categoryKey: DefaultCategoryKey.transport, aliases: ["shell gas"]),
            MerchantProfile(displayName: "Chevron", categoryKey: DefaultCategoryKey.transport, aliases: []),
            MerchantProfile(displayName: "Exxon", categoryKey: DefaultCategoryKey.transport, aliases: ["exxonmobil", "exxon mobil"]),
            MerchantProfile(displayName: "BP", categoryKey: DefaultCategoryKey.transport, aliases: ["bp gas"]),
            MerchantProfile(displayName: "Metro", categoryKey: DefaultCategoryKey.transport, aliases: ["metro card", "subway fare"]),
            MerchantProfile(displayName: "Amazon", categoryKey: DefaultCategoryKey.shopping, aliases: ["amzn", "amazon.com"]),
            MerchantProfile(displayName: "Walmart.com", categoryKey: DefaultCategoryKey.shopping, aliases: []),
            MerchantProfile(displayName: "Best Buy", categoryKey: DefaultCategoryKey.shopping, aliases: ["bestbuy"]),
            MerchantProfile(displayName: "Home Depot", categoryKey: DefaultCategoryKey.shopping, aliases: ["homedepot"]),
            MerchantProfile(displayName: "Lowe's", categoryKey: DefaultCategoryKey.shopping, aliases: ["lowes"]),
            MerchantProfile(displayName: "IKEA", categoryKey: DefaultCategoryKey.shopping, aliases: []),
            MerchantProfile(displayName: "Nike", categoryKey: DefaultCategoryKey.shopping, aliases: []),
            MerchantProfile(displayName: "Apple", categoryKey: DefaultCategoryKey.shopping, aliases: ["apple store", "apple.com"]),
            MerchantProfile(displayName: "Sephora", categoryKey: DefaultCategoryKey.shopping, aliases: []),
            MerchantProfile(displayName: "CVS", categoryKey: DefaultCategoryKey.health, aliases: ["cvs pharmacy"]),
            MerchantProfile(displayName: "Walgreens", categoryKey: DefaultCategoryKey.health, aliases: ["walgreens pharmacy"]),
            MerchantProfile(displayName: "Rite Aid", categoryKey: DefaultCategoryKey.health, aliases: ["riteaid"]),
            MerchantProfile(displayName: "Netflix", categoryKey: DefaultCategoryKey.entertainment, aliases: []),
            MerchantProfile(displayName: "Spotify", categoryKey: DefaultCategoryKey.entertainment, aliases: []),
            MerchantProfile(displayName: "Hulu", categoryKey: DefaultCategoryKey.entertainment, aliases: []),
            MerchantProfile(displayName: "Disney+", categoryKey: DefaultCategoryKey.entertainment, aliases: ["disney plus", "disneyplus"]),
            MerchantProfile(displayName: "HBO Max", categoryKey: DefaultCategoryKey.entertainment, aliases: ["hbomax", "max"]),
            MerchantProfile(displayName: "YouTube Premium", categoryKey: DefaultCategoryKey.entertainment, aliases: ["youtube"]),
            MerchantProfile(displayName: "Apple Music", categoryKey: DefaultCategoryKey.entertainment, aliases: []),
            MerchantProfile(displayName: "iCloud", categoryKey: DefaultCategoryKey.bills, aliases: ["apple icloud"]),
            MerchantProfile(displayName: "Steam", categoryKey: DefaultCategoryKey.entertainment, aliases: []),
            MerchantProfile(displayName: "AMC", categoryKey: DefaultCategoryKey.entertainment, aliases: ["amc theaters"]),
            MerchantProfile(displayName: "Regal", categoryKey: DefaultCategoryKey.entertainment, aliases: ["regal cinema"]),
            MerchantProfile(displayName: "Planet Fitness", categoryKey: DefaultCategoryKey.health, aliases: ["planetfitness"]),
            MerchantProfile(displayName: "Equinox", categoryKey: DefaultCategoryKey.health, aliases: []),
            MerchantProfile(displayName: "Peloton", categoryKey: DefaultCategoryKey.health, aliases: []),
            MerchantProfile(displayName: "Verizon", categoryKey: DefaultCategoryKey.bills, aliases: []),
            MerchantProfile(displayName: "AT&T", categoryKey: DefaultCategoryKey.bills, aliases: ["att", "at and t"]),
            MerchantProfile(displayName: "T-Mobile", categoryKey: DefaultCategoryKey.bills, aliases: ["tmobile", "t mobile"]),
            MerchantProfile(displayName: "Comcast", categoryKey: DefaultCategoryKey.bills, aliases: ["xfinity"]),
            MerchantProfile(displayName: "Spectrum", categoryKey: DefaultCategoryKey.bills, aliases: []),
            MerchantProfile(displayName: "PG&E", categoryKey: DefaultCategoryKey.bills, aliases: ["pge", "pg and e"]),
            MerchantProfile(displayName: "Con Edison", categoryKey: DefaultCategoryKey.bills, aliases: ["coned", "con edison"]),
            MerchantProfile(displayName: "Geico", categoryKey: DefaultCategoryKey.bills, aliases: []),
            MerchantProfile(displayName: "State Farm", categoryKey: DefaultCategoryKey.bills, aliases: ["statefarm"]),
            MerchantProfile(displayName: "Progressive", categoryKey: DefaultCategoryKey.bills, aliases: []),
            MerchantProfile(displayName: "Klarna", categoryKey: DefaultCategoryKey.shopping, aliases: []),
            MerchantProfile(displayName: "Afterpay", categoryKey: DefaultCategoryKey.shopping, aliases: ["after pay"]),
            MerchantProfile(displayName: "Affirm", categoryKey: DefaultCategoryKey.shopping, aliases: []),
            MerchantProfile(displayName: "Rent", categoryKey: DefaultCategoryKey.bills, aliases: ["rent payment", "apartment rent"]),
            MerchantProfile(displayName: "Landlord", categoryKey: DefaultCategoryKey.bills, aliases: []),
            MerchantProfile(displayName: "Gym", categoryKey: DefaultCategoryKey.health, aliases: []),
            MerchantProfile(displayName: "Doctor", categoryKey: DefaultCategoryKey.health, aliases: ["clinic", "urgent care"]),
            MerchantProfile(displayName: "Pharmacy", categoryKey: DefaultCategoryKey.health, aliases: []),
            MerchantProfile(displayName: "Coffee", categoryKey: DefaultCategoryKey.dining, aliases: ["latte", "espresso", "cafe", "café"]),
            MerchantProfile(displayName: "Lunch", categoryKey: DefaultCategoryKey.dining, aliases: ["dinner", "breakfast", "brunch", "food"]),
            MerchantProfile(displayName: "Groceries", categoryKey: DefaultCategoryKey.groceries, aliases: ["grocery", "supermarket"]),
            MerchantProfile(displayName: "Gas", categoryKey: DefaultCategoryKey.transport, aliases: ["fuel", "gasoline"]),
            MerchantProfile(displayName: "Parking", categoryKey: DefaultCategoryKey.transport, aliases: ["garage", "meter"]),
            MerchantProfile(displayName: "Salary", categoryKey: DefaultCategoryKey.income, aliases: ["paycheck", "payroll", "pay"]),
            MerchantProfile(displayName: "Refund", categoryKey: DefaultCategoryKey.income, aliases: ["reimbursement", "cashback"])
        ]
    }

    static func match(_ merchantKey: String) -> MerchantProfile? {
        let key = merchantKey.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }
        for profile in entries {
            if profile.displayName.lowercased() == key { return profile }
            if profile.aliases.contains(where: { $0 == key }) { return profile }
        }
        for profile in entries {
            let names = [profile.displayName.lowercased()] + profile.aliases
            if names.contains(where: { key.hasPrefix($0) || key.hasSuffix($0) }) {
                return profile
            }
        }
        return nil
    }
}
