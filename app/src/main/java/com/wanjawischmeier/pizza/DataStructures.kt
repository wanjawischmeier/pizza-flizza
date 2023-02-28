package com.wanjawischmeier.pizza

import com.google.android.gms.tasks.Task
import com.google.firebase.database.FirebaseDatabase

class User
{
    var creationDate = ""
}

class Item
{
    var name = ""
    var price = 0f
}

class Order
{
    // item_id, count
    lateinit var items: Map<String, Int>
}

class Shop
{
    var name = ""
    var address = ""
    var picture = ""

    // item_id, item
    lateinit var items: Map<String, Item>
    // user_id, order
    lateinit var orders: Map<String, Order>

    companion object {
        private fun <K, V> loadStructure(database: FirebaseDatabase, path: String): Task<Map<K, V>> {
            return database.getReference(path).get().continueWith { task ->
                if (task.isSuccessful) {
                    @Suppress("UNCHECKED_CAST")
                    return@continueWith task.result.value as Map<K, V>
                } else {
                    return@continueWith mapOf<K, V>()
                }
            }
        }

        fun loadAll(database: FirebaseDatabase): Task<Map<String, Shop>> {
            return loadStructure(database, "shops")
        }
    }
}