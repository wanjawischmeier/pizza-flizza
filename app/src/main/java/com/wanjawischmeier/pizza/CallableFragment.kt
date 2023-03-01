package com.wanjawischmeier.pizza

import android.widget.Toast
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.isGone
import androidx.fragment.app.Fragment

open class CallableFragment : Fragment() {
    companion object {
        lateinit var topBubble: ConstraintLayout
        lateinit var bottomLayout: ConstraintLayout
    }

    var isTopBubbleVisible: Boolean
        get() {
            return topBubble.alpha == 1f
        }
        set(value) {
            topBubble.animate()
                .alpha(if (value) 1f else 0f)
                .duration = 100
        }

    var isBottomLayoutVisible: Boolean
        get() {
            return bottomLayout.alpha == 1f
        }
        set(value) {
            var start = 0f
            var end = bottomLayout.height.toFloat()

            if (value) {
                start = end
                end = 0f

                bottomLayout.isGone = false
            }

            bottomLayout.translationY = start
            bottomLayout.animate()
                .translationY(end)
                .withEndAction {
                    if (!value) {
                        bottomLayout.isGone = true
                    }

                    onBottomLayoutGone()
                }
                .duration = 100
        }

    open fun onShow() {}

    open fun onBottomLayoutGone() {}
}