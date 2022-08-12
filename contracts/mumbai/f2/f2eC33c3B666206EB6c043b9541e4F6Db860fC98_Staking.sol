/**
 *Submitted for verification at polygonscan.com on 2022-08-11
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Staking
 * Staking of : NFT Nft_MyNFT
 * NFT Address : 0x7Ea644Ab0ea67dE2905e8e0A8Feea769fB2847F1
 * Number of schemes : 2
 * Scheme 1 functions : stake1, unstake1
 * Scheme 2 functions : stake2, unstake2
*//**
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

interface ERC721{
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract Staking {

	address owner;
	struct record1 { address staker; uint256 stakeTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(uint256 => record1) public addressMap1;
	mapping(uint256 => uint256) public tokenStore1;
	uint256 public lastToken1 = uint256(0);
	struct record2 { address staker; uint256 stakeTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(uint256 => record2) public addressMap2;
	mapping(uint256 => uint256) public tokenStore2;
	uint256 public lastToken2 = uint256(0);
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

	function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data ) public returns (bytes4) {
		return this.onERC721Received.selector;
	}

/**
 * Function stake1
 * Address Map : addressMap1
 * The function takes in 1 variable, zero or a positive integer _tokenId. It can be called by functions both inside and outside of this contract. It does the following :
 * updates addressMap1 (Element _tokenId) as Struct comprising (the address that called this function), current time, 0
 * calls ERC721's safeTransferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as _tokenId
 * emits event Staked with inputs _tokenId
 * updates tokenStore1 (Element lastToken1) as _tokenId
 * updates lastToken1 as (lastToken1) + (1)
*/
	function stake1(uint256 _tokenId) public {
		addressMap1[_tokenId]  = record1 (msg.sender, block.timestamp, uint256(0));
		ERC721(0x7Ea644Ab0ea67dE2905e8e0A8Feea769fB2847F1).safeTransferFrom(msg.sender, address(this), _tokenId);
		emit Staked(_tokenId);
		tokenStore1[lastToken1]  = _tokenId;
		lastToken1  = (lastToken1 + uint256(1));
	}

/**
 * Function unstake1
 * The function takes in 1 variable, zero or a positive integer _tokenId. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap1 with element _tokenId
 * creates an internal variable interestToRemove with initial value thisRecord with element accumulatedInterestToUpdateTime
 * transfers interestToRemove of the native currency to the address that called this function
 * checks that (thisRecord with element staker) is equals to (the address that called this function)
 * calls ERC721's safeTransferFrom function  with variable sender as the address of this contract, variable recipient as the address that called this function, variable amount as _tokenId
 * deletes item _tokenId from mapping addressMap1
 * emits event Unstaked with inputs _tokenId
 * repeat lastToken1 times with loop variable i0 :  (if (tokenStore1 with element Loop Variable i0) is equals to _tokenId then (updates tokenStore1 (Element Loop Variable i0) as tokenStore1 with element (lastToken1) - (1); then updates lastToken1 as (lastToken1) - (1); and then terminates the for-next loop))
*/
	function unstake1(uint256 _tokenId) public {
		record1 memory thisRecord = addressMap1[_tokenId];
		uint256 interestToRemove = thisRecord.accumulatedInterestToUpdateTime;
		payable(msg.sender).transfer(interestToRemove);
		require((thisRecord.staker == msg.sender), "You do not own this token");
		ERC721(0x7Ea644Ab0ea67dE2905e8e0A8Feea769fB2847F1).safeTransferFrom(address(this), msg.sender, _tokenId);
		delete addressMap1[_tokenId];
		emit Unstaked(_tokenId);
		for (uint i0 = 0; i0 < lastToken1; i0++){
			if ((tokenStore1[i0] == _tokenId)){
				tokenStore1[i0]  = tokenStore1[(lastToken1 - uint256(1))];
				lastToken1  = (lastToken1 - uint256(1));
				break;
			}
		}
	}

