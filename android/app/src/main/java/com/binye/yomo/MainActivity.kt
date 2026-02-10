package com.binye.yomo

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.binye.yomo.ui.YomoApp
import com.binye.yomo.ui.theme.YomoTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            YomoTheme {
                YomoApp()
            }
        }
    }
}
