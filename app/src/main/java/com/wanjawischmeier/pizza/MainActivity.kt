package com.wanjawischmeier.pizza

import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentTransaction
import androidx.navigation.Navigation
import androidx.navigation.findNavController
import androidx.navigation.fragment.findNavController
import androidx.navigation.ui.NavigationUI
import androidx.navigation.ui.setupWithNavController
import com.google.android.material.bottomnavigation.BottomNavigationView


class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val header = findViewById<TextView>(R.id.header)
        val topBubble = findViewById<ConstraintLayout>(R.id.top_bubble_constraint)

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
                .commit()

            currentFragment = targetFragment
            currentFragment.onShow(topBubble)
            header.text = menuItem.title

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