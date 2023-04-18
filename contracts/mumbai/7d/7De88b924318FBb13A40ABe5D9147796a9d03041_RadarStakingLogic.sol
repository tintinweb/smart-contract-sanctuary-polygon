// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/iRadarStakingLogic.sol";
import "./interfaces/iRadarToken.sol";
import "./interfaces/iRadarStake.sol";

contract RadarStakingLogic is iRadarStakingLogic, Ownable, ReentrancyGuard {

    constructor(address rewarderAddr, address radarTokenContractAddr, address radarStakeContractAddr) {
        require(address(rewarderAddr) != address(0), "RadarStakingLogic: Rewarder address not set");
        require(address(radarTokenContractAddr) != address(0), "RadarStakingLogic: Token contract not set");
        require(address(radarStakeContractAddr) != address(0), "RadarStakingLogic: Staking contract not set");

        rewarderAddress = rewarderAddr;
        radarTokenContract = iRadarToken(radarTokenContractAddr);
        radarStakeContract = iRadarStake(radarStakeContractAddr);
    }

    /** EVENTS */
    event TokensStaked(address indexed owner, uint256 amount);
    event TokensHarvested(address indexed owner, uint256 amount, bool restake);
    event TokensUnstaked(address indexed owner, uint256 amount);
    event TokensUnstakingTriggered(address indexed owner);

    /** PUBLIC VARS */
    // interface of our ERC20 RADAR token
    iRadarToken public radarTokenContract;
    // interface of the staking contract (stateful)
    iRadarStake public radarStakeContract;
    // the address which holds the reward tokens, which get paid out to users when they harvest their rewards
    address public rewarderAddress;
    // minimum amount to stake (aka. subscription for the DappRadar PRO subscription)
    uint256 public stakeForDappRadarPro = 30_000 ether;

    /** PUBLIC */
    // this contract needs to have permission to move RADAR for the _msgSender() before this function can be called
    // allow amount == 0 so we can reset the staking timers without having to add tokens to the stake
    function stake(uint256 amount) external nonReentrant {
        iRadarStake.Stake memory myStake = radarStakeContract.getStake(_msgSender());
        require(myStake.totalStaked + amount >= stakeForDappRadarPro, "RadarStakingLogic: You cannot stake less than the minimum");

        // check if the user owns the amount of tokens he wants to stake
        require(radarTokenContract.balanceOf(_msgSender()) >= amount, "RadarStakingLogic: Not enough tokens to stake");
        // check if this contract is allowed to move users RADAR to the staking contract
        require(radarTokenContract.allowance(_msgSender(), address(this)) >= amount, "RadarStakingLogic: This contact is not allowed to move the amount of tokens you want to stake");

        // move tokens from the user to the staking contract
        radarTokenContract.transferFrom(_msgSender(), address(radarStakeContract), amount);
        
        // calculate rewards in case the user already has a stake and now added to it
        uint256 tokenReward = calculateReward(_msgSender());
        // move additional tokens to the staking contract so it can later pay out the already accrued and restaked rewards
        if (tokenReward > 0) {
            radarTokenContract.transferFrom(rewarderAddress, address(radarStakeContract), tokenReward);
            emit TokensHarvested(_msgSender(), tokenReward, true);
        }

        // add to stake, which updates totals and resets timestamps
        radarStakeContract.addToStake(amount + tokenReward, _msgSender());
        emit TokensStaked(_msgSender(), amount + tokenReward);
    }

    // there is no cooldown when harvesting token rewards.
    function harvest(bool restake) public nonReentrant {
        iRadarStake.Stake memory myStake = radarStakeContract.getStake(_msgSender());
        require(myStake.totalStaked > 0, "RadarStakingLogic: You don't have tokens staked");
        uint256 tokenReward = calculateReward(_msgSender());
        require(tokenReward > 0, "RadarStakingLogic: No reward to harvest");
        
        emit TokensHarvested(_msgSender(), tokenReward, restake);

        if (restake) {
            // move additional tokens to the staking contract so it can later pay out the already accrued and restaked rewards
            radarTokenContract.transferFrom(rewarderAddress, address(radarStakeContract), tokenReward);

            // stake again to reset the clock and add the reward to the existing stake
            radarStakeContract.addToStake(tokenReward, _msgSender());
            emit TokensStaked(_msgSender(), tokenReward);
        } else {
            // stake again to reset the timestamps and cooldown
            radarStakeContract.addToStake(0, _msgSender());
            // decided to not trigger this event because it does not add value
            // emit TokensStaked(_msgSender(), 0);

            // pay out the rewards, keep the original stake, reset the clock
            radarTokenContract.transferFrom(rewarderAddress, _msgSender(), tokenReward);
        }
    }

    // trigger the cooldown so you can later on call unstake() to unstake your tokens
    function triggerUnstake() external nonReentrant {
        iRadarStake.Stake memory myStake = radarStakeContract.getStake(_msgSender());
        require(myStake.totalStaked > 0, "RadarStakingLogic: You have no stake yet");

        if (myStake.cooldownSeconds <= 0) {
            radarStakeContract.triggerUnstake(_msgSender());
        }

        emit TokensUnstakingTriggered(_msgSender());
    }

    // unstake your tokens + rewards after the cooldown has passed
    function unstake(uint256 amount) external nonReentrant {
        require(amount >= 0, "RadarStakingLogic: Amount cannot be lower than 0");
        iRadarStake.Stake memory myStake = radarStakeContract.getStake(_msgSender());

        require(myStake.cooldownTriggeredAtTimestamp > 0, "RadarStakingLogic: Cooldown not yet triggered");
        require(block.timestamp >= myStake.cooldownTriggeredAtTimestamp + myStake.cooldownSeconds, "RadarStakingLogic: Can't unstake during the cooldown period");
        
        require(myStake.totalStaked >= amount, "RadarStakingLogic: Amount you want to unstake exceeds your staked amount");
        require((myStake.totalStaked - amount >= stakeForDappRadarPro) || (myStake.totalStaked - amount == 0), "RadarStakingLogic: Either unstake all or keep more than the minimum stake required");
        
        // calculate rewards
        uint256 tokenReward = calculateReward(_msgSender());

        // unstake & reset cooldown
        radarStakeContract.removeFromStake(amount, _msgSender());

        if (tokenReward > 0) {
            // transfer the rewards from the rewarderAddress to the user aka. pay the rewards
            radarTokenContract.transferFrom(rewarderAddress, _msgSender(), tokenReward);
            emit TokensHarvested(_msgSender(), tokenReward, false);
        }

        // transfer the stake from the radarStakeContract
        radarTokenContract.transferFrom(address(radarStakeContract), _msgSender(), amount);
        emit TokensUnstaked(_msgSender(), amount);
    }

    // calculate the total rewards a user has already earned.
    function calculateReward(address addr) public view returns(uint256 reward) {
        require(addr != address(0), "RadarStakingLogic: Cannot use the null address");

        iRadarStake.Stake memory myStake = radarStakeContract.getStake(addr);
        uint256 totalStaked = myStake.totalStaked;

        // return 0 if the user has no stake
        if (totalStaked <= 0 ) return 0;

        // calculate the timestamp when the cooldown is over
        uint256 endOfCooldownTimestamp = myStake.cooldownTriggeredAtTimestamp + myStake.cooldownSeconds;

        iRadarStake.Apr[] memory allAprs = radarStakeContract.getAllAprs();
        for (uint256 i = 0; i < allAprs.length; i++) {
            iRadarStake.Apr memory currentApr = allAprs[i];

            // jump over APRs, which are in the past for this user/address
            if (currentApr.endTime > 0 && currentApr.endTime < myStake.lastStakedTimestamp) continue;

            uint256 startTime = (myStake.lastStakedTimestamp > currentApr.startTime) ? myStake.lastStakedTimestamp : currentApr.startTime;
            uint256 endTime = (currentApr.endTime < block.timestamp)? currentApr.endTime : block.timestamp;

            // use current timestamp if the APR is still active (aka. has no endTime yet)
            if (endTime <= 0) endTime = block.timestamp;
            
            // once the cooldown is triggered, accumulate rewards only until that time
            if (myStake.cooldownTriggeredAtTimestamp > 0) {
                // accumulate only until the cooldown is over - user can reset it by unstaking or staking again
                if (endTime > endOfCooldownTimestamp) endTime = endOfCooldownTimestamp;
            }

            // protect against subtraction errors
            if (endTime <= startTime) continue;

            uint256 secondsWithCurrentApr = endTime - startTime;
            uint256 daysPassed = secondsWithCurrentApr/1 days;

            // calculate compounding rewards (per day)
            uint256 compoundingReward = calculateCompoundingReward(totalStaked, currentApr.apr, daysPassed);
            
            // compound the rewards for each APR period
            reward += compoundingReward;
            totalStaked += compoundingReward;
        }

        return reward;
    }

    // calculate compounding interest without running into floating point issues
    function calculateCompoundingReward(uint256 principal, uint256 aprToUse, uint256 daysPassed) private pure returns(uint256 compoundingReward) {
        for (uint256 i = 0; i < daysPassed; i++) {
            compoundingReward += (principal + compoundingReward) * aprToUse/10_000/365;
        }
    }
    
    /** ONLY OWNER */
    // allow to change the minimum amount to stake & keep staked to keep the PRO subscription
    function setStakeForDappRadarPro(uint256 number) external onlyOwner {
        require(number > 0, "RadarStakingLogic: Amount must be above 0");
        stakeForDappRadarPro = number;
    }

    // set the address from which all RADAR rewards are paid
    function setRewarderAddress(address addr) external onlyOwner {
        require(address(addr) != address(0), "RadarStakingLogic: Rewarder address not set");
        rewarderAddress = addr;
    }

    // if someone sends ETH to this contract by accident we want to be able to send it back to them
    function withdraw() external onlyOwner {
        uint256 totalAmount = address(this).balance;

        bool sent;
        (sent, ) = owner().call{value: totalAmount}("");
        require(sent, "RadarStakingLogic: Failed to send funds");
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface iRadarToken is IERC20 {

}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

interface iRadarStakingLogic {
   
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

interface iRadarStake {

    // store lock meta data
    struct Stake {
        uint256 totalStaked;
        uint256 lastStakedTimestamp;
        uint256 cooldownSeconds;
        uint256 cooldownTriggeredAtTimestamp;
    }

    struct Apr {
        uint256 startTime;
        uint256 endTime;
        uint256 apr; // e.g. 300 => 3%
    }

    function getAllAprs() external view returns(Apr[] memory);
    function getStake(address addr) external view returns (Stake memory);

    function addToStake(uint256 amount, address addr) external; // onlyStakingLogicContract
    function triggerUnstake(address addr) external; // onlyStakingLogicContract
    function removeFromStake(uint256 amount, address addr) external; // onlyStakingLogicContract
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