package com.wanjawischmeier.pizza

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.annotation.Nullable
import androidx.constraintlayout.widget.ConstraintLayout


class OrderFragment : CallableFragment() {
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_order, container, false)
    }

    @Nullable
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        /*
        bottomLayout.viewTreeObserver.addOnGlobalLayoutListener(
            object : ViewTreeObserver.OnGlobalLayoutListener {
                override fun onGlobalLayout() {
                    bottomLayout.y += bottomLayout.height
                    bottomLayout.animate()
                        .yBy(-bottomLayout.height.toFloat())
                        .duration = 100

                    bottomLayout.viewTreeObserver.removeOnGlobalLayoutListener(this)
                }
            })


         */

        val itemsList = view.findViewById<LinearLayout>(R.id.items_list)

        for (i in 0..10) {
            layoutInflater.inflate(R.layout.order_card, itemsList)
        }
    }

    override fun onShow() {
        isTopBubbleVisible = true
        isBottomLayoutVisible = true
    }
}