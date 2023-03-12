package com.wanjawischmeier.pizza

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import com.google.android.gms.tasks.Task


class TransactionFragment : CallableFragment() {
    private lateinit var main: MainActivity
    private lateinit var transactions: HashMap<String, Order>
    private lateinit var transactionsList: LinearLayout
    private var transactionChildren = hashMapOf<View, String>()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        main = activity as MainActivity
        return inflater.inflate(R.layout.fragment_transaction, container, false)
    }

    @SuppressLint("InflateParams")
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        transactionsList = (view as ViewGroup).findViewById(R.id.transactions_list)
    }

    @SuppressLint("InflateParams")
    override fun onShow(): Task<Unit> {
        topBubbleVisible = false
        bottomLayoutVisible = false

        return Shop.getFulfilled(GROUP_ID, main.userId, SHOP_ID).continueWith {
            transactions = it.result

            for ((fulfillerId, items) in transactions) {
                val name = main.users[fulfillerId]?.name ?: continue
                var total = 0f

                for ((itemId, count) in items) {
                    total += (main.shop.items[itemId]?.price ?: 0f) * count
                }

                var transactionView: View? = null

                if (transactionChildren.containsValue(fulfillerId)) {
                    for ((view, id) in transactionChildren) {
                        if (id == fulfillerId) {
                            transactionView = view
                        }
                    }
                } else {
                    activity?.runOnUiThread {
                        val inflated = layoutInflater.inflate(R.layout.card_transactions, null)

                        transactionChildren += inflated to fulfillerId
                        transactionsList.addView(inflated)
                        transactionView = inflated
                    }
                }

                transactionView?.findViewById<TextView>(R.id.transaction_name)?.text = name
                transactionView?.findViewById<TextView>(R.id.transaction_price)?.text = getString(R.string.price_format).format(total)
            }

            for ((view, fulfillerId) in transactionChildren) {
                if (!transactions.containsKey(fulfillerId)) {
                    view.animate()
                        .alpha(0f)
                        .withEndAction {
                            (view.parent as ViewGroup).removeView(view)
                            transactionChildren.remove(view)
                        }
                        .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()
                }
            }

            refreshNoItemsHint(transactionChildren.isEmpty())
        }
    }

    override fun onHide() {
        // TODO: Not yet implemented
    }

    private fun refreshNoItemsHint(visible: Boolean) {
        val noItems = view?.findViewById<TextView>(R.id.no_items_text)?.parent
        if (noItems != null) (view as ViewGroup).removeView(noItems as View)

        if (visible) {
            val inflated = layoutInflater.inflate(R.layout.card_no_items, view as ViewGroup)
            inflated.findViewById<TextView>(R.id.no_items_text).text = getString(R.string.info_no_transactions)
        }
    }

    fun accept(view: View) {
        /*
        val popupView = layoutInflater.inflate(R.layout.transaction_popup, null)

        // create the popup window
        // create the popup window
        val width = LinearLayout.LayoutParams.WRAP_CONTENT
        val height = LinearLayout.LayoutParams.WRAP_CONTENT
        val focusable = true // lets taps outside the popup also dismiss it

        val popupWindow = PopupWindow(popupView, width, height, focusable)

        // show the popup window
        // which view you pass in doesn't matter, it is only used for the window tolken
        popupWindow.showAtLocation(view, Gravity.CENTER, 0, 0)
        */

        val parent = view.parent.parent as ViewGroup
        val fulfillerId = transactionChildren[parent] ?: return
        Shop.clearFulfilledOrder(main.users, transactions[fulfillerId] ?: return, GROUP_ID, main.userId, SHOP_ID, fulfillerId)

        transactionsList.removeView(parent)
        transactionChildren.remove(parent)
        transactions.remove(fulfillerId)

        refreshNoItemsHint(transactionChildren.isEmpty())
        onShow()
    }

    fun reject(@Suppress("UNUSED_PARAMETER") view: View) {
        Toast.makeText(main, "reject", Toast.LENGTH_SHORT).show()
    }
}