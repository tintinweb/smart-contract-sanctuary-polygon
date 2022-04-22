// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { utils } from "./utils.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @title buildspace name service
/// @author Sudham Jayanthi
/// @notice A simple implmentation of ens, but for buildspace. (unofficial)

contract bns is ERC721URIStorage {
    using utils for string;

    constructor() payable ERC721("Buildspace Name Service", "BNS") {}

    /// @notice A simple data structure to store domain data
    struct Record {
        address owner;
        string image;
    }

    /// @notice Thrown when someone else tries to perform owner-only tasks
    error Unauthorized();

    /// @notice Thrown when trying to buy a sold domain
    error AlreadySold();

    /// @notice Thrown when enough monies are not sent
    error MonieNotSufficient();

    /// @notice Tracks the current tokenID of the NFT
    uint256 private tokenID;

    /// @notice A list of bought domains to be able to render on frontend
    string[] public domains;

    /// @notice The record data mapped with domain name
    mapping(string => Record) public records;

    /// @notice Emitted when a new domain is bought
    /// @param owner address of the buyer
    /// @param domain name of the domain bought
    event NewRegistration(address owner, string domain);

    /// @dev Returns all the domains sold to render in the frontend
    function getDomains() public view returns (string[] memory) {
        return domains;
    }

    /// @notice Register a new domain
    /// @param domain Name of the domain
    /// @param imageHash IPFS hash of image to be set
    function register(string calldata domain, string calldata imageHash)
        public
        payable
    {
        if (records[domain].owner != address(0)) revert AlreadySold();
        if (msg.value < 0.69 ether) revert MonieNotSufficient();

        domains.push(domain);
        records[domain] = Record({owner: msg.sender, image: imageHash});

        unchecked {
            ++tokenID;
        }

        _safeMint(msg.sender, tokenID);
        _setTokenURI(tokenID, utils.genTokenURI(domain));

        emit NewRegistration(msg.sender, domain);
    }

    /// @notice Update image for a domain
    /// @param domain the domain for which image is to be updated
    /// @param imageHash IPFS hash of the new image
    function updateImage(string calldata domain, string calldata imageHash)
        public
    {
        if (records[domain].owner != msg.sender) revert Unauthorized();

        records[domain].image = imageHash;
    }

    /// @notice Changes domain ownership when the NFT is transferred
    /// @dev Uses the hook provided by open zeppelin
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        records[domains[tokenId - 1]].owner = to; // we're starting tokenID from 1 whereas list indices start from 0
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Base64.sol";

library utils {
    /// @dev Register Mint Image SVG Data
    string public constant svgStart =
        '<svg width="300" height="300" viewBox="0 0 300 300" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><rect width="300" height="300" rx="20" fill="#000"/><text x="40" y="235" fill="#fff" style="font:700 20px sans-serif">';
    string public constant svgEnd =
        '</text><text x="40" y="265" fill="#FF8FF0" style="font:600 18px sans-serif">.buildspace</text><path d="M35.867 76.8h40v-40h-40v40Z" fill="url(#a)"/><defs><pattern id="a" patternContentUnits="objectBoundingBox" width="1" height="1"><use xlink:href="#b" transform="scale(.01563)"/></pattern><image id="b" width="60" height="60" xlink:href="data:image/png;base64,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"/></defs></svg>';

    /// @notice Generates token URI on-chain using the svg data
    function genTokenURI(string calldata domain)
        public
        pure
        returns (string memory)
    {
        bytes memory finalSvg = abi.encodePacked(svgStart, domain, svgEnd);

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name" : "',
                domain,
                '.buildspace",',
                '"description" : "This NFT represents the ownership of a BNS domain.", "image" :  "data:image/svg+xml;base64,',
                Base64.encode(finalSvg),
                '"}'
            )
        );

        string memory _tokenURI = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return _tokenURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

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
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

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
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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