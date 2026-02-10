package com.binye.yomo.ui.screens

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.binye.yomo.data.repository.AuthRepository
import com.google.firebase.auth.FirebaseUser
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class AuthUiState(
    val user: FirebaseUser? = null,
    val isLoading: Boolean = false,
    val error: String? = null,
    val isDevLogin: Boolean = false,
    val devUserId: String? = null
)

class AuthViewModel : ViewModel() {
    private val repo = AuthRepository()

    private val _uiState = MutableStateFlow(
        AuthUiState(user = repo.currentUser)
    )
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    val isLoggedIn: Boolean
        get() = _uiState.value.user != null || _uiState.value.isDevLogin

    val userId: String?
        get() = _uiState.value.user?.uid ?: _uiState.value.devUserId

    fun signInWithGoogle(context: Context, webClientId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val user = repo.signInWithGoogle(context, webClientId)
                _uiState.value = _uiState.value.copy(
                    user = user,
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.localizedMessage ?: "Sign-in failed"
                )
            }
        }
    }

    fun devLogin() {
        _uiState.value = _uiState.value.copy(
            isDevLogin = true,
            devUserId = "dev-android-${System.currentTimeMillis()}"
        )
    }

    fun signOut() {
        repo.signOut()
        _uiState.value = AuthUiState()
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}
