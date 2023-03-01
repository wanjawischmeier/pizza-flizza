package com.wanjawischmeier.pizza

import android.widget.Toast
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.fragment.app.Fragment

open class CallableFragment: Fragment() {
    open fun onShow(topBubble: ConstraintLayout) {
        Toast.makeText(activity, "Show callable", Toast.LENGTH_SHORT).show()
    }
}