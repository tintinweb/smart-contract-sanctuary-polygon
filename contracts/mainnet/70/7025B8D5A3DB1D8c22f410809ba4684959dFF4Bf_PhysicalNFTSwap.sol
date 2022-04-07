/**
 *Submitted for verification at polygonscan.com on 2022-04-07
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File contracts/IPhysicalNFTSwap.sol

// SPDX-License-Identifier: UNLICENSED
// Fleato PhysicalNFTSwap Contract Version 3

pragma solidity ^0.8.0;

/**
 * @dev Interface of the PhysicalNFTSwap
 */
interface IPhysicalNFTSwap {
    /** States
     * UNINITIALIZED - Default state - no record exists
     * SUSPENSE - Charge created. Initial payment has been made. Oracle havent verified the order conditions. NFT not transfered in
     * OK_TO_DELIVER - Oracle has validated the order and payment, taken ownership of the NFT, approved shipment of physical twin (if applicable)
     * OK_TO_PAYOUT - Oracle has validated delivery of physical twin (if applicable), NFT ownership unlocked for withdrawal by buyer, payment and withholding amounts unlocked for withdrawal by seller and adjudicator respectively
     * OK_TO_REFUND - Oracle has validated that it is not too late to revert the txn. NFT unlocked for withdrawal by seller, payment and withholding amounts unlocked for withdrawal by buyer
     * SCAVENGING - Something gone bad, Oracle is pulling the stuck assets (payments, withholdings, nfts) after waiting period.
     */
    enum ApprovedState {
        UNINITIALIZED,
        SUSPENSE,
        OK_TO_DELIVER,
        OK_TO_PAYOUT,
        OK_TO_REFUND,
        SCAVENGING
    }

    struct PaymentInput {
        bytes32 chargeCode;
        bytes32 productCode;
        address seller;
        address buyer;
        address paymentTokenContract;
        uint256 paymentAmount;
        address withholdingTokenContract;
        uint256 withholdingAmount;
        address adjudicator;
        address nftContract;
        uint256 nftTokenId;
    }

    /** @dev called by Oracle, after verifying identity and payment of buyer.
     * This action will transfer the ownership of NFT from seller to the Swap contract
     */
    function markOkToDeliver(bytes32 _chargeCode) external;

    /** @dev called by Oracle, after verifying delivery of physical NFT
     * This action will unlock the payment to be received by seller, and the NFT to be received by the buyer
     */
    function markOkToPayout(bytes32 _chargeCode) external;

    /** @dev called by seller if item is in ok to deliver status, or
     * called by Oracle if item is in suspense status, or after the cool of period of 6 months
     * This action will unlock the payment to be withdrawn by buyer, and NFT by seller
     */
    function markOkToRefund(bytes32 _chargeCode) external;

    /** @dev initiated by buyer against a charge code and payment code provided by Oracle via offband mechanism.
     * Payment is escrowed, and the NFT id is noted (ownership wont transfer yet)
     * Payment could be split into multiple tranches while the status is still in suspense
     */
    function pay(PaymentInput memory _input) external;

    /** @dev initiated by holder of the NFT against a charge code after Oracle has verified the payment. Could be the seller, or anyone else who has the custody.
     * Transfer NFT ownership from caller to this contract
     */
    function depositNFT(bytes32 _chargeCode) external;

    /** @dev withdraw payment once order moves to OkToPayout status
     * Anyone can call, money gets credited to seller
     */
    function withdrawPayment(bytes32 _chargeCode, uint256 _paymentCode)
        external
        returns (bool);

    /** @dev withdraw withholding once order moves to OkToPayout status
     * Witholding may include platform fees, taxes, and any royalties
     * Anyone can call, money gets credited to adjudicator
     */
    function withdrawWithholding(bytes32 _chargeCode, uint256 _paymentCode)
        external
        returns (bool);

    /** @dev withdraw NFT once order moves to OkToPayout status
     * Anyone can call, NFT transfers over to buyer
     */
    function withdrawNFT(bytes32 _chargeCode) external returns (bool);

    /** @dev Convenient method that calls withdrawPayment and withdrawWithholding for all payments and withdrawNFT as well.
     * Anyone can call.
     */
    function withdrawAll(bytes32 _chargeCode)
        external
        returns (bool);

