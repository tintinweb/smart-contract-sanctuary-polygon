// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./IErc20.sol";

/// @notice Emitted when the owner is the zero address.
error Erc20__ApproveOwnerZeroAddress();

/// @notice Emitted when the spender is the zero address.
error Erc20__ApproveSpenderZeroAddress();

/// @notice Emitted when burning more tokens than are in the account.
error Erc20__BurnUnderflow(uint256 accountBalance, uint256 burnAmount);

/// @notice Emitted when the holder is the zero address.
error Erc20__BurnZeroAddress();

/// @notice Emitted when the sender did not give the caller a sufficient allowance.
error Erc20__InsufficientAllowance(uint256 allowance, uint256 amount);

/// @notice Emitted when the beneficiary is the zero address.
error Erc20__MintZeroAddress();

/// @notice Emitted when tranferring more tokens than there are in the account.
error Erc20__TransferUnderflow(uint256 senderBalance, uint256 amount);

/// @notice Emitted when the sender is the zero address.
error Erc20__TransferSenderZeroAddress();

/// @notice Emitted when the recipient is the zero address.
error Erc20__TransferRecipientZeroAddress();

/// @title Erc20
/// @author Paul Razvan Berg
contract Erc20 is IErc20 {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IErc20
    string public override name;

    /// @inheritdoc IErc20
    string public override symbol;

    /// @inheritdoc IErc20
    uint8 public immutable override decimals;

    /// @inheritdoc IErc20
    uint256 public override totalSupply;

    /// @inheritdoc IErc20
    mapping(address => uint256) public override balanceOf;

    /// @inheritdoc IErc20
    mapping(address => mapping(address => uint256)) public override allowance;

    /// CONSTRUCTOR ///

    /// @notice All three of these values are immutable: they can only be set once during construction.
    /// @param _name Erc20 name of this token.
    /// @param _symbol Erc20 symbol of this token.
    /// @param _decimals Erc20 decimal precision of this token.
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IErc20
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        approveInternal(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IErc20
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual override returns (bool) {
        uint256 newAllowance = allowance[msg.sender][spender] - subtractedValue;
        approveInternal(msg.sender, spender, newAllowance);
        return true;
    }

    /// @inheritdoc IErc20
    function increaseAllowance(address spender, uint256 addedValue) external virtual override returns (bool) {
        uint256 newAllowance = allowance[msg.sender][spender] + addedValue;
        approveInternal(msg.sender, spender, newAllowance);
        return true;
    }

    /// @inheritdoc IErc20
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        transferInternal(msg.sender, recipient, amount);
        return true;
    }

    /// @inheritdoc IErc20
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        transferInternal(sender, recipient, amount);

        uint256 currentAllowance = allowance[sender][msg.sender];
        if (currentAllowance < amount) {
            revert Erc20__InsufficientAllowance(currentAllowance, amount);
        }
        approveInternal(sender, msg.sender, currentAllowance);
        return true;
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// This is internal function is equivalent to `approve`, and can be used to e.g. set automatic
    /// allowances for certain subsystems, etc.
    ///
    /// Requirements:
    ///
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    function approveInternal(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if (owner == address(0)) {
            revert Erc20__ApproveOwnerZeroAddress();
        }
        if (spender == address(0)) {
            revert Erc20__ApproveSpenderZeroAddress();
        }

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice Destroys `burnAmount` tokens from `holder`, reducing the token supply.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `holder` must have at least `amount` tokens.
    function burnInternal(address holder, uint256 burnAmount) internal {
        if (holder == address(0)) {
            revert Erc20__BurnZeroAddress();
        }

        uint256 accountBalance = balanceOf[holder];
        if (accountBalance < burnAmount) {
            revert Erc20__BurnUnderflow(accountBalance, burnAmount);
        }

        // Burn the tokens.
        unchecked {
            balanceOf[holder] = accountBalance - burnAmount;
        }

        // Reduce the total supply.
        totalSupply -= burnAmount;

        emit Transfer(holder, address(0), burnAmount);
    }

    /// @notice Prints new tokens into existence and assigns them to `beneficiary`, increasing the
    /// total supply.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - The beneficiary's balance and the total supply cannot overflow.
    function mintInternal(address beneficiary, uint256 mintAmount) internal {
        if (beneficiary == address(0)) {
            revert Erc20__MintZeroAddress();
        }

        /// Mint the new tokens.
        balanceOf[beneficiary] += mintAmount;

        /// Increase the total supply.
        totalSupply += mintAmount;

        emit Transfer(address(0), beneficiary, mintAmount);
    }

    /// @notice Moves `amount` tokens from `sender` to `recipient`.
    ///
    /// @dev This is internal function is equivalent to {transfer}, and can be used to e.g. implement
    /// automatic token fees, slashing mechanisms, etc.
    ///
    /// Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    function transferInternal(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        if (sender == address(0)) {
            revert Erc20__TransferSenderZeroAddress();
        }
        if (recipient == address(0)) {
            revert Erc20__TransferRecipientZeroAddress();
        }

        uint256 senderBalance = balanceOf[sender];
        if (senderBalance < amount) {
            revert Erc20__TransferUnderflow(senderBalance, amount);
        }
        unchecked {
            balanceOf[sender] = senderBalance - amount;
        }

        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: WTFPL
// solhint-disable var-name-mixedcase
pragma solidity >=0.8.4;

import "./Erc20.sol";
import "./IErc20Permit.sol";

/// @notice Emitted when the recovered owner does not match the actual owner.
error Erc20Permit__InvalidSignature(uint8 v, bytes32 r, bytes32 s);

/// @notice Emitted when the owner is the zero address.
error Erc20Permit__OwnerZeroAddress();

/// @notice Emitted when the permit expired.
error Erc20Permit__PermitExpired(uint256 deadline);

/// @notice Emitted when the recovered owner is the zero address.
error Erc20Permit__RecoveredOwnerZeroAddress();

/// @notice Emitted when the spender is the zero address.
error Erc20Permit__SpenderZeroAddress();

/// @title Erc20Permit
/// @author Paul Razvan Berg
contract Erc20Permit is
    IErc20Permit, // one dependency
    Erc20 // one dependency
{
    /// PUBLIC STORAGE ///

    /// @inheritdoc IErc20Permit
    bytes32 public immutable override DOMAIN_SEPARATOR;

    /// @inheritdoc IErc20Permit
    bytes32 public constant override PERMIT_TYPEHASH =
        0xfc77c2b9d30fe91687fd39abb7d16fcdfe1472d065740051ab8b13e4bf4a617f;

    /// @inheritdoc IErc20Permit
    mapping(address => uint256) public override nonces;

    /// @inheritdoc IErc20Permit
    string public constant override version = "1";

    /// CONSTRUCTOR ///

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) Erc20(_name, _symbol, _decimals) {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IErc20Permit
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        if (owner == address(0)) {
            revert Erc20Permit__OwnerZeroAddress();
        }
        if (spender == address(0)) {
            revert Erc20Permit__SpenderZeroAddress();
        }
        if (deadline < block.timestamp) {
            revert Erc20Permit__PermitExpired(deadline);
        }

        // It's safe to use the "+" operator here because the nonce cannot realistically overflow, ever.
        bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));
        address recoveredOwner = ecrecover(digest, v, r, s);

        if (recoveredOwner == address(0)) {
            revert Erc20Permit__RecoveredOwnerZeroAddress();
        }
        if (recoveredOwner != owner) {
            revert Erc20Permit__InvalidSignature(v, r, s);
        }

        approveInternal(owner, spender, amount);
    }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

