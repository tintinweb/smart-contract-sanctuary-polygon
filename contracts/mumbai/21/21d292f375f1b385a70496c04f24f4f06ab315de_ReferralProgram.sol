/**
 *Submitted for verification at polygonscan.com on 2023-05-24
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

// File: R3.sol


pragma solidity ^0.8.0;



contract ReferralProgram is Ownable {
    IERC20 public token;
    uint256 public joiningFee = 5 * 10**18; 
    uint256[7] public levelRewards = [40, 6, 5, 4, 3, 2, 1];
    mapping(address => User) public users;
    address[] public members;

    struct User {
        address referrer;
        uint256 joinTimestamp;
        uint256 earnedRewards;
        bool whitelisted;
    }

    event ReferralRewards(address indexed referrer, uint256 level, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
    }

    function isMember(address user) public view returns (bool) {
        return users[user].joinTimestamp + 5 * 30 days >= block.timestamp;
    }

    function getReferrer(address user) public view returns (address) {
        return users[user].referrer;
    }

    function isInWhitelist(address user) public view returns (bool) {
        return users[user].whitelisted;
    }

    function earnedFromReferrals(address user) public view returns (uint256) {
        return users[user].earnedRewards;
    }

    function setJoiningFee(uint256 _joiningFee) external onlyOwner {
        joiningFee = _joiningFee;
    }

    function setLevelReward(uint8 level, uint256 reward) external onlyOwner {
        require(level < 7, "Invalid level");
        levelRewards[level] = reward;
    }

    function addToWhitelist(address user) external onlyOwner {
        users[user].whitelisted = true;
    }

    function removeFromWhitelist(address user) external onlyOwner {
        users[user].whitelisted = false;
    }

    function join(address referrer) external {
        require(users[msg.sender].joinTimestamp + 5 * 30 days < block.timestamp, "Already joined or not yet expired");

        // Check and clean expired users, up to 5 users at a time
        for (uint i = 0; i < 5 && members.length > 0 && users[members[0]].joinTimestamp + 6 * 30 days < block.timestamp; i++) {
            delete users[members[0]];
            // This is a bit expensive operation, be careful with the gas cost
            for (uint j = 0; j < members.length - 1; j++) {
                members[j] = members[j + 1];
            }
            members.pop();
        }

        if (!users[msg.sender].whitelisted) {
            require(token.balanceOf(msg.sender) >= joiningFee, "Insufficient joining fee");
            require(token.transferFrom(msg.sender, address(this), joiningFee), "Transfer of joining fee failed");
        }

        if (referrer != address(0) && isMember(referrer)) {
            users[msg.sender].referrer = referrer;
        } else {
            users[msg.sender].referrer = owner();
        }

        users[msg.sender].joinTimestamp = block.timestamp;
        members.push(msg.sender);

        if (!users[msg.sender].whitelisted) {
            uint256 remainingAmount = joiningFee;
            address currentReferrer = users[msg.sender].referrer;
            for (uint8 i = 0; i < 7; i++) {
                if (currentReferrer == address(0) || users[currentReferrer].joinTimestamp + 5 * 30 days < block.timestamp) {
                    break;
                }
                uint256 reward = (joiningFee * levelRewards[i]) / 100;
                token.transfer(currentReferrer, reward);
                remainingAmount -= reward;
                users[currentReferrer].earnedRewards += reward;
                emit ReferralRewards(currentReferrer, i, reward);
                currentReferrer = users[currentReferrer].referrer;
            }

            token.transfer(owner(), remainingAmount);
        }
    }


    function withdrawTokens(uint256 amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= amount, "Not enough tokens in the contract");
        require(token.transfer(msg.sender, amount), "Token transfer failed");
    }

   
    function withdrawEther(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Not enough Ether in the contract");
        payable(msg.sender).transfer(amount);
    }
}