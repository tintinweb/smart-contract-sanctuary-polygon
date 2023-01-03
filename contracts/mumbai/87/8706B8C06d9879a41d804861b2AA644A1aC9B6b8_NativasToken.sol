/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "IERC1155Control.sol";
import "Controllable.sol";
import "ERC1155Pausable.sol";
import "ERC1155Swappable.sol";
import "ERC1155Offsettable.sol";
import "ERC1155URIStorable.sol";
import "ERC1155ERC20.sol";

/**
 * @dev ERC1155 preset
 */
contract NativasToken is
    Controllable,
    ERC1155Pausable,
    ERC1155Swappable,
    ERC1155URIStorable,
    ERC1155ERC20
{
    IERC1155Control internal _control;

    constructor(
        address controller_,
        string memory uri_,
        address template_,
        address logger_
    )
        Controllable(controller_)
        ERC1155URIStorable(uri_)
        ERC1155ERC20(template_)
        ERC1155Swappable(logger_)
    {
        _control = IERC1155Control(controller_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC1155URIStorable)
        returns (bool success)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 tokenId)
        public
        view
        virtual
        override(ERC1155ERC20, ERC1155URIStorable)
        returns (bool)
    {
        return super.exists(tokenId);
    }

    /**
     * @dev Set token metadata
     */
    function setMetadata(
        uint256 tokenId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        string memory uri,
        bool offsettable
    ) public virtual {
        setAdapter(tokenId, name, symbol, decimals);
        setOffsettable(tokenId, offsettable);
        setURI(tokenId, uri);
    }

    /**
     * @dev See {Controllable-_transferControl}.
     *
     * Requirements:
     *
     * - the caller must be admin
     */
    function transferControl(address newController) public virtual {
        require(_control.isAdmin(_msgSender()), "ERC1155NE01");
        _transferControl(newController);
    }

    /**
     * @dev See {ERC1155Burnable-_safeBurn}.
     *
     * Requirements:
     *
     * - the caller must be burner.
     */
    function burn(
        address account,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(_control.isBurner(_msgSender()), "ERC1155NE02");
        _safeBurn(account, tokenId, amount, data);
    }

    /**
     * @dev See {ERC1155Burnable-_safeBurnBatch}.
     *
     * Requirements:
     *
     * - the caller must be burner.
     */
    function burnBatch(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(_control.isBurner(_msgSender()), "ERC1155NE03");
        _safeBurnBatch(account, tokenIds, amounts, data);
    }

    /**
     * @dev See {ERC1155Mintable-_mint}.
     *
     * Requirements:
     *
     * - the caller must be minter.
     */
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(_control.isMinter(_msgSender()), "ERC1155NE04");
        _mint(to, tokenId, amount, data);
    }

    /**
     * @dev See {ERC1155Mintable-_mintBatch}.
     *
     * Requirements:
     *
     * - the caller must be minter.
     */
    function mintBatch(
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(_control.isMinter(_msgSender()), "ERC1155NE05");
        _mintBatch(to, tokenIds, amounts, data);
    }

    /**
     * @dev See {ERC1155ERC20-_setAdapter}
     *
     * Requirements:
     *
     * - the caller must be adapter.
     */
    function setAdapter(
        uint256 tokenId,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public virtual {
        require(_control.isAdapter(_msgSender()), "ERC1155NE06");
        _setAdapter(tokenId, name, symbol, decimals);
    }

    /**
     * @dev See {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must be pauser.
     */
    function pause() public virtual {
        require(_control.isPauser(_msgSender()), "ERC1155NE07");
        _pause();
    }

    /**
     * @dev See {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must be pauser.
     */
    function unpause() public virtual {
        require(_control.isPauser(_msgSender()), "ERC1155NE08");
        _unpause();
    }

    /**
     * @dev See {ERC1155URIStorable-_setBaseURI}
     *
     * Requeriments:
     *
     * - the caller must be editor
     */
    function setBaseURI(string memory baseURI) public virtual {
        require(_control.isEditor(_msgSender()), "ERC1155NE09");
        _setBaseURI(baseURI);
    }

    /**
     * @dev See {ERC1155URIStorable-_setURI}
     *
     * Requeriments:
     *
     * - the caller must be editor.
     */
    function setURI(uint256 tokenId, string memory tokenURI) public virtual {
        require(_control.isEditor(_msgSender()), "ERC1155NE10");
        _setURI(tokenId, tokenURI);
    }

    /**
     * @dev See {ERC1155Offsetter-_setOffsettable}
     *
     * Requeriments:
     *
     * - the caller must be offsetter
     */
    function setOffsettable(uint256 tokenId, bool enabled) public virtual {
        require(_control.isSwapper(_msgSender()), "ERC1155NE11");
        _setOffsettable(tokenId, enabled);
    }

    /**
     * @dev See {ERC1155Offsetter-_swap}
     *
     * Requeriments:
     *
     * - the caller must be offsetter
     */
    function swap(
        address account,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(_control.isSwapper(_msgSender()), "ERC1155NE12");
        _swap(account, fromTokenId, toTokenId, amount, data);
    }

    /**
     * @dev See {ERC1155Offsetter-_swapBatch}
     *
     * Requeriments:
     *
     * - the caller must be offsetter
     */
    function swapBatch(
        address account,
        uint256[] memory fromTokenIds,
        uint256[] memory toTokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(_control.isSwapper(_msgSender()), "ERC1155NE13");
        _swapBatch(account, fromTokenIds, toTokenIds, amounts, data);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(ERC1155, ERC1155ERC20, ERC1155Pausable, ERC1155URIStorable)
    {
        super._beforeTokenTransfer(operator, from, to, tokenIds, amounts, data);
    }
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

/**
 * @title
 */
interface IERC1155Control {
    /**
     * @dev Returns `true` if `account` has been granted `admin` role.
     */
    function isAdmin(address account) external returns (bool);

    /**
     * @dev Returns `true` if `account` has been granted `burner` role.
     */
    function isBurner(address account) external returns (bool);

    /**
     * @dev Returns `true` if `account` has been granted `adapter` role.
     */
    function isAdapter(address account) external returns (bool);

    /**
     * @dev Returns `true` if `account` has been granted `minter` role.
     */
    function isMinter(address account) external returns (bool);

    /**
     * @dev Returns `true` if `account` has been granted `pauser` role.
     */
    function isPauser(address account) external returns (bool);

    /**
     * @dev Returns `true` if `account` has been granted `editor` role.
     */
    function isEditor(address account) external returns (bool);

    /**
     * @dev Returns `true` if `account` has been granted `swapper` role.
     */
    function isSwapper(address account) external returns (bool);
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism.
 */
contract Controllable is Context {
    address private _controller;

    event ControlTransferred(
        address indexed oldController,
        address indexed newControllerr
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address controller_) {
        _transferControl(controller_);
    }

    /**
     * @dev Returns the address of the current accessor.
     */
    function controller() public view virtual returns (address) {
        return _controller;
    }

    /**
     * @dev Transfers control of the contract to a new account (`controller_`).
     * Can only be called by the current controller.
     *
     * NOTE: Renouncing control will leave the contract without a controller,
     * thereby removing any functionality that is only available to the controller.
     */
    function _transferControl(address controller_) internal virtual {
        address current = _controller;
        _controller = controller_;
        emit ControlTransferred(current, controller_);
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

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "ERC1155.sol";

/**
 * @dev ERC1155 pause implementation
 */
contract ERC1155Pausable is ERC1155 {
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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, tokenIds, amounts, data);
        require(paused() == false, "ERC1155PE01");
    }
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi
/// @dev https://eips.ethereum.org/EIPS/eip-1155

pragma solidity ^0.8.0;

import "Context.sol";
import "ERC165.sol";
import "IERC1155.sol";
import "ERC1155Common.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 */
contract ERC1155 is Context, ERC165, ERC1155Common, IERC1155 {
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool success)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(account != address(0), "ERC1155E01");
        return _balances[tokenId][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory tokenIds
    ) public view virtual override returns (uint256[] memory) {
        require(accounts.length == tokenIds.length, "ERC1155E02");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], tokenIds[i]);
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
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(_isOwnerOrApproved(from), "ERC1155E03");
        _safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(_isOwnerOrApproved(from), "ERC1155E04");
        _safeBatchTransferFrom(from, to, tokenIds, amounts, data);
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
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155E05");

        address operator = _msgSender();

        _transferFrom(operator, from, to, tokenId, amount, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            from,
            to,
            tokenId,
            amount,
            data
        );
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
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(tokenIds.length == amounts.length, "ERC1155E06");
        require(to != address(0), "ERC1155E07");

        address operator = _msgSender();

        _batchTransferFrom(operator, from, to, tokenIds, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            tokenIds,
            amounts,
            data
        );
    }

    /**
     *
     */
    function _transferFrom(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        uint256[] memory tokenIds = _asSingletonArray(tokenId);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, tokenIds, amounts, data);

        _transfer(from, to, tokenId, amount);

        emit TransferSingle(operator, from, to, tokenId, amount);

        _afterTokenTransfer(operator, from, to, tokenIds, amounts, data);
    }

    /**
     *
     */
    function _batchTransferFrom(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _beforeTokenTransfer(operator, from, to, tokenIds, amounts, data);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _transfer(from, to, tokenIds[i], amounts[i]);
        }

        emit TransferBatch(operator, from, to, tokenIds, amounts);

        _afterTokenTransfer(operator, from, to, tokenIds, amounts, data);
    }

    /**
     *
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        uint256 fromBalance = _balances[tokenId][from];
        require(fromBalance >= amount, "ERC1155E08");
        unchecked {
            _balances[tokenId][from] = fromBalance - amount;
        }
        _balances[tokenId][to] += amount;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isOwnerOrApproved(address from)
        internal
        view
        virtual
        returns (bool)
    {
        return from == _msgSender() || isApprovedForAll(from, _msgSender());
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
        require(owner != operator, "ERC1155E09");
        _operatorApprovals[owner][operator] = approved;
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
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi
/// @dev: https://eips.ethereum.org/EIPS/eip-1155

pragma solidity ^0.8.0;

/**
 * @title ERC-1155 Multi Token Standard
 * Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    /**
     * @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including
     * zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
     * The @param operator argument MUST be the address of an account/contract that is approved to make the transfer
     * (SHOULD be msg.sender).
     * The @param from argument MUST be the address of the holder whose balance is decreased.
     * The @param to argument MUST be the address of the recipient whose balance is increased.
     * The @param tokenId argument MUST be the token type being transferred.
     * The @param amount argument MUST be the number of tokens the holder balance is decreased by and match what the
     * recipient balance is increased by.
     * When minting/creating tokens, the `from` argument MUST be set to `0x0` (i.e. zero address).
     * When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 amount
    );

    /**
     * @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value
     * transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
     * The @param operator argument MUST be the address of an account/contract that is approved to make the transfer
     * (SHOULD be msg.sender).
     * The @param from argument MUST be the address of the holder whose balance is decreased.
     * The @param to argument MUST be the address of the recipient whose balance is increased.
     * The @param tokenIds argument MUST be the list of tokens being transferred.
     * The @param amounts argument MUST be the list of number of tokens (matching the list and order of tokens
     * specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
     * When minting/creating tokens, the `from` argument MUST be set to `0x0` (i.e. zero address).
     * When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] tokenIds,
        uint256[] amounts
    );

    /**
     * @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is
     * enabled or disabled (absence of an event assumes disabled).
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev MUST emit when the URI is updated for a token ID.
     * URIs are defined in RFC 3986.
     * The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
     */
    event URI(string value, uint256 indexed tokenId);

    /**
     * @notice Transfers `value` amount of an `id` from the `from` address to the `to` address specified
     * (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `from` account
     * (see "Approval" section of the standard).
     * MUST revert if `to` is the zero address.
     * MUST revert if balance of holder for token `id` is lower than the `value` sent.
     * MUST revert on any other error.
     * MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section
     * of the standard).
     * After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0).
     * If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of
     * the standard).
     * @param from Source address
     * @param to Target address
     * @param tokenId ID of the token type
     * @param amount Transfer amount
     * @param data Additional data with no specified format, MUST be sent unaltered in call
     * to `onERC1155Received` on `to`
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified
     * (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `from` account
     * (see "Approval" section of the standard).
     * MUST revert if `to` is the zero address.
     * MUST revert if length of `ids` is not the same as length of `values`.
     * MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective
     * amount(s) in `values` sent to the recipient.
     * MUST revert on any other error.
     * MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected
     * (see "Safe Transfer Rules" section of the standard).
     * Balance changes and events MUST follow the ordering of
     * the arrays (ids[0]/values[0] before ids[1]/values[1], etc).
     * After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to`
     * is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s)
     * on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param from Source address
     * @param to Target address
     * @param tokenIds IDs of each token type (order and length must match values array)
     * @param amounts Transfer amounts per token type (order and length must match ids array)
     * @param data Additional data with no specified format, MUST be sent unaltered in call
     * to the `ERC1155TokenReceiver` hook(s) on `to`
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /**
     * @notice Get the balance of an account's tokens.
     * @param owner The address of the token holder
     * @param tokenId ID of the token
     * @return balance owner's balance of the token type requested
     */
    function balanceOf(address owner, uint256 tokenId)
        external
        view
        returns (uint256 balance);

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param owners The addresses of the token holders
     * @param tokenIds ID of the tokens
     * @return balances owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory balances);

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
     * @dev MUST emit the ApprovalForAll event on success.
     * @param operator  Address to add to the set of authorized operators
     * @param approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @notice Queries the approval status of an operator for a given owner.
     * @param owner The owner of the tokens
     * @param operator Address of authorized operator
     * @return success True if the operator is approved, false if not
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool success);
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "Address.sol";
import "IERC1155TokenReceiver.sol";

