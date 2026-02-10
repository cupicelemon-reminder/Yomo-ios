package com.binye.yomo.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.lifecycle.viewmodel.compose.viewModel
import com.binye.yomo.ui.screens.AuthViewModel
import com.binye.yomo.ui.screens.LoginScreen
import com.binye.yomo.ui.screens.ReminderListScreen
import com.binye.yomo.ui.screens.ReminderViewModel

const val WEB_CLIENT_ID = "240921047280-e083q44bb944p99loqpi48tmkcdqg0b3.apps.googleusercontent.com"

@Composable
fun YomoApp() {
    val authViewModel: AuthViewModel = viewModel()
    val reminderViewModel: ReminderViewModel = viewModel()
    val authState by authViewModel.uiState.collectAsState()

    val isLoggedIn = authState.user != null || authState.isDevLogin

    if (isLoggedIn) {
        val userId = authState.user?.uid ?: authState.devUserId ?: return
        ReminderListScreen(
            userId = userId,
            reminderViewModel = reminderViewModel,
            onSignOut = {
                reminderViewModel.stopListening()
                authViewModel.signOut()
            }
        )
    } else {
        LoginScreen(
            authViewModel = authViewModel,
            webClientId = WEB_CLIENT_ID
        )
    }
}
