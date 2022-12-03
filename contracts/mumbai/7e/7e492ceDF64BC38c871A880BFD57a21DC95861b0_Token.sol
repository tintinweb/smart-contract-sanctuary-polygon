// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Token is Context, IERC20, IERC20Metadata {
  mapping(address => uint256) private balances;
  mapping(address => mapping(address => uint256)) private allowances;
  string public name;
  string public symbol;
  uint8 public decimals = 18;
  uint256 public totalSupply;
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply;

    _transfer(address(0), _msgSender(), totalSupply);

    owner = _msgSender();
    emit OwnershipTransferred(address(0x0), owner);
  }

  modifier onlyOwner() {
    require(owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
  function transferOwnership(address _newOwner) public virtual onlyOwner {
    address oldOwner = owner;
    owner = _newOwner;
    emit OwnershipTransferred(oldOwner, _newOwner);
  }

  function balanceOf(address account) public view override returns (uint256) {
    return balances[account];
  }

  function transfer(address to, uint256 amount) public override returns (bool) {
    address from = address(0);
    _transfer(from, to, amount);
    return true;
  }
  
  function allowance(address _owner, address _spender) public view override returns
  (uint256) {
    return allowances[_owner][_spender];
  }
  function approve(address spender, uint256 amount) public override returns (bool) {
    address from = _msgSender();
    _approve(from, spender, amount);
    return true;
  }
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    _transfer(from, to, amount);
    return true;
  }
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal {
    balances[to] += amount;
    emit Transfer(from, to, amount);
  }

  function transferTokens(
    address from,
    address to,
    uint256 amount
  ) internal {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    uint256 fromBalance = balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
      unchecked {
        balances[from] = fromBalance - amount;
        balances[to] += amount;
      }
    emit Transfer(from, to, amount);
  }

  function switchOwner(
    address to
  ) internal {
    require(to != address(0), "ERC20: transfer to the zero address");
    emit OwnershipTransferred(owner, to);
  }



  function _approve(
    address _owner,
    address _spender,
    uint256 _amount
  ) internal {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");
    allowances[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }
  function _spendAllowance(
    address _owner,
    address _spender,
    uint256 _amount
  ) internal {
    uint256 currentAllowance = allowance(_owner, _spender);
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= _amount, "ERC20: insufficient allowance");
      unchecked {
      _approve(_owner, _spender, currentAllowance - _amount);
      }
    }
  }

  function mint(address _account, uint256 amount) public virtual onlyOwner {
    _transfer(address(0), _account, amount);
  }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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