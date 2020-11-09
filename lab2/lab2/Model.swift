import Foundation
import PostgresClientKit

protocol Condition {
    var parameter : String { get }
}

extension Condition {
    fileprivate var text : String {
        var conditionsText = ""
        if self is Database.Query.MatchCondition {
            let matchCondition = self as! Database.Query.MatchCondition
            conditionsText = "\"\(matchCondition.parameter)\" LIKE '\(matchCondition.pattern)'"
        }
        if self is Database.Query.RangeCondition<Date> {
            let dateRangeCondition = self as! Database.Query.RangeCondition<Date>
            let parameter = dateRangeCondition.parameter
            let lowerBound = PostgresTimestampWithTimeZone(date: dateRangeCondition.range.lowerBound).description
            let upperBound = PostgresTimestampWithTimeZone(date: dateRangeCondition.range.upperBound).description
            if !dateRangeCondition.range.isEmpty {
                conditionsText = "\"\(parameter)\" >= '\(lowerBound)' AND \"\(parameter)\" <= '\(upperBound)'"
            }
        }
        if self is Database.Query.RangeCondition<UInt> {
            let numberRangeCondition = self as! Database.Query.RangeCondition<UInt>
            if !numberRangeCondition.range.isEmpty {
                conditionsText = "\"\(numberRangeCondition.parameter)\" >= \(numberRangeCondition.range.lowerBound) AND \"\(numberRangeCondition.parameter)\" <= \(numberRangeCondition.range.upperBound)"
            }
        }
        if self is Database.Query.RangeCondition<Double> {
            let numberRangeCondition = self as! Database.Query.RangeCondition<Double>
            if !numberRangeCondition.range.isEmpty {
                conditionsText = "\"\(numberRangeCondition.parameter)\" >= \(numberRangeCondition.range.lowerBound) AND \"\(numberRangeCondition.parameter)\" <= \(numberRangeCondition.range.upperBound)"
            }
        }
        if self is Database.Query.EqualsCondition<UInt> {
            let numberRangeCondition = self as! Database.Query.EqualsCondition<UInt>
            conditionsText = "\(numberRangeCondition.parameter) = \(numberRangeCondition.value)"
        }
        if self is Database.Query.EqualsCondition<Double> {
            let numberRangeCondition = self as! Database.Query.EqualsCondition<Double>
            conditionsText = "\(numberRangeCondition.parameter) = \(numberRangeCondition.value)"
        }
        if self is Database.Query.EqualsCondition<Date> {
            let numberRangeCondition = self as! Database.Query.EqualsCondition<Double>
            conditionsText = "\(numberRangeCondition.parameter) = \(numberRangeCondition.value)"
        }
        if self is Database.Query.EqualsCondition<String> {
            let numberRangeCondition = self as! Database.Query.EqualsCondition<String>
            conditionsText = "\(numberRangeCondition.parameter) = '\(numberRangeCondition.value)'"
        }
        return conditionsText
    }
}

protocol TableProtocol {
    associatedtype Entity
    var propertyList : [(String, Any.Type)] { get }

    func getEntries (fits conditions : [Condition], limit : Int, offset : UInt) -> Database.Query.Responce<[Entity]>
    func save(entry: Entity) throws
    func delete(entry: Entity) throws
}

class Database {
    var connection : PostgresClientKit.Connection
    var tables : Tables?
    
    init? () {
        do {
            var configuration = PostgresClientKit.ConnectionConfiguration()
            configuration.database = "daninaDB"
            configuration.user = "postgres"
            configuration.ssl = false
            
            connection = try PostgresClientKit.Connection(configuration: configuration)
        } catch {
            print(error)
            return nil
        }
        tables = Tables(db : self)
    }
    
    deinit {
        connection.close()
    }
    
    class Query {
        struct Responce<T> {
            var data : T?
            var error : PostgresClientKit.PostgresError?
            
            init(_ data : T? = nil, error : PostgresClientKit.PostgresError? = nil) {
                self.error = error
                self.data = data
            }
        }
        
        class MatchCondition : Condition {
            let parameter : String
            fileprivate let pattern : String
            
            init (parameter name : String, matches pattern : String) {
                self.parameter = name
                self.pattern = pattern
            }
        }
        
        class RangeCondition<T : Comparable> : Condition {
            let parameter : String
            fileprivate let range : ClosedRange<T>
            
            init (parameter name : String, in range : ClosedRange<T>) {
                self.parameter = name
                self.range = range
            }
        }
        
        class EqualsCondition<T> : Condition {
            let parameter : String
            fileprivate let value : T
            
            init (parameter name : String, equals value : T) {
                self.parameter = name
                self.value = value
            }
        }
        
        private init() {}
    }
    
    class Tables {
        let db : Database
        
        let users : Users
        let tables : Tables
        let items : MenuItems
        let orders : Orders
        let bridge : OrderItemBridge
        
        fileprivate init(db : Database) {
            self.db = db
            
            users = Users(db: db)
            tables = Tables(db: db)
            items = MenuItems(db: db)
            orders = Orders(db: db)
            bridge = OrderItemBridge(db: db)
        }
        
        class Users : Table, TableProtocol {
            unowned let db : Database
            
            let propertyList : [(String, Any.Type)] = [("userID", UInt.self), ("username", String.self), ("fullname", String.self), ("password_hash", String.self), ("role", UInt.self)]
            
            func getEntries (fits conditions : [Condition] = [], limit : Int = -1, offset : UInt = 0) -> Query.Responce<[Entities.User]> {
                do {
                    let text = "SELECT * FROM Users \(getProcessed(conditions: conditions)) ORDER BY \"userID\" ASC LIMIT \((limit < 0) ? "ALL" : String(limit)) OFFSET \(offset)"
                    print(text)
                    let statement = try db.connection.prepareStatement(text: text)
                    defer { statement.close() }
                    let cursor = try statement.execute()
                    defer { cursor.close() }
                    var res : [Entities.User] = []
                    for row in cursor {
                        let columns = try row.get().columns
                        let userID = UInt (try columns[0].int())
                        let username = try columns[1].string()
                        let fullname = try columns[2].string()
                        let password_hash = try columns[3].string()
                        let role = UInt (try columns[4].int())
                        let user = Entities.User(userID : userID, username : username, fullname : fullname, password_hash : password_hash, role : role)
                        res.append (user)
                    }
                    return Query.Responce(res)
                } catch {
                    return Query.Responce(error : error as? PostgresClientKit.PostgresError)
                }
            }
            
            func save(entry: Entities.User) throws {
                var text : String
                if let userID = entry.userID {
                    text = "UPDATE Users SET (username, fullname, password_hash, role) = ($1, $2, $3, $4) WHERE \"userID\" = \(userID)"
                } else {
                    text = "INSERT INTO Users (username, fullname, password_hash, role) VALUES ($1, $2, $3, $4) RETURNING \"userID\""
                }
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute(parameterValues: [entry.username, entry.fullname, entry.password_hash, String(entry.role)])
                defer { cursor.close() }
                guard entry.userID == nil else {
                    return
                }
                for row in cursor {
                    let columns = try row.get().columns
                    entry.userID = UInt (try columns[0].int())
                }
            }
            
            func delete(entry: Entities.User) throws {
                guard let userID = entry.userID else {
                    print ("userID is not set : no way to determine entity to delete")
                    return
                }
                //try db.orders!.delete(by : "userID", of : userID)
                let text = "DELETE FROM Users WHERE \"userID\" = \(userID);"
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute()
                cursor.close()
            }
            
            func insertRandomEntries(amount : UInt) throws {
                let text = "INSERT INTO Users (\"username\", \"fullname\", \"password_hash\", \"role\") SELECT md5(random()::text), md5(random()::text), md5(random()::text), trunc(random()*4 + 1)::smallint FROM generate_series(1, $1)"
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute(parameterValues: [String(amount)])
                cursor.close()
            }
            
            fileprivate init(db : Database) {
                self.db = db
            }
        }
        
        class Tables : Table, TableProtocol {
            unowned let db : Database
            
            let propertyList : [(String, Any.Type)] = [("tableID", UInt.self), ("numberOfSeats", UInt.self)]
            
            func getEntries (fits conditions : [Condition] = [], limit : Int = -1, offset : UInt = 0) -> Query.Responce<[Entities.Table]> {
                do {
                    let text = "SELECT * FROM Tables \(getProcessed(conditions: conditions)) ORDER BY \"tableID\" ASC LIMIT \((limit < 0) ? "ALL" : String(limit)) OFFSET \(offset)"
                    let statement = try db.connection.prepareStatement(text: text)
                    defer { statement.close() }
                    let cursor = try statement.execute()
                    defer { cursor.close() }
                    var res : [Entities.Table] = []
                    for row in cursor {
                        let columns = try row.get().columns
                        let tableID = UInt (try columns[1].int())
                        let numberOfSeats = UInt (try columns[0].int())
                        let table = Entities.Table(tableID : tableID, numberOfSeats: numberOfSeats)
                        res.append (table)
                    }
                    return Query.Responce(res)
                } catch {
                    return Query.Responce(error : error as? PostgresClientKit.PostgresError)
                }
            }
            
            func save(entry: Entities.Table) throws {
                var text : String
                if let tableID = entry.tableID {
                    text = "UPDATE Tables SET \"numberOfSeats\" = $1 WHERE \"tableID\" = \(tableID)"
                } else {
                    text = "INSERT INTO Tables (\"numberOfSeats\") VALUES ($1) RETURNING \"tableID\""
                }
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute(parameterValues: [String (entry.numberOfSeats)])
                defer { cursor.close() }
                guard entry.tableID == nil else {
                    return
                }
                for row in cursor {
                    let columns = try row.get().columns
                    entry.tableID = UInt (try columns[0].int())
                }
            }
            
            func delete(entry: Entities.Table) throws {
                guard let tableID = entry.tableID else {
                    print ("tableID is not set : no way to determine entity to delete")
                    return
                }
                //try db.orders!.delete(by : "tableID", of : tableID)
                let text = "DELETE FROM Tables WHERE \"tableID\" = \(tableID)"
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute()
                cursor.close()
            }
            
            func insertRandomEntries(amount : UInt) throws {
                let text = "INSERT INTO Tables (\"numberOfSeats\") SELECT trunc(random() * 8 + 1)::smallint FROM generate_series(1, $1)"
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute(parameterValues: [String(amount)])
                cursor.close()
            }
            
            fileprivate init(db : Database) {
                self.db = db
            }
        }
        
        class MenuItems : Table, TableProtocol {
            unowned let db : Database
            
            let propertyList : [(String, Any.Type)] = [("itemID", UInt.self), ("description", String.self), ("price", Double.self), ("photoURL", String.self)]
            
            func getEntries (fits conditions : [Condition] = [], limit : Int = -1, offset : UInt = 0) -> Query.Responce<[Entities.MenuItem]> {
                do {
                    let text = "SELECT * FROM menu_items \(getProcessed(conditions: conditions))  ORDER BY \"itemID\" ASC LIMIT \((limit < 0) ? "ALL" : String(limit)) offset \(offset)"
                    let statement = try db.connection.prepareStatement(text: text)
                    defer { statement.close() }
                    let cursor = try statement.execute()
                    defer { cursor.close() }
                    var res : [Entities.MenuItem] = []
                    for row in cursor {
                        let columns = try row.get().columns
                        let itemID = UInt (try columns[0].int())
                        let description = try columns[1].string()
                        let price = try columns[2].double()
                        let photoURL = try columns[3].string()
                        let item = Entities.MenuItem(itemID : itemID, description: description, price : price, photoURL : photoURL)
                        res.append (item)
                    }
                    return Query.Responce(res)
                } catch {
                    return Query.Responce(error : error as? PostgresClientKit.PostgresError)
                }
            }
            
            func save(entry: Entities.MenuItem) throws {
                var text : String
                if let itemID = entry.itemID {
                    text = "UPDATE menu_items SET (\"description\", \"price\", \"photoURL\") = ($1, $2, $3) WHERE \"itemID\" = \(itemID)"
                } else {
                    text = "INSERT INTO menu_items (\"description\", \"price\", \"photoURL\") VALUES ($1, $2, $3) RETURNING \"itemID\""
                }
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute(parameterValues: [String (entry.description), String(entry.price), String(entry.photoURL)])
                defer { cursor.close() }
                guard entry.itemID == nil else {
                    return
                }
                for row in cursor {
                    let columns = try row.get().columns
                    entry.itemID = UInt (try columns[0].int())
                }
            }
            
            func delete(entry: Entities.MenuItem) throws {
                guard let itemID = entry.itemID else {
                    print ("itemID is not set : no way to determine entity to delete")
                    return
                }
                let text = "DELETE FROM menu_items WHERE \"itemID\" = \(itemID)"//; DELETE FROM order_item_bridge WHERE \"itemID\" = \(itemID);"
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute()
                cursor.close()
            }
            
            func insertRandomEntries(amount : UInt) throws {
                let text = "INSERT INTO menu_items (\"description\", \"price\", \"photoURL\") SELECT md5(random()::text), trunc(random()*10000)/100, md5(random()::text) FROM generate_series(1, $1)"
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute(parameterValues: [String(amount)])
                cursor.close()
            }
            
