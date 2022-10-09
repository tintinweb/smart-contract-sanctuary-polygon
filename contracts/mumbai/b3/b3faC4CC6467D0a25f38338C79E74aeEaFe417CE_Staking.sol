/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Staking
 * Staking of : Coin BurnableERC20
 * Coin Address : 0x44c2fc792dBCB876A3EA2473C1C49d91f50CBe06
 * Number of schemes : 1
 * Scheme 1 functions : stake, unstake
 * Referral Scheme : 3
*/

interface ERC20{
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Staking {

	address owner;
	uint256 public taxInterestBank0 = uint256(0);
	uint256 public taxInterestBank1 = uint256(0);
	uint256 public taxPrincipalBank0 = uint256(0);
	uint256 public taxPrincipalBank1 = uint256(0);
	struct record { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; uint256 amtWithdrawn; }
	mapping(address => record) public addressMap;
	mapping(uint256 => address) public addressStore;
	uint256 public numberOfAddressesCurrentlyStaked = uint256(0);
	uint256 public principalCommencementTax = uint256(30000);
	uint256 public principalWithdrawalTax = uint256(60000);
	uint256 public interestTax = uint256(90000);
	uint256 public dailyInterestRate = uint256(5000);
	uint256 public dailyInterestRate_2 = uint256(7500);
	uint256 public dailyInterestRate_3 = uint256(9600);
	uint256 public minStakePeriod = (uint256(700) * uint256(864));
	uint256 public totalWithdrawals = uint256(0);
	struct referralRecord { bool hasDeposited; address referringAddress; uint256 unclaimedRewards; }
	mapping(address => referralRecord) public referralRecordMap;
	event Staked (address indexed account);
	event Unstaked (address indexed account);

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
 * This function allows the owner to change the value of principalCommencementTax.
 * Notes for _principalCommencementTax : 10000 is one percent
*/
	function changeValueOf_principalCommencementTax (uint256 _principalCommencementTax) external onlyOwner {
		 principalCommencementTax = _principalCommencementTax;
	}

	

/**
 * This function allows the owner to change the value of principalWithdrawalTax.
 * Notes for _principalWithdrawalTax : 10000 is one percent
*/
	function changeValueOf_principalWithdrawalTax (uint256 _principalWithdrawalTax) external onlyOwner {
		 principalWithdrawalTax = _principalWithdrawalTax;
	}

	

/**
 * This function allows the owner to change the value of interestTax.
 * Notes for _interestTax : 10000 is one percent
*/
	function changeValueOf_interestTax (uint256 _interestTax) external onlyOwner {
		 interestTax = _interestTax;
	}

	

/**
 * This function allows the owner to change the value of minStakePeriod.
 * Notes for _minStakePeriod : 1 day is represented by 86400 (seconds)
*/
	function changeValueOf_minStakePeriod (uint256 _minStakePeriod) external onlyOwner {
		 minStakePeriod = _minStakePeriod;
	}

/**
 * Function withdrawReferral
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (referralRecordMap with element the address that called this function with element unclaimedRewards) is greater than or equals to _amt
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _amt
 * updates referralRecordMap (Element the address that called this function) (Entity unclaimedRewards) as (referralRecordMap with element the address that called this function with element unclaimedRewards) - (_amt)
*/
	function withdrawReferral(uint256 _amt) public {
		require((referralRecordMap[msg.sender].unclaimedRewards >= _amt), "Insufficient referral rewards to withdraw");
		ERC20(0x44c2fc792dBCB876A3EA2473C1C49d91f50CBe06).transfer(msg.sender, _amt);
		referralRecordMap[msg.sender].unclaimedRewards  = (referralRecordMap[msg.sender].unclaimedRewards - _amt);
	}

/**
 * Function addReferral
 * The function takes in 1 variable, zero or a positive integer _amt. It can only be called by other functions in this contract. It does the following :
 * creates an internal variable referringAddress with initial value referralRecordMap with element the address that called this function with element referringAddress
 * if not referralRecordMap with element the address that called this function with element hasDeposited then (updates referralRecordMap (Element the address that called this function) (Entity hasDeposited) as true)
 * if referringAddress is equals to Address 0 then ()
 * updates referralRecordMap (Element referringAddress) (Entity unclaimedRewards) as (referralRecordMap with element referringAddress with element unclaimedRewards) + ((3) * (_amt))
 * updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
*/
	function addReferral(uint256 _amt) internal {
		address referringAddress = referralRecordMap[msg.sender].referringAddress;
		if (!(referralRecordMap[msg.sender].hasDeposited)){
			referralRecordMap[msg.sender].hasDeposited  = true;
		}
		if ((referringAddress == address(0))){
			return;
		}
		referralRecordMap[referringAddress].unclaimedRewards  = (referralRecordMap[referringAddress].unclaimedRewards + (uint256(3) * _amt));
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
	}

/**
 * Function addReferralAddress
 * The function takes in 1 variable, an address _referringAddress. It can only be called by functions outside of this contract. It does the following :
 * checks that referralRecordMap with element _referringAddress with element hasDeposited
 * checks that not _referringAddress is equals to (the address that called this function)
 * checks that (referralRecordMap with element the address that called this function with element referringAddress) is equals to Address 0
 * updates referralRecordMap (Element the address that called this function) (Entity referringAddress) as _referringAddress
*/
	function addReferralAddress(address _referringAddress) external {
		require(referralRecordMap[_referringAddress].hasDeposited, "Referring Address has not made a deposit");
		require(!((_referringAddress == msg.sender)), "Self-referrals are not allowed");
		require((referralRecordMap[msg.sender].referringAddress == address(0)), "User has previously indicated a referral address");
		referralRecordMap[msg.sender].referringAddress  = _referringAddress;
	}

/**
 * Function stake
 * Daily Interest Rate : Variable dailyInterestRate
 * This interest rate is modified under certain circumstances, as articulated in the consolidatedInterestRate function
 * Minimum Stake Period : Variable minStakePeriod
 * Address Map : addressMap
 * ERC20 Transfer : 0x44c2fc792dBCB876A3EA2473C1C49d91f50CBe06, _stakeAmt
 * The function takes in 1 variable, zero or a positive integer _stakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that _stakeAmt is strictly greater than 0
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that (thisRecord with element stakeAmt) is equals to 0
 * updates addressMap (Element the address that called this function) as Struct comprising current time, (((_stakeAmt) * ((1000000) - (principalCommencementTax))) / (1000000)), current time, 0, 0
 * updates addressStore (Element numberOfAddressesCurrentlyStaked) as the address that called this function
 * updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) + (1)
 * calls ERC20's transferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as _stakeAmt
 * calls addReferral with variable _amt as _stakeAmt
 * updates taxPrincipalBank0 as (taxPrincipalBank0) + (((_stakeAmt) * (3) * (principalCommencementTax)) / ((1000000) * (6)))
 * updates taxPrincipalBank1 as (taxPrincipalBank1) + (((_stakeAmt) * (3) * (principalCommencementTax)) / ((1000000) * (6)))
 * emits event Staked with inputs the address that called this function
*/
	function stake(uint256 _stakeAmt) public {
		require((_stakeAmt > uint256(0)), "Staked amount needs to be greater than 0");
		record memory thisRecord = addressMap[msg.sender];
		require((thisRecord.stakeAmt == uint256(0)), "Need to unstake before restaking");
		addressMap[msg.sender]  = record (block.timestamp, ((_stakeAmt * (uint256(1000000) - principalCommencementTax)) / uint256(1000000)), block.timestamp, uint256(0), uint256(0));
		addressStore[numberOfAddressesCurrentlyStaked]  = msg.sender;
		numberOfAddressesCurrentlyStaked  = (numberOfAddressesCurrentlyStaked + uint256(1));
		ERC20(0x44c2fc792dBCB876A3EA2473C1C49d91f50CBe06).transferFrom(msg.sender, address(this), _stakeAmt);
		addReferral(_stakeAmt);
		taxPrincipalBank0  = (taxPrincipalBank0 + ((_stakeAmt * uint256(3) * principalCommencementTax) / (uint256(1000000) * uint256(6))));
		taxPrincipalBank1  = (taxPrincipalBank1 + ((_stakeAmt * uint256(3) * principalCommencementTax) / (uint256(1000000) * uint256(6))));
		emit Staked(msg.sender);
	}

/**
 * Function unstake
 * The function takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
 * checks that ((current time) - (minStakePeriod)) is greater than or equals to (thisRecord with element stakeTime)
 * creates an internal variable newAccum with initial value (thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _stakedAmt as thisRecord with element stakeAmt)) / (86400000000))
 * creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as (((_unstakeAmt) * ((1000000) - (principalWithdrawalTax))) / (1000000)) + (((interestToRemove) * ((1000000) - (interestTax))) / (1000000))
 * updates totalWithdrawals as (totalWithdrawals) + (((interestToRemove) * ((1000000) - (interestTax))) / (1000000))
 * updates taxPrincipalBank0 as (taxPrincipalBank0) + (((thisRecord with element stakeAmt) * (3) * (principalWithdrawalTax)) / ((1000000) * (6)))
 * updates taxPrincipalBank1 as (taxPrincipalBank1) + (((thisRecord with element stakeAmt) * (3) * (principalWithdrawalTax)) / ((1000000) * (6)))
 * updates taxInterestBank0 as (taxInterestBank0) + (((interestToRemove) * (3) * (interestTax)) / ((1000000) * (6)))
 * updates taxInterestBank1 as (taxInterestBank1) + (((interestToRemove) * (3) * (interestTax)) / ((1000000) * (6)))
 * if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (if (addressStore with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore (Element Loop Variable i0) as addressStore with element (numberOfAddressesCurrentlyStaked) - (1); then updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) - (1); and then terminates the for-next loop)))
 * updates addressMap (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove)), ((thisRecord with element amtWithdrawn) + (interestToRemove))
 * emits event Unstaked with inputs the address that called this function
*/
	function unstake(uint256 _unstakeAmt) public {
		record memory thisRecord = addressMap[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		require(((block.timestamp - minStakePeriod) >= thisRecord.stakeTime), "Insufficient stake period");
		uint256 newAccum = (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * consolidatedInterestRate(thisRecord.stakeAmt)) / uint256(86400000000)));
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		ERC20(0x44c2fc792dBCB876A3EA2473C1C49d91f50CBe06).transfer(msg.sender, (((_unstakeAmt * (uint256(1000000) - principalWithdrawalTax)) / uint256(1000000)) + ((interestToRemove * (uint256(1000000) - interestTax)) / uint256(1000000))));
		totalWithdrawals  = (totalWithdrawals + ((interestToRemove * (uint256(1000000) - interestTax)) / uint256(1000000)));
		taxPrincipalBank0  = (taxPrincipalBank0 + ((thisRecord.stakeAmt * uint256(3) * principalWithdrawalTax) / (uint256(1000000) * uint256(6))));
		taxPrincipalBank1  = (taxPrincipalBank1 + ((thisRecord.stakeAmt * uint256(3) * principalWithdrawalTax) / (uint256(1000000) * uint256(6))));
		taxInterestBank0  = (taxInterestBank0 + ((interestToRemove * uint256(3) * interestTax) / (uint256(1000000) * uint256(6))));
		taxInterestBank1  = (taxInterestBank1 + ((interestToRemove * uint256(3) * interestTax) / (uint256(1000000) * uint256(6))));
		if ((_unstakeAmt == thisRecord.stakeAmt)){
			for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
				if ((addressStore[i0] == msg.sender)){
					addressStore[i0]  = addressStore[(numberOfAddressesCurrentlyStaked - uint256(1))];
					numberOfAddressesCurrentlyStaked  = (numberOfAddressesCurrentlyStaked - uint256(1));
					break;
				}
			}
		}
		addressMap[msg.sender]  = record (thisRecord.stakeTime, (thisRecord.stakeAmt - _unstakeAmt), thisRecord.lastUpdateTime, (newAccum - interestToRemove), (thisRecord.amtWithdrawn + interestToRemove));
		emit Unstaked(msg.sender);
	}