/**
 * Function deposit1
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable accumulatedParts with initial value 0
 * repeat lastToken1 times with loop variable i0 :  (creates an internal variable aSender with initial value tokenStore1 with element Loop Variable i0; then creates an internal variable thisRecord with initial value addressMap1 with element aSender; then creates an internal variable stakedPeriod with initial value (current time) - (thisRecord with element stakeTime); then if stakedPeriod is strictly greater than ((300) * (864)) then (updates stakedPeriod as (300) * (864)); and then updates accumulatedParts as (accumulatedParts) + (stakedPeriod))
 * repeat lastToken1 times with loop variable i0 :  (creates an internal variable aSender with initial value tokenStore1 with element Loop Variable i0; then creates an internal variable thisRecord with initial value addressMap1 with element aSender; then creates an internal variable stakedPeriod with initial value (current time) - (thisRecord with element stakeTime); then if stakedPeriod is strictly greater than ((300) * (864)) then (updates stakedPeriod as (300) * (864)); and then updates addressMap1 (Element aSender) as Struct comprising (thisRecord with element staker), (thisRecord with element stakeTime), ((thisRecord with element accumulatedInterestToUpdateTime) + (((stakedPeriod) * (amount of native currency sent to contract)) / (accumulatedParts))))
*/
	function deposit1() public payable {
		uint256 accumulatedParts = uint256(0);
		for (uint i0 = 0; i0 < lastToken1; i0++){
			uint256 aSender = tokenStore1[i0];
			record1 memory thisRecord = addressMap1[aSender];
			uint256 stakedPeriod = (block.timestamp - thisRecord.stakeTime);
			if ((stakedPeriod > (uint256(300) * uint256(864)))){
				stakedPeriod  = (uint256(300) * uint256(864));
			}
			accumulatedParts  = (accumulatedParts + stakedPeriod);
		}
		for (uint i0 = 0; i0 < lastToken1; i0++){
			uint256 aSender = tokenStore1[i0];
			record1 memory thisRecord = addressMap1[aSender];
			uint256 stakedPeriod = (block.timestamp - thisRecord.stakeTime);
			if ((stakedPeriod > (uint256(300) * uint256(864)))){
				stakedPeriod  = (uint256(300) * uint256(864));
			}
			addressMap1[aSender]  = record1 (thisRecord.staker, thisRecord.stakeTime, (thisRecord.accumulatedInterestToUpdateTime + ((stakedPeriod * msg.value) / accumulatedParts)));
		}
	}

/**
 * Function numberOfStakedTokenIDsOfAnAddress1
 * The function takes in 1 variable, an address _address. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable _counter with initial value 0
 * repeat lastToken1 times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore1 with element Loop Variable i0; and then if (addressMap1 with element _tokenID with element staker) is equals to _address then (updates _counter as (_counter) + (1)))
 * returns _counter as output
*/
	function numberOfStakedTokenIDsOfAnAddress1(address _address) public view returns (uint256) {
		uint256 _counter = uint256(0);
		for (uint i0 = 0; i0 < lastToken1; i0++){
			uint256 _tokenID = tokenStore1[i0];
			if ((addressMap1[_tokenID].staker == _address)){
				_counter  = (_counter + uint256(1));
			}
		}
		return _counter;
	}

/**
 * Function stakedTokenIDsOfAnAddress1
 * The function takes in 1 variable, an address _address. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable tokenIDs
 * creates an internal variable _counter with initial value 0
 * repeat lastToken1 times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore1 with element Loop Variable i0; and then if (addressMap1 with element _tokenID with element staker) is equals to _address then (updates tokenIDs (Element _counter) as _tokenID; and then updates _counter as (_counter) + (1)))
 * returns tokenIDs as output
*/
	function stakedTokenIDsOfAnAddress1(address _address) public view returns (uint256[] memory) {
		uint256[] memory tokenIDs = new uint256[](numberOfStakedTokenIDsOfAnAddress1(_address));
		uint256 _counter = uint256(0);
		for (uint i0 = 0; i0 < lastToken1; i0++){
			uint256 _tokenID = tokenStore1[i0];
			if ((addressMap1[_tokenID].staker == _address)){
				tokenIDs[_counter]  = _tokenID;
				_counter  = (_counter + uint256(1));
			}
		}
		return tokenIDs;
	}

