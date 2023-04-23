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
        uint256 eventTime;
        uint256 postTime;
        bool showPublic;
        bool showPolice;
        address [] voters;
    }    
 
    constructor() payable {
        // Initialize the contract with 1 ether
        //require(msg.value == 1 ether, "You must send 1 ether to initialize the contract");
    }

    receive() external payable {}
    fallback() external payable {}

    mapping(uint256 => Post) public posts;
    uint256 public postCount = 0;
    address[] public police = [0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,0x92d480746e1309a33800A3772b7544cba61ca994,0x936F3348c3035ea5530F0d959272DC6cC0402C44,0x23f4B503f36efe37dc754512c3C9d7Ef61c99371];
    address[] public admin = [0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,0xB9eF15e56A39fAc2a66431d88c7ef950652e6560,0x936F3348c3035ea5530F0d959272DC6cC0402C44,0x23f4B503f36efe37dc754512c3C9d7Ef61c99371];
function createPost(address _owner , string memory _title, string memory _description, string memory _location , string memory _image, uint256 _time ) public returns(uint256){
    Post storage post = posts[postCount];
    require( post.eventTime <= block.timestamp, "Time must be lesser  than current time");
    post.owner = payable(_owner);
    post.description = _description;
    post.upvotes =0;
    post.location = _location;
    post.image = _image;
    post.eventTime = _time;
    post.postTime = block.timestamp;
    post.title=_title;
    post.showPublic = false;
    post.showPolice= false;
    postCount++;
    
    return postCount -1;


}
function sendETHtoContract(uint amount) public payable{
    (bool sent, ) = (address(this)).call{value: amount}("");
        require(sent, "Failed to send Ether");
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

function transfer(address payable to , uint256 amount)public payable{
      (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
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