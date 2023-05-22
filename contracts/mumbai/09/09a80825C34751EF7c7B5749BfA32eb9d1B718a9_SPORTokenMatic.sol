// SPDX-License-Identifier: MIT

/******************************************************************************\
* (https://github.com/shroomtopia)
* Implementation of ShroomTopia's ERC20 SPOR Token
/******************************************************************************/

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {ISPORToken} from "../../Shared/interfaces/ISPORToken.sol";

contract SPORTokenMatic is Context, ISPORToken, Initializable {

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;

  address private childManager;
  address private shroomTopiaDao;

  uint256 private _cap;


  function initToken(uint256 cap_, uint256 initialsupply_, address team_, address childManager_, address shroomTopiaDao_) external initializer {
    _mint(team_, initialsupply_);
    childManager = childManager_;
    shroomTopiaDao = shroomTopiaDao_;
    _cap = cap_;
  }

  // Only ShroomTopia DAO can call this!
  function capChange(uint256 cap_) external {
    require (msg.sender == shroomTopiaDao, 'ERC20: Not Authorized');
    _cap = cap_;
  }

  function cap() public view virtual returns (uint256) {
    return _cap;
  }

  // Only ShroomTopia DAO can call this!
  function mint(address user, uint256 amount) external override {
      require (msg.sender == shroomTopiaDao, 'ERC20: Not Authorized');

      require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");    
      _mint(user, amount);
  }

  function name() public view virtual override returns (string memory) {
      return 'ShroomTopia mSPOR Token';
  }

  function symbol() public view virtual override returns (string memory) {
      return 'mSPOR';
  }

  function decimals() public view virtual override returns (uint8) {
      return 18;
  }

  function totalSupply() public view virtual override returns (uint256) {
      return _totalSupply;
  }


  function balanceOf(address account) public view virtual override returns (uint256) {
      return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
      _transfer(_msgSender(), recipient, amount);
      return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
      return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
      _approve(_msgSender(), spender, amount);
      return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
      _transfer(sender, recipient, amount);

      uint256 currentAllowance = _allowances[sender][_msgSender()];
      require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
      _approve(sender, _msgSender(), currentAllowance - amount);

      return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
      _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
      return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
      uint256 currentAllowance = _allowances[_msgSender()][spender];
      require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);

      return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");

      uint256 senderBalance = _balances[sender];
      require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
      _balances[sender] = senderBalance - amount;
      _balances[recipient] += amount;

      emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
      require(account != address(0), "ERC20: mint to the zero address");

      _totalSupply += amount;
      _balances[account] += amount;
      emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
      require(account != address(0), "ERC20: burn from the zero address");

      uint256 accountBalance = _balances[account];
      require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
      _balances[account] = accountBalance - amount;
      _totalSupply -= amount;

      emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
      require(owner != address(0), "ERC20: approve from the zero address");
      require(spender != address(0), "ERC20: approve to the zero address");

      _allowances[owner][spender] = amount;
      emit Approval(owner, spender, amount);
  }

  function deposit(address user, bytes calldata depositData) external {
      require(msg.sender == childManager, "ERC20: Not Authorized");
      uint256 amount = abi.decode(depositData, (uint256));
      _mint(user, amount);
  }

  function withdraw(uint256 amount) external {
      _burn(_msgSender(), amount);
  }

  function burn(address account, uint256 amount) external override {
      require (msg.sender == shroomTopiaDao, 'ERC20: Not Authorized');

      uint256 accountBalance = _balances[account];
      require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
      _balances[account] = accountBalance - amount;
      _totalSupply -= amount;

      emit Transfer(account, address(0), amount);
  }

}

// // SPDX-License-Identifier: MIT
/******************************************************************************\
* (https://github.com/shroomtopia)
* ShroomTopia's ERC20 SPOR Token Interface
/******************************************************************************/

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Metadata is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

interface ISPORToken is IERC20Metadata {
  function mint(address user, uint256 amount) external;
  function burn(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}