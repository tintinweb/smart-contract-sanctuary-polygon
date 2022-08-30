/**
 *Submitted for verification at polygonscan.com on 2022-08-30
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Staking
 * Staking of : NFT Nft_TestNFT
 * NFT Address : 0xA196E006ae71eCF9074fCcB4DF84A56dbe4ACF37
 * Number of schemes : 1
 * Scheme 1 functions : stake, unstake
 * Referral Scheme : 0.22, 0.14
*/
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
	/**
	 * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
	 * by `operator` from `from`, this function is called.
	 *
	 * It must return its Solidity selector to confirm the token transfer.
	 * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
	 *
	 * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
	 */
	function onERC721Received(
		address operator,
		address from,
		uint256 tokenId,
		bytes calldata data
	) external returns (bytes4);
}

interface ERC20{
	function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ERC721{
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract Staking {

	address owner;
	uint256 public interestTaxBank = uint256(0);
	struct record { address staker; uint256 stakeTime; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(uint256 => record) public addressMap;
	mapping(uint256 => uint256) public tokenStore;
	uint256 public numberOfTokensCurrentlyStaked = uint256(0);
	uint256 public interestTaxWhere10000IsOnePercent = uint256(30000);
	uint256 public dailyInterestRate = uint256(20000);
	uint256 public dailyInterestRate_1 = uint256(10000);
	uint256 public dailyInterestRate_2 = uint256(30000);
	uint256 public minStakePeriod = (uint256(1300) * uint256(864));
	mapping(uint256 => uint256) public recordOfNumberOfPreviousStakesForEachToken;
	uint256 public totalWithdrawals = uint256(0);
	struct referralRecord { bool hasDeposited; address referringAddress; uint256 unclaimedRewards; }
	mapping(address => referralRecord) public referralRecordMap;
	event Staked (uint256 indexed tokenId);
	event Unstaked (uint256 indexed tokenId);

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

	function minUIntPair(uint _i, uint _j) internal pure returns (uint){
		if (_i < _j){
			return _i;
		}else{
			return _j;
		}
	}

	//This function allows the owner to change the value of interestTaxWhere10000IsOnePercent.
	function changeValueOf_interestTaxWhere10000IsOnePercent (uint256 _interestTaxWhere10000IsOnePercent) external onlyOwner {
		 interestTaxWhere10000IsOnePercent = _interestTaxWhere10000IsOnePercent;
	}

	//This function allows the owner to change the value of minStakePeriod.
	function changeValueOf_minStakePeriod (uint256 _minStakePeriod) external onlyOwner {
		 minStakePeriod = _minStakePeriod;
	}	

	function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data ) public returns (bytes4) {
		return this.onERC721Received.selector;
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
		ERC20(0x73C7cD2703eFECDA958132c08b0b376f2668895D).transfer(msg.sender, _amt);
		referralRecordMap[msg.sender].unclaimedRewards  = (referralRecordMap[msg.sender].unclaimedRewards - _amt);
	}

/**
 * Function addReferral
 * The function takes in 0 variables. It can only be called by other functions in this contract. It does the following :
 * creates an internal variable referringAddress with initial value referralRecordMap with element the address that called this function with element referringAddress
 * if not referralRecordMap with element the address that called this function with element hasDeposited then (updates referralRecordMap (Element the address that called this function) (Entity hasDeposited) as true)
 * if referringAddress is equals to Address 0 then ()
 * updates referralRecordMap (Element referringAddress) (Entity unclaimedRewards) as (referralRecordMap with element referringAddress with element unclaimedRewards) + (220000000000000000)
 * updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
 * if referringAddress is equals to Address 0 then ()
 * updates referralRecordMap (Element referringAddress) (Entity unclaimedRewards) as (referralRecordMap with element referringAddress with element unclaimedRewards) + (140000000000000000)
 * updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
*/
	function addReferral() internal {
		address referringAddress = referralRecordMap[msg.sender].referringAddress;
		if (!(referralRecordMap[msg.sender].hasDeposited)){
			referralRecordMap[msg.sender].hasDeposited  = true;
		}
		if ((referringAddress == address(0))){
			return;
		}
		referralRecordMap[referringAddress].unclaimedRewards  = (referralRecordMap[referringAddress].unclaimedRewards + uint256(220000000000000000));
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
		if ((referringAddress == address(0))){
			return;
		}
		referralRecordMap[referringAddress].unclaimedRewards  = (referralRecordMap[referringAddress].unclaimedRewards + uint256(140000000000000000));
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
 * The function takes in 1 variable, zero or a positive integer _tokenId. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (recordOfNumberOfPreviousStakesForEachToken with element _tokenId) is strictly less than 1
 * updates addressMap (Element _tokenId) as Struct comprising (the address that called this function), current time, current time, 0
 * calls ERC721's safeTransferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as _tokenId
 * emits event Staked with inputs _tokenId
 * updates tokenStore (Element numberOfTokensCurrentlyStaked) as _tokenId
 * updates numberOfTokensCurrentlyStaked as (numberOfTokensCurrentlyStaked) + (1)
 * calls addReferral
 * updates recordOfNumberOfPreviousStakesForEachToken (Element _tokenId) as (recordOfNumberOfPreviousStakesForEachToken with element _tokenId) + (1)
*/
	function stake(uint256 _tokenId) public {
		require((recordOfNumberOfPreviousStakesForEachToken[_tokenId] < uint256(1)), "This Token can only be staked 1 time");
		addressMap[_tokenId]  = record (msg.sender, block.timestamp, block.timestamp, uint256(0));
		ERC721(0xA196E006ae71eCF9074fCcB4DF84A56dbe4ACF37).safeTransferFrom(msg.sender, address(this), _tokenId);
		emit Staked(_tokenId);
		tokenStore[numberOfTokensCurrentlyStaked]  = _tokenId;
		numberOfTokensCurrentlyStaked  = (numberOfTokensCurrentlyStaked + uint256(1));
		addReferral();
		recordOfNumberOfPreviousStakesForEachToken[_tokenId]  = (recordOfNumberOfPreviousStakesForEachToken[_tokenId] + uint256(1));
	}

/**
 * Function unstake
 * The function takes in 1 variable, zero or a positive integer _tokenId. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element _tokenId
 * checks that ((current time) - (minStakePeriod)) is greater than or equals to (thisRecord with element stakeTime)
 * creates an internal variable interestToRemove with initial value (thisRecord with element accumulatedInterestToUpdateTime) + ((((minimum of current time, ((thisRecord with element stakeTime) + ((19900) * (864)))) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _tokenId as _tokenId) * (1000000000000)) / (864))
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as ((interestToRemove) * ((1000000) - (interestTaxWhere10000IsOnePercent))) / (1000000)
 * updates interestTaxBank as (interestTaxBank) + (((interestToRemove) * (interestTaxWhere10000IsOnePercent)) / (1000000))
 * updates totalWithdrawals as (totalWithdrawals) + (((interestToRemove) * ((1000000) - (interestTaxWhere10000IsOnePercent))) / (1000000))
 * checks that (thisRecord with element staker) is equals to (the address that called this function)
 * calls ERC721's safeTransferFrom function  with variable sender as the address of this contract, variable recipient as the address that called this function, variable amount as _tokenId
 * deletes item _tokenId from mapping addressMap
 * emits event Unstaked with inputs _tokenId
 * repeat numberOfTokensCurrentlyStaked times with loop variable i0 :  (if (tokenStore with element Loop Variable i0) is equals to _tokenId then (updates tokenStore (Element Loop Variable i0) as tokenStore with element (numberOfTokensCurrentlyStaked) - (1); then updates numberOfTokensCurrentlyStaked as (numberOfTokensCurrentlyStaked) - (1); and then terminates the for-next loop))
*/
	function unstake(uint256 _tokenId) public {
		record memory thisRecord = addressMap[_tokenId];
		require(((block.timestamp - minStakePeriod) >= thisRecord.stakeTime), "Insufficient stake period");
		uint256 interestToRemove = (thisRecord.accumulatedInterestToUpdateTime + (((minUIntPair(block.timestamp, (thisRecord.stakeTime + (uint256(19900) * uint256(864)))) - thisRecord.lastUpdateTime) * consolidatedInterestRate(_tokenId) * uint256(1000000000000)) / uint256(864)));
		ERC20(0x73C7cD2703eFECDA958132c08b0b376f2668895D).transfer(msg.sender, ((interestToRemove * (uint256(1000000) - interestTaxWhere10000IsOnePercent)) / uint256(1000000)));
		interestTaxBank  = (interestTaxBank + ((interestToRemove * interestTaxWhere10000IsOnePercent) / uint256(1000000)));
		totalWithdrawals  = (totalWithdrawals + ((interestToRemove * (uint256(1000000) - interestTaxWhere10000IsOnePercent)) / uint256(1000000)));
		require((thisRecord.staker == msg.sender), "You do not own this token");
		ERC721(0xA196E006ae71eCF9074fCcB4DF84A56dbe4ACF37).safeTransferFrom(address(this), msg.sender, _tokenId);
		delete addressMap[_tokenId];
		emit Unstaked(_tokenId);
		for (uint i0 = 0; i0 < numberOfTokensCurrentlyStaked; i0++){
			if ((tokenStore[i0] == _tokenId)){
				tokenStore[i0]  = tokenStore[(numberOfTokensCurrentlyStaked - uint256(1))];
				numberOfTokensCurrentlyStaked  = (numberOfTokensCurrentlyStaked - uint256(1));
				break;
			}
		}
	}

/**
 * Function updateRecordsWithLatestInterestRates
 * The function takes in 0 variables. It can only be called by other functions in this contract. It does the following :
 * repeat numberOfTokensCurrentlyStaked times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap with element tokenStore with element Loop Variable i0; and then updates addressMap (Element tokenStore with element Loop Variable i0) as Struct comprising (thisRecord with element staker), (thisRecord with element stakeTime), (minimum of current time, ((thisRecord with element stakeTime) + ((19900) * (864)))), ((thisRecord with element accumulatedInterestToUpdateTime) + ((((minimum of current time, ((thisRecord with element stakeTime) + ((19900) * (864)))) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _tokenId as Loop Variable i0) * (1000000000000)) / (864))))
*/
	function updateRecordsWithLatestInterestRates() internal {
		for (uint i0 = 0; i0 < numberOfTokensCurrentlyStaked; i0++){
			record memory thisRecord = addressMap[tokenStore[i0]];
			addressMap[tokenStore[i0]]  = record (thisRecord.staker, thisRecord.stakeTime, minUIntPair(block.timestamp, (thisRecord.stakeTime + (uint256(19900) * uint256(864)))), (thisRecord.accumulatedInterestToUpdateTime + (((minUIntPair(block.timestamp, (thisRecord.stakeTime + (uint256(19900) * uint256(864)))) - thisRecord.lastUpdateTime) * consolidatedInterestRate(i0) * uint256(1000000000000)) / uint256(864))));
		}
	}

/**
 * Function numberOfStakedTokenIDsOfAnAddress
 * The function takes in 1 variable, an address _address. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable _counter with initial value 0
 * repeat numberOfTokensCurrentlyStaked times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore with element Loop Variable i0; and then if (addressMap with element _tokenID with element staker) is equals to _address then (updates _counter as (_counter) + (1)))
 * returns _counter as output
*/
	function numberOfStakedTokenIDsOfAnAddress(address _address) public view returns (uint256) {
		uint256 _counter = uint256(0);
		for (uint i0 = 0; i0 < numberOfTokensCurrentlyStaked; i0++){
			uint256 _tokenID = tokenStore[i0];
			if ((addressMap[_tokenID].staker == _address)){
				_counter  = (_counter + uint256(1));
			}
		}
		return _counter;
	}

/**
 * Function stakedTokenIDsOfAnAddress
 * The function takes in 1 variable, an address _address. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable tokenIDs
 * creates an internal variable _counter with initial value 0
 * repeat numberOfTokensCurrentlyStaked times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore with element Loop Variable i0; and then if (addressMap with element _tokenID with element staker) is equals to _address then (updates tokenIDs (Element _counter) as _tokenID; and then updates _counter as (_counter) + (1)))
 * returns tokenIDs as output
*/
	function stakedTokenIDsOfAnAddress(address _address) public view returns (uint256[] memory) {
		uint256[] memory tokenIDs = new uint256[](numberOfStakedTokenIDsOfAnAddress(_address));
		uint256 _counter = uint256(0);
		for (uint i0 = 0; i0 < numberOfTokensCurrentlyStaked; i0++){
			uint256 _tokenID = tokenStore[i0];
			if ((addressMap[_tokenID].staker == _address)){
				tokenIDs[_counter]  = _tokenID;
				_counter  = (_counter + uint256(1));
			}
		}
		return tokenIDs;
	}

/**
 * Function whichStakedTokenIDsOfAnAddress
 * The function takes in 2 variables, an address _address, and zero or a positive integer _counterIn. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable _counter with initial value 0
 * repeat numberOfTokensCurrentlyStaked times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore with element Loop Variable i0; and then if (addressMap with element _tokenID with element staker) is equals to _address then (if _counterIn is equals to _counter then (returns _tokenID as output); and then updates _counter as (_counter) + (1)))
 * returns 9999999 as output
*/
	function whichStakedTokenIDsOfAnAddress(address _address, uint256 _counterIn) public view returns (uint256) {
		uint256 _counter = uint256(0);
		for (uint i0 = 0; i0 < numberOfTokensCurrentlyStaked; i0++){
			uint256 _tokenID = tokenStore[i0];
			if ((addressMap[_tokenID].staker == _address)){
				if ((_counterIn == _counter)){
					return _tokenID;
				}
				_counter  = (_counter + uint256(1));
			}
		}
		return uint256(9999999);
	}

/**
 * Function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn
 * The function takes in 1 variable, zero or a positive integer _tokenId. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element _tokenId
 * returns (thisRecord with element accumulatedInterestToUpdateTime) + ((((minimum of current time, ((thisRecord with element stakeTime) + ((19900) * (864)))) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _tokenId as _tokenId) * (1000000000000)) / (864)) as output
*/
	function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(uint256 _tokenId) public view returns (uint256) {
		record memory thisRecord = addressMap[_tokenId];
		return (thisRecord.accumulatedInterestToUpdateTime + (((minUIntPair(block.timestamp, (thisRecord.stakeTime + (uint256(19900) * uint256(864)))) - thisRecord.lastUpdateTime) * consolidatedInterestRate(_tokenId) * uint256(1000000000000)) / uint256(864)));
	}

/**
 * Function consolidatedInterestRate
 * The function takes in 1 variable, zero or a positive integer _tokenId. It can be called by functions both inside and outside of this contract. It does the following :
 * if _tokenId is greater than or equals to 10 then (returns dailyInterestRate_2 as output)
 * if _tokenId is less than or equals to 3 then (returns dailyInterestRate_1 as output)
 * returns dailyInterestRate as output
*/
	function consolidatedInterestRate(uint256 _tokenId) public view returns (uint256) {
		if ((_tokenId >= uint256(10))){
			return dailyInterestRate_2;
		}
		if ((_tokenId <= uint256(3))){
			return dailyInterestRate_1;
		}
		return dailyInterestRate;
	}

/**
 * Function modifyDailyInterestRateWhere10000IsOneCoin
 * The function takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls updateRecordsWithLatestInterestRates
 * updates dailyInterestRate as _dailyInterestRate
*/
	function modifyDailyInterestRateWhere10000IsOneCoin(uint256 _dailyInterestRate) public onlyOwner {
		updateRecordsWithLatestInterestRates();
		dailyInterestRate  = _dailyInterestRate;
	}

/**
 * Function modifyDailyInterestRateWhere10000IsOneCoin_1
 * The function takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls updateRecordsWithLatestInterestRates
 * updates dailyInterestRate_1 as _dailyInterestRate
*/
	function modifyDailyInterestRateWhere10000IsOneCoin_1(uint256 _dailyInterestRate) public onlyOwner {
		updateRecordsWithLatestInterestRates();
		dailyInterestRate_1  = _dailyInterestRate;
	}

/**
 * Function modifyDailyInterestRateWhere10000IsOneCoin_2
 * The function takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls updateRecordsWithLatestInterestRates
 * updates dailyInterestRate_2 as _dailyInterestRate
*/
	function modifyDailyInterestRateWhere10000IsOneCoin_2(uint256 _dailyInterestRate) public onlyOwner {
		updateRecordsWithLatestInterestRates();
		dailyInterestRate_2  = _dailyInterestRate;
	}

/**
 * Function withdrawInterestTax
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as interestTaxBank
 * updates interestTaxBank as 0
*/
	function withdrawInterestTax() public onlyOwner {
		ERC20(0x73C7cD2703eFECDA958132c08b0b376f2668895D).transfer(msg.sender, interestTaxBank);
		interestTaxBank  = uint256(0);
	}

/**
 * Function withdrawToken
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _amt
*/
	function withdrawToken(uint256 _amt) public onlyOwner {
		ERC20(0x73C7cD2703eFECDA958132c08b0b376f2668895D).transfer(msg.sender, _amt);
	}
}