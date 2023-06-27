/**
 *Submitted for verification at polygonscan.com on 2023-06-26
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: space.sol


pragma solidity ^0.8.9;






contract SpaceMarketPlace {
    address public owner;
    address public receiver;
    uint256 public receiverBal;
    uint256 public constant NUM_SPACES = 100;
    uint256 public constant MIN_SUBSCRIBE = 0; // minimum balance as percent of highest offer required to defend a space
    uint256 public constant SUBSCRIBE_RATE = 10; // percent of highest offer from each space sent to receiver each per year

    IERC20 public immutable weth;

    struct Space {
        uint256 spaceNo;
        bool exists;
        address owner;
        uint256 balance;
        uint256 highestOffer;
        address highestOfferer;
        string spaceUri;
        uint256 subscTime;
        uint256 subscBurn;
        uint256 subscOffer;
    }

    mapping(uint256 => Space) public spaces;

    event NewOffer(
        uint256 indexed spaceId,
        address indexed offerer,
        uint256 amount
    );

    // WETH address on Goerli = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6
    constructor(IERC20 _weth) {
        owner = msg.sender;
        receiver = owner;
        weth = _weth;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier spaceExists(uint256 spaceId) {
        require(spaces[spaceId].exists, "This space does not exist");
        _;
    }

    modifier canDeposit(uint256 spaceId) {
        require(
            spaces[spaceId].exists && spaces[spaceId].owner == msg.sender,
            "You cannot deposit against this space"
        );
        _;
    }

    modifier canOffer(uint256 spaceId) {
        require(
            spaces[spaceId].exists && spaces[spaceId].owner != msg.sender,
            "You cannot offer on this space"
        );
        _;
    }

    function setReceiver(address _receiver) public onlyOwner {
        receiver = _receiver;
    }

    function transferContractOwner(address newContractOwner) public onlyOwner {
        owner = newContractOwner;
    }

    function deposit(uint256 spaceId, uint256 amount)
        public
        canDeposit(spaceId)
    {
        require(weth.balanceOf(msg.sender) >= amount, "Insufficient balance");
        uint256 allowance = weth.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        require(amount >= 10 gwei, "min balance is 10 GWEI");

        spaces[spaceId].balance += amount;
        updateSubscriptionFlows(spaceId);

        weth.transferFrom(msg.sender, address(this), amount);
    }

    //create timestamp for static balance amount and update flowrate in spaces[_spaceId]
    function updateSubscriptionFlows(uint256 spaceId) internal {
        if (
            spaces[spaceId].balance <=
            spaces[spaceId].subscBurn *
                (block.timestamp - spaces[spaceId].subscTime)
        ) {
            receiverBal += spaces[spaceId].balance;
        } else {
            receiverBal +=
                spaces[spaceId].subscBurn *
                (block.timestamp - spaces[spaceId].subscTime);
        }
        uint256 flowRate = (spaces[spaceId].highestOffer * SUBSCRIBE_RATE) /
            (100 * 365 days);
        spaces[spaceId].balance = getRemainingBalance(spaceId);
        spaces[spaceId].subscTime = block.timestamp;
        spaces[spaceId].subscBurn = flowRate;
    }

    //function that calculates remaining balance in a given space
    function getRemainingBalance(uint256 spaceId)
        public
        view
        returns (uint256 remainingCommit)
    {
        if (
            spaces[spaceId].balance <=
            spaces[spaceId].subscBurn *
                (block.timestamp - spaces[spaceId].subscTime)
        ) {
            remainingCommit = 0;
        } else {
            remainingCommit =
                spaces[spaceId].balance -
                spaces[spaceId].subscBurn *
                (block.timestamp - spaces[spaceId].subscTime);
        }
        return remainingCommit;
    }

    function withdraw(uint256 spaceId, uint256 amount) public {
        require(
            spaces[spaceId].owner == msg.sender,
            "you are not the current space owner"
        );
        require(
            amount <= getRemainingBalance(spaceId),
            "not enough depositted weth left"
        );
        spaces[spaceId].balance = getRemainingBalance(spaceId) - amount;

        updateSubscriptionFlows(spaceId);
        weth.transfer(spaces[spaceId].owner, amount);
    }

    function claimSpace(uint256 spaceId, uint256 amount) public {
        require(spaceId > 0 && spaceId <= NUM_SPACES, "Invalid SpaceId");
        require(
            !spaces[spaceId].exists && spaces[spaceId].owner == address(0),
            "space has already been claimed"
        );
        require(weth.balanceOf(msg.sender) >= amount, "Insufficient balance");
        uint256 allowance = weth.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");

        spaces[spaceId].exists = true;
        spaces[spaceId].spaceNo = spaceId;
        spaces[spaceId].balance += amount;
        spaces[spaceId].owner = msg.sender;
        updateSubscriptionFlows(spaceId);

        weth.transferFrom(msg.sender, address(this), amount);
    }

    function offer(
        uint256 spaceId,
        uint256 amount,
        uint256 subscOffer
    ) external spaceExists(spaceId) {
        Space storage space = spaces[spaceId];
        uint256 refund = 0;
        uint256 allowance = weth.allowance(msg.sender, address(this));
        require(allowance >= amount + subscOffer, "Check the token allowance");
        require(
            space.owner != msg.sender,
            "Owner cannot offer on their own space"
        );
        require(
            amount > space.highestOffer,
            "Offer must be greater than current highest offer"
        );

        // Refund previous highest offerer
        if (space.highestOfferer != address(0)) {
            refund = space.highestOffer + space.subscOffer;
        }

        // Update offering state
        space.highestOfferer = msg.sender;
        space.highestOffer = amount;
        space.subscOffer = subscOffer;

        updateSubscriptionFlows(spaceId);
        if (refund > 0) {
            weth.transfer(space.highestOfferer, refund);
        }
        require(
            weth.balanceOf(msg.sender) >= amount + subscOffer,
            "Insufficient balance"
        );
        require(
            weth.transferFrom(msg.sender, address(this), amount + subscOffer),
            "Transfer failed"
        );

        emit NewOffer(spaceId, msg.sender, amount);
    }

    function acceptOffer(uint256 spaceId) public spaceExists(spaceId) {
        if (
            getRemainingBalance(spaceId) <=
            (spaces[spaceId].highestOffer * MIN_SUBSCRIBE) / 100
        ) {
            _acceptOffer(spaceId, spaces[spaceId].subscOffer);
        } else {
            require(
                msg.sender == spaces[spaceId].owner,
                "The owner has successfully defended ownership with sufficient balance"
            );
            _acceptOffer(spaceId, spaces[spaceId].subscOffer);
        }
    }

    function _acceptOffer(uint256 spaceId, uint256 newDepositAmount) internal {
        Space storage space = spaces[spaceId];
        require(space.highestOfferer != address(0), "No offer to accept");
        //send offer to previous owner
        uint256 allowance = weth.allowance(msg.sender, address(this));
        require(allowance >= newDepositAmount, "Check the token allowance");
        require(
            weth.transfer(space.owner, space.highestOffer),
            "Offer refund transfer failed"
        );
        // refund balance to the previous owner
        weth.transfer(space.owner, space.balance);
        // change ownership to highest offerer
        space.owner = space.highestOfferer;
        // reset highest offer to 0
        space.highestOfferer = address(0);
        space.highestOffer = 0;
        space.balance = newDepositAmount;
        // transfer new balance amount to contract
        weth.transferFrom(msg.sender, address(this), newDepositAmount);
        updateSubscriptionFlows(spaceId);
    }

    function retractOffer(uint256 spaceId) public {
        require(
            spaces[spaceId].highestOfferer == msg.sender,
            "you are not the current highest offerer"
        );
        weth.transfer(
            spaces[spaceId].highestOfferer,
            spaces[spaceId].highestOffer + spaces[spaceId].subscOffer
        );
        spaces[spaceId].highestOfferer = address(0);
        spaces[spaceId].highestOffer = 0;
        spaces[spaceId].subscOffer = 0;
        updateSubscriptionFlows(spaceId);
    }

    function transferSpace(uint256 spaceId, address newOwner) public {
        require(spaces[spaceId].owner == msg.sender, "you are not the owner!");
        spaces[spaceId].owner = newOwner;
        if (spaces[spaceId].highestOfferer == msg.sender) {
            retractOffer(spaceId);
        }
    }

    function setSpaceUri(
        uint256 spaceId,
        uint256 nftTokenId,
        address nftContractAddress
    ) public canDeposit(spaceId) {
        IERC721 nftContract = IERC721(nftContractAddress);
        IERC721Metadata uNftContract = IERC721Metadata(nftContractAddress);
        require(
            nftContract.ownerOf(nftTokenId) == msg.sender,
            "Caller does not own this NFT"
        );
        spaces[spaceId].spaceUri = uNftContract.tokenURI(nftTokenId);
    }

    function getNftUri(uint256 _spaceId) public view returns (string memory) {
        return spaces[_spaceId].spaceUri;
    }

    function updateRevenue() public {
        for (uint256 i = 1; i <= NUM_SPACES; i++) {
            updateSubscriptionFlows(i);
        }
    }

    function claimRevenue() public onlyOwner {
        weth.transfer(receiver, receiverBal);
    }

    function getSubscriptionRevenue()
        public
        view
        returns (uint256 subscriptionRevenue)
    {
        subscriptionRevenue = receiverBal;
        return subscriptionRevenue;
    }

    //off-chain function - not to be called onchain
    function getAllSpaces() public view returns (Space[] memory) {
        Space[] memory _spaces = new Space[](NUM_SPACES);
        uint256 index = 0;
        for (uint256 i = 1; i <= NUM_SPACES; i++) {
       
                _spaces[index] = spaces[i];
                index++;
       
        }
        return _spaces;
    }

    //off-chain function - not to be called onchain
    function getCurrentRemainingBalances()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _balances = new uint256[](NUM_SPACES);
        uint256 index = 0;
        for (uint256 i = 1; i <= NUM_SPACES; i++) {

            uint256 remainingCommit = 0;
            if (
                spaces[i].balance <=
                spaces[i].subscBurn *
                    (block.timestamp - spaces[i].subscTime)
            ) {
                remainingCommit = 0;
            } else {
                remainingCommit =
                    spaces[i].balance -
                    spaces[i].subscBurn *
                    (block.timestamp - spaces[i].subscTime);
            }
            _balances[index] = remainingCommit;
            index++;
        }
        return _balances;
    }
}