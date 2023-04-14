package com.wanjawischmeier.pizzaflizza

import dev.gitlive.firebase.Firebase
import dev.gitlive.firebase.auth.auth
import kotlin.random.Random

class Database {
    fun signedIn() = if (Firebase.auth.currentUser == null) {
        "Signed out"
    } else {
        "Signed in"
    }

    fun generateTimeBasedId(length: Int = 6): String {
        val charPool = ('a'..'z') + ('A'..'Z') + ('0'..'9')
        val random = Random(Time.getMilis())

        return List(length) {
            random.nextInt()
        }.map(charPool::get).joinToString("")
    }
}