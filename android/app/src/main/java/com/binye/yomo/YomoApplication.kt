package com.binye.yomo

import android.app.Application
import com.google.firebase.FirebaseApp

class YomoApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
    }
}
