import Foundation
import StORM
import PostgresStORM

protocol TableProtocol {
    associatedtype Entity
    var propertyList : [(String, Any.Type)] { get }

    func getEntries (limit : UInt?, offset : UInt) -> Database.Query.Responce<[Entity]>
    func save(entry: Entity) throws
    func delete(entry: Entity) throws
}

class Database {
    var tables : Tables?
    
    init? () {
        PostgresConnector.host        = "localhost"
        PostgresConnector.username    = "postgres"
        PostgresConnector.password    = ""
        PostgresConnector.database    = "daniilzhyrov"
        PostgresConnector.port        = 5432
        do {
            try Entities.User().setup()
            try Entities.Table().setup()
            try Entities.MenuItem().setup()
            try Entities.Order().setup()
            try Entities.OrderItemBridge().setup()
        } catch {
            print("It is imposible to establish connection to database.")
            return nil
        }
        tables = Tables(db : self)
    }
    
    class Query {
        struct Responce<T> {
            var data : T?
            var error : String?
            
            init(_ data : T? = nil, error : String? = nil) {
                self.error = error
                self.data = data
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
            
            let propertyList : [(String, Any.Type)] = [("id", Int.self), ("username", String.self), ("fullname", String.self), ("password_hash", String.self), ("role", Int.self)]
            
            func getEntries (limit : UInt? = nil, offset : UInt = 0) -> Query.Responce<[Entities.User]> {
                let user = Entities.User()
                do {
                    try user.findAll()
                } catch {
                    return Query.Responce(error : error.localizedDescription)
                }
                return Query.Responce(user.rows(limit: limit))
            }
            
            func save(entry: Entities.User) throws {
                try entry.save()
            }
            
            func delete(entry: Entities.User) throws {
                try entry.delete()
            }
            
            fileprivate init(db : Database) {
                self.db = db
            }
        }
        
        class Tables : Table, TableProtocol {
            unowned let db : Database
            
            let propertyList : [(String, Any.Type)] = [("id", Int.self), ("numberOfSeats", UInt.self)]
            
            func getEntries (limit : UInt? = nil, offset : UInt = 0) -> Query.Responce<[Entities.Table]> {
                let table = Entities.Table()
                do {
                    try table.findAll()
                } catch {
                    return Query.Responce(error : error.localizedDescription)
                }
                return Query.Responce(table.rows(limit: limit))
            }
            
            func save(entry: Entities.Table) throws {
                try entry.save()
            }
            
            func delete(entry: Entities.Table) throws {
                try entry.delete()
            }
            
            fileprivate init(db : Database) {
                self.db = db
            }
        }
        
        class MenuItems : Table, TableProtocol {
            unowned let db : Database
            
            let propertyList : [(String, Any.Type)] = [("id", Int.self), ("description", String.self), ("price", Double.self), ("photoURL", String.self)]
            
            func getEntries (limit : UInt? = nil, offset : UInt = 0) -> Query.Responce<[Entities.MenuItem]> {
                let item = Entities.MenuItem()
                do {
                    try item.findAll()
                } catch {
                    return Query.Responce(error : error.localizedDescription)
                }
                return Query.Responce(item.rows(limit: limit))
            }
            
            func save(entry: Entities.MenuItem) throws {
                try entry.save()
            }
            
            func delete(entry: Entities.MenuItem) throws {
                try entry.delete()
            }
            
            fileprivate init(db : Database) {
                self.db = db
            }
        }
        
        class Orders : Table, TableProtocol {
            unowned let db : Database
            
            let propertyList : [(String, Any.Type)] = [("id", Int.self), ("userID", UInt.self), ("date", Date.self), ("tableID", UInt.self)]
            
            func getEntries (limit : UInt? = nil, offset : UInt = 0) -> Query.Responce<[Entities.Order]> {
                let order = Entities.Order()
                do {
                    try order.findAll()
                } catch {
                    return Query.Responce(error : error.localizedDescription)
                }
                return Query.Responce(order.rows(limit: limit))
            }
            
            func save(entry: Entities.Order) throws {
                try entry.save()
            }
            
            func delete(entry: Entities.Order) throws {
                try entry.delete()
            }
            
            fileprivate init(db : Database) {
                self.db = db
            }
        }
        
        class OrderItemBridge : Table, TableProtocol {
            unowned let db : Database
            
            let propertyList : [(String, Any.Type)] = [("id", Int.self), ("itemID", UInt.self)]
            
            func getEntries (limit : UInt? = nil, offset : UInt = 0) -> Query.Responce<[Entities.OrderItemBridge]> {
                let bridge = Entities.OrderItemBridge()
                do {
                    try bridge.findAll()
                } catch {
                    return Query.Responce(error : error.localizedDescription)
                }
                return Query.Responce(bridge.rows(limit: limit))
            }
            
            func save (entry : Entities.OrderItemBridge) throws {
                try entry.save()
            }
            
