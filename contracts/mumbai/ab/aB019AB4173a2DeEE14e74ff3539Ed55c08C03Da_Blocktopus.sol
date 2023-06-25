// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Blocktopus {

    struct Volunteer{
        string id;
        string name;
    }
    mapping(uint256 => Volunteer) public volunteersList;
//struct for post
    struct Post {
        address payable owner;
        string title;
        string disasterName;
        string description;
        uint256 upvotes;
        string location ;
        string image;
        uint256 eventTime;
        bool showPublic;
        bool showAdmin;
        
    }
    mapping(uint256 => Post) public posts;
    struct Item{
        string name;
        uint256 quantity;
    }
    
    struct Disaster {
        address owner;
        string name;
        string description;
        uint256 amountCollected;
        string location ;
        string image;
        uint256 startDate;
        uint256 endDate;
        string scale;
        Item[] items; 
        uint256 volunteerCount;
        address [] donators;
        uint256 [] donations;
    }    
 mapping(uint256 => Disaster) public disasters;
    constructor() payable {
        // Initialize the contract with 1 ether
        //require(msg.value == 1 ether, "You must send 1 ether to initialize the contract");
    }

    receive() external payable {}
    fallback() external payable {}

  //  mapping(uint256 => Post) public posts;
    uint256 public postCount = 0;
    uint256 public disasterCount = 0;
    uint256 public volunteerCount = 0;
    address[] public admin = [0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,0xB9eF15e56A39fAc2a66431d88c7ef950652e6560
    ,0x936F3348c3035ea5530F0d959272DC6cC0402C44,0x91f6C69e532F199c4Fde2fb5F23456D505a7DaD5,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4];
function createPost( address payable _owner,
        string memory _title,
        string memory _description,
        //uint256 _upvotes,
        string memory _location ,
        string memory _image,
        uint256 _eventTime,
        //bool _showPublic,
        //bool _showAdmin,
        string memory _disasterName) public returns(uint256){
    Post  storage  post  = posts[postCount];

    //require( post.eventTime <= block.timestamp, "Time must be lesser  than current time");
    post.owner = payable(_owner);
    post.title = _title;
    post.description = _description;
    post.upvotes =0;
    post.location = _location;
    post.image = _image;
    post.eventTime = _eventTime;
    post.showPublic = false;
    post.showAdmin= true;
    post.disasterName = _disasterName;
    postCount++;
    
    return postCount -1;


}


function createDisaster( address _owner,
        string memory _name,
        string memory _description,
       // uint256 _amountCollected,
        string memory _location ,
        string memory _image,
        uint256 _startDate,
        uint256 _endDate,
        string memory _scale) public returns(uint256){
    Disaster  storage  disaster  = disasters[disasterCount];

    require( disaster.startDate <= block.timestamp, "Time must be lesser  than current time");
    disaster.owner = _owner;
    disaster.name = _name;
    disaster.description = _description;
    disaster.amountCollected =0;
    disaster.location = _location;
    disaster.image = _image;
    disaster.startDate = _startDate;
    disaster.endDate = _endDate;
    disaster.scale = _scale;
    disasterCount++;
    
    return disasterCount -1;
    }
    function createVolunteer( string memory _id,
        string memory _name) public returns(uint256){
    Volunteer  storage  volunteer  = volunteersList[volunteerCount];
    volunteer.id = _id;
    volunteer.name = _name;
    volunteerCount++;
    return volunteerCount -1;
        }
    function updateEndDate(uint256 _id, uint256 _date) public returns(bool){
        Disaster  storage  disaster  = disasters[_id];
        disaster.endDate = _date;
        return true;
    }
   function donateToDisaster(uint256 _id , uint256 amount) public payable {
         Disaster  storage  disaster  = disasters[_id];
         disaster.amountCollected += amount;
         disaster.donations.push(amount);
         disaster.donators.push(msg.sender);
         (bool sent, ) = (disaster.owner).call{value: amount}("");
          require(sent, "Failed to send Ether");
    }
function addItemsToDisaster(uint256 _id,string memory _name,uint256 _quantity) public returns(uint256){
    Disaster  storage  disaster  = disasters[_id];
    Item memory item = Item(_name,_quantity);
    disaster.items.push(item);
    return _id;
}
function updateItemsToDisaster(uint256 _id,string memory _name , uint256 _quantity) public returns(bool){
    Disaster  storage  disaster  = disasters[_id];
    for(uint i=0 ; i<disaster.items.length ; i++){
        if(keccak256(abi.encodePacked(disaster.items[i].name)) == keccak256(abi.encodePacked(_name))){
            disaster.items[i].quantity = _quantity;
            return true;
        }
    }
    return false;

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

//get disasters
function getDisasters() public view returns(Disaster[] memory){
    Disaster[] memory allDisasters = new Disaster[](disasterCount);
   for(uint i=0 ; i<disasterCount ; i++){
        Disaster storage item = disasters[i];
        allDisasters[i] = item;
   }
   return allDisasters;
}
function updatePublicView( uint256 _id ) public returns  (bool) {
    //require(msg.sender == police, "Only police can update the view");
    for(uint i=0 ; i<admin.length ; i++){
        if(msg.sender == admin[i]){
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
function updateAdmin(address adminAddress) public returns(bool){
    for(uint i=0 ; i<admin.length ; i++){
        if(msg.sender == admin[i]){
            admin.push(adminAddress);
            return true;
        }
    }
    return false;
}
function isAdmin(address _address) public view returns(bool){
    for(uint i=0 ; i<admin.length ; i++){
        if(_address == admin[i]){
            return true;
        }
    }
    return false;
}
function updateAdminView( uint256 _id ) public returns (bool) {
    //require(msg.sender == police, "Only police can update the view");
    for(uint i=0 ; i<admin.length ; i++){
        if(msg.sender == admin[i]){
            
            Post storage post = posts[_id];
            post.showAdmin = false;
            return true;
        }
    }
   
    
    return false;
}
function upvotePost( uint256 _id ) public payable returns (bool) {
    require( msg.value > 0.00001 ether, "Amount must be greater than 0.00001");
   uint256 amount = msg.value;
   Post storage post = posts[_id];
   //post.voters.push(msg.sender);
   post.upvotes+=1;
  
   (bool sent ,) = payable(admin[1]).call{value: amount}("");
   if(sent){
         return true;
   }
   return false;

    

    
}
function verifyVolunteer( string memory _id , string memory _name) public view returns (bool) {
    for(uint i=0 ; i<volunteerCount ; i++){

            Volunteer storage volunteer = volunteersList[i];
            if(keccak256(abi.encodePacked(volunteer.id)) == keccak256(abi.encodePacked(_id)) && keccak256(abi.encodePacked(volunteer.name)) == keccak256(abi.encodePacked(_name))){
                
                return true;
            }
          
        
    }
    return false;
}
}