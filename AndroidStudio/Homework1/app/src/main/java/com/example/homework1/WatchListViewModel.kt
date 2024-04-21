package com.example.homework1

import androidx.compose.runtime.mutableStateListOf
import androidx.lifecycle.ViewModel

class WatchListViewModel : ViewModel() {
    private val _watchList = mutableStateListOf(
        WatchListItem(1, "Movie 1"),
        WatchListItem(2, "Movie 2"),
        WatchListItem(3, "Series 1"),
        WatchListItem(4, "Series 2")
    )

    val watchList: List<WatchListItem>
        get() = _watchList

    fun toggleWatched(item: WatchListItem) {
        val index = _watchList.indexOfFirst { it.id == item.id }
        if (index != -1) {
            _watchList[index] = _watchList[index].copy(watched = !_watchList[index].watched)
        }
    }

    fun addItem(title: String) {
        val newItem = WatchListItem(_watchList.size + 1, title)
        _watchList.add(newItem)
    }
}
