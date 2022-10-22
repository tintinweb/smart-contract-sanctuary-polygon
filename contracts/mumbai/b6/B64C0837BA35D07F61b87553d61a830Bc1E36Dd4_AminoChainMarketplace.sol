// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title AminoChain Marketplace V0.1.5
 *  @notice Handles the sale of tokenized stem cells and distributing
 *  incentives to donors
 */
contract AminoChainMarketplace is ReentrancyGuard {
    address public owner;
    address public tokenziedStemCells;
    address public authenticator;
    address public immutable i_usdc;

    /** @dev The sale price divied by donorIncentiveRate equals donor incentive amount.
     *   E.G. If donorIncentiveRate is equal to 8, then the donors will get 12.5% of the
     *   sale amounts.
     */
    uint256 public donorIncentiveRate;

    struct Listing {
        address seller;
        uint256 tokenId;
        uint256 price;
        address donor;
        address bioBank;
    }

    mapping(uint256 => Listing) ListingData;

    /** === Constructor === **/

    constructor(
        uint256 _donorIncentiveRate,
        address _usdc,
        address _tokenizedStemCells
    ) {
        owner = msg.sender;
        tokenziedStemCells = _tokenizedStemCells;
        i_usdc = _usdc;
        donorIncentiveRate = _donorIncentiveRate;
    }

    /** === Modifiers === **/

    /** @dev Prevents functions from being called by addresses that are
     *  not the owner address.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Msg sender in not contract owner");
        _;
    }

    /** @dev Prevents functions from being called by addresses that are not
     *  the authenticator contract.
     */
    modifier onlyAuthenticator() {
        require(msg.sender == authenticator, "Msg sender in not authenticator contract");
        _;
    }

    /** === Events === **/

    event newListing(
        address seller,
        uint256 tokenId,
        uint256 price,
        address donor,
        address bioBank
    );

    event sale(
        address seller,
        uint256 tokenId,
        address buyer,
        uint256 salePrice,
        uint256 protocolFee,
        address donor,
        uint256 donorIncentive,
        address bioBank
    );

    event listingCanceled(address seller, uint256 tokenId);

    event ownershipTransferred(address oldOwner, address newOwner);

    event stemCellsAddressSet(address stemCells);

    event authenticatorAddressSet(address authenticator);

    event newDonorIncentiveRate(uint256 newIncentiveRate);

    /** === External Functions === **/

    /** @dev Allows the owner (AminoChain) of the contract to list tokenized stem cells.
     *  The BioBank is the physcial holder of the stem cells. Before calling this function, the
     *  lister must set isApprovedForAll on the ERC-721 contract to true for this contract address.
     */
    function listItem(
        uint256 tokenId,
        uint256 price,
        address donor,
        address bioBank
    ) external onlyAuthenticator {
        require(
            IERC721(tokenziedStemCells).ownerOf(tokenId) == msg.sender,
            "Token is not owned by sender"
        );
        require(ListingData[tokenId].seller == address(0), "Token is already listed");
        require(bioBank != address(0), "BioBank cannot be null");
        require(
            IERC721(tokenziedStemCells).isApprovedForAll(msg.sender, address(this)) == true,
            "Marketplace does not have approval from lister on NFT contract"
        );

        ListingData[tokenId] = Listing(msg.sender, tokenId, price, donor, bioBank);

        emit newListing(msg.sender, tokenId, price, donor, bioBank);
    }

    /** @dev Allows a user to buy tokenized stem cells for a given tokenId (No identity verification yet),
     *  then transfers the incentive (based on donorIncentiveRate) to the donor's wallet, a fee to the authenticator contract,
     *  and the rest of the payment to the bioBanks's wallet. Buyer must have the price amount approved for marketplace address
     *  on the USDC contract.
     */
    function buyItem(uint256 tokenId) external nonReentrant {
        Listing memory data = ListingData[tokenId];
        require(data.seller != address(0), "Token is not listed");
        require(
            IERC721(tokenziedStemCells).ownerOf(tokenId) != msg.sender,
            "Token seller cannot buy their token"
        );
        require(
            IERC721(i_usdc).balanceOf(msg.sender) >= data.price,
            "Buyer's USDC balence is too low"
        );
        require(
            IERC20(i_usdc).allowance(msg.sender, address(this)) >= data.price,
            "Marketplace allowance from buyer on USDC contract must be higher than listing price"
        );

        uint256 incentive = data.price / donorIncentiveRate;
        uint256 fee = data.price / 10;

        /// BioBank Payment
        IERC20(i_usdc).transferFrom(msg.sender, data.bioBank, data.price - (incentive + fee));
        /// Protocol Fee Payment
        IERC20(i_usdc).transferFrom(msg.sender, data.seller, fee);
        /// Donor Incentive Payment
        IERC20(i_usdc).transferFrom(msg.sender, data.donor, incentive);

        IERC721(tokenziedStemCells).safeTransferFrom(data.seller, msg.sender, tokenId);

        emit sale(
            data.seller,
            tokenId,
            msg.sender,
            data.price,
            fee,
            data.donor,
            incentive,
            data.bioBank
        );

        delete ListingData[tokenId];
    }

    /** @dev Allows the lister of a given tokenId to cancel their listing by deleting
     *  the corrosponding listing data.
     */
    function cancelListing(uint256 tokenId) external onlyAuthenticator {
        require(ListingData[tokenId].seller == msg.sender, "Only lister can cancel their listing");

        delete ListingData[tokenId];

        emit listingCanceled(msg.sender, tokenId);
    }

    /** @dev Allows the lister of a given tokenId to update the price of their listing by
     *  modifing the corrosponding listing data.
     */
    function updateListing(uint256 tokenId, uint256 newPrice) external onlyAuthenticator {
        Listing memory data = ListingData[tokenId];
        require(data.seller == msg.sender, "Only lister can update their listing");
        require(data.price != newPrice, "Old price cannot be the same as the new");

        ListingData[tokenId].price = newPrice;

        emit newListing(msg.sender, tokenId, newPrice, data.donor, data.bioBank);
    }

    /** @dev Transfers contract ownership to another wallet address. Many functions
     *  (with onlyOwner modifier) can only be called by the owner address.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != owner, "New address is already owner");
        address oldOwner = owner;
        owner = newOwner;
        emit ownershipTransferred(oldOwner, newOwner);
    }

    /** @dev Sets the address of the tokenized stem cells (ERC-721). Only NFTs from
     *  the address can be listed and sold on this markeplace.
     */
    function setTokenizedStemCells(address stemCells) external onlyOwner {
        require(stemCells != tokenziedStemCells, "New address is already set");
        tokenziedStemCells = stemCells;
        emit stemCellsAddressSet(stemCells);
    }

    /** @dev Sets the address of the authenticator contract. Authenticator mints tokenized
     *  stem cells and lists them on the marketplace.
     */
    function setAuthenticatorAddress(address _authenticator) external onlyOwner {
        require(authenticator != _authenticator, "New address is already set");
        authenticator = _authenticator;
        emit authenticatorAddressSet(_authenticator);
    }

    /** @dev Sets a new donor incentive rate. Which determines the percentage of
     *  each sale that goes to the stem cell donor.
     */
    function setDonorIncentiveRate(uint256 newIncentiveRate) external onlyOwner {
        require(
            donorIncentiveRate != newIncentiveRate,
            "New incentive rate is the same as the old"
        );
        donorIncentiveRate = newIncentiveRate;
        emit newDonorIncentiveRate(newIncentiveRate);
    }

    // === View Functions === //

    /** @dev Returns the listing data for a given tokenId
     */
    function getListingData(uint256 tokenId) public view returns (Listing memory) {
        return ListingData[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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