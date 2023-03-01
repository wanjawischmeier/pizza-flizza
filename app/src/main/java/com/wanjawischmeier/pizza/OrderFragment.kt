package com.wanjawischmeier.pizza

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.LinearLayout
import androidx.annotation.Nullable
import androidx.constraintlayout.widget.ConstraintLayout


class OrderFragment : CallableFragment() {
    lateinit var orderBar: ConstraintLayout

    @Nullable
    override fun onCreateView(
        inflater: LayoutInflater,
        @Nullable container: ViewGroup?,
        @Nullable savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_order, container, false)
    }

    @Nullable
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        orderBar = view.findViewById(R.id.order_layout)
        orderBar.viewTreeObserver.addOnGlobalLayoutListener(
            object : ViewTreeObserver.OnGlobalLayoutListener {
                override fun onGlobalLayout() {
                    orderBar.y += orderBar.height
                    orderBar.animate()
                        .yBy(-orderBar.height.toFloat())
                        .duration = 100

                    orderBar.viewTreeObserver.removeOnGlobalLayoutListener(this)
                }
            })


        val itemsList = view.findViewById<LinearLayout>(R.id.items_list)

        for (i in 0..10) {
            layoutInflater.inflate(R.layout.order_card, itemsList)
        }
    }

    override fun onShow(topBubble: ConstraintLayout) {
        topBubble.animate()
            .alpha(1f)
            .duration = 100

        orderBar.y += orderBar.height
        orderBar.animate()
            .yBy(-orderBar.height.toFloat())
            .duration = 100
    }
}