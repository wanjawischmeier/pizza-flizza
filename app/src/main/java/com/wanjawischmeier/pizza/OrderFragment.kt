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

class OrderFragment : CallableFragment() {
    override var showTopBubble = true
    override var showBottomLayout = true

    private var order: HashMap<String, Int> = hashMapOf()
    private var orderChildren: Map<View, String> = mapOf()
    private var total = 0f

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_order, container, false)
    }

    @Nullable
    @SuppressLint("InflateParams")
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        val priceView = topBubble.findViewById<TextView>(R.id.top_bubble_text)
        val itemsList = view.findViewById<LinearLayout>(R.id.items_list)

        Shop.getOrder(Firebase.auth.currentUser?.uid ?: return).addOnCompleteListener { task ->
            order = task.result ?: return@addOnCompleteListener

            Shop.getItems().addOnCompleteListener { itemsTask ->
                for (itemOrder in itemsTask.result ?: return@addOnCompleteListener) {
                    val itemId = itemOrder.key
                    val item = itemOrder.value
                    var count = 0
                    if (order.containsKey(itemId)) {
                        count = order[itemId]!!
                    }

                    activity?.runOnUiThread {
                        val inflated = layoutInflater.inflate(R.layout.card_order, null)

                        inflated.findViewById<TextView>(R.id.order_name).text = item.name
                        inflated.findViewById<TextView>(R.id.order_price).text = item.price.toString()
                        inflated.findViewById<TextView>(R.id.order_count).text = count.toString()

                        orderChildren = orderChildren + Pair(inflated, itemOrder.key)
                        total = round((total + item.price * count) * 100) / 100
                        priceView.text = getString(R.string.price_format).format(total)
                        itemsList.addView(inflated)
                    }
                }
            }
        }
    }

    override fun onShow() {

    }

    fun modifyCount(view: View, change: Int) {
        val countView = (view.parent as ViewGroup).findViewById<TextView>(R.id.order_count)
        val count = countView.text.toString().toInt() + change
        if (count < 0 || count > 99) return
        countView.text = count.toString()

        val itemId = orderChildren[view.parent.parent as View] ?: return
        Shop.getItem(itemId).addOnCompleteListener { task ->
            val priceView = topBubble.findViewById<TextView>(R.id.top_bubble_text)
            total = round((total + task.result.price * change) * 100) / 100
            priceView.text = getString(R.string.price_format).format(total)
        }

        order[itemId] = count
    }

    fun placeOrder() {
        order = order.filterValues { it != 0 } as HashMap<String, Int>
        Shop.processOrder(Firebase.auth.currentUser?.uid ?: return, order)
    }
}