            fileprivate init(db : Database) {
                self.db = db
            }
        }
        
        class Orders : Table, TableProtocol {
            unowned let db : Database
            
            let propertyList : [(String, Any.Type)] = [("orderID", UInt.self), ("userID", UInt.self), ("date", Date.self), ("tableID", UInt.self)]
            
            func getEntries (fits contitions : [Condition] = [], limit : Int = -1, offset : UInt = 0) -> Query.Responce<[Entities.Order]> {
                do {
                    let text = "SELECT * FROM orders \(getProcessed(conditions: contitions)) ORDER BY \"orderID\" ASC LIMIT \((limit < 0) ? "ALL" : String(limit)) offset \(offset)"
                    let statement = try db.connection.prepareStatement(text: text)
                    defer { statement.close() }
                    let cursor = try statement.execute()
                    defer { cursor.close() }
                    var res : [Entities.Order] = []
                    for row in cursor {
                        let columns = try row.get().columns
                        let orderID = UInt (try columns[0].int())
                        let userID = UInt(try columns[1].int())
                        let date = try columns[2].timestampWithTimeZone().date
                        let tableID = UInt(try columns[3].int())
                        let order = Entities.Order(orderID : orderID, userID: userID, date : date, tableID : tableID)
                        res.append (order)
                    }
                    for entry in res {
                        let entries = db.tables!.bridge.getEntries(fits: [Query.EqualsCondition(parameter: "orderID", equals: entry.orderID!)]).data!.map {
                            $0.1
                        }
                        entry.items = Set (entries)
                    }
                    return Query.Responce(res)
                } catch {
                    return Query.Responce(error : error as? PostgresClientKit.PostgresError)
                }
            }
            
            func save(entry: Entities.Order) throws {
                var text : String
                if let orderID = entry.orderID {
                    text = "UPDATE orders SET (\"userID\", \"date\", \"tableID\") = ($1, $2, $3) WHERE \"orderID\" = \(orderID)"
                } else {
                    text = "INSERT INTO orders (\"userID\", \"date\", \"tableID\") VALUES ($1, $2, $3) RETURNING \"orderID\""
                }
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute(parameterValues: [String (entry.userID), PostgresTimestampWithTimeZone(date: entry.date), String(entry.tableID)])
                defer { cursor.close() }
                if entry.orderID != nil  {
                    try db.tables!.bridge.delete(by: "orderID", equals: entry.orderID!)
                } else {
                    for row in cursor {
                        let columns = try row.get().columns
                        entry.orderID = UInt (try columns[0].int())
                    }
                }
                for item in entry.items {
                    try db.tables!.bridge.save(entry: (entry.orderID!, item))
                }
            }
            
            func delete(entry: Entities.Order) throws {
                guard let orderID = entry.orderID else {
                    print ("orderID is not set : no way to determine entity to delete")
                    return
                }
                let text = "DELETE FROM orders WHERE \"orderID\" = \(orderID)"
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute()
                cursor.close()
            }
            
            func insertRandomEntries(amount : UInt) throws {
                let text = "INSERT INTO orders (\"userID\", \"date\", \"tableID\") SELECT \"userID\", NOW()::timestamp - random() * (INTERVAL '8' DAY), \"tableID\" FROM users, tables ORDER BY random() LIMIT $1 RETURNING \"orderID\""
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute(parameterValues: [String(amount)])
                defer { cursor.close() }
                var orderIds : [UInt] = []
                for row in cursor {
                    let columns = try row.get().columns
                    orderIds.append(UInt (try columns[0].int()))
                }
                for id in orderIds {
                    print (id)
                    try db.tables!.bridge.insertRandomEntries(maxAmount: 12, for: id)
                }
            }
            
            fileprivate init(db : Database) {
                self.db = db
            }
        }
        
        class OrderItemBridge : Table, TableProtocol {
            unowned let db : Database
            
            let propertyList : [(String, Any.Type)] = [("orderID", UInt.self), ("itemID", UInt.self)]
            
