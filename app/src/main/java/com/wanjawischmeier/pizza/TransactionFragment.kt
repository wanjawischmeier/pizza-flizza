package com.wanjawischmeier.pizza

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ListView
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import com.google.android.gms.tasks.Task


class TransactionFragment : CallableFragment() {
    private lateinit var main: MainActivity
    private lateinit var fulfilled: HashMap<Pair<String, String>, Order>
    private lateinit var transactionsList: ListView
    private lateinit var gridViewAdapter: TransactionListViewAdapter

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

        gridViewAdapter = TransactionListViewAdapter(context ?: return null, main, ArrayList())
        transactionsList.adapter = gridViewAdapter

        val userOrder = main.users[main.userId]?.orders?.get(SHOP_ID)
        if (userOrder != null) {
            refreshOrder(main.userId to "", userOrder, true)
        }

        fulfilled = Shop.getFulfilled(SHOP_ID, main.users)

        for ((ids, order) in fulfilled) {
            refreshOrder(ids, order)
        }

        main.swipeRefreshLayout.isRefreshing = false
        refreshNoItemsHint()
        return null
    }

    private fun refreshOrder(ids: Pair<String, String>, order: Order, openOrder: Boolean = false) {
        if (order.isNotEmpty()) {
            var userId = ids.first
            val transactionType = if (openOrder) {
                TransactionType.OPEN
            } else {
                if (ids.second == main.userId) {
                    TransactionType.FULFILLED_BY_USER
                } else {
                    userId = ids.second
                    TransactionType.TO_BE_PAID
                }
            }


            gridViewAdapter.add(TransactionModel(
                ids,
                transactionType,
                getPseudoUsername(userId),
                order
            ))
        }
    }

    private fun refreshNoItemsHint() {
        val noItems = view?.findViewById<TextView>(R.id.no_items_text)?.parent
        if (noItems != null) (view as ViewGroup).removeView(noItems as View)

        if (gridViewAdapter.isEmpty) {
            val inflated = layoutInflater.inflate(R.layout.card_no_items, view as ViewGroup)
            inflated.findViewById<TextView>(R.id.no_items_text).text = getString(R.string.info_no_transactions)
        }
    }

    private fun getPseudoUsername(userId: String): String {
        val email = main.users[userId]?.email ?: return getString(R.string.name_user_unknown)
        return email.split('@')[0]
    }

    fun accept(view: View) {
        val parent = view.parent.parent as ConstraintLayout
        val ids = gridViewAdapter.getIdsByView(parent) ?: return
        val (userId, fulfillerId) = ids
        val item = gridViewAdapter.getItemByIds(ids) ?: return

        if (item.transactionType == TransactionType.OPEN) {
            Shop.clearOrder(GROUP_ID, userId, SHOP_ID)
        } else {
            Shop.clearFulfilledOrder(GROUP_ID, userId, SHOP_ID, fulfillerId)
        }

        gridViewAdapter.remove(ids)
        refreshNoItemsHint()
    }
}