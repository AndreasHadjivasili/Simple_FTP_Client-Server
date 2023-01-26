import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

/*
 * Authors: Andreas Hadjivasili & Constantinos Georgiou
 *
 * Purpose: To implement a simple FTP client - server using sockets.  
 * 
 * Language:  Dart
 * 
 * Version: 1.0
 */

void main(List<String> args) async {

  //**************************************************************************
  // In this section the connection to the server is established. Server in
  // case is located in this machine thus the loopback or localhost address is
  // used. We are chosen a random port above 1024 to use for the socket
  // connection. Also in this section some basic socket error handling is
  // happening.

  // connect to the socket server
  final socket = await Socket.connect('localhost', 4567);
  print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
  var ch;
  var flag=0;
  var input;
  var choice;
  var path;
  var serverResponse;
  var init = 0;
  var len = 0;

  // listen for responses from the server
  socket.listen(

    // handle data from the server
    (Uint8List data) async {
      serverResponse = String.fromCharCodes(data);
   
      if(args[1] == '4'){
          //await Future.delayed(Duration(seconds: 1));
          new File("./ftphome/lexicon.txt").create(recursive: true);
          var file = File("./ftphome/lexicon.txt");
          var sink = file.openWrite();
          sink.write(serverResponse);
          // Close the IOSink to free system resources.
          sink.close();
      }else{
        print('Server: $serverResponse'); 
      }
         

  },

    // handle errors
    onError: (error) {
      print(error);
      socket.destroy();
    },

    // handle server ending connection
    onDone: () {
      print('Server left.');
      socket.destroy();
    },
  );

      //***************************************************************************
      // In this section we have the messaging with the server about the data process
      // that we want to execute. Specifically, once the connection is established 
      // client sends a message to the server to make sure about the connection and
      // after that we have the file download or upload process.  


      // If connection it is okay choose the process -> download or upload
      if(args[0] != "upload" && args[0]!="download"){
        print("Invalid option given!");      
        socket.destroy();
      }

      len = args.length;

      //if choice is upload
      if (args[0] == "upload") {
            
          if(len<=1){
            print("Invalid number of arguments given!");
            socket.destroy();
          }

          await sendMessage(socket, "1");
          
          for( var i = 1 ; i<len; i++ ) { 
            path = args[i];
            //print(path);
            if((File(path).existsSync())){
              String contents = new File(path).readAsStringSync();
              //await sendMessage(socket, contents);

            await sendMessage(socket, path);
            await sendMessage(socket, contents);
            } 
          }

          await sendMessage(socket, "end");
      }     

//**********************************************************************************
// Please add your code below -> Cgeorgiou
// This will be thw analyze section
//if choice is download
  if (args[0] == "download") {

    if(len<2){
      print("Invalid number of arguments given!");
        socket.destroy();
    }

    choice = args[1];

    await sendMessage(socket, args.toString());
  }
}
//***********************************************************************************
//***********************************************************************************

Future<void> sendMessage(Socket socket, String message) async {
//void sendMessage(Socket socket, String message) async {
  //print('Client: $message');
  socket.write(message);
  await Future.delayed(Duration(seconds: 3));
}