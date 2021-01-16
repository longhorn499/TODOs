//
//  TodoList+Extensions.swift
//  TODOs
//
//  Created by Kevin Johnson on 12/6/20.
//

import Foundation

// MARK: - Generated Lists

extension TodoList {
    static func createdTodoLists() -> [TodoList] {
        do {
            return try getCreated()
        } catch {
            return []
        }
    }

    static func daysOfWeekTodoLists(
        calendar: Calendar = .current,
        settings: GeneralSettings = .shared
    ) -> [TodoList] {
        guard var lists = try? getDaysOfWeek(), !lists.isEmpty else {
            return newDaysOfWeekTodoLists()
        }
        let current = currentDaysOfWeek()
        var i = 0
        var mDay = lists.last!.dateCreated
        while i < current.count {
            let today = Date()
            if lists[i].dateCreated.isBefore(today) {
                let removed = lists.remove(at: i)
                let newDay = mDay.byAddingDays(1)
                let newList = TodoList(
                    classification: .daysOfWeek,
                    dateCreated: newDay,
                    name: current[lists.count]
                )
                lists.append(newList)
                mDay = newDay
                // check if day before for rollover items
                if settings.rollover, calendar.dateComponents([.day], from: removed.dateCreated, to: today).day == 1 {
                    let prev = removed.todos.filter { !$0.completed && !$0.isSetting }
                    // could have setting to rollover settings
                    lists[i].todos.append(contentsOf: prev)
                }
            } else {
                i += 1
            }
        }
        return lists
    }

    static func newDaysOfWeekTodoLists(
        calendar: Calendar = .current,
        today: Date = Date()
    ) -> [TodoList] {
        return currentDaysOfWeek().enumerated().map { offset, day in
            TodoList(
                classification: .daysOfWeek,
                dateCreated: today.byAddingDays(offset),
                name: day
            )
        }
    }
}

// MARK: - Caching

import WidgetKit

extension TodoList {
    static func saveCreated(_ lists: [TodoList]) throws {
        try Cache.save(lists, path: "created")
    }

    static func saveDaysOfWeek(_ lists: [TodoList]) throws {
        print("SAVE!")
        print(lists.forEach {
                $0.todos.prettyPrint()
            print($0.dateCreated)
        })
        try Cache.save(lists, path: "week")
        /// save in AppGroup for widget
        /// may not be the best place to put this - SRP
        let url = AppGroup.todos.containerURL.appendingPathComponent("week")
        let data = try JSONEncoder().encode(lists)
        try data.write(to: url)
        /// Reload single widget
        WidgetCenter.shared.reloadTimelines(ofKind: "TODOsWidget")
    }

    private static func getCreated() throws -> [TodoList] {
        return try Cache.read(path: "created")
    }

    private static func getDaysOfWeek() throws -> [TodoList] {
        return try Cache.read(path: "week")
    }
}

// MARK: - Helper

fileprivate func currentDaysOfWeek(starting date: Date = Date(), calendar: Calendar = .current) -> [String] {
    let current = calendar.component(.weekday, from: date)
    let days = [1, 2, 3, 4, 5, 6, 7]
    var rearrangedDays = days
        .split(separator: current)
        .reversed()
        .flatMap { $0 }
    rearrangedDays.insert(current, at: 0)
    return rearrangedDays.map { calendar.weekdaySymbols[$0 - 1] }
}

// MARK: - Settings

extension Array where Element == TodoList {
    func applySetting(_ setting: Setting, calendar: Calendar = .current) {
        applySettings([setting], calendar: calendar)
    }
    
    func applySettings(_ settings: [Setting], calendar: Calendar = .current) {
        for setting in settings {
            switch setting.frequency {
            case .sundays,
                 .mondays,
                 .tuesdays,
                 .wednesdays,
                 .thursdays,
                 .fridays,
                 .saturdays:
                addSettingForDay(setting, setting.frequency.rawValue)
            case .weekends:
                addSettingForDays(setting, [0, 6])
            case .weekdays:
                addSettingForDays(setting, [Int](1...5))
            case .everyday:
                addSettingForDays(setting, [Int](0...6))
            }
        }
    }

    func addSettingForDays(_ setting: Setting, _ days: [Int]) {
        days.forEach { addSettingForDay(setting, $0) }
    }

    private func addSettingForDay(_ setting: Setting, _ day: Int, calendar: Calendar = .current) {
        guard let index = firstIndex(where: { $0.name == calendar.weekdaySymbols[day] }) else {
            assertionFailure("Could not match weekday name to day integer")
            return
        }
        self[index].addTodoFor(setting: setting)
    }
}

extension TodoList {
    func addTodoFor(setting: Setting) {
        let todo = Todo(
            text: setting.name,
            settingUUID: setting.id.uuidString
        )
        /// somehow generated can have same UUID as existing? checking that too
        if !todos.contains(where: { $0.settingUUID == setting.id.uuidString }) && !todos.contains(todo) {
            add(todo: todo)
        }
    }
}
