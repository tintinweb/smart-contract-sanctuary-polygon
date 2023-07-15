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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: MIT OR Apache-2.0

/*
W: https://kingdomofants.io 

                ▒▒██            ██▒▒                
                    ██        ██                    
                    ██  ████  ██                    
                    ████▒▒▒▒████                    
████              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ████
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
  ██              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ██  
    ██            ██▒▒██▒▒▒▒██▒▒██            ██    
      ██          ▓▓▒▒▒▒████▒▒▒▒██          ██      
        ██          ████████████          ██        
          ██          ██▒▒▒▒██          ██          
            ██████████▒▒▒▒▒▒▒▒██████████            
                    ██▒▒▒▒▒▒▒▒██                    
          ████████████▒▒▒▒▒▒▒▒████████████          
        ██          ██▒▒▒▒▒▒▒▒██          ██        
      ██            ██▒▒▒▒▒▒▒▒██            ██      
    ██            ████▒▒▒▒▒▒▒▒████            ██    
  ██            ██    ████████    ██            ██  
██▒▒██        ██    ██▒▒▒▒▒▒▒▒██    ██        ██▒▒██
██▒▒██      ██      ██▒▒▒▒▒▒▒▒██      ██      ██▒▒██
████      ██        ██▒▒▒▒▒▒▒▒██        ██      ████
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██            ██▒▒▒▒██            ██        
      ████            ██▒▒▒▒██            ████      
    ██▒▒██              ████              ██▒▒██    
    ██████                                ██████    

* Howdy folks! Thanks for glancing over our contracts
* Y'all have a nice day! Enjoy the game
*/

pragma solidity ^0.8.13;

interface IANTLottery {
    /**
     * @notice Buy tickets for the current lottery
     * @dev Callable by minter
     * @param _recipient: recipient address 
     * @param _quantity: array of ticket numbers between 1,000,000 and 1,999,999
     */
    function buyTickets(address _recipient, uint256 _quantity) external;

    // /**
    //  * @notice Claim a set of winning tickets for a lottery
    //  * @param _lotteryId: lottery id
    //  * @param _ticketIds: array of ticket ids
    //  * @param _brackets: array of brackets for the ticket ids
    //  * @dev Callable by users only, not contract!
    //  */
    // function claimTickets(
    //     uint256 _lotteryId,
    //     uint256[] calldata _ticketIds,
    //     uint256[] calldata _brackets
    // ) external;

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function closeLottery(uint256 _lotteryId) external;

    /**
     * @notice Draw the final number, calculate reward in CAKE per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(uint256 _lotteryId) external;

    /**
     * @notice Inject funds
     * @param _lotteryId: lottery id
     * @param _amount: amount to inject in CAKE token
     * @dev Callable by operator
     */
    function injectFunds(uint256 _lotteryId, uint256 _amount) external;

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     * @param _endTime: endTime of the lottery
     * @param _rewardsBreakdown: breakdown of rewards per bracket (must sum to 10,000)
     */
    function startLottery(
        uint256 _endTime,
        uint256[6] calldata _rewardsBreakdown
    ) external;

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external returns (uint256);

    /**
     * @notice View user ticket ids, numbers, and statuses of user for a given lottery
     * @param _user: user address
     * @param _lotteryId: lottery id
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param _size: the number of tickets to retrieve
     */
    function viewUserInfoForLotteryId(address _user, uint256 _lotteryId, uint256 _cursor, uint256 _size) external view returns (uint256[] memory, uint256[] memory, bool[] memory, uint256);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

/*
W: https://kingdomofants.io 

                ▒▒██            ██▒▒                
                    ██        ██                    
                    ██  ████  ██                    
                    ████▒▒▒▒████                    
████              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ████
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
  ██              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ██  
    ██            ██▒▒██▒▒▒▒██▒▒██            ██    
      ██          ▓▓▒▒▒▒████▒▒▒▒██          ██      
        ██          ████████████          ██        
          ██          ██▒▒▒▒██          ██          
            ██████████▒▒▒▒▒▒▒▒██████████            
                    ██▒▒▒▒▒▒▒▒██                    
          ████████████▒▒▒▒▒▒▒▒████████████          
        ██          ██▒▒▒▒▒▒▒▒██          ██        
      ██            ██▒▒▒▒▒▒▒▒██            ██      
    ██            ████▒▒▒▒▒▒▒▒████            ██    
  ██            ██    ████████    ██            ██  
██▒▒██        ██    ██▒▒▒▒▒▒▒▒██    ██        ██▒▒██
██▒▒██      ██      ██▒▒▒▒▒▒▒▒██      ██      ██▒▒██
████      ██        ██▒▒▒▒▒▒▒▒██        ██      ████
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██            ██▒▒▒▒██            ██        
      ████            ██▒▒▒▒██            ████      
    ██▒▒██              ████              ██▒▒██    
    ██████                                ██████    

* Howdy folks! Thanks for glancing over our contracts
* Y'all have a nice day! Enjoy the game
*/

pragma solidity ^0.8.13;

interface IANTShop {

