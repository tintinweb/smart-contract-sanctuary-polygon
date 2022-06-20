// SPDX-License-Identifier: MIT
import "./HomeMadeERC721.sol";

pragma solidity ^0.8.0;
contract mintHomeMadeERC721 is HomeMadeERC721{

    string public setBaseURI = "ipfs://bafkreih6n5re2qqqwzvdl5jrgzhfmq6lm3qb7ska2vdwmub5sbgehmgpvm/";

    constructor() HomeMadeERC721("Home Made ERC721", "HMERC721") {
        _setBaseURI(setBaseURI);
    }

    function mint(uint256 tokenID) external {
        _safeMint(_msgSender(), tokenID);
    }

    function burn(uint256 tokenID) external {
        _burn(tokenID);
    }
}

// SPDX-License-Identifier: MIT
import "./Context.sol";
import "./ERC165.sol";
import "./Library/Strings.sol";
import "./interface/IERC721Receiver.sol";
import "./homeMadeMapped.sol";
import "./error.sol";

pragma solidity ^0.8.0;
contract HomeMadeERC721 is Context, ERC165 {
    // using Address for address;
    using Strings for uint256;

    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address operator,uint256 tokenID,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0x757361ccdc389141dd4dbcf6d424c30e29013149edf6da6c4eeacf2457ec8540;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        ds.DOMAIN_SEPARATOR = keccak256(abi.encodePacked(
            keccak256("EIP712Domain(string name,string symbol,address verifyingContract)"),
            keccak256(bytes("Home Made ERC721")),
            keccak256(bytes("HMERC721")),
            address(this)
        ));
        ds._name = name_;
        ds._symbol = symbol_;
    }
/**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        if(owner == address(0)) revert zeroAddress();
        return ds._balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        address owner = ds._owners[tokenId];
        if(owner == address(0)) revert nonexistent();
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        return ds._name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        return ds._symbol;
    }

    function domain_seperator() public view returns (bytes32) {
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        return ds.DOMAIN_SEPARATOR;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URINonexistent();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = HomeMadeERC721.ownerOf(tokenId);
        if (to == owner) revert selfApproval();
        if (_msgSender() != owner || (isApprovedForAll(owner, to))) revert notAllow();
        _approve(to, tokenId);
    }

    // --- Approve by signature ---
    function permit(
        address owner, 
        address operator, 
        uint256 tokenId,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external {
        bytes32 digest =
        keccak256(abi.encodePacked(
            "\x19\x01",
            domain_seperator(),
            keccak256(abi.encode(
                PERMIT_TYPEHASH,
                owner,
                operator,
                tokenId))
        ));

        bytes32 salt = 
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)
        );

        if (HomeMadeERC721.ownerOf(tokenId) != owner) revert incorrectOwner();
        if (owner == operator) revert selfApproval();
        if (isApprovedForAll(owner, operator)) revert notAllow();
        if (owner == address(0)) revert nonexistent();
        if (owner != ecrecover(salt, v, r, s)) revert invalidPermit();
        _approve(operator, tokenId);
    }

    // --- Approve by signature ---
    function permitForAll(
        address owner, 
        address operator, 
        bool allowed, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external {
        bytes32 digest =
        keccak256(abi.encodePacked(
            "\x19\x01",
            domain_seperator(),
            keccak256(abi.encode(
                PERMIT_TYPEHASH,
                owner,
                operator,
                allowed))
        ));

        bytes32 salt = 
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)
        );

        if (owner == address(0)) revert nonexistent();
        if (owner == operator) revert selfApproval();
        if (owner != ecrecover(salt, v, r, s)) revert invalidPermit();
        _setApprovalForAll(owner, operator, allowed);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        if (!(_exists(tokenId))) revert nonexistentToken();
        return ds._tokenApprovals[tokenId];
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
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        return ds._operatorApprovals[owner][operator];
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
    function safeTransfer(
        address _to,
        uint256 tokenId
    ) external {
        _transfer(_msgSender(), _to, tokenId);
        if(!(_checkOnERC721Received(_msgSender(), _to, tokenId, ""))) revert NonReceiver_Implementer();
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

        if (!(_isApprovedOrOwner(_msgSender(), tokenId))) revert notApproved();
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
        if (!(_isApprovedOrOwner(to, tokenId))) revert notApproved();
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
     function _baseURI() internal view returns (string memory) {
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        return ds._baseURI;
    }


    /**
     * @dev set Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
     function _setBaseURI(string memory _uri) internal {
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        ds._baseURI = _uri;
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
        if(!(_checkOnERC721Received(from, to, tokenId, _data))) revert NonReceiver_Implementer();
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
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        return ds._owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        if (!(_exists(tokenId))) revert nonexistentToken();
        address owner = HomeMadeERC721.ownerOf(tokenId);
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        if(!(_checkOnERC721Received(address(0), to, tokenId, _data))) revert NonReceiver_Implementer();
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
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        if (to == address(0)) revert zeroAddress();
        if ((_exists(tokenId))) revert alreadyMinted();

        _beforeTokenTransfer(address(0), to, tokenId);

        ds._balances[to] += 1;
        ds._owners[tokenId] = to;

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
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        address owner = HomeMadeERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        ds._balances[owner] -= 1;
        delete ds._owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        if (HomeMadeERC721.ownerOf(tokenId) != from) revert incorrectOwner();
        if (to == address(0)) revert zeroAddress();

        _beforeTokenTransfer(from, to, tokenId);
        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        ds._balances[from] -= 1;
        ds._balances[to] += 1;
        ds._owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        ds._tokenApprovals[tokenId] = to;
        emit Approval(HomeMadeERC721.ownerOf(tokenId), to, tokenId);
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
        homeMadeMapped.libStorage storage ds = homeMadeMapped.diamondStorage();
        if (owner == operator) revert selfApproval();

        ds._operatorApprovals[owner][operator] = approved;
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
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert NonReceiver_Implementer(); //("ERC721: transfer to non ERC721Receiver implementer");
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

pragma solidity ^0.8.0;
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
import "./interface/IHomeMadeERC721.sol";
abstract contract ERC165 is IHomeMadeERC721 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/**
 * @dev silently declare mapping for the products on Rigel's Protocol Decentralized P2P network
 */
