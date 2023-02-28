package com.wanjawischmeier.pizza

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import java.lang.Integer.max
import java.lang.Integer.min

class OrderActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_order)

        val itemsList = findViewById<LinearLayout>(R.id.items_list)

        for (i in 0..10) {
            layoutInflater.inflate(R.layout.order_card, itemsList)
        }
    }

    private fun modifyCount(view: View, change: Int) {
        val count = (view.parent as ViewGroup).findViewById<TextView>(R.id.order_count)
        count.text = (max(0, min(99, count.text.toString().toInt() + change))).toString()
    }

    fun onSub(view: View) {
        modifyCount(view, -1)
    }

    fun onAdd(view: View) {
        modifyCount(view, 1)
    }
}