/**
 * Function updateRecordsWithLatestInterestRates
 * The function takes in 0 variables. It can only be called by other functions in this contract. It does the following :
 * repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap with element addressStore with element Loop Variable i0; and then updates addressMap (Element addressStore with element Loop Variable i0) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, ((thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _stakedAmt as Loop Variable i0)) / (86400000000))), (thisRecord with element amtWithdrawn))
*/
	function updateRecordsWithLatestInterestRates() internal {
		for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
			record memory thisRecord = addressMap[addressStore[i0]];
			addressMap[addressStore[i0]]  = record (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * consolidatedInterestRate(i0)) / uint256(86400000000))), thisRecord.amtWithdrawn);
		}
	}

/**
 * Function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn
 * The function takes in 1 variable, an address _address. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element _address
 * returns (thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _stakedAmt as thisRecord with element stakeAmt)) / (86400000000)) as output
*/
	function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(address _address) public view returns (uint256) {
		record memory thisRecord = addressMap[_address];
		return (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * consolidatedInterestRate(thisRecord.stakeAmt)) / uint256(86400000000)));
	}

/**
 * Function withdrawInterestWithoutUnstaking
 * The function takes in 1 variable, zero or a positive integer _withdrawalAmt. It can only be called by functions outside of this contract. It does the following :
 * creates an internal variable totalInterestEarnedTillNow with initial value interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn with variable _address as the address that called this function
 * checks that _withdrawalAmt is less than or equals to totalInterestEarnedTillNow
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * updates addressMap (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, ((totalInterestEarnedTillNow) - (_withdrawalAmt)), ((thisRecord with element amtWithdrawn) + (_withdrawalAmt))
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as ((_withdrawalAmt) * ((1000000) - (interestTax))) / (1000000)
 * updates taxInterestBank0 as (taxInterestBank0) + (((_withdrawalAmt) * (3) * (interestTax)) / ((1000000) * (6)))
 * updates taxInterestBank1 as (taxInterestBank1) + (((_withdrawalAmt) * (3) * (interestTax)) / ((1000000) * (6)))
 * updates totalWithdrawals as (totalWithdrawals) + (((_withdrawalAmt) * ((1000000) - (interestTax))) / (1000000))
*/
	function withdrawInterestWithoutUnstaking(uint256 _withdrawalAmt) external {
		uint256 totalInterestEarnedTillNow = interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(msg.sender);
		require((_withdrawalAmt <= totalInterestEarnedTillNow), "Withdrawn amount must be less than withdrawable amount");
		record memory thisRecord = addressMap[msg.sender];
		addressMap[msg.sender]  = record (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, (totalInterestEarnedTillNow - _withdrawalAmt), (thisRecord.amtWithdrawn + _withdrawalAmt));
		ERC20(0x44c2fc792dBCB876A3EA2473C1C49d91f50CBe06).transfer(msg.sender, ((_withdrawalAmt * (uint256(1000000) - interestTax)) / uint256(1000000)));
		taxInterestBank0  = (taxInterestBank0 + ((_withdrawalAmt * uint256(3) * interestTax) / (uint256(1000000) * uint256(6))));
		taxInterestBank1  = (taxInterestBank1 + ((_withdrawalAmt * uint256(3) * interestTax) / (uint256(1000000) * uint256(6))));
		totalWithdrawals  = (totalWithdrawals + ((_withdrawalAmt * (uint256(1000000) - interestTax)) / uint256(1000000)));
	}

