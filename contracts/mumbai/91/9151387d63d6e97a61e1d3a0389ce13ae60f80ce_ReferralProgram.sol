/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

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

// File: 1.sol



pragma solidity ^0.8.0;



contract ReferralProgram is Ownable {
    uint256 public joiningFee = 5 ether;
    uint256 public airdropAmount = 100 * 10**18;
    uint256[7] public levelRewards = [40, 10, 9, 8, 7, 6, 5];
    mapping(address => uint256) public lastAirdropClaim;
    mapping(address => mapping(address => bool)) public claimedAirdrops;
    mapping(address => uint256) public unclaimedAirdrops;
    mapping(address => address) public referrers;

    event Airdrop(address indexed user, address indexed token, uint256 amount);
    event ReferralRewards(address indexed referrer, uint256 level, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can call this function");
        _;
    }

    function setJoiningFee(uint256 _joiningFee) external onlyAdmin {
        joiningFee = _joiningFee;
    }

    function setAirdropAmount(uint256 _airdropAmount) external onlyAdmin {
        airdropAmount = _airdropAmount;
    }

    function setLevelReward(uint8 level, uint256 reward) external onlyAdmin {
        require(level < 7, "Invalid level");
        levelRewards[level] = reward;
    }

    function join(address referrer) external payable {
        require(msg.value >= joiningFee, "Insufficient joining fee");
        require(referrers[msg.sender] == address(0), "Already joined");
        referrers[msg.sender] = referrer == address(0) ? owner() : referrer;

        uint256 remainingAmount = joiningFee;
        address currentReferrer = referrers[msg.sender];
        for (uint8 i = 0; i < 7; i++) {
            if (currentReferrer == address(0)) {
                break;
            }
            uint256 reward = (joiningFee * levelRewards[i]) / 100;
            payable(currentReferrer).transfer(reward);
            remainingAmount -= reward;
            emit ReferralRewards(currentReferrer, i, reward);
            currentReferrer = referrers[currentReferrer];
        }

        payable(owner()).transfer(remainingAmount);
    }

    function addAirdrop(address token) external onlyAdmin {
        for (address user = address(0); user != address(0); user = referrers[user]) {
            if (!claimedAirdrops[user][token]) {
                unclaimedAirdrops[user] += airdropAmount;
                lastAirdropClaim[user] = block.timestamp;
                emit Airdrop(user, token, airdropAmount);
            }
        }
    }

    function claimAirdrop(address token) external {
        require(!claimedAirdrops[msg.sender][token], "Airdrop already claimed");
        require(block.timestamp <= lastAirdropClaim[msg.sender] + 7 days, "Airdrop expired");
        uint256 amount = unclaimedAirdrops[msg.sender];
        require(amount > 0, "No airdrop to claim");
        unclaimedAirdrops[msg.sender] = 0;
        claimedAirdrops[msg.sender][token] = true;
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdrawTokens(address token, uint256 amount) external onlyAdmin {
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdrawEther(uint256 amount) external onlyAdmin {
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}

    fallback() external payable {}
}