/**
 *Submitted for verification at polygonscan.com on 2022-07-15
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

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
	struct record0 { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record0) public addressMap0;
	mapping(uint256 => address) public addressStore0;
	uint256 public lastAddress0 = 0;
	uint256 public minStakeAmt0 = 10000000000000000000;
	uint256 public maxStakeAmt0 = 1000000000000000000000;
	uint256 public principalTax0 = 300;
	uint256 public interestTax0 = 200;
	uint256 public dailyInterestRate0 = 100000;
	uint256 public minStakePeriod0 = (1000 * 864);
	struct record1 { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record1) public addressMap1;
	mapping(uint256 => address) public addressStore1;
	uint256 public lastAddress1 = 0;
	uint256 public dailyInterestRate1 = 200000;
	struct record2 { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record2) public addressMap2;
	mapping(uint256 => address) public addressStore2;
	uint256 public lastAddress2 = 0;
	uint256 public dailyInterestRate2 = 300000;
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

	//This function allows the owner to change the value of minStakeAmt0.
	function changeValueOf_minStakeAmt0 (uint256 _minStakeAmt0) external onlyOwner {
		 minStakeAmt0 = _minStakeAmt0;
	}

	//This function allows the owner to change the value of maxStakeAmt0.
	function changeValueOf_maxStakeAmt0 (uint256 _maxStakeAmt0) external onlyOwner {
		 maxStakeAmt0 = _maxStakeAmt0;
	}

	//This function allows the owner to change the value of principalTax0.
	function changeValueOf_principalTax0 (uint256 _principalTax0) external onlyOwner {
		 principalTax0 = _principalTax0;
	}

	//This function allows the owner to change the value of interestTax0.
	function changeValueOf_interestTax0 (uint256 _interestTax0) external onlyOwner {
		 interestTax0 = _interestTax0;
	}

	//This function allows the owner to change the value of minStakePeriod0.
	function changeValueOf_minStakePeriod0 (uint256 _minStakePeriod0) external onlyOwner {
		 minStakePeriod0 = _minStakePeriod0;
	}

/** The function withdrawReferral takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. This function does the following : 
* creates an internal variable thisRecord with initial value referralRecordMap with element the address that called this function
* checks that (thisRecord with element depositedAmt) is greater than or equals to _amt
* transfers _amt of the native currency to the address that called this function
* updates thisRecord (Entity depositedAmt) as (thisRecord with element depositedAmt) - (_amt)
*/
	function withdrawReferral(uint256 _amt) public {
		referralRecord memory thisRecord = referralRecordMap[msg.sender];
		require((thisRecord.depositedAmt >= _amt), "Insufficient referral rewards to withdraw");
		payable(msg.sender).transfer(_amt);
		thisRecord.depositedAmt  = (thisRecord.depositedAmt - _amt);
	}

/** The function addReferral takes in 2 variables, zero or a positive integer _amt, and an address _referringAddress. It can only be called by other functions in this contract. This function does the following : 
* if _referringAddress is equals to Address 0 then ()
* checks that (referralRecordMap with element _referringAddress with element hasRef) is equals to 1
* checks that not _referringAddress is equals to (the address that called this function)
* creates an internal variable referringAddress with initial value _referringAddress
* if (referralRecordMap with element the address that called this function with element hasRef) is equals to 0 then (updates referralRecordMap (Element the address that called this function) as Struct comprising 1, _referringAddress, 0) otherwise (updates referringAddress as referralRecordMap with element the address that called this function with element referringAddress)
* updates referralRecordMap (Element referringAddress) (Entity depositedAmt) as (referralRecordMap with element referringAddress with element depositedAmt) + (80000000000000000 * _amt / 1000000000000000000)
* updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
* if referringAddress is equals to Address 0 then ()
* updates referralRecordMap (Element referringAddress) (Entity depositedAmt) as (referralRecordMap with element referringAddress with element depositedAmt) + (20000000000000000 * _amt / 1000000000000000000)
* updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
*/
	function addReferral(uint256 _amt, address _referringAddress) internal {
		if ((_referringAddress == address(0))){
			return;
		}
		require((referralRecordMap[_referringAddress].hasRef == 1), "Referring Address has not made a deposit");
		require(!((_referringAddress == msg.sender)), "Self-referrals are not allowed");
		address referringAddress = _referringAddress;
		if ((referralRecordMap[msg.sender].hasRef == 0)){
			referralRecordMap[msg.sender]  = referralRecord (1, _referringAddress, 0);
		}else{
			referringAddress  = referralRecordMap[msg.sender].referringAddress;
		}
		referralRecordMap[referringAddress].depositedAmt  = (referralRecordMap[referringAddress].depositedAmt + 80000000000000000 * _amt / 1000000000000000000);
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
		if ((referringAddress == address(0))){
			return;
		}
		referralRecordMap[referringAddress].depositedAmt  = (referralRecordMap[referringAddress].depositedAmt + 20000000000000000 * _amt / 1000000000000000000);
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
	}

