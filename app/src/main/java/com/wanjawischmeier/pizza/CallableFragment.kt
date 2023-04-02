package com.wanjawischmeier.pizza

import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.isGone
import androidx.core.view.isVisible
import androidx.fragment.app.Fragment
import com.google.android.gms.tasks.Task

abstract class CallableFragment : Fragment() {
    companion object {
        lateinit var topBubble: ConstraintLayout
        lateinit var bottomLayout: ConstraintLayout
    }

    var topBubbleVisible: Boolean
        get() = topBubble.alpha != 0f
        set(value) {
            if (value == topBubbleVisible) return

            topBubble.animate()
                .alpha(if (value) 1f else 0f)
                .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()
        }
    
    var bottomLayoutVisible: Boolean
        get() = bottomLayout.translationY < bottomLayout.height
        set(value) {
            if (value == bottomLayoutVisible) return

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
                }
                .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()
        }

    abstract fun onShow(refresh: Boolean = false): Task<Unit>?

    fun showEmptyCard(info: Int) {
        showEmptyCard(getString(info))
    }

    fun showEmptyCard(info: String) {
        val noItemsTextView = view?.findViewById<TextView>(R.id.no_items_text) ?: layoutInflater
            .inflate(R.layout.card_no_items, view as ViewGroup)
            .findViewById(R.id.no_items_text)

        noItemsTextView.text = info
        noItemsTextView.alpha = 0f
        noItemsTextView.animate()
            .alpha(1f)
            .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()
    }

    fun removeEmptyCard() {
        val parent = view?.findViewById<TextView>(R.id.no_items_text)?.parent ?: return
        (view as ViewGroup).removeView(parent as View)
    }
}