library homeMadeMapped {
    struct libStorage {
        // Token name
    string _name;

    // Token symbol
    string _symbol;

    // base URI;
    string _baseURI;

    // --- EIP712 niceties ---
    bytes32 DOMAIN_SEPARATOR;

    // Mapping from token ID to owner address
    mapping(uint256 => address) _owners;

    // Mapping owner address to token count
    mapping(address => uint256) _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;
    }

    function diamondStorage() internal pure returns(libStorage storage ds) {
        bytes32 storagePosition = keccak256("HOME MADE ERC721");
        assembly {ds.slot := storagePosition}
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// HomeMadeERC721: balance query for the zero address
error zeroAddress();
// HomeMadeERC721: token already minted
error alreadyMinted();
// HomeMadeERC721: owner query for nonexistent token
error nonexistent();
// HomeMadeERC721: URI query for nonexistent token
error URINonexistent();
// HomeMadeERC721: approval to current owner
error selfApproval();
// HomeMadeERC721: approve caller is not owner nor approved for all
error notAllow();
// HomeMadeERC721: approved query for nonexistent token
error nonexistentToken();
// HomeMadeERC721: transfer caller is not owner nor approved
error notApproved();
// HomeMadeERC721: transfer to non ERC721Receiver implementer
error NonReceiver_Implementer();
// HomeMadeERC721: transfer from incorrect owner
error incorrectOwner();
// HomeMadeERC721: Invalid Permit
error invalidPermit();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC165.sol";
interface IHomeMadeERC721 is IERC165 {
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function safeTransfer(
        address _to,
        uint256 tokenId
    ) external;

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
     * @dev Approve or remove `operator` as an operator for the caller with signature.
     * Operators can call {transferFrom} or {safeTransferFrom} for any `tokenId` owned by the owner.
     *
     * Requirements:
     *
     * - The `owner` cannot be the zero address.
     * - The `owner` cannot be the `operator`.
     * - The `owner` must be the signer of `v`, `r`, `s` when split.
     * - The `owner` must own the token.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function permit(
        address owner, 
        address operator, 
        uint256 tokenId,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller with signature.
     * Operators can call {transferFrom} or {safeTransferFrom} for token owned by the owner when `allowed` for the signature is set to true.
     *
     * Requirements:
     *
     * - The `owner` cannot be the zero address.
     * - The `owner` cannot be the `operator`.
     * - The `owner` must be the signer of `v`, `r`, `s` when split.
     *
     * Emits an {ApprovalForAll} event.
     */
    function permitForAll(
        address owner, 
        address operator, 
        bool allowed, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external;

    /**
     * --- EIP712 niceties ---
     */
    function domain_seperator() external view returns (bytes32);

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

pragma solidity ^0.8.0;
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