/**
 *Submitted for verification at polygonscan.com on 2022-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// when we are done with the contract use 'truffle migrate --reset' if you are putting up the same smart contract

contract Decentragram {
  // Code goes here...
  string public name = 'Decentragram'; 
  // address payable author = msg.sender; 


  //store posts 
  uint public imageCount = 0; // will be used to generate user ID
  mapping(uint => Image) public images; 

  struct Image { // Image will store all of these data values in it. Always required when using mapping
    uint id; 
    string hash; // the hash is where the IPFS will be located
    string description; 
    uint tipAmount; 
    address payable author;
  }

  event ImageCreated (
    uint id, 
    string hash, 
    string description, 
    uint tipAmount, 
    address payable author
  );

  event ImageTipped (
    uint id, 
    string hash, 
    string description, 
    uint tipAmount, 
    address payable author
  );



  // create posts 
  function uploadImage(string memory _imgHash, string memory _description) public {
    //checks to see if description exists
    require(bytes(_description).length > 0, 'Please Upload a Description');

  //Checks if image hash exists
   require(bytes(_imgHash).length > 0, 'Please Upload a Description');

   //make sure uploader address existts 
   require(msg.sender != address(0x0));

  // increment image id 
    imageCount ++; // handles ID count


    images[imageCount] = Image(imageCount, _imgHash, _description, 0, payable(msg.sender));

    emit ImageCreated(imageCount, _imgHash, _description, 0, payable(msg.sender));// have to explicitly put payable for msg.sender now to send money to it. in 0.5.0 it was default a payable address


  }


  // Tip posts function
  function tipImageOwner(uint _id) public payable {// needs to have payable with public in order to pay this function cryptocurrency
    //makes sure the Id is valid and that is isn't less than the images that are present
    require(_id > 0 && _id <= imageCount);
    
    // fetch the image from the IPFS
    Image memory _image = images[_id];// Image is a local variable in the memory
    //fetches the author of the post
    address payable _author = _image.author;
   
   
    _author.transfer(msg.value);// msg.value is the crypto sent in to the function when it was called. 
  // msg.value will send the ether to the author aka the person who deployed the contract. 
    // this is a transfer money payment method! pay attention!
    
    //increment tip amount 
    _image.tipAmount = _image.tipAmount + msg.value; 

    //updates images object and tip amount
    images[_id] = _image;


    // trigger event 
    emit ImageTipped(_id, _image.hash, _image.description, _image.tipAmount, _author);

  }




}