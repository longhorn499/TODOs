//
//  SettingsViewController.swift
//  TODOs
//
//  Created by Kevin Johnson on 9/4/20.
//  Copyright © 2020 Kevin Johnson. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    enum Section {
        case recurring
    }

    struct Setting: Codable, Hashable {
        enum Frequency: Int, Codable, CaseIterable {
            case sundays = 0
            case mondays
            case tuesdays
            case wednesdays
            case thursdays
            case fridays
            case saturdays
            case weekends = 100
            case everyday

            var description: String {
                switch self {
                case .sundays,
                     .mondays,
                     .tuesdays,
                     .wednesdays,
                     .thursdays,
                     .fridays,
                     .saturdays:
                    return Calendar.current.shortWeekdaySymbols[self.rawValue]
                case .weekends:
                    return NSLocalizedString("Weekends", comment: "")
                case .everyday:
                    return NSLocalizedString("Everday", comment: "")
                }
            }
        }
        var name: String
        var frequency: Frequency

        init(name: String, frequency: Frequency = .mondays) {
            self.name = name
            self.frequency = frequency
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(frequency)
        }

        static func == (lhs: Setting, rhs: Setting) -> Bool {
            return lhs.name == rhs.name && lhs.frequency == rhs.frequency
        }
    }

    // MARK: - Properties

    private lazy var dataSource: SettingsTableViewDataSource = {
        do {
            let settings: [Setting] = try Cache.read(path: "settings")
            return SettingsTableViewDataSource(
                tableView: self.tableView,
                settings: settings,
                cellDelegate: self
            )
        } catch {
            return SettingsTableViewDataSource(
                tableView: self.tableView,
                settings: [],
                cellDelegate: self
            )
        }
    }()
    private var changingFreqIndex: Int?

    // MARK: - Deinit

    deinit {
        // TODO: Update current weekly TODOs! ++ WHEN GENERATING NEW DAYS, do actual logic for the recurring todo!!
        try? Cache.save(dataSource.settings, path: "settings")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(cell: RecurringTodoCell.self)
        tableView.register(cell: AddTodoCell.self)
        tableView.dataSource = dataSource
        dataSource.applySnapshot(animatingDifferences: false)
    }
}

// MARK: - AddTodoCellDelegate

extension SettingsViewController: AddTodoCellDelegate {
    func addTodoCell(_ cell: AddTodoCell, isEditing textView: UITextView) {
        tableView.resize(for: textView)
    }

    func addTodoCell(_ cell: AddTodoCell, didEndEditing text: String) {
        dataSource.settings.append(.init(name: text))
        dataSource.applySnapshot()
    }
}

// MARK: RecurringTodoCellDelegate

extension SettingsViewController: RecurringTodoCellDelegate {
    func recurringTodoCell(_ cell: RecurringTodoCell, isEditing textView: UITextView) {
        tableView.resize(for: textView)
    }

    func recurringTodoCell(_ cell: RecurringTodoCell, didEndEditing text: String) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            assertionFailure()
            return
        }
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dataSource.settings[indexPath.row].name = text
        }
    }

    func recurringTodoCellDidTapFreq(_ cell: RecurringTodoCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            assertionFailure()
            return
        }
        self.changingFreqIndex = indexPath.row
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        let dummy = UITextField(frame: .zero)
        dummy.delegate = self
        view.addSubview(dummy)
        dummy.inputView = picker
        dummy.becomeFirstResponder()
    }
}

// MARK: - Picker

extension SettingsViewController: UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Setting.Frequency.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let index = changingFreqIndex else { preconditionFailure() }

        /// calced every row slow
        var mFrequencies = SettingsViewController.Setting.Frequency.allCases
        let initial = self.dataSource.settings[index].frequency
        mFrequencies.removeAll(where: { $0 == initial })
        mFrequencies.insert(initial, at: 0)
        return mFrequencies[row].description
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let index = changingFreqIndex else { preconditionFailure() }

        /// calced every row slow
        var mFrequencies = SettingsViewController.Setting.Frequency.allCases
        let initial = self.dataSource.settings[index].frequency
        mFrequencies.removeAll(where: { $0 == initial })
        mFrequencies.insert(initial, at: 0)

        self.dataSource.settings[index].frequency = mFrequencies[row]
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.dataSource.applySnapshot(animatingDifferences: false)
    }
}