/** The function stake0 takes in 1 variable, an address _referringAddress. It can be called by functions both inside and outside of this contract. This function does the following : 
* creates an internal variable thisRecord with initial value addressMap0 with element the address that called this function
* checks that (amount of native currency sent to contract) is greater than or equals to minStakeAmt0
* checks that ((amount of native currency sent to contract) + (thisRecord with element stakeAmt)) is less than or equals to maxStakeAmt0
* checks that (thisRecord with element stakeAmt) is equals to 0
* updates addressMap0 (Element the address that called this function) as Struct comprising current time, (amount of native currency sent to contract), current time, 0
* calls addReferral with variable _amountt as amount of native currency sent to contract, variable _referringAddress as _referringAddress
* emits event Staked with inputs the address that called this function
*/
	function stake0(address _referringAddress) public payable {
		record0 memory thisRecord = addressMap0[msg.sender];
		require((msg.value >= minStakeAmt0), "Less than minimum stake amount");
		require(((msg.value + thisRecord.stakeAmt) <= maxStakeAmt0), "More than maximum stake amount");
		require((thisRecord.stakeAmt == 0), "Need to unstake before restaking");
		addressMap0[msg.sender]  = record0 (block.timestamp, msg.value, block.timestamp, 0);
		addReferral(msg.value, _referringAddress);
		emit Staked(msg.sender);
	}

