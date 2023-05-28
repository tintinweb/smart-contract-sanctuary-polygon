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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAccessControl } from './IAccessControl.sol';
import { AccessControlInternal } from './AccessControlInternal.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControl is IAccessControl, AccessControlInternal {
    /**
     * @inheritdoc IAccessControl
     */
    function grantRole(
        bytes32 role,
        address account
    ) external onlyRole(_getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return _getRoleAdmin(role);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function revokeRole(
        bytes32 role,
        address account
    ) external onlyRole(_getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role) external {
        _renounceRole(role);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { UintUtils } from '../../utils/UintUtils.sol';
import { IAccessControlInternal } from './IAccessControlInternal.sol';
import { AccessControlStorage } from './AccessControlStorage.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControlInternal is IAccessControlInternal {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function _hasRole(
        bytes32 role,
        address account
    ) internal view virtual returns (bool) {
        return
            AccessControlStorage.layout().roles[role].members.contains(account);
    }

    /**
     * @notice revert if sender does not have given role
     * @param role role to query
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @notice revert if given account does not have given role
     * @param role role to query
     * @param account to query
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        'AccessControl: account ',
                        account.toString(),
                        ' is missing role ',
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function _getRoleAdmin(
        bytes32 role
    ) internal view virtual returns (bytes32) {
        return AccessControlStorage.layout().roles[role].adminRole;
    }

    /**
     * @notice set role as admin role
     * @param role role to set
     * @param adminRole admin role to set
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        AccessControlStorage.layout().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function _renounceRole(bytes32 role) internal virtual {
        _revokeRole(role, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';

library AccessControlStorage {
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.AccessControl');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAccessControlInternal } from './IAccessControlInternal.sol';

/**
 * @title AccessControl interface
 */
interface IAccessControl is IAccessControlInternal {
    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function grantRole(bytes32 role, address account) external;

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function renounceRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial AccessControl interface needed by internal functions
 */
interface IAccessControlInternal {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';

interface IOwnable is IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IOwnable } from './IOwnable.sol';

interface ISafeOwnable is IOwnable {
    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function nomineeOwner() external view returns (address);

    /**
     * @notice accept transfer of contract ownership
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IOwnableInternal } from './IOwnableInternal.sol';

interface ISafeOwnableInternal is IOwnableInternal {
    error SafeOwnable__NotNomineeOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address owner) {
        owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                break;
            }
        }
    }

    function _transferOwnership(address account) internal virtual {
        _setOwner(account);
    }

    function _setOwner(address account) internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, account);
        l.owner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { Ownable } from './Ownable.sol';
import { ISafeOwnable } from './ISafeOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { SafeOwnableInternal } from './SafeOwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173 with ownership transfer safety check
 */
abstract contract SafeOwnable is ISafeOwnable, Ownable, SafeOwnableInternal {
    /**
     * @inheritdoc ISafeOwnable
     */
    function nomineeOwner() public view virtual returns (address) {
        return _nomineeOwner();
    }

    /**
     * @inheritdoc ISafeOwnable
     */
    function acceptOwnership() public virtual onlyNomineeOwner {
        _acceptOwnership();
    }

    function _transferOwnership(
        address account
    ) internal virtual override(OwnableInternal, SafeOwnableInternal) {
        super._transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ISafeOwnableInternal } from './ISafeOwnableInternal.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { SafeOwnableStorage } from './SafeOwnableStorage.sol';

abstract contract SafeOwnableInternal is ISafeOwnableInternal, OwnableInternal {
    modifier onlyNomineeOwner() {
        if (msg.sender != _nomineeOwner())
            revert SafeOwnable__NotNomineeOwner();
        _;
    }

    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function _nomineeOwner() internal view virtual returns (address) {
        return SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice accept transfer of contract ownership
     */
    function _acceptOwnership() internal virtual {
        _setOwner(msg.sender);
        delete SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice set nominee owner, granting permission to call acceptOwnership
     */
    function _transferOwnership(address account) internal virtual override {
        SafeOwnableStorage.layout().nomineeOwner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library SafeOwnableStorage {
    struct Layout {
        address nomineeOwner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.SafeOwnable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Merkle tree verification utility
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library MerkleProof {
    /**
     * @notice verify whether given leaf is contained within Merkle tree defined by given root
     * @param proof proof that Merkle tree contains given leaf
     * @param root Merkle tree root
     * @param leaf element whose presence in Merkle tree to prove
     * @return whether leaf is proven to be contained within Merkle tree defined by root
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        unchecked {
            bytes32 computedHash = leaf;

            for (uint256 i = 0; i < proof.length; i++) {
                bytes32 proofElement = proof[i];

                if (computedHash <= proofElement) {
                    computedHash = keccak256(
                        abi.encodePacked(computedHash, proofElement)
                    );
                } else {
                    computedHash = keccak256(
                        abi.encodePacked(proofElement, computedHash)
                    );
                }
            }

            return computedHash == root;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableMap {
    error EnumerableMap__IndexOutOfBounds();
    error EnumerableMap__NonExistentKey();

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(
        AddressToAddressMap storage map,
        uint256 index
    ) internal view returns (address, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);

        return (
            address(uint160(uint256(key))),
            address(uint160(uint256(value)))
        );
    }

    function at(
        UintToAddressMap storage map,
        uint256 index
    ) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(
        AddressToAddressMap storage map,
        address key
    ) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    function length(
        AddressToAddressMap storage map
    ) internal view returns (uint256) {
        return _length(map._inner);
    }

    function length(
        UintToAddressMap storage map
    ) internal view returns (uint256) {
        return _length(map._inner);
    }

    function get(
        AddressToAddressMap storage map,
        address key
    ) internal view returns (address) {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(
        AddressToAddressMap storage map,
        address key
    ) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(
        UintToAddressMap storage map,
        uint256 key
    ) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    function toArray(
        AddressToAddressMap storage map
    )
        internal
        view
        returns (address[] memory keysOut, address[] memory valuesOut)
    {
        uint256 len = map._inner._entries.length;

        keysOut = new address[](len);
        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._key))
                );
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function toArray(
        UintToAddressMap storage map
    )
        internal
        view
        returns (uint256[] memory keysOut, address[] memory valuesOut)
    {
        uint256 len = map._inner._entries.length;

        keysOut = new uint256[](len);
        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = uint256(map._inner._entries[i]._key);
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function keys(
        AddressToAddressMap storage map
    ) internal view returns (address[] memory keysOut) {
        uint256 len = map._inner._entries.length;

        keysOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._key))
                );
            }
        }
    }

    function keys(
        UintToAddressMap storage map
    ) internal view returns (uint256[] memory keysOut) {
        uint256 len = map._inner._entries.length;

        keysOut = new uint256[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = uint256(map._inner._entries[i]._key);
            }
        }
    }

    function values(
        AddressToAddressMap storage map
    ) internal view returns (address[] memory valuesOut) {
        uint256 len = map._inner._entries.length;

        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function values(
        UintToAddressMap storage map
    ) internal view returns (address[] memory valuesOut) {
        uint256 len = map._inner._entries.length;

        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function _at(
        Map storage map,
        uint256 index
    ) private view returns (bytes32, bytes32) {
        if (index >= map._entries.length)
            revert EnumerableMap__IndexOutOfBounds();

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(
        Map storage map,
        bytes32 key
    ) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) revert EnumerableMap__NonExistentKey();
        unchecked {
            return map._entries[keyIndex - 1]._value;
        }
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            unchecked {
                map._entries[keyIndex - 1]._value = value;
            }
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                MapEntry storage last = map._entries[map._entries.length - 1];

                // move last entry to now-vacant index
                map._entries[keyIndex - 1] = last;
                map._indexes[last._key] = keyIndex;
            }

            // clear last index
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC1155Internal } from './IERC1155Internal.sol';

/**
 * @title ERC1155 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
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

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';

/**
 * @title ERC1155 transfer receiver interface
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @notice validate receipt of ERC1155 transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param id token ID received
     * @param value quantity of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice validate receipt of ERC1155 batch transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param ids token IDs received
     * @param values quantities of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165Base } from './IERC165Base.sol';
import { ERC165BaseInternal } from './ERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165Base is IERC165Base, ERC165BaseInternal {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165BaseInternal } from './IERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165BaseInternal is IERC165BaseInternal {
    /**
     * @notice indicates whether an interface is already supported based on the interfaceId
     * @param interfaceId id of interface to check
     * @return bool indicating whether interface is supported
     */
    function _supportsInterface(
        bytes4 interfaceId
    ) internal view returns (bool) {
        return ERC165BaseStorage.layout().supportedInterfaces[interfaceId];
    }

    /**
     * @notice sets status of interface support
     * @param interfaceId id of interface to set status for
     * @param status boolean indicating whether interface will be set as supported
     */
    function _setSupportsInterface(bytes4 interfaceId, bool status) internal {
        if (interfaceId == 0xffffffff) revert ERC165Base__InvalidInterfaceId();
        ERC165BaseStorage.layout().supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC165BaseStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165BaseInternal } from './IERC165BaseInternal.sol';

interface IERC165Base is IERC165, IERC165BaseInternal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165Internal } from '../../../interfaces/IERC165Internal.sol';

interface IERC165BaseInternal is IERC165Internal {
    error ERC165Base__InvalidInterfaceId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { Proxy } from '../../Proxy.sol';
import { IDiamondBase } from './IDiamondBase.sol';
import { DiamondBaseStorage } from './DiamondBaseStorage.sol';

/**
 * @title EIP-2535 "Diamond" proxy base contract
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
abstract contract DiamondBase is IDiamondBase, Proxy {
    /**
     * @inheritdoc Proxy
     */
    function _getImplementation()
        internal
        view
        virtual
        override
        returns (address implementation)
    {
        // inline storage layout retrieval uses less gas
        DiamondBaseStorage.Layout storage l;
        bytes32 slot = DiamondBaseStorage.STORAGE_SLOT;
        assembly {
            l.slot := slot
        }

        implementation = address(bytes20(l.facets[msg.sig]));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
library DiamondBaseStorage {
    struct Layout {
        // function selector => (facet address, selector slot position)
        mapping(bytes4 => bytes32) facets;
        // total number of selectors registered
        uint16 selectorCount;
        // array of selector slots with 8 selectors per slot
        mapping(uint256 => bytes32) selectorSlots;
        address fallbackAddress;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.DiamondBase');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IProxy } from '../../IProxy.sol';

interface IDiamondBase is IProxy {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { OwnableInternal } from '../../../access/ownable/OwnableInternal.sol';
import { DiamondBase } from '../base/DiamondBase.sol';
import { DiamondBaseStorage } from '../base/DiamondBaseStorage.sol';
import { IDiamondFallback } from './IDiamondFallback.sol';

// TODO: DiamondFallback interface

/**
 * @title Fallback feature for EIP-2535 "Diamond" proxy
 */
abstract contract DiamondFallback is
    IDiamondFallback,
    OwnableInternal,
    DiamondBase
{
    /**
     * @inheritdoc IDiamondFallback
     */
    function getFallbackAddress()
        external
        view
        returns (address fallbackAddress)
    {
        fallbackAddress = _getFallbackAddress();
    }

    /**
     * @inheritdoc IDiamondFallback
     */
    function setFallbackAddress(address fallbackAddress) external onlyOwner {
        _setFallbackAddress(fallbackAddress);
    }

    /**
     * @inheritdoc DiamondBase
     * @notice query custom fallback address is no implementation is found
     */
    function _getImplementation()
        internal
        view
        virtual
        override
        returns (address implementation)
    {
        implementation = super._getImplementation();

        if (implementation == address(0)) {
            implementation = _getFallbackAddress();
        }
    }

    /**
     * @notice query the address of the fallback implementation
     * @return fallbackAddress address of fallback implementation
     */
    function _getFallbackAddress()
        internal
        view
        virtual
        returns (address fallbackAddress)
    {
        fallbackAddress = DiamondBaseStorage.layout().fallbackAddress;
    }

    /**
     * @notice set the address of the fallback implementation
     * @param fallbackAddress address of fallback implementation
     */
    function _setFallbackAddress(address fallbackAddress) internal virtual {
        DiamondBaseStorage.layout().fallbackAddress = fallbackAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IDiamondBase } from '../base/IDiamondBase.sol';

interface IDiamondFallback is IDiamondBase {
    /**
     * @notice query the address of the fallback implementation
     * @return fallbackAddress address of fallback implementation
     */
    function getFallbackAddress()
        external
        view
        returns (address fallbackAddress);

    /**
     * @notice set the address of the fallback implementation
     * @param fallbackAddress address of fallback implementation
     */
    function setFallbackAddress(address fallbackAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ISafeOwnable } from '../../access/ownable/ISafeOwnable.sol';
import { IERC165 } from '../../interfaces/IERC165.sol';
import { IDiamondBase } from './base/IDiamondBase.sol';
import { IDiamondFallback } from './fallback/IDiamondFallback.sol';
import { IDiamondReadable } from './readable/IDiamondReadable.sol';
import { IDiamondWritable } from './writable/IDiamondWritable.sol';

interface ISolidStateDiamond is
    IDiamondBase,
    IDiamondFallback,
    IDiamondReadable,
    IDiamondWritable,
    ISafeOwnable,
    IERC165
{
    receive() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { DiamondBaseStorage } from '../base/DiamondBaseStorage.sol';
import { IDiamondReadable } from './IDiamondReadable.sol';

/**
 * @title EIP-2535 "Diamond" proxy introspection contract
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
abstract contract DiamondReadable is IDiamondReadable {
    /**
     * @inheritdoc IDiamondReadable
     */
    function facets() external view returns (Facet[] memory diamondFacets) {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        diamondFacets = new Facet[](l.selectorCount);

        uint8[] memory numFacetSelectors = new uint8[](l.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;

        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(l.facets[selector]));

                bool continueLoop;

                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (diamondFacets[facetIndex].target == facet) {
                        diamondFacets[facetIndex].selectors[
                            numFacetSelectors[facetIndex]
                        ] = selector;
                        // probably will never have more than 256 functions from one facet contract
                        require(numFacetSelectors[facetIndex] < 255);
                        numFacetSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }
                }

                if (continueLoop) {
                    continue;
                }

                diamondFacets[numFacets].target = facet;
                diamondFacets[numFacets].selectors = new bytes4[](
                    l.selectorCount
                );
                diamondFacets[numFacets].selectors[0] = selector;
                numFacetSelectors[numFacets] = 1;
                numFacets++;
            }
        }

        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = diamondFacets[facetIndex].selectors;

            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }

        // setting the number of facets
        assembly {
            mstore(diamondFacets, numFacets)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetFunctionSelectors(
        address facet
    ) external view returns (bytes4[] memory selectors) {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        selectors = new bytes4[](l.selectorCount);

        uint256 numSelectors;
        uint256 selectorIndex;

        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));

                if (facet == address(bytes20(l.facets[selector]))) {
                    selectors[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }

        // set the number of selectors in the array
        assembly {
            mstore(selectors, numSelectors)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetAddresses()
        external
        view
        returns (address[] memory addresses)
    {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        addresses = new address[](l.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;

        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(l.facets[selector]));

                bool continueLoop;

                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facet == addresses[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }

                if (continueLoop) {
                    continue;
                }

                addresses[numFacets] = facet;
                numFacets++;
            }
        }

        // set the number of facet addresses in the array
        assembly {
            mstore(addresses, numFacets)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetAddress(
        bytes4 selector
    ) external view returns (address facet) {
        facet = address(bytes20(DiamondBaseStorage.layout().facets[selector]));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Diamond proxy introspection interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondReadable {
    struct Facet {
        address target;
        bytes4[] selectors;
    }

    /**
     * @notice get all facets and their selectors
     * @return diamondFacets array of structured facet data
     */
    function facets() external view returns (Facet[] memory diamondFacets);

    /**
     * @notice get all selectors for given facet address
     * @param facet address of facet to query
     * @return selectors array of function selectors
     */
    function facetFunctionSelectors(
        address facet
    ) external view returns (bytes4[] memory selectors);

    /**
     * @notice get addresses of all facets used by diamond
     * @return addresses array of facet addresses
     */
    function facetAddresses()
        external
        view
        returns (address[] memory addresses);

    /**
     * @notice get the address of the facet associated with given selector
     * @param selector function selector to query
     * @return facet facet address (zero address if not found)
     */
    function facetAddress(
        bytes4 selector
    ) external view returns (address facet);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IOwnable, Ownable, OwnableInternal } from '../../access/ownable/Ownable.sol';
import { ISafeOwnable, SafeOwnable } from '../../access/ownable/SafeOwnable.sol';
import { IERC165 } from '../../interfaces/IERC165.sol';
import { IERC173 } from '../../interfaces/IERC173.sol';
import { ERC165Base, ERC165BaseStorage } from '../../introspection/ERC165/base/ERC165Base.sol';
import { DiamondBase } from './base/DiamondBase.sol';
import { DiamondFallback, IDiamondFallback } from './fallback/DiamondFallback.sol';
import { DiamondReadable, IDiamondReadable } from './readable/DiamondReadable.sol';
import { DiamondWritable, IDiamondWritable } from './writable/DiamondWritable.sol';
import { ISolidStateDiamond } from './ISolidStateDiamond.sol';

/**
 * @title SolidState "Diamond" proxy reference implementation
 */
abstract contract SolidStateDiamond is
    ISolidStateDiamond,
    DiamondBase,
    DiamondFallback,
    DiamondReadable,
    DiamondWritable,
    SafeOwnable,
    ERC165Base
{
    constructor() {
        bytes4[] memory selectors = new bytes4[](12);
        uint256 selectorIndex;

        // register DiamondFallback

        selectors[selectorIndex++] = IDiamondFallback
            .getFallbackAddress
            .selector;
        selectors[selectorIndex++] = IDiamondFallback
            .setFallbackAddress
            .selector;

        _setSupportsInterface(type(IDiamondFallback).interfaceId, true);

        // register DiamondWritable

        selectors[selectorIndex++] = IDiamondWritable.diamondCut.selector;

        _setSupportsInterface(type(IDiamondWritable).interfaceId, true);

        // register DiamondReadable

        selectors[selectorIndex++] = IDiamondReadable.facets.selector;
        selectors[selectorIndex++] = IDiamondReadable
            .facetFunctionSelectors
            .selector;
        selectors[selectorIndex++] = IDiamondReadable.facetAddresses.selector;
        selectors[selectorIndex++] = IDiamondReadable.facetAddress.selector;

        _setSupportsInterface(type(IDiamondReadable).interfaceId, true);

        // register ERC165

        selectors[selectorIndex++] = IERC165.supportsInterface.selector;

        _setSupportsInterface(type(IERC165).interfaceId, true);

        // register SafeOwnable

        selectors[selectorIndex++] = Ownable.owner.selector;
        selectors[selectorIndex++] = SafeOwnable.nomineeOwner.selector;
        selectors[selectorIndex++] = Ownable.transferOwnership.selector;
        selectors[selectorIndex++] = SafeOwnable.acceptOwnership.selector;

        _setSupportsInterface(type(IERC173).interfaceId, true);

        // diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({
            target: address(this),
            action: FacetCutAction.ADD,
            selectors: selectors
        });

        _diamondCut(facetCuts, address(0), '');

        // set owner

        _setOwner(msg.sender);
    }

    receive() external payable {}

    function _transferOwnership(
        address account
    ) internal virtual override(OwnableInternal, SafeOwnable) {
        super._transferOwnership(account);
    }

    /**
     * @inheritdoc DiamondFallback
     */
    function _getImplementation()
        internal
        view
        override(DiamondBase, DiamondFallback)
        returns (address implementation)
    {
        implementation = super._getImplementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { OwnableInternal } from '../../../access/ownable/OwnableInternal.sol';
import { IDiamondWritable } from './IDiamondWritable.sol';
import { DiamondWritableInternal } from './DiamondWritableInternal.sol';

/**
 * @title EIP-2535 "Diamond" proxy update contract
 */
abstract contract DiamondWritable is
    IDiamondWritable,
    DiamondWritableInternal,
    OwnableInternal
{
    /**
     * @inheritdoc IDiamondWritable
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address target,
        bytes calldata data
    ) external onlyOwner {
        _diamondCut(facetCuts, target, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { DiamondBaseStorage } from '../base/DiamondBaseStorage.sol';
import { IDiamondWritableInternal } from './IDiamondWritableInternal.sol';

abstract contract DiamondWritableInternal is IDiamondWritableInternal {
    using AddressUtils for address;

    bytes32 private constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 private constant CLEAR_SELECTOR_MASK =
        bytes32(uint256(0xffffffff << 224));

    /**
     * @notice update functions callable on Diamond proxy
     * @param facetCuts array of structured Diamond facet update data
     * @param target optional recipient of initialization delegatecall
     * @param data optional initialization call data
     */
    function _diamondCut(
        FacetCut[] memory facetCuts,
        address target,
        bytes memory data
    ) internal {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        unchecked {
            uint256 originalSelectorCount = l.selectorCount;
            uint256 selectorCount = originalSelectorCount;
            bytes32 selectorSlot;

            // Check if last selector slot is not full
            if (selectorCount & 7 > 0) {
                // get last selectorSlot
                selectorSlot = l.selectorSlots[selectorCount >> 3];
            }

            for (uint256 i; i < facetCuts.length; i++) {
                FacetCut memory facetCut = facetCuts[i];
                FacetCutAction action = facetCut.action;

                if (facetCut.selectors.length == 0)
                    revert DiamondWritable__SelectorNotSpecified();

                if (action == FacetCutAction.ADD) {
                    (selectorCount, selectorSlot) = _addFacetSelectors(
                        l,
                        selectorCount,
                        selectorSlot,
                        facetCut
                    );
                } else if (action == FacetCutAction.REPLACE) {
                    _replaceFacetSelectors(l, facetCut);
                } else if (action == FacetCutAction.REMOVE) {
                    (selectorCount, selectorSlot) = _removeFacetSelectors(
                        l,
                        selectorCount,
                        selectorSlot,
                        facetCut
                    );
                }
            }

            if (selectorCount != originalSelectorCount) {
                l.selectorCount = uint16(selectorCount);
            }

            // If last selector slot is not full
            if (selectorCount & 7 > 0) {
                l.selectorSlots[selectorCount >> 3] = selectorSlot;
            }

            emit DiamondCut(facetCuts, target, data);
            _initialize(target, data);
        }
    }

    function _addFacetSelectors(
        DiamondBaseStorage.Layout storage l,
        uint256 selectorCount,
        bytes32 selectorSlot,
        FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            if (
                facetCut.target != address(this) &&
                !facetCut.target.isContract()
            ) revert DiamondWritable__TargetHasNoCode();

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];

                if (address(bytes20(oldFacet)) != address(0))
                    revert DiamondWritable__SelectorAlreadyAdded();

                // add facet for selector
                l.facets[selector] =
                    bytes20(facetCut.target) |
                    bytes32(selectorCount);
                uint256 selectorInSlotPosition = (selectorCount & 7) << 5;

                // clear selector position in slot and add selector
                selectorSlot =
                    (selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);

                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    l.selectorSlots[selectorCount >> 3] = selectorSlot;
                    selectorSlot = 0;
                }

                selectorCount++;
            }

            return (selectorCount, selectorSlot);
        }
    }

    function _removeFacetSelectors(
        DiamondBaseStorage.Layout storage l,
        uint256 selectorCount,
        bytes32 selectorSlot,
        FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            if (facetCut.target != address(0))
                revert DiamondWritable__RemoveTargetNotZeroAddress();

            uint256 selectorSlotCount = selectorCount >> 3;
            uint256 selectorInSlotIndex = selectorCount & 7;

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];

                if (address(bytes20(oldFacet)) == address(0))
                    revert DiamondWritable__SelectorNotFound();

                if (address(bytes20(oldFacet)) == address(this))
                    revert DiamondWritable__SelectorIsImmutable();

                if (selectorSlot == 0) {
                    selectorSlotCount--;
                    selectorSlot = l.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }

                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

                // adding a block here prevents stack too deep error
                {
                    // replace selector with last selector in l.facets
                    lastSelector = bytes4(
                        selectorSlot << (selectorInSlotIndex << 5)
                    );

                    if (lastSelector != selector) {
                        // update last selector slot position info
                        l.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(l.facets[lastSelector]);
                    }

                    delete l.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }

                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = l.selectorSlots[
                        oldSelectorsSlotCount
                    ];

                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);

                    // update storage with the modified slot
                    l.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    selectorSlot =
                        (selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }

                if (selectorInSlotIndex == 0) {
                    delete l.selectorSlots[selectorSlotCount];
                    selectorSlot = 0;
                }
            }

            selectorCount = (selectorSlotCount << 3) | selectorInSlotIndex;

            return (selectorCount, selectorSlot);
        }
    }

    function _replaceFacetSelectors(
        DiamondBaseStorage.Layout storage l,
        FacetCut memory facetCut
    ) internal {
        unchecked {
            if (!facetCut.target.isContract())
                revert DiamondWritable__TargetHasNoCode();

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));

                if (oldFacetAddress == address(0))
                    revert DiamondWritable__SelectorNotFound();
                if (oldFacetAddress == address(this))
                    revert DiamondWritable__SelectorIsImmutable();
                if (oldFacetAddress == facetCut.target)
                    revert DiamondWritable__ReplaceTargetIsIdentical();

                // replace old facet address
                l.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(facetCut.target);
            }
        }
    }

    function _initialize(address target, bytes memory data) private {
        if ((target == address(0)) != (data.length == 0))
            revert DiamondWritable__InvalidInitializationParameters();

        if (target != address(0)) {
            if (target != address(this)) {
                if (!target.isContract())
                    revert DiamondWritable__TargetHasNoCode();
            }

            (bool success, ) = target.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IDiamondWritableInternal } from './IDiamondWritableInternal.sol';

/**
 * @title Diamond proxy upgrade interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondWritable is IDiamondWritableInternal {
    /**
     * @notice update diamond facets and optionally execute arbitrary initialization function
     * @param facetCuts array of structured Diamond facet update data
     * @param target optional target of initialization delegatecall
     * @param data optional initialization function call data
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address target,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IDiamondWritableInternal {
    enum FacetCutAction {
        ADD,
        REPLACE,
        REMOVE
    }

    event DiamondCut(FacetCut[] facetCuts, address target, bytes data);

    error DiamondWritable__InvalidInitializationParameters();
    error DiamondWritable__RemoveTargetNotZeroAddress();
    error DiamondWritable__ReplaceTargetIsIdentical();
    error DiamondWritable__SelectorAlreadyAdded();
    error DiamondWritable__SelectorIsImmutable();
    error DiamondWritable__SelectorNotFound();
    error DiamondWritable__SelectorNotSpecified();
    error DiamondWritable__TargetHasNoCode();

    struct FacetCut {
        address target;
        FacetCutAction action;
        bytes4[] selectors;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IProxy {
    error Proxy__ImplementationIsNotContract();

    fallback() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { AddressUtils } from '../utils/AddressUtils.sol';
import { IProxy } from './IProxy.sol';

/**
 * @title Base proxy contract
 */
abstract contract Proxy is IProxy {
    using AddressUtils for address;

    /**
     * @notice delegate all calls to implementation contract
     * @dev reverts if implementation address contains no code, for compatibility with metamorphic contracts
     * @dev memory location in use by assembly may be unsafe in other contexts
     */
    fallback() external payable virtual {
        address implementation = _getImplementation();

        if (!implementation.isContract())
            revert Proxy__ImplementationIsNotContract();

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice get logic implementation address
     * @return implementation address
     */
    function _getImplementation() internal virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155 } from '../../../interfaces/IERC1155.sol';
import { IERC1155Receiver } from '../../../interfaces/IERC1155Receiver.sol';
import { IERC1155Base } from './IERC1155Base.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from './ERC1155BaseInternal.sol';

/**
 * @title Base ERC1155 contract
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155Base is IERC1155Base, ERC1155BaseInternal {
    /**
     * @inheritdoc IERC1155
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual returns (uint256) {
        return _balanceOf(account, id);
    }

    /**
     * @inheritdoc IERC1155
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual returns (uint256[] memory) {
        if (accounts.length != ids.length)
            revert ERC1155Base__ArrayLengthMismatch();

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        uint256[] memory batchBalances = new uint256[](accounts.length);

        unchecked {
            for (uint256 i; i < accounts.length; i++) {
                if (accounts[i] == address(0))
                    revert ERC1155Base__BalanceQueryZeroAddress();
                batchBalances[i] = balances[ids[i]][accounts[i]];
            }
        }

        return batchBalances;
    }

    /**
     * @inheritdoc IERC1155
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual returns (bool) {
        return ERC1155BaseStorage.layout().operatorApprovals[account][operator];
    }

    /**
     * @inheritdoc IERC1155
     */
    function setApprovalForAll(address operator, bool status) public virtual {
        if (msg.sender == operator) revert ERC1155Base__SelfApproval();
        ERC1155BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender))
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransfer(msg.sender, from, to, id, amount, data);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender))
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransferBatch(msg.sender, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Receiver } from '../../../interfaces/IERC1155Receiver.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC1155BaseInternal } from './IERC1155BaseInternal.sol';
import { ERC1155BaseStorage } from './ERC1155BaseStorage.sol';

/**
 * @title Base ERC1155 internal functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155BaseInternal is IERC1155BaseInternal {
    using AddressUtils for address;

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function _balanceOf(
        address account,
        uint256 id
    ) internal view virtual returns (uint256) {
        if (account == address(0))
            revert ERC1155Base__BalanceQueryZeroAddress();
        return ERC1155BaseStorage.layout().balances[id][account];
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ERC1155BaseStorage.layout().balances[id][account] += amount;

        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _safeMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(account, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @notice mint batch of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            balances[ids[i]][account] += amounts[i];
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), account, ids, amounts);
    }

    /**
     * @notice mint batch of tokens for given address
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _safeMintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _mintBatch(account, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice burn given quantity of tokens held by given address
     * @param account holder of tokens to burn
     * @param id token ID
     * @param amount quantity of tokens to burn
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ''
        );

        mapping(address => uint256) storage balances = ERC1155BaseStorage
            .layout()
            .balances[id];

        unchecked {
            if (amount > balances[account])
                revert ERC1155Base__BurnExceedsBalance();
            balances[account] -= amount;
        }

        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }

    /**
     * @notice burn given batch of tokens held by given address
     * @param account holder of tokens to burn
     * @param ids token IDs
     * @param amounts quantities of tokens to burn
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(msg.sender, account, address(0), ids, amounts, '');

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            for (uint256 i; i < ids.length; i++) {
                uint256 id = ids[i];
                if (amounts[i] > balances[id][account])
                    revert ERC1155Base__BurnExceedsBalance();
                balances[id][account] -= amounts[i];
            }
        }

        emit TransferBatch(msg.sender, account, address(0), ids, amounts);
    }

    /**
     * @notice transfer tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _transfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();

        _beforeTokenTransfer(
            operator,
            sender,
            recipient,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            uint256 senderBalance = balances[id][sender];
            if (amount > senderBalance)
                revert ERC1155Base__TransferExceedsBalance();
            balances[id][sender] = senderBalance - amount;
        }

        balances[id][recipient] += amount;

        emit TransferSingle(operator, sender, recipient, id, amount);
    }

    /**
     * @notice transfer tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _safeTransfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _transfer(operator, sender, recipient, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            id,
            amount,
            data
        );
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _transferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            uint256 token = ids[i];
            uint256 amount = amounts[i];

            unchecked {
                uint256 senderBalance = balances[token][sender];

                if (amount > senderBalance)
                    revert ERC1155Base__TransferExceedsBalance();

                balances[token][sender] = senderBalance - amount;

                i++;
            }

            // balance increase cannot be unchecked because ERC1155Base neither tracks nor validates a totalSupply
            balances[token][recipient] += amount;
        }

        emit TransferBatch(operator, sender, recipient, ids, amounts);
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _safeTransferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _transferBatch(operator, sender, recipient, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice wrap given element in array of length 1
     * @param element element to wrap
     * @return singleton array
     */
    function _asSingletonArray(
        uint256 element
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector)
                    revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice ERC1155 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @dev called for both single and batch transfers
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC1155BaseStorage {
    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155 } from '../../../interfaces/IERC1155.sol';
import { IERC1155BaseInternal } from './IERC1155BaseInternal.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155Base is IERC1155BaseInternal, IERC1155 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Internal } from '../../../interfaces/IERC1155Internal.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155BaseInternal is IERC1155Internal {
    error ERC1155Base__ArrayLengthMismatch();
    error ERC1155Base__BalanceQueryZeroAddress();
    error ERC1155Base__NotOwnerOrApproved();
    error ERC1155Base__SelfApproval();
    error ERC1155Base__BurnExceedsBalance();
    error ERC1155Base__BurnFromZeroAddress();
    error ERC1155Base__ERC1155ReceiverRejected();
    error ERC1155Base__ERC1155ReceiverNotImplemented();
    error ERC1155Base__MintToZeroAddress();
    error ERC1155Base__TransferExceedsBalance();
    error ERC1155Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC1155BaseInternal } from '../base/ERC1155BaseInternal.sol';
import { IERC1155Enumerable } from './IERC1155Enumerable.sol';
import { ERC1155EnumerableInternal, ERC1155EnumerableStorage } from './ERC1155EnumerableInternal.sol';

/**
 * @title ERC1155 implementation including enumerable and aggregate functions
 */
abstract contract ERC1155Enumerable is
    IERC1155Enumerable,
    ERC1155EnumerableInternal
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalHolders(uint256 id) public view virtual returns (uint256) {
        return _totalHolders(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function accountsByToken(
        uint256 id
    ) public view virtual returns (address[] memory) {
        return _accountsByToken(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function tokensByAccount(
        address account
    ) public view virtual returns (uint256[] memory) {
        return _tokensByAccount(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from '../base/ERC1155BaseInternal.sol';
import { ERC1155EnumerableStorage } from './ERC1155EnumerableStorage.sol';

/**
 * @title ERC1155Enumerable internal functions
 */
abstract contract ERC1155EnumerableInternal is ERC1155BaseInternal {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function _totalSupply(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().totalSupply[id];
    }

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function _totalHolders(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().accountsByToken[id].length();
    }

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function _accountsByToken(
        uint256 id
    ) internal view virtual returns (address[] memory) {
        EnumerableSet.AddressSet storage accounts = ERC1155EnumerableStorage
            .layout()
            .accountsByToken[id];

        address[] memory addresses = new address[](accounts.length());

        unchecked {
            for (uint256 i; i < accounts.length(); i++) {
                addresses[i] = accounts.at(i);
            }
        }

        return addresses;
    }

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function _tokensByAccount(
        address account
    ) internal view virtual returns (uint256[] memory) {
        EnumerableSet.UintSet storage tokens = ERC1155EnumerableStorage
            .layout()
            .tokensByAccount[account];

        uint256[] memory ids = new uint256[](tokens.length());

        unchecked {
            for (uint256 i; i < tokens.length(); i++) {
                ids[i] = tokens.at(i);
            }
        }

        return ids;
    }

    /**
     * @notice ERC1155 hook: update aggregate values
     * @inheritdoc ERC1155BaseInternal
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != to) {
            ERC1155EnumerableStorage.Layout storage l = ERC1155EnumerableStorage
                .layout();
            mapping(uint256 => EnumerableSet.AddressSet)
                storage tokenAccounts = l.accountsByToken;
            EnumerableSet.UintSet storage fromTokens = l.tokensByAccount[from];
            EnumerableSet.UintSet storage toTokens = l.tokensByAccount[to];

            for (uint256 i; i < ids.length; ) {
                uint256 amount = amounts[i];

                if (amount > 0) {
                    uint256 id = ids[i];

                    if (from == address(0)) {
                        l.totalSupply[id] += amount;
                    } else if (_balanceOf(from, id) == amount) {
                        tokenAccounts[id].remove(from);
                        fromTokens.remove(id);
                    }

                    if (to == address(0)) {
                        l.totalSupply[id] -= amount;
                    } else if (_balanceOf(to, id) == 0) {
                        tokenAccounts[id].add(to);
                        toTokens.add(id);
                    }
                }

                unchecked {
                    i++;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableSet } from '../../../data/EnumerableSet.sol';

library ERC1155EnumerableStorage {
    struct Layout {
        mapping(uint256 => uint256) totalSupply;
        mapping(uint256 => EnumerableSet.AddressSet) accountsByToken;
        mapping(address => EnumerableSet.UintSet) tokensByAccount;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Enumerable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155BaseInternal } from '../base/IERC1155BaseInternal.sol';

/**
 * @title ERC1155 enumerable and aggregate function interface
 */
interface IERC1155Enumerable is IERC1155BaseInternal {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function totalHolders(uint256 id) external view returns (uint256);

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(
        uint256 id
    ) external view returns (address[] memory);

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(
        address account
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { IERC1155Metadata } from './IERC1155Metadata.sol';
import { ERC1155MetadataInternal } from './ERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155 metadata extensions
 */
abstract contract ERC1155Metadata is IERC1155Metadata, ERC1155MetadataInternal {
    using UintUtils for uint256;

    /**
     * @notice inheritdoc IERC1155Metadata
     */
    function uri(uint256 tokenId) public view virtual returns (string memory) {
        ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage
            .layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155Metadata internal functions
 */
abstract contract ERC1155MetadataInternal is IERC1155MetadataInternal {
    /**
     * @notice set base metadata URI
     * @dev base URI is a non-standard feature adapted from the ERC721 specification
     * @param baseURI base URI
     */
    function _setBaseURI(string memory baseURI) internal {
        ERC1155MetadataStorage.layout().baseURI = baseURI;
    }

    /**
     * @notice set per-token metadata URI
     * @param tokenId token whose metadata URI to set
     * @param tokenURI per-token URI
     */
    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        ERC1155MetadataStorage.layout().tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC1155 metadata extensions
 */
library ERC1155MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Metadata');

    struct Layout {
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata is IERC1155MetadataInternal {
    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721 } from '../../../interfaces/IERC721.sol';
import { IERC721Base } from './IERC721Base.sol';
import { ERC721BaseInternal } from './ERC721BaseInternal.sol';

/**
 * @title Base ERC721 implementation, excluding optional extensions
 */
abstract contract ERC721Base is IERC721Base, ERC721BaseInternal {
    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        return _ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) external view returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool) {
        return _isApprovedForAll(account, operator);
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable {
        _transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable {
        _safeTransferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable {
        _safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address operator, uint256 tokenId) external payable {
        _approve(operator, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool status) external {
        _setApprovalForAll(operator, status);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Receiver } from '../../../interfaces/IERC721Receiver.sol';
import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC721BaseInternal } from './IERC721BaseInternal.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';

/**
 * @title Base ERC721 internal functions
 */
abstract contract ERC721BaseInternal is IERC721BaseInternal {
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    function _balanceOf(
        address account
    ) internal view virtual returns (uint256) {
        if (account == address(0)) revert ERC721Base__BalanceQueryZeroAddress();
        return ERC721BaseStorage.layout().holderTokens[account].length();
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        address owner = ERC721BaseStorage.layout().tokenOwners.get(tokenId);
        if (owner == address(0)) revert ERC721Base__InvalidOwner();
        return owner;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ERC721BaseStorage.layout().tokenOwners.contains(tokenId);
    }

    function _getApproved(
        uint256 tokenId
    ) internal view virtual returns (address) {
        if (!_exists(tokenId)) revert ERC721Base__NonExistentToken();

        return ERC721BaseStorage.layout().tokenApprovals[tokenId];
    }

    function _isApprovedForAll(
        address account,
        address operator
    ) internal view virtual returns (bool) {
        return ERC721BaseStorage.layout().operatorApprovals[account][operator];
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        if (!_exists(tokenId)) revert ERC721Base__NonExistentToken();

        address owner = _ownerOf(tokenId);

        return (spender == owner ||
            _getApproved(tokenId) == spender ||
            _isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert ERC721Base__MintToZeroAddress();
        if (_exists(tokenId)) revert ERC721Base__TokenAlreadyMinted();

        _beforeTokenTransfer(address(0), to, tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, '');
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721Base__ERC721ReceiverNotImplemented();
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        l.holderTokens[owner].remove(tokenId);
        l.tokenOwners.remove(tokenId);

        l.tokenApprovals[tokenId] = address(0);

        emit Approval(owner, address(0), tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        address owner = _ownerOf(tokenId);

        if (owner != from) revert ERC721Base__NotTokenOwner();
        if (to == address(0)) revert ERC721Base__TransferToZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        l.holderTokens[from].remove(tokenId);
        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);
        l.tokenApprovals[tokenId] = address(0);

        emit Approval(owner, address(0), tokenId);
        emit Transfer(from, to, tokenId);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        if (!_isApprovedOrOwner(msg.sender, tokenId))
            revert ERC721Base__NotOwnerOrApproved();
        _transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert ERC721Base__ERC721ReceiverNotImplemented();
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        _safeTransferFrom(from, to, tokenId, '');
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        if (!_isApprovedOrOwner(msg.sender, tokenId))
            revert ERC721Base__NotOwnerOrApproved();
        _safeTransfer(from, to, tokenId, data);
    }

    function _approve(address operator, uint256 tokenId) internal virtual {
        _handleApproveMessageValue(operator, tokenId, msg.value);

        address owner = _ownerOf(tokenId);

        if (operator == owner) revert ERC721Base__SelfApproval();
        if (msg.sender != owner && !_isApprovedForAll(owner, msg.sender))
            revert ERC721Base__NotOwnerOrApproved();

        ERC721BaseStorage.layout().tokenApprovals[tokenId] = operator;
        emit Approval(owner, operator, tokenId);
    }

    function _setApprovalForAll(
        address operator,
        bool status
    ) internal virtual {
        if (operator == msg.sender) revert ERC721Base__SelfApproval();
        ERC721BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes memory returnData = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                data
            ),
            'ERC721: transfer to non ERC721Receiver implementer'
        );

        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return returnValue == type(IERC721Receiver).interfaceId;
    }

    /**
     * @notice ERC721 hook, called before externally called approvals for processing of included message value
     * @param operator beneficiary of approval
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before externally called transfers for processing of included message value
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';

library ERC721BaseStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Base');

    struct Layout {
        EnumerableMap.UintToAddressMap tokenOwners;
        mapping(address => EnumerableSet.UintSet) holderTokens;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721 } from '../../../interfaces/IERC721.sol';
import { IERC721BaseInternal } from './IERC721BaseInternal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721Base is IERC721BaseInternal, IERC721 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Internal } from '../../../interfaces/IERC721Internal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721BaseInternal is IERC721Internal {
    error ERC721Base__NotOwnerOrApproved();
    error ERC721Base__SelfApproval();
    error ERC721Base__BalanceQueryZeroAddress();
    error ERC721Base__ERC721ReceiverNotImplemented();
    error ERC721Base__InvalidOwner();
    error ERC721Base__MintToZeroAddress();
    error ERC721Base__NonExistentToken();
    error ERC721Base__NotTokenOwner();
    error ERC721Base__TokenAlreadyMinted();
    error ERC721Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';
import { IERC721Enumerable } from './IERC721Enumerable.sol';
import { ERC721EnumerableInternal } from './ERC721EnumerableInternal.sol';

abstract contract ERC721Enumerable is
    IERC721Enumerable,
    ERC721EnumerableInternal
{
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC721Enumerable
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view returns (uint256) {
        return _tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        return _tokenByIndex(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';

abstract contract ERC721EnumerableInternal {
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice TODO
     */
    function _totalSupply() internal view returns (uint256) {
        return ERC721BaseStorage.layout().tokenOwners.length();
    }

    /**
     * @notice TODO
     */
    function _tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        return ERC721BaseStorage.layout().holderTokens[owner].at(index);
    }

    /**
     * @notice TODO
     */
    function _tokenByIndex(
        uint256 index
    ) internal view returns (uint256 tokenId) {
        (tokenId, ) = ERC721BaseStorage.layout().tokenOwners.at(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Enumerable {
    /**
     * @notice get total token supply
     * @return total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice get token of given owner at given internal storage index
     * @param owner token holder to query
     * @param index position in owner's token list to query
     * @return tokenId id of retrieved token
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    /**
     * @notice get token at given internal storage index
     * @param index position in global token list to query
     * @return tokenId id of retrieved token
     */
    function tokenByIndex(
        uint256 index
    ) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Base } from './base/IERC721Base.sol';
import { IERC721Enumerable } from './enumerable/IERC721Enumerable.sol';
import { IERC721Metadata } from './metadata/IERC721Metadata.sol';

interface ISolidStateERC721 is IERC721Base, IERC721Enumerable, IERC721Metadata {
    error SolidStateERC721__PayableApproveNotSupported();
    error SolidStateERC721__PayableTransferNotSupported();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC721MetadataInternal } from './ERC721MetadataInternal.sol';
import { IERC721Metadata } from './IERC721Metadata.sol';

/**
 * @title ERC721 metadata extensions
 */
abstract contract ERC721Metadata is IERC721Metadata, ERC721MetadataInternal {
    /**
     * @notice inheritdoc IERC721Metadata
     */
    function name() external view virtual returns (string memory) {
        return _name();
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function symbol() external view virtual returns (string memory) {
        return _symbol();
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function tokenURI(
        uint256 tokenId
    ) external view virtual returns (string memory) {
        return _tokenURI(tokenId);
    }

    /**
     * @inheritdoc ERC721MetadataInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';
import { ERC721BaseInternal } from '../base/ERC721Base.sol';
import { IERC721MetadataInternal } from './IERC721MetadataInternal.sol';
import { ERC721MetadataStorage } from './ERC721MetadataStorage.sol';
import { ERC721MetadataInternal } from './ERC721MetadataInternal.sol';

/**
 * @title ERC721Metadata internal functions
 */
abstract contract ERC721MetadataInternal is
    IERC721MetadataInternal,
    ERC721BaseInternal
{
    using UintUtils for uint256;

    /**
     * @notice get token name
     * @return token name
     */
    function _name() internal view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().name;
    }

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function _symbol() internal view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().symbol;
    }

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function _tokenURI(
        uint256 tokenId
    ) internal view virtual returns (string memory) {
        if (!_exists(tokenId)) revert ERC721Metadata__NonExistentToken();

        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }

    /**
     * @notice ERC721 hook: clear per-token URI data on burn
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (to == address(0)) {
            delete ERC721MetadataStorage.layout().tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC721MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Metadata');

    struct Layout {
        string name;
        string symbol;
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721MetadataInternal } from './IERC721MetadataInternal.sol';

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata is IERC721MetadataInternal {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721BaseInternal } from '../base/IERC721BaseInternal.sol';

/**
 * @title ERC721Metadata internal interface
 */
interface IERC721MetadataInternal is IERC721BaseInternal {
    error ERC721Metadata__NonExistentToken();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC165Base } from '../../introspection/ERC165/base/ERC165Base.sol';
import { ERC721Base, ERC721BaseInternal } from './base/ERC721Base.sol';
import { ERC721Enumerable } from './enumerable/ERC721Enumerable.sol';
import { ERC721Metadata } from './metadata/ERC721Metadata.sol';
import { ISolidStateERC721 } from './ISolidStateERC721.sol';

/**
 * @title SolidState ERC721 implementation, including recommended extensions
 */
abstract contract SolidStateERC721 is
    ISolidStateERC721,
    ERC721Base,
    ERC721Enumerable,
    ERC721Metadata,
    ERC165Base
{
    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        if (value > 0) revert SolidStateERC721__PayableApproveNotSupported();
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external transfer function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        if (value > 0) revert SolidStateERC721__PayableTransferNotSupported();
        super._handleTransferMessageValue(from, to, tokenId, value);
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721BaseInternal, ERC721Metadata) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ArrayUtils {
    /**
     * @notice get minimum value in given array
     * @param array array to search
     * @return minimum value
     */
    function min(bytes32[] memory array) internal pure returns (bytes32) {
        bytes32 minValue = bytes32(type(uint256).max);

        unchecked {
            for (uint256 i; i < array.length; i++) {
                if (array[i] < minValue) {
                    minValue = array[i];
                }
            }
        }

        return minValue;
    }

    /**
     * @notice get minimum value in given array
     * @param array array to search
     * @return minimum value
     */
    function min(address[] memory array) internal pure returns (address) {
        address minValue = address(type(uint160).max);

        unchecked {
            for (uint256 i; i < array.length; i++) {
                if (array[i] < minValue) {
                    minValue = array[i];
                }
            }
        }

        return minValue;
    }

    /**
     * @notice get minimum value in given array
     * @param array array to search
     * @return minimum value
     */
    function min(uint256[] memory array) internal pure returns (uint256) {
        uint256 minValue = type(uint256).max;

        unchecked {
            for (uint256 i; i < array.length; i++) {
                if (array[i] < minValue) {
                    minValue = array[i];
                }
            }
        }

        return minValue;
    }

    /**
     * @notice get maximum value in given array
     * @param array array to search
     * @return maximum value
     */
    function max(bytes32[] memory array) internal pure returns (bytes32) {
        bytes32 maxValue = bytes32(0);

        unchecked {
            for (uint256 i; i < array.length; i++) {
                if (array[i] > maxValue) {
                    maxValue = array[i];
                }
            }
        }

        return maxValue;
    }

    /**
     * @notice get maximum value in given array
     * @param array array to search
     * @return maximum value
     */
    function max(address[] memory array) internal pure returns (address) {
        address maxValue = address(0);

        unchecked {
            for (uint256 i; i < array.length; i++) {
                if (array[i] > maxValue) {
                    maxValue = array[i];
                }
            }
        }

        return maxValue;
    }

    /**
     * @notice get maximum value in given array
     * @param array array to search
     * @return maximum value
     */
    function max(uint256[] memory array) internal pure returns (uint256) {
        uint256 maxValue = 0;

        unchecked {
            for (uint256 i; i < array.length; i++) {
                if (array[i] > maxValue) {
                    maxValue = array[i];
                }
            }
        }

        return maxValue;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Interface for the Multicall utility contract
 */
interface IMulticall {
    /**
     * @notice batch function calls to the contract and return the results of each
     * @param data array of function call data payloads
     * @return results array of function call results
     */
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IMulticall } from './IMulticall.sol';

/**
 * @title Utility contract for supporting processing of multiple function calls in a single transaction
 */
abstract contract Multicall is IMulticall {
    /**
     * @inheritdoc IMulticall
     */
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results) {
        results = new bytes[](data.length);

        unchecked {
            for (uint256 i; i < data.length; i++) {
                (bool success, bytes memory returndata) = address(this)
                    .delegatecall(data[i]);

                if (success) {
                    results[i] = returndata;
                } else {
                    assembly {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }
            }
        }

        return results;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();

    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        if (l.status == 2) revert ReentrancyGuard__ReentrantCall();
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { SolidStateDiamond } from '@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol';

/**
 * @title ArcadiansDiamond
 * @notice This contract is a Diamond contract that extends the SolidStateDiamond to implement the EIP-2535 interface, 
 * which allows it to act as a proxy for a collection of other contracts.
 * This contract specifically supports the ERC-721 standard, which is used to store and manage the Arcadians NFTs.
 */
contract ArcadiansDiamond is SolidStateDiamond {}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { ERC721BaseInternal } from "@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol";
import { ERC721Metadata } from "@solidstate/contracts/token/ERC721/metadata/ERC721Metadata.sol";
import { ISolidStateERC721 } from "@solidstate/contracts/token/ERC721/ISolidStateERC721.sol";
import { SolidStateERC721 } from "@solidstate/contracts/token/ERC721/SolidStateERC721.sol";
import { ERC721Base } from "@solidstate/contracts/token/ERC721/base/ERC721Base.sol";
import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';
import { IERC721Metadata } from "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import { ArcadiansInternal } from "./ArcadiansInternal.sol";
import { ArcadiansStorage } from "./ArcadiansStorage.sol";
import { EnumerableMap } from '@solidstate/contracts/data/EnumerableMap.sol';
import { Multicall } from "@solidstate/contracts/utils/Multicall.sol";
import { InventoryStorage } from "../inventory/InventoryStorage.sol";
import { WhitelistStorage } from "../whitelist/WhitelistStorage.sol";

/**
 * @title ArcadiansFacet
 * @notice This contract is an ERC721 responsible for minting and claiming Arcadian tokens.
 * @dev ReentrancyGuard and Multicall contracts are used for security and gas efficiency.
 */
contract ArcadiansFacet is SolidStateERC721, ArcadiansInternal, Multicall {
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    WhitelistStorage.PoolId constant GuaranteedPool = WhitelistStorage.PoolId.Guaranteed;
    WhitelistStorage.PoolId constant RestrictedPool = WhitelistStorage.PoolId.Restricted;

    /**
     * @notice Returns the URI for a given arcadian
     * @param tokenId ID of the token to query
     * @return The URI for the given token ID
     */
    function tokenURI(
        uint tokenId
    ) external view override (ERC721Metadata, IERC721Metadata) returns (string memory) {
        return _tokenURI(tokenId);
    }

    function _mint() internal returns (uint tokenId) {
        ArcadiansStorage.Layout storage arcadiansSL = ArcadiansStorage.layout();

        tokenId = nextArcadianId();

        if (tokenId > arcadiansSL.arcadiansMaxSupply)
            revert Arcadians_MaximumArcadiansSupplyReached();

        uint nonGuaranteedMintedAmount = _claimedWhitelist(RestrictedPool, msg.sender) + _claimedMintPass(msg.sender) + arcadiansSL.userPublicMints[msg.sender];

        if (_isWhitelistClaimActive(GuaranteedPool) && _elegibleWhitelist(GuaranteedPool, msg.sender) > 0) {
            // OG mint flow
            _consumeWhitelist(GuaranteedPool, msg.sender, 1);
        } else if (nonGuaranteedMintedAmount < arcadiansSL.maxMintPerUser) {

            if (_isMintPassClaimActive() && _elegibleMintPass(msg.sender) > 0) {
                // Magic Eden mint flow
                _consumeMintPass(msg.sender);
            } else if (_isWhitelistClaimActive(RestrictedPool) && _elegibleWhitelist(RestrictedPool, msg.sender) > 0) { 
                // Whitelist mint flow
                _consumeWhitelist(RestrictedPool, msg.sender, 1);

            } else if (arcadiansSL.isPublicMintOpen) {
                if (msg.value != arcadiansSL.mintPrice)
                    revert Arcadians_InvalidPayAmount();
                arcadiansSL.userPublicMints[msg.sender]++;
            } else {
                revert Arcadians_NotElegibleToMint();
            }
        } else {
            revert Arcadians_NotElegibleToMint();
        }

        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice Returns the amount of arcadians that can be minted by an account
     * @param account account to query
     * @return balance amount of arcadians that can be minted
     */
    function availableMints(address account) external view returns (uint balance) {
        ArcadiansStorage.Layout storage arcadiansSL = ArcadiansStorage.layout();
        
        uint mintPerUserMax = arcadiansSL.maxMintPerUser;
        uint nonGuaranteedAvailableMints;
        if (_isWhitelistClaimActive(RestrictedPool)) {
            nonGuaranteedAvailableMints += _elegibleWhitelist(RestrictedPool, account);
        } 
        if (_isMintPassClaimActive()) {
            nonGuaranteedAvailableMints += _elegibleMintPass(account);
        }
        if (arcadiansSL.isPublicMintOpen) {
            nonGuaranteedAvailableMints += mintPerUserMax - arcadiansSL.userPublicMints[account];
        }
        nonGuaranteedAvailableMints = nonGuaranteedAvailableMints > mintPerUserMax ? mintPerUserMax : nonGuaranteedAvailableMints;

        uint guaranteedAvailableMints;
        if (_isWhitelistClaimActive(GuaranteedPool)) {
            guaranteedAvailableMints += _elegibleWhitelist(GuaranteedPool, account);
        }
        return guaranteedAvailableMints + nonGuaranteedAvailableMints;
    }

    /**
     * @notice Returns the total amount of arcadians minted
     * @return uint total amount of arcadians minted
     */
    function totalMinted() external view returns (uint) {
        return _totalSupply();
    }

   /**
     * @notice Mint a token and equip it with the given items
     * @param itemsToEquip array of items to equip in the correspondent slot
     */
    function mintAndEquip(
        InventoryStorage.Item[] calldata itemsToEquip
    )
        external payable nonReentrant
    {
        uint tokenId = _mint();
        _equip(tokenId, itemsToEquip, true);
    }

    /**
     * @notice This function sets the public mint as open/closed
     */
    function setPublicMintOpen(bool isOpen) external onlyManager {
        ArcadiansStorage.Layout storage arcadiansSL = ArcadiansStorage.layout();
        arcadiansSL.isPublicMintOpen = isOpen;
    }
    /**
     * @notice Returns true if the public mint is open, false otherwise
     */
    function publicMintOpen() external view returns (bool) {
        return ArcadiansStorage.layout().isPublicMintOpen;
    }

    /**
     * @notice This function updates the price to mint an arcadian
     * @param newMintPrice The new mint price to be set
     */
    function setMintPrice(uint newMintPrice) external onlyManager {
        _setMintPrice(newMintPrice);
    }

    /**
     * @notice This function gets the current price to mint an arcadian
     * @return The current mint price
     */
    function mintPrice() external view returns (uint) {
        return _mintPrice();
    }

    /**
     * @notice This function sets the new maximum number of arcadians that a user can mint
     * @param newMaxMintPerUser The new maximum number of arcadians that a user can mint
     */
    function setMaxMintPerUser(uint newMaxMintPerUser) external onlyManager {
        _setMaxMintPerUser(newMaxMintPerUser);
    }

    /**
     * @dev This function gets the current maximum number of arcadians that a user can mint
     * @return The current maximum number of arcadians that a user can mint
     */
    function maxMintPerUser() external view returns (uint) {
        return _maxMintPerUser();
    }

    /**
     * @dev This function returns the maximum supply of arcadians
     * @return The current maximum supply of arcadians
     */
    function maxSupply() external view returns (uint) {
        return ArcadiansStorage.layout().arcadiansMaxSupply;
    }

    /**
     * @notice Sets the max arcadians supply
     * @param maxArcadiansSupply The max supply of arcadians that can be minted
     */
    function setMaxSupply(uint maxArcadiansSupply) external onlyManager {
        _setMaxSupply(maxArcadiansSupply);
    }

    /**
     * @notice Set the base URI for all Arcadians metadata
     * @notice Only the manager role can call this function
     * @param newBaseURI The new base URI for all token metadata
     */
    function setBaseURI(string memory newBaseURI) external onlyManager {
        _setBaseURI(newBaseURI);
    }

    /**
     * @dev This function returns the base URI
     * @return The base URI
     */
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function nextArcadianId() internal view returns (uint arcadianId) {
        arcadianId = _totalSupply() + 1;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { RolesInternal } from "../roles/RolesInternal.sol";
import { ArcadiansInternal } from "./ArcadiansInternal.sol";
import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';
import { ERC165BaseInternal } from '@solidstate/contracts/introspection/ERC165/base/ERC165BaseInternal.sol';

contract ArcadiansInit is RolesInternal, ArcadiansInternal, ERC165BaseInternal {
    function init(
        string calldata baseUri, 
        uint maxMintPerUser, 
        uint mintPrice, 
        address mintPassAddress, 
        uint arcadiansMaxSupply
    ) external {

        _setSupportsInterface(type(IERC721).interfaceId, true);

        // Roles facet
        _initRoles();

        // Arcadians facet
        _setBaseURI(baseUri);
        _setMaxMintPerUser(maxMintPerUser);
        _setMintPrice(mintPrice);
        _setMaxSupply(arcadiansMaxSupply);

        // Mint pass
        _setMintPassContractAddress(mintPassAddress);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { ERC721MetadataStorage } from "@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";
import { UintUtils } from '@solidstate/contracts/utils/UintUtils.sol';
import { ArcadiansStorage } from "./ArcadiansStorage.sol";
import { RolesInternal } from "../roles/RolesInternal.sol";
import { WhitelistInternal } from "../whitelist/WhitelistInternal.sol";
import { WhitelistStorage } from "../whitelist/WhitelistStorage.sol";
import { InventoryInternal } from "../inventory/InventoryInternal.sol";
import { MintPassInternal } from "../mintPass/MintPassInternal.sol";

contract ArcadiansInternal is RolesInternal, WhitelistInternal, InventoryInternal, MintPassInternal {

    error Arcadians_InvalidPayAmount();
    error Arcadians_MaximumArcadiansSupplyReached();
    error Arcadians_NotElegibleToMint();

    event MaxMintPerUserChanged(address indexed by, uint oldMaxMintPerUser, uint newMaxMintPerUser);
    event MintPriceChanged(address indexed by, uint oldMintPrice, uint newMintPrice);
    event BaseURIChanged(address indexed by, string oldBaseURI, string newBaseURI);

    using UintUtils for uint;

    function _setBaseURI(string memory newBaseURI) internal {
        ERC721MetadataStorage.Layout storage ERC721SL = ERC721MetadataStorage.layout();
        emit BaseURIChanged(msg.sender, ERC721SL.baseURI, newBaseURI);
        ERC721SL.baseURI = newBaseURI;
    }

    function _baseURI() internal view returns (string memory) {
        return ERC721MetadataStorage.layout().baseURI;
    }

    function _mintPrice() internal view returns (uint) {
        return ArcadiansStorage.layout().mintPrice;
    }

    function _setMintPrice(uint newMintPrice) internal {
        ArcadiansStorage.Layout storage arcadiansSL = ArcadiansStorage.layout();
        emit MintPriceChanged(msg.sender, arcadiansSL.mintPrice, newMintPrice);
        arcadiansSL.mintPrice = newMintPrice;
    }

    function _setMaxMintPerUser(uint newMaxMintPerUser) internal {
        ArcadiansStorage.Layout storage arcadiansSL = ArcadiansStorage.layout();
        emit MaxMintPerUserChanged(msg.sender, arcadiansSL.maxMintPerUser, newMaxMintPerUser);
        arcadiansSL.maxMintPerUser = newMaxMintPerUser;
    }

    function _maxMintPerUser() internal view returns (uint) {
        return ArcadiansStorage.layout().maxMintPerUser;
    }

    function _setMaxSupply(uint arcadiansMaxSupply) internal {
        ArcadiansStorage.Layout storage arcadiansSL = ArcadiansStorage.layout();
        
        arcadiansSL.arcadiansMaxSupply = arcadiansMaxSupply;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

library ArcadiansStorage {

    bytes32 constant ARCADIANS_STORAGE_POSITION =
        keccak256("equippable.storage.position");

    struct Layout {
        uint maxMintPerUser;
        uint mintPrice;
        bool isPublicMintOpen;
        // account => amount minted with public mint
        mapping(address => uint) userPublicMints;
        uint arcadiansMaxSupply;
    }

    function layout()
        internal
        pure
        returns (Layout storage es)
    {
        bytes32 position = ARCADIANS_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-2.0

/**
 * Crated based in the following work:
 * Authors: Moonstream DAO ([email protected])
 * GitHub: https://github.com/G7DAO/contracts
 */

pragma solidity 0.8.19;

import { ReentrancyGuard } from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { InventoryStorage } from "./InventoryStorage.sol";
import { InventoryInternal } from "./InventoryInternal.sol";

/**
 * @title InventoryFacet
 * @dev This contract is responsible for managing the inventory system for the Arcadians using slots. 
 * It defines the functionality to equip and unequip items to Arcadians, check if a combination of items 
 * are unique, and retrieve the inventory slots and allowed items for a slot. 
 * This contract also implements ERC1155Holder to handle ERC1155 token transfers
 * This contract can be used as a facet of a diamond which follows the EIP-2535 diamond standard.
 * It also uses the ReentrancyGuard and Multicall contracts for security and gas efficiency.
 */
contract InventoryFacet is
    ERC1155Holder,
    ReentrancyGuard,
    InventoryInternal
{

    /**
     * @notice Returns the number of inventory slots
     * @dev Slots are 1-indexed
     * @return The number of inventory slots 
     */
    function numSlots() external view returns (uint) {
        return _numSlots();
    }

    function arcadianToBaseItemHash(uint arcadianId) external view returns (bytes32) {
        return InventoryStorage.layout().arcadianToBaseItemHash[arcadianId];
    }

    /**
     * @notice Returns the details of an inventory slot given its ID
     * @dev Slots are 1-indexed
     * @param slotId The ID of the inventory slot
     * @return existentSlot The details of the inventory slot
     */
    function slot(uint8 slotId) external view returns (InventoryStorage.Slot memory existentSlot) {
        return _slot(slotId);
    }

    /**
     * @notice Returns the details of all the existent slots
     * @dev Slots are 1-indexed
     * @return existentSlots The details of all the inventory slots
     */
    function slotsAll() external view returns (InventoryStorage.Slot[] memory existentSlots) {
        return _slotsAll();
    }

    /**
     * @notice Creates a new inventory slot
     * @dev This function is only accessible to the manager role
     * @dev Slots are 1-indexed
     * @param permanent Whether or not the slot can be unequipped once equipped
     * @param isBase If the slot is base
     * @param items The list of items to allow in the slot
     */
    function createSlot(
        bool permanent,
        bool isBase,
        InventoryStorage.Item[] calldata items
    ) external onlyManager {
        _createSlot(permanent, isBase, items);
    }

    /**
     * @notice Sets the slot permanent property
     * @dev This function is only accessible to the manager role
     * @dev Slots are 1-indexed
     * @param permanent Whether or not the slot is permanent
     */
    function setSlotPermanent(
        uint8 slotId,
        bool permanent
    ) external onlyManager {
        _setSlotPermanent(slotId, permanent);
    }

    /**
     * @notice Sets the slot base property
     * @dev This function is only accessible to the manager role
     * @dev Slots are 1-indexed
     * @param isBase Whether or not the slot is base
     */
    function setSlotBase(
        uint8 slotId,
        bool isBase
    ) external onlyManager {
        _setSlotBase(slotId, isBase);
    }

    /**
     * @notice Returns the number coupons available for an account that allow to modify the base traits
     * @param account The accounts to increase the number of coupons
     * @param slotId The slot to get the coupon amount from
     */
    function getBaseModifierCoupon(
        address account,
        uint8 slotId
    ) external view returns (uint) {
        return _getbaseModifierCoupon(account, slotId);
    }

    /**
     * @notice Returns the number coupons available for an account that allow to modify the base traits
     * @param account The accounts to increase the number of coupons
     */
    function getBaseModifierCouponAll(
        address account
    ) external view returns (BaseModifierCoupon[] memory) {
        return _getBaseModifierCouponAll(account);
    }

    /**
     * @notice Returns all the base slots ids
     * @return List of base slots ids
     */
    function getBaseSlotsIds() external view returns (uint8[] memory) {
        return _getBaseSlotsIds();
    }

    /**
     * @notice Adds coupons to accounts that allow to modify the base traits
     * @param account The account to increase the number of coupons
     * @param slotsIds The slots ids to increase the number of coupons
     * @param amounts the amounts of coupons to increase
     */
    function addBaseModifierCoupons(
        address account,
        uint8[] calldata slotsIds,
        uint[] calldata amounts
    ) external onlyAutomation {
        _addBaseModifierCoupons(account, slotsIds, amounts);
    }

    /**
     * @notice Sets the items transfer required on equip
     * @param items The list of items
     * @param requiresTransfer If it requires item transfer to be equipped
     */
    function setItemsTransferRequired(
        InventoryStorage.Item[] calldata items,
        bool[] calldata requiresTransfer
    ) external onlyManager {
        _setItemsTransferRequired(items, requiresTransfer);
    }

    /**
     * @notice Adds items to the list of allowed items for an inventory slot
     * @param slotId The slot id
     * @param items The list of items to allow in the slot
     */
    function allowItemsInSlot(
        uint8 slotId,
        InventoryStorage.Item[] calldata items
    ) external onlyManager {
        _allowItemsInSlot(slotId, items);
    }
    
    /**
     * @notice Removes items from the list of allowed items
     * @param items The list of items to disallow in the slot
     */
    function disallowItems(
        InventoryStorage.Item[] calldata items
    ) external onlyManager {
        _disallowItems(items);
    }

    /**
     * @notice Returns the allowed slot for a given item
     * @param item The item to check
     * @return The allowed slot id for the item. Slots are 1-indexed.
     */
    function allowedSlot(InventoryStorage.Item calldata item) external view returns (uint) {
        return _allowedSlot(item);
    }

    /**
     * @notice Equips multiple items to multiple slots for a specified Arcadian NFT
     * @param arcadianId The ID of the Arcadian NFT to equip the items for
     * @param items An array of items to equip in the corresponding slots
     */
    function equip(
        uint arcadianId,
        InventoryStorage.Item[] calldata items
    ) external nonReentrant {
        _equip(arcadianId, items, false);
    }

    /**
     * @notice Unequips the items equipped in multiple slots for a specified Arcadian NFT
     * @param arcadianId The ID of the Arcadian NFT to equip the item for
     * @param slotsIds The slots ids in which the items will be unequipped
     */
    function unequip(
        uint arcadianId,
        uint8[] calldata slotsIds
    ) external nonReentrant {
        _unequip(arcadianId, slotsIds);
    }

    /**
     * @notice Retrieves the equipped item in a slot for a specified Arcadian NFT
     * @param arcadianId The ID of the Arcadian NFT to query
     * @param slotId The slot id to query
     */
    function equipped(
        uint arcadianId,
        uint8 slotId
    ) external view returns (ItemInSlot memory item) {
        return _equipped(arcadianId, slotId);
    }

    /**
     * @notice Retrieves the equipped items in the slot of an Arcadian NFT
     * @param arcadianId The ID of the Arcadian NFT to query
     * @param slotsIds The slots ids to query
     */
    function equippedBatch(
        uint arcadianId,
        uint8[] calldata slotsIds
    ) external view returns (ItemInSlot[] memory equippedSlot) {
        return _equippedBatch(arcadianId, slotsIds);
    }

    /**
     * @notice Retrieves all the equipped items for a specified Arcadian NFT
     * @param arcadianId The ID of the Arcadian NFT to query
     */
    function equippedAll(
        uint arcadianId
    ) external view returns (ItemInSlot[] memory equippedSlot) {
        return _equippedAll(arcadianId);
    }

    /**
     * @notice Indicates if a list of items applied to an the arcadian is unique
     * @dev The uniqueness is calculated using the existent arcadian items and the input items as well
     * @dev Only items equipped in 'base' slots are considered for uniqueness
     * @param arcadianId The ID of the Arcadian NFT to query
     * @param items An array of items to check for uniqueness after "equipped" over the existent arcadian items.
     */
    function isArcadianUnique(
        uint arcadianId,
        InventoryStorage.Item[] calldata items
    ) external view returns (bool) {
        return _isArcadianUnique(arcadianId, items);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { ReentrancyGuard } from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";
import { ArrayUtils } from "@solidstate/contracts/utils/ArrayUtils.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { RolesInternal } from "../roles/RolesInternal.sol";
import { InventoryStorage } from "./InventoryStorage.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";

contract InventoryInternal is
    ReentrancyGuard,
    RolesInternal
{
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using AddressUtils for address;

    error Inventory_InvalidERC1155Contract();
    error Inventory_UnequippingPermanentSlot();
    error Inventory_InvalidSlotId();
    error Inventory_ItemDoesNotHaveSlotAssigned();
    error Inventory_InsufficientItemBalance();
    error Inventory_UnequippingEmptySlot();
    error Inventory_UnequippingBaseSlot();
    error Inventory_SlotNotSpecified();
    error Inventory_ItemNotSpecified();
    error Inventory_NotArcadianOwner();
    error Inventory_ArcadianNotUnique();
    error Inventory_NotAllBaseSlotsEquipped();
    error Inventory_InputDataMismatch();
    error Inventory_ItemAlreadyEquippedInSlot();
    error Inventory_CouponNeededToModifyBaseSlots();
    error Inventory_NonBaseSlot();

    event ItemsAllowedInSlotUpdated(
        address indexed by,
        InventoryStorage.Item[] items
    );

    event ItemsEquipped(
        address indexed by,
        uint indexed arcadianId,
        uint8[] slots
    );

    event ItemsUnequipped(
        address indexed by,
        uint indexed arcadianId,
        uint8[] slotsIds
    );

    event SlotCreated(
        address indexed by,
        uint8 indexed slotId,
        bool permanent,
        bool isBase
    );

    event BaseModifierCouponAdded(
        address indexed by,
        address indexed to,
        uint8[] slotsIds,
        uint[] amounts
    );

    event BaseModifierCouponConsumed(
        address indexed account,
        uint indexed arcadianId,
        uint8[] slotsIds
    );

    // Helper structs only used in view functions to ease data reading from web3
    struct ItemInSlot {
        uint8 slotId;
        address erc1155Contract;
        uint itemId;
    }
    struct BaseModifierCoupon {
        uint8 slotId;
        uint amount;
    }

    modifier onlyValidSlot(uint8 slotId) {
        if (slotId == 0 || slotId > InventoryStorage.layout().numSlots) revert Inventory_InvalidSlotId();
        _;
    }

    modifier onlyArcadianOwner(uint arcadianId) {
        IERC721 arcadiansContract = IERC721(address(this));
        if (msg.sender != arcadiansContract.ownerOf(arcadianId)) revert Inventory_NotArcadianOwner();
        _;
    }

    function _numSlots() internal view returns (uint) {
        return InventoryStorage.layout().numSlots;
    }

    function _equip(
        uint arcadianId,
        InventoryStorage.Item[] calldata items,
        bool freeBaseModifier
    ) internal onlyArcadianOwner(arcadianId) {

        if (items.length == 0) 
            revert Inventory_ItemNotSpecified();

        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        uint8 numBaseSlotsModified;
        uint8[] memory slotsIds = new uint8[](items.length);
        for (uint i = 0; i < items.length; i++) {
            uint8 slotId = inventorySL.itemSlot[items[i].erc1155Contract][items[i].id];
            slotsIds[i] = slotId;

            InventoryStorage.Item storage existingItem = inventorySL.equippedItems[arcadianId][slotId];
            if (existingItem.erc1155Contract == items[i].erc1155Contract && existingItem.id == items[i].id) {
                continue;
            }

            _equipSingleSlot(arcadianId, items[i], freeBaseModifier);
            if (inventorySL.slots[slotId].isBase) {
                numBaseSlotsModified++;
            }
        }

        if (!_baseAndPermanentSlotsEquipped(arcadianId)) 
            revert Inventory_NotAllBaseSlotsEquipped();

        if (numBaseSlotsModified > 0) {
            if (!_hashBaseItemsUnchecked(arcadianId))
                revert Inventory_ArcadianNotUnique();

            if (!freeBaseModifier) {
                uint8[] memory baseSlotsModified = new uint8[](numBaseSlotsModified);
                uint counter;
                for (uint i = 0; i < items.length; i++) {
                    uint8 slotId = inventorySL.itemSlot[items[i].erc1155Contract][items[i].id];
                    if (inventorySL.slots[slotId].isBase) {
                        baseSlotsModified[counter] = slotId;
                        counter++;
                    }
                }
                emit BaseModifierCouponConsumed(msg.sender, arcadianId, baseSlotsModified);
            }
        }

        emit ItemsEquipped(msg.sender, arcadianId, slotsIds);
    }

    function _equipSingleSlot(
        uint arcadianId,
        InventoryStorage.Item calldata item,
        bool freeBaseModifier
    ) internal returns (uint8 slotId) {

        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        slotId = inventorySL.itemSlot[item.erc1155Contract][item.id];
        
        if (slotId == 0 || slotId > InventoryStorage.layout().numSlots) 
            revert Inventory_ItemDoesNotHaveSlotAssigned();
        
        if (!freeBaseModifier && inventorySL.slots[slotId].isBase) {
            if (inventorySL.baseModifierCoupon[msg.sender][slotId] == 0)
                revert Inventory_CouponNeededToModifyBaseSlots();

            inventorySL.baseModifierCoupon[msg.sender][slotId]--;
        }

        InventoryStorage.Item storage existingItem = inventorySL.equippedItems[arcadianId][slotId];
        if (inventorySL.slots[slotId].permanent && existingItem.erc1155Contract != address(0)) 
            revert Inventory_UnequippingPermanentSlot();

        if (inventorySL.equippedItems[arcadianId][slotId].erc1155Contract != address(0))
            _unequipUnchecked(arcadianId, slotId);

        bool requiresTransfer = inventorySL.requiresTransfer[item.erc1155Contract][item.id];
        if (requiresTransfer) {
            IERC1155 erc1155Contract = IERC1155(item.erc1155Contract);
            if (erc1155Contract.balanceOf(msg.sender, item.id) < 1)
                revert Inventory_InsufficientItemBalance();

            erc1155Contract.safeTransferFrom(
                msg.sender,
                address(this),
                item.id,
                1,
                ''
            );
        }

        inventorySL.equippedItems[arcadianId][slotId] = item;
    }

    function _baseAndPermanentSlotsEquipped(uint arcadianId) internal view returns (bool) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        uint8 numSlots = inventorySL.numSlots;
        for (uint8 i = 0; i < numSlots; i++) {
            uint8 slotId = i + 1;
            InventoryStorage.Slot storage slot = inventorySL.slots[slotId];
            if (!slot.isBase && !slot.permanent)
                continue;
            if (inventorySL.equippedItems[arcadianId][slotId].erc1155Contract == address(0)) {
                return false;
            }
        }
        return true;
    }

    function _unequipUnchecked(
        uint arcadianId,
        uint8 slotId
    ) internal {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        InventoryStorage.Item storage existingItem = inventorySL.equippedItems[arcadianId][slotId];

        bool requiresTransfer = inventorySL.requiresTransfer[existingItem.erc1155Contract][existingItem.id];
        if (requiresTransfer) {
            IERC1155 erc1155Contract = IERC1155(existingItem.erc1155Contract);
            erc1155Contract.safeTransferFrom(
                address(this),
                msg.sender,
                existingItem.id,
                1,
                ''
            );
        }
        delete inventorySL.equippedItems[arcadianId][slotId];
    }

    function _unequip(
        uint arcadianId,
        uint8[] calldata slotsIds
    ) internal onlyArcadianOwner(arcadianId) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        if (slotsIds.length == 0) 
            revert Inventory_SlotNotSpecified();

        for (uint i = 0; i < slotsIds.length; i++) {
            if (inventorySL.slots[slotsIds[i]].permanent) 
                revert Inventory_UnequippingPermanentSlot();

            if (inventorySL.equippedItems[arcadianId][slotsIds[i]].erc1155Contract == address(0)) 
                revert Inventory_UnequippingEmptySlot();
            
            if (inventorySL.slots[slotsIds[i]].isBase)
                revert Inventory_UnequippingBaseSlot();

            _unequipUnchecked(arcadianId, slotsIds[i]);
        }

        _hashBaseItemsUnchecked(arcadianId);

        emit ItemsUnequipped(
            msg.sender,
            arcadianId,
            slotsIds
        );
    }

    function _equipped(
        uint arcadianId,
        uint8 slotId
    ) internal view returns (ItemInSlot memory) {
        InventoryStorage.Item storage item = InventoryStorage.layout().equippedItems[arcadianId][slotId];
        return ItemInSlot(slotId, item.erc1155Contract, item.id);
    }

    function _equippedBatch(
        uint arcadianId,
        uint8[] calldata slotsIds
    ) internal view returns (ItemInSlot[] memory equippedSlots) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        equippedSlots = new ItemInSlot[](slotsIds.length);
        for (uint i = 0; i < slotsIds.length; i++) {
            InventoryStorage.Item storage equippedItem = inventorySL.equippedItems[arcadianId][slotsIds[i]];
            equippedSlots[i] = ItemInSlot(slotsIds[i], equippedItem.erc1155Contract, equippedItem.id);
        }
    }

    function _equippedAll(
        uint arcadianId
    ) internal view returns (ItemInSlot[] memory equippedSlots) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        uint8 numSlots = inventorySL.numSlots;
        equippedSlots = new ItemInSlot[](numSlots);
        for (uint8 i = 0; i < numSlots; i++) {
            uint8 slotId = i + 1;
            InventoryStorage.Item storage equippedItem = inventorySL.equippedItems[arcadianId][slotId];
            equippedSlots[i] = ItemInSlot(slotId, equippedItem.erc1155Contract, equippedItem.id);
        }
    }

    function _isArcadianUnique(
        uint arcadianId,
        InventoryStorage.Item[] calldata items
    ) internal view returns (bool) {

        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        bytes memory encodedItems;
        uint numBaseSlots = inventorySL.baseSlotsIds.length;

        for (uint8 i = 0; i < numBaseSlots; i++) {
            uint8 slotId = inventorySL.baseSlotsIds[i];

            InventoryStorage.Item memory item;
            for (uint j = 0; j < items.length; j++) {
                if (_allowedSlot(items[j]) == slotId) {
                    item = items[j];
                    break;
                }
            }
            if (item.erc1155Contract == address(0)) {
                if (inventorySL.equippedItems[arcadianId][slotId].erc1155Contract != address(0)) {
                    item = inventorySL.equippedItems[arcadianId][slotId];
                } else {
                    revert Inventory_NotAllBaseSlotsEquipped();
                }
            }
            
            encodedItems = abi.encodePacked(encodedItems, slotId, item.erc1155Contract, item.id);
        }

        return inventorySL.arcadianToBaseItemHash[arcadianId] == keccak256(encodedItems) || !inventorySL.baseItemsHashes.contains(keccak256(encodedItems));
    }

    function _hashBaseItemsUnchecked(
        uint arcadianId
    ) internal returns (bool isUnique) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        bytes memory encodedItems;
        uint numBaseSlots = inventorySL.baseSlotsIds.length;

        for (uint8 i = 0; i < numBaseSlots; i++) {
            uint8 slotId = inventorySL.baseSlotsIds[i];
            
            InventoryStorage.Item storage equippedItem = inventorySL.equippedItems[arcadianId][slotId];
            encodedItems = abi.encodePacked(encodedItems, slotId, equippedItem.erc1155Contract, equippedItem.id);
        }

        bytes32 baseItemsHash = keccak256(encodedItems);

        isUnique = inventorySL.arcadianToBaseItemHash[arcadianId] == baseItemsHash || !inventorySL.baseItemsHashes.contains(baseItemsHash);
        inventorySL.baseItemsHashes.remove(inventorySL.arcadianToBaseItemHash[arcadianId]);
        inventorySL.baseItemsHashes.add(baseItemsHash);
        inventorySL.arcadianToBaseItemHash[arcadianId] = baseItemsHash;
    }

    function _createSlot(
        bool permanent,
        bool isBase,
        InventoryStorage.Item[] calldata allowedItems
    ) internal {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        // slots are 1-index
        inventorySL.numSlots += 1;
        uint8 newSlotId = inventorySL.numSlots;
        inventorySL.slots[newSlotId].permanent = permanent;
        inventorySL.slots[newSlotId].isBase = isBase;
        inventorySL.slots[newSlotId].id = newSlotId;

        _setSlotBase(newSlotId, isBase);

        if (allowedItems.length > 0) {
            _allowItemsInSlot(newSlotId, allowedItems);
        }

        emit SlotCreated(msg.sender, newSlotId, permanent, isBase);
    }

    function _setSlotBase(
        uint8 slotId,
        bool isBase
    ) internal onlyValidSlot(slotId) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        uint8[] storage baseSlotsIds = inventorySL.baseSlotsIds;
        uint numBaseSlots = baseSlotsIds.length;

        if (isBase) {
            bool alreadyInBaseList;
            for (uint i = 0; i < numBaseSlots; i++) {
                if (baseSlotsIds[i] == slotId) {
                    alreadyInBaseList = true;
                    break;
                }
            }
            if (!alreadyInBaseList) {
                baseSlotsIds.push(slotId);
            }
        } else {
            for (uint i = 0; i < numBaseSlots; i++) {
                if (baseSlotsIds[i] == slotId) {
                    baseSlotsIds[i] = baseSlotsIds[numBaseSlots - 1];
                    baseSlotsIds.pop();
                    break;
                }
            }
        }

        inventorySL.slots[slotId].isBase = isBase;
    }

    function _setSlotPermanent(
        uint8 slotId,
        bool permanent
    ) internal onlyValidSlot(slotId) {
        InventoryStorage.layout().slots[slotId].permanent = permanent;
    }

    function _addBaseModifierCoupons(
        address account,
        uint8[] calldata slotsIds,
        uint[] calldata amounts
    ) internal {
        if (slotsIds.length != amounts.length)
            revert Inventory_InputDataMismatch();

        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        uint8 numSlots = inventorySL.numSlots;

        for (uint i = 0; i < slotsIds.length; i++) {
            if (slotsIds[i] == 0 && slotsIds[i] > numSlots) 
                revert Inventory_InvalidSlotId();
            if (!inventorySL.slots[slotsIds[i]].isBase) {
                revert Inventory_NonBaseSlot();
            }
            InventoryStorage.layout().baseModifierCoupon[account][slotsIds[i]] += amounts[i];
        }

        emit BaseModifierCouponAdded(msg.sender, account, slotsIds, amounts);
    }

    function _getbaseModifierCoupon(address account, uint8 slotId) internal view onlyValidSlot(slotId) returns (uint) {
        if (!InventoryStorage.layout().slots[slotId].isBase) {
            revert Inventory_NonBaseSlot();
        }
        return InventoryStorage.layout().baseModifierCoupon[account][slotId];
    }

    function _getBaseModifierCouponAll(address account) internal view returns (BaseModifierCoupon[] memory) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        uint numBaseSlots = inventorySL.baseSlotsIds.length;

        BaseModifierCoupon[] memory coupons = new BaseModifierCoupon[](numBaseSlots);
        uint counter;
        for (uint8 i = 0; i < numBaseSlots; i++) {
            uint8 slotId = uint8(inventorySL.baseSlotsIds[i]);

            coupons[counter].slotId = slotId;
            coupons[counter].amount = inventorySL.baseModifierCoupon[account][slotId];
            counter++;
        }
        return coupons;
    }

    function _getBaseSlotsIds() internal view returns (uint8[] memory) {
        return InventoryStorage.layout().baseSlotsIds;
    }

    function _setItemsTransferRequired(
        InventoryStorage.Item[] calldata items,
        bool[] calldata requiresTransfer
    ) internal {
        if (items.length != requiresTransfer.length)
            revert Inventory_InputDataMismatch();
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        for (uint i = 0; i < items.length; i++) {
            inventorySL.requiresTransfer[items[i].erc1155Contract][items[i].id] = requiresTransfer[i];
        }
    }
    
    function _allowItemsInSlot(
        uint8 slotId,
        InventoryStorage.Item[] calldata items
    ) internal virtual onlyValidSlot(slotId) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();

        for (uint i = 0; i < items.length; i++) {
            if (!items[i].erc1155Contract.isContract()) 
                revert Inventory_InvalidERC1155Contract();

            inventorySL.itemSlot[items[i].erc1155Contract][items[i].id] = slotId;
        }

        emit ItemsAllowedInSlotUpdated(msg.sender, items);
    }

    function _disallowItems(
        InventoryStorage.Item[] calldata items
    ) internal virtual {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        for (uint i = 0; i < items.length; i++) {
            delete inventorySL.itemSlot[items[i].erc1155Contract][items[i].id];
        }

        emit ItemsAllowedInSlotUpdated(msg.sender, items);
    }

    function _allowedSlot(InventoryStorage.Item calldata item) internal view returns (uint) {
        return InventoryStorage.layout().itemSlot[item.erc1155Contract][item.id];
    }

    function _slot(uint8 slotId) internal view returns (InventoryStorage.Slot storage slot) {
        return InventoryStorage.layout().slots[slotId];
    }

    function _slotsAll() internal view returns (InventoryStorage.Slot[] memory slotsAll) {
        InventoryStorage.Layout storage inventorySL = InventoryStorage.layout();
        
        uint8 numSlots = inventorySL.numSlots;
        slotsAll = new InventoryStorage.Slot[](numSlots);

        for (uint8 i = 0; i < numSlots; i++) {
            uint8 slotId = i + 1;
            slotsAll[i] = inventorySL.slots[slotId];
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import { RolesInternal } from "../roles/RolesInternal.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

/**
LibInventory defines the storage structure used by the Inventory contract as a facet for an EIP-2535 Diamond
proxy.
 */
library InventoryStorage {
    bytes32 constant INVENTORY_STORAGE_POSITION =
        keccak256("inventory.storage.position");

    // Holds the information needed to identify an ERC1155 item
    struct Item {
        address erc1155Contract;
        uint id;
    }

    // Holds the general information about a slot
    struct Slot {
        uint8 id;
        bool permanent;
        bool isBase;
    }

    struct Layout {
        uint8 numSlots;

        // Slot id => Slot
        mapping(uint8 => Slot) slots;

        // arcadian id => slot id => Items equipped
        mapping(uint => mapping(uint8 => Item)) equippedItems;

        // item address => item id => allowed slot id
        mapping(address => mapping(uint => uint8)) itemSlot;
        
        // item address => item id => equip items requires transfer
        mapping(address => mapping(uint => bool)) requiresTransfer;

        // List of all the existent hashes
        EnumerableSet.Bytes32Set baseItemsHashes;
        // arcadian id => base items hash
        mapping(uint => bytes32) arcadianToBaseItemHash;

        // account => slotId => number of coupons to modify the base traits
        mapping(address => mapping(uint => uint)) baseModifierCoupon;

        // List of all the base slots ids
        uint8[] baseSlotsIds;
    }

    function layout()
        internal
        pure
        returns (Layout storage istore)
    {
        bytes32 position = INVENTORY_STORAGE_POSITION;
        assembly {
            istore.slot := position
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { SolidStateDiamond } from '@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol';

/**
 * @title ItemsDiamond
 * @notice This contract is a Diamond contract that extends the SolidStateDiamond to implement the EIP-2535 interface, 
 * which allows it to act as a proxy for a collection of other contracts.
 * This contract specifically supports the ERC-1155 standard, which is used to store and manage the Arcadians Items.
 */
contract ItemsDiamond is SolidStateDiamond {}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { ERC1155Base } from "@solidstate/contracts/token/ERC1155/base/ERC1155Base.sol";
import { ERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import { ERC1155Enumerable } from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155Enumerable.sol";
import { ERC1155EnumerableInternal } from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableInternal.sol";
import { ERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155Metadata.sol";
import { ReentrancyGuard } from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import { ItemsInternal } from "./ItemsInternal.sol";
import { ItemsStorage } from "./ItemsStorage.sol";
import { Multicall } from "@solidstate/contracts/utils/Multicall.sol";
import { IERC1155 } from '@solidstate/contracts/interfaces/IERC1155.sol';
import { RolesInternal } from "./../roles/RolesInternal.sol";

/**
 * @title ItemsFacet
 * @dev This contract handles the creation and management of items
 * It uses ERC1155 tokens to represent items and provides methods to mint new items,
 * claim items via Merkle tree or a whitelist, and set the base and URIs for
 * the items. It also uses the ReentrancyGuard and Multicall contracts for security
 * and gas efficiency.
 */
contract ItemsFacet is ERC1155Base, ERC1155Enumerable, ERC1155Metadata, ReentrancyGuard, ItemsInternal, Multicall, RolesInternal {
    
    // /**
    //  * @notice Claims an item if present in the Merkle tree
    //  * @param itemId The ID of the item to claim
    //  * @param amount The amount of the item to claim
    //  * @param proof The Merkle proof for the item
    //  */
    // function claimMerkle(uint itemId, uint amount, bytes32[] calldata proof)
    //     public nonReentrant
    // {
    //     _claimMerkle(msg.sender, itemId, amount, proof);
    // }

    // /**
    //  * @notice Claims items if present in the Merkle tree
    //  * @param itemsIds The IDs of the items to claim
    //  * @param amounts The amounts of the items to claim
    //  * @param proofs The Merkle proofs for the items
    //  */
    // function claimMerkleBatch(uint[] calldata itemsIds, uint[] calldata amounts, bytes32[][] calldata proofs) external nonReentrant {
    //     _claimMerkleBatch(msg.sender, itemsIds, amounts, proofs);
    // }

    // /**
    //  * @notice Claims items from a whitelist
    //  * @param itemIds The IDs of the items to claim
    //  * @param amounts The amounts of the items to claim
    //  */
    // function claimWhitelist(uint[] calldata itemIds, uint[] calldata amounts) external nonReentrant {
    //     _claimWhitelist(itemIds, amounts);
    // }

    // /**
    //  * @notice Amount claimed by an address of a specific item
    //  * @param account the account to query
    //  * @param itemId the item id to query
    //  * @return amount returns the claimed amount given an account and an item id
    //  */
    // function claimedAmount(address account, uint itemId) external view returns (uint amount) {
    //     return _claimedAmount(account, itemId);
    // }

    /**
     * @notice Burn an amount of an item
     * @param itemId The ID of the item to burn
     * @param amount The item amount to burn
     */
    function burn(uint itemId, uint amount)
        public
    {
        _burn(msg.sender, itemId, amount);
    }

    /**
     * @notice Burn amounts of items
     * @param itemIds The item ID burn
     * @param amounts The item amounts to be minted
     */
    function burnBatch(uint256[] memory itemIds, uint256[] memory amounts)
        public
    {
        _burnBatch(msg.sender, itemIds, amounts);
    }

    /**
     * @notice Mints a new item. Only minter role account can mint
     * @param to The address to mint the item to
     * @param itemId The ID of the item to mint
     * @param amount The item amount to be minted
     */
    function mint(address to, uint itemId, uint amount)
        public onlyManager
    {
        _mint(to, itemId, amount);
    }

    /**
     * @notice Mint a batch of items to a specific address. Only minter role account can mint
     * @param to The address to receive the minted items
     * @param itemIds An array of items IDs to be minted
     * @param amounts The items amounts to be minted
     */
    function mintBatch(address to, uint[] calldata itemIds, uint[] calldata amounts)
        public onlyManager
    {
        _mintBatch(to, itemIds, amounts);
    }

    /**
     * @notice Set the base URI for all items metadata
     * @dev Only the manager role can call this function
     * @param baseURI The new base URI
     */
    function setBaseURI(string calldata baseURI) external onlyManager {
        _setBaseURI(baseURI);
    }

    /**
     * @notice Set the base URI for all items metadata
     * @dev Only the manager role can call this function
     * @param newBaseURI The new base URI
     * @param migrate Should migrate to IPFS
     */
    function migrateToIPFS(string calldata newBaseURI, bool migrate) external onlyManager {
        _migrateToIPFS(newBaseURI, migrate);
    }

    /**
     * @dev Returns the current inventory address
     * @return The address of the inventory contract
     */
    function getInventoryAddress() external view returns (address) {
        return _getInventoryAddress();
    }

    /**
     * @dev Sets the inventory address
     * @param inventoryAddress The new address of the inventory contract
     */
    function setInventoryAddress(address inventoryAddress) external onlyManager {
        _setInventoryAddress(inventoryAddress);
    }

    /**
     * @notice Override ERC1155Metadata
     */
    function uri(uint tokenId) public view override returns (string memory) {
        if (ItemsStorage.layout().isMigratedToIPFS) {
            return string.concat(super.uri(tokenId), ".json");
        } else {
            return super.uri(tokenId);
        }
    }

    /**
     * @notice Set the URI for a specific item ID
     * @dev Only the manager role can call this function
     * @param tokenId The ID of the item to set the URI for
     * @param tokenURI The new item URI
     */
    function setTokenURI(uint tokenId, string calldata tokenURI) external onlyManager {
        _setTokenURI(tokenId, tokenURI);
    }


    // overrides
    function safeTransferFrom(
        address from,
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) public override (ERC1155Base) {
        // Add red carpet logic for the inventory
        if (from != msg.sender && !isApprovedForAll(from, msg.sender) && _getInventoryAddress() != msg.sender )
            revert ERC1155Base__NotOwnerOrApproved();
        _safeTransfer(msg.sender, from, to, id, amount, data);
    }

    function supportsInterface(bytes4 _interface) external pure returns (bool) {
        return type(IERC1155).interfaceId == _interface;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override (ERC1155BaseInternal, ERC1155EnumerableInternal, ItemsInternal)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { ERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import { RolesInternal } from "../roles/RolesInternal.sol";
import { ItemsInternal } from "./ItemsInternal.sol";
import { InventoryInternal } from "../inventory/InventoryInternal.sol";
import { ERC165BaseInternal } from '@solidstate/contracts/introspection/ERC165/base/ERC165BaseInternal.sol';
import { IERC1155 } from '@solidstate/contracts/interfaces/IERC1155.sol';
import { WhitelistStorage } from '../whitelist/WhitelistStorage.sol';

contract ItemsInit is RolesInternal, ItemsInternal, InventoryInternal, ERC165BaseInternal {    
    function init(string calldata baseUri, address inventoryAddress) external {

        _setSupportsInterface(type(IERC1155).interfaceId, true);

        // _updateMerkleRoot(merkleRoot);

        _initRoles();

        _setBaseURI(baseUri);
        _setInventoryAddress(inventoryAddress);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { ERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import { ERC1155EnumerableInternal } from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableInternal.sol";
import { ERC1155MetadataInternal } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataInternal.sol";
import { ItemsStorage } from "./ItemsStorage.sol";
// import { MerkleInternal } from "../merkle/MerkleInternal.sol";
// import { WhitelistInternal } from "../whitelist/WhitelistInternal.sol";
import { ArrayUtils } from "@solidstate/contracts/utils/ArrayUtils.sol";
// import { WhitelistStorage } from "../whitelist/WhitelistStorage.sol";

contract ItemsInternal is ERC1155BaseInternal, ERC1155EnumerableInternal, ERC1155MetadataInternal {

    error Items_InputsLengthMistatch();
    error Items_InvalidItemId();
    error Items_ItemsBasicStatusAlreadyUpdated();
    error Items_MintingNonBasicItem();
    error Items_MaximumItemMintsExceeded();

    // event ItemsClaimedMerkle(address indexed to, uint[] itemsIds, uint[] amounts);

    using ArrayUtils for uint[];

    // function _claimMerkle(address to, uint itemId, uint amount, bytes32[] memory proof)
    //     internal
    // {
    //     if (itemId < 1) revert Items_InvalidItemId();

    //     ItemsStorage.Layout storage itemsSL = ItemsStorage.layout();

    //     bytes memory leaf = abi.encode(to, itemId, amount);
    //     _consumeLeaf(proof, leaf);

    //     ERC1155BaseInternal._mint(to, itemId, amount, "");

    //     itemsSL.amountClaimed[to][itemId] += amount;
        
    //     uint[] memory itemsIds = new uint[](1);
    //     itemsIds[0] = itemId;
    //     uint[] memory amounts = new uint[](1);
    //     amounts[0] = amount;
    //     emit ItemsClaimedMerkle(to, itemsIds, amounts);
    // }

    // function _claimMerkleBatch(address to, uint[] calldata itemsIds, uint[] calldata amounts, bytes32[][] calldata proofs) 
    //     internal
    // {
    //     if (itemsIds.length != amounts.length) 
    //         revert Items_InputsLengthMistatch();

    //     ItemsStorage.Layout storage itemsSL = ItemsStorage.layout();

    //     for (uint i = 0; i < itemsIds.length; i++) {

    //         if (itemsIds[i] < 1) revert Items_InvalidItemId();

    //         bytes memory leaf = abi.encode(to, itemsIds[i], amounts[i]);
    //         _consumeLeaf(proofs[i], leaf);

    //         ERC1155BaseInternal._mint(to, itemsIds[i], amounts[i], "");

    //         itemsSL.amountClaimed[to][itemsIds[i]] += amounts[i];
    //     }

    //     emit ItemsClaimedMerkle(to, itemsIds, amounts);
    // }
    
    // function _claimWhitelist(uint[] calldata itemIds, uint[] calldata amounts) internal {
    //     if (itemIds.length != amounts.length) 
    //         revert Items_InputsLengthMistatch();


    //     uint totalAmount = 0;
    //     for (uint i = 0; i < itemIds.length; i++) {
    //         if (itemIds[i] < 1) 
    //             revert Items_InvalidItemId();

    //         ERC1155BaseInternal._mint(msg.sender, itemIds[i], amounts[i], "");
    //         totalAmount += amounts[i];
    //     }
    //     _consumeWhitelist(WhitelistStorage.PoolId.Guaranteed, msg.sender, totalAmount);
    // }

    function _claimedAmount(address account, uint itemId) internal view returns (uint) {
        return ItemsStorage.layout().amountClaimed[account][itemId];
    }

    function _mint(address to, uint itemId, uint amount)
        internal
    {
        if (itemId < 1) revert Items_InvalidItemId();

        ERC1155BaseInternal._mint(to, itemId, amount, "");
    }

    function _mintBatch(address to, uint[] calldata itemsIds, uint[] calldata amounts)
        internal
    {
        if (itemsIds.min() < 1) revert Items_InvalidItemId();

        ERC1155BaseInternal._mintBatch(to, itemsIds, amounts, "");
    }

    function _migrateToIPFS(string calldata newBaseURI, bool migrate) internal {
        _setBaseURI(newBaseURI);
        ItemsStorage.layout().isMigratedToIPFS = migrate;
    }

    function _getInventoryAddress() internal view returns (address) {
        return ItemsStorage.layout().inventoryAddress;
    }

    function _setInventoryAddress(address inventoryAddress) internal {
        ItemsStorage.layout().inventoryAddress = inventoryAddress;
    }

    // overrides
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override (ERC1155BaseInternal, ERC1155EnumerableInternal)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

library ItemsStorage {

    bytes32 constant ITEMS_STORAGE_POSITION =
        keccak256("items.storage.position");

    struct Layout {
        // wallet address => token id => is claimed 
        mapping(address => mapping(uint => uint)) amountClaimed;
        bool isMigratedToIPFS;

        // token id => is basic item
        mapping(uint => bool) isBasicItem;
        uint[] basicItemsIds;
        address inventoryAddress;
    }

    function layout()
        internal
        pure
        returns (Layout storage es)
    {
        bytes32 position = ITEMS_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { MerkleInternal } from './MerkleInternal.sol';

/**
 * @title MerkleFacet
 * @notice This contract provides external functions to retrieve and update the Merkle root hash,
 * which is used to verify the authenticity of data in a Merkle tree.
 * This contract can be used as a facet of a diamond which follows the EIP-2535 diamond standard.
 */
contract MerkleFacet is MerkleInternal {

    /**
     * @notice Returns the current Merkle root hash
     * @return The current Merkle root hash
     */
    function merkleRoot() external view returns (bytes32) {
        return _merkleRoot();
    }
    
    /**
     * @notice Updates the Merkle root hash with a new value
     * @dev This function can only be called by an address with the manager role
     * @param newMerkleRoot The new Merkle root hash value to be set
     */
    function updateMerkleRoot(bytes32 newMerkleRoot) external onlyManager {
        _updateMerkleRoot(newMerkleRoot);
    }

    /**
     * @notice Updates the claim state to active and enables the claim of tokens
     * @dev This function can only be called by an address with the manager role
     */
    function setMerkleClaimActive() external onlyManager {
        _setMerkleClaimActive();
    }

    /**
     * @notice Updates the claim state to inactive and disables the claim of tokens
     * @dev This function can only be called by an address with the manager role
     */
    function setMerkleClaimInactive() external onlyManager {
        _setMerkleClaimInactive();
    }

    /**
     * @notice Returns true if elegible tokens can be claimed, or false otherwise
     * @return active bool indicating if claim is active
     */
    function isMerkleClaimActive() view external returns (bool active) {
        return _isMerkleClaimActive();
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { MerkleProof } from "@solidstate/contracts/cryptography/MerkleProof.sol";
import { MerkleStorage } from "./MerkleStorage.sol";
import { RolesInternal } from "./../roles/RolesInternal.sol";

contract MerkleInternal is RolesInternal {

    error Merkle_AlreadyClaimed();
    error Merkle_InvalidClaimAmount();
    error Merkle_NotIncludedInMerkleTree();
    error Merkle_ClaimInactive();
    error Merkle_ClaimStateAlreadyUpdated();

    function _merkleRoot() internal view returns (bytes32) {
        return MerkleStorage.layout().merkleRoot;
    }

    function _updateMerkleRoot(bytes32 newMerkleRoot) internal {
        MerkleStorage.layout().merkleRoot = newMerkleRoot;
    }

    function _isMerkleClaimActive() view internal returns (bool) {
        return !MerkleStorage.layout().claimInactive;
    }

    function _setMerkleClaimActive() internal {
        MerkleStorage.Layout storage merkleSL = MerkleStorage.layout();

        if (!merkleSL.claimInactive) revert Merkle_ClaimStateAlreadyUpdated();
        
        merkleSL.claimInactive = false;
    }

    function _setMerkleClaimInactive() internal {
        MerkleStorage.Layout storage merkleSL = MerkleStorage.layout();

        if (merkleSL.claimInactive) revert Merkle_ClaimStateAlreadyUpdated();
        
        merkleSL.claimInactive = true;
    }

    // To create 'leaf' use abi.encode(leafProp1, leafProp2, ...)
    function _consumeLeaf(bytes32[] memory proof, bytes memory _leaf) internal {
        MerkleStorage.Layout storage merkleSL = MerkleStorage.layout();

        if (merkleSL.claimInactive) revert Merkle_ClaimInactive();

        // TODO: IMPORTANT: ON PRODUCTION REVERT CHANGED ON ITEMS MERKLE CLAIM, TO AVOID INFINITE CLAIM
        bytes32 proofHash = keccak256(abi.encodePacked(proof));
        // if (merkleSL.claimedProof[proofHash]) revert Merkle_AlreadyClaimed();

        bytes32 leaf = keccak256(bytes.concat(keccak256(_leaf)));
        bool isValid = MerkleProof.verify(proof, merkleSL.merkleRoot, leaf);
        
        if (!isValid) revert Merkle_NotIncludedInMerkleTree();
        
        merkleSL.claimedProof[proofHash] = true;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

library MerkleStorage {

    bytes32 constant MERKLE_STORAGE_POSITION =
        keccak256("merkle.storage.position");

    struct Layout {
        bytes32 merkleRoot;
        bool claimInactive;
        mapping(bytes32 => bool) claimedProof;
        mapping(address => uint) amountClaimed;
    }

    function layout()
        internal
        pure
        returns (Layout storage es)
    {
        bytes32 position = MERKLE_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.19;

interface IERC721A {
    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
        uint24 extraData;
    }

    struct MintStageInfo {
        uint80 price;
        uint32 walletLimit;
        bytes32 merkleRoot;
        uint24 maxStageSupply;
        uint64 startTimeUnixSeconds;
        uint64 endTimeUnixSeconds;
    }

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event ConsecutiveTransfer(uint256 fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PermanentBaseURI(string baseURI);
    event SetActiveStage(uint256 activeStage);
    event SetBaseURI(string baseURI);
    event SetCosigner(address cosigner);
    event SetCrossmintAddress(address crossmintAddress);
    event SetGlobalWalletLimit(uint256 globalWalletLimit);
    event SetMaxMintableSupply(uint256 maxMintableSupply);
    event SetMintable(bool mintable);
    event SetTimestampExpirySeconds(uint64 expiry);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event UpdateStage(
        uint256 stage,
        uint80 price,
        uint32 walletLimit,
        bytes32 merkleRoot,
        uint24 maxStageSupply,
        uint64 startTimeUnixSeconds,
        uint64 endTimeUnixSeconds
    );
    event Withdraw(uint256 value);

    function approve(address to, uint256 tokenId) external payable;
    function assertValidCosign(address minter, uint32 qty, uint64 timestamp, bytes calldata signature) external view;
    function balanceOf(address owner) external view returns (uint256);
    function crossmint(uint32 qty, address to, bytes32[] calldata proof, uint64 timestamp, bytes calldata signature) external payable;
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);
    function explicitOwnershipsOf(uint256[] calldata tokenIds) external view returns (TokenOwnership[] memory);
    function getActiveStageFromTimestamp(uint64 timestamp) external view returns (uint256);
    function getApproved(uint256 tokenId) external view returns (address);
    function getCosignDigest(address minter, uint32 qty, uint64 timestamp) external view returns (bytes32);
    function getCosignNonce(address minter) external view returns (uint256);
    function getCosigner() external view returns (address);
    function getCrossmintAddress() external view returns (address);
    function getGlobalWalletLimit() external view returns (uint256);
    function getMaxMintableSupply() external view returns (uint256);
    function getMintable() external view returns (bool);
    function getNumberStages() external view returns (uint256);
    function getStageInfo(uint256 index)
        external
        view
        returns (
            MintStageInfo memory,
            uint32,
            uint256
        );
    function getTimestampExpirySeconds() external view returns (uint64);
    function getTokenURISuffix() external view returns (string memory);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function mint(address minter, uint32 qty, uint64 timestamp) external payable;
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function ownerMint(uint32 qty, address to) external;
        function ownerOf(uint256 tokenId) external view returns (address);
    function permanentBaseURI() external view returns (string memory);
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
    function setApprovalForAll(address operator, bool approved) external;
    function setActiveStage(uint256 stage) external;
    function setBaseURI(string calldata baseURI) external;
    function setCosigner(address cosigner) external;
    function setCrossmintAddress(address crossmintAddress) external;
    function setGlobalWalletLimit(uint256 globalWalletLimit) external;
    function setMaxMintableSupply(uint256 maxMintableSupply) external;
    function setMintable(bool mintable) external;
    function setTimestampExpirySeconds(uint64 expiry) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function symbol() external view returns (string memory);
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
    function tokensOfOwnerIn(address owner, uint256 indexStart, uint256 indexStop) external view returns (uint256[] memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function updateStage(
        uint256 stage,
        uint80 price,
        uint32 walletLimit,
        bytes32 merkleRoot,
        uint24 maxStageSupply,
        uint64 startTimeUnixSeconds,
        uint64 endTimeUnixSeconds
    ) external;
    function withdraw(uint256 value) external;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { MintPassInternal } from './MintPassInternal.sol';
import { MintPassStorage } from "./MintPassStorage.sol";
import { RolesInternal } from "./../roles/RolesInternal.sol";

/**
 * @title WhitelistFacet
 * @notice This contract allows the admins to whitelist an address with a specific amount,
 * which can then be used to claim tokens in other contracts.
 * To consume the whitelist, the token contracts should call the internal functions from WhitelistInternal.
 * This contract can be used as a facet of a diamond which follows the EIP-2535 diamond standard.
 */
contract MintPassFacet is MintPassInternal, RolesInternal {
    
    /**
     * @return The total claimed amount using the mint pass
     */
    function totalClaimedMintPass() external view returns (uint) {
        return _totalClaimedMintPass();
    }

    /**
     * @return The amount of mint passes redeemed by the account
     */
    function claimedMintPass(address account) external view returns (uint) {
        return _claimedMintPass(account);
    }

    /**
     * @return The amount of mint passes owned by the account that are not redeemed
     */
    function elegibleMintPass(address account) external view returns (uint) {
        return _elegibleMintPass(account);
    }
    
    /**
     * @notice Sets the claim state to active/inactive
     * @dev This function can only be called by an address with the manager role
     */
    function setClaimActiveMintPass(bool active) external onlyManager {
        _setClaimActiveMintPass(active);
    }

    /**
     * @notice Returns true if the mint pass claim is active, or false otherwise
     * @return active bool indicating if claim is active
     */
    function isMintPassClaimActive() view external returns (bool active) {
        return _isMintPassClaimActive();
    }

    /**
     * @notice Sets the ERC721 contract address that holds the mint passes tokens
     */
    function setMintPassContractAddress(address passContractAddress) external onlyManager {
        _setMintPassContractAddress(passContractAddress);
    }

    /**
     * @notice Returns the ERC721 contract address that holds the mint passes tokens
     */
    function mintPassContractAddress() external view returns (address) {
        return _mintPassContractAddress();
    }

    /**
     * @notice Returns true if a token pass was used to mint
     */
    function isTokenClaimed(uint tokenId) external view returns (bool) {
        return _isTokenClaimed(tokenId);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { MintPassStorage } from "./MintPassStorage.sol";
import { IERC721A } from "./IERC721A.sol";

contract MintPassInternal {

    error MintPass_ClaimInactive();

    event MintPassConsumed(address indexed account, uint tokenId);

    function _totalClaimedMintPass() internal view returns (uint) {
        return MintPassStorage.layout().totalClaimed;
    }

    function _claimedMintPass(address account) internal view returns (uint) {
        return MintPassStorage.layout().claimedAmount[account];
    }

    function _elegibleMintPass(address account) internal view returns (uint elegibleAmount) {
        MintPassStorage.Layout storage mintPassSL = MintPassStorage.layout();

        IERC721A passContract = IERC721A(mintPassSL.passContractAddress);

        uint[] memory tokensOfOwner = passContract.tokensOfOwner(account);
        for (uint i = 0; i < tokensOfOwner.length; i++) {
            if (!mintPassSL.isTokenClaimed[tokensOfOwner[i]]) {
                elegibleAmount++;
            }
        }
    }

    function _consumeMintPass(address account) internal returns (bool consumed) {
        MintPassStorage.Layout storage mintPassSL = MintPassStorage.layout();

        IERC721A passContract = IERC721A(mintPassSL.passContractAddress);

        if (!MintPassStorage.layout().claimActive)
            revert MintPass_ClaimInactive();

        uint[] memory tokensOfOwner = passContract.tokensOfOwner(account);

        for (uint i = 0; i < tokensOfOwner.length; i++) {
            uint tokenId = tokensOfOwner[i];
            if (!mintPassSL.isTokenClaimed[tokenId]) {
                mintPassSL.claimedAmount[account]++;
                mintPassSL.totalClaimed++;
                mintPassSL.isTokenClaimed[tokenId] = true;
                consumed = true;

                emit MintPassConsumed(account, 1);
                break;
            }
        }
    }

    function _isMintPassClaimActive() view internal returns (bool) {
        return MintPassStorage.layout().claimActive;
    }

    function _setClaimActiveMintPass(bool active) internal {
        MintPassStorage.layout().claimActive = active;
    }

    function _setMintPassContractAddress(address passContractAddress) internal {
        MintPassStorage.layout().passContractAddress = passContractAddress;
    }

    function _mintPassContractAddress() internal view returns (address) {
        return MintPassStorage.layout().passContractAddress;
    }

    function _isTokenClaimed(uint tokenId) internal view returns (bool) {
        return MintPassStorage.layout().isTokenClaimed[tokenId];
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

library MintPassStorage {

    bytes32 constant MINT_PASS_STORAGE_POSITION =
        keccak256("mintPass.storage.position");
    
    struct Layout {
        mapping(uint => bool) isTokenClaimed;
        mapping(address => uint) claimedAmount;
        uint totalClaimed;
        uint maxSupply;
        bool claimActive;
        address passContractAddress;
    }

    function layout()
        internal
        pure
        returns (Layout storage es)
    {
        bytes32 position = MINT_PASS_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MockERC721 is ERC721, ERC721Enumerable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MockERC721", "MTK") {}

    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function tokensOfOwner(address account) public view returns (uint[] memory) {
        uint balance = ERC721.balanceOf(account);
        uint[] memory tokens = new uint[](balance);
        for (uint i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(account, i);
        }
        return tokens;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { AccessControl } from "@solidstate/contracts/access/access_control/AccessControl.sol";
import { RolesInternal } from './RolesInternal.sol';
/**
 * @title RolesFacet
 * @notice This contract provides external functions to retrieve the role IDs used by the AccessControl contract.
 * The contract extends the RolesInternal contract which provides internal functions to manage roles.
 * This contract can be used as a facet of a diamond which follows the EIP-2535 diamond standard
 */
contract RolesFacet is RolesInternal, AccessControl {
    /**
     * @notice Returns the ID of the default admin role
     * @return The ID of the default admin role
     */
    function defaultAdminRole() external pure returns (bytes32) {
        return _defaultAdminRole();
    }

    /**
     * @notice Returns the ID of the manager role
     * @return The ID of the manager role
     */
    function managerRole() external view returns (bytes32) {
        return _managerRole();
    }

    /**
     * @notice Returns the ID of the automation role
     * @return The ID of the automation role
     */
    function automationRole() external view returns (bytes32) {
        return _automationRole();
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { AccessControlInternal } from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import { AccessControlStorage } from "@solidstate/contracts/access/access_control/AccessControlStorage.sol";
import { RolesStorage } from './RolesStorage.sol';

contract RolesInternal is AccessControlInternal {

    error Roles_MissingAdminRole();
    error Roles_MissingManagerRole();
    error Roles_MissingAutomationRole();

    modifier onlyDefaultAdmin() {
        if (!_hasRole(_defaultAdminRole(), msg.sender))
            revert Roles_MissingAdminRole();
        _;
    }

    modifier onlyManager() {
        if (!_hasRole(_managerRole(), msg.sender))
            revert Roles_MissingManagerRole();
        _;
    }

    modifier onlyAutomation() {
        if (!_hasRole(_managerRole(), msg.sender) && !_hasRole(_automationRole(), msg.sender))
            revert Roles_MissingAutomationRole();
        _;
    }

    function _defaultAdminRole() internal pure returns (bytes32) {
        return AccessControlStorage.DEFAULT_ADMIN_ROLE;
    }

    function _managerRole() internal view returns (bytes32) {
        return RolesStorage.layout().managerRole;
    }

    function _automationRole() internal view returns (bytes32) {
        return RolesStorage.layout().automationRole;
    }

    function _initRoles() internal {
        RolesStorage.Layout storage rolesSL = RolesStorage.layout();
        rolesSL.managerRole = keccak256("manager.role");
        rolesSL.automationRole = keccak256("automation.role");

        _grantRole(_defaultAdminRole(), msg.sender);
        _grantRole(_managerRole(), msg.sender);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

library RolesStorage {

    bytes32 constant ROLES_STORAGE_POSITION =
        keccak256("roles.storage.position");

    struct Layout {
        bytes32 managerRole;
        bytes32 automationRole;
    }

    function layout()
        internal
        pure
        returns (Layout storage es)
    {
        bytes32 position = ROLES_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { WhitelistInternal } from './WhitelistInternal.sol';
import { WhitelistStorage } from "./WhitelistStorage.sol";

/**
 * @title WhitelistFacet
 * @notice This contract allows the admins to whitelist an address with a specific amount,
 * which can then be used to claim tokens in other contracts.
 * To consume the whitelist, the token contracts should call the internal functions from WhitelistInternal.
 * This contract can be used as a facet of a diamond which follows the EIP-2535 diamond standard.
 */
contract WhitelistFacet is WhitelistInternal {
    WhitelistStorage.PoolId constant GuaranteedPool = WhitelistStorage.PoolId.Guaranteed;
    WhitelistStorage.PoolId constant RestrictedPool = WhitelistStorage.PoolId.Restricted;

    /**
     * @return The amount claimed from the guaranteed pool by the account
     */
    function claimedGuaranteedPool(address account) external view returns (uint) {
        return _claimedWhitelist(GuaranteedPool, account);
    }

    /**
     * @return The amount claimed from the restricted pool by the account 
     */
    function claimedRestrictedPool(address account) external view returns (uint) {
        return _claimedWhitelist(RestrictedPool, account);
    }

    /**
     * @return The account elegible amount from the guaranteed pool
     */
    function elegibleGuaranteedPool(address account) external view returns (uint) {
        return _elegibleWhitelist(GuaranteedPool, account);
    }

    /**
     * @return The account elegible amount from the restricted pool
     */
    function elegibleRestrictedPool(address account) external view returns (uint) {
        return _elegibleWhitelist(RestrictedPool, account);
    }
    
    /**
     * @return The total claimed amount from the Guaranteed pool
     */
    function totalClaimedGuaranteedPool() external view returns (uint) {
        return _totalClaimedWhitelist(GuaranteedPool);
    }
    
    /**
     * @return The total claimed amount from the Restricted pool
     */
    function totalClaimedRestrictedPool() external view returns (uint) {
        return _totalClaimedWhitelist(RestrictedPool);
    }
    
    /**
     * @return The total elegible amount from the Guaranteed pool
     */
    function totalElegibleGuaranteedPool() external view returns (uint) {
        return _totalElegibleWhitelist(GuaranteedPool);
    }

    /**
     * @return The total elegible amount from the Restricted pool
     */
    function totalElegibleRestrictedPool() external view returns (uint) {
        return _totalElegibleWhitelist(RestrictedPool);
    }

    /**
     * @notice Increase the account whitelist elegible amount in the Guaranteed pool
     * @dev This function can only be called by an address with the manager role
     * @param account The address to add to the whitelist
     * @param amount The amount to whitelist for the address
     */
    function increaseElegibleGuaranteedPool(address account, uint amount) onlyManager external {
        _increaseWhitelistElegible(GuaranteedPool, account, amount);
    }

    /**
     * @notice Increase the account whitelist elegible amount in the restricted pool
     * @dev This function can only be called by an address with the manager role
     * @param account The address to add to the whitelist
     * @param amount The amount to whitelist for the address
     */
    function increaseElegibleRestrictedPool(address account, uint amount) onlyManager external {
        _increaseWhitelistElegible(RestrictedPool, account, amount);
    }

    /**
     * @notice Increase the guaranteed pool elegible amounts for multiple addresses
     * @dev This function can only be called by an address with the manager role
     * @param accounts An array of addresses to add to the whitelist
     * @param amounts An array of amounts to whitelist for each address
     */
    function increaseElegibleGuaranteedPoolBatch(address[] calldata accounts, uint[] calldata amounts) external onlyManager {
        _increaseWhitelistElegibleBatch(GuaranteedPool, accounts, amounts);
    }

    /**
     * @notice Increase the restricted pool elegible amounts for multiple addresses
     * @dev This function can only be called by an address with the manager role
     * @param accounts An array of addresses to add to the whitelist
     * @param amounts An array of amounts to whitelist for each address
     */
    function increaseElegibleRestrictedPoolBatch(address[] calldata accounts, uint[] calldata amounts) external onlyManager {
        _increaseWhitelistElegibleBatch(RestrictedPool, accounts, amounts);
    }

    /**
     * @notice Adds a new address to the Guaranteed Pool with a specific amount
     * @dev This function can only be called by an address with the manager role
     * @param account The address to add to the whitelist
     * @param totalAmount The amount to whitelist for the address
     */
    function setElegibleGuaranteedPool(address account, uint totalAmount) onlyManager external {
        _setWhitelistElegible(GuaranteedPool, account, totalAmount);
    }

    /**
     * @notice Adds a new address to the Restricted Pool with a specific amount
     * @dev This function can only be called by an address with the manager role
     * @param account The address to add to the whitelist
     * @param totalAmount The amount to whitelist for the address
     */
    function setElegibleRestrictedPool(address account, uint totalAmount) onlyManager external {
        _setWhitelistElegible(RestrictedPool, account, totalAmount);
    }

    /**
     * @notice Adds multiple addresses to the Guaranteed Pool with specific amounts
     * @dev This function can only be called by an address with the manager role
     * @param accounts An array of addresses to add to the whitelist
     * @param totalAmounts An array of amounts to whitelist for each address
     */
    function setElegibleGuaranteedPoolBatch(address[] calldata accounts, uint[] calldata totalAmounts) external onlyManager {
        _setWhitelistElegibleBatch(GuaranteedPool, accounts, totalAmounts);
    }

    /**
     * @notice Adds multiple addresses to the Restricted Pool with specific amounts
     * @dev This function can only be called by an address with the manager role
     * @param accounts An array of addresses to add to the whitelist
     * @param totalAmounts An array of amounts to whitelist for each address
     */
    function setElegibleRestrictedPoolBatch(address[] calldata accounts, uint[] calldata totalAmounts) external onlyManager {
        _setWhitelistElegibleBatch(RestrictedPool, accounts, totalAmounts);
    }

    /**
     * @notice Updates the claim state to active and enables the guaranteed pool token claim
     * @dev This function can only be called by an address with the manager role
     */
    function setClaimActiveGuaranteedPool(bool active) external onlyManager {
        _setWhitelistClaimActive(GuaranteedPool, active);
    }

    /**
     * @notice Updates the claim state to active and enables the restricted pool token claim
     * @dev This function can only be called by an address with the manager role
     */
    function setClaimActiveRestrictedPool(bool active) external onlyManager {
        _setWhitelistClaimActive(RestrictedPool, active);
    }

    /**
     * @notice Returns true if elegible tokens can be claimed in the guaranteed pool, or false otherwise
     * @return active bool indicating if claim is active
     */
    function isClaimActiveGuaranteedPool() view external returns (bool active) {
        return _isWhitelistClaimActive(GuaranteedPool);
    }

    /**
     * @notice Returns true if elegible tokens can be claimed in the restricted pool, or false otherwise
     * @return active bool indicating if claim is active
     */
    function isClaimActiveRestrictedPool() view external returns (bool active) {
        return _isWhitelistClaimActive(RestrictedPool);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

import { WhitelistStorage } from "./WhitelistStorage.sol";
import { RolesInternal } from "./../roles/RolesInternal.sol";
contract WhitelistInternal is RolesInternal {

    error Whitelist_ExceedsElegibleAmount();
    error Whitelist_InputDataMismatch();
    error Whitelist_ClaimStateAlreadyUpdated();
    error Whitelist_ClaimInactive();

    event WhitelistBalanceChanged(address indexed account, WhitelistStorage.PoolId poolId, uint totalElegibleAmount, uint totalClaimedAmount);

    function _totalClaimedWhitelist(WhitelistStorage.PoolId poolId) internal view returns (uint) {
        return WhitelistStorage.layout().pools[poolId].totalClaimed;
    }

    function _totalElegibleWhitelist(WhitelistStorage.PoolId poolId) internal view returns (uint) {
        return WhitelistStorage.layout().pools[poolId].totalElegible;
    }

    function _claimedWhitelist(WhitelistStorage.PoolId poolId, address account) internal view returns (uint) {
        return WhitelistStorage.layout().pools[poolId].claimed[account];
    }

    function _elegibleWhitelist(WhitelistStorage.PoolId poolId, address account) internal view returns (uint) {
        return WhitelistStorage.layout().pools[poolId].elegible[account];
    }

    function _consumeWhitelist(WhitelistStorage.PoolId poolId, address account, uint amount) internal {
        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        WhitelistStorage.Pool storage pool = whitelistSL.pools[poolId];

        if (!pool.claimActive)
            revert Whitelist_ClaimInactive();

        if (pool.elegible[account] < amount) 
            revert Whitelist_ExceedsElegibleAmount();

        pool.elegible[account] -= amount;
        pool.claimed[account] += amount;
        pool.totalClaimed += amount;
        pool.totalElegible -= amount;

        emit WhitelistBalanceChanged(account, poolId, pool.elegible[account], pool.claimed[account]);
    }

    function _increaseWhitelistElegible(WhitelistStorage.PoolId poolId, address account, uint amount) internal {
        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        WhitelistStorage.Pool storage pool = whitelistSL.pools[poolId];
        pool.elegible[account] += amount;
        pool.totalElegible += amount;
        
        emit WhitelistBalanceChanged(account, poolId, pool.elegible[account], pool.claimed[account]);
    }

    function _increaseWhitelistElegibleBatch(WhitelistStorage.PoolId poolId, address[] calldata accounts, uint[] calldata amounts) internal {
        if (accounts.length != amounts.length) revert Whitelist_InputDataMismatch();

        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        WhitelistStorage.Pool storage pool = whitelistSL.pools[poolId];

        for (uint i = 0; i < accounts.length; i++) {
            pool.elegible[accounts[i]] += amounts[i];
            pool.totalElegible += amounts[i];
            emit WhitelistBalanceChanged(accounts[i], poolId, pool.elegible[accounts[i]], pool.claimed[accounts[i]]);
        }
    }

    function _setWhitelistElegible(WhitelistStorage.PoolId poolId, address account, uint amount) internal {
        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        WhitelistStorage.Pool storage pool = whitelistSL.pools[poolId];

        pool.totalElegible += amount - pool.elegible[account];
        pool.elegible[account] += amount;
        emit WhitelistBalanceChanged(account, poolId, pool.elegible[account], pool.claimed[account]);
    }

    function _setWhitelistElegibleBatch(WhitelistStorage.PoolId poolId, address[] calldata accounts, uint[] calldata amounts) internal {
        if (accounts.length != amounts.length) revert Whitelist_InputDataMismatch();

        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        WhitelistStorage.Pool storage pool = whitelistSL.pools[poolId];

        for (uint i = 0; i < accounts.length; i++) {
            pool.totalElegible += amounts[i] - pool.elegible[accounts[i]];
            pool.elegible[accounts[i]] = amounts[i];
            emit WhitelistBalanceChanged(accounts[i], poolId, pool.elegible[accounts[i]], pool.claimed[accounts[i]]);
        }
    }

    function _isWhitelistClaimActive(WhitelistStorage.PoolId poolId) view internal returns (bool) {
        return WhitelistStorage.layout().pools[poolId].claimActive;
    }

    function _setWhitelistClaimActive(WhitelistStorage.PoolId poolId, bool active) internal {
        WhitelistStorage.Layout storage whitelistSL = WhitelistStorage.layout();
        WhitelistStorage.Pool storage pool = whitelistSL.pools[poolId];
        
        pool.claimActive = active;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.19;

library WhitelistStorage {

    bytes32 constant WHITELIST_STORAGE_POSITION =
        keccak256("whitelist.storage.position");

    enum PoolId { Guaranteed, Restricted }
    
    struct Pool {
        mapping(address => uint) claimed;
        mapping(address => uint) elegible;
        uint totalClaimed;
        uint totalElegible;
        bool claimActive;
    }

    struct Layout {
        // pool id => tokens pool
        mapping(PoolId => Pool) pools;
    }

    function layout()
        internal
        pure
        returns (Layout storage es)
    {
        bytes32 position = WHITELIST_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/great-wyrm/contracts
 */

pragma solidity ^0.8.0;

import {ERC721Base, IERC721} from "@solidstate/contracts/token/ERC721/base/ERC721Base.sol";
import {ERC721Enumerable, IERC721Enumerable} from "@solidstate/contracts/token/ERC721/enumerable/ERC721Enumerable.sol";
import {IERC721Metadata} from "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import {LibDiamond} from "../diamond/libraries/LibDiamond.sol";
import {ITerminus} from "../interfaces/ITerminus.sol";

library LibCharacters {
    bytes32 constant CHARACTER_METADATA_STORAGE_POSITION =
        keccak256("great-wyrm.characters.storage");

    struct CharactersStorage {
        address InventoryAddress;
        address AdminTerminusAddress;
        uint256 AdminTerminusPoolID;
        uint256 CharacterCreationTerminusPoolID;
        string ContractName;
        string ContractSymbol;
        string ContractURI;
        // TokenID => string storing the token URI for each character
        mapping(uint256 => string) TokenURIs;
        // Token ID => bool describing whether or not the metadata for the character represented by that
        // token ID is licensed appopriately.
        mapping(uint256 => bool) MetadataValid;
    }

    /**
    Loads the DELEGATECALL-compliant storage structure for LibCharacters.
     */
    function charactersStorage()
        internal
        pure
        returns (CharactersStorage storage cs)
    {
        bytes32 position = CHARACTER_METADATA_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }
}

/**
CharactersFacet contains all the characters in the universe of Great Wyrm.
 */
contract CharactersFacet is ERC721Base, ERC721Enumerable {
    /// InventorySet is fired every time the inventory address changes on the character contract.
    event InventorySet(address inventoryAddress);
    /// ContractInformationSet is fired every time the name, symbol, or contract metadata URI are
    /// changed on the character contract.
    event ContractInformationSet(string name, string symbol, string uri);
    /// TokenURISet is fired every time a player changes the metadata URI for one of their characters.
    event TokenURISet(
        uint256 indexed tokenId,
        address indexed changer,
        string uri
    );
    /// TokenValiditySet is fired every time a game master marks a token's metadata as valid or invalid.
    event TokenValiditySet(
        uint256 indexed tokenId,
        address indexed changer,
        bool valid
    );

    /// onlyGameMaster modifies functions that can only be called by game masters.
    modifier onlyGameMaster() {
        LibCharacters.CharactersStorage storage cs = LibCharacters
            .charactersStorage();
        ITerminus adminTerminusContract = ITerminus(cs.AdminTerminusAddress);
        require(
            adminTerminusContract.balanceOf(
                msg.sender,
                cs.AdminTerminusPoolID
            ) >= 1,
            "CharactersFacet.onlyGameMaster: Message sender is not a game master"
        );
        _;
    }

    /// onlyPlayerOf modifies functions that apply to a specific character and enforces that those functions
    /// are only being called by a sender which currently controls that character.
    modifier onlyPlayerOf(uint256 tokenId) {
        require(
            msg.sender == _ownerOf(tokenId),
            "CharactersFacet.onlyPlayerOf: Message sender does not control the given character"
        );
        _;
    }

    /// supportsInterface is implemented here for deployment of the characters contract as a standalone,
    /// immutable contract. In an EIP-2535 setup, this should be served via the DiamondLoupeFacet.
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    /// Initializes a character contract by specifying:
    /// 1. An address for a Terminus contract on which the access control badges will be defined.
    /// 2. The pool ID for the game master pool on the Terminus contract specified in (1).
    /// 3. The pool ID for the Terminus pool on the Terminus contract specified in (1) from which tokens are
    ///    required in order to create new Great Wyrm characters. This requirement helps ensure that
    ///    someone doesn't just create characters on an infinite loop and overpopulate the world.
    /// 4. A name for the contract.
    /// 5. A symbol for the contract.
    /// 6. A metadata URI for the contract.
    function init(
        address adminTerminusAddress,
        uint256 adminTerminusPoolId,
        uint256 characterCreationTerminusPoolId,
        string calldata contractName,
        string calldata contractSymbol,
        string calldata contractUri
    ) public {
        LibDiamond.enforceIsContractOwner();

        LibCharacters.CharactersStorage storage cs = LibCharacters
            .charactersStorage();
        cs.AdminTerminusAddress = adminTerminusAddress;
        cs.AdminTerminusPoolID = adminTerminusPoolId;
        cs.CharacterCreationTerminusPoolID = characterCreationTerminusPoolId;
        cs.ContractName = contractName;
        cs.ContractSymbol = contractSymbol;
        cs.ContractURI = contractUri;

        emit ContractInformationSet(
            cs.ContractName,
            cs.ContractSymbol,
            cs.ContractURI
        );

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Enumerable).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
    }

    /// setInventory allows the owner of the character contract to set the address of the Inventory
    /// contract it uses.
    /// For more information about Inventory:
    /// 1. Source code: https://github.com/G7DAO/contracts/blob/cafd8ed8bfbb61d3eff3ce5b21da77063d2592df/contracts/inventory/Inventory.sol
    /// 2. Design document: https://docs.google.com/document/d/1Oa9I9b7t46_ngYp-Pady5XKEDW8M2NE9rI0GBRACZBI/edit?usp=sharing
    function setInventory(address inventoryAddress) external {
        LibDiamond.enforceIsContractOwner();

        LibCharacters.CharactersStorage storage cs = LibCharacters
            .charactersStorage();
        cs.InventoryAddress = inventoryAddress;

        emit InventorySet(inventoryAddress);
    }

    /// Returns the address of the Inventory contract (if any) that the character contract is using.
    function inventory() external view returns (address) {
        return LibCharacters.charactersStorage().InventoryAddress;
    }

    /// Allows contract owner to modify contract name, symbol, or metadata URI.
    function setContractInformation(
        string calldata contractName,
        string calldata contractSymbol,
        string calldata contractUri
    ) external {
        LibDiamond.enforceIsContractOwner();

        LibCharacters.CharactersStorage storage cs = LibCharacters
            .charactersStorage();
        cs.ContractName = contractName;
        cs.ContractSymbol = contractSymbol;
        cs.ContractURI = contractUri;

        emit ContractInformationSet(
            cs.ContractName,
            cs.ContractSymbol,
            cs.ContractURI
        );
    }

    /// Returns the contract name.
    function name() external view returns (string memory) {
        return LibCharacters.charactersStorage().ContractName;
    }

    /// Returns the contract symbol.
    function symbol() external view returns (string memory) {
        return LibCharacters.charactersStorage().ContractSymbol;
    }

    /// Returns the contract metadata URI.
    function contractURI() external view returns (string memory) {
        return LibCharacters.charactersStorage().ContractURI;
    }

    /// Returns the metadata URI for a given character (specified by tokenId). This metadata at this
    /// URI represents the character's profile in the Great Wyrm game.
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return LibCharacters.charactersStorage().TokenURIs[tokenId];
    }

    /// Allows a player to set the metadata URI for one of their characters.
    /// The `isAppropriatelyLicensed` argument is a certification from the player that the content at
    /// the metadata URI may be used by the Great Wyrm community under a CC0 license.
    function setTokenUri(
        uint256 tokenId,
        string calldata uri,
        bool isAppropriatelyLicensed
    ) external onlyPlayerOf(tokenId) {
        require(
            isAppropriatelyLicensed,
            "CharactersFacet.setTokenUri: Please set the last parameter to this function to true, to certify that the content at that URI is appropriately licensed."
        );
        LibCharacters.CharactersStorage storage cs = LibCharacters
            .charactersStorage();
        cs.TokenURIs[tokenId] = uri;
        cs.MetadataValid[tokenId] = false;

        emit TokenURISet(tokenId, msg.sender, uri);
        // We do not emit a TokenValiditySet event - that is reserved for Game Masters.
    }

    /// Checks if the metadata for a given character is valid according to the game masters of Great Wyrm.
    function isMetadataValid(uint256 tokenId) external view returns (bool) {
        return LibCharacters.charactersStorage().MetadataValid[tokenId];
    }

    /// Allows game masters to mark a character's metadata as being valid or invalid.
    function setMetadataValidity(uint256 tokenId, bool valid)
        external
        onlyGameMaster
    {
        LibCharacters.CharactersStorage storage cs = LibCharacters
            .charactersStorage();
        cs.MetadataValid[tokenId] = valid;
        emit TokenValiditySet(tokenId, msg.sender, valid);
    }

    /// Allows anyone possessing a character creation Terminus token to create a Greaty Wyrm character.
    /// The character creation Terminus token is used up in the process.
    function createCharacter(address player) external returns (uint256) {
        LibCharacters.CharactersStorage storage cs = LibCharacters
            .charactersStorage();
        ITerminus adminTerminusContract = ITerminus(cs.AdminTerminusAddress);
        adminTerminusContract.burn(
            msg.sender,
            cs.CharacterCreationTerminusPoolID,
            1
        );
        uint256 tokenId = _totalSupply() + 1;
        _mint(player, tokenId);
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";

contract Diamond {
    constructor(address _contractOwner, address _diamondCutFacet) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

contract DiamondCutFacet is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";

// The functions in DiamondLoupeFacet MUST be added to a diamond.
// The EIP-2535 Diamond standard requires these functions.

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = ds
                .facetFunctionSelectors[facetAddress_]
                .functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetFunctionSelectors_ = ds
            .facetFunctionSelectors[_facet]
            .functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        override
        returns (address[] memory facetAddresses_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = ds.facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        override
        returns (address facetAddress_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds
            .selectorToFacetAndPosition[_functionSelector]
            .facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId)
        external
        view
        override
        returns (bool)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC173} from "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(
    address _initializationContractAddress,
    bytes _calldata
);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(
            _init,
            "LibDiamondCut: _init address has no code"
        );
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface generated by solface: https://github.com/bugout-dev/solface
// solface version: 0.0.4
interface ICharacters {
	// structs

	// events
	event Approval(address owner, address operator, uint256 tokenId);
	event ApprovalForAll(address owner, address operator, bool approved);
	event ContractInformationSet(string name, string symbol, string uri);
	event InventorySet(address inventoryAddress);
	event TokenURISet(uint256 tokenId, address changer, string uri);
	event TokenValiditySet(uint256 tokenId, address changer, bool valid);
	event Transfer(address from, address to, uint256 tokenId);

	// functions
	function approve(address operator, uint256 tokenId) external ;
	function balanceOf(address account) external view returns (uint256);
	function contractURI() external view returns (string memory);
	function createCharacter(address player) external  returns (uint256);
	function getApproved(uint256 tokenId) external view returns (address);
	function init(address adminTerminusAddress, uint256 adminTerminusPoolId, uint256 characterCreationTerminusPoolId, string memory contractName, string memory contractSymbol, string memory contractUri) external ;
	function inventory() external view returns (address);
	function isApprovedForAll(address account, address operator) external view returns (bool);
	function isMetadataValid(uint256 tokenId) external view returns (bool);
	function name() external view returns (string memory);
	function ownerOf(uint256 tokenId) external view returns (address);
	function safeTransferFrom(address from, address to, uint256 tokenId) external ;
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external ;
	function setApprovalForAll(address operator, bool status) external ;
	function setContractInformation(string memory contractName, string memory contractSymbol, string memory contractUri) external ;
	function setInventory(address inventoryAddress) external ;
	function setMetadataValidity(uint256 tokenId, bool valid) external ;
	function setTokenUri(uint256 tokenId, string memory uri, bool isAppropriatelyLicensed) external ;
	function supportsInterface(bytes4 interfaceId) external pure returns (bool);
	function symbol() external view returns (string memory);
	function tokenByIndex(uint256 index) external view returns (uint256);
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
	function tokenURI(uint256 tokenId) external view returns (string memory);
	function totalSupply() external view returns (uint256);
	function transferFrom(address from, address to, uint256 tokenId) external ;

	// errors
	error AddressUtils__NotContract();
	error ERC721Base__BalanceQueryZeroAddress();
	error ERC721Base__ERC721ReceiverNotImplemented();
	error ERC721Base__InvalidOwner();
	error ERC721Base__MintToZeroAddress();
	error ERC721Base__NonExistentToken();
	error ERC721Base__NotOwnerOrApproved();
	error ERC721Base__NotTokenOwner();
	error ERC721Base__SelfApproval();
	error ERC721Base__TokenAlreadyMinted();
	error ERC721Base__TransferToZeroAddress();
	error EnumerableMap__IndexOutOfBounds();
	error EnumerableMap__NonExistentKey();
	error EnumerableSet__IndexOutOfBounds();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface generated by solface: https://github.com/bugout-dev/solface
// solface version: 0.0.4
interface ITerminus {
	// structs

	// events
	event ApprovalForAll(address account, address operator, bool approved);
	event PoolMintBatch(uint256 id, address operator, address from, address[] toAddresses, uint256[] amounts);
	event TransferBatch(address operator, address from, address to, uint256[] ids, uint256[] values);
	event TransferSingle(address operator, address from, address to, uint256 id, uint256 value);
	event URI(string value, uint256 id);

	// functions
	function approveForPool(uint256 poolID, address operator) external ;
	function balanceOf(address account, uint256 id) external view returns (uint256);
	function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns (uint256[] memory);
	function burn(address from, uint256 poolID, uint256 amount) external ;
	function contractURI() external view returns (string memory);
	function createPoolV1(uint256 _capacity, bool _transferable, bool _burnable) external  returns (uint256);
	function createSimplePool(uint256 _capacity) external  returns (uint256);
	function isApprovedForAll(address account, address operator) external view returns (bool);
	function isApprovedForPool(uint256 poolID, address operator) external view returns (bool);
	function mint(address to, uint256 poolID, uint256 amount, bytes memory data) external ;
	function mintBatch(address to, uint256[] memory poolIDs, uint256[] memory amounts, bytes memory data) external ;
	function paymentToken() external view returns (address);
	function poolBasePrice() external view returns (uint256);
	function poolIsBurnable(uint256 poolID) external view returns (bool);
	function poolIsTransferable(uint256 poolID) external view returns (bool);
	function poolMintBatch(uint256 id, address[] memory toAddresses, uint256[] memory amounts) external ;
	function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external ;
	function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external ;
	function setApprovalForAll(address operator, bool approved) external ;
	function setContractURI(string memory _contractURI) external ;
	function setController(address newController) external ;
	function setPaymentToken(address newPaymentToken) external ;
	function setPoolBasePrice(uint256 newBasePrice) external ;
	function setPoolBurnable(uint256 poolID, bool burnable) external ;
	function setPoolController(uint256 poolID, address newController) external ;
	function setPoolTransferable(uint256 poolID, bool transferable) external ;
	function setURI(uint256 poolID, string memory poolURI) external ;
	function supportsInterface(bytes4 interfaceId) external view returns (bool);
	function terminusController() external view returns (address);
	function terminusPoolCapacity(uint256 poolID) external view returns (uint256);
	function terminusPoolController(uint256 poolID) external view returns (address);
	function terminusPoolSupply(uint256 poolID) external view returns (uint256);
	function totalPools() external view returns (uint256);
	function unapproveForPool(uint256 poolID, address operator) external ;
	function uri(uint256 poolID) external view returns (string memory);
	function withdrawPayments(address toAddress, uint256 amount) external ;

	// errors
}

// SPDX-License-Identifier: UNLICENSED
///@notice This contract is for mock for WETH token.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockERC20 is ERC20Burnable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}

// SPDX-License-Identifier: UNLICENSED
///@notice This contract is for mock for terminus token (used only for cli generation).
pragma solidity ^0.8.0;

import "../terminus/TerminusFacet.sol";

contract MockTerminus is TerminusFacet {
    constructor() {}
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 */

pragma solidity ^0.8.9;

struct TerminusPool {
    address terminusAddress;
    uint256 poolId;
}

library LibTerminusController {
    bytes32 constant TERMINUS_CONTROLLER_STORAGE_POSITION =
        keccak256("moonstreamdao.eth.storage.terminus.controller");

    struct TerminusControllerStorage {
        address terminusAddress;
        TerminusPool terminusMainAdminPool;
        mapping(uint256 => TerminusPool) poolController;
    }

    function terminusControllerStorage()
        internal
        pure
        returns (TerminusControllerStorage storage es)
    {
        bytes32 position = TERMINUS_CONTROLLER_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 * This contract stands as a proxy for the Terminus contract
 * with a ability to whitelist operators by using Terminus Pools
 */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../TerminusFacet.sol";
import "../TerminusPermissions.sol";
import "./LibTerminusController.sol";
import "../TokenDrainerFacet.sol";

pragma solidity ^0.8.9;

// Permissions:
// - Contract owner can change _TERMINUS_MAIN_ADMIN_POOL_ID (+ all other operations?)
// - Holder of _TERMINUS_MAIN_ADMIN_POOL_ID can change poolControllerPoolID, create pool (+ pool operations?)
// - PoolController can: mint/burn + setURI

contract TerminusControllerFacet is TerminusPermissions, TokenDrainerFacet {
    /**
     * @dev Checks if the caller holds the Admin Pool token or PoolController of pool with poolID
     * @param poolId The poolID to check
     */
    modifier onlyPoolController(uint256 poolId) {
        TerminusPool memory pool = LibTerminusController
            .terminusControllerStorage()
            .poolController[poolId];

        TerminusPool memory adminPool = LibTerminusController
            .terminusControllerStorage()
            .terminusMainAdminPool;
        require(
            _holdsPoolToken(adminPool.terminusAddress, adminPool.poolId, 1) ||
                _holdsPoolToken(pool.terminusAddress, pool.poolId, 1),
            "TerminusControllerFacet.onlyPoolController: Sender doens't hold pool controller token"
        );
        _;
    }

    /**
     * @dev Checks if the caller holds the Admin Pool token
     */
    modifier onlyMainAdmin() {
        TerminusPool memory adminPool = LibTerminusController
            .terminusControllerStorage()
            .terminusMainAdminPool;
        require(
            _holdsPoolToken(adminPool.terminusAddress, adminPool.poolId, 1),
            "TerminusControllerFacet.onlyPoolController: Sender doens't hold pool controller token"
        );
        _;
    }

    function initTerminusController(
        address terminusAddress,
        address _TERMINUS_MAIN_ADMIN_POOL_TERMINUS_ADDRESS,
        uint256 _TERMINUS_MAIN_ADMIN_POOL_ID
    ) public {
        LibTerminusController.TerminusControllerStorage
            storage ts = LibTerminusController.terminusControllerStorage();

        ts.terminusMainAdminPool = TerminusPool(
            _TERMINUS_MAIN_ADMIN_POOL_TERMINUS_ADDRESS,
            _TERMINUS_MAIN_ADMIN_POOL_ID
        );
        ts.terminusAddress = terminusAddress;
    }

    function terminusContract() internal view returns (TerminusFacet) {
        return
            TerminusFacet(
                LibTerminusController
                    .terminusControllerStorage()
                    .terminusAddress
            );
    }

    function getTerminusPoolControllerPool(uint256 poolId)
        public
        view
        returns (TerminusPool memory)
    {
        return
            LibTerminusController.terminusControllerStorage().poolController[
                poolId
            ];
    }

    function getTerminusAddress() public view returns (address) {
        return
            LibTerminusController.terminusControllerStorage().terminusAddress;
    }

    function getTerminusMainAdminPoolId()
        public
        view
        returns (TerminusPool memory)
    {
        return
            LibTerminusController
                .terminusControllerStorage()
                .terminusMainAdminPool;
    }

    /**
     * @dev Gives permission to the holder of the  (poolControllerPoolId,terminusAddress)
     * to mint/burn/setURI for the pool with poolId
     */
    function setPoolControlPermissions(
        uint256 poolId,
        address terminusAddress,
        uint256 poolControllerPoolId
    ) public onlyMainAdmin {
        LibTerminusController.terminusControllerStorage().poolController[
                poolId
            ] = TerminusPool(terminusAddress, poolControllerPoolId);
    }

    // PROXY FUNCTIONS:

    /**
     * @dev Sets the controller of the terminus contract
     */
    function setController(address newController) external {
        LibDiamond.enforceIsContractOwner();
        terminusContract().setController(newController);
    }

    function poolMintBatch(
        uint256 id,
        address[] memory toAddresses,
        uint256[] memory amounts
    ) public onlyPoolController(id) {
        terminusContract().poolMintBatch(id, toAddresses, amounts);
    }

    function terminusController() external view returns (address) {
        return terminusContract().terminusController();
    }

    function contractURI() public view returns (string memory) {
        return terminusContract().contractURI();
    }

    function setContractURI(string memory _contractURI) external onlyMainAdmin {
        terminusContract().setContractURI(_contractURI);
    }

    function setURI(uint256 poolID, string memory poolURI)
        external
        onlyPoolController(poolID)
    {
        terminusContract().setURI(poolID, poolURI);
    }

    function totalPools() external view returns (uint256) {
        return terminusContract().totalPools();
    }

    function setPoolController(uint256 poolID, address newController)
        external
        onlyMainAdmin
    {
        terminusContract().setPoolController(poolID, newController);
    }

    function terminusPoolController(uint256 poolID)
        external
        view
        returns (address)
    {
        return terminusContract().terminusPoolController(poolID);
    }

    function terminusPoolCapacity(uint256 poolID)
        external
        view
        returns (uint256)
    {
        return terminusContract().terminusPoolCapacity(poolID);
    }

    function terminusPoolSupply(uint256 poolID)
        external
        view
        returns (uint256)
    {
        return terminusContract().terminusPoolSupply(poolID);
    }

    function isApprovedForPool(uint256 poolID, address operator)
        public
        view
        returns (bool)
    {
        return terminusContract().isApprovedForPool(poolID, operator);
    }

    function approveForPool(uint256 poolID, address operator)
        external
        onlyPoolController(poolID)
    {
        terminusContract().approveForPool(poolID, operator);
    }

    function unapproveForPool(uint256 poolID, address operator)
        external
        onlyPoolController(poolID)
    {
        terminusContract().unapproveForPool(poolID, operator);
    }

    function _approvePoolCreationPayments() internal {
        IERC20 paymentToken = IERC20(terminusContract().paymentToken());
        uint256 fee = terminusContract().poolBasePrice();
        uint256 contractBalance = paymentToken.balanceOf(address(this));
        require(
            contractBalance >= fee,
            "TerminusControllerFacet._getPoolCreationPayments: Not enough funds, pls transfet payment tokens to terminusController contract"
        );
        paymentToken.approve(getTerminusAddress(), fee);
    }

    function createSimplePool(uint256 _capacity)
        external
        onlyMainAdmin
        returns (uint256)
    {
        _approvePoolCreationPayments();
        return terminusContract().createSimplePool(_capacity);
    }

    function createPoolV1(
        uint256 _capacity,
        bool _transferable,
        bool _burnable
    ) external onlyMainAdmin returns (uint256) {
        _approvePoolCreationPayments();
        return
            terminusContract().createPoolV1(
                _capacity,
                _transferable,
                _burnable
            );
    }

    function mint(
        address to,
        uint256 poolID,
        uint256 amount,
        bytes memory data
    ) external onlyPoolController(poolID) {
        terminusContract().mint(to, poolID, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory poolIDs,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyMainAdmin {
        terminusContract().mintBatch(to, poolIDs, amounts, data);
    }

    function burn(
        address from,
        uint256 poolID,
        uint256 amount
    ) external onlyPoolController(poolID) {
        terminusContract().burn(from, poolID, amount);
    }

    function balanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        return terminusContract().balanceOf(account, id);
    }
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 * An ERC1155 implementation which uses the Moonstream DAO common storage structure for proxies.
 * EIP1155: https://eips.ethereum.org/EIPS/eip-1155
 *
 * The Moonstream contract is used to delegate calls from an EIP2535 Diamond proxy.
 *
 * This implementation is adapted from the OpenZeppelin ERC1155 implementation:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/tree/6bd6b76d1156e20e45d1016f355d154141c7e5b9/contracts/token/ERC1155
 */

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./LibTerminus.sol";

contract ERC1155WithTerminusStorage is
    Context,
    ERC165,
    IERC1155,
    IERC1155MetadataURI
{
    using Address for address;

    constructor() {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function uri(uint256 poolID)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return LibTerminus.terminusStorage().poolURI[poolID];
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155WithTerminusStorage: balance query for the zero address"
        );
        return LibTerminus.terminusStorage().poolBalances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155WithTerminusStorage: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            LibTerminus.terminusStorage().globalOperatorApprovals[account][
                operator
            ];
    }

    function isApprovedForPool(uint256 poolID, address operator)
        public
        view
        returns (bool)
    {
        return LibTerminus._isApprovedForPool(poolID, operator);
    }

    function approveForPool(uint256 poolID, address operator) external {
        LibTerminus.enforcePoolIsController(poolID, _msgSender());
        LibTerminus._approveForPool(poolID, operator);
    }

    function unapproveForPool(uint256 poolID, address operator) external {
        LibTerminus.enforcePoolIsController(poolID, _msgSender());
        LibTerminus._unapproveForPool(poolID, operator);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() ||
                isApprovedForAll(from, _msgSender()) ||
                isApprovedForPool(id, _msgSender()),
            "ERC1155WithTerminusStorage: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155WithTerminusStorage: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(
            to != address(0),
            "ERC1155WithTerminusStorage: transfer to the zero address"
        );
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        require(
            !ts.poolNotTransferable[id],
            "ERC1155WithTerminusStorage: _safeTransferFrom -- pool is not transferable"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        uint256 fromBalance = ts.poolBalances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155WithTerminusStorage: insufficient balance for transfer"
        );
        unchecked {
            ts.poolBalances[id][from] = fromBalance - amount;
        }
        ts.poolBalances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ERC1155WithTerminusStorage: ids and amounts length mismatch"
        );
        require(
            to != address(0),
            "ERC1155WithTerminusStorage: transfer to the zero address"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            require(
                !ts.poolNotTransferable[id],
                "ERC1155WithTerminusStorage: _safeBatchTransferFrom -- pool is not transferable"
            );

            uint256 fromBalance = ts.poolBalances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155WithTerminusStorage: insufficient balance for transfer"
            );
            unchecked {
                ts.poolBalances[id][from] = fromBalance - amount;
            }
            ts.poolBalances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(
            to != address(0),
            "ERC1155WithTerminusStorage: mint to the zero address"
        );
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        require(
            ts.poolSupply[id] + amount <= ts.poolCapacity[id],
            "ERC1155WithTerminusStorage: _mint -- Minted tokens would exceed pool capacity"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ts.poolSupply[id] += amount;
        ts.poolBalances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            to != address(0),
            "ERC1155WithTerminusStorage: mint to the zero address"
        );
        require(
            ids.length == amounts.length,
            "ERC1155WithTerminusStorage: ids and amounts length mismatch"
        );

        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            require(
                ts.poolSupply[ids[i]] + amounts[i] <= ts.poolCapacity[ids[i]],
                "ERC1155WithTerminusStorage: _mintBatch -- Minted tokens would exceed pool capacity"
            );
            ts.poolSupply[ids[i]] += amounts[i];
            ts.poolBalances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(
            from != address(0),
            "ERC1155WithTerminusStorage: burn from the zero address"
        );
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        require(
            ts.poolBurnable[id],
            "ERC1155WithTerminusStorage: _burn -- pool is not burnable"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        uint256 fromBalance = ts.poolBalances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155WithTerminusStorage: burn amount exceeds balance"
        );
        unchecked {
            ts.poolBalances[id][from] = fromBalance - amount;
            ts.poolSupply[id] -= amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(
            from != address(0),
            "ERC1155WithTerminusStorage: burn from the zero address"
        );
        require(
            ids.length == amounts.length,
            "ERC1155WithTerminusStorage: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                ts.poolBurnable[ids[i]],
                "ERC1155WithTerminusStorage: _burnBatch -- pool is not burnable"
            );
        }

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = ts.poolBalances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155WithTerminusStorage: burn amount exceeds balance"
            );
            unchecked {
                ts.poolBalances[id][from] = fromBalance - amount;
                ts.poolSupply[id] -= amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(
            owner != operator,
            "ERC1155WithTerminusStorage: setting approval status for self"
        );
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.globalOperatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert(
                        "ERC1155WithTerminusStorage: ERC1155Receiver rejected tokens"
                    );
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert(
                    "ERC1155WithTerminusStorage: transfer to non ERC1155Receiver implementer"
                );
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert(
                        "ERC1155WithTerminusStorage: ERC1155Receiver rejected tokens"
                    );
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert(
                    "ERC1155WithTerminusStorage: transfer to non ERC1155Receiver implementer"
                );
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 * Common storage structure and internal methods for Moonstream DAO Terminus contracts.
 * As Terminus is an extension of ERC1155, this library can also be used to implement bare ERC1155 contracts
 * using the common storage pattern (e.g. for use in diamond proxies).
 */

// TODO(zomglings): Should we support EIP1761 in addition to ERC1155 or roll our own scopes and feature flags?
// https://eips.ethereum.org/EIPS/eip-1761

pragma solidity ^0.8.9;

library LibTerminus {
    bytes32 constant TERMINUS_STORAGE_POSITION =
        keccak256("moonstreamdao.eth.storage.terminus");

    struct TerminusStorage {
        // Terminus administration
        address controller;
        bool isTerminusActive;
        uint256 currentPoolID;
        address paymentToken;
        uint256 poolBasePrice;
        // Terminus pools
        mapping(uint256 => address) poolController;
        mapping(uint256 => string) poolURI;
        mapping(uint256 => uint256) poolCapacity;
        mapping(uint256 => uint256) poolSupply;
        mapping(uint256 => mapping(address => uint256)) poolBalances;
        mapping(uint256 => bool) poolNotTransferable;
        mapping(uint256 => bool) poolBurnable;
        mapping(address => mapping(address => bool)) globalOperatorApprovals;
        mapping(uint256 => mapping(address => bool)) globalPoolOperatorApprovals;
        // Contract metadata
        string contractURI;
    }

    function terminusStorage()
        internal
        pure
        returns (TerminusStorage storage es)
    {
        bytes32 position = TERMINUS_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }

    event ControlTransferred(
        address indexed previousController,
        address indexed newController
    );

    event PoolControlTransferred(
        uint256 indexed poolID,
        address indexed previousController,
        address indexed newController
    );

    function setController(address newController) internal {
        TerminusStorage storage ts = terminusStorage();
        address previousController = ts.controller;
        ts.controller = newController;
        emit ControlTransferred(previousController, newController);
    }

    function enforceIsController() internal view {
        TerminusStorage storage ts = terminusStorage();
        require(msg.sender == ts.controller, "LibTerminus: Must be controller");
    }

    function setTerminusActive(bool active) internal {
        TerminusStorage storage ts = terminusStorage();
        ts.isTerminusActive = active;
    }

    function setPoolController(uint256 poolID, address newController) internal {
        TerminusStorage storage ts = terminusStorage();
        address previousController = ts.poolController[poolID];
        ts.poolController[poolID] = newController;
        emit PoolControlTransferred(poolID, previousController, newController);
    }

    function createSimplePool(uint256 _capacity) internal returns (uint256) {
        TerminusStorage storage ts = terminusStorage();
        uint256 poolID = ts.currentPoolID + 1;
        setPoolController(poolID, msg.sender);
        ts.poolCapacity[poolID] = _capacity;
        ts.currentPoolID++;
        return poolID;
    }

    function enforcePoolIsController(uint256 poolID, address maybeController)
        internal
        view
    {
        TerminusStorage storage ts = terminusStorage();
        require(
            ts.poolController[poolID] == maybeController,
            "LibTerminus: Must be pool controller"
        );
    }

    function _isApprovedForPool(uint256 poolID, address operator)
        internal
        view
        returns (bool)
    {
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        if (operator == ts.poolController[poolID]) {
            return true;
        } else if (ts.globalPoolOperatorApprovals[poolID][operator]) {
            return true;
        }
        return false;
    }

    function _approveForPool(uint256 poolID, address operator) internal {
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.globalPoolOperatorApprovals[poolID][operator] = true;
    }

    function _unapproveForPool(uint256 poolID, address operator) internal {
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.globalPoolOperatorApprovals[poolID][operator] = false;
    }
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 * This is an implementation of the Terminus decentralized authorization contract.
 *
 * Terminus users can create authorization pools. Each authorization pool has the following properties:
 * 1. Controller: The address that controls the pool. Initially set to be the address of the pool creator.
 * 2. Pool URI: Metadata URI for the authorization pool.
 * 3. Pool capacity: The total number of tokens that can be minted in that authorization pool.
 * 4. Pool supply: The number of tokens that have actually been minted in that authorization pool.
 * 5. Transferable: A boolean value which denotes whether or not tokens from that pool can be transfered
 *    between addresses. (Note: Implemented by TerminusStorage.poolNotTransferable since we expect most
 *    pools to be transferable. This negation is better for storage + gas since false is default value
 *    in map to bool.)
 * 6. Burnable: A boolean value which denotes whether or not tokens from that pool can be burned.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC1155WithTerminusStorage.sol";
import "./LibTerminus.sol";
import "../diamond/libraries/LibDiamond.sol";

contract TerminusFacet is ERC1155WithTerminusStorage {
    constructor() {
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.controller = msg.sender;
    }

    event PoolMintBatch(
        uint256 indexed id,
        address indexed operator,
        address from,
        address[] toAddresses,
        uint256[] amounts
    );

    function setController(address newController) external {
        LibTerminus.enforceIsController();
        LibTerminus.setController(newController);
    }

    function poolMintBatch(
        uint256 id,
        address[] memory toAddresses,
        uint256[] memory amounts
    ) public {
        require(
            toAddresses.length == amounts.length,
            "TerminusFacet: _poolMintBatch -- toAddresses and amounts length mismatch"
        );
        address operator = _msgSender();
        require(
            isApprovedForPool(id, operator),
            "TerminusFacet: poolMintBatch -- caller is neither owner nor approved"
        );

        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();

        uint256 i = 0;
        uint256 totalAmount = 0;

        for (i = 0; i < toAddresses.length; i++) {
            address to = toAddresses[i];
            uint256 amount = amounts[i];
            require(
                to != address(0),
                "TerminusFacet: _poolMintBatch -- cannot mint to zero address"
            );
            totalAmount += amount;
            ts.poolBalances[id][to] += amount;
            emit TransferSingle(operator, address(0), to, id, amount);
        }

        require(
            ts.poolSupply[id] + totalAmount <= ts.poolCapacity[id],
            "TerminusFacet: _poolMintBatch -- Minted tokens would exceed pool capacity"
        );
        ts.poolSupply[id] += totalAmount;

        emit PoolMintBatch(id, operator, address(0), toAddresses, amounts);
    }

    function terminusController() external view returns (address) {
        return LibTerminus.terminusStorage().controller;
    }

    function paymentToken() external view returns (address) {
        return LibTerminus.terminusStorage().paymentToken;
    }

    function setPaymentToken(address newPaymentToken) external {
        LibTerminus.enforceIsController();
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.paymentToken = newPaymentToken;
    }

    function poolBasePrice() external view returns (uint256) {
        return LibTerminus.terminusStorage().poolBasePrice;
    }

    function setPoolBasePrice(uint256 newBasePrice) external {
        LibTerminus.enforceIsController();
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.poolBasePrice = newBasePrice;
    }

    function _paymentTokenContract() internal view returns (IERC20) {
        address paymentTokenAddress = LibTerminus
            .terminusStorage()
            .paymentToken;
        require(
            paymentTokenAddress != address(0),
            "TerminusFacet: Payment token has not been set"
        );
        return IERC20(paymentTokenAddress);
    }

    function withdrawPayments(address toAddress, uint256 amount) external {
        LibTerminus.enforceIsController();
        require(
            _msgSender() == toAddress,
            "TerminusFacet: withdrawPayments -- Controller can only withdraw to self"
        );
        IERC20 paymentTokenContract = _paymentTokenContract();
        paymentTokenContract.transfer(toAddress, amount);
    }

    function contractURI() public view returns (string memory) {
        return LibTerminus.terminusStorage().contractURI;
    }

    function setContractURI(string memory _contractURI) external {
        LibTerminus.enforceIsController();
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.contractURI = _contractURI;
    }

    function setURI(uint256 poolID, string memory poolURI) external {
        LibTerminus.enforcePoolIsController(poolID, _msgSender());
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.poolURI[poolID] = poolURI;
    }

    function totalPools() external view returns (uint256) {
        return LibTerminus.terminusStorage().currentPoolID;
    }

    function setPoolController(uint256 poolID, address newController) external {
        LibTerminus.enforcePoolIsController(poolID, msg.sender);
        LibTerminus.setPoolController(poolID, newController);
    }

    function terminusPoolController(uint256 poolID)
        external
        view
        returns (address)
    {
        return LibTerminus.terminusStorage().poolController[poolID];
    }

    function terminusPoolCapacity(uint256 poolID)
        external
        view
        returns (uint256)
    {
        return LibTerminus.terminusStorage().poolCapacity[poolID];
    }

    function terminusPoolSupply(uint256 poolID)
        external
        view
        returns (uint256)
    {
        return LibTerminus.terminusStorage().poolSupply[poolID];
    }

    function poolIsTransferable(uint256 poolID) external view returns (bool) {
        return !LibTerminus.terminusStorage().poolNotTransferable[poolID];
    }

    function poolIsBurnable(uint256 poolID) external view returns (bool) {
        return LibTerminus.terminusStorage().poolBurnable[poolID];
    }

    function setPoolTransferable(uint256 poolID, bool transferable) external {
        LibTerminus.enforcePoolIsController(poolID, msg.sender);
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.poolNotTransferable[poolID] = !transferable;
    }

    function setPoolBurnable(uint256 poolID, bool burnable) external {
        LibTerminus.enforcePoolIsController(poolID, msg.sender);
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.poolBurnable[poolID] = burnable;
    }

    function createSimplePool(uint256 _capacity) external returns (uint256) {
        LibTerminus.enforceIsController();
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        uint256 requiredPayment = ts.poolBasePrice;
        IERC20 paymentTokenContract = _paymentTokenContract();
        require(
            paymentTokenContract.allowance(_msgSender(), address(this)) >=
                requiredPayment,
            "TerminusFacet: createSimplePool -- Insufficient allowance on payment token"
        );
        paymentTokenContract.transferFrom(
            msg.sender,
            address(this),
            requiredPayment
        );
        return LibTerminus.createSimplePool(_capacity);
    }

    function createPoolV1(
        uint256 _capacity,
        bool _transferable,
        bool _burnable
    ) external returns (uint256) {
        LibTerminus.enforceIsController();
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        // TODO(zomglings): Implement requiredPayment update based on pool features.
        uint256 requiredPayment = ts.poolBasePrice;
        IERC20 paymentTokenContract = _paymentTokenContract();
        require(
            paymentTokenContract.allowance(_msgSender(), address(this)) >=
                requiredPayment,
            "TerminusFacet: createPoolV1 -- Insufficient allowance on payment token"
        );
        paymentTokenContract.transferFrom(
            msg.sender,
            address(this),
            requiredPayment
        );
        uint256 poolID = LibTerminus.createSimplePool(_capacity);
        if (!_transferable) {
            ts.poolNotTransferable[poolID] = true;
        }
        if (_burnable) {
            ts.poolBurnable[poolID] = true;
        }
        return poolID;
    }

    function mint(
        address to,
        uint256 poolID,
        uint256 amount,
        bytes memory data
    ) external {
        require(
            isApprovedForPool(poolID, msg.sender),
            "TerminusFacet: mint -- caller is neither owner nor approved"
        );
        _mint(to, poolID, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory poolIDs,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        for (uint256 i = 0; i < poolIDs.length; i++) {
            require(
                isApprovedForPool(poolIDs[i], msg.sender),
                "TerminusFacet: mintBatch -- caller is neither owner nor approved"
            );
        }
        _mintBatch(to, poolIDs, amounts, data);
    }

    function burn(
        address from,
        uint256 poolID,
        uint256 amount
    ) external {
        address operator = _msgSender();
        require(
            operator == from || isApprovedForPool(poolID, operator),
            "TerminusFacet: burn -- caller is neither owner nor approved"
        );
        _burn(from, poolID, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 * Initializer for Terminus contract. Used when mounting a new TerminusFacet onto its diamond proxy.
 */

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "../diamond/libraries/LibDiamond.sol";
import "./LibTerminus.sol";

contract TerminusInitializer {
    function init() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC1155).interfaceId] = true;
        ds.supportedInterfaces[type(IERC1155MetadataURI).interfaceId] = true;

        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.controller = msg.sender;
    }
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TerminusFacet.sol";

pragma solidity ^0.8.9;

abstract contract TerminusPermissions {
    function _holdsPoolToken(
        address terminusAddress,
        uint256 poolId,
        uint256 _amount
    ) internal view returns (bool) {
        TerminusFacet terminus = TerminusFacet(terminusAddress);
        return terminus.balanceOf(msg.sender, poolId) >= _amount;
    }

    modifier holdsPoolToken(address terminusAddress, uint256 poolId) {
        require(
            _holdsPoolToken(terminusAddress, poolId, 1),
            "TerminusPermissions.holdsPoolToken: Sender doens't hold  pool tokens"
        );
        _;
    }

    modifier spendsPoolToken(address terminusAddress, uint256 poolId) {
        require(
            _holdsPoolToken(terminusAddress, poolId, 1),
            "TerminusPermissions.spendsPoolToken: Sender doens't hold  pool tokens"
        );
        TerminusFacet terminusContract = TerminusFacet(terminusAddress);
        terminusContract.burn(msg.sender, poolId, 1);
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 */
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../diamond/libraries/LibDiamond.sol";

contract TokenDrainerFacet {
    function drainERC20(address tokenAddress, address receiverAddress)
        external
    {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        withdrawERC20(tokenAddress, balance, receiverAddress);
    }

    function withdrawERC20(
        address tokenAddress,
        uint256 amount,
        address receiverAddress
    ) public {
        LibDiamond.enforceIsContractOwner();
        IERC20 token = IERC20(tokenAddress);
        token.transfer(receiverAddress, amount);
    }

    function drainERC1155(
        address tokenAddress,
        uint256 tokenId,
        address receiverAddress
    ) external {
        uint256 balance = IERC1155(tokenAddress).balanceOf(
            address(this),
            tokenId
        );
        withdrawERC1155(tokenAddress, tokenId, balance, receiverAddress);
    }

    function withdrawERC1155(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        address receiverAddress
    ) public {
        LibDiamond.enforceIsContractOwner();
        IERC1155 token = IERC1155(tokenAddress);
        token.safeTransferFrom(
            address(this),
            receiverAddress,
            tokenId,
            amount,
            ""
        );
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//

//import "@openzeppelin/contracts/access/Ownable.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract YourContract {
  string public purpose = "Building Unstoppable Apps!!!";

  // 🙋🏽‍♂️ this is an error handler
  // error EmptyPurposeError(uint code, string message);

  constructor() {
    // 🙋🏽‍♂️ what should we do on deploy?
  }

  // this is an event for the function below
  event SetPurpose(address sender, string purpose);

  function setPurpose(string memory newPurpose) public {
    // 🙋🏽‍♂️ you can add error handling!

    // if(bytes(newPurpose).length == 0){
    //     revert EmptyPurposeError({
    //         code: 1,
    //         message: "Purpose can not be empty"
    //     });
    // }

    purpose = newPurpose;

    emit SetPurpose(msg.sender, purpose);
  }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract YourNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() ERC721("YourNFT", "YNFT") {}

  function _baseURI() internal view virtual override returns (string memory) {
    return "https://ipfs.io/ipfs/";
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    // DO SOMETHING
    return super.tokenURI(tokenId);
  }

  function mintItem(address to, string memory tokenURI) public returns (uint256) {
    _tokenIds.increment();

    uint256 id = _tokenIds.current();
    _mint(to, id);
    _setTokenURI(id, tokenURI);

    return id;
  }
}