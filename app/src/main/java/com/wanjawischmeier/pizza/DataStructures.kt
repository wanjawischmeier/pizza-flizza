package com.wanjawischmeier.pizza

import com.google.android.gms.tasks.Task
import com.google.firebase.database.FirebaseDatabase
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import org.json.JSONObject

const val SHOP_ID = "penny_burgtor"

class User
{
    var creationDate = ""
}

@Serializable
class Item(
    @SerialName("name") val name: String,
    @SerialName("price") val price: Float
)

class Shop
{
    var name = ""
    var address = ""
    var picture = ""

    // item_id, item
    lateinit var items: Map<String, Pair<String, Float>>
    // user_id, order (item_id, count)
    lateinit var orders: Map<String, Map<String, Int>>

    companion object {
        lateinit var database: FirebaseDatabase

        private fun <K, V> loadStructure(path: String): Task<HashMap<K, V>> {
            return database.getReference(path).get().continueWith { task ->
                if (task.isSuccessful) {
                    @Suppress("UNCHECKED_CAST")
                    return@continueWith task.result.value as HashMap<K, V>
                } else {
                    return@continueWith hashMapOf<K, V>()
                }
            }
        }

        fun getAll(): Task<HashMap<String, Shop>> {
            return loadStructure("shops")
        }

        fun getOrders(): Task<HashMap<String, Map<String, Int>>> {
            return loadStructure("shops/$SHOP_ID/orders")
        }

        fun getOrder(uid: String): Task<HashMap<String, Int>> {
            return loadStructure("shops/$SHOP_ID/orders/$uid")
        }

        fun processOrder(uid: String, order: HashMap<String, Int>) {
            database.getReference("shops/$SHOP_ID/orders/$uid").setValue(order)
        }

        fun getItems(): Task<HashMap<String, Item>> {
            return database.getReference("shops/$SHOP_ID/items").get().continueWith { task ->
                if (task.isSuccessful) {
                    val result = task.result.value as HashMap<*, *>
                    val jsonString = JSONObject(result).toString()
                    return@continueWith Json.decodeFromString<HashMap<String, Item>>(jsonString)
                } else return@continueWith null
            }
        }

        fun getItem(itemId: String): Task<Item> {
            return database.getReference("shops/$SHOP_ID/items/$itemId").get().continueWith { task ->
                if (task.isSuccessful) {
                    val result = task.result.value as HashMap<*, *>
                    val jsonString = JSONObject(result).toString()
                    return@continueWith Json.decodeFromString<Item>(jsonString)
                } else return@continueWith null
            }
        }
    }
}