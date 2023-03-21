package com.wanjawischmeier.pizza

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.GridView
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import com.google.android.gms.tasks.Task
import java.util.*
import kotlin.math.max
import kotlin.math.min
import kotlin.math.round


const val GROUP_ID = "prenski_12"
const val SHOP_ID = "penny_burgtor"

class OrderFragment : CallableFragment() {
    private lateinit var gridViewAdapter: OrderGridViewAdapter
    private lateinit var itemsGrid: GridView
    private lateinit var priceView: TextView
    private lateinit var main: MainActivity
    private lateinit var order: Order
    private var total = 0f
    private var oldTotal = 0f

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        priceView = topBubble.findViewById(R.id.top_bubble_text)
        main = activity as MainActivity
        return inflater.inflate(R.layout.fragment_order, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        itemsGrid = view.findViewById(R.id.items_grid)

        main.swipeRefreshLayout.setOnChildScrollUpCallback { _, _ ->
            itemsGrid.canScrollVertically(-1)
        }
    }

    @SuppressLint("DiscouragedApi")
    override fun onShow(): Task<Unit> {
        bottomLayoutVisible = false
        topBubbleVisible = true
        total = 0f

        val items = main.shop.items

        return User.getUser(GROUP_ID, main.userId).continueWith {
            order = it.result.orders[SHOP_ID] ?: hashMapOf()

            // TODO: manage context being null
            gridViewAdapter = OrderGridViewAdapter(context!!, ArrayList<OrderModel>())
            itemsGrid.adapter = gridViewAdapter

            for ((itemId, item) in items.toSortedMap()) {
                if (gridViewAdapter.contains(itemId)) continue
                val count = order[itemId]?.get(ITEM_COUNT) ?: 0L
                total = round((total + item.price * count) * 100) / 100

                val imageId = resources.getIdentifier(itemId, "drawable", context!!.packageName)
                gridViewAdapter.add(OrderModel(
                    itemId,
                    item.name,
                    item.price,
                    count,
                    if (imageId == 0) {
                        R.drawable.baeckerkroenung
                    } else {
                        imageId
                    }
                ))
            }

            priceView.text = getString(R.string.price_format).format(total)
            oldTotal = total
        }
    }

    fun modifyCount(view: View, change: Long) {
        val parent = view.parent.parent.parent as ConstraintLayout
        val itemModel = gridViewAdapter.getItemByView(parent) ?: return
        val itemId = itemModel.id
        val item = main.shop.items[itemId] ?: return

        itemModel.count = max(0, min(99, itemModel.count + change))
        total = max(0f, min(99f, round((total + item.price * change) * 100) / 100))
        priceView.text = getString(R.string.price_format).format(total)
        bottomLayoutVisible = total != oldTotal

        order[itemId] = mutableListOf(itemModel.count, Calendar.getInstance().time.time)
        gridViewAdapter.notifyDataSetChanged()
    }

    fun placeOrder() {
        main.swipeRefreshLayout.isRefreshing = true

        order = order.filterValues { it[ITEM_COUNT] != 0L } as Order
        Shop.processOrder(GROUP_ID, main.userId, SHOP_ID, order).continueWith {
            main.swipeRefreshLayout.isRefreshing = false
            bottomLayoutVisible = false
        }
    }
}