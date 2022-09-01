// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract JobRate is Ownable {

    struct StartAndEnd {
        uint32 startNum;
        uint32 endNum;
    }

    //SKILL1 = 00; // 0-250/1000 25%
    //SKILL2 = 01; // 251-500/1000 25%
    //SKILL3 = 02; // 501-750/1000 25%
    //SKILL4 = 03; 751-1000/1000 25%

    /// @dev declare mapping to store keys and rates.
    uint32[] rarityKeys;
    mapping(uint32 => uint32) rarityRates;
    mapping(uint32 => StartAndEnd) rarityRange;


    /// @dev setup keys and rates.
    function setUpRarityRates(
        uint32[] memory keys,
        uint32[] memory rates
    ) public onlyOwner returns (uint32[] memory) {

        require(rates.length == keys.length, "Keys and Rates' Length must be equal.");
        delete rarityKeys;

        for (uint32 i = 0; i < keys.length; i++) {
            rarityKeys.push(keys[i]);
            rarityRates[keys[i]] = rates[i];
        }
        return rates;
    }

    /// @dev setup rarity rage for random rates
    function setUpRarityRang() public onlyOwner returns (uint32) {

         uint32 currentNumber;

        for (uint32 i = 0; i < rarityKeys.length; i++) {
            if (i == 0) {
                rarityRange[rarityKeys[i]].startNum = 0;
                rarityRange[rarityKeys[i]].endNum =
                    rarityRange[rarityKeys[i]].startNum +
                    rarityRates[rarityKeys[i]];
                currentNumber = rarityRange[rarityKeys[i]].endNum;
            } else {
                rarityRange[rarityKeys[i]].startNum = currentNumber + 1;
                rarityRange[rarityKeys[i]].endNum =
                    rarityRange[rarityKeys[i]].startNum +
                    (rarityRates[rarityKeys[i]] - 1);
                currentNumber = rarityRange[rarityKeys[i]].endNum;
            }
        }

        require(currentNumber == 1000, "Current number must be equal to 1000.");

        return currentNumber;
    }

    /// @dev get result.
    function getJobResult(uint32 _number) public view returns (uint32) {

        require(_number <= 1000, "_number must be less than 1000.");
        
        for (uint32 i = 0; i < rarityKeys.length; i++) {
            if (
                _number >= rarityRange[rarityKeys[i]].startNum &&
                _number <= rarityRange[rarityKeys[i]].endNum
            ) {
                return rarityKeys[i];
            }
        }

        return 0;
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