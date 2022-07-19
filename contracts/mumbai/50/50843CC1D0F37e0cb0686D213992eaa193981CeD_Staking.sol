/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Staking
 * Number of schemes : 4
 * Scheme 1 functions : stake1, unstake1
 * Scheme 2 functions : stake2, unstake2
 * Scheme 3 functions : stake3, unstake3
 * Scheme 4 functions : stake4, unstake4
 * Referral Scheme : 0.08, 0.02
*/
library Interest {

   function add(uint x, uint y) internal pure returns (uint z) {
		require((z = x + y) >= x, "ds-math-add-overflow");
	}
	function sub(uint x, uint y) internal pure returns (uint z) {
		require((z = x - y) <= x, "ds-math-sub-underflow");
	}
	function mul(uint x, uint y) internal pure returns (uint z) {
		require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
	}

	function min(uint x, uint y) internal pure returns (uint z) {
		return x <= y ? x : y;
	}
	function max(uint x, uint y) internal pure returns (uint z) {
		return x >= y ? x : y;
	}
	function imin(int x, int y) internal pure returns (int z) {
		return x <= y ? x : y;
	}
	function imax(int x, int y) internal pure returns (int z) {
		return x >= y ? x : y;
	}

	uint constant WAD = 10 ** 18;
	uint constant RAY = 10 ** 27;

	function wmul(uint x, uint y) internal pure returns (uint z) {
		z = add(mul(x, y), WAD / 2) / WAD;
	}
	function rmul(uint x, uint y) internal pure returns (uint z) {
		z = add(mul(x, y), RAY / 2) / RAY;
	}
	function wdiv(uint x, uint y) internal pure returns (uint z) {
		z = add(mul(x, WAD), y / 2) / y;
	}
	function rdiv(uint x, uint y) internal pure returns (uint z) {
		z = add(mul(x, RAY), y / 2) / y;
	}

	function rpow(uint x, uint n) internal pure returns (uint z) {
		z = n % 2 != 0 ? x : RAY;

		for (n /= 2; n != 0; n /= 2) {
			x = rmul(x, x);

			if (n % 2 != 0) {
				z = rmul(z, x);
			}
		}
	}

	function wadToRay(uint _wad) internal pure returns (uint) {
		return mul(_wad, 10 ** 9);
	}

	function weiToRay(uint _wei) internal pure returns (uint) {
		return mul(_wei, 10 ** 27);
	} 

	function accrueInterest(uint _principal, uint _rateWhere10000is1Perc, uint _age) internal pure returns (uint) {
		return rmul(_principal, rpow(10 ** 27 + _rateWhere10000is1Perc * 11574074074100000, _age));
	}

}

