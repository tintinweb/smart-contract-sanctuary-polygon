/**
 *Submitted for verification at polygonscan.com on 2022-05-08
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

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


// File @openzeppelin/contracts/token/ERC20/[email protected]
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


// File interfaces/IRouter.sol

interface IRouter {
  event Deposit(uint32 serverId, string username, address indexed sender, uint value);
  event Withdraw(uint32 serverId, string username, address indexed recipient, uint value);
}


// File interfaces/IManagerRouter.sol

pragma solidity >=0.5.0;

interface IManagerRouter {
  function validate(address contractAddress)  external returns (bool);
  function getCommission(address contractAddress) external returns (uint32);
}


// File contracts/CustomerRouter.sol

// This contract is under development and has not yet been deployed on mainnet

pragma solidity ^0.8.0;
contract CustomerRouter is IRouter, Ownable {
  
  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
  IERC20 private immutable _token;
  IManagerRouter private _managerRouter;
  address public tokenAddress;
  address public managerRouterAddress;
  uint32 public depositFeeAdmin = 0;
  uint32 public depositBurn = 0;
  uint32 public depositFee = 0;
  uint32 public withdrawFeeAdmin = 0;
  uint32 public withdrawBurn = 0;
  uint32 public withdrawFee = 0;
  
  // Function to receive Ether. msg.data must be empty
  receive() external payable {}

  // Fallback function is called when msg.data is not empty
  fallback() external payable {}

  constructor(IERC20 token, address managerRouter) {
    require(address(0) != managerRouter, "Bad manager router");
    _token = token;
    tokenAddress = address(token);
    managerRouterAddress = managerRouter;
    _managerRouter = IManagerRouter(managerRouter);
  }
  
  function deposit(uint32 serverId, string calldata nickname, uint amount) external {
    require(_managerRouter.validate(address(this)), "Server or Router is not valid!");
    require(amount > 0, toString(amount));
    
    uint managerFeeAmount = _getPercentage(amount, _managerRouter.getCommission(address(this)));
    uint adminFeeAmount = _getPercentage(amount, depositFeeAdmin);
    uint burnAmount = _getPercentage(amount, depositBurn);
    uint feeAmount = _getPercentage(amount, depositFee);
    
    uint depositAmount = amount - adminFeeAmount - burnAmount - feeAmount - managerFeeAmount;

    _token.transferFrom(_msgSender(), address(this), amount);

    if (burnAmount > 0) {
      _token.transfer(DEAD, burnAmount);
    }

    if (adminFeeAmount > 0) {
      _token.transfer(owner(), adminFeeAmount);
    }

    if (managerFeeAmount > 0) {
      _token.transfer(managerRouterAddress, managerFeeAmount);
    }

    emit Deposit(serverId, nickname, _msgSender(), depositAmount);
  }
  
  /*
    At the moment, the withdrawal is made on behalf of the owner,
    because it is necessary to ensure that the withdrawal is made
    directly by the owner of the game account, for this,
    certain checks are made on the centralized server
    
    In future versions of the router this will be rewritten
    and there will be no centralized server 
  */
  function withdraw(uint32 serverId, address recipient, string calldata nickname, uint amount) external onlyOwner {
    require(_managerRouter.validate(address(this)), "Server or Router is not valid!");
    require(amount > 0, "Amount must be greater than 0");

    uint managerFeeAmount = _getPercentage(amount, _managerRouter.getCommission(address(this)));
    uint adminFeeAmount = _getPercentage(amount, withdrawFeeAdmin);
    uint burnAmount = _getPercentage(amount, withdrawBurn);
    uint feeAmount = _getPercentage(amount, withdrawFee);
    
    uint withdrawAmount = amount - adminFeeAmount - burnAmount - feeAmount - managerFeeAmount;
    
    _token.transfer(recipient, withdrawAmount);
    
    if (burnAmount > 0) {
      _token.transfer(DEAD, burnAmount);
    }
    
    if (adminFeeAmount > 0) {
      _token.transfer(owner(), adminFeeAmount);
    }
    
    if (managerFeeAmount > 0) {
      _token.transfer(managerRouterAddress, managerFeeAmount);
    }
      
    emit Withdraw(serverId, nickname, recipient, amount);
  }

  function setDepositFees(uint32 feeAdmin, uint32 burnFee, uint32 fee) external onlyOwner {
    require(
      feeAdmin <= 10000 &&
      burnFee <= 10000 &&
      fee <= 10000
    );

    depositFeeAdmin = feeAdmin;
    depositBurn = burnFee;
    depositFee = fee;
  }

  function setWithdrawFees(uint32 feeAdmin, uint32 burnFee, uint32 fee) external onlyOwner {
    require(
      feeAdmin <= 10000 &&
      burnFee <= 10000 &&
      fee <= 10000
    );
    
    withdrawFeeAdmin = feeAdmin;
    withdrawBurn = burnFee;
    withdrawFee = fee;
  }
  
  function grabStuckTokens(IERC20 token, address wallet, uint amount) external onlyOwner {
    token.transfer(wallet, amount);
  }
  
  function _getPercentage(uint number, uint32 percent) internal pure returns (uint) {
    return (number * percent) / 10000;
  }

  function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}