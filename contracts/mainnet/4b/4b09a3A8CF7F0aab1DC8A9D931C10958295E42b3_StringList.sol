//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StringList is Ownable {
    /// Events
    event Add(address indexed _caller, string _value);
    event Remove(address indexed _caller,  string _value);

    string constant PLACE_HOLDER = "____INVALID_PLACE_HOLER";

    /// Errors
    string constant ERROR_VALUE_NOT_PART_OF_THE_LIST = "ERROR_VALUE_NOT_PART_OF_THE_LIST";
    string constant ERROR_VALUE_PART_OF_THE_LIST = "ERROR_VALUE_PART_OF_THE_LIST";
    string constant ERROR_INVALID_INDEX = "ERROR_INVALID_INDEX";
    string constant ERROR_INVALID_VALUE = "ERROR_INVALID_VALUE";

    /// State
    string public name;
    string[] public values;
    mapping(string => uint256) internal indexByValue;

    /**
     * @dev Initialize contract
     * @notice Create a new list with name `_name`
     * @param _name The list's display name
     */
    constructor(string memory _name) {
        name = _name;

        // Invalidate first position
        values.push(PLACE_HOLDER);
    }

    /**
     * @dev Add a value to the  list
     * @notice Add "`_value`" to the string` list.
     * @param _value String value to remove
     */
    function add(string calldata _value) external onlyOwner {
        // Check if the value is part of the list
        require(indexByValue[_value] == 0, ERROR_VALUE_PART_OF_THE_LIST);

        // Check if the value is not the placeholder
        require(keccak256(abi.encodePacked(_value)) != keccak256(abi.encodePacked(PLACE_HOLDER)), ERROR_INVALID_VALUE);

        _add(_value);
    }

    /**
     * @dev Remove a value from the list
     * @notice Remove "`_value`" from the `self.symbol(): string` list
     * @param _value String value to remove
     */
    function remove(string calldata _value) external onlyOwner {
        require(indexByValue[_value] > 0, ERROR_VALUE_NOT_PART_OF_THE_LIST);

        // Values length
        uint256 lastValueIndex = size();

        // Index of the value to remove in the array
        uint256 removedIndex = indexByValue[_value];

        // Last value id
        string memory lastValue = values[lastValueIndex];

        // Override index of the removed value with the last one
        values[removedIndex] = lastValue;
        indexByValue[lastValue] = removedIndex;

        emit Remove(msg.sender, _value);

        // Clean storage
        values.pop();
        delete indexByValue[_value];
    }

    /**
    * @dev Get list's size
    * @return list's size
    */
    function size() public view returns (uint256) {
        return values.length - 1;
    }

    /**
    * @dev Get list's item
    * @param _index of the item
    * @return item at index
    */
    function get(uint256 _index) public view returns (string memory) {
        require(_index < values.length - 1, ERROR_INVALID_INDEX);

        return values[_index + 1];
    }

    /**
    * @dev Add a value to the  list
    * @param _value String value to remove
    */
    function _add(string calldata _value) internal {
        // Store the value to be looped
        values.push(_value);

        // Save mapping of the value within its position in the array
        indexByValue[_value] = values.length - 1;

        emit Add(msg.sender, _value);
    }

}

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