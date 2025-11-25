# TestAppA

## Архитектура
Проект реализован с использованием паттерна **MVVM (Model-View-ViewModel)**.  
- **Model** — описывает данные приложения (Post, User).  
- **View** — экраны и ячейки таблицы (FeedViewController, PostTableViewCell).  
- **ViewModel** — логика получения данных, обработка и передача в View.

## Скриншот
![Главный экран](screenshots/main_screen.png)  

> Скриншоты расположены в папке `screenshots` проекта.

## Используемые технологии
- **Swift 5+**  
- **UIKit**  
- **CoreData** — для оффлайн-хранения постов  
- **Alamofire** — для сетевых запросов  
- **MVVM** — архитектурный паттерн  
- **JSONPlaceholder API** — для моковых данных  

## Инструкция по сборке
1. Клонировать репозиторий:
```bash
git clone git@github.com:Eliseev-Anton/apptest.git
2.Перейти в папку проекта:
cd TestApp
3.Открыть проект в Xcode:
open TestApp.xcodeproj
4.Выбрать симулятор или устройство
5.Собрать проект: Cmd + B
6.Запустить приложение: Cmd + R
