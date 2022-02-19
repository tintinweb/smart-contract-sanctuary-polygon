// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILeveler.sol";

contract Leveler is ILeveler, Ownable {
    struct LevelRange {
        uint256 price;
        uint256 lower;
        uint256 upper;
    }

    event LevelPriceChange(uint256 id, uint256 oldprice, uint256 newprice);

    event IdPriceChange(uint256 id, uint256 oldprice, uint256 newprice);

    event Setup(
        uint256[] levels,
        uint256[] prices,
        uint256[] lowers,
        uint256[] uppers
    );

    mapping(uint256 => uint256) private idPrices;
    mapping(uint256 => LevelRange) public levels;
    uint256[] levelKeys;
    bool private isSetup;

    function setPriceById(uint256 _tokenId, uint256 _price) external onlyOwner {
        require(_price > 0, "LevelPrice: Price is zero");
        uint256 oldPrice = idPrices[_tokenId];
        idPrices[_tokenId] = _price;
        emit IdPriceChange(_tokenId, oldPrice, _price);
    }

    function setPriceByLevel(uint256 _levelId, uint256 _price)
        external
        onlyOwner
    {
        require(_price > 0, "LevelPrice: Price is zero");
        require(
            _levelId < levelKeys.length,
            "LevelPrice: LevelId out of range"
        );
        uint256 oldPrice = levels[_levelId].price;
        levels[_levelId].price = _price;
        emit LevelPriceChange(_levelId, oldPrice, _price);
    }

    function setupOnce(
        uint256[] memory _levels,
        uint256[] memory _prices,
        uint256[] memory _lowers,
        uint256[] memory _uppers
    ) external onlyOwner {
        require(!isSetup, "Leveler: Setup once only");
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
        emit Setup(_levels, _prices, _lowers, _uppers);
        isSetup = true;
    }

    function getLevelPriceById(uint256 _tokenId)
        external
        view
        override
        returns (uint256 level, uint256 price)
    {
        require(isSetup, "Leveler: Setup first");
        for (uint256 i = 0; i < levelKeys.length; i++) {
            LevelRange memory info = levels[levelKeys[i]];
            if (info.lower <= _tokenId && info.upper >= _tokenId) {
                if (idPrices[_tokenId] > 0) {
                    return (levelKeys[i], idPrices[_tokenId]);
                } else {
                    return (levelKeys[i], info.price);
                }
            }
        }
        return (0, 0);
    }

    function getPriceByLevel(uint256 _level) public view returns (uint256) {
        require(isSetup, "Leveler: Setup first");
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

interface ILeveler {
    function getLevelPriceById(uint256 _tokenId)
        external
        view
        returns (uint256, uint256);
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