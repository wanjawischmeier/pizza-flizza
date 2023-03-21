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
    private lateinit var itemGridViewAdapter: ItemGridViewAdapter
    private lateinit var itemsGrid: GridView
    private lateinit var priceView: TextView
    private lateinit var main: MainActivity
    private lateinit var order: Order
    private var total = 0f

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
        bottomLayoutVisible = false
        itemsGrid = view.findViewById(R.id.items_grid)

        main.swipeRefreshLayout.setOnChildScrollUpCallback { _, _ ->
            itemsGrid.canScrollVertically(-1)
        }
    }

    @SuppressLint("DiscouragedApi")
    override fun onShow(): Task<Unit> {
        topBubbleVisible = true

        val itemArrayList: ArrayList<ItemModel> = ArrayList<ItemModel>()
        val items = main.shop.items

        total = 0f

        return User.getUser(GROUP_ID, main.userId).continueWith {
            order = it.result.orders[SHOP_ID] ?: hashMapOf()

            // TODO: manage context being null
            itemGridViewAdapter = ItemGridViewAdapter(context!!, itemArrayList)
            itemsGrid.adapter = itemGridViewAdapter

            for ((itemId, item) in items) {
                if (itemGridViewAdapter.contains(itemId)) continue
                val count = order[itemId]?.get(ITEM_COUNT) ?: 0L
                total = round((total + item.price * count) * 100) / 100

                val imageId = resources.getIdentifier(itemId, "drawable", context!!.packageName)
                itemArrayList.add(ItemModel(
                    itemId, item.name, item.price, count,
                    if (imageId == 0) R.drawable.baeckerkroenung else imageId
                ))
            }

            priceView.text = getString(R.string.price_format).format(total)
        }
    }

    override fun onHide() {
        // TODO: Not yet implemented
    }

    fun modifyCount(view: View, change: Long) {
        val parent = view.parent.parent.parent as ConstraintLayout
        val itemModel = itemGridViewAdapter.getItemByView(parent) ?: return
        val itemId = itemModel.id
        val item = main.shop.items[itemId] ?: return

        itemModel.count = max(0, min(99, itemModel.count + change))
        total = max(0f, min(99f, round((total + item.price * change) * 100) / 100))
        priceView.text = getString(R.string.price_format).format(total)
        bottomLayoutVisible = total > 0

        order[itemId] = listOf(itemModel.count, Calendar.getInstance().time.time)
        itemGridViewAdapter.notifyDataSetChanged()
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