/**
 * Function whichStakedTokenIDsOfAnAddress1
 * The function takes in 2 variables, an address _address, and zero or a positive integer _counterIn. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable _counter with initial value 0
 * repeat lastToken1 times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore1 with element Loop Variable i0; and then if (addressMap1 with element _tokenID with element staker) is equals to _address then (if _counterIn is equals to _counter then (returns _tokenID as output); and then updates _counter as (_counter) + (1)))
 * returns 9999999 as output
*/
	function whichStakedTokenIDsOfAnAddress1(address _address, uint256 _counterIn) public view returns (uint256) {
		uint256 _counter = uint256(0);
		for (uint i0 = 0; i0 < lastToken1; i0++){
			uint256 _tokenID = tokenStore1[i0];
			if ((addressMap1[_tokenID].staker == _address)){
				if ((_counterIn == _counter)){
					return _tokenID;
				}
				_counter  = (_counter + uint256(1));
			}
		}
		return uint256(9999999);
	}

/**
 * Function stake2
 * Address Map : addressMap2
 * The function takes in 1 variable, zero or a positive integer _tokenId. It can be called by functions both inside and outside of this contract. It does the following :
 * updates addressMap2 (Element _tokenId) as Struct comprising (the address that called this function), current time, 0
 * calls ERC721's safeTransferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as _tokenId
 * emits event Staked with inputs _tokenId
 * updates tokenStore2 (Element lastToken2) as _tokenId
 * updates lastToken2 as (lastToken2) + (1)
*/
	function stake2(uint256 _tokenId) public {
		addressMap2[_tokenId]  = record2 (msg.sender, block.timestamp, uint256(0));
		ERC721(0x7Ea644Ab0ea67dE2905e8e0A8Feea769fB2847F1).safeTransferFrom(msg.sender, address(this), _tokenId);
		emit Staked(_tokenId);
		tokenStore2[lastToken2]  = _tokenId;
		lastToken2  = (lastToken2 + uint256(1));
	}

/**
 * Function unstake2
 * The function takes in 1 variable, zero or a positive integer _tokenId. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap2 with element _tokenId
 * creates an internal variable interestToRemove with initial value thisRecord with element accumulatedInterestToUpdateTime
 * transfers interestToRemove of the native currency to the address that called this function
 * checks that (thisRecord with element staker) is equals to (the address that called this function)
 * calls ERC721's safeTransferFrom function  with variable sender as the address of this contract, variable recipient as the address that called this function, variable amount as _tokenId
 * deletes item _tokenId from mapping addressMap2
 * emits event Unstaked with inputs _tokenId
 * repeat lastToken2 times with loop variable i0 :  (if (tokenStore2 with element Loop Variable i0) is equals to _tokenId then (updates tokenStore2 (Element Loop Variable i0) as tokenStore2 with element (lastToken2) - (1); then updates lastToken2 as (lastToken2) - (1); and then terminates the for-next loop))
*/
	function unstake2(uint256 _tokenId) public {
		record2 memory thisRecord = addressMap2[_tokenId];
		uint256 interestToRemove = thisRecord.accumulatedInterestToUpdateTime;
		payable(msg.sender).transfer(interestToRemove);
		require((thisRecord.staker == msg.sender), "You do not own this token");
		ERC721(0x7Ea644Ab0ea67dE2905e8e0A8Feea769fB2847F1).safeTransferFrom(address(this), msg.sender, _tokenId);
		delete addressMap2[_tokenId];
		emit Unstaked(_tokenId);
		for (uint i0 = 0; i0 < lastToken2; i0++){
			if ((tokenStore2[i0] == _tokenId)){
				tokenStore2[i0]  = tokenStore2[(lastToken2 - uint256(1))];
				lastToken2  = (lastToken2 - uint256(1));
				break;
			}
		}
	}

