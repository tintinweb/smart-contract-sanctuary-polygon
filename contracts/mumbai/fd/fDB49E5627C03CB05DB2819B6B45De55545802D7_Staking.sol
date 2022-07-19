/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Staking
 * Number of schemes : 1
 * Scheme functions : stake, unstake
 * Referral Scheme : 5, 2.5
*/

contract Staking {

	address owner;
	struct record { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record) public addressMap;
	mapping(uint256 => address) public addressStore;
	uint256 public lastAddress = 0;
	uint256 public dailyInterestRate = 20000;
	struct referralRecord { uint256 hasRef; address referringAddress; uint256 depositedAmt; }
	mapping(address => referralRecord) public referralRecordMap;
	event Staked (address account);
	event Unstaked (address account);

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
 * Function withdrawReferral
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (referralRecordMap with element the address that called this function with element depositedAmt) is greater than or equals to _amt
 * transfers _amt of the native currency to the address that called this function
 * updates referralRecordMap (Element the address that called this function) (Entity depositedAmt) as (referralRecordMap with element the address that called this function with element depositedAmt) - (_amt)
*/
	function withdrawReferral(uint256 _amt) public {
		require((referralRecordMap[msg.sender].depositedAmt >= _amt), "Insufficient referral rewards to withdraw");
		payable(msg.sender).transfer(_amt);
		referralRecordMap[msg.sender].depositedAmt  = (referralRecordMap[msg.sender].depositedAmt - _amt);
	}

/**
 * Function addReferral
 * The function takes in 1 variable, zero or a positive integer _amt. It can only be called by other functions in this contract. It does the following :
 * creates an internal variable referringAddress with initial value referralRecordMap with element the address that called this function with element referringAddress
 * if (referralRecordMap with element the address that called this function with element hasRef) is equals to 0 then (updates referralRecordMap (Element the address that called this function) (Entity hasRef) as 1)
 * if referringAddress is equals to Address 0 then ()
 * updates referralRecordMap (Element referringAddress) (Entity depositedAmt) as (referralRecordMap with element referringAddress with element depositedAmt) + ((5) * (_amt))
 * updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
 * if referringAddress is equals to Address 0 then ()
 * updates referralRecordMap (Element referringAddress) (Entity depositedAmt) as (referralRecordMap with element referringAddress with element depositedAmt) + (((25) * (_amt)) / (10))
 * updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
*/
	function addReferral(uint256 _amt) internal {
		address referringAddress = referralRecordMap[msg.sender].referringAddress;
		if ((referralRecordMap[msg.sender].hasRef == 0)){
			referralRecordMap[msg.sender].hasRef  = 1;
		}
		if ((referringAddress == address(0))){
			return;
		}
		referralRecordMap[referringAddress].depositedAmt  = (referralRecordMap[referringAddress].depositedAmt + (5 * _amt));
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
		if ((referringAddress == address(0))){
			return;
		}
		referralRecordMap[referringAddress].depositedAmt  = (referralRecordMap[referringAddress].depositedAmt + ((25 * _amt) / 10));
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
	}

/**
 * Function addReferralAddress
 * The function takes in 1 variable, an address _referringAddress. It can only be called by functions outside of this contract. It does the following :
 * checks that (referralRecordMap with element _referringAddress with element hasRef) is equals to 1
 * checks that not _referringAddress is equals to (the address that called this function)
 * checks that (referralRecordMap with element the address that called this function with element referringAddress) is equals to Address 0
 * updates referralRecordMap (Element the address that called this function) (Entity referringAddress) as _referringAddress
*/
	function addReferralAddress(address _referringAddress) external {
		require((referralRecordMap[_referringAddress].hasRef == 1), "Referring Address has not made a deposit");
		require(!((_referringAddress == msg.sender)), "Self-referrals are not allowed");
		require((referralRecordMap[msg.sender].referringAddress == address(0)), "User has previously indicated a referral address");
		referralRecordMap[msg.sender].referringAddress  = _referringAddress;
	}

/**
 * Function stake
 * Daily Interest Rate : Variable dailyInterestRate
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * if (thisRecord with element stakeAmt) is equals to 0 then (updates addressMap (Element the address that called this function) as Struct comprising current time, (amount of native currency sent to contract), current time, 0) otherwise (updates addressMap (Element the address that called this function) as Struct comprising current time, ((thisRecord with element stakeAmt) + (amount of native currency sent to contract)), current time, (thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate / 86400000000); then updates addressStore (Element lastAddress) as the address that called this function; and then updates lastAddress as (lastAddress) + (1))
 * calls addReferral with variable _amount as amount of native currency sent to contract
 * emits event Staked with inputs the address that called this function
*/
	function stake() public payable {
		record memory thisRecord = addressMap[msg.sender];
		if ((thisRecord.stakeAmt == 0)){
			addressMap[msg.sender]  = record (block.timestamp, msg.value, block.timestamp, 0);
		}else{
			addressMap[msg.sender]  = record (block.timestamp, (thisRecord.stakeAmt + msg.value), block.timestamp, thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate / 86400000000);
			addressStore[lastAddress]  = msg.sender;
			lastAddress  = (lastAddress + 1);
		}
		addReferral(msg.value);
		emit Staked(msg.sender);
	}

/**
 * Function unstake
 * The function takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
 * creates an internal variable newAccum with initial value thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate / 86400000000
 * creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
 * transfers (_unstakeAmt) + (interestToRemove) of the native currency to the address that called this function
 * if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat lastAddress times with loop variable i0 :  (if (addressStore with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore (Element Loop Variable i0) as addressStore with element (lastAddress) - (1); then updates lastAddress as (lastAddress) - (1); and then terminates the for-next loop)))
 * updates addressMap (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove))
 * emits event Unstaked with inputs the address that called this function
*/
	function unstake(uint256 _unstakeAmt) public {
		record memory thisRecord = addressMap[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		uint256 newAccum = thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate / 86400000000;
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		payable(msg.sender).transfer((_unstakeAmt + interestToRemove));
		if ((_unstakeAmt == thisRecord.stakeAmt)){
			for (uint i0 = 0; i0 < lastAddress; i0++){
				if ((addressStore[i0] == msg.sender)){
					addressStore[i0]  = addressStore[(lastAddress - 1)];
					lastAddress  = (lastAddress - 1);
					break;
				}
			}
		}
		addressMap[msg.sender]  = record (thisRecord.stakeTime, (thisRecord.stakeAmt - _unstakeAmt), thisRecord.lastUpdateTime, (newAccum - interestToRemove));
		emit Unstaked(msg.sender);
	}

/**
 * Function modifyDailyInterestRateWhere10000IsOnePercent
 * The function takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * repeat lastAddress times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap with element addressStore with element Loop Variable i0; and then updates addressMap (Element addressStore with element Loop Variable i0) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, (thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate / 86400000000))
 * updates dailyInterestRate as _dailyInterestRate
*/
	function modifyDailyInterestRateWhere10000IsOnePercent(uint256 _dailyInterestRate) public onlyOwner {
		for (uint i0 = 0; i0 < lastAddress; i0++){
			record memory thisRecord = addressMap[addressStore[i0]];
			addressMap[addressStore[i0]]  = record (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate / 86400000000);
		}
		dailyInterestRate  = _dailyInterestRate;
	}

/**
 * Function withdrawToken
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * transfers _amt of the native currency to the address that called this function
*/
	function withdrawToken(uint256 _amt) public onlyOwner {
		payable(msg.sender).transfer(_amt);
	}

	function sendMeNativeCurrency() external payable {
	}
}