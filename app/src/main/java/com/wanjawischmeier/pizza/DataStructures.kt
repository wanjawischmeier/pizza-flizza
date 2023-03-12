package com.wanjawischmeier.pizza

import com.google.android.gms.tasks.Task
import com.google.firebase.database.ktx.database
import com.google.firebase.ktx.Firebase

// userId, user
typealias Users = Map<String, User>
// itemId, count
typealias Order = HashMap<String, Long>
// fulfillerId, order
typealias FulfilledOrder = HashMap<String, Order>

class User {
    var name = ""
    var creationDate = ""

    // shopId, order
    var orders = hashMapOf<String, Order>()
    // shopId, fulfilledOrder
    var fulfilled = hashMapOf<String, FulfilledOrder>()

    companion object {
        fun getUsers(groupId: String): Task<Users> {
            return Firebase.database.getReference("users/$groupId").get().continueWith { userTask ->
                return@continueWith userTask.result.children.mapNotNull {
                    val key = it.key ?: return@mapNotNull null
                    val value = it.getValue(User::class.java) ?: return@mapNotNull null
                    return@mapNotNull key to value
                }.toMap()
            }
        }

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

        fun getOpenOrders(users: Users, shopId: String): HashMap<String, Order> {
            val open = hashMapOf<String, Order>()

            for ((userId, user) in users) {
                val order = user.orders[shopId] ?: continue
                val fulfilled = user.fulfilled[shopId] ?: hashMapOf()

                for ((itemId, count) in order) {
                    var fulfilledCount = 0L

                    for (items in fulfilled.values) {
                        fulfilledCount += items[itemId] ?: 0L
                    }

                    if (count - fulfilledCount > 0) {
                        val newOrder = hashMapOf(itemId to count - fulfilledCount)
                        open[userId] = (open[userId]?.plus(newOrder) ?: newOrder) as HashMap<String, Long>
                    }
                }
            }

            return open
        }

        @Suppress("UNCHECKED_CAST")
        fun getFulfilled(groupId: String, userId: String, shopId: String): Task<HashMap<String, Order>> {
            return Firebase.database.getReference("users/$groupId/$userId/fulfilled/$shopId").get().continueWith {
                return@continueWith (it.result.value ?: hashMapOf<String, Order>()) as HashMap<String, Order>
            }
        }

        fun processOrder(groupId: String, userId: String, shopId: String, order: Order): Task<Void> {
            return Firebase.database.getReference("users/$groupId/$userId/orders/$shopId").setValue(order)
        }

        fun fulfillItem(users: Users, groupId: String, userId: String, shopId: String, fulfillerId: String, itemId: String, count: Long): Task<Void> {
            val currentCount = users[userId]?.fulfilled?.get(shopId)?.get(fulfillerId)?.get(itemId) ?: 0L
            return Firebase.database.getReference("users/$groupId/$userId/fulfilled/$shopId/$fulfillerId/$itemId").setValue(currentCount + count)
        }

        fun clearFulfilledOrder(users: Users, order: Order, groupId: String, userId: String, shopId: String, fulfillerId: String) {
            Firebase.database.getReference("users/$groupId/$userId/fulfilled/$shopId/$fulfillerId").removeValue().continueWith {
                for ((itemId, count) in order) {
                    val ref = Firebase.database.getReference("users/$groupId/$userId/orders/$shopId/$itemId")
                    val new = (users[userId]?.orders?.get(shopId)?.get(itemId) ?: 0L) - count

                    if (new > 0) {
                        ref.setValue(new)
                    } else {
                        ref.removeValue()
                    }
                }
            }
        }
    }
}