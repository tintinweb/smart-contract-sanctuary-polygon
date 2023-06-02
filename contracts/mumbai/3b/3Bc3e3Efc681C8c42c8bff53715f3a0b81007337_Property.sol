// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/Helper.sol";
import "../interfaces/IUniHelper.sol";
import "../interfaces/IVote.sol";
import "../interfaces/IStakingPool.sol";
import "../interfaces/IOwnablee.sol";

contract Property is ReentrancyGuard {

    event AuditorProposalCreated(address creator, address member, string title, string description, uint256 createTime);
    event RewardFundProposalCreated(address creator, address member, string title, string description, uint256 createTime);
    event FilmBoardProposalCreated(address creator, address member, string title, string description, uint256 createTime);
    event FilmBoardMemberAdded(address caller, address member, uint256 addTime);
    event FilmBoardMemberRemoved(address caller, address member, uint256 removeTime);
    event PropertyProposalCreated(address creator, uint256 property, uint256 flag, string title, string description, uint256 createTime);
    event PropertyUpdated(address caller, uint256 property, uint256 flag, uint256 updateTime);
    
    struct Proposal {
        string title;          // proposal title
        string description;    // proposal description
        uint256 createTime;    // proposal created timestamp
        uint256 approveTime;   // proposal approved timestamp
        address creator;       // proposal creator address        
        Helper.Status status;  // status of proposal
    }
  
    address private immutable OWNABLE;        // Ownablee contract address 
    address private immutable VOTE;           // Vote contract address
    address private immutable STAKING_POOL;   // StakingPool contract address
    address private immutable UNI_HELPER;     // UniHelper contract address
    address public DAO_FUND_REWARD;       // address for sending the DAO rewards fund

    uint256 public filmVotePeriod;       // 0 - film vote period
    uint256 public agentVotePeriod;      // 1 - vote period for replacing auditor
    uint256 public disputeGracePeriod;   // 2 - grace period for replacing Auditor
    uint256 public propertyVotePeriod;   // 3 - vote period for updating properties    
    uint256 public lockPeriod;           // 4 - lock period for staked VAB
    uint256 public rewardRate;           // 5 - day rewards rate => 0.0004%(1% = 1e8, 100% = 1e10)
    uint256 public extraRewardRate;      // 6 - bonus day rewards rate =>0.0001%(1% = 1e8, 100% = 1e10)
    uint256 public maxAllowPeriod;       // 7 - max allowed period for removing filmBoard member
    uint256 public proposalFeeAmount;    // 8 - USDC amount($100) studio should pay when create a proposal
    uint256 public fundFeePercent;       // 9 - percent(2% = 2*1e8) of fee on the amount raised
    uint256 public minDepositAmount;     // 10 - USDC min amount($50) that a customer can deposit to a film approved for funding
    uint256 public maxDepositAmount;     // 11 - USDC max amount($5000) that a customer can deposit to a film approved for funding
    uint256 public maxMintFeePercent;    // 12 - 10%(1% = 1e8, 100% = 1e10)
    uint256 public minVoteCount;         // 13 - 5 ppl(minium voter count for approving the proposal)
    uint256 public minStakerCountPercent;// 14 - percent(5% = 5*1e8)
    uint256 public availableVABAmount;   // 15 - vab amount for replacing the auditor    
    uint256 public boardVotePeriod;      // 16 - filmBoard vote period
    uint256 public boardVoteWeight;      // 17 - filmBoard member's vote weight
    uint256 public rewardVotePeriod;     // 18 - withdraw address setup for moving to V2
    uint256 public subscriptionAmount;   // 19 - user need to have an active subscription(pay $1 per month) for rent films.    
    uint256 public boardRewardRate;      // 20 - 25%(1% = 1e8, 100% = 1e10) more reward rate for filmboard members
    
    uint256 public governanceProposalCount;

    uint256[] private filmVotePeriodList;          // 0
    uint256[] private agentVotePeriodList;         // 1
    uint256[] private disputeGracePeriodList;      // 2 
    uint256[] private propertyVotePeriodList;      // 3
    uint256[] private lockPeriodList;              // 4
    uint256[] private rewardRateList;              // 5
    uint256[] private extraRewardRateList;         // 6
    uint256[] private maxAllowPeriodList;          // 7
    uint256[] private proposalFeeAmountList;       // 8
    uint256[] private fundFeePercentList;          // 9
    uint256[] private minDepositAmountList;        // 10
    uint256[] private maxDepositAmountList;        // 11
    uint256[] private maxMintFeePercentList;       // 12
    uint256[] private minVoteCountList;            // 13
    uint256[] private minStakerCountPercentList;   // 14
    uint256[] private availableVABAmountList;      // 15   
    uint256[] private boardVotePeriodList;         // 16
    uint256[] private boardVoteWeightList;         // 17
    uint256[] private rewardVotePeriodList;        // 18
    uint256[] private subscriptionAmountList;      // 19
    uint256[] private boardRewardRateList;         // 20

    address[] private agentList;             // for replacing auditor
    address[] private rewardAddressList;     // for adding v2 pool address
    address[] private filmBoardCandidates;   // filmBoard candidates and if isBoardWhitelist is true, become filmBoard member
    address[] private filmBoardMembers;      // filmBoard members

    mapping(address => uint256) public isBoardWhitelist;       // (filmBoard member => 0: no member, 1: candiate, 2: already member)
    mapping(address => uint256) public isRewardWhitelist;      // (rewardAddress => 0: no member, 1: candiate, 2: already member) 

    mapping(address => Proposal) public rewardProposalInfo;    // (rewardAddress => Proposal)       
    mapping(address => Proposal) public boardProposalInfo;     // (board => Proposal)       
    mapping(address => Proposal) public agentProposalInfo;     // (pool address => Proposal)       
    mapping(uint256 => mapping(uint256 => Proposal)) public propertyProposalInfo;  // (flag => (property => Proposal))

    mapping(address => uint256) public userGovernProposalCount;// (user => created governance-proposal count)

    modifier onlyVote() {
        require(msg.sender == VOTE, "caller is not the vote contract");
        _;
    }
    modifier onlyAuditor() {
        require(msg.sender == IOwnablee(OWNABLE).auditor(), "caller is not the auditor");
        _;
    }
    modifier onlyStaker() {
        require(IStakingPool(STAKING_POOL).getStakeAmount(msg.sender) > 0, "Not staker");
        _;
    }

    constructor(
        address _ownable,
        address _uniHelper,
        address _vote,
        address _staking
    ) {
        require(_ownable != address(0), "ownableContract: Zero address");
        OWNABLE = _ownable;  
        require(_uniHelper != address(0), "uniHelperContract: Zero address");
        UNI_HELPER = _uniHelper;
        require(_vote != address(0), "voteContract: Zero address");
        VOTE = _vote;
        require(_staking != address(0), "stakingContract: Zero address");
        STAKING_POOL = _staking;       

        filmVotePeriod = 10 minutes; // 10 days;   
        boardVotePeriod = 10 minutes; // 14 days;
        agentVotePeriod = 10 minutes; // 10 days;
        disputeGracePeriod = 30 days;  
        propertyVotePeriod = 10 minutes; // 10 days;
        rewardVotePeriod = 10 minutes; // 30 days;
        lockPeriod = 10 minutes; //30 days;
        maxAllowPeriod = 90 days;        

        boardVoteWeight = 30 * 1e8;      // 30% (1% = 1e8)
        rewardRate = 40000;              // 0.0004% (1% = 1e8, 100%=1e10)
        extraRewardRate = 10000;         // 0.0001% (1% = 1e8, 100%=1e10)
        boardRewardRate = 25 * 1e8;      // 25%
        fundFeePercent = 2 * 1e8;        // percent(2%) 
        maxMintFeePercent = 10 * 1e8;    // 10%
        minStakerCountPercent = 5 * 1e8; // 5%(1% = 1e8, 100%=1e10)

        address usdcToken = IOwnablee(_ownable).USDC_TOKEN();
        address vabToken = IOwnablee(_ownable).PAYOUT_TOKEN();
        proposalFeeAmount = 20 * (10**IERC20Metadata(usdcToken).decimals());   // amount in cash(usd dollar - $20)
        minDepositAmount = 50 * (10**IERC20Metadata(usdcToken).decimals());    // amount in cash(usd dollar - $50)
        maxDepositAmount = 5000 * (10**IERC20Metadata(usdcToken).decimals());  // amount in cash(usd dollar - $5000)
        availableVABAmount = 75 * 1e6 * (10**IERC20Metadata(vabToken).decimals()); // 75M        
        subscriptionAmount = 1 * (10**IERC20Metadata(usdcToken).decimals());   // amount in cash(usd dollar - $1)
        minVoteCount = 1;//5;
    }

    /// =================== proposals for replacing auditor ==============
    /// @notice Anyone($100 fee in VAB) create a proposal for replacing Auditor
    function proposalAuditor(
        address _agent,
        string memory _title,
        string memory _description
    ) external onlyStaker {
        require(_agent != address(0), "proposalAuditor: Zero address");                
        require(IOwnablee(OWNABLE).auditor() != _agent, "proposalAuditor: Already auditor address");                
        require(__isPaidFee(proposalFeeAmount), 'proposalAuditor: Not paid fee');

        agentList.push(_agent);
        governanceProposalCount += 1;
        userGovernProposalCount[msg.sender] += 1;

        Proposal storage ap = agentProposalInfo[_agent];
        ap.title = _title;
        ap.description = _description;
        ap.createTime = block.timestamp;
        ap.creator = msg.sender;
        ap.status = Helper.Status.LISTED;

        // add timestap to array for calculating rewards
        IStakingPool(STAKING_POOL).updateProposalCreatedTimeList(block.timestamp);

        emit AuditorProposalCreated(msg.sender, _agent, _title, _description, block.timestamp);
    }

    /// @notice Check if proposal fee transferred from studio to stakingPool
    // Get expected VAB amount from UniswapV2 and then Transfer VAB: user(studio) -> stakingPool.
    function __isPaidFee(uint256 _payAmount) private returns(bool) {         
        address usdcToken = IOwnablee(OWNABLE).USDC_TOKEN();
        address vabToken = IOwnablee(OWNABLE).PAYOUT_TOKEN();   
        uint256 expectVABAmount = IUniHelper(UNI_HELPER).expectedAmount(_payAmount, usdcToken, vabToken);
        if(expectVABAmount > 0) {
            Helper.safeTransferFrom(vabToken, msg.sender, address(this), expectVABAmount);
            if(IERC20(vabToken).allowance(address(this), STAKING_POOL) == 0) {
                Helper.safeApprove(vabToken, STAKING_POOL, IERC20(vabToken).totalSupply());
            }  
            IStakingPool(STAKING_POOL).addRewardToPool(expectVABAmount);
            return true;
        } else {
            return false;
        }
    }  

    // =================== DAO fund rewards proposal ====================
    function proposalRewardFund(
        address _rewardAddress,
        string memory _title,
        string memory _description
    ) external onlyStaker {
        require(_rewardAddress != address(0), "proposalRewardFund: Zero candidate address");     
        require(isRewardWhitelist[_rewardAddress] == 0, "proposalRewardFund: Already created proposal by this address");
        require(__isPaidFee(10 * proposalFeeAmount), 'proposalRewardFund: Not paid fee');

        rewardAddressList.push(_rewardAddress);
        isRewardWhitelist[_rewardAddress] = 1;        
        governanceProposalCount += 1;
        userGovernProposalCount[msg.sender] += 1;

        Proposal storage rp = rewardProposalInfo[_rewardAddress];
        rp.title = _title;
        rp.description = _description;
        rp.createTime = block.timestamp;
        rp.creator = msg.sender;
        rp.status = Helper.Status.LISTED;

        // add timestap to array for calculating rewards
        IStakingPool(STAKING_POOL).updateProposalCreatedTimeList(block.timestamp);

        emit RewardFundProposalCreated(msg.sender, _rewardAddress, _title, _description, block.timestamp);
    }

    /// @notice Set DAO_FUND_REWARD by Vote contract
    function setRewardAddress(address _rewardAddress) external onlyVote nonReentrant {
        require(_rewardAddress != address(0), "setRewardAddress: Zero address");     
        require(isRewardWhitelist[_rewardAddress] == 1, "setRewardAddress: no proposal address");

        isRewardWhitelist[_rewardAddress] = 2;
        DAO_FUND_REWARD = _rewardAddress;
    }

    /// @notice Get reward fund proposal title and description
    function getRewardProposalInfo(address _rewardAddress) external view returns (string memory, string memory, uint256) {
        Proposal memory rp = rewardProposalInfo[_rewardAddress];
        string memory title_ = rp.title;
        string memory desc_ = rp.description;        
        uint256 time_ = rp.createTime;

        return (title_, desc_, time_);
    }

    // =================== FilmBoard proposal ====================
    /// @notice Anyone($100 fee of VAB) create a proposal with the case to be added to film board
    function proposalFilmBoard(
        address _member, 
        string memory _title,
        string memory _description
    ) external onlyStaker {
        require(_member != address(0), "proposalFilmBoard: Zero candidate address");     
        require(isBoardWhitelist[_member] == 0, "proposalFilmBoard: Already film board member or candidate");                  
        require(__isPaidFee(proposalFeeAmount), 'proposalFilmBoard: Not paid fee');     

        filmBoardCandidates.push(_member);
        isBoardWhitelist[_member] = 1;
        governanceProposalCount += 1;
        userGovernProposalCount[msg.sender] += 1;

        Proposal storage bp = boardProposalInfo[_member];
        bp.title = _title;
        bp.description = _description;
        bp.createTime = block.timestamp;
        bp.creator = msg.sender;
        bp.status = Helper.Status.LISTED;

        // add timestap to array for calculating rewards
        IStakingPool(STAKING_POOL).updateProposalCreatedTimeList(block.timestamp);

        emit FilmBoardProposalCreated(msg.sender, _member, _title, _description, block.timestamp);
    }

    /// @notice Add a member to whitelist by Vote contract
    function addFilmBoardMember(address _member) external onlyVote nonReentrant {
        require(_member != address(0), "addFilmBoardMember: Zero candidate address");     
        require(isBoardWhitelist[_member] == 1, "addFilmBoardMember: Already film board member or no candidate");   

        filmBoardMembers.push(_member);
        isBoardWhitelist[_member] = 2;
        
        emit FilmBoardMemberAdded(msg.sender, _member, block.timestamp);
    }

    /// @notice Remove a member from whitelist if he didn't vote to any propsoal for over 3 months
    function removeFilmBoardMember(address _member) external onlyStaker nonReentrant {
        require(isBoardWhitelist[_member] == 2, "removeFilmBoardMember: Not Film board member");        
        require(maxAllowPeriod < block.timestamp - IVote(VOTE).getLastVoteTime(_member), 'maxAllowPeriod');
        require(maxAllowPeriod > block.timestamp - IStakingPool(STAKING_POOL).lastfundProposalCreateTime(), 'lastfundProposalCreateTime');

        isBoardWhitelist[_member] = 0;
    
        for(uint256 i = 0; i < filmBoardMembers.length; i++) {
            if(_member == filmBoardMembers[i]) {
                filmBoardMembers[i] = filmBoardMembers[filmBoardMembers.length - 1];
                filmBoardMembers.pop();
            }
        }
        emit FilmBoardMemberRemoved(msg.sender, _member, block.timestamp);
    }

    /// @notice Get proposal list(flag=1=>agentList, 2=>rewardAddressList, 3=>boardCandidateList, rest=>boardMemberList)
    function getGovProposalList(uint256 _flag) external view returns (address[] memory) {
        if(_flag == 1) return agentList;
        else if(_flag == 2) return rewardAddressList;
        else if(_flag == 3) return filmBoardCandidates;
        else return filmBoardMembers;
    }    

    // ===================properties proposal ====================
    /// @notice proposals for properties
    function proposalProperty(
        uint256 _property, 
        uint256 _flag,
        string memory _title,
        string memory _description
    ) public onlyStaker {
        require(_property > 0 && _flag >= 0, "proposalProperty: Invalid param");
        require(__isPaidFee(proposalFeeAmount), 'proposalProperty: Not paid fee');

        if(_flag == 0) {
            require(filmVotePeriod != _property, "proposalProperty: Already filmVotePeriod");
            filmVotePeriodList.push(_property);
        } else if(_flag == 1) {
            require(agentVotePeriod != _property, "proposalProperty: Already agentVotePeriod");
            agentVotePeriodList.push(_property);
        } else if(_flag == 2) {
            require(disputeGracePeriod != _property, "proposalProperty: Already disputeGracePeriod");
            disputeGracePeriodList.push(_property);
        } else if(_flag == 3) {
            require(propertyVotePeriod != _property, "proposalProperty: Already propertyVotePeriod");
            propertyVotePeriodList.push(_property);
        } else if(_flag == 4) {
            require(lockPeriod != _property, "proposalProperty: Already lockPeriod");
            lockPeriodList.push(_property);
        } else if(_flag == 5) {
            require(rewardRate != _property, "proposalProperty: Already rewardRate");
            rewardRateList.push(_property);
        } else if(_flag == 6) {
            require(extraRewardRate != _property, "proposalProperty: Already extraRewardRate");
            extraRewardRateList.push(_property);
        } else if(_flag == 7) {
            require(maxAllowPeriod != _property, "proposalProperty: Already maxAllowPeriod");
            maxAllowPeriodList.push(_property);
        } else if(_flag == 8) {
            require(proposalFeeAmount != _property, "proposalProperty: Already proposalFeeAmount");
            proposalFeeAmountList.push(_property);
        } else if(_flag == 9) {
            require(fundFeePercent != _property, "proposalProperty: Already fundFeePercent");
            fundFeePercentList.push(_property);
        } else if(_flag == 10) {
            require(minDepositAmount != _property, "proposalProperty: Already minDepositAmount");
            minDepositAmountList.push(_property);
        } else if(_flag == 11) {
            require(maxDepositAmount != _property, "proposalProperty: Already maxDepositAmount");
            maxDepositAmountList.push(_property);
        } else if(_flag == 12) {
            require(maxMintFeePercent != _property, "proposalProperty: Already maxMintFeePercent");
            maxMintFeePercentList.push(_property);
        } else if(_flag == 13) {
            require(minVoteCount != _property, "proposalProperty: Already minVoteCount");
            minVoteCountList.push(_property);
        } else if(_flag == 14) {
            require(minStakerCountPercent != _property, "proposalProperty: Already minStakerCountPercent");
            minStakerCountPercentList.push(_property);
        } else if(_flag == 15) {
            require(availableVABAmount != _property, "proposalProperty: Already availableVABAmount");
            availableVABAmountList.push(_property);
        } else if(_flag == 16) {
            require(boardVotePeriod != _property, "proposalProperty: Already boardVotePeriod");
            boardVotePeriodList.push(_property);
        } else if(_flag == 17) {
            require(boardVoteWeight != _property, "proposalProperty: Already boardVoteWeight");
            boardVoteWeightList.push(_property);
        } else if(_flag == 18) {
            require(rewardVotePeriod != _property, "proposalProperty: Already rewardVotePeriod");
            rewardVotePeriodList.push(_property);
        } else if(_flag == 19) {
            require(subscriptionAmount != _property, "proposalProperty: Already subscriptionAmount");
            subscriptionAmountList.push(_property);
        } else if(_flag == 20) {
            require(boardRewardRate != _property, "proposalProperty: Already boardRewardRate");
            boardRewardRateList.push(_property);
        }          
        
        governanceProposalCount += 1;     
        userGovernProposalCount[msg.sender] += 1;         

        Proposal storage pp = propertyProposalInfo[_flag][_property];
        pp.title = _title;
        pp.description = _description;
        pp.createTime = block.timestamp;
        pp.creator = msg.sender;
        pp.status = Helper.Status.LISTED;

        // add timestap to array for calculating rewards
        IStakingPool(STAKING_POOL).updateProposalCreatedTimeList(block.timestamp);

        emit PropertyProposalCreated(msg.sender, _property, _flag, _title, _description, block.timestamp);
    }

    function getProperty(
        uint256 _index, 
        uint256 _flag
    ) external view returns (uint256 property_) { 
        require(_flag >= 0 && _index >= 0, "getProperty: Invalid flag");   
        
        property_ = 0;
        if(_flag == 0 && filmVotePeriodList.length > 0 && filmVotePeriodList.length > _index) {
            property_ = filmVotePeriodList[_index];
        } else if(_flag == 1 && agentVotePeriodList.length > 0 && agentVotePeriodList.length > _index) {
            property_ = agentVotePeriodList[_index];
        } else if(_flag == 2 && disputeGracePeriodList.length > 0 && disputeGracePeriodList.length > _index) {
            property_ = disputeGracePeriodList[_index];
        } else if(_flag == 3 && propertyVotePeriodList.length > 0 && propertyVotePeriodList.length > _index) {
            property_ = propertyVotePeriodList[_index];
        } else if(_flag == 4 && lockPeriodList.length > 0 && lockPeriodList.length > _index) {
            property_ = lockPeriodList[_index];
        } else if(_flag == 5 && rewardRateList.length > 0 && rewardRateList.length > _index) {
            property_ = rewardRateList[_index];
        } else if(_flag == 6 && extraRewardRateList.length > 0 && extraRewardRateList.length > _index) {
            property_ = extraRewardRateList[_index];
        } else if(_flag == 7 && maxAllowPeriodList.length > 0 && maxAllowPeriodList.length > _index) {
            property_ = maxAllowPeriodList[_index];
        } else if(_flag == 8 && proposalFeeAmountList.length > 0 && proposalFeeAmountList.length > _index) {
            property_ = proposalFeeAmountList[_index];
        } else if(_flag == 9 && fundFeePercentList.length > 0 && fundFeePercentList.length > _index) {
            property_ = fundFeePercentList[_index];
        } else if(_flag == 10 && minDepositAmountList.length > 0 && minDepositAmountList.length > _index) {
            property_ = minDepositAmountList[_index];
        } else if(_flag == 11 && maxDepositAmountList.length > 0 && maxDepositAmountList.length > _index) {
            property_ = maxDepositAmountList[_index];
        } else if(_flag == 12 && maxMintFeePercentList.length > 0 && maxMintFeePercentList.length > _index) {
            property_ = maxMintFeePercentList[_index];
        } else if(_flag == 13 && minVoteCountList.length > 0 && minVoteCountList.length > _index) {
            property_ = minVoteCountList[_index];
        } else if(_flag == 14 && minStakerCountPercentList.length > 0 && minStakerCountPercentList.length > _index) {
            property_ = minStakerCountPercentList[_index];
        } else if(_flag == 15 && availableVABAmountList.length > 0 && availableVABAmountList.length > _index) {
            property_ = availableVABAmountList[_index];
        } else if(_flag == 16 && boardVotePeriodList.length > 0 && boardVotePeriodList.length > _index) {
            property_ = boardVotePeriodList[_index];
        } else if(_flag == 17 && boardVoteWeightList.length > 0 && boardVoteWeightList.length > _index) {
            property_ = boardVoteWeightList[_index];
        } else if(_flag == 18 && rewardVotePeriodList.length > 0 && rewardVotePeriodList.length > _index) {
            property_ = rewardVotePeriodList[_index];
        } else if(_flag == 19 && subscriptionAmountList.length > 0 && subscriptionAmountList.length > _index) {
            property_ = subscriptionAmountList[_index];
        } else if(_flag == 20 && boardRewardRateList.length > 0 && boardRewardRateList.length > _index) {
            property_ = boardRewardRateList[_index];
        }                      
    }

    function updateProperty(
        uint256 _index, 
        uint256 _flag
    ) external onlyVote {
        require(_flag >= 0 && _index >= 0, "updateProperty: Invalid flag");   

        if(_flag == 0) {
            filmVotePeriod = filmVotePeriodList[_index];
            emit PropertyUpdated(msg.sender, filmVotePeriod, _flag, block.timestamp);
        } else if(_flag == 1) {
            agentVotePeriod = agentVotePeriodList[_index];
            emit PropertyUpdated(msg.sender, agentVotePeriod, _flag, block.timestamp);
        } else if(_flag == 2) {
            disputeGracePeriod = disputeGracePeriodList[_index];
            emit PropertyUpdated(msg.sender, disputeGracePeriod, _flag, block.timestamp);
        } else if(_flag == 3) {
            propertyVotePeriod = propertyVotePeriodList[_index];
            emit PropertyUpdated(msg.sender, propertyVotePeriod, _flag, block.timestamp);
        } else if(_flag == 4) {
            lockPeriod = lockPeriodList[_index];
            emit PropertyUpdated(msg.sender, lockPeriod, _flag, block.timestamp);
        } else if(_flag == 5) {
            rewardRate = rewardRateList[_index];
            emit PropertyUpdated(msg.sender, rewardRate, _flag, block.timestamp);
        } else if(_flag == 6) {
            extraRewardRate = extraRewardRateList[_index];
            emit PropertyUpdated(msg.sender, extraRewardRate, _flag, block.timestamp);
        } else if(_flag == 7) {
            maxAllowPeriod = maxAllowPeriodList[_index];
            emit PropertyUpdated(msg.sender, maxAllowPeriod, _flag, block.timestamp);        
        } else if(_flag == 8) {
            proposalFeeAmount = proposalFeeAmountList[_index];
            emit PropertyUpdated(msg.sender, proposalFeeAmount, _flag, block.timestamp);        
        } else if(_flag == 9) {
            fundFeePercent = fundFeePercentList[_index];
            emit PropertyUpdated(msg.sender, fundFeePercent, _flag, block.timestamp);        
        } else if(_flag == 10) {
            minDepositAmount = minDepositAmountList[_index];
            emit PropertyUpdated(msg.sender, minDepositAmount, _flag, block.timestamp);        
        } else if(_flag == 11) {
            maxDepositAmount = maxDepositAmountList[_index];
            emit PropertyUpdated(msg.sender, maxDepositAmount, _flag, block.timestamp);        
        } else if(_flag == 12) {
            maxMintFeePercent = maxMintFeePercentList[_index];
            emit PropertyUpdated(msg.sender, maxMintFeePercent, _flag, block.timestamp);     
        } else if(_flag == 13) {
            minVoteCount = minVoteCountList[_index];
            emit PropertyUpdated(msg.sender, minVoteCount, _flag, block.timestamp);     
        } else if(_flag == 14) {
            minStakerCountPercent = minStakerCountPercentList[_index];
            emit PropertyUpdated(msg.sender, minStakerCountPercent, _flag, block.timestamp);     
        } else if(_flag == 15) {
            availableVABAmount = availableVABAmountList[_index];
            emit PropertyUpdated(msg.sender, availableVABAmount, _flag, block.timestamp);     
        } else if(_flag == 16) {
            boardVotePeriod = boardVotePeriodList[_index];
            emit PropertyUpdated(msg.sender, boardVotePeriod, _flag, block.timestamp);     
        } else if(_flag == 17) {
            boardVoteWeight = boardVoteWeightList[_index];
            emit PropertyUpdated(msg.sender, boardVoteWeight, _flag, block.timestamp);     
        } else if(_flag == 18) {
            rewardVotePeriod = rewardVotePeriodList[_index];
            emit PropertyUpdated(msg.sender, rewardVotePeriod, _flag, block.timestamp);     
        } else if(_flag == 19) {
            subscriptionAmount = subscriptionAmountList[_index];
            emit PropertyUpdated(msg.sender, subscriptionAmount, _flag, block.timestamp);     
        } else if(_flag == 20) {
            boardRewardRate = boardRewardRateList[_index];
            emit PropertyUpdated(msg.sender, boardRewardRate, _flag, block.timestamp);     
        }         
    }

    /// @notice Get property proposal list
    function getPropertyProposalList(uint256 _flag) public view returns (uint256[] memory _list) {
        if(_flag == 0) _list = filmVotePeriodList;
        else if(_flag == 1) _list = agentVotePeriodList;
        else if(_flag == 2) _list = disputeGracePeriodList;
        else if(_flag == 3) _list = propertyVotePeriodList;
        else if(_flag == 4) _list = lockPeriodList;
        else if(_flag == 5) _list = rewardRateList;
        else if(_flag == 6) _list = extraRewardRateList;
        else if(_flag == 7) _list = maxAllowPeriodList;
        else if(_flag == 8) _list = proposalFeeAmountList;
        else if(_flag == 9) _list = fundFeePercentList;
        else if(_flag == 10) _list = minDepositAmountList;
        else if(_flag == 11) _list = maxDepositAmountList;
        else if(_flag == 12) _list = maxMintFeePercentList;
        else if(_flag == 13) _list = minVoteCountList;        
        else if(_flag == 14) _list = minStakerCountPercentList;     
        else if(_flag == 15) _list = availableVABAmountList;     
        else if(_flag == 16) _list = boardVotePeriodList;     
        else if(_flag == 17) _list = boardVoteWeightList;     
        else if(_flag == 18) _list = rewardVotePeriodList;     
        else if(_flag == 19) _list = subscriptionAmountList;     
        else if(_flag == 20) _list = boardRewardRateList;                                   
    }

    /// @notice Get property proposal created time
    function getPropertyProposalTime(
        uint256 _property, 
        uint256 _flag
    ) external view returns (uint256 cTime_, uint256 aTime_) {
        cTime_ = propertyProposalInfo[_flag][_property].createTime;
        aTime_ = propertyProposalInfo[_flag][_property].approveTime;
    }
    
    /// @notice Get agent/board/pool proposal created time
    function getGovProposalTime(
        address _member, 
        uint256 _flag
    ) external view returns (uint256 cTime_, uint256 aTime_) {
        if(_flag == 1) {
            cTime_ = agentProposalInfo[_member].createTime;
            aTime_ = agentProposalInfo[_member].approveTime;
        } else if(_flag == 2) {
            cTime_ = boardProposalInfo[_member].createTime;
            aTime_ = boardProposalInfo[_member].approveTime;
        } else if(_flag == 3) {
            cTime_ = rewardProposalInfo[_member].createTime;
            aTime_ = rewardProposalInfo[_member].approveTime;
        }
    }

    function updatePropertyProposalApproveTime(
        uint256 _property, 
        uint256 _flag, 
        uint256 _approveStatus
    ) external onlyVote {
        propertyProposalInfo[_flag][_property].approveTime = block.timestamp;
        if(_approveStatus == 1) propertyProposalInfo[_flag][_property].status = Helper.Status.UPDATED;
        else propertyProposalInfo[_flag][_property].status = Helper.Status.REJECTED;
    }

    function updateGovProposalApproveTime(
        address _member, 
        uint256 _flag, 
        uint256 _approveStatus
    ) external onlyVote {
        if(_flag == 1) {
            agentProposalInfo[_member].approveTime = block.timestamp;
            if(_approveStatus == 1) agentProposalInfo[_member].status = Helper.Status.UPDATED;
            else agentProposalInfo[_member].status = Helper.Status.REJECTED;
        } else if(_flag == 2) {
            boardProposalInfo[_member].approveTime = block.timestamp;
            if(_approveStatus == 1) boardProposalInfo[_member].status = Helper.Status.UPDATED;
            else boardProposalInfo[_member].status = Helper.Status.REJECTED;
        } else if(_flag == 3) {
            rewardProposalInfo[_member].approveTime = block.timestamp;
            if(_approveStatus == 1) rewardProposalInfo[_member].status = Helper.Status.UPDATED;
            else rewardProposalInfo[_member].status = Helper.Status.REJECTED;
        }
    }
    
    ///================ @dev Update the property value for only testing in the testnet
    // we won't deploy this function in the mainnet
    function updatePropertyForTesting(
        uint256 _value, 
        uint256 _flag
    ) external onlyAuditor {
        require(_value > 0, "test: Zero value");

        if(_flag == 0) filmVotePeriod = _value;
        else if(_flag == 1) agentVotePeriod = _value;
        else if(_flag == 2) disputeGracePeriod = _value;
        else if(_flag == 3) propertyVotePeriod = _value;
        else if(_flag == 4) lockPeriod = _value;
        else if(_flag == 5) rewardRate = _value;
        else if(_flag == 6) extraRewardRate = _value;
        else if(_flag == 7) maxAllowPeriod = _value;
        else if(_flag == 8) proposalFeeAmount = _value;
        else if(_flag == 9) fundFeePercent = _value;
        else if(_flag == 10) minDepositAmount = _value;
        else if(_flag == 11) maxDepositAmount = _value;
        else if(_flag == 12) maxMintFeePercent = _value;
        else if(_flag == 13) availableVABAmount = _value;
        else if(_flag == 14) boardVotePeriod = _value;
        else if(_flag == 15) boardVoteWeight = _value;
        else if(_flag == 16) rewardVotePeriod = _value;
        else if(_flag == 17) subscriptionAmount = _value;
        else if(_flag == 18) minVoteCount = _value;        
        else if(_flag == 19) minStakerCountPercent = _value;                
    }

    /// @dev Update the rewardAddress for only testing in the testnet
    function updateDAOFundForTesting(address _address) external onlyAuditor {        
        DAO_FUND_REWARD = _address;    
    }
        
}

// ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
// 88             88            B8         B8         B8
//  88           88             88         88         88
//   88         88              88         88         88 
//    88       88   .d88888b.   88b8888b.  88b8888b.  88  .d88888b. 
//     88     88    88'   `88   88'   `88  88'   `88  88  88'   `8b
//      88   88     88     88   88     88  88     88  88  88b8888P`
//       88 88      88.   .88   88.   .88  88.   .88  88  88.   
//        88        `88888P`88  BBP88888'  BBP88888`  88  `888888P
// ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../libraries/Helper.sol";
import "../interfaces/IUniHelper.sol";
import "../interfaces/IStakingPool.sol";
import "../interfaces/IProperty.sol";
import "../interfaces/IOwnablee.sol";
import "../interfaces/IFactoryFilmNFT.sol";
import "../interfaces/IVabbleDAO.sol";
import "hardhat/console.sol";

contract VabbleDAO is ReentrancyGuard {
    using Counters for Counters.Counter;

    event FilmProposalCreated(uint256 filmId, uint256 noVote, uint256 fundType, address studio, uint256 createTime);
    event FilmProposalUpdated(uint256 filmId, uint256 fundType, address studio, uint256 updateTime);  
    event FinalFilmSetted(address[] users, uint256[] filmIds, uint256[] watchedPercents, uint256[] rentPrices, uint256 setTime);
    event FilmFundPeriodUpdated(uint256 filmId, address studio, uint256 fundPeriod, uint256 updateTime);
    event AllocatedToPool(address[] users, uint256[] amounts, uint256 which);
    
    address public immutable OWNABLE;         // Ownablee contract address
    address public immutable VOTE;            // Vote contract address
    address public immutable STAKING_POOL;    // StakingPool contract address
    address public immutable UNI_HELPER;      // UniHelper contract address
    address public immutable DAO_PROPERTY;
    address public immutable FILM_NFT_FACTORY;  
    
    uint256[] private proposalFilmIds;    
    uint256[] private approvedFundingFilmIds;
    uint256[] private approvedListingFilmIds;
    address[] private studioPoolUsers;            // (which => user list)
    address[] private edgePoolUsers;              // (which => user list)

    mapping(uint256 => IVabbleDAO.Film) public filmInfo;              // Each film information(filmId => Film)
    mapping(address => uint256[]) private userFilmProposalIds;        // (studio => filmId list)
    mapping(address => uint256[]) private userApprovedFilmIds;        // (studio => filmId list)    

    uint256 public StudioPool; 
    uint256 public finalFilmCalledTime;

    Counters.Counter public filmCount;          // filmId is from No.1

    modifier onlyAuditor() {
        require(msg.sender == IOwnablee(OWNABLE).auditor(), "caller is not the auditor");
        _;
    }  
    modifier onlyVote() {
        require(msg.sender == VOTE, "caller is not the vote contract");
        _;
    }
    modifier onlyStakingPool() {
        require(msg.sender == STAKING_POOL, "caller is not the StakingPool contract");
        _;
    }

    receive() external payable {}
    
    constructor(
        address _ownable,
        address _uniHelper,
        address _vote,
        address _staking,
        address _property,
        address _filmNftFactory
    ) {        
        require(_ownable != address(0), "ownableContract: Zero address");
        OWNABLE = _ownable;     
        require(_uniHelper != address(0), "uniHelperContract: Zero address");
        UNI_HELPER = _uniHelper;
        require(_vote != address(0), "voteContract: Zero address");
        VOTE = _vote;
        require(_staking != address(0), "stakingContract: Zero address");
        STAKING_POOL = _staking;      
        require(_property != address(0), "daoProperty: Zero address");
        DAO_PROPERTY = _property; 
        require(_filmNftFactory!= address(0), "setup: zero factoryContract address");
        FILM_NFT_FACTORY = _filmNftFactory;  
    }

    // ======================== Film proposal ==============================
    /// @notice Staker create multi proposal for a lot of films | noVote: if 0 => false, 1 => true
    /// _feeToken : Matic/USDC/USDT, not VAB
    function proposalFilmCreate(uint256 _fundType, uint256 _noVote, address _feeToken) external payable nonReentrant {     
        require(_feeToken != IOwnablee(OWNABLE).PAYOUT_TOKEN(), "proposalFilm: not allowed VAB");
        if(_feeToken != address(0)) {
            require(IOwnablee(OWNABLE).isDepositAsset(_feeToken), "proposalFilm: not allowed asset");   
        }
        if(_fundType == 0) require(_noVote == 0, "proposalFilm: should pass vote");
        
        __paidFee(_feeToken, _noVote);
 
        filmCount.increment();
        uint256 filmId = filmCount.current();

        IVabbleDAO.Film storage fInfo = filmInfo[filmId];
        fInfo.fundType = _fundType;
        fInfo.noVote = _noVote;
        fInfo.studio = msg.sender;
        fInfo.status = Helper.Status.LISTED;

        proposalFilmIds.push(filmId);
        userFilmProposalIds[msg.sender].push(filmId);

        emit FilmProposalCreated(filmId, _noVote, _fundType, msg.sender, block.timestamp);
    }
    function proposalFilmUpdate(
        uint256 _filmId, 
        string memory _title,
        string memory _description,
        uint256[] memory _sharePercents,
        address[] memory _studioPayees,
        uint256 _raiseAmount,
        uint256 _fundPeriod,
        uint256 _enableClaimer
    ) public {                
        require(_studioPayees.length > 0, 'proposalUpdate: empty payees');
        require(_studioPayees.length == _sharePercents.length, 'proposalUpdate: invalid share percent');

        IVabbleDAO.Film storage fInfo = filmInfo[_filmId];
        if(fInfo.fundType > 0) {            
            require(_fundPeriod > 0, 'proposalUpdate: invalid fund period');
            require(_raiseAmount > IProperty(DAO_PROPERTY).minDepositAmount(), 'proposalUpdate: invalid raise amount');
        }

        uint256 totalPercent = 0;
        if(_studioPayees.length == 1) totalPercent = _sharePercents[0];
        else {
            for(uint256 i = 0; i < _studioPayees.length; i++) {
                totalPercent += _sharePercents[i];
            }
        }
        require(totalPercent == 1e10, 'proposalUpdate: total percent should be 100%');
        
        require(fInfo.status == Helper.Status.LISTED, 'proposalUpdate: Not listed');
        require(fInfo.studio == msg.sender, 'proposalUpdate: not film owner');

        fInfo.title = _title;
        fInfo.description = _description;
        fInfo.sharePercents = _sharePercents;
        fInfo.studioPayees = _studioPayees;    
        fInfo.raiseAmount = _raiseAmount;
        fInfo.fundPeriod = _fundPeriod;
        fInfo.enableClaimer = _enableClaimer;
        fInfo.pCreateTime = block.timestamp;
        fInfo.studio = msg.sender;
        fInfo.status = Helper.Status.UPDATED;

        IStakingPool(STAKING_POOL).updateProposalCreatedTimeList(block.timestamp); // add timestap to array for calculating rewards

        // If proposal is for fund, update "lastfundProposalCreateTime"
        if(fInfo.fundType > 0) {
            IStakingPool(STAKING_POOL).updateLastfundProposalCreateTime(block.timestamp);

            if(fInfo.noVote == 1) {
                fInfo.status = Helper.Status.APPROVED_FUNDING;
                fInfo.pApproveTime = block.timestamp;
                approvedFundingFilmIds.push(_filmId);
                userApprovedFilmIds[msg.sender].push(_filmId);
            } 
        }       

        emit FilmProposalUpdated(_filmId, fInfo.fundType, msg.sender, block.timestamp);     
    }

    /// @notice Check if proposal fee transferred from studio to stakingPool
    // Get expected VAB amount from UniswapV2 and then Transfer VAB: user(studio) -> stakingPool.
    function __paidFee(address _dToken, uint256 _noVote) private {    
        uint256 feeAmount = IProperty(DAO_PROPERTY).proposalFeeAmount(); // in cash(usdc)
        if(_noVote == 1) feeAmount = IProperty(DAO_PROPERTY).proposalFeeAmount() * 2;
        
        uint256 expectTokenAmount = feeAmount;
        if(_dToken != IOwnablee(OWNABLE).USDC_TOKEN()) {
            expectTokenAmount = IUniHelper(UNI_HELPER).expectedAmount(feeAmount, IOwnablee(OWNABLE).USDC_TOKEN(), _dToken);
        }

        if(_dToken == address(0)) {
            require(msg.value >= expectTokenAmount, "paidFee: Insufficient paid");
            if (msg.value > expectTokenAmount) {
                Helper.safeTransferETH(msg.sender, msg.value - expectTokenAmount);
            }
            // Send ETH from this contract to UNI_HELPER contract
            Helper.safeTransferETH(UNI_HELPER, expectTokenAmount);
        } else {
            Helper.safeTransferFrom(_dToken, msg.sender, address(this), expectTokenAmount);
            if(IERC20(_dToken).allowance(address(this), UNI_HELPER) == 0) {
                Helper.safeApprove(_dToken, UNI_HELPER, IERC20(_dToken).totalSupply());
            }
        }                
        
        address vabToken = IOwnablee(OWNABLE).PAYOUT_TOKEN();
        bytes memory swapArgs = abi.encode(expectTokenAmount, _dToken, vabToken);
        uint256 vabAmount = IUniHelper(UNI_HELPER).swapAsset(swapArgs);    
        
        if(IERC20(vabToken).allowance(address(this), STAKING_POOL) == 0) {
            Helper.safeApprove(vabToken, STAKING_POOL, IERC20(vabToken).totalSupply());
        }  
        IStakingPool(STAKING_POOL).addRewardToPool(vabAmount);
    } 

    /// @notice Approve a film for funding/listing from vote contract
    function approveFilmByVote(uint256 _filmId, uint256 _flag) external onlyVote {
        require(_filmId > 0, "approveFilmByVote: Invalid filmId"); 

        filmInfo[_filmId].pApproveTime = block.timestamp;

        (, , uint256 fundType) = getFilmFund(_filmId);
        if(_flag == 0) {
            if(fundType > 0) { // in case of fund film
                filmInfo[_filmId].status = Helper.Status.APPROVED_FUNDING;
                approvedFundingFilmIds.push(_filmId);
            } else {
                filmInfo[_filmId].status = Helper.Status.APPROVED_LISTING;    
                approvedListingFilmIds.push(_filmId);
            }        
            address studioA = filmInfo[_filmId].studio;
            userApprovedFilmIds[studioA].push(_filmId);
        } else {
            filmInfo[_filmId].status = Helper.Status.REJECTED;
        } 
    }

    /// @notice onlyStudio update film fund period
    function updateFilmFundPeriod(uint256 _filmId, uint256 _fundPeriod) external nonReentrant {
        require(msg.sender == filmInfo[_filmId].studio, "updateFundPeriod: not film owner");
        require(filmInfo[_filmId].fundType > 0, "updateFundPeriod: not fund film");

        filmInfo[_filmId].fundPeriod = _fundPeriod;
        
        emit FilmFundPeriodUpdated(_filmId, msg.sender, _fundPeriod, block.timestamp);
    }   

    /// @notice Allocate VAB from StakingPool(user balance) to EdgePool(Ownable)/StudioPool(VabbleDAO) by Auditor
    // _which = 1 => to EdgePool, _which = 2 => to StudioPool
    function allocateToPool(
        address[] memory _users,
        uint256[] memory _amounts,
        uint256 _which
    ) external onlyAuditor nonReentrant {
        require(_users.length == _amounts.length, "allocate: bad array");
        require(_which == 1 || _which == 2, "allocate: bad from value");

        if(_which == 1) {            
            IStakingPool(STAKING_POOL).sendVAB(_users, OWNABLE, _amounts);
        } else {
            StudioPool += IStakingPool(STAKING_POOL).sendVAB(_users, address(this), _amounts);
        }

        for(uint256 i = 0; i < _users.length; i++) {   
            if(_which == 1) {
                edgePoolUsers.push(_users[i]);
            } else {
                studioPoolUsers.push(_users[i]);
            }
        }

        emit AllocatedToPool(_users, _amounts, _which);
    }

    /// @notice Allocate VAB from EdgePool(Ownable) to StudioPool(VabbleDAO) by Auditor
    function allocateFromEdgePool(uint256 _amount) external onlyAuditor nonReentrant {
        IOwnablee(OWNABLE).addToStudioPool(_amount);
        StudioPool += _amount;

        for(uint256 i = 0; i < edgePoolUsers.length; i++) {   
            studioPoolUsers.push(edgePoolUsers[i]);
        }

        delete edgePoolUsers;
    }

    /// @notice Withdraw VAB token from StudioPool(VabbleDAO) to V2 by StakingPool contract
    function withdrawVABFromStudioPool(address _to) external onlyStakingPool returns (uint256) {
        address vabToken = IOwnablee(OWNABLE).PAYOUT_TOKEN();    
        uint256 poolBalance = IERC20(vabToken).balanceOf(address(this));    

        if(poolBalance >= StudioPool && StudioPool > 0) {
            Helper.safeTransfer(vabToken, _to, poolBalance);
            
            StudioPool = 0;
            delete studioPoolUsers;
        }
        
        return poolBalance;
    }

    /// @notice Set final films for a customer with watched 
    // Auditor call this function per month
    function setFinalFilms(        
        uint256[] memory _filmIds,
        uint256[] memory _payouts // VAB to payees based on share(%) and watch(%) from offchain
    ) external onlyAuditor nonReentrant {
        require(_filmIds.length > 0 && _filmIds.length == _payouts.length, "final: bad length");
        require(_filmIds.length == studioPoolUsers.length, "final: bad pool users");
        if(finalFilmCalledTime > 0) {
            require(block.timestamp - finalFilmCalledTime >= 30 days, "final: can be called once per 30 days");
        }

        address vabToken = IOwnablee(OWNABLE).PAYOUT_TOKEN();
        for(uint256 i = 0; i < _filmIds.length; i++) {     
            __setFinalFilm(studioPoolUsers[i], vabToken, _filmIds[i], _payouts[i]);
        }

        delete studioPoolUsers;
        finalFilmCalledTime = block.timestamp;
    }
    
    function __setFinalFilm(
        address _user,
        address _vabToken,
        uint256 _filmId, 
        uint256 _payout  
    ) private {     
        IVabbleDAO.Film memory fInfo = filmInfo[_filmId];
        require(fInfo.status == Helper.Status.APPROVED_LISTING, "final: Not approved listing film");
        require(StudioPool >= _payout, "final: insufficient studio pool");
        require(IERC20(_vabToken).balanceOf(address(this)) >= _payout, "final: insufficient balance");
                     
        for(uint256 k = 0; k < fInfo.studioPayees.length; k++) {
            uint256 shareAmount = _payout * fInfo.sharePercents[k] / 1e10;
            Helper.safeTransfer(IOwnablee(OWNABLE).PAYOUT_TOKEN(), fInfo.studioPayees[k], shareAmount);
        }        
        
        StudioPool -= _payout;        

        __payRevenue(_user, _vabToken, _filmId, _payout);   
    }     

    // TODO revenue    
    // Transfer revenue amount to user if user fund to this film throughout NFT mint
    function __payRevenue(
        address _user,
        address _vabToken,
        uint256 _filmId,
        uint256 _payout
    ) private {
        uint256 nftCountOwned;
        uint256[] memory nftList = IFactoryFilmNFT(FILM_NFT_FACTORY).getFilmTokenIdList(_filmId);
        for(uint256 i = 0; i < nftList.length; i++) {
            if(IERC721(FILM_NFT_FACTORY).ownerOf(nftList[i]) == _user) nftCountOwned += 1;
        }        

        ( , , , , uint256 revenuePercent, ,) = IFactoryFilmNFT(FILM_NFT_FACTORY).getMintInfo(_filmId);
        uint256 revenueAmount = nftCountOwned * _payout * revenuePercent / 1e10;
        if(_payout >= revenueAmount && revenueAmount > 0) {
            require(StudioPool >= revenueAmount, "revenue: insufficient studio pool");
            require(IERC20(_vabToken).balanceOf(address(this)) >= revenueAmount, "revenue: insufficient balance");
            
            Helper.safeTransfer(IOwnablee(OWNABLE).PAYOUT_TOKEN(), _user, revenueAmount);
            StudioPool -= revenueAmount; 
        }
    }
    
    /// @notice Get film status based on Id
    function getFilmStatus(uint256 _filmId) external view returns (Helper.Status status_) {
        status_ = filmInfo[_filmId].status;
    }

    /// @notice Get film owner(studio) based on Id
    function getFilmOwner(uint256 _filmId) external view returns (address owner_) {
        owner_ = filmInfo[_filmId].studio;
    }

    /// @notice Get film fund info based on Id
    function getFilmFund(uint256 _filmId) public view 
    returns (
        uint256 raiseAmount_, 
        uint256 fundPeriod_, 
        uint256 fundType_
    ) {
        raiseAmount_ = filmInfo[_filmId].raiseAmount;
        fundPeriod_ = filmInfo[_filmId].fundPeriod;
        fundType_ = filmInfo[_filmId].fundType;
    }

    /// @notice Get film fund info based on Id
    function getFilmShare(uint256 _filmId) external view 
    returns (
        uint256[] memory sharePercents_, 
        address[] memory studioPayees_
    ) {
        sharePercents_ = filmInfo[_filmId].sharePercents;
        studioPayees_ = filmInfo[_filmId].studioPayees;
    }

    /// @notice Get film proposal created time based on Id
    function getFilmProposalTime(uint256 _filmId) external view returns (uint256 cTime_, uint256 aTime_) {
        cTime_ = filmInfo[_filmId].pCreateTime;
        aTime_ = filmInfo[_filmId].pApproveTime;
    }

    /// @notice Get enableClaimer based on Id
    function isEnabledClaimer(uint256 _filmId) external view returns (bool enable_) {
        if(filmInfo[_filmId].enableClaimer == 1) enable_ = true;
        else enable_ = false;
    }
    
    /// @notice Set enableClaimer based on Id by studio
    function updateEnabledClaimer(uint256 _filmId, uint256 _enable) external {
        require(filmInfo[_filmId].studio == msg.sender, "updateEnableClaimer: not film owner");

        filmInfo[_filmId].enableClaimer = _enable;
    }

    /// @notice Get film Ids
    function getFilmIds(uint256 _flag) external view returns (uint256[] memory list_) {        
        if(_flag == 1) list_ = proposalFilmIds;
        else if(_flag == 2) list_ = approvedListingFilmIds;        
        else if(_flag == 3) list_ = approvedFundingFilmIds;
    }

    function getUserFilmIds(uint256 _flag, address _user) external view returns (uint256[] memory list_) {        
        if(_flag == 2) list_ = userFilmProposalIds[_user];
        else if(_flag == 3) list_ = userApprovedFilmIds[_user];
    }

    function getUserFilmListForMigrate(address _user) external view returns (IVabbleDAO.Film[] memory filmList_) {   
        IVabbleDAO.Film memory fInfo;
        uint256[] memory ids = userApprovedFilmIds[_user];
        require(ids.length > 0, "migrate: no film");

        filmList_ = new IVabbleDAO.Film[](ids.length);
        for(uint256 i = 0; i < ids.length; i++) {             
            fInfo = filmInfo[ids[i]];
            require(fInfo.studio == _user, "migrate: not film owner");

            if(fInfo.status == Helper.Status.APPROVED_FUNDING || fInfo.status == Helper.Status.APPROVED_LISTING) {
                filmList_[i] = fInfo;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/Helper.sol";
import "../interfaces/IVabbleDAO.sol";
import "../interfaces/IStakingPool.sol";
import "../interfaces/IProperty.sol";
import "../interfaces/IOwnablee.sol";

contract Vote is ReentrancyGuard {

    event VotedToFilm(address voter, uint256 filmId, uint256 voteInfo, uint256 voteTime);
    event VotedToAgent(address voter, address agent, uint256 voteInfo, uint256 voteTime);
    event VotedToProperty(address voter, uint256 flag, uint256 propertyVal, uint256 voteInfo, uint256 voteTime);
    event VotedToPoolAddress(address voter, address rewardAddress, uint256 voteInfo, uint256 voteTime);
    event VotedToFilmBoard(address voter, address candidate, uint256 voteInfo, uint256 voteTime);
       
    event FilmApproved(uint256 filmId, uint256 fundType, uint256 approveTime, uint256 reason);
    event AuditorReplaced(address agent, address caller, uint256 replaceTime, uint256 reason);
    event FilmBoardAdded(address boardMember, address caller, uint256 addTime, uint256 reason);
    event PoolAddressAdded(address pool, address caller, uint256 addTime, uint256 reason);
    event PropertyUpdated(uint256 whichProperty, uint256 propertyValue, address caller, uint256 updateTime, uint256 reason);
    
    struct Voting {
        uint256 stakeAmount_1;  // staking amount of voter with status(yes)
        uint256 stakeAmount_2;  // staking amount of voter with status(no)
        uint256 stakeAmount_3;  // staking amount of voter with status(abstain)
        uint256 voteCount_1;    // number of accumulated votes(yes)
        uint256 voteCount_2;    // number of accumulated votes(no)
        uint256 voteCount_3;    // number of accumulated votes(abstain)
    }

    struct AgentVoting {
        uint256 stakeAmount_1;    // staking amount of voter with status(yes)
        uint256 stakeAmount_2;    // staking amount of voter with status(no)
        uint256 stakeAmount_3;    // staking amount of voter with status(abstain)
        uint256 voteCount_1;      // number of accumulated votes(yes)
        uint256 voteCount_2;      // number of accumulated votes(no)
        uint256 voteCount_3;      // number of accumulated votes(abstain)
        uint256 disputeStartTime; // dispute vote start time for an agent
        uint256 disputeVABAmount; // VAB voted dispute
    }

    address private immutable OWNABLE;     // Ownablee contract address
    address private VABBLE_DAO;
    address private STAKING_POOL;
    address private DAO_PROPERTY;
             
    bool public isInitialized;         // check if contract initialized or not

    mapping(uint256 => Voting) public filmVoting;                            // (filmId => Voting)
    mapping(address => mapping(uint256 => bool)) public isAttendToFilmVote;  // (staker => (filmId => true/false))
    mapping(address => Voting) public filmBoardVoting;                       // (filmBoard candidate => Voting) 
    mapping(address => mapping(address => bool)) public isAttendToBoardVote; // (staker => (filmBoard candidate => true/false))    
    mapping(address => Voting) public rewardAddressVoting;                   // (rewardAddress candidate => Voting)  
    mapping(address => mapping(address => bool)) public isAttendToRewardAddressVote; // (staker => (reward address => true/false))    
    mapping(address => AgentVoting) public agentVoting;                      // (agent => AgentVoting) 
    mapping(address => mapping(address => bool)) public isAttendToAgentVote; // (staker => (agent => true/false)) 
    mapping(uint256 => mapping(uint256 => Voting)) public propertyVoting;    // (flag => (property value => Voting))
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) public isAttendToPropertyVote; // (flag => (staker => (property => true/false)))    
    mapping(address => uint256) public userFilmVoteCount;   //(user => film vote count)
    mapping(address => uint256) public userGovernVoteCount; //(user => governance vote count)
    mapping(uint256 => uint256) public govPassedVoteCount;  //(flag => pased vote count) 1: agent, 2: disput, 3: board, 4: pool, 5: property    
    mapping(address => uint256) private lastVoteTime;        // (staker => block.timestamp) for removing filmboard member
    // For extra reward
    mapping(address => uint256[]) private fundingFilmIdsPerUser;                         // (staker => filmId[] for only funding)
    mapping(address => mapping(uint256 => uint256)) private fundingIdsVoteStatusPerUser; // (staker => (filmId => voteInfo) for only funing) 1,2,3
        
    modifier initialized() {
        require(isInitialized, "Need initialized!");
        _;
    }
    modifier onlyAuditor() {
        require(msg.sender == IOwnablee(OWNABLE).auditor(), "caller is not the auditor");
        _;
    }
    modifier onlyStaker() {
        require(IStakingPool(STAKING_POOL).getStakeAmount(msg.sender) > 0, "Not staker");
        _;
    }

    constructor(address _ownable) {
        require(_ownable != address(0), "ownableContract: Zero address");
        OWNABLE = _ownable; 
    }

    /// @notice Initialize Vote
    function initializeVote(
        address _vabbleDAO,
        address _stakingPool,
        address _property
    ) external onlyAuditor {
        require(_vabbleDAO != address(0), "initializeVote: Zero vabbleDAO address");
        VABBLE_DAO = _vabbleDAO;        
        require(_stakingPool != address(0), "initializeVote: Zero stakingPool address");
        STAKING_POOL = _stakingPool;
        require(_property != address(0), "initializeVote: Zero property address");
        DAO_PROPERTY = _property;
           
        isInitialized = true;
    }        

    /// @notice Vote to multi films from a staker
    function voteToFilms(
        uint256[] memory _filmIds, 
        uint256[] memory _voteInfos
    ) external onlyStaker initialized nonReentrant {
        require(_filmIds.length > 0, "voteToFilm: zero length");
        require(_filmIds.length == _voteInfos.length, "voteToFilm: Bad item length");

        for(uint256 i = 0; i < _filmIds.length; i++) { 
            __voteToFilm(_filmIds[i], _voteInfos[i]);
        }        
    }

    function __voteToFilm(
        uint256 _filmId, 
        uint256 _voteInfo
    ) private {
        require(msg.sender != IVabbleDAO(VABBLE_DAO).getFilmOwner(_filmId), "filmVote: film owner");
        require(!isAttendToFilmVote[msg.sender][_filmId], "_voteToFilm: Already voted");    

        Helper.Status status = IVabbleDAO(VABBLE_DAO).getFilmStatus(_filmId);
        require(status == Helper.Status.UPDATED, "Not updated");        

        (uint256 pCreateTime, ) = IVabbleDAO(VABBLE_DAO).getFilmProposalTime(_filmId);
        require(pCreateTime > 0, "not updated");
        require(__isVotePeriod(IProperty(DAO_PROPERTY).filmVotePeriod(), pCreateTime), "film elapsed vote period");
        
        uint256 stakeAmount = IStakingPool(STAKING_POOL).getStakeAmount(msg.sender);
        (, , uint256 fundType) = IVabbleDAO(VABBLE_DAO).getFilmFund(_filmId);
        if(fundType > 0) { // in case of fund film
            // If film is for funding and voter is film board member, more weight(30%) per vote
            if(IProperty(DAO_PROPERTY).isBoardWhitelist(msg.sender) == 2) {
                stakeAmount *= (IProperty(DAO_PROPERTY).boardVoteWeight() + 1e10) / 1e10; // (30+100)/100=1.3
            }
            //For extra reward in funding film case
            fundingFilmIdsPerUser[msg.sender].push(_filmId);
            fundingIdsVoteStatusPerUser[msg.sender][_filmId] = _voteInfo;
        }

        Voting storage fv = filmVoting[_filmId];
        if(_voteInfo == 1) {
            fv.stakeAmount_1 += stakeAmount;   // Yes
            fv.voteCount_1++;
        } else if(_voteInfo == 2) {
            fv.stakeAmount_2 += stakeAmount;   // No
            fv.voteCount_2++;
        } else {
            fv.stakeAmount_3 += stakeAmount;   // Abstain
            fv.voteCount_3++;
        }

        userFilmVoteCount[msg.sender] += 1;

        isAttendToFilmVote[msg.sender][_filmId] = true;
        
        // for removing board member if he don't vote for some period
        lastVoteTime[msg.sender] = block.timestamp;

        // Example: withdrawTime is 6/15 and proposal CreatedTime is 6/10, votePeriod is 10 days
        // In this case, we update the withdrawTime to sum(6/20) of proposal CreatedTime and votePeriod
        // so, staker cannot unstake his amount till 6/20
        uint256 withdrawableTime =  IStakingPool(STAKING_POOL).getWithdrawableTime(msg.sender);
        if (pCreateTime + IProperty(DAO_PROPERTY).filmVotePeriod() > withdrawableTime) {
            IStakingPool(STAKING_POOL).updateWithdrawableTime(msg.sender, pCreateTime + IProperty(DAO_PROPERTY).filmVotePeriod());
        }
        // 1++ for calculating the rewards
        if(withdrawableTime > block.timestamp) {
            IStakingPool(STAKING_POOL).updateVoteCount(msg.sender);
        }
        
        emit VotedToFilm(msg.sender, _filmId, _voteInfo, block.timestamp);
    }

    /// @notice Approve multi films that votePeriod has elapsed after votePeriod(10 days) by anyone
    // if isFund is true then "APPROVED_FUNDING", if isFund is false then "APPROVED_LISTING"
    function approveFilms(uint256[] memory _filmIds) external onlyStaker nonReentrant {
        require(_filmIds.length > 0, "approveFilms: Invalid items");

        for(uint256 i = 0; i < _filmIds.length; i++) {
            __approveFilm(_filmIds[i]);
        }   
    }

    function __approveFilm(uint256 _filmId) private {
        Voting storage fv = filmVoting[_filmId];
        
        // Example: stakeAmount of "YES" is 2000 and stakeAmount("NO") is 1000, stakeAmount("ABSTAIN") is 500 in 10 days(votePeriod)
        // In this case, Approved since 2000 > 1000 + 500 (it means ">50%") and stakeAmount of "YES" > 75m          
        (uint256 pCreateTime, uint256 pApproveTime) = IVabbleDAO(VABBLE_DAO).getFilmProposalTime(_filmId);
        require(!__isVotePeriod(IProperty(DAO_PROPERTY).filmVotePeriod(), pCreateTime), "approveFilms: vote period yet");
        require(pApproveTime == 0, "film already approved");
        
        (, , uint256 fundType) = IVabbleDAO(VABBLE_DAO).getFilmFund(_filmId);
        uint256 reason = 0;
        uint256 totalVoteCount = fv.voteCount_1 + fv.voteCount_2 + fv.voteCount_3;
        if(totalVoteCount >= IStakingPool(STAKING_POOL).getLimitCount() && fv.stakeAmount_1 > fv.stakeAmount_2) {
            reason = 0;
        } else {
            if(totalVoteCount < IStakingPool(STAKING_POOL).getLimitCount()) {
                reason = 1;
            } else if(fv.stakeAmount_1 <= fv.stakeAmount_2) {
                reason = 2;
            } else {
                reason = 10;
            } 
        }  

        IVabbleDAO(VABBLE_DAO).approveFilmByVote(_filmId, reason);

        emit FilmApproved(_filmId, fundType, block.timestamp, reason);
    }

    /// @notice Stakers vote(1,2,3 => Yes, No, Abstain) to agent for replacing Auditor    
    function voteToAgent(
        address _agent, 
        uint256 _voteInfo, 
        uint256 _flag     //  flag=1 => dispute vote
    ) external onlyStaker initialized nonReentrant {       
        require(!isAttendToAgentVote[msg.sender][_agent], "voteToAgent: Already voted");
        require(msg.sender != _agent, "voteToAgent: self voted");
        
        (uint256 pCreateTime, ) = IProperty(DAO_PROPERTY).getGovProposalTime(_agent, 1);
        require(pCreateTime > 0, "voteToAgent: no proposal");

        AgentVoting storage av = agentVoting[_agent];
        uint256 totalVoteCount = av.voteCount_1 + av.voteCount_2 + av.voteCount_3;
        if(_flag == 1) {
            require(_voteInfo == 2, "voteToAgent: invalid vote value");
            require(totalVoteCount > 0, "voteToAgent: no voter");          
            require(!__isVotePeriod(IProperty(DAO_PROPERTY).agentVotePeriod(), pCreateTime), "agent vote period yet");  

            if(av.disputeVABAmount == 0) {
                av.disputeStartTime = block.timestamp;
                govPassedVoteCount[2] += 1;
            } else {
                require(__isVotePeriod(IProperty(DAO_PROPERTY).disputeGracePeriod(), av.disputeStartTime), "agent elapsed grace period");            
            }
        } else {
            require(__isVotePeriod(IProperty(DAO_PROPERTY).agentVotePeriod(), pCreateTime), "agent elapsed vote period");               
        }

        uint256 stakeAmount = IStakingPool(STAKING_POOL).getStakeAmount(msg.sender);
        if(_voteInfo == 1) {
            av.stakeAmount_1 += stakeAmount;
            av.voteCount_1++;
        } else if(_voteInfo == 2) {
            if(_flag == 1) av.disputeVABAmount += stakeAmount;
            else {
                av.stakeAmount_2 += stakeAmount;
                av.voteCount_2++;
            }
        } else {
            av.stakeAmount_3 += stakeAmount;
            av.voteCount_3++;
        }
        
        userGovernVoteCount[msg.sender] += 1;

        isAttendToAgentVote[msg.sender][_agent] = true;

        // for removing board member if he don't vote for some period
        lastVoteTime[msg.sender] = block.timestamp;
        // 1++ for calculating the rewards
        if(IStakingPool(STAKING_POOL).getWithdrawableTime(msg.sender) > block.timestamp) {
            IStakingPool(STAKING_POOL).updateVoteCount(msg.sender);
        }

        emit VotedToAgent(msg.sender, _agent, _voteInfo, block.timestamp);
    }

    /// @notice Replace Auditor based on vote result
    function replaceAuditor(address _agent) external onlyStaker nonReentrant {
        require(_agent != address(0) && IOwnablee(OWNABLE).auditor() != _agent, "replaceAuditor: invalid index or no proposal");
        
        (uint256 pCreateTime, uint256 pApproveTime) = IProperty(DAO_PROPERTY).getGovProposalTime(_agent, 1);
        require(!__isVotePeriod(IProperty(DAO_PROPERTY).agentVotePeriod(), pCreateTime), "auditor vote period yet"); 
        require(pApproveTime == 0, "auditor already approved"); 
        
        AgentVoting storage av = agentVoting[_agent];
        uint256 disputeTime = av.disputeStartTime;
        if(disputeTime > 0) {
            require(!__isVotePeriod(IProperty(DAO_PROPERTY).disputeGracePeriod(), disputeTime), "auditor grace period yet");            
        } else {
            require(
                !__isVotePeriod(IProperty(DAO_PROPERTY).agentVotePeriod() + IProperty(DAO_PROPERTY).disputeGracePeriod(), pCreateTime), 
                "auditor dispute vote period yet"
            );
        }

        uint256 reason = 0;
        uint256 totalVoteCount = av.voteCount_1 + av.voteCount_2 + av.voteCount_3;
        // must be over 51%, staking amount must be over 75m, dispute staking amount must be less than 150m
        if(
            totalVoteCount >= IStakingPool(STAKING_POOL).getLimitCount() &&
            av.stakeAmount_1 > av.stakeAmount_2 &&
            av.stakeAmount_1 > IProperty(DAO_PROPERTY).availableVABAmount() &&
            av.disputeVABAmount < 2 * IProperty(DAO_PROPERTY).availableVABAmount()
        ) {
            IOwnablee(OWNABLE).replaceAuditor(_agent);
            IProperty(DAO_PROPERTY).updateGovProposalApproveTime(_agent, 1, 1);
            govPassedVoteCount[1] += 1;
        } else {
            IProperty(DAO_PROPERTY).updateGovProposalApproveTime(_agent, 1, 0);

            if(totalVoteCount < IStakingPool(STAKING_POOL).getLimitCount()) {
                reason = 1;
            } else if(av.stakeAmount_1 <= av.stakeAmount_2) {
                reason = 2;
            } else if(av.stakeAmount_1 <= IProperty(DAO_PROPERTY).availableVABAmount()) {
                reason = 3;
            } else if(av.disputeVABAmount >= 2 * IProperty(DAO_PROPERTY).availableVABAmount()) {
                reason = 4;
            } else {
                reason = 10;
            }
        }
        emit AuditorReplaced(_agent, msg.sender, block.timestamp, reason);
    }
    
    function voteToFilmBoard(
        address _candidate, 
        uint256 _voteInfo
    ) external onlyStaker initialized nonReentrant {
        require(IProperty(DAO_PROPERTY).isBoardWhitelist(_candidate) == 1, "voteToFilmBoard: Not candidate");
        require(!isAttendToBoardVote[msg.sender][_candidate], "voteToFilmBoard: Already voted");   
        require(msg.sender != _candidate, "voteToFilmBoard: self voted");   

        (uint256 pCreateTime, ) = IProperty(DAO_PROPERTY).getGovProposalTime(_candidate, 2);
        require(pCreateTime > 0, "voteToFilmBoard: no proposal");
        require(__isVotePeriod(IProperty(DAO_PROPERTY).boardVotePeriod(), pCreateTime), "filmBoard elapsed vote period");
        
        uint256 stakeAmount = IStakingPool(STAKING_POOL).getStakeAmount(msg.sender);
        
        Voting storage fbp = filmBoardVoting[_candidate];     
        if(_voteInfo == 1) {
            fbp.stakeAmount_1 += stakeAmount; // Yes
            fbp.voteCount_1++;
        } else if(_voteInfo == 2) {
            fbp.stakeAmount_2 += stakeAmount; // No
            fbp.voteCount_2++;
        } else {
            fbp.stakeAmount_3 += stakeAmount; // Abstain
            fbp.voteCount_3++;
        }

        userGovernVoteCount[msg.sender] += 1;

        isAttendToBoardVote[msg.sender][_candidate] = true;

        // for removing board member if he don't vote for some period
        lastVoteTime[msg.sender] = block.timestamp;
        // 1++ for calculating the rewards
        if(IStakingPool(STAKING_POOL).getWithdrawableTime(msg.sender) > block.timestamp) {
            IStakingPool(STAKING_POOL).updateVoteCount(msg.sender);
        }

        emit VotedToFilmBoard(msg.sender, _candidate, _voteInfo, block.timestamp);
    }
    
    function addFilmBoard(address _member) external onlyStaker nonReentrant {
        require(IProperty(DAO_PROPERTY).isBoardWhitelist(_member) == 1, "addFilmBoard: Not candidate");

        (uint256 pCreateTime, uint256 pApproveTime) = IProperty(DAO_PROPERTY).getGovProposalTime(_member, 2);
        require(!__isVotePeriod(IProperty(DAO_PROPERTY).boardVotePeriod(), pCreateTime), "filmBoard vote period yet");
        require(pApproveTime == 0, "filmBoard already approved");

        uint256 reason = 0;
        Voting storage fbp = filmBoardVoting[_member];
        uint256 totalVoteCount = fbp.voteCount_1 + fbp.voteCount_2 + fbp.voteCount_3;
        if(
            totalVoteCount >= IStakingPool(STAKING_POOL).getLimitCount() &&
            fbp.stakeAmount_1 > fbp.stakeAmount_2 &&
            fbp.stakeAmount_1 > IProperty(DAO_PROPERTY).availableVABAmount()
        ) {
            IProperty(DAO_PROPERTY).addFilmBoardMember(_member);   
            IProperty(DAO_PROPERTY).updateGovProposalApproveTime(_member, 2, 1);
            govPassedVoteCount[3] += 1;
        } else {
            IProperty(DAO_PROPERTY).updateGovProposalApproveTime(_member, 2, 0);

            if(totalVoteCount < IStakingPool(STAKING_POOL).getLimitCount()) {
                reason = 1;
            } else if(fbp.stakeAmount_1 <= fbp.stakeAmount_2) {
                reason = 2;
            } else if(fbp.stakeAmount_1 <= IProperty(DAO_PROPERTY).availableVABAmount()) {
                reason = 3;
            } else {
                reason = 10;
            }
        }        
        emit FilmBoardAdded(_member, msg.sender, block.timestamp, reason);
    }

    ///@notice Stakers vote to proposal for setup the address to reward DAO fund
    function voteToRewardAddress(address _rewardAddress, uint256 _voteInfo) external onlyStaker initialized nonReentrant {
        require(IProperty(DAO_PROPERTY).isRewardWhitelist(_rewardAddress) == 1, "voteToRewardAddress: Not candidate");
        require(!isAttendToRewardAddressVote[msg.sender][_rewardAddress], "voteToRewardAddress: Already voted");     
        require(msg.sender != _rewardAddress, "voteToRewardAddress: self voted");       

        (uint256 pCreateTime, ) = IProperty(DAO_PROPERTY).getGovProposalTime(_rewardAddress, 3);
        require(pCreateTime > 0, "voteToRewardAddress: no proposal");
        require(__isVotePeriod(IProperty(DAO_PROPERTY).rewardVotePeriod(), pCreateTime), "reward elapsed vote period");
        
        uint256 stakeAmount = IStakingPool(STAKING_POOL).getStakeAmount(msg.sender);

        Voting storage rav = rewardAddressVoting[_rewardAddress];
        if(_voteInfo == 1) {
            rav.stakeAmount_1 += stakeAmount;   // Yes
            rav.voteCount_1++;
        } else if(_voteInfo == 2) {
            rav.stakeAmount_2 += stakeAmount;   // No
            rav.voteCount_2++;
        } else {
            rav.stakeAmount_3 += stakeAmount;   // Abstain
            rav.voteCount_3++;
        }

        userGovernVoteCount[msg.sender] += 1;

        isAttendToRewardAddressVote[msg.sender][_rewardAddress] = true;

        // for removing board member if he don't vote for some period
        lastVoteTime[msg.sender] = block.timestamp;
        // 1++ for calculating the rewards
        if(IStakingPool(STAKING_POOL).getWithdrawableTime(msg.sender) > block.timestamp) {
            IStakingPool(STAKING_POOL).updateVoteCount(msg.sender);
        }

        emit VotedToPoolAddress(msg.sender, _rewardAddress, _voteInfo, block.timestamp);
    }

    function setDAORewardAddress(address _rewardAddress) external onlyStaker nonReentrant {
        require(IProperty(DAO_PROPERTY).isRewardWhitelist(_rewardAddress) == 1, "setRewardAddress: Not candidate");

        (uint256 pCreateTime, uint256 pApproveTime) = IProperty(DAO_PROPERTY).getGovProposalTime(_rewardAddress, 3);
        require(!__isVotePeriod(IProperty(DAO_PROPERTY).rewardVotePeriod(), pCreateTime), "reward vote period yet");
        require(pApproveTime == 0, "pool address already approved");
        
        uint256 reason = 0;
        Voting storage rav = rewardAddressVoting[_rewardAddress];
        uint256 totalVoteCount = rav.voteCount_1 + rav.voteCount_2 + rav.voteCount_3;
        if(
            totalVoteCount >= IStakingPool(STAKING_POOL).getLimitCount() &&       // Less than limit count
            rav.stakeAmount_1 > rav.stakeAmount_2 &&                         // less 51%
            rav.stakeAmount_1 > IProperty(DAO_PROPERTY).availableVABAmount() // less than permit amount
        ) {
            IProperty(DAO_PROPERTY).setRewardAddress(_rewardAddress);
            IProperty(DAO_PROPERTY).updateGovProposalApproveTime(_rewardAddress, 3, 1);
            govPassedVoteCount[4] += 1;
        } else {
            IProperty(DAO_PROPERTY).updateGovProposalApproveTime(_rewardAddress, 3, 0);

            if(totalVoteCount < IStakingPool(STAKING_POOL).getLimitCount()) {
                reason = 1;
            } else if(rav.stakeAmount_1 <= rav.stakeAmount_2) {
                reason = 2;
            } else if(rav.stakeAmount_1 <= IProperty(DAO_PROPERTY).availableVABAmount()) {
                reason = 3;
            } else {
                reason = 10;
            }
        }        
        emit PoolAddressAdded(_rewardAddress, msg.sender, block.timestamp, reason);
    }

    /// @notice Stakers vote(1,2,3 => Yes, No, Abstain) to proposal for updating properties(filmVotePeriod, rewardRate, ...)
    function voteToProperty(
        uint256 _voteInfo, 
        uint256 _propertyIndex, 
        uint256 _flag
    ) external onlyStaker initialized nonReentrant {
        uint256 propertyVal = IProperty(DAO_PROPERTY).getProperty(_propertyIndex, _flag);
        require(propertyVal > 0, "voteToProperty: no proposal");
        require(!isAttendToPropertyVote[_flag][msg.sender][propertyVal], "voteToProperty: Already voted");
        
        (uint256 pCreateTime, ) = IProperty(DAO_PROPERTY).getPropertyProposalTime(propertyVal, _flag);
        require(pCreateTime > 0, "voteToProperty: no proposal");
        require(__isVotePeriod(IProperty(DAO_PROPERTY).propertyVotePeriod(), pCreateTime), "property elapsed vote period");

        uint256 stakeAmount = IStakingPool(STAKING_POOL).getStakeAmount(msg.sender);

        Voting storage pv = propertyVoting[_flag][propertyVal];
        if(_voteInfo == 1) {
            pv.stakeAmount_1 += stakeAmount;
            pv.voteCount_1++;
        } else if(_voteInfo == 2) {
            pv.stakeAmount_2 += stakeAmount;
            pv.voteCount_2++;
        } else {
            pv.stakeAmount_3 += stakeAmount;
            pv.voteCount_3++;
        }
        
        userGovernVoteCount[msg.sender] += 1;

        isAttendToPropertyVote[_flag][msg.sender][propertyVal] = true;
        
        // for removing board member if he don't vote for some period
        lastVoteTime[msg.sender] = block.timestamp;
        // 1++ for calculating the rewards
        if(IStakingPool(STAKING_POOL).getWithdrawableTime(msg.sender) > block.timestamp) {
            IStakingPool(STAKING_POOL).updateVoteCount(msg.sender);
        }

        emit VotedToProperty(msg.sender, _flag, propertyVal, _voteInfo, block.timestamp);
    }

    /// @notice Update properties based on vote result(>=51% and stakeAmount of "Yes" > 75m)
    function updateProperty(
        uint256 _propertyIndex, 
        uint256 _flag
    ) external onlyStaker nonReentrant {
        uint256 propertyVal = IProperty(DAO_PROPERTY).getProperty(_propertyIndex, _flag);
        (uint256 pCreateTime, uint256 pApproveTime) = IProperty(DAO_PROPERTY).getPropertyProposalTime(propertyVal, _flag);
        require(!__isVotePeriod(IProperty(DAO_PROPERTY).propertyVotePeriod(), pCreateTime), "property vote period yet");
        require(pApproveTime == 0, "property already approved");

        uint256 reason = 0;
        Voting storage pv = propertyVoting[_flag][propertyVal];
        uint256 totalVoteCount = pv.voteCount_1 + pv.voteCount_2 + pv.voteCount_3;
        if(
            totalVoteCount >= IStakingPool(STAKING_POOL).getLimitCount() && 
            pv.stakeAmount_1 > pv.stakeAmount_2 &&
            pv.stakeAmount_1 > IProperty(DAO_PROPERTY).availableVABAmount()
        ) {
            IProperty(DAO_PROPERTY).updateProperty(_propertyIndex, _flag);    
            IProperty(DAO_PROPERTY).updatePropertyProposalApproveTime(propertyVal, _flag, 1);
            govPassedVoteCount[5] += 1;              
        } else {
            IProperty(DAO_PROPERTY).updatePropertyProposalApproveTime(propertyVal, _flag, 0);

            if(totalVoteCount < IStakingPool(STAKING_POOL).getLimitCount()) {
                reason = 1;
            } else if(pv.stakeAmount_1 <= pv.stakeAmount_2) {
                reason = 2;
            } else if(pv.stakeAmount_1 <= IProperty(DAO_PROPERTY).availableVABAmount()) {
                reason = 3;
            } else {
                reason = 10;
            }
        }
        emit PropertyUpdated(_flag, propertyVal, msg.sender, block.timestamp, reason);
    }

    function __isVotePeriod(
        uint256 _period, 
        uint256 _startTime
    ) private view returns (bool) {
        if(_period >= block.timestamp - _startTime) return true;
        else return false;
    }
    /// @notice Get funding filmId voteStatus per User
    function getFundingIdVoteStatusPerUser(
        address _staker, 
        uint256 _filmId
    ) external view returns(uint256) {
        return fundingIdsVoteStatusPerUser[_staker][_filmId];
    }

    /// @notice Get funding filmIds per User
    function getFundingFilmIdsPerUser(address _staker) external view returns(uint256[] memory) {
        return fundingFilmIdsPerUser[_staker];
    }

    /// @notice Delete all funding filmIds per User from only StakingPool contract
    function removeFundingFilmIdsPerUser(address _staker) external {
        require(msg.sender == STAKING_POOL, "caller is not StakingPool contract");
        delete fundingFilmIdsPerUser[_staker];
    }

    /// @notice Update last vote time for removing filmboard member
    function getLastVoteTime(address _member) external view returns (uint256 time_) {
        time_ = lastVoteTime[_member];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IFactoryFilmNFT {    
    function getMintInfo(uint256 _filmId) external view 
    returns (
        uint256 tier_,
        uint256 maxMintAmount_,
        uint256 mintPrice_,
        uint256 feePercent_,
        uint256 revenuePercent_,
        address nft_,
        address studio_
    );

    function getFilmTokenIdList(uint256 _filmId) external view returns (uint256[] memory);

    function getRaisedAmountByNFT(uint256 _filmId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IOwnablee {  
    function auditor() external view returns (address);

    function replaceAuditor(address _newAuditor) external;
    
    function isDepositAsset(address _asset) external view returns (bool);
    
    function getDepositAssetList() external view returns (address[] memory);

    function VAB_WALLET() external view returns (address);
    
    function USDC_TOKEN() external view returns (address);

    function PAYOUT_TOKEN() external view returns (address);

    function addToStudioPool(uint256 _amount) external;

    function withdrawVABFromEdgePool(address _to) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IProperty {  
    function filmVotePeriod() external view returns (uint256);        // 0
    function agentVotePeriod() external view returns (uint256);       // 1
    function disputeGracePeriod() external view returns (uint256);    // 2
    function propertyVotePeriod() external view returns (uint256);    // 3
    function lockPeriod() external view returns (uint256);            // 4
    function rewardRate() external view returns (uint256);            // 5
    function extraRewardRate() external view returns (uint256);       // 6
    function maxAllowPeriod() external view returns (uint256);        // 7
    function proposalFeeAmount() external view returns (uint256);     // 8
    function fundFeePercent() external view returns (uint256);        // 9
    function minDepositAmount() external view returns (uint256);      // 10
    function maxDepositAmount() external view returns (uint256);      // 11
    function maxMintFeePercent() external view returns (uint256);     // 12    
    function minVoteCount() external view returns (uint256);          // 13
    
    function subscriptionAmount() external view returns (uint256);    
    function availableVABAmount() external view returns (uint256);
    function rewardVotePeriod() external view returns (uint256);      
    function boardVotePeriod() external view returns (uint256);       
    function boardVoteWeight() external view returns (uint256);       
    function boardRewardRate() external view returns (uint256);       
    function minStakerCountPercent() external view returns (uint256);      

    // function removeAgent(address _agent) external;

    function getProperty(uint256 _propertyIndex, uint256 _flag) external view returns (uint256 property_);
    function updateProperty(uint256 _propertyIndex, uint256 _flag) external;
    // function removeProperty(uint256 _propertyIndex, uint256 _flag) external;
    
    function setRewardAddress(address _rewardAddress) external;    
    function isRewardWhitelist(address _rewardAddress) external view returns (uint256);
    function DAO_FUND_REWARD() external view returns (address);

    function updateLastVoteTime(address _member) external;
    function addFilmBoardMember(address _member) external;
    function isBoardWhitelist(address _member) external view returns (uint256);

    function getPropertyProposalTime(uint256 _property, uint256 _flag) external view returns (uint256 cTime_, uint256 aTime_);
    function getGovProposalTime(address _member, uint256 _flag) external view returns (uint256 cTime_, uint256 aTime_);
    function updatePropertyProposalApproveTime(uint256 _property, uint256 _flag, uint256 _approveStatus) external;
    function updateGovProposalApproveTime(address _member, uint256 _flag, uint256 _approveStatus) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStakingPool {    
    function getStakeAmount(address _user) external view returns(uint256 amount_);

    function getWithdrawableTime(address _user) external view returns(uint256 time_);

    function updateWithdrawableTime(address _user, uint256 _time) external;

    function updateVoteCount(address _user) external;

    function addRewardToPool(uint256 _amount) external;
    
    function getLimitCount() external view returns(uint256 count_);
       
    function lastfundProposalCreateTime() external view returns(uint256);

    function updateLastfundProposalCreateTime(uint256 _time) external;

    function updateProposalCreatedTimeList(uint256 _time) external;

    function getRentVABAmount(address _user) external view returns(uint256 amount_);
    
    function sendVAB(address[] memory _users, address _to, uint256[] memory _amounts) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Interface for Helper
interface IUniHelper {

    function expectedAmount(
        uint256 _depositAmount,
        address _depositAsset, 
        address _incomingAsset
    ) external view returns (uint256 amount_);

    function swapAsset(bytes calldata _swapArgs) external returns (uint256 amount_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/Helper.sol";
import "../dao/VabbleDAO.sol";

interface IVabbleDAO {   
    
    struct Film {
        string title;            // proposal title
        string description;      // proposal description
        uint256[] sharePercents; // percents(1% = 1e8) that studio defines to pay revenue for each payee
        address[] studioPayees;  // payee addresses who studio define to pay revenue
        uint256 raiseAmount;     // USDC amount(in cash) studio are seeking to raise for the film
        uint256 fundPeriod;      // how many days(ex: 20 days) to keep the funding pool open        
        uint256 fundType;        // Financing Type(None=>0, Token=>1, NFT=>2, NFT & Token=>3)
        uint256 noVote;          // if 0 => false, 1 => true
        uint256 enableClaimer;   // if 0 => false, 1 => true
        uint256 pCreateTime;     // proposal created time(block.timestamp) by studio
        uint256 pApproveTime;    // proposal approved time(block.timestamp) by vote
        address studio;          // studio address(film owner)
        Helper.Status status;    // status of film
    }

    function getFilmFund(uint256 _filmId) external view returns (uint256 raiseAmount_, uint256 fundPeriod_, uint256 fundType_);

    function getFilmStatus(uint256 _filmId) external view returns (Helper.Status status_);
    
    function getFilmOwner(uint256 _filmId) external view returns (address owner_);

    function getFilmProposalTime(uint256 _filmId) external view returns (uint256 cTime_, uint256 aTime_);

    function approveFilmByVote(uint256 _filmId, uint256 _flag) external;

    function isEnabledClaimer(uint256 _filmId) external view returns (bool enable_);

    function getFilmShare(uint256 _filmId) external view 
    returns (
        uint256[] memory sharePercents_, 
        address[] memory studioPayees_
    );

    function getUserFilmListForMigrate(address _user) external view returns (Film[] memory filmList_);

    function withdrawVABFromStudioPool(address _to) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../dao/Vote.sol";
interface IVote { 
    function getFundingFilmIdsPerUser(address _staker) external view returns (uint256[] memory);
    
    function getFundingIdVoteStatusPerUser(address _staker, uint256 _filmId) external view returns(uint256);

    function removeFundingFilmIdsPerUser(address _staker) external;

    function getLastVoteTime(address _member) external view returns (uint256 time_);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Helper {
    enum Status {
        LISTED,              //0 proposal created by studio
        UPDATED,             //1 proposal updated by studio
        APPROVED_LISTING,    //2 approved for listing by vote from VAB holders(staker)
        APPROVED_FUNDING,    //3 approved for funding by vote from VAB holders(staker)
        REJECTED             //4 rejected by vote from VAB holders(staker)
    }

    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "VabbleDAO::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "VabbleDAO::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "VabbleDAO::safeTransferETH: ETH transfer failed");
    }

    function safeTransferAsset(
        address token,
        address to,
        uint256 value
    ) internal {
        if (token == address(0)) {
            safeTransferETH(to, value);
        } else {
            safeTransfer(token, to, value);
        }
    }

    function safeTransferNFT(
        address _nft,
        address _from,
        address _to,
        TokenType _type,
        uint256 _tokenId
    ) internal {
        if (_type == TokenType.ERC721) {
            IERC721(_nft).safeTransferFrom(_from, _to, _tokenId);
        } else {
            IERC1155(_nft).safeTransferFrom(_from, _to, _tokenId, 1, "0x00");
        }
    }

    function isContract(address _address) internal view returns(bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}