/**
 *Submitted for verification at polygonscan.com on 2023-04-07
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

// File: contracts/House.sol




pragma solidity ^0.8.19;

interface FFC {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract House is Ownable {
    FFC public ffc;
    address public bettingContract;
    uint256 public totalReceived;
    uint256 public totalSent;

    event BetReceived(uint256 indexed amount);
    event BetSent(address indexed recipient, uint256 indexed amount);

    error AddressIsZero();
    error InvalidAmount();
    error InsufficientBalance();
    error UnauthorizedAddress();

    modifier addressIsZero(address value) {
        if (value == address(0)) revert AddressIsZero();
        _;
    }

    constructor() {
        totalReceived = 0;
        totalSent = 0;
    }

    function approveBettingContract() external onlyOwner returns (bool) {
        ffc.approve(bettingContract, 10000);
        return true;
    }

    function receiveBet(uint256 amount) external returns (bool) {
        if (msg.sender != bettingContract) revert UnauthorizedAddress();
        if (amount == 0) revert InvalidAmount();
        totalReceived += amount;
        emit BetReceived(amount);
        return true;
    }

    function sendBet(
        address recipient,
        uint256 amount
    ) external returns (bool) {
        if (msg.sender != bettingContract) revert UnauthorizedAddress();
        if (amount == 0) revert InvalidAmount();
        if (amount > ffc.balanceOf(address(this))) revert InsufficientBalance();
        totalSent += amount;
        emit BetSent(recipient, amount);
        return true;
    }

    function setBettingContract(
        address _bettingContract
    ) external onlyOwner addressIsZero(_bettingContract) returns (bool) {
        bettingContract = _bettingContract;
        return true;
    }

    function setFlyFlutterCoin(
        address _ffcAddress
    ) external onlyOwner addressIsZero(_ffcAddress) returns (bool) {
        ffc = FFC(_ffcAddress);
        return true;
    }
}