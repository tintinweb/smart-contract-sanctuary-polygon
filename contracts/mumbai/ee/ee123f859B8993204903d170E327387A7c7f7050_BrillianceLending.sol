// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;


import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";


contract BrillianceLending {

    enum AssetType{ERC1155, ERC721}

    event Lend(uint256 loanId, address nftAddress, uint256 tokenId, uint256 assetPrice, uint256 platformFee);

    event LoanRepayment(uint256 loanId, address nftAddress, uint256 tokenId, uint256 interestFee, uint256 loanAmount); 

    event LoanOverdued(uint256 loanId, address nftAddress, uint256 tokenId);

    address public owner;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    uint256 public totalNumLoans;

    uint256 public totalActiveLoans;

    uint256 public sellerFee = 50;

    uint256 public buyerFee = 50;

    mapping(uint256 => LoanDetail) public loans;
    mapping(uint256 => bool) public loanIdStatus;
    mapping(uint256 => bool) public loanRepaidOrLiquidated;

    mapping(uint256 => bool) private usedNonce;

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;        
    }

    struct Order {
        address borrower;
        address lender;
        address erc20Address;
        address nftAddress;
        AssetType nftType;
        uint256 unitPrice;
        uint256 amount;
        uint256 tokenId;
        uint256 qty;
        uint256 loanDuration;
        uint256 interestRateDuration;
    }

    struct LoanDetail {
        uint256 loanId;
        address nftAddress;
        AssetType nftType;
        uint256 tokenId;
        address borrower;
        address lender;
        uint256 loanPrincipalAmount;
        uint256 loanRepaymentAmount;
        uint256 loanStartTime;
        uint256 loanDuration;
        address loanERC20Address;
        uint256 qty;
        uint256 loanInterestForDuration;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: owner sign verification failed");
        _;
    }

    function getSigner(bytes32 hash, Sign memory sign) internal pure returns(address) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s); 
    }

    function verifyLenderSign( address lender, address borrower, address nftAddress, uint256 tokenId, uint256 amount, uint256 qty, Sign memory sign) internal view {
        bytes32 hash = keccak256(abi.encodePacked(this, lender, borrower, tokenId, nftAddress, amount, qty, sign.nonce));
        require(lender == getSigner(hash, sign), "lender sign verification failed");
    }

    function verifySign(uint256 tokenId, address caller, Sign memory sign) internal view {
        bytes32 hash = keccak256(abi.encodePacked(this, caller, tokenId, sign.nonce));
        require(owner == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s), "Owner sign verification failed");
    }

    function inititateLend (Order memory order, Sign memory sign) external returns(bool){
        require(!usedNonce[sign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        verifyLenderSign(order.lender, msg.sender, order.nftAddress, order.tokenId, order.amount, order.qty, sign);

        totalNumLoans += 1;
        order.loanDuration = order.loanDuration * 1 days;

        uint price = order.amount * 1000 / (1000 + buyerFee);
        require(order.amount >= price, "Subtraction overflow");
        uint _buyerFee = order.amount - price;
        uint _sellerFee = price * sellerFee / 1000;
        uint256 platformFee = _buyerFee + _sellerFee;

        require(price >= _sellerFee, "Subtraction overflow");
        uint256 assetPrice = price - _sellerFee;

        uint256 interest = platformFee + (order.amount *  order.interestRateDuration / 1000);

        uint256 id = totalNumLoans;

        loans[id] = LoanDetail(
            id,
            order.nftAddress,
            order.nftType,
            order.tokenId,
            msg.sender,
            order.lender,
            order.unitPrice,
            order.unitPrice + interest,
            block.timestamp,
            order.loanDuration,
            order.erc20Address,
            order.qty,
            order.interestRateDuration            
        );

        loanIdStatus[id] = true;
        totalActiveLoans += 1;


        if(order.nftType == AssetType.ERC721) { 
            IERC721(order.nftAddress).safeTransferFrom(order.borrower, address(this), order.tokenId);
        }
        if(order.nftType == AssetType.ERC1155) {
            IERC1155(order.nftAddress).safeTransferFrom(order.borrower, address(this), order.tokenId, order.qty, "");
        }
        if(assetPrice > 0){
            IERC20(order.erc20Address).transferFrom(order.lender, order.borrower, assetPrice);
        }
        if(platformFee > 0) {
            IERC20(order.erc20Address).transferFrom(order.lender, owner, platformFee);
        }

        emit Lend(id, order.nftAddress, order.tokenId, assetPrice, platformFee );

        return true;
    }

    function loanRepayment(uint256 _loanId, Sign memory sign) external returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        verifySign(_loanId, msg.sender, sign);
        require(loanIdStatus[_loanId], "Invalid loanId");
        require(!loanRepaidOrLiquidated[_loanId], "Loan has been already repaid or liquidated");
        require(msg.sender == loans[_loanId].borrower,"Current user and borrower is not same ");

        uint256 timeDiff = block.timestamp - loans[_loanId].loanStartTime;

        uint256 interestDue = calculateInterest(loans[_loanId].loanPrincipalAmount, loans[_loanId].loanRepaymentAmount, timeDiff, loans[_loanId].loanDuration, loans[_loanId].loanInterestForDuration);

        uint256 amount = loans[_loanId].loanPrincipalAmount + interestDue;
        if(amount > 0) {
            IERC20(loans[_loanId].loanERC20Address).transferFrom(loans[_loanId].borrower, loans[_loanId].lender, amount);
        }

        if(loans[_loanId].nftType == AssetType.ERC721) { 
            IERC721(loans[_loanId].nftAddress).safeTransferFrom(address(this), loans[_loanId].borrower, loans[_loanId].tokenId);
        }
        if(loans[_loanId].nftType == AssetType.ERC1155) {
            IERC1155(loans[_loanId].nftAddress).safeTransferFrom(address(this), loans[_loanId].borrower, loans[_loanId].tokenId, loans[_loanId].qty, "");
        }

        loanRepaidOrLiquidated[_loanId] = true;
        loanIdStatus[_loanId] = false;
        totalActiveLoans -= 1;
        emit LoanRepayment(_loanId, loans[_loanId].nftAddress, loans[_loanId].tokenId, interestDue, loans[_loanId].loanPrincipalAmount);
        delete loans[_loanId];

        return true;
    }

    function loanOverdue(uint256 _loanId, Sign memory sign) external returns(bool) {

        require(!usedNonce[sign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        verifySign(_loanId, msg.sender, sign);

        require(loanIdStatus[_loanId],"Invalid LoanId");
        require(msg.sender == loans[_loanId].lender,"Current User and lender is not same");
        require(!loanRepaidOrLiquidated[_loanId], "Loan has been already repaid or liquidated");
        uint256 loanMaturityDate = loans[_loanId].loanStartTime + loans[_loanId].loanDuration;
        require(block.timestamp > loanMaturityDate, "loan not overdue yet");
        
        if(loans[_loanId].nftType == AssetType.ERC721) {
            IERC721(loans[_loanId].nftAddress).safeTransferFrom(address(this), loans[_loanId].lender, loans[_loanId].tokenId);
        }

        if(loans[_loanId].nftType == AssetType.ERC1155) {
            IERC1155(loans[_loanId].nftAddress).safeTransferFrom(address(this), loans[_loanId].lender, loans[_loanId].tokenId, loans[_loanId].qty, "");
        }

        totalActiveLoans -= 1;
        delete loans[_loanId];
        loanIdStatus[_loanId] = false;
        loanRepaidOrLiquidated[_loanId] = true;

        emit LoanOverdued(_loanId, loans[_loanId].nftAddress, loans[_loanId].tokenId);
        
        return true;
    }

    function calculateInterest(uint256 amount, uint256 repaymentAmount, uint256 timeDiff, uint256 loanDuration, uint256 interestRate) internal pure returns(uint256) {
        uint256 interestForDuration = amount *  interestRate / 1000;
        uint256 interestForCurrent = interestForDuration * timeDiff / loanDuration;
        if((amount + interestForCurrent) >= repaymentAmount) {
            uint256 lendingInterest = repaymentAmount - amount;
            return lendingInterest;
        }
        return interestForCurrent;
    }

    function getInterest(uint256 _loanId) external view returns(uint256) {
        uint256 timeDiff = block.timestamp - loans[_loanId].loanStartTime;
        uint256 interestDue = calculateInterest(loans[_loanId].loanPrincipalAmount, loans[_loanId].loanRepaymentAmount, timeDiff, loans[_loanId].loanDuration, loans[_loanId].loanInterestForDuration);
        uint256 amount = loans[_loanId].loanPrincipalAmount + interestDue;
        return amount;
    }

    function setBuyerFee(uint256 _buyerFee) external onlyOwner returns(bool) {
        require(_buyerFee >= 0, "Fee must be greater than zero");
        buyerFee = _buyerFee;
        return true;
    }

    function setSellerFee(uint256 _sellerFee) external onlyOwner returns(bool) {
        require(_sellerFee >= 0, "Fee must be greater than zero");
        sellerFee = _sellerFee;
        return true;
    }

    function getUserDetails(uint256 _loanId) external view returns(LoanDetail memory) {
        return loans[_loanId];
    }

    function onERC721Received( address, address, uint256, bytes calldata /*data*/) external pure returns(bytes4) {
        return _ERC721_RECEIVED;
    }
    
    function onERC1155Received( address /*operator*/, address /*from*/, uint256 /*id*/, uint256 /*value*/, bytes calldata /*data*/ ) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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