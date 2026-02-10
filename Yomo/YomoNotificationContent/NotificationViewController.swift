//
//  NotificationViewController.swift
//  YomoNotificationContent
//
//  Custom notification content extension with snooze slider (Screen 8)
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    // Storyboard outlet (required by MainInterface.storyboard connection)
    @IBOutlet weak var label: UILabel!

    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let snoozeLabel = UILabel()
    private let minutesLabel = UILabel()
    private let slider = UISlider()
    private let snoozeButton = UIButton(type: .system)
    private let completeButton = UIButton(type: .system)

    private var reminderId: String = ""
    private var reminderTitle: String = ""
    private var snoozeMinutes: Int = 15

    // MARK: - Colors (matching design tokens)
    private let brandBlue = UIColor(red: 74/255, green: 144/255, blue: 217/255, alpha: 1)
    private let checkGold = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1)
    private let textPrimary = UIColor(red: 26/255, green: 26/255, blue: 46/255, alpha: 1)
    private let textSecondary = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
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
        switch response.actionIdentifier {
        case "YOMO_COMPLETE":
            completion(.dismissAndForwardAction)
        case "YOMO_SNOOZE_5", "YOMO_SNOOZE_15", "YOMO_SNOOZE_30":
            completion(.dismissAndForwardAction)
        case "YOMO_CUSTOM_SNOOZE":
            completion(.doNotDismiss)
        default:
            completion(.dismissAndForwardAction)
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        preferredContentSize = CGSize(width: view.bounds.width, height: 200)

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
        minutesLabel.font = .systemFont(ofSize: 32, weight: .bold)
        minutesLabel.textColor = brandBlue
        minutesLabel.textAlignment = .center
        updateMinutesLabel()

        // Slider
        slider.minimumValue = 1
        slider.maximumValue = 60
        slider.value = 15
        slider.tintColor = brandBlue
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        // Snooze button
        snoozeButton.setTitle("Snooze", for: .normal)
        snoozeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        snoozeButton.backgroundColor = brandBlue
        snoozeButton.setTitleColor(.white, for: .normal)
        snoozeButton.layer.cornerRadius = 12
        snoozeButton.addTarget(self, action: #selector(snoozeTapped), for: .touchUpInside)

        // Complete button
        completeButton.setTitle("Complete", for: .normal)
        completeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        completeButton.backgroundColor = UIColor(red: 255/255, green: 245/255, blue: 224/255, alpha: 1)
        completeButton.setTitleColor(checkGold, for: .normal)
        completeButton.layer.cornerRadius = 12
        completeButton.addTarget(self, action: #selector(completeTapped), for: .touchUpInside)

        // Layout
        let stack = UIStackView(arrangedSubviews: [
            titleLabel, snoozeLabel, minutesLabel, slider
        ])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill

        let buttonStack = UIStackView(arrangedSubviews: [snoozeButton, completeButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        let mainStack = UIStackView(arrangedSubviews: [stack, buttonStack])
        mainStack.axis = .vertical
        mainStack.spacing = 16

        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            snoozeButton.heightAnchor.constraint(equalToConstant: 44),
            completeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Actions

    @objc private func sliderChanged() {
        snoozeMinutes = Int(slider.value)
        updateMinutesLabel()
    }

    @objc private func snoozeTapped() {
        // Write snooze info via App Group UserDefaults
        if let defaults = UserDefaults(suiteName: "group.com.binye.Yomo") {
            defaults.set(reminderId, forKey: "pendingSnoozeReminderId")
            defaults.set(reminderTitle, forKey: "pendingSnoozeTitle")
            defaults.set(snoozeMinutes, forKey: "pendingSnoozeMinutes")
            defaults.synchronize()
        }

        // Schedule a local notification for the snooze
        let content = UNMutableNotificationContent()
        content.title = "Yomo"
        content.body = reminderTitle
        content.sound = .default
        content.userInfo = ["reminderId": reminderId, "title": reminderTitle]

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

        extensionContext?.dismissNotificationContentExtension()
    }

    @objc private func completeTapped() {
        if let defaults = UserDefaults(suiteName: "group.com.binye.Yomo") {
            defaults.set(reminderId, forKey: "pendingCompleteReminderId")
            defaults.synchronize()
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderId])
        extensionContext?.dismissNotificationContentExtension()
    }

    private func updateMinutesLabel() {
        minutesLabel.text = "\(snoozeMinutes) min"
    }
}
