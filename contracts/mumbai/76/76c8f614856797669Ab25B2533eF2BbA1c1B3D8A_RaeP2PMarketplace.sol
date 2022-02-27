pragma solidity ^0.8.0;

import "./utils/ERC721/IERC721.sol";
import "./utils/ERC721/extensions/IERC721Metadata.sol";

contract RaeP2PMarketplace {
    uint256 private numLoans;
    uint256 private numOffers;
    mapping(uint256 => Loan) public loans;
    mapping(uint256 => Offer) public offers;
    mapping(address => uint256[]) public borrowerToLoanIDs;
    mapping(address => uint256[]) public lenderToLoanIDs;
    mapping(address => uint256[]) public userToOffers;
    mapping(uint256 => uint256[]) public loanToOffers;

    struct Loan {
        uint256 id;
        address borrower;
        address tokenAddress;
        uint256 tokenID;
        uint256 amount;
        uint256 desiredCompletionTimestamp;
        uint256 desiredReturnAmount;
        uint256 acceptedOfferID;
        uint256 completionTimestamp;
        bool isSettled;
        bool isCancelled;
    }

    struct Offer {
        uint256 id;
        uint256 loanID;
        address lender;
        uint256 returnAmount;
        uint256 completionTimeInDays;
    }

    function initiateLoan(
        address _tokenAddress, 
        uint256 _tokenID,
        uint256 _desiredAmount, 
        uint256 _desiredReturnAmount,
        uint256 _desiredCompletionTimeInDays
    ) public returns (uint256) {
        require(_desiredAmount > 0, "Desired loan amount cannot be zero");
        require(_desiredCompletionTimeInDays > 0, "Desired completion time cannot be zero");
        require(_desiredReturnAmount > 0, "Desired interest percentage cannot be zero");        
        require(IERC721(_tokenAddress).ownerOf(_tokenID) == msg.sender, "Unauthorized");

        IERC721(_tokenAddress).transferFrom(msg.sender, address(this), _tokenID);

        numLoans++;
        uint256 newLoanID = numLoans;

        Loan memory newLoan = Loan(
            newLoanID,
            msg.sender,
            _tokenAddress,
            _tokenID,
            _desiredAmount,
            _desiredCompletionTimeInDays,
            _desiredReturnAmount,
            0,
            0,
            false,
            false
        );

        loans[newLoanID] = newLoan;
        borrowerToLoanIDs[msg.sender].push(newLoanID);

        return newLoanID;
    }

    function cancelLoan(
        uint256 _loanID
    ) public {
        Loan memory currentLoan = loans[_loanID];

        require(currentLoan.borrower == msg.sender, "unauthorized");
        require(currentLoan.isCancelled == false, "loan is already cancelled");
        require(currentLoan.isSettled == false, "loan is already settled");
        require(currentLoan.acceptedOfferID == 0, "you have already accepted an offer");

        IERC721(currentLoan.tokenAddress).transferFrom(address(this), msg.sender, currentLoan.tokenID);
        loans[_loanID].isCancelled = true;
    }

    function makeOffer(
        uint256 _loanID,
        uint256 _offeredReturnAmount,
        uint256 _offeredCompletionTimeInDays
    ) public payable returns (uint256) {
        Loan memory currentLoan = loans[_loanID];

        require(currentLoan.acceptedOfferID == 0, "an offer has already been accepted");
        require(currentLoan.isCancelled == false, "you can make offer to active loan request only");
        require(currentLoan.borrower != msg.sender, "you can't offer yourself a loan");
        require(currentLoan.amount == msg.value, "pay the required amount");

        numOffers++;
        uint256 newOfferID = numOffers;

        Offer memory newOffer = Offer(
            newOfferID,
            _loanID,
            msg.sender,
            _offeredReturnAmount,
            _offeredCompletionTimeInDays
        );

        offers[newOfferID] = newOffer;
        userToOffers[msg.sender].push(newOfferID);
        loanToOffers[_loanID].push(newOfferID);

        return newOfferID;
    }

    function acceptOffer(
        uint256 _offerID
    ) public {
        Offer memory currentOffer = offers[_offerID];
        Loan memory currentLoan = loans[currentOffer.loanID];

        require(msg.sender == currentLoan.borrower, "You can accept offers only on your loans");
        require(currentLoan.isCancelled == false && currentLoan.isSettled == false, "loan shouldn't be cancelled or settled already");
        require(currentLoan.acceptedOfferID == 0, "you have already accepted an offer");

        loans[currentOffer.loanID].acceptedOfferID = _offerID;
        loans[currentOffer.loanID].completionTimestamp = block.timestamp + currentOffer.completionTimeInDays * 1 days;
        lenderToLoanIDs[currentOffer.lender].push(currentLoan.id);
    }

    function repayLoan(
        uint256 _loanID
    ) public payable {
        Loan memory currentLoan = loans[_loanID];
        Offer memory currentOffer = offers[currentLoan.acceptedOfferID];

        require(currentLoan.borrower == msg.sender, "Only borrower can pay back.");
        require(currentOffer.returnAmount == msg.value, "Eth being paid should be equal to returnAmount");
        require(currentLoan.completionTimestamp > block.timestamp, "Loan should be returned before completion time");
        require(currentLoan.isSettled == false, "loan is already settled");

        payable(currentOffer.lender).transfer(msg.value);
        IERC721(currentLoan.tokenAddress).transferFrom(address(this), msg.sender, currentLoan.tokenID);

        loans[_loanID].isSettled = true;
    }

    function seizeNFT(
        uint256 _loanID
    ) public {
        Loan memory currentLoan = loans[_loanID];
        Offer memory currentOffer = offers[currentLoan.acceptedOfferID];

        require(currentOffer.lender == msg.sender, "Only lender can call this function");
        require(currentLoan.isSettled == false, "Loan is already settled");
        require(currentLoan.completionTimestamp < block.timestamp, "It should be past completion time to seize NFT");

        IERC721(currentLoan.tokenAddress).transferFrom(address(this), msg.sender, currentLoan.tokenID);

        loans[_loanID].isSettled = true;
    }

    function getTokenURI(
        address _tokenAddress,
        uint256 _tokenID
    ) public view returns (string memory) {
        return IERC721Metadata(_tokenAddress).tokenURI(_tokenID);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/introspection/IERC165.sol";

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