//
//  TaskListViewController.swift
//  CoreDataDemo
//
//  Created by Alexey Efimov on 04.10.2021.
//

import UIKit
import CoreData

protocol TaskViewControllerDelegate {
    func reloadData()
}

class TaskListViewController: UITableViewController {
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private let cellID = "task"
    private var taskList: [Task] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        setupNavigationBar()
        fetchData()
    }

    private func setupNavigationBar() {
        title = "Task List"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let navBarAppearance = UINavigationBarAppearance()
        
        navBarAppearance.backgroundColor = UIColor(
            red: 21/255,
            green: 101/255,
            blue: 192/255,
            alpha: 194/255
        )
        
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTask)
        )
        
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
    }
    
    @objc private func addNewTask() {
        showAlert(with: "New Task", and: "What do you want to do?")
    }
    
    private func fetchData() {
        let fetchRequest = Task.fetchRequest()
        
        do {
            taskList = try context.fetch(fetchRequest)
        } catch let error {
            print("Failed to fetch data", error)
        }
    }
    
    private func showAlert(with title: String, and message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let task = alert.textFields?.first?.text, !task.isEmpty else { return }
            self.save(task)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextField { textField in
            textField.placeholder = "New Task"
        }
        present(alert, animated: true)
    }

    // MARK: - Core Data 
    private func save(_ taskName: String) {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Task", in: context) else { return }
        guard let task = NSManagedObject(entity: entityDescription, insertInto: context) as? Task else { return }
        task.title = taskName
        taskList.append(task)
        
        let cellIndex = IndexPath(row: taskList.count - 1, section: 0)
        tableView.insertRows(at: [cellIndex], with: .automatic)
        
        if context.hasChanges {
            do {
                try context.save()
            } catch let error {
                print(error)
            }
        }
    }
    
    private func deleteTask(_ deleteTask: Task) {
        
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        guard let tasks = try? context.fetch(fetchRequest) else { return }
        for task in tasks {
            if task == deleteTask {
                context.delete(task)
            }
            
            if context.hasChanges {
                do {
                    try context.save()
                } catch let error {
                    print(error)
                }
            }
        }
    }
    
    private func updateTask(_ updateTask: Task, _ newText: String, item: Int) {
        
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        guard let tasks = try? context.fetch(fetchRequest) else { return }
        for task in tasks {
            if task == updateTask {
                task.title = newText
                taskList[item].title = newText
                tableView.reloadData()
            }
            if context.hasChanges {
                do {
                    try context.save()
                } catch let error {
                    print(error)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let task = taskList[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            tableView.beginUpdates()
            let task = taskList[indexPath.row]
            deleteTask(task)
            taskList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            tableView.endUpdates()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let task = taskList[indexPath.row]
        let item = indexPath.row
        
        
        let alert = UIAlertController(title: "Edit item", message: "Edit your item", preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        alert.textFields?.first?.text = task.title
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let newText = alert.textFields?.first?.text, !newText.isEmpty else { return }
            self.updateTask(task, newText, item: item)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }
}

// MARK: - TaskViewControllerDelegate
extension TaskListViewController: TaskViewControllerDelegate {
    func reloadData() {
        fetchData()
        tableView.reloadData()
    }
}


