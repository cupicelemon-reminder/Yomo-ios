package com.binye.yomo.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.binye.yomo.data.model.Reminder
import com.binye.yomo.data.repository.ReminderRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

data class ReminderGroup(
    val title: String,
    val reminders: List<Reminder>
)

data class ReminderUiState(
    val groups: List<ReminderGroup> = emptyList(),
    val isLoading: Boolean = true,
    val error: String? = null,
    val pendingCount: Int = 0,
    val completedCount: Int = 0
)

class ReminderViewModel : ViewModel() {
    private val repo = ReminderRepository()

    private val _uiState = MutableStateFlow(ReminderUiState())
    val uiState: StateFlow<ReminderUiState> = _uiState.asStateFlow()

    private var listenerJob: Job? = null

    fun startListening(userId: String) {
        listenerJob?.cancel()
        listenerJob = viewModelScope.launch {
            repo.observeReminders(userId).collect { reminders ->
                val pending = reminders.filter { it.isPending }
                val completed = reminders.filter { it.isCompleted }

                val groups = buildGroups(pending, completed)
                _uiState.value = ReminderUiState(
                    groups = groups,
                    isLoading = false,
                    pendingCount = pending.size,
                    completedCount = completed.size
                )
            }
        }
    }

    fun toggleComplete(reminder: Reminder) {
        viewModelScope.launch {
            try {
                repo.toggleComplete(reminder)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.localizedMessage ?: "Failed to update reminder"
                )
            }
        }
    }

    fun stopListening() {
        listenerJob?.cancel()
        listenerJob = null
    }

    private fun buildGroups(
        pending: List<Reminder>,
        completed: List<Reminder>
    ): List<ReminderGroup> {
        val groups = mutableListOf<ReminderGroup>()
        val now = Calendar.getInstance()
        val today = stripTime(now.time)

        val tomorrow = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
        }
        val tomorrowDate = stripTime(tomorrow.time)

        val endOfWeek = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 7)
        }
        val endOfWeekDate = stripTime(endOfWeek.time)

        val overdue = mutableListOf<Reminder>()
        val todayList = mutableListOf<Reminder>()
        val tomorrowList = mutableListOf<Reminder>()
        val thisWeekList = mutableListOf<Reminder>()
        val laterList = mutableListOf<Reminder>()

        for (reminder in pending) {
            val triggerDate = stripTime(reminder.triggerDate.toDate())
            when {
                triggerDate.before(today) -> overdue.add(reminder)
                triggerDate == today -> todayList.add(reminder)
                triggerDate == tomorrowDate -> tomorrowList.add(reminder)
                triggerDate.before(endOfWeekDate) -> thisWeekList.add(reminder)
                else -> laterList.add(reminder)
            }
        }

        if (overdue.isNotEmpty()) groups.add(ReminderGroup("Overdue", overdue))
        if (todayList.isNotEmpty()) groups.add(ReminderGroup("Today", todayList))
        if (tomorrowList.isNotEmpty()) groups.add(ReminderGroup("Tomorrow", tomorrowList))
        if (thisWeekList.isNotEmpty()) groups.add(ReminderGroup("This Week", thisWeekList))
        if (laterList.isNotEmpty()) groups.add(ReminderGroup("Later", laterList))
        if (completed.isNotEmpty()) groups.add(ReminderGroup("Completed", completed))

        return groups
    }

    private fun stripTime(date: Date): Date {
        val cal = Calendar.getInstance().apply {
            time = date
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return cal.time
    }
}
