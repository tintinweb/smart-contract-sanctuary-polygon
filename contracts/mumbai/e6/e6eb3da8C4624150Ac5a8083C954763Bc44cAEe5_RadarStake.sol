// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/iRadarStake.sol";
import "./interfaces/iRadarToken.sol";
import "./interfaces/iRadarStakingLogic.sol";

contract RadarStake is iRadarStake, Ownable, ReentrancyGuard {

    constructor(address radarTokenContractAddr) {
        require(address(radarTokenContractAddr) != address(0), "RadarStake: Token contract not set");
        radarTokenContract = iRadarToken(radarTokenContractAddr);
    }

    /** EVENTS */
    event AddedToStake(address indexed owner, uint256 amount);
    event RemovedFromStake(address indexed owner, uint256 amount);
    event CooldownTriggered(address indexed owner, uint256 cooldownSeconds);

    /** PUBLIC VARS */
    // interface of our ERC20 RADAR token
    iRadarToken public radarTokenContract;
    // interface of the staking logic smart contract (stateless)
    iRadarStakingLogic public radarStakingLogicContract;
    // keeps track of all staked tokens at all times
    uint256 public totalStaked;
    // duration of the cooldown before a user can unstake
    uint256 public cooldownSeconds = 30 days; // e.g. 86_400 = 1 day
    // all APRs over time with their respective start and end times
    Apr[] public allAprs;

    /** PRIVATE VARS */
    // all data needed to calculate staking rewards and for keeping tack of users staked funds
    mapping(address => Stake) private _stakedTokens;

    /** MODIFIERS */
    modifier onlyStakingLogicContract() {
        require(_msgSender() == address(radarStakingLogicContract), "RadarStake: Only the StakingLogic contract can call this");
        _;
    }

    /** PUBLIC */
    // allow to fetch all APRs so the staking contract can fetch all of them with one call
    function getAllAprs() external view returns(Apr[] memory) {
        return allAprs;
    }

    // get one stake represening onr user
    function getStake(address addr) external view returns (Stake memory) {
        return _stakedTokens[addr];
    }

    /** ONLY STAKING LOGIC CONTRACT */
    // add to your stake & reset counters - allow amount == 0, so you can reset timers without having to add tokens to your stake
    function addToStake(uint256 amount, address addr) external onlyStakingLogicContract {
        require(amount >= 0, "RadarStake: Amount has to be 0 or higher");
        require(addr != address(0), "RadarStake: Cannot use the null address");
        require(allAprs.length > 0, "RadarStake: No APR set");

        // storage variable used multiple times thus storing it into memory and using the new one from now on
        uint256 _totalStaked = totalStaked;

        Stake memory myStake = _stakedTokens[addr];
        if (myStake.totalStaked > 0 && _totalStaked >= myStake.totalStaked) {
            // subtract the current stake from the total counter (memory)
            _totalStaked -= myStake.totalStaked;
        }

        // save new Stake
        _stakedTokens[addr] = Stake({
            totalStaked: myStake.totalStaked + amount,
            lastStakedTimestamp: block.timestamp,
            cooldownSeconds: 0, // reset cooldown
            cooldownTriggeredAtTimestamp: 0 // reset cooldown
        });

        // add to total staked amount (memory)
        _totalStaked += myStake.totalStaked + amount;
        // store this variable back to storage
        totalStaked = _totalStaked;

        emit AddedToStake(addr, amount);
    }

    // start the cooldown period before user can unstake when calling unstake() later
    function triggerUnstake(address addr) external onlyStakingLogicContract {
        require(addr != address(0), "RadarStake: Cannot use the null address");
        require(cooldownSeconds > 0, "RadarStake: Cooldown seconds must be bigger than 0");

        Stake memory myStake = _stakedTokens[addr];
        require(myStake.totalStaked >= 0, "RadarStake: You have no stake yet");

        // trigger cooldown only when it's not yet triggered
        if (myStake.cooldownSeconds <= 0) {
            myStake.cooldownSeconds = cooldownSeconds; // set the amount of seconds that have to pass before user can unstake
            myStake.cooldownTriggeredAtTimestamp = block.timestamp; // store the current time to calculate if the cooldown has passed
            _stakedTokens[addr] = myStake; // store the updated Stake to permantent storage

            emit CooldownTriggered(addr, cooldownSeconds);
        }
    }

    // remove from your stake
    function removeFromStake(uint256 amount, address addr) external onlyStakingLogicContract {
        require(amount >= 0, "RadarStake: Amount cannot be lower than 0");
        require(addr != address(0), "RadarStake: Cannot use the null address");
        Stake memory myStake = _stakedTokens[addr];
        require(myStake.cooldownSeconds >= 0, "RadarStake: CooldownSeconds cannot be lower than 0");
        require(myStake.totalStaked >= amount, "RadarStake: You cannot unstake more than you have staked");
        require(totalStaked >= amount, "RadarStake: Cannot unstake more than is staked in total");

        if (myStake.totalStaked == amount) {
            delete(_stakedTokens[addr]); // clean memory when the whole stake is being taken out
        } else {
            // save new Stake
            _stakedTokens[addr] = Stake({
                totalStaked: myStake.totalStaked - amount, // deduct the amount from the current stake
                lastStakedTimestamp: block.timestamp, // reset stake timestamp because we always harvest rewards before unstaking
                cooldownSeconds: 0, // reset cooldown
                cooldownTriggeredAtTimestamp: 0 // reset cooldown
            });
        }
        
        totalStaked -= amount; // subtract from total staked amount

        emit RemovedFromStake(addr, amount);
    }

    /** ONLY OWNER */
    // called when we deploy a new version of our staking rewards logic (new features etc.)
    function setContracts(address radarStakingLogicContractAddr) external onlyOwner {
        require(radarStakingLogicContractAddr != address(0), "RadarStake: Cannot use the null address");
        radarStakingLogicContract = iRadarStakingLogic(radarStakingLogicContractAddr);
    }

    // e.g apr = 300 => 3% APR
    function changeApr(uint256 apr) external onlyOwner {
        require(apr >= 0, "RadarStake: APR cannot be lower than 0");

        // set endTime for previous APR to make rewards calculations easier later on
        if (allAprs.length > 0) {
            Apr storage previousApr = allAprs[allAprs.length - 1];
            previousApr.endTime = block.timestamp;
        }

        // add new APR to the array so rewards can start accruing for this new APR from now on
        allAprs.push(Apr({
            startTime: block.timestamp,
            endTime: 0,
            apr: apr
        }));
    }

    // this is needed so that our RadarStakingLogic contract is allowed to call transferFrom() in the name of this contract so that users can get their payout when they call RadarStakingLogic.harvest or RadarStakingLogic.unstake
    function allowTokenTransfers(uint256 amount) external onlyOwner {
        require(amount >= 0, "RadarStake: Amount cannot be lower than 0");

        radarTokenContract.approve(address(radarStakingLogicContract), amount);
    }

    // allow to change the cooldown period
    function setCooldownSeconds(uint256 number) external onlyOwner {
        require(number >= 0, "RadarStake: Amount must be above 0");
        cooldownSeconds = number;
    }

    // if someone sends RADAR to this contract by accident we want to be able to send it back to them
    function withdrawRewardTokens(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "RadarStake: Cannot use the null address");
        require(amount >= 0, "RadarStake: Amount cannot be lower than 0");
        uint256 radarBalance = radarTokenContract.balanceOf(address(this));
        require(radarBalance >= amount, "RadarStake: Cannot withdraw more than is available");
        require(radarBalance - amount >= totalStaked, "RadarStake: Cannot withdraw more than is staked");
        
        // approve this contract to move the amount of tokens
        radarTokenContract.approve(address(this), amount);
        // transfer those tokens to the given address
        radarTokenContract.transferFrom(address(this), to, amount);
    }

    // if someone sends ETH to this contract by accident we want to be able to send it back to them
    function withdraw() external onlyOwner {
        uint256 totalAmount = address(this).balance;

        bool sent;
        (sent, ) = owner().call{value: totalAmount}("");
        require(sent, "RadarStake: Failed to send funds");
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