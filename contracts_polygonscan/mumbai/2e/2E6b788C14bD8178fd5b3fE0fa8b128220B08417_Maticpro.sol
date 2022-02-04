/**
 *Submitted for verification at polygonscan.com on 2022-02-03
*/

pragma solidity 0.5.10;

/*

The new blockchain technology facilitates peer-to-peer transactions without any intermediary 
such as a bank or governing body. Keeping the user's information anonymous, the blockchain 
validates and keeps a permanent public record of all transactions.

Publish Date:04Feb 2022
Final Publish Date:04Feb 2022
Coding Level: High
MATIC PRO COMMUNITY

*/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    
}

/*=====================================
=            CONFIGURABLES            =
=====================================*/


contract Maticpro{
    
     struct User {
        uint id;
        address referrer;
        mapping(uint8 => bool) activePackage;
    }

    uint8 public constant LAST_PACKAGE = 5;
    
    mapping(address => User) public users;
    
    mapping(uint8 => uint) public packagePrice;

    uint public lastUserId = 1;
    
    address public owner;

    address constant public adminChargeWalletAddress=0x2Fe099E770EB116C072592aF4cfC530350ba6a14;

    address constant public comminityDistributionWalletAddress=0x8EFa76d5654Da8DC428D1d862C690603c654c7bB;
    
    string public projectName = "Maticpro";
    string public projectURL = "https://maticpro.io";

    uint8 constant public investmentAdmincharge_ = 5;

    uint8 constant public investmentCommunityDistribution_ = 95;

    event PurchasePackage(address indexed user,uint8 package);

    event Registration(address indexed user, address indexed referrer,uint8 package);
    
    event WithdrawMatic();

    constructor() public {

    address ownerAddress=0xa28040b624581Fdc83360dd39BE09254956d2333;

    packagePrice[1] = 25;
    packagePrice[2] = 50;
    packagePrice[3] = 100;
    packagePrice[4] = 200;
    packagePrice[5] = 500;

    owner = ownerAddress;
        
    User memory user = User({
        id: 1,
        referrer: address(0)
    });
        
    for (uint8 i = 1; i <= LAST_PACKAGE; i++) {
        users[ownerAddress].activePackage[i] = true;
    } 
        
    users[ownerAddress] = user;

    }

    function registrationExt(address referrerAddress,uint8 package) external payable {
        registration(msg.sender, referrerAddress,package);
    }
    
    
    function WithdrawalMaticExt() external payable {
         withdrawMatic();
    }
    
    
    function upgradePackage(uint8 package) external payable {
            
        require(checkUserExists(msg.sender), "User Not Exists. Need To Register First.");
        
        require(!users[msg.sender].activePackage[package], "You Have Already Purchased");
        
        require(package >= 1 && package <= LAST_PACKAGE, "Invalid Package");
        
        users[msg.sender].activePackage[package] = true;
       
        capturePackage(msg.sender,msg.value);
            
        emit PurchasePackage(msg.sender,package);
            
    } 
    
    
    function registration(address userAddress, address referrerAddress,uint8 package) private {
        
        require(!checkUserExists(userAddress), "You Have Already Registered !");
        
        require(checkUserExists(referrerAddress), "Referral Not Exists !");
        
        require(msg.value == packagePrice[package]*1000000000000000000 , "Invalid Registration Cost");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress
        });

        users[userAddress] = user;

        users[userAddress].referrer = referrerAddress;
       
        lastUserId++;

        capturePackage(msg.sender,msg.value);

        emit Registration(userAddress, referrerAddress,package);
    }
    
    function capturePackage(address userAddress,uint256 _incomingMatic) private {
        sendMaticDividends(_incomingMatic);
    }
    
    function checkUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function sendMaticDividends(uint256 _incomingMatic) private {
        uint256 _adminDividends = calculateFee(_incomingMatic,investmentAdmincharge_);
        uint256 _communityDividends = calculateFee(_incomingMatic,investmentCommunityDistribution_);
        address(uint160(adminChargeWalletAddress)).send(_adminDividends);
        address(uint160(comminityDistributionWalletAddress)).send(_communityDividends);
    }

    function withdrawMatic() public returns (uint256 ){
        
        require(msg.sender ==  address(uint160(owner)) ,"Do Not Try To Call From Other Way OR You Are Not Authorized To Call.");
        
        require(checkUserExists(msg.sender), "You Have Not Registered Yet !");

        uint256 _incomingMatic=address(this).balance;
        uint256 _adminDividends = calculateFee(_incomingMatic,investmentAdmincharge_);
        uint256 _communityDividends = calculateFee(_incomingMatic,investmentCommunityDistribution_);
        address(uint160(adminChargeWalletAddress)).send(_adminDividends);
        address(uint160(comminityDistributionWalletAddress)).send(_communityDividends);
        
        emit WithdrawMatic();
    }

    function calculateFee(uint256 _amount,uint256 _taxFee) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(_amount,_taxFee),10**2);
    }
}