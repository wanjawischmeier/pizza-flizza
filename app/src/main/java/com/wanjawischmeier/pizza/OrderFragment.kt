package com.wanjawischmeier.pizza

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.annotation.Nullable


class OrderFragment : CallableFragment() {
    override var showTopBubble = true
    override var showBottomLayout = true

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_order, container, false)
    }

    @Nullable
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        val itemsList = view.findViewById<LinearLayout>(R.id.items_list)

        for (i in 0..10) {
            layoutInflater.inflate(R.layout.order_card, itemsList)
        }
    }
}