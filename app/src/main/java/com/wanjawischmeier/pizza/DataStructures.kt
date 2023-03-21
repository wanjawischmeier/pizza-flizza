package com.wanjawischmeier.pizza

import com.google.android.gms.tasks.Task
import com.google.firebase.database.ktx.database
import com.google.firebase.ktx.Firebase
import java.util.Calendar

// userId, user
typealias Users = Map<String, User>
// itemId, count
typealias Order = HashMap<String, MutableList<Long>>
// fulfillerId, order
typealias FulfilledOrder = HashMap<String, Order>

const val ITEM_COUNT = 0
const val ITEM_TIME = 1

class User {
    var email = ""
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
                for ((itemId, count) in user.orders[shopId] ?: continue) {
                    val newOrder = hashMapOf(userId to count)
                    open[itemId] = (open[itemId]?.plus(newOrder) ?: newOrder) as Order
                }
            }

            return open
        }

        @Suppress("UNCHECKED_CAST")
        fun getFulfilled(shopId: String, users: Users): HashMap<Pair<String, String>, Order> {
            val fulfilled = hashMapOf<Pair<String, String>, Order>()

            for ((userId, user) in users) {
                for ((fulfillerId, order) in user.fulfilled[shopId] ?: continue) {
                    fulfilled += (userId to fulfillerId) to order
                }
            }

            return fulfilled
        }

        fun processOrder(groupId: String, userId: String, shopId: String, order: Order): Task<Void> {
            return Firebase.database.getReference("users/$groupId/$userId/orders/$shopId").setValue(order)
        }

        fun fulfillItem(users: Users, groupId: String, userId: String, shopId: String, fulfillerId: String, itemId: String, count: Long): Task<Task<Void>> {
            val currentOpen = users[userId]?.orders?.get(shopId)?.get(itemId)?.get(ITEM_COUNT) ?: 0L
            val currentFulfilled = users[userId]?.fulfilled?.get(shopId)?.get(fulfillerId)?.get(itemId)?.get(ITEM_COUNT) ?: 0L
            val time = Calendar.getInstance().time.time

            return if (currentOpen - count <= 0) {
                Firebase.database.getReference("users/$groupId/$userId/orders/$shopId/$itemId").removeValue()
            } else {
                Firebase.database.getReference("users/$groupId/$userId/orders/$shopId/$itemId").setValue(
                    listOf(currentOpen - count, time)
                )
            }.continueWith { task ->
                if (userId == fulfillerId) return@continueWith task

                Firebase.database.getReference("users/$groupId/$userId/fulfilled/$shopId/$fulfillerId/$itemId").setValue(
                    listOf(currentFulfilled + count, time)
                )
            }
        }

        fun clearOrder(groupId: String, userId: String, shopId: String): Task<Void> {
            return Firebase.database.getReference("users/$groupId/$userId/orders/$shopId").removeValue()
        }

        fun clearFulfilledOrder(groupId: String, userId: String, shopId: String, fulfillerId: String): Task<Void> {
            return Firebase.database.getReference("users/$groupId/$userId/fulfilled/$shopId/$fulfillerId").removeValue()
        }
    }
}