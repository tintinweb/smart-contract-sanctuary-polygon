// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./BananaToken.sol";
import "./Dai.sol";

// Banana Dao Contract
contract BananaDao {
  uint public totalNodes;
  address [] public bananaNodesAddresses;

  BananaToken public bananaAddress;
  Dai public daiAddress;
  address private owner;
  uint public bananaInterestRatePercent;

  struct Account {
    bool exists;
    uint nanoCount;
    uint miniCount;
    uint kiloCount;
    uint megaCount;
    uint gigaCount;
    uint interestAccumulated;
  }

  mapping(address => Account) public accounts;

  // 0.5%, 0.6%, 0.7%, 0.8%, 1% /day
  uint [] public nodeMultiplers = [1, 3, 7, 16, 100];

  constructor(BananaToken _bananaAddress, Dai _daiAddress) {
    owner = msg.sender;
    bananaAddress = _bananaAddress;
    daiAddress = _daiAddress;
    bananaInterestRatePercent = 1 * 100;
  }

  function setupAccountForMigration(address _address, uint _nanoCount, uint _miniCount, uint _kiloCount, uint _megaCount, uint _gigaCount, uint _interestAccumulated) public {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'Only owner can create a node.');

    if(!accounts[_address].exists){
      Account memory account = Account(true, _nanoCount, _miniCount, _kiloCount, _megaCount, _gigaCount, _interestAccumulated);
      bananaNodesAddresses.push(_address);
      totalNodes += _nanoCount + _miniCount + _kiloCount + _megaCount + _gigaCount;
      accounts[_address] = account;
    }
  }

  // totalNodes getter
  function getTotalNodes() public view returns(uint) {
    return totalNodes;
  }

  // bananaNodesAddresses getters
  function getAccountsLength() public view returns(uint) {
    return bananaNodesAddresses.length;
  }

  function getAccountsAddressForIndex(uint _index) public view returns(address) {
    return bananaNodesAddresses[_index];
  }

  // accounts getter
  function getAccount(address _address) public view returns(uint, uint, uint, uint, uint, uint) {
    Account memory acc = accounts[_address];
    return(acc.nanoCount, acc.miniCount, acc.kiloCount, acc.megaCount, acc.gigaCount, acc.interestAccumulated);
  }

  function mintNode(address _address, uint _bananaAmount, uint _daiAmount, uint _nodeType) public {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == _address, 'Only user can create a node.');
    require(_nodeType >= 0 && _nodeType <= 4, 'Invalid node type');

    Account memory account;

    if(accounts[_address].exists){
      account = accounts[_address];
    }
    else{
      account = Account(true, 0, 0, 0, 0, 0, 0);
      bananaNodesAddresses.push(_address);
    }

    if(_nodeType == 0){
      require(_bananaAmount >= 100 * 10 ** 18, 'You must provide at least 100 BANANA for the LP token');
      require(_daiAmount >= 100 * 10 ** 18, 'You must provide at least 100 DAI for the LP token');
      account.nanoCount++;
    }
    else if(_nodeType == 1){
      require(_bananaAmount >= 250 * 10 ** 18, 'You must provide at least 250 BANANA for the LP token');
      require(_daiAmount >= 250 * 10 ** 18, 'You must provide at least 250 DAI for the LP token');
      account.miniCount++;
    }
    else if(_nodeType == 2){
      require(_bananaAmount >= 500 * 10 ** 18, 'You must provide at least 500 BANANA for the LP token');
      require(_daiAmount >= 500 * 10 ** 18, 'You must provide at least 500 DAI for the LP token');
      account.kiloCount++;
    }
    else if(_nodeType == 3){
      require(_bananaAmount >= 1000 * 10 ** 18, 'You must provide at least 1000 BANANA for the LP token');
      require(_daiAmount >= 1000 * 10 ** 18, 'You must provide at least 1000 DAI for the LP token');
      account.megaCount++;
    }
    else if(_nodeType == 4){
      require(_bananaAmount >= 5000 * 10 ** 18, 'You must provide at least 5000 BANANA for the LP token');
      require(_daiAmount >= 5000 * 10 ** 18, 'You must provide at least 5000 DAI for the LP token');
      account.gigaCount++;
    }
    totalNodes++;
    accounts[_address] = account;

    bananaAddress.transferFrom(_address, address(this), _bananaAmount);
    daiAddress.transferFrom(_address, address(this), _daiAmount);
  }

  function widthrawInterest(address _to) public {
    require(_to != address(0), "_to is address 0");
    require(msg.sender == _to, 'Only user can widthraw its own funds.');
    require(accounts[_to].interestAccumulated > 0, 'Interest accumulated must be greater than zero.');

    uint amount = accounts[_to].interestAccumulated;
    accounts[_to].interestAccumulated = 0;

    bananaAddress.transfer(_to, amount);
  }

  // _indexTo not included
  function payInterest(uint _indexFrom, uint _indexTo) public {
    require(msg.sender == owner, 'You must be the owner to run this.');

    uint i;
    for(i = _indexFrom; i < _indexTo; i++){
      address a = bananaNodesAddresses[i];
      Account memory acc = accounts[a];
      uint interestAccumulated;

      // add bananaInterestRatePercent/100 BANANA per node that address has
      interestAccumulated = (acc.nanoCount * nodeMultiplers[0] * bananaInterestRatePercent * 10 ** 18) / 100;
      interestAccumulated += (acc.miniCount * nodeMultiplers[1] * bananaInterestRatePercent * 10 ** 18) / 100;
      interestAccumulated += (acc.kiloCount * nodeMultiplers[2] * bananaInterestRatePercent * 10 ** 18) / 100;
      interestAccumulated += (acc.megaCount * nodeMultiplers[3] * bananaInterestRatePercent * 10 ** 18) / 100;
      interestAccumulated += (acc.gigaCount * nodeMultiplers[4] * bananaInterestRatePercent * 10 ** 18) / 100;

      acc.interestAccumulated += interestAccumulated;

      accounts[a] = acc;
    }
  }

  // runs daily at 2AM
  function balancePool() public {
    require(msg.sender == owner, 'You must be the owner to run this.');

    uint poolAmount = bananaAddress.balanceOf(address(this)) / 10 ** 18;
    uint runwayInDays = poolAmount/((totalNodes * bananaInterestRatePercent * nodeMultiplers[4]) / 100);
    if(runwayInDays > 900){
      uint newTotalTokens = (365 * bananaInterestRatePercent * totalNodes * nodeMultiplers[4]) / 100; // 365 is the desired runway
      uint amountToBurn = poolAmount - newTotalTokens;
      bananaAddress.burn(amountToBurn * 10 ** 18);
    }
    else if(runwayInDays < 360){
      uint newTotalTokens = (365 * bananaInterestRatePercent * totalNodes * nodeMultiplers[4]) / 100; // 365 is the desired runway
      uint amountToMint = newTotalTokens - poolAmount;
      bananaAddress.mint(amountToMint * 10 ** 18);
    }
  }

  function changeInterestRate(uint _newRate) public {
    require(msg.sender == owner, 'You must be the owner to run this.');
    bananaInterestRatePercent = _newRate;
  }

  function transferBanana(address _address, uint amount) public {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'You must be the owner to run this.');
    bananaAddress.transfer(_address, amount);
  }

  function transferDai(address _address, uint amount) public {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'You must be the owner to run this.');
    daiAddress.transfer(_address, amount);
  }

  function awardNode(address _address, uint _nodeType) public {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'You must be the owner to run this.');

    Account memory account;

    if(accounts[_address].exists){
      account = accounts[_address];
    }
    else{
      account = Account(true, 0, 0, 0, 0, 0, 0);
      bananaNodesAddresses.push(_address);
    }

    if(_nodeType == 0){
      account.nanoCount++;
    }
    else if(_nodeType == 1){
      account.miniCount++;
    }
    else if(_nodeType == 2){
      account.kiloCount++;
    }
    else if(_nodeType == 3){
      account.megaCount++;
    }
    else if(_nodeType == 4){
      account.gigaCount++;
    }
    totalNodes++;
    accounts[_address] = account;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";

