package com.wanjawischmeier.pizza

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase


class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (Firebase.auth.currentUser == null) {
            val intent = Intent(this, LoginActivity::class.java)
            finish()
            startActivity(intent)
        }

        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val header = findViewById<TextView>(R.id.header)
        CallableFragment.topBubble = findViewById(R.id.top_bubble_constraint)
        CallableFragment.bottomLayout = findViewById(R.id.bottom_layout)

        val orderFragment = OrderFragment()
        val fulfillFragment = FulfillFragment()
        var currentFragment = orderFragment as CallableFragment
        var targetFragment = currentFragment

        supportFragmentManager.beginTransaction().apply {
            remove(supportFragmentManager.fragments[0])
            add(R.id.nav_host_fragment, orderFragment)
            add(R.id.nav_host_fragment, fulfillFragment)
            hide(fulfillFragment)
        }.commit()
        orderFragment.onShow()

        val bottomNavigationView = findViewById<BottomNavigationView>(R.id.bottomNavigationView)
        bottomNavigationView.setOnItemSelectedListener { menuItem ->
            val menuItemId = menuItem.itemId
            val selectedItemId = bottomNavigationView.selectedItemId
            if (menuItemId == selectedItemId) {
                return@setOnItemSelectedListener false
            }

            when (menuItemId) {
                R.id.navigation_order -> targetFragment = orderFragment
                R.id.navigation_shop -> targetFragment = fulfillFragment
            }

            supportFragmentManager.beginTransaction()
                .hide(currentFragment)
                .show(targetFragment)
                .runOnCommit {
                    header.text = menuItem.title
                    currentFragment = targetFragment
                    currentFragment.onShow()
                }
                .commit()

            return@setOnItemSelectedListener true
        }
    }

    private fun modifyCount(view: View, change: Int) {
        val count = (view.parent as ViewGroup).findViewById<TextView>(R.id.order_count)
        count.text = (Integer.max(0, Integer.min(99, count.text.toString().toInt() + change))).toString()
    }

    fun onSub(view: View) {
        modifyCount(view, -1)
    }

    fun onAdd(view: View) {
        modifyCount(view, 1)
    }
}