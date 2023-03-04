package com.wanjawischmeier.pizza

import com.google.android.gms.tasks.Task
import com.google.firebase.database.ktx.database
import com.google.firebase.ktx.Firebase
import kotlin.reflect.typeOf

class User {
    var name = ""
    var creationDate = ""

    // shopId, order (itemId, count)
    var orders = hashMapOf<String, HashMap<String, Long>>()

    companion object {
        fun getUser(groupId: String, userId: String): Task<User> {
            return Firebase.database.getReference("users/$groupId/$userId").get().continueWith { userTask ->
                return@continueWith userTask.result.getValue(User::class.java)
            }
        }
    }
}

class Item {
    var name = ""
    var price = 0f
}

class Shop {
    var name = ""
    var address = ""
    var picture = ""

    // itemId, item
    var items = mapOf<String, Item>()

    companion object {
        fun getShop(shopId: String): Task<Shop> {
            return Firebase.database.getReference("shops/$shopId").get().continueWith { task ->
                return@continueWith task.result.getValue(Shop::class.java)
            }
        }

        private fun addMaps(a: Map<String, Long>, b: Map<String, Long>): HashMap<String, Long> {
            return b.map { (key, value) ->
                key to (a[key]?.plus(value) ?: value)
            }.toMap() as HashMap<String, Long>
        }

        /**
         * Retrieves all open and fulfilled orders
         * @param groupId Only returns orders placed by members of this group
         * @param shopId Only returns orders placed for this shop
         * @return A [Pair] of open and fulfilled orders
         */
        @Suppress("UNCHECKED_CAST")
        fun getOrders(groupId: String, shopId: String): Task<Pair<HashMap<String, Long>, HashMap<String, Long>>> {
            return Firebase.database.getReference("users/$groupId").get().continueWith { task ->
                var orders = hashMapOf<String, Long>()
                var fulfilled = hashMapOf<String, Long>()

                val users = task.result.value ?: return@continueWith orders to fulfilled

                for (user in (users as Map<String, Map<*, *>>).values) {
                    if (user.containsKey("orders")) {
                        val userOrders = user["orders"] as Map<String, Map<String, Long>>
                        orders = addMaps(orders, userOrders[shopId] ?: mapOf())
                    }

                    if (user.containsKey("fulfilled")) {
                        val userFulfilled = user["fulfilled"] as Map<String, Map<String, Long>>
                        fulfilled = addMaps(fulfilled, userFulfilled[shopId] ?: mapOf())
                    }
                }

                return@continueWith orders to fulfilled
            }
        }

        /**
         * Retrieves all open orders
         * @param groupId Only returns orders placed by members of this group
         * @param shopId Only returns orders placed for this shop
         */
        @Suppress("UNCHECKED_CAST")
        fun getOpenOrders(groupId: String, shopId: String): Task<Map<String, Long>> {
            return Firebase.database.getReference("users/$groupId").get().continueWith { task ->
                var orders = hashMapOf<String, Long>()

                val users = task.result.value ?: return@continueWith orders

                for (user in (users as Map<String, Map<*, *>>).values) {
                    val userOrders = (user["orders"] ?: continue) as HashMap<String, HashMap<String, Long>>
                    val userFulfilled = (user["fulfilled"] ?: hashMapOf<String, HashMap<String, Long>>()) as HashMap<String, HashMap<String, Long>>

                    val order = userOrders[shopId] ?: continue
                    val fulfilled = userFulfilled[shopId] ?: hashMapOf()

                    for ((key, value) in order) {
                        orders[key] = value.toInt() + (orders[key] ?: 0) - (fulfilled[key]?.toInt() ?: 0)
                    }
                }

                return@continueWith orders
            }
        }

        fun processOrder(groupId: String, userId: String, shopId: String, order: HashMap<String, Long>) {
            Firebase.database.getReference("users/$groupId/$userId/orders/$shopId").setValue(order)
        }

        fun setFulfilled(groupId: String, userId: String, shopId: String, fulfilled: HashMap<String, Long>) {
            Firebase.database.getReference("users/$groupId/$userId/fulfilled/$shopId").setValue(fulfilled)
        }
    }
}

/*
class Shoping {
    companion object {
        lateinit var database: FirebaseDatabase
        lateinit var orders: HashMap<String, Map<String, Int>>

        private fun <K, V> loadStructure(path: String): Task<HashMap<K, V>> {
            return database.getReference(path).get().continueWith { task ->
                if (task.isSuccessful && task.result.value != null) {
                    @Suppress("UNCHECKED_CAST")
                    return@continueWith task.result.value as HashMap<K, V>
                } else {
                    return@continueWith hashMapOf<K, V>()
                }
            }
        }

        fun getAll(): Task<HashMap<String, Shoping>> {
            return loadStructure("shops")
        }

        fun getOrders(): Task<HashMap<String, Map<String, Int>>> {
            return loadStructure("shops/$SHOP_ID/orders")
        }

        fun getOrder(uid: String): Task<HashMap<String, Int>> {
            return loadStructure("users/$uid/$SHOP_ID/order")
        }

        fun processOrder(userId: String, order: HashMap<String, Int>) {
            database.getReference("users/$GROUP_ID/$userId/orders/$SHOP_ID").setValue(order)
        }

        fun getItems(): Task<HashMap<String, Item2>> {
            return database.getReference("shops/$SHOP_ID/items").get().continueWith { task ->
                if (task.isSuccessful) {
                    val idllddl = task.result.getValue(User::class.java) ?: return@continueWith null
                    val result = task.result.value as HashMap<*, *>
                    val jsonString = JSONObject(result).toString()
                    return@continueWith Json.decodeFromString<HashMap<String, Item2>>(jsonString)
                } else return@continueWith null
            }
        }

        fun getItem(itemId: String): Task<Item2> {
            return database.getReference("shops/$SHOP_ID/items/$itemId").get().continueWith { task ->
                if (task.isSuccessful) {
                    val result = task.result.value as HashMap<*, *>
                    val jsonString = JSONObject(result).toString()
                    return@continueWith Json.decodeFromString<Item2>(jsonString)
                } else return@continueWith null
            }
        }
    }
}
*/