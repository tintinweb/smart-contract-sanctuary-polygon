// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Champion is ERC721Enumerable {
  constructor() ERC721("Red Village Champion", "RVC") {}

  function mint(uint256 amount, uint256 padding) external {
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(msg.sender, totalSupply() + padding);
    }
  }

  function mintId(uint256 id) external {
    _safeMint(msg.sender, id);
  }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
pragma solidity 0.8.16;

import { Base } from "../../../common/Base.sol";
import { SummonChampion } from "../types/Types.sol";
import { ISummonChampion } from "../interfaces/ISummonChampion.sol";
import { ERC721Enumerable, ERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SummonChampions is Base, ERC721Enumerable, ISummonChampion {
  // vars
  string public baseURI;
  uint256 public currentId = 28000;
  mapping(uint256 => SummonChampion.TokenInfo) public tokens;

  constructor() ERC721("TheRedVillageChampions", "TRVC") {}

  /* View */
  // verified
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Non exists token");
    return string(abi.encodePacked(baseURI, tokens[_tokenId].uri_name));
  }

  // verified
  function getCurrentId() public view returns (uint256) {
    return currentId;
  }

  /* Admin */
  // verified
  function mintTo(address _owner, string memory _uriName) public onlyRoler("mintTo") returns (uint256 newChampionId) {
    newChampionId = currentId;
    _mint(_owner, currentId);
    tokens[currentId] = SummonChampion.TokenInfo({ uri_name: _uriName, timestamp: block.timestamp });
    currentId += 1;
  }

  function setTokenUriName(uint256 _tokenId, string memory _uriName) public onlyRoler("setTokenUriName") {
    tokens[_tokenId].uri_name = _uriName;
  }

  function setBaseURI(string memory _uri) public onlyRoler("setBaseURI") {
    baseURI = _uri;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Pellar + LightLink 2022

abstract contract Base is Ownable {
  // variable
  address public accessControlProvider = 0x0bF8b07D3A0C83C5DDe4e12143A4203897f55F90;

  constructor() {}

  // verified
  modifier onlyRoler(string memory _methodInfo) {
    require(_msgSender() == owner() || IAccessControl(accessControlProvider).hasRole(_msgSender(), address(this), _methodInfo), "Caller does not have permission");
    _;
  }

  // verified
  function setAccessControlProvider(address _contract) external onlyRoler("setAccessControlProvider") {
    accessControlProvider = _contract;
  }
}

interface IAccessControl {
  function hasRole(
    address _account,
    address _contract,
    string memory _methodInfo
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library SummonChampion {
  struct TokenInfo {
    string uri_name;
    uint256 timestamp;
  }
}

library SummonTypes {
  struct LineageMetadata {
    uint256 session_id;
    uint256 summon_type; // private, public, etc
    uint256 summoned_at;
    uint256 latest_summon_time;
  }

  struct LineageNode {
    bool inited;
    LineageMetadata metadata;
    uint256[] parents;
    uint256 original_mum;
  }

  struct ChampionInfo {
    // (session id => (summon_type => total_count)) // maximum summon times count in a session by summon types
    mapping(uint256 => mapping(uint256 => uint256)) session_summoned_count;

    // (type => total_count) // maximum summon times count in champion lifes by summon types
    mapping(uint256 => uint256) total_summoned_count;

    mapping(bytes => bytes) others; // put type here
  }

  struct SessionCheckpoint {
    bool inited;
    uint256 total_champions_summoned;
  }

  struct SummonSessionInfo {
    uint256 id;
    uint256 max_champions_summoned;
    uint256 summon_type;
    uint8 lineage_level;
    ParentSummonChampions[] parents;
    FixedFeeInfo fees;
  }

  struct ParentSummonChampions {
    uint256 champion_id;
    address owner;
    uint256 summon_eligible_after_session;
    uint256 max_per_life;
    uint256 max_per_session_by_type;
    uint256 max_per_session;
  }

  struct FixedFeeInfo {
    address currency;
    uint256 total_fee;

    address donor_receiver;
    uint256 donor_amount;

    uint256 platform_amount;

    DynamicFeeReceiver[] dynamic_fee_receivers;
  }

  struct DynamicFeeReceiver {
    address receiver;
    uint256 amount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// Pellar + LightLink 2022

interface ISummonChampion {
  // mint
  function mintTo(address _owner, string memory _uri) external returns (uint256);

  function getCurrentId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
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
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "./draft-ERC20Permit.sol";
import "../../../utils/math/Math.sol";
import "../../../governance/utils/IVotes.sol";
import "../../../utils/math/SafeCast.sol";
import "../../../utils/cryptography/ECDSA.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Votes is IVotes, ERC20Permit {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

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
    address private immutable _CACHED_THIS;

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
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
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
pragma solidity ^0.8.16;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

//
//   +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+
//   |T| |h| |e|   |R| |e| |d|   |V| |i| |l| |l| |a| |g| |e|
//   +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+
//
//
//   The Red Village + Pellar 2022
//

contract TheRedVillage is ERC20, ERC20Permit, ERC20Votes {
  constructor() ERC20("The Red Village", "TRV") ERC20Permit("The Red Village") {
    _mint(msg.sender, 100000000000000);
  }

  function decimals() public view virtual override returns (uint8) {
    return 6;
  }

  function _maxSupply() internal view virtual override returns (uint224) {
    return 100000000000000;
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._burn(account, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

//
//   +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+
//   |T| |h| |e|   |R| |e| |d|   |V| |i| |l| |l| |a| |g| |e|
//   +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+
//
//
//   The Red Village + Pellar 2022
//

contract TRVDeployer is Ownable {
  // 0 -> access control
  // 1 -> ca state
  // 2 -> cf state
  // 3 -> tournament state
  // 4 -> champion utils // new
  // 5 -> blooding service // new
  // 6 -> bloodbath service // new
  // 7 -> blood elo service // new
  // 8 -> solo service
  // 9 -> tournament route
  // 10 -> zoo keeper
  // 11 -> summoning restriction
  mapping(uint256 => address) public elements;

  // 0xcD408729542856080C16331aAE3ADAd9bc015B8c deployed deployer

  constructor() {
    // replace deployed contract here.
    elements[0] = 0x0bF8b07D3A0C83C5DDe4e12143A4203897f55F90;

    elements[1] = 0x5A06c52A8B4eF58173A91A8fFE342A09AaF4Fc9D;
    elements[2] = 0xCF25D328550Bd4e2A214e57331b04d80F0C088Ca;
    elements[3] = 0x913B34CB9597f899EEE159a0b5564e4cC2958330;

    elements[4] = 0xC26056434F8aE5E95Ef65c8791E8C100962e4817; // new
    elements[5] = 0xE493A00cb33FD62650998a2558724EF1bd198dEc; // new
    elements[6] = 0x767604eaAb3709D0dfAda3113753ed657bA6B4C3; // new
    elements[7] = 0x5CeEFf8B91a06762713d5B3e6fe3EB7C87f6DBBE; // new
    elements[8] = 0xA6DDBAf74eDd8A2A1A38f743dAEC6Ebe71499531;

    elements[9] = 0x570F2d96a114F272Fc461440B4C3b08dC7007F5E;

    elements[10] = 0x50509eCacA1665129280B5eaBFd5E93a8e5F58de;

    // summoning
    elements[11] = 0x889394882fA3d7fdc3A57627B1F32301b41e8628;
  }

  function setContracts(uint256[] memory _ids, address[] memory _contracts) external onlyOwner {
    require(_ids.length == _contracts.length, "Input mismatch");

    for (uint256 i = 0; i < _ids.length; i++) {
      elements[_ids[i]] = _contracts[i];
    }
  }

  function setupRouterRolesForAdmin(address[] memory _contracts) external onlyOwner {
    for (uint256 i = 0; i < _contracts.length; i++) {
      IAll(elements[0]).grantMaster(_contracts[i], elements[9]);
    }
  }

  function init() external onlyOwner {
    IAll(elements[0]).grantMaster(address(this), elements[1]);
    IAll(elements[0]).grantMaster(address(this), elements[2]);
    IAll(elements[0]).grantMaster(address(this), elements[3]);

    IAll(elements[0]).grantMaster(address(this), elements[4]);
    IAll(elements[0]).grantMaster(address(this), elements[5]);
    IAll(elements[0]).grantMaster(address(this), elements[6]);
    IAll(elements[0]).grantMaster(address(this), elements[7]);
    IAll(elements[0]).grantMaster(address(this), elements[8]);

    IAll(elements[0]).grantMaster(address(this), elements[9]);
    IAll(elements[0]).grantMaster(address(this), elements[10]);
  }

  function setup() external onlyOwner {
    IAll(elements[0]).setAccessControlProvider(elements[0]);
    IAll(elements[1]).setAccessControlProvider(elements[0]);
    IAll(elements[2]).setAccessControlProvider(elements[0]);
    IAll(elements[3]).setAccessControlProvider(elements[0]);
    IAll(elements[4]).setAccessControlProvider(elements[0]);
    IAll(elements[5]).setAccessControlProvider(elements[0]);
    IAll(elements[6]).setAccessControlProvider(elements[0]);
    IAll(elements[7]).setAccessControlProvider(elements[0]);
    IAll(elements[8]).setAccessControlProvider(elements[0]);
    IAll(elements[9]).setAccessControlProvider(elements[0]);
    IAll(elements[10]).setAccessControlProvider(elements[0]);
  }

  function bindingService() external onlyOwner {
    bindingRoleForService(elements[5]);
    bindingRoleForService(elements[6]);
    bindingRoleForService(elements[7]);
    bindingRoleForService(elements[8]);

    IAll(elements[5]).bindSummoningRestriction(elements[11]);
    IAll(elements[6]).bindSummoningRestriction(elements[11]);
    IAll(elements[7]).bindSummoningRestriction(elements[11]);
  }

  function bindingRoleForService(address _service) internal {
    IAll(elements[0]).grantMaster(_service, elements[1]);
    IAll(elements[0]).grantMaster(_service, elements[2]);
    IAll(elements[0]).grantMaster(_service, elements[3]);
    IAll(elements[0]).grantMaster(_service, elements[10]);
    IAll(elements[0]).grantMaster(_service, elements[11]);

    IAll(_service).bindChampionAttributesState(elements[1]);
    IAll(_service).bindChampionFightingState(elements[2]);
    IAll(_service).bindTournamentState(elements[3]);
    IAll(_service).bindChampionUtils(elements[4]);
    IAll(_service).bindZooKeeper(elements[10]);
  }

  function bindingRoleForRoute() external onlyOwner {
    IAll(elements[0]).grantMaster(elements[9], elements[5]);
    IAll(elements[0]).grantMaster(elements[9], elements[6]);
    IAll(elements[0]).grantMaster(elements[9], elements[7]);
    IAll(elements[0]).grantMaster(elements[9], elements[8]);
  }

  function bindingServiceForRoute() external onlyOwner {
    IAll(elements[9]).updateService(0, elements[8]);
    IAll(elements[9]).updateService(1, elements[5]);
    IAll(elements[9]).updateService(2, elements[6]);
    IAll(elements[9]).updateService(3, elements[7]);
  }
}

interface IAll {
  function setAccessControlProvider(address) external;

  function grantMaster(address, address) external;

  function bindChampionAttributesState(address) external;

  function bindChampionFightingState(address) external;

  function bindTournamentState(address) external;

  function bindChampionUtils(address) external;

  function bindSummoningRestriction(address) external;

  function bindZooKeeper(address) external;

  function updateService(uint64, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract SummoningDeployer is Ownable {
  // 0 -> access control
  // 1 -> ca state
  // 2 -> erc721 summoning champion // new
  // 3 -> summoning state // new
  // 4 -> champion utils // new
  // 5 -> summoning service // new
  // 6 -> summoning route // new
  // 7 -> zoo keeper
  // 8 -> summoning restriction
  mapping(uint256 => address) public elements;

  // 0xB048F230fbeB94a256803A62C326BF3c2D2Cfd32 deployer deployed at

  constructor() {
    // replace deployed contract here.
    elements[0] = 0x0bF8b07D3A0C83C5DDe4e12143A4203897f55F90;

    elements[1] = 0x5A06c52A8B4eF58173A91A8fFE342A09AaF4Fc9D;
    elements[2] = 0xDe972Ab55B73279E627b82706977643e604dCA24; // new
    elements[3] = 0xDf7fc1f01A5cC611cc7A04E1Ef639A6Ea78Ce18f; // new

    elements[4] = 0xC26056434F8aE5E95Ef65c8791E8C100962e4817; // new
    elements[5] = 0x3c2dDFE4FDfcc6f2cFa75Cf075Ac70665F90cc62; // new
    elements[6] = 0x36aa6E9717BBF0A46F6bfD8a624432C01676D26C; // new
    elements[7] = 0x50509eCacA1665129280B5eaBFd5E93a8e5F58de;
    elements[8] = 0x889394882fA3d7fdc3A57627B1F32301b41e8628;
  }

  function setContracts(uint256[] memory _ids, address[] memory _contracts) external onlyOwner {
    require(_ids.length == _contracts.length, "Input mismatch");

    for (uint256 i = 0; i < _ids.length; i++) {
      elements[_ids[i]] = _contracts[i];
    }
  }

  function setupRouterRolesForAdmin(address[] memory _contracts) external onlyOwner {
    for (uint256 i = 0; i < _contracts.length; i++) {
      IAll(elements[0]).grantMaster(_contracts[i], elements[6]);
    }
  }

  function init() external onlyOwner {
    IAll(elements[0]).grantMaster(address(this), elements[1]);
    IAll(elements[0]).grantMaster(address(this), elements[2]);
    IAll(elements[0]).grantMaster(address(this), elements[3]);

    IAll(elements[0]).grantMaster(address(this), elements[4]);
    IAll(elements[0]).grantMaster(address(this), elements[5]);
    IAll(elements[0]).grantMaster(address(this), elements[6]);
    IAll(elements[0]).grantMaster(address(this), elements[7]);

    IAll(elements[0]).grantMaster(address(this), elements[8]);
  }

  function setup() external onlyOwner {
    IAll(elements[0]).setAccessControlProvider(elements[0]);
    IAll(elements[1]).setAccessControlProvider(elements[0]);
    IAll(elements[2]).setAccessControlProvider(elements[0]);
    IAll(elements[3]).setAccessControlProvider(elements[0]);
    IAll(elements[4]).setAccessControlProvider(elements[0]);
    IAll(elements[5]).setAccessControlProvider(elements[0]);
    IAll(elements[6]).setAccessControlProvider(elements[0]);
    IAll(elements[7]).setAccessControlProvider(elements[0]);
    IAll(elements[8]).setAccessControlProvider(elements[0]);
  }

  function bindingSummoningRestriction() external onlyOwner {
    IAll(elements[8]).bindSummoningState(elements[3]);
  }

  function bindingService() external onlyOwner {
    IAll(elements[0]).grantMaster(elements[5], elements[1]);
    IAll(elements[0]).grantMaster(elements[5], elements[2]);
    IAll(elements[0]).grantMaster(elements[5], elements[3]);
    IAll(elements[0]).grantMaster(elements[5], elements[7]);

    IAll(elements[5]).bindChampionAttributesState(elements[1]);
    IAll(elements[5]).bindSummoningChampionContract(elements[2]);
    IAll(elements[5]).bindSummoningState(elements[3]);
    IAll(elements[5]).bindChampionUtils(elements[4]);
    IAll(elements[5]).bindZooKeeper(elements[7]);
  }

  function bindingServiceForRoute() external onlyOwner {
    IAll(elements[0]).grantMaster(elements[6], elements[5]);
    IAll(elements[6]).bindService(elements[5]);
  }
}

interface IAll {
  function setAccessControlProvider(address) external;

  function grantMaster(address, address) external;

  function bindChampionAttributesState(address) external;

  function bindSummoningChampionContract(address) external;

  function bindSummoningState(address) external;

  function bindChampionUtils(address) external;

  function bindZooKeeper(address) external;

  function bindService(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Base } from "../../../common/Base.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../interfaces/IZooKeeper.sol";

// Pellar + LightLink 2022

contract TRVZooKeeper is Base, IZooKeeper, ERC721Holder, ERC1155Holder {
  function transferERC20In(
    address _currency,
    address _from,
    uint256 _amount
  ) external override onlyRoler("transferERC20In") {
    IERC20(_currency).transferFrom(_from, address(this), _amount);
  }

  function transferERC20Out(
    address _currency,
    address _to,
    uint256 _amount
  ) external override onlyRoler("transferERC20Out") {
    IERC20(_currency).transfer(_to, _amount);
  }

  function transferERC721In(
    address _currency,
    address _from,
    uint256 _tokenId
  ) external override onlyRoler("transferERC721In") {
    IERC721(_currency).transferFrom(_from, address(this), _tokenId);
  }

  function transferERC721Out(
    address _currency,
    address _to,
    uint256 _tokenId
  ) external override onlyRoler("transferERC721Out") {
    IERC721(_currency).transferFrom(address(this), _to, _tokenId);
  }

  function transferERC1155In(
    address _currency,
    address _from,
    uint256 _id,
    uint256 _amount
  ) external override onlyRoler("transferERC1155In") {
    IERC1155(_currency).safeTransferFrom(_from, address(this), _id, _amount, '');
  }

  function transferERC1155Out(
    address _currency,
    address _to,
    uint256 _id,
    uint256 _amount
  ) external override onlyRoler("transferERC1155Out") {
    IERC1155(_currency).safeTransferFrom(address(this), _to, _id, _amount, '');
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
pragma solidity ^0.8.16;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/interfaces/IERC1155.sol";

// Pellar + LightLink 2022

interface IZooKeeper {
  function transferERC20In(
    address _currency,
    address _from,
    uint256 _amount
  ) external;

  function transferERC20Out(
    address _currency,
    address _to,
    uint256 _amount
  ) external;

  function transferERC721In(
    address _currency,
    address _from,
    uint256 _tokenId
  ) external;

  function transferERC721Out(
    address _currency,
    address _to,
    uint256 _tokenId
  ) external;

  function transferERC1155In(
    address _currency,
    address _from,
    uint256 _id,
    uint256 _amount
  ) external;

  function transferERC1155Out(
    address _currency,
    address _to,
    uint256 _id,
    uint256 _amount
  ) external;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
pragma solidity 0.8.16;

import { Base } from "../../../common/Base.sol";
import { IChampionUtils } from "../../../interfaces/IChampionUtils.sol";
import { TournamentTypes } from "../types/Types.sol";
import { ITournamentService } from "../interfaces/ITournamentService.sol";
import { ITournamentState } from "../interfaces/ITournamentState.sol";
import { IZooKeeper } from "../interfaces/IZooKeeper.sol";
import { ICAState } from "../interfaces/ICAState.sol";
import { ICFState } from "../interfaces/ICFState.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Pellar + LightLink 2022

contract BaseService is Base {
  bool public requireBlooded = false;
  // constants
  uint8 public SOLO_ID = 0;
  uint8 public BLOODING_ID = 1;
  uint8 public BLOODBATH_ID = 2;
  uint8 public BLOOD_ELO_ID = 3;

  // variables
  address public tournamentState;
  address public cFState;
  address public cAState;
  address public championUtils;
  address public summoningRestrictionAddr;
  address public zooKeeper;

  function toggleRequireBlooded(bool _state) external onlyRoler("toggleRequireBlooded") {
    requireBlooded = _state;
  }

  // reviewed
  function bindTournamentState(address _contract) external onlyRoler("bindTournamentState") {
    tournamentState = _contract;
  }

  // reviewed
  function bindChampionFightingState(address _contract) external onlyRoler("bindChampionFightingState") {
    cFState = _contract;
  }

  // reviewed
  function bindChampionAttributesState(address _contract) external onlyRoler("bindChampionAttributesState") {
    cAState = _contract;
  }

  // reviewed
  function bindChampionUtils(address _contract) external onlyRoler("bindChampionUtils") {
    championUtils = _contract;
  }

  function bindSummoningRestriction(address _contract) external onlyRoler("bindSummoningRestriction") {
    summoningRestrictionAddr = _contract;
  }

  function bindZooKeeper(address _contract) external onlyRoler("bindZooKeeper") {
    zooKeeper = _contract;
  }

  // reviewed
  // verified
  function splitSignature(bytes memory _sig)
    internal
    pure
    returns (
      uint8,
      bytes32,
      bytes32
    )
  {
    require(_sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  // reviewed
  // verified
  function getSigner(bytes memory _message, bytes memory _signature) internal pure returns (address) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(_message.length), _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s);
  }
}

contract BaseTournamentService is BaseService, ITournamentService {
  uint8 public serviceID;
  uint64 public currentTournamentID;
  mapping(address => uint256) public platformShare;
  mapping(string => bool) public createdKeys;

  function _updateFightingForJoin(uint256 _championID) internal {
    ICFState(cFState).increasePendingCount(_championID, serviceID);
  }

  // reviewed
  function _payForJoin(
    address _currency,
    uint256 _buyIn,
    address _payer
  ) internal virtual {
    if (_buyIn == 0) return;
    IZooKeeper(zooKeeper).transferERC20In(_currency, _payer, _buyIn);
  }

  function _refundByCancel(uint64 _serviceID, uint64 _tournamentID) internal virtual {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(_serviceID, _tournamentID);

    uint64 size = uint64(tournament.warriors.length);
    for (uint256 i = 0; i < size; i++) {
      ICFState(cFState).decreasePendingCount(tournament.warriors[i].ID, _serviceID);
      if (tournament.configs.buy_in > 0) {
        address receiver = tournament.warriors[i].account;
        IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, receiver, tournament.configs.buy_in);
      }
    }
  }

  // reviewed
  function _canChangeBuyIn(
    uint64 _serviceID,
    uint64 _tournamentID,
    uint256 _newBuyIn
  ) internal view returns (bool) {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(_serviceID, _tournamentID);
    return _newBuyIn == tournament.configs.buy_in || tournament.warriors.length == 0;
  }

  // reviewed
  function _isAlreadyJoin(TournamentTypes.Warrior[] memory _warriors, uint256 _championID) internal pure returns (bool) {
    uint256 size = _warriors.length;
    for (uint256 i = 0; i < size; i++) {
      if (_warriors[i].ID == _championID) return true;
    }
    return false;
  }

  // reviewed
  function _isInWhitelist(uint256[] memory _whitelist, uint256 _id) internal pure returns (bool) {
    uint16 size = uint16(_whitelist.length);
    if (size == 0) {
      return true;
    }
    for (uint16 i = 0; i < size; i++) {
      if (_id == _whitelist[i]) {
        return true;
      }
    }
    return false;
  }

  // reviewed
  function _isInBlacklist(uint256[] memory _blacklist, uint256 _id) internal pure returns (bool) {
    uint16 size = uint16(_blacklist.length);
    if (size == 0) {
      return false;
    }
    for (uint16 i = 0; i < size; i++) {
      if (_id == _blacklist[i]) {
        return true;
      }
    }
    return false;
  }

  // reviewed
  function _isInCharacterClassList(uint16[] memory _characterClasses, uint256 _id) internal view returns (bool) {
    uint16 size = uint16(_characterClasses.length);
    if (size == 0) {
      return true;
    }
    uint16 characterClass = ICAState(cAState).getCharacterClassByChampionId(_id);
    for (uint16 i = 0; i < size; i++) {
      if (characterClass == _characterClasses[i]) {
        return true;
      }
    }
    return false;
  }

  // reviewed
  function _validWinRate(
    uint256 _championID,
    uint16 _start,
    uint16 _end,
    uint32 _position,
    uint16 _minRate,
    uint16 _maxRate,
    uint16 _baseDivider
  ) internal view returns (bool) {
    if (_minRate == 0 && _maxRate == 0) {
      return true;
    }
    uint128 totalFought = ICFState(cFState).getTotalWinByPosition(_championID, _start, _end, 0);

    if (totalFought == 0) {
      return false;
    }

    uint128 totalWin = ICFState(cFState).getTotalWinByPosition(_championID, _start, _end, _position);

    uint256 precision = 10**18;

    return
      ((precision * _minRate) / _baseDivider) <= ((totalWin * precision) / totalFought) && //
      ((totalWin * precision) / totalFought) < ((precision * _maxRate) / _baseDivider);
  }

  // reviewed
  function createTournament(
    string[] memory _key,
    TournamentTypes.TournamentConfigs[] memory _configs, //
    TournamentTypes.TournamentRestrictions[] memory _restrictions
  ) external virtual override onlyRoler("createTournament") {
    require(_configs.length == _restrictions.length, "Input mismatch");
    uint64 size = uint64(_configs.length);
    uint64 currentID = currentTournamentID;
    for (uint64 i = 0; i < size; i++) {
      if (createdKeys[_key[i]]) {
        continue;
      }
      TournamentTypes.TournamentConfigs memory data = _configs[i];
      data.status = TournamentTypes.TournamentStatus.AVAILABLE; // override
      data.creator = tx.origin;
      ITournamentState(tournamentState).createTournament(serviceID, currentID, _key[i], data, _restrictions[i]);
      createdKeys[_key[i]] = true;
      currentID += 1;
    }
    currentTournamentID += size;
  }

  // reviewed
  function updateTournamentConfigs(uint64 _tournamentID, TournamentTypes.TournamentConfigs memory _configs) external virtual override onlyRoler("updateTournamentConfigs") {
    require(_canChangeBuyIn(serviceID, _tournamentID, _configs.buy_in), "TRV: Can not update buy in with player joined");
    ITournamentState(tournamentState).updateTournamentConfigs(serviceID, _tournamentID, _configs);
  }

  // reviewed
  function updateTournamentRestrictions(uint64 _tournamentID, TournamentTypes.TournamentRestrictions memory _restrictions) external virtual override onlyRoler("updateTournamentRestrictions") {
    ITournamentState(tournamentState).updateTournamentRestrictions(serviceID, _tournamentID, _restrictions);
  }

  function updateTournamentTopUp(TournamentTypes.TopupDto[] memory _tournaments) external virtual override onlyRoler("updateTournamentTopUp") {
    uint256 size = _tournaments.length;
    for (uint256 i = 0; i < size; i++) {
      ITournamentState(tournamentState).updateTournamentTopUp(serviceID, _tournaments[i].tournament_id, _tournaments[i].top_up);
    }
  }

  // reviewed
  function cancelTournament(uint64 _tournamentID, bytes memory) external virtual override onlyRoler("cancelTournament") {
    _refundByCancel(serviceID, _tournamentID);
    ITournamentState(tournamentState).cancelTournament(serviceID, _tournamentID);
  }

  function eligibleJoinTournament(uint64, uint256) public view virtual override returns (bool, string memory) {
    return (true, "");
  }

  // _signature
  function joinTournament(bytes memory _signature, bytes memory _params) external virtual override onlyRoler("joinTournament") {
    address signer = tx.origin;
    // service ID, tournamentID, ...
    (uint64 _serviceID, uint64 tournamentID, address joiner, uint256 championID, uint16 stance) = abi.decode(_params, (uint64, uint64, address, uint256, uint16));

    if (_signature.length > 0) {
      bytes memory message = abi.encodePacked(
        "Tournament Type: ", //
        Strings.toString(_serviceID),
        ",",
        " Tournament ID: ",
        Strings.toString(tournamentID),
        ",",
        " Champion ID: ",
        Strings.toString(championID),
        ",",
        " Stance: ",
        Strings.toString(stance)
      );
      signer = getSigner(message, _signature);
    }

    require(_serviceID == serviceID, "TRV: Non-relay attack");
    require(signer == joiner, "TRV: Signer mismatch"); // require signature match with joiner
    require(IChampionUtils(championUtils).isOwnerOf(signer, championID), "TRV: Require owner"); // require owner of token

    (bool eligible, string memory errMsg) = eligibleJoinTournament(tournamentID, championID);
    require(eligible, errMsg);

    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, tournamentID);
    require(tournament.configs.status == TournamentTypes.TournamentStatus.AVAILABLE, "TRV: Tournament not available");

    _payForJoin(tournament.configs.currency, tournament.configs.buy_in, joiner);
    _updateFightingForJoin(championID);

    ITournamentState(tournamentState).joinTournament(serviceID, tournamentID, TournamentTypes.Warrior({ account: signer, ID: championID, stance: stance, win_position: 0, data: "" }));
  }

  // reviewed
  function completeTournament(
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors,
    TournamentTypes.EloDto[] memory _championsElo,
    bytes memory _additionalInfo
  ) external virtual override onlyRoler("completeTournament") {
    require(_warriors.length == _championsElo.length, "Array mismatch");
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, _tournamentID);
    for (uint256 i = 0; i < _championsElo.length; i++) {
      ICFState(cFState).setChampionElo(_championsElo[i].champion_id, _championsElo[i].elo);
    }

    uint256 prizePool = tournament.configs.buy_in * tournament.configs.size + tournament.configs.top_up;
    uint256 share = ((prizePool * tournament.configs.fee_percentage) / 10000);
    platformShare[tournament.configs.currency] += share;

    uint256 winnings = prizePool - share;

    // double up type
    if (_additionalInfo.length > 0) {
      address[] memory receivers = abi.decode(_additionalInfo, (address[]));
      if (receivers.length > 0) {
        for (uint8 i; i < receivers.length; i++) {
          IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, receivers[i], winnings / receivers.length);
        }

        winnings = 0;
      }
    }

    for (uint256 i = 0; i < _warriors.length; i++) {
      require(_warriors[i].win_position > 0, "Invalid position");
      _warriors[i].account = tournament.warriors[i].account;
      _warriors[i].stance = tournament.warriors[i].stance;

      if (_warriors[i].win_position == 1) {
        IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, _warriors[i].account, (winnings * 70) / 100);
      }
      if (_warriors[i].win_position == 2) {
        IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, _warriors[i].account, (winnings * 30) / 100);
      }
      ICFState(cFState).increaseRankingsCount(_warriors[i].ID, serviceID, 0); // update total fought
      ICFState(cFState).increaseRankingsCount(_warriors[i].ID, serviceID, _warriors[i].win_position); // update ranking
      ICFState(cFState).decreasePendingCount(_warriors[i].ID, serviceID);
    }
    ITournamentState(tournamentState).completeTournament(serviceID, _tournamentID, _warriors);
  }
}

interface ITRVBPToken {
  function ownerOf(uint256 tokenId) external view returns (address owner);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface IStaking {
  function getStaker(uint256 _championID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IChampionUtils {
  function isOwnerOf(address _account, uint256 _championID) external view returns (bool);

  function isOriginalOwnerOf(address _account, uint256 _championID) external view returns (bool);

  function getTokenContract(uint256 _championID) external view returns (address);

  function maxFightPerChampion() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Pellar + LightLink 2022

library CommonTypes {
  struct Object {
    bytes key; // convert string to bytes ie: bytes("other_key")
    bytes value; // output of abi.encode(arg);
  }
}

// this is for tournaments (should not change)
library TournamentTypes {
  // status
  enum TournamentStatus {
    AVAILABLE,
    READY,
    COMPLETED,
    CANCELLED
  }

  struct TopupDto {
    uint64 tournament_id;
    uint256 top_up;
  }

  struct EloDto {
    uint256 champion_id;
    uint64 elo;
  }

  // id, owner, stance, position
  struct Warrior {
    address account;
    uint32 win_position;
    uint256 ID;
    uint16 stance;
    bytes data; // <- for dynamic data
  }

  struct TournamentConfigs {
    address creator;
    uint32 size;
    address currency; // address of currency that support
    TournamentStatus status;
    uint16 fee_percentage; // * fee_percentage and div for 10000
    uint256 start_at;
    uint256 buy_in;
    uint256 top_up;
    bytes data;
  }

  struct TournamentRestrictions {
    uint64 elo_min;
    uint64 elo_max;

    uint16 win_rate_percent_min;
    uint16 win_rate_percent_max;
    uint16 win_rate_base_divider;

    uint256[] whitelist;
    uint256[] blacklist;

    uint16[] character_classes;

    bytes data; // <= for dynamic data
  }

  // tournament information
  struct TournamentInfo {
    bool inited;
    TournamentConfigs configs;
    TournamentRestrictions restrictions;
    Warrior[] warriors;
  }
}

// champion class <- tournamnet type
library ChampionFightingTypes {
  struct ChampionInfo {
    bool elo_inited;
    uint64 elo;
    mapping(uint64 => uint64) pending;
    mapping(uint64 => mapping(uint32 => uint64)) rankings; // description: count rankings, how many 1st, 2nd, 3rd, 4th, 5th, .... map with index of mapping.
    mapping(bytes => bytes) others; // put type here
  }
}

// CA contract related
library ChampionAttributeTypes {
  struct GeneralAttributes {
    string name;
    uint16 background;
    uint16 bloodline;
    uint16 genotype;
    uint16 character_class;
    uint16 breed;
    uint16 armor_color; // US Spelling
    uint16 hair_color; // US Spelling
    uint16 hair_class;
    uint16 hair_style;
    uint16 warpaint_color;
    uint16 warpaint_style;
  }

  struct Attributes {
    GeneralAttributes general;
    mapping(bytes => bytes) others;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import { TournamentTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ITournamentService {
  // join tournament
  function joinTournament(bytes memory _signature, bytes memory _params) external;

  // create tournament
  function createTournament(string[] memory _key, TournamentTypes.TournamentConfigs[] memory configs, TournamentTypes.TournamentRestrictions[] memory _restrictions) external;

  // update tournament
  function updateTournamentConfigs(
    uint64 _tournamentID,
    TournamentTypes.TournamentConfigs memory _data
  ) external;

  function updateTournamentRestrictions(
    uint64 _tournamentID,
    TournamentTypes.TournamentRestrictions memory _data
  ) external;

  function updateTournamentTopUp(TournamentTypes.TopupDto[] memory _tournaments) external;

  // cancel tournament
  function cancelTournament(uint64 _tournamentID, bytes memory _params) external;

  function eligibleJoinTournament(uint64 _tournamentID, uint256 _championID) external view returns (bool, string memory);

  function completeTournament(
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors,
    TournamentTypes.EloDto[] memory _championsElo,
    bytes memory
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import { TournamentTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ITournamentState {
  // create tournament
  function createTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    string memory _key,
    TournamentTypes.TournamentConfigs memory _data,
    TournamentTypes.TournamentRestrictions memory _restrictions
  ) external;

  // update tournament
  function updateTournamentConfigs(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentConfigs memory _data
  ) external;

  function updateTournamentRestrictions(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentRestrictions memory _data
  ) external;

  function updateTournamentTopUp(
    uint64 _serviceID,
    uint64 _tournamentID,
    uint256 _topUp
  ) external;

  function joinTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.Warrior memory _warrior
  ) external;

  function completeTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors
  ) external;

  function cancelTournament(
    uint64 _serviceID,
    uint64 _tournamentID
  ) external;

  function getTournamentsByClassAndId(uint64 _serviceID, uint64 _tournamentID) external view returns (TournamentTypes.TournamentInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Pellar + LightLink 2022

import { ChampionAttributeTypes, CommonTypes } from "../types/Types.sol";

interface ICAState {
  function setGeneralAttributes(
    uint256[] memory _tokenIds,
    ChampionAttributeTypes.GeneralAttributes[] memory _attributes
  ) external;

  function setOtherAttributes(
    uint256[] memory _tokenIds,
    CommonTypes.Object[] memory _attributes
  ) external;

  // get
  function getCharacterClassByChampionId(uint256 _tokenId) external view returns (uint16);

  function getGeneralAttributesByChampionId(
    uint256 _tokenId
  ) external view returns (ChampionAttributeTypes.GeneralAttributes memory);

  function getOtherAttributeByChampionId(
    uint256 _tokenId,
    bytes memory _key
  ) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Pellar + LightLink 2022

interface ICFState {
  // increase ranking count by position
  function increaseRankingsCount(
    uint256 _championID,
    uint64 _serviceID,
    uint32 _position
  ) external;

  function increasePendingCount(uint256 _championID, uint64 _serviceID) external;

  function decreasePendingCount(uint256 _championID, uint64 _serviceID) external;

  function setChampionElo(uint256 _championID, uint64 _elo) external;

  // get position count of champion in a service type
  function getRankingsCount(
    uint256 _championID,
    uint64 _serviceID,
    uint32 _position
  ) external view returns (uint64);

  // get total win by position
  function getTotalWinByPosition(
    uint256 _championID,
    uint64 _start,
    uint64 _end,
    uint32 _position
  ) external view returns (uint128 total);

  // get total pending
  function getTotalPending(uint256 _championID, uint64 _start, uint64 _end) external view returns (uint128 total);

  function eloInited(uint256 _championID) external view returns (bool);

  function getChampionElo(uint256 _championID) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Base2.sol";
import { ISummoningRestrictions } from "../../../interfaces/ISummoningRestrictions.sol";

// Pellar + LightLink 2022

contract BloodingService is BaseTournamentService {
  constructor() {
    serviceID = BLOODING_ID;
    currentTournamentID = 24000;
  }

  // reviewed
  function eligibleJoinTournament(uint64 _tournamentID, uint256 _championID) public view virtual override returns (bool, string memory) {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, _tournamentID);

    if (_isAlreadyJoin(tournament.warriors, _championID)) {
      return (false, "TRV: Already joined"); // check if join or not
    }

    if (!ISummoningRestrictions(summoningRestrictionAddr).summoningEligibleToFight(_championID)) {
      return (false, "TRV: Require reach time after summoning");
    }

    if (ICFState(cFState).getTotalPending(_championID, SOLO_ID, SOLO_ID) > 0) {
      return (false, "TRV: Having bet NFT pending");
    }

    if (ICFState(cFState).getTotalPending(_championID, BLOODING_ID, BLOODING_ID) > 0) {
      return (false, "TRV: Only 1 blooding at the same time");
    }

    if (ICFState(cFState).getRankingsCount(_championID, serviceID, 1) > 0) {
      return (false, "TRV: Require unblooded"); // 1 => first win
    }

    if (ICFState(cFState).getTotalPending(_championID, BLOODING_ID, 30) >= IChampionUtils(championUtils).maxFightPerChampion()) {
      return (false, "TRV: Exceed max fight per champion");
    }

    if (!_isInCharacterClassList(tournament.restrictions.character_classes, _championID)) {
      return (false, "TRV: character class required");
    }

    if (!_isInWhitelist(tournament.restrictions.whitelist, _championID)) {
      return (false, "TRV: whitelist required");
    }

    if (_isInBlacklist(tournament.restrictions.blacklist, _championID)) {
      return (false, "TRV: non-blacklist required");
    }
    return (true, "");
  }

  function withdrawPlatformShare(address _currency, address _to) external onlyRoler("withdrawPlatformShare") {
    uint256 amount = platformShare[_currency];
    platformShare[_currency] = 0;
    IZooKeeper(zooKeeper).transferERC20Out(_currency, _to, amount);
  }
}

contract BloodbathService is BaseTournamentService {
  constructor() {
    serviceID = BLOODBATH_ID;
    currentTournamentID = 24000;
  }

  // reviewed
  function eligibleJoinTournament(uint64 _tournamentID, uint256 _championID) public view virtual override returns (bool, string memory) {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, _tournamentID);

    if (_isAlreadyJoin(tournament.warriors, _championID)) {
      return (false, "TRV: Already joined"); // check if join or not
    }

    if (!ISummoningRestrictions(summoningRestrictionAddr).summoningEligibleToFight(_championID)) {
      return (false, "TRV: Require reach time after summoning");
    }

    if (ICFState(cFState).getTotalPending(_championID, SOLO_ID, SOLO_ID) > 0) {
      return (false, "TRV: Having bet NFT pending");
    }

    uint128 totalFought;
    for (uint8 i = BLOODING_ID; i <= 30; i++) {
      totalFought += ICFState(cFState).getRankingsCount(_championID, i, 0);
    }

    if (requireBlooded && !(ICFState(cFState).getRankingsCount(_championID, BLOODING_ID, 1) > 0 || totalFought >= 5)) {
      // => 1 => first win, service ID = 1 => blooding
      // => 0 => total fought, service ID = 1
      return (false, "TRV: Require blooded");
    }

    if (ICFState(cFState).getTotalPending(_championID, BLOODING_ID, 30) >= IChampionUtils(championUtils).maxFightPerChampion()) {
      return (false, "TRV: Exceed max fight per champion");
    }

    if (!_validWinRate(_championID, BLOODING_ID, 30, 1, tournament.restrictions.win_rate_percent_min, tournament.restrictions.win_rate_percent_max, tournament.restrictions.win_rate_base_divider)) {
      return (false, "TRV: require win rate eligible");
    }

    if (!_isInCharacterClassList(tournament.restrictions.character_classes, _championID)) {
      return (false, "TRV: character class required");
    }

    if (!_isInWhitelist(tournament.restrictions.whitelist, _championID)) {
      return (false, "TRV: whitelist required");
    }

    if (_isInBlacklist(tournament.restrictions.blacklist, _championID)) {
      return (false, "TRV: non-blacklist required");
    }
    return (true, "");
  }

  function withdrawPlatformShare(address _currency, address _to) external onlyRoler("withdrawPlatformShare") {
    uint256 amount = platformShare[_currency];
    platformShare[_currency] = 0;
    IZooKeeper(zooKeeper).transferERC20Out(_currency, _to, amount);
  }
}

contract BloodEloService is BaseTournamentService {
  constructor() {
    serviceID = BLOOD_ELO_ID;
    currentTournamentID = 24000;
  }

  // reviewed
  function eligibleJoinTournament(uint64 _tournamentID, uint256 _championID) public view virtual override returns (bool, string memory) {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, _tournamentID);

    if (_isAlreadyJoin(tournament.warriors, _championID)) {
      return (false, "TRV: Already joined"); // check if join or not
    }

    if (!ISummoningRestrictions(summoningRestrictionAddr).summoningEligibleToFight(_championID)) {
      return (false, "TRV: Require reach time after summoning");
    }

    if (ICFState(cFState).getTotalPending(_championID, SOLO_ID, SOLO_ID) > 0) {
      return (false, "TRV: Having bet NFT pending");
    }

    uint128 totalFought;
    for (uint8 i = BLOODING_ID; i <= 30; i++) {
      totalFought += ICFState(cFState).getRankingsCount(_championID, i, 0);
    }

    if (requireBlooded && !(ICFState(cFState).getRankingsCount(_championID, BLOODING_ID, 1) > 0 || totalFought >= 5)) {
      // => 1 => first win, service ID = 1 => blooding
      // => 0 => total fought, service ID = 1
      return (false, "TRV: Require blooded");
    }

    if (ICFState(cFState).getTotalPending(_championID, BLOODING_ID, 30) >= IChampionUtils(championUtils).maxFightPerChampion()) {
      return (false, "TRV: Exceed max fight per champion");
    }

    uint64 elo = ICFState(cFState).getChampionElo(_championID);

    if (!(tournament.restrictions.elo_min <= elo && elo < tournament.restrictions.elo_max)) {
      return (false, "TRV: elo required");
    }

    if (!_validWinRate(_championID, BLOODING_ID, 30, 1, tournament.restrictions.win_rate_percent_min, tournament.restrictions.win_rate_percent_max, tournament.restrictions.win_rate_base_divider)) {
      return (false, "TRV: require win rate eligible");
    }

    if (!_isInCharacterClassList(tournament.restrictions.character_classes, _championID)) {
      return (false, "TRV: character class required");
    }

    if (!_isInWhitelist(tournament.restrictions.whitelist, _championID)) {
      return (false, "TRV: whitelist required");
    }

    if (_isInBlacklist(tournament.restrictions.blacklist, _championID)) {
      return (false, "TRV: non-blacklist required");
    }
    return (true, "");
  }

  function withdrawPlatformShare(address _currency, address _to) external onlyRoler("withdrawPlatformShare") {
    uint256 amount = platformShare[_currency];
    platformShare[_currency] = 0;
    IZooKeeper(zooKeeper).transferERC20Out(_currency, _to, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../modules/summoning/interfaces/ISummoningRestrictions.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import { SummonTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ISummoningRestrictions {
  function setParentFightEligibleDurations(uint256 _seconds) external;

  function setChildFightEligibleDurations(uint256 _seconds) external;

  function summoningEligibleToFight(uint256 _championID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Base } from "../../../common/Base.sol";
import { SummonTypes } from "../types/Types.sol";
import { ISummoningRestrictions } from "../interfaces/ISummoningRestrictions.sol";
import { ISummoningState, SummonTypes } from "../../../interfaces/ISummoningState.sol";

contract SummoningRestrictions is Base, ISummoningRestrictions {
  address public summoningState;
  uint256 public parentFightEligibleDuration = 2 days;
  uint256 public childFightEligibleDuration = 0;

  function bindSummoningState(address _contract) external onlyRoler("bindSummoningState") {
    summoningState = _contract;
  }

  function setParentFightEligibleDurations(uint256 _seconds) external onlyRoler("setParentFightEligibleDurations") {
    parentFightEligibleDuration = _seconds;
  }

  function setChildFightEligibleDurations(uint256 _seconds) external onlyRoler("setChildFightEligibleDurations") {
    childFightEligibleDuration = _seconds;
  }

  function summoningEligibleToFight(uint256 _championID) external view returns (bool) {
    SummonTypes.LineageNode memory summoningChamp = ISummoningState(summoningState).getLineageNode(_championID);
    if (summoningChamp.metadata.summoned_at >= summoningChamp.metadata.latest_summon_time) {
      return summoningChamp.metadata.summoned_at + childFightEligibleDuration <= block.timestamp;
    }
    return summoningChamp.metadata.latest_summon_time + parentFightEligibleDuration <= block.timestamp;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../modules/summoning/interfaces/ISummoningState.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import { SummonTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ISummoningState {
  function createSession(string memory) external;

  function setTotalChampionsSummonedInSession(uint256 _sessionId, uint256 _total) external;

  function increaseTotalChampionsSummonedInSession(uint256 _sessionId) external;

  function decreaseTotalChampionsSummonedInSession(uint256 _sessionId) external;

  function setLineageNode(
    uint256 _championID, //
    SummonTypes.LineageMetadata memory _metadata,
    uint256[] memory _parents,
    uint256 _originalMum,
    bytes memory _notes
  ) external;

  // session
  function setTotalParticipateInSessionByChampions(
    uint256[] memory _championIDs, //
    uint256[] memory _sessionIDs,
    uint256[] memory _types, //
    uint256[] memory _counts
  ) external;

  function increaseTotalParticipateInSessionByChampion(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _type
  ) external;

  function decreaseTotalParticipateInSessionByChampion(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _type
  ) external;

  // life
  function setTotalParticipateInLifeByChampions(
    uint256[] memory _championIDs, //
    uint256[] memory _types, //
    uint256[] memory _counts
  ) external;

  function increaseTotalParticipateInLifeByChampion(uint256 _championID, uint256 _type) external;

  function decreaseTotalParticipateInLifeByChampion(uint256 _championID, uint256 _type) external;

  function tickChampionsSummoned(uint256 _sessionID, bytes32 _key) external;

  function increasePlatformShare(address _currency, uint256 _amount) external;

  function decreasePlatformShare(address _currency, uint256 _amount) external;

  /** View */
  function getCurrentSessionId() external view returns (uint256);

  function getTotalChampionsSummonedInSession(uint256 _sessionId) external view returns (uint256);

  function getLineageNode(uint256 _championID) external view returns (SummonTypes.LineageNode memory);

  function getChampionSummonedAtSession(uint256 _championID) external view returns (uint256);

  function getTotalParticipateInSessionByChampionAndType(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _type
  ) external view returns (uint256);

  function getTotalParticipateInSessionByChampion(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256);

  function getTotalParticipateInLifeByChampionAndType(uint256 _championID, uint256 _type) external view returns (uint256);

  function getTotalParticipateInLifeByChampion(
    uint256 _championID,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256);

  function getChampionsSummonedTicked(uint256 _sessionID, bytes32 _key) external view returns (bool);

  function getPlatformShare(address _currency) external view returns (uint256);

  function getSummonedTimestamp(uint256 _championID) external view returns (uint256);

  function getLatestSummonedTimestamp(uint256 _championID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Base } from "../../../common/Base.sol";
import { ICAState } from "../../../interfaces/ICAState.sol";
import { IZooKeeper } from "../../../interfaces/IZooKeeper.sol";
import { IChampionUtils } from "../../../interfaces/IChampionUtils.sol";
import { SummonTypes } from "../types/Types.sol";
import { ChampionAttributeTypes } from "../../../types/Types.sol";
import { ISummoningService } from "../interfaces/ISummoningService.sol";
import { ISummoningState } from "../interfaces/ISummoningState.sol";
import { ISummonChampion } from "../interfaces/ISummonChampion.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SummoningService is Base, ISummoningService {
  address public cAState;
  address public summonChampion;
  address public summoningState;
  address public championUtils;
  address public zooKeeper;
  address public verifier = 0x9f6B54d48AD2175e56a1BA9bFc74cd077213B68D;

  /* Setup */
  // verified
  function bindChampionAttributesState(address _contract) external onlyRoler("bindChampionAttributesState") {
    cAState = _contract;
  }

  // verified
  function bindSummoningChampionContract(address _contract) external onlyRoler("bindSummoningChampionContract") {
    summonChampion = _contract;
  }

  // verified
  function bindSummoningState(address _contract) external onlyRoler("bindSummoningState") {
    summoningState = _contract;
  }

  // verified
  function bindChampionUtils(address _contract) external onlyRoler("bindChampionUtils") {
    championUtils = _contract;
  }

  // verified
  function bindZooKeeper(address _contract) external onlyRoler("bindZooKeeper") {
    zooKeeper = _contract;
  }

  // verified
  function updateVerifier(address _newAccount) external onlyRoler("updateVerifier") {
    verifier = _newAccount;
  }

  // verified
  function withdrawPlatformShare(address _currency, address _to) external onlyRoler("withdrawPlatformShare") {
    uint256 amount = ISummoningState(summoningState).getPlatformShare(_currency);
    IZooKeeper(zooKeeper).transferERC20Out(
      _currency, //
      _to,
      amount
    );
    ISummoningState(summoningState).decreasePlatformShare(_currency, amount);
  }

  /* Logic */
  // verified
  function createSession(string memory _key) external onlyRoler("createSession") {
    ISummoningState(summoningState).createSession(_key);
  }

  // verified
  function paidFees(SummonTypes.SummonSessionInfo memory _sessionInfo, address _payer) internal {
    // transfer fee before update data
    uint256 _totalFee = _sessionInfo.fees.donor_amount + _sessionInfo.fees.platform_amount;

    uint256 dyFeeSize = _sessionInfo.fees.dynamic_fee_receivers.length;
    for (uint256 i; i < dyFeeSize; i++) {
      _totalFee += _sessionInfo.fees.dynamic_fee_receivers[i].amount;
    }

    require(_totalFee == _sessionInfo.fees.total_fee, "TRV: Fee mismatch");

    // paid fee
    IZooKeeper(zooKeeper).transferERC20In(
      _sessionInfo.fees.currency, //
      _payer,
      _sessionInfo.fees.total_fee
    );

    // transfer fee to donor
    IZooKeeper(zooKeeper).transferERC20Out(
      _sessionInfo.fees.currency, //
      _sessionInfo.fees.donor_receiver,
      _sessionInfo.fees.donor_amount
    );

    // fee to platform
    ISummoningState(summoningState).increasePlatformShare(_sessionInfo.fees.currency, _sessionInfo.fees.platform_amount);

    // other parties
    for (uint256 i; i < dyFeeSize; i++) {
      IZooKeeper(zooKeeper).transferERC20Out(
        _sessionInfo.fees.currency, //
        _sessionInfo.fees.dynamic_fee_receivers[i].receiver,
        _sessionInfo.fees.dynamic_fee_receivers[i].amount
      );
    }
  }

  // verified
  function updateStateInfo(SummonTypes.SummonSessionInfo memory _sessionInfo, bytes32 _key) internal returns (uint256[] memory) {
    // update timer to avoid relay attack
    ISummoningState(summoningState).tickChampionsSummoned(_sessionInfo.id, _key);

    // update total champions in session
    ISummoningState(summoningState).increaseTotalChampionsSummonedInSession(_sessionInfo.id);

    uint256[] memory _parents = new uint256[](_sessionInfo.parents.length);
    for (uint256 i; i < _sessionInfo.parents.length; i++) {
      // update total participate of champion in session
      ISummoningState(summoningState).increaseTotalParticipateInSessionByChampion(
        _sessionInfo.parents[i].champion_id, //
        _sessionInfo.id,
        _sessionInfo.summon_type
      );

      // update total participate of champion in life
      ISummoningState(summoningState).increaseTotalParticipateInLifeByChampion(
        _sessionInfo.parents[i].champion_id, //
        _sessionInfo.summon_type
      );

      // store parents
      _parents[i] = _sessionInfo.parents[i].champion_id;
    }

    return _parents;
  }

  // verified
  function summonNewChampion(
    SummonTypes.SummonSessionInfo memory _sessionInfo,
    address _owner, //
    ChampionAttributeTypes.GeneralAttributes memory _attributes,
    uint256[] memory _parents,
    bytes memory _notes
  ) internal {
    // mint champion
    uint256 newChampionId = ISummonChampion(summonChampion).getCurrentId();
    ISummonChampion(summonChampion).mintTo(_owner, string(abi.encodePacked(Strings.toString(newChampionId), ".json")));
    // create champion attributes
    uint256[] memory tokenIds = new uint256[](1);
    ChampionAttributeTypes.GeneralAttributes[] memory champAttributes = new ChampionAttributeTypes.GeneralAttributes[](1);
    tokenIds[0] = newChampionId;
    champAttributes[0] = _attributes;
    ICAState(cAState).setGeneralAttributes(tokenIds, champAttributes);
    // create lineageNode
    ISummoningState(summoningState).setLineageNode(
      newChampionId, //
      SummonTypes.LineageMetadata({
        session_id: _sessionInfo.id, //
        summon_type: _sessionInfo.summon_type,
        summoned_at: block.timestamp,
        latest_summon_time: block.timestamp
      }),
      _parents,
      getOriginalMum(_parents[1]),
      _notes
    );
  }

  // verified
  function summon(
    bytes calldata _verifySignature,
    bytes memory _signature,
    bytes memory _params
  ) public onlyRoler("summon") {
    address signer = tx.origin;

    (
      SummonTypes.SummonSessionInfo memory sessionInfo, //
      address summonOwner,
      uint256 timer,
      bytes memory notes
    ) = abi.decode(_params, (SummonTypes.SummonSessionInfo, address, uint256, bytes));

    (uint8 gifts, ChampionAttributeTypes.GeneralAttributes memory attributes) = abi.decode(notes, (uint8, ChampionAttributeTypes.GeneralAttributes));
    require(sessionInfo.parents.length == 2, "TRV: Not enough parents");
    require(sessionInfo.fees.donor_receiver == sessionInfo.parents[0].owner, "TRV: Donor mismatch");

    if (_signature.length > 0) {
      // TODO:
      // add something to uniq message
      bytes memory message = abi.encodePacked(
        "Summoning ID: ", //
        Strings.toString(sessionInfo.id),
        ",",
        " Champion IDs: ",
        Strings.toString(sessionInfo.parents[0].champion_id),
        " # ",
        Strings.toString(sessionInfo.parents[1].champion_id),
        ",",
        " Timer: ",
        Strings.toString(timer)
      );
      signer = getSigner(message, _signature);
    }

    // check admin signature is ok
    require(verifier == getSigner(_params, _verifySignature), "TRV: Require verified");

    // check signature ok - gasless or not
    require(signer == summonOwner, "TRV: Signer mismatch"); // require signature match with joiner
    require(IChampionUtils(championUtils).isOriginalOwnerOf(signer, sessionInfo.parents[1].champion_id), "TRV: Require owner");
    require(IChampionUtils(championUtils).isOriginalOwnerOf(sessionInfo.parents[0].owner, sessionInfo.parents[0].champion_id), "TRV: Donor delisted");
    bytes32 key = keccak256(abi.encodePacked(Strings.toString(sessionInfo.parents[0].champion_id), " # ", Strings.toString(sessionInfo.parents[1].champion_id), " Timer: ", Strings.toString(timer)));
    require(!ISummoningState(summoningState).getChampionsSummonedTicked(sessionInfo.id, key), "TRV: Already summoned");

    // check eligible
    (bool eligible, string memory errMsg) = eligibleSummon(sessionInfo);
    require(eligible, errMsg);

    // pay fee
    paidFees(sessionInfo, signer);

    uint256[] memory _parents = updateStateInfo(sessionInfo, key);

    for (uint8 i; i < gifts; i++) {
      summonNewChampion(sessionInfo, summonOwner, attributes, _parents, notes);
    }
  }

  // verified
  function eligibleSummon(SummonTypes.SummonSessionInfo memory _sessionInfo) public view returns (bool, string memory) {
    // check if exceed max champions per session
    if (ISummoningState(summoningState).getTotalChampionsSummonedInSession(_sessionInfo.id) >= _sessionInfo.max_champions_summoned) {
      return (false, "TRV: Error 1");
    }

    for (uint256 i; i < _sessionInfo.parents.length; i++) {
      // check if exceed max per champion in session
      if (
        ISummoningState(summoningState).getTotalParticipateInSessionByChampionAndType(
          _sessionInfo.parents[i].champion_id, //
          _sessionInfo.id,
          _sessionInfo.summon_type
        ) >= _sessionInfo.parents[i].max_per_session_by_type
      ) {
        return (false, string(abi.encodePacked("TRV: Error 2 by #", Strings.toString(_sessionInfo.parents[i].champion_id))));
      }

      // check if exceed max per champion in session
      if (
        ISummoningState(summoningState).getTotalParticipateInSessionByChampion(
          _sessionInfo.parents[i].champion_id, //
          _sessionInfo.id,
          0,
          30
        ) >= _sessionInfo.parents[i].max_per_session
      ) {
        return (false, string(abi.encodePacked("TRV: Error 5 by #", Strings.toString(_sessionInfo.parents[i].champion_id))));
      }

      // check if exceed max per champion in life
      if (
        ISummoningState(summoningState).getTotalParticipateInLifeByChampion(
          _sessionInfo.parents[i].champion_id, //
          0,
          30
        ) >= _sessionInfo.parents[i].max_per_life
      ) {
        return (false, string(abi.encodePacked("TRV: Error 3 by #", Strings.toString(_sessionInfo.parents[i].champion_id))));
      }

      // check if parent summoned before
      if ((ISummoningState(summoningState).getChampionSummonedAtSession(_sessionInfo.parents[i].champion_id) + _sessionInfo.parents[i].summon_eligible_after_session) > _sessionInfo.id) {
        return (
          false,
          string(
            abi.encodePacked(
              "TRV: Error 4 by #", //
              Strings.toString(_sessionInfo.parents[i].champion_id),
              " wait for *",
              Strings.toString(_sessionInfo.parents[i].summon_eligible_after_session)
            )
          )
        );
      }
    }

    // check lineage
    if (!lineageEligible(_sessionInfo.parents[0].champion_id, _sessionInfo.parents[1].champion_id, _sessionInfo.lineage_level)) {
      return (false, "TRV: Lineage ineligible");
    }

    return (true, "");
  }

  // verified
  function lineageEligible(
    uint256 _firstChampionID,
    uint256 _secondChampionID,
    uint8 _level
  ) public view returns (bool) {
    // list ancestors
    uint256[] memory firstAncestors = getAncestors(_firstChampionID, _level, new uint256[](0));
    uint256[] memory secondAncestors = getAncestors(_secondChampionID, _level, new uint256[](0));

    // check if same at least 1 ancestor return false
    for (uint256 i; i < firstAncestors.length; i++) {
      for (uint256 j; j < secondAncestors.length; j++) {
        if (firstAncestors[i] == secondAncestors[j]) return false;
      }
    }

    return true;
  }

  function getOriginalMum(uint256 _championMumID) public view returns (uint256) {
    if (isNodeLeaf(_championMumID)) {
      return _championMumID;
    }
    SummonTypes.LineageNode memory node = ISummoningState(summoningState).getLineageNode(_championMumID);

    return node.original_mum;
  }

  // verified
  function getAncestors(
    uint256 _championID,
    uint8 _level,
    uint256[] memory _ancestors
  ) public view returns (uint256[] memory) {
    _ancestors = new uint256[](1);
    _ancestors[0] = _championID;
    if (isNodeLeaf(_championID) || _level == 0) {
      return _ancestors;
    }

    SummonTypes.LineageNode memory node = ISummoningState(summoningState).getLineageNode(_championID);
    uint256 size = node.parents.length;
    for (uint256 i; i < size; i++) {
      uint256[] memory newAncestors = getAncestors(node.parents[i], _level - 1, _ancestors);
      _ancestors = concatenateArrays(_ancestors, newAncestors);
    }
    return _ancestors;
  }

  // verified
  function concatenateArrays(uint256[] memory _first, uint256[] memory _second) public pure returns (uint256[] memory) {
    uint256 newSize = _first.length + _second.length;
    uint256[] memory output = new uint256[](newSize);

    for (uint256 j; j < _first.length; j++) {
      output[j] = _first[j];
    }

    uint256 currentIdx = _first.length;
    for (uint256 j; j < _second.length; j++) {
      output[currentIdx + j] = _second[j];
    }
    return output;
  }

  // verified
  function isNodeLeaf(uint256 _championID) public pure returns (bool) {
    if (_championID < 28000) return true;
    return false;
  }

  function splitSignature(bytes memory _sig)
    internal
    pure
    returns (
      uint8,
      bytes32,
      bytes32
    )
  {
    require(_sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  // reviewed
  // verified
  function getSigner(bytes memory _message, bytes memory _signature) internal pure returns (address) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(_message.length), _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../modules/tournament_v2/interfaces/ICAState.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../modules/tournament_v2/interfaces/IZooKeeper.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../modules/tournament_v2/types/Types.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SummonTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ISummoningService {
  function withdrawPlatformShare(address _currency, address _to) external;

  function createSession(string memory _key) external;

  function summon(
    bytes calldata _verifySignature,
    bytes memory _signature,
    bytes memory _params
  ) external;

  function eligibleSummon(SummonTypes.SummonSessionInfo memory _sessionInfo) external view returns (bool, string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Base } from "../../../common/Base.sol";
import { SummonTypes } from "../types/Types.sol";
import { ISummoningRoute } from "../interfaces/ISummoningRoute.sol";
import { ISummoningService } from "../interfaces/ISummoningService.sol";

// Pellar + LightLink 2022

contract SummoningRoute is Base, ISummoningRoute {
  address public summoningService;

  function bindService(address _contract) external onlyRoler("bindService") {
    require(_contract != address(0), "Must set non-zero address");
    summoningService = _contract;
  }

  function withdrawPlatformShare(address _currency, address _to) external onlyRoler("withdrawPlatformShare") {
    ISummoningService(summoningService).withdrawPlatformShare(_currency, _to);
  }

  function createSession(string memory _key) external onlyRoler("createSession") {
    ISummoningService(summoningService).createSession(_key);
  }

  function summon(
    bytes memory _verifySignature,
    bytes memory _signature,
    bytes memory _params
  ) public {
    require(summoningService != address(0), "Non-exists service");
    ISummoningService(summoningService).summon(_verifySignature, _signature, _params);
  }

  function batchSummon(
    bytes[] memory _verifySignatures,
    bytes[] memory _signatures,
    bytes[] memory _params
  ) public {
    require(_params.length == _signatures.length, "Input mismatch");
    for (uint256 i = 0; i < _params.length; i++) {
      summon(_verifySignatures[i], _signatures[i], _params[i]);
    }
  }

  function eligibleSummon(SummonTypes.SummonSessionInfo memory _sessionInfo) public view returns (bool, string memory) {
    return ISummoningService(summoningService).eligibleSummon(_sessionInfo);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SummonTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ISummoningRoute {
  // bind service processing summon
  function bindService(address _service) external;

  function withdrawPlatformShare(address _currency, address _to) external;

  // summon
  function createSession(string memory _key) external;

  function summon(
    bytes memory _verifySignature,
    bytes memory _signature,
    bytes memory _params
  ) external;

  // batch summon
  function batchSummon(
    bytes[] memory _verifySignatures,
    bytes[] memory _signatures,
    bytes[] memory _params
  ) external;

  function eligibleSummon(SummonTypes.SummonSessionInfo memory _sessionInfo) external view returns (bool, string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Base } from "../../../common/Base.sol";
import { SummonTypes } from "../types/Types.sol";
import { ISummoningState } from "../interfaces/ISummoningState.sol";

contract SummoningState is Base, ISummoningState {
  // vars
  uint256 public currentSessionId = 1;

  mapping(uint256 => SummonTypes.LineageNode) public lineageTree;

  // summon (champion_id => info)
  mapping(uint256 => SummonTypes.ChampionInfo) champions;

  mapping(uint256 => SummonTypes.SessionCheckpoint) public sessionCheckpoints;
  mapping(string => bool) public createdKeys;

  mapping(uint256 => mapping(bytes32 => bool)) public tickSummoned;

  mapping(address => uint256) public platformShare;

  // TODO: events
  event SessionUpdated(uint256 indexed id, string key, uint256 timestamp, SummonTypes.SessionCheckpoint checkpoint);
  event LineageNodeUpdated(uint256 indexed id, uint256 championID, SummonTypes.LineageNode node, uint256[] totalJoinedInSessionByType, uint256[] totalJoinedInLifeByType, bytes notes);

  /**Set */
  // verified
  function createSession(string memory _key) external onlyRoler("createSession") {
    if (createdKeys[_key]) {
      return;
    }
    sessionCheckpoints[currentSessionId].inited = true;
    createdKeys[_key] = true;
    emit SessionUpdated(currentSessionId, _key, block.timestamp, sessionCheckpoints[currentSessionId]);
    currentSessionId += 1;
  }

  // verified
  function setOriginalMum(uint256 _championID, uint256 _mumID) external onlyRoler("setOriginalMum") {
    lineageTree[_championID].original_mum = _mumID;
    uint256 size = lineageTree[_championID].parents.length;
    uint256[] memory totalJoinedInSessionByType = new uint256[](size);
    uint256[] memory totalJoinedInLifeByType = new uint256[](size);

    for (uint256 i = 0; i < size; i++) {
      totalJoinedInSessionByType[i] = getTotalParticipateInSessionByChampionAndType(lineageTree[_championID].parents[i], lineageTree[_championID].metadata.session_id, lineageTree[_championID].metadata.summon_type);
      totalJoinedInLifeByType[i] = getTotalParticipateInLifeByChampionAndType(lineageTree[_championID].parents[i], lineageTree[_championID].metadata.summon_type);
    }
    emit LineageNodeUpdated(lineageTree[_championID].metadata.session_id, _championID, lineageTree[_championID], totalJoinedInSessionByType, totalJoinedInLifeByType, '0x');
  }

  // verified
  function setTotalChampionsSummonedInSession(uint256 _sessionId, uint256 _total) external onlyRoler("setTotalChampionsSummonedInSession") {
    sessionCheckpoints[_sessionId].total_champions_summoned = _total;
    emit SessionUpdated(_sessionId, "", block.timestamp, sessionCheckpoints[_sessionId]);
  }

  // verified
  function increaseTotalChampionsSummonedInSession(uint256 _sessionId) external onlyRoler("increaseTotalChampionsSummonedInSession") {
    sessionCheckpoints[_sessionId].total_champions_summoned += 1;
    emit SessionUpdated(_sessionId, "", block.timestamp, sessionCheckpoints[_sessionId]);
  }

  // verified
  function decreaseTotalChampionsSummonedInSession(uint256 _sessionId) external onlyRoler("decreaseTotalChampionsSummonedInSession") {
    if (sessionCheckpoints[_sessionId].total_champions_summoned > 0) {
      sessionCheckpoints[_sessionId].total_champions_summoned -= 1;
    }
    emit SessionUpdated(_sessionId, "", block.timestamp, sessionCheckpoints[_sessionId]);
  }

  // verified
  function setLineageNode(
    uint256 _championID, //
    SummonTypes.LineageMetadata memory _metadata,
    uint256[] memory _parents,
    uint256 _originalMum,
    bytes memory _notes
  ) external onlyRoler("setLineageNode") {
    require(sessionCheckpoints[_metadata.session_id].inited, "Session not inited");
    SummonTypes.LineageNode storage lineageNode = lineageTree[_championID];

    lineageNode.inited = true;
    lineageNode.metadata = _metadata;
    lineageNode.parents = _parents;
    lineageNode.original_mum = _originalMum;

    uint256 size = _parents.length;

    uint256[] memory totalJoinedInSessionByType = new uint256[](size);
    uint256[] memory totalJoinedInLifeByType = new uint256[](size);

    for (uint256 i = 0; i < size; i++) {
      totalJoinedInSessionByType[i] = getTotalParticipateInSessionByChampionAndType(_parents[i], _metadata.session_id, _metadata.summon_type);
      totalJoinedInLifeByType[i] = getTotalParticipateInLifeByChampionAndType(_parents[i], _metadata.summon_type);
      lineageTree[_parents[i]].metadata.latest_summon_time = block.timestamp;
    }
    emit LineageNodeUpdated(_metadata.session_id, _championID, lineageNode, totalJoinedInSessionByType, totalJoinedInLifeByType, _notes);
  }

  function setLatestTimeSummoned(uint256 _championID, uint256 _amount) external onlyRoler("setLatestTimeSummoned") {
    lineageTree[_championID].metadata.latest_summon_time = _amount;
  }

  // session
  // verified
  function setTotalParticipateInSessionByChampions(
    uint256[] memory _championIDs, //
    uint256[] memory _sessionIDs,
    uint256[] memory _types, //
    uint256[] memory _counts
  ) external onlyRoler("setTotalParticipateInSessionByChampions") {
    require(_championIDs.length == _sessionIDs.length, "Input mismatch");
    require(_championIDs.length == _types.length, "Input mismatch");
    require(_championIDs.length == _counts.length, "Input mismatch");

    uint256 size = _championIDs.length;
    for (uint256 i = 0; i < size; i++) {
      champions[_championIDs[i]].session_summoned_count[_sessionIDs[i]][_types[i]] = _counts[i];
    }
  }

  // verified
  function increaseTotalParticipateInSessionByChampion(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _type
  ) external onlyRoler("increaseTotalParticipateInSessionByChampion") {
    champions[_championID].session_summoned_count[_sessionID][_type] += 1;
  }

  // verified
  function decreaseTotalParticipateInSessionByChampion(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _type
  ) external onlyRoler("decreaseTotalParticipateInSessionByChampion") {
    if (champions[_championID].session_summoned_count[_sessionID][_type] > 0) {
      champions[_championID].session_summoned_count[_sessionID][_type] -= 1;
    }
  }

  // life
  // verified
  function setTotalParticipateInLifeByChampions(
    uint256[] memory _championIDs, //
    uint256[] memory _types, //
    uint256[] memory _counts
  ) external onlyRoler("setTotalParticipateInLifeByChampions") {
    require(_championIDs.length == _types.length, "Input mismatch");
    require(_championIDs.length == _counts.length, "Input mismatch");

    uint256 size = _championIDs.length;
    for (uint256 i = 0; i < size; i++) {
      champions[_championIDs[i]].total_summoned_count[_types[i]] = _counts[i];
    }
  }

  // verified
  function increaseTotalParticipateInLifeByChampion(uint256 _championID, uint256 _type) external onlyRoler("increaseTotalParticipateInLifeByChampion") {
    champions[_championID].total_summoned_count[_type] += 1;
  }

  // verified
  function decreaseTotalParticipateInLifeByChampion(uint256 _championID, uint256 _type) external onlyRoler("decreaseTotalParticipateInLifeByChampion") {
    if (champions[_championID].total_summoned_count[_type] > 0) {
      champions[_championID].total_summoned_count[_type] -= 1;
    }
  }

  // verified
  function tickChampionsSummoned(uint256 _sessionID, bytes32 _key) external onlyRoler("tickChampionsSummoned") {
    tickSummoned[_sessionID][_key] = true;
  }

  // verified
  function increasePlatformShare(address _currency, uint256 _amount) external onlyRoler("increasePlatformShare") {
    platformShare[_currency] += _amount;
  }

  // verified
  function decreasePlatformShare(address _currency, uint256 _amount) external onlyRoler("decreasePlatformShare") {
    platformShare[_currency] -= _amount;
  }

  /** View */
  // verified
  function getCurrentSessionId() public view returns (uint256) {
    return currentSessionId;
  }

  // verified
  function getTotalChampionsSummonedInSession(uint256 _sessionId) public view returns (uint256) {
    return sessionCheckpoints[_sessionId].total_champions_summoned;
  }

  // verified
  function getLineageNode(uint256 _championID) public view returns (SummonTypes.LineageNode memory) {
    return lineageTree[_championID];
  }

  // verified
  function getChampionSummonedAtSession(uint256 _championID) public view returns (uint256) {
    return lineageTree[_championID].metadata.session_id;
  }

  // verified
  function getTotalParticipateInSessionByChampionAndType(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _type
  ) public view returns (uint256) {
    return champions[_championID].session_summoned_count[_sessionID][_type];
  }

  // verified
  function getTotalParticipateInSessionByChampion(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _start,
    uint256 _end
  ) public view returns (uint256 sum) {
    for (uint256 i = _start; i <= _end; i++) {
      sum += champions[_championID].session_summoned_count[_sessionID][i];
    }
  }

  // verified
  function getTotalParticipateInLifeByChampionAndType(uint256 _championID, uint256 _type) public view returns (uint256) {
    return champions[_championID].total_summoned_count[_type];
  }

  // verified
  function getTotalParticipateInLifeByChampion(
    uint256 _championID,
    uint256 _start,
    uint256 _end
  ) public view returns (uint256 sum) {
    for (uint256 i = _start; i <= _end; i++) {
      sum += champions[_championID].total_summoned_count[i];
    }
  }

  // verified
  function getChampionsSummonedTicked(uint256 _sessionID, bytes32 _key) public view returns (bool) {
    return tickSummoned[_sessionID][_key];
  }

  // verified
  function getPlatformShare(address _currency) public view returns (uint256) {
    return platformShare[_currency];
  }

  // verified
  function getSummonedTimestamp(uint256 _championID) public view returns (uint256) {
    return lineageTree[_championID].metadata.summoned_at;
  }

  // verified
  function getLatestSummonedTimestamp(uint256 _championID) public view returns (uint256) {
    return lineageTree[_championID].metadata.latest_summon_time;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Base } from "../../../common/Base.sol";
import { TournamentTypes } from "../types/Types.sol";
import { ITournamentService } from "../interfaces/ITournamentService.sol";
import { ITournamentState } from "../interfaces/ITournamentState.sol";
import { IZooKeeper } from "../interfaces/IZooKeeper.sol";
import { ICAState } from "../interfaces/ICAState.sol";
import { ICFState } from "../interfaces/ICFState.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Pellar + LightLink 2022

contract BaseService is Base {
  bool public requireBlooded = false;
  // constants
  uint8 public SOLO_ID = 0;
  uint8 public BLOODING_ID = 1;
  uint8 public BLOODBATH_ID = 2;
  uint8 public BLOOD_ELO_ID = 3;

  // variables
  address public tournamentState;
  address public cFState;
  address public cAState;
  address public championUtils;
  address public zooKeeper;

  function toggleRequireBlooded(bool _state) external onlyRoler("toggleRequireBlooded") {
    requireBlooded = _state;
  }

  // reviewed
  function bindTournamentState(address _contract) external onlyRoler("bindTournamentState") {
    tournamentState = _contract;
  }

  // reviewed
  function bindChampionFightingState(address _contract) external onlyRoler("bindChampionFightingState") {
    cFState = _contract;
  }

  // reviewed
  function bindChampionAttributesState(address _contract) external onlyRoler("bindChampionAttributesState") {
    cAState = _contract;
  }

  // reviewed
  function bindChampionUtils(address _contract) external onlyRoler("bindChampionUtils") {
    championUtils = _contract;
  }

  function bindZooKeeper(address _contract) external onlyRoler("bindZooKeeper") {
    zooKeeper = _contract;
  }

  // reviewed
  // verified
  function splitSignature(bytes memory _sig)
    internal
    pure
    returns (
      uint8,
      bytes32,
      bytes32
    )
  {
    require(_sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  // reviewed
  // verified
  function getSigner(bytes memory _message, bytes memory _signature) internal pure returns (address) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(_message.length), _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s);
  }
}

contract BaseTournamentService is BaseService, ITournamentService {
  uint8 public serviceID;
  uint64 public currentTournamentID;
  mapping(address => uint256) public platformShare;
  mapping(string => bool) public createdKeys;

  function _updateFightingForJoin(uint256 _championID) internal {
    ICFState(cFState).increasePendingCount(_championID, serviceID);
  }

  // reviewed
  function _payForJoin(
    address _currency,
    uint256 _buyIn,
    address _payer
  ) internal virtual {
    if (_buyIn == 0) return;
    IZooKeeper(zooKeeper).transferERC20In(_currency, _payer, _buyIn);
  }

  function _refundByCancel(uint64 _serviceID, uint64 _tournamentID) internal virtual {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(_serviceID, _tournamentID);

    uint64 size = uint64(tournament.warriors.length);
    for (uint256 i = 0; i < size; i++) {
      ICFState(cFState).decreasePendingCount(tournament.warriors[i].ID, _serviceID);
      if (tournament.configs.buy_in > 0) {
        address receiver = tournament.warriors[i].account;
        IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, receiver, tournament.configs.buy_in);
      }
    }
  }

  // reviewed
  function _canChangeBuyIn(
    uint64 _serviceID,
    uint64 _tournamentID,
    uint256 _newBuyIn
  ) internal view returns (bool) {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(_serviceID, _tournamentID);
    return _newBuyIn == tournament.configs.buy_in || tournament.warriors.length == 0;
  }

  // reviewed
  function _isAlreadyJoin(TournamentTypes.Warrior[] memory _warriors, uint256 _championID) internal pure returns (bool) {
    uint256 size = _warriors.length;
    for (uint256 i = 0; i < size; i++) {
      if (_warriors[i].ID == _championID) return true;
    }
    return false;
  }

  // reviewed
  function _isInWhitelist(uint256[] memory _whitelist, uint256 _id) internal pure returns (bool) {
    uint16 size = uint16(_whitelist.length);
    if (size == 0) {
      return true;
    }
    for (uint16 i = 0; i < size; i++) {
      if (_id == _whitelist[i]) {
        return true;
      }
    }
    return false;
  }

  // reviewed
  function _isInBlacklist(uint256[] memory _blacklist, uint256 _id) internal pure returns (bool) {
    uint16 size = uint16(_blacklist.length);
    if (size == 0) {
      return false;
    }
    for (uint16 i = 0; i < size; i++) {
      if (_id == _blacklist[i]) {
        return true;
      }
    }
    return false;
  }

  // reviewed
  function _isInCharacterClassList(uint16[] memory _characterClasses, uint256 _id) internal view returns (bool) {
    uint16 size = uint16(_characterClasses.length);
    if (size == 0) {
      return true;
    }
    uint16 characterClass = ICAState(cAState).getCharacterClassByChampionId(_id);
    for (uint16 i = 0; i < size; i++) {
      if (characterClass == _characterClasses[i]) {
        return true;
      }
    }
    return false;
  }

  // reviewed
  function _validWinRate(
    uint256 _championID,
    uint16 _start,
    uint16 _end,
    uint32 _position,
    uint16 _minRate,
    uint16 _maxRate,
    uint16 _baseDivider
  ) internal view returns (bool) {
    if (_minRate == 0 && _maxRate == 0) {
      return true;
    }
    uint128 totalFought = ICFState(cFState).getTotalWinByPosition(_championID, _start, _end, 0);

    if (totalFought == 0) {
      return false;
    }

    uint128 totalWin = ICFState(cFState).getTotalWinByPosition(_championID, _start, _end, _position);

    uint256 precision = 10**18;

    return
      ((precision * _minRate) / _baseDivider) <= ((totalWin * precision) / totalFought) && //
      ((totalWin * precision) / totalFought) < ((precision * _maxRate) / _baseDivider);
  }

  // reviewed
  function createTournament(
    string[] memory _key,
    TournamentTypes.TournamentConfigs[] memory _configs, //
    TournamentTypes.TournamentRestrictions[] memory _restrictions
  ) external virtual override onlyRoler("createTournament") {
    require(_configs.length == _restrictions.length, "Input mismatch");
    uint64 size = uint64(_configs.length);
    uint64 currentID = currentTournamentID;
    for (uint64 i = 0; i < size; i++) {
      if (createdKeys[_key[i]]) {
        continue;
      }
      TournamentTypes.TournamentConfigs memory data = _configs[i];
      data.status = TournamentTypes.TournamentStatus.AVAILABLE; // override
      data.creator = tx.origin;
      ITournamentState(tournamentState).createTournament(serviceID, currentID, _key[i], data, _restrictions[i]);
      createdKeys[_key[i]] = true;
      currentID += 1;
    }
    currentTournamentID += size;
  }

  // reviewed
  function updateTournamentConfigs(uint64 _tournamentID, TournamentTypes.TournamentConfigs memory _configs) external virtual override onlyRoler("updateTournamentConfigs") {
    require(_canChangeBuyIn(serviceID, _tournamentID, _configs.buy_in), "TRV: Can not update buy in with player joined");
    ITournamentState(tournamentState).updateTournamentConfigs(serviceID, _tournamentID, _configs);
  }

  // reviewed
  function updateTournamentRestrictions(uint64 _tournamentID, TournamentTypes.TournamentRestrictions memory _restrictions) external virtual override onlyRoler("updateTournamentRestrictions") {
    ITournamentState(tournamentState).updateTournamentRestrictions(serviceID, _tournamentID, _restrictions);
  }

  function updateTournamentTopUp(TournamentTypes.TopupDto[] memory _tournaments) external virtual override onlyRoler("updateTournamentTopUp") {
    uint256 size = _tournaments.length;
    for (uint256 i = 0; i < size; i++) {
      ITournamentState(tournamentState).updateTournamentTopUp(serviceID, _tournaments[i].tournament_id, _tournaments[i].top_up);
    }
  }

  // reviewed
  function cancelTournament(uint64 _tournamentID, bytes memory) external virtual override onlyRoler("cancelTournament") {
    _refundByCancel(serviceID, _tournamentID);
    ITournamentState(tournamentState).cancelTournament(serviceID, _tournamentID);
  }

  function eligibleJoinTournament(uint64, uint256) public view virtual override returns (bool, string memory) {
    return (true, "");
  }

  // _signature
  function joinTournament(bytes memory _signature, bytes memory _params) external virtual override onlyRoler("joinTournament") {
    address signer = tx.origin;
    // service ID, tournamentID, ...
    (uint64 _serviceID, uint64 tournamentID, address joiner, uint256 championID, uint16 stance) = abi.decode(_params, (uint64, uint64, address, uint256, uint16));

    if (_signature.length > 0) {
      bytes memory message = abi.encodePacked(
        "Tournament Type: ", //
        Strings.toString(_serviceID),
        ",",
        " Tournament ID: ",
        Strings.toString(tournamentID),
        ",",
        " Champion ID: ",
        Strings.toString(championID),
        ",",
        " Stance: ",
        Strings.toString(stance)
      );
      signer = getSigner(message, _signature);
    }

    require(_serviceID == serviceID, "TRV: Non-relay attack");
    require(signer == joiner, "TRV: Signer mismatch"); // require signature match with joiner
    require(IChampionUtils(championUtils).isOwnerOf(signer, championID), "TRV: Require owner"); // require owner of token

    (bool eligible, string memory errMsg) = eligibleJoinTournament(tournamentID, championID);
    require(eligible, errMsg);

    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, tournamentID);
    require(tournament.configs.status == TournamentTypes.TournamentStatus.AVAILABLE, "TRV: Tournament not available");

    _payForJoin(tournament.configs.currency, tournament.configs.buy_in, joiner);
    _updateFightingForJoin(championID);

    ITournamentState(tournamentState).joinTournament(serviceID, tournamentID, TournamentTypes.Warrior({ account: signer, ID: championID, stance: stance, win_position: 0, data: "" }));
  }

  // reviewed
  function completeTournament(
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors,
    TournamentTypes.EloDto[] memory _championsElo,
    bytes memory _additionalInfo
  ) external virtual override onlyRoler("completeTournament") {
    require(_warriors.length == _championsElo.length, "Array mismatch");
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, _tournamentID);
    for (uint256 i = 0; i < _championsElo.length; i++) {
      ICFState(cFState).setChampionElo(_championsElo[i].champion_id, _championsElo[i].elo);
    }

    uint256 prizePool = tournament.configs.buy_in * tournament.configs.size + tournament.configs.top_up;
    uint256 share = ((prizePool * tournament.configs.fee_percentage) / 10000);
    platformShare[tournament.configs.currency] += share;

    uint256 winnings = prizePool - share;

    // double up type
    if (_additionalInfo.length > 0) {
      address[] memory receivers = abi.decode(_additionalInfo, (address[]));
      if (receivers.length > 0) {
        for (uint8 i; i < receivers.length; i++) {
          IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, receivers[i], winnings / receivers.length);
        }

        winnings = 0;
      }
    }

    for (uint256 i = 0; i < _warriors.length; i++) {
      require(_warriors[i].win_position > 0, "Invalid position");
      _warriors[i].account = tournament.warriors[i].account;
      _warriors[i].stance = tournament.warriors[i].stance;

      if (_warriors[i].win_position == 1) {
        IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, _warriors[i].account, (winnings * 70) / 100);
      }
      if (_warriors[i].win_position == 2) {
        IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, _warriors[i].account, (winnings * 30) / 100);
      }
      ICFState(cFState).increaseRankingsCount(_warriors[i].ID, serviceID, 0); // update total fought
      ICFState(cFState).increaseRankingsCount(_warriors[i].ID, serviceID, _warriors[i].win_position); // update ranking
      ICFState(cFState).decreasePendingCount(_warriors[i].ID, serviceID);
    }
    ITournamentState(tournamentState).completeTournament(serviceID, _tournamentID, _warriors);
  }
}

interface IChampionUtils {
  function isOwnerOf(address _account, uint256 _championID) external view returns (bool);

  function isOriginalOwnerOf(address _account, uint256 _championID) external view returns (bool);

  function getTokenContract(uint256 _championID) external view returns (address);

  function maxFightPerChampion() external view returns (uint256);
}

interface ITRVBPToken {
  function ownerOf(uint256 tokenId) external view returns (address owner);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface IStaking {
  function getStaker(uint256 _championID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Base.sol";

// Pellar + LightLink 2022

contract SoloService is BaseTournamentService {
  constructor() {
    serviceID = SOLO_ID;
    currentTournamentID = 4000;
  }

  address public verifier = 0x9f6B54d48AD2175e56a1BA9bFc74cd077213B68D;

  uint256 public fixedFee = 8700000000000000;
  uint256 public fixedCancelFee;

  uint256 public threshold;
  uint16 public cutPercent; // div base = 1000

  mapping(uint64 => uint256) public fixedFeeCheckpoint;
  mapping(uint64 => uint256) public fixedFeeCancelCheckpoint;
  mapping(uint256 => bool) public booking;

  mapping(uint256 => uint64) public pendingNBN;

  // reviewed
  function updateVerifier(address _newAccount) external onlyRoler("updateVerifier") {
    verifier = _newAccount;
  }

  function updateFixedFee(uint256 _newFee) external onlyRoler("updateFixedFee") {
    require(_newFee >= fixedCancelFee, "Fee too small");
    fixedFee = _newFee;
  }

  function updateFixedCancelFee(uint256 _newFee) external onlyRoler("updateFixedCancelFee") {
    require(_newFee <= fixedFee, "Cancel fee too big");
    fixedCancelFee = _newFee;
  }

  // reviewed
  function updateCutPercent(uint256 _threshold, uint16 _cut) external onlyRoler("updateCutPercent") {
    require(_cut <= 1000, "TRV: Exceed max");
    threshold = _threshold;
    cutPercent = _cut;
  }

  // check if champion eligible to be challenged
  function challengeInfoByChampion(uint256 _championID)
    public
    view
    returns (
      bool isJoinedBetNFT,
      uint128 totalBetNFTPending,
      uint256 totalNotBetNFTPending,
      uint128 totalTournamentPending
    )
  {
    isJoinedBetNFT = IChampionUtils(championUtils).isOriginalOwnerOf(zooKeeper, _championID);
    totalBetNFTPending = ICFState(cFState).getTotalPending(_championID, SOLO_ID, SOLO_ID);
    totalNotBetNFTPending = pendingNBN[_championID];
    totalTournamentPending = ICFState(cFState).getTotalPending(_championID, BLOODING_ID, 30);
  }

  function eligibleJoinTournament(uint64 _tournamentID, uint256 _championID) public view virtual override returns (bool, string memory) {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, _tournamentID);

    if (_isAlreadyJoin(tournament.warriors, _championID)) {
      return (false, "TRV: Already joined"); // check if join or not
    }

    if (!_isInWhitelist(tournament.restrictions.whitelist, _championID)) {
      return (false, "TRV: Require opponent");
    }

    (bool betNFT, , , , uint256 expireTime) = abi.decode(tournament.configs.data, (bool, uint16, uint256, uint256, uint256));

    if (expireTime <= block.timestamp) {
      return (false, "TRV: Invite expired");
    }

    if (betNFT && pendingNBN[_championID] > 0) {
      return (false, "TRV: Already joined non-bet NFT fight");
    }

    return (true, "");
  }

  // reviewed
  // cancel will refund NFT token if need
  function _refundByCancel(uint64 _serviceID, uint64 _tournamentID) internal virtual override {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(_serviceID, _tournamentID);

    (bool betNFT, , uint256 stakeA) = abi.decode(tournament.configs.data, (bool, uint16, uint256));

    booking[tournament.configs.start_at] = false;

    if (betNFT) {
      ICFState(cFState).decreasePendingCount(tournament.restrictions.whitelist[0], serviceID);
      ICFState(cFState).decreasePendingCount(tournament.restrictions.whitelist[1], serviceID);
    }

    uint64 size = uint64(tournament.warriors.length);
    for (uint64 i = 0; i < size; i++) {
      uint256 championID = tournament.warriors[i].ID;
      address receiver = tournament.warriors[i].account;
      if (betNFT) {
        // refund
        IZooKeeper(zooKeeper).transferERC721Out(IChampionUtils(championUtils).getTokenContract(championID), receiver, championID);
      } else {
        if (pendingNBN[tournament.warriors[i].ID] > 0) {
          pendingNBN[tournament.warriors[i].ID] -= 1;
        }
      }
      IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, receiver, stakeA + fixedFeeCheckpoint[_tournamentID] - fixedFeeCancelCheckpoint[_tournamentID]);
    }
  }

  // 1st param = _signature
  function joinTournament(bytes memory, bytes memory _params) external virtual override onlyRoler("joinTournament") {
    address signer = tx.origin;
    // service ID, tournamentID, ...
    (uint64 _serviceID, uint64 tournamentID, address joiner, uint256 championID, uint16 stance) = abi.decode(_params, (uint64, uint64, address, uint256, uint16));

    require(_serviceID == serviceID, "TRV: Non-relay attack");
    require(signer == joiner, "TRV: Signer mismatch"); // require signature match with joiner
    require(IChampionUtils(championUtils).isOriginalOwnerOf(signer, championID), "TRV: Require owner"); // require owner of token

    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, tournamentID);
    require(tournament.configs.status == TournamentTypes.TournamentStatus.AVAILABLE, "TRV: Tournament not available");

    require(!_isAlreadyJoin(tournament.warriors, championID), "TRV: Already joined");
    require(_isInWhitelist(tournament.restrictions.whitelist, championID), "TRV: Opponent required");

    (bool betNFT, , , uint256 stakeB, uint256 expireTime) = abi.decode(tournament.configs.data, (bool, uint16, uint256, uint256, uint256));
    require(expireTime > block.timestamp, "TRV: Invite expired");

    if (betNFT) {
      require(pendingNBN[championID] == 0, "TRV: Already joined NBN");
      IZooKeeper(zooKeeper).transferERC721In(IChampionUtils(championUtils).getTokenContract(championID), joiner, championID);
    } else {
      pendingNBN[championID] += 1;
    }

    _payForJoin(tournament.configs.currency, fixedFeeCheckpoint[tournamentID] + stakeB, joiner);

    ITournamentState(tournamentState).joinTournament(
      serviceID,
      tournamentID,
      TournamentTypes.Warrior({
        account: signer, //
        ID: championID,
        stance: stance,
        win_position: 0,
        data: ""
      })
    );
  }

  // reviewed
  // 1st param = _signature
  function createChallenge(
    bytes calldata,
    bytes calldata _params,
    bytes calldata _verifySignature,
    TournamentTypes.TournamentConfigs memory _configs,
    TournamentTypes.TournamentRestrictions calldata _restrictions,
    bool _betNFT,
    uint256 _myStake
  ) external {
    // check signature
    address signer = msg.sender;
    (
      uint64 _serviceID, //
      address joiner,
      uint256 myChampionID,
      uint16 stance
    ) = abi.decode(_params, (uint64, address, uint256, uint16));

    // check requirements
    require(_serviceID == serviceID, "TRV: Non-relay attack");
    require(verifier == getSigner(abi.encode(_betNFT, _myStake, _configs, _restrictions), _verifySignature), "TRV: Require verified");
    require(signer == joiner, "TRV: Signer mismatch"); // require signature match with joiner
    require(IChampionUtils(championUtils).isOriginalOwnerOf(signer, myChampionID), "TRV: Require owner"); // require owner of token
    require(!IChampionUtils(championUtils).isOriginalOwnerOf(zooKeeper, _restrictions.whitelist[1]), "TRV: Opponent already joined BN"); // require owner of token
    require(!booking[_configs.start_at], "TRV: Already booked");
    {
      // abi.encode(betNFT, round, myStake, opponentStake, expireTime)
      booking[_configs.start_at] = true;
      _configs.creator = signer;
      _configs.size = 2;
      _configs.status = TournamentTypes.TournamentStatus.AVAILABLE;
      ITournamentState(tournamentState).createTournament(serviceID, currentTournamentID, "1v1", _configs, _restrictions);
      fixedFeeCheckpoint[currentTournamentID] = fixedFee;
      fixedFeeCancelCheckpoint[currentTournamentID] = fixedCancelFee;

      {
        if (_betNFT) {
          require(pendingNBN[_restrictions.whitelist[0]] == 0, "TRV: Challenger already joined NBN");
          require(pendingNBN[_restrictions.whitelist[1]] == 0, "TRV: Opponent already joined NBN");
          require(ICFState(cFState).getTotalPending(_restrictions.whitelist[0], BLOODING_ID, 30) == 0, "TRV: Challenger already joined tournament");
          require(ICFState(cFState).getTotalPending(_restrictions.whitelist[1], BLOODING_ID, 30) == 0, "TRV: Opponent already joined tournament");

          IZooKeeper(zooKeeper).transferERC721In(IChampionUtils(championUtils).getTokenContract(myChampionID), joiner, myChampionID);

          ICFState(cFState).increasePendingCount(_restrictions.whitelist[0], serviceID);
          ICFState(cFState).increasePendingCount(_restrictions.whitelist[1], serviceID);
        } else {
          pendingNBN[_restrictions.whitelist[0]] += 1;
        }

        _payForJoin(_configs.currency, fixedFee + _myStake, joiner);

        ITournamentState(tournamentState).joinTournament(
          serviceID,
          currentTournamentID,
          TournamentTypes.Warrior({
            account: signer, //
            ID: myChampionID,
            stance: stance,
            win_position: 0,
            data: ""
          })
        );
      }

      currentTournamentID += 1;
    }
  }

  // reviewed
  function createTournament(
    string[] memory _key,
    TournamentTypes.TournamentConfigs[] memory _configs, //
    TournamentTypes.TournamentRestrictions[] memory _restrictions
  ) external virtual override onlyRoler("createTournament") {}

  // reviewed
  function completeTournament(
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors,
    TournamentTypes.EloDto[] memory, // no ELO in 1v1
    bytes memory
  ) external virtual override onlyRoler("completeTournament") {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, _tournamentID);
    require(tournament.configs.status == TournamentTypes.TournamentStatus.READY, "Not allow"); // re-entry guard
    (bool betNFT, , uint256 stakeA, uint256 stakeB) = abi.decode(tournament.configs.data, (bool, uint16, uint256, uint256));

    uint256 cut;
    {
      if ((stakeA + stakeB + tournament.configs.top_up) > threshold) {
        cut = (((stakeA + stakeB + tournament.configs.top_up) * cutPercent) / 1000);
      }

      platformShare[tournament.configs.currency] += (fixedFeeCheckpoint[_tournamentID] * tournament.configs.size + cut);
    }

    uint256 winnings = (stakeA + stakeB + tournament.configs.top_up) - cut;
    address winner;

    for (uint256 i = 0; i < _warriors.length; i++) {
      require(_warriors[i].win_position > 0, "Invalid position");
      if (_warriors[i].win_position == 1) {
        IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, _warriors[i].account, winnings);
        winner = _warriors[i].account;
      }
      ICFState(cFState).increaseRankingsCount(_warriors[i].ID, serviceID, 0); // update total fought
      ICFState(cFState).increaseRankingsCount(_warriors[i].ID, serviceID, _warriors[i].win_position); // update ranking
    }

    if (betNFT) {
      for (uint256 i = 0; i < _warriors.length; i++) {
        IZooKeeper(zooKeeper).transferERC721Out(IChampionUtils(championUtils).getTokenContract(_warriors[i].ID), winner, _warriors[i].ID);
        ICFState(cFState).decreasePendingCount(_warriors[i].ID, serviceID);
      }
    } else {
      for (uint256 i = 0; i < _warriors.length; i++) {
        if (pendingNBN[_warriors[i].ID] > 0) {
          pendingNBN[_warriors[i].ID] -= 1;
        }
      }
    }

    ITournamentState(tournamentState).completeTournament(serviceID, _tournamentID, _warriors);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Base } from "../../common/Base.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TRVRaffle is Base {
  struct Reward {
    address reward_token;
    address receiver_address;
    uint256 amount;
  }

  address public signerAccount = 0x9f6B54d48AD2175e56a1BA9bFc74cd077213B68D;

  mapping(uint256 => mapping(string => mapping(address => bool))) public released;

  event Pledge(address indexed account, uint256 timePledged, bytes notes);
  event FundsReleased(uint256 indexed timestamps, string tag, Reward winner, bytes notes);

  function pledge(
    uint256 _timestamp,
    bytes memory _notes,
    bytes memory _signature
  ) external {
    bytes32 message = keccak256(abi.encodePacked(msg.sender, _timestamp, _notes));
    require(_timestamp >= block.timestamp, "Signature expired");
    require(validSignature(message, _signature), "Signature invalid");
    emit Pledge(msg.sender, block.timestamp, _notes);
  }

  function releaseFunds(
    Reward[] memory _winners,
    uint256 _timestamps,
    string memory _tag,
    bytes memory _notes
  ) external onlyRoler("releaseFunds") {
    uint256 size = _winners.length;
    for (uint256 i = 0; i < size; i++) {
      require(!released[_timestamps][_tag][_winners[i].receiver_address], "Already released");
      IERC20(_winners[i].reward_token).transfer(_winners[i].receiver_address, _winners[i].amount);
      released[_timestamps][_tag][_winners[i].receiver_address] = true;

      emit FundsReleased(_timestamps, _tag, _winners[i], _notes);
    }
  }

  /* Admin sections */
  function updateSigner(address _account) external onlyRoler("updateSigner") {
    signerAccount = _account;
  }

  function forceWithdrawToken(
    address _currency,
    address _to,
    uint256 _amount
  ) external onlyRoler("forceWithdrawToken") {
    IERC20(_currency).transfer(_to, _amount);
  }

  /** Internal */
  function splitSignature(bytes memory _sig)
    internal
    pure
    returns (
      uint8,
      bytes32,
      bytes32
    )
  {
    require(_sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  function validSignature(bytes32 _message, bytes memory _signature) internal view returns (bool) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s) == signerAccount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Base } from "../../../common/Base.sol";
import { ChampionFightingTypes, TournamentTypes } from "../types/Types.sol";
import { ICFState } from "../interfaces/ICFState.sol";

// Pellar + LightLink 2022

// champion fighting = CF
contract CFState is Base, ICFState {
  // variables
  uint64 public total;
  mapping(uint256 => ChampionFightingTypes.ChampionInfo) champions;

  /**Set */
  function setRankingsCount(uint256[] memory _championIDs, uint64[] memory _serviceIds, uint32[] memory _positions, uint64[] memory _counts) external onlyRoler("setRankingsCount") {
    require(_championIDs.length == _serviceIds.length, "Input mismatch");
    require(_championIDs.length == _positions.length, "Input mismatch");
    require(_championIDs.length == _counts.length, "Input mismatch");

    uint256 size = _championIDs.length;
    for (uint256 i = 0; i < size; i++) {
      champions[_championIDs[i]].rankings[_serviceIds[i]][_positions[i]] = _counts[i];
    }
  }

  function setPendingCount(uint256[] memory _championIDs, uint64[] memory _serviceIds, uint64[] memory _counts) external onlyRoler("setPendingCount") {
    require(_championIDs.length == _serviceIds.length, "Input mismatch");
    require(_championIDs.length == _counts.length, "Input mismatch");

    uint256 size = _championIDs.length;
    for (uint256 i = 0; i < size; i++) {
      champions[_championIDs[i]].pending[_serviceIds[i]] = _counts[i];
    }
  }

  // reviewed
  // position = 0 => set total fought
  // verified
  function increaseRankingsCount(uint256 _championID, uint64 _serviceId, uint32 _position) external onlyRoler("increaseRankingsCount") {
    champions[_championID].rankings[_serviceId][_position] += 1;
  }

  // reviewed
  // set pending count
  // verified
  function increasePendingCount(uint256 _championID, uint64 _serviceID) external onlyRoler("increasePendingCount") {
    champions[_championID].pending[_serviceID] += 1;
  }

  // reviewed
  // verified
  function decreasePendingCount(uint256 _championID, uint64 _serviceID) external onlyRoler("decreasePendingCount") {
    if (champions[_championID].pending[_serviceID] > 0) {
      champions[_championID].pending[_serviceID] -= 1;
    }
  }

  // reviewed
  // set champion elo
  function setChampionElo(uint256 _championID, uint64 _elo) public onlyRoler("setChampionElo") {
    if (!champions[_championID].elo_inited) {
      champions[_championID].elo_inited = true;
      total += 1;
    }
    champions[_championID].elo = _elo;
  }

  // reviewed
  // multiple call
  // verified
  function setMultipleChampionsElo(uint256[] calldata _championIds, uint64[] calldata _elos) external onlyRoler("setMultipleChampionsElo") {
    require(_championIds.length == _elos.length, "Input mismatch");
    for (uint16 i = 0; i < _championIds.length; i++) {
      setChampionElo(_championIds[i], _elos[i]);
    }
  }

  /** View */
  // reviewed
  // position = 0 => get total fought
  // verified
  function getRankingsCount(uint256 _championId, uint64 _serviceId, uint32 _position) public view returns (uint64) {
    return champions[_championId].rankings[_serviceId][_position];
  }

  // reviewed
  // get total pending
  // verified
  function getTotalPending(uint256 _championID, uint64 _start, uint64 _end) public view returns (uint128 sum) {
    for (uint64 i = _start; i <= _end; i++) {
      sum += champions[_championID].pending[i];
    }
  }

  // reviewed
  // position = 0 => get total fought
  // verified
  function getTotalWinByPosition(uint256 _championID, uint64 _start, uint64 _end, uint32 _position) public view returns (uint128 sum) {
    for (uint64 i = _start; i <= _end; i++) {
      sum += champions[_championID].rankings[i][_position];
    }
  }

  // reviewed
  // get elo
  // verified
  function eloInited(uint256 _championID) public view returns (bool) {
    return champions[_championID].elo_inited;
  }

  // reviewed
  // verified
  function getChampionElo(uint256 _championID) public view returns (uint64) {
    if (!champions[_championID].elo_inited) {
      return 1800;
    }
    return champions[_championID].elo;
  }

  // verified
  function getTotal() public view returns (uint64) {
    return total;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Base } from "../../../common/Base.sol";
import { TournamentTypes } from "../types/Types.sol";
import { ITournamentState } from "../interfaces/ITournamentState.sol";

// Pellar + LightLink 2022

contract TournamentState is Base, ITournamentState {
  event TournamentChanged(uint64 indexed serviceID, uint64 indexed tournamentID, string key, bytes configs, bytes restrictions, bytes warriors);

  // mapping(serviceID => mapping(tournamentID => TournamentInfo))
  mapping(uint64 => mapping(uint64 => TournamentTypes.TournamentInfo)) battles;

  // reviewed
  // verified
  function createTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    string memory _key,
    TournamentTypes.TournamentConfigs memory _data,
    TournamentTypes.TournamentRestrictions memory _restrictions
  ) external onlyRoler("createTournament") {
    TournamentTypes.TournamentInfo storage tournament = battles[_serviceID][_tournamentID];
    require(bytes(_key).length > 0, "Key required");
    require(!tournament.inited, "Already exists.");
    require(_data.fee_percentage <= 10000, "Exceed max");

    if (_restrictions.win_rate_base_divider == 0) {
      _restrictions.win_rate_base_divider = 1;
    }

    tournament.inited = true;
    tournament.configs = _data;
    tournament.restrictions = _restrictions;

    emit TournamentChanged(_serviceID, _tournamentID, _key, abi.encode(_data), abi.encode(_restrictions), abi.encode(tournament.warriors));
  }

  // reviewed
  // verified
  function updateTournamentConfigs(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentConfigs memory _data
  ) external onlyRoler("updateTournamentConfigs") {
    TournamentTypes.TournamentInfo memory tournament = battles[_serviceID][_tournamentID];
    require(tournament.inited, "Not exists"); // require exists
    require(_data.fee_percentage <= 10000, "Exceed max");
    require(tournament.configs.status == TournamentTypes.TournamentStatus.AVAILABLE, "Not available"); // require available

    battles[_serviceID][_tournamentID].configs = _data;

    emit TournamentChanged(_serviceID, _tournamentID, '', abi.encode(_data), abi.encode(tournament.restrictions), abi.encode(tournament.warriors));
  }

  // reviewed
  function updateTournamentRestrictions(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentRestrictions memory _data
  ) external onlyRoler("updateTournamentRestrictions") {
    TournamentTypes.TournamentInfo memory tournament = battles[_serviceID][_tournamentID];
    require(tournament.inited, "Not exists"); // require exists
    require(tournament.configs.status == TournamentTypes.TournamentStatus.AVAILABLE, "Not available"); // require available

    battles[_serviceID][_tournamentID].restrictions = _data;

    emit TournamentChanged(_serviceID, _tournamentID, '', abi.encode(tournament.configs), abi.encode(_data), abi.encode(tournament.warriors));
  }

  function updateTournamentTopUp(
    uint64 _serviceID,
    uint64 _tournamentID,
    uint256 _topUp
  ) external onlyRoler("updateTournamentTopUp") {
    TournamentTypes.TournamentInfo memory tournament = battles[_serviceID][_tournamentID];
    require(tournament.inited, "Not exists"); // require exists
    require(tournament.configs.status == TournamentTypes.TournamentStatus.AVAILABLE, "Not available"); // require available

    battles[_serviceID][_tournamentID].configs.top_up = _topUp;

    emit TournamentChanged(_serviceID, _tournamentID, '', abi.encode(battles[_serviceID][_tournamentID].configs), abi.encode(tournament.restrictions), abi.encode(tournament.warriors));
  }

  function joinTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.Warrior memory _warrior
  ) external onlyRoler("joinTournament") {
    TournamentTypes.TournamentInfo memory tournament = battles[_serviceID][_tournamentID];
    require(tournament.inited, "Not exists.");
    require(tournament.warriors.length < tournament.configs.size, "Tournament full");

    battles[_serviceID][_tournamentID].warriors.push(_warrior);
    // set to ready if done
    if (battles[_serviceID][_tournamentID].warriors.length >= tournament.configs.size) {
      battles[_serviceID][_tournamentID].configs.status = TournamentTypes.TournamentStatus.READY;
    }

    emit TournamentChanged(_serviceID, _tournamentID, '', abi.encode(battles[_serviceID][_tournamentID].configs), abi.encode(tournament.restrictions), abi.encode(battles[_serviceID][_tournamentID].warriors));
  }

  // reviewed
  // verified
  function completeTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors
  ) external onlyRoler("completeTournament") {
    TournamentTypes.TournamentInfo storage tournament = battles[_serviceID][_tournamentID];
    require(tournament.inited, "Not exists.");
    require(tournament.warriors.length == _warriors.length, "Input mismatch");
    require(tournament.configs.status == TournamentTypes.TournamentStatus.AVAILABLE || tournament.configs.status == TournamentTypes.TournamentStatus.READY, "Not allow");
    require(tournament.warriors.length == tournament.configs.size, "Not full");

    tournament.configs.status = TournamentTypes.TournamentStatus.COMPLETED;

    for (uint256 i = 0; i < _warriors.length; i++) {
      require(_warriors[i].win_position > 0, "Invalid position");
      tournament.warriors[i].ID = _warriors[i].ID;
      tournament.warriors[i].account = _warriors[i].account;
      tournament.warriors[i].win_position = _warriors[i].win_position;
      tournament.warriors[i].stance = _warriors[i].stance;
      tournament.warriors[i].data = _warriors[i].data;
    }

    emit TournamentChanged(_serviceID, _tournamentID, '', abi.encode(battles[_serviceID][_tournamentID].configs), abi.encode(tournament.restrictions), abi.encode(battles[_serviceID][_tournamentID].warriors));
  }

  // reviewed
  function cancelTournament(uint64 _serviceID, uint64 _tournamentID) external onlyRoler("cancelTournament") {
    TournamentTypes.TournamentInfo storage tournament = battles[_serviceID][_tournamentID];
    require(tournament.inited, "Not exists.");
    require(tournament.configs.status == TournamentTypes.TournamentStatus.AVAILABLE, "Not allow");
    require(tournament.warriors.length < tournament.configs.size, "Already full");

    tournament.configs.status = TournamentTypes.TournamentStatus.CANCELLED;
    emit TournamentChanged(_serviceID, _tournamentID, '', abi.encode(battles[_serviceID][_tournamentID].configs), abi.encode(tournament.restrictions), abi.encode(tournament.warriors));
  }

  // verified
  function getTournamentsByClassAndId(uint64 _serviceID, uint64 _tournamentID) public view returns (TournamentTypes.TournamentInfo memory) {
    return battles[_serviceID][_tournamentID];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Base } from "../../../common/Base.sol";
import { TournamentTypes } from "../types/Types.sol";
import { ITournamentRoute } from "../interfaces/ITournamentRoute.sol";
import { ITournamentService } from "../interfaces/ITournamentService.sol";

// Pellar + LightLink 2022

contract TRVTournamentRoute is Base, ITournamentRoute {
  mapping(uint64 => address) public services;

  // reviewed
  // verified
  function bindService(uint64 _ID, address _service) external onlyRoler("bindService") {
    require(_service != address(0), "Must set non-zero address");
    services[_ID] = _service;
  }

  // reviewed
  // verified
  function updateService(uint64 _ID, address _service) external onlyRoler("updateService") {
    require(services[_ID] != address(0), "Not exists");
    services[_ID] = _service;
  }

  // reviewed
  // join tournament
  // verified
  function joinTournament(
    uint64 _serviceID,
    bytes memory _signature,
    bytes memory _params
  ) external { // dont add roler here :D
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).joinTournament(_signature, _params);
  }

  // reviewed
  // create tournament
  // verified
  function createTournament(
    uint64 _serviceID,
    string[] memory _key,
    TournamentTypes.TournamentConfigs[] memory _configs,
    TournamentTypes.TournamentRestrictions[] memory _restrictions
  ) external onlyRoler("createTournament") {
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).createTournament(_key, _configs, _restrictions);
  }

  // reviewed
  // update tournament
  // verified
  function updateTournamentConfigs(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentConfigs memory _configs
  ) external onlyRoler("updateTournamentConfigs") {
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).updateTournamentConfigs(_tournamentID, _configs);
  }

  // reviewed
  // verified
  function updateTournamentRestrictions(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentRestrictions memory _restrictions
  ) external onlyRoler("updateTournamentRestrictions") {
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).updateTournamentRestrictions(_tournamentID, _restrictions);
  }

  function updateTournamentTopUp(uint64 _serviceID, TournamentTypes.TopupDto[] memory _tournaments) external onlyRoler("updateTournamentTopUp") {
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).updateTournamentTopUp(_tournaments);
  }

  // reviewed
  // cancel tournament
  // verified
  function cancelTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    bytes memory _params
  ) external onlyRoler("cancelTournament") {
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).cancelTournament(_tournamentID, _params);
  }

  function eligibleJoinTournament(uint64 _serviceID, uint64 _tournamentID, uint256 _championID) public view returns (bool, string memory) {
    return ITournamentService(services[_serviceID]).eligibleJoinTournament(_tournamentID, _championID);
  }

  // reviewed
  // verified
  function completeTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors,
    TournamentTypes.EloDto[] memory _championsElo,
    bytes memory _data
  ) external onlyRoler("completeTournament") {
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).completeTournament(_tournamentID, _warriors, _championsElo, _data);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import { TournamentTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ITournamentRoute {
  // bind service processing tournament
  function bindService(uint64 _ID, address _service) external;

  // join tournament
  function joinTournament(
    uint64 _serviceID,
    bytes memory _signature,
    bytes memory _params
  ) external;

  // create tournament
  function createTournament(
    uint64 _serviceID,
    string[] memory _key,
    TournamentTypes.TournamentConfigs[] memory configs,
    TournamentTypes.TournamentRestrictions[] memory _restrictions
  ) external;

  // update tournament
  function updateTournamentConfigs(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentConfigs memory configs
  ) external;

  function updateTournamentRestrictions(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentRestrictions memory _restrictions
  ) external;

  function updateTournamentTopUp(uint64 _serviceID, TournamentTypes.TopupDto[] memory _tournaments) external;

  // cancel tournament
  function cancelTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    bytes memory _params
  ) external;

  function eligibleJoinTournament(uint64 _serviceID, uint64 _tournamentID, uint256 _championID) external view returns (bool, string memory);

  function completeTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors,
    TournamentTypes.EloDto[] memory _championsElo,
    bytes memory
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Base } from "../../../common/Base.sol";
import { ITournamentRoute } from "../interfaces/ITournamentRoute.sol";

// Pellar + LightLink 2022

contract TRVTournamentRouteExtended is Base {
  uint256 public maxPerTxn = 4;
  address public tournamentRoute = 0xF681C909C16a0c5AA10308075144DC5666e936BE;

  function bindTournamentRouteAddress(address _tournamentRoute) external onlyRoler("bindTournamentRouteAddress") {
    tournamentRoute = _tournamentRoute;
  }

  function setupMaxPerTxn(uint256 _max) external onlyRoler("setupMaxPerTxn") {
    maxPerTxn = _max;
  }

  function joinTournaments(
    uint64[] memory _serviceIDs,
    bytes[] memory _signatures,
    bytes[] memory _params
  ) external {
    require(maxPerTxn >= _serviceIDs.length, "Exceed Max");
    require(_serviceIDs.length == _signatures.length, "Input mismatch");
    require(_serviceIDs.length == _params.length, "Input mismatch");

    uint256 size = _serviceIDs.length;
    for (uint256 i = 0; i < size; i++) {
      ITournamentRoute(tournamentRoute).joinTournament(_serviceIDs[i], _signatures[i], _params[i]);
    }
  }

  function eligibleJoinTournament(
    uint64[] memory _serviceIDs,
    uint64[] memory _tournamentIDs,
    uint256[] memory _championIDs
  ) public view returns (bool[] memory, string[] memory) {
    bool[] memory results = new bool[](_serviceIDs.length);
    string[] memory messages = new string[](_serviceIDs.length);

    uint256 size = _serviceIDs.length;
    for (uint256 i = 0; i < size; i++) {
      (bool eligible, string memory message) = ITournamentRoute(tournamentRoute).eligibleJoinTournament(_serviceIDs[i], _tournamentIDs[i], _championIDs[i]);
      results[i] = eligible;
      messages[i] = message;
    }

    return (results, messages);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Base } from "../../../common/Base.sol";
import { ChampionAttributeTypes, CommonTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

// champion attributes = CA
contract CAState is Base {
  mapping (uint256 => ChampionAttributeTypes.Attributes) champions;
  // string[1] private BACKGROUNDS = ['Black'];
  // string[1] private BLOODLINES = ['Genesis'];
  // string[3] private GENOTYPES = ['R1', 'R2', 'R3'];
  // string[5] private CHARACTER_CLASSES = ['Druid', 'Wizard', 'Barbarian', 'Ranger', 'Paladin'];
  // string[7] private BREEDS = ['Undead', 'Orc', 'Half Dwarf', 'Origin', 'High Born', 'Nordic', 'Elf'];
  // string[47] private ARMOUR_COLORS = [
  //   'Snowfall', 'Meadowlight', 'Rune', 'Emerald', 'Stategreen', 'Forestdeep', 'Frost', 'Coldshade', 'Rainstorm', 'Thundercloud',
  //   'Gloombane', 'Splendid', 'Memorial', 'Winterkill', 'Winterstorm', 'Spectral', 'Thunderstorm', 'Charcoal', 'Chaos', 'Onyx',
  //   'Royal Black', 'Dark of Night', 'Royal White', 'Charlemagne', 'Ivory', 'White Quartz', 'Dynasty', 'Mercia', 'Benedictine', 'Bone',
  //   'Alpensun', 'Coronet', 'Candlelight', 'Duskglow', 'Ochrewash', 'Firefly', 'Polarwind', 'Pennyroyal', 'Mayhem', 'Greatwood',
  //   'Blood', 'Brimstone', 'Crime-of-Passion', 'Red-of-War', 'Ruby Red', 'Sovereign', 'Gloom'
  // ];
  // string[7] private HAIR_COLORS = ['None', 'Tan', 'Blonde', 'Black', 'Gray', 'Brown', 'Auburn'];
  // string[5] private HAIR_CLASSES = ['Druid', 'Wizard', 'Barbarian', 'Ranger', 'Paladin'];
  // string[8] private HAIR_STYLES = ['Braid', 'Short', 'Wartail', 'Mohawk', 'Long', 'Bald', 'Hightail', 'Sidepart'];
  // string[9] private WARPAINT_COLORS = ['None', 'Black', 'White', 'Blue', 'Yellow', 'Green', 'Silver', 'Red', 'Gold'];
  // string[11] private WARPAINT_STYLES = ['None', 'Scar', 'Ragnarok', 'Trident', 'Rogue', 'Vortex', 'Sceptre', 'Hex', 'Mimic', 'Sigil', 'Crest'];

  // reviewed
  // verified
  function setGeneralAttributes(
    uint256[] memory _tokenIds,
    ChampionAttributeTypes.GeneralAttributes[] memory _attributes
  ) external onlyRoler("setGeneralAttributes") {
    require(_tokenIds.length == _attributes.length, "Input mismatch");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      champions[_tokenIds[i]].general = _attributes[i];
    }
  }

  // reviewed
  // verified
  function setOtherAttributes(
    uint256[] memory _tokenIds,
    CommonTypes.Object[] memory _attributes
  ) external onlyRoler("setOtherAttributes") {
    require(_tokenIds.length == _attributes.length, "Input mismatch");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      champions[_tokenIds[i]].others[_attributes[i].key] = _attributes[i].value;
    }
  }

  // reviewed
  // verified
  function getCharacterClassByChampionId(uint256 _tokenId) public view returns (uint16) {
    return champions[_tokenId].general.character_class;
  }

  // reviewed
  // verified
  function getGeneralAttributesByChampionId(
    uint256 _tokenId
  ) public view returns (ChampionAttributeTypes.GeneralAttributes memory) {
    return champions[_tokenId].general;
  }

  // reviewed
  // verified
  function getOtherAttributeByChampionId(
    uint256 _tokenId,
    bytes memory _key
  ) public view returns (bytes memory) {
    return champions[_tokenId].others[_key];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Base } from "./Base.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IChampionUtils } from "../interfaces/IChampionUtils.sol";

contract ChampionUtils is Base, IChampionUtils {
  mapping(uint16 => address) public tokens;
  address public stakingContract;
  uint256 public maxFightPerChampion = 1;

  constructor() {
    tokens[0] = 0x8Cb43fC8fd57D6263cC200B01D5F5d727e98ac79;
    tokens[1] = 0x649C8bC7f95f69b5005086c4EAB0e9E2C3d9c05c;
    tokens[2] = address(0); // unknown, future drop
    tokens[3] = 0xDe972Ab55B73279E627b82706977643e604dCA24;
  }

  // verified
  function setMaxFightPerChamp(uint256 _maxFightPerChamp) external onlyRoler("setMaxFightPerChamp") {
    maxFightPerChampion = _maxFightPerChamp;
  }

  // reviewed
  // verified
  function setTokenContract(uint16 _index, address _contract) external onlyRoler("setTokenContract") {
    tokens[_index] = _contract;
  }

  // reviewed
  // verified
  function setStakingContract(address _contract) external onlyRoler("setStakingContract") {
    stakingContract = _contract;
  }

  // reviewed
  // verified
  function getTokenContract(uint256 _championID) public view returns (address) {
    if (_championID < 5000) {
      return tokens[0];
    }
    if (_championID >= 5000 && _championID < 11000) {
      return tokens[1];
    }
    if (_championID >= 11000 && _championID < 28000) {
      return tokens[2];
    }
    return tokens[3];
  }

  // verified
  function isOwnerOf(address _account, uint256 _championID) public view returns (bool) {
    address owner = IERC721(getTokenContract(_championID)).ownerOf(_championID);
    return owner == _account || _account == IStaking(stakingContract).getStaker(_championID);
  }

  // reviewed
  // verified
  function isOriginalOwnerOf(address _account, uint256 _championID) public view returns (bool) {
    return IERC721(getTokenContract(_championID)).ownerOf(_championID) == _account;
  }
}

interface IStaking {
  function getStaker(uint256 _championID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Pellar + LightLink 2022

import { Base } from "./Base.sol";

library RoleMemberSet {
  struct Record {
    address[] values;
    mapping(address => uint256) indexes; // value to index
  }

  function add(Record storage _record, address _value) internal {
    if (contains(_record, _value)) return; // exist
    _record.values.push(_value);
    _record.indexes[_value] = _record.values.length;
  }

  function remove(Record storage _record, address _value) internal {
    uint256 valueIndex = _record.indexes[_value];
    if (valueIndex == 0) return; // removed non-exist value
    uint256 toDeleteIndex = valueIndex - 1; // dealing with out of bounds
    uint256 lastIndex = _record.values.length - 1;
    if (lastIndex != toDeleteIndex) {
      address lastvalue = _record.values[lastIndex];
      _record.values[toDeleteIndex] = lastvalue;
      _record.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
    }
    _record.values.pop();
    _record.indexes[_value] = 0; // set to 0
  }

  function contains(Record storage _record, address _value) internal view returns (bool) {
    return _record.indexes[_value] != 0;
  }

  function size(Record storage _record) internal view returns (uint256) {
    return _record.values.length;
  }

  function at(Record storage _record, uint256 _index) internal view returns (address) {
    return _record.values[_index];
  }
}

contract AccessControl is Base {
  using RoleMemberSet for RoleMemberSet.Record;

  // variables

  // contract => list addresses
  mapping(address => RoleMemberSet.Record) master;

  // role => list addresses
  mapping(bytes => RoleMemberSet.Record) roleMembers;

  constructor () {
    accessControlProvider = address(this);
  }

  /**
   * @dev Grant roles
   * {grantRoles}.
   *
   * allow an account can access method of a contract (that contract need call function from here to check)
   * _methodInfo ie: setData(uint256,uint256) (no space)
   */
  // verified
  function grantRoles(
    address _account,
    address _contract,
    string[] memory _methodsInfo
  ) external onlyRoler("grantRoles") {
    bytes memory role;
    for (uint256 i = 0; i < _methodsInfo.length; i++) {
      role = abi.encode(_contract, _methodsInfo[i]);
      roleMembers[role].add(_account);
    }
  }

  // verified
  function revokeRoles(
    address _account,
    address _contract,
    string[] memory _methodsInfo
  ) external onlyRoler("revokeRoles") {
    bytes memory role;
    for (uint256 i = 0; i < _methodsInfo.length; i++) {
      role = abi.encode(_contract, _methodsInfo[i]);
      roleMembers[role].remove(_account);
    }
  }

  // verified
  function grantMaster(
    address _account,
    address _contract
  ) external onlyRoler("grantMaster") {
    master[_contract].add(_account);
  }

  // verified
  function revokeMaster(
    address _account,
    address _contract
  ) external onlyRoler("revokeMaster") {
    master[_contract].remove(_account);
  }

  // View
  // verified
  function hasRole(
    address _account,
    address _contract,
    string memory _methodInfo
  ) public view returns (bool) {
    return master[_contract].contains(_account) || roleMembers[abi.encode(_contract, _methodInfo)].contains(_account);
  }

  // verified
  function getMembersByRole(address _contract, string memory _methodInfo) public view returns (address[] memory) {
    uint256 size = roleMembers[abi.encode(_contract, _methodInfo)].size();
    address[] memory records = new address[](size);

    for (uint256 i = 0; i < size; i++) {
      records[i] = roleMembers[abi.encode(_contract, _methodInfo)].at(i);
    }
    return records;
  }

  // verified
  function getMemberOfRoleByIndex(
    address _contract,
    string memory _methodInfo,
    uint256 _index
  ) public view returns (address) {
    return roleMembers[abi.encode(_contract, _methodInfo)].at(_index);
  }

  // verified
  function getMastersByRole(address _contract) public view returns (address[] memory) {
    uint256 size = master[_contract].size();
    address[] memory records = new address[](size);

    for (uint256 i = 0; i < size; i++) {
      records[i] = master[_contract].at(i);
    }
    return records;
  }

  // verified
  function getMasterOfRoleByIndex(
    address _contract,
    uint256 _index
  ) public view returns (address) {
    return master[_contract].at(_index);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockWeth is ERC20 {
  constructor () ERC20("", "") {}

  function mint(uint256 _amount) external {
    _mint(msg.sender, _amount);
  }
}