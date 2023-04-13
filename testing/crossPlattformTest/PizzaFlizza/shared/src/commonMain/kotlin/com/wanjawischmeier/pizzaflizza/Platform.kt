package com.wanjawischmeier.pizzaflizza

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform