// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./../interfaces/IMarket.sol";

contract LiquidityPool {
    uint256 public constant DIVISOR = 10000;
    uint256 private constant UINT_MAX = type(uint256).max;

    bool public initialized;
    IMarket public market;
    address public creator;
    uint256 public creatorFee;
    uint256 public pointsToWin; // points that a user needs to win the liquidity pool prize
    uint256 public betMultiplier; // how much the LP adds to the market pool for each $ added to the market
    uint256 public totalDeposits;
    uint256 public poolReward;
    uint256 public creatorReward;

    mapping(address => uint256) private balances;
    mapping(uint256 => bool) private claims;

    event Staked(address indexed _user, uint256 _amount);
    event Withdrawn(address indexed _user, uint256 _amount);
    event LiquidityReward(address indexed _user, uint256 _reward);
    event BetReward(uint256 indexed _tokenID, uint256 _reward);
    event MarketPaymentSent(address indexed _market, uint256 _amount);
    event MarketPaymentReceived(address indexed _market, uint256 _amount);

    constructor() {}

    function initialize(
        address _creator,
        uint256 _creatorFee,
        uint256 _betMultiplier,
        address _market,
        uint256 _pointsToWin
    ) external {
        require(!initialized, "Already initialized.");
        require(_creatorFee < DIVISOR, "Creator fee too big");
        require(
            _pointsToWin > 0 && _pointsToWin <= IMarket(_market).numberOfQuestions(),
            "Invalid pointsToWin value"
        );

        creator = _creator;
        creatorFee = _creatorFee;
        betMultiplier = _betMultiplier;
        market = IMarket(_market);
        pointsToWin = _pointsToWin;

        initialized = true;
    }

    function deposit() external payable {
        require(block.timestamp <= market.closingTime(), "Deposits not allowed");

        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;

        emit Staked(msg.sender, msg.value);
    }

    function withdraw() external {
        require(market.nextTokenID() == 0, "Withdraw not allowed");

        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        totalDeposits -= amount;

        requireSendXDAI(payable(msg.sender), amount);
        emit Withdrawn(msg.sender, amount);
    }

    function claimLiquidityRewards(address _account) external {
        require(market.resultSubmissionPeriodStart() != 0, "Withdraw not allowed");
        require(
            block.timestamp > market.resultSubmissionPeriodStart() + market.submissionTimeout(),
            "Submission period not over"
        );
        require(balances[_account] > 0, "Not enough balance");

        uint256 marketPayment;
        if (market.ranking(0).points >= pointsToWin) {
            // there's at least one winner
            uint256 maxPayment = market.price() * market.nextTokenID();
            maxPayment = mulCap(maxPayment, betMultiplier);
            marketPayment = totalDeposits < maxPayment ? totalDeposits : maxPayment;
        }

        uint256 amount = poolReward + totalDeposits - marketPayment;
        amount = mulCap(amount, balances[_account]) / totalDeposits;
        balances[_account] = 0;

        requireSendXDAI(payable(_account), amount);
        emit LiquidityReward(_account, amount);
    }

    /** @dev Sends a prize to the token holder if applicable.
     *  @param _rankIndex The ranking position of the bet which reward is being claimed.
     *  @param _firstSharedIndex If there are many tokens sharing the same score, this is the first ranking position of the batch.
     *  @param _lastSharedIndex If there are many tokens sharing the same score, this is the last ranking position of the batch.
     */
    function claimBettorRewards(
        uint256 _rankIndex,
        uint256 _firstSharedIndex,
        uint256 _lastSharedIndex
    ) external {
        require(market.resultSubmissionPeriodStart() != 0, "Not in claim period");
        require(
            block.timestamp > market.resultSubmissionPeriodStart() + market.submissionTimeout(),
            "Submission period not over"
        );

        require(market.ranking(_rankIndex).points >= pointsToWin, "Invalid rankIndex");
        require(!claims[_rankIndex], "Already claimed");

        uint248 points = market.ranking(_rankIndex).points;
        // Check that shared indexes are valid.
        require(points == market.ranking(_firstSharedIndex).points, "Wrong start index");
        require(points == market.ranking(_lastSharedIndex).points, "Wrong end index");
        require(points > market.ranking(_lastSharedIndex + 1).points, "Wrong end index");
        require(
            _firstSharedIndex == 0 || points < market.ranking(_firstSharedIndex - 1).points,
            "Wrong start index"
        );
        uint256 sharedBetween = _lastSharedIndex - _firstSharedIndex + 1;

        uint256 cumWeigths = 0;
        uint256[] memory prizes = market.getPrizes();
        for (uint256 i = _firstSharedIndex; i < prizes.length && i <= _lastSharedIndex; i++) {
            cumWeigths += prizes[i];
        }

        uint256 maxPayment = market.price() * market.nextTokenID();
        maxPayment = mulCap(maxPayment, betMultiplier);
        uint256 marketPayment = totalDeposits < maxPayment ? totalDeposits : maxPayment;

        uint256 reward = (marketPayment * cumWeigths) / (DIVISOR * sharedBetween);
        claims[_rankIndex] = true;
        payable(market.ownerOf(market.ranking(_rankIndex).tokenID)).transfer(reward);
        emit BetReward(market.ranking(_rankIndex).tokenID, reward);
    }

    function executeCreatorRewards() external {
        uint256 creatorRewardToSend;
        if (totalDeposits == 0) {
            // No liquidity was provided. Creator gets all the rewards
            creatorRewardToSend = creatorReward + poolReward;
            poolReward = 0;
        } else {
            creatorRewardToSend = creatorReward;
        }
        creatorReward = 0;
        requireSendXDAI(payable(creator), creatorRewardToSend);
    }

    function requireSendXDAI(address payable _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        require(success, "LiquidityPool: Send XDAI failed");
    }

    /**
     * @dev Multiplies two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function mulCap(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring '_a' not being zero, but the
        // benefit is lost if '_b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) return 0;

        unchecked {
            uint256 c = _a * _b;
            return c / _a == _b ? c : UINT_MAX;
        }
    }

    receive() external payable {
        (, , address manager, , ) = market.marketInfo();
        if (msg.sender == manager) {
            creatorReward = (msg.value * creatorFee) / DIVISOR;
            poolReward = msg.value - creatorReward;
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