contract Dai is ERC20 {
  constructor() ERC20('Mock DAI token', 'mDAI') {
    _mint(msg.sender, 1000000 * 10 ** 18);
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
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";

contract BananaToken is ERC20 {
  address private owner;
  address private bananaDao;
  uint private limit = 100000000 * 10 ** 18;

  constructor() ERC20('Banana Token', 'BANANA') {
    owner = msg.sender;

    _mint(msg.sender, 2000000 * 10 ** 18);
  }

  function setBananaDaoContract(address _bananaDao) public{
    require(msg.sender == owner, 'You must be the owner to run this.');
    bananaDao = _bananaDao;
  }

  function setTranferLimit(uint _limit) public{
    require(msg.sender == owner, 'You must be the owner to run this.');
    limit = _limit;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override(ERC20) returns (bool) {
    require(amount <= limit, 'This transfer exceeds the allowed limit!');
    return super.transferFrom(sender, recipient, amount);
  }

  function transfer(address recipient, uint256 amount) public override(ERC20) returns (bool) {
    require(amount <= limit, 'This transfer exceeds the allowed limit!');
    return super.transfer(recipient, amount);
  }

  function mint(uint256 _amount) public {
    require(msg.sender == bananaDao || msg.sender == owner, 'Can only be used by BananaDao or owner.');
    _mint(msg.sender, _amount);
  }

  function burn(uint256 _amount) public {
    require(msg.sender == bananaDao || msg.sender == owner, 'Can only be used by BananaDao or owner.');
    _burn(msg.sender, _amount);
  }
}