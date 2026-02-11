//
//  NotificationViewController.swift
//  YomoNotificationContent
//
//  Custom notification content extension with snooze slider (Screen 8)
//  Shows when user long-presses a Yomo notification.
//  Handles snooze/complete WITHOUT opening the app.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    // MARK: - UI Elements
    private let bellIcon = UIImageView()
    private let titleLabel = UILabel()
    private let snoozeLabel = UILabel()
    private let minutesLabel = UILabel()
    private let slider = UISlider()
    private let minLabel = UILabel()
    private let maxLabel = UILabel()
    private let snoozeButton = UIButton(type: .system)
    private let completeButton = UIButton(type: .system)

    private var reminderId: String = ""
    private var reminderTitle: String = ""
    private var snoozeMinutes: Int = 15

    private let appGroupId = "group.com.binye.Yomo"

    // MARK: - Colors (matching design tokens)
    private let brandBlue = UIColor(red: 74/255, green: 144/255, blue: 217/255, alpha: 1)
    private let checkGold = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1)
    private let goldBg = UIColor(red: 255/255, green: 245/255, blue: 224/255, alpha: 1)
    private let textPrimary = UIColor(red: 26/255, green: 26/255, blue: 46/255, alpha: 1)
    private let textSecondary = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        preferredContentSize = CGSize(width: view.bounds.width, height: 280)
        setupUI()
    }

    // MARK: - Notification Content

    func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        reminderId = userInfo["reminderId"] as? String ?? ""
        reminderTitle = userInfo["title"] as? String ?? notification.request.content.body

        titleLabel.text = reminderTitle
        updateMinutesLabel()
    }

    func didReceive(
        _ response: UNNotificationResponse,
        completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void
    ) {
        // No external actions - all handled by in-extension buttons
        completion(.dismiss)
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Bell icon
        let bellConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        bellIcon.image = UIImage(systemName: "bell.fill", withConfiguration: bellConfig)
        bellIcon.tintColor = brandBlue
        bellIcon.contentMode = .scaleAspectFit

        // Title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        // Snooze label
        snoozeLabel.text = "Snooze for:"
        snoozeLabel.font = .systemFont(ofSize: 13)
        snoozeLabel.textColor = textSecondary
        snoozeLabel.textAlignment = .center

        // Minutes display
        minutesLabel.font = .monospacedDigitSystemFont(ofSize: 32, weight: .bold)
        minutesLabel.textColor = brandBlue
        minutesLabel.textAlignment = .center
        updateMinutesLabel()

        // Slider
        slider.minimumValue = 1
        slider.maximumValue = 60
        slider.value = 15
        slider.tintColor = brandBlue
        slider.isUserInteractionEnabled = true
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        // Min/max labels
        minLabel.text = "1 min"
        minLabel.font = .systemFont(ofSize: 11)
        minLabel.textColor = textSecondary

        maxLabel.text = "60 min"
        maxLabel.font = .systemFont(ofSize: 11)
        maxLabel.textColor = textSecondary
        maxLabel.textAlignment = .right

        // Snooze button
        snoozeButton.setTitle("  Snooze", for: .normal)
        snoozeButton.setImage(UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
        snoozeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        snoozeButton.backgroundColor = brandBlue
        snoozeButton.setTitleColor(.white, for: .normal)
        snoozeButton.tintColor = .white
        snoozeButton.layer.cornerRadius = 14
        snoozeButton.clipsToBounds = true
        snoozeButton.addTarget(self, action: #selector(snoozeTapped), for: .touchUpInside)

        // Complete button
        completeButton.setTitle("  Complete", for: .normal)
        completeButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        completeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        completeButton.backgroundColor = goldBg
        completeButton.setTitleColor(checkGold, for: .normal)
        completeButton.tintColor = checkGold
        completeButton.layer.cornerRadius = 14
        completeButton.clipsToBounds = true
        completeButton.addTarget(self, action: #selector(completeTapped), for: .touchUpInside)

        // -- Layout with auto layout --

        // Header: bell + title
        let headerStack = UIStackView(arrangedSubviews: [bellIcon, titleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4
        headerStack.alignment = .center

        // Slider row with min/max labels
        let sliderRangeStack = UIStackView(arrangedSubviews: [minLabel, maxLabel])
        sliderRangeStack.axis = .horizontal
        sliderRangeStack.distribution = .equalSpacing

        // Snooze controls
        let snoozeStack = UIStackView(arrangedSubviews: [snoozeLabel, minutesLabel, slider, sliderRangeStack])
        snoozeStack.axis = .vertical
        snoozeStack.spacing = 4
        snoozeStack.alignment = .fill

        // Buttons
        let buttonStack = UIStackView(arrangedSubviews: [snoozeButton, completeButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        // Main stack
        let mainStack = UIStackView(arrangedSubviews: [headerStack, snoozeStack, buttonStack])
        mainStack.axis = .vertical
        mainStack.spacing = 12

        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16),
            bellIcon.heightAnchor.constraint(equalToConstant: 28),
            snoozeButton.heightAnchor.constraint(equalToConstant: 48),
            completeButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    // MARK: - Actions

    @objc private func sliderChanged() {
        snoozeMinutes = Int(slider.value)
        updateMinutesLabel()
    }

    @objc private func snoozeTapped() {
        // Cancel the current notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderId])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [reminderId])

        // Schedule a new notification for after the snooze
        let content = UNMutableNotificationContent()
        content.title = "Yomo"
        content.body = reminderTitle
        content.sound = .default
        content.badge = 1
        content.userInfo = ["reminderId": reminderId, "title": reminderTitle]
        content.categoryIdentifier = "YOMO_REMINDER_FREE"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(snoozeMinutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: reminderId,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)

        // Update the reminder's snoozedUntil in shared storage
        let snoozeDate = Date().addingTimeInterval(TimeInterval(snoozeMinutes * 60))
        updateReminderSnooze(reminderId: reminderId, snoozeDate: snoozeDate)

        // Queue a pending action so the main app can sync to Firestore
        appendPendingAction(type: "snooze", reminderId: reminderId, snoozeDate: snoozeDate)

        updateAppBadgeFromStore()

        // Dismiss notification WITHOUT opening the app
        extensionContext?.dismissNotificationContentExtension()
    }

    @objc private func completeTapped() {
        // Cancel notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderId])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [reminderId])

        // Mark complete in shared storage
        completeReminderInStore(reminderId: reminderId)

        // Queue a pending action so the main app can sync to Firestore
        appendPendingAction(type: "complete", reminderId: reminderId)

        updateAppBadgeFromStore()

        // Dismiss notification WITHOUT opening the app
        extensionContext?.dismissNotificationContentExtension()
    }

    private func updateMinutesLabel() {
        minutesLabel.text = "\(snoozeMinutes) min"
    }

    // MARK: - Shared Storage (App Group)

    private func updateReminderSnooze(reminderId: String, snoozeDate: Date) {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              var dtos = loadDTOs(from: defaults) else { return }

        if let index = dtos.firstIndex(where: { $0.id == reminderId }) {
            dtos[index].snoozedUntil = snoozeDate.timeIntervalSince1970
            dtos[index].updatedAt = Date().timeIntervalSince1970
            saveDTOs(dtos, to: defaults)
        }
    }

    private func completeReminderInStore(reminderId: String) {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              var dtos = loadDTOs(from: defaults) else { return }

        if let index = dtos.firstIndex(where: { $0.id == reminderId }) {
            let dto = dtos[index]
            if let recurrenceType = dto.recurrenceType, recurrenceType != "none" {
                // Recurring: advance to next date
                let triggerDate = Date(timeIntervalSince1970: dto.triggerDate)
                let interval = dto.recurrenceInterval ?? 1
                let unit = dto.recurrenceUnit ?? "day"
                let nextDate = calculateNextDate(from: triggerDate, interval: interval, unit: unit)
                dtos[index].triggerDate = nextDate.timeIntervalSince1970
                dtos[index].snoozedUntil = nil
                dtos[index].updatedAt = Date().timeIntervalSince1970
            } else {
                dtos[index].status = "completed"
                dtos[index].updatedAt = Date().timeIntervalSince1970
            }
            saveDTOs(dtos, to: defaults)
        }
    }

    // MARK: - DTO matching LocalReminderStore format

    private struct ReminderDTO: Codable {
        var id: String
        var title: String
        var notes: String?
        var triggerDate: Double
        var recurrenceType: String?
        var recurrenceInterval: Int?
        var recurrenceUnit: String?
        var recurrenceDaysOfWeek: [Int]?
        var recurrenceTimeRangeStart: String?
        var recurrenceTimeRangeEnd: String?
        var recurrenceBasedOnCompletion: Bool?
        var status: String
        var snoozedUntil: Double?
        var createdAt: Double
        var updatedAt: Double
    }

    private let storageKey = "yomo_local_reminders"

    private func loadDTOs(from defaults: UserDefaults) -> [ReminderDTO]? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode([ReminderDTO].self, from: data)
    }

    private func saveDTOs(_ dtos: [ReminderDTO], to defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(dtos) {
            defaults.set(data, forKey: storageKey)
            defaults.synchronize()
        }
    }

    private func updateAppBadgeFromStore() {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let dtos = loadDTOs(from: defaults) else {
            setAppBadge(0)
            return
        }

        let now = Date().timeIntervalSince1970
        let overdueCount = dtos.filter { dto in
            guard dto.status == "active" else { return false }
            let display = dto.snoozedUntil ?? dto.triggerDate
            return display < now
        }.count

        setAppBadge(overdueCount)
    }

    private func setAppBadge(_ count: Int) {
        if #available(iOSApplicationExtension 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(count)
        }
    }

    // MARK: - Pending Actions Queue

    private let pendingActionsKey = "yomo_pending_extension_actions"

    /// Append an action so the main app can replay it against Firestore on next launch.
    private func appendPendingAction(type: String, reminderId: String, snoozeDate: Date? = nil) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
        var actions = defaults.array(forKey: pendingActionsKey) as? [[String: Any]] ?? []
        var entry: [String: Any] = ["type": type, "reminderId": reminderId]
        if let snoozeDate {
            entry["snoozeDate"] = snoozeDate.timeIntervalSince1970
        }
        actions.append(entry)
        defaults.set(actions, forKey: pendingActionsKey)
        defaults.synchronize()
    }

    private func calculateNextDate(from date: Date, interval: Int, unit: String) -> Date {
        let calendar = Calendar.current
        let now = Date()
        var nextDate = date

        let component: Calendar.Component = {
            switch unit {
            case "hour": return .hour
            case "week": return .weekOfYear
            case "month": return .month
            default: return .day
            }
        }()

        while nextDate <= now {
            nextDate = calendar.date(byAdding: component, value: interval, to: nextDate) ?? nextDate
        }

        return nextDate
    }
}
