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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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

/*
    Copyright 2017-2019 Phillip A. Elsasser

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @title Math function library with overflow protection inspired by Open Zeppelin
library MathLib {

    int256 constant INT256_MIN = int256((uint256(1) << 255));
    int256 constant INT256_MAX = int256(~((uint256(1) << 255)));

    function multiply(uint256 a, uint256 b) pure internal returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b,  "MathLib: multiplication overflow");

        return c;
    }

    function divideFractional(
        uint256 a,
        uint256 numerator,
        uint256 denominator
    ) pure internal returns (uint256)
    {
        return multiply(a, numerator) / denominator;
    }

    function subtract(uint256 a, uint256 b) pure internal returns (uint256) {
        require(b <= a, "MathLib: subtraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "MathLib: addition overflow");
        return c;
    }

    /// @notice determines the amount of needed collateral for a given position (qty and price)
    /// @param priceFloor lowest price the contract is allowed to trade before expiration
    /// @param priceCap highest price the contract is allowed to trade before expiration
    /// @param qtyMultiplier multiplier for qty from base units
    /// @param longQty qty to redeem
    /// @param shortQty qty to redeem
    /// @param price of the trade
    function calculateCollateralToReturn(
        uint priceFloor,
        uint priceCap,
        uint qtyMultiplier,
        uint longQty,
        uint shortQty,
        uint price
    ) pure internal returns (uint)
    {
        uint neededCollateral = 0;
        uint maxLoss;
        if (longQty > 0) {   // calculate max loss from entry price to floor
            if (price <= priceFloor) {
                maxLoss = 0;
            } else {
                maxLoss = subtract(price, priceFloor);
            }
            neededCollateral = multiply(multiply(maxLoss, longQty),  qtyMultiplier);
        }

        if (shortQty > 0) {  // calculate max loss from entry price to ceiling;
            if (price >= priceCap) {
                maxLoss = 0;
            } else {
                maxLoss = subtract(priceCap, price);
            }
            neededCollateral = add(neededCollateral, multiply(multiply(maxLoss, shortQty),  qtyMultiplier));
        }
        return neededCollateral;
    }

    /// @notice determines the amount of needed collateral for minting a long and short position token
    function calculateTotalCollateral(
        uint priceFloor,
        uint priceCap,
        uint qtyMultiplier
    ) pure internal returns (uint)
    {
        return multiply(subtract(priceCap, priceFloor), qtyMultiplier);
    }

    /// @notice calculates the fee in terms of base units of the collateral token per unit pair minted.
    function calculateFeePerUnit(
        uint priceFloor,
        uint priceCap,
        uint qtyMultiplier,
        uint feeInBasisPoints
    ) pure internal returns (uint)
    {
        uint midPrice = add(priceCap, priceFloor) / 2;
        return multiply(multiply(midPrice, qtyMultiplier), feeInBasisPoints) / 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library StringLib {

    /// @notice converts bytes32 into a string.
    /// @param bytesToConvert bytes32 array to convert
    function bytes32ToString(bytes32 bytesToConvert) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = bytesToConvert[i];
        }
        return string(bytesArray);
    }
}

/*
    Copyright 2017-2019 Phillip A. Elsasser

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./libraries/MathLib.sol";
import "./libraries/StringLib.sol";
import "./tokens/PositionToken.sol";


/// @title MarketContract base contract implement all needed functionality for trading.
/// @notice this is the abstract base contract that all contracts should inherit from to
/// implement different oracle solutions.
/// @author Phil Elsasser <[email protected]>
contract MarketContract is Ownable {
    using StringLib for *;

    string public CONTRACT_NAME;
    address public COLLATERAL_TOKEN_ADDRESS;
    address public COLLATERAL_POOL_ADDRESS;
    uint public PRICE_CAP;
    uint public PRICE_FLOOR;
    uint public PRICE_DECIMAL_PLACES;   // how to convert the pricing from decimal format (if valid) to integer
    uint public QTY_MULTIPLIER;         // multiplier corresponding to the value of 1 increment in price to token base units
    uint public COLLATERAL_PER_UNIT;    // required collateral amount for the full range of outcome tokens
    uint public COLLATERAL_TOKEN_FEE_PER_UNIT;
    uint public MKT_TOKEN_FEE_PER_UNIT;
    uint public EXPIRATION;
    uint public SETTLEMENT_DELAY = 1 days;
    address public LONG_POSITION_TOKEN;
    address public SHORT_POSITION_TOKEN;

    // state variables
    int public lastGeostats;
    uint public lastPrice;
    uint public settlementPrice;
    uint public settlementTimeStamp;
    bool public isSettled = false;

    // events
    event UpdatedLastPrice(uint256 price);
    event ContractSettled(uint settlePrice);

    /// @param contractNames bytes32 array of names
    ///     contractName            name of the market contract
    ///     longTokenSymbol         symbol for the long token
    ///     shortTokenSymbol        symbol for the short token
    /// @param baseAddresses array of 2 addresses needed for our contract including:
    ///     ownerAddress                    address of the owner of these contracts.
    ///     collateralTokenAddress          address of the ERC20 token that will be used for collateral and pricing
    ///     collateralPoolAddress           address of our collateral pool contract
    /// @param contractSpecs array of unsigned integers including:
    ///     floorPrice          minimum tradeable price of this contract, contract enters settlement if breached
    ///     capPrice            maximum tradeable price of this contract, contract enters settlement if breached
    ///     priceDecimalPlaces  number of decimal places to convert our queried price from a floating point to
    ///                         an integer
    ///     qtyMultiplier       multiply traded qty by this value from base units of collateral token.
    ///     feeInBasisPoints    fee amount in basis points (Collateral token denominated) for minting.
    ///     mktFeeInBasisPoints fee amount in basis points (MKT denominated) for minting.
    ///     expirationTimeStamp seconds from epoch that this contract expires and enters settlement
    constructor(
        bytes32[3] memory contractNames,
        address[3] memory baseAddresses,
        uint[7] memory contractSpecs
    ) 
    {
        PRICE_FLOOR = contractSpecs[0];
        PRICE_CAP = contractSpecs[1];
        require(PRICE_CAP > PRICE_FLOOR, "PRICE_CAP must be greater than PRICE_FLOOR");

        PRICE_DECIMAL_PLACES = contractSpecs[2];
        QTY_MULTIPLIER = contractSpecs[3];
        EXPIRATION = contractSpecs[6];
        require(EXPIRATION > block.timestamp, "EXPIRATION must be in the future");
        require(QTY_MULTIPLIER != 0,"QTY_MULTIPLIER cannot be 0");

        COLLATERAL_TOKEN_ADDRESS = baseAddresses[1];
        COLLATERAL_POOL_ADDRESS = baseAddresses[2];
        COLLATERAL_PER_UNIT = MathLib.calculateTotalCollateral(PRICE_FLOOR, PRICE_CAP, QTY_MULTIPLIER);
        COLLATERAL_TOKEN_FEE_PER_UNIT = MathLib.calculateFeePerUnit(
            PRICE_FLOOR,
            PRICE_CAP,
            QTY_MULTIPLIER,
            contractSpecs[4]
        );
        MKT_TOKEN_FEE_PER_UNIT = MathLib.calculateFeePerUnit(
            PRICE_FLOOR,
            PRICE_CAP,
            QTY_MULTIPLIER,
            contractSpecs[5]
        );

        // create long and short tokens
        CONTRACT_NAME = contractNames[0].bytes32ToString();
        PositionToken longPosToken = new PositionToken(
            "MARKET Protocol Long Position Token",
            contractNames[1].bytes32ToString(),
            uint8(PositionToken.MarketSide.Long)
        );
        PositionToken shortPosToken = new PositionToken(
            "MARKET Protocol Short Position Token",
            contractNames[2].bytes32ToString(),
            uint8(PositionToken.MarketSide.Short)
        );

        LONG_POSITION_TOKEN = address(longPosToken);
        SHORT_POSITION_TOKEN = address(shortPosToken);

        transferOwnership(baseAddresses[0]);
    }

    /*
    // EXTERNAL - onlyCollateralPool METHODS
    */

    /// @notice called only by our collateral pool to create long and short position tokens
    /// @param qtyToMint    qty in base units of how many short and long tokens to mint
    /// @param minter       address of minter to receive tokens
    function mintPositionTokens(
        uint256 qtyToMint,
        address minter
    ) external onlyCollateralPool
    {
        // mint and distribute short and long position tokens to our caller
        PositionToken(LONG_POSITION_TOKEN).mintAndSendToken(qtyToMint, minter);
        PositionToken(SHORT_POSITION_TOKEN).mintAndSendToken(qtyToMint, minter);
    }

    /// @notice called only by our collateral pool to redeem long position tokens
    /// @param qtyToRedeem  qty in base units of how many tokens to redeem
    /// @param redeemer     address of person redeeming tokens
    function redeemLongToken(
        uint256 qtyToRedeem,
        address redeemer
    ) external onlyCollateralPool
    {
        // mint and distribute short and long position tokens to our caller
        PositionToken(LONG_POSITION_TOKEN).redeemToken(qtyToRedeem, redeemer);
    }

    /// @notice called only by our collateral pool to redeem short position tokens
    /// @param qtyToRedeem  qty in base units of how many tokens to redeem
    /// @param redeemer     address of person redeeming tokens
    function redeemShortToken(
        uint256 qtyToRedeem,
        address redeemer
    ) external onlyCollateralPool
    {
        // mint and distribute short and long position tokens to our caller
        PositionToken(SHORT_POSITION_TOKEN).redeemToken(qtyToRedeem, redeemer);
    }

    /*
    // Public METHODS
    */

    /// @notice checks to see if a contract is settled, and that the settlement delay has passed
    function isPostSettlementDelay() public view returns (bool) {
        return isSettled && (block.timestamp >= (settlementTimeStamp + SETTLEMENT_DELAY));
    }

    /*
    // PRIVATE METHODS
    */

    /// @dev checks our last query price to see if our contract should enter settlement due to it being past our
    //  expiration date or outside of our tradeable ranges.
    function checkSettlement() internal {
        require(!isSettled, "Contract is already settled"); // already settled.

        uint newSettlementPrice;
        if (block.timestamp > EXPIRATION) {  // note: miners can cheat this by small increments of time (minutes, not hours)
            isSettled = true;                   // time based expiration has occurred.
            newSettlementPrice = lastPrice;
        } else if (lastPrice >= PRICE_CAP) {    // price is greater or equal to our cap, settle to CAP price
            isSettled = true;
            newSettlementPrice = PRICE_CAP;
        } else if (lastPrice <= PRICE_FLOOR) {  // price is lesser or equal to our floor, settle to FLOOR price
            isSettled = true;
            newSettlementPrice = PRICE_FLOOR;
        }

        if (isSettled) {
            settleContract(newSettlementPrice);
        }
    }

    /// @dev records our final settlement price and fires needed events.
    /// @param finalSettlementPrice final query price at time of settlement
    function settleContract(uint finalSettlementPrice) internal {
        settlementTimeStamp = block.timestamp;
        settlementPrice = finalSettlementPrice;
        emit ContractSettled(finalSettlementPrice);
    }

    /// @notice only able to be called directly by our collateral pool which controls the position tokens
    /// for this contract!
    modifier onlyCollateralPool {
        require(msg.sender == COLLATERAL_POOL_ADDRESS, "Only callable from the collateral pool");
        _;
    }

}

