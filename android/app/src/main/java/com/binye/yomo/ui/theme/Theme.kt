package com.binye.yomo.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val LightColorScheme = lightColorScheme(
    primary = BrandBlue,
    onPrimary = Color.White,
    primaryContainer = BrandBlue.copy(alpha = 0.12f),
    secondary = CheckGold,
    onSecondary = Color.White,
    background = WarmBg,
    onBackground = TextPrimary,
    surface = CardGlass,
    onSurface = TextPrimary,
    surfaceVariant = Color(0xFFF3EDE4),
    onSurfaceVariant = TextSecondary,
    error = Coral,
    onError = Color.White,
    outline = Color(0xFFD1C9BE)
)

private val DarkColorScheme = darkColorScheme(
    primary = BrandBlue,
    onPrimary = Color.White,
    primaryContainer = BrandBlueDark,
    secondary = CheckGold,
    onSecondary = Color.White,
    background = WarmBgDark,
    onBackground = TextPrimaryDark,
    surface = CardGlassDark,
    onSurface = TextPrimaryDark,
    surfaceVariant = Color(0xFF2D2D3A),
    onSurfaceVariant = TextSecondaryDark,
    error = Coral,
    onError = Color.White,
    outline = Color(0xFF404050)
)

@Composable
fun YomoTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = YomoTypography,
        content = content
    )
}
