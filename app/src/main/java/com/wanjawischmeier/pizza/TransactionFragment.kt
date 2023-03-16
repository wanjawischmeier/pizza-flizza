package com.wanjawischmeier.pizza

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.isGone
import com.google.android.gms.tasks.Task
import java.text.SimpleDateFormat


class TransactionFragment : CallableFragment() {
    private lateinit var main: MainActivity
    private lateinit var fulfilled: HashMap<Pair<String, String>, Order>
    private lateinit var transactionsList: LinearLayout
    private var transactionChildren = hashMapOf<ConstraintLayout, Pair<String, String>>()
    private var userView: ConstraintLayout? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        main = activity as MainActivity
        return inflater.inflate(R.layout.fragment_transaction, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        transactionsList = (view as ViewGroup).findViewById(R.id.transactions_list)
    }

    override fun onShow(): Task<Unit>? {
        topBubbleVisible = false
        bottomLayoutVisible = false

        val userOrder = main.users[main.userId]?.orders?.get(SHOP_ID)
        refreshOrder(Pair(main.userId, main.userId), userOrder, true)

        fulfilled = Shop.getFulfilled(SHOP_ID, main.users)

        for ((view, ids) in transactionChildren) {
            if (!fulfilled.containsKey(ids)) {
                transactionChildren.remove(view)
                transactionsList.removeView(view)
            }
        }

        for ((ids, order) in fulfilled) {
            refreshOrder(ids, order)
        }

        refreshNoItemsHint()
        return null
    }

    @SuppressLint("InflateParams")
    private fun refreshOrder(ids: Pair<String, String>, order: Order?, openOrder: Boolean = false) {
        val fulfillerId = ids.second

        if (order?.isNotEmpty() == true) {
            var total = 0f
            var content = ""
            var date = 0L

            // get latest change
            order.values.forEach { item -> if (item[ITEM_TIME] > date) date = item[ITEM_TIME] }
            val dateFormatter = SimpleDateFormat("dd.MM.yy HH:mm", SimpleDateFormat.getAvailableLocales()[0])

            for ((itemId, itemInfo) in order) {
                val item = main.shop.items[itemId]
                val name = item?.name ?: "Unknown Name"
                val count = itemInfo[ITEM_COUNT]

                total += (item?.price ?: 0f) * itemInfo[ITEM_COUNT]
                content += "- ${count}x $name\n"
            }

            activity?.runOnUiThread {
                val transactionView = getViewFromUserIds(ids, openOrder)
                val outlineId = if (fulfillerId == main.userId) {
                    if (openOrder) R.drawable.order_open_outline
                    else null
                } else R.drawable.order_to_pay_outline
                transactionView.findViewById<View>(R.id.transaction_payed_button).isGone = fulfillerId != main.userId || openOrder
                transactionView.findViewById<TextView>(R.id.transaction_name)?.text = getPseudoUsername(fulfillerId)
                transactionView.findViewById<TextView>(R.id.transaction_date)?.text = dateFormatter.format(date)
                transactionView.findViewById<TextView>(R.id.transaction_price_text)?.text = getString(R.string.price_format).format(total)
                transactionView.findViewById<TextView>(R.id.transaction_content)?.text = content.trim()
                transactionView.findViewById<View>(R.id.transaction_status_ring).setBackgroundResource(outlineId ?: return@runOnUiThread)
            }
        } else {
            if (fulfillerId == main.userId && !transactionChildren.containsValue(ids)) {
                transactionsList.removeView(userView)
                userView = null
            } else {
                if (transactionChildren.containsValue(ids)) {
                    // view already inflated, so no need to run on ui thread
                    val transactionView = getViewFromUserIds(ids)
                    transactionChildren -= transactionView
                    transactionsList.removeView(transactionView)
                }
            }
        }
    }

    @SuppressLint("InflateParams")
    private fun getViewFromUserIds(ids: Pair<String, String>, addToUser: Boolean = false): ConstraintLayout {
        if (addToUser && userView != null) {
            return userView!!
        }

        val matching = transactionChildren.filterValues { _ids -> _ids == ids  }.keys.iterator()

        return if (matching.hasNext() && !addToUser) {
            matching.next()
        } else {
            val inflated = layoutInflater.inflate(R.layout.card_transactions, null) as ConstraintLayout
            transactionsList.addView(inflated)

            if (addToUser) {
                userView = inflated
            } else {
                transactionChildren += inflated to ids
            }
            inflated
        }
    }

    override fun onHide() {
        // TODO: Not yet implemented
    }

    private fun refreshNoItemsHint() {
        val noItems = view?.findViewById<TextView>(R.id.no_items_text)?.parent
        if (noItems != null) (view as ViewGroup).removeView(noItems as View)

        if (transactionChildren.isEmpty() && userView == null) {
            val inflated = layoutInflater.inflate(R.layout.card_no_items, view as ViewGroup)
            inflated.findViewById<TextView>(R.id.no_items_text).text = getString(R.string.info_no_transactions)
        }
    }

    private fun getPseudoUsername(userId: String): String {
        val email = main.users[userId]?.email ?: return "Unknown Username"
        return email.split('@')[0]
    }

    fun accept(view: View) {
        val parent = view.parent.parent as ConstraintLayout
        val ids = transactionChildren[parent] ?: return
        val (userId, fulfillerId) = ids
        Shop.clearFulfilledOrder(GROUP_ID, userId, SHOP_ID, fulfillerId)

        transactionsList.removeView(parent)
        transactionChildren.remove(parent)

        refreshNoItemsHint()
    }
}