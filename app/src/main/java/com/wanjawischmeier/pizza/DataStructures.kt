package com.wanjawischmeier.pizza

import com.google.android.gms.tasks.Task
import com.google.firebase.database.ktx.database
import com.google.firebase.ktx.Firebase

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

        fun processOrder(groupId: String, userId: String, shopId: String, order: HashMap<String, Long>) {
            Firebase.database.getReference("users/$groupId/$userId/orders/$shopId").setValue(order)
        }

        fun setFulfilled(groupId: String, userId: String, shopId: String, fulfilled: HashMap<String, Long>) {
            Firebase.database.getReference("users/$groupId/$userId/fulfilled/$shopId").setValue(fulfilled)
        }
    }
}