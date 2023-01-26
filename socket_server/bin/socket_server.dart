import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'dart:async';

/*
 * Authors: Andreas Hadjivasili & Constantinos Georgiou
 *
 * Purpose: To implement a simple FTP client - server using sockets.  
 * 
 * Language:  Dart
 * 
 * Version: 1.0
 *
 */


//***********************************************************************************
//***********************************************************************************

displayFile(Socket client,name){
  var data = new File(name).readAsStringSync();
  client.write(data);
  //data.readAsLines().then(displayLineByLine);
}

//***********************************************************************************
//***********************************************************************************

displayLineByLine(Socket client,List<String> lines) {
  for (var line in lines) {
    client.write(line);
  }
}

//***********************************************************************************
//***********************************************************************************

List<FileSystemEntity> dirContents(Directory dir) {
  var files = <FileSystemEntity>[];
  //var completer = Completer<List<FileSystemEntity>>();
  List<FileSystemEntity> lister = dir.listSync(recursive: false);
  return lister;
  // lister.listen ( 
  //     (file) => files.add(file),
  //     // should also register onError
  //     onDone:   () => completer.complete(files)
  //     );
  // return completer.future;
}

//***********************************************************************************
//***********************************************************************************

appendList(str,wordlist) {
  var tmp_lst = [];
  tmp_lst = str.split(" ");
  wordlist.addAll(tmp_lst);
}

void main() async {
  // bind the socket server to an address and port
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, 4567);

  // listen for clent connections to the server
  server.listen((client) {
    handleConnection(client);
  });
}


//******************************************************************************
// This is a function that creates a new file in the given path to store the data

void createFileRecursively(String filename) {
  // Create a new directory, recursively creating non-existent directories.
  //new Directory.fromPath(new Path(filename).directoryPath).createSync(recursive: true);
 // new File(filename).createSync();
 new File(filename).create(recursive: true);
}

//******************************************************************************
// This is a function that handles the connection between the server and the client