    struct TypeInfo {
        uint256 mints; // mint amount
        uint256 burns; // burn amount
        bool isSet; // token info setting status
        string baseURI; // token uri for typeId
        string name; // token name
    }

    function balanceOf(address account, uint256 id) external view returns(uint256);
    function getInfoForType(uint256 typeId) external view returns (TypeInfo memory);
    function mint(uint256 typeId, uint256 quantity, address recipient) external;
    function burn(uint256 typeId, uint256 quantity, address burnFrom) external;
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

/*
W: https://kingdomofants.io 

                ▒▒██            ██▒▒                
                    ██        ██                    
                    ██  ████  ██                    
                    ████▒▒▒▒████                    
████              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ████
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
  ██              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ██  
    ██            ██▒▒██▒▒▒▒██▒▒██            ██    
      ██          ▓▓▒▒▒▒████▒▒▒▒██          ██      
        ██          ████████████          ██        
          ██          ██▒▒▒▒██          ██          
            ██████████▒▒▒▒▒▒▒▒██████████            
                    ██▒▒▒▒▒▒▒▒██                    
          ████████████▒▒▒▒▒▒▒▒████████████          
        ██          ██▒▒▒▒▒▒▒▒██          ██        
      ██            ██▒▒▒▒▒▒▒▒██            ██      
    ██            ████▒▒▒▒▒▒▒▒████            ██    
  ██            ██    ████████    ██            ██  
██▒▒██        ██    ██▒▒▒▒▒▒▒▒██    ██        ██▒▒██
██▒▒██      ██      ██▒▒▒▒▒▒▒▒██      ██      ██▒▒██
████      ██        ██▒▒▒▒▒▒▒▒██        ██      ████
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██            ██▒▒▒▒██            ██        
      ████            ██▒▒▒▒██            ████      
    ██▒▒██              ████              ██▒▒██    
    ██████                                ██████    

* Howdy folks! Thanks for glancing over our contracts
* Y'all have a nice day! Enjoy the game
*/

pragma solidity ^0.8.13;

interface IPurse {
    struct PurseCategory {
        string categoryName; // category name like 'Common', 'UnCommon', 'Rare', ...
        uint256 rarity; // rarity percentage
        uint256 minted; // total minted tokens
        uint256 antFoodRarity; // antFood reward rarity percentage
        uint256 levelingPotionRarity; // leveling potions reward rarity percentage
        uint256 lotteryTicketRarity; // lottery tickets reward rarity percentage
        uint256 antFoodRewardAmount; // antFood reward amounts
        uint256 levelingPotionRewardAmount; // leveling potion reward amounts
        uint256 lotteryTicketRewardAmount; // lottery ticekt reward amounts
    }

    struct PurseTokenRewardInfo {
      address owner; // token owner
      uint256 tokenId; // token id
      uint256 purseCategoryId; // id number of purse category
      string rewardType; // earned reward type when use a purse token. e.g. ANTFood, LevelingPotion, LotteryTicket
      uint256 quantity; // earned reward amount
      bool isUsed; // purse token is used or not
    }

