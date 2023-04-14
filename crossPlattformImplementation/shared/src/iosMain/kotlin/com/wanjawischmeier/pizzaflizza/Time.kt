package com.wanjawischmeier.pizzaflizza

import kotlin.math.roundToLong

actual class Time {
    actual companion object {
        lateinit var timeImplementation: () -> Double

        actual fun getMilis(): Long {
            return if (this::timeImplementation.isInitialized) {
                (timeImplementation() * 1000).roundToLong()
            } else 0L
        }
    }
}