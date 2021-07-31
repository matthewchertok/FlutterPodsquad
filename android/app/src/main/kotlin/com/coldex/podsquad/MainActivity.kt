package com.coldex.podsquad

import android.content.Context
import android.os.Bundle
import android.util.Log
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.messages.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*


class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?){
        super.onCreate(savedInstanceState)
        val flutterView = flutterEngine?.dartExecutor?.binaryMessenger

        val pubSubChannel = MethodChannel(flutterView, "publishAndSubscribe")
        val listenerChannel = EventChannel(flutterView, "nearbyScannerAndroid")

        pubSubChannel.setMethodCallHandler { call, result ->
            val message = Message(call.arguments.toString().toByteArray())
            when (call.method) {
                "startPublishAndSubscribe" -> {
                    // get Bluetooth permissions
                        Nearby.getMessagesClient(this, MessagesOptions.Builder()
                                .setPermissions(NearbyPermissions.BLE)
                                .build())

                    // publish my ID and listen for people nearby
                    val nearbyListener = NearbyListenerAndroid(context, call.arguments.toString())
                    listenerChannel.setStreamHandler(nearbyListener)

                    result.success("Started publishing and subscribing! Publishing message ${
                        call.arguments}")
                }
                else -> {
                    Nearby.getMessagesClient(context).unpublish(message)
                    // I can't stop the stream handler, but it's okay. If I'm not publishing or
                    // subscribing, then stream shouldn't return anything.
                    result.success("Stopped publishing and subscribing!")
                }
            }
        }

    }
}

class NearbyListenerAndroid(private val context: Context, private val messageToPublish: String):
        EventChannel
.StreamHandler {
    private var listener: MessageListener? = null

    // called when the stream is set up
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // set up a listener to listen for nearby people
        this.listener = object: MessageListener() {
            // when someone is met, notify Dart code
            override fun onFound(message: Message) {
                Log.d("USER MET", "Found user with ID: " + message.content.toString())
                events?.success(message.content.toString())
            }
            override fun onLost(message: Message) {
                // don't do anything here
            }
        }
        publish(messageToPublish)
        subscribe()
        events?.success("Started listening for nearby people successfully!")

    }

    override fun onCancel(arguments: Any?) {
        this.listener = null
        Nearby.getMessagesClient(context).unpublish(Message(messageToPublish.toByteArray()))
        if (this.listener != null) Nearby.getMessagesClient(context).unsubscribe(this.listener!!)

    }

    private fun publish(message: String) {
        Log.i("PUBLISHING", "Publishing message: $message")
        val message = Message(message.toByteArray())
        Nearby.getMessagesClient(context).publish(message)
    }

    // Subscribe to receive messages.
    private fun subscribe() {
        Log.i("SUBSCRIBING", "Subscribing.")
        val options = SubscribeOptions.Builder()
                .build()
        if (this.listener != null) Nearby.getMessagesClient(context).subscribe(this.listener!!, options)
    }


}