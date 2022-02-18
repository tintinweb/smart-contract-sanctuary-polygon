// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILevelPrice.sol";

contract LevelPrice is ILevelPrice, Ownable {
    struct LevelRange {
        uint256 price;
        uint256 lower;
        uint256 upper;
    }

    struct IdLevelRange {
        uint256 level;
        uint256 price;
    }

    mapping(uint256 => IdLevelRange) private idLevelandRanges;
    mapping(uint256 => LevelRange) public levels;
    uint256[] levelKeys;

    function setLevelPriceById(
        uint256 _tokenId,
        uint256 _level,
        uint256 _price
    ) external onlyOwner {
        require(_price > 0, "LevelPrice: Price is zero");
        require(_level > 0, "LevelPrice: Level is zero");
        idLevelandRanges[_tokenId] = IdLevelRange({
            level: _level,
            price: _price
        });
    }

    function setupLevels(
        uint256[] memory _levels,
        uint256[] memory _prices,
        uint256[] memory _lowers,
        uint256[] memory _uppers
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
            levels[_levels[i]] = LevelRange(_prices[i], _lowers[i], _uppers[i]);
            levelKeys.push(_levels[i]);
        }
        return true;
    }

    function getLevelPriceById(uint256 _tokenId)
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
                return [levelKeys[i], info.price];
            }
        }
        revert("Not found");
    }

    function getLevelById(uint256 _tokenId)
        external
        view
        override
        returns (uint256)
    {
        return getLevelPriceById(_tokenId)[0];
    }

    function getPriceById(uint256 _tokenId)
        external
        view
        override
        returns (uint256)
    {
        return getLevelPriceById(_tokenId)[1];
    }

    function getPriceByLevel(uint256 _level) public view returns (uint256) {
        return levels[_level].price;
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
pragma solidity ^0.8.4;

interface ILevelPrice {
    function getLevelPriceById(uint256 _tokenId)
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