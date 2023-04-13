package com.wanjawischmeier.pizza.shared

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform