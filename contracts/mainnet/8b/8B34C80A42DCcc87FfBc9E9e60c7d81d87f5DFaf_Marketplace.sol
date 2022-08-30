// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import {Minter} from "./launchpad/Minter.sol";
import {Playground} from "./launchpad/Playground.sol";
import {Rewarder} from "./launchpad/Rewarder.sol";
import {BetNFTItem, BetNFTState} from "./utils/BetStructs.sol";

/**
 * @title Marketplace contract
 * @notice BetNFT marketplace
 */
contract Marketplace is Minter, Playground, Rewarder {
    constructor() {}

    /**
     * @notice Get state information of a BetNFT
     * @param tokenId NFT tokenId
     * @return item NFT item info
     * @return state NFT state info
     */
    function betNFT(uint256 tokenId)
        external
        view
        returns (BetNFTItem memory, BetNFTState memory)
    {
        return (_BET_NFT.getItem(tokenId), _BET_NFT.getState(tokenId));
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import {IMinter} from "../interfaces/IMinter.sol";
import {LaunchBase} from "./LaunchBase.sol";
import {StateValidator} from "../helpers/StateValidator.sol";
import {TransferHelper} from "../helpers/TransferHelper.sol";
import {BetNFTItem, BetNFTState, JackpotTransferer} from "../utils/BetStructs.sol";
import {EnumRewardPhase, EnumItemStatus, EnumActionType} from "../utils/BetEnums.sol";
import "../utils/BetConstants.sol";
import "../utils/BetErrors.sol";

/**
 * @title Minter contract
 * @notice Mint a BetNFT
 */
contract Minter is StateValidator, IMinter, LaunchBase, TransferHelper {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Stake ERC20 tokens, mint BetNFT and transfer BetNFT ownership
     * @param tokenId NFT tokenId
     * @param matchKey assertIdx(2)+marketId(4)+period(2)+sportType(2)+matchId(6)
     * @param ticker ERC20 token symbol
     * @param price NFT mint price
     * @param faceValue NFT face value
     * @param punter punter's address
     * @param tokenURI NFT tokenURI
     * @param assertKey assertKey
     */
    function createBetNFT(
        uint256 tokenId,
        uint256 matchKey,
        bytes32 ticker,
        uint256 price,
        uint256 faceValue,
        address punter,
        string memory tokenURI,
        string memory assertKey
    ) external override onlyRole(INVOKER_ROLE) {
        require(!_BET_NFT.exists(tokenId), "BetNFT already exists");
        validateMatchKey(matchKey);

        if (faceValue <= price) {
            revert FaceValueInvalid(price, faceValue);
        }

        JackpotTransferer memory ownerTransferer = JackpotTransferer(
            tokenId,
            _VALID_TOKENS[ticker],
            punter,
            address(_JACKPOT),
            price
        );
        validateJackpotTransferer(ownerTransferer);
        JackpotTransferer memory bookmakerTransferer = JackpotTransferer(
            tokenId,
            _VALID_TOKENS[ticker],
            _BOOKMAKER,
            address(_JACKPOT),
            faceValue - price
        );
        validateJackpotTransferer(bookmakerTransferer);

        _JACKPOT.bet(ownerTransferer, bookmakerTransferer);

        BetNFTItem memory item = BetNFTItem(
            tokenId,
            matchKey,
            price,
            faceValue,
            0,
            ticker,
            EnumRewardPhase.PENDING,
            msg.sender,
            _BOOKMAKER,
            address(_JACKPOT),
            tokenURI,
            assertKey,
            1
        );

        BetNFTState memory state = BetNFTState(
            tokenId,
            price,
            ticker,
            punter, //owner
            address(0),
            0,
            EnumItemStatus.MINTED,
            EnumActionType.MINT
        );
        _BET_NFT.mint(item, state);
    }

    /**
     * @notice Unlisting BetNFTs
     * @param tokenIds BetNFT tokenIds
     * @return result whether unlisting BetNFTs successfully
     */
    function unlistBetNFTs(uint256[] memory tokenIds)
        external
        override
        onlyRole(INVOKER_ROLE)
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            BetNFTState memory state = _BET_NFT.getState(tokenId);
            state.expires = 0;
            state.actionType = EnumActionType.UNLIST;
            _BET_NFT.update(state);
        }
        return true;
    }

    /**
     * @notice Buyback unreward BetNFT from bookmaker with a specified value
     * @param tokenIds BetNFT tokenIds
     * @return result whether buyback BetNFTs successfully
     */
    function buybackBetNFTs(uint256[] memory tokenIds)
        external
        override
        onlyRole(INVOKER_ROLE)
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            BetNFTItem memory item = _BET_NFT.getItem(tokenId);
            BetNFTState memory state = _BET_NFT.getState(tokenId);
            if (tokenId == 0) {
                revert NFTNotExisted(tokenId);
            }
            if (item.rewardPhase != EnumRewardPhase.LOST) {
                revert NFTRewardPhaseInvalid(tokenId);
            }

            state.actionType = EnumActionType.BUYBACK;
            uint256 buybackPrice = item.mintValue / _BUYBACK_VALUE_FACTOR;
            if (validateBetNFTState(state)) {
                state.price = buybackPrice;
                _BET_NFT.update(state);
            }

            transferERC20From(
                _VALID_TOKENS[state.ticker],
                item.bookmaker,
                state.owner,
                buybackPrice
            );
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import {LaunchBase} from "./LaunchBase.sol";
import {IPlayground} from "../interfaces/IPlayground.sol";
import {IJackpot} from "../interfaces/IJackpot.sol";
import {BetNFTItem, BetNFTState, JackpotTransferer} from "../utils/BetStructs.sol";
import {EnumRewardPhase, EnumItemStatus, EnumActionType} from "../utils/BetEnums.sol";
import {TransferHelper} from "../helpers/TransferHelper.sol";
import {StateValidator} from "../helpers/StateValidator.sol";
import "../utils/BetErrors.sol";

/**
 * @title Playground contract
 * @notice BetNFT marketplace
 */
contract Playground is IPlayground, StateValidator, LaunchBase, TransferHelper {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Listing BetNFT for sale
     * @param tokenId NFT tokenId
     * @param price NFT price
     * @param expires NFT listing expires
     * @return result whether listing BetNFT successfully
     */
    function listBetNFT(
        uint256 tokenId,
        uint256 price,
        uint256 expires
    ) external override returns (bool) {
        BetNFTState memory state = _BET_NFT.getState(tokenId);
        if (msg.sender != state.owner && msg.sender != state.seller) {
            revert NFTSellerOnly();
        }
        state.price = price;
        state.expires = expires;
        if (state.owner == msg.sender) {
            state.actionType = EnumActionType.LIST;
        } else {
            state.actionType = EnumActionType.UPDATE;
        }
        if (validateBetNFTState(state)) {
            _BET_NFT.update(state);
        }
        return true;
    }

    /**
     * @notice Unlisting BetNFT for edit or collecting
     * @param tokenId BetNFT tokenId
     * @return result whether unlisting BetNFT successfully
     */
    function unlistBetNFT(uint256 tokenId) external override returns (bool) {
        BetNFTState memory state = _BET_NFT.getState(tokenId);
        if (msg.sender != state.owner && msg.sender != state.seller) {
            revert NFTSellerOnly();
        }
        state.expires = 0;
        state.actionType = EnumActionType.UNLIST;
        if (validateBetNFTState(state)) {
            _BET_NFT.update(state);
        }
        return true;
    }

    /**
     * @notice Complete BetNFT trade between seller and buyer
     * @param tokenId BetNFT tokenId
     * @return result whether trade BetNFT successfully
     */
    function tradeBetNFT(uint256 tokenId) external override returns (bool) {
        BetNFTState memory state = _BET_NFT.getState(tokenId);
        state.owner = msg.sender;
        state.actionType = EnumActionType.SALE;

        address seller = state.seller;
        if (validateBetNFTState(state)) {
            state.expires = 0;
            _BET_NFT.update(state);
        }

        transferERC20From(
            _VALID_TOKENS[state.ticker],
            msg.sender,
            seller,
            state.price
        );
        return true;
    }

    /**
     * @notice Withdraw reward and burn the BetNFT
     * @param tokenId BetNFT tokenId
     * @param matchKey matchKey to be checked
     * @return result whether clearing and burn BetNFT successfully
     */
    function claimBetNFT(uint256 tokenId, uint256 matchKey)
        external
        override
        nonReentrant
        returns (bool)
    {
        BetNFTItem memory item = _BET_NFT.getItem(tokenId);
        BetNFTState memory state = _BET_NFT.getState(tokenId);

        if (matchKey != item.matchKey) {
            revert MatchKeyInvalid(matchKey);
        }
        if (msg.sender != state.owner) {
            revert NFTOwnerOnly();
        }
        if (
            item.rewardPhase != EnumRewardPhase.REFUNDED &&
            item.rewardPhase != EnumRewardPhase.WIN &&
            item.rewardPhase != EnumRewardPhase.ERROR
        ) {
            revert NFTRewardPhaseInvalid(tokenId);
        }

        state.actionType = EnumActionType.CLAIM;
        if (validateBetNFTState(state)) {
            state.price = item.reward;
            _BET_NFT.update(state);
        }

        JackpotTransferer memory transferer = JackpotTransferer(
            item.tokenId,
            _VALID_TOKENS[item.ticker],
            item.jackpot,
            msg.sender,
            item.reward
        );
        validateJackpotTransferer(transferer);
        IJackpot(item.jackpot).redeem(transferer);
        return true;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import {LaunchBase} from "./LaunchBase.sol";
import {BetCalculator} from "../calculator/BetCalculator.sol";
import {IRewarder} from "../interfaces/IRewarder.sol";
import {IJackpot} from "../interfaces/IJackpot.sol";
import {BetNFTItem, BetNFTState, JackpotTransferer} from "../utils/BetStructs.sol";
import {EnumRewardPhase, EnumItemStatus, EnumActionType} from "../utils/BetEnums.sol";
import {StateValidator} from "../helpers/StateValidator.sol";
import "../utils/BetConstants.sol";
import "../utils/BetErrors.sol";

/**
 * @title Rewarder contract
 * @notice Fetch match result and calculate rewards
 */
contract Rewarder is IRewarder, StateValidator, BetCalculator, LaunchBase {
    mapping(uint256 => int256[]) public matchResult;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Calculate BetNFT reward, bookmaker withdraws stakes
     * @param tokenId BetNFT tokenId
     * @return whether calculate reward successfully
     */
    function calculateReward(uint256 tokenId)
        external
        override
        onlyRole(INVOKER_ROLE)
        returns (bool)
    {
        BetNFTItem memory item = _BET_NFT.getItem(tokenId);

        EnumRewardPhase rewardPhase = item.rewardPhase;
        uint256 matchKey = item.matchKey;
        (, string[] memory rules) = validateMatchKey(matchKey);

        if (rewardPhase > EnumRewardPhase.PENDING) {
            revert NFTRewardAlreadyCalculated(tokenId, item.faceValue);
        }
        uint256 reward = item.reward;
        if (matchResult[matchKey].length == 0) {
            matchResult[matchKey] = _ORACLE_CONSUMER.checkMatchResult(matchKey);
        }
        if (matchResult[matchKey].length > 0) {
            // match has been cancelled
            if (matchResult[matchKey][0] < 0) {
                rewardPhase = EnumRewardPhase.REFUNDED;
                reward = item.mintValue;
            } else {
                bool success;
                (success, reward) = getUnfixedBettingReward(
                    matchResult[matchKey],
                    item.assertKey,
                    rules
                );

                if (success) {
                    if (item.faceValue < reward) {
                        revert RewardInvalid(tokenId, reward, item.faceValue);
                    }
                    rewardPhase = reward > 0
                        ? EnumRewardPhase.WIN
                        : EnumRewardPhase.LOST;
                } else {
                    rewardPhase = EnumRewardPhase.ERROR;
                    reward = item.faceValue;
                }
            }
            item.reward = reward;
            item.rewardPhase = rewardPhase;
            _BET_NFT.calculate(item);

            if (
                rewardPhase > EnumRewardPhase.PENDING && item.faceValue > reward
            ) {
                JackpotTransferer memory transferer = JackpotTransferer(
                    item.tokenId,
                    _VALID_TOKENS[item.ticker],
                    item.jackpot,
                    item.bookmaker,
                    item.faceValue - reward
                );
                validateJackpotTransferer(transferer);
                IJackpot(item.jackpot).redeem(transferer);
            }
        }
        return true;
    }

    /**
     * @notice Request match result from oracle
     * @param matchKey unique key for the match result
     * @param enforce enforce an oracle request
     */
    function requestMatchResult(uint256 matchKey, bool enforce)
        external
        override
        onlyRole(INVOKER_ROLE)
    {
        _ORACLE_CONSUMER.requestMatchResult(matchKey, enforce);
    }

    /**
     * @notice Get match result from oracle
     * @param matchKey unique key for the match result
     */
    function checkMatchResult(uint256 matchKey)
        external
        override
        onlyRole(INVOKER_ROLE)
    {
        matchResult[matchKey] = _ORACLE_CONSUMER.checkMatchResult(matchKey);
    }

    /**
     * @notice Get match result of a given match
     * @param matchKey unique key for the match result
     * @return result match result in array format
     */
    function fetchMatchResult(uint256 matchKey)
        external
        view
        override
        returns (int256[] memory)
    {
        return matchResult[matchKey];
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import {EnumRewardPhase, EnumItemStatus, EnumActionType} from "./BetEnums.sol";

struct BetNFTItem {
    uint256 tokenId;
    uint256 matchKey; 
    uint256 mintValue;
    uint256 faceValue;
    uint256 reward;
    bytes32 ticker;
    EnumRewardPhase rewardPhase;
    address minter;
    address bookmaker;
    address jackpot;
    string tokenURI;
    string assertKey;
    uint8 version;
}

struct BetNFTState {
    uint256 tokenId;
    uint256 price;
    bytes32 ticker;
    address owner;
    address seller;
    uint256 expires;
    EnumItemStatus itemStatus;
    EnumActionType actionType;
}

struct JackpotTransferer {
    uint256 tokenId;
    address tokenAddress; //payment token
    address from;
    address to;
    uint256 amount;
}

struct JackpotDistributer {
    uint256 tokenId;
    address tokenAddress; //payment token
    address jackpot;
    address owner;
    address seller;
    address bookmaker;
    uint256 mintValue;
    uint256 faceValue;
    uint256 reward;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

interface IMinter {
    /**
     * @notice Stake ERC20 tokens, mint BetNFT and transfer BetNFT ownership
     * @param tokenId NFT tokenId
     * @param matchKey assertIdx(2)+marketId(4)+period(2)+sportType(2)+matchId(6)
     * @param ticker ERC20 token symbol
     * @param price NFT mint price
     * @param faceValue NFT face value
     * @param punter punter's address
     * @param tokenURI NFT tokenURI
     * @param assertKey assertKey
     */
    function createBetNFT(
        uint256 tokenId,
        uint256 matchKey,
        bytes32 ticker,
        uint256 price,
        uint256 faceValue,
        address punter,
        string memory tokenURI,
        string memory assertKey
    ) external;

    /**
     * @notice Unlisting BetNFTs
     * @param tokenIds BetNFT tokenIds
     * @return result whether unlisting BetNFTs successfully
     */
    function unlistBetNFTs(uint256[] memory tokenIds) external returns (bool);

    /**
     * @notice Buyback unreward BetNFT from bookmaker with a specified value
     * @param tokenIds BetNFT tokenIds
     * @return result whether buyback BetNFTs successfully
     */
    function buybackBetNFTs(uint256[] memory tokenIds) external returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IBetNFT} from "../interfaces/IBetNFT.sol";
import {IJackpot} from "../interfaces/IJackpot.sol";
import {IOracleConsumer} from "../interfaces/IOracleConsumer.sol";

/**
 * @title Lauchbase contract
 * @notice Setup contract relationships
 */
contract LaunchBase is AccessControl, ReentrancyGuard {
    IBetNFT public _BET_NFT;
    IJackpot public _JACKPOT;
    IOracleConsumer public _ORACLE_CONSUMER;
    address public _BOOKMAKER;
    uint256 public _BUYBACK_VALUE_FACTOR;
    mapping(bytes32 => address) public _VALID_TOKENS;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setupLaunchpad(
        address betNFT,
        address jackpot,
        address oracleConsumer
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _BET_NFT = IBetNFT(betNFT);
        _JACKPOT = IJackpot(jackpot);
        _ORACLE_CONSUMER = IOracleConsumer(oracleConsumer);
    }

    function setupBetNFT(address betNFT) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _BET_NFT = IBetNFT(betNFT);
    }

    function setupJackpot(address jackpot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _JACKPOT = IJackpot(jackpot);
    }

    function setupOracleConsumer(address oracleConsumer)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _ORACLE_CONSUMER = IOracleConsumer(oracleConsumer);
    }

    function setupBuybackValueFactor(uint256 buybackValueFactor)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _BUYBACK_VALUE_FACTOR = buybackValueFactor;
    }

    function addBookmaker(address bookmakerAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _BOOKMAKER = bookmakerAddress;
    }

    /**
     * @notice Add an ERC20 token that supports payment on NFTs
     * @param ticker ERC20 token symbol
     * @param tokenAddress ERC20 token contract address
     */
    function addToken(bytes32 ticker, address tokenAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _VALID_TOKENS[ticker] = tokenAddress;
    }

    /**
     * @notice Remove an ERC20 token that supports payment on NFTs
     * @param ticker ERC20 token symbol
     */
    function removeToken(bytes32 ticker) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _VALID_TOKENS[ticker];
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import {BetNFTState, JackpotTransferer} from "../utils/BetStructs.sol";
import {EnumActionType, EnumItemStatus} from "../utils/BetEnums.sol";
import {AssertRules} from "./AssertRules.sol";
import {Decoder} from "../utils/Decoder.sol";
import "../utils/BetConstants.sol";
import "../utils/BetErrors.sol";

contract StateValidator is AssertRules {
    using Decoder for uint256;

    function validateBetNFTState(BetNFTState memory state)
        internal
        view
        returns (bool)
    {
        uint256 tokenId = state.tokenId;
        if (tokenId == 0) {
            revert NFTNotExisted(tokenId);
        }

        EnumActionType actionType = state.actionType;
        uint256 price = state.price;
        uint256 expires = state.expires;
        if (
            actionType == EnumActionType.LIST ||
            actionType == EnumActionType.UPDATE
        ) {
            if (price < MINIMUM_BET_USDC || price > MAXMUM_BET_USDC) {
                revert AmountInvalid(state.owner, price);
            }
            if (
                (expires <= block.timestamp * 1000) ||
                (expires > (block.timestamp + MAXMUM_EXPIRE_SPAN) * 1000)
            ) {
                revert NFTListingExpireInvalid(tokenId, expires);
            }
        } else if (actionType == EnumActionType.SALE) {
            if (price < MINIMUM_BET_USDC || price > MAXMUM_BET_USDC) {
                revert AmountInvalid(state.owner, price);
            }
            if (state.itemStatus != EnumItemStatus.LISTED) {
                revert NFTNotListed(tokenId);
            }
            if (expires <= block.timestamp * 1000) {
                revert NFTListingExpired(tokenId, expires);
            }
        } else if (actionType == EnumActionType.UNLIST) {
            if (state.itemStatus != EnumItemStatus.LISTED) {
                revert NFTNotListed(tokenId);
            }
        } else if (
            actionType == EnumActionType.BUYBACK ||
            actionType == EnumActionType.CLAIM
        ) {
            if (price < MINIMUM_BET_USDC || price > MAXMUM_BET_USDC) {
                revert AmountInvalid(state.owner, price);
            }
            if (state.itemStatus == EnumItemStatus.LISTED) {
                revert NFTNotUnlisted(tokenId);
            }
        }
        return true;
    }

    function validateJackpotTransferer(JackpotTransferer memory transferer)
        internal
        pure
        returns (bool)
    {
        address tokenAddress = transferer.tokenAddress;
        address from = transferer.from;
        address to = transferer.to;
        uint256 amount = transferer.amount;

        if (to == address(0)) {
            revert AccountInvalid(to);
        }
        if (tokenAddress == address(0)) {
            revert PaymentTokenInvalid();
        }
        if (amount < MINIMUM_BET_USDC || amount > MAXMUM_BET_USDC) {
            revert AmountInvalid(from, amount);
        }
        return true;
    }

    function validateMatchKey(uint256 matchKey)
        internal
        view
        returns (uint256 assertIdx, string[] memory rules)
    {
        (assertIdx, ) = matchKey.decode(DIGITS_ASSERT_IDX_MASK);
        rules = getRule(assertIdx);
        if (rules.length == 0) {
            revert MatchKeyInvalid(matchKey);
        }
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../utils/BetErrors.sol";

/**
 * @title ERC20 Transfer Helper contract
 * @notice Proceed ERC20 token transactions
 */
contract TransferHelper {
    /**
     * @param tokenAddress  The ERC20 token to transfer.
     * @param from  The originator of the transfer.
     * @param to The recipient of the transfer.
     * @param amount The amount to transfer.
     */
    function transferERC20From(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        if (tokenAddress == address(0)) {
            revert PaymentTokenInvalid();
        }
        uint256 balance = IERC20(tokenAddress).balanceOf(from);
        if (balance < amount) {
            revert BalanceInsufficient(from, balance, amount);
        }
        IERC20(tokenAddress).transferFrom(from, to, amount);
        return true;
    }

    /**
     * @param tokenAddress  The ERC20 token to transfer.
     * @param to The recipient of the transfer.
     * @param amount The amount to transfer.
     */
    function transferERC20(
        address tokenAddress,
        address to,
        uint256 amount
    ) public returns (bool) {
        if (tokenAddress == address(0)) {
            revert PaymentTokenInvalid();
        }
        IERC20(tokenAddress).transfer(to, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

enum EnumRewardPhase {
    NON,
    PENDING,
    REFUNDED,
    WIN,
    LOST,
    ERROR
}

enum EnumItemStatus {
    NON,
    MINTED,
    UNLISTED,
    LISTED,
    FREEZED
}

enum EnumActionType {
    NON,
    MINT,
    LIST,
    UNLIST,
    UPDATE,
    TRANSFER,
    SALE,
    CLAIM,
    BUYBACK,
    BURN
}

enum EnumOracleCode {
    NON,
    SUCCESS,
    RESULT_NOT_FOUND,
    MATCH_CANCELED,
    MATCH_NOT_FOUND,
    ERROR
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

uint256 constant MINIMUM_BET_USDC = 1000;
uint256 constant MAXMUM_BET_USDC = 1000000 * 10**6;
uint256 constant MINIMUM_EXPIRE_SPAN = 30 seconds;
uint256 constant MAXMUM_EXPIRE_SPAN = 30 days;

uint256 constant MATCH_RESULT_UNIT_LENGTH = 5;
uint256 constant DIGITS_ORACLE_CODE = 10**2;
uint256 constant DIGITS_MATCH_RESULT = 10**5;
uint256 constant DIGITS_ASSERT_IDX_MASK = 10**14;

bytes32 constant CONTRACTOR_ROLE = keccak256("CONTRACTOR_ROLE");
bytes32 constant INVOKER_ROLE = keccak256("INVOKER_ROLE");

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

error NFTNotExisted(uint256 tokenId);
error NFTNotListed(uint256 tokenId);
error NFTNotUnlisted(uint256 tokenId);
error NFTListingExpired(uint256 tokenId, uint256 expires);
error NFTListingExpireInvalid(uint256 tokenId, uint256 expires);
error NFTSellerOnly();
error NFTSupervisorOnly();
error NFTOwnerOnly();
error NFTRewardPhaseInvalid(uint256 tokenId);

error NFTRewardAlreadyCalculated(uint256 tokenId, uint256 faceValue);
error NFTRewardNotCalculated(uint256 tokenId, uint256 matchKey);

error JackpotAddressError(address jackpot, address correctJackpot);
error JackpotBalanceError(address jackpot, uint256 amount, uint256 balance);
error AccountInvalid(address account);
error AmountInvalid(address account, uint256 amount);
error FaceValueInvalid(uint256 amount, uint256 faceValue);
error RewardInvalid(uint256 tokenId, uint256 reward, uint256 faceValue);
error PaymentTokenInvalid();

error BalanceInsufficient(address account, uint256 balance, uint256 required);

error MatchKeyInvalid(uint256 matchKey);
error MatchResultNotFound(uint256 matchKey);
error MatchResultAlreadyExisted(uint256 matchKey);

error OracleMatchNotFound(uint256 oracleResult);
error OracleResultNotFound(uint256 oracleResult);
error OracleResultInalid(uint256 oracleResult);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import {BetNFTItem, BetNFTState} from "../utils/BetStructs.sol";
import {EnumRewardPhase, EnumItemStatus, EnumActionType} from "../utils/BetEnums.sol";

interface IBetNFT {
    /**
     * @notice Mint NFT
     * @param item NFT item
     * @param state NFT state
     * @return result whether mint successfully
     */
    function mint(BetNFTItem calldata item, BetNFTState calldata state)
        external
        returns (bool);

    /**
     * @notice Update NFT states
     * @param state NFT state
     * @return result whether NFT state updated successfully
     */
    function update(BetNFTState memory state) external returns (bool);

    /**
     * @notice Update NFT item according to the calculated reward
     * @param item NFT item
     * @return result whether NFT item updated successfully
     */
    function calculate(BetNFTItem memory item) external returns (bool);

    /**
     * @notice Get the NFT state
     * @param tokenId BetNFT token Id
     * @return state NFT state
     */
    function getState(uint256 tokenId)
        external
        view
        returns (BetNFTState memory state);

    /**
     * @notice Get the NFT item
     * @param tokenId BetNFT token Id
     * @return item NFT item
     */
    function getItem(uint256 tokenId)
        external
        view
        returns (BetNFTItem memory item);

    /**
     * @notice Get the NFT owner
     * @param tokenId BetNFT token Id
     * @return owner NFT owner address
     */
    function getOwner(uint256 tokenId) external view returns (address);

    /**
     * @notice Check whether an NFT exists
     * @param tokenId BetNFT token Id
     * @return result whether a given BetNFT exists
     */
    function exists(uint256 tokenId) external view returns (bool);

    event LogBetNFTCreate(
        uint256 indexed tokenId,
        uint256 matchKey,
        uint256 mintValue,
        uint256 faceValue,
        bytes32 ticker,
        address minter,
        address bookmaker,
        address jackpot,
        string tokenURI,
        address indexed owner
    );

    event LogBetNFTTransfer(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to
    );

    event LogBetNFTList(
        uint256 indexed tokenId,
        uint256 price,
        bytes32 ticker,
        address indexed owner,
        address indexed seller,
        uint256 expires,
        EnumItemStatus itemStatus
    );

    event LogBetNFTUpdate(
        uint256 indexed tokenId,
        uint256 price,
        bytes32 ticker,
        address indexed owner,
        address indexed seller,
        uint256 expires,
        EnumItemStatus itemStatus
    );

    event LogBetNFTUnlist(
        uint256 indexed tokenId,
        uint256 price,
        bytes32 ticker,
        address indexed owner,
        address indexed seller,
        uint256 expires,
        EnumItemStatus itemStatus
    );

    event LogBetNFTSale(
        uint256 indexed tokenId,
        uint256 price,
        bytes32 ticker,
        address indexed owner,
        address indexed seller,
        uint256 expires,
        EnumItemStatus itemStatus
    );

    event LogBetNFTClaim(
        uint256 indexed tokenId,
        uint256 price,
        address indexed owner,
        address indexed seller
    );

    event LogBetNFTBuyback(
        uint256 indexed tokenId,
        uint256 price,
        address indexed owner,
        address indexed seller
    );

    event LogBetNFTCalculate(
        uint256 indexed tokenId,
        uint256 reward,
        EnumRewardPhase indexed rewardPhase
    );
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import {JackpotTransferer} from "../utils/BetStructs.sol";

interface IJackpot {
    event LogJackpotBet(
        uint256 indexed tokenId,
        address tokenAddress,
        address indexed owner,
        uint256 ownerAmount,
        address indexed bookmaker,
        uint256 bookmakerAmount
    );

    event LogJackpotWithdraw(
        uint256 indexed tokenId,
        address tokenAddress,
        address indexed account,
        uint256 amount
    );

    /**
     * @notice Both BetNFT owner and bookmaker bet into the jackpot
     * @param ownerTransferer Token transfer object
     * @param bookmakerTransferer Token transfer object
     * @return result Whether token transfer successfully
     */
    function bet(
        JackpotTransferer calldata ownerTransferer,
        JackpotTransferer calldata bookmakerTransferer
    ) external returns (bool);

    /**
     * @notice BetNFT owner claim rewards in term of ERC20 tokens
     * @param transferer Token transfer object
     * @return result Whether token transferred successfully
     */
    function redeem(JackpotTransferer calldata transferer)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import {EnumOracleCode} from "../utils/BetEnums.sol";

interface IOracleConsumer {
    event LogOracleMatchResultRequested(
        bytes32 indexed requestId,
        uint256 indexed matchKey
    );

    event LogOracleMatchResultFulfilled(
        bytes32 indexed requestId,
        uint256 indexed matchKey,
        EnumOracleCode indexed code,
        int256[] matchResult
    );

    /**
     * @notice Rewarder fetch oracle match result
     * @param matchKey unique key for the match result
     * @return result match result in array format
     */
    function checkMatchResult(uint256 matchKey)
        external
        view
        returns (int256[] memory);

    /**
     * @notice Send chainlink request to get match result
     * @param matchKey unique key for the match result
     * @return requestId
     */
    function requestMatchResult(uint256 matchKey, bool enforce)
        external
        returns (bytes32 requestId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

contract AssertRules {
    mapping(uint256 => string[]) private defaultAssertFunc;

    constructor() {
        defaultAssertFunc[10] = ["(vK1,@,vR*,)?(vK2,):(v0,)"];

        // Over/Under
        defaultAssertFunc[20] = [
            "(vR0,+,vR1,<,(vK1,-,vK2,),)?(vK4,)",
            "(vR0,+,vR1,=,(vK1,-,vK2,),)?(vK5,)",
            "(vR0,+,vR1,>,(vK1,-,vK2,),)?(vK3,)"
        ];
        // Asian Handicap
        defaultAssertFunc[21] = [
            "(vR1,-,vR0,<,(vK1,-,vK2,),)?(vK3,)",
            "(vR1,-,vR0,=,(vK1,-,vK2,),)?(vK5,)",
            "(vR1,-,vR0,>,(vK1,-,vK2,),)?(vK4,)"
        ];
        // 2-way basketball
        defaultAssertFunc[22] = ["(vR0,-,vR1,>,(vK1,-,vK2,),)?(vK3,):(vK4,)"];
        // 1x2 (football)
        defaultAssertFunc[23] = [
            "(vR0,-,vR1,<,(vK1,-,vK2,),)?(vK4,)",
            "(vR0,-,vR1,=,(vK1,-,vK2,),)?(vK5,)",
            "(vR0,-,vR1,>,(vK1,-,vK2,),)?(vK3,)"
        ];
    }

    function getRule(uint256 assertIdx) public view returns (string[] memory) {
        return defaultAssertFunc[assertIdx];
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

/**
 * @title The decoder library
 */
library Decoder {
    function decode(uint256 x, uint256 bits)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 key = x % bits;
        return ((x - key) / bits, key);
    }

    function countUnits(uint256 value, uint256 unit)
        internal
        pure
        returns (uint256 count, uint256 length)
    {
        if (value == 0) {
            return (1, 0);
        }
        length = 0;
        count = 0;
        while (value > 0) {
            value /= 10;
            if (length % unit == 0) {
                count++;
            }
            length++;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import {BetNFTItem, BetNFTState} from "../utils/BetStructs.sol";

interface IPlayground {
    /**
     * @notice Listing BetNFT for sale
     * @param tokenId NFT tokenId
     * @param price NFT price
     * @param expires NFT listing expires
     * @return result whether listing BetNFT successfully
     */
    function listBetNFT(
        uint256 tokenId,
        uint256 price,
        uint256 expires
    ) external returns (bool);

    /**
     * @notice Unlisting BetNFT for edit or collecting
     * @param tokenId BetNFT tokenId
     * @return result whether unlisting BetNFT successfully
     */
    function unlistBetNFT(uint256 tokenId) external returns (bool);

    /**
     * @notice Complete BetNFT trade between seller and buyer
     * @param tokenId BetNFT tokenId
     * @return result whether trade BetNFT successfully
     */
    function tradeBetNFT(uint256 tokenId) external returns (bool);

    /**
     * @notice Withdraw reward and burn the BetNFT
     * @param tokenId BetNFT tokenId
     * @param matchKey matchKey to be checked
     * @return result whether clearing and burn BetNFT successfully
     */
    function claimBetNFT(uint256 tokenId, uint256 matchKey)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import "./BetCalculatorLogger.sol";

/**
 * @title Betting bonus calculation contract
 * @notice In fact, this contract is a VM based on solidity, which is used to explain the gambling rules described using GRS
 */
contract BetCalculator {
    uint256 private constant FIX = 32; ///decimal point Fix bit.
    uint256 private constant KEY_MASK = 32; ///assertKey mask
    uint256 private constant ALPHA_0 = 0x30;
    int256 private constant IMPOSSIBLE_INT = -0xFFFF;

    enum EnumCalState {
        calCondition,
        calResultSuccess,
        calResultFalse
    }

    struct AssertData {
        uint256[] assertKey;
        bytes[] assertFuc;
        int256[] matchResult;
        bool unrecoveredError;
    }

    /**
     * @notice Deserialize assertKey array
     * @param oAssertKey assertKey string encoding
     * @param arrAssertKey the function fulfill &arrAssertKey
     */
    function assertKeyDeserialization(
        bytes memory oAssertKey,
        uint256[] memory arrAssertKey
    ) internal pure returns (bool) {
        uint256 curArr = 0;
        uint256 uValue = 0;

        if (oAssertKey[oAssertKey.length - 1] != ",") {
            return false;
        }
        for (uint256 pf = 0; pf < oAssertKey.length; ) {
            if (oAssertKey[pf] == ",") {
                pf++;
                arrAssertKey[curArr] = uValue;
                curArr++;
                uValue = 0;
                continue;
            } else if (oAssertKey[pf] == ">") {
                pf++;
                uValue =
                    (uValue << FIX) /
                    (10**((uint8(oAssertKey[pf]) - ALPHA_0)));
                pf++;
            } else {
                uValue = uValue * 10 + (uint8(oAssertKey[pf]) - ALPHA_0);
                pf++;
            }
        }
        return true;
    }

    /**
     * @notice Deserialize assertKey array
     * @param oAssertKey assertKey uint256 encoding
     * @param arrAssertKey the function fulfill &arrAssertKey
     */
    function assertKeyDeserialization(
        uint256[] memory oAssertKey,
        uint256[] memory arrAssertKey
    ) internal view returns (bool) {
        for (uint256 pf = 0; pf < oAssertKey.length; pf++) {
            if (oAssertKey[pf] & (0xFFFFFFFF << KEY_MASK) > 0) {
                //需要小数点
                arrAssertKey[pf] =
                    ((oAssertKey[pf] >> KEY_MASK) << FIX) /
                    (10**(oAssertKey[pf] & 0xFFFFFFFF));
                LogBC.logUint("HIGH", arrAssertKey[pf]);
            } else {
                arrAssertKey[pf] = oAssertKey[pf];
                LogBC.logUint("LOW", arrAssertKey[pf]);
            }
        }
        return true;
    }

    /**
     * @notice Basic operations
     * @param l left value
     * @param r right value
     * @param o operator
     * @return bool operation successfully
     * @return int256 operation result
     */
    // solhint-disable
    function calculateEquation(
        int256 l,
        int256 r,
        bytes1 o,
        AssertData memory ad
    ) internal pure returns (bool, int256) {
        if (o == "+") {
            return (true, l + r);
        } else if (o == "-") {
            return (true, l - r);
        } else if (o == "*") {
            return (true, l * r);
        } else if (o == "M") {
            return (true, (l * r) >> FIX);
        } else if (o == "/") {
            return (true, l / r);
        } else if (o == "D") {
            return (true, (l << FIX) / r);
        } else if (o == ">") {
            return (l > r, 0);
        } else if (o == "G") {
            return (l >= r, 0);
        } else if (o == "<") {
            return (l < r, 0);
        } else if (o == "L") {
            return (l <= r, 0);
        } else if (o == "=") {
            return (l == r, 0);
        } else if (o == "|") {
            if (l != 0 || r != 0) {
                return (true, 0);
            } else {
                return (false, 0);
            }
        } else if (o == "&") {
            if (l != 0 && r != 0) {
                return (true, 0);
            } else {
                return (false, 0);
            }
        } else if (o == "@" && r == 0) {
            //belong to Result set
            for (uint256 i = 0; i < ad.matchResult.length; i++) {
                if (l == ad.matchResult[i]) return (true, 0);
            }
            return (false, 0);
        } else {
            return (false, 0);
        }
    }

    /**
     * @notice Handling value expressions
     * @param fuc current processing statement
     * @param pf current cursor
     * @return uint256 renew cursor
     * @return bool operation successfully,if value operation fails, the program cannot be recovered
     * @return int256 value result
     */
    function calculateValueExp(
        bytes memory fuc,
        uint256 pf,
        AssertData memory ad
    )
        internal
        pure
        returns (
            uint256,
            bool,
            int256
        )
    {
        int256 result = 0;
        while (fuc[pf] != ",") {
            if (fuc[pf] == "R") {
                pf++;
                if (fuc[pf] == "K") {
                    ///vRK?
                    pf++;
                    uint256 idx = uint8(fuc[pf]) - ALPHA_0;
                    if (idx >= ad.matchResult.length) {
                        ad.unrecoveredError = true;
                        pf = fuc.length - 1;
                        return (pf, false, 0);
                    }
                    result = ad.matchResult[ad.assertKey[idx]];
                } else if (fuc[pf] == "*") {
                    ///vR*
                    result = 0;
                } else {
                    ///vR?
                    uint256 idx = uint8(fuc[pf]) - ALPHA_0;
                    if (idx >= ad.matchResult.length) {
                        ad.unrecoveredError = true;
                        pf = fuc.length - 1;
                        return (pf, false, 0);
                    }
                    result = ad.matchResult[idx];
                }
                pf++;
            } else if (fuc[pf] == "K") {
                pf++;
                uint256 idx = uint8(fuc[pf]) - ALPHA_0;
                if (idx >= ad.assertKey.length) {
                    ad.unrecoveredError = true;
                    pf = fuc.length - 1;
                    return (pf, false, 0);
                }
                result = int256(ad.assertKey[idx]);
                pf++;
            } else {
                result = int256(uint256(uint8(fuc[pf]) - ALPHA_0));
                pf++;
            }
        }
        return (pf, true, result);
    }

    /**
     * @notice Handling sub expressions
     * @param fuc current processing statement
     * @param pf current cursor
     * @return uint256 renew cursor
     * @return bool operation successfully
     * @return int256 value result
     */
    function calculateSubExp(
        bytes memory fuc,
        uint256 pf,
        AssertData memory ad
    )
        internal
        view
        returns (
            uint256,
            bool,
            int256
        )
    {
        int256 lExp = IMPOSSIBLE_INT;
        int256 rExp = IMPOSSIBLE_INT;
        int256 expResult = IMPOSSIBLE_INT;
        bool bResult = false;
        bytes1 opt;

        if (fuc[pf] == "(") {
            ///start evaluating subexpression
            pf++;
        }
        while (pf < fuc.length) {
            if (fuc[pf] == ")") {
                ///subexpression calculated

                pf++;
                break;
            } else if (fuc[pf] == ",") {
                pf++;
            } else if (fuc[pf] == "(") {
                (pf, bResult, expResult) = calculateSubExp(fuc, pf, ad);
                LogBC.logValue(
                    "calculateSubExp-SubExp-Result",
                    fuc,
                    pf,
                    bResult,
                    expResult
                );
                if (lExp == IMPOSSIBLE_INT) {
                    lExp = expResult;
                } else {
                    rExp = expResult;
                }
            } else if (fuc[pf] == "v") {
                pf++;
                (pf, bResult, expResult) = calculateValueExp(fuc, pf, ad);
                LogBC.logValue(
                    "calculateSubExp-value-Result",
                    fuc,
                    pf,
                    bResult,
                    expResult
                );
                if (lExp == IMPOSSIBLE_INT) {
                    lExp = expResult;
                } else {
                    rExp = expResult;
                }
            } else {
                opt = fuc[pf];
                pf++;

                continue;
            }

            if (rExp != IMPOSSIBLE_INT) {
                ///The three elements of the expression are ready

                (bResult, expResult) = calculateEquation(lExp, rExp, opt, ad);
                LogBC.logExpF(
                    "alculateSubExp-Exp",
                    lExp,
                    opt,
                    rExp,
                    bResult,
                    expResult
                );
                lExp = expResult;
                rExp = IMPOSSIBLE_INT;
            }
        }

        return (pf, bResult, lExp);
    }

    /**
     * @notice Calculator main function
     * @return bool operation successfully
     * @return uint256 value result payload by "<< FIX"
     */
    function calculateFuc(AssertData memory ad)
        internal
        view
        returns (bool, uint256)
    {
        bool bResult = false;

        int256 expResult = IMPOSSIBLE_INT;

        EnumCalState calState = EnumCalState.calCondition;

        for (uint256 i = 0; i < ad.assertFuc.length; i++) {
            bytes memory fuc = ad.assertFuc[i]; ///do exp i
            calState = EnumCalState.calCondition;
            for (uint256 pf = 0; pf < fuc.length; ) {
                if (fuc[pf] == "?") {
                    if (calState == EnumCalState.calResultFalse) {
                        ///Conditional statement failed，evaluate exp2
                        while (fuc[pf] != ":") {
                            pf++;
                            if (pf == fuc.length) {
                                break; ///jump to next exp
                            }
                        }
                    }
                    pf++;
                    continue;
                } else if (fuc[pf] == ":" || fuc[pf] == ",") {
                    pf++;
                    continue;
                } else {
                    ///“( or v‘
                    (pf, bResult, expResult) = calculateSubExp(fuc, pf, ad);
                    LogBC.logValue(
                        "calculateFuc -SubExpReturn",
                        fuc,
                        pf,
                        bResult,
                        expResult
                    );
                }

                if (calState == EnumCalState.calCondition) {
                    if (!bResult) {
                        calState = EnumCalState.calResultFalse;
                        LogBC.logUint("Exp false", i);
                        ///current exp false, jump to next exp
                    } else {
                        calState = EnumCalState.calResultSuccess; ///current exp success，evaluate rewards
                        LogBC.logUint("Exp true", i);
                    }
                } else if (
                    calState == EnumCalState.calResultSuccess && bResult
                ) {
                    LogBC.logUint(
                        "-------Reward-------",
                        uint256(expResult) >> FIX
                    );
                    if (expResult >= 0) {
                        return (true, uint256(expResult));
                    } else {
                        return (false, 0);
                    }
                } else if (calState == EnumCalState.calResultFalse && bResult) {
                    LogBC.logUint(
                        "-------Reward-------",
                        uint256(expResult) >> FIX
                    );
                    if (expResult >= 0) {
                        return (true, uint256(expResult));
                    } else {
                        return (false, 0);
                    }
                }
            }
        }
        return (false, 0);
    }

    /**
     * @notice Internal entry function
     */
    function _getBettingReward(
        int256[] memory matchResult,
        uint256[] memory assertKey,
        bytes[] memory assertFuc
    ) internal view returns (bool, uint256) {
        AssertData memory ad = AssertData({
            assertKey: assertKey,
            assertFuc: assertFuc,
            matchResult: matchResult,
            unrecoveredError: false
        });
        (bool success, uint256 result) = calculateFuc(ad);
        if (!ad.unrecoveredError) {
            return (success, result);
        } else {
            return (false, result);
        }
    }

    /**
     * @notice  Entry function, string encoding, return rewards payload by <<FIX
     */
    function getFixedBettingReward(
        int256[] memory matchResult,
        string memory strAssertKey,
        string[] memory assertFuc
    ) public view returns (bool, uint256) {
        uint256[] memory assertKey = new uint256[](bytes(strAssertKey).length);

        if (!assertKeyDeserialization(bytes(strAssertKey), assertKey)) {
            return (false, 0);
        }

        bytes[] memory _aF = new bytes[](assertFuc.length);
        for (uint256 i = 0; i < assertFuc.length; i++) {
            _aF[i] = bytes(assertFuc[i]);
        }

        return (_getBettingReward(matchResult, assertKey, _aF));
    }

    /**
     * @notice  Entry function, string encoding,  return rewards WITHOUT <<FIX
     */
    function getUnfixedBettingReward(
        int256[] memory matchResult,
        string memory strAssertKey,
        string[] memory assertFuc
    ) internal view returns (bool, uint256) {
        (bool success, uint256 result) = getFixedBettingReward(
            matchResult,
            strAssertKey,
            assertFuc
        );

        return (success, result >> FIX);
    }

    /**
     * @notice  Entry function, uint256 encoding
     */
    function getFixedBettingReward(
        int256[] memory matchResult,
        uint256[] memory oAssertKey,
        bytes[] memory assertFuc
    ) public view returns (bool, uint256) {
        uint256[] memory assertKey = new uint256[](oAssertKey.length);

        if (!assertKeyDeserialization(oAssertKey, assertKey)) {
            return (false, 0);
        }

        return (_getBettingReward(matchResult, assertKey, assertFuc));
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

interface IRewarder {
    /**
     * @notice Calculate BetNFT reward, bookmaker withdraws stakes
     * @param tokenId BetNFT tokenId
     * @return whether calculate reward successfully
     */
    function calculateReward(uint256 tokenId) external returns (bool);

    /**
     * @notice Request match result from oracle
     * @param matchKey unique key for the match result
     * @param enforce enforce an oracle request
     */
    function requestMatchResult(uint256 matchKey, bool enforce) external;

    /**
     * @notice Get match result from oracle
     * @param matchKey unique key for the match result
     */
    function checkMatchResult(uint256 matchKey) external;

    /**
     * @notice Get match result of a given match
     * @param matchKey unique key for the match result
     * @return result match result in array format
     */
    function fetchMatchResult(uint256 matchKey)
        external
        returns (int256[] memory);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

library LogBC {
    function logExpF(
        string memory script,
        int256 lExp,
        bytes1 opt,
        int256 rExp,
        bool bResult,
        int256 expResult
    ) internal view {}

    function logValue(
        string memory script,
        bytes memory fuc,
        uint256 pf,
        bool bResult,
        int256 expResult
    ) internal view {}

    function logUint(string memory script, uint256 uPayload) internal view {}
}