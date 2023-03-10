// SPDX-License-Identifier: AGPL-3.0
// Copyright (c) 2023 Upshot Technologies Inc. All Rights Reserved
pragma solidity ^0.8.0;

interface IAdminTwoStep {
    function admin() external view returns (address);
    function pendingAdmin() external view returns (address);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    function transferAdmin(address newAdmin) external;
    function claimAdmin() external;
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Upshot Technologies Inc. All Rights Reserved
pragma solidity 0.8.x;

import {LpPosition} from "../pool/LpPosition.sol";
import {CreatePairParams} from "../pool/CreatePairParams.sol";
import {IPermitter} from "../interface/IPermitter.sol";

import {IERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {CurveErrorCode} from "../util/CurveErrorCode.sol";

import {IAdminTwoStep} from "./IAdminTwoStep.sol";

interface IDittoPool is IAdminTwoStep {
    // forgefmt: disable-start
    // * =============== ADMINISTRATIVE FUNCTIONS ================== *
    // forgefmt: disable-end

    /**
     * @notice For use in tokenURI function metadata
     * @return curve type of curve
     */
    function bondingCurve() external pure returns (string memory curve);

    /**
     * @notice Used by the Contract Factory to set the initial state & parameters of the pool.
     * @dev Necessary separate from constructor due to [ERC-1167](https://eips.ethereum.org/EIPS/eip-1167) factory clone paradigm
     * @param params A struct that contains various initialization parameters for the pool. See `CreatePairParams.sol` for details.
     * @param lpNft_ The Liquidity Provider Positions NFT contract that tokenizes liquidity provisions in the protocol
     * @param permitter_ Contract to authorize which tokenIds from the underlying collection are allowed to be traded in this pool.
     * @dev Set permitter to address(0) to allow any TokenIds from the underlying NFT collection.
     */
    function initPool(CreatePairParams calldata params, LpPosition lpNft_, IPermitter permitter_) external;

    /**
     * @notice Admin: change the spot price charged to buy an NFT from the pair
     * @param newSpotPrice_ New spot price: now NFTs purchased at this price, sold at `newSpotPrice_ + Delta`
     */
    function changeSpotPrice(uint128 newSpotPrice_) external;

    /**
     * @notice Change the delta parameter associated with the bonding curve
     * @dev see the sudoswap documentation on bonding curves for additional information
     * Each bonding curve uses delta differently, but in general it is used as an input
     * to determine the next price on the bonding curve
     * @param newDelta_ New delta parameter
     */
    function changeDelta(uint128 newDelta_) external;


    /**
     * @notice Change the pool's fee, paid to the pool admin, charged by the pool for trades with it
     * @param newFee_ New fee, in wei / 1e18, charged by the pool for trades with it (i.e. 1% = 0.01e18)
     */
    function changeFee(uint96 newFee_) external;


    /**
     * @notice Change who the pool admin fee for this pool is sent to.
     * @param newAdminFeeRecipient_ New address to send admin fees to
     */
    function changeAdminFeeRecipient(address newAdminFeeRecipient_) external;


    // forgefmt: disable-start


    // ***************************************************************
    // * ===== FUNCTIONS TO MARKET MAKE: ADD/REMOVE LIQUIDITY ====== *
    // ***************************************************************


    // forgefmt: disable-end

    /**
     * @notice Function for market makers / liquidity providers to deposit NFTs and ERC20s into the pool.
     * @dev Can be called multiple times to add liquidity to an existing position.
     * @param tokenIdList_ The list of NFT tokenIds msg.sender wishes to deposit into the pool.
     * @param tokenDepositAmount_ The amount of ERC20 tokens msg.sender wishes to deposit into the pool.
     * @return lpPositionTokenId The tokenId of the LP position NFT that was minted as a result of this liquidity deposit.
     */
    function addLiquidity(
        uint256[] calldata tokenIdList_,
        uint256 tokenDepositAmount_,
        bytes calldata permitterData
    ) external returns (uint256 lpPositionTokenId);

    /**
     * @notice DittoContractFactory convience function to deposit liqudity into the pool on behalf of a third party
     * @dev This function expects a third party to "forward" nfts and tokens to the pool: necessary because on the
     * creation and deposit of liquidity to a new pool, the pool does not exist at the beginning of the transaction
     * so there is no way to approve the pool to transfer tokens first. E.g. NFTs flow from alice -> factory -> pool
     * all of the resulting liquidity is then given to lpPositionRecipient_. Important: if called incorrectly,
     * `lpPositionRecipient_` can steal everything deposited from msg.sender after this addLiquidityFromForwarder call.
     * @param tokenIdList_ The list of NFT tokenIds msg.sender wishes to deposit into the pool.
     * @param tokenDepositAmount_ The amount of ERC20 tokens msg.sender wishes to deposit into the pool.
     * @param lpPositionRecipient_ Who receives control of resulting LP position NFT and therefore all the liquidity
     * @return lpPositionTokenId The tokenId of the LP position NFT that was minted as a result of this liquidity deposit.
     */
    function addLiquidityFromForwarder(
        uint256[] calldata tokenIdList_,
        uint256 tokenDepositAmount_,
        address lpPositionRecipient_,
        bytes calldata permitterData
    ) external returns (uint256 lpPositionTokenId);

    /**
     * @notice Function for liquidity providers to withdraw NFTs and ERC20 tokens from their LP positions.
     * @dev Can be called to change an existing liquidity position, or remove an LP position by withdrawing all liquidity.
     * @param tokenIdList_ The list of NFT tokenIds msg.sender wishes to withdraw from the pool.
     * @param tokenWithdrawAmount_ The amount of ERC20 tokens the msg.sender wishes to withdraw from the pool.
     * @param lpPositionTokenId_ The tokenId of the LP position NFT that the liquidity is being removed from.
     */
    function pullLiquidity(
        uint256[] calldata tokenIdList_, 
        uint256 tokenWithdrawAmount_, 
        uint256 lpPositionTokenId_
    ) external;


    // forgefmt: disable-start
    // ***************************************************************
    // * =========== FUNCTIONS TO TRADE WITH THE POOL ============== *
    // ***************************************************************
    // forgefmt: disable-end

    /**
     * @notice Trade ERC20s for a specific list of NFT token ids.
     * @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
     * This swap is meant for users who want specific IDs. Also higher chance of
     * reverting if some of the specified IDs leave the pool before the swap goes through.
     * @param nftIds The list of IDs of the NFTs to purchase
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender (in wei or base units of ERC20).
     * If the actual amount is greater than this value, the transaction will be reverted.
     * @param nftRecipient Address to send the NFTs to
     * @return inputAmount The actual amount of token consumed by this purchase transaction
     */
    function swapTokensForNfts(
        uint256[] calldata nftIds, 
        uint256 maxExpectedTokenInput, 
        address nftRecipient
    ) external returns (uint256 inputAmount);
       
    /**
     * @notice Trades NFTs in exchange for money in ERC20 form.
     * @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
     * @dev Key difference with sudoswap here:
     * In sudoswap, each market maker has a separate smart contract with their liquidity.
     * To sell to a market maker, you just check if their specific `LSSVMPair` contract has enough money.
     * In DittoSwap, we share different market makers' liquidity in the same pool contract.
     * So this function has an additional parameter `lpPositionIds` forcing the buyer to check
     * off-chain which market maker's LP position that they want to trade with, for each specific NFT
     * that they are selling into the pool. The lpPositionIds array should correspond with the nftIds
     * array in the same order & indexes. e.g. to sell NFT with tokenId 1337 to the market maker who's
     * LP position has id 42, the buyer would call this function with
     * nftIds = [1337] and lpPositionIds = [42].
     *
     * @param nftIds The list of IDs of the NFTs to sell to the pair
     * @param lpPositionIds The list of IDs of the LP positions to sell to the pair
     * @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
     * amount is less than this value, the transaction will be reverted.
     * @param tokenRecipient The recipient of the token output
     * @return outputAmount The amount of token received
     */
    function swapNftsForTokens(
        uint256[] calldata nftIds,
        uint256[] calldata lpPositionIds,
        uint256 minExpectedTokenOutput,
        address tokenRecipient,
        bytes calldata permitterData
    ) external returns (uint256 outputAmount);

     /**
        @dev Used as read function to query the bonding curve for buy pricing info
        @param numNfts The number of NFTs to buy from the pair
     */
    function getBuyNftQuote(
        uint256 numNfts
    ) external view returns (
        CurveErrorCode error,
        uint256 newSpotPrice,
        uint256 newDelta,
        uint256 inputAmount,
        uint256 adminFee,
        uint256 protocolFee
    );

    /**
        @dev Used as read function to query the bonding curve for sell pricing info
        @param numNfts The number of NFTs to sell to the pair
     */
    function getSellNftQuote(
        uint256 numNfts
    ) external view returns (
        CurveErrorCode error,
        uint256 newSpotPrice,
        uint256 newDelta,
        uint256 outputAmount,
        uint256 adminFee,
        uint256 protocolFee
    );

    // forgefmt: disable-start


    // ***************************************************************
    // * ======= EXTERNALLY CALLABLE READ-ONLY VIEW FUNCTIONS ====== *
    // ***************************************************************


    // forgefmt: disable-end

    /**
     * @notice Returns the address of the ERC20 token that this pool is trading NFTs against.
     * @return token_ The address of the ERC20 token that this pool is trading NFTs against.
     */
    function token() external view returns (address token_);

   /**
     * @notice returns the status of whether this contract has been initialized
     * @dev see [ERC-1167](https://eips.ethereum.org/EIPS/eip-1167) factory clone paradigm
     * and also `DittoPoolFactory.sol`
     *
     * @return initialized whether the contract has been initialized
     */
    function initialized() external view returns (bool);

    /**
     * @notice returns the fee associated with trading with any pair of this pool
     * @return fee_ the fee associated with trading with any pair of this pool
     */
    function fee() external view returns (uint96 fee_);

    /**
     * @notice returns the delta parameter for the bonding curve associated this pool
     * see sudoswap documentation for details on bonding curves
     * Each bonding curve uses delta differently, but in general it is used as an input
     * to determine the next price on the bonding curve
     * @return delta_ the delta parameter for the bonding curve of this pool
     */
    function delta() external view returns (uint128 delta_);

    /**
     * @notice returns the spot price to sell the next NFT into this pool, spot+delta to buy
     * @return spotPrice_ this pool's current spot price
     */
    function spotPrice() external view returns (uint128 spotPrice_);

    /**
     * @notice returns the factory that created this pool, see ERC-1167
     * @return dittoPoolFactory the ditto pool factory for the contract
     */
    function dittoPoolFactory() external view returns (address);

    /**
     * @notice returns the address that recieves admin fees from trades with this pool
     * @return adminFeeRecipient returns the admin fee recipient of this pool
     */
    function adminFeeRecipient() external view returns (address);

    /**
     * @notice returns the NFT collection that represents liquidity positions in this pool
     * @return lpNft address of the LP Position NFT collection for this pool
     */
    function getLpPositionCollection() external view returns (address);

    /**
     * @notice returns the nft collection that this pool trades with/for
     * @return nft_ the address of the underlying nft collection contract
     */
    function nft() external view returns (IERC721 nft_);

    /**
     * @notice returns the permitter contract that allows or denies specific NFT tokenIds to be traded in this pool
     * @dev if this address is zero, then all NFTs from the underlying collection are allowed to be traded in this pool
     * @return permitter the address of this pool's permitter contract, or zero if no permitter is set
     */
    function permitter() external view returns (IPermitter);

    /**
     * @notice returns how many ERC20 tokens a liquidity provider has in the pool
     * @param lpPositionTokenId_ LP Position NFT token ID to query for
     * @return lpTokenBalance the amount of ERC20 tokens the liquidity provider has in the pool
     */
    function getTokenBalanceForLpPositionId(uint256 lpPositionTokenId_) external view returns (uint256);

    /**
     * @notice return the full list of NFT tokenIds that are owned by a specific liquidity provider in this pool
     * @dev this function is not gas efficient and not-meant to be used on chain, only as a convenience for off-chain
     * worst-case is O(n) over the length of all the NFTs owned by the pool
     * @param lpPositionId_ an LP position NFT token Id for a user providing liquidity to this pool
     * @return nftIds the list of NFT tokenIds in this pool that are owned by the specific liquidity provider
     */
    function getNftIdsForLpPositionId(uint256 lpPositionId_) external view returns (uint256[] memory nftIds);

    /**
     * @notice returns the number of NFTs owned by a specific liquidity provider in this pool
     * @param lpPositionId_ a user providing liquidity to this pool for trading with
     * @return userNftCount the number of NFTs in this pool owned by the liquidity provider
     */
    function getNftCountForLpPositionId(uint256 lpPositionId_) external view returns (uint256);

    /**
     * @notice returns the number of NFTs and number of ERC20s owned by a specific liquidity provider in this pool
     * pretty much equivalent to the user's liquidity position in non-nft form.
     * @param lpPositionId_ a user providing liquidity to this pool for trading with
     * @return tokenBalance the amount of ERC20 tokens the liquidity provider has in the pool
     * @return userNftCount the number of NFTs in this pool owned by the liquidity provider
     */
    function getDepositForLpPositionId(uint256 lpPositionId_) external view returns (uint256 tokenBalance, uint256 userNftCount);

    /**
     * @notice returns the full list of all NFT tokenIds that are owned by this pool
     * @dev does not have to match what the underlying NFT contract balanceOf(dittoPool) 
     * thinks is owned by this pool: this is only valid liquidity tradeable in this pool
     * NFTs can be lost by unsafe transferring them to a dittoPool
     * also this function is O(n) gas efficient, only really meant to be used off-chain
     * @return nftIds the list of all NFT Token Ids in this pool, across all liquidity positions
     */
    function getAllPoolHeldNftIds() external view returns (uint256[] memory);

    /**
     * @notice returns the full list of all LP Position NFT tokenIds that represent liquidity in this pool
     * @return lpIds the list of all LP Position NFT Token Ids corresponding to liquidity in this pool
     */
    function getAllPoolLpPositionIds() external view returns (uint256[] memory);

    /**
     * @notice returns the full amount of all ERC20 tokens that the pool thinks it owns
     * @dev may not match the underlying ERC20 contract balanceOf() because of unsafe transfers
     * this is only accounting for valid liquidity tradeable in the pool
     * @return totalPoolTokenBalance the amount of ERC20 tokens the pool thinks it owns
     */
    function getAllPoolTokenBalance() external view returns (uint256);







    /**
     * @dev When safeTransfering an ERC721 in, we add ID to the idSet
     *     if it's the same collection used by pool. (As it doesn't auto-track because no ERC721Enumerable)
     *
     * TYLER SECURITY NOTE: Believe this function has to be changed to be a no-operation
     * all internal token balance accounting needs to happen in addLiquidity functions, as users can just
     * safeTransferFrom NFTs to the pool directly without calling the addLiquidity functions
     * Will bring this up for a different commit to edit
     */
    function onERC721Received(address, address, uint256 id, bytes memory) external returns (bytes4);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC4906 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Upshot Technologies Inc. All Rights Reserved
pragma solidity 0.8.x;

import {IERC4906} from "./IERC4906.sol";
import {IDittoPool} from "./IDittoPool.sol";
import {IERC721} from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface ILpPosition is IERC4906 {
    // forgefmt: disable-next-line
    // * =============== State Changing Functions ================== *

    /**
     * @notice Allows the factory to whitelist DittoPool contracts as allowed to mint and burn LpPosition NFTs.
     * @dev only the Ditto Pool Factory is allowed to call this function
     * @param dittoPool_ The address of the DittoPool contract to whitelist.
     * @param nft_ The address of the NFT contract that the DittoPool trades.
     */
    function setApprovedDittoPool(address dittoPool_, address nft_) external;

    /**
     * @notice mint function used to create new LP Position NFTs
     * @dev only callable by approved DittoPool contracts
     * @param _to The address of the user who will own the new NFT.
     * @return tokenId The tokenId of the newly minted NFT.
     */
    function mint(address _to) external returns (uint256 tokenId);

    /**
     * @notice burn function used to destroy LP Position NFTs
     * @dev only supposed to be called by approved DittoPool contracts
     * @param tokenId_ The tokenId of the NFT to burn.
     */
    function burn(uint256 tokenId_) external;

    /**
     * @notice Updates LP position NFT metadata on trades, as LP's LP information changes due to the trade
     * @dev see [EIP-4906](https://eips.ethereum.org/EIPS/eip-4906) EIP-721 Metadata Update Extension
     * @dev only supposed to be called by approved DittoPool contracts
     * @param tokenId_ the tokenId of the NFT who's metadata needs to be updated
     */
    function emitMetadataUpdate(uint256 tokenId_) external;

    /**
     * @notice Tells off-chain actors to update LP position NFT metadata for all tokens in the collection
     * @dev see [EIP-4906](https://eips.ethereum.org/EIPS/eip-4906) EIP-721 Metadata Update Extension
     * @dev only supposed to be called by approved DittoPool contracts
     */
    function emitMetadataUpdateForAll() external;

    // forgefmt: disable-next-line
    // * ======= EXTERNALLY CALLABLE READ-ONLY VIEW FUNCTIONS ====== *


    /**
     * @notice Returns the DittoPool and liquidity provider's address for a given LP Position NFT tokenId.
     * @param tokenId_ The LP Position tokenId to get info for.
     * @return pool The DittoPool contract that the LP Position NFT is tied to.
     * @return user The liquidity provider's address that the LP Position NFT is tied to.
     */
    function getPoolAndUserForLpPositionId(uint256 tokenId_) external view returns (IDittoPool pool, address user);

    /**
     * @notice Returns the address of the underlying NFT collection traded by the DittoPool correspoding to an LP Position NFT tokenId.
     * @param tokenId_ The LP Position tokenId to get info for.
     * @return nft The address of the underlying NFT collection for that LP position
     */
    function getNftForLpPositionId(uint256 tokenId_) external view returns (IERC721);

    /**
     * @notice Returns the tokenId of an LP Position NFT for a given DittoPool and liquidity provider's address.
     * @dev this function will return address(0) if no LP Position NFT exists for the given pool and liquidity provider.
     * @param pool_ the DittoPool address to get info for
     * @param user_ the liqudity provider's address to get info for
     * @return id the tokenId of the LP Position NFT for the given pool and liquidity provider.
     */
    function getLpPositionIdForPoolAndUser(address pool_, address user_) external view returns (uint256);

    /**
     * @notice Returns the amount of ERC20 tokens held by a liquidity provider in a given LP Position.
     * @param tokenId_ The LP Position tokenId to get info for.
     * @return value the amount of ERC20 tokens held by the liquidity provider in the given LP Position.
     */
    function getLpPositionValueToken(uint256 tokenId_) external view returns (uint256);

    /**
     * @notice returns the list of NFT Ids (of the underlying NFT collection) held by a liquidity provider in a given LP Position.
     * @param tokenId_ The LP Position tokenId to get info for.
     * @return nftIds the list of NFT Ids held by the liquidity provider in the given LP Position.
     */
    function getAllHeldNftIds(uint256 tokenId_) external view returns (uint256[] memory);

    /**
     * @notice returns the sum total of NFTs held by a liquidity provider in a given LP Position.
     * @param tokenId_ The LP Position tokenId to get info for.
     * @return nftCount the sum total of NFTs held by the liquidity provider in the given LP Position.
     */
    function getNumNftsHeld(uint256 tokenId_) external view returns (uint256);

    /**
     * @notice returns the "value" of an LP positions NFT holdings in ERC20 Tokens,
     * if it were to be sold at the current spot price today
     * @param tokenId_ The LP Position tokenId to get info for.
     * @return value the "value" of an LP positions NFT holdings in ERC20 Tokens.
     */
    function getLpPositionValueNft(uint256 tokenId_) external view returns (uint256);

    /**
     * @notice returns the "value" of an LP positions total holdings in ERC20s + NFTs,
     * if all the Nfts in the holdings were sold at the current spot price today
     * @param tokenId_ The LP Position tokenId to get info for.
     * @return value the "value" of an LP positions sum total holdings in ERC20s + NFTs.
     */
    function getLpPositionValue(uint256 tokenId_) external view returns (uint256);

    /**
     * @notice returns the address of the DittoPoolFactory contract
     * @return factory the address of the DittoPoolFactory contract
     */
    function dittoPoolFactory() external view returns (address);

    /**
     * @notice returns the next tokenId to be minted
     * @dev NFTs are minted sequentially, starting at tokenId 1
     * @return nextId the next tokenId to be minted
     */
    function nextId() external view returns (uint256);

    /**
     * @notice returns the total number of LP Position NFTs in existence right now
     * @dev see [ERC-721 Metadata Extension](https://eips.ethereum.org/EIPS/eip-721) standard
     * @return totalSupply the total number of LP Position NFTs in existence right now
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Upshot Technologies Inc. All Rights Reserved
pragma solidity 0.8.x;

interface IPermitter {
    function checkPermitterData(
        uint[] calldata tokenIds, 
        bytes memory premitterData
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Upshot Technologies Inc. All Rights Reserved
pragma solidity 0.8.x;

struct CreatePairParams {
    address token; // ERC20 token address
    address nft; // the address of the NFT collection that we are creating a pool for
    address owner; // owner creating the pool. Pool uses this info, but does not actually set it on the pair
    uint128 delta; // the delta of the pool, see sudoswap documentation
    uint96 fee; // the fee price of the pool for trades
    uint128 spotPrice; // the spot price of the pool, see sudoswap documentation
    uint256[] tokenIdList; // the token IDs of NFTs to deposit into the pool
    uint256 initialTokenBalance; // the number of ERC20 tokens to transfer to the pool
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Upshot Technologies Inc. All Rights Reserved
pragma solidity 0.8.x;

import {AdminTwoStep} from "../util/AdminTwoStep.sol";
import {MetadataInfo} from "./metadata/MetadataInfo.sol";
import {MetadataGenerator} from "./metadata/MetadataGenerator.sol";
import {ILpPosition} from "../interface/ILpPosition.sol";
import {ERC721 as ERC721Solmate} from "../../../lib/solmate/src/tokens/ERC721.sol";
import {IDittoPool} from "../interface/IDittoPool.sol";
import {IERC721} from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

/**
 * @title LpPosition
 * @author Upshot Technologies Inc.
 * @notice LpPosition is an ERC721 NFT collection that tokenizes market makers' liquidity positions in the Ditto protocol.
 * @dev Invariant: For each individual DittoPool, every liquidity provider can have at most 1 NFT tokenId tied to their position in that pool.
 */
contract LpPosition is AdminTwoStep, ILpPosition, ERC721Solmate {
    address internal immutable _dittoPoolFactory;
    ///@dev NFTs are minted sequentially, starting at tokenId 1
    uint256 internal _nextId = 1;
    uint256 internal _totalSupply;

    ///@dev stores which pool each lpId corresponds to
    mapping(uint256 => IDittoPool) internal _idToPool;
    /// @dev the pool address is the key of the outer mapping, user address key for inner mapping
    mapping(address => mapping(address => uint256)) internal _poolAndUserToId;
    /// @dev dittoPool address is the key of the mapping, underlying NFT address traded by that pool is the value
    mapping(address => address) internal _approvedDittoPools;

    MetadataGenerator public _metadataGenerator;

    // forgefmt: disable-start
    // ***************************************************************
    // * =============== ADMINISTRATIVE FUNCTIONS ================== *
    // ***************************************************************
    // forgefmt: disable-end

    /**
     * @notice Constructor. Records the DittoPoolFactory address.
     */
    constructor(address metadataGenerator_, address admin) ERC721Solmate("Ditto LP Positions NFT", "ULP") {
        _dittoPoolFactory = msg.sender;
        _metadataGenerator = MetadataGenerator(metadataGenerator_);
        _setAdmin(admin);
    }

    /**
     * @notice Modifier that restricts access to the DittoPoolFactory contract that created this NFT collection.
     */
    modifier onlyDittoPoolFactory() {
        require(msg.sender == _dittoPoolFactory, "DITTO_FACTORY_ONLY");
        _;
    }

    /**
     * @notice Modifier that restricts access to DittoPool contracts that have been approved to mint and burn LpPosition NFTs.
     */
    modifier onlyApprovedDittoPools() {
        require(_approvedDittoPools[msg.sender] != address(0), "DITTO_POOL_ONLY");
        _;
    }

    // forgefmt: disable-start
    // ***************************************************************
    // * =============== State Changing Functions ================== *
    // ***************************************************************
    // forgefmt: disable-end

    function setMetadataGenerator(address metadataGenerator_) external onlyAdmin {
        _metadataGenerator = MetadataGenerator(metadataGenerator_);
    }

    ///@inheritdoc ILpPosition
    function setApprovedDittoPool(address dittoPool_, address nft_) public onlyDittoPoolFactory {
        _approvedDittoPools[dittoPool_] = nft_;
    }

    ///@inheritdoc ILpPosition
    function mint(address to_) public onlyApprovedDittoPools returns (uint256 tokenId) {
        tokenId = _nextId;

        _idToPool[tokenId] = IDittoPool(msg.sender);
        _poolAndUserToId[msg.sender][to_] = tokenId;

        _safeMint(to_, tokenId);
        unchecked {
            _nextId++;
            _totalSupply++;
        }
    }

    ///@inheritdoc ILpPosition
    function burn(uint256 tokenId_) external onlyApprovedDittoPools {
        address pool = address(_idToPool[tokenId_]);
        address user = _ownerOf[tokenId_];
        delete _idToPool[tokenId_];
        delete _poolAndUserToId[pool][user];

        unchecked {
            _totalSupply--;
        }

        _burn(tokenId_);
    }

    ///@inheritdoc ILpPosition
    function emitMetadataUpdate(uint256 tokenId_) external onlyApprovedDittoPools {
        emit MetadataUpdate(tokenId_);
    }

    ///@inheritdoc ILpPosition
    function emitMetadataUpdateForAll() external onlyApprovedDittoPools {
        if (_totalSupply > 0)
            emit BatchMetadataUpdate(1, _totalSupply);
    }

    ///@inheritdoc ERC721Solmate
    function transferFrom(address from_, address to_, uint256 id_) public override {
        ERC721Solmate.transferFrom(from_, to_, id_);
        address pool = address(_idToPool[id_]);
        delete _poolAndUserToId[pool][from_];
        _poolAndUserToId[pool][to_] = id_;
    }

    // forgefmt: disable-start
    // ***************************************************************
    // * ======= EXTERNALLY CALLABLE READ-ONLY VIEW FUNCTIONS ====== *
    // ***************************************************************
    // forgefmt: disable-end

    ///@inheritdoc ILpPosition
    function getPoolAndUserForLpPositionId(uint256 tokenId_) external view returns (IDittoPool pool, address user) {
        pool = _idToPool[tokenId_];
        user = _ownerOf[tokenId_];
    }

    ///@inheritdoc ILpPosition
    function getNftForLpPositionId(uint256 tokenId_) external view returns (IERC721) {
        address pool = address(_idToPool[tokenId_]);
        return IERC721(_approvedDittoPools[pool]);
    }

    ///@inheritdoc ILpPosition
    function getLpPositionIdForPoolAndUser(address pool_, address user_) external view returns (uint256) {
        return _poolAndUserToId[pool_][user_];
    }

    ///@inheritdoc ILpPosition
    function getLpPositionValueToken(uint256 tokenId_) public view returns (uint256) {
        IDittoPool pool = _idToPool[tokenId_];
        return pool.getTokenBalanceForLpPositionId(tokenId_);
    }

    ///@inheritdoc ILpPosition
    function getAllHeldNftIds(uint256 tokenId_) external view returns (uint256[] memory) {
        IDittoPool pool = _idToPool[tokenId_];
        return pool.getNftIdsForLpPositionId(tokenId_);
    }

    ///@inheritdoc ILpPosition
    function getNumNftsHeld(uint256 tokenId_) public view returns (uint256) {
        IDittoPool pool = _idToPool[tokenId_];
        return pool.getNftCountForLpPositionId(tokenId_);
    }

    ///@inheritdoc ILpPosition
    function getLpPositionValueNft(uint256 tokenId_) external view returns (uint256) {
        IDittoPool pool = _idToPool[tokenId_];
        return this.getNumNftsHeld(tokenId_) * pool.spotPrice();
    }

    ///@inheritdoc ILpPosition
    function getLpPositionValue(uint256 tokenId_) external view returns (uint256) {
        return this.getLpPositionValueToken(tokenId_) + this.getLpPositionValueNft(tokenId_);
    }

    ///@inheritdoc ILpPosition
    function dittoPoolFactory() external view returns (address) {
        return _dittoPoolFactory;
    }

    ///@inheritdoc ILpPosition
    function nextId() external view returns (uint256) {
        return _nextId;
    }

    ///@inheritdoc ILpPosition
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // forgefmt: disable-start
    // ***************************************************************
    // * ============= Standard ERC721 Functions =================== *
    // ***************************************************************
    // forgefmt: disable-end

    /**
     * @notice returns the metadata for a given token, to be viewed on marketplaces and off-chain
     * @dev see [EIP-721](https://eips.ethereum.org/EIPS/eip-721) EIP-721 Metadata Extension
     * @param tokenId the tokenId of the NFT to get metadata for
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        IDittoPool pool = IDittoPool(_idToPool[tokenId]);
        uint256 tokenCount = getLpPositionValueToken(tokenId);
        uint256 nftCount = getNumNftsHeld(tokenId);
        return _metadataGenerator.payloadTokenUri(tokenId, pool, tokenCount, nftCount);
    }

    /**
     * @notice which API interfaces this contract supports. See [EIP-165](https://eips.ethereum.org/EIPS/eip-165)
     */
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x49064906 // ERC165 Interface ID for ERC4906
            || interfaceId == 0x5b5e139f;// ERC165 Interface ID for ERC721Metadata
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Upshot Technologies Inc. All Rights Reserved
pragma solidity 0.8.x;

import {AdminTwoStep} from "../../util/AdminTwoStep.sol";
import {IDittoPool} from "../../interface/IDittoPool.sol";

import {MetadataInfo} from "./MetadataInfo.sol";
import {Base64} from "./Base64.sol";
import {Strings} from "../../../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {IERC20Metadata} from "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC721Metadata} from "../../../../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 */
contract MetadataGenerator is AdminTwoStep {

    string[] public _assetDay;
    string[] public _assetNight;

    constructor() {
        _setAdmin(msg.sender);
    }

    function getAsset(uint256 index, bool day) external view returns (string memory asset){
        if(day){
            asset = _assetDay[index];
        } else {
            asset = _assetNight[index];
        }
    }

    function setAsset(string calldata asset, bool day) onlyAdmin external {
        if(day){
            _assetDay.push(asset);
        } else {
            _assetNight.push(asset);
        }
    }

    /**
     */
    function _getPseudoRandomNumber(uint256 max, uint256 tokenId, address pool, address token) private pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tokenId,
                        pool,
                        token
                    )
                )
            ) % max;
    }

