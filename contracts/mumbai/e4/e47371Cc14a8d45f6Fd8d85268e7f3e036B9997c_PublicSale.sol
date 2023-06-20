// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBlacklist {
    function addToBlacklist(address user) external;
    function removeFromBlacklist(address user) external;
    function check(address user) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "./IERC20.sol";
import { IBlacklist } from "./interfaces/IBlacklist.sol";


contract PublicSale is Ownable, Pausable {

    struct Allocation {
        address owner;
        uint256 usdtAmount;
        uint256 boughtTokens;
        uint256 partialUnlockAmount;
        uint256 claimedTokens;
        uint256 lastClaimId;
        bool claimedFirst;
    }

    enum SaleStage {
        Paused,
        NotStarted,
        InProggress,
        Ended
    }

    IERC20 public token;
    IERC20 public USDT;
    IBlacklist public blacklist;
    
    uint256 public startTs;
    uint256 public endTs;
    uint256 public amountToken;
    uint256 public tokenSold;
    uint256 private totalDeposited;

    uint256 public tokenPrice = 2; 
    uint256 public tokenPriceDecimals = 100; // 1 token = 0.02

    uint256 public maxPerUser;
    uint256 public unlockPeriodTime = 30 days;
    uint256 public firstUnlockPercent = 20;
    uint256 public vestingPeriodMonth = 12;

    mapping(address => Allocation) public allocations;

    event SetSale(uint256 start, uint256 end, uint256 amountTokens);
    event BuyTokens(address user, uint256 usdtAmount, uint256 tokenAmount);
    event ClaimTokens(address user, uint256 tokenAmount);
    event SetTokenPrice (uint256 tokenPrice, uint256 tokenPriceDecimals);
    event SetVesting(uint256 maxPerUser, uint256 unlockPeriodTime, uint256 firstUnlockPercent, uint256 vestingPeriodMonth);
    event SetTokens(IERC20 token, IERC20 USDT);
    event Sweep(IERC20 token, address recepient);

    constructor(
        IERC20 token_,
        IERC20 USDT_,
        IBlacklist blacklist_,
        uint256 maxPerUser_
    ) {
        token = token_;
        USDT = USDT_;
        blacklist = blacklist_;
        maxPerUser = maxPerUser_;
        _transferOwnership(msg.sender);
    }

    modifier isNotBlackListed {
        require(!blacklist.check(msg.sender), "You're on the blacklist");
        _;
    }

    function setSale(uint256 start, uint256 end, uint256 amount) external onlyOwner {
        token.transferFrom(msg.sender, address(this), amount);
        startTs = start;
        endTs = end;
        amountToken = amount;

        emit SetSale(start, end, amountToken);
    }

    function getStage() public view returns (SaleStage) {
        if(paused()) {
            return SaleStage.Paused;
        }
        if(block.timestamp < startTs) {
            return SaleStage.NotStarted;
        }
        if(block.timestamp >= endTs) {
            return SaleStage.Ended;
        }
        return SaleStage.InProggress;
    }

    function buyTokensFor(uint256 amount) external isNotBlackListed {
        require(getStage() == SaleStage.InProggress, "Sale is closed");
        uint256 tokensToPurchase = amount * (10 ** (token.decimals() - USDT.decimals())) * tokenPriceDecimals / tokenPrice;
        require(allocations[msg.sender].boughtTokens + tokensToPurchase <= maxPerUser, "Increased maximum per user in sale");
        require(tokenSold + tokensToPurchase <= amountToken, "Increased maximum tokens per sale");

        USDT.transferFrom(msg.sender, address(this), amount);
        if (allocations[msg.sender].owner == address(0)) allocations[msg.sender].owner = msg.sender;
        allocations[msg.sender].boughtTokens += tokensToPurchase;
        allocations[msg.sender].usdtAmount += amount;
        allocations[msg.sender].partialUnlockAmount = (allocations[msg.sender].boughtTokens * (100 - firstUnlockPercent)) / (vestingPeriodMonth * 100); 
        tokenSold += tokensToPurchase;

        emit BuyTokens(msg.sender, amount, tokensToPurchase);
    }

    function getCurrentEraId() public view returns (uint256) {
        if (endTs >= block.timestamp) {
            return 0;
        }
        return (block.timestamp - endTs) / unlockPeriodTime > vestingPeriodMonth ? 
            vestingPeriodMonth : 
            (block.timestamp - endTs) / unlockPeriodTime;
    }

    function calculateAvailableEras(address user) internal view returns(uint256) {
        if(allocations[user].lastClaimId == getCurrentEraId()) {
            return 0;
        }
        return getCurrentEraId() - allocations[user].lastClaimId;
    }

    function claim() external isNotBlackListed {
        require(getStage() == SaleStage.Ended, "Sale is not ended");
        Allocation storage allocation = allocations[msg.sender];
        bool isClaimded;
        if(!allocation.claimedFirst) {
            allocation.claimedFirst = true;
            uint256 firstClaimAmount =  allocation.boughtTokens * firstUnlockPercent / 100;
            allocation.claimedTokens += firstClaimAmount;
            isClaimded = true;
            require(firstClaimAmount > 0, "You are not a token buyer");
            token.transfer(msg.sender, firstClaimAmount);

            emit ClaimTokens(msg.sender, firstClaimAmount);
        }

        uint256 claimablePeriods = calculateAvailableEras(msg.sender);
        if (claimablePeriods > 0) {
            uint256 amountToClaim;
            for (uint256 i = 0; i < claimablePeriods;) {
                amountToClaim += allocation.partialUnlockAmount;
            unchecked { i++; }    
            }
            allocation.claimedTokens += amountToClaim;
            allocation.lastClaimId += claimablePeriods;
            isClaimded = true;
            token.transfer(msg.sender, amountToClaim);

            emit ClaimTokens(msg.sender, amountToClaim);
        }    
        require(isClaimded, "You need to wait until next unlock");
    }

    function setTokenPrice (uint256 tokenPrice_, uint256 tokenPriceDecimals_) external onlyOwner {
        tokenPrice = tokenPrice_;
        tokenPriceDecimals = tokenPriceDecimals_;

        emit SetTokenPrice(tokenPrice_, tokenPriceDecimals_);
    }

    function setVestingSettings(uint256 maxPerUser_, uint256 unlockPeriodTime_, uint256 firstUnlockPercent_, uint256 vestingPeriodMonth_) external onlyOwner {
        maxPerUser = maxPerUser_;
        unlockPeriodTime = unlockPeriodTime_;
        firstUnlockPercent = firstUnlockPercent_;
        vestingPeriodMonth = vestingPeriodMonth_;

        emit SetVesting(maxPerUser_, unlockPeriodTime_, firstUnlockPercent_, vestingPeriodMonth_);
    }

    function setTokenSettings(IERC20 token_, IERC20 USDT_) external onlyOwner {
        token = token_;
        USDT = USDT_;

        emit SetTokens(token_, USDT_);
    }

    function getTotalDeposited() public view returns (uint256) {
        return totalDeposited;
    } 

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function sweep(IERC20 tokenAddress, address recipient) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        tokenAddress.transfer(recipient, amount);

        emit Sweep(tokenAddress, recipient);
    }
}