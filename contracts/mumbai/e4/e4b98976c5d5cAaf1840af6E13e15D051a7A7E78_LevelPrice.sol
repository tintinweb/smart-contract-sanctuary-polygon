// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/ILevelPrice.sol";

contract LevelPrice is ILevelPrice, Ownable {
    // using Counters for Counters.Counter;

    struct LevelRange {
        uint256 lower;
        uint256 upper;
    }

    struct IdLevelRange {
        uint256 level;
        uint256 price;
    }

    mapping(uint256 => IdLevelRange) public idLevelandRanges;
    mapping(uint256 => uint256) public levelPrices;
    mapping(uint256 => LevelRange) public levels;
    uint256[] levelKeys;

    function setLevelandPriceById(
        uint256 _tokenId,
        uint256 _level,
        uint256 _price
    ) public onlyOwner {
        require(_price > 0, "LevelPrice: Price is zero");
        require(_level > 0, "LevelPrice: Level is zero");
        idLevelandRanges[_tokenId] = IdLevelRange({
            level: _level,
            price: _price
        });
    }

    function setupLevels(
        uint256[] calldata _levels,
        uint256[] calldata _prices,
        uint256[] calldata _lowers,
        uint256[] calldata _uppers
    ) external onlyOwner returns (bool) {
        require(
            _levels.length > 0 &&
                _levels.length == _prices.length &&
                _prices.length == _lowers.length &&
                _lowers.length == _uppers.length,
            "LevelPrice: Invalid Input"
        );

        for (uint256 i = 0; i < _levels.length; i++) {
            require(_prices[i] > 0, "LevelPrice: price is zero");
            levels[_levels[i]] = LevelRange(_lowers[i], _uppers[i]);
            levelPrices[_levels[i]] = _prices[i];
            levelKeys[i] = _levels[i];
        }
        return true;
    }

    function getLevelandPriceById(uint256 _tokenId)
        public
        view
        override
        returns (uint256[2] memory)
    {
        if (idLevelandRanges[_tokenId].level > 0) {
            return [
                idLevelandRanges[_tokenId].level,
                idLevelandRanges[_tokenId].price
            ];
        }
        for (uint256 i = 0; i < levelKeys.length; i++) {
            LevelRange memory info = levels[levelKeys[i]];
            if (info.lower <= _tokenId && info.upper >= _tokenId) {
                return [levelKeys[i], levelPrices[levelKeys[i]]];
            }
        }
        revert("Not found");
    }

    function getLevelById(uint256 _tokenId)
        public
        view
        override
        returns (uint256)
    {
        if (idLevelandRanges[_tokenId].level > 0) {
            return idLevelandRanges[_tokenId].level;
        }
        for (uint256 i = 0; i < levelKeys.length; i++) {
            LevelRange memory info = levels[levelKeys[i]];
            if (info.lower <= _tokenId && info.upper >= _tokenId) {
                return levelKeys[i];
            }
        }
        revert("Not found");
    }

    function getPriceById(uint256 _tokenId)
        external
        view
        override
        returns (uint256)
    {
        if (idLevelandRanges[_tokenId].level > 0) {
            return idLevelandRanges[_tokenId].price;
        }
        for (uint256 i = 0; i < levelKeys.length; i++) {
            LevelRange memory range = levels[levelKeys[i]];
            if (range.lower <= _tokenId && range.upper >= _tokenId) {
                return levelPrices[levelKeys[i]];
            }
        }
        revert("Not found");
    }

    function getPriceByLevel(uint256 _level) public view returns (uint256) {
        return levelPrices[_level];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.4;

interface ILevelPrice {
    function getLevelandPriceById(uint256 _tokenId)
        external
        view
        returns (uint256[2] memory);

    function getPriceById(uint256 _tokenId) external view returns (uint256);

    function getLevelById(uint256 _tokenId) external view returns (uint256);
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