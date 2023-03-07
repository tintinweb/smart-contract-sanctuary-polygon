// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/IMarket.sol";

contract KeyValue {
    address public owner = msg.sender;
    address public marketFactoryV2;
    mapping(address => string) public username;
    mapping(string => bool) public usernameExists;
    mapping(address => address) public marketCreator;
    mapping(address => bool) public marketDeleted;

    event SetUsername(address userId, string username);
    event SetMarketCreator(address marketId, address creator);
    event MarketDeleted(address marketId);

    function changeOwner(address _owner) external {
        require(msg.sender == owner, "Not authorized");
        owner = _owner;
    }

    function changeMarketFactory(address _marketFactoryV2) external {
        require(msg.sender == owner, "Not authorized");
        marketFactoryV2 = _marketFactoryV2;
    }

    function setUsername(address userId, string calldata name) public {
        require(!usernameExists[name], "Username already exists");
        require(userId == msg.sender || msg.sender == owner, "Unable to set username");

        usernameExists[username[userId]] = false;
        usernameExists[name] = true;

        username[userId] = name;

        emit SetUsername(userId, name);
    }

    function setUsernames(address[] calldata userIds, string[] calldata names) external {
        uint256 count = userIds.length;
        for (uint256 i = 0; i < count; i++) {
            setUsername(userIds[i], names[i]);
        }
    }

    function setMarketCreator(address marketId, address creator) external {
        require(msg.sender == marketFactoryV2, "Not market factory");

        marketCreator[marketId] = creator;

        emit SetMarketCreator(marketId, creator);
    }

    function deleteMarket(address marketId) public {
        require(msg.sender == marketCreator[marketId] || msg.sender == owner, "Not creator");
        require(marketId.balance == 0 && IMarket(marketId).nextTokenID() == 0, "Market has bets");

        marketDeleted[marketId] = true;

        emit MarketDeleted(marketId);
    }

    function deleteMarkets(address[] calldata marketIds) external {
        uint256 count = marketIds.length;
        for (uint256 i = 0; i < count; i++) {
            deleteMarket(marketIds[i]);
        }
    }
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