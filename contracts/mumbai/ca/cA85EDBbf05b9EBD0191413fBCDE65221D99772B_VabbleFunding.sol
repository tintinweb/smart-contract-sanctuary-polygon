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
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/Helper.sol";
import "../interfaces/IUniHelper.sol";
import "../interfaces/IStakingPool.sol";
import "../interfaces/IProperty.sol";
import "../interfaces/IOwnablee.sol";
import "../interfaces/IFactoryFilmNFT.sol";
import "../interfaces/IVabbleDAO.sol";

contract VabbleFunding is ReentrancyGuard {
    
    event DepositedTokenToFilm(address customer, address token, uint256 amount, uint256 filmId, uint256 depositTime);
    event FundFilmProcessed(uint256 filmId, address studio, uint256 processTime);
    event FundWithdrawed(uint256 filmId, address customer, uint256 withdrawTime);
    
    struct Asset {
        address token;   // token address
        uint256 amount;  // token amount
    }
  
    address private immutable OWNABLE;         // Ownablee contract address
    address private immutable STAKING_POOL;    // StakingPool contract address
    address private immutable UNI_HELPER;      // UniHelper contract address
    address private immutable DAO_PROPERTY;
    address private immutable FILM_NFT_FACTORY;  
    address private immutable VABBLE_DAO;  
    
    uint256[] private fundProcessedFilmIds;
    
    mapping(uint256 => Asset[]) public assetPerFilm;                  // (filmId => Asset[token, amount])
    mapping(uint256 => mapping(address => Asset[])) public assetInfo; // (filmId => (customer => Asset[token, amount]))
    mapping(uint256 => address[]) private filmInvestorList;   // (filmId => investor address[])
    mapping(address => uint256[]) private userInvestFilmIds;  // (user => invest filmId[]) for only approved_funding films
    mapping(address => mapping(uint256 => bool)) public isFundProcessed; // (customer => (filmId => true/false))
    
    receive() external payable {}
    
    constructor(
        address _ownable,
        address _uniHelper,
        address _staking,
        address _property,
        address _filmNftFactory,
        address _vabbleDAO
    ) {        
        require(_ownable != address(0), "ownableContract: Zero address");
        OWNABLE = _ownable;     
        require(_uniHelper != address(0), "uniHelperContract: Zero address");
        UNI_HELPER = _uniHelper;
        require(_staking != address(0), "stakingContract: Zero address");
        STAKING_POOL = _staking;      
        require(_property != address(0), "daoProperty: Zero address");
        DAO_PROPERTY = _property; 
        require(_filmNftFactory!= address(0), "setup: zero factoryContract address");
        FILM_NFT_FACTORY = _filmNftFactory;  
        require(_vabbleDAO!= address(0), "setup: zero DAO address");
        VABBLE_DAO = _vabbleDAO;  
    }

    // =================== Funding(Launch Pad) START ===============================
    /// @notice Deposit tokens(VAB, USDT, USDC)/native token($50 ~ $5000 per address for a film) to only funding film by investor
    function depositToFilm(
        uint256 _filmId,
        uint256 _amount, 
        address _token
    ) external payable {
        if(_token != IOwnablee(OWNABLE).PAYOUT_TOKEN() || _token != address(0)) {
            require(IOwnablee(OWNABLE).isDepositAsset(_token), "depositToFilm: not allowed asset");   
        }
        require(msg.sender != address(0) && _amount > 0, "depositToFilm: Zero value");

        (, uint256 fundPeriod, uint256 fundType) = IVabbleDAO(VABBLE_DAO).getFilmFund(_filmId);    
        (, uint256 pApproveTime) = IVabbleDAO(VABBLE_DAO).getFilmProposalTime(_filmId);
        Helper.Status status = IVabbleDAO(VABBLE_DAO).getFilmStatus(_filmId);

        require(fundType == 1 || fundType == 3, "depositToFilm: not fund type by token");
        require(status == Helper.Status.APPROVED_FUNDING, "depositToFilm: filmId not approved for funding");
        require(fundPeriod >= block.timestamp - pApproveTime, "depositToFilm: passed funding period");    

        uint256 userFundAmountPerFilm = getUserFundAmountPerFilm(msg.sender, _filmId);
        uint256 fundAmount = _amount;
        if(_token != IOwnablee(OWNABLE).USDC_TOKEN()) {
            fundAmount = IUniHelper(UNI_HELPER).expectedAmount(_amount, _token, IOwnablee(OWNABLE).USDC_TOKEN());    
        }
        uint256 amountOfUser = userFundAmountPerFilm + fundAmount;  
        require(__checkMinMaxAmount(amountOfUser), "depositToFilm: Invalid amount");

        if(userFundAmountPerFilm == 0) {
            filmInvestorList[_filmId].push(msg.sender);            
            userInvestFilmIds[msg.sender].push(_filmId);
        }

        // Return remain ETH to user back if case of ETH
        if(_token == address(0)) {
            require(msg.value >= _amount, "depositToFilm: Insufficient paid");
            if (msg.value > _amount) {
                Helper.safeTransferETH(msg.sender, msg.value - _amount);
            }
        } else {
            Helper.safeTransferFrom(_token, msg.sender, address(this), _amount);
        }
        
        __assignToken(_filmId, _token, _amount);

        emit DepositedTokenToFilm(msg.sender, _token, _amount, _filmId, block.timestamp);
    }    

    /// @dev Update/Add user fund amount
    function __assignToken(uint256 _filmId, address _token, uint256 _amount) private {
        bool isNewTokenPerUser = true;
        bool isNewTokenPerFilm = true;

        // update token amount
        for(uint256 i = 0; i < assetInfo[_filmId][msg.sender].length; i++) {
            if(_token == assetInfo[_filmId][msg.sender][i].token) {
                assetInfo[_filmId][msg.sender][i].amount += _amount;
                isNewTokenPerUser = false;
            }
        }
        // add new token
        if(isNewTokenPerUser) {
            assetInfo[_filmId][msg.sender].push(Asset({token: _token, amount: _amount}));
        }
        
        for(uint256 i = 0; i < assetPerFilm[_filmId].length; i++) {
            if(_token == assetPerFilm[_filmId][i].token) {
                assetPerFilm[_filmId][i].amount += _amount;
                isNewTokenPerFilm = false;
            }
        }
        if(isNewTokenPerFilm) {
            assetPerFilm[_filmId].push(Asset({token: _token, amount: _amount}));
        }
    }

    /// @notice onlyStudio send the 2% of funds to reward pool in VAB if funding meet the raise amount after fund period
    function fundProcess(uint256 _filmId) external nonReentrant {                
        address owner = IVabbleDAO(VABBLE_DAO).getFilmOwner(_filmId);
        require(owner == msg.sender, "fundProcess: not film owner");

        Helper.Status status = IVabbleDAO(VABBLE_DAO).getFilmStatus(_filmId);
        require(status == Helper.Status.APPROVED_FUNDING, "fundProcess: filmId not approved for funding");
        
        (, uint256 fundPeriod, ) = IVabbleDAO(VABBLE_DAO).getFilmFund(_filmId);    
        (, uint256 pApproveTime) = IVabbleDAO(VABBLE_DAO).getFilmProposalTime(_filmId);        
        require(fundPeriod < block.timestamp - pApproveTime, "fundProcess: funding period");

        require(isRaisedFullAmount(_filmId), "fundProcess: fails to meet raise amount");
        require(!isFundProcessed[msg.sender][_filmId], "fundProcess: already processed");
        
        // Send fundFeePercent(2%) to reward pool as VAB token and rest send to studio
        address vabToken = IOwnablee(OWNABLE).PAYOUT_TOKEN();
        Asset[] memory assetArr = assetPerFilm[_filmId];
        uint256 rewardSumAmount;
        uint256 rewardAmount;
        for(uint256 i = 0; i < assetArr.length; i++) {                
            rewardAmount = assetArr[i].amount * IProperty(DAO_PROPERTY).fundFeePercent() / 1e10;
            if(vabToken == assetArr[i].token) {
                rewardSumAmount += rewardAmount;
            } else {
                if(assetArr[i].token == address(0)) {
                    Helper.safeTransferETH(UNI_HELPER, rewardAmount);
                } else {
                    if(IERC20(assetArr[i].token).allowance(address(this), UNI_HELPER) == 0) {
                        Helper.safeApprove(assetArr[i].token, UNI_HELPER, IERC20(assetArr[i].token).totalSupply());
                    }
                }                
                bytes memory swapArgs = abi.encode(rewardAmount, assetArr[i].token, vabToken);
                rewardSumAmount += IUniHelper(UNI_HELPER).swapAsset(swapArgs);
            }
            Helper.safeTransferAsset(assetArr[i].token, msg.sender, (assetArr[i].amount - rewardAmount));
            // assetArr[i].amount = 0;
        }

        if(rewardSumAmount > 0) {
            if(IERC20(vabToken).allowance(address(this), STAKING_POOL) == 0) {
                Helper.safeApprove(vabToken, STAKING_POOL, IERC20(vabToken).totalSupply());
            }        
            IStakingPool(STAKING_POOL).addRewardToPool(rewardSumAmount);
        }

        fundProcessedFilmIds.push(_filmId);
        isFundProcessed[msg.sender][_filmId] = true;

        emit FundFilmProcessed(_filmId, msg.sender, block.timestamp);
    }

    /// @notice Investor can withdraw fund after fund period if funding fails to meet the raise amount
    function withdrawFunding(uint256 _filmId) external nonReentrant {     
        Helper.Status status = IVabbleDAO(VABBLE_DAO).getFilmStatus(_filmId);        
        require(status == Helper.Status.APPROVED_FUNDING, "withdrawFunding: filmId not approved for funding");
        
        (, uint256 fundPeriod, ) = IVabbleDAO(VABBLE_DAO).getFilmFund(_filmId);    
        (, uint256 pApproveTime) = IVabbleDAO(VABBLE_DAO).getFilmProposalTime(_filmId); 
        require(fundPeriod < block.timestamp - pApproveTime, "withdrawFunding: funding period");

        require(!isRaisedFullAmount(_filmId), "withdrawFunding: satisfied raise amount");

        Asset[] storage assetArr = assetInfo[_filmId][msg.sender];
        for(uint256 i = 0; i < assetArr.length; i++) {   
            if(assetArr[i].token == address(0)) {
                if(address(this).balance >= assetArr[i].amount) {
                    Helper.safeTransferETH(msg.sender, assetArr[i].amount);
                    assetArr[i].amount = 0;
                }                
            } else {
                if(IERC20(assetArr[i].token).balanceOf(address(this)) >= assetArr[i].amount) {
                    Helper.safeTransfer(assetArr[i].token, msg.sender, assetArr[i].amount);    
                    assetArr[i].amount = 0;
                }
            }
        }

        emit FundWithdrawed(_filmId, msg.sender, block.timestamp);
    }

    /// @dev Check min & max amount for each token/ETH per film
    function __checkMinMaxAmount(uint256 _amount) private view returns (bool passed_) {
        if(_amount >= IProperty(DAO_PROPERTY).minDepositAmount() && _amount <= IProperty(DAO_PROPERTY).maxDepositAmount()) {
            passed_ = true;
        } else {
            passed_ = false;
        } 
    }
    
    /// @notice Check if fund meet raise amount
    function isRaisedFullAmount(uint256 _filmId) public view returns (bool) {
        uint256 raisedAmount = getRaisedAmountByToken(_filmId) + IFactoryFilmNFT(FILM_NFT_FACTORY).getRaisedAmountByNFT(_filmId);

        (uint256 raiseAmount, , ) = IVabbleDAO(VABBLE_DAO).getFilmFund(_filmId);    
        if(raisedAmount > 0 && raisedAmount >= raiseAmount) {
            return true;
        } else {
            return false;
        }
    }     

    /// @notice Get user fund amount in cash(usdc) for each token per film
    function getUserFundAmountPerFilm(
        address _customer, 
        uint256 _filmId
    ) public view returns (uint256 amount_) {
        address usdcToken = IOwnablee(OWNABLE).USDC_TOKEN();
        Asset[] memory assetArr = assetInfo[_filmId][_customer];
        for(uint256 i = 0; i < assetArr.length; i++) {
            if(assetArr[i].amount == 0) continue;

            if(assetArr[i].token == usdcToken) {
                amount_ += assetArr[i].amount;
            } else {
                amount_ += IUniHelper(UNI_HELPER).expectedAmount(assetArr[i].amount, assetArr[i].token, usdcToken);
            }
        }
    }

    /// @notice Get fund amount in cash(usdc) per film
    function getRaisedAmountByToken(uint256 _filmId) public view returns (uint256 amount_) {
        address usdcToken = IOwnablee(OWNABLE).USDC_TOKEN();
        Asset[] memory assetArr = assetPerFilm[_filmId];
        for(uint256 i = 0; i < assetArr.length; i++) {
            if(assetArr[i].amount == 0) continue;

            if(assetArr[i].token == usdcToken) {
                amount_ += assetArr[i].amount;
            } else {
                amount_ += IUniHelper(UNI_HELPER).expectedAmount(assetArr[i].amount, assetArr[i].token, usdcToken);
            }
        }
    }

    /// @notice Get investor list per film Id
    function getInvestorList(uint256 _filmId) external view returns (address[] memory) {
        return filmInvestorList[_filmId];
    }

    /// @notice Get fundProcessedFilmIds
    function getFundProcessedFilmIdList() external view returns (uint256[] memory) {
        return fundProcessedFilmIds;
    }

    /// @notice Get userInvestFilmIds
    function getUserInvestFilmIdList(address _user) external view returns (uint256[] memory) {
        return userInvestFilmIds[_user];
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

    function swapAsset(bytes calldata _swapArgs) external returns (uint256 amount_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/Helper.sol";

interface IVabbleDAO {   

    function getFilmFund(uint256 _filmId) external view returns (uint256 raiseAmount_, uint256 fundPeriod_, uint256 fundType_);

    function getFilmStatus(uint256 _filmId) external view returns (Helper.Status status_);
    
    function getFilmOwner(uint256 _filmId) external view returns (address owner_);

    function getFilmProposalTime(uint256 _filmId) external view returns (uint256 cTime_, uint256 aTime_);

    function setFilmProposalApproveTime(uint256 _filmId, uint256 _time) external;

    function approveFilm(uint256 _filmId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Helper {
    enum Status {
        LISTED,              // proposal created by studio
        UPDATED,             // proposal updated by studio
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