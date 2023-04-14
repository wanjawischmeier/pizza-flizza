package com.wanjawischmeier.pizzaflizza

import java.util.*

actual class Time {
    actual companion object {
        actual fun getMilis() = Calendar.getInstance().time.time
    }
}