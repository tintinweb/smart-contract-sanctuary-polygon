/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

contract Staking {

	address owner;
	struct record0 { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record0) public addressMap0;
	mapping(uint256 => address) public addressStore0;
	uint256 public lastAddress0 = 0;
	uint256 public dailyInterestRate0 = 10000;
	uint256 public minStakePeriod0 = (300 * 864);
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

	//This function allows the owner to change the value of dailyInterestRate0.
	function changeValueOf_dailyInterestRate0 (uint256 _dailyInterestRate0) external onlyOwner {
		 dailyInterestRate0 = _dailyInterestRate0;
	}

	//This function allows the owner to change the value of minStakePeriod0.
	function changeValueOf_minStakePeriod0 (uint256 _minStakePeriod0) external onlyOwner {
		 minStakePeriod0 = _minStakePeriod0;
	}

	//The function withdrawReferral takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. This function does the following : 
		//creates an internal variable thisRecord with initial value referralRecordMap with element the address that called this function
		//checks that (thisRecord with element depositedAmt) is greater than or equals to _amt
		//transfers _amt of the native currency to the address that called this function
		//updates thisRecord (Entity depositedAmt) as (thisRecord with element depositedAmt) - (_amt)
	function withdrawReferral(uint256 _amt) public {
		referralRecord memory thisRecord = referralRecordMap[msg.sender];
		require((thisRecord.depositedAmt >= _amt), "Insufficient referral rewards to withdraw");
		payable(msg.sender).transfer(_amt);
		thisRecord.depositedAmt  = (thisRecord.depositedAmt - _amt);
	}

	//The function addReferral takes in 2 variables, zero or a positive integer _amt, and an address _referringAddress. It can only be called by other functions in this contract. This function does the following : 
		//checks that (referralRecordMap with element _referringAddress with element hasRef) is equals to 1
		//checks that not _referringAddress is equals to (the address that called this function)
		//creates an internal variable referringAddress with initial value _referringAddress
		//if (referralRecordMap with element the address that called this function with element hasRef) is equals to 0 then (updates referralRecordMap (Element the address that called this function) as Struct comprising 1, _referringAddress, 0) otherwise (updates referringAddress as referralRecordMap with element the address that called this function with element referringAddress)
		//updates referralRecordMap (Element referringAddress) (Entity depositedAmt) as (referralRecordMap with element referringAddress with element depositedAmt) + (50000000000000000 * _amt / 1000000000000000000)
		//updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
		//if referringAddress is equals to Address 0 then ()
		//updates referralRecordMap (Element referringAddress) (Entity depositedAmt) as (referralRecordMap with element referringAddress with element depositedAmt) + (25000000000000000 * _amt / 1000000000000000000)
		//updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
	function addReferral(uint256 _amt, address _referringAddress) internal {
		require((referralRecordMap[_referringAddress].hasRef == 1), "Referring Address has not made a deposit");
		require(!((_referringAddress == msg.sender)), "Self-referrals are not allowed");
		address referringAddress = _referringAddress;
		if ((referralRecordMap[msg.sender].hasRef == 0)){
			referralRecordMap[msg.sender]  = referralRecord (1, _referringAddress, 0);
		}else{
			referringAddress  = referralRecordMap[msg.sender].referringAddress;
		}
		referralRecordMap[referringAddress].depositedAmt  = (referralRecordMap[referringAddress].depositedAmt + 50000000000000000 * _amt / 1000000000000000000);
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
		if ((referringAddress == address(0))){
			return;
		}
		referralRecordMap[referringAddress].depositedAmt  = (referralRecordMap[referringAddress].depositedAmt + 25000000000000000 * _amt / 1000000000000000000);
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
	}

	//The function stake0 takes in 1 variable, an address _referringAddress. It can be called by functions both inside and outside of this contract. This function does the following : 
		//creates an internal variable thisRecord with initial value addressMap0 with element the address that called this function
		//checks that (thisRecord with element stakeAmt) is equals to 0
		//updates addressMap0 (Element the address that called this function) as Struct comprising current time, (amount of native currency sent to contract), current time, 0
		//calls addReferral with variable _amountt as amount of native currency sent to contract, variable _referringAddress as _referringAddress
		//emits event Staked with inputs the address that called this function
	function stake0(address _referringAddress) public payable {
		record0 memory thisRecord = addressMap0[msg.sender];
		require((thisRecord.stakeAmt == 0), "Need to unstake before restaking");
		addressMap0[msg.sender]  = record0 (block.timestamp, msg.value, block.timestamp, 0);
		addReferral(msg.value, _referringAddress);
		emit Staked(msg.sender);
	}

	//The function unstake0 takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. This function does the following : 
		//creates an internal variable thisRecord with initial value addressMap0 with element the address that called this function
		//checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
		//checks that ((current time) - (minStakePeriod0)) is greater than or equals to (thisRecord with element stakeTime)
		//creates an internal variable newAccum with initial value thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate0 / 86400000000
		//creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
		//transfers _unstakeAmt + interestToRemove of the native currency to the address that called this function
		//if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat lastAddress0 times with loop variable i0 :  (if (addressStore0 with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore0 (Element Loop Variable i0) as addressStore0 with element (lastAddress0) - (1); then updates lastAddress0 as (lastAddress0) - (1); and then terminates the for-next loop)))
		//updates addressMap0 (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove))
		//emits event Unstaked with inputs the address that called this function
	function unstake0(uint256 _unstakeAmt) public {
		record0 memory thisRecord = addressMap0[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		require(((block.timestamp - minStakePeriod0) >= thisRecord.stakeTime), "Insufficient stakeperiod");
		uint256 newAccum = thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate0 / 86400000000;
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		payable(msg.sender).transfer(_unstakeAmt + interestToRemove);
		if ((_unstakeAmt == thisRecord.stakeAmt)){
			for (uint i0 = 0; i0 < lastAddress0; i0++){
				if ((addressStore0[i0] == msg.sender)){
					addressStore0[i0]  = addressStore0[(lastAddress0 - 1)];
					lastAddress0  = (lastAddress0 - 1);
					break;
				}
			}
		}
		addressMap0[msg.sender]  = record0 (thisRecord.stakeTime, (thisRecord.stakeAmt - _unstakeAmt), thisRecord.lastUpdateTime, (newAccum - interestToRemove));
		emit Unstaked(msg.sender);
	}

	//The function modifyDailyInterestRate0 takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. This function does the following : 
		//checks that the function is called by the owner of the contract
		//repeat lastAddress0 times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap0 with element addressStore0 with element Loop Variable i0; then updates addressMap0 (Element addressStore0 with element Loop Variable i0) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, (thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate0 / 86400000000); and then updates dailyInterestRate0 as _dailyInterestRate)
	function modifyDailyInterestRate0(uint256 _dailyInterestRate) public onlyOwner {
		for (uint i0 = 0; i0 < lastAddress0; i0++){
			record0 memory thisRecord = addressMap0[addressStore0[i0]];
			addressMap0[addressStore0[i0]]  = record0 (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate0 / 86400000000);
			dailyInterestRate0  = _dailyInterestRate;
		}
	}

	//The function withdrawToken takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. This function does the following : 
		//checks that the function is called by the owner of the contract
		//transfers _amt of the native currency to the address that called this function
	function withdrawToken(uint256 _amt) public onlyOwner {
		payable(msg.sender).transfer(_amt);
	}
}