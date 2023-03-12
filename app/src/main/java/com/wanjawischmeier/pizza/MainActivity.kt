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
TODO: fix quick switching bug
TODO: consider nav bar state on resume
TODO: fix grab card bug
TODO: login add username
TODO: add discard order warning
TODO: fix accepting multiple orders
TODO: smooth bottom loading bar
 */

class MainActivity : AppCompatActivity() {
    private lateinit var orderFragment: OrderFragment
    private lateinit var shopFragment: ShopFragment
    private lateinit var transactionFragment: TransactionFragment
    private lateinit var previousFragment: CallableFragment
    private lateinit var currentFragment: CallableFragment
    private lateinit var bottomNavigationView: BottomNavigationView

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

        swipeRefreshLayout.isRefreshing = true

        orderFragment = OrderFragment()
        shopFragment = ShopFragment()
        transactionFragment = TransactionFragment()

        currentFragment = orderFragment
        previousFragment = currentFragment

        supportFragmentManager.beginTransaction().apply {
            remove(supportFragmentManager.fragments[0])
            add(R.id.nav_host_fragment, orderFragment)
            add(R.id.nav_host_fragment, shopFragment)
            add(R.id.nav_host_fragment, transactionFragment)
            hide(shopFragment)
            hide(transactionFragment)

            runOnCommit {
                val after = { swipeRefreshLayout.isRefreshing = false }
                currentFragment.onShow()?.continueWith { after.invoke() } ?: after.invoke()
            }
        }.commit()

        bottomNavigationView = findViewById(R.id.bottomNavigationView)
        bottomNavigationView.setOnItemSelectedListener { menuItem ->
            val menuItemId = menuItem.itemId
            if (menuItemId == bottomNavigationView.selectedItemId) {
                return@setOnItemSelectedListener false
            }

            swipeRefreshLayout.isRefreshing = true
            previousFragment = currentFragment

            when (menuItemId) {
                R.id.navigation_order -> currentFragment = orderFragment
                R.id.navigation_shop -> currentFragment = shopFragment
                R.id.navigation_transaction -> currentFragment = transactionFragment
            }

            /*
            // Login screen bridge
            if (targetFragment == transactionFragment) {
                val intent = Intent(this, LoginActivity::class.java)
                finish()
                startActivity(intent)
            }
             */

            previousFragment.onHide()
            navigationHeader.text = menuItem.title
            navigationHost.animate()
                .alpha(0f)
                .withEndAction {
                    supportFragmentManager.beginTransaction().apply {
                        hide(previousFragment)
                        show(currentFragment)

                        runOnCommit {
                            User.getUsers(GROUP_ID).continueWith { usersTask ->
                                users = usersTask.result ?: return@continueWith

                                val after = {
                                    swipeRefreshLayout.isRefreshing = false

                                    navigationHost.animate()
                                        .alpha(1f)
                                        .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()
                                }

                                val showTask = currentFragment.onShow()
                                showTask?.continueWith { after.invoke() } ?: after.invoke()
                            }
                        }.commit()
                    }
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