/*
    Copyright 2017-2019 Phillip A. Elsasser

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title Position Token
/// @notice A token that represents a claim to a collateral pool and a short or long position.
/// The collateral pool acts as the owner of this contract and controls minting and redemption of these
/// tokens based on locked collateral in the pool.
/// NOTE: We eventually can move all of this logic into a library to avoid deploying all of the logic
/// every time a new market contract is deployed.
/// @author Phil Elsasser <[email protected]>
contract PositionToken is ERC20, Ownable {

    string _name;
    string _symbol;
    uint8 _decimals;

    MarketSide public MARKET_SIDE; // 0 = Long, 1 = Short
    enum MarketSide { Long, Short}

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 marketSide
    ) ERC20(tokenName, tokenSymbol)
    {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = 5;
        MARKET_SIDE = MarketSide(marketSide);
    }

    /// @dev Called by our MarketContract (owner) to create a long or short position token. These tokens are minted,
    /// and then transferred to our recipient who is the party who is minting these tokens.  The collateral pool
    /// is the only caller (acts as the owner) because collateral must be deposited / locked prior to minting of new
    /// position tokens
    /// @param qtyToMint quantity of position tokens to mint (in base units)
    /// @param recipient the person minting and receiving these position tokens.
    function mintAndSendToken(
        uint256 qtyToMint,
        address recipient
    ) external onlyOwner
    {
        _mint(recipient, qtyToMint);
    }

    /// @dev Called by our MarketContract (owner) when redemption occurs.  This means that either a single user is redeeming
    /// both short and long tokens in order to claim their collateral, or the contract has settled, and only a single
    /// side of the tokens are needed to redeem (handled by the collateral pool)
    /// @param qtyToRedeem quantity of tokens to burn (remove from supply / circulation)
    /// @param redeemer the person redeeming these tokens (who are we taking the balance from)
    function redeemToken(
        uint256 qtyToRedeem,
        address redeemer
    ) external onlyOwner
    {
        _burn(redeemer, qtyToRedeem);
    }
}