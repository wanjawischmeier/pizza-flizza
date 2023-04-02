package com.wanjawischmeier.pizza

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.GridView
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import com.google.android.gms.tasks.Task
import uk.co.deanwild.materialshowcaseview.MaterialShowcaseSequence
import uk.co.deanwild.materialshowcaseview.MaterialShowcaseView
import java.util.*
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
    private lateinit var previousOrder: Order
    private lateinit var showcaseSequence: MaterialShowcaseSequence
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
        itemsGrid = view.findViewById(R.id.items_grid)
    }

    @SuppressLint("DiscouragedApi")
    override fun onShow(refresh: Boolean): Task<Unit> {
        main.scrollContainer = itemsGrid
        bottomLayoutVisible = false
        topBubbleVisible = true
        total = 0f
        previousOrder = hashMapOf()
        showcaseSequence = MaterialShowcaseSequence(activity)

        return User.getUser(GROUP_ID, main.userId).continueWith {
            order = it.result.orders[SHOP_ID] ?: hashMapOf()

            // TODO: manage context being null
            gridViewAdapter = OrderGridViewAdapter(context!!, ArrayList<OrderCard>(), showcaseSequence)
            itemsGrid.adapter = gridViewAdapter

            for ((itemId, item) in main.shop.items.toSortedMap()) {
                if (gridViewAdapter.contains(itemId)) continue
                val count = order[itemId]?.get(ITEM_COUNT) ?: 0L
                total = round((total + item.price * count) * 100) / 100

                val imageId = resources.getIdentifier(itemId, "drawable", context!!.packageName)
                gridViewAdapter.add(OrderCard(
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
            /*
            showcaseSequence.addSequenceItem(
                MaterialShowcaseView.Builder(context as Activity)
                    .setTarget(topBubble)
                    .setDismissText(R.string.tour_accept)
                    .setContentText(R.string.sample_tour_content)
                    .setDelay(resources.getInteger(R.integer.tour_delay))
                    .setDismissOnTouch(true)
                    // .singleUse("TEST5")
                    .build()
            ).start()
             */
        }
    }

    fun modifyCount(view: View, change: Long) {
        val parent = view.parent.parent.parent as ConstraintLayout
        val itemModel = gridViewAdapter.getItemByView(parent) ?: return
        val itemId = itemModel.id
        val item = main.shop.items[itemId] ?: return
        val newCount = itemModel.count + change

        // TODO: please. please. just a simple conditional statement
        if (newCount >= 0) {
            itemModel.count = min(99L, itemModel.count + change)
            total = min(99f, round((total + item.price * change) * 100) / 100)
            priceView.text = getString(R.string.price_format).format(total)
            // some simple conditions pls
            bottomLayoutVisible = true
            gridViewAdapter.notifyDataSetChanged()
            /*
            MaterialShowcaseView.Builder(context as Activity)
                .setTarget(bottomLayout.findViewById(R.id.bottom_button))
                .setDismissText(R.string.tour_accept)
                .setContentText(R.string.sample_tour_content)
                .setDelay(resources.getInteger(R.integer.tour_delay))
                .withOvalShape()
                .setShapePadding(50)
                .setDismissOnTouch(true)
                // .singleUse("TEST5")
                .show()
             */
        }

        if (itemModel.count == 0L) {
            order.remove(itemId)
        } else {
            order[itemId] = mutableListOf(itemModel.count, Calendar.getInstance().time.time)
        }
    }

    fun placeOrder() {
        main.swipeRefreshLayout.isRefreshing = true

        Shop.processOrder(GROUP_ID, main.userId, SHOP_ID, order).continueWith {
            main.swipeRefreshLayout.isRefreshing = false
            bottomLayoutVisible = false
            previousOrder = order
        }
    }
}