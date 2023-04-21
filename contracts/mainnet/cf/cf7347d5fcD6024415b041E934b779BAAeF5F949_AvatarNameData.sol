// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
  A storage contract to store the names of the components.  
  @dev Component IDs now no longer need to be unique across all asset categories.
*/

contract AvatarNameData is Ownable {

    //constants for the types of attribute categories
    uint constant NAME_ATTRIBUTE = 1;
    uint constant HEX_ATTRIBUTE = 2;

    //represents a single component's data needed for tokenURI
    struct AttributeInfo {
        string name;
        bool valid;
    }

    //Represents the different Categories trait/components belong in, and it's type
    struct AttributeCategory{
        mapping(uint => AttributeInfo) name;
        uint attrType;
        bool valid;
    }

    //Array of Attribute Categories
    mapping(uint => AttributeCategory) public _attrCategory;

    //List of possible errors
    error InvalidAttribute(uint attrId);
    error InvalidComponent(uint compId, uint attrId);

     //check that the attribute category is valid
    modifier attrExists(uint attrId) {
        if(!_attrCategory[attrId].valid)
            revert InvalidAttribute(attrId);
        _;
    }

    function addAttributeCategory(uint attrId, uint attributeType) public onlyOwner {
        //check that the attribute category DOESN't exist yet.
        if(_attrCategory[attrId].valid)
            revert InvalidAttribute(attrId);
        if( (attributeType != NAME_ATTRIBUTE) && (attributeType != HEX_ATTRIBUTE) )
            revert InvalidAttribute(attrId);

        _attrCategory[attrId].valid = true;
        _attrCategory[attrId].attrType = attributeType;
    }

    //add a new component to data
    function addComponent(uint componentId, uint attrId, string calldata name) public onlyOwner attrExists(attrId) {
        //don't add components to HEX_ATTRIBUTE categories
        if(_attrCategory[attrId].attrType == HEX_ATTRIBUTE)
            revert InvalidComponent(componentId, attrId);
            
        _attrCategory[attrId].name[componentId] = AttributeInfo(name, true);
    }

    //batch add components
    function addManyComponents(uint[] calldata componentId, uint[] calldata attrIds, string[] calldata names) public onlyOwner {
        for(uint i=0; i < componentId.length ; i++) {
            addComponent(componentId[i], attrIds[i], names[i]);
        }
    }

    //get the name of the component
    function componentName(uint componentId, uint attrId) public view attrExists(attrId) returns(string memory) {
        if(_attrCategory[attrId].attrType == NAME_ATTRIBUTE){
            if(!_attrCategory[attrId].name[componentId].valid)
                revert InvalidComponent(componentId, attrId);

            return _attrCategory[attrId].name[componentId].name;
        }
        else if(_attrCategory[attrId].attrType == HEX_ATTRIBUTE){
            //any component is valid (convert to HEX)
            return string(abi.encodePacked("#",toHexString(componentId, 6)));
        }
        else    
            revert InvalidComponent(componentId, attrId);
    }

    //batch lookup of component names
    function componentNames(uint[] memory compValues, uint[] memory attrIds) public view returns(string[] memory) {
        string[] memory output = new string[](compValues.length);
        for(uint i=0; i < compValues.length ; i++) {
            output[i] = componentName(compValues[i], attrIds[i]);
        }
        return output;
    }

    //validate componentID and attributeID
    function componentAttribute(uint componentId, uint attrId) public view attrExists(attrId) returns(bool) {
        //zero is always a valid component attribute (represents a remove attribute)
        if(componentId == 0)
            return true;
            
        if(_attrCategory[attrId].attrType == NAME_ATTRIBUTE)
            return _attrCategory[attrId].name[componentId].valid;
        else if(_attrCategory[attrId].attrType == HEX_ATTRIBUTE)
            return true;
        else    
            return false;
    }

    //validate all provided componentIds and attributeIds
    //this will return the index of the first mismatch
    //if there are no mismatches, then i will equal the array size.
    function batchComponentAttributes(uint[] memory componentIds, uint[] memory attrIds) public view returns (uint) {
        uint i;
        for(i=0 ; i < componentIds.length ; i++) {
            //terminate and report if mismatch found
            if(!componentAttribute(componentIds[i], attrIds[i]))
                break;
        }
        return i;
    }

    /**
     * @dev Converts a `uint256` to its ASCII HEX `string` representation with a fixed length. Number will be truncated if larger than will fit in length digits.
     */
    function toHexString(uint256 num, uint256 length) private pure returns (bytes memory) {
        bytes memory bstr = new bytes(length);
        
        for(uint k = length ; k > 0 ; --k )
        {
            uint curr = (num & 15); //mask to one byte
            bstr[k-1] = curr > 9 ? bytes1(uint8(55 + curr)) : bytes1(uint8(48 + curr)); 
            num = num >> 4;
        }
        return bstr;
    }

}