    function _getComponent00(string memory bg, string memory alt, address addressPool) private pure returns (string memory) {
        string memory inputPool = string(abi.encodePacked('Pool: ', Strings.toHexString(uint256(uint160(addressPool)), 20)));
        string memory svg00 = string(abi.encodePacked(
            '<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 768 768"><defs><style>.gray{fill:#e5e5e5;}.strokes{stroke:#000;stroke-miterlimit:10;stroke-width:1.5px;}.bg{fill:',
            bg,
            ';}.alt{fill:',
            alt,
            ';}</style></defs><rect width="768" height="768" class="gray"/><g class="strokes"><rect class="bg" x="19.22" y="19.73" width="355.16" height="355.16" rx="40" ry="40"/><rect class="bg" x="19.22" y="394.11" width="355.16" height="355.16" rx="40" ry="40"/><path class="alt" d="m337.92,218.48c19.07-42.5,2.47-92.89-44.59-63.49-39.9,24.92-61.99-11.56-73.34-31.1-16.84-28.99-33.68-6.94-56.68,5.48-28.19,15.22-36.69-17.26-75.39-17.17-28.21.07-33.61,20.35-19.59,38.52,21.95,28.45,3.57,60.1-9.15,87.67-12.54,27.19-14.6,39.87-6.04,50.22,10.63,12.84,34.6,8.03,54.48-5.43,32.2-21.8,38.94-32.11,58.45-39.68,64.49-25.02,50.41,31.79,76.03,41.7,42.55,16.47,81.58-34.99,95.82-66.72Z"/><path class="gray" d="m116.47,221.75c1.36-2.28,2.35-5.13,2.97-8.57.62-3.44.93-7.58.93-12.43,0-4.31-.37-7.95-1.11-10.95-.74-2.99-1.79-5.44-3.16-7.35s-3.09-3.4-5.19-4.49c-2.1-1.09-4.6-1.84-7.5-2.26-2.9-.42-6.17-.63-9.83-.63h-15.31c1.83,17.69-6.13,35.8-14.14,52.79-.03.97-.06,1.94-.1,2.88h29.17c4.06,0,7.57-.28,10.54-.85,2.97-.57,5.49-1.5,7.57-2.78,2.08-1.29,3.8-3.07,5.16-5.34Zm-19.26-14.51c-.15,1.41-.38,2.57-.71,3.49-.32.92-.75,1.65-1.3,2.19s-1.2.9-1.97,1.08c-.77.17-1.6.26-2.49.26-.64,0-1.25-.01-1.82-.04-.57-.02-1.15-.06-1.74-.11-.09,0-.17-.02-.26-.03-.02-1.46-.04-3.12-.04-4.98v-11.69c0-1.73.01-3.5.04-5.31,0-.76.02-1.49.04-2.21.06,0,.12-.01.18-.01,1.16-.07,2.34-.11,3.53-.11,1.04,0,1.93.09,2.67.26.74.17,1.37.49,1.89.97.52.47.93,1.14,1.23,2,.3.87.53,2.03.71,3.49.17,1.46.26,3.25.26,5.38s-.07,3.97-.22,5.38Z"/><path class="gray" d="m151.15,218.14c-.05-2.3-.07-4.69-.07-7.16v-16.4c0-2.52.02-4.9.07-7.12.05-2.23.09-4.35.11-6.38.02-2.03.04-4.03.04-6.01h-23.68c.15,1.98.23,3.98.26,6.01.02,2.03.04,4.17.04,6.42v30.73c0,2.25-.01,4.4-.04,6.46s-.11,4.07-.26,6.05h23.68c.05-1.98.05-4,0-6.05-.05-2.05-.1-4.23-.15-6.53Z"/><path class="gray" d="m139.7,146.86c-3.76,0-6.53.88-8.31,2.63-1.78,1.76-2.67,4.24-2.67,7.46,0,3.27.89,5.76,2.67,7.5,1.78,1.73,4.55,2.6,8.31,2.6,3.56,0,6.21-.88,7.94-2.64,1.73-1.76,2.6-4.24,2.6-7.46,0-3.37-.87-5.89-2.6-7.57-1.73-1.68-4.38-2.52-7.94-2.52Z"/><path class="gray" d="m192.35,230.8c-.05-.79-.07-2-.07-3.64s-.04-3.59-.11-5.86c-.07-2.28-.11-4.81-.11-7.61s-.01-5.76-.04-8.91c-.02-2.85-.03-5.75-.04-8.7.68,0,1.34.01,2.04.02,2.65.02,5.33.09,8.05.19-.05-1.58-.09-3.36-.11-5.34-.02-1.98-.04-3.81-.04-5.49,0-1.83.01-3.7.04-5.6.02-1.9.06-3.5.11-4.79h-44.53c.1,1.29.15,2.88.15,4.79v11.17c0,1.98-.05,3.74-.15,5.27,3.49-.13,6.87-.2,10.16-.23,0,2.99-.03,5.91-.07,8.73-.05,3.14-.1,6.12-.15,8.94-.05,2.82-.07,5.36-.07,7.61s-.03,4.21-.07,5.86c-.05,1.66-.07,2.86-.07,3.6,1.19-.1,2.49-.17,3.9-.22,1.41-.05,2.89-.06,4.45-.04,1.56.02,2.96.04,4.19.04s2.68-.01,4.19-.04,3.01-.01,4.49.04c1.48.05,2.77.12,3.86.22Z"/><path class="gray" d="m243.38,230.8c-.05-.79-.07-2-.07-3.64s-.04-3.59-.11-5.86c-.07-2.28-.11-4.81-.11-7.61s-.01-5.76-.04-8.91c-.02-2.85-.03-5.75-.04-8.7.68,0,1.34.01,2.04.02,2.65.02,5.33.09,8.05.19-.05-1.58-.09-3.36-.11-5.34-.02-1.98-.04-3.81-.04-5.49,0-1.83.01-3.7.04-5.6.02-1.9.06-3.5.11-4.79h-44.53c.1,1.29.15,2.88.15,4.79v11.17c0,1.98-.05,3.74-.15,5.27,3.49-.13,6.87-.2,10.16-.23,0,2.99-.03,5.91-.07,8.73-.05,3.14-.1,6.12-.15,8.94-.05,2.82-.07,5.36-.07,7.61s-.03,4.21-.07,5.86c-.05,1.66-.07,2.86-.07,3.6,1.19-.1,2.49-.17,3.9-.22,1.41-.05,2.89-.06,4.45-.04,1.56.02,2.96.04,4.19.04s2.68-.01,4.19-.04,3.01-.01,4.49.04c1.48.05,2.77.12,3.86.22Z"/><path class="gray" d="m262.88,182.85c-1.58,2.13-2.75,4.74-3.49,7.83-.74,3.09-1.11,6.69-1.11,10.8,0,4.45.33,8.3,1,11.54.67,3.24,1.74,6.05,3.23,8.42s3.38,4.33,5.68,5.86c2.3,1.53,5.06,2.65,8.28,3.34,3.22.69,6.95,1.04,11.21,1.04s8.05-.35,11.25-1.04c3.19-.69,5.97-1.81,8.35-3.34,2.37-1.53,4.33-3.49,5.86-5.86,1.53-2.38,2.67-5.18,3.42-8.42.74-3.24,1.11-7.09,1.11-11.54,0-5.24-.62-9.61-1.86-13.1-1.24-3.49-3.12-6.3-5.64-8.42-2.52-2.13-5.67-3.64-9.43-4.53-3.76-.89-8.09-1.34-12.99-1.34-4.06,0-7.65.27-10.76.82-3.12.54-5.85,1.47-8.2,2.78-2.35,1.31-4.32,3.03-5.9,5.16Zm27.54,7.5c.79.3,1.45.9,1.97,1.82.52.92.9,2.15,1.15,3.71.25,1.56.37,3.45.37,5.68,0,2.43-.12,4.47-.37,6.12-.25,1.66-.63,2.98-1.15,3.97-.52.99-1.16,1.7-1.93,2.12-.77.42-1.67.63-2.71.63-1.09,0-2.03-.21-2.82-.63-.79-.42-1.44-1.11-1.93-2.08-.49-.97-.87-2.28-1.11-3.93-.25-1.66-.37-3.72-.37-6.2,0-2.27.14-4.18.41-5.71.27-1.53.64-2.76,1.11-3.67.47-.92,1.1-1.52,1.89-1.82.79-.3,1.73-.45,2.82-.45.99,0,1.88.15,2.67.45Z"/><path class="gray" d="m326.28,212.54c-1.68,1.73-2.52,4.38-2.52,7.94,0,3.76.88,6.53,2.63,8.31,1.28,1.3,2.94,2.11,4.99,2.47,2.54-4.46,4.74-8.78,6.54-12.78.98-2.18,1.86-4.38,2.65-6.58-1.69-1.3-3.93-1.95-6.71-1.95-3.37,0-5.89.87-7.57,2.6Z"/></g><path fill="transparent" id="rect-path-0" d="m39.39,166.08v-101.2c0-13.81,11.19-25,25-25h264.84c13.81,0,25,11.19,25,25v101.2"/><text font-family="monospace" font-size="1em" class="gray"><textPath xlink:href="#rect-path-0" dominant-baseline="text-after-edge" startOffset="50%" text-anchor="middle">',
            inputPool
        ));
        return svg00;
    }

