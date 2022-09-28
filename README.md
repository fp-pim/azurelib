# Flaschenpost Azure Library for PHP

This project provides a set of PHP client libraries that make it easy to access
Microsoft™ Azure service bus (queues and topics).

# Features

* Service Bus
  * Queues: create, list and delete queues; send, receive, unlock and delete messages
  * Topics: create, list, and delete topics; create, list, and delete subscriptions; send, receive, unlock and delete messages; create, list, and delete rules


# Getting Started
## Download Source Code

To get the source code from our repository, type

```
git clone https://FlaschenpostSE@dev.azure.com/FlaschenpostSE/PHP/_git/azurelib
cd ./azurelib
```

> **Note**
>
> The recommended way to resolve dependencies is to install them using the [Composer package manager](http://getcomposer.org).

## Install via Composer

* Create a file named **composer.json** in the root of your project and add the following code to it:

  ```json
  {
      "require": {
          "flaschenpost/azurelib": "^0.5"
      }
  }
  ```

* Download **[composer.phar](http://getcomposer.org/composer.phar)** in your project root.

* Open a command prompt and execute this in your project root

  ```
  php composer.phar install
  ```

  > **Note**
  >
  > On Windows, you will also need to add the Git executable to your PATH environment variable.

# Usage

## Getting Started

There are four basic steps that have to be performed before you can make a call to any Microsoft Azure API when using the libraries.

* First, include the autoloader script:

  ```PHP
  require_once "vendor/autoload.php";
  ```

* Include the namespaces you are going to use.

  To create any Microsoft Azure service client you need to use the **ServicesBuilder** class:

  ```PHP
  use WindowsAzure\Common\ServicesBuilder;
  ```

  To process exceptions you need:

  ```PHP
  use WindowsAzure\Common\ServiceException;
  ```

* To instantiate the service client you will also need a valid connection string. The format is:

  * For accessing a live storage service (tables, blobs, queues):

    ```
    DefaultEndpointsProtocol=[http|https];AccountName=[yourAccount];AccountKey=[yourKey]
    ```

  * For accessing the Service Bus:

    ```
    Endpoint=[yourEndpoint];SharedSecretIssuer=[yourWrapAuthenticationName];SharedSecretValue=[yourWrapPassword]
    ```

    Where the Endpoint is typically of the format `https://[yourNamespace].servicebus.windows.net`.

* Instantiate a "REST Proxy" - a wrapper around the available calls for the given service.
* 
  * For Service Bus:

    ```PHP
    $serviceBusRestProxy = ServicesBuilder::getInstance()->createServiceBusService($connectionString);
    ```

## Service Bus Queues
The current PHP Service Bus APIs only support ACS connection strings. You need to use PowerShell to create a new ACS Service Bus namespace at the present time.
First, make sure you have Azure PowerShell installed, then in a PowerShell command prompt, run
```PowerShell
Add-AzureAccount # this will sign you in
New-AzureSBNamespace -CreateACSNamespace $true -Name 'mytestbusname' -Location 'West US' -NamespaceType 'Messaging'
```
If it is sucessful, you will get the connection string in the PowerShell output. If you get connection errors with it and the conection string looks like Endpoint=sb://..., change it to **Endpoint=https://...**

### Create a Queue

```PHP
try {
  $queueInfo = new QueueInfo("myqueue");

  // Create queue.
  $serviceBusRestProxy->createQueue($queueInfo);
} catch(ServiceException $e){
  $code = $e->getCode();
  $error_message = $e->getMessage();
  echo $code.": ".$error_message."<br />";
}
```

[Error Codes and Messages](http://msdn.microsoft.com/en-us/library/windowsazure/dd179357)

### Send a Message

To send a message to a Service Bus queue, your application will call the **ServiceBusRestProxy->sendQueueMessage** method. Messages sent to (and received from ) Service Bus queues are instances
of the **BrokeredMessage** class.

```PHP
try {
  // Create message.
  $message = new BrokeredMessage();
  $message->setBody("my message");

  // Send message.
  $serviceBusRestProxy->sendQueueMessage("myqueue", $message);
} catch(ServiceException $e){
  $code = $e->getCode();
  $error_message = $e->getMessage();
  echo $code.": ".$error_message."<br />";
}
```

### Receive a Message

The primary way to receive messages from a queue is to use a **ServiceBusRestProxy->receiveQueueMessage** method. Messages can be received in two different modes: **ReceiveAndDelete** (mark message as consumed on read) and **PeekLock** (locks message for a period of time, but does not delete).

The example below demonstrates how a message can be received and processed using **PeekLock** mode (not the default mode).

```PHP
try {
  // Set the receive mode to PeekLock (default is ReceiveAndDelete).
  $options = new ReceiveMessageOptions();
  $options->setPeekLock(true);

  // Receive message.
  $message = $serviceBusRestProxy->receiveQueueMessage("myqueue", $options);
  echo "Body: ".$message->getBody()."<br />";
  echo "MessageID: ".$message->getMessageId()."<br />";

  // *** Process message here ***

  // Delete message.
  $serviceBusRestProxy->deleteMessage($message);
} catch(ServiceException $e){
  $code = $e->getCode();
  $error_message = $e->getMessage();
  echo $code.": ".$error_message."<br />";
}
```

## Service Bus Topics

### Create a Topic

```PHP
try {
  // Create topic.
  $topicInfo = new TopicInfo("mytopic");
  $serviceBusRestProxy->createTopic($topicInfo);
} catch(ServiceException $e){
  $code = $e->getCode();
  $error_message = $e->getMessage();
  echo $code.": ".$error_message."<br />";
}
```

### Create a subscription with the default (MatchAll) filter

```PHP
try {
  // Create subscription.
  $subscriptionInfo = new SubscriptionInfo("mysubscription");
  $serviceBusRestProxy->createSubscription("mytopic", $subscriptionInfo);
} catch(ServiceException $e){
  $code = $e->getCode();
  $error_message = $e->getMessage();
  echo $code.": ".$error_message."<br />";
}
```

### Send a message to a topic

Messages sent to Service Bus topics are instances of the **BrokeredMessage** class.

```PHP
try {
  // Create message.
  $message = new BrokeredMessage();
  $message->setBody("my message");

  // Send message.
  $serviceBusRestProxy->sendTopicMessage("mytopic", $message);
} catch(ServiceException $e){
  $code = $e->getCode();
  $error_message = $e->getMessage();
  echo $code.": ".$error_message."<br />";
}
```

### Receive a message from a topic

The primary way to receive messages from a subscription is to use a **ServiceBusRestProxy->receiveSubscriptionMessage** method. Received messages can work in two different modes: **ReceiveAndDelete** (the default) and **PeekLock** similarly to Service Bus Queues.

The example below demonstrates how a message can be received and processed using **ReceiveAndDelete** mode (the default mode).

```PHP
try {
  // Set receive mode to PeekLock (default is ReceiveAndDelete)
  $options = new ReceiveMessageOptions();
  $options->setReceiveAndDelete();

  // Get message.
  $message = $serviceBusRestProxy->receiveSubscriptionMessage("mytopic",
                                "mysubscription",
                                $options);
  echo "Body: ".$message->getBody()."<br />";
  echo "MessageID: ".$message->getMessageId()."<br />";
} catch(ServiceException $e){
  $code = $e->getCode();
  $error_message = $e->getMessage();
  echo $code.": ".$error_message."<br />";
}
```

# Learn More
[Microsoft Azure PHP Developer Center](http://www.windowsazure.com/en-us/develop/php/)

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