    /** @dev Scavenge unclaimed payments and withholdings after 6 months period
     * Anyone can call, money moves to scavenger
     */
    function scavengePaymentAndWithholding(
        bytes32 _chargeCode,
        uint256 _paymentCode
    ) external returns (bool);

    /** @dev Scavenge unclaimed NFTs after 6 months period
     * Anyone can call, NFT moves to scavenger
     */
    function scavengeNFT(bytes32 _chargeCode) external returns (bool);


    /** @dev refund payment and withholdings once order moves to OkToRefund status
     * Anyone can call, money gets credited to buyer
     */
    function refundPaymentAndWithholding(
        bytes32 _chargeCode,
        uint256 _paymentCode
    ) external returns (bool);

    /** @dev refund NFT once order moves to OkToRefund status
     * Anyone can call, NFT transfers over to seller
     */
    function refundNFT(bytes32 _chargeCode) external returns (bool);

    /** @dev get charge status
     */
    function getChargeStatus(bytes32 _chargeCode)
        external
        view
        returns (
            bytes32 productCode,
            address seller,
            address buyer,
            ApprovedState approvedState,
            address adjudicator,
            uint256 paymentsLength,
            uint256 created
        );

    /** @dev get NFT Status
     */
    function getNFTStatus(bytes32 _chargeCode)
        external
        view
        returns (
            address nftContract,
            uint256 nftTokenId,
            bool nftInCustody,
            bool nftWithdrawn,
            bool nftRefunded,
            bool nftScavenged
        );

    /** @dev get payment status
     */
    function getPaymentStatus(bytes32 _chargeCode, uint256 _paymentCode)
        external
        view
        returns (
            address sender,
            address paymentTokenContract,
            uint256 paymentAmount,
            address withholdingTokenContract,
            uint256 withholdingAmount,
            bool paymentWithdrawn,
            bool withholdingWithdrawn,
            bool paymentAndWithholdingRefunded,
            bool paymentScavenged,
            bool withholdingScavenged,
            uint256 created
        );

    /** @dev Emitted when new charge is created
     */
    event NewCharge(bytes32 indexed chargeCode, bytes32 indexed productCode);
    event NewPayment(bytes32 indexed chargeCode, uint256 indexed paymentCode);
    event NewNFTDeposit(bytes32 indexed chargeCode, address indexed nftContract, uint256 indexed tokenId, address receipient);

    event PaymentWithdrawn(bytes32 indexed chargeCode, uint256 paymentCode);
    event WithholdingWithdrawn(bytes32 indexed chargeCode, uint256 paymentCode);
    event NFTWithdrawn(bytes32 indexed chargeCode, address indexed nftContract, uint256 indexed tokenId, address receipient);

    event PaymentAndWithholdingRefunded(bytes32 indexed chargeCode, uint256 paymentCode);
    event NFTRefunded(bytes32 indexed chargeCode, address indexed nftContract, uint256 indexed tokenId, address receipient);
    
    event OkToDeliver(bytes32 indexed chargeCode);
    event OkToPayout(bytes32 indexed chargeCode);
    event OkToRefund(bytes32 indexed chargeCode);
    
