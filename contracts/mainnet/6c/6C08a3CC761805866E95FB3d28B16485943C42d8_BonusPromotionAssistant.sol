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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
pragma solidity ^0.8.1;

interface IAuctionBonus {
    function onBidMinting(address _user) external;

    function mint(address _user, uint256 _amount, bool _alsoBurn) external;

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../interfaces/IAuctionBonus.sol";

contract BonusPromotionAssistant is Ownable, ReentrancyGuard {
    event BonusTokenSet(address _bonus);

    event StaticPromoterSet(
        address _promoter,
        uint256 _giftCount,
        uint256 _giftSize,
        uint256 _expiry
    );
    event DynamicPromoterSet(
        address _promoter,
        uint256 _totalTokens,
        uint256 _expiry
    );

    event StaticGiftGiven(address _promoter, address _player, uint256 _amount);
    event DynamicGiftGiven(address _promoter, address _player, uint256 _amount);

    /// @notice local mapping of extra given by this contract
    //Pool => User => BidList => Extra
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public userExtraBids;

    /// @notice dictates the amount of given tokens per gift of a promoter
    mapping(address => uint256) public staticPromotionGiftSize;

    /// @notice dictates the expiry epoch of a promoter
    mapping(address => uint256) public staticPromotionExpiry;

    /// @notice dictates the amount of gifts of a promoter
    mapping(address => uint256) public staticPromotionGiftsCount;

    /// @notice dictates the amount of total amount of gift tokens of a dynamic promoter
    mapping(address => uint256) public dynamicPromotionTotalAmount;

    /// @notice dictates the expiry epoch of a dynamic promoter
    mapping(address => uint256) public dynamicPromotionExpiry;

    IAuctionBonus public bonus;

    constructor(IAuctionBonus _bonus) {
        bonus = _bonus;
        emit BonusTokenSet(address(_bonus));
    }

    /// @notice gift bonus token to a user
    //Reentrancy safe due staticPromotionGiftsCount reduction
    function giftBonus(address _user) external {
        unchecked {
            require(
                block.timestamp < staticPromotionExpiry[msg.sender],
                "Allowance expired"
            );
            require(staticPromotionGiftsCount[msg.sender] >= 1, "Out of gifts");
            staticPromotionGiftsCount[msg.sender] -= 1;
            uint256 _localAmount = staticPromotionGiftSize[msg.sender];
            bonus.mint(_user, _localAmount, true);
            emit StaticGiftGiven(msg.sender, _user, _localAmount);
        }
    }

    /// @notice gift bonus token to multiple users
    //Reentrancy safe due staticPromotionGiftsCount reduction
    function giftBonusBatch(address[] memory _users) external {
        unchecked {
            require(
                block.timestamp < staticPromotionExpiry[msg.sender],
                "Allowance expired"
            );
            require(
                staticPromotionGiftsCount[msg.sender] >= _users.length,
                "Not enough gifts"
            );
            staticPromotionGiftsCount[msg.sender] -= _users.length;
            uint256 _localAmount = staticPromotionGiftSize[msg.sender];
            for (uint256 i; i < _users.length; ++i) {
                bonus.mint(_users[i], _localAmount, true);
                emit StaticGiftGiven(msg.sender, _users[i], _localAmount);
            }
        }
    }

    /// @notice Give a bonus token amount to a user
    //Reentrancy safe due dynamicPromotionTotalAmount reduction
    function giftBonusDynamic(address _user, uint256 _amount) external {
        unchecked {
            require(
                block.timestamp < dynamicPromotionExpiry[msg.sender],
                "Allowance expired"
            );
            require(
                dynamicPromotionTotalAmount[msg.sender] >= _amount,
                "Not enough allowance"
            );
            dynamicPromotionTotalAmount[msg.sender] -= _amount;
            bonus.mint(_user, _amount, true);
            emit DynamicGiftGiven(msg.sender, _user, _amount);
        }
    }

    /// @notice Give a bonus token amount to multiple users
    function giftBonusBatchDynamic(
        address[] memory _users,
        uint256[] calldata _amounts
    ) external nonReentrant {
        unchecked {
            require(
                block.timestamp < dynamicPromotionExpiry[msg.sender],
                "Allowance expired"
            );
            uint256 _localTotal;
            for (uint256 i; i < _users.length; ++i) {
                _localTotal += _amounts[i];
                bonus.mint(_users[i], _amounts[i], true);
                emit DynamicGiftGiven(msg.sender, _users[i], _amounts[i]);
            }
            require(
                dynamicPromotionTotalAmount[msg.sender] >= _localTotal,
                "Not enough allowance"
            );
            dynamicPromotionTotalAmount[msg.sender] -= _localTotal;
        }
    }

    function setStaticPromoter(
        address _promoter,
        uint256 _expiry,
        uint256 _giftCount,
        uint256 _giftSize
    ) external onlyOwner {
        staticPromotionGiftSize[_promoter] = _giftSize;
        staticPromotionGiftsCount[_promoter] = _giftCount;
        staticPromotionExpiry[_promoter] = _expiry;
        emit StaticPromoterSet(_promoter, _giftCount, _giftSize, _expiry);
    }

    function setDynamicPromoter(
        address _promoter,
        uint256 _expiry,
        uint256 _totalAmount
    ) external onlyOwner {
        dynamicPromotionTotalAmount[_promoter] = _totalAmount;
        dynamicPromotionExpiry[_promoter] = _expiry;
        emit DynamicPromoterSet(_promoter, _expiry, _totalAmount);
    }

    function setBonus(IAuctionBonus _bonus) external onlyOwner {
        bonus = _bonus;
        emit BonusTokenSet(address(_bonus));
    }
}