/// @title IErc20
/// @author Paul Razvan Berg
/// @notice Implementation for the Erc20 standard.
///
/// We have followed general OpenZeppelin guidelines: functions revert instead of returning
/// `false` on failure. This behavior is nonetheless conventional and does not conflict with
/// the with the expectations of Erc20 applications.
///
/// Additionally, an {Approval} event is emitted on calls to {transferFrom}. This allows
/// applications to reconstruct the allowance for all accounts just by listening to said
/// events. Other implementations of the Erc may not emit these events, as it isn't
/// required by the specification.
///
/// Finally, the non-standard {decreaseAllowance} and {increaseAllowance} functions have been
/// added to mitigate the well-known issues around setting allowances.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/ERC20.sol
interface IErc20 {
    /// EVENTS ///

    /// @notice Emitted when an approval happens.
    /// @param owner The address of the owner of the tokens.
    /// @param spender The address of the spender.
    /// @param amount The maximum amount that can be spent.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emitted when a transfer happens.
    /// @param from The account sending the tokens.
    /// @param to The account receiving the tokens.
    /// @param amount The amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the remaining number of tokens that `spender` will be allowed to spend
    /// on behalf of `owner` through {transferFrom}. This is zero by default.
    ///
    /// @dev This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the number of decimals used to get its user representation.
    function decimals() external view returns (uint8);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    function symbol() external view returns (string memory);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may
    /// use both the old and the new allowance by unfortunate transaction ordering. One possible solution
    /// to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired
    /// value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for problems described
    /// in {Erc20Interface-approve}.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    /// - `spender` must have allowance for the caller of at least `subtractedValue`.
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for the problems described above.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `recipient` cannot be the zero address.
    /// - The caller must have a balance of at least `amount`.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount`
    /// `is then deducted from the caller's allowance.
    ///
    /// @dev Emits a {Transfer} event and an {Approval} event indicating the updated allowance. This is
    /// not required by the Erc. See the note at the beginning of {Erc20}.
    ///
    /// Requirements:
    ///
    /// - `sender` and `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    /// - The caller must have approed `sender` to spent at least `amount` tokens.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: WTFPL
// solhint-disable func-name-mixedcase
pragma solidity >=0.8.4;

import "./IErc20.sol";

/// @title IErc20Permit
/// @author Paul Razvan Berg
/// @notice Extension of Erc20 that allows token holders to use their tokens without sending any
/// transactions by setting the allowance with a signature using the `permit` method, and then spend
/// them via `transferFrom`.
/// @dev See https://eips.ethereum.org/EIPS/eip-2612.
interface IErc20Permit is IErc20 {
    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over `owner`'s tokens, assuming the latter's
    /// signed approval.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: The same issues Erc20 `approve` has related to transaction
    /// ordering also apply here.
    ///
    /// Requirements:
    ///
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    /// - `deadline` must be a timestamp in the future.
    /// - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the Eip712-formatted
    /// function arguments.
    /// - The signature must use `owner`'s current nonce.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice The Eip712 domain's keccak256 hash.
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Provides replay protection.
    function nonces(address account) external view returns (uint256);

    /// @notice keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)");
    function PERMIT_TYPEHASH() external view returns (bytes32);