/**
 * Function consolidatedInterestRate
 * The function takes in 1 variable, zero or a positive integer _stakedAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * if _stakedAmt is greater than or equals to 5001000000000000000000 then (returns dailyInterestRate_3 as output)
 * if (2001000000000000000000 is less than or equals to _stakedAmt) and (_stakedAmt is less than or equals to 5000000000000000000000) then (returns dailyInterestRate_2 as output)
 * if (500000000000000000000 is less than or equals to _stakedAmt) and (_stakedAmt is less than or equals to 2000000000000000000000) then (returns 6500 as output)
 * returns dailyInterestRate as output
*/
	function consolidatedInterestRate(uint256 _stakedAmt) public view returns (uint256) {
		if ((_stakedAmt >= uint256(5001000000000000000000))){
			return dailyInterestRate_3;
		}
		if (((uint256(2001000000000000000000) <= _stakedAmt) && (_stakedAmt <= uint256(5000000000000000000000)))){
			return dailyInterestRate_2;
		}
		if (((uint256(500000000000000000000) <= _stakedAmt) && (_stakedAmt <= uint256(2000000000000000000000)))){
			return uint256(6500);
		}
		return dailyInterestRate;
	}

/**
 * Function modifyDailyInterestRate
 * Notes for _dailyInterestRate : 10000 is one percent
 * The function takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls updateRecordsWithLatestInterestRates
 * updates dailyInterestRate as _dailyInterestRate
*/
	function modifyDailyInterestRate(uint256 _dailyInterestRate) public onlyOwner {
		updateRecordsWithLatestInterestRates();
		dailyInterestRate  = _dailyInterestRate;
	}

