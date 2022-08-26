//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract SolidityDevs{
    mapping(address => bool) internal owner;
    struct Dev{
        string name;
        uint256 score;
        address wallet;
        uint256[] ratings;
        bool active;
    }
    uint256 public counter;
    Dev[] public allDevs;
    mapping(uint256 => Dev) private devs;
    address private fundManager;


    event DevCreated(string indexed name, address owner);
    event DevDeleted(string indexed name, address owner);
    event DevRated(string indexed name, address owner, uint256 rating);
    event Donated(address donator, uint256 amount);

    constructor(){
        owner[msg.sender] = true;
        fundManager = msg.sender;
    }

    function addOwner(address _address)  external{
        require(owner[msg.sender], "Only owner can call");
        owner[_address] = true;
    }

    function createDev(string memory _name, address _address) external {  
        require(owner[msg.sender], "Only owner can call");   
        uint256[] memory arr = new uint256[](0);
        devs[counter] = Dev(_name, 0, _address, arr, true);
        allDevs.push(devs[counter]);
        counter ++;
        emit DevCreated(_name, msg.sender);
    }

    function viewDev(uint256 _id) public view returns(Dev memory){
        return devs[_id];
    }

    function getAllDevs() view public returns(Dev[] memory){
        return allDevs;
    }
 
    function viewRatings(uint256 _id) public view returns(uint256[] memory){
        Dev storage dev = devs[_id];
        return dev.ratings;
    }

    function rateDev(uint256 _id, uint256 _rating) external {
        require(owner[msg.sender], "Only owner can call"); 
        Dev storage dev = devs[_id];
        require(dev.active, "This dev is not active");
        require(_rating > 0 && _rating <=10, "Must be a rating between 1-10");
        dev.ratings.push(_rating);
        uint256 average = 0;
        for(uint256 i = 0; i <dev.ratings.length; i++){
            average += dev.ratings[i];
        }
        dev.score = average *100 / dev.ratings.length;

        emit DevRated(dev.name, msg.sender, _rating);
    }

    function deleteDev(uint256 _id) external{
        require(owner[msg.sender], "Only owner can call"); 
        Dev storage dev = devs[_id];
        require(dev.active, "This dev is not active");
        dev.active = !dev.active;
        emit DevDeleted(dev.name, msg.sender);
    }

     receive() external payable{
         emit Donated(msg.sender, msg.value);
     }

    function withdraw() external{
        require(msg.sender == fundManager, "You cannot withdraw");
          (bool success,) = payable(fundManager).call{value: address(this).balance}("");
          require(success, "Transfer Failed");
    }

    function changeFundManager(address _address) external{
        require(msg.sender == fundManager, "You cannot withdraw");
        fundManager = _address;
    }

}