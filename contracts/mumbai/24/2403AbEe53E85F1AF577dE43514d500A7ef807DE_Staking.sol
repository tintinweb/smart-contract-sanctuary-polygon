/**
 *Submitted for verification at polygonscan.com on 2022-07-22
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Staking
 * Number of schemes : 1
 * Scheme 1 functions : stake, unstake
*/

contract Staking {

	address owner;
	struct record { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record) public addressMap;
	mapping(uint256 => address) public addressStore;
	uint256 public lastAddress = 0;
	uint256 public dailyInterestRate = 30000;
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
 * Function stake
 * Daily Interest Rate : Variable dailyInterestRate
 * Address Map : addressMap
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (amount of native currency sent to contract) is strictly greater than 0
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * if (thisRecord with element stakeAmt) is equals to 0 then (updates addressMap (Element the address that called this function) as Struct comprising current time, (amount of native currency sent to contract), current time, 0; then updates addressStore (Element lastAddress) as the address that called this function; and then updates lastAddress as (lastAddress) + (1)) otherwise (updates addressMap (Element the address that called this function) as Struct comprising current time, ((thisRecord with element stakeAmt) + (amount of native currency sent to contract)), current time, (thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate / 86400000000))
 * emits event Staked with inputs the address that called this function
*/
	function stake() public payable {
		require((msg.value > 0), "Staked amount needs to be greater than 0");
		record memory thisRecord = addressMap[msg.sender];
		if ((thisRecord.stakeAmt == 0)){
			addressMap[msg.sender]  = record (block.timestamp, msg.value, block.timestamp, 0);
			addressStore[lastAddress]  = msg.sender;
			lastAddress  = (lastAddress + 1);
		}else{
			addressMap[msg.sender]  = record (block.timestamp, (thisRecord.stakeAmt + msg.value), block.timestamp, thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate / 86400000000);
		}
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