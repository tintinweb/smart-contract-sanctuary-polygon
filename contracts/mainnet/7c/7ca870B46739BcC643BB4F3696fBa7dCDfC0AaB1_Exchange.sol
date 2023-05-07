/**
 *Submitted for verification at polygonscan.com on 2023-05-06
*/

pragma solidity >=0.7.0 <0.9.0;



interface ERC20{
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Exchange {

	address owner;
	struct referralRecord { bool hasDeposited; address referringAddress; uint256 unclaimedRewards1To2; uint256 referralsAmt1To2AtLevel0; uint256 referralsCount1To2AtLevel0; }
	mapping(address => referralRecord) public referralRecordMap;
	event ReferralAddressAdded (address indexed referredAddress);
	uint256 public exchange1To2rate = uint256(1400000000000000000000);
	uint256 public totalUnclaimedRewards1To2 = uint256(0);
	uint256 public totalClaimedRewards1To2 = uint256(0);
	event Exchanged (address indexed tgt);

	constructor() {
		owner = msg.sender;
	}

	//This function allows the owner to specify an address that will take over ownership rights instead. Please double check the address provided as once the function is executed, only the new owner will be able to change the address back.
	function changeOwner(address _newOwner) public onlyOwner {
		owner = _newOwner;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

/**
 * Function changeValueOf_exchange1To2rate
 * Notes for _exchange1To2rate : Number of Native Token (1 Native Token is represented by 10^18) to 1 Coin mpolToken (represented by 1).
 * The function takes in 1 variable, (zero or a positive integer) _exchange1To2rate. It can only be called by functions outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * updates exchange1To2rate as _exchange1To2rate
*/
	function changeValueOf_exchange1To2rate(uint256 _exchange1To2rate) external onlyOwner {
		exchange1To2rate  = _exchange1To2rate;
	}

/**
 * Function exchange1To2
 * Minimum Exchange Amount : 10000000000000000000 in terms of Native Token. 1 Native Token is represented by 10^18.
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (amount of native currency sent to contract) is greater than or equals to 10000000000000000000
 * calls addReferral1To2 with variable _amt as (amount of native currency sent to contract)
 * checks that (amount of native currency owned by the address of this contract) is greater than or equals to (((amount of native currency sent to contract) * (100) * (10000)) / (100000000))
 * if (((amount of native currency sent to contract) * (100) * (10000)) / (100000000)) is strictly greater than 0 then (transfers ((amount of native currency sent to contract) * (100) * (10000)) / (100000000) of the native currency to Address 0x3d7F628252Aa4F655A7394aE34952fA1E9573Ff6)
 * checks that (ERC20(Address 0x5cB4ce8F60beDB05Aee2d47959276adcB735f21a)'s at balanceOf function  with variable recipient as (the address of this contract)) is greater than or equals to (((((amount of native currency sent to contract) * ((1000000) - (10000))) / (1000000)) * (exchange1To2rate)) / (1000000000000000000))
 * if (((((amount of native currency sent to contract) * ((1000000) - (10000))) / (1000000)) * (exchange1To2rate)) / (1000000000000000000)) is strictly greater than 0 then (calls ERC20(Address 0x5cB4ce8F60beDB05Aee2d47959276adcB735f21a)'s at transfer function  with variable recipient as (the address that called this function), variable amount as (((((amount of native currency sent to contract) * ((1000000) - (10000))) / (1000000)) * (exchange1To2rate)) / (1000000000000000000)))
 * emits event Exchanged with inputs the address that called this function
*/
	function exchange1To2() public payable {
		require((msg.value >= uint256(10000000000000000000)), "Too little exchanged");
		addReferral1To2(msg.value);
		require((address(this).balance >= ((msg.value * uint256(100) * uint256(10000)) / uint256(100000000))), "Insufficient amount of native currency in this contract to transfer out. Please contact the contract owner to top up the native currency.");
		if ((((msg.value * uint256(100) * uint256(10000)) / uint256(100000000)) > uint256(0))){
			payable(address(0x3d7F628252Aa4F655A7394aE34952fA1E9573Ff6)).transfer(((msg.value * uint256(100) * uint256(10000)) / uint256(100000000)));
		}
		require((ERC20(address(0x5cB4ce8F60beDB05Aee2d47959276adcB735f21a)).balanceOf(address(this)) >= ((((msg.value * (uint256(1000000) - uint256(10000))) / uint256(1000000)) * exchange1To2rate) / uint256(1000000000000000000))), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		if ((((((msg.value * (uint256(1000000) - uint256(10000))) / uint256(1000000)) * exchange1To2rate) / uint256(1000000000000000000)) > uint256(0))){
			ERC20(address(0x5cB4ce8F60beDB05Aee2d47959276adcB735f21a)).transfer(msg.sender, ((((msg.value * (uint256(1000000) - uint256(10000))) / uint256(1000000)) * exchange1To2rate) / uint256(1000000000000000000)));
		}
		emit Exchanged(msg.sender);
	}

/**
 * Function withdrawReferral1To2
 * The function takes in 1 variable, (zero or a positive integer) _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (referralRecordMap with element the address that called this function with element unclaimedRewards1To2) is greater than or equals to _amt
 * updates referralRecordMap (Element the address that called this function) (Entity unclaimedRewards1To2) as (referralRecordMap with element the address that called this function with element unclaimedRewards1To2) - (_amt)
 * updates totalUnclaimedRewards1To2 as (totalUnclaimedRewards1To2) - (_amt)
 * updates totalClaimedRewards1To2 as (totalClaimedRewards1To2) + (_amt)
 * checks that (amount of native currency owned by the address of this contract) is greater than or equals to _amt
 * if _amt is strictly greater than 0 then (transfers _amt of the native currency to the address that called this function)
*/
	function withdrawReferral1To2(uint256 _amt) public {
		require((referralRecordMap[msg.sender].unclaimedRewards1To2 >= _amt), "Insufficient referral rewards to withdraw");
		referralRecordMap[msg.sender].unclaimedRewards1To2  = (referralRecordMap[msg.sender].unclaimedRewards1To2 - _amt);
		totalUnclaimedRewards1To2  = (totalUnclaimedRewards1To2 - _amt);
		totalClaimedRewards1To2  = (totalClaimedRewards1To2 + _amt);
		require((address(this).balance >= _amt), "Insufficient amount of native currency in this contract to transfer out. Please contact the contract owner to top up the native currency.");
		if ((_amt > uint256(0))){
			payable(msg.sender).transfer(_amt);
		}
	}

/**
 * Function addReferral1To2
 * The function takes in 1 variable, (zero or a positive integer) _amt. It can only be called by other functions in this contract. It does the following :
 * creates an internal variable referringAddress with initial value referralRecordMap with element the address that called this function with element referringAddress
 * creates an internal variable referralsAllocated with initial value 0
 * if not referralRecordMap with element the address that called this function with element hasDeposited then (updates referralRecordMap (Element the address that called this function) (Entity hasDeposited) as true)
 * if referringAddress is equals to Address 0 then (returns referralsAllocated as output)
 * updates referralRecordMap (Element referringAddress) (Entity referralsAmt1To2AtLevel0) as (referralRecordMap with element referringAddress with element referralsAmt1To2AtLevel0) + (_amt)
 * updates referralRecordMap (Element referringAddress) (Entity referralsCount1To2AtLevel0) as (referralRecordMap with element referringAddress with element referralsCount1To2AtLevel0) + (1)
 * updates referralRecordMap (Element referringAddress) (Entity unclaimedRewards1To2) as (referralRecordMap with element referringAddress with element unclaimedRewards1To2) + (((12) * (_amt)) / (10000))
 * updates referralsAllocated as (referralsAllocated) + (((12) * (_amt)) / (10000))
 * updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
 * updates totalUnclaimedRewards1To2 as (totalUnclaimedRewards1To2) + (referralsAllocated)
 * returns referralsAllocated as output
*/
	function addReferral1To2(uint256 _amt) internal returns (uint256) {
		address referringAddress = referralRecordMap[msg.sender].referringAddress;
		uint256 referralsAllocated = uint256(0);
		if (!(referralRecordMap[msg.sender].hasDeposited)){
			referralRecordMap[msg.sender].hasDeposited  = true;
		}
		if ((referringAddress == address(0))){
			return referralsAllocated;
		}
		referralRecordMap[referringAddress].referralsAmt1To2AtLevel0  = (referralRecordMap[referringAddress].referralsAmt1To2AtLevel0 + _amt);
		referralRecordMap[referringAddress].referralsCount1To2AtLevel0  = (referralRecordMap[referringAddress].referralsCount1To2AtLevel0 + uint256(1));
		referralRecordMap[referringAddress].unclaimedRewards1To2  = (referralRecordMap[referringAddress].unclaimedRewards1To2 + ((uint256(12) * _amt) / uint256(10000)));
		referralsAllocated  = (referralsAllocated + ((uint256(12) * _amt) / uint256(10000)));
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
		totalUnclaimedRewards1To2  = (totalUnclaimedRewards1To2 + referralsAllocated);
		return referralsAllocated;
	}

/**
 * Function withdrawToken1
 * The function takes in 1 variable, (zero or a positive integer) _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * checks that (amount of native currency owned by the address of this contract) is greater than or equals to ((_amt) + (totalUnclaimedRewards1To2))
 * if _amt is strictly greater than 0 then (transfers _amt of the native currency to the address that called this function)
*/
	function withdrawToken1(uint256 _amt) public onlyOwner {
		require((address(this).balance >= (_amt + totalUnclaimedRewards1To2)), "Insufficient amount of native currency in this contract to transfer out. Please contact the contract owner to top up the native currency.");
		if ((_amt > uint256(0))){
			payable(msg.sender).transfer(_amt);
		}
	}

/**
 * Function withdrawToken2
 * The function takes in 1 variable, (zero or a positive integer) _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * checks that (ERC20(Address 0x5cB4ce8F60beDB05Aee2d47959276adcB735f21a)'s at balanceOf function  with variable recipient as (the address of this contract)) is greater than or equals to _amt
 * if _amt is strictly greater than 0 then (calls ERC20(Address 0x5cB4ce8F60beDB05Aee2d47959276adcB735f21a)'s at transfer function  with variable recipient as (the address that called this function), variable amount as _amt)
*/
	function withdrawToken2(uint256 _amt) public onlyOwner {
		require((ERC20(address(0x5cB4ce8F60beDB05Aee2d47959276adcB735f21a)).balanceOf(address(this)) >= _amt), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		if ((_amt > uint256(0))){
			ERC20(address(0x5cB4ce8F60beDB05Aee2d47959276adcB735f21a)).transfer(msg.sender, _amt);
		}
	}

/**
 * Function addReferralAddress
 * The function takes in 1 variable, (an address) _referringAddress. It can only be called by functions outside of this contract. It does the following :
 * checks that referralRecordMap with element _referringAddress with element hasDeposited
 * checks that not _referringAddress is equals to (the address that called this function)
 * checks that (referralRecordMap with element the address that called this function with element referringAddress) is equals to Address 0
 * updates referralRecordMap (Element the address that called this function) (Entity referringAddress) as _referringAddress
 * emits event ReferralAddressAdded with inputs the address that called this function
*/
	function addReferralAddress(address _referringAddress) external {
		require(referralRecordMap[_referringAddress].hasDeposited, "Referring Address has not made a deposit");
		require(!((_referringAddress == msg.sender)), "Self-referrals are not allowed");
		require((referralRecordMap[msg.sender].referringAddress == address(0)), "User has previously indicated a referral address");
		referralRecordMap[msg.sender].referringAddress  = _referringAddress;
		emit ReferralAddressAdded(msg.sender);
	}
}