    function _getComponent01(address addressAdmin, string memory curve, uint256 normalDelta) private pure returns (string memory) {
        string memory inputAdmin = string(abi.encodePacked('Admin: ', Strings.toHexString(uint256(uint160(addressAdmin)), 20)));
        string memory delta = string(abi.encodePacked('Delta: ', Strings.toString(normalDelta)));
        string memory svg01 = string(abi.encodePacked(
            '</textPath></text><path fill="transparent" id="rect-path" d="m39.39,226.05v101.2c0,13.81,11.19,25,25,25h264.84c13.81,0,25-11.19,25-25v-101.2"/><text font-family="monospace" font-size="1em" class="gray"><textPath xlink:href="#rect-path" dominant-baseline="hanging" startOffset="50%" text-anchor="middle">',
            inputAdmin,
            '</textPath></text><g transform="translate(-60,0)"><path d="m114.98,507.47h-26.84v-26.91h26.84v26.91Zm-25.55-1.3h24.25v-24.31h-24.25v24.31Z" class="gray"/><path d="m114.27,481.15c0,5.71,0,18.74-13.36,23.6-1.75.65-3.7,1.1-5.97,1.43-1.88.26-3.96.39-6.22.39v.13h25.61l-.06-25.55h0Z" class="gray"/><text transform="translate(126.2 500.58)" font-family="monospace" class="gray" font-size="1.75em">',
            curve,
            '</text><polygon points="114.33 538.4 88.79 538.4 101.56 512.85 114.33 538.4" class="gray"/><text transform="translate(126.18 532.21)" font-family="monospace" class="gray" font-size="1.75em">',
            delta
        ));
        return svg01;
    }

