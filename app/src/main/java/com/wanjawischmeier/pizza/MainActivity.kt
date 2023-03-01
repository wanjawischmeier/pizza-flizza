package com.wanjawischmeier.pizza

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.FragmentContainerView
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

        val navigationHeader = findViewById<TextView>(R.id.header)
        val navigationHost = findViewById<FragmentContainerView>(R.id.nav_host_fragment)
        CallableFragment.topBubble = findViewById(R.id.top_bubble_constraint)
        CallableFragment.bottomLayout = findViewById(R.id.bottom_layout)

        val orderFragment = OrderFragment()
        val fulfillFragment = FulfillFragment()
        val transactionFragment = TransactionFragment()
        var currentFragment = orderFragment as CallableFragment
        var targetFragment = currentFragment

        supportFragmentManager.beginTransaction().apply {
            remove(supportFragmentManager.fragments[0])
            add(R.id.nav_host_fragment, orderFragment)
            add(R.id.nav_host_fragment, fulfillFragment)
            add(R.id.nav_host_fragment, transactionFragment)
            hide(fulfillFragment)
            hide(transactionFragment)
            runOnCommit(orderFragment::onShow)
        }.commit()

        val bottomNavigationView = findViewById<BottomNavigationView>(R.id.bottomNavigationView)
        bottomNavigationView.setOnItemSelectedListener { menuItem ->
            val menuItemId = menuItem.itemId
            if (menuItemId == bottomNavigationView.selectedItemId) {
                return@setOnItemSelectedListener false
            }

            when (menuItemId) {
                R.id.navigation_order -> targetFragment = orderFragment
                R.id.navigation_shop -> targetFragment = fulfillFragment
                R.id.navigation_transaction -> targetFragment = transactionFragment
            }

            if (targetFragment == transactionFragment) {
                val intent = Intent(this, LoginActivity::class.java)
                finish()
                startActivity(intent)
            }

            val transaction = supportFragmentManager.beginTransaction().apply {
                hide(currentFragment)
                show(targetFragment)
                runOnCommit {
                    currentFragment = targetFragment

                    navigationHost.animate()
                        .alpha(1f)
                        .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()
                }
            }

            navigationHeader.text = menuItem.title
            targetFragment.updateTopBubble()
            targetFragment.updateBottomLayout()
            targetFragment.onShow()
            navigationHost.animate()
                .alpha(0f)
                .withEndAction {
                    transaction.commit()
                }
                .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()

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