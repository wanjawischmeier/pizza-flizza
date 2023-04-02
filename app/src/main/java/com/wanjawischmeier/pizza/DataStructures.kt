package com.wanjawischmeier.pizza

import android.os.Build
import com.google.android.gms.tasks.Task
import com.google.firebase.database.DatabaseException
import com.google.firebase.database.ktx.database
import com.google.firebase.ktx.Firebase
import java.util.*
import kotlin.collections.List

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
    var priorities = listOf<List<String>>()

    companion object {
        fun getUsers(groupId: String): Task<Users> {
            return Firebase.database.getReference("users/$groupId").get().continueWith { userTask ->
                return@continueWith userTask.result.children.mapNotNull {
                    val uid = it.key ?: return@mapNotNull null
                    val user = it.getValue(User::class.java) ?: return@mapNotNull null

                    // clear old orders
                    for ((shopId, order) in user.orders)
                    {
                        for ((itemId, item) in order) {
                            val itemDate = Date(item[ITEM_TIME])
                            val currentDate = Date()

                            val differentDate = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                val calendar = Calendar.Builder().setInstant(itemDate).build()
                                calendar.get(Calendar.DAY_OF_YEAR) != Calendar.getInstance().get(Calendar.DAY_OF_YEAR)
                            } else {
                                @Suppress("DEPRECATION")
                                currentDate.day != itemDate.day
                            }

                            if (differentDate) {
                                Shop.clearItem(groupId, uid, shopId, itemId)
                            }
                        }
                    }

                    return@mapNotNull uid to user
                }.toMap()
            }
        }

        fun getUser(groupId: String, userId: String): Task<User> {
            return Firebase.database.getReference("users/$groupId/$userId").get().continueWith {
                return@continueWith it.result.getValue(User::class.java)
            }
        }

        fun setPriorities(groupId: String, userId: String, proritizedItems: List<List<String>>): Task<Void> {
            return Firebase.database.getReference("users/$groupId/$userId/priorities").setValue(proritizedItems)
        }
    }
}

class Shop {
    var name = ""
    var address = ""
    var picture = ""

    // itemId, item
    var items = mapOf<String, Item>()

    class Item {
        var name = ""
        var price = 0f
        var type = 0

        enum class Type {
            HEARTY, SWEET, SIDE_DISH, IRRELEVANT
        }
    }

    companion object {
        fun getShop(shopId: String): Task<Shop?> {
            return Firebase.database.getReference("shops/$shopId").get().continueWith {
                if (it.isSuccessful) {
                    return@continueWith it.result.getValue(Shop::class.java)
                } else {
                    return@continueWith null
                }
            }
        }

        fun getItemType(shop: Shop, itemType: Item.Type): Map<String, Item> {
            return shop.items.filter { it.value.type == itemType.ordinal }.toMap()
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

            if (currentOpen == count) {
                users[userId]?.orders?.get(shopId)?.remove(itemId)
            } else {
                users[userId]?.orders?.get(shopId)?.get(itemId)?.set(ITEM_COUNT, currentOpen - count)
            }

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

        fun clearItem(groupId: String, userId: String, shopId: String, itemId: String): Task<Void> {
            return Firebase.database.getReference("users/$groupId/$userId/orders/$shopId/$itemId").removeValue()
        }

        fun clearFulfilledOrder(groupId: String, userId: String, shopId: String, fulfillerId: String): Task<Void> {
            return Firebase.database.getReference("users/$groupId/$userId/fulfilled/$shopId/$fulfillerId").removeValue()
        }
    }
}

class Database {
    enum class VersionHintType {
        INFO, WARNING, ERROR, OBSOLETE, DISABLED
    }

    class VersionHint {
        val type = 0
        val message = ""
    }

    companion object {
        fun getVersionHint(version: Int): Task<VersionHint?> {
            return Firebase.database.getReference("version_hints/$version").get().continueWith {
                if (it.isSuccessful) {
                    return@continueWith try {
                        it.result.getValue(VersionHint::class.java)
                    }
                    catch (_: DatabaseException) {
                        null
                    }
                } else {
                    return@continueWith null
                }
            }
        }
    }
}