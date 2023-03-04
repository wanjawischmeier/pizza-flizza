package com.wanjawischmeier.pizza

import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.isGone
import androidx.fragment.app.Fragment

open class CallableFragment : Fragment() {
    companion object {
        lateinit var topBubble: ConstraintLayout
        lateinit var bottomLayout: ConstraintLayout
    }

    open var showTopBubble = false
    open var showBottomLayout = false

    fun updateTopBubble() {
        topBubble.animate()
            .alpha(if (showTopBubble) 1f else 0f)
            .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()
    }

    fun updateBottomLayout() {
        var start = 0f
        var end = bottomLayout.height.toFloat()

        if (showBottomLayout) {
            start = end
            end = 0f
            bottomLayout.isGone = false
        }

        bottomLayout.translationY = start
        bottomLayout.animate()
            .translationY(end)
            .withEndAction {
                if (!showBottomLayout) {
                    bottomLayout.isGone = true
                }
            }
            .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()
    }

    open fun onShow() {}

    open fun onHide() {}
}