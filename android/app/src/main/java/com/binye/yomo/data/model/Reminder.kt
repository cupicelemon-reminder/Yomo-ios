package com.binye.yomo.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot

data class Reminder(
    val id: String = "",
    val userId: String = "",
    val title: String = "",
    val triggerDate: Timestamp = Timestamp.now(),
    val status: String = "pending",
    val category: String = "general",
    val createdAt: Timestamp = Timestamp.now(),
    val updatedAt: Timestamp = Timestamp.now(),
    val completedAt: Timestamp? = null,
    val source: String = "android"
) {
    companion object {
        fun fromDocument(doc: DocumentSnapshot): Reminder? {
            val data = doc.data ?: return null
            return Reminder(
                id = doc.id,
                userId = data["userId"] as? String ?: "",
                title = data["title"] as? String ?: "",
                triggerDate = data["triggerDate"] as? Timestamp ?: Timestamp.now(),
                status = data["status"] as? String ?: "pending",
                category = data["category"] as? String ?: "general",
                createdAt = data["createdAt"] as? Timestamp ?: Timestamp.now(),
                updatedAt = data["updatedAt"] as? Timestamp ?: Timestamp.now(),
                completedAt = data["completedAt"] as? Timestamp,
                source = data["source"] as? String ?: "unknown"
            )
        }
    }

    val isPending: Boolean get() = status == "pending"
    val isCompleted: Boolean get() = status == "completed"
}
