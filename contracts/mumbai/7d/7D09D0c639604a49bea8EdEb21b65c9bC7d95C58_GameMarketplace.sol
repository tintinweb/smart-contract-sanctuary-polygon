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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
//import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract GameMarketplace is Ownable {
    using Counters for Counters.Counter;

    struct Item {
        uint256 id;
        address owner;
        string name;
        uint256 poolId;
        uint256 categoryId;
        address rentedBy;
    }


    Counters.Counter private _itemIds;
    Counters.Counter private _categoryIds;

    mapping(uint256 => string) private _categories;
    event CategoryCreated(uint256 categoryId, string category);

    mapping(uint256 => Item) private _items;
    bytes32 internal keyHash;
    uint256 internal fee;

//    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyHash, uint256 _fee)
//    ERC721("GameMarketplace", "GMKT")
//    VRFConsumerBase(_VRFCoordinator, _LinkToken)
//    {
//        keyHash = _keyHash;
//        fee = _fee;
//    }


    /**
     * @dev Create a new category.
     * @param _categoryName The name of the category
     */
    function createCategory(string memory _categoryName) public onlyOwner {
        _categoryIds.increment();

        uint256 newCategoryId = _categoryIds.current();
        _categories[newCategoryId] = _categoryName;

        emit CategoryCreated(newCategoryId, _categoryName);
    }

    /**
     * @dev Add item to a category pool.
     * @param _categoryId The ID of the category
     * @param _price The rent price of the item
     */
//    function addItemToPool(uint256 _categoryId, uint256 _price) public virtual {
//        // Implement function to add an item to a category pool
//    }
//
//    /**
//     * @dev Rent an item from a category pool.
//     * @param _categoryId The ID of the category
//     */
//    function rentItemFromPool(uint256 _categoryId) public payable virtual {
//        // Implement function to rent an item from a category pool
//    }
//
//    /**
//     * @dev End the rental period for an item.
//     * @param _itemId The ID of the item
//     */
//    function endRental(uint256 _itemId) public virtual {
//        // Implement function to end the rental period for an item
//    }
//
//    /**
//     * @dev Withdraw rental fees for an item.
//     * @param _itemId The ID of the item
//     */
//    function withdrawRentFees(uint256 _itemId) public virtual {
//        // Implement function to withdraw rental fees for an item
//    }
//
//    /**
//     * @dev Request randomness for item selection in a category pool.
//     * @param _categoryId The ID of the category
//     */
//    function requestRandomItem(uint256 _categoryId) internal virtual {
//        // Implement function to request randomness for item selection in a category pool
//    }
//
//    /**
//     * @dev Fulfill randomness for item selection in a category pool.
//     * @param _randomness The random number returned by the Chainlink VRF
//     */
//    function fulfillRandomness(uint256 _randomness) internal override {
//        // Implement function to fulfill randomness for item selection in a category pool
//    }
//
//    function setRentalFee(string memory _category) public {
//        // A Chainlink Functions URL seria algo como:
////        // https://usechainlinkfunctions.com/{your-chainlink-function-id}
////        // Substitua {your-chainlink-function-id} pelo ID da sua função Chainlink.
////        string memory chainlinkFunctionURL = "https://usechainlinkfunctions.com/{your-chainlink-function-id}";
////
////        // Crie a URL da função Lambda, adicionando a categoria à URL base.
////        string memory lambdaFunctionURL = string(abi.encodePacked(chainlinkFunctionURL, "?category=", _category));
////
////        // Use Chainlink Functions para chamar a função Lambda.
////        (bool success, bytes memory returnData) = chainlinkFunctionURL.get(lambdaFunctionURL);
////
////        require(success, "Failed to get the rental fee from the Lambda function.");
////
////        // Transformar os dados retornados em uint para usar como taxa de aluguel.
////        uint rentalFee = abi.decode(returnData, (uint));
////
////        // Armazenar a taxa de aluguel para a categoria.
////        rentalFees[_category] = rentalFee;
//    }

}