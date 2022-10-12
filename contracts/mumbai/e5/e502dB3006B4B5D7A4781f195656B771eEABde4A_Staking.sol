/**
 *Submitted for verification at polygonscan.com on 2022-10-11
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Staking
 * Staking of : Coin Coin_DryTestMint
 * Coin Address : 0x26033cF00F3D8d8A444DCdc480C53248A24887bF
 * Number of schemes : 1
 * Scheme 1 functions : stake, unstake
 * Referral Scheme : 1, 3, 5
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
	struct record { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record) public addressMap;
	mapping(uint256 => address) public addressStore;
	uint256 public numberOfAddressesCurrentlyStaked = uint256(0);
	uint256 public minStakeAmt = uint256(500000000000000000000);
	uint256 public maxStakeAmt = uint256(50000000000000000000000);
	uint256 public dailyInterestRate = uint256(9700);
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
 * This function allows the owner to change the value of minStakeAmt.
 * Notes for _minStakeAmt : 1 Coin Coin_DryTestMint is represented by 10^18.
*/
	function changeValueOf_minStakeAmt (uint256 _minStakeAmt) external onlyOwner {
		 minStakeAmt = _minStakeAmt;
	}

	

/**
 * This function allows the owner to change the value of maxStakeAmt.
 * Notes for _maxStakeAmt : 1 Coin Coin_DryTestMint is represented by 10^18.
*/
	function changeValueOf_maxStakeAmt (uint256 _maxStakeAmt) external onlyOwner {
		 maxStakeAmt = _maxStakeAmt;
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
		ERC20(0x26033cF00F3D8d8A444DCdc480C53248A24887bF).transfer(msg.sender, _amt);
		referralRecordMap[msg.sender].unclaimedRewards  = (referralRecordMap[msg.sender].unclaimedRewards - _amt);
	}

/**
 * Function addReferral
 * The function takes in 1 variable, zero or a positive integer _amt. It can only be called by other functions in this contract. It does the following :
 * creates an internal variable referringAddress with initial value referralRecordMap with element the address that called this function with element referringAddress
 * if not referralRecordMap with element the address that called this function with element hasDeposited then (updates referralRecordMap (Element the address that called this function) (Entity hasDeposited) as true)
 * if referringAddress is equals to Address 0 then ()
 * updates referralRecordMap (Element referringAddress) (Entity unclaimedRewards) as (referralRecordMap with element referringAddress with element unclaimedRewards) + (_amt)
 * updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
 * if referringAddress is equals to Address 0 then ()
 * updates referralRecordMap (Element referringAddress) (Entity unclaimedRewards) as (referralRecordMap with element referringAddress with element unclaimedRewards) + ((3) * (_amt))
 * updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
 * if referringAddress is equals to Address 0 then ()
 * updates referralRecordMap (Element referringAddress) (Entity unclaimedRewards) as (referralRecordMap with element referringAddress with element unclaimedRewards) + ((5) * (_amt))
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
		referralRecordMap[referringAddress].unclaimedRewards  = (referralRecordMap[referringAddress].unclaimedRewards + _amt);
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
		if ((referringAddress == address(0))){
			return;
		}
		referralRecordMap[referringAddress].unclaimedRewards  = (referralRecordMap[referringAddress].unclaimedRewards + (uint256(3) * _amt));
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
		if ((referringAddress == address(0))){
			return;
		}
		referralRecordMap[referringAddress].unclaimedRewards  = (referralRecordMap[referringAddress].unclaimedRewards + (uint256(5) * _amt));
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
 * Minimum Stake Period : 3 days
 * Address Map : addressMap
 * ERC20 Transfer : 0x26033cF00F3D8d8A444DCdc480C53248A24887bF, _stakeAmt
 * The function takes in 1 variable, zero or a positive integer _stakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that _stakeAmt is strictly greater than 0
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that _stakeAmt is greater than or equals to minStakeAmt
 * checks that ((_stakeAmt) + (thisRecord with element stakeAmt)) is less than or equals to maxStakeAmt
 * checks that (thisRecord with element stakeAmt) is equals to 0
 * updates addressMap (Element the address that called this function) as Struct comprising current time, (((_stakeAmt) * ((1000000) - (50000))) / (1000000)), current time, 0
 * updates addressStore (Element numberOfAddressesCurrentlyStaked) as the address that called this function
 * updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) + (1)
 * calls ERC20's transferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as _stakeAmt
 * calls addReferral with variable _amt as _stakeAmt
 * updates taxPrincipalBank0 as (taxPrincipalBank0) + (((_stakeAmt) * (50) * (50000)) / ((1000000) * (100)))
 * updates taxPrincipalBank1 as (taxPrincipalBank1) + (((_stakeAmt) * (50) * (50000)) / ((1000000) * (100)))
 * emits event Staked with inputs the address that called this function
*/
	function stake(uint256 _stakeAmt) public {
		require((_stakeAmt > uint256(0)), "Staked amount needs to be greater than 0");
		record memory thisRecord = addressMap[msg.sender];
		require((_stakeAmt >= minStakeAmt), "Less than minimum stake amount");
		require(((_stakeAmt + thisRecord.stakeAmt) <= maxStakeAmt), "More than maximum stake amount");
		require((thisRecord.stakeAmt == uint256(0)), "Need to unstake before restaking");
		addressMap[msg.sender]  = record (block.timestamp, ((_stakeAmt * (uint256(1000000) - uint256(50000))) / uint256(1000000)), block.timestamp, uint256(0));
		addressStore[numberOfAddressesCurrentlyStaked]  = msg.sender;
		numberOfAddressesCurrentlyStaked  = (numberOfAddressesCurrentlyStaked + uint256(1));
		ERC20(0x26033cF00F3D8d8A444DCdc480C53248A24887bF).transferFrom(msg.sender, address(this), _stakeAmt);
		addReferral(_stakeAmt);
		taxPrincipalBank0  = (taxPrincipalBank0 + ((_stakeAmt * uint256(50) * uint256(50000)) / (uint256(1000000) * uint256(100))));
		taxPrincipalBank1  = (taxPrincipalBank1 + ((_stakeAmt * uint256(50) * uint256(50000)) / (uint256(1000000) * uint256(100))));
		emit Staked(msg.sender);
	}