contract Staking {

	address owner;
	uint256 public taxInterestBank0 = 0;
	uint256 public taxInterestBank1 = 0;
	uint256 public taxPrincipalBank0 = 0;
	uint256 public taxPrincipalBank1 = 0;
	struct record1 { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record1) public addressMap1;
	mapping(uint256 => address) public addressStore1;
	uint256 public lastAddress1 = 0;
	uint256 public minStakeAmt1 = 10000000000000000000;
	uint256 public maxStakeAmt1 = 1000000000000000000000;
	uint256 public principalTaxWhere10000IsOnePercent1 = 30000;
	uint256 public interestTaxWhere10000IsOnePercent1 = 20000;
	uint256 public dailyInterestRate1 = 100000;
	uint256 public minStakePeriod1 = (1000 * 864);
	struct record2 { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record2) public addressMap2;
	mapping(uint256 => address) public addressStore2;
	uint256 public lastAddress2 = 0;
	uint256 public dailyInterestRate2 = 200000;
	struct record3 { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record3) public addressMap3;
	mapping(uint256 => address) public addressStore3;
	uint256 public lastAddress3 = 0;
	uint256 public dailyInterestRate3 = 300000;
	struct record4 { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record4) public addressMap4;
	mapping(uint256 => address) public addressStore4;
	uint256 public lastAddress4 = 0;
	uint256 public principalTaxWhere10000IsOnePercent4 = 32000;
	uint256 public interestTaxWhere10000IsOnePercent4 = 23000;
	uint256 public dailyInterestRate4 = 180000;
	uint256 public minStakePeriod4 = (200 * 864);
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

	//This function allows the owner to change the value of minStakeAmt1.
	function changeValueOf_minStakeAmt1 (uint256 _minStakeAmt1) external onlyOwner {
		 minStakeAmt1 = _minStakeAmt1;
	}

	//This function allows the owner to change the value of maxStakeAmt1.
	function changeValueOf_maxStakeAmt1 (uint256 _maxStakeAmt1) external onlyOwner {
		 maxStakeAmt1 = _maxStakeAmt1;
	}

	//This function allows the owner to change the value of principalTaxWhere10000IsOnePercent1.
	function changeValueOf_principalTaxWhere10000IsOnePercent1 (uint256 _principalTaxWhere10000IsOnePercent1) external onlyOwner {
		 principalTaxWhere10000IsOnePercent1 = _principalTaxWhere10000IsOnePercent1;
	}

	//This function allows the owner to change the value of interestTaxWhere10000IsOnePercent1.
	function changeValueOf_interestTaxWhere10000IsOnePercent1 (uint256 _interestTaxWhere10000IsOnePercent1) external onlyOwner {
		 interestTaxWhere10000IsOnePercent1 = _interestTaxWhere10000IsOnePercent1;
	}

	//This function allows the owner to change the value of minStakePeriod1.
	function changeValueOf_minStakePeriod1 (uint256 _minStakePeriod1) external onlyOwner {
		 minStakePeriod1 = _minStakePeriod1;
	}

	//This function allows the owner to change the value of principalTaxWhere10000IsOnePercent4.
	function changeValueOf_principalTaxWhere10000IsOnePercent4 (uint256 _principalTaxWhere10000IsOnePercent4) external onlyOwner {
		 principalTaxWhere10000IsOnePercent4 = _principalTaxWhere10000IsOnePercent4;
	}

	//This function allows the owner to change the value of interestTaxWhere10000IsOnePercent4.
	function changeValueOf_interestTaxWhere10000IsOnePercent4 (uint256 _interestTaxWhere10000IsOnePercent4) external onlyOwner {
		 interestTaxWhere10000IsOnePercent4 = _interestTaxWhere10000IsOnePercent4;
	}

	//This function allows the owner to change the value of minStakePeriod4.
	function changeValueOf_minStakePeriod4 (uint256 _minStakePeriod4) external onlyOwner {
		 minStakePeriod4 = _minStakePeriod4;
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
 * updates referralRecordMap (Element referringAddress) (Entity depositedAmt) as (referralRecordMap with element referringAddress with element depositedAmt) + (((8) * (_amt)) / (100))
 * updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
 * if referringAddress is equals to Address 0 then ()
 * updates referralRecordMap (Element referringAddress) (Entity depositedAmt) as (referralRecordMap with element referringAddress with element depositedAmt) + (((2) * (_amt)) / (100))
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
		referralRecordMap[referringAddress].depositedAmt  = (referralRecordMap[referringAddress].depositedAmt + ((8 * _amt) / 100));
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
		if ((referringAddress == address(0))){
			return;
		}
		referralRecordMap[referringAddress].depositedAmt  = (referralRecordMap[referringAddress].depositedAmt + ((2 * _amt) / 100));
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
 * Function stake1
 * Daily Interest Rate : Variable dailyInterestRate1
 * Minimum Stake Period : Variable minStakePeriod1
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap1 with element the address that called this function
 * checks that (amount of native currency sent to contract) is greater than or equals to minStakeAmt1
 * checks that ((amount of native currency sent to contract) + (thisRecord with element stakeAmt)) is less than or equals to maxStakeAmt1
 * checks that (thisRecord with element stakeAmt) is equals to 0
 * updates addressMap1 (Element the address that called this function) as Struct comprising current time, (amount of native currency sent to contract), current time, 0
 * calls addReferral with variable _amount as amount of native currency sent to contract
 * emits event Staked with inputs the address that called this function
*/
	function stake1() public payable {
		record1 memory thisRecord = addressMap1[msg.sender];
		require((msg.value >= minStakeAmt1), "Less than minimum stake amount");
		require(((msg.value + thisRecord.stakeAmt) <= maxStakeAmt1), "More than maximum stake amount");
		require((thisRecord.stakeAmt == 0), "Need to unstake before restaking");
		addressMap1[msg.sender]  = record1 (block.timestamp, msg.value, block.timestamp, 0);
		addReferral(msg.value);
		emit Staked(msg.sender);
	}

/**
 * Function unstake1
 * The function takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap1 with element the address that called this function
 * checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
 * checks that ((current time) - (minStakePeriod1)) is greater than or equals to (thisRecord with element stakeTime)
 * creates an internal variable newAccum with initial value thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate1 / 86400000000
 * creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
 * transfers (((_unstakeAmt) * ((1000000) - (principalTaxWhere10000IsOnePercent1))) / (1000000)) + (((interestToRemove) * ((1000000) - (interestTaxWhere10000IsOnePercent1))) / (1000000)) of the native currency to the address that called this function
 * updates taxPrincipalBank0 as (taxPrincipalBank0) + (((thisRecord with element stakeAmt) * (40) * (principalTaxWhere10000IsOnePercent1)) / ((1000000) * (100)))
 * updates taxPrincipalBank1 as (taxPrincipalBank1) + (((thisRecord with element stakeAmt) * (60) * (principalTaxWhere10000IsOnePercent1)) / ((1000000) * (100)))
 * updates taxInterestBank0 as (taxInterestBank0) + (((interestToRemove) * (40) * (interestTaxWhere10000IsOnePercent1)) / ((1000000) * (100)))
 * updates taxInterestBank1 as (taxInterestBank1) + (((interestToRemove) * (60) * (interestTaxWhere10000IsOnePercent1)) / ((1000000) * (100)))
 * if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat lastAddress1 times with loop variable i0 :  (if (addressStore1 with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore1 (Element Loop Variable i0) as addressStore1 with element (lastAddress1) - (1); then updates lastAddress1 as (lastAddress1) - (1); and then terminates the for-next loop)))
 * updates addressMap1 (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove))
 * emits event Unstaked with inputs the address that called this function
*/
	function unstake1(uint256 _unstakeAmt) public {
		record1 memory thisRecord = addressMap1[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		require(((block.timestamp - minStakePeriod1) >= thisRecord.stakeTime), "Insufficient stake period");
		uint256 newAccum = thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate1 / 86400000000;
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		payable(msg.sender).transfer((((_unstakeAmt * (1000000 - principalTaxWhere10000IsOnePercent1)) / 1000000) + ((interestToRemove * (1000000 - interestTaxWhere10000IsOnePercent1)) / 1000000)));
		taxPrincipalBank0  = (taxPrincipalBank0 + ((thisRecord.stakeAmt * 40 * principalTaxWhere10000IsOnePercent1) / (1000000 * 100)));
		taxPrincipalBank1  = (taxPrincipalBank1 + ((thisRecord.stakeAmt * 60 * principalTaxWhere10000IsOnePercent1) / (1000000 * 100)));
		taxInterestBank0  = (taxInterestBank0 + ((interestToRemove * 40 * interestTaxWhere10000IsOnePercent1) / (1000000 * 100)));
		taxInterestBank1  = (taxInterestBank1 + ((interestToRemove * 60 * interestTaxWhere10000IsOnePercent1) / (1000000 * 100)));
		if ((_unstakeAmt == thisRecord.stakeAmt)){
			for (uint i0 = 0; i0 < lastAddress1; i0++){
				if ((addressStore1[i0] == msg.sender)){
					addressStore1[i0]  = addressStore1[(lastAddress1 - 1)];
					lastAddress1  = (lastAddress1 - 1);
					break;
				}
			}
		}
		addressMap1[msg.sender]  = record1 (thisRecord.stakeTime, (thisRecord.stakeAmt - _unstakeAmt), thisRecord.lastUpdateTime, (newAccum - interestToRemove));
		emit Unstaked(msg.sender);
	}

/**
 * Function modifyDailyInterestRateWhere10000IsOnePercent1
 * The function takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * repeat lastAddress1 times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap1 with element addressStore1 with element Loop Variable i0; and then updates addressMap1 (Element addressStore1 with element Loop Variable i0) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, (thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate1 / 86400000000))
 * updates dailyInterestRate1 as _dailyInterestRate
*/
	function modifyDailyInterestRateWhere10000IsOnePercent1(uint256 _dailyInterestRate) public onlyOwner {
		for (uint i0 = 0; i0 < lastAddress1; i0++){
			record1 memory thisRecord = addressMap1[addressStore1[i0]];
			addressMap1[addressStore1[i0]]  = record1 (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate1 / 86400000000);
		}
		dailyInterestRate1  = _dailyInterestRate;
	}

/**
 * Function stake2
 * Daily Interest Rate : Variable dailyInterestRate2
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap2 with element the address that called this function
 * if (thisRecord with element stakeAmt) is equals to 0 then (updates addressMap2 (Element the address that called this function) as Struct comprising current time, (amount of native currency sent to contract), current time, 0) otherwise (updates addressMap2 (Element the address that called this function) as Struct comprising current time, ((thisRecord with element stakeAmt) + (amount of native currency sent to contract)), current time, (thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate2 / 86400000000); then updates addressStore2 (Element lastAddress2) as the address that called this function; and then updates lastAddress2 as (lastAddress2) + (1))
 * calls addReferral with variable _amount as amount of native currency sent to contract
 * emits event Staked with inputs the address that called this function
*/
	function stake2() public payable {
		record2 memory thisRecord = addressMap2[msg.sender];
		if ((thisRecord.stakeAmt == 0)){
			addressMap2[msg.sender]  = record2 (block.timestamp, msg.value, block.timestamp, 0);
		}else{
			addressMap2[msg.sender]  = record2 (block.timestamp, (thisRecord.stakeAmt + msg.value), block.timestamp, thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate2 / 86400000000);
			addressStore2[lastAddress2]  = msg.sender;
			lastAddress2  = (lastAddress2 + 1);
		}
		addReferral(msg.value);
		emit Staked(msg.sender);
	}

/**
 * Function unstake2
 * The function takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap2 with element the address that called this function
 * checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
 * creates an internal variable newAccum with initial value thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate2 / 86400000000
 * creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
 * transfers (_unstakeAmt) + (interestToRemove) of the native currency to the address that called this function
 * if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat lastAddress2 times with loop variable i0 :  (if (addressStore2 with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore2 (Element Loop Variable i0) as addressStore2 with element (lastAddress2) - (1); then updates lastAddress2 as (lastAddress2) - (1); and then terminates the for-next loop)))
 * updates addressMap2 (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove))
 * emits event Unstaked with inputs the address that called this function
*/
	function unstake2(uint256 _unstakeAmt) public {
		record2 memory thisRecord = addressMap2[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		uint256 newAccum = thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate2 / 86400000000;
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		payable(msg.sender).transfer((_unstakeAmt + interestToRemove));
		if ((_unstakeAmt == thisRecord.stakeAmt)){
			for (uint i0 = 0; i0 < lastAddress2; i0++){
				if ((addressStore2[i0] == msg.sender)){
					addressStore2[i0]  = addressStore2[(lastAddress2 - 1)];
					lastAddress2  = (lastAddress2 - 1);
					break;
				}
			}
		}
		addressMap2[msg.sender]  = record2 (thisRecord.stakeTime, (thisRecord.stakeAmt - _unstakeAmt), thisRecord.lastUpdateTime, (newAccum - interestToRemove));
		emit Unstaked(msg.sender);
	}

/**
 * Function modifyDailyInterestRateWhere10000IsOnePercent2
 * The function takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * repeat lastAddress2 times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap2 with element addressStore2 with element Loop Variable i0; and then updates addressMap2 (Element addressStore2 with element Loop Variable i0) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, (thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate2 / 86400000000))
 * updates dailyInterestRate2 as _dailyInterestRate
*/
	function modifyDailyInterestRateWhere10000IsOnePercent2(uint256 _dailyInterestRate) public onlyOwner {
		for (uint i0 = 0; i0 < lastAddress2; i0++){
			record2 memory thisRecord = addressMap2[addressStore2[i0]];
			addressMap2[addressStore2[i0]]  = record2 (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate2 / 86400000000);
		}
		dailyInterestRate2  = _dailyInterestRate;
	}

/**
 * Function stake3
 * Daily Interest Rate : Variable dailyInterestRate3
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap3 with element the address that called this function
 * if (thisRecord with element stakeAmt) is equals to 0 then (updates addressMap3 (Element the address that called this function) as Struct comprising current time, (amount of native currency sent to contract), current time, 0) otherwise (updates addressMap3 (Element the address that called this function) as Struct comprising current time, ((thisRecord with element stakeAmt) + (amount of native currency sent to contract)), current time, ((compound interest for amount ((thisRecord with element stakeAmt) + (thisRecord with element accumulatedInterestToUpdateTime)) at rate (where 10000 = 1%) dailyInterestRate3 over ((current time) - (thisRecord with element lastUpdateTime)) seconds) - (thisRecord with element stakeAmt)); then updates addressStore3 (Element lastAddress3) as the address that called this function; and then updates lastAddress3 as (lastAddress3) + (1))
 * calls addReferral with variable _amount as amount of native currency sent to contract
 * emits event Staked with inputs the address that called this function
*/
	function stake3() public payable {
		record3 memory thisRecord = addressMap3[msg.sender];
		if ((thisRecord.stakeAmt == 0)){
			addressMap3[msg.sender]  = record3 (block.timestamp, msg.value, block.timestamp, 0);
		}else{
			addressMap3[msg.sender]  = record3 (block.timestamp, (thisRecord.stakeAmt + msg.value), block.timestamp, (Interest.accrueInterest((thisRecord.stakeAmt + thisRecord.accumulatedInterestToUpdateTime), dailyInterestRate3, (block.timestamp - thisRecord.lastUpdateTime)) - thisRecord.stakeAmt));
			addressStore3[lastAddress3]  = msg.sender;
			lastAddress3  = (lastAddress3 + 1);
		}
		addReferral(msg.value);
		emit Staked(msg.sender);
	}

/**
 * Function unstake3
 * The function takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap3 with element the address that called this function
 * checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
 * creates an internal variable newAccum with initial value (compound interest for amount ((thisRecord with element stakeAmt) + (thisRecord with element accumulatedInterestToUpdateTime)) at rate (where 10000 = 1%) dailyInterestRate3 over ((current time) - (thisRecord with element lastUpdateTime)) seconds) - (thisRecord with element stakeAmt)
 * creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
 * transfers (_unstakeAmt) + (interestToRemove) of the native currency to the address that called this function
 * if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat lastAddress3 times with loop variable i0 :  (if (addressStore3 with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore3 (Element Loop Variable i0) as addressStore3 with element (lastAddress3) - (1); then updates lastAddress3 as (lastAddress3) - (1); and then terminates the for-next loop)))
 * updates addressMap3 (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove))
 * emits event Unstaked with inputs the address that called this function
*/
	function unstake3(uint256 _unstakeAmt) public {
		record3 memory thisRecord = addressMap3[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		uint256 newAccum = (Interest.accrueInterest((thisRecord.stakeAmt + thisRecord.accumulatedInterestToUpdateTime), dailyInterestRate3, (block.timestamp - thisRecord.lastUpdateTime)) - thisRecord.stakeAmt);
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		payable(msg.sender).transfer((_unstakeAmt + interestToRemove));
		if ((_unstakeAmt == thisRecord.stakeAmt)){
			for (uint i0 = 0; i0 < lastAddress3; i0++){
				if ((addressStore3[i0] == msg.sender)){
					addressStore3[i0]  = addressStore3[(lastAddress3 - 1)];
					lastAddress3  = (lastAddress3 - 1);
					break;
				}
			}
		}
		addressMap3[msg.sender]  = record3 (thisRecord.stakeTime, (thisRecord.stakeAmt - _unstakeAmt), thisRecord.lastUpdateTime, (newAccum - interestToRemove));
		emit Unstaked(msg.sender);
	}

/**
 * Function modifyDailyInterestRateWhere10000IsOnePercent3
 * The function takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * repeat lastAddress3 times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap3 with element addressStore3 with element Loop Variable i0; and then updates addressMap3 (Element addressStore3 with element Loop Variable i0) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, ((compound interest for amount ((thisRecord with element stakeAmt) + (thisRecord with element accumulatedInterestToUpdateTime)) at rate (where 10000 = 1%) dailyInterestRate3 over ((current time) - (thisRecord with element lastUpdateTime)) seconds) - (thisRecord with element stakeAmt)))
 * updates dailyInterestRate3 as _dailyInterestRate
*/
	function modifyDailyInterestRateWhere10000IsOnePercent3(uint256 _dailyInterestRate) public onlyOwner {
		for (uint i0 = 0; i0 < lastAddress3; i0++){
			record3 memory thisRecord = addressMap3[addressStore3[i0]];
			addressMap3[addressStore3[i0]]  = record3 (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, (Interest.accrueInterest((thisRecord.stakeAmt + thisRecord.accumulatedInterestToUpdateTime), dailyInterestRate3, (block.timestamp - thisRecord.lastUpdateTime)) - thisRecord.stakeAmt));
		}
		dailyInterestRate3  = _dailyInterestRate;
	}

/**
 * Function stake4
 * Daily Interest Rate : Variable dailyInterestRate4
 * Minimum Stake Period : Variable minStakePeriod4
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap4 with element the address that called this function
 * checks that (thisRecord with element stakeAmt) is equals to 0
 * updates addressMap4 (Element the address that called this function) as Struct comprising current time, (amount of native currency sent to contract), current time, 0
 * calls addReferral with variable _amount as amount of native currency sent to contract
 * emits event Staked with inputs the address that called this function
*/
	function stake4() public payable {
		record4 memory thisRecord = addressMap4[msg.sender];
		require((thisRecord.stakeAmt == 0), "Need to unstake before restaking");
		addressMap4[msg.sender]  = record4 (block.timestamp, msg.value, block.timestamp, 0);
		addReferral(msg.value);
		emit Staked(msg.sender);
	}

/**
 * Function unstake4
 * The function takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap4 with element the address that called this function
 * checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
 * checks that ((current time) - (minStakePeriod4)) is greater than or equals to (thisRecord with element stakeTime)
 * creates an internal variable newAccum with initial value (compound interest for amount ((thisRecord with element stakeAmt) + (thisRecord with element accumulatedInterestToUpdateTime)) at rate (where 10000 = 1%) dailyInterestRate4 over ((current time) - (thisRecord with element lastUpdateTime)) seconds) - (thisRecord with element stakeAmt)
 * creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
 * transfers (((_unstakeAmt) * ((1000000) - (principalTaxWhere10000IsOnePercent4))) / (1000000)) + (((interestToRemove) * ((1000000) - (interestTaxWhere10000IsOnePercent4))) / (1000000)) of the native currency to the address that called this function
 * updates taxPrincipalBank0 as (taxPrincipalBank0) + (((thisRecord with element stakeAmt) * (40) * (principalTaxWhere10000IsOnePercent4)) / ((1000000) * (100)))
 * updates taxPrincipalBank1 as (taxPrincipalBank1) + (((thisRecord with element stakeAmt) * (60) * (principalTaxWhere10000IsOnePercent4)) / ((1000000) * (100)))
 * updates taxInterestBank0 as (taxInterestBank0) + (((interestToRemove) * (40) * (interestTaxWhere10000IsOnePercent4)) / ((1000000) * (100)))
 * updates taxInterestBank1 as (taxInterestBank1) + (((interestToRemove) * (60) * (interestTaxWhere10000IsOnePercent4)) / ((1000000) * (100)))
 * if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat lastAddress4 times with loop variable i0 :  (if (addressStore4 with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore4 (Element Loop Variable i0) as addressStore4 with element (lastAddress4) - (1); then updates lastAddress4 as (lastAddress4) - (1); and then terminates the for-next loop)))
 * updates addressMap4 (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove))
 * emits event Unstaked with inputs the address that called this function
*/
	function unstake4(uint256 _unstakeAmt) public {
		record4 memory thisRecord = addressMap4[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		require(((block.timestamp - minStakePeriod4) >= thisRecord.stakeTime), "Insufficient stake period");
		uint256 newAccum = (Interest.accrueInterest((thisRecord.stakeAmt + thisRecord.accumulatedInterestToUpdateTime), dailyInterestRate4, (block.timestamp - thisRecord.lastUpdateTime)) - thisRecord.stakeAmt);
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		payable(msg.sender).transfer((((_unstakeAmt * (1000000 - principalTaxWhere10000IsOnePercent4)) / 1000000) + ((interestToRemove * (1000000 - interestTaxWhere10000IsOnePercent4)) / 1000000)));
		taxPrincipalBank0  = (taxPrincipalBank0 + ((thisRecord.stakeAmt * 40 * principalTaxWhere10000IsOnePercent4) / (1000000 * 100)));
		taxPrincipalBank1  = (taxPrincipalBank1 + ((thisRecord.stakeAmt * 60 * principalTaxWhere10000IsOnePercent4) / (1000000 * 100)));
		taxInterestBank0  = (taxInterestBank0 + ((interestToRemove * 40 * interestTaxWhere10000IsOnePercent4) / (1000000 * 100)));
		taxInterestBank1  = (taxInterestBank1 + ((interestToRemove * 60 * interestTaxWhere10000IsOnePercent4) / (1000000 * 100)));
		if ((_unstakeAmt == thisRecord.stakeAmt)){
			for (uint i0 = 0; i0 < lastAddress4; i0++){
				if ((addressStore4[i0] == msg.sender)){
					addressStore4[i0]  = addressStore4[(lastAddress4 - 1)];
					lastAddress4  = (lastAddress4 - 1);
					break;
				}
			}
		}
		addressMap4[msg.sender]  = record4 (thisRecord.stakeTime, (thisRecord.stakeAmt - _unstakeAmt), thisRecord.lastUpdateTime, (newAccum - interestToRemove));
		emit Unstaked(msg.sender);
	}

/**
 * Function modifyDailyInterestRateWhere10000IsOnePercent4
 * The function takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * repeat lastAddress4 times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap4 with element addressStore4 with element Loop Variable i0; and then updates addressMap4 (Element addressStore4 with element Loop Variable i0) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, ((compound interest for amount ((thisRecord with element stakeAmt) + (thisRecord with element accumulatedInterestToUpdateTime)) at rate (where 10000 = 1%) dailyInterestRate4 over ((current time) - (thisRecord with element lastUpdateTime)) seconds) - (thisRecord with element stakeAmt)))
 * updates dailyInterestRate4 as _dailyInterestRate
*/
	function modifyDailyInterestRateWhere10000IsOnePercent4(uint256 _dailyInterestRate) public onlyOwner {
		for (uint i0 = 0; i0 < lastAddress4; i0++){
			record4 memory thisRecord = addressMap4[addressStore4[i0]];
			addressMap4[addressStore4[i0]]  = record4 (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, (Interest.accrueInterest((thisRecord.stakeAmt + thisRecord.accumulatedInterestToUpdateTime), dailyInterestRate4, (block.timestamp - thisRecord.lastUpdateTime)) - thisRecord.stakeAmt));
		}
		dailyInterestRate4  = _dailyInterestRate;
	}

/**
 * Function withdrawPrincipalTax0
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0x82137f52C632043410Fcc95C17254CDaE1E93824
 * transfers taxPrincipalBank0 of the native currency to the address that called this function
 * updates taxPrincipalBank0 as 0
*/
	function withdrawPrincipalTax0() public {
		require((msg.sender == address(0x82137f52C632043410Fcc95C17254CDaE1E93824)), "Not the withdrawal address");
		payable(msg.sender).transfer(taxPrincipalBank0);
		taxPrincipalBank0  = 0;
	}

/**
 * Function withdrawPrincipalTax1
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0xB3d4a3b65B8f68938De1b0fa536FFE0b4665d995
 * transfers taxPrincipalBank1 of the native currency to the address that called this function
 * updates taxPrincipalBank1 as 0
*/
	function withdrawPrincipalTax1() public {
		require((msg.sender == address(0xB3d4a3b65B8f68938De1b0fa536FFE0b4665d995)), "Not the withdrawal address");
		payable(msg.sender).transfer(taxPrincipalBank1);
		taxPrincipalBank1  = 0;
	}

/**
 * Function withdrawInterestTax0
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0x82137f52C632043410Fcc95C17254CDaE1E93824
 * transfers taxInterestBank0 of the native currency to the address that called this function
 * updates taxInterestBank0 as 0
*/
	function withdrawInterestTax0() public {
		require((msg.sender == address(0x82137f52C632043410Fcc95C17254CDaE1E93824)), "Not the withdrawal address");
		payable(msg.sender).transfer(taxInterestBank0);
		taxInterestBank0  = 0;
	}

/**
 * Function withdrawInterestTax1
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0xB3d4a3b65B8f68938De1b0fa536FFE0b4665d995
 * transfers taxInterestBank1 of the native currency to the address that called this function
 * updates taxInterestBank1 as 0
*/
	function withdrawInterestTax1() public {
		require((msg.sender == address(0xB3d4a3b65B8f68938De1b0fa536FFE0b4665d995)), "Not the withdrawal address");
		payable(msg.sender).transfer(taxInterestBank1);
		taxInterestBank1  = 0;
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