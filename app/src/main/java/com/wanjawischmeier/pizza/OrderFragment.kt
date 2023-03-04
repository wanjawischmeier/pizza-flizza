package com.wanjawischmeier.pizza

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.annotation.Nullable
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase
import kotlin.math.round

const val GROUP_ID = "prenski_12"
const val SHOP_ID = "penny_burgtor"

class OrderFragment : CallableFragment() {
    override var showTopBubble = true
    override var showBottomLayout = true

    private var orderChildren: Map<View, String> = mapOf()
    private lateinit var shop: Shop
    private lateinit var order: HashMap<String, Long>
    private lateinit var priceView: TextView
    private var total = 0f

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        priceView = topBubble.findViewById(R.id.top_bubble_text)
        return inflater.inflate(R.layout.fragment_order, container, false)
    }

    @Nullable
    @SuppressLint("InflateParams")
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        Shop.getShop(SHOP_ID).continueWith { shopTask ->
            shop = shopTask.result

            val userId = Firebase.auth.currentUser?.uid ?: return@continueWith
            User.getUser(GROUP_ID, userId).continueWith { userTask ->
                order = userTask.result.orders[SHOP_ID] ?: hashMapOf()
                inflateItems(view)
            }
        }
    }

    @SuppressLint("InflateParams")
    private fun inflateItems(view: View) {
        val itemsList = view.findViewById<LinearLayout>(R.id.items_list)

        val items = shop.items
        for ((itemId, item) in items) {
            // Check if item has already been ordered
            val count = order[itemId] ?: 0
            total = round((total + item.price * count) * 100) / 100

            // Avoid parralel inflations
            activity?.runOnUiThread {
                val inflated = layoutInflater.inflate(R.layout.card_order, null)

                inflated.findViewById<TextView>(R.id.order_name).text = item.name
                inflated.findViewById<TextView>(R.id.order_price).text = item.price.toString()
                inflated.findViewById<TextView>(R.id.order_count).text = count.toString()

                orderChildren = orderChildren + (inflated to itemId)
                itemsList.addView(inflated)
            }
        }

        priceView.text = getString(R.string.price_format).format(total)
    }

    fun modifyCount(view: View, change: Long) {
        val countView = (view.parent as ViewGroup).findViewById<TextView>(R.id.order_count)
        val count = countView.text.toString().toLong() + change
        if (count < 0 || count > 99) return
        countView.text = count.toString()

        val itemId = orderChildren[view.parent.parent as View] ?: return
        val item = shop.items[itemId] ?: return
        total = round((total + item.price * change) * 100) / 100
        priceView.text = getString(R.string.price_format).format(total)

        order[itemId] = count
    }

    fun placeOrder() {
        order = order.filterValues { it != 0L } as HashMap<String, Long>
        Shop.processOrder(GROUP_ID, Firebase.auth.currentUser?.uid ?: return, SHOP_ID, order)
    }
}