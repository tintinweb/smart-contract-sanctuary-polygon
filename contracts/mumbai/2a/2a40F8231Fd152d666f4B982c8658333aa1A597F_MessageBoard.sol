/**
 *Submitted for verification at polygonscan.com on 2023-01-11
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : MsgBoard
*/

contract MessageBoard {

	address owner;
	struct aMessage { uint256 msgId; uint256 catId; string message; address userName; uint256 messageNativeCurrencyPrice; }
	struct aCategory { uint256 catId; bool isTheCategoryAlreadyAdded; uint256 messageNativeCurrencyPrice; }
	mapping(string => aCategory) public categoriesInfo;
	string[] public categoriesList;
	aMessage[] public messagesList;
	uint256 public messageNativePrice = uint256(20000000000000);

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
 * Function addMessage
 * The function takes in 2 variables, (a string) catName, and (a string) message. It can only be called by functions outside of this contract. It does the following :
 * creates an internal variable thisCategory with initial value categoriesInfo with element catName
 * if (thisCategory with element isTheCategoryAlreadyAdded) is equals to true then it does nothing else otherwise (creates an internal variable nosCategories with initial value length of categoriesList; then adds catName to categoriesList; then updates thisCategory (Entity isTheCategoryAlreadyAdded) as true; and then updates thisCategory (Entity catId) as nosCategories)
 * checks that (amount of native currency sent to contract) is strictly greater than (thisCategory with element messageNativeCurrencyPrice)
 * checks that (amount of native currency sent to contract) is greater than or equals to messageNativePrice
 * updates thisCategory (Entity messageNativeCurrencyPrice) as amount of native currency sent to contract
 * updates categoriesInfo (Element catName) as thisCategory
 * creates an internal variable nosMessages with initial value length of messagesList
 * creates an internal variable messagesContent with initial value Struct comprising nosMessages, (thisCategory with element catId), message, (the address that called this function), (amount of native currency sent to contract)
 * adds messagesContent to messagesList
*/
	function addMessage(string memory catName, string memory message) external payable {
		aCategory memory thisCategory = categoriesInfo[catName];
		if ((thisCategory.isTheCategoryAlreadyAdded == true)){
		}else{
			uint256 nosCategories = (categoriesList).length;
			categoriesList.push(catName);
			thisCategory.isTheCategoryAlreadyAdded  = true;
			thisCategory.catId  = nosCategories;
		}
		require((msg.value > thisCategory.messageNativeCurrencyPrice), "Need at least one payment that is strictly greater than previous payments");
		require((msg.value >= messageNativePrice), "Incorrect Payment");
		thisCategory.messageNativeCurrencyPrice  = msg.value;
		categoriesInfo[catName]  = thisCategory;
		uint256 nosMessages = (messagesList).length;
		aMessage memory messagesContent = aMessage (nosMessages, thisCategory.catId, message, msg.sender, msg.value);
		messagesList.push(messagesContent);
	}

/**
 * Function withdrawNativeCurrency
 * The function takes in 1 variable, (zero or a positive integer) _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * checks that (amount of native currency owned by the address of this contract) is greater than or equals to _amt
 * transfers _amt of the native currency to the address that called this function
*/
	function withdrawNativeCurrency(uint256 _amt) public onlyOwner {
		require((address(this).balance >= _amt), "Insufficient amount of native currency in this contract to transfer out. Please contact the contract owner to top up the native currency.");
		payable(msg.sender).transfer(_amt);
	}
}