/**
 * Function modifyDailyInterestRate_2
 * Notes for _dailyInterestRate : 10000 is one percent
 * The function takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls updateRecordsWithLatestInterestRates
 * updates dailyInterestRate_2 as _dailyInterestRate
*/
	function modifyDailyInterestRate_2(uint256 _dailyInterestRate) public onlyOwner {
		updateRecordsWithLatestInterestRates();
		dailyInterestRate_2  = _dailyInterestRate;
	}

/**
 * Function modifyDailyInterestRate_3
 * Notes for _dailyInterestRate : 10000 is one percent
 * The function takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls updateRecordsWithLatestInterestRates
 * updates dailyInterestRate_3 as _dailyInterestRate
*/
	function modifyDailyInterestRate_3(uint256 _dailyInterestRate) public onlyOwner {
		updateRecordsWithLatestInterestRates();
		dailyInterestRate_3  = _dailyInterestRate;
	}

/**
 * Function withdrawPrincipalTax0
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0xf0e1AA4ffb43fc9352d5B059c5b5088B990cC165
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as taxPrincipalBank0
 * updates taxPrincipalBank0 as 0
*/
	function withdrawPrincipalTax0() public {
		require((msg.sender == address(0xf0e1AA4ffb43fc9352d5B059c5b5088B990cC165)), "Not the withdrawal address");
		ERC20(0x44c2fc792dBCB876A3EA2473C1C49d91f50CBe06).transfer(msg.sender, taxPrincipalBank0);
		taxPrincipalBank0  = uint256(0);
	}

