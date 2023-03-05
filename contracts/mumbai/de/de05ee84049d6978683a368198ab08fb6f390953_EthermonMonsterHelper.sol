/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

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

// File: contracts/Tournament.sol


pragma solidity ^0.8.9;




contract EthermonMonsterHelper is Ownable {

    mapping(uint256 tourneyNumber => uint256 tokens) public tokenPool;
    mapping(uint256 tourneyNumber => mapping(address addr => bool)) private enrolledPlayers;
    mapping(uint256 tourneyNumber => address addr) public winner;
    mapping(address => bool) public moderators;
    mapping(uint256 tourneyNumber => uint256 startTime) public timers;

    uint256 public ownerBalance = 0;
    uint256 public buyIn = 1 * 10**18;
    uint256 public maintainFee = .1 * 10**18;
    
    address public tokenContract =  0xe675d762199E0F7BD907B67E76f04403088ff5aC;


    function addModerator(address addr)
        public
        onlyOwner
        {
            moderators[addr] = true;
        }


    function removeModerator(address addr)
        public
        onlyOwner
        {
            moderators[addr] = false;
        }


    function setBuyIn(uint256 newBuyIn)
        public
        onlyOwner
        {
            buyIn = newBuyIn;
        }


    function setMaintainFee(uint256 newFee)
        public
        onlyOwner
        {
            maintainFee = newFee;
        }


    function enableTournament(uint256 tourneyNumber, uint256 startTime)
        public
        {
            require(moderators[msg.sender] || msg.sender == owner(), "Access Denied");
            require(timers[tourneyNumber] > block.timestamp || timers[tourneyNumber] == 0, "Cannot Change, Already Started");
            timers[tourneyNumber] = startTime;
        }


    function enrollPlayer(uint256 tourneyNumber)
        public
        {
            IERC20 tc = IERC20(tokenContract); 
            require(timers[tourneyNumber] > 0, "No Tourney Found");
            require(timers[tourneyNumber] < block.timestamp, "Tournament Already Started");
            require(!enrolledPlayers[tourneyNumber][msg.sender], "Already Enrolled");
            tokenPool[tourneyNumber] += buyIn-maintainFee;
            ownerBalance += maintainFee;
            enrolledPlayers[tourneyNumber][msg.sender] = true;
            tc.transferFrom(msg.sender, address(this), buyIn);
        }


    function isEnrolled(address addr, uint256 tourneyNumber)
        public
        view
        returns(bool)
        {
            return enrolledPlayers[tourneyNumber][addr];
        }


    function setWinner(uint256 tourneyNumber, address addr)
        public
        {
            require(moderators[msg.sender] || msg.sender == owner(), "Access Denied");
            winner[tourneyNumber] = addr;
        }


    function payWinnings(uint256 tourneyNumber)
        public
        {
            IERC20 tc = IERC20(tokenContract); 
            require(winner[tourneyNumber] == msg.sender, "You Didnt Win");
            require(tokenPool[tourneyNumber] > 0, "Nothing To Withdraw");
            tc.transferFrom(address(this), msg.sender, tokenPool[tourneyNumber]);
            tokenPool[tourneyNumber] = 0;
        }


    function withdraw(address addr)
        public
        onlyOwner
        {
            IERC20 tc = IERC20(tokenContract);
            tc.transferFrom(address(this), addr, ownerBalance);
            ownerBalance = 0;
        }


    function getTotalTokenBalance() external view returns(uint256) {
        IERC20 tc = IERC20(tokenContract);
        return tc.balanceOf(address(this));
    }


    function approveToken(uint256 _amount)
        public
        {
            IERC20 tc = IERC20(tokenContract);
            tc.approve(address(this), _amount);
        }
}