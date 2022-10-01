/**
 *Submitted for verification at polygonscan.com on 2022-09-30
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Staking
 * Staking of : Coin Coin_Testtoken
 * Coin Address : 0xA0Ec9Be4b42EB17a9FEF44127765080eC72017E3
 * Number of schemes : 1
 * Scheme 1 functions : stake, unstake
*/

interface ERC20{
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Staking {

	address owner;
	uint256 public interestTaxBank = uint256(0);
	struct record { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; uint256 amtWithdrawn; }
	mapping(address => record) public addressMap;
	mapping(uint256 => address) public addressStore;
	uint256 public numberOfAddressesCurrentlyStaked = uint256(0);
	uint256 public minStakeAmt = uint256(100000000000000000000);
	uint256 public maxStakeAmt = uint256(100000000000000000000000);
	uint256 public interestTax = uint256(50000);
	uint256 public dailyInterestRate = uint256(10000);
	uint256 public totalWithdrawals = uint256(0);
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
 * Notes for _minStakeAmt : 1 Coin Coin_Testtoken is represented by 10^18.
*/
	function changeValueOf_minStakeAmt (uint256 _minStakeAmt) external onlyOwner {
		 minStakeAmt = _minStakeAmt;
	}

	

/**
 * This function allows the owner to change the value of maxStakeAmt.
 * Notes for _maxStakeAmt : 1 Coin Coin_Testtoken is represented by 10^18.
*/
	function changeValueOf_maxStakeAmt (uint256 _maxStakeAmt) external onlyOwner {
		 maxStakeAmt = _maxStakeAmt;
	}

	

/**
 * This function allows the owner to change the value of interestTax.
 * Notes for _interestTax : 10000 is one percent
*/
	function changeValueOf_interestTax (uint256 _interestTax) external onlyOwner {
		 interestTax = _interestTax;
	}

/**
 * Function stake
 * Daily Interest Rate : Variable dailyInterestRate
 * Address Map : addressMap
 * ERC20 Transfer : 0xA0Ec9Be4b42EB17a9FEF44127765080eC72017E3, _stakeAmt
 * The function takes in 1 variable, zero or a positive integer _stakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that _stakeAmt is strictly greater than 0
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that _stakeAmt is greater than or equals to minStakeAmt
 * checks that ((_stakeAmt) + (thisRecord with element stakeAmt)) is less than or equals to maxStakeAmt
 * if (thisRecord with element stakeAmt) is equals to 0 then (updates addressMap (Element the address that called this function) as Struct comprising current time, _stakeAmt, current time, 0, 0; then updates addressStore (Element numberOfAddressesCurrentlyStaked) as the address that called this function; and then updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) + (1)) otherwise (updates addressMap (Element the address that called this function) as Struct comprising current time, ((thisRecord with element stakeAmt) + (_stakeAmt)), current time, ((thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (dailyInterestRate)) / (86400000000))), (thisRecord with element amtWithdrawn))
 * calls ERC20's transferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as _stakeAmt
 * emits event Staked with inputs the address that called this function
*/
	function stake(uint256 _stakeAmt) public {
		require((_stakeAmt > uint256(0)), "Staked amount needs to be greater than 0");
		record memory thisRecord = addressMap[msg.sender];
		require((_stakeAmt >= minStakeAmt), "Less than minimum stake amount");
		require(((_stakeAmt + thisRecord.stakeAmt) <= maxStakeAmt), "More than maximum stake amount");
		if ((thisRecord.stakeAmt == uint256(0))){
			addressMap[msg.sender]  = record (block.timestamp, _stakeAmt, block.timestamp, uint256(0), uint256(0));
			addressStore[numberOfAddressesCurrentlyStaked]  = msg.sender;
			numberOfAddressesCurrentlyStaked  = (numberOfAddressesCurrentlyStaked + uint256(1));
		}else{
			addressMap[msg.sender]  = record (block.timestamp, (thisRecord.stakeAmt + _stakeAmt), block.timestamp, (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate) / uint256(86400000000))), thisRecord.amtWithdrawn);
		}
		ERC20(0xA0Ec9Be4b42EB17a9FEF44127765080eC72017E3).transferFrom(msg.sender, address(this), _stakeAmt);
		emit Staked(msg.sender);
	}