/** The function unstake0 takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. This function does the following : 
* creates an internal variable thisRecord with initial value addressMap0 with element the address that called this function
* checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
* checks that ((current time) - (minStakePeriod0)) is greater than or equals to (thisRecord with element stakeTime)
* creates an internal variable newAccum with initial value thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate0 / 86400000000
* creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
* transfers (((_unstakeAmt) * ((10000) - (principalTax0))) / (10000)) + (((interestToRemove) * ((10000) - (interestTax0))) / (10000)) of the native currency to the address that called this function
* updates taxPrincipalBank0 as (taxPrincipalBank0) + (((thisRecord with element stakeAmt) * (40) * (principalTax0)) / ((10000) * (100)))
* updates taxPrincipalBank1 as (taxPrincipalBank1) + (((thisRecord with element stakeAmt) * (60) * (principalTax0)) / ((10000) * (100)))
* updates taxInterestBank0 as (taxInterestBank0) + (((interestToRemove) * (40) * (interestTax0)) / ((10000) * (100)))
* updates taxInterestBank1 as (taxInterestBank1) + (((interestToRemove) * (60) * (interestTax0)) / ((10000) * (100)))
* if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat lastAddress0 times with loop variable i0 :  (if (addressStore0 with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore0 (Element Loop Variable i0) as addressStore0 with element (lastAddress0) - (1); then updates lastAddress0 as (lastAddress0) - (1); and then terminates the for-next loop)))
* updates addressMap0 (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove))
* emits event Unstaked with inputs the address that called this function
*/
	function unstake0(uint256 _unstakeAmt) public {
		record0 memory thisRecord = addressMap0[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		require(((block.timestamp - minStakePeriod0) >= thisRecord.stakeTime), "Insufficient stakeperiod");
		uint256 newAccum = thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate0 / 86400000000;
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		payable(msg.sender).transfer((((_unstakeAmt * (10000 - principalTax0)) / 10000) + ((interestToRemove * (10000 - interestTax0)) / 10000)));
		taxPrincipalBank0  = (taxPrincipalBank0 + ((thisRecord.stakeAmt * 40 * principalTax0) / (10000 * 100)));
		taxPrincipalBank1  = (taxPrincipalBank1 + ((thisRecord.stakeAmt * 60 * principalTax0) / (10000 * 100)));
		taxInterestBank0  = (taxInterestBank0 + ((interestToRemove * 40 * interestTax0) / (10000 * 100)));
		taxInterestBank1  = (taxInterestBank1 + ((interestToRemove * 60 * interestTax0) / (10000 * 100)));
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

/** The function modifyDailyInterestRateWhere10000IsOnePercent0 takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. This function does the following : 
* checks that the function is called by the owner of the contract
* repeat lastAddress0 times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap0 with element addressStore0 with element Loop Variable i0; then updates addressMap0 (Element addressStore0 with element Loop Variable i0) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, (thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate0 / 86400000000); and then updates dailyInterestRate0 as _dailyInterestRate)
*/
	function modifyDailyInterestRateWhere10000IsOnePercent0(uint256 _dailyInterestRate) public onlyOwner {
		for (uint i0 = 0; i0 < lastAddress0; i0++){
			record0 memory thisRecord = addressMap0[addressStore0[i0]];
			addressMap0[addressStore0[i0]]  = record0 (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate0 / 86400000000);
			dailyInterestRate0  = _dailyInterestRate;
		}
	}

/** The function stake1 takes in 1 variable, an address _referringAddress. It can be called by functions both inside and outside of this contract. This function does the following : 
* creates an internal variable thisRecord with initial value addressMap1 with element the address that called this function
* if (thisRecord with element stakeAmt) is equals to 0 then (updates addressMap1 (Element the address that called this function) as Struct comprising current time, (amount of native currency sent to contract), current time, 0) otherwise (updates addressMap1 (Element the address that called this function) as Struct comprising current time, ((thisRecord with element stakeAmt) + (amount of native currency sent to contract)), current time, (thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate1 / 86400000000); then updates addressStore1 (Element lastAddress1) as the address that called this function; and then updates lastAddress1 as (lastAddress1) + (1))
* calls addReferral with variable _amountt as amount of native currency sent to contract, variable _referringAddress as _referringAddress
* emits event Staked with inputs the address that called this function
*/
	function stake1(address _referringAddress) public payable {
		record1 memory thisRecord = addressMap1[msg.sender];
		if ((thisRecord.stakeAmt == 0)){
			addressMap1[msg.sender]  = record1 (block.timestamp, msg.value, block.timestamp, 0);
		}else{
			addressMap1[msg.sender]  = record1 (block.timestamp, (thisRecord.stakeAmt + msg.value), block.timestamp, thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate1 / 86400000000);
			addressStore1[lastAddress1]  = msg.sender;
			lastAddress1  = (lastAddress1 + 1);
		}
		addReferral(msg.value, _referringAddress);
		emit Staked(msg.sender);
	}

/** The function unstake1 takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. This function does the following : 
* creates an internal variable thisRecord with initial value addressMap1 with element the address that called this function
* checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
* creates an internal variable newAccum with initial value thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate1 / 86400000000
* creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
* if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat lastAddress1 times with loop variable i0 :  (if (addressStore1 with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore1 (Element Loop Variable i0) as addressStore1 with element (lastAddress1) - (1); then updates lastAddress1 as (lastAddress1) - (1); and then terminates the for-next loop)))
* updates addressMap1 (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove))
* emits event Unstaked with inputs the address that called this function
*/
	function unstake1(uint256 _unstakeAmt) public {
		record1 memory thisRecord = addressMap1[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		uint256 newAccum = thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate1 / 86400000000;
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
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

/** The function modifyDailyInterestRateWhere10000IsOnePercent1 takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. This function does the following : 
* checks that the function is called by the owner of the contract
* repeat lastAddress1 times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap1 with element addressStore1 with element Loop Variable i0; then updates addressMap1 (Element addressStore1 with element Loop Variable i0) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, (thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate1 / 86400000000); and then updates dailyInterestRate1 as _dailyInterestRate)
*/
	function modifyDailyInterestRateWhere10000IsOnePercent1(uint256 _dailyInterestRate) public onlyOwner {
		for (uint i0 = 0; i0 < lastAddress1; i0++){
			record1 memory thisRecord = addressMap1[addressStore1[i0]];
			addressMap1[addressStore1[i0]]  = record1 (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, thisRecord.accumulatedInterestToUpdateTime + thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate1 / 86400000000);
			dailyInterestRate1  = _dailyInterestRate;
		}
	}

/** The function stake2 takes in 1 variable, an address _referringAddress. It can be called by functions both inside and outside of this contract. This function does the following : 
* creates an internal variable thisRecord with initial value addressMap2 with element the address that called this function
* if (thisRecord with element stakeAmt) is equals to 0 then (updates addressMap2 (Element the address that called this function) as Struct comprising current time, (amount of native currency sent to contract), current time, 0) otherwise (updates addressMap2 (Element the address that called this function) as Struct comprising current time, ((thisRecord with element stakeAmt) + (amount of native currency sent to contract)), current time, ((compound interest for amount ((thisRecord with element stakeAmt) + (thisRecord with element accumulatedInterestToUpdateTime)) at rate (where 10000 = 1%) dailyInterestRate2 over ((current time) - (thisRecord with element lastUpdateTime)) seconds) - (thisRecord with element stakeAmt)); then updates addressStore2 (Element lastAddress2) as the address that called this function; and then updates lastAddress2 as (lastAddress2) + (1))
* calls addReferral with variable _amountt as amount of native currency sent to contract, variable _referringAddress as _referringAddress
* emits event Staked with inputs the address that called this function
*/
	function stake2(address _referringAddress) public payable {
		record2 memory thisRecord = addressMap2[msg.sender];
		if ((thisRecord.stakeAmt == 0)){
			addressMap2[msg.sender]  = record2 (block.timestamp, msg.value, block.timestamp, 0);
		}else{
			addressMap2[msg.sender]  = record2 (block.timestamp, (thisRecord.stakeAmt + msg.value), block.timestamp, (Interest.accrueInterest((thisRecord.stakeAmt + thisRecord.accumulatedInterestToUpdateTime), dailyInterestRate2, (block.timestamp - thisRecord.lastUpdateTime)) - thisRecord.stakeAmt));
			addressStore2[lastAddress2]  = msg.sender;
			lastAddress2  = (lastAddress2 + 1);
		}
		addReferral(msg.value, _referringAddress);
		emit Staked(msg.sender);
	}

/** The function unstake2 takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. This function does the following : 
* creates an internal variable thisRecord with initial value addressMap2 with element the address that called this function
* checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
* creates an internal variable newAccum with initial value (compound interest for amount ((thisRecord with element stakeAmt) + (thisRecord with element accumulatedInterestToUpdateTime)) at rate (where 10000 = 1%) dailyInterestRate2 over ((current time) - (thisRecord with element lastUpdateTime)) seconds) - (thisRecord with element stakeAmt)
* creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
* if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat lastAddress2 times with loop variable i0 :  (if (addressStore2 with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore2 (Element Loop Variable i0) as addressStore2 with element (lastAddress2) - (1); then updates lastAddress2 as (lastAddress2) - (1); and then terminates the for-next loop)))
* updates addressMap2 (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove))
* emits event Unstaked with inputs the address that called this function
*/
	function unstake2(uint256 _unstakeAmt) public {
		record2 memory thisRecord = addressMap2[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		uint256 newAccum = (Interest.accrueInterest((thisRecord.stakeAmt + thisRecord.accumulatedInterestToUpdateTime), dailyInterestRate2, (block.timestamp - thisRecord.lastUpdateTime)) - thisRecord.stakeAmt);
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
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

/** The function modifyDailyInterestRateWhere10000IsOnePercent2 takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. This function does the following : 
* checks that the function is called by the owner of the contract
* repeat lastAddress2 times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap2 with element addressStore2 with element Loop Variable i0; then updates addressMap2 (Element addressStore2 with element Loop Variable i0) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, ((compound interest for amount ((thisRecord with element stakeAmt) + (thisRecord with element accumulatedInterestToUpdateTime)) at rate (where 10000 = 1%) dailyInterestRate2 over ((current time) - (thisRecord with element lastUpdateTime)) seconds) - (thisRecord with element stakeAmt)); and then updates dailyInterestRate2 as _dailyInterestRate)
*/
	function modifyDailyInterestRateWhere10000IsOnePercent2(uint256 _dailyInterestRate) public onlyOwner {
		for (uint i0 = 0; i0 < lastAddress2; i0++){
			record2 memory thisRecord = addressMap2[addressStore2[i0]];
			addressMap2[addressStore2[i0]]  = record2 (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, (Interest.accrueInterest((thisRecord.stakeAmt + thisRecord.accumulatedInterestToUpdateTime), dailyInterestRate2, (block.timestamp - thisRecord.lastUpdateTime)) - thisRecord.stakeAmt));
			dailyInterestRate2  = _dailyInterestRate;
		}
	}

/** The function withdrawPrincipalTax0 takes in 0 variables. It can be called by functions both inside and outside of this contract. This function does the following : 
* checks that (the address that called this function) is equals to Address 0x82137f52C632043410Fcc95C17254CDaE1E93824
* transfers taxPrincipalBank0 of the native currency to the address that called this function
* updates taxPrincipalBank0 as 0
*/
	function withdrawPrincipalTax0() public {
		require((msg.sender == address(0x82137f52C632043410Fcc95C17254CDaE1E93824)), "Not the withdrawal address");
		payable(msg.sender).transfer(taxPrincipalBank0);
		taxPrincipalBank0  = 0;
	}

/** The function withdrawPrincipalTax1 takes in 0 variables. It can be called by functions both inside and outside of this contract. This function does the following : 
* checks that (the address that called this function) is equals to Address 0xB3d4a3b65B8f68938De1b0fa536FFE0b4665d995
* transfers taxPrincipalBank1 of the native currency to the address that called this function
* updates taxPrincipalBank1 as 0
*/
	function withdrawPrincipalTax1() public {
		require((msg.sender == address(0xB3d4a3b65B8f68938De1b0fa536FFE0b4665d995)), "Not the withdrawal address");
		payable(msg.sender).transfer(taxPrincipalBank1);
		taxPrincipalBank1  = 0;
	}

/** The function withdrawInterestTax0 takes in 0 variables. It can be called by functions both inside and outside of this contract. This function does the following : 
* checks that (the address that called this function) is equals to Address 0x82137f52C632043410Fcc95C17254CDaE1E93824
* transfers taxInterestBank0 of the native currency to the address that called this function
* updates taxInterestBank0 as 0
*/
	function withdrawInterestTax0() public {
		require((msg.sender == address(0x82137f52C632043410Fcc95C17254CDaE1E93824)), "Not the withdrawal address");
		payable(msg.sender).transfer(taxInterestBank0);
		taxInterestBank0  = 0;
	}

/** The function withdrawInterestTax1 takes in 0 variables. It can be called by functions both inside and outside of this contract. This function does the following : 
* checks that (the address that called this function) is equals to Address 0xB3d4a3b65B8f68938De1b0fa536FFE0b4665d995
* transfers taxInterestBank1 of the native currency to the address that called this function
* updates taxInterestBank1 as 0
*/
	function withdrawInterestTax1() public {
		require((msg.sender == address(0xB3d4a3b65B8f68938De1b0fa536FFE0b4665d995)), "Not the withdrawal address");
		payable(msg.sender).transfer(taxInterestBank1);
		taxInterestBank1  = 0;
	}

/** The function withdrawToken takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. This function does the following : 
* checks that the function is called by the owner of the contract
* transfers _amt of the native currency to the address that called this function
*/
	function withdrawToken(uint256 _amt) public onlyOwner {
		payable(msg.sender).transfer(_amt);
	}
}