    /// @notice Eip712 version of this implementation.
    function version() external view returns (string memory);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/ITicketBooth.sol";
import "./abstract/Operatable.sol";
import "./abstract/TerminalUtility.sol";

import "./libraries/Operations.sol";

import "./Tickets.sol";

/** 
  @notice 
  Manage Ticket printing, redemption, and account balances.

  @dev
  Tickets can be either represented internally staked, or as unstaked ERC-20s.
  This contract manages these two representations and the conversion between the two.

  @dev
  The total supply of a project's tickets and the balance of each account are calculated in this contract.
*/
contract TicketBooth is TerminalUtility, Operatable, ITicketBooth {
    // --- public immutable stored properties --- //

    /// @notice The Projects contract which mints ERC-721's that represent project ownership and transfers.
    IProjects public immutable override projects;

    // --- public stored properties --- //

    // Each project's ERC20 Ticket tokens.
    mapping(uint256 => ITickets) public override ticketsOf;

    // Each holder's balance of staked Tickets for each project.
    mapping(address => mapping(uint256 => uint256))
        public
        override stakedBalanceOf;

    // The total supply of 1155 tickets for each project.
    mapping(uint256 => uint256) public override stakedTotalSupplyOf;

    // The amount of each holders tickets that are locked.
    mapping(address => mapping(uint256 => uint256))
        public
        override lockedBalanceOf;

    // The amount of each holders tickets that are locked by each address.
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public
        override lockedBalanceBy;

    // --- external views --- //

    /** 
      @notice 
      The total supply of tickets for each project, including staked and unstaked tickets.

      @param _projectId The ID of the project to get the total supply of.

      @return supply The total supply.
    */
    function totalSupplyOf(uint256 _projectId)
        external
        view
        override
        returns (uint256 supply)
    {
        supply = stakedTotalSupplyOf[_projectId];
        ITickets _tickets = ticketsOf[_projectId];
        if (_tickets != ITickets(address(0)))
            supply = supply + _tickets.totalSupply();
    }

    /** 
      @notice 
      The total balance of tickets a holder has for a specified project, including staked and unstaked tickets.

      @param _holder The ticket holder to get a balance for.
      @param _projectId The project to get the `_hodler`s balance of.

      @return balance The balance.
    */
    function balanceOf(address _holder, uint256 _projectId)
        external
        view
        override
        returns (uint256 balance)
    {
        balance = stakedBalanceOf[_holder][_projectId];
        ITickets _ticket = ticketsOf[_projectId];
        if (_ticket != ITickets(address(0)))
            balance = balance + _ticket.balanceOf(_holder);
    }

    // --- external transactions --- //

    /** 
      @param _projects A Projects contract which mints ERC-721's that represent project ownership and transfers.
      @param _operatorStore A contract storing operator assignments.
      @param _terminalDirectory A directory of a project's current Juicebox terminal to receive payments in.
    */
    constructor(
        IProjects _projects,
        IOperatorStore _operatorStore,
        ITerminalDirectory _terminalDirectory
    ) Operatable(_operatorStore) TerminalUtility(_terminalDirectory) {
        projects = _projects;
    }

    /**
        @notice 
        Issues an owner's ERC-20 Tickets that'll be used when unstaking tickets.

        @dev 
        Deploys an owner's Ticket ERC-20 token contract.

        @param _projectId The ID of the project being issued tickets.
        @param _name The ERC-20's name. " Juicebox ticket" will be appended.
        @param _symbol The ERC-20's symbol. "j" will be prepended.
    */
    function issue(
        uint256 _projectId,
        string calldata _name,
        string calldata _symbol
    )
        external
        override
        requirePermission(
            projects.ownerOf(_projectId),
            _projectId,
            Operations.Issue
        )
    {
        // There must be a name.
        require((bytes(_name).length > 0), "TicketBooth::issue: EMPTY_NAME");

        // There must be a symbol.
        require(
            (bytes(_symbol).length > 0),
            "TicketBooth::issue: EMPTY_SYMBOL"
        );

        // Only one ERC20 ticket can be issued.
        require(
            ticketsOf[_projectId] == ITickets(address(0)),
            "TicketBooth::issue: ALREADY_ISSUED"
        );

        // Create the contract in this TerminalV1 contract in order to have mint and burn privileges.
        // Prepend the strings with standards.
        ticketsOf[_projectId] = new Tickets(_name, _symbol);

        emit Issue(_projectId, _name, _symbol, msg.sender);
    }

    /** 
      @notice 
      Print new tickets.

      @dev
      Only a project's current terminal can print its tickets.

      @param _holder The address receiving the new tickets.
      @param _projectId The project to which the tickets belong.
      @param _amount The amount to print.
      @param _preferUnstakedTickets Whether ERC20's should be converted automatically if they have been issued.
    */
    function print(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        bool _preferUnstakedTickets
    ) external override onlyTerminal(_projectId) {
        // An amount must be specified.
        require(_amount > 0, "TicketBooth::print: NO_OP");

        // Get a reference to the project's ERC20 tickets.
        ITickets _tickets = ticketsOf[_projectId];

        // If there exists ERC-20 tickets and the caller prefers these unstaked tickets.
        bool _shouldUnstakeTickets = _preferUnstakedTickets &&
            _tickets != ITickets(address(0));

        if (_shouldUnstakeTickets) {
            // Print the equivalent amount of ERC20s.
            _tickets.print(_holder, _amount);
        } else {
            // Add to the staked balance and total supply.
            stakedBalanceOf[_holder][_projectId] =
                stakedBalanceOf[_holder][_projectId] +
                _amount;
            stakedTotalSupplyOf[_projectId] =
                stakedTotalSupplyOf[_projectId] +
                _amount;
        }

        emit Print(
            _holder,
            _projectId,
            _amount,
            _shouldUnstakeTickets,
            _preferUnstakedTickets,
            msg.sender
        );
    }

    /** 
      @notice 
      Redeems tickets.

      @dev
      Only a project's current terminal can redeem its tickets.

      @param _holder The address that owns the tickets being redeemed.
      @param _projectId The ID of the project of the tickets being redeemed.
      @param _amount The amount of tickets being redeemed.
      @param _preferUnstaked If the preference is to redeem tickets that have been converted to ERC-20s.
    */
    function redeem(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        bool _preferUnstaked
    ) external override onlyTerminal(_projectId) {
        // Get a reference to the project's ERC20 tickets.
        ITickets _tickets = ticketsOf[_projectId];

        // Get a reference to the staked amount.
        uint256 _unlockedStakedBalance = stakedBalanceOf[_holder][_projectId] -
            lockedBalanceOf[_holder][_projectId];

        // Get a reference to the number of tickets there are.
        uint256 _unstakedBalanceOf = _tickets == ITickets(address(0))
            ? 0
            : _tickets.balanceOf(_holder);

        // There must be enough tickets.
        // Prevent potential overflow by not relying on addition.
        require(
            (_amount < _unstakedBalanceOf &&
                _amount < _unlockedStakedBalance) ||
                (_amount >= _unstakedBalanceOf &&
                    _unlockedStakedBalance >= _amount - _unstakedBalanceOf) ||
                (_amount >= _unlockedStakedBalance &&
                    _unstakedBalanceOf >= _amount - _unlockedStakedBalance),
            "TicketBooth::redeem: INSUFFICIENT_FUNDS"
        );

        // The amount of tickets to redeem.
        uint256 _unstakedTicketsToRedeem;

        // If there's no balance, redeem no tickets
        if (_unstakedBalanceOf == 0) {
            _unstakedTicketsToRedeem = 0;
            // If prefer converted, redeem tickets before redeeming staked tickets.
        } else if (_preferUnstaked) {
            _unstakedTicketsToRedeem = _unstakedBalanceOf >= _amount
                ? _amount
                : _unstakedBalanceOf;
            // Otherwise, redeem staked tickets before unstaked tickets.
        } else {
            _unstakedTicketsToRedeem = _unlockedStakedBalance >= _amount
                ? 0
                : _amount - _unlockedStakedBalance;
        }

        // The amount of staked tickets to redeem.
        uint256 _stakedTicketsToRedeem = _amount - _unstakedTicketsToRedeem;

        // Redeem the tickets.
        if (_unstakedTicketsToRedeem > 0)
            _tickets.redeem(_holder, _unstakedTicketsToRedeem);
        if (_stakedTicketsToRedeem > 0) {
            // Reduce the holders balance and the total supply.
            stakedBalanceOf[_holder][_projectId] =
                stakedBalanceOf[_holder][_projectId] -
                _stakedTicketsToRedeem;
            stakedTotalSupplyOf[_projectId] =
                stakedTotalSupplyOf[_projectId] -
                _stakedTicketsToRedeem;
        }

        emit Redeem(
            _holder,
            _projectId,
            _amount,
            _unlockedStakedBalance,
            _preferUnstaked,
            msg.sender
        );
    }

    /**
      @notice 
      Stakes ERC20 tickets by burning their supply and creating an internal staked version.

      @dev
      Only a ticket holder or an operator can stake its tickets.

      @param _holder The owner of the tickets to stake.
      @param _projectId The ID of the project whos tickets are being staked.
      @param _amount The amount of tickets to stake.
     */
    function stake(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    )
        external
        override
        requirePermissionAllowingWildcardDomain(
            _holder,
            _projectId,
            Operations.Stake
        )
    {
        // Get a reference to the project's ERC20 tickets.
        ITickets _tickets = ticketsOf[_projectId];

        // Tickets must have been issued.
        require(
            _tickets != ITickets(address(0)),
            "TicketBooth::stake: NOT_FOUND"
        );

        // Get a reference to the holder's current balance.
        uint256 _unstakedBalanceOf = _tickets.balanceOf(_holder);

        // There must be enough balance to stake.
        require(
            _unstakedBalanceOf >= _amount,
            "TicketBooth::stake: INSUFFICIENT_FUNDS"
        );

        // Redeem the equivalent amount of ERC20s.
        _tickets.redeem(_holder, _amount);

        // Add the staked amount from the holder's balance.
        stakedBalanceOf[_holder][_projectId] =
            stakedBalanceOf[_holder][_projectId] +
            _amount;

        // Add the staked amount from the project's total supply.
        stakedTotalSupplyOf[_projectId] =
            stakedTotalSupplyOf[_projectId] +
            _amount;

        emit Stake(_holder, _projectId, _amount, msg.sender);
    }

    /**
      @notice 
      Unstakes internal tickets by creating and distributing ERC20 tickets.

      @dev
      Only a ticket holder or an operator can unstake its tickets.

      @param _holder The owner of the tickets to unstake.
      @param _projectId The ID of the project whos tickets are being unstaked.
      @param _amount The amount of tickets to unstake.
     */
    function unstake(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    )
        external
        override
        requirePermissionAllowingWildcardDomain(
            _holder,
            _projectId,
            Operations.Unstake
        )
    {
        // Get a reference to the project's ERC20 tickets.
        ITickets _tickets = ticketsOf[_projectId];

        // Tickets must have been issued.
        require(
            _tickets != ITickets(address(0)),
            "TicketBooth::unstake: NOT_FOUND"
        );

        // Get a reference to the amount of unstaked tickets.
        uint256 _unlockedStakedTickets = stakedBalanceOf[_holder][_projectId] -
            lockedBalanceOf[_holder][_projectId];

        // There must be enough unlocked staked tickets to unstake.
        require(
            _unlockedStakedTickets >= _amount,
            "TicketBooth::unstake: INSUFFICIENT_FUNDS"
        );

        // Subtract the unstaked amount from the holder's balance.
        stakedBalanceOf[_holder][_projectId] =
            stakedBalanceOf[_holder][_projectId] -
            _amount;

        // Subtract the unstaked amount from the project's total supply.
        stakedTotalSupplyOf[_projectId] =
            stakedTotalSupplyOf[_projectId] -
            _amount;

        // Print the equivalent amount of ERC20s.
        _tickets.print(_holder, _amount);

        emit Unstake(_holder, _projectId, _amount, msg.sender);
    }

    /** 
      @notice 
      Lock a project's tickets, preventing them from being redeemed and from converting to ERC20s.

      @dev
      Only a ticket holder or an operator can lock its tickets.

      @param _holder The holder to lock tickets from.
      @param _projectId The ID of the project whos tickets are being locked.
      @param _amount The amount of tickets to lock.
    */
    function lock(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    )
        external
        override
        requirePermissionAllowingWildcardDomain(
            _holder,
            _projectId,
            Operations.Lock
        )
    {
        // Amount must be greater than 0.
        require(_amount > 0, "TicketBooth::lock: NO_OP");

        // The holder must have enough tickets to lock.
        require(
            stakedBalanceOf[_holder][_projectId] -
                lockedBalanceOf[_holder][_projectId] >=
                _amount,
            "TicketBooth::lock: INSUFFICIENT_FUNDS"
        );

        // Update the lock.
        lockedBalanceOf[_holder][_projectId] =
            lockedBalanceOf[_holder][_projectId] +
            _amount;
        lockedBalanceBy[msg.sender][_holder][_projectId] =
            lockedBalanceBy[msg.sender][_holder][_projectId] +
            _amount;

        emit Lock(_holder, _projectId, _amount, msg.sender);
    }

    /** 
      @notice 
      Unlock a project's tickets.

      @dev
      The address that locked the tickets must be the address that unlocks the tickets.

      @param _holder The holder to unlock tickets from.
      @param _projectId The ID of the project whos tickets are being unlocked.
      @param _amount The amount of tickets to unlock.
    */
    function unlock(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external override {
        // Amount must be greater than 0.
        require(_amount > 0, "TicketBooth::unlock: NO_OP");

        // There must be enough locked tickets to unlock.
        require(
            lockedBalanceBy[msg.sender][_holder][_projectId] >= _amount,
            "TicketBooth::unlock: INSUFFICIENT_FUNDS"
        );

        // Update the lock.
        lockedBalanceOf[_holder][_projectId] =
            lockedBalanceOf[_holder][_projectId] -
            _amount;
        lockedBalanceBy[msg.sender][_holder][_projectId] =
            lockedBalanceBy[msg.sender][_holder][_projectId] -
            _amount;

        emit Unlock(_holder, _projectId, _amount, msg.sender);
    }

    /** 
      @notice 
      Allows a ticket holder to transfer its tickets to another account, without unstaking to ERC-20s.

      @dev
      Only a ticket holder or an operator can transfer its tickets.

      @param _holder The holder to transfer tickets from.
      @param _projectId The ID of the project whos tickets are being transfered.
      @param _amount The amount of tickets to transfer.
      @param _recipient The recipient of the tickets.
    */
    function transfer(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        address _recipient
    )
        external
        override
        requirePermissionAllowingWildcardDomain(
            _holder,
            _projectId,
            Operations.Transfer
        )
    {
        // Can't transfer to the zero address.
        require(
            _recipient != address(0),
            "TicketBooth::transfer: ZERO_ADDRESS"
        );

        // An address can't transfer to itself.
        require(_holder != _recipient, "TicketBooth::transfer: IDENTITY");

        // There must be an amount to transfer.
        require(_amount > 0, "TicketBooth::transfer: NO_OP");

        // Get a reference to the amount of unlocked staked tickets.
        uint256 _unlockedStakedTickets = stakedBalanceOf[_holder][_projectId] -
            lockedBalanceOf[_holder][_projectId];

        // There must be enough unlocked staked tickets to transfer.
        require(
            _amount <= _unlockedStakedTickets,
            "TicketBooth::transfer: INSUFFICIENT_FUNDS"
        );

        // Subtract from the holder.
        stakedBalanceOf[_holder][_projectId] =
            stakedBalanceOf[_holder][_projectId] -
            _amount;

        // Add the tickets to the recipient.
        stakedBalanceOf[_recipient][_projectId] =
            stakedBalanceOf[_recipient][_projectId] +
            _amount;

        emit Transfer(_holder, _projectId, _recipient, _amount, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import '@paulrberg/contracts/token/erc20/Erc20Permit.sol';

import './interfaces/ITickets.sol';

import '@openzeppelin/contracts/access/Ownable.sol';


import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract Tickets is ERC20, ERC20Permit, Ownable, ITickets {
  using SafeMath for uint256;
  using Address for address;


  uint8 private _decimals = 9;

  address payable public multisigAddress = payable(0x72d710c1954ADBFE3e4325088388391DfD8CD831);
  address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

  mapping(address => uint256) _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) public isExcludedFromFee;
  mapping(address => bool) public isWalletLimitExempt;
  mapping(address => bool) public isTxLimitExempt;
  mapping(address => bool) public isMarketPair;
  mapping(address => bool) public isbotBlackList;
  bool public isaddLiquidity;

  uint256 public _buyLiquidityFee = 3;
  uint256 public _buyBurnFee = 1;
  uint256 public _buyTeamFee = 6;

  uint256 public _sellLiquidityFee = 3;
  uint256 public _sellBurnFee = 1;
  uint256 public _sellTeamFee = 6;

  uint256 public _liquidityShare = _buyLiquidityFee.add(_sellLiquidityFee);
  uint256 public _BurnShare = _buyBurnFee.add(_sellBurnFee);
  uint256 public _teamShare = _buyTeamFee.add(_sellTeamFee);

  uint256 public _totalTaxIfBuying;
  uint256 public _totalTaxIfSelling;
  uint256 public _totalDistributionShares;

  uint256 private _totalSupply;
  // uint256 public _maxTxAmount = _totalSupply.div(10);
  // uint256 public _walletMax = _totalSupply.div(10);
  uint256 private minimumTokensBeforeSwap = _totalSupply.div(1000000);

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapPair;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;
  bool public swapAndLiquifyByLimitOnly = false;
  bool public checkWalletLimit = true;
  uint256 public endtime;
  uint256 public feeTXtime;

  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

  event SwapETHForTokens(uint256 amountIn, address[] path);

  event SwapTokensForETH(uint256 amountIn, address[] path);

  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor(string memory _name, string memory _symbol) ERC20(_name,_symbol) ERC20Permit(_name) {

    //uniswaprouter in mumbai
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    );

    uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    uniswapV2Router = _uniswapV2Router;
    _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

    isExcludedFromFee[owner()] = true;
    isExcludedFromFee[address(this)] = true;

    _totalTaxIfBuying = _buyLiquidityFee.add(_buyBurnFee).add(_buyTeamFee);
    _totalTaxIfSelling = _sellLiquidityFee.add(_sellBurnFee).add(_sellTeamFee);
    _totalDistributionShares = _liquidityShare.add(_BurnShare).add(_teamShare);

    isWalletLimitExempt[owner()] = true;
    isWalletLimitExempt[address(uniswapPair)] = true;
    isWalletLimitExempt[address(this)] = true;

    isTxLimitExempt[owner()] = true;
    isTxLimitExempt[address(this)] = true;

    isMarketPair[address(uniswapPair)] = true;

    _balances[_msgSender()] = _totalSupply;
    emit Transfer(address(0), _msgSender(), _totalSupply);
  }

  function print(address _account, uint256 _amount) external override onlyOwner {
    return _mint(_account, _amount * 10**6);
  }


  function redeem(address _account, uint256 _amount) external override onlyOwner {
    return _burn(_account, _amount * 10**6);
  }



  //new functions
  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override(ERC20, IERC20) returns (uint256) {
    return _balances[account];
  }

  function allowance(address owner, address spender) public view override(ERC20, IERC20) returns (uint256) {
    return _allowances[owner][spender];
  }

  function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    override
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  function minimumTokensBeforeSwapAmount() public view returns (uint256) {
    return minimumTokensBeforeSwap;
  }


  function setMarketPairStatus(address account, bool newValue) public onlyOwner {
    isMarketPair[account] = newValue;
  }

  function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
    isTxLimitExempt[holder] = exempt;
  }

  function setIsExcludedFromFee(address account, bool newValue) public onlyOwner {
    isExcludedFromFee[account] = newValue;
  }

  function setBuyTaxes(
    uint256 newLiquidityTax,
    uint256 newBurnTax,
    uint256 newTeamTax
  ) external onlyOwner {
    _buyLiquidityFee = newLiquidityTax;
    _buyBurnFee = newBurnTax;
    _buyTeamFee = newTeamTax;

    _totalTaxIfBuying = _buyLiquidityFee.add(_buyBurnFee).add(_buyTeamFee);
  }

  function setSellTaxes(
    uint256 newLiquidityTax,
    uint256 newBurnTax,
    uint256 newTeamTax
  ) external onlyOwner {
    _sellLiquidityFee = newLiquidityTax;
    _sellBurnFee = newBurnTax;
    _sellTeamFee = newTeamTax;

    _totalTaxIfSelling = _sellLiquidityFee.add(_sellBurnFee).add(_sellTeamFee);
  }

  function setDistributionSettings(
    uint256 newLiquidityShare,
    uint256 newBurnShare,
    uint256 newTeamShare
  ) external onlyOwner {
    _liquidityShare = newLiquidityShare;
    _BurnShare = newBurnShare;
    _teamShare = newTeamShare;

    _totalDistributionShares = _liquidityShare.add(_BurnShare).add(_teamShare);
  }

  // function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
  //     _maxTxAmount = maxTxAmount;
  // }

  function enableDisableWalletLimit(bool newValue) external onlyOwner {
    checkWalletLimit = newValue;
  }

  function setIsWalletLimitExempt(address holder, bool exempt) external onlyOwner {
    isWalletLimitExempt[holder] = exempt;
  }

  // function setWalletLimit(uint256 newLimit) external onlyOwner {
  //     _walletMax  = newLimit;
  // }

  function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner {
    minimumTokensBeforeSwap = newLimit;
  }

  // function setdeadAddress(address newAddress) external onlyOwner() {
  //     deadAddress = payable(newAddress);
  // }

  function setmultisigAddress(address newAddress) external onlyOwner {
    multisigAddress = payable(newAddress);
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  function setSwapAndLiquifyByLimitOnly(bool newValue) public onlyOwner {
    swapAndLiquifyByLimitOnly = newValue;
  }

  function getCirculatingSupply() public view returns (uint256) {
    return _totalSupply.sub(balanceOf(deadAddress));
  }

  function transferToAddressETH(address payable recipient, uint256 amount) private {
    recipient.transfer(amount);
  }

  function changeRouterVersion(address newRouterAddress)
    public
    onlyOwner
    returns (address newPairAddress)
  {
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouterAddress);

    newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    if (newPairAddress == address(0)) //Create If Doesnt exist
    {
      newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
        address(this),
        _uniswapV2Router.WETH()
      );
    }

    uniswapPair = newPairAddress; //Set new pair address
    uniswapV2Router = _uniswapV2Router; //Set new router address

    isWalletLimitExempt[address(uniswapPair)] = true;
    isMarketPair[address(uniswapPair)] = true;
  }

  //to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}

  function transfer(address recipient, uint256 amount) public override(ERC20, IERC20) returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override(ERC20, IERC20) returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
    );
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal override {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');
    require(!isbotBlackList[sender], 'account is bot');
    if (sender == uniswapPair && recipient != owner() && !isaddLiquidity) {
      if (endtime == 0) {
        endtime = block.timestamp + feeTXtime;
      }
      if (endtime > block.timestamp) {
        isbotBlackList[recipient] = true;
      } else {
        isaddLiquidity = true;
      }
    }

    if (inSwapAndLiquify) {
      _basicTransfer(sender, recipient, amount);
    } else {
      // if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
      //     require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
      // }

      uint256 contractTokenBalance = balanceOf(address(this));
      bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

      if (
        overMinimumTokenBalance &&
        !inSwapAndLiquify &&
        !isMarketPair[sender] &&
        swapAndLiquifyEnabled
      ) {
        if (swapAndLiquifyByLimitOnly) contractTokenBalance = minimumTokensBeforeSwap;
        swapAndLiquify(contractTokenBalance);
      }

      _balances[sender] = _balances[sender].sub(amount, 'Insufficient Balance');

      uint256 finalAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient])
        ? amount
        : takeFee(sender, recipient, amount);

