/**
 *Submitted for verification at polygonscan.com on 2023-02-11
*/

//SPDX-License-Identifier:Apache-2.0
pragma solidity 0.8.18;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the IERC token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function increaseAllowance(address spender, uint256 addedValue) external  returns (bool);
  function decreaseAllowance(address spender, uint256 subtractedValue) external  returns (bool);
  function burn(uint256 amount) external returns (bool);
  
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
interface Proxy{
  function transfer2(address recipient, uint256 amount,address contractAddr) external returns (bool);
  function transferFrom2(address sender, address recipient, uint256 amount,address contractAddr) external returns (bool);
}
contract ProxyIerc20 is  IERC20 {

    address private targetContract;//目标合约插槽
    address private _admin;

    constructor(address _targetContract) {
        targetContract=_targetContract;
        _admin=msg.sender;
    }
    function set_targetContract(address addr)external {
        require(_admin==msg.sender,"You don't have permission");
        targetContract=addr;
    }
  /**
   * @dev Returns the IERC token owner.
   */
  function getOwner() external override view returns (address) {
    return IERC20(targetContract).getOwner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external override view returns (uint8) {
    return IERC20(targetContract).decimals();
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external override view returns (string memory) {
    return IERC20(targetContract).symbol();
  }

  /**
  * @dev Returns the token name.
  */
  function name() external override view returns (string memory) {
    return IERC20(targetContract).name();
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() external override view returns (uint256) {
    return IERC20(targetContract).totalSupply();
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) external override view returns (uint256) {
    return IERC20(targetContract).balanceOf(account);
  }
  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external override returns (bool){
    if(isContract(msg.sender)){
        Proxy(targetContract).transfer2(recipient, amount,msg.sender);
    }
    else{
        IERC20(targetContract).transfer(recipient, amount);
    }
    emit Transfer(msg.sender, recipient, amount); 
    return true;
 }
  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender) external override view returns (uint256) {
    return IERC20(targetContract).allowance(owner,spender);
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    IERC20(targetContract).approve( spender, amount);
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {IERC20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    if(isContract(msg.sender)){
        Proxy(targetContract).transferFrom2(sender,recipient,amount,msg.sender);
    }
    else{
        IERC20(targetContract).transferFrom(sender,recipient,amount);
    }
    emit Transfer(sender, recipient, amount); 
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) external  returns (bool) {
    IERC20(targetContract).increaseAllowance(spender,addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    IERC20(targetContract).decreaseAllowance( spender, subtractedValue);
    return true;
  }

  /**
   * @dev Burn `amount` tokens and decreasing the total supply.
   */
  event Burn(address indexed from, address indexed to, uint256 value);
  function burn(uint256 amount) external returns (bool) {
    IERC20(targetContract).burn( amount);
    emit Burn(msg.sender,address(0),amount);
    return true;
  }

  function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}