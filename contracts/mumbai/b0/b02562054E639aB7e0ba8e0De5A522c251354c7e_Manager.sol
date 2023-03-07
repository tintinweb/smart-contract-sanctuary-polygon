// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./../interfaces/IMarket.sol";

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract Manager {
    address payable public creator;
    uint256 public creatorFee;
    address payable public protocolTreasury;
    uint256 public protocolFee;
    IMarket public market;

    bool public initialized;
    bool public managerRewardDistributed;
    mapping(address => bool) public claimed; // claimed[referral]
    uint256 public amountClaimed;
    uint256 public creatorReward;
    uint256 public protocolReward;

    constructor() {}

    function initialize(
        address payable _creator,
        uint256 _creatorFee,
        address payable _protocolTreasury,
        uint256 _protocolFee,
        address _market
    ) external {
        require(!initialized, "Already initialized.");

        creator = _creator;
        creatorFee = _creatorFee;
        protocolTreasury = _protocolTreasury;
        protocolFee = _protocolFee;
        market = IMarket(_market);

        initialized = true;
    }

    function distributeRewards() external {
        require(market.resultSubmissionPeriodStart() != 0, "Fees not received");
        require(!managerRewardDistributed, "Reward already claimed");

        managerRewardDistributed = true;

        uint256 totalFee = creatorFee + protocolFee;
        uint256 totalReward = market.managementReward();
        uint256 totalBets = market.nextTokenID();
        uint256 nonReferralShare = totalBets - market.totalAttributions();

        uint256 creatorMarketReward = (totalReward * creatorFee * nonReferralShare) /
            (totalBets * totalFee * 2);
        creatorMarketReward += (totalReward * creatorFee) / (totalFee * 2);
        creatorReward += creatorMarketReward;

        uint256 protocolMarketReward = (totalReward * protocolFee * nonReferralShare) /
            (totalBets * totalFee * 3);
        protocolMarketReward += (totalReward * protocolFee * 2) / (totalFee * 3);
        protocolReward += protocolMarketReward;

        amountClaimed += creatorMarketReward + protocolMarketReward;
    }

    function executeCreatorRewards() external {
        uint256 creatorRewardToSend = creatorReward;
        creatorReward = 0;
        requireSendXDAI(creator, creatorRewardToSend);
    }

    function executeProtocolRewards() external {
        uint256 protocolRewardToSend = protocolReward;
        protocolReward = 0;
        requireSendXDAI(protocolTreasury, protocolRewardToSend);
    }

    function claimReferralReward(address _referral) external {
        require(market.resultSubmissionPeriodStart() != 0, "Fees not received");
        require(!claimed[_referral], "Reward already claimed");

        uint256 totalFee = creatorFee + protocolFee;
        uint256 totalReward = market.managementReward();
        uint256 referralShare = market.attributionBalance(_referral);
        uint256 totalBets = market.nextTokenID();

        uint256 rewardFromCreator = (totalReward * creatorFee * referralShare) /
            (totalBets * totalFee * 2);
        uint256 rewardFromProtocol = (totalReward * protocolFee * referralShare) /
            (totalBets * totalFee * 3);

        claimed[_referral] = true;
        amountClaimed += rewardFromCreator + rewardFromProtocol;
        requireSendXDAI(payable(_referral), rewardFromCreator + rewardFromProtocol);
    }

    function distributeSurplus() external {
        require(market.resultSubmissionPeriodStart() != 0, "Can't distribute surplus yet");
        uint256 remainingManagementReward = market.managementReward() - amountClaimed;
        uint256 surplus = address(this).balance -
            remainingManagementReward -
            creatorReward -
            protocolReward;
        creatorReward += surplus / 2;
        protocolReward += surplus / 2;
    }

    function distributeERC20(IERC20 _token) external {
        uint256 tokenBalance = _token.balanceOf(address(this));
        _token.transfer(creator, tokenBalance / 2);
        _token.transfer(protocolTreasury, tokenBalance / 2);
    }

    function requireSendXDAI(address payable _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        require(success, "Send XDAI failed");
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMarket is IERC721 {
    struct Result {
        uint256 tokenID;
        uint248 points;
        bool claimed;
    }

    function marketInfo()
        external
        view
        returns (
            uint16,
            uint16,
            address payable,
            string memory,
            string memory
        );

    function name() external view returns (string memory);

    function betNFTDescriptor() external view returns (address);

    function questionsHash() external view returns (bytes32);

    function resultSubmissionPeriodStart() external view returns (uint256);

    function closingTime() external view returns (uint256);

    function submissionTimeout() external view returns (uint256);

    function nextTokenID() external view returns (uint256);

    function price() external view returns (uint256);

    function totalPrize() external view returns (uint256);

    function getPrizes() external view returns (uint256[] memory);

    function prizeWeights(uint256 index) external view returns (uint16);

    function totalAttributions() external view returns (uint256);

    function attributionBalance(address _attribution) external view returns (uint256);

    function managementReward() external view returns (uint256);

    function tokenIDtoTokenHash(uint256 _tokenID) external view returns (bytes32);

    function placeBet(address _attribution, bytes32[] calldata _results)
        external
        payable
        returns (uint256);

    function bets(bytes32 _tokenHash) external view returns (uint256);

    function ranking(uint256 index) external view returns (Result memory);

    function fundMarket(string calldata _message) external payable;

    function numberOfQuestions() external view returns (uint256);

    function questionIDs(uint256 index) external view returns (bytes32);

    function realitio() external view returns (address);

    function ownerOf() external view returns (address);

    function getPredictions(uint256 _tokenID) external view returns (bytes32[] memory);

    function getScore(uint256 _tokenID) external view returns (uint256 totalPoints);
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