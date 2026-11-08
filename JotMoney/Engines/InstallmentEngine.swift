import Foundation

enum InstallmentEngine {
    static func schedule(plan: InstallmentPlan, calendar: Calendar = .current) -> [Date] {
        guard plan.periodCount > 0 else { return [] }
        let cadence = plan.cadence
        return (0..<plan.periodCount).compactMap { index in
            if index == 0 { return plan.firstChargeDate }
            return calendar.date(
                byAdding: cadence.component,
                value: index * cadence.step,
                to: plan.firstChargeDate
            )
        }
    }

    static func validate(_ plan: InstallmentPlan) throws {
        guard plan.periodCount > 0, plan.perPeriodCents > 0 else {
            throw LedgerError.planMismatch(total: plan.totalCents, product: 0)
        }
        let product = Int64(plan.periodCount) * plan.perPeriodCents
        let difference = plan.totalCents - product
        guard abs(difference) <= Int64(plan.periodCount) else {
            throw LedgerError.planMismatch(total: plan.totalCents, product: product)
        }
    }

    static func periodAmount(plan: InstallmentPlan, index: Int) -> Int64 {
        guard index == 0 else { return plan.perPeriodCents }
        let residual = plan.totalCents - plan.perPeriodCents * Int64(plan.periodCount)
        return plan.perPeriodCents + residual
    }

    static func dueIndices(plan: InstallmentPlan, now: Date = Date()) -> [Int] {
        let dates = schedule(plan: plan)
        guard plan.generatedCount < dates.count else { return [] }
        return (plan.generatedCount..<dates.count).filter { dates[$0] <= now }
    }

    static func nextChargeDate(plan: InstallmentPlan, now: Date = Date()) -> Date? {
        schedule(plan: plan).first { $0 >= now }
    }

    static func remainingCents(plan: InstallmentPlan) -> Int64 {
        let dates = schedule(plan: plan)
        guard plan.generatedCount < dates.count else { return 0 }
        var total: Int64 = 0
        for index in plan.generatedCount..<dates.count {
            total += periodAmount(plan: plan, index: index)
        }
        return total
    }
}
