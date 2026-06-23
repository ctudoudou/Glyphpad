import CSQLite
import Foundation

public final class SQLiteDatabase: @unchecked Sendable {
    private let handle: OpaquePointer

    public init(path: String) throws {
        var database: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(path, &database, flags, nil)

        guard result == SQLITE_OK, let database else {
            let message = database.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite error"
            if let database {
                sqlite3_close(database)
            }
            throw SQLiteError.openFailed(message)
        }

        self.handle = database
        try execute("PRAGMA foreign_keys = ON;")
    }

    deinit {
        sqlite3_close(handle)
    }

    public func execute(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(handle, sql, nil, nil, &errorMessage)

        guard result == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? lastErrorMessage
            sqlite3_free(errorMessage)
            throw SQLiteError.stepFailed(message)
        }
    }

    public func prepare(_ sql: String) throws -> SQLiteStatement {
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(handle, sql, -1, &statement, nil)

        guard result == SQLITE_OK, let statement else {
            throw SQLiteError.prepareFailed(lastErrorMessage)
        }

        return SQLiteStatement(statement: statement, database: self)
    }

    fileprivate var lastErrorMessage: String {
        String(cString: sqlite3_errmsg(handle))
    }
}

public final class SQLiteStatement {
    private let statement: OpaquePointer
    private unowned let database: SQLiteDatabase
    private let transientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    fileprivate init(statement: OpaquePointer, database: SQLiteDatabase) {
        self.statement = statement
        self.database = database
    }

    deinit {
        sqlite3_finalize(statement)
    }

    public func bind(_ value: String, at index: Int32) throws {
        let result = sqlite3_bind_text(statement, index, value, -1, transientDestructor)
        try checkBind(result)
    }

    public func bind(_ value: String?, at index: Int32) throws {
        guard let value else {
            try bindNull(at: index)
            return
        }

        try bind(value, at: index)
    }

    public func bind(_ value: Int, at index: Int32) throws {
        let result = sqlite3_bind_int64(statement, index, sqlite3_int64(value))
        try checkBind(result)
    }

    public func bind(_ value: Double, at index: Int32) throws {
        let result = sqlite3_bind_double(statement, index, value)
        try checkBind(result)
    }

    public func bindNull(at index: Int32) throws {
        let result = sqlite3_bind_null(statement, index)
        try checkBind(result)
    }

    public func step() throws -> Bool {
        let result = sqlite3_step(statement)

        switch result {
        case SQLITE_ROW:
            return true
        case SQLITE_DONE:
            return false
        default:
            throw SQLiteError.stepFailed(database.lastErrorMessage)
        }
    }

    public func reset() throws {
        let result = sqlite3_reset(statement)
        guard result == SQLITE_OK else {
            throw SQLiteError.stepFailed(database.lastErrorMessage)
        }
        sqlite3_clear_bindings(statement)
    }

    public func string(at column: Int32) throws -> String {
        guard let value = sqlite3_column_text(statement, column) else {
            throw SQLiteError.invalidColumn("Column \(column) is NULL")
        }

        return String(cString: value)
    }

    public func optionalString(at column: Int32) -> String? {
        guard let value = sqlite3_column_text(statement, column) else {
            return nil
        }

        return String(cString: value)
    }

    public func int(at column: Int32) -> Int {
        Int(sqlite3_column_int64(statement, column))
    }

    public func double(at column: Int32) -> Double {
        sqlite3_column_double(statement, column)
    }

    private func checkBind(_ result: Int32) throws {
        guard result == SQLITE_OK else {
            throw SQLiteError.bindFailed(database.lastErrorMessage)
        }
    }
}