    event PaymentScavenged(bytes32 indexed chargeCode, uint256 paymentCode);
    event WithholdingScavenged(bytes32 indexed chargeCode, uint256 paymentCode);
    event NFTScavenged(bytes32 indexed chargeCode, address indexed nftContract, uint256 indexed tokenId, address receipient);
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

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


// File contracts/PhysicalNFTSwap.sol

pragma solidity ^0.8.0;







contract PhysicalNFTSwap is ERC721Holder, ERC1155Holder, IPhysicalNFTSwap {
    /** @dev Actors
     * sender will pay payment
     * sender will pay withholding
     * seller will transfer in nft
     *
     * buyer will get nft
     * seller will get payment
     * adjudicator will get withholding
     *
     * sender will get returned (refunded) payment
     * sender will get returned (refunded) withholding
     * seller will get returned (refunded) nft
     *
     * scavenger will get scavenged payment
     * scavenger will get scavenged withholding
     * scavenger will get scavenged nft
     */
    address scavenger;

    /** @dev One Contract per Sale / order
     */
    struct ChargeContract {
        bytes32 productCode;
        address nftContract;
        uint256 nftTokenId;
        address seller;
        address buyer;
        ApprovedState approvedState;
        address adjudicator;
        uint256 payments;
        uint256 created;
        bool nftInCustody;
        bool nftWithdrawn;
        bool nftRefunded;
        bool nftScavenged;
    }

    /** @dev One or more payment per Charge Contract
     */
    struct PaymentContract {
        address sender;
        address paymentTokenContract;
        uint256 paymentAmount;
        address withholdingTokenContract;
        uint256 withholdingAmount;
        bool paymentWithdrawn;
        bool withholdingWithdrawn;
        bool paymentAndWithholdingRefunded;
        bool paymentScavenged;
        bool withholdingScavenged;
        uint256 created;
    }

    modifier tokensTransferable(
        address _token,
        address _sender,
        uint256 _amount
    ) {
        if (_amount > 0) {
            require(
                IERC20(_token).allowance(_sender, address(this)) >= _amount,
                "no allowance"
            );
        }
        _;
    }

    modifier chargeExists(bytes32 _chargeCode) {
        require(hasCharge(_chargeCode), "wrong charge code");
        _;
    }

    modifier depositableTo(PaymentInput memory _input) {
        if (
            charges[_input.chargeCode].approvedState ==
            ApprovedState.UNINITIALIZED
        ) {
            //New charge, just accept; Would have ben nice to check if buyer can receive 1155 NFTs, it now need to be done by the oracle.
        } else {
            require(
                charges[_input.chargeCode].approvedState ==
                    ApprovedState.SUSPENSE,
                "wrong charge state"
            );
        }
        _;
    }

    modifier paymentWithdrawable(bytes32 _chargeCode, uint256 _paymentCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.OK_TO_PAYOUT,
            "wrong charge state"
        );
        require(
            payments[_chargeCode][_paymentCode].paymentWithdrawn == false &&
                payments[_chargeCode][_paymentCode].paymentAndWithholdingRefunded == false &&
                payments[_chargeCode][_paymentCode].paymentScavenged == false,
            "already withdrawn, refunded or scavenged"
        );
        _;
    }

