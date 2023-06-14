/**
 *Submitted for verification at polygonscan.com on 2023-06-14
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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// File: StakingNodeBGT.sol


pragma solidity ^0.8.0;


interface BGT  {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external;
 
    function burn(uint256 amount) external;
}

contract StakingNodeBGT is Ownable {
    
    BGT private bgtToken;
    uint256 private totalQuantity;
    uint256 private quantity;
    mapping(address => uint256) private balances;

    event NodeApplication(address indexed applicant, uint256 amount, uint256 balance);
    event ApplicationCanceled(address indexed applicant, uint amount);

    constructor(address _bgtTokenAddress) {
        bgtToken = BGT(_bgtTokenAddress);
        quantity = 100 * (10 ** bgtToken.decimals());
    }

    function applyForNode() external {
        require(quantity > balances[msg.sender], "You've applied for a node");
        uint256 amount = quantity - balances[msg.sender];
        require(bgtToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");

        // Update the balance and the dpos
        balances[msg.sender] += amount;
        totalQuantity += amount;
        // Transfer BGT tokens from user to the contract
        bgtToken.transferFrom(msg.sender, address(this), amount);
    
        emit NodeApplication(msg.sender, amount, balances[msg.sender]);
    }

    function cancelApplication() external {
        require(balances[msg.sender] > 0, "You have not applied for a node");

        uint amount = balances[msg.sender];

        // Transfer the pledged USDT back to the user
        bgtToken.transfer(msg.sender, amount);

        // Update the node application status and canceled application status
        balances[msg.sender] = 0;
        totalQuantity -= amount;

        emit ApplicationCanceled(msg.sender, amount);
    }

    function getTotalQuantity() external view returns (uint256)
    {
        return totalQuantity;
    }
}