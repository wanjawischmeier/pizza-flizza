package com.wanjawischmeier.pizza

import android.os.Build
import com.google.android.gms.tasks.Task
import com.google.firebase.database.DatabaseException
import com.google.firebase.database.ktx.database
import com.google.firebase.database.ktx.getValue
import com.google.firebase.ktx.Firebase
import java.util.*

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
        fun getUsers(groupId: String): Task<Users?> {
            return Firebase.database.getReference("users/$groupId").get().continueWith continueGroup@ { groupTask ->
                if (!groupTask.isSuccessful) return@continueGroup null

                return@continueGroup groupTask.result.children.mapNotNull { userEntry ->
                    val uid = userEntry.key ?: return@mapNotNull null
                    val user = userEntry.getValue(User::class.java) ?: return@mapNotNull null

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

        fun getUser(groupId: String, userId: String): Task<User?> {
            return Firebase.database.getReference("users/$groupId/$userId").get().continueWith continueUser@ { userTask ->
                return@continueUser if (userTask.isSuccessful) {
                    userTask.result.getValue(User::class.java)
                } else null
            }
        }

        fun setPreferences(groupId: String, userId: String, preferredItems: List<List<String>>): Task<Void> {
            return Firebase.database.getReference("users/$groupId/$userId/preferences").setValue(preferredItems)
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
            return Firebase.database.getReference("shops/$shopId").get().continueWith continueShop@ { shopTask ->
                return@continueShop if (shopTask.isSuccessful) {
                    shopTask.result.getValue(Shop::class.java)
                } else null
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
            }.continueWith continueModify@ { modifyItemTask ->
                if (userId == fulfillerId) return@continueModify modifyItemTask

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
        INFO, WARNING, ERROR, DEPRICATED, DISABLED
    }

    class VersionHint {
        var type = 0
        val message = ""
    }

    companion object {
        fun getVersionHint(version: Int, callback: (VersionHint?) -> Unit) {
            var hint: VersionHint? = null
            // I'm really sorry for the call stack that is about to be summoned here
            Firebase.database.getReference("version_hints/depricated").get().continueWith { depricatedTask ->
                if (depricatedTask.isSuccessful && (depricatedTask.result.getValue<Long>() ?: 0) >= version) {
                    hint = VersionHint()
                    hint?.type = VersionHintType.DEPRICATED.ordinal
                }

                Firebase.database.getReference("version_hints/disabled").get().continueWith { disabledTask ->
                    if (disabledTask.isSuccessful && (disabledTask.result.getValue<Long>() ?: 0) >= version) {
                        hint = VersionHint()
                        hint?.type = VersionHintType.DISABLED.ordinal
                    }

                    Firebase.database.getReference("version_hints/$version").get().continueWith { versionTask ->
                        if (versionTask.isSuccessful) {
                            try {
                                val value = versionTask.result.getValue(VersionHint::class.java)
                                if (value != null) {
                                    hint = value
                                }
                            }
                            catch (_: DatabaseException) {}
                        }

                        callback(hint)
                    }
                }
            }
        }
    }
}