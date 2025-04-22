// ファイル: Views/Settings/Components/ExerciseManagementView.swift

import SwiftUI

struct ExerciseManagementView: View {
    @StateObject private var viewModel = ExerciseManagementViewModel()
    @State private var showingAddExercise = false
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory = .all
    
    var filteredExercises: [Exercise] {
        let categoryFiltered = viewModel.getExercisesByCategory(category: selectedCategory)
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { exercise in
                exercise.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 検索バー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("種目を検索", text: $searchText)
                    .foregroundColor(.primary)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color.lightGray)
            .cornerRadius(10)
            .padding([.horizontal, .top])
            
            // カテゴリーフィルター
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExerciseCategory.allCases) { category in
                        CategoryButton(
                            title: category.rawValue,
                            isSelected: selectedCategory == category,
                            action: {
                                selectedCategory = category
                            }
                        )
                    }
                }
                .padding([.horizontal, .top])
            }
            
            // 種目リスト
            List {
                ForEach(filteredExercises, id: \.id) { exercise in
                    ExerciseManagementRow(
                        exercise: exercise,
                        onToggleFavorite: {
                            viewModel.toggleFavorite(exercise: exercise)
                        }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !exercise.isDefault {
                            Button(role: .destructive) {
                                viewModel.deleteExercise(exercise: exercise)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("種目管理")
        .navigationBarItems(
            trailing: Button(action: {
                showingAddExercise = true
            }) {
                Image(systemName: "plus")
            }
        )
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(onSave: { name in
                viewModel.addExercise(name: name)
            })
        }
        .onAppear {
            viewModel.loadExercises()
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.primaryRed : Color.lightGray)
                .foregroundColor(isSelected ? .white : Color.darkGray)
                .cornerRadius(16)
        }
    }
}

struct ExerciseManagementRow: View {
    let exercise: Exercise
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack {
            Text(exercise.name ?? "")
                .foregroundColor(.primary)
            
            Spacer()
            
            if exercise.isDefault {
                Text("デフォルト")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.lightGray)
                    .cornerRadius(4)
            }
            
            Button(action: onToggleFavorite) {
                Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 22))
                    .foregroundColor(exercise.isFavorite ? .accentOrange : .gray)
                    .padding(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

struct ExerciseManagementView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExerciseManagementView()
                .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
        }
    }
}