      // if(checkWalletLimit && !isWalletLimitExempt[recipient])
      //     require(balanceOf(recipient).add(finalAmount) <= _walletMax);

      _balances[recipient] = _balances[recipient].add(finalAmount);

      emit Transfer(sender, recipient, finalAmount);
      // return true;
    }
  }

  function _basicTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    _balances[sender] = _balances[sender].sub(amount, 'Insufficient Balance');
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
    // return true;
  }

  function swapAndLiquify(uint256 tAmount) private lockTheSwap {
    uint256 tokensForLP = tAmount.mul(_liquidityShare).div(_totalDistributionShares).div(2);
    uint256 tokensForSwap = tAmount.sub(tokensForLP);

    swapTokensForEth(tokensForSwap);
    uint256 amountReceived = address(this).balance;

    uint256 totalBNBFee = _totalDistributionShares.sub(_liquidityShare.div(2));

    uint256 amountBNBLiquidity = amountReceived.mul(_liquidityShare).div(totalBNBFee).div(2);
    uint256 amountBNBTeam = amountReceived.mul(_teamShare).div(totalBNBFee);
    uint256 amountBNBBurn = amountReceived.sub(amountBNBLiquidity).sub(amountBNBTeam);

    if (amountBNBBurn > 0) transferToAddressETH(multisigAddress, amountBNBBurn);

    if (amountBNBTeam > 0) transferToAddressETH(multisigAddress, amountBNBTeam);

    if (amountBNBLiquidity > 0 && tokensForLP > 0) addLiquidity(tokensForLP, amountBNBLiquidity);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this), // The contract
      block.timestamp
    );
    emit SwapTokensForETH(tokenAmount, path);
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      owner(),
      block.timestamp
    );
  }

  function takeFee(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (uint256) {
    uint256 feeAmount = 0;

    if (isMarketPair[sender]) {
      feeAmount = amount.mul(_totalTaxIfBuying).div(100);
    } else if (isMarketPair[recipient]) {
      feeAmount = amount.mul(_totalTaxIfSelling).div(100);
    }

    if (feeAmount > 0) {
      _balances[address(this)] = _balances[address(this)].add(feeAmount);
      emit Transfer(sender, address(this), feeAmount);
    }

    return amount.sub(feeAmount);
  }

  function setblocklist(address _account) external onlyOwner {
    if (isbotBlackList[_account]) {
      isbotBlackList[_account] = false;
    } else {
      isbotBlackList[_account] = true;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./../interfaces/IOperatable.sol";

abstract contract Operatable is IOperatable {
    modifier requirePermission(
        address _account,
        uint256 _domain,
        uint256 _index
    ) {
        require(
            msg.sender == _account ||
                operatorStore.hasPermission(
                    msg.sender,
                    _account,
                    _domain,
                    _index
                ),
            "Operatable: UNAUTHORIZED"
        );
        _;
    }

    modifier requirePermissionAllowingWildcardDomain(
        address _account,
        uint256 _domain,
        uint256 _index
    ) {
        require(
            msg.sender == _account ||
                operatorStore.hasPermission(
                    msg.sender,
                    _account,
                    _domain,
                    _index
                ) ||
                operatorStore.hasPermission(msg.sender, _account, 0, _index),
            "Operatable: UNAUTHORIZED"
        );
        _;
    }

    modifier requirePermissionAcceptingAlternateAddress(
        address _account,
        uint256 _domain,
        uint256 _index,
        address _alternate
    ) {
        require(
            msg.sender == _account ||
                operatorStore.hasPermission(
                    msg.sender,
                    _account,
                    _domain,
                    _index
                ) ||
                msg.sender == _alternate,
            "Operatable: UNAUTHORIZED"
        );
        _;
    }

    /// @notice A contract storing operator assignments.
    IOperatorStore public immutable override operatorStore;

    /** 
      @param _operatorStore A contract storing operator assignments.
    */
    constructor(IOperatorStore _operatorStore) {
        operatorStore = _operatorStore;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./../interfaces/ITerminalUtility.sol";

abstract contract TerminalUtility is ITerminalUtility {
    modifier onlyTerminal(uint256 _projectId) {
        require(
            address(terminalDirectory.terminalOf(_projectId)) == msg.sender,
            "TerminalUtility: UNAUTHORIZED"
        );
        _;
    }

    /// @notice The direct deposit terminals.
    ITerminalDirectory public immutable override terminalDirectory;

    /** 
      @param _terminalDirectory A directory of a project's current Juicebox terminal to receive payments in.
    */
    constructor(ITerminalDirectory _terminalDirectory) {
        terminalDirectory = _terminalDirectory;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ITerminalDirectory.sol";
import "./ITerminal.sol";

interface IDirectPaymentAddress {
    event Forward(
        address indexed payer,
        uint256 indexed projectId,
        address beneficiary,
        uint256 value,
        string memo,
        bool preferUnstakedTickets
    );

    function terminalDirectory() external returns (ITerminalDirectory);

    function projectId() external returns (uint256);

    function memo() external returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IOperatorStore.sol";

interface IOperatable {
    function operatorStore() external view returns (IOperatorStore);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IOperatorStore {
    event SetOperator(
        address indexed operator,
        address indexed account,
        uint256 indexed domain,
        uint256[] permissionIndexes,
        uint256 packed
    );

    function permissionsOf(
        address _operator,
        address _account,
        uint256 _domain
    ) external view returns (uint256);

    function hasPermission(
        address _operator,
        address _account,
        uint256 _domain,
        uint256 _permissionIndex
    ) external view returns (bool);

    function hasPermissions(
        address _operator,
        address _account,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external view returns (bool);

    function setOperator(
        address _operator,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external;

    function setOperators(
        address[] calldata _operators,
        uint256[] calldata _domains,
        uint256[][] calldata _permissionIndexes
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ITerminal.sol";
import "./IOperatorStore.sol";

interface IProjects is IERC721 {
    event Create(
        uint256 indexed projectId,
        address indexed owner,
        bytes32 indexed handle,
        string uri,
        ITerminal terminal,
        address caller
    );

    event SetHandle(
        uint256 indexed projectId,
        bytes32 indexed handle,
        address caller
    );

    event SetUri(uint256 indexed projectId, string uri, address caller);

    event TransferHandle(
        uint256 indexed projectId,
        address indexed to,
        bytes32 indexed handle,
        bytes32 newHandle,
        address caller
    );

    event ClaimHandle(
        address indexed account,
        uint256 indexed projectId,
        bytes32 indexed handle,
        address caller
    );

    event ChallengeHandle(
        bytes32 indexed handle,
        uint256 challengeExpiry,
        address caller
    );

    event RenewHandle(
        bytes32 indexed handle,
        uint256 indexed projectId,
        address caller
    );

    function count() external view returns (uint256);

    function uriOf(uint256 _projectId) external view returns (string memory);

    function handleOf(uint256 _projectId) external returns (bytes32 handle);

    function projectFor(bytes32 _handle) external returns (uint256 projectId);

    function transferAddressFor(bytes32 _handle)
        external
        returns (address receiver);

    function challengeExpiryOf(bytes32 _handle) external returns (uint256);

    function exists(uint256 _projectId) external view returns (bool);

    function create(
        address _owner,
        bytes32 _handle,
        string calldata _uri,
        ITerminal _terminal
    ) external returns (uint256 id);

    function setHandle(uint256 _projectId, bytes32 _handle) external;

    function setUri(uint256 _projectId, string calldata _uri) external;

    function transferHandle(
        uint256 _projectId,
        address _to,
        bytes32 _newHandle
    ) external returns (bytes32 _handle);

    function claimHandle(
        bytes32 _handle,
        address _for,
        uint256 _projectId
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './ITerminalDirectory.sol';

interface ITerminal {
  function terminalDirectory() external view returns (ITerminalDirectory);

  function migrationIsAllowed(ITerminal _terminal) external view returns (bool);

  function pay(
    uint256 _projectId,
    address _beneficiary,
    string calldata _memo,
    bool _preferUnstakedTickets
  ) external payable returns (uint256 fundingCycleId);

  function addToBalance(uint256 _projectId) external payable;

  function allowMigration(ITerminal _contract) external;

  function migrate(uint256 _projectId, ITerminal _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IDirectPaymentAddress.sol";
import "./ITerminal.sol";
import "./IProjects.sol";
import "./IProjects.sol";

interface ITerminalDirectory {
    event DeployAddress(
        uint256 indexed projectId,
        string memo,
        address indexed caller
    );

    event SetTerminal(
        uint256 indexed projectId,
        ITerminal indexed terminal,
        address caller
    );

    event SetPayerPreferences(
        address indexed account,
        address beneficiary,
        bool preferUnstakedTickets
    );

    function projects() external view returns (IProjects);

    function terminalOf(uint256 _projectId) external view returns (ITerminal);

    function beneficiaryOf(address _account) external returns (address);

    function unstakedTicketsPreferenceOf(address _account)
        external
        returns (bool);

    function addressesOf(uint256 _projectId)
        external
        view
        returns (IDirectPaymentAddress[] memory);

    function deployAddress(uint256 _projectId, string calldata _memo) external;

    function setTerminal(uint256 _projectId, ITerminal _terminal) external;

    function setPayerPreferences(
        address _beneficiary,
        bool _preferUnstakedTickets
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ITerminalDirectory.sol";

interface ITerminalUtility {
    function terminalDirectory() external view returns (ITerminalDirectory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IProjects.sol";
import "./IOperatorStore.sol";
import "./ITickets.sol";

interface ITicketBooth {
    event Issue(
        uint256 indexed projectId,
        string name,
        string symbol,
        address caller
    );
    event Print(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        bool convertedTickets,
        bool preferUnstakedTickets,
        address controller
    );

    event Redeem(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        uint256 stakedTickets,
        bool preferUnstaked,
        address controller
    );

    event Stake(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Unstake(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Lock(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Unlock(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Transfer(
        address indexed holder,
        uint256 indexed projectId,
        address indexed recipient,
        uint256 amount,
        address caller
    );

    function ticketsOf(uint256 _projectId) external view returns (ITickets);

    function projects() external view returns (IProjects);

    function lockedBalanceOf(address _holder, uint256 _projectId)
        external
        view
        returns (uint256);

    function lockedBalanceBy(
        address _operator,
        address _holder,
        uint256 _projectId
    ) external view returns (uint256);

    function stakedBalanceOf(address _holder, uint256 _projectId)
        external
        view
        returns (uint256);

    function stakedTotalSupplyOf(uint256 _projectId)
        external
        view
        returns (uint256);

    function totalSupplyOf(uint256 _projectId) external view returns (uint256);

    function balanceOf(address _holder, uint256 _projectId)
        external
        view
        returns (uint256 _result);

    function issue(
        uint256 _projectId,
        string calldata _name,
        string calldata _symbol
    ) external;

    function print(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        bool _preferUnstakedTickets
    ) external;

    function redeem(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        bool _preferUnstaked
    ) external;

    function stake(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function unstake(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function lock(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function unlock(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function transfer(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        address _recipient
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITickets is IERC20 {
    function print(address _account, uint256 _amount) external;

    function redeem(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library Operations {
  uint256 public constant Configure = 1;
  uint256 public constant PrintPreminedTickets = 2;
  uint256 public constant Redeem = 3;
  uint256 public constant Migrate = 4;
  uint256 public constant SetHandle = 5;
  uint256 public constant SetUri = 6;
  uint256 public constant ClaimHandle = 7;
  uint256 public constant RenewHandle = 8;
  uint256 public constant Issue = 9;
  uint256 public constant Stake = 10;
  uint256 public constant Unstake = 11;
  uint256 public constant Transfer = 12;
  uint256 public constant Lock = 13;
  uint256 public constant SetPayoutMods = 14;
  uint256 public constant SetTicketMods = 15;
  uint256 public constant SetTerminal = 16;
  uint256 public constant PrintTickets = 17;
}