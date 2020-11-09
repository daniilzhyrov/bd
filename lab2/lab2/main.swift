import Foundation
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

enum States {
    case Initial
    case OperationSelection (Database.Table)
    case CreateOrUpdateEntry (Database.Table, Database.Entity? = nil)
    case ShowEntries (Database.Table, [Condition] = [])
    case InsertRandomEntries (Database.Table)
}

let db = Database()
var state = States.Initial
var exit = false

if let db = db {
    while (true) {
        View.display(output: "")
        switch state {
        case .Initial:
            View.display(output: "Оберіть сутність")
            View.display(output: "1 - user")
            View.display(output: "2 - table")
            View.display(output: "3 - menu_item")
            View.display(output: "4 - order")
            View.display(output: "0 - Вихід")
            View.display(output: "> ", lineBreak: false)
            var input = UInt (View.getUserInput())
            while input == nil || input! > 4 {
                View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ")
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
                View.display(output: "Помилка оброблення вводу. Спробуйте знову.")
                break
            }
            break
            
        case .OperationSelection(let table):
            View.display(output: "Оберіть операцію")
            View.display(output: "1 - Створити нову сутність")
            View.display(output: "2 - Переглянути список сутностей таблиці")
            View.display(output: "3 - Додати випадкові сутності до таблиці")
            View.display(output: "0 - Повернутися до вибору таблиці")
            View.display(output: "> ", lineBreak: false)
            var input = UInt (View.getUserInput())
            while input == nil || input! > 3 {
                View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
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
            case 3:
                state = .InsertRandomEntries(table)
                break
            default:
                break
            }
            break
            
        case .CreateOrUpdateEntry(let table, var entity):
            View.display(output: "Введіть дані сутності")
            if table is Database.Tables.Users {
                let table = table as! Database.Tables.Users
                View.display(output: "Нікнейм > ", lineBreak: false)
                let username = View.getUserInput()
                View.display(output: "Повне ім'я > ", lineBreak: false)
                let fullname = View.getUserInput()
                View.display(output: "Пароль > ", lineBreak: false)
                let password = View.getUserInput()
                let password_hash = MD5(from : password)
                View.display(output: "Роль > ", lineBreak: false)
                var role = UInt(View.getUserInput())
                while role == nil || role! > 4 {
                    View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                    role = UInt (View.getUserInput())
                }
                if entity == nil {
                    entity = Database.Entities.User(username: username, fullname: fullname, password_hash: password_hash, role: role!)
                }
                do {
                    try table.save(entry: entity as! Database.Entities.User)
                    View.display(output: "Cутність успішно створено")
                } catch {
                    View.display(output: "Помилка створення нової сутності. Деталі: \(error)")
                }
            }
            if table is Database.Tables.Tables {
                let table = table as! Database.Tables.Tables
                View.display(output: "Кількість місць > ", lineBreak: false)
                var numberOfSeats = UInt(View.getUserInput())
                while numberOfSeats == nil {
                    View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                    numberOfSeats = UInt (View.getUserInput())
                }
                if entity == nil {
                    entity = Database.Entities.Table(numberOfSeats: numberOfSeats!)
                }
                do {
                    try table.save(entry: entity as! Database.Entities.Table)
                    View.display(output: "Cутність успішно створено")
                } catch {
                    View.display(output: "Помилка створення нової сутності. Деталі: \(error)")
                }
            }
            if table is Database.Tables.MenuItems {
                let table = table as! Database.Tables.MenuItems
                View.display(output: "Опис > ", lineBreak: false)
                let description = View.getUserInput()
                View.display(output: "Ціна > ", lineBreak: false)
                var price = Double(View.getUserInput())
                while price == nil || price! <= 0 {
                    View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                    price = Double (View.getUserInput())
                }
                View.display(output: "Посилання на фото > ", lineBreak: false)
                let photoURL = View.getUserInput()
                if entity == nil {
                    entity = Database.Entities.MenuItem(description: description, price: price!, photoURL: photoURL)
                }
                do {
                    try table.save(entry: entity as! Database.Entities.MenuItem)
                    View.display(output: "Cутність успішно створено")
                } catch {
                    View.display(output: "Помилка створення нової сутності. Деталі: \(error)")
                }
            }
            if table is Database.Tables.Orders {
                let table = table as! Database.Tables.Orders
                View.display(output: "ID замовника > ", lineBreak: false)
                var userID = UInt(View.getUserInput())
                while userID == nil {
                    View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                    userID = UInt (View.getUserInput())
                }
                let date = Date()
                View.display(output: "ID столика > ", lineBreak: false)
                var tableID = UInt(View.getUserInput())
                while tableID == nil {
                    View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                    tableID = UInt (View.getUserInput())
                }
                if entity == nil {
                    entity = Database.Entities.Order(userID: userID!, date: date, tableID: tableID!)
                }
                do {
                    try table.save(entry: entity as! Database.Entities.Order)
                    View.display(output: "Cутність успішно створено")
                } catch {
                    View.display(output: "Помилка створення нової сутності. Деталі: \(error)")
                }
            }
            state = .OperationSelection(table)
            break
        case .ShowEntries(let table, var conditions):
            View.display(output: "Максимальна кількість записів до відображення > ", lineBreak: false)
            var limit = UInt(View.getUserInput())
            while limit == nil || limit == 0 {
                View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                limit = UInt (View.getUserInput())
            }
            View.display(output: "Починаючі із запису № > ", lineBreak: false)
            var offset = UInt(View.getUserInput())
            while offset == nil || offset == 0 {
                View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                offset = UInt (View.getUserInput())
            }
            offset! -= 1
            var entriesGeneral : [Database.Entity] = []
            if table is Database.Tables.Users {
                let table = table as! Database.Tables.Users
                let entries = table.getEntries(fits : conditions, limit : Int(limit!), offset : offset!).data!
                View.display(output: "\n№\tuserID\tusername\tfullname\tpassword_hash\t\t\t\trole")
                for (index, entry) in entries.enumerated() {
                    View.display(output: "\(index+1)\t\(entry.userID!)\t\t\(entry.username)\t\(entry.fullname)\t\(entry.password_hash)\t\(entry.role)")
                }
                entriesGeneral = entries
            }
            if table is Database.Tables.Tables {
                let table = table as! Database.Tables.Tables
                let entries = table.getEntries(fits : conditions, limit : Int(limit!), offset : offset!).data!
                View.display(output: "\n№\ttableID\tnumberOfSeats")
                for (index, entry) in entries.enumerated() {
                    View.display(output: "\(index+1)\t\(entry.tableID!)\t\t\(entry.numberOfSeats)")
                }
                entriesGeneral = entries
            }
            if table is Database.Tables.MenuItems {
                let table = table as! Database.Tables.MenuItems
                let entries = table.getEntries(fits : conditions, limit : Int(limit!), offset : offset!).data!
                View.display(output: "\n№\titemID\tdescription\tprice\tphotoURL")
                for (index, entry) in entries.enumerated() {
                    View.display(output: "\(index+1)\t\(entry.itemID!)\t\t\(entry.description)\t\(entry.price)\t\(entry.photoURL)")
                }
                entriesGeneral = entries
            }
            if table is Database.Tables.Orders {
                let table = table as! Database.Tables.Orders
                let entries = table.getEntries(fits : conditions, limit : Int(limit!), offset : offset!).data!
                View.display(output: "\n№\torderID\tuserID\tdate\ttableID")
                for (index, entry) in entries.enumerated() {
                    View.display(output: "\(index+1)\t\(entry.orderID!)\t\t\(entry.userID)\t\(entry.date)\t\(entry.tableID)")
                }
                entriesGeneral = entries
            }
            View.display(output: "\nОберіть операцію")
            View.display(output: "1 - Додати умову фільтрації списку сутностей")
            View.display(output: "2 - Очистити умови фільтрації списку сутностей")
            View.display(output: "3 - Оновити дані сутності")
            View.display(output: "4 - Видалити сутність")
            View.display(output: "0 - Повернутися назад")
            View.display(output: "> ", lineBreak: false)
            var input = UInt(View.getUserInput())
            while input == nil || input! > 4 {
                View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                input = UInt (View.getUserInput())
            }
            switch input {
            case 0:
                state = .OperationSelection(table)
                break
            case 1:
                View.display(output: "\nОберіть ім'я параметра > ")
                var parameterName : String = ""
                var parameterType : Any.Type = Any.self
                if table is Database.Tables.Users {
                    let table = table as! Database.Tables.Users
                    for (index, property) in table.propertyList.enumerated() {
                        View.display(output: "\(index + 1) - \(property.0)")
                    }
                    View.display(output: "0 - Повернутися назад")
                    View.display(output: "> ", lineBreak: false)
                    var propertyNumber = UInt(View.getUserInput())
                    while propertyNumber == nil || propertyNumber! > table.propertyList.count {
                        View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                        propertyNumber = UInt(View.getUserInput())
                    }
                    if propertyNumber == 0 {
                        break
                    }
                    (parameterName, parameterType) = table.propertyList[Int(propertyNumber!) - 1]
                }
                if table is Database.Tables.Tables {
                    let table = table as! Database.Tables.Tables
                    for (index, property) in table.propertyList.enumerated() {
                        View.display(output: "\(index + 1) - \(property.0)")
                    }
                    View.display(output: "0 - Повернутися назад")
                    var propertyNumber = UInt(View.getUserInput())
                    while propertyNumber == nil || propertyNumber! > table.propertyList.count {
                        View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                        propertyNumber = UInt(View.getUserInput())
                    }
                    if propertyNumber == 0 {
                        break
                    }
                    (parameterName, parameterType) = table.propertyList[Int(propertyNumber!) - 1]
                }
                if table is Database.Tables.MenuItems {
                    let table = table as! Database.Tables.MenuItems
                    for (index, property) in table.propertyList.enumerated() {
                        View.display(output: "\(index + 1) - \(property.0)")
                    }
                    View.display(output: "0 - Повернутися назад")
                    var propertyNumber = UInt(View.getUserInput())
                    while propertyNumber == nil || propertyNumber! > table.propertyList.count {
                        View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                        propertyNumber = UInt(View.getUserInput())
                    }
                    if propertyNumber == 0 {
                        break
                    }
                    (parameterName, parameterType) = table.propertyList[Int(propertyNumber!) - 1]
                }
                if table is Database.Tables.Orders {
                    let table = table as! Database.Tables.Orders
                    for (index, property) in table.propertyList.enumerated() {
                        View.display(output: "\(index + 1) - \(property.0)")
                    }
                    View.display(output: "0 - Повернутися назад")
                    var propertyNumber = UInt(View.getUserInput())
                    while propertyNumber == nil || propertyNumber! > table.propertyList.count {
                        View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                        propertyNumber = UInt(View.getUserInput())
                    }
                    if propertyNumber == 0 {
                        break
                    }
                    (parameterName, parameterType) = table.propertyList[Int(propertyNumber!) - 1]
                }
                var condition : Condition?
                if parameterType == String.self {
                    View.display(output: "\nОберіть тип умови")
                    View.display(output: "1 - Дорівнює")
                    View.display(output: "2 - Відповідає шаблону")
                    View.display(output: "0 - Повернутись назад")
                    View.display(output: "> ", lineBreak: false)
                    var number = UInt(View.getUserInput())
                    while number == nil || number! > 2 {
                        View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                        number = UInt (View.getUserInput())
                    }
                    if number == 0 {
                        break
                    }
                    if number == 1 {
                        View.display(output: "Дорівнює значенню > ", lineBreak: false)
                        let value = View.getUserInput()
                        condition = Database.Query.EqualsCondition(parameter: parameterName, equals: value)
                    }
                    if number == 2 {
                        View.display(output: "Відповідає шаблону > ", lineBreak: false)
                        let value = View.getUserInput()
                        condition = Database.Query.MatchCondition(parameter: parameterName, matches: value)
                    }
                }
                if parameterType == UInt.self {
                    View.display(output: "\nОберіть тип умови")
                    View.display(output: "1 - Дорівнює")
                    View.display(output: "2 - Належить проміжку")
                    View.display(output: "0 - Повернутись назад")
                    View.display(output: "> ", lineBreak: false)
                    var number = UInt(View.getUserInput())
                    while number == nil || number! > 2 {
                        View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                        number = UInt (View.getUserInput())
                    }
                    if number == 0 {
                        break
                    }
                    if number == 1 {
                        View.display(output: "Дорівнює значенню > ", lineBreak: false)
                        var value = UInt(View.getUserInput())
                        while value == nil {
                            View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                            value = UInt (View.getUserInput())
                        }
                        condition = Database.Query.EqualsCondition(parameter: parameterName, equals: value)
                    }
                    if number == 2 {
                        View.display(output: "Належить проміжку від > ", lineBreak: false)
                        var lower = UInt(View.getUserInput())
                        while lower == nil {
                            View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                            lower = UInt (View.getUserInput())
                        }
                        View.display(output: "До > ", lineBreak: false)
                        var upper = UInt(View.getUserInput())
                        while upper == nil {
                            View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                            upper = UInt (View.getUserInput())
                        }
                        condition = Database.Query.RangeCondition(parameter: parameterName, in: lower!...upper!)
                    }
                }
                if parameterType == Double.self {
                    View.display(output: "\nОберіть тип умови")
                    View.display(output: "1 - Дорівнює")
                    View.display(output: "2 - Належить проміжку")
                    View.display(output: "0 - Повернутись назад")
                    View.display(output: "> ", lineBreak: false)
                    var number = UInt(View.getUserInput())
                    while number == nil || number! > 2 {
                        View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                        number = UInt (View.getUserInput())
                    }
                    if number == 0 {
                        break
                    }
                    if number == 1 {
                        View.display(output: "Дорівнює значенню > ", lineBreak: false)
                        var value = Double(View.getUserInput())
                        while value == nil {
                            View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                            value = Double (View.getUserInput())
                        }
                        condition = Database.Query.EqualsCondition(parameter: parameterName, equals: value)
                    }
                    if number == 2 {
                        View.display(output: "Належить проміжку від > ", lineBreak: false)
                        var lower = Double(View.getUserInput())
                        while lower == nil {
                            View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                            lower = Double (View.getUserInput())
                        }
                        View.display(output: "До > ")
                        var upper = Double(View.getUserInput())
                        while upper == nil {
                            View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                            upper = Double (View.getUserInput())
                        }
                        condition = Database.Query.RangeCondition(parameter: parameterName, in: lower!...upper!)
                    }
                }
                if parameterType == Date.self {
                    View.display(output: "\nОберіть тип умови")
                    View.display(output: "1 - Дорівнює")
                    View.display(output: "2 - Належить проміжку")
                    View.display(output: "0 - Повернутись назад")
                    var number = UInt(View.getUserInput())
                    while number == nil || number! > 2 {
                        View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                        number = UInt (View.getUserInput())
                    }
                    if number == 0 {
                        break
                    }
                    func toDate (text : String) -> Date? {
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        return dateFormatter.date(from:text)
                    }
                    if number == 1 {
                        View.display(output: "Дорівнює значенню > ", lineBreak: false)
                        var value = toDate(text: View.getUserInput())
                        while value == nil {
                            View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                            value = toDate (text: View.getUserInput())
                        }
                        condition = Database.Query.EqualsCondition(parameter: parameterName, equals: value)
                    }
                    if number == 2 {
                        View.display(output: "Належить проміжку від > ", lineBreak: false)
                        var lower = toDate(text: View.getUserInput())
                        while lower == nil {
                            View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                            lower = toDate (text: View.getUserInput())
                        }
                        View.display(output: "До > ", lineBreak: false)
                        var upper = toDate(text: View.getUserInput())
                        while upper == nil {
                            View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                            upper = toDate (text: View.getUserInput())
                        }
                        condition = Database.Query.RangeCondition(parameter: parameterName, in: lower!...upper!)
                    }
                }
                conditions.append(condition!)
                state = .ShowEntries(table, conditions)
                break
            case 2:
                state = .ShowEntries(table)
                break
            case 3:
                View.display(output: "Введіть номер сутності до оновлення > ", lineBreak: false)
                var input = UInt(View.getUserInput())
                while input == nil || input! > limit! || input == 0 {
                    View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
                    input = UInt (View.getUserInput())
                }
                state = .CreateOrUpdateEntry(table, entriesGeneral[Int(input!) - 1])
                break
            case 4:
                View.display(output: "Введіть номер сутності до видалення > ", lineBreak: false)
                var input = UInt(View.getUserInput())
                while input == nil || input! > limit! || input == 0 {
                    View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n> ", lineBreak: false)
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
                    View.display(output: "Запис успішно видалено")
                } catch {
                    View.display(output: "Помилка видалення сутності. Деталі: \(error)")
                }
                break
            default:
                View.display(output: "Помилка обробки вводу")
                break
            }
            break
        case .InsertRandomEntries(let table):
            View.display(output: "Введіть кількість записів до вставки > ", lineBreak: false)
            var number = UInt (View.getUserInput())
            while number == nil {
                View.display(output: "Введення не може бути опрацьовано. Спробуйте знову.\n>", lineBreak: false)
                number = UInt(View.getUserInput())
            }
            do {
                if table is Database.Tables.Users {
                    let table = table as! Database.Tables.Users
                    try table.insertRandomEntries(amount: number!)
                }
                if table is Database.Tables.Tables {
                    let table = table as! Database.Tables.Tables
                    try table.insertRandomEntries(amount: number!)
                }
                if table is Database.Tables.MenuItems {
                    let table = table as! Database.Tables.MenuItems
                    try table.insertRandomEntries(amount: number!)
                }
                if table is Database.Tables.Orders {
                    let table = table as! Database.Tables.Orders
                    try table.insertRandomEntries(amount: number!)
                }
            } catch {
                View.display(output: "Помилка видалення сутності. Деталі: \(error)")
            }
            state = .OperationSelection(table)
            break
        }
        if exit {
            break
        }
    }
} else {
    View.display(output: "Помилка з'єднання із базою даних")
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
