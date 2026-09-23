import XCTest
@testable import MondayMoneyMove

@MainActor
final class MoveStoreTests: XCTestCase {
    func testSavedMoveAndCompletionSurviveRelaunch() throws {
        let name = "MoveStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = MoveStore(defaults: defaults)
        store.add("Review recurring expenses")
        store.completeCurrent()
        let reopened = MoveStore(defaults: defaults)
        XCTAssertEqual(reopened.current?.text, "Review recurring expenses")
        XCTAssertEqual(reopened.completedCount, 1)
        XCTAssertEqual(reopened.current?.id, store.current?.id)
        reopened.add("Set a savings goal")
        XCTAssertEqual(reopened.moves.count, 2)
        XCTAssertEqual(reopened.current?.text, "Set a savings goal")
        XCTAssertEqual(reopened.completedCount, 1)
    }

    func testDeletionPersistsAndEmptyCompletionIsSafe() throws {
        let name = "MoveStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = MoveStore(defaults: defaults)
        store.completeCurrent()
        XCTAssertTrue(store.moves.isEmpty)
        store.add("Review a bill")
        store.clearAll()
        XCTAssertTrue(MoveStore(defaults: defaults).moves.isEmpty)
    }

    func testCorruptSavedDataDoesNotCrash() throws {
        let name = "MoveStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(Data("not JSON".utf8), forKey: "mondayMoneyMoves")
        let store = MoveStore(defaults: defaults)
        XCTAssertTrue(store.moves.isEmpty)
        store.add("Start again")
        XCTAssertEqual(MoveStore(defaults: defaults).current?.text, "Start again")
    }
}
