package com.example.homework1

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.homework1.ui.theme.Homework1Theme
import androidx.lifecycle.viewmodel.compose.viewModel


class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            Homework1Theme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    WatchListScreen()
                }
            }
        }
    }
}



@Composable
fun WatchListScreen(
    modifier: Modifier = Modifier,
    viewModel: WatchListViewModel = viewModel()
) {
    val watchList by remember { mutableStateOf(viewModel.watchList) }

    Column(modifier = modifier) {
        WatchList(
            list = watchList,
            onToggleWatched = { item -> viewModel.toggleWatched(item) },
            onAddItem = { title -> viewModel.addItem(title) }
        )
    }
}

@Composable
fun WatchList(
    list: List<WatchListItem>,
    onToggleWatched: (WatchListItem) -> Unit,
    onAddItem: (String) -> Unit
) {
    Column {
        WatchListHeader(onAddItem = onAddItem)
        LazyColumn {
            items(list) { item ->
                WatchListItem(
                    item = item,
                    onToggleWatched = { onToggleWatched(item) }
                )
            }
        }
    }
}

@Composable
fun WatchListHeader(onAddItem: (String) -> Unit) {
    var newItemTitle by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
    ) {
        TextField(
            value = newItemTitle,
            onValueChange = { newItemTitle = it },
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("Enter new item title") }
        )

        Spacer(modifier = Modifier.height(16.dp))

        Button(
            onClick = {
                if (newItemTitle.isNotEmpty()) {
                    onAddItem(newItemTitle)
                    newItemTitle = ""
                }
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Add Item")
        }
    }
}

@Composable
fun WatchListItem(
    item: WatchListItem,
    onToggleWatched: () -> Unit
) {
    Row(
        modifier = Modifier
            .padding(16.dp)
            .fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Checkbox(
            checked = item.watched,
            onCheckedChange = { isChecked ->
                onToggleWatched()
            },
            modifier = Modifier.padding(end = 16.dp)
        )

        Text(
            modifier = Modifier.weight(1f),
            text = item.title,
            color = if (item.watched) Color.Gray else Color.Black
        )
    }
}

