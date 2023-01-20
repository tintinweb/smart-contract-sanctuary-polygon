/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import '@grexie/signable/contracts/Signable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

contract CharityToken is Signable, IERC20Metadata {
  IERC20Metadata private _token;
  address private _signer;

  address public serviceAccount;
  uint256 public serviceFee;
  uint256 public minDeposit;
  uint256 public minWithdraw;

  string public name;
  string public symbol;

  mapping(address => bool) public paused;
  mapping(address => bool) public adminPaused;

  uint256 public totalSupply;
  mapping(address => uint256) public balances;
  mapping(address => bool) public allowed;
  mapping(address => mapping(address => uint256)) public allowances;

  event ServiceFee(address indexed account, uint256 amount);
  event SignerChanged(address indexed from, address indexed to);
  event ServiceAccountChanged(address indexed from, address indexed to);
  event ServiceFeeChanged(uint256 from, uint256 to);
  event MinWithdrawChanged(uint256 from, uint256 to);
  event MinDepositChanged(uint256 from, uint256 to);
  event Paused(address indexed account);
  event Resumed(address indexed account);
  event AdminPaused(address indexed account);
  event AdminResumed(address indexed account);
  event AllowTransfers(address indexed account);
  event DisallowTransfers(address indexed account);

  constructor(
    string memory name_,
    string memory symbol_,
    address token_,
    address signer_,
    address serviceAccount_,
    uint256 serviceFee_,
    uint256 minDeposit_,
    uint256 minWithdraw_
  ) {
    name = name_;
    symbol = symbol_;
    _token = IERC20Metadata(token_);
    _signer = signer_;
    serviceAccount = serviceAccount_;
    serviceFee = serviceFee_;
    minDeposit = minDeposit_;
    minWithdraw = minWithdraw_;
  }

  function signer() public view virtual override(ISignable) returns (address) {
    return _signer;
  }

  function setSigner(address signer_, Signature calldata signature)
    external
    verifySignature(abi.encode(this.setSigner.selector, signer_), signature)
  {
    emit SignerChanged(_signer, signer_);
    _signer = signer_;
  }

  function setServiceAccount(
    address serviceAccount_,
    Signature calldata signature
  )
    public
    verifySignature(
      abi.encode(this.setServiceAccount.selector, serviceAccount_),
      signature
    )
  {
    emit ServiceAccountChanged(serviceAccount, serviceAccount_);
    serviceAccount = serviceAccount_;
  }

  function setServiceFee(uint256 serviceFee_, Signature calldata signature)
    external
    verifySignature(
      abi.encode(this.setServiceFee.selector, serviceFee_),
      signature
    )
  {
    emit ServiceFeeChanged(serviceFee, serviceFee_);
    serviceFee = serviceFee_;
  }

  function setMinDeposit(uint256 minDeposit_, Signature calldata signature)
    external
    verifySignature(
      abi.encode(this.setMinDeposit.selector, minDeposit_),
      signature
    )
  {
    emit MinDepositChanged(minDeposit, minDeposit_);
    minDeposit = minDeposit_;
  }

  function setMinWithdraw(uint256 minWithdraw_, Signature calldata signature)
    external
    verifySignature(
      abi.encode(this.setMinWithdraw.selector, minWithdraw_),
      signature
    )
  {
    emit MinWithdrawChanged(minWithdraw, minWithdraw_);
    minWithdraw = minWithdraw_;
  }

  function token() public view returns (address) {
    return address(_token);
  }

  function decimals() external view returns (uint8) {
    return _token.decimals();
  }

  function balanceOf(address account) external view returns (uint256) {
    return balances[account];
  }

  function deposit(uint256 amount)
    external
    whenNotPaused(msg.sender)
    returns (bool)
  {
    require(
      amount >= minDeposit,
      'CharityToken: amount must meet minimum deposit'
    );

    require(
      _token.transferFrom(msg.sender, address(this), amount),
      'CharityToken: failed to transfer'
    );

    totalSupply += amount;

    uint256 _serviceFee = (amount * serviceFee) / 10000;
    amount -= _serviceFee;

    balances[serviceAccount] += _serviceFee;
    balances[msg.sender] += amount;

    emit Transfer(address(0), msg.sender, amount + _serviceFee);
    emit Transfer(msg.sender, serviceAccount, _serviceFee);

    return true;
  }

  function withdraw(uint256 amount)
    external
    whenNotPaused(msg.sender)
    returns (bool)
  {
    require(
      amount >= minWithdraw,
      'CharityToken: amount must meet minimum withdrawal'
    );
    require(
      balances[msg.sender] >= amount,
      'CharityToken: insufficient balance'
    );

    balances[msg.sender] -= amount;
    totalSupply -= amount;
    emit Transfer(msg.sender, address(0), amount);

    require(
      _token.transfer(msg.sender, amount),
      'CharityToken: failed to transfer'
    );

    return true;
  }

  function allowance(address owner, address spender)
    external
    view
    returns (uint256)
  {
    return allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    external
    whenNotPaused(msg.sender)
    whenNotPaused(spender)
    returns (bool)
  {
    require(
      allowed[spender],
      'CharityToken: can only approve allowed accounts'
    );

    allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);

    return true;
  }

  function transfer(address to, uint256 amount)
    external
    whenNotPaused(msg.sender)
    whenNotPaused(to)
    returns (bool)
  {
    require(allowed[to], 'CharityToken: can only transfer to allowed accounts');
    require(
      balances[msg.sender] >= amount,
      'CharityToken: insufficient balance'
    );

    balances[msg.sender] -= amount;
    balances[to] += amount;

    emit Transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external whenNotPaused(from) whenNotPaused(to) returns (bool) {
    require(
      to == msg.sender,
      'CharityToken: only approved spender can transfer from'
    );
    require(allowed[to], 'CharityToken: can only transfer to allowed accounts');
    require(
      allowances[from][to] >= amount,
      'CharityToken: amount not approved'
    );
    require(balances[from] >= amount, 'CharityToken: insufficient balance');

    allowances[from][to] -= amount;
    balances[from] -= amount;
    balances[to] += amount;

    emit Transfer(from, to, amount);

    return true;
  }

  function claim(
    address from,
    uint256 amount,
    Signature calldata signature
  )
    external
    whenNotPaused(from)
    whenNotPaused(msg.sender)
    verifySignature(abi.encode(this.claim.selector, from, amount), signature)
    returns (bool)
  {
    require(balances[from] >= amount, 'CharityToken: insufficient balance');

    balances[from] -= amount;
    balances[msg.sender] += amount;
    emit Transfer(from, msg.sender, amount);

    return true;
  }

  function allow(address to, Signature calldata signature)
    external
    verifySignature(abi.encode(this.allow.selector, to), signature)
    returns (bool)
  {
    require(to != address(0), 'CharityToken: refusing to allow zero address');
    require(!allowed[to], 'CharityToken: already allowed');

    allowed[to] = true;

    emit AllowTransfers(to);

    return true;
  }

  function disallow(address to, Signature calldata signature)
    external
    verifySignature(abi.encode(this.disallow.selector, to), signature)
    returns (bool)
  {
    require(allowed[to], 'CharityToken: not already allowed');

    allowed[to] = false;

    emit DisallowTransfers(to);

    return true;
  }

  function pause() external returns (bool) {
    require(!paused[msg.sender], 'CharityToken: account already paused');
    paused[msg.sender] = true;

    emit Paused(msg.sender);

    return true;
  }

  function resume() external returns (bool) {
    require(paused[msg.sender], 'CharityToken: account already paused');
    paused[msg.sender] = false;

    emit Resumed(msg.sender);

    return true;
  }

  function pauseAccount(address account, Signature calldata signature)
    external
    verifySignature(abi.encode(this.pauseAccount.selector, account), signature)
    returns (bool)
  {
    require(!adminPaused[account], 'CharityToken: account already paused');

    adminPaused[account] = true;

    emit AdminPaused(account);

    return true;
  }

  function resumeAccount(address account, Signature calldata signature)
    external
    verifySignature(abi.encode(this.resumeAccount.selector, account), signature)
    returns (bool)
  {
    require(adminPaused[account], 'CharityToken: account not paused');

    adminPaused[account] = false;

    emit AdminResumed(account);

    return true;
  }

  modifier whenNotPaused(address account) {
    require(!adminPaused[address(0)], 'CharityToken: contract is paused');
    require(!adminPaused[account], 'CharityToken: admin has paused account');
    require(!paused[account], 'CharityToken: account is paused');
    _;
  }

  receive() external payable {
    revert();
  }

  function recoverERC20(address token_) external returns (bool) {
    uint256 balance;
    IERC20 token__ = IERC20(token_);

    if (token_ == address(_token)) {
      balance = _token.balanceOf(address(this)) - totalSupply;
    } else {
      balance = token__.balanceOf(address(this));
    }

    return token__.transfer(serviceAccount, balance);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ISignable.sol';

abstract contract Signable is ISignable {
  struct Signature {
    bytes32 nonce;
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  bytes32 private _uniq;
  mapping(bytes32 => bool) private _signatures;

  constructor() {
    _uniq = keccak256(abi.encodePacked(block.timestamp, address(this)));
  }

  function uniq() public view virtual override(ISignable) returns (bytes32) {
    return _uniq;
  }

  modifier verifySignature(bytes memory message, Signature memory signature) {
    address _signer = this.signer();
    require(_signer != address(0), 'Signable: signer not initialised');

    bytes32 signatureHash = keccak256(abi.encode(signature));
    require(!_signatures[signatureHash], 'Signable: signature already used');

    require(
      _signer ==
        ecrecover(
          keccak256(abi.encode(_uniq, signature.nonce, msg.sender, message)),
          signature.v,
          signature.r,
          signature.s
        ),
      'Signable: invalid signature'
    );
    _signatures[signatureHash] = true;
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISignable {
  function uniq() external view returns (bytes32);

  function signer() external view returns (address);
}