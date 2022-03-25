/**
 *Submitted for verification at polygonscan.com on 2022-03-25
*/

// File: contracts/gorilla/ISIMBundleStore.sol



pragma solidity ^0.8.0;

interface ISIMBundleStore {

    function getProductListingCount() external view returns (uint256);
    function getProduct(uint256 listingIndex) external view returns (address productAddress,
                                                                        string memory imageURI,
                                                                        string memory title, 
                                                                        string memory desc,
                                                                        uint256 price);

    
}
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/IERC721Metadata.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/gorilla/SIMBundleReader.sol



pragma solidity ^0.8.0;




contract SIMBundleReader {

    ISIMBundleStore private _store;
  
    constructor(address storeAddress) {
        _store = ISIMBundleStore(storeAddress);
    }

    function balanceOf(address owner) public view virtual returns (uint256[] memory balances) {
        require(owner != address(0), "SIMBundleReader: balance query for the zero address");

        uint256 size = _store.getProductListingCount();
        balances = new uint256[](size);


        for (uint i = 0; i < size; i++) {
            (address _productAddress, , , , ) = _store.getProduct(i);
            IERC721Enumerable _product = IERC721Enumerable(_productAddress);
            uint256 balance = _product.balanceOf(owner);
            balances[i] = balance;
        }

        return balances;
    }

    function tokenURIsOfOwner(address owner) external view returns (string[][] memory uris) {
        require(owner != address(0), "SIMBundleReader: token URIs query for the zero address");

        uint256 size = _store.getProductListingCount();
        uris = new string[][](size);


        for (uint i = 0; i < size; i++) {
            (address _productAddress, , , , ) = _store.getProduct(i);
            IERC721Enumerable _product = IERC721Enumerable(_productAddress);
            IERC721Metadata _productMetadata = IERC721Metadata(_productAddress);
            uint256 balance = _product.balanceOf(owner);
            
            uris[i] = new string[](balance);
            for (uint j = 0; j < balance; j++) { 
                uint256 tokenId = _product.tokenOfOwnerByIndex(owner, j);
                uris[i][j] = _productMetadata.tokenURI(tokenId);
            }

        }

        return uris;
    }

    function tokenIdsOfOwner(address owner) external view returns (uint256[][] memory tokenIds) {
        require(owner != address(0), "SIMBundleReader: token ids query for the zero address");

        uint256 size = _store.getProductListingCount();
        tokenIds = new uint256[][](size);


        for (uint i = 0; i < size; i++) {
            (address _productAddress, , , , ) = _store.getProduct(i);
            IERC721Enumerable _product = IERC721Enumerable(_productAddress);
            uint256 balance = _product.balanceOf(owner);
            
            tokenIds[i] = new uint256[](balance);
            for (uint j = 0; j < balance; j++) { 
                uint256 tokenId = _product.tokenOfOwnerByIndex(owner, j);
                tokenIds[i][j] = tokenId;
            }

        }

        return tokenIds;
    }


    function summaryForOwner(address owner) external view returns (string[][] memory uris, uint256[][] memory tokenIds) {
        require(owner != address(0), "SIMBundleReader: summary query for the zero address");

        uint256 size = _store.getProductListingCount();
        uris = new string[][](size);
        tokenIds = new uint256[][](size);


        for (uint i = 0; i < size; i++) {
            (address _productAddress, , , , ) = _store.getProduct(i);
            IERC721Enumerable _product = IERC721Enumerable(_productAddress);
            IERC721Metadata _productMetadata = IERC721Metadata(_productAddress);
            uint256 balance = _product.balanceOf(owner);
            
            uris[i] = new string[](balance);
            tokenIds[i] = new uint256[](balance);

            for (uint j = 0; j < balance; j++) { 
                uint256 tokenId = _product.tokenOfOwnerByIndex(owner, j);
                tokenIds[i][j] = tokenId;
                uris[i][j] = _productMetadata.tokenURI(tokenId);
            }

        }
    }
}