/**
 * Function unstake
 * The function takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
 * checks that ((current time) - ((300) * (864))) is greater than or equals to (thisRecord with element stakeTime)
 * creates an internal variable newAccum with initial value (thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _stakedAmt as thisRecord with element stakeAmt)) / (86400000000))
 * creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as (((_unstakeAmt) * ((1000000) - (50000))) / (1000000)) + (((interestToRemove) * ((1000000) - (50000))) / (1000000))
 * updates totalWithdrawals as (totalWithdrawals) + (((interestToRemove) * ((1000000) - (50000))) / (1000000))
 * updates taxPrincipalBank0 as (taxPrincipalBank0) + (((thisRecord with element stakeAmt) * (50) * (50000)) / ((1000000) * (100)))
 * updates taxPrincipalBank1 as (taxPrincipalBank1) + (((thisRecord with element stakeAmt) * (50) * (50000)) / ((1000000) * (100)))
 * updates taxInterestBank0 as (taxInterestBank0) + (((interestToRemove) * (50) * (50000)) / ((1000000) * (100)))
 * updates taxInterestBank1 as (taxInterestBank1) + (((interestToRemove) * (50) * (50000)) / ((1000000) * (100)))
 * if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (if (addressStore with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore (Element Loop Variable i0) as addressStore with element (numberOfAddressesCurrentlyStaked) - (1); then updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) - (1); and then terminates the for-next loop)))
 * updates addressMap (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove))
 * emits event Unstaked with inputs the address that called this function
*/
	function unstake(uint256 _unstakeAmt) public {
		record memory thisRecord = addressMap[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		require(((block.timestamp - (uint256(300) * uint256(864))) >= thisRecord.stakeTime), "Insufficient stake period");
		uint256 newAccum = (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * consolidatedInterestRate(thisRecord.stakeAmt)) / uint256(86400000000)));
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		ERC20(0x26033cF00F3D8d8A444DCdc480C53248A24887bF).transfer(msg.sender, (((_unstakeAmt * (uint256(1000000) - uint256(50000))) / uint256(1000000)) + ((interestToRemove * (uint256(1000000) - uint256(50000))) / uint256(1000000))));
		totalWithdrawals  = (totalWithdrawals + ((interestToRemove * (uint256(1000000) - uint256(50000))) / uint256(1000000)));
		taxPrincipalBank0  = (taxPrincipalBank0 + ((thisRecord.stakeAmt * uint256(50) * uint256(50000)) / (uint256(1000000) * uint256(100))));
		taxPrincipalBank1  = (taxPrincipalBank1 + ((thisRecord.stakeAmt * uint256(50) * uint256(50000)) / (uint256(1000000) * uint256(100))));
		taxInterestBank0  = (taxInterestBank0 + ((interestToRemove * uint256(50) * uint256(50000)) / (uint256(1000000) * uint256(100))));
		taxInterestBank1  = (taxInterestBank1 + ((interestToRemove * uint256(50) * uint256(50000)) / (uint256(1000000) * uint256(100))));
		if ((_unstakeAmt == thisRecord.stakeAmt)){
			for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
				if ((addressStore[i0] == msg.sender)){
					addressStore[i0]  = addressStore[(numberOfAddressesCurrentlyStaked - uint256(1))];
					numberOfAddressesCurrentlyStaked  = (numberOfAddressesCurrentlyStaked - uint256(1));
					break;
				}
			}
		}
		addressMap[msg.sender]  = record (thisRecord.stakeTime, (thisRecord.stakeAmt - _unstakeAmt), thisRecord.lastUpdateTime, (newAccum - interestToRemove));
		emit Unstaked(msg.sender);
	}

