import Foundation
import SwiftData

enum Persistence {
    static let schema = Schema([
        Account.self,
        LedgerEntry.self,
        Category.self,
        Budget.self,
        RecurringRule.self,
        InstallmentPlan.self,
        InterestEntry.self,
        MerchantMemory.self,
        AuditLogEntry.self
    ])

    static func makeContainer() -> ModelContainer {
        if AppPreferences.iCloudSyncEnabled,
           let cloud = try? ModelContainer(
               for: schema,
               configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .private("iCloud.com.zzoutuo.JotMoney"))]
           ) {
            return cloud
        }
        if let local = try? ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)]) {
            return local
        }
        if let memory = try? ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]) {
            return memory
        }
        fatalError("Unable to create the JotMoney data store")
    }
}
