//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import ".././BKEInterface.sol";

contract WildcardLogos is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    BKEInterface private _BKI;
    uint32 public editionLimit;
    string public version = "0.0.1";
    string public projectName  = "Wildcard Logos";
    string public BKContractName = "WildcardLogos V0.0.1";
    string public BKEVersion = "BKEmbedded.0.1.17";
    string public mediaType = "static image";
    uint public windowEndSeconds = 1667260799;
    string public windowEndDate = "11:59PM October 31 2022 (UTC)";
    uint32 public royaltyBasisPts = 1000;
    
    
    constructor(uint32 editionLimit_) ERC721("WildcardLogos", "WCL") {
        _tokenIdCounter.increment(); //force start with token1?
        editionLimit = editionLimit_;
    }

    function safeMint(address to) public onlyOwner returns(uint tokenId) {
        require(address(_BKI) != address(0), "{VNB654}");  //BKI not assigned.
        require(_tokenIdCounter.current() <= editionLimit, "{VNB655}"); //edition limit reached.
        require(windowEndSeconds>block.timestamp, "{VNB656}"); //publish after window end probhibited
        require(_BKI.isSigned(_tokenIdCounter.current(), msg.sender, to) > 0, "{VHVHED}");  //contract is not yet signed.
         tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        return tokenId;
    }

    function assignBKI(BKEInterface BKI_) public {
        require(address(_BKI) == address(0), "{YDTSS7}");  //BKI is write-once
        _BKI = BKI_;
        
    } 

    function getPageCount() public view returns(uint32) {
        return _BKI.getPageCount();
    }
    
    function getAgreementDraft(uint16 page) public view returns(string memory) {

        require (address(_BKI) != address(0), "{ACIDI9}");  //BKI not assigned.
        return _BKI.getDocTemplatePage(page);
    }

    function getAgreementPageSigned(uint16 sigId, uint16 page) public view returns(string memory, bool interrupted) {
        require (address(_BKI) != address(0), "{MGNF99}");  //BKI not assigned.
        return _BKI.getSignedDocPage(sigId, page);
    }
    function resumePageRender(string memory partialPage, uint16 sigId) public view returns(string memory, bool interrupted) {
        require (address(_BKI) != address(0), "{M9F8D7}");  //BKI not assigned.
        return _BKI.resumePageRender(partialPage, sigId);
    }



    function getBKI() public view returns(BKEInterface) {
        return _BKI;
    }  
    function tokenURI(uint256 tokenId) 
        public 
        pure
        override(ERC721, ERC721URIStorage) 
        returns (string memory) {
     //   super._requireMinted(tokenId); return the uri info whether or not token is minted for docuemnt prep
     //   purposes.
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }
     
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        address maker = from;
        if(maker==address(0)) {
            maker = owner();
            require(msg.sender==owner(), "{VNB657}"); //only owner as initial maker
        } else {
            require(_BKI.isSigned(tokenId,maker, to ) > 0, "{HYT772}"); //agreement is not signed.
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getSigIDsForTokenId(uint256 tokenId) public view returns(uint32[] memory sigIds) {
        return _BKI.getSigIdsForTokenId(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    
    function baseURI() public pure returns(string memory) {
        return _baseURI();
    }
    
    string private constant uri = "https://us-central1-bkopy-63ecf.cloudfunctions.net/getWildcardMeta?id=";
    // string private constant uri = "https://us-central";
    function _baseURI() internal pure override returns (string memory) {
        return uri;
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;
import "./BKEmbedded.sol";

/**
 * @dev BKEInerface serves as an intermediary between a "data source" smart contract, and BKEmbedded.
 * It is used primarily so that the smart contract get retrieve fully rendered agreements directly by from the 
 * smart contract by calling by the methods melow.  
 * 
 * The source contract (which may be a datasource for some of the values required by a contract template)
 * can either inherit BKEinterface, or just create and store a reference to it.
 */

contract BKEInterface {

    BKEmbedded private BKE;
    bool private inherited = false;
    address private creator;
    address private source;  //the contract which this is the intermediary for.
    /**
     * @dev Constructor for the BKE source.
     * @param _BKE The BKE contract to use.
     */
    constructor(BKEmbedded _BKE)   {
        creator = msg.sender;
        BKE = _BKE;
    }
    
    
    modifier onlySource() {
        require(msg.sender == source, " {SJDEU7}"); //Can only be called by the source contract.
        _;
    }
    /**
     * @dev Creates a DocumentRecord on BKEmbedded and returns the docId;
     * @param valuesJSON The values for the tagRefs in the document.
     * address of the caller (which could be the Source contract).  If an address is provided, the creator
     * set on the document is is msg.sender, and the maker on the document is the makerAddress param.
     * Both maker and creator must have been authorized or the function will revert.
     */
    // function createDocument(string memory valuesJSON) public onlySource returns(uint32 docId) {
    //     require(BKE.authorizedCreators(msg.sender),"{zxczxc}");  //source contract not authorized creator.
    //     docId = BKE.createDocument(valuesJSON);
    //     return docId;
    // }

    // function signByMaker(uint32 docId, address makerAddress, address takerAddress, bytes memory makerSignature) 
    //   onlySource public returns(uint32 sigId) {
    //     require(BKE.authorizedCreators(msg.sender), "{hhh}");  //contracts call to signByMaker must be in the authorized creator list.
    //     require(BKE.isAuthorizedMaker(makerAddress),"{ggg}");  //maker address not authorized.
    //     SigningParams memory p;
    //     p.docId = docId;
    //     p.takerAddress = takerAddress;
    //     p.makerAddress = makerAddress;
    //     p.makerSignature = makerSignature;
    //     p.tokenId = BKE.getDocRecord(docId).tokenId;
    //     p.jsonAttribsSigned = BKE.getDocRecord(docId).jsonAttribs;
    //     return BKE.createSigningRecord(p);
    //  }


    /**
     * @dev In order for a taker to sign a document, they need to sign the hashProof for the document
     * in question.  This function returns hashProof for a signing record for and validates that taker
     * who's signature is expected.
     */
    function getHashProof(uint32 sigId, address takerAddress) public view returns (bytes32){
        SigningRecord memory s = BKE.getSigningRecord(sigId);
        require(s.taker == takerAddress,"{AKVB99}");  //taker doesn't match
        return s.hashProof;
    }

    /**
     * @dev returns the address of the BKEmbedded contract for the source contract.
     */
    function getEmbeddedAddress() public view returns (address) {
        return address(BKE);
    }
    function getSource() public view returns (address) {
        return source;
    }


    // function signByTaker(uint32 sigId, bytes memory takerSignature) public onlySource   {
    //     SigningRecord memory sig = BKE.getSigningRecord(sigId);
    //     BKE.takerSignDocument(sig.hashProof, takerSignature);
    // }

    function isSigned(uint256 tokenId, address makerAddress, address takerAddress) public view returns (uint32) {
         return BKE.isSigned(tokenId, makerAddress, takerAddress);
    }

    /**
     * @dev Render the full template for a given doc Id.
     *
     */
    function getDocTemplatePage(uint16 page) public view returns (string memory){

        require(BKE.isPublished(),"{XJU7D7}");  //contracts call to getDocTemplate must be in the authorized creator list.
        return BKE.getTemplatePage(page);
    }

    /**
     * @dev Gets the values to replace attribute TagRefs in the template.
     */
    function getTagValues(uint32 sigId) public view returns(TagRefMapData memory) {
        return BKE.getTagRefMapData(sigId);
    }

    /**
     * @dev Merges the template with the template to yield the signed document.
     */
    function getSignedDocPage(uint32 sigId, uint16 page) public view returns (string memory, bool aborted) {
        return BKE.getMergePage(sigId,page );
    }

    function resumePageRender(string memory partialPage, uint32 sigId) public view returns(string memory, bool aborted) {
        return BKE.finishMergePage(sigId, partialPage);
    }

    function getSigIdsForTokenId(uint256 tokenId) public view returns (uint32[] memory) {
       FetchQuery memory qry;
       qry.qryType =QueryType.TokenId;
       qry.id = tokenId;
       return BKE.querySigIdList(qry);
    }

    function getPageCount() public view returns (uint16) {
        return BKE.pageCount();
    }
    
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;


import "./BKBindingCollection.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BKSigningHelper.sol";
import "./BKBinding.sol";
import "./BKRenderer.sol";
import "hardhat/console.sol";

uint256 constant SIG_LENGTH = 65;

/** 
 /**
     * @dev The BKEmbedded smart contract is contract is designed to store legal agreements inside a smart contract, and to record the signature of those legal agreement by counterparties, and to be able  to provide accurate copies of the signed agreement to callers.  (For the sake of clarity, the word  "agreement" herein is intended to refer to written contract document, while the word "contracct"  is used to refer to smart contract code that performs the functions described below.)
     
     BKopy does not save the full text of the agreements, rather it tracks a reference to a document template, called a "Binding" whichis represented by its own smart contract  (see BKBinding.sol),  as well as a set of values to be inserted into that template, along with digital signatures and  cryptographic hashes that can beused to prove that the document returned by BKopyEmbedded is, in fact, the document  which was digitally signed by the counterparties to the agreement.
     
      This version of BKopyEmbedded anticpates 'bilateral' agreement between a one "maker" (in legal terms the party making an "offer",) and a counterparty, the "taker". who is the party accepting the offer.  This current version does not enable direct assignment of agreements in a chain, i.e. where "taker" under one agreement becomes "maker"  in the next as a means of assigning the benefits from to a succession of owners.   Rather, it is anticpated,  for example, the if the ownership of a token changes from one party to the next, the agreement with the first  owner is terminated, and remade between the original maker and the next taker.  Subsequent versions may permit such assignment. 
     
     The agreement to be signed is created by merging a template (one template per BKEmbedded contract) with a set of  values constituting the particulars of the agreement.  The template itself is created from a series of Bindings  which contains contain straight text, basic html and certain bracketed expressions ("template tags") which  have special meaning to a BKRendering engine (which can be invoked either from a smart contract, or via a Typescript API off of the blockchain.  The BKRendering engine is designed to be non-state changing so there is no gas to render the template once the template and supporting data are stored.) 
     
     There are two primary types of tags that can be including in templates -- the first is a "binding tag" which causes the render  engine to imiport the text of another binding tag into the current binding's text, (e.g. !{my_simple_binding.1.0.0} and the second is a "tagRef" which is a named request associated with some value stored, either in a smart contract or in an external metadata store, the URL of which is accessible in the source smart contract, or as part of the transaction data provided when the document is prepared by "createDocument".
     
     The rendering process (converting a template and tagREf values into a signable agreement) consists of first  loading a root template, and then recursively loading all the templates it, and all its children, may specify  in embedded binding tags.  The resulting document template then contains no binding tags, but it still contains  tagRefs which specify string values that must be acquired by the render engine in order to fully render hte  agreement.  The render engine produces a dictionary, consisting of a tagRef name and its corresponding value,  and then proceeds to query BKEmbedded to obtain the value to use for the tagREf.  BKEmbedded relies on its associated BKBindingCollection to both locate the text of embedded bindings, and to determine how a particular tagRef should acquire the value to be replaced.  
     
     The BKBindingCollection associated with a given BKEmbedded contract contains the addresses of the all the named bindings that are required.  It also contains list of "attributes" (and their associated tagRefs) that can be  and replaced, when encountered in template text. The BindingCollection defines the mechanism by which the value should be retreived.  (Mechanisms include simple named function calls, function calls containing an index parameter like a  tokenId, or functions which return the url where a JSON document maybe obtained, and the relevant key which should be used as the value of the TagRef.)  When a contract is signed, the values retrieved for each tagRef and permanently recorded with the signed agreeement.  (So any change in the values that might otherwise be returned by BKEmbedded will not impact the content of any already-signed document.  The BKEmbedded contract is capable of executing the  necessary functions to retrieve the values that should be inserted in the TagRef map by making staticcalls to the  contract at the "sourceContract" address, based on the metadata stored in the binding collection (function names,  return value type etc.)
     
     The process of creating Agreements:
     
      In order to create a document which counterparties can sign, one of the parties, the "creator", creates a document  record that is saved in BKEmbedded, which represents the content of the contract.  The document record contains the  name of the root binding, as well as a map of all tagRefs and their corresponding values.   It also records who the " maker" of the document should be.  At this point it is not signed, and the identity of the Taker is not yet known,  so this data is save in the DocumentRecord struct  The DocumentRecord struct is saved in a map, indexed by a  consecutive docId, which can be used to access the document for later signature or retrieval. 
     
      To start the signature process, the maker provides their digital signature to BKEmbedded, which stores the  in a new document called a SigningRecord.  The contract creator specifies at publish time whether or not maker must digitally sign SigningRecords.  While the provision of a digital signature provides better evidentiary support for  the fact that the offer was in fact made (and is therefore legally binding on) the maker, but since only the maker  could authorize the the creation of a signing document in the first place, the choice can be left to the end user  without threatening thelegal status of the agreement.  The signing record includes signatures by the contracting  parties of the the template hash, and all of the values to be repaced in the template with the exception of the  signatures themselves.
     
      As a general proposition however, the taker will need to provide a digital signature, as it si the only way to prove on the blockchain that the taker did in fact accept the obligations associated with the agreement.    (Considering adding a "no taker signature' version where the agreement imposes no obligations on the taker.)  The maker then calls the function "signDocument" on BKEmbedded, which returns a docId.  The docId is used to access the document record, and the maker can then sign the document. 
     
     Note that both documents and signing records apply to specific "tokenId".  If the contract does not create tokens, the tokenId can be used to distinguish other features of the contract which would result in the need for a separate agreement.

    */

contract BKEmbedded is Ownable {
  
    string public constant BKContractName = "BKEmbedded.0.1.17";

    bool public isPublished; //in order to create or sign documents, contract must be published by owner.
    address public dataSource; //dataSource is the contract from which attribute values are retrieved.  (If BKopyEmbedded is used as an
    //inherited, parent, dataSoruce==address(this).  Otherwise it is the conract to call
    //to fetch tagRef values via contract functions.
    address private bkEmbedRootAddress; //address of BKEmbedRoot.
   // address private rendererAddress; //address of BKREnderer library.

    //SignApprovalMethod public approvalMethod = SignApprovalMethod.ACLList; //Determines the mechanism by which an individual Taker is approved to sign by the maker.
    //string public delegateSignApprovalFunctionName; //If the approval method is "delegate", the creator may delegate approval to a function on the interiting contract.

    bool public requireMakerSignature = false; //Specifies whether or not the maker must sign the fullRender hash of the document.
    string public BKTemplate; //the name of the root BKBindingTemplate.  This is write once, set by setRootTemplate, and must be set before
    //publication.  It's existence and validity is confirmed with BKBindingCollection before it can be set.
    bytes32 public templateDocumentHash; //hash of the BKTemplate before tagrefs are interpolated.

    address public bindingCollAddress; //address of the BKBindingCollection that contains the BKTemplate.

    uint32 public docCount; //number of recorded document records starting with 1 (consecutive)
    uint32 public sigCount; //number of recorded signature records, starting with 1. (consecutive), so count is sigIndex

    mapping(uint32 => SigningRecord) public signingRecords; //mapping of sigIndex to sigParams in SigningRecord
    mapping(uint32 => DocumentRecord) private documentRecords; //mapping of docId to docParams in DocumentRecord
    mapping(address => bool) public authorizedCreators; //addresses which are authorized to call create document by the contract owner.  Includes contract owner by default.
    mapping(address => bytes) private makerSignatures; //maker Address=> signature of templateDocumentHash by the doc creator.

    mapping(uint256 => uint32[]) public tokenIdToDocId; //docId=>sigId
    uint32[] completedDocumentIds;
    mapping(address => uint32[]) public sigIndexByMaker; //Mapping to list of transIds for a given sender.
    mapping(address => uint32[]) public sigIndexByTaker; //Mapping to list of transId for a given taker (taker could sign more one doc possibly)
    mapping(uint256 => uint32[]) public sigIndexByTokenId; //Mapping to list of transId for a given tokenId;  Note 0 is not a valid tokenID!
    mapping(bytes32 => uint32) public sigIndexByHashProof; //Mapping of hashproof to sigId.  Hashproof is hash(templateDocumentHash and jsonAttribsSigned)
    // mapping(address => address) private takerMap; //authorized taker => maker who authorized the taker.
    mapping(uint32 => uint32[]) private docTransactionMap; //map of docId => sigIds in the signingParamsMap.
    string[] private pageStore;

    event CreateDocumentEvent(uint32 indexed docId, uint256 indexed tokenId);

    event SignedEvent(
        uint32 indexed sigId,
        address indexed maker,
        address indexed taker,
        uint256 tokenId,
        uint32 docId
    );

    event PendingSignedEvent(
        uint32 indexed sigId,
        address indexed maker,
        address indexed taker,
        uint256 tokenId,
        uint32 docId
    );
    event RejectedEvent(
        uint32 indexed sigId,
        address indexed maker,
        address indexed taker,
        uint256 tokenId,
        uint32 docId
    );

    /**
     * @dev The data source from which this BKEmbedded will read to acquire tagRef values is the 'datasource'.  If the
     * the daa source is not supplied (blank or address(0)), then it is assumed that the datasource is BKEmbedded itself,
     * or more likely, a contract which inherits from BKEmbedded.
     * @param dataSource_  The address of the contract from which tagRef values should be retrieved.
     *        if this contract is the parent of a contract which embeds it, datasource should either be address0, or address(this);
     */
    constructor(address bindingColAddress_, address dataSource_) {
        docCount = 0; //new doc ids start with 1
        sigCount = 0;
        if (dataSource_ == address(0)) {
            dataSource = address(this);
        } else {
            dataSource = dataSource_;
        }
        bindingCollAddress = bindingColAddress_;
        bkEmbedRootAddress = BKBindingCollection(bindingCollAddress).embedRoot();
        isPublished = false;
        authorizedCreators[msg.sender] = true; //owner is authorized as creator by default.
       // rendererAddress = BKEmbedRoot(bkEmbedRootAddress).rendererAddress();
    }

    modifier onlyAuthorizedCreator() {
        require(
            msg.sender == owner() || authorizedCreators[msg.sender],
            "only owner or authorized {AJVI0S}"
        );
        _;
    }

    /**
    enum QueryType {
    TokenId,
    DocId,
    Maker,
    Taker,
}
struct FetchQuery {
    QueryType qryType;
    address target;
    uint id;  //either a TokenId or DocId   /
    uint start; //an index to start returning values.  0 is the first.
    uint count; //if length 0 return all, else return count
}
*/
    /**
     * Returns a list list of sigIds based on the given query.  Because sigIds are
     * consecutive ordered integers, no "all" fetch type is required. just read total
     * sigCount and select a range from [1..count].
     * if @param qry.count is 0, count is ignored, and the function returns all qualifying sigIds.
     */
    function querySigIdList(FetchQuery memory qry)
        public
        view
        returns (uint32[] memory)
    {
        uint32[] memory retval;
        uint32[] memory source;
        if (qry.qryType == QueryType.TokenId)
            source = sigIndexByTokenId[qry.id];
        if (qry.qryType == QueryType.DocId)
            source = docTransactionMap[uint32(qry.id)];
        if (qry.qryType == QueryType.Maker)
            source = sigIndexByMaker[qry.target];
        if (qry.qryType == QueryType.Taker)
            source = sigIndexByTaker[qry.target];
        uint256 sourceLength = source.length;
        if (sourceLength == 0) return retval;
        if (qry.start >= sourceLength) return retval;
        if (qry.count == 0) qry.count = sourceLength;
        uint256 endIndex = qry.start + qry.count - 1;
        if (endIndex >= sourceLength) endIndex = sourceLength - 1;
        retval = new uint32[](endIndex - qry.start + 1);
        uint256 n = 0;
        for (uint256 i = qry.start; i <= endIndex; i++) {
            retval[n] = source[i];
            n++;
        }
        return retval;
    }

     

    //permits the account to create documents.
    function addCreator(address creator) public onlyOwner {
        authorizedCreators[creator] = true;
    }

    /**
     *@dev returns all docIds for a given maker, (whether or not comoplete)
     */
    function docIdListByMaker(address maker)
        public
        view
        returns (uint32[] memory)
    {
        return sigIndexByMaker[maker];
    }

    /**
     *@dev returns all docIds for a given maker, (whether or not comoplete)
     */
    function docIdListByTaker(address taker)
        public
        view
        returns (uint32[] memory)
    {
        return sigIndexByTaker[taker];
    }

    //convenience function //for V1, taker signatures are always required.
    function takerSigRequired() internal pure returns (bool) {
        return true;
    }

    function removeMaker(address removed) public onlyAuthorizedCreator {
        require(removed != owner(), "contract owner can't be removed");
        makerSignatures[removed] = "";
    }

    function docSigState(uint32 sigId) public view returns (SigState) {
        SigningRecord memory doc = signingRecords[sigId];
        if (
            doc.makerSigState == SigState.Rejected ||
            doc.takerSigState == SigState.Rejected
        ) return SigState.Rejected;
        if (
            doc.takerSigState == SigState.Complete &&
            doc.takerSigState == SigState.Complete
        ) return SigState.Complete;
        return SigState.Pending;
    }

    /**
     * @dev sets the root template for agreements to be produced by this smart contract.  It is write once,
     * and must be set before publishing.
     */
    function setRootTemplate(string memory fqBindingName)
        public
        onlyAuthorizedCreator
    {
        require(!isPublished);
        require(
            bytes(BKTemplate).length == 0,
            "BKTemplate is write once. {KCI3CD}"
        );

        BKBindingCollection coll = BKBindingCollection(bindingCollAddress);
        require(
            coll.isPublished(fqBindingName),
            "BKTemplate isnt published {JN3IDE"
        );
        require(coll.isTemplate(fqBindingName), "not a root template {NNCB3A}");
        BKTemplate = fqBindingName;
        templateDocumentHash = BKBinding(coll.getAddress(fqBindingName))
            .templateHash();
    }

    function getAttribMeta(string memory attribName)
        private
        view
        returns (BKAttrib memory)
    {
        return
            BKBindingCollection(bindingCollAddress).getAttribMeta(attribName);
    }

    function signingHelper() internal view returns (BKSigningHelper) {
        address sigHelperAddress = BKBindingCollection(bindingCollAddress)
            .sigHelperAddress();
        return BKSigningHelper(sigHelperAddress);
    }

    /* VALUE ACCESSOR FUNCTIONS
     *  These functions are used by attributes to access values stored on the parent contracts.
     *  getSimpleFunctionResult retrieves the value returned by a parameterless function.
     *  getTokenIndexedFunctionResult retrieves the value of a function that takes a tokenId (or Uint) as a parameter.
     *  getAddressIndexedFunctionResult retrieves the value of a function that takes an address as a parameter.
     *  These are used internally by the renderer to fetch values of contract attributes for insertion into a document.
     *  In each case, the caller specifies the return type of of the function to be called, and coerces the result to string.
     *  Only view function may be called via these methods.
     */
    function getSimpleFunctionResult(
        string memory functionName,
        SolidityABITypes resultType
    ) public view virtual returns (string memory result) {
        result = signingHelper().getSimpleFunctionResult(
            functionName,
            resultType,
            dataSource
        );

        // bytes memory result;
        // bool success;
        // (success, result) = address(this).staticcall(abi.encodeWithSignature(functionName.concat("()")));
        // require(success, functionName.concat("couldn't be fetched"));
        // return BKLibrary.parseResult(resultType, result);
    }

    function getTokenIndexedFunctionResult(
        string memory functionName,
        uint256 tokenIndex,
        SolidityABITypes resultType
    ) public view virtual returns (string memory) {
        return
            signingHelper().getTokenIndexedFunctionResult(
                functionName,
                tokenIndex,
                resultType,
                dataSource
            );
    }

    //Two address functions not yet implemented.
    /*Calls a contract function which takes msg.sender as an address parameter */
    function getSenderIndexedFunction(
        string memory functionName,
        SolidityABITypes resultType
    ) public view virtual returns (string memory) {
        return
            getAddressPairIndexedFunctionResult(
                functionName,
                msg.sender,
                address(0),
                resultType
            );
    }

    /*Calls a contract function which takes a single address as an address parameter */
    function getAddressIndexedFunctionResult(
        string memory functionName,
        address address1,
        SolidityABITypes resultType
    ) public view virtual returns (string memory) {
        return
            getAddressPairIndexedFunctionResult(
                functionName,
                address1,
                address(0),
                resultType
            );
    }

    // /*Calls a conttract function with takes one or two addresses as parameters.  For 1 address, set address2 to address(0) */
    function getAddressPairIndexedFunctionResult(
        string memory functionName,
        address address1,
        address address2,
        SolidityABITypes resultType
    ) public view virtual returns (string memory) {
        return
            signingHelper().getAddressPairIndexedFunctionResult(
                functionName,
                address1,
                address2,
                resultType,
                dataSource
            );
    }

    // /**Overrideable so child contracts modify behavior  */
    // function createDocument(string memory jsonString,  address makerAddress)
    //     public
    //     virtual
    // {
    //     _createDocument(jsonString, makerAddress);
    // }
    /**
     *  @param jsonString is the stringied version of a javascript Map<string, string> which which provides the data needed to create a document record in JSON String form.  
     *  
     *  
     *  JSON keys  must include:
     *  tokenId: the tokenId of the document.  There can be only one document per tokenId.  Token 0 has a special meaning -- its the default
     *  documentId for cases in which all rendered agreements are the same and do not vary based on tokenid or any other exgternal value.
     *  attribsMap:  a stringified Map<tagRef, stringValue> of the key/value pairs of tagrefs and values.
     *  bindingCollection: a BKBindingCollection address, which must match the address of this BKEmbedded binding collection.
     *  sourceContract: Either a) a contract address from which tagRef values can be obtained, or address(0), if this contract is 
                        itself the source of tagRef values. 
     *  template :  must match the name of the root template (stored as BKTemplate)

     *  The JSON keys should include either maker or taker, or maker or taker signatures.
     */
    function createDocument(string memory jsonString)
        public
        returns (uint32 docId) 
        {
        checkCreateDocument(jsonString); //this will revert if there's a problem that would cause reversion.
        DocumentRecord storage doc = documentRecords[docCount + 1];
        string memory tokenId_s = signingHelper().jsonValueByKey(jsonString, "token_id");
        uint256 tokenId_ = signingHelper().string2Uint(tokenId_s);
        //If token_id is zerolength,  set to tokenId to 0
        docCount = docCount + 1;
        doc.docId = docCount;
        doc.tokenId = tokenId_;
        doc.jsonAttribs = jsonString;
        doc.creator = msg.sender;
        doc.timestamp = block.timestamp;
        tokenIdToDocId[tokenId_].push(doc.docId);
        emit CreateDocumentEvent(doc.docId, doc.tokenId);

        return doc.docId;
    }

    /**This function can be called as a view function to see if a createdocument call will succeed, so as to avoid gas 
        fees from failed transactions */
    function checkCreateDocument(string memory jsonString)
        private
        view
        returns (bool)
    {
       
        require(isPublished, "{DHYE56}"); //not published
        require(authorizedCreators[msg.sender], "{JFIIF8}"); //not an authorized creator
   
        string memory jsonCheck;
        uint256 tokenId = 0;
      
        (jsonCheck, tokenId) = checkJsonDocValues(jsonString);

        require(bytes(jsonCheck).length == 0, string(abi.encodePacked(jsonCheck," {ASAWEC}"))); //json values do not match what they are supposed to.

        // require(tokenIdToDocId[tokenId] == 0, "{KSBNIC}"); //tokenId already has a docId.
        return true;
    }

    //@dev internal.  Called by checkCreateDocument to check if JSON string values match this
    //contract.
    function checkJsonDocValues(string memory jsonString)
        internal
        view
        returns (string memory, uint256 tokenId_)
    {
        string memory retval = "";
        string memory testval; //a value extracted from the json string.
        string memory localval; //the string version of a local variable.
        testval = signingHelper().jsonValueByKey(jsonString, "project_name");
        testval = signingHelper().jsonValueByKey(jsonString, "token_id");
        if (bytes(testval).length == 0) {
            retval = string(abi.encodePacked(retval," token_id is required"));
        } else {
            tokenId_ = signingHelper().string2Uint(testval) ;
        }
 
        testval = signingHelper().jsonValueByKey(jsonString, "template");
        if (!signingHelper().eql(testval,  BKTemplate)) string(abi.encodePacked(retval, " template mismatch"));
        testval = signingHelper().jsonValueByKey(jsonString, "collection");
        localval = signingHelper().adr2str(bindingCollAddress);
        if (!signingHelper().eql(testval,  localval)) string(abi.encodePacked(retval, " collection mismatch"));
        testval = signingHelper().jsonValueByKey(jsonString, "source_contract");
        if (!signingHelper().eql(testval,  signingHelper().adr2str(address(this))))
            string(abi.encodePacked(retval, " sourceContract mismatch"));
        return (retval, tokenId_);
    }

    /**Used by takers to countersign docs already signed by makers */
    function takerSignDocument(bytes32 hashproof, bytes memory signature)
        public
    {
        checkTakerSignDocument(hashproof, signature);
        uint32 sigIndex = sigIndexByHashProof[hashproof];
        SigningRecord storage sig = signingRecords[sigIndex];
        sig.takerSig = signature;
        sig.takerSigState = SigState.Complete;
        sig.timestamp = block.timestamp;
        completedDocumentIds.push(sig.sigId);
        emit SignedEvent(
            sig.sigId,
            sig.maker,
            sig.taker,
            sig.tokenId,
            sig.docId
        );
    }

    /**
     * @dev indicates whether there is a signed document for combination of token, maker and taker.
     * @return uint32 the sigId for the document if it exists, or 0 if no sigDocument was found.
     */
    function isSigned(
        uint256 tokenId,
        address maker,
        address taker
    ) public view returns (uint32) {
        uint32[] memory sigIds = sigIndexByTokenId[tokenId];
        for (uint32 i = 0; i < sigIds.length; i++) {
            SigningRecord storage sig = signingRecords[sigIds[i]];
            if (sig.maker == maker && sig.taker == taker) {
                return sig.sigId;
            }
        }
        return 0;
    }

    function checkTakerSignDocument(bytes32 hashproof, bytes memory signature)
        internal
        view
        returns (bool)
    {
        SigningRecord memory sig = signingRecords[
            sigIndexByHashProof[hashproof]
        ];
        require(sig.sigId > 0, "no such signing document {SJF9N0}");
        address hashSigner = signingHelper().getSigner(hashproof, signature); //this will revert if the signature is invalid.
        require(
            hashSigner == sig.taker && hashSigner == msg.sender,
            "{KDNEI0}"
        ); //signer must be both taker and sender.
        require(sig.hashProof == hashproof, "{KFEV30}"); //if this happens, there's a program error with the sigIndexByHashProof.
        require(sig.taker == msg.sender); //the taker has to be sender, as well the account which issued the signature.
        return true;
    }

    function checkJsonSigValues(SigningParams memory sigParams)
        internal
        view
        returns (string memory)
    {
        string memory jsonString = sigParams.jsonAttribsSigned;
        string memory retval = "";
        string memory testval; //a value extracted from the json string.
        testval = signingHelper().jsonValueByKey(jsonString, "maker");
        if (!signingHelper().eql(testval,  signingHelper().adr2str(sigParams.makerAddress)))
            string(abi.encodePacked(retval, " maker mismatch"));
        testval = signingHelper().jsonValueByKey(jsonString, "taker");
        if (!signingHelper().eql(testval,  signingHelper().adr2str(sigParams.takerAddress)))
            string(abi.encodePacked(retval, " taker mismatch"));
        testval = signingHelper().jsonValueByKey(jsonString, "tokenId");
        if (signingHelper().string2Uint(testval) != sigParams.tokenId)
            string(abi.encodePacked(retval, " tokenId mismatch"));
        return retval;
    }

    /**@dev This function can be called to retrieve the data that will be used to produce the final document to be signed
by a taker, and can also be used to produce the hash proof to be signed by the client. */
    function getTagRefMapData(uint32 sigId)
        public
        view
        returns (TagRefMapData memory)
    {
        SigningRecord storage sig = signingRecords[sigId];
        DocumentRecord storage doc = documentRecords[sig.docId];
        TagRefMapData memory retval;
        retval.sigId = sigId;
        retval.maker = sig.maker;
        retval.taker = sig.taker;
        retval.tokenId = sig.tokenId;
        retval.jsonMap = doc.jsonAttribs;
        retval.hashProof = sig.hashProof;
        retval.makerSig = sig.makerSig;
        retval.takerSig = sig.takerSig;
        retval.rootTemplate = signingHelper().jsonValueByKey(doc.jsonAttribs, "template");
        return retval;
    }

    /**
     * The maker must create a signatureDocument before the taker can sign.  
     * If the maker is required to sign, the params should include the maker signature
     * which should be a valid signature of the hash proof. The hash proof definition is:
     * bytes32 hashProof = keccak256(abi.encodePacked(templateDocumentHash, params.jsonAttribsSigned,
               params.makerAddress, params.takerAddress));
    */
    function createSigningRecord(SigningParams memory params)
        public
        returns (uint32)
    {
        bytes32 hashproof_ = checkCreateSigningRecord(params); //this will revert if there's a problem that would cause reversion.
        sigCount += 1;
        SigningRecord storage sig = signingRecords[sigCount];
        sig.docId = params.docId;
        sig.sigId = sigCount;
        sig.maker = params.makerAddress;
        sig.taker = params.takerAddress;
        sig.tokenId = params.tokenId;

        sig.hashProof = hashproof_; //if there is a maker signature, we already know that it matches this hash.
        //sig.sigdataJson = params.jsonAttribsSigned;
        sig.makerSig = params.makerSignature; //this could be empty if not required.
        sig.timestamp = block.timestamp;
        //if the sender is maker, and a signature is required, then the signature has been checked, so in any event maker is complete.
        sig.makerSigState = SigState.Complete;

        //add sig document to maps.
        sigIndexByMaker[params.makerAddress].push(sig.sigId);
        sigIndexByTaker[params.takerAddress].push(sig.sigId);
        sigIndexByTokenId[params.tokenId].push(sig.sigId);
        console.log("stella tokenId", params.tokenId);
        console.log("martha sigIds:", sigIndexByTokenId[params.tokenId][0]);
        sigIndexByHashProof[sig.hashProof] = sig.sigId;
        docTransactionMap[sig.docId].push(sig.sigId); //the hash proof is what uniquely identifies this signature document.
        emit PendingSignedEvent(
            sig.sigId,
            params.makerAddress,
            params.takerAddress,
            params.tokenId,
            params.docId
        );
        return sig.sigId;
    }

    /**
     * This function is used to validate params by createSigningRecord, but also can be called directly by a
     * a client as a (free) view function before calling createSigningRecord to avoid wasting gas in case
     * of reversion.
     * @return bytes32 - the calculated hashproof based on supplied params.
     */
    function checkCreateSigningRecord(SigningParams memory params)
        private
        view
        returns (bytes32)
    {
        require(isPublished, "not published");
        require(isAuthorizedMaker(params.makerAddress), "{A64EWS}}");
        //Doc Id is valid?
        require(params.docId > 0 && params.docId <= docCount, "{SJD9N0}"); //unknown docId
        DocumentRecord memory doc = documentRecords[params.docId];
        require(params.makerAddress == msg.sender, "{XCSDR3}"); //sender should be maker.
        require(params.tokenId == doc.tokenId, "VNDJC98"); //tokenId in params doesn't match original doc.
        //make sure a taker address is present
        require(params.takerAddress != address(0), "{XCSDR4}"); //no taker address in params.
        if (requireMakerSignature) {
            require(params.makerSignature.length > 0, "{XCSDR5}"); //no maker signature provided
        }
        require(
            signingHelper().startwith(params.jsonAttribsSigned,
                signingHelper().subst(doc.jsonAttribs, 0, -1)),
            "{JVND33}"); //jsonAttribs have been changed.

        bytes32 hashProof = keccak256(
            abi.encodePacked(
                templateDocumentHash,
                params.jsonAttribsSigned,
                params.makerAddress,
                params.takerAddress
            )
        );

        require(sigIndexByHashProof[hashProof] == 0, "{XCSDR7}"); //already a document for this hash proof.
        address hashSigner;
        if (requireMakerSignature) {
            hashSigner = signingHelper().getSigner(
                hashProof,
                params.makerSignature
            );
            require(hashSigner == params.makerAddress, "{FND7A2}"); //hashProof signer is not maker;
        }
        //check that taker and maker address are included in the JSON -- NOT!

        // require(
        //     (params.jsonAttribsSigned.jsonValueByKey("maker")).equals(
        //         signingHelper().adr2str(params.makerAddress)
        //     ),
        //     "{F2SKES}"
        // ); //json maker address doesn't match signed params.abi
        // require(
        //     (params.jsonAttribsSigned.jsonValueByKey("taker")).equals(
        //         signingHelper().adr2str(params.takerAddress)
        //     ),
        //     "{KFK43N}"
        // ); //json taker address doesn't match signed params.abi

        return hashProof;
    }

    function getDocRecord(uint32 docId)
        public
        view
        returns (DocumentRecord memory)
    {
        require(documentRecords[docId].docId > 0, "{8KE3GJ}"); //document not found
        return documentRecords[docId];
    }

    function getDocRecordsForTokenId(uint256 tokenId)
        public
        view
        returns (DocumentRecord[] memory)
    {
        uint256 recCount = tokenIdToDocId[tokenId].length;
        DocumentRecord[] memory retval = new DocumentRecord[](recCount);

        if (recCount == 0) return retval;
        for (uint256 i = 0; i < recCount; i++) {
            retval[i] = documentRecords[tokenIdToDocId[tokenId][i]];
        }
        return retval;
    }

    function getSigningRecord(uint32 sigId)
        public
        view
        returns (SigningRecord memory)
    {
        require(signingRecords[sigId].sigId > 0, "{F987DF}"); //document not found
        return signingRecords[sigId];
    }

    // //returns the json data for the attribsMap.
    // function getSignedAttribsJSON(uint32 docId)
    //     public
    //     view
    //     returns (string memory)
    // {
    //     require(docId == 0 || docId > docCount, "invalid docId {KINT55");
    //     return documentRecords[docId].jsonAttribs;
    // }

    /** Publishes this BKEmbedded so it is ready for use.  It sets the initial maker (which may be owner)
     *    and records the template signature produced by the maker.  This demonstrates makers
     *    consent to the use of template.
     *   Each maker authorized to create documents must first by authorized by calling publish
     *   @param makerAddress is the address of the maker who is signing the agreement.    *
     *   @param makerSignature is the signature by the maker of the template hash.  This is always required.
     *   @param requireMakerSignature_ determines whether the maker must provide a full signature of the agreement
     *          transaction for it to treated as complete and binding.
     *
     */
    function publish(
        bytes memory makerSignature, //signature of the templateDocumentHash.
        address makerAddress,
        bool requireMakerSignature_
    ) public onlyAuthorizedCreator {
        require(!(isPublished), "{NVND3K}"); //already published
        require(bytes(BKTemplate).length > 0, "{JRR2QA}"); //no template specified
        require(templateDocumentHash != 0, "{JJU73T}"); //no template hash
        require (pageStore.length > 0, "{KFJUEN}"); //page store is empty.
        addMaker(makerSignature, makerAddress);
        requireMakerSignature = requireMakerSignature_; //write only at publsih time?
        isPublished = true;
    }

    function addMaker(
        bytes memory makerSignature, //signature of the templateDocumentHash.
        address makerAddress
    ) public onlyAuthorizedCreator {
        //   require(isPublished,"{KFHEDK}"); //not published.
        address signerAddress = signingHelper().getSigner(
            templateDocumentHash,
            makerSignature
        );
        require(signerAddress == makerAddress, "{XNXN93}"); //templateHash signer is not maker
        makerSignatures[makerAddress] = makerSignature;
    }

    function isAuthorizedMaker(address signerAddress)
        public
        view
        virtual
        returns (bool)
    {
        return makerSignatures[signerAddress].length != 0;
    }

    // function addApprovedTaker(address takerAddress) public {
    //     require(makerSignatures[msg.sender].length > 0, "QL5HY"); //sender is not a Maker
    //     takerMap[takerAddress] = msg.sender;
    // }

    /**
     * @dev This function marks a pending document as "rejected" and emits a rejected event.
     * It can be called by either the maker or the taker so long as the document is pending
     * for the part in question.  (If no signature is required, a document can't be rejected by
     * the party who created it.)
     */
    function rejectSignature(uint32 sigId) public {
        checkRejectSignature(sigId); //will revert if sigId/msg.sender are not valid to reject.

        SigningRecord storage sig = signingRecords[sigId];
        if (msg.sender == sig.maker) {
            sig.makerSigState = SigState.Rejected;
        } else {
            sig.takerSigState = SigState.Rejected;
        }
        sig.timestamp = block.timestamp;
        //remove taker from map.
        emit RejectedEvent(
            sig.sigId,
            sig.maker,
            sig.taker,
            sig.tokenId,
            sig.docId
        );
    }

    function checkRejectSignature(uint32 sigId) public view returns (bool) {
        SigningRecord storage sig = signingRecords[sigId];
        require(sig.sigId > 0, "{PNM4444}"); //document not found
        require(docSigState(sigId) == SigState.Pending, "{PNM4445}"); //document not pending
        require(
            msg.sender == sig.maker || msg.sender == sig.taker,
            "{PNM4446}"
        ); //only maker or taker can reject
        if (msg.sender == sig.maker) {
            require(sig.makerSigState == SigState.Pending, "{PNM4447}"); //only if pending
        } else {
            require(sig.takerSigState == SigState.Pending, "{PNM4448}"); //only if pending.
        }
        return true;
    }

   

    function addTemplatePage(string memory pageContents)
        public
        onlyAuthorizedCreator
    {
        if (pageStore.length == 0) {
            pageStore.push(
                signingHelper().makeHeaderPage(
                    BKContractName,
                    BKTemplate,
                    msg.sender
                )
            );
        }
        pageStore.push(pageContents);
    }

    function pageCount() public view returns (uint16) {
        return uint16(pageStore.length);
    }

    function getMergePage(uint32 sigId, uint16 pageNumber)
        public
        view
        returns (string memory page, bool isPartial)
    {
        require(pageNumber < pageStore.length, "{VN8765}"); //page out of ranger
        return
            signingHelper().renderPage(
                getTemplatePage(pageNumber),
                getTagRefMapData(sigId)
            );
    }

    //This function is for continuation of a rendering interupted by running out of gas.
    function finishMergePage(uint32 sigId, string memory partialPage)
        public
        view
        returns (string memory, bool isPartial)
    {
        return signingHelper().renderPage(partialPage, getTagRefMapData(sigId));
    }

    function getTemplatePage(uint16 pageNumber)
        public
        view
        returns (string memory page)
    {
    
        string memory pageNum = signingHelper().uintToStr(pageNumber);
        require(pageNumber <= pageStore.length, signingHelper().concat(pageNum, ": {P3KKJ0}")); //page out of range
        return pageStore[pageNumber];
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./BKBinding.sol";
import "./BKLibrary.sol";
import "./BKStrings.sol";
import "./BKEmbedded.sol";
import "./BKBindingFactory.sol";
import "./BKEmbedRoot.sol";
import "./BKRenderer.sol";
import "hardhat/console.sol";


/**
    @title BKBindingCollection for BKEmbeded
    @author BKopy.io c 2022
    @dev Contains a collection of bindings and attributes which make up a legal agreement.
         Bindings represent section of the agreement; attributes are values which are inserted into
         the templates.  The attributes are read either from the smart contract, or values which
         are specific to a particular transaction.
*/
contract BKBindingCollection {
    using BKLibrary for string;
    address public owner;
    address public sigHelperAddress; //address of the global BKSigningHelper
    string private _id;  //should be a guid which represents this collection.
    address public embedRoot; //The address of BKEmbedRoot.
    mapping(address => string) public embedContracts; //contractAddress => rootTemplateName;
    mapping(string => address) private bindingMap; //fqName to contract addres
    mapping(string => BKAttrib) private attribMap;    //tagRef->BKAttrib struct
    mapping(string => uint8) private sectionMap;
    string public projectName;
    string[] private bindingNameList;
    string[] private attribNameList;
    string[] private _sectionList;
    //  mapping(string=>BKLibrary.SolidityABITypes) private attribMap;

    address[] private bindingAddressList;

 
    constructor(address owner_, address embedRoot_ ) {
        embedRoot = embedRoot_;
        owner = owner_;
        sectionMap["Uncategorized"] = 0;
        sectionMap["RootTemplate"] = 1;
        _sectionList.push("Uncategorized");
        _sectionList.push("RootTemplate");   
        sigHelperAddress = BKEmbedRoot(embedRoot).getBKSigningHelperAddress();
    }

    string constant public BKVersion = "0.1.17";
    string constant public contractName = "BKBindingCollection";
    
    function setProjectName(string memory projectName_) public  {
       
        require(msg.sender == embedRoot || msg.sender == owner || msg.sender==BKOPY_PROTOCOL_OWNER, "onlyOwnerOrRoot" );
        require(bytes(projectName).length==0, "write-once");
        require(bytes(projectName_).length > 0, "name is empty");
        projectName = projectName_;
        BKLibrary.addStandardAttributesToCollection(address(this));
    }

    // @dev Ideally, 'id' would be set in the constructor, but doing so pushes the size of
    // BKBindingCollectionMaker up by .75K, and likely exceeds the Spurious Dragon size limit
    // So this function is used to set it after the collection is created, which should be done 
    // by the same creator who sets the project name. 
    function setId(string calldata id_) public {
       require( bytes(_id).length==0, "write-once");
        _id= id_;
    }
    function getId() public view returns (string memory) {
        return _id;
    }
     
    /**
     * @dev determines wither a given name is a root template or not.
     */
    function isTemplate(string memory fqName) public view returns (bool) {
        require(exists(fqName), fqName.concat(" does not exist"));
        BKBinding b = BKBinding(bindingMap[fqName]);
        return b.isRootTemplate();
    }
       
    /**
        Returns the list of finalized (published) binding names
    */
    function bindingList() public view returns (string[] memory) {
        return bindingNameList;
    }

    function existsSection(string memory name) public view returns (bool) {
        return sectionMap[name] != 0;
    }

    function sectionList() public view returns (string[] memory) {
        return _sectionList;
    }

    function sectionIndex(string memory name) public view returns (uint8) {
        return sectionMap[name];
    }

    function addSection(string memory sectionName) public  {
        require(msg.sender == owner, "onlyOwner");
        require(
            !existsSection(sectionName),
            sectionName.concat(" already exists")
        );
        require(_sectionList.length < 255, "max sections");
        require(!sectionName.isEmpty(), "section name is empty");
        sectionMap[sectionName] = uint8(_sectionList.length);
        _sectionList.push(sectionName);
    }

    function attribList() public view returns (string[] memory) {
        return attribNameList;
    }

    /** Returns whether named binding is present in the collection.  (includes unpublished)
     */
    function exists(string memory fqName) public view returns (bool) {
        if (bindingMap[fqName] == address(0)) return false;
        return true;
    }
    function isPublished(string calldata fqName) public view returns (bool) {
        require(exists(fqName), fqName.concat(" does not exist"));
        return BKBinding(bindingMap[fqName]).isPublished();
    }

    function existsAttrib(string memory attribName) public view returns (bool) {
        attribName = attribName.toLowerCase();
        SolidityABITypes typ = attribMap[attribName].outputType;
        if (typ == SolidityABITypes.Null) {
            return false;
        }
        return true;
    }

    function getAttribMeta(string memory attribName)
        public
        view
        returns (BKAttrib memory)
    {
        attribName = attribName.toLowerCase();
        require(
            existsAttrib(attribName),
            attribName.concat(" is unknown BKAttrib {VIDSPF}")
        );
        return attribMap[attribName];
    }

    // function getAccessorFunction(string memory attribName)
    //     public
    //     view
    //     returns (string memory)
    // {
    //     require(existsAttrib(attribName.toLowerCase()), 
    //             BKStrings.concat(attribName, " no such attrib")
    //            );
    //     string memory fName = getAttribMeta(attribName).functionName;
    //     if (fName.isEmpty()) return attribName.concat("()");
    //     return fName.concat("()");
    // }

    function getAddress(string memory fqName) public view returns (address) {
        return bindingMap[fqName];
    }

     
    
    /** Makes a new, named binding with the given name and version number.
        In order to use the binding, finalize must be called first.  Parameters 
        to finalize provide the binding metadata which includes the text of 
        binding template.
        @param name_ the name of the binding
        @param version_ a string of the form major.minor.version, (i.e. "1.0.1"
        The binding fully qualified of the bindinglooks something like sample_binding.1.0.1.
        @dev Note that the format of name and version are checked and if not proper will revert.
              name should be [a-z][a-z|_]+ (i.e lower case words separated only by underscores.
              versions should be a 3 sets of 1 or 2 digit numbers separated by periods, eg. 2.10.3

    */
    function makeBinding(string memory name_, string memory version_)
        public
        returns (address)
    {
   
        require(msg.sender == owner, "onlyOwner");
        name_ = BKStrings.toLower(name_);
        require(
            !name_.isEmpty() && !version_.isEmpty(),
            "name, version are required"
        );
        require(name_.isSnakeCase(), "name must be snake case");
        string memory fqName = name_.concat(".").concat(version_);
        require(!exists(fqName), fqName.concat(": duplicate binding"));
        BKBinding binding = newBinding(name_, version_);
        bindingMap[fqName] = address(binding);
        bindingNameList.push(fqName);
        return address(binding);
    }    

    //should be called only by make binding.
    function newBinding(string memory name, string memory version) private returns(BKBinding) {
        BKEmbedRoot root = BKEmbedRoot(embedRoot);
        address factoryAddress = root.factoryAddress();
        return BKBindingFactory(factoryAddress).makeNewBinding(name, version, address(this), _id);
    }

    /**
        @dev Default attribs are added by setProjectName function
     */
    function addAttrib(BKAttrib memory meta) public {
        //BKLibrary in add ProjectName adds default attribs due to size constraints.
        require(msg.sender == owner  || msg.sender == address(this), "onlyOwnerThis");
        require(
            !existsAttrib(meta.tagRef.toLowerCase()),
            meta.functionName.concat(": duplicate attrib")
        );
        require(!meta.functionName.isEmpty(), "functionName can't be empty");
        require(!meta.tagRef.isEmpty());
        require(meta.outputType != SolidityABITypes.Null, "attrib type cant be null");
        if (meta.callType==AttribCallType.KeyForStruct || meta.callType== AttribCallType.JsonKeyForURL)  {
            require(!meta.metaKeyName.isEmpty(), "metKeyName cant be empty");
        }
        attribMap[meta.tagRef] = meta;
        attribNameList.push(meta.tagRef);
    }

     

    function finalize(string memory fqName, BindingMeta memory meta)
        public
    {
        require(msg.sender == owner, "onlyOwner");
        require(exists(fqName), "no such binding");
        address bindingAddress = getAddress(fqName);
        string memory validateResult = validate(meta, fqName);
        require(validateResult.equals("ok"), validateResult.concat( " {KKXEVMV}"));
        BKBinding binding = BKBinding(bindingAddress);
        require(
            !binding.isPublished(),
            fqName.concat(": binding already published")
        );
        binding.addMeta(meta);
        binding.publish();       
    }      
    
    function validate(BindingMeta memory meta, string memory fqName)
        private
        view
        returns (string memory)
    {
        //check if any embedded bindings or attributes, that they are known, and if there are are they already written?
        require(
            !meta.templateText.isEmpty(),
            fqName.concat(" is missing templateText")
        );
        string[] memory bindings = BKStrings.findTemplateRefs(
            meta.templateText,
            "!{"
        );
        if (bindings.length > 0) {
            for (uint256 i = 0; i < bindings.length; i++) {
                if (bindings[i].equals(fqName)) {
                    return "BKBinding is circular";
                }
                //prevent recurive circular binding by requiring that all embedded bindings must
                //defined and published before the containing binding is published.
                if (!exists(bindings[i]))
                    return bindings[i].concat(" is unknown embedded binding");
                //check that the embedded binding is published. (Must be published because template text might be changed pre-publish,)
                bool published = BKBinding(bindingMap[bindings[i]]).isPublished();

                if (!published) {
                    return bindings[i].concat(" is embedded but not yet published");
                }
            }
        }  
        return "ok";
    }
    function templateHash(string memory fqName) public view returns(bytes32) {
        require(exists(fqName), "no such binding {CMDJH7}");
        address bindingAddress = getAddress(fqName);
        BKBinding binding = BKBinding(bindingAddress);
        return binding.templateHash();
    }
 
    function render(string memory template, address contractAddress) public view returns(string memory) {
        string memory retval =  BKRenderer(BKEmbedRoot(embedRoot).rendererAddress()).render(address(this), contractAddress, template);
        return retval;
    }
    
    function selfDestruct() public  {
        require(msg.sender == BKOPY_PROTOCOL_OWNER, "only BKopy owner");
        selfdestruct(payable(BKOPY_PROTOCOL_OWNER));
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;
import "./BKBindingCollection.sol";
import "./BKEmbedded.sol";
import "./BKLibrary.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";
import "./BKStrings.sol";

//import "hardhat/console.sol";

 

string constant BytesPrefix = "0x";

/**
 * This contract consists of various utility functions used by the BKEmbedded protocol.
 * It functions repository for library functions used by the BKEmbedded, primarily
 * to reduce the size of BKEmbedded by moving these functions into a separate contract.
 * li
 */
contract BKSigningHelper {
    using ECDSA for bytes32;
    using BKLibrary for string;
 

    string constant public contractName="BKSigningHelper.1.16";

   
    address public rootAddress; //BKEmbedRoot
   
    constructor(address rootAddress_) {
        rootAddress = rootAddress_;
    }

    /**
      * @dev A utility function to see if the data recorded in a json string, matches parameters 
      * that are supplied to certain function calls.  For example, SigningParams contains the address
      * for the "taker" as a aprameter.  The same address is also contained in the json string parameter.
      * This function checks the two values match.  The function will return empty string if no 
      * problems are found. If problems are found, the function will a return a string describing
      * mismatch.
     */
    function checkJsonValues(
        SigningParams memory params,
        string memory template
    ) external view returns (string memory ) {

        string memory retval = "";
    
        string memory jsonTaker = params.jsonAttribsSigned.jsonValueByKey("taker");
        string memory takerSt = BytesPrefix.concat(
            BKLibrary.addr2string(params.takerAddress)
        );
        if (!jsonTaker.equals(takerSt)) retval.concat("taker address mismatch");
        string memory jsonMaker = params.jsonAttribsSigned.jsonValueByKey("maker");
        string memory makerSt = BytesPrefix.concat(
            BKLibrary.addr2string(params.makerAddress)
        );
        if (!makerSt.equals(jsonMaker)) retval.concat(" maker address mismatch");
        string memory jsonId = params.jsonAttribsSigned.jsonValueByKey("token_id");
        string memory tokenIdSt = BKLibrary.uint2str(params.tokenId);
        if (!jsonId.equals(tokenIdSt)) retval.concat(" token_id mismatch");
        string memory jsontemplate = params.jsonAttribsSigned.jsonValueByKey("template");
        if (!jsontemplate.equals(template)) retval.concat(" template mismatch");
        if (bytes(retval).length > 0) {
            console.log("checkSignAndRecordJsonValues: ", retval);
        }
       
        return retval;
    }

    /**
    *   User to check countersignature of a signed transaction.
     */
    function checkCountersign(
        bytes calldata signature,
        bytes32 message,
        address signer
    ) external pure returns (bool) {
       
        address messageSigner = extractAddress(signature, "",message);
        return (messageSigner == signer);
    }
    

    
    // @dev taker signature is a digital signature by the taker account of hash(JSON.stringfy(AttribsDictionary) and hash(document template))
    // @dev maker signature is only applied to hash(document template), so the makers signature need only be calculated once
    // Individual maker signatures of specific attrib values are not required because only makers can approve the signature
    // in the firstplace, and thus are deemd to have approved any agreement which they have accepted for registration. 
    // Maker signatures are stored within BKEmbedded in the makerSignatures map, and stored at the time a maker is is registered
    // with addMaker signature.
    /* Confirms that the supplied signatures in the singing params struct are valid as to taker and maker address of maker and taker..  */
    function checkContractSignature(
        bytes32 templateHash,
        SigningParams memory params,
        bytes memory makerSig
    ) public view returns (bool) {
        // Calculate the hash of templateHash and attributes
        bytes32 docHash = keccak256(
            abi.encodePacked(templateHash, params.jsonAttribsSigned)
        );
        //Check that this docHash was signed by either maker or taker.
        address takerAddress = params.takerAddress;
        address makerAddress = params.makerAddress;
        if (params.takerSignature.length > 0) {
            address sigAddress = extractAddress(params.takerSignature, "", docHash);
            if (takerAddress != sigAddress) {
                console.log("taker signature failed {SJFKEX}", takerAddress, sigAddress);
                return false;
            }
        } else {
            //check maker signature
            if(makerSig.length==0) {
                console.log("both taker and maker address are missing {JNYCBE}");
                return false;
            }
            address sigAddress = extractAddress(params.makerSignature, "", docHash);
            if (makerAddress != sigAddress) {
                console.log("maker signature failed {SMFERX}", makerAddress, sigAddress);
                return false;
            }
        }
        return true;
    }

    function getAddressPairIndexedFunctionResult(string memory functionName, 
       address address1, address address2, SolidityABITypes resultType, address source) 
       public virtual view returns(string memory) {
        string memory functionCall;
        bytes memory payload;
        if (address2 == address(0)) {
            functionCall=functionName.concat("(address)");
            payload = abi.encodeWithSignature(functionCall, address1);
        } else {
            functionCall = functionName.concat("address,address");
            payload = abi.encodeWithSignature(functionCall, address1, address2);
        }
        bytes memory result;
        bool success;
        (success, result) = source.staticcall(payload);
        require(success, functionName.concat(" couldn't be fetched"));
        string memory retval = BKLibrary.parseResult(resultType, result);
        return retval;
    }

    function getSigner(bytes32 hashMessage, bytes memory signature) public pure returns (address) {
        return extractAddress(signature, "", hashMessage);
    }

    function makeHeaderPage(string calldata conName, string calldata template, address creatorAddress ) public view returns (string memory) {
          return conName.concat("<p>Document Template:  ").concat(template).concat(" Creation timestamp: ")
              .concat(BKLibrary.uint2str(block.timestamp)).concat(" by ").concat(BKLibrary.addr2string(creatorAddress)).concat("</p>");            
    }

    function getTokenIndexedFunctionResult(string memory functionName, uint tokenIndex, SolidityABITypes resultType, 
    address source) public virtual view returns(string memory) {   
        string memory functionCall = functionName.concat("(uint256)");
        bytes memory payload = abi.encodeWithSignature(functionCall, tokenIndex);
        bytes memory result;
        bool success;
        

        (success, result) = source.staticcall(payload);
        require(success, functionName.concat(" couldn't be fetched"));
        return BKLibrary.parseResult(resultType, result);
    }

    function getSimpleFunctionResult(string memory functionName, SolidityABITypes resultType, address source) public virtual view returns(string memory) {            
        bytes memory result;
        bool success;
        (success, result) = address(source).staticcall(abi.encodeWithSignature(functionName.concat("()")));
        require(success, functionName.concat("couldn't be fetched"));
        return BKLibrary.parseResult(resultType, result);
    }

    

    function checkHash(string memory message, bytes32 hash)
        public
        pure
        returns (bool)
    {
        bytes32 messageHash = keccak256(abi.encodePacked(message));
        return messageHash == hash;
    }

    /**This function calculates the same hash as ethers.utils.solidicityKeccak256 . */
    function calcHash(string memory doc) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(doc));
        return hash;
    }
    function verifyHashSignature(bytes32 hash, bytes calldata signature, address signer) public pure returns (bool) {
        address messageSigner = extractAddress(signature, "", hash);
        return (messageSigner == signer);
    }


    function verifyStringSignature (
        address sender,
        string memory message,
        bytes memory signature
    ) public pure returns (bool) {
        address result = sigAddressFromString(message, signature);
        if (sender == result) return true;
        return false;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    function sigAddressFromHash(bytes32 message, bytes memory signature)
        public
        pure
        returns (address)
    {
        return extractAddress(signature, "", message);
    }

    function sigAddressFromString(string memory message, bytes memory signature)
        public
        pure
        returns (address)
    {
        return extractAddress(signature, message, 0);
    }

    function extractAddress(
        // https://blog.ricmoo.com/verifying-messages-in-solidity-50a94f82b2ca
        // Returns the address that signed a given string message or hash message

        bytes memory signature,
        string memory message,
        bytes32 hashedMessage
    ) private pure returns (address signer) {
        bool isHash = (hashedMessage > 0);
        if (isHash) {
            return hashedMessage.toEthSignedMessageHash().recover(signature);
        }
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(signature);
        string memory header;
        bytes32 check;
        header = "\x19Ethereum Signed Message:\n000000";
        uint256 length;
        uint256 lengthOffset;
        assembly {
            length := mload(message)
            lengthOffset := add(header, 57)
        }
        if (isHash) length = 32;
        require(length <= 999999);
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    function renderPage(string memory template, TagRefMapData memory data) public view returns(string memory, bool abort) {
        abort = false;
        string[] memory tags = BKLibrary.findEmbeddedAttributes(template);
        
        string memory tag;
        string memory bTag;
        string memory value = "";
        for (uint i = 0; i < tags.length; i++) {
            tag = tags[i];
           
            if (tag.equals("maker")) value = BKLibrary.addr2string(data.maker);
            if (tag.equals("taker")) value = BKLibrary.addr2string(data.taker);
            if (tag.equals("maker_signature")) value = BKLibrary.bytestoString(data.makerSig);
            if (tag.equals("taker_signature")) value = BKLibrary.bytestoString(data.takerSig);
            if (value.length()==0) {
                value = BKLibrary.jsonValueByKey(data.jsonMap, tag);
            }
            if (value.length()==0) value = string(abi.encodePacked("[missing '",tag,"']"));
          
            bTag = string(abi.encodePacked("#{",tag,"}"));
            uint pos = BKStrings.findPos(template,bTag);
            string memory aftertag = template.substring(pos+bTag.length(),0);
            template = string(abi.encodePacked(template.substring(0,int(pos-1)),value,aftertag));
            //check for out of gas 
            if (gasleft() < 2500000) abort = true;
            if (abort) break;
            value = "";
        }
        return (template, abort);
    }

    /**
     * @dev extracts a value from json array formmatted as [["key","value"],["key","value"]]
     */
    function jsonValueByKey(string memory json, string memory key)
        public
        pure
        returns (string memory)
    {
        require(json.startsWith("[["), json.concat(" not a json string"));
        string memory qt = '"';
        string memory keyFind = qt.concat(key).concat('","');
        string memory pre;
        string memory post;
        (, post) = json.splitAt(keyFind);
        (pre, ) = post.splitAt('"');
        return pre;
    }

    function string2Uint(string memory s) public pure returns (uint) {
        return BKLibrary.stringToUint(s);
    }

    function eql(string memory s1, string memory s2) public pure returns (bool) {
        
        return BKLibrary.equals(s1, s2);
    }
    function subst(string memory s, uint start, int length) public pure returns (string memory) {
        return BKLibrary.substring(s, start, length);
    }
    function startwith(string memory s, string memory start) public pure returns (bool) {
        return BKLibrary.startsWith(s, start);
    }
    function adr2str(address a) public pure returns (string memory) {
        return BKLibrary.addr2string(a);
    }
 
    function uintToStr(uint n) public pure returns (string memory) {
        return BKLibrary.uint2str(n);
    }
    function concat(string memory s1, string memory s2) public pure returns (string memory) {
        return BKLibrary.concat(s1, s2);
    }
 
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;
import "./BKLibrary.sol";

uint constant MAX_TEXT_LENGTH = 10000;  //75 storage slots.

contract BKBinding {
    using BKLibrary for string;

    /** @dev _section represents the section of the agreement where this binding is placed. 
       section 0=null and section 1 = template which is a top level binding used to encapsulate other bindings.
       other sections such as "definitions", "entitlements" "warrenties" etc. can be created by the end user.  
    */
   
    address private _owner;
    string private _collectionId;  //Identifies the collection to which this binding belongs.
    bool private _published;

    modifier onlyOwner() {
        require(msg.sender == _owner, "onlyOwner");  //
        _;
    }

    constructor(string memory name_, string memory version_, address owner_, string memory collectionId_ ) {
        _data.name = name_;
        _data.version = version_;
        _published=false;
        _collectionId = collectionId_;
        _owner = owner_;  //should be parent BKBindingCollection.
        fqName = _data.name.concat(".").concat(_data.version);
    }

    string public constant BKVersion="0.1.17";
    string public constant BKContractName = "BKBinding";
    string public fqName;
    
    BindingMeta private _data;

    function name() public view returns(string memory) {
        return _data.name; 
    }
    function version() public view returns(string memory) {
        return _data.version;
    }
    function templateHash() public view returns(bytes32) {
        return _data.templateHash;
    }
    function isPublished() public  view returns(bool) {
        return _published;
    }
    function publish() public {
        require(msg.sender == _owner, "{NNH6H6}");  //can only be called by binding collection
        require(!_published, "{PP8JJD}"); //already published
        if (isRootTemplate()) {
            require(_data.templateHash > 0 , "{KSKVN3}"); // rendered template hash is required for root templates before publishing.        }
        }
        _published = true;
    }

   

    // /**
    //  * @dev This is a hash of the rendered template of a root binding calculated by the 
    //  * API at publish time (without tagRef interpolation).  That is, all the bindings
    //  * composedD together, but with tagRefs embedded.
    //  */
    // function setTemplateHash(bytes32 hash) public  {

    //     require(msg.sender == _owner, "{KXMDWW}");  //can only be called by binding collection
    //     require(templateHash == "","{UJUR88}"); //templateHash is write once
    //     require(!isPublished() && isRootTemplate(), "{JJSSX3}");  //must be published and root template
    //     templateHash = hash;
    // }

    function getBindingMeta() public view returns(BindingMeta memory) {
        
        return _data;
    }
    function isRootTemplate() public view returns(bool) {
        return _data.section == 1;
    }
    function getTemplateText() public view returns(string memory) {
        return _data.templateText;
    }
    function meta() public view returns(BindingMeta memory) {
        return _data;
    }

    function addMeta(BindingMeta memory metadata) public  {
        require(msg.sender == _owner, "{NNXDT3}");  //can only be called by binding collection
        require(metadata.templateText.length() <= MAX_TEXT_LENGTH, "{MCUEHS}"); //templateText is too long
        require(!isPublished(), "already published");
        require(_data.name.equals(metadata.name), "name mismatch");
        require(_data.version.equals(metadata.version), "version mismatch");
        
        uint length = metadata.templateText.length();
        require (length > 0, "Binding template text is empty");
        _data.templateText = metadata.templateText;
        _data.plainText = metadata.plainText;
        _data.section = metadata.section;
        _data.author = metadata.author;
        _data.templateHash = metadata.templateHash;
        fqName = _data.name.concat(".").concat(_data.version);   
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./BKBindingCollection.sol";
import "./BKEmbedded.sol";
import "./BKEmbedRoot.sol";
import "./BKStrings.sol";
import "./BKLibrary.sol";
import "./BKBinding.sol";
import "hardhat/console.sol";

//must be the same as defined in BKBinding.sol

//uint256 constant RENDER_SECTION_LIMIT = 10000; //max length of a rendered sectionText

/**  @author BKopy.io
     Agreement rendering methods for BKEmbeded Protocol

 */
contract BKRenderer {
    address private _root;
    using BKLibrary for string;
    address private _owner;

    constructor(address root_) {
        _root = root_;
        _owner = msg.sender;
    }

    string public constant BKVersion = "0.1.17";
    string public constant contractName = "BKRenderer";

    // function renderTemplateSection(string memory templateName, collAddress, uint16 index) {
    //     //Render the bottom from top to bottom until you reach the start mark.
    //     //for the sectionText.  Then render until there are no binding tags in the first 10000 characters
    //     //following the start.

    //     string memory originalTemplateText  = getBindingText(templateName, collAddress);
    //     string memory iTemplateText=oTemplateText;
    //     uint retvalStart = (index * RENDER_LIMIT);
    //     uint retvalEnd = retvalStart + (RENDER_LIMIT-1);
    //     uint totalLength;
    //     uint startPos =0;  //The character position of the fully rendered template of the first char of iTemplateTexgt.
    //     uint endPos = iTemplateText.length();

    //     while (endPos < retvalStart) {
    //        //need to get more characters
    //        if (hasTags(iTemplateText)) {
    //          string[] tags = getTags(templateText);
    //          for(uint i=0; i<tags.length; i++) {
    //             iTemplateText = replaceTag(tags[i], iTemplateText);
    //             endPos = startPos + (iTemplate.text).length;
    //             if(endPos >)
    //          }

    //        } else {

    //        }

    //     }

    //     while (endPos > retvalStart) {

    //     if(startPos < retvalStart) {
    //         (,iTemplateText, splitPos) = splitAt(iTemplateText, retvalStart);
    //         startPos = (startPos + splitPos);
    //         endPos = (startPos + iTemplateText.length -1);
    //     }
    //     if (templateText.length > RENDER_LIMIT) {
    //         templateText=replaceTags(templateText);
    //     }
    //     return templateText;

    //     //get rid of everything prior to the start pos.addAttrib

    //     //REPLACE BINDINGS

    //     for(uint16 i=0; i<= index; i++) {
    //         startPos = startPos + 1;
    //         endPos = endPos + iTemplateText.length();
    //         totalLength += endPos-startPos;
    //         string[] bindingList = getBindingList(iTemplateText);
    //         hasBindings = bindingList.length> 0;
    //         if (hasBindings) {
    //             for (uint16 j=0; j<bindingList.length; j++) {
    //                 string memory bindingName = bindingList[j];
    //                 string memory bindingText = getBindingText(bindingName, collAddress);
    //                 iTemplateText = iTemplateText.replace(bindingName, bindingText);
    //                 if (iTemplateText.length() > RENDER_LIMIT) {
    //                     truncate(iTemplateText, RENDER_LIMIT);
    //                 }
    //             }
    //         }
    //         if (iTemplateText.length() > RENDER_LIMIT) {
    //             string memory pre;
    //             string memory post;
    //             (,iTemplateText) = splitAt(0, RENDER_LIMIT);

    //             iRemaining = iTemplateText.substring(RENDER_LIMIT+1);
    //         }
    //     }
    //     return iTemplateText;
    // }

    // function hasTags(string memory source) public pure returns (bool) {
    //     if findTags(source) > 0 {
    //         return true;
    //     } else {
    //         return false;
    //     }
    // }

    // /** @dev replaces template tags until there are no templatetags in the first RENDER_LIMIT characters of the source,
    // and then returns no more than render limit characters. */
    // function replaceTag(string memory source) private pure returns(string) {

    // }

    /** @dev splits a string such that before is chars(0->position) and after chars(position+1->end string) EXCEPT
            if the splitpoint would split in the middle of a binding, tag, before will consit of characters from 0 to the charcter
            preceding the start of the binding tag, and after would start witht he binding tag and continue till the end of the string. */
    // function splitAt(string memory text, uint position) private pure returns(string memory beforeSplit, string memory afterSplit, uint splitPoint) {
    //     string[] memory bindingList = getBindingList(text);
    //     //Don't split a binding tag across two sections, so see if position of the "length" param
    //     //would truncate the text in the middle of a tag.
    //     //is in the middle of a tag.

    //     for(uint i=0; i<bindingList.length; i++) {
    //         string memory before;
    //         string memory after;
    //         (before, after) = text.splitAt(bindingList[i]);
    //         if (before.length() < length)
    //             if (before.length() + bindingList[i].length() > length ) {
    //                 length = before.length();
    //                 break;
    //                 //splitting at length would split the tag, so back up the break point.
    //             }
    //         }
    //         if (before.length() > length) continue;
    //     }

    //     if (length > text.length()) return (text, "");
    //     return (text.substring(0, length-1), text.substring(length, 0);
    // }

    

    function render(
        address bindingColAddress,
        address contractAddress,
        string memory template
    ) public view returns (string memory) {
        BKBindingCollection bindingColl = BKBindingCollection(
            bindingColAddress
        );
        string memory rendered = getBindingText(template, bindingColAddress);
        rendered = renderBindings(rendered, bindingColl);
        rendered = renderAttribs(rendered, contractAddress);
        rendered = renderBoolAttribs(rendered, contractAddress, bindingColl);
        rendered = removeComments(rendered);
        return rendered;
    }

    function renderAttribs(string memory input, address contractAddress)
        private
        view
        returns (string memory)
    {
        string memory prefix = "#{";
        string[] memory attributes = BKStrings.findTemplateRefs(input, prefix);
        string memory target;
        string memory replacement;
        BKEmbedded dataSource = BKEmbedded(contractAddress);
        if (attributes.length == 0) return input;
        for (uint256 i = 0; i < attributes.length; i++) {
            target = prefix.concat(attributes[i]).concat("}");

            replacement = dataSource.getSimpleFunctionResult(
                attributes[i],
                SolidityABITypes.String
            );

            input = BKStrings.replace(input, target, replacement);
        }

        return input;
    }

    function isBoolAttrib(
        BKBindingCollection bindingColl,
        string memory attribName
    ) internal view returns (bool) {
        BKAttrib memory meta = bindingColl.getAttribMeta(attribName);
        bool result = (meta.outputType == SolidityABITypes.Boolean);
        return result;
    }

    function getBindingText(string memory fqName, address collAddress)
        private
        view
        returns (string memory)
    {
        BKBindingCollection bindingColl = BKBindingCollection(collAddress);
        return BKBinding(bindingColl.getAddress(fqName)).meta().templateText;
    }

    function renderBindings(
        string memory input,
        BKBindingCollection bindingColl
    ) private view returns (string memory) {
        console.log("pickles starting render bindings");
        console.log(input);
        string memory prefix = "!{";
        string[] memory embedded = BKStrings.findTemplateRefs(input, prefix);
        if (embedded.length == 0) return input;
        string memory bindingName;
        for (uint256 i = 0; i < embedded.length; i++) {
            bindingName = prefix.concat(embedded[i]).concat("}");

            string memory templateText = BKBinding(
                bindingColl.getAddress(embedded[i])
            ).meta().templateText;
            console.log("ricecrispies before replace", input, templateText);
            input = BKStrings.replace(input, bindingName, templateText);
            console.log("rice crispies", i, input);
        }
        
        embedded = BKStrings.findTemplateRefs(input, prefix);
        console.log("cukes", embedded.length);
    
        if (embedded.length == 0) return input;
        renderBindings(input, bindingColl);
        return "";
    }

    function renderBoolAttribs(
        string memory input,
        address contractAddress,
        BKBindingCollection bindingColl
    ) private view returns (string memory) {
        string memory prefix = "~{";
        string[] memory embedded = BKStrings.findTemplateRefs(input, prefix);
        BKEmbedded dataSource = BKEmbedded(contractAddress);
        if (embedded.length == 0) return input;
        string memory target;
        string memory replacement;
        for (uint256 i = 0; i < embedded.length; i++) {
            target = prefix.concat(embedded[i]).concat("}");
            string memory attribName;
            string memory trueVal;
            string memory falseVal;
            (attribName, trueVal, falseVal) = embedded[i].parseBooleanReplace();
            require(
                isBoolAttrib(bindingColl, attribName),
                attribName.concat("in boolean tag not bool attrib")
            );
            if (
                dataSource
                    .getSimpleFunctionResult(
                        attribName,
                        SolidityABITypes.Boolean
                    )
                    .equals("true")
            ) {
                replacement = trueVal;
            } else {
                replacement = falseVal;
            }
        }
        input = BKStrings.replace(input, target, replacement);
        return input;
    }

    function removeComments(string memory input)
        private
        view
        returns (string memory)
    {
        string memory prefix = ">{";
        string[] memory embedded = BKStrings.findTemplateRefs(input, prefix);
        if (embedded.length == 0) return input;
        for (uint256 i = 0; i < embedded.length; i++) {
            string memory target = prefix.concat(embedded[i]).concat("}");
            input = BKStrings.replace(input, target, "");
        }
        return input;
    }

    function renderTemplate( address collAddress, string memory templateName) public  view returns (string memory) {
        BKBindingCollection coll = BKBindingCollection(collAddress);
        BKBinding binding = BKBinding(coll.getAddress(templateName));
        string memory rootTemplateText = binding.getTemplateText();
        return renderBindings(rootTemplateText, coll);    

    }

    function mergeDocument(string memory templateDoc, TagRefMapData memory mapData) public view returns(string memory) {
       string memory prefix = "#{";
        string[] memory attributes = BKStrings.findTemplateRefs(templateDoc, prefix);
        string memory target;
        string memory replacement;
        if (attributes.length == 0) return templateDoc;
        for (uint256 i = 0; i < attributes.length; i++) {
            target = prefix.concat(attributes[i]).concat("}");
            replacement =  getFromJSON(attributes[i],  mapData);
            templateDoc = BKStrings.replace(templateDoc, target, replacement);
        }
        return templateDoc;
    } 

    function getFromJSON(string memory key,  TagRefMapData memory data) public pure returns(string memory) {
      
        if (key.equals("maker")) return BKLibrary.addr2string(data.maker);
        if (key.equals("taker")) return BKLibrary.addr2string(data.taker);
        if (key.equals("maker_signature")) return string(data.makerSig);
        if (key.equals("taker_signature")) return string(data.takerSig);
        string memory val = BKLibrary.jsonValueByKey(data.jsonMap, key);
        if (val.length()==0) return "[missing]";
        return val;
    }

// /**
//  * Entry point to render a template section.
//  * a) Render the template by successive replacement of binding from the top down.
//  * If the section is more than 10K characters, then skip to the a new section, 
//  * if the the secionIndex requested is > current section.
//  * Within the section once the template is rendered, render any attributes.
//  * 
//  * Care has to be taken not split either binding tags or attribute tags that may appear at the end of the section.  So we take care not to split them, but instead to split before any such tag.
//  */
//     function getTemplateSection(
//         BKBindingCollection coll,
//         string memory attribs,
//         string memory template,https://meet.google.com/tya-xivb-gne
//         uint16 index
//     ) public view returns (string memory) {
//         Rendercycle cycle;
//         cycle = renderCycle(cycle);
//         while (!cycle.complete) {
//             cycle=renderCycle(cycle);
//         }
//         string memory templateText = cycle.sectionText;
//         //check for attribs that need replacing.
//         //are there any partial attribs over the boundary?
//         string memory attribs = BKString.findTemplateRefs(templateText, "#{");


//     }

//     struct RenderCycle {
//         uint256 startChar;
//         uint256 endChar;
//         uint16 sectionIndex;
//         string sectionText;
//         string extra;
//         bool clean;
//         bool complete;
//     }
//     //Called by render cycle.  Replaces tags within a sectionText until sectionText length limit is reached.  
//     function renderBindings(RenderCycle memory cycle) private view returns (RenderCycle) {
//         uint32 limit = RENDER_SECTION_LIMIT;
//         string memory text = cycle.sectionText;
//         string[] memory bindings = BKStrings.findTemplateRefs(text, "!{");
//         for(uint i; i<bindings.length; i++) {
//             if (text.length > limit) break;
//             string memory bindingName = bindings[i];
//             string memory templateText = BKBinding(
//                 coll.getAddress(bindingName)
//             ).meta().templateText;
//             text = BKStrings.replace(text, bindingName, templateText);
//             if (i==binding.bindings.length-1) {
//                 cycle.clean=true;
//             }
//         }
//         cycle.sectionText = text;
//         return;



//         }
//     }

//     function renderCycle(
//         BKBindingCollection coll,
//         RenderCycle cycle;
//     ) private pure returns (RenderCycle memory cycle) {
//         uint256 limit = RENDER_SECTION_LIMIT;
//         string memory extra = "";
//         renderBinding(coll, cycle);


//         if (renderText.length() > limit) {
//             (renderText, extra) = truncateRenderText(renderText);
//             cycle.complete=false;
//             cycle.clean = false;
//             cycle.extra = extra;
//             cycle.endChar = startChar + renderText.length() -1 ;
//             return cycle;
//         }
//         cycle.startChar = startChar;
//         string[] memory bindingTags = BKStrings.findTemplateRefs(
//             renderText,
//             "!{"
//         );
//         if (bindingTags.length == 0) {
//             cycle.endChar = renderText.length();
//             cycle.complete = true;
//             return cycle;
//         }
//         //if (bindingTags.length==0) return (0, 0, 0, true, true);
//     }

//     function truncateRenderText(string memory renderText)
//         private
//         pure
//         returns (string memory truncated, string memory extra)
//     {
//         uint256 limit = RENDER_SECTION_LIMIT;
//         if (renderText.length() <= limit) return (renderText, "");
//         string[] memory bindingTags = BKStrings.findTemplateRefs(
//             renderText,
//             "!{"
//         );
//         //possible that binding crosses boundary?
//         if (bindingTags.length > 0) {
//             //has bindings, and is long than 10k chars:
//             string memory lastbinding = bindingTags[bindingTags.length - 1];
//             uint32 lastbindingpos = renderText.findLastPos(
//                 bindingTags[bindingTags.length - 1]
//             );
//             //does binding cross boundary?
//             if (lastbindingpos + lastbinding.length() > limit) {
//                 //binding crosses limit remove it from the end.
//                 truncated = renderText.substring(0, int(uint(lastbindingpos)));
//                 extra = renderText.substring(limit + 1, 0);
//                 return (truncated, extra);
//             }
//         }
//         //no boundary crossing, so just trncate at limit.
//         truncated = renderText.substring(0, int256(limit - 1));
//         extra = renderText.substring(limit, 0);
//         return (truncated, extra);
//     }

    function selfDestruct() public {
        require(msg.sender == _owner);
        selfdestruct(payable(_owner));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;
import "./BKStrings.sol";
import "./BKEmbedRoot.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*BKEmbedded definitions */
enum QueryType {
    TokenId,
    DocId,
    Maker,
    Taker
}

struct FetchQuery {
    QueryType qryType;
    address target;
    uint id;  //either a TokenId or DocId   /
    uint start; //an index to start returning values.  0 is the first.
    uint count; //if length 0 return all, else return count
}

//SigningRcord is a struct used for permanent storage of signed agreements and contains the signature metadata,
//as well as reference to the Document record which contains the content of the content.
struct SigningRecord {
    uint32 sigId;  //The id of the signing record (key to the signingRecords map)
    uint32 docId;  //The docId representing the doc which this signature applies to
    address maker;  //The offering party of the agreement
    address taker;  //The accepting party of the agreement
    uint256 timestamp;  //The time at which the agreement which the most recent state change in signature status occurred.
    SigState makerSigState;  //Whether or not the maker has signed, or transferred, etc., the agreement
    SigState takerSigState;  //Whether or not the taker has signed, or transferred, etc., the agreement
    bytes makerSig;  //The digital signature of the agreement by the maker account.  
    bytes takerSig;  //The digital signature of the agreement by the taker account.
    uint tokenId;
    bytes32 hashProof;  //maker or taker signing the hashproof constitutes signature of the agreement.  
                        //The hashProof is calculagted as hash(templateDocHash, doc.jsonattribs, maker, taker);

}

//The document record contains all the data necessary to render a document other than the signing record data.abi
//The attribs map contains the standard attributes collection, source_contract, and metadata.
struct DocumentRecord {
    uint32 docId;
    uint tokenId;    //should not be zero unless there is only going to be one document id for the entire contract.
    uint256 timestamp; //when the document was first published.
    string jsonAttribs; //inclues all values of attributes and metadata, but excludes signing record attributes.
   // address maker;  //the party that will be the maker of each signingRecord with respect this docuemnt.
    address creator; //the address of the party creating the record (must be an authorizedCreator) document
   // bytes creatorSig; //signature of the jsonAttribs by creator.
}

/* @dev The SigningParam struct is the struct by clients to pass the parameters to create or sign an agreement */
struct SigningParams {  
    uint32 docId;
    address takerAddress;
    address makerAddress;
    bytes takerSignature; //signature of hash(attribValuesJSON and hash(document template))
    bytes makerSignature;
    uint tokenId; //can be derived from attribValues.
    //bytes32 hashProof; //A hash of the templateHash and jsonAttribsSigned.
    //attribValuesJSON are the "non-transactional" attributes, other than token_id which is included in the Json.
    string jsonAttribsSigned;  //the attribs from the doc, including everything but signatures.
}

/** @dev This struct can be called by takers once a signing doc is produced by a maker to do a fullrendder of the agreement to
        be signed. */
    struct TagRefMapData {
        uint32 sigId;
        uint tokenId;
        address maker;
        address taker;
        string jsonMap;
        string rootTemplate;
        bytes32 hashProof;
        bytes makerSig;
        bytes takerSig;
    }
     

/*END BKEMBEDDED definitions */






enum SolidityABITypes {
    Null,
    String, //1
    Boolean, //2
    Number, //3
    Address, //4
    BigNumber, //5
    Bytes32
}
//address constant BKOPY_PROTOCOL_OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;  //hardhat local
//address constant BKOPY_PROTOCOL_OWNER = 0x59F5B98D5b5fc01c8aE10238b93618053E62BE20; //Polygon Mumbai;
enum AttribCallType {
    SimpleFunction,
    IndexedByTokenId,
    IndexedBySender,
    IndexedByRecipient,
    KeyForStruct,
    JsonKeyForURL,
    Predefined
}
enum MetaIndexType {
    none,
    token_id,
    sender_address,
    recipient_address
}

enum SigState {
    Pending, //The party has not yet signed.;
    Complete, //The party has signed.
    Rejected, //At least one of the counterparties has rejected the agreement.
    Terminated, //The parties have agreed that a previously signed agreement is terminated. (Both maker and taker should be terminated.)
    Assigned   //One of theparties has assigned the benefit of the agreement to some other party.  As a result they are no longer
              //bound by the terms, nor entitled to its benefits.
}

struct BKAttrib {
    string functionName;
    string tagRef;
    AttribCallType callType;
    SolidityABITypes outputType;
    MetaIndexType metaIndexType;
    string metaKeyName;
}
struct DictionaryEntry {
    string key;
    string value;
}

struct SignaturePair {
    address sender;
    address recipient;
    uint256 index;
}
struct BindingMeta {
    string name;
    string version;
    uint8 section;
    string templateText;
    string plainText; //A short string describing the purpose of the binding.
    string author; //The author of the binding.
    bytes32 templateHash; //hash of template if it is a root template, otherwise 0.
}

// struct DocumentRecord {
//     uint256 id;
//     string template;  //template name.
//     uint256 tokenId;
//     uint256 timestamp;  //original publication time.
//     string attribsMap;  //json of the map.
//     bytes32 docHash; //hash templateHash and attrirbsMap json string;
// }

enum TagType {
    Null, //tag type not assigned
    BKBinding, //the tag represents a binding
    Contract, //the tag represent a contract attrib
    Token //the tag represents a token attribute
}

/** @author BKopy.io
    @dev Library and type definitions for BKopyEmbedded protocol;
*/
library BKLibrary {
    using ECDSA for bytes32;
    using BKStrings for string;
    string public constant BKVersion = "0.1.17";
    string public constant BKContractName = "BKLibrary";
    uint256 public constant MAX_INT = 2**256 - 1;
   
    //find the last position of the needle in self.
    function findLastPos(string memory self, string memory needle) public pure returns (uint32) {
        string memory  result = rfind(self, needle);
        uint32 pos =  uint32(bytes(result).length);
        pos = pos-uint32(bytes(needle).length);
        return pos;
    }
    /**
     * @dev returns the from the beginning of the string up to and including the needle string;
     */
    function rfind(string memory selfString, string memory needleString) public pure returns(string memory){
         return BKStrings.rFindString(selfString, needleString);
    }

    /**
     * @dev creates the predefined attributes representing transaction specific values.
     * Called by BKCollection setProjectName as part of the project initialization.
     *  Attribute names include
     *  sender, token_id recipient, owner, maker, taker, template, metadata, agreement_date,
     *  taker_signature, maker_signature, source_contract.
     */
    function addStandardAttributesToCollection(address bindingCollAddress)
        public
    {
        BKBindingCollection(bindingCollAddress).addAttrib(senderAttrib());
        BKBindingCollection(bindingCollAddress).addAttrib(tokenIdAttrib());
        BKBindingCollection(bindingCollAddress).addAttrib(recipientAttrib());
        BKBindingCollection(bindingCollAddress).addAttrib(ownerAttrib());
        BKBindingCollection(bindingCollAddress).addAttrib(makerAttrib());
        BKBindingCollection(bindingCollAddress).addAttrib(takerAttrib());
        BKBindingCollection(bindingCollAddress).addAttrib(metadataAttrib());
        BKBindingCollection(bindingCollAddress).addAttrib(
            agreementDateAttrib()
        );
        BKBindingCollection(bindingCollAddress).addAttrib(
            takerSignatureAttrib()
        );
        BKBindingCollection(bindingCollAddress).addAttrib(
            makerSignatureAttrib()
        );
        BKBindingCollection(bindingCollAddress).addAttrib(
            sourceContractAttrib()
        );
    }

    function senderAttrib() public pure returns (BKAttrib memory) {
        BKAttrib memory retval;
        retval.functionName = "NoOp";
        retval.tagRef = "sender";
        retval.callType = AttribCallType.Predefined;
        retval.outputType = SolidityABITypes.Address;
        retval.metaIndexType = MetaIndexType.none;
        retval.metaKeyName = "";
        return retval;
    }

    function tokenIdAttrib() public pure returns (BKAttrib memory) {
        BKAttrib memory retval;
        retval.functionName = "NoOp";
        retval.tagRef = "token_id";
        retval.callType = AttribCallType.Predefined;
        retval.outputType = SolidityABITypes.BigNumber;
        retval.metaIndexType = MetaIndexType.none;
        retval.metaKeyName = "";
        return retval;
    }

    function recipientAttrib() public pure returns (BKAttrib memory) {
        BKAttrib memory retval;
        retval.functionName = "NoOp";
        retval.tagRef = "recipient";
        retval.callType = AttribCallType.Predefined;
        retval.outputType = SolidityABITypes.Address;
        retval.metaIndexType = MetaIndexType.none;
        retval.metaKeyName = "";
        return retval;
    }

    function ownerAttrib() public pure returns (BKAttrib memory) {
        BKAttrib memory retval;
        retval.functionName = "NoOp";
        retval.tagRef = "owner";
        retval.callType = AttribCallType.Predefined;
        retval.outputType = SolidityABITypes.Address;
        retval.metaIndexType = MetaIndexType.none;
        retval.metaKeyName = "";
        return retval;
    }

    function makerAttrib() public pure returns (BKAttrib memory) {
        BKAttrib memory retval;
        retval.functionName = "NoOp";
        retval.tagRef = "maker";
        retval.callType = AttribCallType.Predefined;
        retval.outputType = SolidityABITypes.Address;
        retval.metaIndexType = MetaIndexType.none;
        retval.metaKeyName = "";
        return retval;
    }

    function takerAttrib() public pure returns (BKAttrib memory) {
        BKAttrib memory retval;
        retval.functionName = "NoOp";
        retval.tagRef = "taker";
        retval.callType = AttribCallType.Predefined;
        retval.outputType = SolidityABITypes.Address;
        retval.metaIndexType = MetaIndexType.none;
        retval.metaKeyName = "";
        return retval;
    }

    function templateAttrib() public pure returns (BKAttrib memory) {
        BKAttrib memory retval;
        retval.functionName = "NoOp";
        retval.tagRef = "template";
        retval.callType = AttribCallType.Predefined;
        retval.outputType = SolidityABITypes.Address;
        retval.metaIndexType = MetaIndexType.none;
        retval.metaKeyName = "";
        return retval;
    }

    function metadataAttrib() public pure returns (BKAttrib memory) {
        BKAttrib memory retval;
        retval.functionName = "NoOp";
        retval.tagRef = "metadata";
        retval.callType = AttribCallType.Predefined;
        retval.outputType = SolidityABITypes.String;
        retval.metaIndexType = MetaIndexType.none;
        retval.metaKeyName = "";
        return retval;
    }

    function agreementDateAttrib() public pure returns (BKAttrib memory) {
        BKAttrib memory retval;
        retval.functionName = "NoOp";
        retval.tagRef = "agreement_date";
        retval.callType = AttribCallType.Predefined;
        retval.outputType = SolidityABITypes.Number;
        retval.metaIndexType = MetaIndexType.none;
        retval.metaKeyName = "";
        return retval;
    }

    function takerSignatureAttrib() public pure returns (BKAttrib memory) {
        BKAttrib memory retval;
        retval.functionName = "NoOp";
        retval.tagRef = "taker_signature";
        retval.callType = AttribCallType.Predefined;
        retval.outputType = SolidityABITypes.String;
        retval.metaIndexType = MetaIndexType.none;
        retval.metaKeyName = "";
        return retval;
    }

    function makerSignatureAttrib() public pure returns (BKAttrib memory) {
        BKAttrib memory retval;
        retval.functionName = "NoOp";
        retval.tagRef = "maker_signature";
        retval.callType = AttribCallType.Predefined;
        retval.outputType = SolidityABITypes.String;
        retval.metaIndexType = MetaIndexType.none;
        retval.metaKeyName = "";
        return retval;
    }

    function sourceContractAttrib() public pure returns (BKAttrib memory) {
        BKAttrib memory retval;
        retval.functionName = "NoOp";
        retval.tagRef = "source_contract";
        retval.callType = AttribCallType.Predefined;
        retval.outputType = SolidityABITypes.Address;
        retval.metaIndexType = MetaIndexType.none;
        retval.metaKeyName = "";
        return retval;
    }

    function findEmbeddedBindings(string memory templateString)
        public 
        pure
        returns (string[] memory)
    {
        return BKStrings.findTemplateRefs(templateString, "!{");
    }

    function findEmbeddedAttributes(string memory templateString)  
        public pure returns(string[] memory) 
    {
        return BKStrings.findTemplateRefs(templateString, "#{");
    }
    

    /**
     * @dev Returns substring of str
     * @param str string the string to substring;
        * @param startIndex uint the start index;
        * @param endPos index :  if endIndex >= startIndex, endIndex is the character pos for the end of the substring;
                                   if endIndex < startIndex, it is treated as a negative offset from the end of the string.
     */   
    function substring(string memory str, uint startIndex, int endPos) public pure returns (string memory ) {
        uint endIndex;
        if (endPos == 0) {
            endIndex = length(str)-1;
        } else if (endPos > 0) {
            endIndex = uint(endPos);
        } else {
            endPos = endPos * -1;
            endIndex = (length(str)-1) - uint(endPos);
        }
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex+1);
        for(uint i = startIndex; i <= endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**Boolean replace tag format is ~{isSomething,The true value|The false value} 
        This function splits the tag into its component parts.
    */
    function parseBooleanReplace(string memory booleanReplaceTag)
        public
        pure
        returns (
            string memory attr,
            string memory trueVal,
            string memory falseVal
        )
    {
        string memory remaining;
        (attr, remaining) = splitAt(booleanReplaceTag, ",");
        (trueVal, falseVal) = splitAt(remaining, "|");
    }

    function replace(string memory source, string memory needle, string memory replacement) public view returns(string memory) {
         console.log("peperaoni", needle, replacement);
         console.log(length(replacement));
         console.log(length(needle));
         console.log(block.gaslimit);
         console.log(gasleft());
         string memory retval = BKStrings.replace(source, needle, replacement);
         console.log("finished", length(retval));
         return retval;
    }

    function splitAt(string memory source, string memory needle)
        public
        pure
        returns (string memory beforeIt, string memory afterIt)
    {
        (beforeIt, afterIt) = BKStrings.splitAt(source, needle);
    }

    function toLowerCase(string memory str)
        public
        pure
        returns (string memory)
    {
        return BKStrings.toLower(str);
    }

    function length(string memory s1) public pure returns (uint256) {
        return bytes(s1).length;
    }

    function equals(string memory s1, string memory s2)
        public
        pure
        returns (bool)
    {
        return BKStrings.eq(s1, s2);
    }

    function concat(string memory s1, string memory s2)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(s1, s2));
    }

    function isEmpty(string memory s1) public pure returns (bool) {
        if (bytes(s1).length == 0) return true;
        return false;
    }
    function startsWith(string memory s1, string memory prefix)
        public
        pure
        returns (bool)
    {
        return s1.startsWith(prefix);
    }

    function isSnakeCase(string memory s) public pure returns (bool) {
        return BKStrings.isSnakeCase(s);
    }

    function bytes2Address(bytes memory bys)
        public
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 32))
        }
    }

    function bytestoString(bytes memory data)
        public
        pure
        returns (string memory)
    {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function uint2str(uint256 _i)
        public
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function addr2string(address x) public pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return concat(("0x"),string(s));
    }

    function char(bytes1 b) public pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function bytesToBytes32(bytes memory b) private pure returns (bytes32) {
        bytes32 out;
        uint256 offset = 0;
        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function parseResult(SolidityABITypes typ_, bytes memory result)
        public
        pure
        returns (string memory)
    {
        string memory retval;

        if (typ_ == SolidityABITypes.Null) {
            revert("Type is null");
        }

        if (typ_ == SolidityABITypes.String) {           
            retval = string(result);
            return retval;
        }

        if (typ_ == SolidityABITypes.Boolean) {
            uint256 numval = bytesToUint(result);
            if (numval > 0) return "true";
            return "false";
        }

        if (
            typ_ == SolidityABITypes.Number ||
            typ_ == SolidityABITypes.BigNumber
        ) {
            uint256 numval = bytesToUint(result);
            retval = uint2str(numval);
            return retval;
        }

        if (typ_ == SolidityABITypes.Address) {
            address ad;
            ad = bytes2Address(result);
            retval = bytestoString(abi.encodePacked(ad));
            return retval;
        }

        if (typ_ == SolidityABITypes.Bytes32) {
            retval = bytestoString(abi.encodePacked(result));
            return retval;
        }
        revert("Unknown SolidityABITypes");
    }

    function stringToUint(string memory s) public pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            // c = b[i] was not needed
            if (uint(uint8(b[i])) >= 48 && uint(uint8(b[i])) <= 57) {
                result = result * 10 + (uint256(uint8(b[i])) - 48); // bytes and int are not compatible with the operator -.
            }
        }
        return result; // this was missing
    }

    function bytesToUint(bytes memory bs) public pure returns (uint256) {
        uint256 start = 0;
        require(bs.length >= start + 32, "slicing out of range");
        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }

    //contract signature functions;
    function checkContractSignature(
        bytes32 templateHash,
        string memory attributesJSON,
        address signer,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(attributesJSON, templateHash)
        );
        address sigAddress = extractAddress(signature, "", hash);
       
        return (signer == sigAddress);
    }

    function checkHash(string memory message, bytes32 hash)
        public
        pure
        returns (bool)
    {
        bytes32 messageHash = keccak256(abi.encodePacked(message));
        return messageHash == hash;
    }

    /**This function calculates the same hash as ethers.utils.solidicityKeccak256 . */
    function calcHash(string memory doc) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(doc));
        return hash;
    }

    function verifyStringSignature(
        address sender,
        string memory message,
        bytes memory signature
    ) public view returns (bool) {
        address result = sigAddressFromString(message, signature);
        if (sender == result) return true;
        console.log("verify failed {86GYRT}");
        console.log(sender);
        console.log(result);
        return false;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    function sigAddressFromHash(bytes32 message, bytes memory signature)
        public
        pure
        returns (address)
    {
        return extractAddress(signature, "", message);
    }

    function sigAddressFromString(string memory message, bytes memory signature)
        public
        pure
        returns (address)
    {
        return extractAddress(signature, message, 0);
    }

    function extractAddress(
        // https://blog.ricmoo.com/verifying-messages-in-solidity-50a94f82b2ca
        // Returns the address that signed a given string message

        bytes memory signature,
        string memory message,
        bytes32 hashedMessage
    ) private pure returns (address signer) {
        bool isHash = (hashedMessage > 0);
        if (isHash) {
            return hashedMessage.toEthSignedMessageHash().recover(signature);
        }

        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(signature);
        string memory header;
        bytes32 check;

        header = "\x19Ethereum Signed Message:\n000000";

        uint256 leng;
        uint256 lengthOffset;
        assembly {
            leng := mload(message)
            lengthOffset := add(header, 57)
        }
        if (isHash) leng = 32;
        require(leng <= 999999);
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = leng / divisor;
            if (digit == 0) {
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            lengthLength++;
            leng -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }

        check = keccak256(abi.encodePacked(header, message));

        return ecrecover(check, v, r, s);
    }

    /**
     * @dev extracts a value from json array formmatted as [["key","value"],["key","value"]]
     */
    function jsonValueByKey(string memory json, string memory key)
        public
        pure
        returns (string memory)
    {
        require(json.startsWith("[["), json.concat(" not a json string"));
        string memory qt = '"';
        string memory keyFind = qt.concat(key).concat('","');
        string memory pre;
        string memory post;
        (, post) = json.splitAt(keyFind);
        (pre, ) = post.splitAt('"');
        return pre;
    }

    

}

//SPDX-License-Identifier: apache2

 
pragma solidity 0.8.6;

import "hardhat/console.sol";


/**
  *@title BKStrings Library for BKEmbedded
  *@author BKopy.io
*/
library BKStrings {
    string public constant BKVersion = "0.1.17";
    string public constant contractName = "BKStrings";
    function eq(string memory s1, string memory s2) public pure returns (bool) {
        return (equals(toSlice(s1), toSlice(s2)));
    }
    
    function concat(string memory s1, string memory s2)
        public
        pure
        returns (string memory)
    {
        slice memory sl1 = toSlice(s1);
        slice memory sl2 = toSlice(s2);
        return concatSlice(sl1, sl2);
    }

    function concatArray(string[] memory ar1, string[] memory ar2)
        public
        pure
        returns (string[] memory)
    {
        string[] memory retval = new string[](ar1.length + ar2.length);
        for (uint256 i = 0; i < ar1.length; i++) {
            retval[i] = ar1[i];
        }
        for (uint256 i = 0; i < ar2.length; i++) {
            retval[i + ar1.length] = ar2[i];
        }
        return retval;
    }

    

     

    function splitAt(string memory source, string memory needle) public pure returns(string memory beforeIt, string memory afterIt) {
        slice memory src = toSlice(source);
        slice memory nedel = toSlice(needle);
        slice memory token;
        split(src, nedel, token);
        beforeIt = toString(token);
        afterIt = toString(src);
        return(beforeIt, afterIt);
    }

    function arrayContains(string[] memory source, string memory target)
        public
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < source.length; i++) {
            if (eq(source[i], target)) {
                return true;
            }
        }
        return false;
    }

    function extractRef(slice memory value, slice memory prefix)
        public
        pure
        returns (string memory, string memory)
    {
        slice memory source = value;
        slice memory left = split(source, toSlice("}"));
        slice memory right = source;
        slice memory name = find(left, prefix);
        name = beyond(name, prefix);
        return (toString(name), toString(right));
    }

    /** Finds template refs in a template string and returns them in an array. 
         @dev Note  it's possible that the return values contains duplicate values.
         @param templateString - the string to be searched from template tags.
         @param prefixString - the type of template tag to search for, i.e. for bindings, use "!{"
         @return the tag, without the opening prfix and brackets.
     */
    function findTemplateRefs(
        string memory templateString,
        string memory prefixString
    ) public pure returns (string[] memory) {
        uint256 retvalIndex = 0;
        slice memory template = toSlice(templateString);
        slice memory prefix = toSlice(prefixString);
        string memory binding;
        string memory remainderString;
        uint256 refCount = count(template, prefix);
        string[] memory retval = new string[](refCount);

        while (contains(template, prefix)) {
            (binding, remainderString) = extractRef(template, prefix);
            if (!empty(toSlice(binding))) {
                retval[retvalIndex] = binding;
                retvalIndex++;
                template = toSlice(remainderString);
            }
        }
        return retval;
    }

      



    /** Replaces non-overlapping occurences of target_ in  source_ with replacement_
        @param source_ The string in which to make replacements.
        @param target_ The string to be replaced
        @param replacement_ The string to replace all occurrences of target_ 
     */
    function replace(
        string memory source_,
        string memory target_,
        string memory replacement_
    ) public view returns (string memory) {
        uint256 startgas = gasleft();
        slice memory source = toSlice(source_);
        slice memory target = toSlice(target_);
        slice memory replacement = toSlice(replacement_);
        slice memory retval = copy(source);
        slice memory before;
        slice memory following;
        require(
            !(contains(replacement, target)),
            concat(toString(target), ": circular - replacement contains target")
        );
        uint256 found = count(source, target);
        if (found == 0) return source_;
        while (found > 0) {
            before = split(retval, target);
            following = retval;
            retval = toSlice(concatSlice(before, replacement));
            retval = toSlice(concatSlice(retval, following));
            found = count(retval, target);
        }
         console.log("gas used ", startgas - gasleft());
        return toString(retval);
       

    }

    function startsWith(string memory source, string memory prefix) public pure returns (bool) {
        slice memory src = toSlice(source);
        slice memory pre = toSlice(prefix);
        return startsWithSlice(src, pre);
    }

    function isSnakeCase(string memory source) public pure returns(bool) {
        if (!eq(source, toLower(source))) return false;
        slice memory src = toSlice(source);
        slice memory allValid = toSlice("abcdefghijklmnopqrstuvwzys01234567890_");
        for (uint i; i<len(src);i++) {
            slice memory rune;
            if (!contains(allValid,nextRune(src,rune))) return false;
        }
        return true;
        //are all chars valid?
    }

    
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
    /* 
     * @title String & slice utility library for Solidity contracts.
     * @author Nick Johnson <[email protected]>
     *
     * @dev Functionality in this library is largely implemented using an
     *      abstraction called a 'slice'. A slice represents a part of a string -
     *      anything from the entire string to a single character, or even no
     *      characters at all (a 0-length slice). Since a slice only has to specify
     *      an offset and a length, copying and manipulating slices is a lot less
     *      expensive than copying and manipulating the strings they reference.
     *
     *      To further reduce gas costs, most functions on slice that need to return
     *      a slice modify the original one instead of allocating a new one; for
     *      instance, `s.split(".")` will return the text up to the first '.',
     *      modifying s to only contain the remainder of the string after the '.'.
     *      In situations where you do not want to modify the original slice, you
     *      can make a copy first with `.copy()`, for example:
     *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
     *      Solidity has no memory management, it will result in allocating many
     *      short-lived slices that are later discarded.
     *
     *      Functions that return two slices come in two versions: a non-allocating
     *      version that takes the second slice as an argument, modifying it in
     *      place, and an allocating version that allocates and returns the second
     *      slice; see `nextRune` for example.
     *
     *      Functions that have to copy string data will return strings rather than
     *      slices; these can be cast back to slices for further processing if
     *      required.
     *
     *      For convenience, some functions are provided with non-modifying
     *      variants that create a new slice and return both; for instance,
     *      `s.splitNew('.')` leaves s unmodified, and returns two values
     *      corresponding to the left and right parts of the string.
     */
    struct slice {
        uint256 _len;
        uint256 _ptr;
    }

    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 leng
    ) private pure {
        // Copy word-length chunks while possible
        for (; leng >= 32; leng -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = type(uint256).max;
        if (leng > 0) {
            mask = 256**(32 - leng) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) public pure returns (slice memory) {
        uint256 ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) private pure returns (uint256) {
        uint256 ret;
        if (self == 0) return 0;
        if (uint256(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint256(self) / 0x100000000000000000000000000000000);
        }
        if (uint256(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint256(self) / 0x10000000000000000);
        }
        if (uint256(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint256(self) / 0x100000000);
        }
        if (uint256(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint256(self) / 0x10000);
        }
        if (uint256(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) private pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }
    
    
    function rFindString(string memory selfString, string memory needleString) public pure returns (string memory) {
        slice memory self = toSlice(selfString);
        slice memory needle = toSlice(needleString);
        slice memory result = rfind(self, needle);
        return toString(result);
    }


    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) private pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) public pure returns (string memory) {
        string memory ret = new string(self._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) private pure returns (uint256 l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint256 ptr = self._ptr - 31;
        uint256 end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) private pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other)
        private
        pure
        returns (int256)
    {
        uint256 shortest = self._len;
        if (other._len < self._len) shortest = other._len;

        uint256 selfptr = self._ptr;
        uint256 otherptr = other._ptr;
        for (uint256 idx = 0; idx < shortest; idx += 32) {
            uint256 a;
            uint256 b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = type(uint256).max; // 0xffff...
                if (shortest < 32) {
                    mask = ~(2**(8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint256 diff = (a & mask) - (b & mask);
                    if (diff != 0) return int256(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int256(self._len) - int256(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other)
        private
        pure
        returns (bool)
    {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune)
        private
        pure
        returns (slice memory)
    {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint256 l;
        uint256 b;
        // Load the first byte of the rune into the LSBs of b
        assembly {
            b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
        }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self)
        private
        pure
        returns (slice memory ret)
    {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) private pure returns (uint256 ret) {
        if (self._len == 0) {
            return 0;
        }

        uint256 word;
        uint256 length;
        uint256 divisor = 2**248;

        // Load the rune into the MSBs of b
        assembly {
            word := mload(mload(add(self, 32)))
        }
        uint256 b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint256 i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) private pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWithSlice(slice memory self, slice memory needle)
        private
        pure
        returns (bool)
    {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle)
        private
        pure
        returns (slice memory)
    {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle)
        private
        pure
        returns (bool)
    {
        if (self._len < needle._len) {
            return false;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle)
        private
        pure
        returns (slice memory)
    {
        if (self._len < needle._len) {
            return self;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr = selfptr;
        uint256 idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint256 end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr) return selfptr;
                    ptr--;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle)
        private
        pure
        returns (slice memory)
    {
        uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    function findPos(string memory self, string memory needle) public pure returns(uint16) {
        slice memory selfS = toSlice(self);
        uint slen = selfS._len;
        slice memory needleS = toSlice(needle);
        slice memory res = find(selfS, needleS);
        return uint16(slen - res._len);
    }

     /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle)
        private
        pure
        returns (slice memory)
    {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(
        slice memory self,
        slice memory needle,
        slice memory token
    ) private pure returns (slice memory) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle)
        private
        pure
        returns (slice memory token)
    {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(
        slice memory self,
        slice memory needle,
        slice memory token
    ) private pure returns (slice memory) {
        uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle)
        private
        pure
        returns (slice memory token)
    {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle)
        private
        pure
        returns (uint256 cnt)
    {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) +
            needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr =
                findPtr(
                    self._len - (ptr - self._ptr),
                    ptr,
                    needle._len,
                    needle._ptr
                ) +
                needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle)
        private
        pure
        returns (bool)
    {
        return
            rfindPtr(self._len, self._ptr, needle._len, needle._ptr) !=
            self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concatSlice(slice memory self, slice memory other)
        private
        pure
        returns (string memory)
    {
        string memory ret = new string(self._len + other._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }


    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts)
        private
        pure
        returns (string memory)
    {
        if (parts.length == 0) return "";

        uint256 length = self._len * (parts.length - 1);
        for (uint256 i = 0; i < parts.length; i++) length += parts[i]._len;

        string memory ret = new string(length);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        for (uint256 i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }

    
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./BKBinding.sol";

/**The contract creates Bindings */
contract BKBindingFactory {
    event NewBinding(address bindingAddress, address indexed collectionAddress);
    address private _owner;
    constructor() {
        _owner = msg.sender;
    }
    string public constant BKVersion = "0.1.17";
    string public constant contractName = "BKBindingFactory";


    function makeNewBinding(string memory name, string memory version, address collection, string memory collectionId_) public returns(BKBinding) {
        BKBinding binding = new BKBinding(name, version, collection, collectionId_);
        emit NewBinding(address(binding), collection);
        return binding;
    }



     

    
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./BKBindingCollection.sol";
import "hardhat/console.sol";

struct CustomerMeta {
    string name;
    address collectionOwner;
    address[] bindingCollections;
    bool enabled;
   
}

//address constant BKOPY_PROTOCOL_OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; //hardhat node local
address constant BKOPY_PROTOCOL_OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;  //hardhat local
//address constant BKOPY_PROTOCOL_OWNER = 0x59F5B98D5b5fc01c8aE10238b93618053E62BE20; //Polygon Mumbai;



/** @title Root contract for BKEmbeded Protocol 
 *  @author BKopy.io, 2022
 */
contract BKEmbedRoot {
    /**@dev For prevening duplicate customer names */ 
    mapping(string=>address) private customerNameMap; //"name" => customer address
    mapping (address=>CustomerMeta) private customerMetaMap;  //customer address => CustomerMeta
    mapping(address=>address) private custAddressByCollectionMap; //BKBindingCollectionAddress => collectionOwner;
    mapping(string=>address) private collectionIDMap; //collectionId => BKBindingCollectionAddress
    mapping(address => address[]) private delegates; //List of delgate address for a collection owner.  These delegates will have full control over the collection.
    mapping(address=>bool) private bkAdmin; //List of addresses that can act as protocol owner in "only owner" tests.
    address private _factoryAddress;   //These are common utility contracts for all BKCatalog implementations.
    address private _rendererAddress;
    address private _bkLibraryAddress;
    address private _bkStringsAddress;
    address[] private _customers;
    address private _bcollMakerAddress;
    address private _signingHelperAddress;
    address private protocolOwner;  //BKOPY_PROTOCOL_ADDRESS

    modifier onlyOwner() {    
        require(msg.sender == protocolOwner || bkAdmin[msg.sender], "onlyOwner modifier");
        _;
    }

    constructor() {  
        require(msg.sender == BKOPY_PROTOCOL_OWNER, "onlyProtocolOwner") ;
        protocolOwner = msg.sender;
        bkAdmin[protocolOwner] = true;
    }
     
    string public constant BKVersion = "0.1.17";
    string public constant contractName = "BKEmbedRoot";
    
    /**
        * @dev Returns the address of a BKopyCollection with the supplied id.  (A random sixChar alpha string);
     */
    function idToCollection(string memory id) public view returns(address) {
        require(collectionIDMap[id] != address(0), "idToCollection: id not found");
        return collectionIDMap[id];
    }
     

    /**Register a new collection produced by the BKopyCollectionMaker contract.
     */
    function registerCollection(address collectionOwner_, address bindingCollectionAddress, string memory id_) public {
        //console.log("starting new collection");
      
       customerMetaMap[collectionOwner_].bindingCollections.push(bindingCollectionAddress); 
        custAddressByCollectionMap[bindingCollectionAddress]=collectionOwner_;
        collectionIDMap[id_] = bindingCollectionAddress;
    }
   
     
    function setProtocolContracts( address factory, address renderer, address bklibrary, address bkstrings, address bcollFactory, address bkSigningHelper)
            public onlyOwner {
        _factoryAddress = factory;
        _rendererAddress = renderer;
        _bkLibraryAddress = bklibrary;
        _bkStringsAddress = bkstrings;
        _bcollMakerAddress = bcollFactory;
        _signingHelperAddress = bkSigningHelper;

    }

    /** returns BKBindingFactoryAdresss instance */
    function factoryAddress()  public view returns(address) {
        return _factoryAddress;
    }
    /** returns BKRendererAddress for instance */
    function rendererAddress()  public view returns(address) {
        return _rendererAddress;
    }

    /** return BKLibrary adress */
    function libraryAddress() public view returns(address) {
        return _bkLibraryAddress;
    }
    function bkStringsAddress() public view returns(address) {
        return _bkStringsAddress;
    }
    function bcollMakerAddress() public view returns(address) {
        return _bcollMakerAddress;
    }


    function getBindingCollAddress() public view returns(address) {
        return getBindingCollAddress(msg.sender);
    }
    function getBKSigningHelperAddress() public view returns(address) {
        return _signingHelperAddress;
    }

    

    function getBKBindingCollectionsList(address collectionOwner_) public view returns(address[] memory) {
        if(msg.sender != protocolOwner) {
          require(isCustomerRegistered(collectionOwner_), "customer not registered");       
        }
        CustomerMeta memory meta = customerMetaMap[collectionOwner_];
        return meta.bindingCollections;
    }


    /**Returns the last binding collection created by owner */
    function getBindingCollAddress(address collectionOwner_) public view returns(address) {
       
        CustomerMeta  memory meta = customerMetaMap[collectionOwner_];
        address[] memory collsArray = meta.bindingCollections;
        require(collsArray.length>0, "No collections for customer");
        uint index = uint(collsArray.length) -1;
        return collsArray[index];

    }


    /**Returns the address of the indexed binding collection owned by collectionOwner. */
    function getBindingCollAddress(address collectionOwner_, uint32 index_) public view returns(address) {
        CustomerMeta  memory meta = customerMetaMap[collectionOwner_];
        address[] memory collsArray = meta.bindingCollections;
        require(collsArray.length > uint(index_), "Index out of bounds");
        return collsArray[uint(index_)];
    }
  


    function collectionOwner(address collection) public  view returns(address) {
        address collOwner = custAddressByCollectionMap[collection];
        require(collOwner !=address(0), "no such collection");
        return collOwner;
    }
    
    /** A delegate is either the collection owner or a delegate created by the collection owner
        with grant delegate, or a BKopy admin */
    function isDelegate(address delegate,address collection) public view returns(bool) {
        if(bkAdmin[delegate]) return true;    
        if(delegate == collectionOwner(collection)) return true;       
        if(inArray(delegates[collection], delegate)) return true;
        return false;
    }

    /** Grantes a delegate who can manage the bidningCollection */
    function grantDelegate(address delegate, address collection ) public {
        require(msg.sender == collectionOwner(collection) || msg.sender==protocolOwner, "unauthorized");
        //don't push twice
        if (!isDelegate(delegate, collection)) {
            delegates[collection].push(delegate);
        }
    }

    /**Revokes the delegate */
    function revokeDelegate(address delegate, address collection) public {
        require(delegate != address(0), "delegate is address(0)");
        require(msg.sender == collectionOwner(collection) || msg.sender==protocolOwner, "unauthorized");
        deleteFromArray(delegates[collection], delegate);
    }

    //helpers

    //address array handling

    function inArray(address[] memory source, address needle) private pure returns(bool) {
        if (source.length==0) return false;
        for(uint i=0; i<source.length; i++) {
            if (needle==source[i]) return true;
        }
        return false;
    }
    function deleteFromArray(address[] storage source, address needle) private {
        if (!inArray(source, needle)) return; //nothing to delete
        if(source.length==1 && source[0]==needle) {
            source.pop();
            return;
        }
        for(uint i=0; i<source.length; i++) {
            if(source[i]==needle) {
                if(i<(source.length-1)) {  //check that item isn't last element
                  source[i]=source[source.length-1]; //swap deleted item with last element.
                }
                source.pop();
            }
        }
    }

    function registerCustomer(string memory name, address customerAddress) public  {
        
        require(bkAdmin[msg.sender], "onlyOwner meth");
        CustomerMeta memory meta;
        require(!(isCustomerRegistered(customerAddress)), "customer already registered.");
        meta.name = name;
        meta.collectionOwner = customerAddress;
        meta.enabled=true;
        customerMetaMap[customerAddress] = meta;
        customerNameMap[name]=customerAddress;
        _customers.push(customerAddress);
    }

    function getCustomer(address customerAddress) public view returns(CustomerMeta memory) {
      
        require(isCustomerRegistered(customerAddress), "no such customer");
 
        CustomerMeta memory meta = customerMetaMap[customerAddress];
        return meta;
    }

    function getCustomerName(address customerAddress) public view returns (string memory) {
      
        CustomerMeta storage meta = customerMetaMap[customerAddress];
        return meta.name;
    }

    function isCustomerRegistered(address customerAddress) public view returns(bool) {
        if (customerMetaMap[customerAddress].enabled) return true;
        return false;
   }


    function getCustomerList() public view onlyOwner returns (address[] memory) {
        return _customers;
    }

    function selfDestruct() public onlyOwner {
        selfdestruct(payable(protocolOwner));
    }
     
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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