    /**
     * TODO: truncate counts, 1,000 => 1k, 1,000,000 => 1m, etc...
     */
    function _getComponent02(uint256 normalFee,
                            string memory symbolTokenRaw,
                            string memory symbolNftRaw,
                            uint256 nftCount,
                            uint256 normalToken,
                            uint256 pseudoRandomNumber0,
                            uint256 pseudoRandomNumber1) private view returns (string memory) {

        //TODO: needs to be cumulative fee, inclusive of protocol fee, etc...
        //need more uni tests!
        string memory fee = string(abi.encodePacked('Fee: ', Strings.toString(normalFee), '%'));
    
        string memory nftSymbol;
        if(bytes(symbolNftRaw).length > 13){
            nftSymbol = _substring(symbolNftRaw, 0, 13);
        } else {
            nftSymbol = symbolNftRaw;
        }
        string memory symbolValueNft = string(abi.encodePacked(nftSymbol, ': ', Strings.toString(nftCount)));
        //TODO: truncate symbolTokenRaw if it's too long
        string memory symbolValueToken = string(abi.encodePacked(symbolTokenRaw, ': ', Strings.toString(normalToken)));

        string memory svg02 = string(abi.encodePacked(
            '</text><ellipse class="gray" cx="101.56" cy="549.7" rx="13.42" ry="3.81"/><path class="gray" d="m88.14,553.1v15.83c0,2.1,6.01,3.81,13.42,3.81s13.42-1.71,13.42-3.81v-15.83c-2.78,2.14-9.21,2.78-13.42,2.78s-10.64-.64-13.42-2.78Z"/><text transform="translate(126.88 563.83)" font-family="monospace" class="gray" font-size="1.75em">',
            fee,
            '</text><rect x="88.79" y="603.76" width="25.61" height="25.61" class="gray"/><text transform="translate(126.18 623.14)" font-family="monospace" class="gray" font-size="1.75em">',
            symbolValueNft,
            '</text><path d="m101.56,637.28h0c7.07,0,12.77,5.71,12.77,12.77h0c0,7.07-5.71,12.77-12.77,12.77h0c-7.07,0-12.77-5.71-12.77-12.77h0c0-7.07,5.71-12.77,12.77-12.77Z" class="gray"/><text transform="translate(126.18 655.52)" font-family="monospace" class="gray" font-size="1.75em">',
            symbolValueToken,
            '</text></g><image width="100%" height="100%" xlink:href="data:image/svg+xml;base64,',
            pseudoRandomNumber0 == 0 ? _assetNight[pseudoRandomNumber1] : _assetDay[pseudoRandomNumber1],
            '"/></svg>'));
        return svg02;
    }

