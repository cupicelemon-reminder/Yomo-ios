package com.binye.yomo.data.repository

import com.binye.yomo.data.model.Reminder
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

class ReminderRepository {
    private val db = FirebaseFirestore.getInstance()

    fun observeReminders(userId: String): Flow<List<Reminder>> = callbackFlow {
        val registration: ListenerRegistration = db.collection("reminders")
            .whereEqualTo("userId", userId)
            .orderBy("triggerDate", Query.Direction.ASCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                val reminders = snapshot?.documents
                    ?.mapNotNull { Reminder.fromDocument(it) }
                    ?: emptyList()
                trySend(reminders)
            }

        awaitClose { registration.remove() }
    }

    suspend fun toggleComplete(reminder: Reminder) {
        val newStatus = if (reminder.isPending) "completed" else "pending"
        val updates = mutableMapOf<String, Any>(
            "status" to newStatus,
            "updatedAt" to Timestamp.now()
        )
        if (newStatus == "completed") {
            updates["completedAt"] = Timestamp.now()
        } else {
            updates["completedAt"] = com.google.firebase.firestore.FieldValue.delete()
        }

        db.collection("reminders")
            .document(reminder.id)
            .update(updates)
            .await()
    }
}