/**
 * Function unstake
 * The function takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
 * creates an internal variable newAccum with initial value (thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (dailyInterestRate)) / (86400000000))
 * creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
 * transfers ((interestToRemove) * ((1000000) - (interestTax))) / (1000000) of the native currency to the address that called this function
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _unstakeAmt
 * updates totalWithdrawals as (totalWithdrawals) + (((interestToRemove) * ((1000000) - (interestTax))) / (1000000))
 * updates interestTaxBank as (interestTaxBank) + (((interestToRemove) * (interestTax)) / (1000000))
 * if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (if (addressStore with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore (Element Loop Variable i0) as addressStore with element (numberOfAddressesCurrentlyStaked) - (1); then updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) - (1); and then terminates the for-next loop)))
 * updates addressMap (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove)), ((thisRecord with element amtWithdrawn) + (interestToRemove))
 * emits event Unstaked with inputs the address that called this function
*/
	function unstake(uint256 _unstakeAmt) public {
		record memory thisRecord = addressMap[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		uint256 newAccum = (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate) / uint256(86400000000)));
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		payable(msg.sender).transfer(((interestToRemove * (uint256(1000000) - interestTax)) / uint256(1000000)));
		ERC20(0xA0Ec9Be4b42EB17a9FEF44127765080eC72017E3).transfer(msg.sender, _unstakeAmt);
		totalWithdrawals  = (totalWithdrawals + ((interestToRemove * (uint256(1000000) - interestTax)) / uint256(1000000)));
		interestTaxBank  = (interestTaxBank + ((interestToRemove * interestTax) / uint256(1000000)));
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
 * repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap with element addressStore with element Loop Variable i0; and then updates addressMap (Element addressStore with element Loop Variable i0) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, ((thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (dailyInterestRate)) / (86400000000))), (thisRecord with element amtWithdrawn))
*/
	function updateRecordsWithLatestInterestRates() internal {
		for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
			record memory thisRecord = addressMap[addressStore[i0]];
			addressMap[addressStore[i0]]  = record (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate) / uint256(86400000000))), thisRecord.amtWithdrawn);
		}
	}

/**
 * Function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn
 * The function takes in 1 variable, an address _address. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element _address
 * returns (thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (dailyInterestRate)) / (86400000000)) as output
*/
	function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(address _address) public view returns (uint256) {
		record memory thisRecord = addressMap[_address];
		return (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * dailyInterestRate) / uint256(86400000000)));
	}

/**
 * Function withdrawInterestWithoutUnstaking
 * The function takes in 1 variable, zero or a positive integer _withdrawalAmt. It can only be called by functions outside of this contract. It does the following :
 * creates an internal variable totalInterestEarnedTillNow with initial value interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn with variable _address as the address that called this function
 * checks that _withdrawalAmt is less than or equals to totalInterestEarnedTillNow
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * updates addressMap (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, ((totalInterestEarnedTillNow) - (_withdrawalAmt)), ((thisRecord with element amtWithdrawn) + (_withdrawalAmt))
 * transfers ((_withdrawalAmt) * ((1000000) - (interestTax))) / (1000000) of the native currency to the address that called this function
 * updates interestTaxBank as (interestTaxBank) + (((_withdrawalAmt) * (interestTax)) / (1000000))
 * updates totalWithdrawals as (totalWithdrawals) + (((_withdrawalAmt) * ((1000000) - (interestTax))) / (1000000))
*/
	function withdrawInterestWithoutUnstaking(uint256 _withdrawalAmt) external {
		uint256 totalInterestEarnedTillNow = interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(msg.sender);
		require((_withdrawalAmt <= totalInterestEarnedTillNow), "Withdrawn amount must be less than withdrawable amount");
		record memory thisRecord = addressMap[msg.sender];
		addressMap[msg.sender]  = record (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, (totalInterestEarnedTillNow - _withdrawalAmt), (thisRecord.amtWithdrawn + _withdrawalAmt));
		payable(msg.sender).transfer(((_withdrawalAmt * (uint256(1000000) - interestTax)) / uint256(1000000)));
		interestTaxBank  = (interestTaxBank + ((_withdrawalAmt * interestTax) / uint256(1000000)));
		totalWithdrawals  = (totalWithdrawals + ((_withdrawalAmt * (uint256(1000000) - interestTax)) / uint256(1000000)));
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
 * Function withdrawInterestTax
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * transfers interestTaxBank of the native currency to the address that called this function
 * updates interestTaxBank as 0
*/
	function withdrawInterestTax() public onlyOwner {
		payable(msg.sender).transfer(interestTaxBank);
		interestTaxBank  = uint256(0);
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