//
//  HybridFuelTests.swift
//  EVChargingTrackerTests
//
//  Covers hybrid car / gasoline fuel support: derived price-per-unit, the
//  three-way fuel calc, export/import round-trips, and fuel-expense cleanup.
//

import Testing
@testable import EVChargingTracker

struct HybridFuelTests {

    // MARK: - getFuelPricePerUnit (derived, never stored)

    @Test func getFuelPricePerUnit_returnsCostDividedByVolume_forFuel() async throws {
        let expense = createTestFuelExpense(cost: 60.0, fuelVolume: 40.0)
        #expect(expense.getFuelPricePerUnit() == 1.5)
    }

    @Test func getFuelPricePerUnit_isNil_forNonFuelExpense() async throws {
        let charging = Expense(
            date: Date(),
            energyCharged: 50,
            chargerType: .home7kW,
            odometer: 1000,
            cost: 25,
            notes: "",
            isInitialRecord: false,
            expenseType: .charging,
            currency: .usd)
        #expect(charging.getFuelPricePerUnit() == nil)
    }

    @Test func getFuelPricePerUnit_isNil_whenVolumeIsZero() async throws {
        let expense = createTestFuelExpense(cost: 60.0, fuelVolume: 0)
        #expect(expense.getFuelPricePerUnit() == nil)
    }

    @Test func getFuelPricePerUnit_isNil_whenCostIsNil() async throws {
        let expense = createTestFuelExpense(cost: nil, fuelVolume: 40.0)
        #expect(expense.getFuelPricePerUnit() == nil)
    }

    // MARK: - Three-way fuel calc (FuelCalc)

    @Test func fuelCalc_cost_isVolumeTimesPrice() async throws {
        #expect(FuelCalc.cost(volume: 40, price: 1.5) == 60)
    }

    @Test func fuelCalc_volume_isCostDividedByPrice() async throws {
        #expect(FuelCalc.volume(cost: 60, price: 1.5) == 40)
    }

    @Test func fuelCalc_volume_isNil_whenPriceIsZero() async throws {
        #expect(FuelCalc.volume(cost: 60, price: 0) == nil)
    }

    // MARK: - Export / import round-trip (price survives because it is derived)

    @Test func fuelExpense_roundTripsThroughExport_preservingDerivedPrice() async throws {
        let original = createTestFuelExpense(cost: 60.0, fuelType: .octane98, fuelVolume: 40.0)

        let exported = ExportExpense(from: original)
        let restored = try exported.toExpense()

        #expect(restored.expenseType == .fuel)
        #expect(restored.fuelType == .octane98)
        #expect(restored.fuelVolume == 40.0)
        #expect(restored.cost == 60.0)
        #expect(restored.getFuelPricePerUnit() == 1.5)
    }

    @Test func oldBackupWithoutFuelFields_decodesAsNonFuel() async throws {
        // A pre-v9 backup carries no fuel fields; decoding must not crash and
        // the fuel accessors stay nil.
        let json = """
        {
          "id": 5,
          "date": 0,
          "energyCharged": 12.5,
          "chargerType": "Home (7kW)",
          "odometer": 1000,
          "cost": "25.0",
          "notes": "",
          "isInitialRecord": false,
          "expenseType": "charging",
          "currency": "USD",
          "carId": 1
        }
        """
        let exported = try JSONDecoder().decode(ExportExpense.self, from: Data(json.utf8))
        let restored = try exported.toExpense()
        #expect(restored.fuelType == nil)
        #expect(restored.fuelVolume == nil)
    }

    @Test func hybridCar_roundTripsThroughExport() async throws {
        let original = createTestCar(carType: .hybrid)

        let exported = ExportCar(from: original)
        let restored = exported.toCar()

        #expect(restored.carType == .hybrid)
    }

    @Test func oldBackupWithoutCarType_defaultsToElectric() async throws {
        let json = """
        {
          "id": 1,
          "name": "Legacy",
          "selectedForTracking": true,
          "batteryCapacity": 75,
          "expenseCurrency": "USD",
          "currentMileage": 1000,
          "initialMileage": 0,
          "milleageSyncedAt": 0,
          "createdAt": 0
        }
        """
        let exported = try JSONDecoder().decode(ExportCar.self, from: Data(json.utf8))
        #expect(exported.toCar().carType == .electric)
    }

    // MARK: - deleteFuelExpenses isolation

    @Test func deleteFuelExpenses_removesOnlyFuelRowsForThatCar() async throws {
        let repo = MockExpensesRepository()
        repo.expenses = [
            createTestFuelExpense(id: 1, carId: 1),
            createTestFuelExpense(id: 2, carId: 1),
            createTestFuelExpense(id: 3, carId: 2),
            Expense(
                id: 4, date: Date(), energyCharged: 10, chargerType: .home7kW,
                odometer: 1, cost: 5, notes: "", isInitialRecord: false,
                expenseType: .charging, currency: .usd, carId: 1)
        ]

        let removed = repo.deleteFuelExpenses(forCar: 1)

        #expect(removed == 2)
        #expect(repo.expenses.count == 2)
        #expect(repo.expenses.contains { $0.id == 3 }) // other car's fuel kept
        #expect(repo.expenses.contains { $0.id == 4 }) // car 1's charging kept
    }

    // MARK: - Localized labels

    @Test func fuelType_localizedName_usesRonFormat() async throws {
        // L() falls back to the key, so the format substitution is what matters.
        #expect(FuelType.octane95.localizedName.contains("95"))
    }
}
