/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @maticnetwork/fx-portal/contracts/tunnel/[email protected]

pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/SpitDispenser.sol

pragma solidity ^0.8.12;



/**
 * SpitDispenser

**/

contract SpitDispenser is FxBaseChildTunnel, Ownable {

    uint256 public spitRate = 15 ether;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public spitAccumulated;

    mapping(address => uint256) public lastUpdated;

    ///@dev verify address before deployment
    IERC20 public spit;

    /*///////////////////////////////////////////////////////////////
    //                        CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////*/

    ///@dev verify address before deployment
    constructor() FxBaseChildTunnel(0xCf73231F28B7331BBe3124B907840A94851f9f11) {}

    /*///////////////////////////////////////////////////////////////
    //                        User FUNCTIONS                      //
    //////////////////////////////////////////////////////////////*/

    ///@notice Allows user to withdraw spit tokens
    function collectSpit() external updateReward(msg.sender) {
        uint256 amount = spitAccumulated[msg.sender];
        spitAccumulated[msg.sender] = 0;
        spit.transfer(msg.sender, amount);
    }

    /*///////////////////////////////////////////////////////////////
    //                 ACCESS CONTROLLED FUNCTIONS                //
    //////////////////////////////////////////////////////////////*/

    ///@notice Allows owner to remove spit from the contract
    function withdrawSpit(address recipient, uint256 amount) public onlyOwner {
        spit.transfer(recipient, amount);
    }

    ///@notice Allows owner to update the spit rate
    function setSpitRate(uint256 reward) public onlyOwner {
        spitRate = reward;
    }

    ///@notice Allows owner to update the FxRoot Tunnel address
    function updateFxRootTunnel(address _fxRootTunnel) external onlyOwner {
        fxRootTunnel = _fxRootTunnel;
    }

    ///@notice Allows owner to update spit token address
    function updateSpitAddress(address _spit) external onlyOwner {
        spit = IERC20(_spit);
    }

    /*///////////////////////////////////////////////////////////////
    //                  INTERNAL STAKING LOGIC                    //
    //////////////////////////////////////////////////////////////*/

    ///@notice Updates the user balance and last updated time
    modifier updateReward(address account) {
        uint256 amount = earned(account);
        lastUpdated[account] = block.timestamp;
        spitAccumulated[account] += amount;
        _;
    }

    ///@notice Updates the staked balance when a spitBuddy is staked on mainnet
    function processStake(address account, uint256 amount) internal updateReward(account) {
        stakedBalance[account] += amount;
    }

    ///@notice Updates the staked balance when a spitBuddy is unstaked on mainnet
    function processUnstake(address account, uint256 amount) internal updateReward(account) {
        stakedBalance[account] -= amount;
    }

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal override validateSender(sender) {
        (address from, uint256 count, bool action) = abi.decode(message, (address, uint256, bool));
        action ? processStake(from, count) : processUnstake(from, count);
    }

    /*///////////////////////////////////////////////////////////////
    //                         UTILITIES                          //
    //////////////////////////////////////////////////////////////*/

    ///@notice Internal spit accumulation tracking
    function earned(address account) internal view returns (uint256) {
        return rewardsPerSecond(account) * (block.timestamp - lastUpdated[account]);
    }

    ///@notice Returns the amount of spit tokens a user can collect
    function getUserAccruedRewards(address account) external view returns (uint256) {
        return spitAccumulated[account] + earned(account);
    }

    ///@notice Returns the amount of spit tokens a user is accumulating per second
    function rewardsPerSecond(address account) internal view returns (uint256) {
        return (stakedBalance[account] * spitRate) / 1 days;
    }

    
}