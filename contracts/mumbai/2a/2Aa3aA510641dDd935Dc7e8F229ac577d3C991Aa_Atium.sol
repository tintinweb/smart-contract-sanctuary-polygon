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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./AtiumReg.sol";
import "./AtiumToken.sol";
import "./AtiumPlan.sol";

error Atium_NotAmount();
error Atium_NotReceiverId();
error Atium_SavingsGoal_Not_Hit();
error Atium_NoWithdrawal();
error Atium_TransactionFailed();
error Atium_Cancelled();
error Atium_SavingsGoal_Exceeded(uint256 goal, uint256 rem);

contract Atium is AtiumPlan {

    mapping(uint256 => bool) private savingsCancelled;
    mapping(uint256 => bool) private allowanceCancelled;
    mapping(uint256 => bool) private trustfundCancelled;
    mapping(uint256 => bool) private giftCancelled;

    mapping(uint256 => uint256) private allowanceBalance;
    mapping(uint256 => uint256) private trustfundBalance;

    event Withdrawn(address indexed receiver, uint256 atium, uint256 amount);
    /// for atium values -- SAVINGS = 0, ALLOWANCE = 1, TRUSTFUND = 2. GIFT = 3


    ///////////////////////////////////////////////////////
    ///////////////// DEPOSIT FUNCTIONS ///////////////////
    ///////////////////////////////////////////////////////

    function save(uint256 _id, uint256 _amount) external payable inSavings(_id) {
        if (_id == 0 || _amount == 0) {
            revert Atium_ZeroInput();
        }
        if (msg.value != _amount) {
            revert Atium_NotAmount();
        }
        if (_amount + savingsById[_id].amount > savingsById[_id].goal) {
            revert Atium_SavingsGoal_Exceeded({
                goal: savingsById[_id].goal,
                rem: savingsById[_id].goal - savingsById[_id].amount
            });
        }
        savingsById[_id].amount += _amount;

        SavingsList memory s = SavingsList ({
            id: _id,
            user: msg.sender,
            amount: savingsById[_id].amount,
            goal: savingsById[_id].goal,
            time: savingsById[_id].time
        });

        savingsById[_id] = s;

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Savings(
            _id, 
            msg.sender, 
            savingsById[_id].amount,
            savingsById[_id].goal, 
            savingsById[_id].time
            );
    }

    function allowance(uint256 _id, uint256 _amount) external payable inAllowance(_id) {
        if (_id == 0 || _amount == 0) {
            revert Atium_ZeroInput();
        }
        if (msg.value != _amount) {
            revert Atium_NotAmount();
        }
        allowanceById[_id].deposit += _amount;
        allowanceBalance[_id] += _amount;

        AllowanceList memory al = AllowanceList ({
            id: _id,
            sender: msg.sender,
            receiver: allowanceById[_id].receiver,
            deposit: allowanceById[_id].deposit,
            startDate: allowanceById[_id].startDate,
            withdrawalAmount: allowanceById[_id].withdrawalAmount,
            withdrawalInterval: allowanceById[_id].withdrawalInterval
        });

        allowanceById[_id] = al;

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Allowance(
        _id, 
        msg.sender,
        allowanceById[_id].receiver,
        allowanceById[_id].deposit,
        allowanceById[_id].startDate,
        allowanceById[_id].withdrawalAmount,
        allowanceById[_id].withdrawalInterval
        );
    }

    function trustfund(uint256 _id, uint256 _amount) external payable inTrustfund(_id) {
        if (_id == 0 || _amount == 0) {
            revert Atium_ZeroInput();
        }
        if (msg.value != _amount) {
            revert Atium_NotAmount();
        }
        trustfundById[_id].amount += _amount;
        trustfundBalance[_id] += _amount;

        TrustFundList memory t = TrustFundList ({
            id: _id,
            sender: msg.sender,
            receiver: trustfundById[_id].receiver,
            amount: trustfundById[_id].amount,
            startDate: trustfundById[_id].startDate,
            withdrawalAmount: trustfundById[_id].withdrawalAmount,
            withdrawalInterval: trustfundById[_id].withdrawalInterval
        });

        trustfundById[_id] = t;

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Trustfund(
        _id, 
        msg.sender,
        trustfundById[_id].receiver,
        trustfundById[_id].amount,
        trustfundById[_id].startDate,
        trustfundById[_id].withdrawalAmount,
        trustfundById[_id].withdrawalInterval
        );
    }

    function gift(uint256 _id, uint256 _amount) external payable inGift(_id) {
        if (_id == 0 || _amount == 0) {
            revert Atium_ZeroInput();
        }
        if (msg.value != _amount) {
            revert Atium_NotAmount();
        }
        giftById[_id].amount += _amount;

        GiftList memory g = GiftList ({
            id: _id,
            sender: msg.sender,
            receiver: giftById[_id].receiver,
            date: giftById[_id].date,
            amount: giftById[_id].amount
        });

        giftById[_id] = g;

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Gift(
            _id, 
            msg.sender, 
            giftById[_id].receiver,
            giftById[_id].amount,
            giftById[_id].date
            );
    }


    ///////////////////////////////////////////////////////////
    //////////// (RECEIVER) WITHDRAWAL FUNCTIONS //////////////
    ///////////////////////////////////////////////////////////

    function w_save(uint256 _id) external inSavings(_id) {
        if (savingsById[_id].amount < savingsById[_id].goal || block.timestamp < savingsById[_id].time) {
            revert Atium_SavingsGoal_Not_Hit();
        }
        if (savingsCancelled[_id]) {
            revert Atium_Cancelled();
        }
        savingsCancelled[_id] = true;

        (bool sent, ) = payable(msg.sender).call{value: savingsById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Withdrawn(msg.sender, 0, savingsById[_id].amount);
    }

    function w_allowance(uint256 _id) external rAllowance(_id) {
        uint256 witAmount;
        
        if (allowanceBalance[_id] == 0) {
            revert Atium_NoWithdrawal();
        }

        uint256 a = block.timestamp;
        uint256 b = allowanceDate[_id];
        uint256 c = allowanceById[_id].withdrawalInterval;

        if ((a - b) < c) {
            revert Atium_OnlyFutureDate();
        }

        uint256 d = (a - b) / c;
        allowanceDate[_id] += (d * c);
        
        if (allowanceBalance[_id] < allowanceById[_id].withdrawalAmount) {
            witAmount = allowanceBalance[_id];
        }

        if (allowanceBalance[_id] >= allowanceById[_id].withdrawalAmount) {
            witAmount = d * allowanceById[_id].withdrawalAmount;
        }

        allowanceBalance[_id] -= witAmount;
        (bool sent, ) = payable(msg.sender).call{value: witAmount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Withdrawn(msg.sender, 1, witAmount);
    }

    function w_trustfund(uint256 _id) external rTrustfund(_id) {
        uint256 witAmount;

        if (trustfundBalance[_id] == 0) {
            revert Atium_NoWithdrawal();
        }

        uint256 a = trustfundById[_id].startDate;
        uint256 b = trustfundDate[_id];
        uint256 c = trustfundById[_id].withdrawalInterval;

        uint256 d = (a - b) / c;
        trustfundDate[_id] += (d * c);

        if (trustfundBalance[_id] < trustfundById[_id].withdrawalAmount) {
            witAmount = trustfundBalance[_id];
        }

        if (trustfundBalance[_id] >= trustfundById[_id].withdrawalAmount) {
            witAmount = d * trustfundById[_id].withdrawalAmount;
        }

        trustfundBalance[_id] -= witAmount;
        (bool sent, ) = payable(msg.sender).call{value: witAmount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Withdrawn(msg.sender, 2, witAmount);
    }

    function w_gift(uint256 _id) external rGift(_id) {
        giftCancelled[_id] = true;
        (bool sent, ) = payable(msg.sender).call{value: giftById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Withdrawn(msg.sender, 3, giftById[_id].amount);
    }


    ///////////////////////////////////////////////////////////
    ///////////////// CANCEL PLANS FUNCTIONS //////////////////
    ///////////////////////////////////////////////////////////

    function cancelSavings(uint256 _id) external inSavings(_id) {
        if (savingsCancelled[_id]) {
            revert Atium_Cancelled();
        }
        savingsCancelled[_id] = true;

        (bool sent, ) = payable(msg.sender).call{value: savingsById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Withdrawn(msg.sender, 0, savingsById[_id].amount);
    }

    function cancelAllowance(uint256 _id) external inAllowance(_id) {
        if (allowanceCancelled[_id]) {
            revert Atium_Cancelled();
        }
        allowanceCancelled[_id] = true;
        
        (bool sent, ) = payable(msg.sender).call{value: allowanceBalance[_id]}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Withdrawn(msg.sender, 1, allowanceById[_id].deposit);
    }

    function cancelTrustfund(uint256 _id) external inTrustfund(_id) {
        if (trustfundCancelled[_id]) {
            revert Atium_Cancelled();
        }
        trustfundCancelled[_id] = true;
        
        (bool sent, ) = payable(msg.sender).call{value: trustfundBalance[_id]}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }    

        emit Withdrawn(msg.sender, 2, trustfundById[_id].amount);
    }

    function cancelGift(uint256 _id) external inGift(_id) {
        if (giftCancelled[_id]) {
            revert Atium_Cancelled();
        }
        giftCancelled[_id] = true;
        
        (bool sent, ) = payable(msg.sender).call{value: giftById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }     

        emit Withdrawn(msg.sender, 2, giftById[_id].amount);
    }
    
    ///////////////////////////////////////////////////////
    ///////////////// GETTERS FUNCTIONS  //////////////////
    ///////////////////////////////////////////////////////

    function getSavingsBalance(uint256 _id) public view returns (uint256) {
        return savingsById[_id].amount;
    }

    function getAllowanceBalance(uint256 _id) public view returns (uint256) {
        return allowanceBalance[_id];
    }

    function getTrustfundBalance(uint256 _id) public view returns (uint256) {
        return trustfundBalance[_id];
    }

    function getGiftBalance(uint256 _id) public view returns (uint256) {
        return giftById[_id].amount;
        
    }

    ///////////////////////////////////////////////////////
    ///////////////// RECEIVER MODIFIERS //////////////////
    ///////////////////////////////////////////////////////

    modifier rAllowance(uint256 _id) {
        if (allowanceById[_id].receiver != msg.sender) {
            revert Atium_NotReceiverId();
        }
        _;
    }

    modifier rTrustfund(uint256 _id) {
        if (trustfundById[_id].receiver != msg.sender) {
            revert Atium_NotReceiverId();
        }
        _;
    }

    modifier rGift(uint256 _id) {
        if (giftById[_id].receiver != msg.sender) {
            revert Atium_NotReceiverId();
        }
        _;
    }


    receive() payable external {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";

error Atium_NotOwnerId();
error Atium_OnlyFutureDate();
error Atium_ZeroInput();

contract AtiumPlan {
    using Counters for Counters.Counter;

    Counters.Counter private _atiumId;
    Counters.Counter private _savingsId;
    Counters.Counter private _allowanceId;
    Counters.Counter private _trustfundId;
    Counters.Counter private _giftId;

    mapping(uint256 => AtiumList) internal atiumById;
    mapping(uint256 => SavingsList) internal savingsById;
    mapping(uint256 => AllowanceList) internal allowanceById;
    mapping(uint256 => TrustFundList) internal trustfundById;
    mapping(uint256 => GiftList) internal giftById;

    mapping(uint256 => uint256) internal allowanceDate;
    mapping(uint256 => uint256) internal trustfundDate;

    enum Select {SAVINGS, ALLOWANCE, TRUSTFUND, GIFT}
    //SAVINGS = 0, ALLOWANCE = 1, TRUSTFUND = 2. GIFT = 3

    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event Savings(uint256 id, address indexed user, uint256 deposit, uint256 goal, uint256 time);

    event Allowance(
        uint256 id, 
        address indexed user,
        address indexed receiver, 
        uint256 deposit,
        uint256 startDate,
        uint256 withdrawal,
        uint256 interval
        );

    event Trustfund(
        uint256 id, 
        address indexed user,
        address indexed receiver, 
        uint256 deposit,
        uint256 startDate,
        uint256 withdrawal,
        uint256 interval
        );

    event Gift(
        uint256 id, 
        address indexed user, 
        address indexed receiver, 
        uint256 deposit,
        uint256 date
        );

    struct AtiumList {
        uint256 id;
        address user;
        Select select;
    }

    struct SavingsList {
        uint256 id;
        address user;
        uint256 amount;
        uint256 goal;
        uint256 time;
    }

    struct AllowanceList {
        uint256 id;
        address sender;
        address receiver;
        uint256 deposit;
        uint256 startDate;
        uint256 withdrawalAmount;
        uint256 withdrawalInterval;
    }

    struct TrustFundList {
        uint256 id;
        address sender;
        address receiver;
        uint256 amount;
        uint256 startDate;
        uint256 withdrawalAmount;
        uint256 withdrawalInterval;
    }

    struct GiftList {
        uint256 id;
        address sender;
        address receiver;
        uint256 date;
        uint256 amount;
    }

    /////////////////////////////////////////////////////////
    /////////////////  ATIUM PLANS FUNCTIONS  ///////////////
    /////////////////////////////////////////////////////////

    function savingsPlanGoal(uint256 _goal) external {
        if (_goal == 0) {
            revert Atium_ZeroInput();
        }
        _atiumId.increment();
        _savingsId.increment();

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.SAVINGS
        });

        SavingsList memory s = SavingsList ({
            id: _savingsId.current(),
            user: msg.sender,
            amount: savingsById[_savingsId.current()].amount,
            goal: _goal,
            time: 0
        });

        atiumById[_atiumId.current()] = a;
        savingsById[_savingsId.current()] = s;

        emit Savings(
            _savingsId.current(), 
            msg.sender, 
            savingsById[_savingsId.current()].amount,
            _goal, 
            0
            );
    }

    function savingsPlanTime(uint256 _time) external {
        if (_time == 0) {
            revert Atium_ZeroInput();
        }
        _atiumId.increment();
        _savingsId.increment();
        _time += block.timestamp;

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.SAVINGS
        });

        SavingsList memory s = SavingsList ({
            id: _savingsId.current(),
            user: msg.sender,
            amount: savingsById[_savingsId.current()].amount,
            goal: 0,
            time: _time
        });

        atiumById[_atiumId.current()] = a;
        savingsById[_savingsId.current()] = s;

        emit Savings(
            _savingsId.current(), 
            msg.sender, 
            savingsById[_savingsId.current()].amount,
            0, 
            _time
            );
    }

    function allowancePlan(
        address _receiver, 
        uint256 _startDate, 
        uint256 _amount, 
        uint256 _interval
        ) external {
        
        if (_receiver == address(0) || _startDate == 0 || _amount == 0 || _interval == 0) {
            revert Atium_ZeroInput();
        }

        _atiumId.increment();
        _allowanceId.increment();
        _startDate += block.timestamp;

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.ALLOWANCE
        });

        AllowanceList memory al = AllowanceList ({
            id: _allowanceId.current(),
            sender: msg.sender,
            receiver: _receiver,
            deposit: allowanceById[_allowanceId.current()].deposit,
            startDate: _startDate,
            withdrawalAmount: _amount,
            withdrawalInterval: _interval
        });

        atiumById[_atiumId.current()] = a;
        allowanceById[_allowanceId.current()] = al;
        allowanceDate[_allowanceId.current()] = _startDate;

        emit Allowance(
        _allowanceId.current(), 
        msg.sender,
        _receiver, 
        allowanceById[_allowanceId.current()].deposit,
        _startDate,
        _amount,
        _interval
        );
    }

    function trustfundPlan(
        address _receiver, 
        uint256 _startDate, 
        uint256 _amount, 
        uint256 _interval
        ) external {

        if (_receiver == address(0) || _startDate == 0 || _amount == 0 || _interval == 0) {
            revert Atium_ZeroInput();
        }

        _atiumId.increment();
        _trustfundId.increment();
        _startDate += block.timestamp;

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.TRUSTFUND
        });

        TrustFundList memory t = TrustFundList ({
            id: _trustfundId.current(),
            sender: msg.sender,
            receiver: _receiver,
            amount: trustfundById[_trustfundId.current()].amount,
            startDate: _startDate,
            withdrawalAmount: _amount,
            withdrawalInterval: _interval
        });

        atiumById[_atiumId.current()] = a;
        trustfundById[_trustfundId.current()] = t;
        trustfundDate[_trustfundId.current()] = _startDate;

        emit Trustfund(
        _trustfundId.current(), 
        msg.sender,
        _receiver, 
        trustfundById[_trustfundId.current()].amount,
        _startDate,
        _amount,
        _interval
        );
    }

    function giftPlan(address _receiver, uint256 _date) external {

        if (_receiver == address(0) || _date == 0) {
            revert Atium_ZeroInput();
        }

        _atiumId.increment();
        _giftId.increment();
        _date += block.timestamp;

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.GIFT
        });

        GiftList memory g = GiftList ({
            id: _giftId.current(),
            sender: msg.sender,
            receiver: _receiver,
            amount: giftById[_giftId.current()].amount,
            date: _date
        });

        atiumById[_atiumId.current()] = a;
        giftById[_giftId.current()] = g;

        emit Gift(
            _giftId.current(), 
            msg.sender, 
            _receiver, 
            giftById[_giftId.current()].amount,
            _date
            );
    }

    /////////////////////////////////////////////////////
    ////////////// EDIT/UPDATE ATIUM PLANS //////////////
    /////////////////////////////////////////////////////

    function editSavingsPlanGoal(uint256 _id, uint256 _goal) public inSavings(_id) {

        SavingsList memory s = SavingsList ({
            id: _id,
            user: msg.sender,
            amount: savingsById[_id].amount,
            goal: _goal,
            time: 0
        });

        savingsById[_id] = s;

        emit Savings(
            _id, 
            msg.sender, 
            savingsById[_id].amount,
            _goal, 
            0
            );
    }

    function editSavingsPlanTime(uint256 _id, uint256 _time) public inSavings(_id) {

        _time += block.timestamp;

        SavingsList memory s = SavingsList ({
            id: _id,
            user: msg.sender,
            amount: savingsById[_id].amount,
            goal: 0,
            time: _time
        });

        savingsById[_id] = s;

        emit Savings(
            _id, 
            msg.sender, 
            savingsById[_id].amount,
            0, 
            _time
            );
    }

    function editAllowancePlan(
        uint256 _id, 
        address _receiver, 
        uint256 _startDate, 
        uint256 _amount, 
        uint256 _interval
        ) external inAllowance(_id) {

        _startDate += block.timestamp;

        AllowanceList memory al = AllowanceList ({
            id: _id,
            sender: msg.sender,
            receiver: _receiver,
            deposit: allowanceById[_id].deposit,
            startDate: _startDate += block.timestamp,
            withdrawalAmount: _amount,
            withdrawalInterval: _interval
        });

        allowanceById[_id] = al;
        allowanceDate[_id] = _startDate;

        emit Allowance(
        _id, 
        msg.sender,
        _receiver, 
        allowanceById[_id].deposit,
        _startDate,
        _amount,
        _interval
        );
    }

    function editTrustfundPlan(
        uint256 _id, 
        address _receiver, 
        uint256 _startDate, 
        uint256 _amount, 
        uint256 _interval
        ) external inTrustfund(_id) {

        _startDate += block.timestamp;

        TrustFundList memory t = TrustFundList ({
            id: _id,
            sender: msg.sender,
            receiver: _receiver,
            amount: trustfundById[_id].amount,
            startDate: _startDate,
            withdrawalAmount: _amount,
            withdrawalInterval: _interval
        });

        trustfundById[_id] = t;
        trustfundDate[_id] = _startDate;

        emit Trustfund(
        _id, 
        msg.sender,
        _receiver, 
        trustfundById[_id].amount,
        _startDate,
        _amount,
        _interval
        );
    }

    function editGiftPlan(uint256 _id, address _receiver, uint256 _date) external inGift(_id) {

        _date += block.timestamp;

        GiftList memory g = GiftList ({
            id: _id,
            sender: msg.sender,
            receiver: _receiver,
            amount: giftById[_id].amount,
            date: _date
        });

        giftById[_id] = g;

        emit Gift(
            _id, 
            msg.sender, 
            _receiver, 
            giftById[_id].amount,
            _date
            );
    }

    /////////////////////////////////////////////////////
    ///////////////  GETTER FUNCTIONS ///////////////////
    /////////////////////////////////////////////////////

    function getAtium(uint256 _id) public view returns (AtiumList memory) {
        return atiumById[_id];
    }

    function getSavings(uint256 _id) public view returns (SavingsList memory) {
        return savingsById[_id];
    }

    function getAllowance(uint256 _id) public view returns (AllowanceList memory) {
        return allowanceById[_id];
    }

    function getTrustfund(uint256 _id) public view returns (TrustFundList memory) {
        return trustfundById[_id];
    }

    function getGift(uint256 _id) public view returns (GiftList memory) {
        return giftById[_id];
    }

    ////////////////////////////////////////////////////
    ///////////////////  MODIFIERS  ////////////////////
    ////////////////////////////////////////////////////

    modifier inSavings(uint256 _id) {
        if (savingsById[_id].user != msg.sender) {
            revert Atium_NotOwnerId();
        }
        _;
    }

    modifier inAllowance(uint256 _id) {
        if (allowanceById[_id].sender != msg.sender) {
            revert Atium_NotOwnerId();
        }
        _;
    }

    modifier inTrustfund(uint256 _id) {
        if (trustfundById[_id].sender != msg.sender) {
            revert Atium_NotOwnerId();
        }
        _;
    }

    modifier inGift(uint256 _id) {
        if (giftById[_id].sender != msg.sender) {
            revert Atium_NotOwnerId();
        }
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";

/**
@title - Atium Registration 
@notice - This contract is used to manage the atium signup and atium members profile. For now, 
            the purpose of this contract is to reward atium tokens
@dev - The members can signup and update their profile.
@author - Gbolahan Fakorede
 */

contract AtiumReg {
    using Counters for Counters.Counter;
    Counters.Counter private _ids;

    ///@notice - Error raised when a member already exists.
    error Atium__MemberExists();

    ///@notice -  Error raised when a member does not exist.
    error Atium__NotMember();

    /**
    @dev - Mapping to check if address is an Atium account
    */
    mapping(address => bool) public member;

    /**
      @notice - Mapping of member id to Member struct
    */
    mapping(uint256 => Member) private idToMember;

    /**
      @notice - Mapping of member id to Member address
    */
    mapping(uint256 => address) public addressById;

    /**
      @notice - Structure of an Artist
      @param - id: Id for each artist
      @param - dateJoined: Date artist joined platform
      @param - artistAddress: address of the artist
      @param - artistDetails: Artist details
     */
    struct Member {
        uint id;
        address userAddress;
    }
    /**
    @notice - Event for new artist sign-up
     */
    event newArtistJoined(
        uint id,
        address userAddress
    );

    /**
   @notice - Array to store all artists
    */
    Member[] public members;

    /**
   @notice - Function for new member sign-up
    */

    function memberSignUp() external onlyNonMember {
        _ids.increment();

        Member memory m = Member({
            id: _ids.current(),
            userAddress: msg.sender
        });
        members.push(m);

        member[msg.sender] = true;
        idToMember[_ids.current()] = m;
        addressById[_ids.current()] = msg.sender;

        emit newArtistJoined(
            _ids.current(),
            msg.sender
        );
    }

    /**
    @notice - Function to get all artists
    */
    function getAllMembers() external view returns (Member[] memory) {
        return members;
    }

    ///MODIFIERS

    ///@notice - Modifier to check if an address is a member
    modifier onlyMember {
        if (member[msg.sender] == false) {
            revert Atium__MemberExists();
        }
        _;
    }

    ///@notice - Modifier to check if an address is not a member
    modifier onlyNonMember {
        if (member[msg.sender] == true) {
            revert Atium__NotMember();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AtiumToken is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("ATIUM", "ATM") {
        _mint(msg.sender, 1 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}