            func getEntries (fits conditions : [Condition], limit : Int = -1, offset : UInt = 0) -> Query.Responce<[(UInt, UInt)]> {
                do {
                    let text = "SELECT * FROM order_item_bridge \(getProcessed(conditions: conditions)) ORDER BY \"orderID\" ASC LIMIT \((limit < 0) ? "ALL" : String(limit)) offset \(offset)"
                    let statement = try db.connection.prepareStatement(text: text)
                    defer { statement.close() }
                    let cursor = try statement.execute()
                    defer { cursor.close() }
                    var res : [(UInt, UInt)] = []
                    for row in cursor {
                        let columns = try row.get().columns
                        let orderID = UInt (try columns[1].int())
                        let itemID = UInt (try columns[1].int())
                        res.append ((orderID, itemID))
                    }
                    return Query.Responce(res)
                } catch {
                    return Query.Responce(error : error as? PostgresClientKit.PostgresError)
                }
            }
            
            func save (entry : (UInt, UInt)) throws {
                let (orderID, itemID) = entry
                let text = "INSERT INTO order_item_bridge (\"orderID\", \"itemID\") VALUES ($1, $2) ON CONFLICT (\"orderID\", \"itemID\") DO NOTHING"
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute(parameterValues: [String (orderID), String(itemID)])
                cursor.close()
            }
            
            func delete(entry : (UInt, UInt)) throws {
                let (orderID, itemID) = entry
                let text = "DELETE FROM order_item_bridge WHERE \"orderID\" = \(orderID) AND \"itemID\" = \(itemID)"
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute()
                cursor.close()
            }
            
            func delete (by parameter: String, equals value : UInt) throws {
                let text = "DELETE FROM order_item_bridge WHERE \"\(parameter)\" = \(value)"
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute()
                cursor.close()
            }
            
            func insertRandomEntries(maxAmount : UInt, for orderID : UInt) throws {
                let text = "INSERT INTO order_item_bridge SELECT $1, \"itemID\" FROM menu_items ORDER BY random() limit (trunc(random() * $2) + 1)::int"
                let statement = try db.connection.prepareStatement(text: text)
                defer { statement.close() }
                let cursor = try statement.execute(parameterValues: [String(orderID), String(maxAmount)])
                cursor.close()
            }
            
            fileprivate init(db : Database) {
                self.db = db
            }
        }
    }
    
    class Entities {
        class User : Entity {
            fileprivate (set) var userID : UInt? = nil
            var username : String,
                fullname : String,
                password_hash : String,
                role : UInt
            
            init(username : String, fullname : String, password_hash : String, role : UInt) {
                self.username = username
                self.fullname = fullname
                self.password_hash = password_hash
                self.role = role
            }
            
            fileprivate convenience init(userID : UInt, username : String, fullname : String, password_hash : String, role : UInt) {
                self.init(username : username, fullname : fullname, password_hash : password_hash, role: role)
                self.userID = userID
            }
        }
        
        class Table : Entity {
            fileprivate (set) var tableID : UInt? = nil
            var numberOfSeats : UInt
            
            init(numberOfSeats : UInt) {
                self.numberOfSeats = numberOfSeats
            }
            
            fileprivate convenience init(tableID : UInt, numberOfSeats : UInt) {
                self.init(numberOfSeats : numberOfSeats)
                self.tableID = tableID
            }
        }
        
        class MenuItem : Entity {
            fileprivate (set) var itemID : UInt? = nil
            var description : String,
                price : Double,
                photoURL : String
            
            init(description : String, price : Double, photoURL : String) {
                self.description = description
                self.price = price
                self.photoURL = photoURL
            }
            
            fileprivate convenience init(itemID : UInt, description : String, price : Double, photoURL : String) {
                self.init(description : description, price : price, photoURL : photoURL)
                self.itemID = itemID
            }
        }
        
        class Order : Entity {
            fileprivate (set) var orderID : UInt?
            var userID : UInt,
                date : Date,
                tableID : UInt,
                items : Set <UInt>
            
            init(userID : UInt, date : Date, tableID : UInt, items : [UInt] = []) {
                self.userID = userID
                self.date = date
                self.tableID = tableID
                self.items = Set (items)
            }
            
            fileprivate convenience init(orderID : UInt, userID : UInt, date : Date, tableID : UInt, items : [UInt] = []) {
                self.init(userID : userID, date : date, tableID : tableID, items : items)
                self.orderID = orderID
            }
        }
        
        private init() {}
    }
    
    class Table {
        func getProcessed(conditions : [Condition]) -> String {
            if conditions.isEmpty {
                return ""
            }
            var text = "WHERE"
            var first = true
            for condition in conditions {
                if !first {
                    text += " AND"
                } else {
                    first = false
                }
                text += " " + condition.text
            }
            return text
        }
    }
    
    class Entity {
        
    }
}
