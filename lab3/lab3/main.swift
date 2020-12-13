import Foundation
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

enum States {
    case Initial
    case OperationSelection (Database.Table)
    case CreateOrUpdateEntry (Database.Table, Entity? = nil)
    case ShowEntries (Database.Table)
}

let db = Database()

if let db = db {
    var state = States.Initial
    while (true) {
        var exit = false
        print("")
        switch state {
        case .Initial:
            print("Оберіть сутність")
            print("1 - user")
            print("2 - table")
            print("3 - menu_item")
            print("4 - order")
            print("0 - Вихід")
            print("> ", terminator: "")
            var input = UInt (View.getUserInput())
            while input == nil || input! > 4 {
                print("Введення не може бути опрацьовано. Спробуйте знову.\n> ")
                input = UInt (View.getUserInput())
            }
            if input == 0 {
                exit = true
                break
            }
            switch input {
            case 1:
                state = .OperationSelection (db.tables!.users)
                break
            case 2:
                state = .OperationSelection(db.tables!.tables)
                break
            case 3:
                state = .OperationSelection(db.tables!.items)
                break
            case 4:
                state = .OperationSelection(db.tables!.orders)
                break
            default:
                print("Помилка оброблення вводу. Спробуйте знову.")
                break
            }
            break
            
        case .OperationSelection(let table):
            print("Оберіть операцію")
            print("1 - Створити нову сутність")
            print("2 - Переглянути список сутностей таблиці")
            print("0 - Повернутися до вибору таблиці")
            print("> ", terminator: "")
            var input = UInt (View.getUserInput())
            while input == nil || input! > 3 {
                print("Введення не може бути опрацьовано. Спробуйте знову.\n> ", terminator: "")
                input = UInt (View.getUserInput())
            }
            switch input {
            case 0:
                state = .Initial
                break
            case 1:
                state = .CreateOrUpdateEntry(table)
                break
            case 2:
                state = .ShowEntries(table)
                break
            default:
                break
            }
            break
            
        case .CreateOrUpdateEntry(let table, var entity):
            print("Введіть дані сутності")
            if table is Database.Tables.Users {
                let table = table as! Database.Tables.Users
                print("Нікнейм > ", terminator: "")
                let username = View.getUserInput()
                print("Повне ім'я > ", terminator: "")
                let fullname = View.getUserInput()
                print("Пароль > ", terminator: "")
                let password = View.getUserInput()
                let password_hash = MD5(from : password)
                print("Роль > ", terminator: "")
                var role = Int(View.getUserInput())
                while role == nil || role! > 4 || role! < 0 {
                    print("Введення не може бути опрацьовано. Спробуйте знову.\n> ", terminator: "")
                    role = Int (View.getUserInput())
                }
                if entity == nil {
                    entity = Database.Entities.User()
                }
                let user = entity as! Database.Entities.User
                user.username = username
                user.fullname = fullname
                user.password_hash = password_hash
                user.role = role!
                entity = user
                do {
                    try table.save(entry: entity as! Database.Entities.User)
                    print("Cутність успішно створено/оновлено")
                } catch {
                    print("Помилка створення нової сутності. Деталі: \(error)")
                }
            }
            if table is Database.Tables.Tables {
                let table = table as! Database.Tables.Tables
                print("Кількість місць > ", terminator: "")
                var numberOfSeats = UInt(View.getUserInput())
                while numberOfSeats == nil {
                    print("Введення не може бути опрацьовано. Спробуйте знову.\n> ", terminator: "")
                    numberOfSeats = UInt (View.getUserInput())
                }
                if entity == nil {
                    entity = Database.Entities.Table()
                }
                (entity as! Database.Entities.Table).numberOfSeats = numberOfSeats!
                do {
                    try table.save(entry: entity as! Database.Entities.Table)
                    print("Cутність успішно створено")
                } catch {
                    print("Помилка створення нової сутності. Деталі: \(error)")
                }
            }
            if table is Database.Tables.MenuItems {
                let table = table as! Database.Tables.MenuItems
                print("Опис > ", terminator: "")
                let description = View.getUserInput()
                print("Ціна > ", terminator: "")
                var price = Double(View.getUserInput())
                while price == nil || price! <= 0 {
                    print("Введення не може бути опрацьовано. Спробуйте знову.\n> ", terminator: "")
                    price = Double (View.getUserInput())
                }
                print("Посилання на фото > ", terminator: "")
                let photoURL = View.getUserInput()
                if entity == nil {
                    entity = Database.Entities.MenuItem()
                }
                let item = entity as! Database.Entities.MenuItem
                item.description = description
                item.price = price!
                item.photoURL = photoURL
                entity = item
                do {
                    try table.save(entry: entity as! Database.Entities.MenuItem)
                    print("Cутність успішно створено")
                } catch {
                    print("Помилка створення нової сутності. Деталі: \(error)")
                }
            }
            if table is Database.Tables.Orders {
                let table = table as! Database.Tables.Orders
                print("ID замовника > ", terminator: "")
                var userID = UInt(View.getUserInput())
                while userID == nil {
                    print("Введення не може бути опрацьовано. Спробуйте знову.\n> ", terminator: "")
                    userID = UInt (View.getUserInput())
                }
                let date = Date()
                print("ID столика > ", terminator: "")
                var tableID = UInt(View.getUserInput())
                while tableID == nil {
                    print("Введення не може бути опрацьовано. Спробуйте знову.\n> ", terminator: "")
                    tableID = UInt (View.getUserInput())
                }
                if entity == nil {
                    entity = Database.Entities.Order()
                }
                let order = entity as! Database.Entities.Order
                order.userID = userID!
                order.date = date
                order.tableID = tableID!
                entity = order
                do {
                    try table.save(entry: entity as! Database.Entities.Order)
                    print("Cутність успішно створено")
                } catch {
                    print("Помилка створення нової сутності. Деталі: \(error)")
                }
            }
            state = .OperationSelection(table)
            break
        case .ShowEntries(let table):
            print("Максимальна кількість записів до відображення > ", terminator: "")
            var limit = UInt(View.getUserInput())
            while limit == nil || limit == 0 {
                print("Введення не може бути опрацьовано. Спробуйте знову.\n> ", terminator: "")
                limit = UInt (View.getUserInput())
            }
            print("Починаючі із запису № > ", terminator: "")
            var offset = UInt(View.getUserInput())
            while offset == nil || offset == 0 {
                print("Введення не може бути опрацьовано. Спробуйте знову.\n> ", terminator: "")
                offset = UInt (View.getUserInput())
            }
            offset! -= 1
            var entriesGeneral : [Entity] = []
            if table is Database.Tables.Users {
                let table = table as! Database.Tables.Users
                let entries = table.getEntries(limit : UInt(limit!), offset : offset!).data!
                if entries.isEmpty {
                    print("Таблиця не містить сутностей")
                } else {
                    print("\n№\tuserID\tusername\t\tfullname\t\tpassword_hash\t\t\t\t\trole")
                    for (index, entry) in entries.enumerated() {
                        print("\(index+1)\t\(entry.id)\t\t\(entry.username)\t\(entry.fullname)\t\(entry.password_hash)\t\(entry.role)")
                    }
                }
                entriesGeneral = entries
            }
            if table is Database.Tables.Tables {
                let table = table as! Database.Tables.Tables
                let entries = table.getEntries(limit : UInt(limit!), offset : offset!).data!
                if entries.isEmpty {
                    print("Таблиця не містить сутностей")
                } else {
                    print("\n№\ttableID\tnumberOfSeats")
                    for (index, entry) in entries.enumerated() {
                        print("\(index+1)\t\(entry.id)\t\t\(entry.numberOfSeats)")
                    }
                }
                entriesGeneral = entries
            }
            if table is Database.Tables.MenuItems {
                let table = table as! Database.Tables.MenuItems
                let entries = table.getEntries(limit : UInt(limit!), offset : offset!).data!
                if entries.isEmpty {
                    print("Таблиця не містить сутностей")
                } else {
                    print("\n№\titemID\tdescription\tprice\tphotoURL")
                    for (index, entry) in entries.enumerated() {
                        print("\(index+1)\t\(entry.id)\t\t\(entry.description)\t\(entry.price)\t\(entry.photoURL)")
                    }
                }
                entriesGeneral = entries
            }
            if table is Database.Tables.Orders {
                let table = table as! Database.Tables.Orders
                let entries = table.getEntries(limit : UInt(limit!), offset : offset!).data!
                if entries.isEmpty {
                    print("Таблиця не містить сутностей")
                } else {
                    print("\n№\torderID\tuserID\tdate\ttableID")
                    for (index, entry) in entries.enumerated() {
                        print("\(index+1)\t\(entry.id)\t\t\(entry.userID)\t\(entry.date)\t\(entry.tableID)")
                    }
                }
                entriesGeneral = entries
            }
            if (entriesGeneral.isEmpty) {
                state = .OperationSelection(table)
                break
            }
            print("\nОберіть операцію")
            print("1 - Оновити дані сутності")
            print("2 - Видалити сутність")
            print("0 - Повернутися назад")
            print("> ", terminator: "")
            var input = UInt(View.getUserInput())
            while input == nil || input! > 4 {
                print("Введення не може бути опрацьовано. Спробуйте знову.\n> ", terminator: "")
                input = UInt (View.getUserInput())
            }
            switch input {
            case 0:
                state = .OperationSelection(table)
                break
            case 1:
                print("Введіть номер сутності до оновлення > ", terminator: "")
                var input = UInt(View.getUserInput())
                print(entriesGeneral.count)
                while input == nil || input! > min (limit!, UInt(entriesGeneral.count)) || input == 0 {
                    print("Введення не може бути опрацьовано. Спробуйте знову.\n> ", terminator: "")
                    input = UInt (View.getUserInput())
                }
                state = .CreateOrUpdateEntry(table, entriesGeneral[Int(input!) - 1])
                break
            case 2:
                print("Введіть номер сутності до видалення > ", terminator: "")
                var input = UInt(View.getUserInput())
                while input == nil || input! > min (limit!, UInt(entriesGeneral.count)) || input == 0 {
                    print("Введення не може бути опрацьовано. Спробуйте знову.\n> ", terminator: "")
                    input = UInt (View.getUserInput())
                }
                do {
                    if table is Database.Tables.Users {
                        let table = table as! Database.Tables.Users
                        try table.delete(entry: entriesGeneral[Int(input!) - 1] as! Database.Entities.User)
                    }
                    if table is Database.Tables.Tables {
                        let table = table as! Database.Tables.Tables
                        try table.delete(entry: entriesGeneral[Int(input!) - 1] as! Database.Entities.Table)
                    }
                    if table is Database.Tables.MenuItems {
                        let table = table as! Database.Tables.MenuItems
                        try table.delete(entry: entriesGeneral[Int(input!) - 1] as! Database.Entities.MenuItem)
                    }
                    if table is Database.Tables.Orders {
                        let table = table as! Database.Tables.Orders
                        try table.delete(entry: entriesGeneral[Int(input!) - 1] as! Database.Entities.Order)
                    }
                    print("Запис успішно видалено")
                } catch {
                    print("Помилка видалення сутності. Деталі: \(error)")
                }
                break
            default:
                print("Помилка обробки вводу")
                break
            }
            break
        }
        if exit {
            break
        }
    }
} else {
    print("Помилка з'єднання із базою даних")
}

func getUserInput() -> String {
    readLine()!.trimmingCharacters(in: .whitespaces)
}

func MD5(from string: String) -> String {
    let length = Int(CC_MD5_DIGEST_LENGTH)
    let messageData = string.data(using:.utf8)!
    var digestData = Data(count: length)

    _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
        messageData.withUnsafeBytes { messageBytes -> UInt8 in
            if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                let messageLength = CC_LONG(messageData.count)
                CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
            }
            return 0
        }
    }
    return digestData.map { String(format: "%02hhx", $0) }.joined()
}