/**
 * Function updateRecordsWithLatestInterestRates
 * The function takes in 0 variables. It can only be called by other functions in this contract. It does the following :
 * repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap with element addressStore with element Loop Variable i0; and then updates addressMap (Element addressStore with element Loop Variable i0) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, ((thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _stakedAmt as Loop Variable i0)) / (86400000000))))
*/
	function updateRecordsWithLatestInterestRates() internal {
		for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
			record memory thisRecord = addressMap[addressStore[i0]];
			addressMap[addressStore[i0]]  = record (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * consolidatedInterestRate(i0)) / uint256(86400000000))));
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
 * Function consolidatedInterestRate
 * The function takes in 1 variable, zero or a positive integer _stakedAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * if _stakedAmt is greater than or equals to 500000000000000000000 then (returns 9700 as output)
 * returns dailyInterestRate as output
*/
	function consolidatedInterestRate(uint256 _stakedAmt) public view returns (uint256) {
		if ((_stakedAmt >= uint256(500000000000000000000))){
			return uint256(9700);
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
 * Function withdrawPrincipalTax0
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0xcb2A7dAF65bd94e74E1a0393912aD0fcc4a50c7f
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as taxPrincipalBank0
 * updates taxPrincipalBank0 as 0
*/
	function withdrawPrincipalTax0() public {
		require((msg.sender == address(0xcb2A7dAF65bd94e74E1a0393912aD0fcc4a50c7f)), "Not the withdrawal address");
		ERC20(0x26033cF00F3D8d8A444DCdc480C53248A24887bF).transfer(msg.sender, taxPrincipalBank0);
		taxPrincipalBank0  = uint256(0);
	}

/**
 * Function withdrawPrincipalTax1
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0xf0e1AA4ffb43fc9352d5B059c5b5088B990cC165
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as taxPrincipalBank1
 * updates taxPrincipalBank1 as 0
*/
	function withdrawPrincipalTax1() public {
		require((msg.sender == address(0xf0e1AA4ffb43fc9352d5B059c5b5088B990cC165)), "Not the withdrawal address");
		ERC20(0x26033cF00F3D8d8A444DCdc480C53248A24887bF).transfer(msg.sender, taxPrincipalBank1);
		taxPrincipalBank1  = uint256(0);
	}

/**
 * Function withdrawInterestTax0
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0xcb2A7dAF65bd94e74E1a0393912aD0fcc4a50c7f
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as taxInterestBank0
 * updates taxInterestBank0 as 0
*/
	function withdrawInterestTax0() public {
		require((msg.sender == address(0xcb2A7dAF65bd94e74E1a0393912aD0fcc4a50c7f)), "Not the withdrawal address");
		ERC20(0x26033cF00F3D8d8A444DCdc480C53248A24887bF).transfer(msg.sender, taxInterestBank0);
		taxInterestBank0  = uint256(0);
	}

/**
 * Function withdrawInterestTax1
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0xf0e1AA4ffb43fc9352d5B059c5b5088B990cC165
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as taxInterestBank1
 * updates taxInterestBank1 as 0
*/
	function withdrawInterestTax1() public {
		require((msg.sender == address(0xf0e1AA4ffb43fc9352d5B059c5b5088B990cC165)), "Not the withdrawal address");
		ERC20(0x26033cF00F3D8d8A444DCdc480C53248A24887bF).transfer(msg.sender, taxInterestBank1);
		taxInterestBank1  = uint256(0);
	}

/**
 * Function withdrawToken
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _amt
*/
	function withdrawToken(uint256 _amt) public onlyOwner {
		ERC20(0x26033cF00F3D8d8A444DCdc480C53248A24887bF).transfer(msg.sender, _amt);
	}
}