    modifier nftWithdrawable(bytes32 _chargeCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.OK_TO_PAYOUT,
            "wrong charge state"
        );
        require(
            charges[_chargeCode].nftInCustody == true &&
                charges[_chargeCode].nftWithdrawn == false &&
                charges[_chargeCode].nftRefunded == false &&
                charges[_chargeCode].nftScavenged == false,
            "already withdrawn, refunded or scavenged"
        );
        _;
    }

    modifier withholdingWithdrawable(
        bytes32 _chargeCode,
        uint256 _paymentCode
    ) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.OK_TO_PAYOUT,
            "wrong charge state"
        );
        require(
            payments[_chargeCode][_paymentCode].withholdingWithdrawn == false &&
                payments[_chargeCode][_paymentCode].paymentAndWithholdingRefunded == false &&
                payments[_chargeCode][_paymentCode].withholdingScavenged ==
                false,
            "already withdrawn, refunded or scavenged"
        );
        _;
    }

    modifier paymentRefundable(bytes32 _chargeCode, uint256 _paymentCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.OK_TO_REFUND,
            "wrong charge state"
        );
        require(
            payments[_chargeCode][_paymentCode].paymentAndWithholdingRefunded == false &&
                payments[_chargeCode][_paymentCode].paymentWithdrawn == false &&
                payments[_chargeCode][_paymentCode].withholdingWithdrawn ==
                false &&
                payments[_chargeCode][_paymentCode].paymentScavenged == false,
            "already withdrawn, refunded or scavenged"
        );
        _;
    }

    modifier nftRefundable(bytes32 _chargeCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.OK_TO_REFUND,
            "wrong charge state"
        );
        require(
            charges[_chargeCode].nftWithdrawn == false &&
                charges[_chargeCode].nftRefunded == false &&
                charges[_chargeCode].nftScavenged == false,
            "already withdrawn, refunded or scavenged"
        );
        _;
    }

    modifier deliveryApprovable(bytes32 _chargeCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.SUSPENSE,
            "wrong charge state"
        );
        require(
            charges[_chargeCode].adjudicator == msg.sender,
            "not adjudicator"
        );
        _;
    }

    modifier nftDepositable(bytes32 _chargeCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.OK_TO_DELIVER,
            "wrong charge state"
        );
        require(
            charges[_chargeCode].nftContract != address(0),
            "wrong charge code"
        );
        require(
            charges[_chargeCode].nftInCustody == false,
            "asset already in custody"
        );
        _;
    }

    modifier payoutApprovable(bytes32 _chargeCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.OK_TO_DELIVER,
            "wrong charge state"
        );
        require(
            charges[_chargeCode].nftContract == address(0) || charges[_chargeCode].nftInCustody == true,
            "asset not in custody"
        );
        require(
            charges[_chargeCode].adjudicator == msg.sender,
            "not adjudicator"
        );
        _;
    }

    modifier refundApprovable(bytes32 _chargeCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.SUSPENSE ||
                charges[_chargeCode].approvedState ==
                ApprovedState.OK_TO_DELIVER,
            "wrong charge state"
        );
        require(
            (charges[_chargeCode].approvedState == ApprovedState.SUSPENSE &&
                charges[_chargeCode].adjudicator == msg.sender) ||
                (charges[_chargeCode].approvedState ==
                    ApprovedState.OK_TO_DELIVER &&
                    charges[_chargeCode].seller == msg.sender) ||
                (charges[_chargeCode].approvedState ==
                    ApprovedState.OK_TO_DELIVER &&
                    charges[_chargeCode].adjudicator == msg.sender &&
                    charges[_chargeCode].created + 7 days < block.timestamp),
            "not seller or adjudicator or wrong approvedState or cooling period not met"
        );
        _;
    }

    modifier paymentAndWithholdingScavengable(
        bytes32 _chargeCode,
        uint256 _paymentCode
    ) {
        require(
            payments[_chargeCode][_paymentCode].paymentAndWithholdingRefunded == false,
            "already refunded"
        );
        require(
            payments[_chargeCode][_paymentCode].paymentWithdrawn == false ||
                payments[_chargeCode][_paymentCode].withholdingWithdrawn ==
                false,
            "asset not in custody"
        );
        require(
            payments[_chargeCode][_paymentCode].paymentScavenged == false &&
                payments[_chargeCode][_paymentCode].withholdingScavenged ==
                false,
            "already scavenged"
        );
        require(
            payments[_chargeCode][_paymentCode].created + 180 days <
                block.timestamp,
            "not 180 days yet"
        );
        _;
    }

    modifier nftScavengable(bytes32 _chargeCode) {
        require(charges[_chargeCode].nftRefunded == false, "already refunded");
        require(
            charges[_chargeCode].nftInCustody == true &&
                charges[_chargeCode].nftWithdrawn == false,
            "asset not in custody"
        );
        require(
            charges[_chargeCode].nftScavenged == false,
            "already scavenged"
        );
        require(
            charges[_chargeCode].created + 180 days < block.timestamp,
            "not 180 days yet"
        );
        _;
    }

    mapping(bytes32 => ChargeContract) charges;
    mapping(bytes32 => mapping(uint256 => PaymentContract)) payments;

    function hasCharge(bytes32 _chargeCode)
        internal
        view
        returns (bool exists)
    {
        exists = (charges[_chargeCode].seller != address(0));
    }

    function _transferInNFT(bytes32 _chargeCode) internal {
        ChargeContract storage c = charges[_chargeCode];
        if (
            IERC1155(c.nftContract).supportsInterface(
                type(IERC1155).interfaceId
            )
        ) {
            IERC1155(c.nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                c.nftTokenId,
                1,
                abi.encodePacked(_chargeCode)
            );
            c.nftInCustody = true;
        } else if (
            IERC721(c.nftContract).supportsInterface(type(IERC721).interfaceId)
        ) {
            IERC721(c.nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                c.nftTokenId
            );
            c.nftInCustody = true;
        }
    }

    function _transferOutNFTIfInCustody(bytes32 _chargeCode, address _receiver)
        internal
        returns (bool)
    {
        ChargeContract storage c = charges[_chargeCode];
        if (c.nftInCustody) {
            if (
                IERC1155(c.nftContract).supportsInterface(
                    type(IERC1155).interfaceId
                )
            ) {
                IERC1155(c.nftContract).safeTransferFrom(
                    address(this),
                    _receiver,
                    c.nftTokenId,
                    1,
                    abi.encodePacked(_chargeCode)
                );
                c.nftInCustody = false;
                return true;
            } else if (
                IERC721(c.nftContract).supportsInterface(
                    type(IERC721).interfaceId
                )
            ) {
                IERC721(c.nftContract).safeTransferFrom(
                    address(this),
                    _receiver,
                    c.nftTokenId
                );
                c.nftInCustody = false;
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    constructor(address _scavenger) {
        scavenger = _scavenger;
    }

    function markOkToDeliver(bytes32 _chargeCode)
        external
        virtual
        override
        deliveryApprovable(_chargeCode)
    {
        charges[_chargeCode].approvedState = ApprovedState.OK_TO_DELIVER;
        emit OkToDeliver(_chargeCode);
    }

    function markOkToPayout(bytes32 _chargeCode)
        external
        virtual
        override
        payoutApprovable(_chargeCode)
    {
        ChargeContract storage c = charges[_chargeCode];
        c.approvedState = ApprovedState.OK_TO_PAYOUT;
        emit OkToPayout(_chargeCode);
    }

    function markOkToRefund(bytes32 _chargeCode)
        external
        virtual
        override
        refundApprovable(_chargeCode)
    {
        ChargeContract storage c = charges[_chargeCode];
        c.approvedState = ApprovedState.OK_TO_REFUND;
        emit OkToRefund(_chargeCode);
    }

    /** @dev initiated by holder of the NFT against a charge code after Oracle has verified the payment. Could be the seller, or anyone else who has the custody.
     * Transfer NFT ownership from caller to this contract
     */
    function depositNFT(bytes32 _chargeCode)
        external
        virtual
        override
        nftDepositable(_chargeCode)
    {
        ChargeContract storage c = charges[_chargeCode];
        _transferInNFT(_chargeCode);
        emit NewNFTDeposit(_chargeCode, c.nftContract, c.nftTokenId,address(this));
    }

    /**
     * @dev Accepts payment
     * If this is the first payment for the charge code, nftContract, nftTokenId, seller, adjudicator will be honored.
     * If this is a subsequent payment, above fields will be ignored.
     */
    function pay(PaymentInput memory _input)
        external
        virtual
        override
        tokensTransferable(
            _input.paymentTokenContract,
            msg.sender,
            _input.paymentAmount
        )
        tokensTransferable(
            _input.withholdingTokenContract,
            msg.sender,
            _input.withholdingAmount
        )
        depositableTo(_input)
    {
        // Debit the payment
        if (
            !IERC20(_input.paymentTokenContract).transferFrom(
                msg.sender,
                address(this),
                _input.paymentAmount
            )
        ) revert("payment transfer from sender to smartcontract failed");

        // Debit the withholding
        if (
            !IERC20(_input.withholdingTokenContract).transferFrom(
                msg.sender,
                address(this),
                _input.withholdingAmount
            )
        ) revert("withholding transfer from sender to smartcontract failed");

        if (hasCharge(_input.chargeCode)) {
            require(
                charges[_input.chargeCode].seller == _input.seller &&
                    charges[_input.chargeCode].nftContract ==
                    _input.nftContract &&
                    charges[_input.chargeCode].nftTokenId ==
                    _input.nftTokenId &&
                    charges[_input.chargeCode].buyer == _input.buyer &&
                    charges[_input.chargeCode].adjudicator ==
                    _input.adjudicator,
                "charge dont match"
            );
            charges[_input.chargeCode].payments =
                charges[_input.chargeCode].payments +
                1;
        } else {
            if (_input.nftContract != address(0)) {
                if (
                    IERC1155(_input.nftContract).supportsInterface(
                        type(IERC1155).interfaceId
                    )
                ) {
                    require(
                        IERC1155(_input.nftContract).balanceOf(
                            _input.seller,
                            _input.nftTokenId
                        ) >
                            0 &&
                            IERC1155(_input.nftContract).isApprovedForAll(
                                _input.seller,
                                address(this)
                            ),
                        "not approved for sale"
                    );
                } else if (
                    IERC721(_input.nftContract).supportsInterface(
                        type(IERC721).interfaceId
                    )
                ) {
                    require(
                        IERC721(_input.nftContract).ownerOf(
                            _input.nftTokenId
                        ) ==
                            _input.seller &&
                            IERC721(_input.nftContract).isApprovedForAll(
                                _input.seller,
                                address(this)
                            ),
                        "not approved for sale"
                    );
                }
            }
            charges[_input.chargeCode] = ChargeContract(
                _input.productCode,
                _input.nftContract,
                _input.nftTokenId,
                _input.seller,
                _input.buyer,
                ApprovedState.SUSPENSE,
                _input.adjudicator,
                0,
                block.timestamp,
                false,
                false,
                false,
                false
            );
            emit NewCharge(_input.chargeCode, _input.productCode);
        }

        payments[_input.chargeCode][
            charges[_input.chargeCode].payments
        ] = PaymentContract(
            msg.sender,
            _input.paymentTokenContract,
            _input.paymentAmount,
            _input.withholdingTokenContract,
            _input.withholdingAmount,
            false,
            false,
            false,
            false,
            false,
            block.timestamp
        );
        emit NewPayment(_input.chargeCode, charges[_input.chargeCode].payments);
    }

    function withdrawPayment(bytes32 _chargeCode, uint256 _paymentCode)
        public
        virtual
        override
        chargeExists(_chargeCode)
        paymentWithdrawable(_chargeCode, _paymentCode)
        returns (bool)
    {
        ChargeContract storage c = charges[_chargeCode];
        PaymentContract storage p = payments[_chargeCode][_paymentCode];
        p.paymentWithdrawn = true;
        IERC20(p.paymentTokenContract).transfer(c.seller, p.paymentAmount);
        emit PaymentWithdrawn(_chargeCode, _paymentCode);
        return true;
    }

    function withdrawWithholding(bytes32 _chargeCode, uint256 _paymentCode)
        public
        virtual
        override
        chargeExists(_chargeCode)
        withholdingWithdrawable(_chargeCode, _paymentCode)
        returns (bool)
    {
        ChargeContract storage c = charges[_chargeCode];
        PaymentContract storage p = payments[_chargeCode][_paymentCode];
        p.withholdingWithdrawn = true;
        IERC20(p.withholdingTokenContract).transfer(
            c.adjudicator,
            p.withholdingAmount
        );
        emit WithholdingWithdrawn(_chargeCode, _paymentCode);
        return true;
    }

    function withdrawNFT(bytes32 _chargeCode)
        public
        virtual
        override
        chargeExists(_chargeCode)
        nftWithdrawable(_chargeCode)
        returns (bool)
    {
        ChargeContract storage c = charges[_chargeCode];
        if (_transferOutNFTIfInCustody(_chargeCode, c.buyer)) {
            c.nftWithdrawn = true;
            emit NFTWithdrawn(_chargeCode, c.nftContract, c.nftTokenId, c.buyer);
            return true;
        } else {
            return false;
        }
    }

    function withdrawAll(bytes32 _chargeCode)
        external
        virtual
        override
        returns (bool)
    {
        ChargeContract storage c = charges[_chargeCode];
        for (uint256 i = 0; i <= c.payments; i++) {
            withdrawPayment(_chargeCode, i);
            withdrawWithholding(_chargeCode, i);
        }
        withdrawNFT(_chargeCode);
        return true;
    }

    //For cases when buyer or seller has lost their key and their funds locked.
    function scavengePaymentAndWithholding(
        bytes32 _chargeCode,
        uint256 _paymentCode
    )
        external
        virtual
        override
        paymentAndWithholdingScavengable(_chargeCode, _paymentCode)
        returns (bool)
    {
        ChargeContract storage c = charges[_chargeCode];
        c.approvedState = ApprovedState.SCAVENGING;

        PaymentContract storage p = payments[_chargeCode][_paymentCode];

        if (payments[_chargeCode][_paymentCode].paymentWithdrawn == false) {
            IERC20(p.paymentTokenContract).transfer(scavenger, p.paymentAmount);
            p.paymentScavenged = true;
            emit PaymentScavenged(_chargeCode, _paymentCode);
        }

        if (payments[_chargeCode][_paymentCode].withholdingWithdrawn == false) {
            IERC20(p.withholdingTokenContract).transfer(
                scavenger,
                p.withholdingAmount
            );
            p.withholdingScavenged = true;
            emit WithholdingScavenged(_chargeCode, _paymentCode);
        }
        return true;
    }

    function scavengeNFT(bytes32 _chargeCode)
        external
        virtual
        override
        nftScavengable(_chargeCode)
        returns (bool)
    {
        ChargeContract storage c = charges[_chargeCode];
        c.approvedState = ApprovedState.SCAVENGING;
        if (_transferOutNFTIfInCustody(_chargeCode, scavenger)) {
            c.nftScavenged = true;
            emit NFTScavenged(_chargeCode, c.nftContract, c.nftTokenId, scavenger);
            return true;
        } else {
            return false;
        }
    }

    function refundPaymentAndWithholding(
        bytes32 _chargeCode,
        uint256 _paymentCode
    )
        external
        virtual
        override
        chargeExists(_chargeCode)
        paymentRefundable(_chargeCode, _paymentCode)
        returns (bool)
    {
        PaymentContract storage p = payments[_chargeCode][_paymentCode];
        p.paymentAndWithholdingRefunded = true;
        IERC20(p.paymentTokenContract).transfer(p.sender, p.paymentAmount);
        IERC20(p.withholdingTokenContract).transfer(
            p.sender,
            p.withholdingAmount
        );
        emit PaymentAndWithholdingRefunded(_chargeCode, _paymentCode);
        return true;
    }

    function refundNFT(bytes32 _chargeCode)
        external
        virtual
        override
        chargeExists(_chargeCode)
        nftRefundable(_chargeCode)
        returns (bool)
    {
        ChargeContract storage c = charges[_chargeCode];
        if (_transferOutNFTIfInCustody(_chargeCode, c.seller)) {
            c.nftRefunded = true;
        }
        emit NFTRefunded(_chargeCode, c.nftContract, c.nftTokenId, c.seller);
        return true;
    }

    function getChargeStatus(bytes32 _chargeCode)
        public
        view
        virtual
        override
        returns (
            bytes32 productCode,
            address seller,
            address buyer,
            ApprovedState approvedState,
            address adjudicator,
            uint256 paymentsLength,
            uint256 created
        )
    {
        ChargeContract storage c = charges[_chargeCode];
        return (
            c.productCode,
            c.seller,
            c.buyer,
            c.approvedState,
            c.adjudicator,
            c.payments + 1,
            c.created
        );
    }

    function getNFTStatus(bytes32 _chargeCode)
        public
        view
        virtual
        override
        returns (
            address nftContract,
            uint256 nftTokenId,
            bool nftInCustody,
            bool nftWithdrawn,
            bool nftRefunded,
            bool nftScavenged
        )
    {
        ChargeContract storage c = charges[_chargeCode];
        return (
            c.nftContract,
            c.nftTokenId,
            c.nftInCustody,
            c.nftWithdrawn,
            c.nftRefunded,
            c.nftScavenged
        );
    }

    function getPaymentStatus(bytes32 _chargeCode, uint256 _paymentCode)
        public
        view
        virtual
        override
        returns (
            address sender,
            address paymentTokenContract,
            uint256 paymentAmount,
            address withholdingTokenContract,
            uint256 withholdingAmount,
            bool paymentWithdrawn,
            bool withholdingWithdrawn,
            bool paymentAndWithholdingRefunded,
            bool paymentScavenged,
            bool withholdingScavenged,
            uint256 created
        )
    {
        PaymentContract storage p = payments[_chargeCode][_paymentCode];
        return (
            p.sender,
            p.paymentTokenContract,
            p.paymentAmount,
            p.withholdingTokenContract,
            p.withholdingAmount,
            p.paymentWithdrawn,
            p.withholdingWithdrawn,
            p.paymentAndWithholdingRefunded,
            p.paymentScavenged,
            p.withholdingScavenged,
            p.created
        );
    }
}