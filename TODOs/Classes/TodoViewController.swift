//
//  ViewController.swift
//  TODOs
//
//  Created by Kevin Johnson on 11/19/19.
//  Copyright © 2019 Kevin Johnson. All rights reserved.
//

import UIKit

// Table round corners and inset entire thing slightly / 2 page setup (custom lists, and days)
// TODO: UITableViewDiffableDataSource w/ dynamic section names and count basically..

class TodoViewController: UIViewController {

    // MARK: - Properties

    private var todoLists: [TodoList] = [
        TodoList.createdTodoLists(),
        TodoList.daysOfWeekTodoLists()
        ]
        .reduce([TodoList](), +)
    @IBOutlet private weak var tableView: UITableView!

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(cell: TodoCell.self)
        tableView.register(cell: AddTodoCell.self)
        tableView.estimatedRowHeight = 92
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: .zero)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    @objc func willResignActive() {
        try? TodoList.saveLists(todoLists)
    }

    // MARK: - IBAction

    @IBAction func tappedActionBarButtonItem(_ sender: UIBarButtonItem) {
        // TODO: Next Up alert for new list generation!! create w/ name :-)
    }

    @IBAction func tappedEditDoneBarButtonItem(_ sender: UIBarButtonItem) {
        // TODO: do custom grab to reorder like TrelloSwiftReorder
        tableView.isEditing.toggle()
        let barButtonItem = UIBarButtonItem(
            barButtonSystemItem: tableView.isEditing ? .done : .edit,
            target:  self,
            action: #selector(tappedEditDoneBarButtonItem(_:))
        )
        barButtonItem.tintColor = .systemPurple
        navigationItem.rightBarButtonItems![1] = barButtonItem
    }
}

// MARK: - UITableViewDataSource

extension TodoViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return todoLists.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoLists[section].todos.count + 1 // for AddTodoCell
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let list = todoLists[indexPath.section]
        if list.todos.count == indexPath.row {
            let cell: AddTodoCell = tableView.dequeueReusableCell(for: indexPath)
            cell.delegate = self
            return cell
        }
        let cell: TodoCell = tableView.dequeueReusableCell(for: indexPath)
        cell.delegate = self
        cell.configure(data: list.todos[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // TODO: Custom view! w/ trash icon to delete
        return todoLists[section].name
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if todoLists[indexPath.section].todos.count == indexPath.row {
            return false // AddTodoCell
        }
        return true
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if todoLists[indexPath.section].todos.count == indexPath.row {
            return false // AddTodoCell
        }
        return true
    }

    // TODO: Next up, SwiftReorder! use that!
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let todoList = todoLists[sourceIndexPath.section]
        let todo = todoList.todos.remove(at: sourceIndexPath.row)
        todoList.todos.insert(todo, at: destinationIndexPath.row)
        tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }
}

// MARK: - UITableViewDelegate

extension TodoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteItem = UIContextualAction(style: .destructive, title: "Delete") {  (contextualAction, view, boolValue) in
            _ = self.todoLists[indexPath.section].todos.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        let markCompleted = UIContextualAction(style: .normal, title: "Completed") {  (contextualAction, view, boolValue) in
            // TODO: Don't just delete, update TodoList to have completed array that have their own display cell (not editable, but delatable)
            _ = self.todoLists[indexPath.section].todos.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        markCompleted.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [deleteItem, markCompleted])
    }
}

// MARK: - AddTodoCellDelegate

extension TodoViewController: AddTodoCellDelegate {
    func addTodoCell(_ cell: AddTodoCell, isEditing textView: UITextView) {
        UIView.setAnimationsEnabled(false)
        textView.sizeToFit()
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }

    func addTodoCell(_ cell: AddTodoCell, didEndEditing text: String) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            assertionFailure()
            return
        }
        todoLists[indexPath.section].todos.append(Todo(text: text))
        tableView.insertRows(at: [indexPath], with: .automatic)
    }
}

// MARK: TodoCellDelegate

extension TodoViewController: TodoCellCellDelegate {
    func todoCell(_ cell: TodoCell, isEditing textView: UITextView) {
        // dry
        UIView.setAnimationsEnabled(false)
        textView.sizeToFit()
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }

    func todoCell(_ cell: TodoCell, didEndEditing text: String) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            assertionFailure()
            return
        }
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            todoLists[indexPath.section].todos[indexPath.row].text = text
        }
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}
