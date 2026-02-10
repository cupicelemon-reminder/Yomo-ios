//
//  ReminderListView.swift
//  Yomo
//
//  Screen 4: Main reminder list with grouped sections
//

import SwiftUI

struct ReminderListView: View {
    @StateObject private var viewModel = ReminderViewModel()
    @State private var showNewReminder = false
    @State private var selectedReminder: Reminder?
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                if viewModel.isLoading && viewModel.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(.brandBlue)
                    Spacer()
                } else if viewModel.isEmpty {
                    EmptyStateView {
                        showNewReminder = true
                    }
                } else {
                    reminderList
                }
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    fabButton
                }
            }
            .padding(.trailing, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Reload in case the notification extension snoozed/completed while in background
            if viewModel.isLocalMode {
                LocalReminderStore.shared.reloadFromDisk()
            }
        }
        .sheet(isPresented: $showNewReminder) {
            NewReminderView()
        }
        .sheet(item: $selectedReminder) { reminder in
            EditReminderView(reminder: reminder)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(AppState.shared)
        }
    }

    // MARK: - Nav Bar
    private var navBar: some View {
        HStack {
            Image("logo-nobg")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Reminder List
    private var reminderList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.md) {
                if !viewModel.overdueReminders.isEmpty {
                    reminderSection(
                        title: "OVERDUE",
                        titleColor: .dangerRed,
                        reminders: viewModel.overdueReminders
                    )
                }

                if !viewModel.todayReminders.isEmpty {
                    reminderSection(
                        title: "TODAY",
                        titleColor: .textSecondary,
                        reminders: viewModel.todayReminders
                    )
                }

                if !viewModel.tomorrowReminders.isEmpty {
                    reminderSection(
                        title: "TOMORROW",
                        titleColor: .textSecondary,
                        reminders: viewModel.tomorrowReminders
                    )
                }

                if !viewModel.thisWeekReminders.isEmpty {
                    reminderSection(
                        title: "THIS WEEK",
                        titleColor: .textSecondary,
                        reminders: viewModel.thisWeekReminders
                    )
                }

                if !viewModel.laterReminders.isEmpty {
                    reminderSection(
                        title: "LATER",
                        titleColor: .textSecondary,
                        reminders: viewModel.laterReminders
                    )
                }

                Spacer().frame(height: 80)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
        }
    }

    // MARK: - Section
    private func reminderSection(
        title: String,
        titleColor: Color,
        reminders: [Reminder]
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.sectionHeader)
                .foregroundColor(titleColor)
                .tracking(1)
                .padding(.top, Spacing.sm)

            ForEach(reminders) { reminder in
                ReminderCard(reminder: reminder) {
                    selectedReminder = reminder
                }
            }
        }
    }

    // MARK: - FAB
    private var fabButton: some View {
        Button {
            HapticManager.light()
            showNewReminder = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.brandBlue)
                    .frame(width: 56, height: 56)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            .elevatedShadow()
        }
    }
}