/**
 * @dev Common function for ERC1155 standar.
 */
contract ERC1155Common {
    using Address for address;

    /**
     * @dev helper function to create an array from an element.
     */
    function _asSingletonArray(uint256 element)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    /**
     * @dev transfer acceptance check.
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            bytes4 response = IERC1155TokenReceiver(to).onERC1155Received(
                operator,
                from,
                tokenId,
                amount,
                data
            );
            require(
                response == IERC1155TokenReceiver.onERC1155Received.selector,
                "ERC1155E10"
            );
        }
    }

    /**
     * @dev batch transfer acceptance check.
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            bytes4 response = IERC1155TokenReceiver(to).onERC1155BatchReceived(
                operator,
                from,
                tokenIds,
                amounts,
                data
            );
            require(
                response == IERC1155TokenReceiver.onERC1155Received.selector,
                "ERC1155E11"
            );
        }
    }
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

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi
/// @dev: https://eips.ethereum.org/EIPS/eip-1155

pragma solidity ^0.8.0;

/**
 * @title ERC1155TokenReceiver interface to accept transfers
 * Note: The ERC-165 identifier for this interface is 0x4e2312e0.
 */
interface IERC1155TokenReceiver {
    /**
     * @notice Handle the receipt of a single ERC1155 token type.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end
     * of a `safeTransferFrom` after the balance has been updated.
     * This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61) if it accepts the transfer.
     * This function MUST revert if it rejects the transfer.
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being
     * reverted by the caller.
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param tokenId The ID of the token being transferred
     * @param amount The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return result `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4 result);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end
     * of a `safeBatchTransferFrom` after the balances have been updated.
     * This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81) if it accepts the transfer(s).
     * This function MUST revert if it rejects the transfer(s).
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being
     * reverted by the caller.
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param tokenIds An array containing ids of each token being transferred (order and length must match _values array)
     * @param amounts An array containing amounts of each token being transferred (order and length must match _ids array)
     * @param data Additional data with no specified format
     * @return result `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4 result);
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "Strings.sol";
import "ERC1155Offsettable.sol";
import "ERC1155Mintable.sol";

/**
 * @dev Offset Implementation
 */
contract ERC1155Swappable is ERC1155Offsettable, ERC1155Mintable {
    constructor(address logger_) ERC1155Offsettable(logger_) {}

    function _swap(
        address account,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(_offsettable[fromTokenId] == false, "ERC1155WE01");
        require(_offsettable[toTokenId] == true, "ERC1155WE02");
        _burn(account, fromTokenId, amount, data);
        _mint(account, toTokenId, amount, data);
    }

    function _swapBatch(
        address account,
        uint256[] memory fromTokenIds,
        uint256[] memory toTokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        for (uint256 i = 0; i < fromTokenIds.length; i++) {
            require(_offsettable[fromTokenIds[i]] == false, "ERC1155WE03");
        }
        for (uint256 i = 0; i < toTokenIds.length; i++) {
            require(_offsettable[toTokenIds[i]] == true, "ERC1155WE04");
        }
        _burnBatch(account, fromTokenIds, amounts, data);
        _mintBatch(account, toTokenIds, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "Strings.sol";
import "IERC1155Logger.sol";
import "ERC1155Burnable.sol";

/**
 * @dev Offset Implementation
 */
contract ERC1155Offsettable is ERC1155Burnable {
    IERC1155Logger internal _logger;

    mapping(uint256 => bool) internal _offsettable;

    constructor(address logger_) {
        _logger = IERC1155Logger(logger_);
    }

    function logger() public view virtual returns (address) {
        return address(_logger);
    }

    function offsettable(uint256 tokenId) public view virtual returns (bool) {
        return _offsettable[tokenId];
    }

    function offset(
        address account,
        uint256 tokenId,
        uint256 amount,
        string memory reason,
        bytes memory data
    ) public virtual {
        require(_isOwnerOrApproved(account), "ERC1155OE01");
        _burn(account, tokenId, amount, data);
        _offset(account, tokenId, amount, reason);
    }

    function offsetBatch(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        string[] memory reasons,
        bytes memory data
    ) public virtual {
        require(_isOwnerOrApproved(account), "ERC1155OE03");
        _burnBatch(account, tokenIds, amounts, data);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _offset(account, tokenIds[i], amounts[i], reasons[i]);
        }
    }

    function _setOffsettable(uint256 tokenId, bool enabled) internal virtual {
        _offsettable[tokenId] = enabled;
    }

    function _offset(
        address account,
        uint256 tokenId,
        uint256 amount,
        string memory reason
    ) internal virtual {
        require(_offsettable[tokenId], "ERC1155OE02");
        _logger.offset(account, tokenId, amount, reason);
    }
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

/**
 * @title
 */
interface IERC1155Logger {
    function offset(
        address account,
        uint256 tokenId,
        uint256 amount,
        string memory reason
    ) external;
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "ERC1155.sol";

/**
 * @dev Burn implementation
 */
contract ERC1155Burnable is ERC1155 {
    /**
     * @dev See {ERC1155Accessible-_burn}.
     *
     * Requirements:
     *
     * - the caller must have the `BURNER_ROLE`.
     * - the caller must be the owner or approved.
     */
    function _safeBurn(
        address account,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(_isOwnerOrApproved(account), "ERC1155BE01");
        _burn(account, tokenId, amount, data);
    }

    /**
     * @dev See {ERC1155Accessible-_burnBatch}.
     *
     * Requirements:
     *
     * - the caller must have the `BURNER_ROLE`.
     * - the caller must be the owner or approved.
     */
    function _safeBurnBatch(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(_isOwnerOrApproved(account), "ERC1155BE02");
        _burnBatch(account, tokenIds, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `tokenId` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `tokenId`.
     */
    function _burn(
        address from,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(from != address(0), "ERC1155BE03");

        address operator = _msgSender();
        uint256[] memory tokenIds = _asSingletonArray(tokenId);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(
            operator,
            from,
            address(0),
            tokenIds,
            amounts,
            data
        );

        uint256 fromBalance = _balances[tokenId][from];
        require(fromBalance >= amount, "ERC1155BE04");
        unchecked {
            _balances[tokenId][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), tokenId, amount);

        _afterTokenTransfer(
            operator,
            from,
            address(0),
            tokenIds,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amounts` tokens of token type `tokenIds` from `from`
     *
     * emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - `from` must have at least `amounts` tokens of token type `tokenIds`.
     */
    function _burnBatch(
        address from,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(from != address(0), "ERC1155BE05");
        require(tokenIds.length == amounts.length, "ERC1155BE06");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            address(0),
            tokenIds,
            amounts,
            data
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            uint256 amount = amounts[i];
            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155BE07");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), tokenIds, amounts);

        _afterTokenTransfer(
            operator,
            from,
            address(0),
            tokenIds,
            amounts,
            data
        );
    }
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "ERC1155.sol";

/**
 * @dev Mint implementation
 */
contract ERC1155Mintable is ERC1155 {
    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement
     * {IERC1155Receiver-onERC1155Received} and return the acceptance magic value.
     */
    function _mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155ME01");

        address operator = _msgSender();
        uint256[] memory tokenIds = _asSingletonArray(tokenId);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, tokenIds, amounts, data);

        _balances[tokenId][to] += amount;
        emit TransferSingle(operator, address(0), to, tokenId, amount);

        _afterTokenTransfer(operator, address(0), to, tokenIds, amounts, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            tokenId,
            amount,
            data
        );
    }

    /**
     * @dev Creates `amounts` tokens of token type `ids`, and assigns them to `to`.
     *
     * emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement
     * {IERC1155Receiver-onERC1155BatchReceived} and return the acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155ME02");
        require(tokenIds.length == amounts.length, "ERC1155ME03");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, tokenIds, amounts, data);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _balances[tokenIds[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, tokenIds, amounts);

        _afterTokenTransfer(operator, address(0), to, tokenIds, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            tokenIds,
            amounts,
            data
        );
    }
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "Strings.sol";
import "IERC1155MetadataURI.sol";
import "ERC1155.sol";

/**
 * @dev ERC1155 token with storage based token URI management.
 */
contract ERC1155URIStorable is ERC1155, IERC1155MetadataURI {
    using Strings for uint256;
    // Used as the URI for all token types by relying on ID substitution.
    string internal _baseURI;
    // Mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev set base uri
     */
    constructor(string memory uri_) {
        _setBaseURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool success)
    {
        return
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the concatenation of the `_uri`
     * and the token-specific uri if the latter is set
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_baseURI, _tokenURIs[tokenId]));
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return bytes(_tokenURIs[tokenId]).length > 0;
    }

    /**
     * @dev Sets `baseURI` as the `_uri` for all tokens
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, tokenIds, amounts, data);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(exists(tokenIds[i]) == true, "ERC1155UE01");
        }
    }
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi
/// @dev https://eips.ethereum.org/EIPS/eip-1155

pragma solidity ^0.8.0;

/**
 * @title Interface of the optional ERC1155MetadataExtension interface
 * Note: The ERC-165 identifier for this interface is 0x0e89341c.
 */
interface IERC1155MetadataURI {
    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     * The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
     * @return uri string
     */
    function uri(uint256 tokenId) external view returns (string memory uri);
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "Clones.sol";
import "IERC1155ERC20.sol";
import "IERC20Adapter.sol";
import "ERC1155Supply.sol";

/**
 *
 */
contract ERC1155ERC20 is ERC1155Supply, IERC1155ERC20 {
    using Clones for address;

    // NativasAdapter template
    address internal _template;
    // Mapping token id to adapter address
    mapping(uint256 => address) internal _adapters;

    /**
     * @dev MUST trigger when a new adapter is created.
     */
    event AdapterCreated(uint256 indexed tokenId, address indexed adapter);

    /**
     * @dev Set NativasAdapter contract template
     */
    constructor(address template_) {
        _template = template_;
    }

    /**
     * @dev Get NativasAdapter contract template
     */
    function template() public view virtual returns (address) {
        return _template;
    }

    /**
     * @dev Get adpter contract address for token id.
     */
    function getAdapter(uint256 tokenId) public view virtual returns (address) {
        return _adapters[tokenId];
    }

    /**
     * @dev Perform tranfer from adapter contract.
     *
     * Requirements:
     *
     * - the caller MUST be the token adapter.
     */
    function safeAdapterTransferFrom(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(_msgSender() == _adapters[tokenId], "ERC1155AE01");
        _safeAdapterTransferFrom(operator, from, to, tokenId, amount, data);
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _adapters[tokenId] != address(0);
    }

    /**
     * @dev Create new adapter contract por token id
     */
    function _setAdapter(
        uint256 tokenId,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal virtual {
        address adapter = _template.clone();
        IERC20Adapter(adapter).init(tokenId, name, symbol, decimals);
        _adapters[tokenId] = adapter;
        emit AdapterCreated(tokenId, adapter);
    }

    /**
     * @dev Transfers `amount` tokens of token type `tokenId` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `tokenId` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement
     * {IERC1155Receiver-onERC1155Received} and return the acceptance magic value.
     */
    function _safeAdapterTransferFrom(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155AE02");
        _transferFrom(operator, from, to, tokenId, amount, data);
        _doSafeTransferAcceptanceCheck(
            operator,
            from,
            to,
            tokenId,
            amount,
            data
        );
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, tokenIds, amounts, data);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(exists(tokenIds[i]) == true, "ERC1155AE03");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "IERC1155.sol";
import "IERC1155Supply.sol";

/**
 * @title Extension of ERC1155 that adds backward compatibility
 */
interface IERC1155ERC20 is IERC1155, IERC1155Supply {
    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeAdapterTransferFrom(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external;
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

/**
 * @title Extension of ERC1155 that adds tracking of total supply per id.
 */
interface IERC1155Supply {
    /**
     * Useful for scenarios where Fungible and Non-fungible tokens have to be
     * clearly identified. Note: While a totalSupply of 1 might mean the
     * corresponding is an NFT, there is no guarantees that no other token with the
     * same id are not going to be minted.
     */
    function totalSupply(uint256 tokenId)
        external
        view
        returns (uint256 totalSupply);
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

/**
 * @dev Interface for the adapter functions from the ERC20 standard.
 */
interface IERC20Adapter {
    /**
     * @dev Initialize ERC20 contract
     */
    function init(
        uint256 tokenId_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external;
}

/// SPDX-License-Identifier: MIT
/// @by: Nativas BCorp
/// @author: Juan Pablo Crespi

pragma solidity ^0.8.0;

import "IERC1155Supply.sol";
import "ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 */
contract ERC1155Supply is ERC1155, IERC1155Supply {
    // total supply
    mapping(uint256 => uint256) internal _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256 supply)
    {
        return _totalSupply[tokenId];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return totalSupply(tokenId) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, tokenIds, amounts, data);
        //Mint
        if (from == address(0)) {
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                _totalSupply[tokenIds[i]] += amounts[i];
            }
        }
        // Burn
        if (to == address(0)) {
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                uint256 id = tokenIds[i];
                uint256 amount = amounts[i];
                require(_totalSupply[id] >= amount, "ERC1155SE01");
                unchecked {
                    _totalSupply[id] -= amount;
                }
            }
        }
    }
}