    /**
     */
    function _substring(string memory str, uint startIndex, uint endIndex) private pure returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function payloadTokenUri(uint256 tokenId, IDittoPool pool, uint256 tokenCount, uint256 nftCount) view external returns (string memory) {
        string memory description = 'Upshot Swap is an NFT AMM that allows for autonomously providing liquidity and trading NFTs completely on-chain, without an off-chain orderbook. '
                                    'Liquidity providers deposit NFTs into Upshot Swap pools and are given NFT LP tokens to track their ownership of that liquidity. '
                                    'These NFT LP tokens represent liquidity in the AMM. '
                                    'When withdrawing liquidity, liquidity providers burn their NFT LP token(s) and are sent back the corresponding liquidity from the pool.'; 

        address addressPool = address(pool);
        address addressAdmin = pool.admin();
        address addressNft = address(pool.nft());

        uint256 decimals;
        try IERC20Metadata(pool.token()).decimals() returns (uint8 decimals_){
            decimals = uint256(decimals_);
        } catch {
            decimals = 18;
        }

        MetadataInfo memory info = MetadataInfo(
            pool.bondingCurve(), 
            addressPool, 
            addressAdmin, 
            tokenCount/(10**decimals), 
            pool.delta()/(10**decimals), 
            pool.fee()/(10**decimals),
            nftCount,
            IERC20Metadata(address(pool.token())).symbol(), 
            IERC721Metadata(addressNft).symbol(),
            addressNft,
            tokenId
            );

        return
            string(abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(bytes(abi.encodePacked(
                        '{"name":"',
                            string(abi.encodePacked('Upshot Swap #', Strings.toString(tokenId))),
                        '", "description":"',
                            description,
                        '", "image": "',
                            'data:image/svg+xml;base64,',
                            Base64.encode(bytes(generateImage(info))),
                        '"}'
                    )))
            ));
    }

    /**

     */
    function generateImage(MetadataInfo memory info) view internal returns (string memory) {

        ///@dev Get a number, if it's even, it's day, if it's odd, it's night
        bool day;
        string memory bg;
        string memory alt;
        uint256 pseudoRandomNumber0 = _getPseudoRandomNumber(2, info.tokenId, info.addressPool, info.addressNft);
        uint256 pseudoRandomNumber1 = _getPseudoRandomNumber(5, info.tokenId, info.addressPool, info.addressNft);

        if(pseudoRandomNumber0 == 0){
            day = true;
            bg = "#00A0FF";
            alt = "#FFC600";
        } else {
            day = false;
            bg = "#20F";
            alt = "#FF583E";
        }

        string memory svg = string(abi.encodePacked(
            _getComponent00(bg, alt, info.addressPool),
            _getComponent01(info.addressAdmin, info.curve, info.normalDelta),   
            _getComponent02(info.normalFee, info.symbolToken, info.symbolNft, info.nftCount, info.normalToken, pseudoRandomNumber0, pseudoRandomNumber1)
        ));
        return svg;
    }


}

// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Upshot Technologies Inc. All Rights Reserved
pragma solidity 0.8.x;

struct MetadataInfo {
    string curve; 
    address addressPool;
    address addressAdmin;
    uint256 normalToken; 
    uint256 normalDelta; 
    uint256 normalFee;
    uint256 nftCount;
    string symbolToken; 
    string symbolNft;
    address addressNft;
    uint256 tokenId;
}

// SPDX-License-Identifier: AGPL-3.0
// Copyright (c) 2023 Upshot Technologies Inc. All Rights Reserved
pragma solidity ^0.8.0;

import {IAdminTwoStep} from "../interface/IAdminTwoStep.sol";

abstract contract AdminTwoStep is IAdminTwoStep {
    address public admin;
    address public pendingAdmin;

    function _setAdmin(address initialAdmin) internal {
        admin = initialAdmin;
    }

    /*****************************************************
     * =============== User Interface ================== *
     *****************************************************/
    function transferAdmin(address newAdmin) public virtual onlyAdmin {
        pendingAdmin = newAdmin;
    }

    function claimAdmin() public virtual onlyPendingAdmin {
        emit AdminTransferred(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    /*****************************************************
     * ================== Modifiers ==================== *
     *****************************************************/
    modifier onlyAdmin() {
        _requireOnlyAdmin();
        _;
    }

    modifier onlyPendingAdmin() {
        _requireOnlyPendingAdmin();
        _;
    }

    /*****************************************************
     * ==================== Auth ======================= *
     *****************************************************/
    // NOTE: These functions are broken out to minimize contract size.
    //   Internal calls require only jump statements,
    //   but require strings take a minimum of 32 bytes per string.
    //   modifiers copy their whole bytecode into the modified function.
    function _requireAuthorized(bool authorized) internal pure {
        require(authorized, "AdminTwoStep: invalid msg.sender");
    }

    function _requireOnlyAdmin() internal view {
        _requireAuthorized(msg.sender == admin);
    }

    function _requireOnlyPendingAdmin() internal view {
        _requireAuthorized(msg.sender == pendingAdmin);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

enum CurveErrorCode {
    OK, // No error
    INVALID_NUMITEMS, // The numItem value is 0
    SPOT_PRICE_OVERFLOW // The updated spot price doesn't fit into 128 bits
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}