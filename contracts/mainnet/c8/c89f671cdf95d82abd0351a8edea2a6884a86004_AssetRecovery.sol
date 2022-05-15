/**
 *Submitted for verification at polygonscan.com on 2022-05-15
*/

// File: gogo-contracts/contracts/staking/orionmoney/IStakeOrionManager.sol


pragma solidity ^0.8.4;

interface IStakeOrionManager {
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function exit() external;

    function getStableReward() external;

    function withdrawPending() external;

    function getReward() external;

    function getRewardFor(address user) external;

    function notifyRewardAmount(uint256 reward) external;

    function getUserContract(address user) external view returns (address);

    function getPending(address user) external view returns (bool);

    function getPendingAmount(address user) external view returns (uint256);

    function getContractBalance(address user) external view returns (uint256);

    function getStakedBalance(address user) external view returns (uint256);

    function earnedStable(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function rewardsClaimableWithoutLoss(address account)
        external
        view
        returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function setFeeReceiver(address newFeeReceiver) external;

    function setRewardsDistributionAddress(address rewardsDistributionAddress)
        external;

    function setRewardsDuration(uint256 _rewardsDuration) external;

    function setFee(uint256 fee) external;

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function setPoolManager(address poolManager_) external;

    function transferOwnership(address newOwner) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: gogo-contracts/contracts/staking/orionmoney/asset-recovery/AssetRecovery.sol


pragma solidity 0.8.4;




contract AssetRecovery is Ownable {
    bool public isInit;
    IStakeOrionManager public som;
    IERC20 public asset;

    // user => auth.
    mapping(address => address) public authorized;

    constructor(bool _init) {
        isInit = _init; // set to true, when using proxy
    }

    function initialize(IStakeOrionManager _som, IERC20 _asset) external {
        require(!isInit, "contract already initialized");

        isInit = true;

        _transferOwnership(msg.sender);

        som = _som;
        asset = _asset;
    }

    function balanceOf(address _account) public view returns (uint256) {
        address userContract = som.getUserContract(_account);
        return asset.balanceOf(userContract);
    }

    function _withdraw(address _account) internal {
        address userContract = som.getUserContract(_account);
        uint256 accountBalance = balanceOf(_account);

        IStakeOrionManager(userContract).recoverERC20(
            address(asset),
            accountBalance
        );

        require(accountBalance > 0, "Transfer failed: 0 balance");

        asset.transfer(msg.sender, accountBalance);

        emit Withdraw(_account, msg.sender, address(asset), accountBalance);
    }

    function withdraw() external {
        _withdraw(msg.sender);
    }

    // needed for external smart contracts which used our usdc pool
    function withdrawFor(address _account) external {
        require(msg.sender == authorized[_account], "no authorization");
        _withdraw(_account);
    }

    // set auth to address(0) to remove allowance
    function setAuthorization(address _account, address _auth)
        external
        onlyOwner
    {
        authorized[_account] = _auth;
    }

    // administrative manager functions

    function setSOMOwner(address _newOwner) external onlyOwner {
        som.transferOwnership(_newOwner);
    }

    function recoverERC20(IERC20 token) external onlyOwner {
        uint256 thisBalance = token.balanceOf(address(this));

        require(thisBalance > 0, "Transfer failed: 0 balance");

        token.transfer(msg.sender, thisBalance);

        emit Recovered(address(token), thisBalance);
    }

    function recoverERC20FromSOM(IERC20 token) external onlyOwner {
        uint256 somBalance = token.balanceOf(address(som));

        require(somBalance > 0, "Transfer failed: 0 balance");

        som.recoverERC20(address(token), somBalance);

        token.transfer(msg.sender, somBalance);

        emit Recovered(address(token), somBalance);
    }

    function recoverERC20FromUserContract(address userContract, IERC20 token)
        external
        onlyOwner
    {
        uint256 userContractBalance = token.balanceOf(userContract);

        require(userContractBalance > 0, "Transfer failed: 0 balance");

        IStakeOrionManager(userContract).recoverERC20(
            address(token),
            userContractBalance
        );

        token.transfer(msg.sender, userContractBalance);

        emit Recovered(address(token), userContractBalance);
    }

    function recoverERC20FromUser(address user, IERC20 token)
        external
        onlyOwner
    {
        address userContract = som.getUserContract(user);
        uint256 userContractBalance = token.balanceOf(userContract);

        require(userContractBalance > 0, "Transfer failed: 0 balance");

        IStakeOrionManager(userContract).recoverERC20(
            address(token),
            userContractBalance
        );

        token.transfer(msg.sender, userContractBalance);

        emit Recovered(address(token), userContractBalance);
    }

    function setPoolManager(address _poolmanager) external onlyOwner {
        som.setPoolManager(_poolmanager);
    }

    function setFee(uint256 _fee) external onlyOwner {
        som.setFee(_fee);
    }

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        som.setRewardsDuration(_duration);
    }

    function setRewardsDistributionAddress(address _distributionAddress)
        external
        onlyOwner
    {
        som.setRewardsDistributionAddress(_distributionAddress);
    }

    function setFeereceiver(address account) external onlyOwner {
        som.setFeeReceiver(account);
    }

    /* Allow calling arbitrarily external contracts from this contract essentially having address(this) as msg.sender in external contracts
     *  Calldata param should be an abi encoded signature and data. eg: abi.encodeWithSignature("add(uint8,uint8)", 10, 15)
     */
    function callExt(address target, bytes memory data)
        external
        onlyOwner
        returns (bytes memory)
    {
        (bool success, bytes memory result) = target.call(data);
        require(success, "Ext: Call failed");
        return result;
    }

    // events
    event Withdraw(
        address account,
        address sender,
        address assetAddress,
        uint256 amount
    );
    event Recovered(address token, uint256 amount);
}