package com.wanjawischmeier.pizza

import kotlin.math.floor
import kotlin.math.min
import kotlin.math.roundToInt

class ItemSorter <T> (
    list: Iterable<T>,
    private val limit: Int,
    private val progress: (Int) -> Unit,
    private val callback: (List<T>, Int) -> Unit
) {
    private var minimum = 0
    private var maximum = 0
    private var pointer = 0
    private var listPointer = 1
    private var comparisons = 0
    private var value: T
    private var sorted: MutableList<T>
    private var cache = mutableMapOf<Pair<T, T>, Boolean>()
    private var input: List<T> = list.toList()
    private var key: Pair<T, T>

    init {
        sorted = mutableListOf(input[0])
        value = input[listPointer]
        maximum = min(sorted.size, limit)
        pointer = maximum - 1
        key = value to sorted[pointer]
    }

    private fun loadNextKey(sortedKey: Int) {
        sorted.add(min(sorted.size, sortedKey), value)

        listPointer++

        if (listPointer >= input.size) {
            pointer = -1
            callback(sorted.subList(0, limit), comparisons)
            return
        } else {
            progress((listPointer / input.size.toFloat() * 100).roundToInt())
        }

        value = input[listPointer]
        minimum = 0
        maximum = min(sorted.size, limit)
        pointer = maximum - 1

        key = value to sorted[pointer]
        setComparisonResult(cache[key] ?: return)
    }

    fun getNextComparison(): Pair<T, T> {
        return key
    }

    fun setComparisonResult(result: Boolean) {
        if (pointer == -1) {
            return
        } else {
            comparisons++
        }

        cache[key] = result

        if (result) {
            maximum = pointer
        } else {
            minimum = if (minimum == pointer) {
                maximum
            } else {
                pointer
            }

            if (minimum > limit) {
                loadNextKey(pointer)
                return
            }
        }

        if (minimum == maximum) {
            loadNextKey(minimum)
            return
        }

        pointer = minimum + floor((maximum - minimum) / 2f).toInt()
        key = value to sorted[pointer]

        val cached = cache[key]
        if (cached != null) {
            comparisons--
            setComparisonResult(cached)
        }
    }
}