/**
 *Submitted for verification at polygonscan.com on 2023-07-29
*/

interface so23 {
  function getReferralAmount(address _address) external view returns (uint);
  function setReferralValue(address _address, uint _value) external;  
} 

pragma solidity ^0.6.0;
 
contract SO23Referral {
    uint256 public _percentage = 30;
	uint256 public _decimals = 100;
	uint256 public _totalPaid = 0;
    address public owner;
	address public outerAddress;
	address public so23ContractAddress;
	so23 public so23Contract;
	bool public payoutsBlocked = false;
	bool public whitelistOnly = false;
    
    event Payout(address indexed _from, uint256 _value);
	
	mapping(address => uint256) referralsPayoutHistory;
	mapping(address => uint256) referralsLastPayoutDate;
	
	address[] referralsPaid;
	address[] whitelist;
 
    constructor(address _so23main) public {
        owner = msg.sender; 
		outerAddress = msg.sender;
		so23ContractAddress =_so23main;
		so23Contract = so23(_so23main);
    }
   
    function percentage() public view returns (uint256) {        
        return _percentage;
    }
	
	function decimals() public view returns (uint256) {        
        return _decimals;
    }
	
	function getReferralsPaidLength() public view returns (uint256) {        
        return referralsPaid.length;
    }
	
	function getReferralsPaidAt(uint i) public view returns (address) {        
        return referralsPaid[i];
    }
	
	function getWhitelistLength() public view returns (uint256) {        
        return whitelist.length;
    }
	
	function getWhitelistAt(uint i) public view returns (address) {        
        return whitelist[i];
    }
	
	function isOnWhiteList(address _address) public view returns (bool, uint) {        
        bool found = false;
		uint index = 0;
		
		for (uint i = 0; i < whitelist.length; i++)
		{
			if (whitelist[i] == _address)
			{
				found = true;
				index = i;
			}
		}
		
		return (found, index);		
    }	
	
	function getReferralsPayoutHistory(address _address) public view returns (uint) {        
        return referralsPayoutHistory[_address];
    }
	
	function getReferralsLastPayoutDate(address _address) public view returns (uint) {        
        return referralsLastPayoutDate[_address];
    }
 
    function balanceOfReferralNet(address _address) public view returns (uint256 balance) {
        return so23Contract.getReferralAmount(_address) * (_percentage / _decimals);
    }
	
	function balanceOfReferralGross(address _address) public view returns (uint256 balance) {
        return so23Contract.getReferralAmount(_address);
    }
 
    function payout() public {
        if (so23Contract.getReferralAmount(msg.sender) <= 0) revert('amount cannot be zero');
		if (msg.sender == 0x0000000000000000000000000000000000000000) revert('invalid sender');
		if (payoutsBlocked) revert('payouts blocked');
		
		if (whitelistOnly)
		{
			bool found = false;
			for (uint i = 0; i < whitelist.length; i++)
			{
				if (whitelist[i] == msg.sender)
					found = true;
			}
			if (!found) revert('not found in whitelist');
		}
		
		uint amountToPay = balanceOfReferralNet(msg.sender);
		
		address payable add = payable(msg.sender);
		if(!add.send(amountToPay)) revert();
		
		so23Contract.setReferralValue(msg.sender, 0);
		
		if (referralsPayoutHistory[msg.sender] == 0)
			referralsPaid.push(msg.sender);
		
		referralsPayoutHistory[msg.sender] += amountToPay;
		
		referralsLastPayoutDate[msg.sender] = block.timestamp;
		
		_totalPaid += amountToPay;
		
		emit Payout(msg.sender, amountToPay);
    }
	
	function release() public
	{
		if (msg.sender != owner) revert();
		address payable add = payable(outerAddress);
		if(!add.send(address(this).balance)) revert();
	}
	
	function setOuterAddress(address _address) public
	{
		if(msg.sender == owner)
			outerAddress = _address;
		else
			revert();
	}
	
	function setPercentage(uint value) public
	{
		if(msg.sender == owner)
			_percentage = value;
		else
			revert();
	}
	
	function setDecimals(uint value) public
	{
		if(msg.sender == owner)
			_decimals = value;
		else
			revert();
	}   

	function setWhitelist(address _address) public
	{
		if(msg.sender == owner)
			whitelist.push(_address);
		else
			revert();
	}   
	
	function setWhitelistAt(address _address, uint i) public
	{
		if(msg.sender == owner)
			whitelist[i] = _address;
		else
			revert();
	}   
	
	function removeFromWhitelist(address _address) public
	{
		if (!(msg.sender == owner)) revert();
		
		uint removed = 0;
		
		for (uint i = 0; i < whitelist.length; i++)
		{
			if (whitelist[i] == _address)
			{
				whitelist[i] = 0x0000000000000000000000000000000000000000;
				removed++;
			}
		}
		
		if (removed == 0) revert('not found');		
	}   
}