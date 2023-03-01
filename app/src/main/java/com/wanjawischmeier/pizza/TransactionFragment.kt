package com.wanjawischmeier.pizza

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView


class TransactionFragment : CallableFragment() {
    lateinit var comingSoon: TextView

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val inflated = inflater.inflate(R.layout.fragment_transaction, container, false)
        comingSoon = inflated.findViewById(R.id.coming_soon)
        return inflated
    }
}