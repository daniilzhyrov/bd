# Лабораторна робота №1, Бази даних 1. Реляційні БД
### Назва: "Проектування бази даних та ознайомлення з базовими операціями СУБД"
### Жиров Даниїл, КП-82
- Предметна галузь: ресторан (користувачі, замовлення, елементи меню, столики)
- Графічний файл розробленої моделі «сутність-зв’язок»:
![alt text](https://i.ibb.co/BzK4bgB/Blank-Diagram-2.png "Графічний файл")
- Струкрура БД з назвами таблиць та зв'язками між ними:
1. users  
 -- userID - bigserial <- PRIMARY KEY  
 -- username - varchar (32)  
 -- fullname - varchar (32)  
 -- password_hash - varchar(32)
 -- role - smallint  
  
2. tables  
 -- tableID - bigserial <- PRIMARY KEY  
 -- numberOfSeats - smallint
  
3. orders  
 -- orderID - bigserial <- PRIMARY KEY  
 -- userID - bigserial <- FOREIGN KEY (users, userID)  
 -- date - timestamp  
 -- tableID - bigserial <- FOREIGN KEY (tables, tableID)  
   
 4. menu_items  
 -- itemID - bigserial <- PRIMARY KEY  
 -- description - varchar (128)  
 -- price - double precision  
 -- photoURL - varchar(128)  
 
5. order_item_bridge  
 -- orderID - bigserial <- PRIMARY KEY  
 -- itemID - bigserial <- PRIMARY KEY  
- Екранні форми вмісту таблиць бази даних:
1. menu_items
![alt text](https://i.ibb.co/ZJZhHdz/Screenshot-2020-09-29-at-22-25-24.png "Таблиця menu_items")
2. tables  
![alt text](https://i.ibb.co/n6QjQ9H/Screenshot-2020-09-29-at-22-28-07.png "Таблиця tables")
3. users
![alt text](https://i.ibb.co/kxQPsnR/Screenshot-2020-09-29-at-22-33-43.png "Таблиця users")