            func delete(entry : Entities.OrderItemBridge) throws {
                try entry.delete()
            }
            
            func delete (by parameter: String, equals value : UInt) throws {
                var parameters = [String : Any]()
                parameters[parameter] = value
                let bridge = Entities.OrderItemBridge()
                try bridge.find(parameters)
                for item in bridge.rows() {
                    try item.delete()
                }
            }
            
            fileprivate init(db : Database) {
                self.db = db
            }
        }
    }
    
    class Entities {
        class User : PostgresStORM, Entity {
            var id : Int = 0
            var username : String = "",
                fullname : String = "",
                password_hash : String = "",
                role : Int = 0
            
            override open func table() -> String { return "users" }
            
            override func to(_ this: StORMRow) {
                id = this.data["id"] as? Int ?? 0
                username = this.data["username"] as? String ?? ""
                fullname = this.data["fullname"] as? String ?? ""
                password_hash = this.data["password_hash"] as? String ?? ""
                role = this.data["role"] as? Int ?? 0
            }
            
            func rows(limit : UInt? = nil) -> [User] {
                var rows = [User]()
                var upperBound = self.results.rows.count
                if limit != nil && limit! < UInt(self.results.rows.count) {
                    upperBound = Int(limit!)
                }
                for i in 0..<upperBound {
                    let row = User()
                    row.to(self.results.rows[i])
                    rows.append(row)
                }
                return rows
            }
        }
        
        class Table : PostgresStORM, Entity {
            var id : Int = 0
            var numberOfSeats : Int = 0
            
            override open func table() -> String { return "tables" }
            
            override func to(_ this: StORMRow) {
                id = this.data["id"] as? Int ?? 0
                numberOfSeats = this.data["numberOfSeats"] as? UInt ?? 0
            }
            
            func rows(limit : UInt? = nil) -> [Table] {
                var rows = [Table]()
                var upperBound = self.results.rows.count
                if limit != nil && limit! < UInt(self.results.rows.count) {
                    upperBound = Int(limit!)
                }
                for i in 0..<upperBound {
                    let row = Table()
                    row.to(self.results.rows[i])
                    rows.append(row)
                }
                return rows
            }
        }
        
        class MenuItem : PostgresStORM, Entity {
            var id : Int = 0
            var description : String = "",
                price : Double = 0,
                photoURL : String = ""
            
            override open func table() -> String { return "menu_items" }
            
            override func to(_ this: StORMRow) {
                id = this.data["id"] as? Int ?? 0
                description = this.data["description"] as? String ?? ""
                price = this.data["price"] as? Double ?? 0
                photoURL = this.data["photoURL"] as? String ?? ""
            }
            
            func rows(limit : UInt? = nil) -> [MenuItem] {
                var rows = [MenuItem]()
                var upperBound = self.results.rows.count
                if limit != nil && limit! < UInt(self.results.rows.count) {
                    upperBound = Int(limit!)
                }
                for i in 0..<upperBound {
                    let row = MenuItem()
                    row.to(self.results.rows[i])
                    rows.append(row)
                }
                return rows
            }
        }
        
        class Order : PostgresStORM, Entity {
            var id : Int = 0
            var userID : UInt = 0,
                date : Date = Date(),
                tableID : UInt = 0
            
            
            override open func table() -> String { return "orders" }
            
            override func to(_ this: StORMRow) {
                id = this.data["id"] as? Int ?? 0
                userID = this.data["userID"] as? UInt ?? 0
                date = this.data["date"] as? Date ?? Date()
                tableID = this.data["tableID"] as? UInt ?? 0
            }
            
            func rows(limit : UInt? = nil) -> [Order] {
                var rows = [Order]()
                var upperBound = self.results.rows.count
                if limit != nil && limit! < UInt(self.results.rows.count) {
                    upperBound = Int(limit!)
                }
                for i in 0..<upperBound {
                    let row = Order()
                    row.to(self.results.rows[i])
                    rows.append(row)
                }
                return rows
            }
        }
        
        class OrderItemBridge : PostgresStORM, Entity {
            var id : Int = 0
            var orderID : UInt = 0,
                tableID : UInt = 0
            
            
            override open func table() -> String { return "order_item_bridge" }
            
            override func to(_ this: StORMRow) {
                id = this.data["id"] as? Int ?? 0
                orderID = this.data["orderID"] as? UInt ?? 0
                tableID = this.data["tableID"] as? UInt ?? 0
            }
            
            func rows(limit : UInt? = nil) -> [OrderItemBridge] {
                var rows = [OrderItemBridge]()
                var upperBound = self.results.rows.count
                if limit != nil && limit! < UInt(self.results.rows.count) {
                    upperBound = Int(limit!)
                }
                for i in 0..<upperBound {
                    let row = OrderItemBridge()
                    row.to(self.results.rows[i])
                    rows.append(row)
                }
                return rows
            }
        }
        
        private init() {}
    }
    
    class Table {}
}

protocol Entity {}
