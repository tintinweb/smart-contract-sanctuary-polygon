// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DEXTransactions is Ownable {
    mapping(address => bool) public dexAddress;
    address[] dexAddressList;

    function getAllDexAddresses() public view returns (address[] memory) {
        return dexAddressList;
    }

    function checkIfDEXAddress(address _dex) public view returns (bool) {
      return dexAddress[_dex];
    }

    function addDEXAddress(address _dex) public onlyOwner {
        dexAddress[_dex] = true;
        dexAddressList.push(_dex);
    }

    function removeDEXAddress(uint _index) public onlyOwner {
        require(_index < dexAddressList.length);
        dexAddress[dexAddressList[_index]] = false;
        dexAddressList[_index] = dexAddressList[dexAddressList.length - 1];
        dexAddressList.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Taxable.sol";
import "./DEXTransactions.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ERC20Mod is IERC20, IERC20Metadata, DEXTransactions, Taxable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    uint256 public maxPerTransaction = 25000000 * 10**decimals();
    uint256 public maxPerWallet = 50000000 * 10**decimals();

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function setMaxTransactionAmount(uint256 amount) public onlyOwner {
        require(amount <= totalSupply());
        maxPerTransaction = amount * 10**decimals();
    }

    function setMaxWalletAmount(uint256 amount) public onlyOwner {
        require(amount <= totalSupply());
        maxPerWallet = amount * 10**decimals();
    }

    function _distributeTax(uint taxAmount) internal {
        require(_taxEqualsHundred(), "Total tax percentage should be 100");
        for (uint i = 0; i < taxReceiverList.length; i++) {
            address account = taxReceiverList[i];
            _balances[account] += calculateFeeAmount(
                taxAmount,
                taxPercentages[account]
            );
        }
    }

    function _antiWhaleCheck(
        address to,
        address from,
        uint amount
    ) internal returns (bool) {
        require(
            amount <= maxPerTransaction,
            "Amount per transaction exceeded!"
        );
        require(
            _balances[dexAddress[to] ? from : to] + amount <= maxPerWallet,
            "Amount per wallet exceeded!"
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        if (
            (checkIfDEXAddress(from) || checkIfDEXAddress(to)) &&
            from != owner()
        ) {
            _antiWhaleCheck(to, from, amount);

            uint256 taxAmount = calculateTaxAmount(amount);
            uint256 transferAmount = calculateTransferAmount(amount, taxAmount);
            _balances[to] += transferAmount;
            _distributeTax(taxAmount);
        } else {
            _balances[to] += amount;
        }
        _balances[from] = fromBalance - amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Mod.sol";

contract MemeGPTToken is ERC20Mod {
    string private _name = "MemeGPT";
    string private constant _symbol = "MGPT";
    uint private constant _numTokens = 5_000_000_000;

    constructor() ERC20Mod(_name, _symbol) {
        _mint(msg.sender, _numTokens * 10**decimals());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Taxable is Ownable {
    uint8 public tax = 5; // 5%

    mapping(address => uint8) public taxPercentages;
    address[] taxReceiverList;

    event UpdateTax(uint8 oldPercentage, uint8 newPercentage);
    event UpdateReceiverTax(
        address receiver,
        uint8 oldPercentage,
        uint8 newPercentage
    );
    event AddTaxReceiver(address receiver, uint8 percentage);
    event RemoveTaxReceiver(address receiver);

    function getAllTaxReceivers() public view returns (address[] memory) {
        return taxReceiverList;
    }

    function addTaxReceiver(
        address _receiver,
        uint8 _percentage
    ) public onlyOwner {
        require(taxPercentages[_receiver] == 0);
        taxPercentages[_receiver] = _percentage;
        taxReceiverList.push(_receiver);

        emit AddTaxReceiver(_receiver, _percentage);
    }

    function updateReceiverTax(
        address _receiver,
        uint8 _percentage
    ) public onlyOwner {
        require(taxPercentages[_receiver] > 0);
        emit UpdateReceiverTax(
            _receiver,
            taxPercentages[_receiver],
            _percentage
        );
        taxPercentages[_receiver] = _percentage;
    }

    function removeTaxReceiver(uint _index) public onlyOwner {
        require(_index < taxReceiverList.length);
        emit RemoveTaxReceiver(taxReceiverList[_index]);
        taxPercentages[taxReceiverList[_index]] = 0;
        taxReceiverList[_index] = taxReceiverList[taxReceiverList.length - 1];
        taxReceiverList.pop();
    }

    function updateTax(uint8 _tax) public onlyOwner {
        emit UpdateTax(tax, _tax);
        tax = _tax;
    }

    function calculateFeeAmount(
        uint256 _amount,
        uint _fee
    ) public pure returns (uint256) {
        return (_amount * _fee) / 100;
    }

    function calculateTaxAmount(uint256 _amount) public view returns (uint256) {
        return calculateFeeAmount(_amount, tax);
    }

    function calculateTransferAmount(
        uint256 _amount,
        uint _tax
    ) public pure returns (uint256) {
        return _amount - _tax;
    }

    function _taxEqualsHundred() internal view returns (bool) {
        uint sum = 0;
        for (uint i = 0; i < taxReceiverList.length; i++) {
            address account = taxReceiverList[i];
            sum += taxPercentages[account];
        }

        return (sum == 100);
    }
}