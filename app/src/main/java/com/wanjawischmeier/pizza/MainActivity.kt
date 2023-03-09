package com.wanjawischmeier.pizza

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.FragmentContainerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.google.android.gms.tasks.Task
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase

/*
TODO: hide order button on order
TODO: fix quick switching bug
TODO: fix reopen bug (onResume?)
TODO: fix grab card bug
 */

class MainActivity : AppCompatActivity() {
    private lateinit var orderFragment: OrderFragment
    private lateinit var shopFragment: ShopFragment
    private lateinit var transactionFragment: TransactionFragment
    private lateinit var currentFragment: CallableFragment

    lateinit var shop: Shop
    lateinit var users: Users
    lateinit var swipeRefreshLayout: SwipeRefreshLayout
    var userId = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val user = Firebase.auth.currentUser
        if (user == null) {
            val intent = Intent(this, LoginActivity::class.java)
            finish()
            startActivity(intent)
        } else {
            userId = user.uid
        }

        setContentView(R.layout.activity_main)

        CallableFragment.topBubble = findViewById(R.id.top_bubble_constraint)
        CallableFragment.bottomLayout = findViewById(R.id.bottom_layout)

        swipeRefreshLayout = findViewById(R.id.swipe_refresh_layout)
        swipeRefreshLayout.setOnRefreshListener(this::refreshView)
    }

    override fun onStart() {
        super.onStart()

        swipeRefreshLayout.isRefreshing = true

        Shop.getShop(SHOP_ID).continueWith { shopTask ->
            shop = shopTask.result

            User.getUsers(GROUP_ID).continueWith { usersTask ->
                users = usersTask.result
                swipeRefreshLayout.isRefreshing = false

                runOnUiThread(this::initializeFragments)
            }
        }
    }

    private fun initializeFragments() {
        val navigationHeader = findViewById<TextView>(R.id.header)
        val navigationHost = findViewById<FragmentContainerView>(R.id.nav_host_fragment)

        orderFragment = OrderFragment()
        shopFragment = ShopFragment()
        transactionFragment = TransactionFragment()

        currentFragment = orderFragment
        var targetFragment = currentFragment

        supportFragmentManager.beginTransaction().apply {
            remove(supportFragmentManager.fragments[0])
            add(R.id.nav_host_fragment, orderFragment)
            add(R.id.nav_host_fragment, shopFragment)
            add(R.id.nav_host_fragment, transactionFragment)
            hide(shopFragment)
            hide(transactionFragment)
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

            /*
            // Login screen bridge
            if (targetFragment == transactionFragment) {
                val intent = Intent(this, LoginActivity::class.java)
                finish()
                startActivity(intent)
            }
             */

            val transaction = supportFragmentManager.beginTransaction().apply {
                hide(currentFragment)
                show(targetFragment)
                runOnCommit {
                    refreshView().continueWith {
                        runOnUiThread {
                            currentFragment.onHide()
                            targetFragment.updateTopBubble()
                            targetFragment.updateBottomLayout()
                            currentFragment = targetFragment

                            val after = {
                                swipeRefreshLayout.isRefreshing = false

                                navigationHost.animate()
                                    .alpha(1f)
                                    .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()
                            }

                            currentFragment.onShow()?.continueWith { after.invoke() } ?: after.invoke()
                        }
                    }
                }
            }

            navigationHeader.text = menuItem.title
            navigationHost.animate()
                .alpha(0f)
                .withEndAction {
                    transaction.commit()
                }
                .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()

            return@setOnItemSelectedListener true
        }
    }

    private fun refreshView(): Task<Users> {
        val user = Firebase.auth.currentUser
        if (user == null) {
            val intent = Intent(this, LoginActivity::class.java)
            finish()
            startActivity(intent)
        } else {
            userId = user.uid
        }

        val taskUsers = User.getUsers(GROUP_ID)
        taskUsers.continueWith { usersTask ->
            users = usersTask.result

            val after = { swipeRefreshLayout.isRefreshing = false }

            currentFragment.onShow()?.continueWith { after.invoke() } ?: after.invoke()
        }

        return taskUsers
    }

    fun onOrderSub(view: View) {
        orderFragment.modifyCount(view, -1)
    }

    fun onOrderAdd(view: View) {
        orderFragment.modifyCount(view, 1)
    }

    fun onTransactionAccept(view: View) {
        transactionFragment.accept(view)
    }

    fun onTransactionReject(view: View) {
        transactionFragment.reject(view)
    }

    @Suppress("UNUSED_PARAMETER")
    fun onOrder(view: View) {
        orderFragment.placeOrder()
    }
}