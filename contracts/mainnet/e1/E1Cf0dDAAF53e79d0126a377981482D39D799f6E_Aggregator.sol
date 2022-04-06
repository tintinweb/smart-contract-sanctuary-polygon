/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC1155/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC1155/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC1155/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/token/ERC1155/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

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


// File contracts/Aggregator.sol


pragma solidity ^0.8.4;




contract Aggregator is ERC1155Holder{

    address private owner;          // contract address
    address private officialWallet; // official address
    uint256 transferFee;            // need to divide 10000

    struct NFT{
        string desc;
        uint256 price;
        uint256 lowerBound;
        uint256 upperBound;
        uint256 balance;
        uint nftType; // 0 for ERC721, 1 for ERC1155
        address nftAddr;
        address erc20Addr;
    }
    mapping(uint256 => NFT) private NFTs; // NFT name -> NFT
    

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address incomeAddress, uint256 fee) {
        owner = msg.sender;
        officialWallet = incomeAddress;
        transferFee = fee;
    }

    function createNFTs(
        uint256[] memory nid, 
        string[] memory desc, 
        uint256[] memory price, 
        uint256[] memory lowerBound, 
        uint256[] memory upperBound, 
        uint256[] memory balance, 
        uint[] memory nftType,
        address[] memory nftAddr,
        address[] memory erc20Addr) public onlyOwner{
        for (uint256 i = 0; i < nid.length; i++) {
            require(nftType[i] < 2, "nft type not support");
            NFTs[nid[i]] = NFT(desc[i], price[i], lowerBound[i], upperBound[i], balance[i], nftType[i], nftAddr[i], erc20Addr[i]);
        }
    }

    function increaseNFTs(
        uint256[] memory nid,
        uint256[] memory increasement) public onlyOwner{
        for (uint256 i = 0; i < nid.length; i++) {
            NFTs[nid[i]].balance += increasement[i];
        }
    }

    function getNFT(uint256 nid) public view returns (string memory, uint256, uint256, uint256, uint256, uint, address, address) {
        NFT memory nft = NFTs[nid];
        return (nft.desc, nft.price, nft.lowerBound, nft.upperBound, nft.balance, nft.nftType, nft.nftAddr, nft.erc20Addr);
    }

    function buyNFTs(address to, uint256[] memory nids, uint256[] memory amounts) public {
        require(nids.length > 0, "nft number == 0");
        uint256[] memory nfts = new uint256[](nids.length);
        uint256 sum;
        for (uint256 i = 0; i < nids.length; i++) {
            require(NFTs[nids[i]].balance >= amounts[i], "nft not enough");
            if (i < nids.length - 1) {
                require(NFTs[nids[i]].nftType == NFTs[nids[i+1]].nftType, "nft type should be same");
                require(NFTs[nids[i]].nftAddr == NFTs[nids[i+1]].nftAddr, "nft addr should be same");
                require(NFTs[nids[i]].erc20Addr == NFTs[nids[i+1]].erc20Addr, "erc20 addr should be same");
            }
            nfts[i] = nids[i];
            sum += NFTs[nids[i]].price * amounts[i];
        }

        if (NFTs[nids[0]].nftType == 0) {
            _transferNFT721(to, nfts, amounts);
        } else {
            _transferNFT1155(to, nfts, amounts);
        }

        _transferERC20(address(this), officialWallet, sum, NFTs[nids[0]].erc20Addr);

        return;
    }

    function transferERC20(address _to, uint256 amt, address erc20Addr) public onlyOwner {
        require(amt > 0);
        IERC20 erc20 = IERC20(erc20Addr);
        erc20.transfer(_to, amt);
    }

    function transferNFTs(address to, uint256[] memory nids) public onlyOwner {
        require(nids.length > 0, "len(nids) == 0");
        for (uint256 i = 0; i < nids.length; i++) {
            require(NFTs[nids[i]].balance > 0, "nft not enough");
            if (i < nids.length - 1) {
                require(NFTs[nids[i]].nftType == NFTs[nids[i+1]].nftType, "nft type should be same");
                require(NFTs[nids[i]].nftAddr == NFTs[nids[i+1]].nftAddr, "nft addr should be same");
                require(NFTs[nids[i]].erc20Addr == NFTs[nids[i+1]].erc20Addr, "erc20 addr should be same");
            }
        }

        if (NFTs[nids[0]].nftType == 0) {
            _transferAllNFT721(to, nids);
        } else {
            _transferAllNFT1155(to, nids);
        }
    }

    function _transferERC20(address _to, address _feeTo, uint256 price, address erc20Addr) internal {
        uint256 fee = price * transferFee / 10000;
        require(price - fee > 0);
        IERC20 erc20 = IERC20(erc20Addr);
        if (price - fee > 0) {
            erc20.transferFrom(msg.sender, _to, price - fee);
        }
        if (fee > 0) {
            erc20.transferFrom(msg.sender, _feeTo, fee);
        }
    }
 
     // only for the same nft address
    function _transferNFT721(address to, uint256[] memory nids, uint256[] memory amounts) internal {
        require(nids.length > 0, "len(nids) == 0");

        IERC721Enumerable erc721 = IERC721Enumerable(NFTs[nids[0]].nftAddr);
        uint256 total = erc721.balanceOf(address(this));
        require(total >= nids.length, "nft not enough");

        for (uint256 i = 0; i < nids.length; i++) {
            for(uint256 j = 0; j < total;) {
                uint256 tokenId = erc721.tokenOfOwnerByIndex(address(this), j);
                if (tokenId >= NFTs[nids[i]].lowerBound && tokenId <= NFTs[nids[i]].upperBound) {
                    erc721.transferFrom(address(this), to, tokenId);
                    NFTs[nids[i]].balance--;
                    amounts[i]--;
                    total--;
                    if (amounts[i] == 0) {
                        break;
                    }
                } else {
                    j++;
                }
            }
        }
    }

    // only for the same nft address
    function _transferNFT1155(address to, uint256[] memory nids, uint256[] memory amounts) internal {
        require(nids.length > 0, "len(nids) == 0");
        require(nids.length == amounts.length, "len(nids) != len(amounts)");
        uint256[] memory ids = new uint256[](nids.length);
        IERC1155 erc1155 = IERC1155(NFTs[nids[0]].nftAddr);
        for (uint256 i = 0; i < nids.length; i++) {
            require(NFTs[nids[i]].nftType == 1, "nft type is not erc1155");
            require(NFTs[nids[i]].balance >= amounts[i], "nft not enough");
            if (i < nids.length - 1) {
                require(NFTs[nids[i]].nftAddr == NFTs[nids[i+1]].nftAddr, "nft addr not same");
            }
            ids[i] = NFTs[nids[i]].lowerBound;
            NFTs[nids[i]].balance -= amounts[i];
        }
        bytes memory bs;
        erc1155.safeBatchTransferFrom(address(this), to, ids, amounts, bs);
    }

         // only for the same nft address
    function _transferAllNFT721(address to, uint256[] memory nids) internal {
        require(nids.length > 0, "len(nids) == 0");

        IERC721Enumerable erc721 = IERC721Enumerable(NFTs[nids[0]].nftAddr);
        uint256 total = erc721.balanceOf(address(this));

        while(total > 0) {
            uint256 tokenId = erc721.tokenOfOwnerByIndex(address(this), 0);
            erc721.transferFrom(address(this), to, tokenId);
            total--;
        }
    }

    function _transferAllNFT1155(address to, uint256[] memory nids) internal {
        require(nids.length > 0, "len(nids) == 0");
        uint256[] memory ids = new uint256[](nids.length);
        uint256[] memory amounts = new uint256[](nids.length);
        IERC1155 erc1155 = IERC1155(NFTs[nids[0]].nftAddr);
        for (uint256 i = 0; i < nids.length; i++) {
            require(NFTs[nids[i]].nftType == 1, "nft type is not erc1155");
            if (i < nids.length - 1) {
                require(NFTs[nids[i]].nftAddr == NFTs[nids[i+1]].nftAddr, "nft addr not same");
            }
            ids[i] = NFTs[nids[i]].lowerBound;
            amounts[i] = NFTs[nids[i]].balance;
            NFTs[nids[i]].balance = 0;
        }
        bytes memory bs;
        erc1155.safeBatchTransferFrom(address(this), to, ids, amounts, bs);
    }
}