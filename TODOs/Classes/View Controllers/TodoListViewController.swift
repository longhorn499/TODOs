//
//  TodoListViewController.swift
//  TODOs
//
//  Created by Kevin Johnson on 2/23/20.
//  Copyright © 2020 Kevin Johnson. All rights reserved.
//

import UIKit

class TodoListViewController: UIViewController {

    // MARK: - Properties

    private(set) var todoLists: [TodoList]
    private var bottomInset: CGFloat

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.dragInteractionEnabled = true
        table.dragDelegate = self
        table.dropDelegate = self
        table.register(cell: TodoCell.self)
        table.register(cell: AddTodoCell.self)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 92
        table.sectionHeaderHeight = UITableView.automaticDimension
        table.estimatedSectionHeaderHeight = 44
        table.tableFooterView = UIView(frame: .zero)
        table.clipsToBounds = true
        table.translatesAutoresizingMaskIntoConstraints = false
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.bottomInset, right: 0)
        return table
    }()

    // MARK: - Init

    init(todoLists: [TodoList], bottomInset: CGFloat) {
        self.todoLists = todoLists
        self.bottomInset = bottomInset
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }

    // MARK: - Public Functions

    func updateTodoLists(_ lists: [TodoList]) {
        todoLists = lists
        tableView.reloadData()
    }
    
    func addNewTodoList(with name: String) {
        todoLists.insert(
            TodoList(classification: .created, name: name),
            at: 0
        )
        tableView.insertSections(IndexSet(arrayLiteral: 0), with: .automatic)
    }
}

// MARK: - UITableViewDataSource

extension TodoListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return todoLists.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoLists[section].visibleTodos.count + 1 // for AddTodoCell
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let list = todoLists[indexPath.section]
        print(list.todos.count, list.visibleTodos.count, list.showCompleted, list.name)
        if list.visibleTodos.count == indexPath.row {
            let cell: AddTodoCell = tableView.dequeueReusableCell(for: indexPath)
            if indexPath.section == todoLists.count - 1 {
                cell.separatorInset = .hideSeparator // hide last
            }
            cell.delegate = self
            return cell
        }
        let cell: TodoCell = tableView.dequeueReusableCell(for: indexPath)
        cell.delegate = self
        cell.configure(data: list.visibleTodos[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if todoLists[indexPath.section].visibleTodos.count == indexPath.row {
            return false // AddTodoCell
        }
        return true
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if todoLists[indexPath.section].visibleTodos.count == indexPath.row {
            return false // AddTodoCell
        }
        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let sourceTodoList = todoLists[sourceIndexPath.section]
        let destinationTodoList = todoLists[destinationIndexPath.section]
//        let movedTodo = sourceTodoList.visibleTodos.remove(at: sourceIndexPath.row)
//        destinationTodoList.visibleTodos.insert(movedTodo, at: destinationIndexPath.row)
    }
}

// MARK: - UITableViewDelegate

extension TodoListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let list = todoLists[indexPath.section]
        let deleteItem = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completion) in
            _ = list.todos.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }

        let completed = list.visibleTodos[indexPath.row].completed
        let title: String = completed ? "Not Complete" : "Completed"
        let markCompleted = UIContextualAction(style: .normal, title: title) {  (_, _, completion) in
            list.visibleTodos[indexPath.row].completed.toggle()
            if list.showCompleted {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            } else {
                if list.visibleTodos[indexPath.row].completed {
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
                
            }
            completion(true)
        }
        markCompleted.backgroundColor = .systemGreen
        let duplicate = UIContextualAction(style: .normal, title: "Duplicate") { (_, _, completion) in
            let todo = list.visibleTodos[indexPath.row]
            list.todos.insert(todo, at: indexPath.row + 1)
            self.tableView.insertRows(at: [IndexPath(row: indexPath.row + 1, section: indexPath.section)], with: .automatic)
            completion(true)
        }
        duplicate.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [deleteItem, markCompleted, duplicate])
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = TodoListSectionHeaderView()
        header.configure(data: todoLists[section])
        header.delegate = self
        header.section = section
        return header
    }

    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        // Disallow moving TodoCell below AddTodoCell
        let proposedSection = proposedDestinationIndexPath.section
        let proposedRow = proposedDestinationIndexPath.row
        let proposedSectionTodosCount = todoLists[proposedSection].visibleTodos.count

        if sourceIndexPath.section == proposedSection,
            proposedRow == proposedSectionTodosCount {
            return sourceIndexPath
        } else if sourceIndexPath.section != proposedSection,
            proposedRow > proposedSectionTodosCount {
            return IndexPath(row: proposedRow - 1, section: proposedSection)
        }
        return proposedDestinationIndexPath
    }
}

// MARK: - UITableViewDragDelegate

extension TodoListViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return []
    }
}

// MARK: - UITableViewDropDelegate

extension TodoListViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        // do nothing
    }
}

// MARK: - AddTodoCellDelegate

extension TodoListViewController: AddTodoCellDelegate {
    func addTodoCell(_ cell: AddTodoCell, isEditing textView: UITextView) {
        tableView.resize(for: textView)
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

extension TodoListViewController: TodoCellCellDelegate {
    func todoCell(_ cell: TodoCell, isEditing textView: UITextView) {
        tableView.resize(for: textView)
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

// MARK: - TodoListSectionHeaderViewDelegate

extension TodoListViewController: TodoListSectionHeaderViewDelegate {
    func todoListSectionHeaderView(_ view: TodoListSectionHeaderView, tappedAction section: Int) {
        UIAlertController.todoListActions(todoLists[section].showCompleted, presenter: self, completion: { _ in
            self.todoLists[section].showCompleted.toggle()
            self.tableView.reloadSections(IndexSet(arrayLiteral: section), with: .none)
        })
    }
}