/**
 * Function withdrawPrincipalTax1
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0x07Bde6b2c28a84e0Be5e1286e9585823c3353994
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as taxPrincipalBank1
 * updates taxPrincipalBank1 as 0
*/
	function withdrawPrincipalTax1() public {
		require((msg.sender == address(0x07Bde6b2c28a84e0Be5e1286e9585823c3353994)), "Not the withdrawal address");
		ERC20(0x44c2fc792dBCB876A3EA2473C1C49d91f50CBe06).transfer(msg.sender, taxPrincipalBank1);
		taxPrincipalBank1  = uint256(0);
	}

/**
 * Function withdrawInterestTax0
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0xf0e1AA4ffb43fc9352d5B059c5b5088B990cC165
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as taxInterestBank0
 * updates taxInterestBank0 as 0
*/
	function withdrawInterestTax0() public {
		require((msg.sender == address(0xf0e1AA4ffb43fc9352d5B059c5b5088B990cC165)), "Not the withdrawal address");
		ERC20(0x44c2fc792dBCB876A3EA2473C1C49d91f50CBe06).transfer(msg.sender, taxInterestBank0);
		taxInterestBank0  = uint256(0);
	}

/**
 * Function withdrawInterestTax1
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0x07Bde6b2c28a84e0Be5e1286e9585823c3353994
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as taxInterestBank1
 * updates taxInterestBank1 as 0
*/
	function withdrawInterestTax1() public {
		require((msg.sender == address(0x07Bde6b2c28a84e0Be5e1286e9585823c3353994)), "Not the withdrawal address");
		ERC20(0x44c2fc792dBCB876A3EA2473C1C49d91f50CBe06).transfer(msg.sender, taxInterestBank1);
		taxInterestBank1  = uint256(0);
	}

/**
 * Function withdrawToken
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _amt
*/
	function withdrawToken(uint256 _amt) public onlyOwner {
		ERC20(0x44c2fc792dBCB876A3EA2473C1C49d91f50CBe06).transfer(msg.sender, _amt);
	}
}