/**
 * Function deposit2
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable accumulatedParts with initial value 0
 * repeat lastToken2 times with loop variable i0 :  (creates an internal variable aSender with initial value tokenStore2 with element Loop Variable i0; then creates an internal variable thisRecord with initial value addressMap2 with element aSender; then creates an internal variable stakedPeriod with initial value (current time) - (thisRecord with element stakeTime); then if stakedPeriod is strictly greater than ((300) * (864)) then (updates stakedPeriod as (300) * (864)); and then updates accumulatedParts as (accumulatedParts) + (stakedPeriod))
 * repeat lastToken2 times with loop variable i0 :  (creates an internal variable aSender with initial value tokenStore2 with element Loop Variable i0; then creates an internal variable thisRecord with initial value addressMap2 with element aSender; then creates an internal variable stakedPeriod with initial value (current time) - (thisRecord with element stakeTime); then if stakedPeriod is strictly greater than ((300) * (864)) then (updates stakedPeriod as (300) * (864)); and then updates addressMap2 (Element aSender) as Struct comprising (thisRecord with element staker), (thisRecord with element stakeTime), ((thisRecord with element accumulatedInterestToUpdateTime) + (((stakedPeriod) * (amount of native currency sent to contract)) / (accumulatedParts))))
*/
	function deposit2() public payable {
		uint256 accumulatedParts = uint256(0);
		for (uint i0 = 0; i0 < lastToken2; i0++){
			uint256 aSender = tokenStore2[i0];
			record2 memory thisRecord = addressMap2[aSender];
			uint256 stakedPeriod = (block.timestamp - thisRecord.stakeTime);
			if ((stakedPeriod > (uint256(300) * uint256(864)))){
				stakedPeriod  = (uint256(300) * uint256(864));
			}
			accumulatedParts  = (accumulatedParts + stakedPeriod);
		}
		for (uint i0 = 0; i0 < lastToken2; i0++){
			uint256 aSender = tokenStore2[i0];
			record2 memory thisRecord = addressMap2[aSender];
			uint256 stakedPeriod = (block.timestamp - thisRecord.stakeTime);
			if ((stakedPeriod > (uint256(300) * uint256(864)))){
				stakedPeriod  = (uint256(300) * uint256(864));
			}
			addressMap2[aSender]  = record2 (thisRecord.staker, thisRecord.stakeTime, (thisRecord.accumulatedInterestToUpdateTime + ((stakedPeriod * msg.value) / accumulatedParts)));
		}
	}

/**
 * Function numberOfStakedTokenIDsOfAnAddress2
 * The function takes in 1 variable, an address _address. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable _counter with initial value 0
 * repeat lastToken2 times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore2 with element Loop Variable i0; and then if (addressMap2 with element _tokenID with element staker) is equals to _address then (updates _counter as (_counter) + (1)))
 * returns _counter as output
*/
	function numberOfStakedTokenIDsOfAnAddress2(address _address) public view returns (uint256) {
		uint256 _counter = uint256(0);
		for (uint i0 = 0; i0 < lastToken2; i0++){
			uint256 _tokenID = tokenStore2[i0];
			if ((addressMap2[_tokenID].staker == _address)){
				_counter  = (_counter + uint256(1));
			}
		}
		return _counter;
	}

/**
 * Function stakedTokenIDsOfAnAddress2
 * The function takes in 1 variable, an address _address. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable tokenIDs
 * creates an internal variable _counter with initial value 0
 * repeat lastToken2 times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore2 with element Loop Variable i0; and then if (addressMap2 with element _tokenID with element staker) is equals to _address then (updates tokenIDs (Element _counter) as _tokenID; and then updates _counter as (_counter) + (1)))
 * returns tokenIDs as output
*/
	function stakedTokenIDsOfAnAddress2(address _address) public view returns (uint256[] memory) {
		uint256[] memory tokenIDs = new uint256[](numberOfStakedTokenIDsOfAnAddress2(_address));
		uint256 _counter = uint256(0);
		for (uint i0 = 0; i0 < lastToken2; i0++){
			uint256 _tokenID = tokenStore2[i0];
			if ((addressMap2[_tokenID].staker == _address)){
				tokenIDs[_counter]  = _tokenID;
				_counter  = (_counter + uint256(1));
			}
		}
		return tokenIDs;
	}

/**
 * Function whichStakedTokenIDsOfAnAddress2
 * The function takes in 2 variables, an address _address, and zero or a positive integer _counterIn. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable _counter with initial value 0
 * repeat lastToken2 times with loop variable i0 :  (creates an internal variable _tokenID with initial value tokenStore2 with element Loop Variable i0; and then if (addressMap2 with element _tokenID with element staker) is equals to _address then (if _counterIn is equals to _counter then (returns _tokenID as output); and then updates _counter as (_counter) + (1)))
 * returns 9999999 as output
*/
	function whichStakedTokenIDsOfAnAddress2(address _address, uint256 _counterIn) public view returns (uint256) {
		uint256 _counter = uint256(0);
		for (uint i0 = 0; i0 < lastToken2; i0++){
			uint256 _tokenID = tokenStore2[i0];
			if ((addressMap2[_tokenID].staker == _address)){
				if ((_counterIn == _counter)){
					return _tokenID;
				}
				_counter  = (_counter + uint256(1));
			}
		}
		return uint256(9999999);
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