// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SoberHaven {
    struct Post {
        address owner;
        string title;
        string description;
        uint256 upvotes;
        string location ;
        string image;
        uint256 time;
        bool showPublic;
        bool showPolice;
        address [] voters;
    }    
    
    
    constructor() payable {
        // Initialize the contract with 1 ether
        //require(msg.value == 1 ether, "You must send 1 ether to initialize the contract");
    }



    mapping(uint256 => Post) public posts;
    uint256 public postCount = 0;
    address[] public police = [0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,0x936F3348c3035ea5530F0d959272DC6cC0402C44];
    address[] public admin = [0x617F2E2fD72FD9D5503197092aC168c91465E7f2,0x936F3348c3035ea5530F0d959272DC6cC0402C44];
function createPost(address _owner , string memory _title, string memory _description, uint256 _upvotes, string memory _location , string memory _image, uint256 _time ) public returns(uint256){
    Post storage post = posts[postCount];
    require( post.time <= block.timestamp, "Time must be lesser  than current time");
    post.owner = payable(_owner);
    post.description = _description;
    post.upvotes = _upvotes;
    post.location = _location;
    post.image = _image;
    post.time = _time;
    post.title=_title;
    post.showPublic = false;
    post.showPolice= false;
    postCount++;
    
    return postCount -1;


}
function getPosts() public view returns(Post[] memory){
    Post[] memory allPosts = new Post[](postCount);
   for(uint i=0 ; i<postCount ; i++){
        Post storage item = posts[i];
        allPosts[i] = item;
   }
   return allPosts;
}
function updatePublicView( uint256 _id ) public returns  (bool) {
    //require(msg.sender == police, "Only police can update the view");
    for(uint i=0 ; i<police.length ; i++){
        if(msg.sender == police[i]){
            Post storage post = posts[_id];
            post.showPublic = true;
           transfer(payable(post.owner),0.00001 ether);
            return true;
        }
    }

   
    
    return false;
}

function transfer(address payable to , uint256 amount)public{
     to.transfer(amount);
}

function updatePoliceView( uint256 _id ) public returns (bool) {
    //require(msg.sender == police, "Only police can update the view");
    for(uint i=0 ; i<admin.length ; i++){
        if(msg.sender == admin[i]){
            
            Post storage post = posts[_id];
            post.showPolice = true;
            return true;
        }
    }
   
    
    return false;
}
function upvotePost( uint256 _id ) public payable returns (bool) {
    require( msg.value > 0.00001 ether, "Amount must be greater than 0.00001");
   uint256 amount = msg.value;
   Post storage post = posts[_id];
   post.voters.push(msg.sender);
   post.upvotes+=1;
  
   (bool sent ,) = payable(admin[1]).call{value: amount}("");
   if(sent){
         return true;
   }
   return false;

    

    
}
}