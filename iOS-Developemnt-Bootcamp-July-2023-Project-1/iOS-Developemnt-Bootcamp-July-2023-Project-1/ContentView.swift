//
//  ContentView.swift
//  iOS-Developemnt-Bootcamp-July-2023-Project-1
//
//  Created by Juhaina on 18/01/1445 AH.
//

import SwiftUI

struct ContentView: View {
    @State private var tasks = [Task]()
    @State private var showingAddTask = false
    @State private var filterStatus: Task.Status? = nil
    @State private var searchText = ""
    @State private var isDarkMode = false

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchText)
                        .padding(7)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)

                List {
                    ForEach(filteredTasks) { task in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(task.title)
                                Text(task.status.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .foregroundColor(.pink)
                                Text(task.priority.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    
                            }
                            Spacer()
                            Button(action: { tasks[getIndex(for: task)].edit.toggle() }) {
                                Text("Edit")
                                    .foregroundColor(.blue)
                            }
                            .sheet(isPresented: $tasks[getIndex(for: task)].edit) {
                                EditView(task: $tasks[getIndex(for: task)])
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
                .navigationTitle("Tasks")
                .navigationBarItems(
                    leading: Button(action: { showingAddTask.toggle() }) {
                        Image(systemName: "plus")
                            .imageScale(.large)
                    },
                    trailing: EditButton()
                )
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Picker("Filter", selection: $filterStatus) {
                            Text("All").tag(Task.Status?.none)
                            ForEach(Task.Status.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(Task.Status?.some(status))
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isDarkMode.toggle()
                        }) {
                            Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                        }
                    }
                }
                .sheet(isPresented: $showingAddTask) {
                    AddView(tasks: $tasks)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear {
                tasks = loadTasks()
                isDarkMode = colorScheme == .dark
            }
            .onDisappear {
                saveTasks()
            }
            .accentColor(.pink)
        }
    }

    private var filteredTasks: [Task] {
        if searchText.isEmpty {
            return tasks.filter { filterStatus == nil || $0.status == filterStatus }
        } else {
            return tasks.filter { (filterStatus == nil || $0.status == filterStatus) && $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func getIndex(for task: Task) -> Int {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            fatalError("Task not found in the array")
        }
        return index
    }

    private func delete(offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }

    private func saveTasks() {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(tasks) {
            UserDefaults.standard.set(encodedData, forKey: "tasks")
        }
    }

    private func loadTasks() -> [Task] {
        if let data = UserDefaults.standard.data(forKey: "tasks") {
            let decoder = JSONDecoder()
            if let decodedTasks = try? decoder.decode([Task].self, from: data) {
                return decodedTasks
            }
        }
        return []
    }
}

struct Task: Identifiable, Codable {
    let id = UUID()
    var title: String
    var status: Status = .backlog
    var priority: Priority = .low
    var edit: Bool = false
    
    enum Status: String, CaseIterable, Codable {
        case backlog = "Backlog"
        case todo = "Todo"
        case inProgress = "In-Progress"
        case done = "Done"
    }
    
    enum Priority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
}

struct EditView: View {
    @Binding var task: Task
    @State private var editedTitle: String
    
    init(task: Binding<Task>) {
        _task = task
        _editedTitle = State(initialValue: task.wrappedValue.title)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Task title", text: $editedTitle, onCommit: save)
                Picker("Status", selection: $task.status) {
                    ForEach(Task.Status.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                Picker("Priority", selection: $task.priority) {
                    ForEach(Task.Priority.allCases, id: \.self) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
            }
            .navigationTitle("Edit task")
        }
        .onAppear {
            editedTitle = task.title
        }
    }
    
    private func save() {
        task.title = editedTitle
    }
}

struct AddView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var tasks: [Task]
    @State private var title: String = ""
    @State private var status: Task.Status = .backlog
    @State private var priority: Task.Priority = .low
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Task title", text: $title)
                Picker("Status", selection: $status) {
                    ForEach(Task.Status.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                Picker("Priority", selection: $priority) {
                    ForEach(Task.Priority.allCases, id: \.self) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
            }
            .navigationTitle("New task")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Add") {
                let task = Task(title: title, status: status, priority: priority)
                tasks.append(task)
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
