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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
pragma solidity ^0.8.4;

import "./interfaces/IPalletMinter.sol";
import "./interfaces/IPalletRegistry.sol";
import "./interfaces/IPalletLocker.sol";
import "./interfaces/IChamberOfCommerce.sol";
import "./SafeERC20.sol";

import { IPalletRegistryEvents } from "./interfaces/IEvents.sol";

contract PalletRegistry is IPalletRegistry, IPalletRegistryEvents {
    using SafeERC20 for IERC20;
    IPalletMinter public palletMinter;
    IChamberOfCommerce public chamberOfCommerce;
    address public depositToken; // xGET or GET
    // palletIndex => struct PalletStruct
    mapping(uint256 => PalletStruct) public pallets;

    constructor(
        address _palletMinter,
        address _chamberOfCommerce
    ) {
        palletMinter = IPalletMinter(_palletMinter);
        chamberOfCommerce = IChamberOfCommerce(_chamberOfCommerce);
        depositToken = chamberOfCommerce.depositToken();
    }

    modifier isChamberPaused() {
        require(
            !chamberOfCommerce.isChamberPaused(),
            "PalletRegistry:Chamber is paused"
        );
        _;
    }

    // check if allowed to create pallet (importer / borrower)
    modifier isCallerBorrower() {
        require(
            chamberOfCommerce.isAddressBorrower(msg.sender),
            "PalletRegistry:isCallerBorrower:Operator not valid borrower/importer"
        );
        _;
    }

    modifier isDAOController() {
        require(
            IChamberOfCommerce(chamberOfCommerce).isDAOController(msg.sender),
            "PalletRegistry:Caller not a DAO controller"
        );
        _;
    }

    modifier onlyClearingHouse() {
        require(
            msg.sender == IChamberOfCommerce(chamberOfCommerce).clearingHouse(),
            "PalletRegistry:Caller not clearinghouse"
        );
        _;
    }

    /// Step 1. 
    /// @notice mints a palletIndex to the caller
    /// @dev function requires a approval of xGET of the caller to the registry
    /// @dev caller needs to be approved by COC (as a borrower, as whitelisted)
    /// @param _depositTokenAmount amount of xGET that will be used as collateral for the pallet (the deposited amount)
    /// @return _palletIndex returns the index of the minted pallet
    function mintPalletAndDeposit(
        uint256 _depositTokenAmount
    ) external isCallerBorrower isChamberPaused returns(uint256 _palletIndex) {
        require(
            _depositTokenAmount > 0,
            "PalletRegistry:It is required to deposit at least 1 gwei xGET"
        );
        // fetch the palletLocker of the caller, as it will be the destination for the xGET deposit
        address _palletLockerAddress = chamberOfCommerce.returnPalletLocker(msg.sender);
        // redundant check - ensuring that the palletLocker is properly configured
        require(
            IPalletLocker(_palletLockerAddress).safeAddress() == msg.sender, 
            "PalletRegistry:Palletlocker not owned by caller"
        );
        _palletIndex = palletMinter.mintPalletAndDeposit(msg.sender);
        PalletStruct storage _pallet = pallets[_palletIndex];
        _pallet.depositTokenAddress = depositToken;
        _pallet.safeAddressIssuer = msg.sender;
        _pallet.palletLocker = _palletLockerAddress;
        _pallet.depositedDepositTokens = _depositTokenAmount;
        _pallet.palletState = PalletState.UN_REGISTERED;

        // transfer the xGET tokens to the PalletLocker of the caller - REQUIRES APPROVAL of xGET to this PR beforehand
        IERC20(depositToken).safeTransferFrom(
            msg.sender, 
            _palletLockerAddress,
            _depositTokenAmount
        );
        emit PalletMinted(
            _palletIndex, 
            msg.sender,
            _depositTokenAmount
        );
    }

    /**
     * Function that adds xGET to an already existing pallet deposit balance in pallet locker
     */
    function addTokensToPallet(
        uint256 _palletIndex,
        uint256 _extraDepositTokens
    ) external isCallerBorrower isChamberPaused {
        require(
            _extraDepositTokens > 0,
            "PalletRegistry:Invalid depositToken amount"
        );
        // check if the pallet exists and is issued by the caller
        _isIssuerCheck(_palletIndex);
        /**
         * We do not check if the caller currently owns the pallet, since it would also be fine if the pallet is already in the clearinghouse.
         */
        address palletLockerAddress_ = chamberOfCommerce.returnPalletLocker(msg.sender);
        // redundantCheck, ensuring that xGET isn't sent to a unconfigured or wrong locker
        require(
            IPalletLocker(palletLockerAddress_).safeAddress() == msg.sender, 
            "PalletRegistry:Palletlocker not owned by caller"
        );
        // in case this error comes up, it isn't possible anymore to add tokens to the pallet. Either burn and remint, or not do the addition in this case
        require(
            pallets[_palletIndex].depositTokenAddress == depositToken,
            "PalletRegistry:Global deposit token has changed"
        );
        PalletState state_ = pallets[_palletIndex].palletState;
        require(
            (state_ != PalletState.NON_EXISTANT || state_ != PalletState.DISCARDED),
            "PalletRegistry:Pallet in invalid state"
        );
        // add additional deposited xGET to total deposited
        pallets[_palletIndex].depositedDepositTokens += _extraDepositTokens;
        // transfer the xGET tokens to the PalletLocker
        IERC20(depositToken).safeTransferFrom(
            msg.sender, 
            palletLockerAddress_,
            _extraDepositTokens
        );
        emit DepositTokensAdded(
            _palletIndex,
            _extraDepositTokens
        );
    }

    /**
     * This function burns the pallet and returns the deposited GET to the burners wallet
     * @dev can only be called by the creator of a pallet. also the caller must have the pallet in their wallet
     * @dev by owning a pallet, we can infer that the pallet isn't used as collateral
     */
    function burnPalletManual(
        uint256 _palletIndex
    ) external isCallerBorrower isChamberPaused {
        _isIssuerCheck(_palletIndex);
        // caller must own the pallet if they want to burn it
        _ownerOfCheck(_palletIndex, msg.sender);
        _unwindPalletForIssuer(_palletIndex);
        emit PalletBurnedManual(_palletIndex);
    }

    function _unwindPalletForIssuer(uint256 _palletIndex) internal {
        emit PalletUnwindIssuer(
            _palletIndex,
            _unwindPallet(
                _palletIndex, 
                pallets[_palletIndex].safeAddressIssuer
                )
        );
    }

    /**
     * Internal function that unwids a pallet. Meaning that it burns the pallet and transfers the deposited xGET to a recipient address. 
     * @param _palletIndex the index of the pallet
     * @param _recipientDeposit the address that will receive the deposited xGET of the pallet
     * 
     */
    function _unwindPallet(
        uint256 _palletIndex,
        address _recipientDeposit
        ) internal returns(uint256 amountWithdrawn_) {
        amountWithdrawn_ = pallets[_palletIndex].depositedDepositTokens;
        address palletLockerAddress_ = pallets[_palletIndex].palletLocker;
        pallets[_palletIndex].palletState = PalletState.DISCARDED;
        pallets[_palletIndex].depositedDepositTokens = uint256(0);     
        // transfer the deposited tokens to the caller/burner
        _pullFromLockerTo(
            palletLockerAddress_,
            pallets[_palletIndex].depositTokenAddress,
            _recipientDeposit,
            amountWithdrawn_
        );
        // TODO add a comment
        palletMinter.burnPallet(_palletIndex);
        emit UnwindPallet(
            _palletIndex,
            amountWithdrawn_,
            _recipientDeposit,
            palletLockerAddress_
        );
    }

    /**
     * function unwinds the deposited GET on a pallet, sends the xGET to the issuer of the pallet
     * @param _palletIndex the pallet index of the the collateral that is being unwound
     * @dev can only be called by the Clearinghouse
     * @dev only works if the clearinghouse transfers the pallet to the PR before calling the function
     */
    function burnPalletClearingHouse(
        uint256 _palletIndex
    ) external onlyClearingHouse {
        // check if the pallet is sitting in this contract
        _ownerOfCheck(_palletIndex, address(this));
        // TODO add a comment
        _unwindPalletForIssuer(_palletIndex);
        emit UnwindIssuer(_palletIndex);
    }
    
    // TODO add a comment
    function unwindPalletLiquidator(
        uint256 _palletIndex,
        address _recipientLiquidator
    ) external onlyClearingHouse {
        // check if the pallet is sitting in this contract
        _ownerOfCheck(_palletIndex, address(this));
        // TODO add a comment
        _unwindPallet(_palletIndex, _recipientLiquidator);
        emit PalletUnwindLiquidation(
            _palletIndex,
            _recipientLiquidator
        );
    }

    function changeDepositToken() external isDAOController {
        depositToken = chamberOfCommerce.depositToken();
        emit DepositTokenChange(depositToken);
    }

    /**
     * @param _eventAddress address of the EventImplementation contract of the event
     * @dev this function assumes that the caller is allowed to register tickets to the pallet. This means that any whitelisted caller is able to register inventory. Hence the pallet approval/judging tx is needed.
     */
    function registerEventToPallet(
        uint256 _palletIndex,
        address _eventAddress,
        uint64 _maxAmountInventory,
        uint64 _averagePriceInventory
    ) external isCallerBorrower isChamberPaused {
        // check if the caller is the original issuer of the pallet
        _isIssuerCheck(_palletIndex);
        // for registration the pallet needs to be owned by he caller
        _ownerOfCheck(_palletIndex, msg.sender);
        // eventAddress must be a contract - also it cannot be address(0x0). This require checks both
        require(
            _eventAddress.code.length > 0,
            "PalletRegistry:EventAddress must be a contract" 
        );
        PalletStruct storage _pallet = pallets[_palletIndex];
        _pallet.maxAmountInventory = _maxAmountInventory;
        _pallet.averagePriceInventory = _averagePriceInventory;
        _pallet.eventAddress = _eventAddress;
        _pallet.palletState = PalletState.REGISTERED;
        emit RegisterEventToPallet(
            _palletIndex,
            _eventAddress
        );
    }

    /**
     * In the verification step a entity of the DAO checks, by running through off-line resources.
     * The following is checked:
     * - Is the eventAddress deployed by the ticketeer that is borrowing
     * - Is the inventory properly configured, is the metadata set
     * - Check the status of the event, the EO, does the borrower understand what the consequences are of collateralization of inventory
     * @param _palletIndex index of the pallet being judged by the DAO
     * @param _ruling verdict about the pallet, with true meaning VERIFIED, and false being REJECTED
     */
    function judgePallet(
        uint256 _palletIndex,
        bool _ruling,
        bool _fuelCheck
    ) external isChamberPaused isDAOController {
        _palletExistsCheck(_palletIndex);
        require(
            pallets[_palletIndex].palletState == PalletState.REGISTERED, 
            "PalletRegistry:Invalid pallet state to judge"
        );
        PalletState state_;
        // if _ruling is true, the DAO verifies the pallet
        if (_ruling) {
            state_ = PalletState.VERIFIED;
            // if _fuelCheck is true, t
            if (_fuelCheck) _fuelBalanceCheck(_palletIndex);
        } else { 
            // if _ruling is false, the pallet is discarded 
            state_ = PalletState.DISCARDED;
            // a discarded pallet is useless, so the deposited xGET will now be returned to the pallet issuers address automatically
            // fetch the address of the issuer/minter of the pallet
            // since the pallet is DISCARDED, the xGET is returned to the palletIssuerAddress
            _unwindPallet(_palletIndex, pallets[_palletIndex].safeAddressIssuer);
        }
        pallets[_palletIndex].palletState = state_;
        emit PalletJudged(
            _palletIndex, 
            _ruling
        ); 
    }

    function _fuelBalanceCheck(uint256 _palletIndex) internal {
        // TODO check if this is the beste way to go about this memory wise
        PalletStruct memory info_ = pallets[_palletIndex];
        if (chamberOfCommerce.isFuelAndCollateralSufficient(
                info_.safeAddressIssuer, 
                info_.maxAmountInventory, 
                info_.averagePriceInventory,
                info_.depositedDepositTokens
            )) {
                pallets[_palletIndex].fuelAndCollateralCheck = true;
                emit BalanceCheck(
                    _palletIndex,
                    true
                );
        } else {
            pallets[_palletIndex].fuelAndCollateralCheck = false;
            emit BalanceCheck(
                _palletIndex,
                false
            );
        }
    }

    /**
     * Internal function that pulls xGET from a EFM-Actors locker and transfers it to the recipient address
     * @param _palletLockerAddress address of the palletLocker xGET will be pulled from
     * @param _toAddress the recipient of the pull xGET tokens
     * @param _stakeDepositAmount amount of xGET that will be pulled from the locker
     * @dev all checks to the validity of this pull should be done in the primary function (so the function calling this internal function)
     */
    function _pullFromLockerTo(
        address _palletLockerAddress,
        address _palletDepositTokenAddress,
        address _toAddress,
        uint256 _stakeDepositAmount
        ) internal {
            // pull the xGET from the locker and transfer it to this contract (the PalletRegistry)
            IPalletLocker(_palletLockerAddress).pullAmountToPalletRegistry(
                _palletDepositTokenAddress,
                _stakeDepositAmount
            ); // the xGET now resides in this contract  (the PalletRegistry)
            // transfer the tokens from the PR contract to the recipient address
            IERC20(depositToken).safeTransfer(
                _toAddress,
                _stakeDepositAmount
            );
            emit WithdrawPalletLocker(
                _palletDepositTokenAddress,
                _toAddress,
                _stakeDepositAmount
            );
    }

    /**
     * @dev if the palletIndex doesn't exist, the call will fail with a _palletExistsCheck error
     */
    function isPalletVerfied(
        uint256 _palletIndex
    ) external view returns(bool isVerified_) {
        _palletExistsCheck(_palletIndex);
        isVerified_ = pallets[_palletIndex].palletState == PalletState.VERIFIED;
    }

    function _ownerOfCheck(uint256 _palletIndex, address _ownerAddress) internal view {
        require(
            palletMinter.ownerOf(_palletIndex) == _ownerAddress,
            "PalletRegistry:Invalid owner of pallet"
        );
    }

    function _palletExistsCheck(uint256 _palletIndex) internal view {
        require(
            palletExists(_palletIndex),
            "PalletRegistry:Pallet does not exist"
        );
    }

    /**
     * Returns if the palletIndex belongs to the safeAddressIssuer. Basically did _palletIssuerAddress mint the _palletIndex
     * @dev if the palletIndex doesn't exist, the call will fail with a _palletExistsCheck error
     */ 
    function isPalletIssuer(
        uint256 _palletIndex,
        address _palletIssuerAddress
    ) public view returns(bool _isIssuer) {
        _palletExistsCheck(_palletIndex);
        _isIssuer = pallets[_palletIndex].safeAddressIssuer == _palletIssuerAddress;
    }

    /**
     * @dev if the palletIndex doesn't exist, the call will fail with a _palletExistsCheck error
     */
    function returnPalletEvent(
        uint256 _palletIndex
    ) external view returns(address eventAddress_) {
        _palletExistsCheck(_palletIndex);
        eventAddress_ = pallets[_palletIndex].eventAddress;
    }

    /**
     * @dev if the palletIndex doesn't exist, the call will fail with a _palletExistsCheck error
     */
    function returnPalletInfo(
        uint256 _palletIndex
    ) external view returns(PalletStruct memory info_) {
        _palletExistsCheck(_palletIndex);
        info_ = pallets[_palletIndex];
    }

    function canRegisterPalletInOffering(
        uint256 _palletIndex,
        address _addressOf
    ) external view returns(bool canRegister_) {
        canRegister_ = (
            palletExists(_palletIndex) && 
            (pallets[_palletIndex].safeAddressIssuer == _addressOf) && 
            (pallets[_palletIndex].palletState == PalletState.VERIFIED) && 
            (_addressOf == palletMinter.ownerOf(_palletIndex))
            );
    }

    function ownerOf(
        uint256 _palletIndex
    ) external view returns(address owner_) {
        owner_ = palletMinter.ownerOf(_palletIndex);
    }

    function palletExists(
        uint256 _palletIndex
    ) public view returns(bool exists_) {
        exists_ = palletMinter.palletExists(_palletIndex);
    }

    function _isIssuerCheck(uint256 _palletIndex) internal view {
        require(
            isPalletIssuer(_palletIndex, msg.sender),
            "PalletRegistry:Only issuer can do this action"
        );
    }

    /**
     * Emergency function that transfers any funds in this wallet to the emergencyMultisig
     * @param _withdrawTokenAddress address of the ERC20 token that will be withdrawn to the emergencyMultisig
     * @param _amountToWithdraw amount of tokens to withdraw
     * @dev can only be called by a DAO controller
     */
    function withdrawTokensToEmergencyWallet(
        address _withdrawTokenAddress,
        uint256 _amountToWithdraw
    ) external isDAOController {
        address emergencyAddress_ = IChamberOfCommerce(chamberOfCommerce).emergencyMultisig();
        IERC20(_withdrawTokenAddress).transfer(emergencyAddress_, _amountToWithdraw);
        emit EmergencyWithdraw(
            _withdrawTokenAddress,
            msg.sender,
            _amountToWithdraw
        );
    }

    // FOR TESTING PURPOSES
    function returnPalletMinter() external view returns(address palletMinter_) {
        palletMinter_ = address(palletMinter);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ITellerV2DataTypes, IEconomicsDataTypes } from "./IDataTypes.sol";

interface IChamberOfCommerce is ITellerV2DataTypes, IEconomicsDataTypes {
    function bondCouncil() external view returns(address);
    function fuelToken() external returns(address);
    function depositToken() external returns(address);
    function tellerContract() external returns(address);
    function clearingHouse() external returns(address);
    function ticketSaleOracle() external returns(address);
    function economics() external returns(address);
    function palletRegistry() external returns(address);
    function palletMinter() external returns(address);
    function tellerKeeper() external returns(address);
    function returnPalletLocker(address _safeAddress) external view returns(address _palletLocker);
    function isChamberPaused() external view returns (bool);

    function returnIntegratorData(
        uint32 _integratorIndex
    )  external view returns(IntegratorData memory data_);

    function isAddressBorrower(
        address _addressSafeBorrower
    ) external view returns(bool);

    function isAccountWhitelisted(
        address _addressAccount
    ) external view returns(bool);

    function isAccountBlacklisted(
        address _addressAccount
    ) external view returns(bool);

    function returnPalletEvent(
        uint256 _palletIndex
    ) external view returns(address eventAddress_);

    function viewIntegratorUSDBalance(
        uint32 _integratorIndex
    ) external view returns (uint256 balance_);

    function emergencyMultisig() external view returns(address);

    function returnIntegratorIndexByRelayer(
        address _relayerAddress
    ) external view returns(uint32 integratorIndex_);

    function isDAOController(
        address _challenedController
    ) external view returns(bool);

    function isFuelAndCollateralSufficient(
        address _palletIssuerAddress, 
        uint64 _maxAmountInventory, 
        uint64 _averagePriceInventory,
        uint256 _amountPallet) external view returns(bool judgement_);


    function getIntegratorFuelPrice(
        uint32 _integratorIndex
    ) external view returns(uint256 _price);

    function palletIndexToBid(
        uint256 _palletIndex
    ) external view returns(uint256 _bidId);

    // EXTERNALCALL TO ORACLE
    function nftsIssuedForEvent(
        address _eventAddress
    ) external view returns(uint32 _ticketCount);

    // EXTERNALCALL TO ORACLE
    function isCountFinalized(
        address _eventAddress
    ) external view returns(bool _isFinalized);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IChamberOfCommerceDataTypes {

    // ChamberOfCommerce
    enum AccountType {
        NOT_SET,
        BORROWER,
        LENDER
    }

    enum AccountStatus {
        NONE,
        REGISTERED,
        WHITELISTED,
        BLACKLIST
    }

    struct ActorAccount {
        // uint256 actorIndex;
        uint32 integratorIndex;
        AccountStatus status;
        AccountType accountType;
        address palletLocker;
        // address stakeLocker;
        address relayerAddress;
        string nickName;
        string uriGeneral;
        string uriTerms;
    }

    struct CreditScore {
        uint256 minimumDeposit;
        uint24 fuelRequirement; // 100% = 1_000_000 = 1e6
    }
}

interface IEventImplementationDataTypes {

    enum TicketFlags {
        SCANNED, // 0
        CHECKED_IN, // 1
        INVALIDATED, // 2
        CLAIMED // 3
    }

    struct BalanceUpdates {
        address owner;
        uint64 quantity;
    }

    struct TokenData {
        address owner;
        uint40 basePrice;
        uint8 booleanFlags;
    }

    struct AddressData {
        // uint64 more than enough
        uint64 balance;
    }

    struct EventData {
        uint32 index;
        uint64 startTime;
        uint64 endTime;
        int32 latitude;
        int32 longitude;
        string currency;
        string name;
        string shopUrl;
        string imageUrl;
    }

    struct TicketAction {
        uint256 tokenId;
        bytes32 externalId; // sha256 hashed, emitted in event only.
        address to;
        uint64 orderTime;
        uint40 basePrice;
    }

    struct EventFinancing {
        uint64 palletIndex;
        address bondCouncil;
        bool inventoryRegistered;
        bool financingActive;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }
}


interface IBondCouncilDataTypes is IEventImplementationDataTypes {
    /**
     * @notice What happens to the collateral after a certain 'bond state' is a Policy. The Policy struct defines the consequence on the actions of the collateral
     * @param isPolicy bool that tracks 'if a policy exists'. Should always be set to True if a Policy is set
     * @param primaryBlocked if the NFTs can be sold on the primary market if the Policy is active. True means that the NFTs cannot be sold on the primary market.
     * Same principle of True/False relation to possible ticket-actions is the case for the other bools in this struct.
     */
    struct Policy {
        bool isPolicy;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }

    /**
     * @param verified bool indicating if the TB is verified by the DAO
     * @param eventAddress address of the Event (EventImplementation proxy) 
     * @param policyDuringLoan integer of the Policy that will be executed after the offering is ACCEPTED (so during the duration of the loan/bond)
     * @param policyAfterLiquidation integer of the Policy that will be executed if the offering is LIQUIDATED (so this is the consequence of not repaying the loan/bond)
     * @param flushstruct this is a copy of the EventFinancing struct in EventImplementation. 
     * @dev when a configuration is 'flushed' this means that the flushstruct is pushed to the EventImplementation contract. 
     */
    struct InventoryProcedure {
        bool verified;
        address eventAddress;
        uint256 policyDuringLoan;
        uint256 policyAfterLiquidation;
        EventFinancing flushstruct;
    }

    /**
     * XXXX ADD DESCRIPTION
     * @param INACTIVE XXX
     * @param DURING XXX
     * @param LIQUIDATED XXX
     * @param REPAID XXX
     */
    enum CollateralizationStage {
        INACTIVE,
        DURING,
        LIQUIDATED,
        REPAID
    }
}

interface IClearingHouseDataTypes {

    /**
     * Struct encoding the status of the collateral/loan/bid offering.
     * @param NONE offering isn't registered at all (doesn't exist)
     * @param READY the pallet is ready to be used as collateral
     * @param ACTIVE the pallet is being used as collateral
     * @param COMPLETED the pallet is returned to the bond issuer (the offering is completed, loan has been repaid)
     * @param DEFAULTED the pallet is sent to the lender because the loan/bond wasn't repaid. The offering isn't active anymore
     */
    enum OfferingStatus {
        NONE,
        READY,
        ACTIVE,
        COMPLETED,
        DEFAULTED
    }
}

interface IEconomicsDataTypes {
    struct IntegratorData {
        uint32 index;
        uint32 activeTicketCount;
        bool isBillingEnabled;
        bool isConfigured;
        uint256 price;
        uint256 availableFuel;
        uint256 reservedFuel;
        uint256 reservedFuelProtocol;
        string name;
    }

    struct RelayerData {
        uint32 integratorIndex;
    }

    struct DynamicRates {
        uint24 minFeePrimary;
        uint24 maxFeePrimary;
        uint24 primaryRate;
        uint24 minFeeSecondary;
        uint24 maxFeeSecondary;
        uint24 secondaryRate;
        uint24 salesTaxRate;
    }
}

interface PalletRegistryDataTypes {

    enum PalletState {
        NON_EXISTANT,
        UN_REGISTERED, // 'pallet is unregistered to an event'
        REGISTERED, // 'pallet is registered to an event'
        VERIFIED, // pallet is now sealed
        DISCARDED // end state
    }

    struct PalletStruct {
        address depositTokenAddress;
        uint64 maxAmountInventory;
        uint64 averagePriceInventory;
        bool fuelAndCollateralCheck;
        address safeAddressIssuer;
        address palletLocker;
        uint256 depositedDepositTokens;
        PalletState palletState;
        address eventAddress;
    }
}

interface ITellerV2DataTypes {
    enum BidState {
        NONEXISTENT,
        PENDING,
        CANCELLED,
        ACCEPTED,
        PAID,
        LIQUIDATED
    }
    
    struct Payment {
        uint256 principal;
        uint256 interest;
    }

    struct Terms {
        uint256 paymentCycleAmount;
        uint32 paymentCycle;
        uint16 APR;
    }
    
    struct LoanDetails {
        ERC20 lendingToken;
        uint256 principal;
        Payment totalRepaid;
        uint32 timestamp;
        uint32 acceptedTimestamp;
        uint32 lastRepaidTimestamp;
        uint32 loanDuration;
    }

    struct Bid {
        address borrower;
        address receiver;
        address lender;
        uint256 marketplaceId; // TODO should this be uncommented really?
        bytes32 _metadataURI; // DEPRECIATED
        LoanDetails loanDetails;
        Terms terms;
        BidState state;
    }
}

interface ITrancheBucketFactoryDataTypes {

    enum BucketType {
        NONE,
        BACKED,
        UN_BACKED
    }

}

interface ITrancheBucketDataTypes is IEconomicsDataTypes {

    /**
     * @param NONE config doesn't exist
     * @param CONFIGURABLE BUCKET IS CONFIGURABLE. it is possible to change the inv range and the kickback per NFT sold (so the bucket is still configuratable)
     * @param BUCKET_ACTIVE BUCKET IS ACTIVE. the bucket is active / in use (the loan/bond has been issued). The bucket CANNOT be configured anymore
     * @param AT_CHECKOUT BUCKET DEBT IS BEING CALCULATED AND PAID. The bond/loan has been repaid / the ticket sale is completed. In a sense the bucket backer is at the checkout of the process (the total bill is made up, and the payment request/process is being run). Look of it as it as the contract being at the checkout at the supermarket, items bought are scanned, creditbard(Economics contract) is charged.
     * @param REDEEMABLE the proceeds/kickback collected in the bucket can now be claimed from the bucket contract. 
     * @param INVALID_CANCELLED_VOID the bucket is invalid. this can have several reasons. The different reasons are listed below.
     * 
     * We have collapsed all these different reasons in a single state because the purpose of this struct is to tell the market what the shares are worth anything. If the bucket is in this state, the value of the shares are 0 (and they are unmovable).
     */


    // stored in: bucketState
    enum BucketConfiguration {
        NONE,
        CONFIGURABLE,
        BUCKET_ACTIVE,
        AT_CHECKOUT,
        REDEEMABLE,
        INVALID_CANCELLED_VOID
    }

    // stored in backing.verification
    enum BackingVerification {
        NONE,
        INVALIDATED,
        VERIFIED
    }

    // stored in tranche
    struct InventoryTranche {
        uint32 startIndexTranche;
        uint32 stopIndexTranche;
        uint32 averagePriceNFT;
        uint32 totalNFTInventory;
        uint32 usdKickbackPerNft; // 10000 = 1e4 = $1,00 = 1 dollar 
    }

    struct BackingStruct {
        bool relayerAttestation;
        BackingVerification verification;
        IntegratorData integratorData;
        uint32 integratorIndex;
        uint256 timestampBacking; // the moment the bucket was deployed and the backing was configured 
    }

    // struct OfferingBidInfo{
    //     address eventAddress;
    //     uint256 bidId;
    // }

    // struct RepaymentStruct {
    //     uint32 scalingFactor;
    //     uint32 bucketDebt;
    //     uint256 amountReceived;
    //     uint256 totalYieldCollected;
    //     uint256 supplyAtFinalization;
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IClearingHouseDataTypes, ITrancheBucketDataTypes, IBondCouncilDataTypes, ITellerV2DataTypes, ITrancheBucketFactoryDataTypes } from "./IDataTypes.sol";

interface IChamberOfCommerceEvents {


    event DefaultDepositSet(
        uint256 newDefaultDeposit
    );

    event CreditScoreEdit(
        address safeAddress,
        uint256 minimumDeposit,
        uint24 fuelRequirement
    );

    event EconomicsContractChange(
        address economicsContract
    );

    event DepositTokenChange(address newDepositToken);

    event AccountDeleted(
        address accountAddress
    );

    event RegisterySet(
        address palletRegistry
    );

    event ControllerSet(
        address addressController,
        bool setting
    );

    event ChamberPaused();

    event ChamberUnPaused();

    event AccountRegistered(
        address safeAddress,
        // uint256 actorIndex,
        string nickName
    );

    event AccountApproved(
        address safeAddress
    );

    event AccountWhitelisted(
        address safeAddress
    );

    event AccountBlacklisted(
        address safeAddress
    );

    event ContractsConfigured(
        address palletLockerFactory,
        address bondCouncil,
        address ticketSalesOracle,
        address economics,
        address palletRegistry,
        address clearingHouse,
        address tellerKeeper
    );

    event PalletLockerDeployed(
        address safeAddress,
        address palletLockerAddress
    );

    event StakeLockerDeployed(
        address safeAddress,
        address safeLockerAddress
    );
}

interface IClearingHouseEvents is IClearingHouseDataTypes {

    event BucketUpdate();

    event ManualCancel(uint256 palletIndex);

    event OfferingAccepted(
        uint256 palletIndex
    );

    event ContractConfigured(
        address palletRegistry,
        address tellerKeeper,
        address bondCouncil
    );

    event OfferingRegistered(
        uint256 palletIndex,
        uint256 bidId
    );

    event OfferingCancelled(
        uint256 palletIndex
    );

    event OfferingLiquidated(
        uint256 palletIndex,
        address lenderAddress
    );

    event PalletReclaimed(
        uint256 palletIndex
    );

    event OfferingStatusChange(
        uint256 palletIndex,
        OfferingStatus _status
    );

}

interface IPalletRegistryEvents {

    event EmergencyWithdraw(
        address tokenAddress,
        address controllerDAO,
        uint256 amountWithdrawn
    );
    
    event BalanceCheck(
        uint256 palletIndex,
        bool rulingBalance
    );

    event DepositTokenChange(address newDepositToken);

    event PalletUnwindLiquidation(
        uint256 palletIndex,
        address liquidatorAddress
    );

    event PalletUnwindIssuer(
        uint256 palletIndex,
        uint256 depositAmount
    );

    event UnwindIssuer(
        uint256 palletIndex
    );

    event UnwindPallet(
        uint256 palletIndex,
        uint256 amountUnwound,
        address recipientDeposit,
        address lockerAddress
    );

    event PalletMinted(
        uint256 palletIndex,
        address safeAddress,
        uint256 tokensDeposited
    );

    event RegisterEventToPallet (
        uint256 palletIndex,
        address eventAddress
    );

    event DepositTokensAdded(
        uint256 palletIndex,
        uint256 extraDepositTokens
    );

    event PalletBurnedManual(
        uint256 palletIndex
    );

    event WithdrawPalletLocker(
        address depositTokenAddress,
        address toAddress,
        uint256 stakeDepositAmount
    );

    event PalletJudged(
        uint256 palletIndex,
        bool ruling
    );

    event PalletDepositClaimed(
        address claimAddress,
        uint256 palletIndex,
        uint256 depositedStateTokens
    );
}

interface ITrancheBucketEvents is ITrancheBucketDataTypes {

    event PaymentApproved();

    event ManualWithdraw(
        address withdrawTokenAddress,
        uint256 amountWithdrawn
    );

    event FunctionNotFullyExecuted();

    event BucketUpdate();

    event ManualCancel();

    event ClaimNotAllowed();

    event ModificationNotAllowed();

    event TrancheFinalized();

    event TrancheFullyRegistered(
        uint32 startIndex,
        uint32 stopIndex,
        uint32 averagePrice,
        uint32 totalInventory
    );

    event AllStaked(
        uint256 stakedAmount,
        uint256 sharesAmount
    );

    event BucketConfigured(
        uint32 integratorIndex
    );

    event RelayerAttestation(
        address attestationAddress
    );

    event BackingVerified(
        bool ruling
    );

    event TrancheShareMint(
        uint256 totalSupply
    );

    event BurnAll();

    event StateChange(
        BucketConfiguration _status
    );

    event InvalidState(
        BucketConfiguration currentState,
        BucketConfiguration requiredState
    );

    event DAOCancel();

    event StateAlreadyInSync();

    event SharesClaimed(
        address claimerAddress,
        uint256 amountClaimed
    );
    
    event UpdateDebt(
        uint256 currentDebt,
        uint256 timestamp
    );

    event BucketCheckedOut(
        uint256 finalDebt
    );

    event ReceivablesUpdated(
        uint256 balanceOf
    );

    event RedemptionUnlocked(
        uint256 balance,
        uint256 atPrice,
        uint256 totalReward
    );

    event Claim(
        uint256 shares,
        uint256 yield
    );

    event ClaimAmount();
}

interface ITellerKeeperEvents is ITellerV2DataTypes {

    event EmergencyWithdraw(
        address tokenAddress,
        address controllerDAO,
        uint256 amountWithdrawn
    );

    error NoOfferingToUpdate(
        uint256 palletIndex,
        string message
    );

    event KeeperUpToDate();

    event NotEnoughFuel();

    event OfferingManualCancel(
        uint256 palletIndex
    );

    event OfferingRegistered(
        uint256 palletIndex
    );

    event TellerLiquidation(
        uint256 palletIndex
    );

    event ContractConfigured(
        address trancheBucketFactory,
        address clearingHouse
    );

    event KeeperReward(
        address rewardRecipient,
        uint256 amountRewarded
    );

    event TellerPaid(
        uint256 palletIndex
    );

    event RewardUpdated(
        uint256 newUpdateReward
    );

    event TellerCancelled(
        uint256 palletIndex
    );

    event TellerAccepted(
        uint256 palletIndex
    );

    event StateUpdateKeeper(
        uint256 bidId,
        uint256 palletIndex,
        BidState currentState
    );
}

interface ITrancheBucketFactoryEvents is ITrancheBucketDataTypes, ITrancheBucketFactoryDataTypes {

    event BucketAlreadyActive();

    event TrancheBucketDeleted(
        uint256 palletIndex,
        address deletedBucket
    );

   event SetTrancheBucketStateManual(
        uint256 palletIndex,
        address bucketAddress
    );

    event TrancheLockerCreated(
        uint256 palletIndex,
        BucketType bucketType,
        address trancheAddress
    );

    event ContractConfigured(
        address clearingHouse
    );

    event RelayChangeToBucket(
        uint256 palletIndex,
        BucketConfiguration newState
    );
}

interface IBondCouncilEvents is IBondCouncilDataTypes {

    event FlushSwitchOff();

    event FlushSwitch(
        bool flushSwitch
    );

    event ImpossibleState();

    event CancelProcedure(
        uint256 palletIndex
    );

    event ManualFS (
        uint256 palletIndex,
        uint256 policyIndex
    );

    event EditProcedure(
        uint256 palletIndex
    );

    event VerifyProcedure(
        uint256 palletIndex
    );

    event PalletCancellation(
        uint256 palletIndex
    );

    event PalletCollateralization(
        uint256 palletIndex
    );

    event PolicyAdded(
        uint256 policyIndex,
        Policy newpolicy
    );

    event ManualFlush(
        uint256 palletIndex
    );

    event PalletRegistered(
        uint256 palletIndex
    );

    event Flush(
        uint256 palletIndex
    );

    event ContractsConfigured(
        address clearingHouse,
        address palletRegistry
    );

    event ChamberSet(
        address chamberOfCommerce
    );

    event Liquidation(
        uint256 palletIndex
    );

    event Repayment(
        uint256 palletIndex
    );
}

interface IStakeLockerFactoryEvents {

    event StakeLockerDeployed(
        address safeAddress
    );

    event TokensAdded(
        address stakeLocker,
        uint256 tokensAdded
    );

    event BalanceUpdated(
        address stakeLocker,
        uint256 newBalance
    );
    
    event UnstakeRequest(
        address safeAddress,
        address lockerAddress,
        uint256 requestAmount
    );

    event UnstakeRequestExecuted(
        address lockerAddress,
        uint256 requestAmount
    );

    event UnstakeRequestRejected(
        address lockerAddress,
        uint256 rejectedAmount
    );

    event EmergencyWithdrawAll(
        address lockerAddress,
        uint256 withdrawAmount
    );

    event LockerSlashed(
        address lockerAddress,
        uint256 slashAmount
    );
}


interface IStakeLockerEvents {

}

interface ITicketSaleOracleEvents {

    event EventCountUpdate(
        address eventAddress,
        uint32 nftsSold
    );

    event EventFinalized(
        address eventAddress
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPalletLocker {

    event PullToFactory(
        uint256 amountDepositTokens
    );

    event EmergencyWithdraw(
        address tokenAddress,
        address controllerDAO,
        uint256 amountWithdrawn
    );

    function pullAmountToPalletRegistry(
        address _addressDepositTokens,
        uint256 _amountStakeAmount
    ) external;

    function safeAddress() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// TODO should this not be the inteface of IERC721Enumerable?
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPalletMinter is IERC721 {

    function mintPalletAndDeposit(address _to) external returns(uint256);

    function burnPallet(uint256 _palletIndex) external;

    function palletIndexTracker() external view returns(uint256);

    function palletExists(
        uint256 _palletIndex
    ) external view returns(bool);

    function setRegistry(
        address _palletRegistry
    ) external;

    event RegistryChange(
        address newRegistry
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { PalletRegistryDataTypes } from "./IDataTypes.sol";

interface IPalletRegistry is PalletRegistryDataTypes{

    function returnPalletMinter() external view returns(address palletMinter_);

    // External -> calls PalletMinter
    function palletExists(
        uint256 _palletIndex
    ) external view returns(bool);
    
    // External -> calls PalletMinter
    function ownerOf(
        uint256 _palletIndex
    ) external view returns(address owner_);

    function mintPalletAndDeposit(
        uint256 _depositTokenAmount
    ) external returns(uint256 _palletIndex);

    function judgePallet(
        uint256 _palletIndex,
        bool _ruling,
        bool _fuelCheck
    ) external;

    function isPalletVerfied(
        uint256 _palletIndex
    ) external view returns(bool _isApproved);

    function canRegisterPalletInOffering(
        uint256 _palletIndex,
        address _addressOf
    ) external view returns(bool canRegister_);

    function isPalletIssuer(
        uint256 _palletIndex,
        address _safeAddress
    ) external view returns(bool _isIssuer);

    function returnPalletEvent(
        uint256 _palletIndex
    ) external view returns(address eventAddress_);

    function registerEventToPallet(
        uint256 _palletIndex,
        address _eventAddress,
        uint64 _maxAmountInventory,
        uint64 _averagePriceInventory
    ) external;

    function burnPalletManual(
        uint256 _palletIndex
    ) external;

    function returnPalletInfo(
        uint256 _palletIndex
    ) external view returns(PalletStruct memory _info);

    function burnPalletClearingHouse(
        uint256 _palletIndex
    ) external;

    function unwindPalletLiquidator(
        uint256 _palletIndex,
        address _recipientLiquidator
    ) external;
}