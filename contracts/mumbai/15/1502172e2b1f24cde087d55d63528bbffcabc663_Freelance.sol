/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Freelance 
{
    address public owner;
    mapping(uint256 => address) public users;
    mapping(address => bool) public approved;
    mapping(address => string) public userType;
    uint256 public totalUsers;

    struct Projects 
    {
        address bidder;
        uint256 price;
    }

    struct OrderBetween
    {
        uint start;
        uint end;
        address seller;
        address buyer;
    }

    mapping(address => string) public projectRequestId;
    mapping(string => bool) public projectRequestActive;
    mapping(string => Projects[]) public offers;
    mapping(string => string) public projectStatus;
    mapping(string => OrderBetween[]) public OrderUsers;
    mapping(address => uint256) public userEarnings;
    mapping(string => uint256) public projectPrice;

    uint public feePercentage = 2;
    uint256 public tax;

    constructor()
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
   
    function whiteListedUsers(address _user, string memory _type) public 
    {
        require(_user != address(0),"Invalid User address");
        require(approved[_user] != true, "Already whitelisted");
        users[totalUsers] = _user;
        approved[_user] = true;
        userType[_user] = _type; //type will be seller or buyer
        totalUsers++;
    }

    function changeUserType(address _user, string memory _type) public 
    {
        require(_user != address(0),"Invalid User address");
        require(approved[_user] != false, "User not whitelisted");

        userType[_user] = _type; //type will be seller or buyer
    }

    function projectRequest(string memory _id) public
    {
        if(keccak256(abi.encodePacked(userType[msg.sender])) == keccak256(abi.encodePacked("buyer")))
        {
            projectRequestId[msg.sender] = _id;
            projectRequestActive[_id] = true;
        }
        else 
        {
            revert("Only buyer can request");
        }
    }

    function bidding(string memory _id, address _bidder, uint256 _price) public 
    {
        require(projectRequestActive[_id] != false, "Project Request Expired");
        if(keccak256(abi.encodePacked(userType[msg.sender])) == keccak256(abi.encodePacked("seller")))
        {
            Projects memory objects;
            objects.bidder = _bidder;
            objects.price = _price;

            offers[_id].push(objects);
        }
        else 
        {
            revert("Only Seller can bid");
        }
    }

    function order(string memory _pid, address _seller, address _buyer, uint256 _price, uint _end) public {
        OrderBetween memory objects;
        objects.start = block.timestamp;
        objects.end = _end + block.timestamp;
        objects.seller = _seller;
        objects.buyer = _buyer;

        OrderUsers[_pid].push(objects);
        projectPrice[_pid] = _price;
        projectStatus[_pid] = "progress";
    }

    function orderSubmission(string memory _pid, string memory _status, address _seller) public payable
    {
        if(keccak256(abi.encodePacked(projectStatus[_pid])) != keccak256(abi.encodePacked("complete")))
        {
            if(keccak256(abi.encodePacked(_status)) == keccak256(abi.encodePacked("complete")))
            {
                require(msg.value >= projectPrice[_pid], "Pay order must be equal to price");
                tax = msg.value * feePercentage / 100;
                uint amount = msg.value - tax;
                payable(_seller).transfer(amount);
                uint256 earning = userEarnings[_seller];
                userEarnings[_seller] = earning + amount;
            }

            projectStatus[_pid] = _status;
        }
        else 
        {
            revert("Project is completed");
        }
        
    }

    function setFeePercentage(uint _num) public onlyOwner
    {
        feePercentage = _num;
    }
    
    
}