    function mint(address receipient, uint256 quantity) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

/*
W: https://kingdomofants.io 

                ▒▒██            ██▒▒                
                    ██        ██                    
                    ██  ████  ██                    
                    ████▒▒▒▒████                    
████              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ████
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
  ██              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ██  
    ██            ██▒▒██▒▒▒▒██▒▒██            ██    
      ██          ▓▓▒▒▒▒████▒▒▒▒██          ██      
        ██          ████████████          ██        
          ██          ██▒▒▒▒██          ██          
            ██████████▒▒▒▒▒▒▒▒██████████            
                    ██▒▒▒▒▒▒▒▒██                    
          ████████████▒▒▒▒▒▒▒▒████████████          
        ██          ██▒▒▒▒▒▒▒▒██          ██        
      ██            ██▒▒▒▒▒▒▒▒██            ██      
    ██            ████▒▒▒▒▒▒▒▒████            ██    
  ██            ██    ████████    ██            ██  
██▒▒██        ██    ██▒▒▒▒▒▒▒▒██    ██        ██▒▒██
██▒▒██      ██      ██▒▒▒▒▒▒▒▒██      ██      ██▒▒██
████      ██        ██▒▒▒▒▒▒▒▒██        ██      ████
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██            ██▒▒▒▒██            ██        
      ████            ██▒▒▒▒██            ████      
    ██▒▒██              ████              ██▒▒██    
    ██████                                ██████    

* Howdy folks! Thanks for glancing over our contracts
* Y'all have a nice day! Enjoy the game
*/

pragma solidity ^0.8.13;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IANTShop.sol';
import './interfaces/IPurse.sol';
import './interfaces/IANTLottery.sol';

contract Marketplace is Pausable, Ownable, ReentrancyGuard {

    // info for minting each antshop items
    struct MintInfo {
        bool mintMethod;
        bool isSet;
        uint256 mintPrice;
        uint256 tokenAmountForMint;
        address tokenAddressForMint;
    }
    // reference to the ANTShop
    IANTShop public ANTShop;
    // reference to the Purse
    IPurse public Purse;
    // reference to the ANTLottery
    IANTLottery public ANTLottery;

    // purse token mint method true => matic mint, false => custom token mint like usdt
    bool public purseMintMethod;
    // matic price for purse minting
    uint256 public purseMintPrice;
    // token address for purse minting
    address public purseMintTokenAddress;
    // token amount for purse minting
    uint256 public purseMintTokenAmount;
    // lotteryTicket mint method true => matic mint, false => custom token mint like usdt
    bool public lotteryTicketMintMethod;
    // matic price for lotteryTicket minting
    uint256 public lotteryTicketMintPrice;
    // token address for lotteryTicket minting
    address public lotteryTicketMintTokenAddress;
    // token amount for lotteryTicket minting
    uint256 public lotteryTicketMintTokenAmount;
    // max number for buying the lottery tickets
    uint256 public maxNumberTicketsPerBuy = 9999;

    mapping(address => bool) private minters;
    // ANTShop tokens mint information
    mapping(uint256 => MintInfo) public mintInfo;

    modifier onlyMinterOrOwner() {
        require(minters[_msgSender()] || _msgSender() == owner(), "Marketplace: Caller is not the owner or minter");
        _;
    }
    
    // buy ANTShop tokens event
    event BuyANTShopToken(uint256 typeId, address recipient, uint256 quantity);
    // buy Purse tokens event
    event BuyPurseToken(address recipient, uint256 quantity);
    // buy Lottery Tickets event
    event BuyLotteryTickets(address recipient, uint256 quantity);
    
    constructor(IANTShop _antShop, IPurse _purse, IANTLottery _antLottery) {
        ANTShop = _antShop;
        Purse = _purse;
        ANTLottery = _antLottery;
    }

    /**
    * ██ ███    ██ ████████
    * ██ ████   ██    ██
    * ██ ██ ██  ██    ██
    * ██ ██  ██ ██    ██
    * ██ ██   ████    ██
    * This section has internal only functions
    */

    /**
    * @notice Transfer ETH and return the success status.
    * @dev This function only forwards 30,000 gas to the callee.
    * @param to Address for ETH to be send to
    * @param value Amount of ETH to send
    */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    /**
    * ███████ ██   ██ ████████
    * ██       ██ ██     ██
    * █████     ███      ██
    * ██       ██ ██     ██
    * ███████ ██   ██    ██
    * This section has external functions
    */

    /**
    * @notice Sell ANTShop Tokens
    * @param _typeId type id for mint info 0 => ANTFood, 1 => Leveling Potion
    * @param _quantity ANTShop mint tokens number
    * @param _recipient buy token recipient wallet address
    */

    function buyTokens(uint256 _typeId, uint256 _quantity, address _recipient) external payable whenNotPaused nonReentrant {
        IANTShop.TypeInfo memory typeInfo = ANTShop.getInfoForType(_typeId);
        MintInfo memory _mintInfo = mintInfo[_typeId];
        require(typeInfo.isSet, "Marketplace: type info not set in ANTShop");
        require(_mintInfo.isSet, "Marketplace: mint info not set");
        if(_mintInfo.mintMethod){
            require(msg.value >= _mintInfo.mintPrice * _quantity, "Marketplace: Insufficient Matic");
        }
        else {
            require(_mintInfo.tokenAddressForMint != address(0x0), "Marketplace: token address can't be null");
            require(IERC20(_mintInfo.tokenAddressForMint).balanceOf(_msgSender()) >= _mintInfo.tokenAmountForMint * _quantity, "Marketplace: Insufficient Tokens");
            require(IERC20(_mintInfo.tokenAddressForMint).allowance(_msgSender(), address(this)) >= _mintInfo.tokenAmountForMint * _quantity, "Marketplace: You should approve tokens for minting");
            IERC20(_mintInfo.tokenAddressForMint).transferFrom(_msgSender(), address(this), _mintInfo.tokenAmountForMint * _quantity);
        }
        ANTShop.mint(_typeId, _quantity, _recipient);
        emit BuyANTShopToken(_typeId, _recipient, _quantity);
    }

    /**
    * @notice Sell Purse Tokens
    * @param _recipient buy token recipient wallet address
    * @param _quantity mint tokens number to see purse tokens
    */

    function buyPurseTokens(address _recipient, uint256 _quantity) external payable whenNotPaused nonReentrant {
        if(purseMintMethod){
            require(msg.value >= purseMintPrice * _quantity, "Marketplace: Insufficient Matic");
        }
        else {
            require(purseMintTokenAddress != address(0x0), "Marketplace: token address can't be null");
            require(IERC20(purseMintTokenAddress).balanceOf(_msgSender()) >= purseMintTokenAmount * _quantity, "Marketplace: Insufficient Tokens");
            require(IERC20(purseMintTokenAddress).allowance(_msgSender(), address(this)) >= purseMintTokenAmount * _quantity, "Marketplace: You should approve tokens for minting");
            IERC20(purseMintTokenAddress).transferFrom(_msgSender(), address(this), purseMintTokenAmount * _quantity);
        }
        Purse.mint(_recipient, _quantity);
        emit BuyPurseToken(_recipient, _quantity);
    }

    /**
    * @notice Sell Lottery Tickets
    * @param _recipient buy tickets recipient wallet address
    * @param _quantity mint tokens number to see lottery tickets
    */

    function buyLotteryTickets(address _recipient, uint256 _quantity) external payable whenNotPaused nonReentrant {
        if(lotteryTicketMintMethod){
            require(msg.value >= lotteryTicketMintPrice * _quantity, "Marketplace: Insufficient Matic");
        }
        else {
            require(lotteryTicketMintTokenAddress != address(0x0), "Marketplace: token address can't be null");
            require(IERC20(lotteryTicketMintTokenAddress).balanceOf(_msgSender()) >= lotteryTicketMintTokenAmount * _quantity, "Marketplace: Insufficient Tokens");
            require(IERC20(lotteryTicketMintTokenAddress).allowance(_msgSender(), address(this)) >= lotteryTicketMintTokenAmount * _quantity, "Marketplace: You should approve tokens for minting");
            IERC20(lotteryTicketMintTokenAddress).transferFrom(_msgSender(), address(this), lotteryTicketMintTokenAmount * _quantity);
        }
        ANTLottery.buyTickets(_recipient, _quantity);
        emit BuyLotteryTickets(_recipient, _quantity);
    }

    /**
    * @notice Return Mint information(mint price, token address and amount for mint)
    * @param _typeId type id for mint info 0 => ANTFood, 1 => Leveling Potion
    */

    function getMintInfo(uint256 _typeId) external view returns(MintInfo memory) {
        require(mintInfo[_typeId].isSet, "Marketplace: Mint information not set yet");
        return mintInfo[_typeId];
    }

    /**
    * @notice Check address has minterRole
    */

    function getMinterRole(address _address) public view returns(bool) {
        return minters[_address];
    }

    /**
    *   ██████  ██     ██ ███    ██ ███████ ██████
    *  ██    ██ ██     ██ ████   ██ ██      ██   ██
    *  ██    ██ ██  █  ██ ██ ██  ██ █████   ██████
    *  ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██
    *   ██████   ███ ███  ██   ████ ███████ ██   ██
    * This section will have all the internals set to onlyOwner
    */

    /**
    * @notice Set mint information like mint price, token address and amount for minting
    * @dev This function can only be called by the owner
    * @param _typeId type id for mint info 0 => ANTFood, 1 => Leveling Potion
    * @param _mintPrice matic for minting
    * @param _tokenAddressForMint token addres for minting
    * @param _tokenAmountForMint token token amount for minting
    */

    function setMintInfo(uint256 _typeId, uint256 _mintPrice, address _tokenAddressForMint, uint256 _tokenAmountForMint) external onlyMinterOrOwner {
        require(_tokenAddressForMint != address(0x0), "Marketplace: token address can't be a null address");
        mintInfo[_typeId].mintPrice = _mintPrice;
        mintInfo[_typeId].tokenAddressForMint = _tokenAddressForMint;
        mintInfo[_typeId].tokenAmountForMint = _tokenAmountForMint;
        mintInfo[_typeId].isSet = true;
        mintInfo[_typeId].mintMethod = true;
    }

    /**
    * @notice Set mint method true => Matic mint, false => custom token mint
    * @dev This function can only be called by the owner
    * @param _typeId type id for mint info 0 => ANTFood, 1 => Leveling Potion
    * @param _mintMethod mint method value
    */

    function setMintMethod(uint256 _typeId, bool _mintMethod) external onlyMinterOrOwner {
        mintInfo[_typeId].mintMethod = _mintMethod;
    }

    /**
    * @notice Set Purse token mint info
    * @dev This function can only be called by the owner
    * @param _mintMethod mint method value true => matic mint, false => custom token mint like usdt
    * @param _maticPrice  matic mint price
    * @param _tokenAddress token address for minting
    * @param _tokenAmount token amount for minting
    */

    function setPurseMintInfo(bool _mintMethod, uint256 _maticPrice, address _tokenAddress, uint256 _tokenAmount) external onlyMinterOrOwner {
        require(_tokenAddress != address(0), "Marketplace: Purse token address can't be zero address");
        purseMintMethod = _mintMethod;
        purseMintPrice = _maticPrice;
        purseMintTokenAddress = _tokenAddress;
        purseMintTokenAmount = _tokenAmount;
    }

    /**
    * @notice Set Lottery Ticket mint info
    * @dev This function can only be called by the owner
    * @param _mintMethod mint method value true => matic mint, false => custom token mint like usdt
    * @param _maticPrice  matic mint price
    * @param _tokenAddress token address for minting
    * @param _tokenAmount token amount for minting
    */

    function setLotteryTicketMintInfo(bool _mintMethod, uint256 _maticPrice, address _tokenAddress, uint256 _tokenAmount) external onlyMinterOrOwner {
        require(_tokenAddress != address(0), "Marketplace: Lottery token address can't be zero address");
        lotteryTicketMintMethod = _mintMethod;
        lotteryTicketMintPrice = _maticPrice;
        lotteryTicketMintTokenAddress = _tokenAddress;
        lotteryTicketMintTokenAmount = _tokenAmount;
    }

    /**
    * @notice Set a new max number tickets per buy
    * @dev This function can only be called by the owner
    * @param _maxNumberTicketsPerBuy a max ticket numbers for buy
    */

    function setMaxNumberTicketsPerBuy(uint256 _maxNumberTicketsPerBuy) external onlyMinterOrOwner {
        maxNumberTicketsPerBuy = _maxNumberTicketsPerBuy;
    }

    /**
    * @notice Set a new Purse smart contract address
    * @dev This function can only be called by the owner
    * @param _purse Reference to Purse
    */

    function setPurseContract(IPurse _purse) external onlyMinterOrOwner {
        require(address(_purse) != address(0x0), "Marketplace: Purse address can't be null address");
        Purse = _purse;
    }

    /**
    * @notice Set a new ANTShop smart contract address
    * @dev This function can only be called by the owner
    * @param _antShop Reference to ANTShop
    */

    function setANTShopContract(IANTShop _antShop) external onlyMinterOrOwner {
        require(address(_antShop) != address(0x0), "Marketplace: ANTShop address can't be null address");
        ANTShop = _antShop;
    }

    /**
    * @notice Set a new ANTLottery smart contract address
    * @dev This function can only be called by the owner
    * @param _antLottery Reference to ANTLottery
    */

    function setANTLotteryContract(IANTLottery _antLottery) external onlyMinterOrOwner {
        require(address(_antLottery) != address(0x0), "Marketplace: ANTLottery address can't be null address");
        ANTLottery = _antLottery;
    }

    /**
    * enables owner to pause / unpause contract
    */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
    * @notice Function to grant mint role
    * @dev This function can only be called by the owner
    * @param _address address to get minter role
    */
    function addMinterRole(address _address) external onlyOwner {
        minters[_address] = true;
    }

    /**
    * @notice Function to revoke mint role
    * @dev This function can only be called by the owner
    * @param _address address to revoke minter role
    */
    function revokeMinterRole(address _address) external onlyOwner {
        minters[_address] = false;
    }

    /**
    * @notice Allows owner to withdraw ETH funds to an address
    * @dev wraps _user in payable to fix address -> address payable
    * @param to Address for ETH to be send to
    * @param amount Amount of ETH to send
    */
    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(_safeTransferETH(to, amount));
    }

    /**
    * @notice Allows ownder to withdraw any accident tokens transferred to contract
    * @param _tokenContract Address for the token
    * @param to Address for token to be send to
    * @param amount Amount of token to send
    */
    function withdrawToken(
        address _tokenContract,
        address to,
        uint256 amount
    ) public onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(to, amount);
    }
}