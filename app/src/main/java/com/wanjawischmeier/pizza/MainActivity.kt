package com.wanjawischmeier.pizza

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.FragmentContainerView
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.google.firebase.auth.ktx.auth
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.ktx.Firebase

class MainActivity : AppCompatActivity() {
    private lateinit var orderFragment: OrderFragment

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
        Shop.database = FirebaseDatabase.getInstance()

        orderFragment = OrderFragment()
        val shopFragment = ShopFragment()
        val transactionFragment = TransactionFragment()
        var currentFragment = orderFragment as CallableFragment
        var targetFragment = currentFragment

        supportFragmentManager.beginTransaction().apply {
            remove(supportFragmentManager.fragments[0])
            add(R.id.nav_host_fragment, orderFragment)
            add(R.id.nav_host_fragment, shopFragment)
            add(R.id.nav_host_fragment, transactionFragment)
            hide(shopFragment)
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
                R.id.navigation_shop -> targetFragment = shopFragment
                R.id.navigation_transaction -> targetFragment = transactionFragment
            }

            // Login screen bridge
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

    fun onSub(view: View) {
        orderFragment.modifyCount(view, -1)
    }

    fun onAdd(view: View) {
        orderFragment.modifyCount(view, 1)
    }

    @Suppress("UNUSED_PARAMETER")
    fun onOrder(view: View) {
        orderFragment.placeOrder()
    }
}