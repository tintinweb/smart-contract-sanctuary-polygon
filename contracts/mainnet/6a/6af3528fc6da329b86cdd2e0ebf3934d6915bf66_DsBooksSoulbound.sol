/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface BSOContract {
    function mint(address account) external;
    function tokensOf(address account) external returns (uint256);
}

contract DsBooksSoulbound {

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Maping from token ID to CID
    mapping(uint256 => string) private _cids;

    // Maping from address to tokens IDs
    mapping(address => uint[]) private _ownedTokens;

    uint256 private _mintedBooks;

    address public admin;
    address BSOContractAddress;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor() {
        _name = unicode"Crónicas de un marinero desahuciado NFT";
        _symbol =  "CMDNFT";

        _mintedBooks = 0;

        admin = msg.sender;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _cids[tokenId])) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "ipfs://";
    }

    function tokensOf(address owner) public view virtual returns (uint[] memory) {
        return _ownedTokens[owner];        
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "invalid token ID");
        return owner;
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
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
    function mint(address to, string memory cid) public virtual payable {
        require(msg.value == 0.1 ether, "0.1 matic is required to mint a book");
        _mint(to, cid);
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
    function _mint(address to, string memory cid) internal virtual {
        require(to != address(0), "mint to the zero address");

        uint256 tokenId = _mintedBooks + 1;

        require(!_exists(tokenId), "token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "token already minted");

        _owners[tokenId] = to;
        _cids[tokenId] = cid;

        _ownedTokens[to].push(tokenId);

        _mintedBooks++;     

        uint256 bsoMinted = BSOContract(BSOContractAddress).tokensOf(to);

        if(bsoMinted == 0){
            BSOContract(BSOContractAddress).mint(to);
        }

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    function mintedBooks() public view virtual returns (uint256){
        return _mintedBooks;
    }

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "only owner can burn it");

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ownerOf(tokenId);

        delete _owners[tokenId];
        delete _cids[tokenId];

        uint tokenIndex;
        for (uint256 index = 0; index < _ownedTokens[owner].length; index++) {
            if(_ownedTokens[owner][index] == tokenId){
                tokenIndex = index;
                break;
            }
        }
        
        removeTokenFromOwnedTokens(tokenIndex, owner);
        
        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    function removeTokenFromOwnedTokens(uint index, address owner) internal {
        if (index >= _ownedTokens[owner].length) return;

        for (uint i = index; i<_ownedTokens[owner].length-1; i++){
            _ownedTokens[owner][i] = _ownedTokens[owner][i+1];
        }
        delete _ownedTokens[owner][_ownedTokens[owner].length-1];
        _ownedTokens[owner].pop();
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "invalid token ID");
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {

    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    function setBSOContractAddress(address contractAddress) public {
        require(msg.sender == admin, "only admin can set BSO contract address");
        require(BSOContractAddress == address(0) , "contract address already set");
        BSOContractAddress = contractAddress;
    }  

    function withdrawPayments(address payable payee) public virtual {
         require(msg.sender == admin, "only admin can withdraw payments");
         payee.transfer(address(this).balance);
    }
}