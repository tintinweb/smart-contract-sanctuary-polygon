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
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../libraries/Helper.sol";
import "../interfaces/IUniHelper.sol";
import "../interfaces/IStakingPool.sol";
import "../interfaces/IProperty.sol";
import "../interfaces/IOwnablee.sol";
import "../interfaces/IFactoryFilmNFT.sol";

contract VabbleDAO is ReentrancyGuard {
    using Counters for Counters.Counter;
    
    event FilmProposalCreated(uint256[] filmIds, uint256[] noVotes, address studio);
    event FilmProposalUpdated(uint256 indexed filmId, address studio);
    event FilmApproved(uint256 filmId);
    event FinalFilmSetted(address[] users, uint256[] filmIds, uint256[] watchedPercents, uint256[] rentPrices);
    event FilmShareAndPayeeUpdated(address filmOwner, uint256 filmId, uint256[] shares, address[] payees);
    event FilmFundPeriodUpdated(address filmOwner, uint256 filmId, uint256 fundPeriod);
    
    struct Film {
        uint256[] nftRight;      // What genre the film will be(Action,Adventure,Animation,Biopic, , , Western,War,WEB3)
        uint256[] sharePercents; // percents(1% = 1e8) that studio defines to pay revenue for each payee
        address[] choiceAuditor; // What auditor will you distribute to = Vabble consumer portal. Titled as "Vabble"
        address[] studioPayees;  // payee addresses who studio define to pay revenue
        uint256 raiseAmount;     // USDC amount(in cash) studio are seeking to raise for the film
        uint256 fundPeriod;      // how many days(ex: 20 days) to keep the funding pool open        
        uint256 fundType;        // Financing Type(None=>0, Token=>1, NFT=>2, NFT & Token=>3)
        uint256 pCreateTime;     // proposal created time(block.timestamp) by studio
        uint256 pApproveTime;    // proposal approved time(block.timestamp) by vote
        uint256 noVote;          // check if vote need or not. if 0 => false, 1 => true
        address studio;          // Studio Address (Admin of film)
        Helper.Status status;    // status of film
    }
  
    address public immutable OWNABLE;         // Ownablee contract address
    address public immutable VOTE;            // Vote contract address
    address public immutable STAKING_POOL;    // StakingPool contract address
    address public immutable UNI_HELPER;      // UniHelper contract address
    address public immutable DAO_PROPERTY;
    address public immutable FILM_NFT_FACTORY;  
    
    uint256[] private proposalFilmIds;    
    uint256[] private approvedNoVoteFilmIds;
    uint256[] private approvedFundingFilmIds;
    uint256[] private approvedListingFilmIds;
    
    mapping(uint256 => Film) private filmInfo;             // Each film information(filmId => Film)
    mapping(address => uint256) public userFilmProposalCount; // (user => created film-proposal count)
    mapping(address => uint256[]) private userFinalFilmIds;
    mapping(address => uint256[]) private userFilmProposalIds; // (studio => filmId list)
    
    Counters.Counter public filmCount;          // filmId is from No.1

    modifier onlyVote() {
        require(msg.sender == VOTE, "caller is not the vote contract");
        _;
    }
    modifier onlyAuditor() {
        require(msg.sender == IOwnablee(OWNABLE).auditor(), "caller is not the auditor");
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
    /// @notice Staker create multi proposal for a lot of films | if 0 => false, 1 => true
    function proposalFilmCreate(uint256[] memory _noVotes, address _feeToken) external payable nonReentrant {     
        require(_noVotes.length > 0, 'proposalFilm: bad length');
        if(_feeToken != IOwnablee(OWNABLE).PAYOUT_TOKEN()) {
            require(IOwnablee(OWNABLE).isDepositAsset(_feeToken), "proposalFilm: not allowed asset");   
        }
        
        __paidFee(_feeToken, _noVotes);
 
        uint256[] memory idList = new uint256[](_noVotes.length);
        for(uint256 i = 0; i < _noVotes.length; i++) {
            idList[i] = __proposalFilmCreate(_noVotes[i]);
        }

        emit FilmProposalCreated(idList, _noVotes, msg.sender);
    }

    function __proposalFilmCreate(uint256 _noVote) private returns (uint256) {  
        filmCount.increment();
        uint256 filmId = filmCount.current();

        Film storage fInfo = filmInfo[filmId];
        fInfo.noVote = _noVote;
        fInfo.studio = msg.sender;
        fInfo.status = Helper.Status.LISTED;

        proposalFilmIds.push(filmId);
        userFilmProposalIds[msg.sender].push(filmId);

        userFilmProposalCount[msg.sender] += 1;

        return filmId;
    }

    function proposalFilmMultiUpdate(bytes[] calldata _updateFilms) external nonReentrant {
        require(_updateFilms.length > 0, "proposalUpdate: Invalid item length");
        for(uint256 i = 0; i < _updateFilms.length; i++) {
            (
                uint256 _filmId, 
                uint256[] memory _nftRight,
                uint256[] memory _sharePercents,
                address[] memory _choiceAuditor,
                address[] memory _studioPayees,
                uint256 _raiseAmount,
                uint256 _fundPeriod,
                uint256 _fundType
            ) = abi.decode(_updateFilms[i], (uint256, uint256[], uint256[], address[], address[], uint256, uint256, uint256));

            proposalFilmUpdate(
                _filmId,
                _nftRight,
                _sharePercents,
                _choiceAuditor,
                _studioPayees,
                _raiseAmount,
                _fundPeriod,
                _fundType
            );
        }
    }

    function proposalFilmUpdate(
        uint256 _filmId, 
        uint256[] memory _nftRight,
        uint256[] memory _sharePercents,
        address[] memory _choiceAuditor,
        address[] memory _studioPayees,
        uint256 _raiseAmount,
        uint256 _fundPeriod,
        uint256 _fundType
    ) public {                
        require(_nftRight.length > 0, 'proposalUpdate: invalid right');
        require(_studioPayees.length == _sharePercents.length, 'proposalUpdate: invalid share percent');
        if(_fundType > 0) {            
            require(_fundPeriod > 0, 'proposalUpdate: invalid fund period');
            require(_raiseAmount > IProperty(DAO_PROPERTY).minDepositAmount(), 'proposalUpdate: invalid raise amount');
        }

        uint256 totalPercent = 0;
        for(uint256 i = 0; i < _studioPayees.length; i++) {
            require(_sharePercents[i] <= 1e10, 'proposalUpdate: over 100%');
            totalPercent += _sharePercents[i];
        }
        require(totalPercent <= 1e10, 'proposalUpdate: total over 100%');
        
        Film storage fInfo = filmInfo[_filmId];
        require(fInfo.status == Helper.Status.LISTED, 'proposalUpdate: Not listed');
        require(fInfo.studio == msg.sender, 'proposalUpdate: not film owner');

        fInfo.nftRight = _nftRight;
        fInfo.sharePercents = _sharePercents;
        fInfo.choiceAuditor = _choiceAuditor;
        fInfo.studioPayees = _studioPayees;    
        fInfo.raiseAmount = _raiseAmount;
        fInfo.fundPeriod = _fundPeriod;
        fInfo.fundType = _fundType;
        fInfo.pCreateTime = block.timestamp;
        fInfo.studio = msg.sender;

        userFilmProposalCount[msg.sender] += 1;
        IStakingPool(STAKING_POOL).updateProposalCreatedTimeList(block.timestamp); // add timestap to array for calculating rewards

        // If proposal is for fund, update "lastfundProposalCreateTime"
        if(fInfo.fundType > 0) IStakingPool(STAKING_POOL).updateLastfundProposalCreateTime(block.timestamp);

        if(fInfo.noVote == 1) {
            if(_fundType > 0) {
                fInfo.status = Helper.Status.APPROVED_FUNDING;
                approvedFundingFilmIds.push(_filmId);
            } else {
                fInfo.status = Helper.Status.APPROVED_WITHOUTVOTE;
                approvedNoVoteFilmIds.push(_filmId);
            }            
        }        

        emit FilmProposalUpdated(_filmId, msg.sender);     
    }

    /// @notice Check if proposal fee transferred from studio to stakingPool
    // Get expected VAB amount from UniswapV2 and then Transfer VAB: user(studio) -> stakingPool.
    function __paidFee(address _dToken, uint256[] memory _noVotes) private {    
        uint256 feeAmount = IProperty(DAO_PROPERTY).proposalFeeAmount(); // in cash(usdc)
        uint256 _usdcAmount;
        for(uint256 i = 0; i < _noVotes.length; i++) {
            if(_noVotes[i] == 1) _usdcAmount += feeAmount * 2;
            else _usdcAmount += feeAmount;
        }
        
        uint256 expectTokenAmount = _usdcAmount;
        if(_dToken != IOwnablee(OWNABLE).USDC_TOKEN()) {
            expectTokenAmount = IUniHelper(UNI_HELPER).expectedAmount(_usdcAmount, IOwnablee(OWNABLE).USDC_TOKEN(), _dToken);
        }
        Helper.safeTransferFrom(_dToken, msg.sender, address(this), expectTokenAmount);

        // Send ETH from this contract to UNI_HELPER contract
        if(_dToken == address(0)) Helper.safeTransferETH(UNI_HELPER, expectTokenAmount);
        
        address vabToken = IOwnablee(OWNABLE).PAYOUT_TOKEN();
        uint256 vabAmount = expectTokenAmount;
        if(_dToken != vabToken) {
            if(IERC20(_dToken).allowance(address(this), UNI_HELPER) == 0) {
                Helper.safeApprove(_dToken, UNI_HELPER, IERC20(_dToken).totalSupply());
            }
            bytes memory swapArgs = abi.encode(expectTokenAmount, _dToken, vabToken);
            vabAmount = IUniHelper(UNI_HELPER).swapAsset(swapArgs);    
        }
        
        if(IERC20(vabToken).allowance(address(this), STAKING_POOL) == 0) {
            Helper.safeApprove(vabToken, STAKING_POOL, IERC20(vabToken).totalSupply());
        }  
        IStakingPool(STAKING_POOL).addRewardToPool(vabAmount);
    } 

    /// @notice Approve a film for funding/listing from vote contract
    function approveFilm(uint256 _filmId) external onlyVote {
        require(_filmId > 0, "ApproveFilm: Invalid filmId"); 

        (, , uint256 fundType) = getFilmFund(_filmId);
        if(fundType > 0) { // in case of fund film
            filmInfo[_filmId].status = Helper.Status.APPROVED_FUNDING;
            approvedFundingFilmIds.push(_filmId);
        } else {
            filmInfo[_filmId].status = Helper.Status.APPROVED_LISTING;    
            approvedListingFilmIds.push(_filmId);
        }        

        emit FilmApproved(_filmId);
    }

    /// @notice onlyStudio update film share and payee
    function updateFilmShareAndPayee(
        uint256 _filmId, 
        uint256[] memory _sharePercents, 
        address[] memory _studioPayees
    ) public nonReentrant {        
        require(filmInfo[_filmId].studio == msg.sender, "updateFilm: not film owner");
        require(_sharePercents.length == _studioPayees.length, "updateFilm: bad array length");

        uint256 totalPercent = 0;
        for(uint256 k = 0; k < _studioPayees.length; k++) {
            totalPercent += _sharePercents[k];
        }
        require(totalPercent <= 1e10, 'updateFilm: total over 100%');

        Film storage fInfo = filmInfo[_filmId];
        fInfo.studioPayees = _studioPayees;   
        fInfo.sharePercents = _sharePercents;   
            
        emit FilmShareAndPayeeUpdated(msg.sender, _filmId, _sharePercents, _studioPayees);
    }

    /// @notice onlyStudio update film fund period
    function updateFilmFundPeriod(uint256 _filmId, uint256 _fundPeriod) external nonReentrant {
        require(msg.sender == filmInfo[_filmId].studio, "updateRentPrice: not film owner");

        filmInfo[_filmId].fundPeriod = _fundPeriod;
        
        emit FilmFundPeriodUpdated(msg.sender, _filmId, _fundPeriod);
    }   

    /// @notice Set final films for a customer with watched percents
    function setFinalFilms(        
        address[] memory _users,
        uint256[] memory _filmIds,
        uint256[] memory _watchPercents,
        uint256[] memory _rentPrices
    ) external onlyAuditor nonReentrant {
        require(_filmIds.length > 0 && _filmIds.length == _watchPercents.length, "setFinalFilms: bad length");
        require(_rentPrices.length == _watchPercents.length, "setFinalFilms: bad rent price length");

        for(uint256 i = 0; i < _filmIds.length; i++) {        
            __setFinalFilm(_users[i], _filmIds[i], _watchPercents[i], _rentPrices[i]);
        }

        emit FinalFilmSetted(_users, _filmIds, _watchPercents, _rentPrices);
    }
    
    function __setFinalFilm(
        address _user, 
        uint256 _filmId, 
        uint256 _watchPercent,
        uint256 _rentPrice
    ) private {          
        Film memory fInfo = filmInfo[_filmId];
        require(
            fInfo.status == Helper.Status.APPROVED_LISTING || 
            fInfo.status == Helper.Status.APPROVED_WITHOUTVOTE,
            "setFinalFilm: bad film status"
        );
                  
        // Transfer VAB to payees based on share(%) and watch(%)
        uint256 payout = __getPayoutFor(_rentPrice, _watchPercent);
        uint256 userVAB = IStakingPool(STAKING_POOL).getRentVABAmount(_user);
        require(payout > 0 && userVAB >= payout, "setFinalFilm: insufficient balance");

        uint256 restAmount = payout;
        for(uint256 k = 0; k < fInfo.studioPayees.length; k++) {
            uint256 shareAmount = payout * fInfo.sharePercents[k] / 1e10;
            IStakingPool(STAKING_POOL).sendVAB(_user, fInfo.studioPayees[k], shareAmount);
            restAmount -= shareAmount;
        }

        uint256 nftCountOwned = 0;
        uint256[] memory nftList = IFactoryFilmNFT(FILM_NFT_FACTORY).getFilmTokenIdList(_filmId);
        for(uint256 i = 0; i < nftList.length; i++) {
            if(IERC721(FILM_NFT_FACTORY).ownerOf(nftList[i]) == _user) {
                nftCountOwned += 1;
            }
        }        

        ( , , , , uint256 revenuePercent, ,) = IFactoryFilmNFT(FILM_NFT_FACTORY).getMintInfo(_filmId);
        if(nftCountOwned > 0 && revenuePercent > 0) {
            uint256 revenueAmount = restAmount * revenuePercent / 1e10;
            revenueAmount *= nftCountOwned;
            require(restAmount >= revenueAmount, "setFinalFilm: insufficient revenueAmount"); 

            // Transfer revenue amount to user if user fund to this film throughout NFT mint
            IStakingPool(STAKING_POOL).sendVAB(_user, _user, revenueAmount);
            restAmount -= revenueAmount;
        }        
        // Transfer remain amount to film owner
        IStakingPool(STAKING_POOL).sendVAB(_user, fInfo.studio, restAmount);

        userFinalFilmIds[_user].push(_filmId);
    }     

    /// @dev Get payout(VAB) amount based on watched percent for a film
    function __getPayoutFor(uint256 _rentPrice, uint256 _percent) private view returns(uint256) {
        uint256 usdcAmount = _rentPrice * _percent / 1e10;
        address vabToken = IOwnablee(OWNABLE).PAYOUT_TOKEN();
        address usdcToken = IOwnablee(OWNABLE).USDC_TOKEN();
        return IUniHelper(UNI_HELPER).expectedAmount(usdcAmount, usdcToken, vabToken);
    }

    /// @dev For transferring to Studio, Get share amount based on share percent
    function __getShareAmount(
        uint256 _payout, 
        uint256 _filmId, 
        uint256 _k
    ) private view returns(uint256) {
        return _payout * filmInfo[_filmId].sharePercents[_k] / 1e10;
    }

    /// @notice Get film item based on filmId
    function getFilmById(uint256 _filmId) external view 
    returns (
        uint256[] memory nftRight_,
        uint256[] memory sharePercents_,
        address[] memory choiceAuditor_,
        address[] memory studioPayees_
    ) {
        nftRight_ = filmInfo[_filmId].nftRight;
        sharePercents_ = filmInfo[_filmId].sharePercents;
        choiceAuditor_ = filmInfo[_filmId].choiceAuditor;
        studioPayees_ = filmInfo[_filmId].studioPayees;  
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

    /// @notice Get film proposal created time based on Id
    function getFilmProposalTime(uint256 _filmId) external view returns (uint256 cTime_, uint256 aTime_) {
        cTime_ = filmInfo[_filmId].pCreateTime;
        aTime_ = filmInfo[_filmId].pApproveTime;
    }

    /// @notice Set film proposal approved time based on Id
    function setFilmProposalApproveTime(uint256 _filmId, uint256 _time) external onlyVote {
        filmInfo[_filmId].pApproveTime = _time;
    }

    /// @notice Get film Ids
    function getFilmIds(uint256 _flag) external view returns (uint256[] memory) {        
        if(_flag == 1) return proposalFilmIds;
        else if(_flag == 2) return approvedNoVoteFilmIds;        
        else if(_flag == 3) return approvedFundingFilmIds;
        else return approvedListingFilmIds;
    }

    function getUserFilmIds(uint256 _flag, address _user) external view returns (uint256[] memory) {        
        if(_flag == 1) return userFinalFilmIds[_user];        
        else return userFilmProposalIds[_user];
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
    function updatePropertyProposalApproveTime(uint256 _property, uint256 _flag, uint256 _time) external;
    function updateGovProposalApproveTime(address _member, uint256 _flag, uint256 _time) external;
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
    
    function sendVAB(address _user, address _to, uint256 _amount) external;
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

    function expectedAmountIn(
        uint256 _depositAmount,
        address _depositAsset, 
        address _incomingAsset
    ) external view returns (uint256 amount_);

    function swapAsset(bytes calldata _swapArgs) external returns (uint256 amount_);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Helper {
    enum Status {
        LISTED,              // proposal created by studio
        APPROVED_LISTING,    // approved for listing by vote from VAB holders(staker)
        APPROVED_FUNDING,    // approved for funding by vote from VAB holders(staker)
        APPROVED_WITHOUTVOTE // approved without community Vote
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