void handleConnection(Socket client) {

  var option = 0;
  var flag = 0;
  var path;
  var tokens;
  var choice;

  print('Connection from'
      ' ${client.remoteAddress.address}:${client.remotePort}');

  // listen for events from the client
  client.listen(
    // handle data from the client
    (Uint8List data) async  {
      await Future.delayed(Duration(seconds: 1));
      final message = String.fromCharCodes(data);

      tokens = message.split(" ");
    
      if (message == "1") {
        option = 1;
        client.write('Uploading started');
      }

      for (var t = 0; t<tokens.length; t++){
       tokens[t] =  tokens[t].replaceAll("[", "");
       tokens[t] =  tokens[t].replaceAll(",", "");
      tokens[t] =  tokens[t].replaceAll("]", "");
      }

      // var n = tokens.length;
      // var x = tokens[0];
      // print('$n   $x');

      if (tokens.length > 1 && tokens[0] == 'download'){
        option=2;
        client.write('Download started');
        choice = tokens[1];
      }

      // first in case of upload
      if(option==1 && message != "1" && message != "2"){  

        if (message=='end'){
          client.write("Upload done!");
          client.close();
        }

        if(flag == 0 && message!='end'){
          path = message;
          createFileRecursively(path);
          flag = 1;
        }

        if(flag == 1 && message!='end'&& message!= path){
          
          createFileRecursively(path);
          var file = File(path);
          var sink = file.openWrite();
          sink.write(message);
          // Close the IOSink to free system resources.
          sink.close();
          flag = 0;
        }


      } 









//====================================================================================================================

  if(option==2 ){ 


    switch(choice){

    case '0':{
      displayFile(client,tokens[2]);
    }
    break;

     //////////////////////////////////////////////////////////////////////////////////

    case '1':{
      //var systemTempDir = Directory.current;
      var myDir = Directory(tokens[2]);     //e.g. C:\Users\kotsi\Desktop\CS\examino8\epl421\assignments\Dart_Project
      var x = dirContents(myDir);
      for (var i=0; i<x.length;i++){
        client.write(x[i].toString());
      }
    }
    break;

     //////////////////////////////////////////////////////////////////////////////////

    case '2':{
      // List directory contents, recursing into sub-directories, but not following symbolic links.
      var systemDir = Directory.current;
      //print(systemDir.toString());

      Stream<FileSystemEntity> entityList =
          systemDir.list(recursive: true, followLinks: false);
      await for (FileSystemEntity entity in entityList){
        String path = entity.path.toString();
        String base = Directory.current.toString().split(" ")[1].replaceAll("'", "");

        String out = path.replaceAll(base, '\n~');
        client.write(out);
        //print(entity.path);
      }
    }
    break;

   //////////////////////////////////////////////////////////////////////////////////  

    case '3':{
      var systemDir = Directory.current;
      var dirList = [];
      dirList.add(systemDir);

      while(dirList.length > 0){
        var current_dir = dirList.removeAt(0);
        Stream<FileSystemEntity> entityList =
            current_dir.list(recursive: false, followLinks: false);
        await for (FileSystemEntity entity in entityList){
          String path = entity.path.toString();
          String base = Directory.current.toString().split(" ")[1].replaceAll("'", "");

          String out = path.replaceAll(base, '\n~');
          client.write(out);

          if (entity is Directory) {
            dirList.add(Directory(path.toString()));
          }
        }

      }
    }
    break;

     //////////////////////////////////////////////////////////////////////////////////

    case '4':
    case '5':{
      var base  = Directory.current.toString().split(" ")[1].replaceAll("'", "") + '\\ftphome';
      var systemDir = Directory(base);
      print(systemDir.toString());
      //print(systemDir);
      var wordlist = [];
      Stream<FileSystemEntity> entityList =
          systemDir.list(recursive: true, followLinks: false);
      await for (FileSystemEntity entity in entityList){
        if (entity is File) {
          String path = entity.path.toString();
          File path_file = new File(path);

          List<String> lines = path_file.readAsLinesSync();
          const regex = "/[!#%&()*+,-./:;<=>?@[\]^_`{|}~]";
          for (var line in lines){
            for (var c=0;c<regex.length;c++){
              line = line.replaceAll(regex[c], '');
            }
            appendList(line,wordlist);
          }
        }
      }
      // print(wordlist.length);
      // final result = wordlist
      // .fold(<String, int>{}, (Map<String, int> map, item) => map..update(item, (count) => count + 1, ifAbsent: () => 1));

      var map = Map();
      wordlist.forEach((element) {
        if(!map.containsKey(element)) {
          map[element] = 1;
        } else {
          map[element] +=1;
        }
      });  


      if (choice == '4'){
        for(var k in map.keys){
          client.write('\n');
          client.write(k);
        }
      }


      if (choice =='5'){
        var searching_word = tokens[2];
        for(var k in map.keys){
          if (k == searching_word){
            var pt = map[k];
            client.write("Frequency of the word $searching_word . . . $pt");
            client.write("\n");
          }
        }
      }

      // if (choice =='5'){
      //   //stdout.write("Give me the word you are looking for: ");
      //   //String? searching_word = stdin.readLineSync();
      //   var searching_word = tokens[2];
      //   for(var i=0;i<result.keys.length;i++){
      //     if (result.keys.elementAt(i) == searching_word){
      //       var pt = result.values.elementAt(i);
      //       client.write("Frequency of the word $searching_word . . . $pt");
      //     }
      //   }
      // }
    }
    break; 
  }

  client.write("Download done!");
  client.close();
}


  if (message.isEmpty) {
     client.flush();
  }

  },

    // handle errors
    onError: (error) {
      print(error);
      client.close();
    },

    // handle the client closing the connection
    onDone: () {
      print('Client left');
      client.close();
    },
  );




}