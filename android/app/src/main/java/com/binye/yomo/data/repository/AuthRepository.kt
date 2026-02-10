package com.binye.yomo.data.repository

import android.content.Context
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import kotlinx.coroutines.tasks.await

class AuthRepository {
    private val auth = FirebaseAuth.getInstance()

    val currentUser: FirebaseUser? get() = auth.currentUser

    suspend fun signInWithGoogle(context: Context, webClientId: String): FirebaseUser? {
        val credentialManager = CredentialManager.create(context)

        val googleIdOption = GetGoogleIdOption.Builder()
            .setFilterByAuthorizedAccounts(false)
            .setServerClientId(webClientId)
            .build()

        val request = GetCredentialRequest.Builder()
            .addCredentialOption(googleIdOption)
            .build()

        val result = credentialManager.getCredential(context, request)
        val googleIdToken = GoogleIdTokenCredential
            .createFrom(result.credential.data)
            .idToken

        val credential = GoogleAuthProvider.getCredential(googleIdToken, null)
        val authResult = auth.signInWithCredential(credential).await()
        return authResult.user
    }

    suspend fun signInAnonymously(): FirebaseUser? {
        val result = auth.signInAnonymously().await()
        return result.user
    }

    fun signOut() {
        auth.signOut()
    }
}
