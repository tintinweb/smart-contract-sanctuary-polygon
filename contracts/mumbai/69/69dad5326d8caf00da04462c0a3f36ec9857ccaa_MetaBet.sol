// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MetaBetDomain.sol";
import "./MetaWallet.sol";
import "./MetaBetInterface.sol";
import "./MetaBetLib.sol";
import "hardhat/console.sol";

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/18c7efe800df6fc19554ece3b1f238e9e028a1db/contracts/token/ERC721/ERC721.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/18c7efe800df6fc19554ece3b1f238e9e028a1db/contracts/utils/Counters.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/18c7efe800df6fc19554ece3b1f238e9e028a1db/contracts/math/SafeMath.sol";

/*
 * @notice SmartBet core smart contract. Handles matches, bets and farming
 */
contract MetaBet is
    Context,
    Ownable,
    MetaBetDomain,
    MetaWallet,
    MetaBetInterface
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using MetaBetLib for uint256;

    uint256 private constant MAX_DEPOSIT = 999999;

    // 押注者数量，如果押注用户为0或者所有用户都已经提取完资产，管理者可以提取剩余的资产余额
    uint256 private assetCount = 0;

    ////////////////////////////////////////
    //                                    //
    //         STATE VARIABLES            //
    //                                    //
    ////////////////////////////////////////
    // incremented id for league id generation
    Counters.Counter private leagueIds;

    // incremented for match id generation
    Counters.Counter private matchIds;

    // incremented id for NFT minting
    Counters.Counter private tokenIds;

    // 比赛创建者角色信息-管理员
    mapping(address => bool) private _operators;

    // 比赛创建者角色信息
    mapping(address => bool) private _signers;

    // 重入工具判断
    bool retryAttach = false;

    // mapping(bytes32 => uint256) matchResultRequestIds;

    mapping(address => uint256[]) private matchesBetted;

    // Mapping from smartAssetId to owner address
    mapping(uint256 => address) private _smartAssetIdOwners; // 关联关系

    ////////////////////////////////////////
    //                                    //
    //           CONSTRUCTOR              //
    //                                    //
    ////////////////////////////////////////
    constructor(address _erc20Token) {
        erc20Token = IERC20(_erc20Token);
        addToken(_erc20Token);
        addSigner(_msgSender(), Role.OPERATOR);
    }

    ////////////////////////////////////////
    //                                    //
    //              MODIFIERS             //
    //                                    //
    ////////////////////////////////////////

    modifier onlySigner() {
        require(
            isSigner(_msgSender(), Role.CREATOR),
            "SignerRole: caller does not have the Signer role"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            isSigner(_msgSender(), Role.OPERATOR),
            "OperatorRole: caller does not have the Operator role"
        );
        _;
    }

    /*
     *  @notice Checks if the NFT is valid
     *  @dev Validates NFT
     */
    modifier validateToken(uint256 _smartAssetId) {
        require(_exists(_smartAssetId), "Invalid smartAssetId");
        _;
    }

    /*
     *  @notice  Ensure token belongs to the caller
     */
    modifier isTokenOwner(uint256 _smartAssetId) {
        require(
            smartAssetIdOwnerOf(_smartAssetId) == _msgSender(),
            "caller is not token owner"
        );
        _;
    }

    ////////////////////////////////////////
    //                                    //
    //              FUNCTIONS             //
    //                                    //
    ////////////////////////////////////////

    /*
     *  @notice  New League creation
     *  @dev
     *  @param
     *  @return  league Id
     */
    function createLeague(
        string calldata _name,
        string calldata _country,
        string calldata _logo
    ) public onlyOwner returns (uint256) {
        leagueIds.increment();
        uint256 leagueId = leagueIds.current();

        leagues[leagueId] = League(_msgSender(), _name, _country, _logo, true);
        //  address creator,
        // uint256 indexed leagueId,
        // uint256 indexed createdOn,
        // League leagueInfo
        uint256 createdOnDay = block.timestamp - (block.timestamp % 86400);
        emit LeagueCreatedEvent(
            _msgSender(),
            leagueId,
            createdOnDay,
            leagues[leagueId]
        );
        return leagueId;
    }

    /*
     *  @notice  League colse
     *  @dev
     *  @param
     *  @return  league Id
     */
    function closeLeague(uint256 _leagueId)
        public
        onlyOwner
        leagueExists(_leagueId)
        returns (uint256)
    {
        leagues[_leagueId].flag = true;
        emit LeagueClosedEvent(_msgSender(), _leagueId, block.timestamp);
        return _leagueId;
    }

    /*
     *  @notice  New match creation
     *  @dev
     *  @param
     *  @return  match Id
     */
    function createMatch(
        uint256 _leagueId,
        uint256 _apiMatchId,
        string calldata _matchResultLink,
        MatchInfo calldata _matchInfo
    )
        public
        payable
        leagueExists(_leagueId)
        isNewAPIMatch(_apiMatchId)
        returns (uint256)
    {
        uint256 amountBet = msg.value;
        require(
            _matchInfo.initOddsTeamA > 0 &&
                _matchInfo.initOddsTeamB > 0 &&
                _matchInfo.initOddsDraw > 0,
            "Invalid Odds [TeamA or TeamB or Draw]"
        );
        if (_matchInfo.assetType == AssetType.ETH) {
            require(amountBet != 0, "Invalid amount bet");
            payable(address(this)).transfer(amountBet);
        }
        if (_matchInfo.assetType == AssetType.ERC20) {
            amountBet =
                _matchInfo.initOddsTeamA +
                _matchInfo.initOddsTeamB +
                _matchInfo.initOddsDraw;
            require(
                IERC20(_matchInfo.payToken).transferFrom(
                    _msgSender(),
                    address(this),
                    amountBet
                )
            );
        }
        if (!isSigner(_msgSender(), Role.CREATOR)) {
            addSigner(_msgSender(), Role.CREATOR);
        }
        matchIds.increment();
        uint256 matchId = matchIds.current();
        RealTimeAmount memory realTimeAmount = RealTimeAmount(
            _matchInfo.initOddsTeamA,
            _matchInfo.initOddsTeamB,
            _matchInfo.initOddsDraw
        );

        apiMatches[_apiMatchId] = matchId;
        // 创建比赛项目
        matches[matchId] = Match(
            _msgSender(),
            _leagueId,
            _matchResultLink,
            _matchInfo.initOddsTeamA,
            _matchInfo.initOddsTeamB,
            _matchInfo.initOddsDraw,
            0,
            true,
            0, // 平或X队得分
            0, // A队得分 A 0
            0, // B队得分 scoreB 0
            0, // 最终赢率（含本金） finalOdds 0
            tokenIds.current(), // 下注Id （最终下注ID）（chainlink取值后查询下注ID）
            _matchInfo, // 比赛信息
            MatchResult.NOT_DETERMINED, // 比赛结果
            MatchState.NOT_STARTED // 押注赛程状态
        );

        // 初始化A队押注金额
        awardBetSmartAsset(
            _msgSender(),
            _leagueId,
            matchId,
            MatchResult.TEAM_A_WON,
            _matchInfo.assetType,
            _matchInfo.payToken,
            _matchInfo.initOddsTeamA,
            realTimeAmount
        );
        // 初始化B队押注金额
        awardBetSmartAsset(
            _msgSender(),
            _leagueId,
            matchId,
            MatchResult.TEAM_B_WON,
            _matchInfo.assetType,
            _matchInfo.payToken,
            _matchInfo.initOddsTeamB,
            realTimeAmount
        );
        // 初始化平押注金额
        awardBetSmartAsset(
            _msgSender(),
            _leagueId,
            matchId,
            MatchResult.DRAW,
            _matchInfo.assetType,
            _matchInfo.payToken,
            _matchInfo.initOddsDraw,
            realTimeAmount
        );

        addToken(_matchInfo.payToken);
        emitMatchCreatedEvent(_leagueId, matchId, _apiMatchId, _matchInfo);
        return matchId;
    }

    function emitMatchCreatedEvent(
        uint256 _leagueId,
        uint256 _matchId,
        uint256 _apiMatchId,
        MatchInfo calldata _info
    ) internal {
        uint256 createdOnDay = block.timestamp - (block.timestamp % 86400);
        emit MatchCreatedEvent(
            _msgSender(),
            _leagueId,
            _matchId,
            _apiMatchId,
            createdOnDay,
            _info
        );
    }

    /*
     *  @notice  New bet creation. Mint NFT to bettor
     *  @dev
     *  @param
     *  @return  token id
     */
    function placeBet(
        uint256 _matchId,
        uint8 _resultBetOn,
        PayAsset memory _payAsset
    )
        public
        payable
        isCircuitBreakOff
        matchExists(_matchId)
        matchNotStarted(_matchId)
        isBetAllowed(_matchId)
        validateMatchResult(_resultBetOn)
        returns (uint256)
    {
        if (
            _payAsset.assetType != AssetType.ETH &&
            _payAsset.assetType != AssetType.ERC20 &&
            _payAsset.assetType != AssetType.ERC721 &&
            _payAsset.assetType != AssetType.ERC1155 &&
            _payAsset.assetType != AssetType.ERC721Deprecated
        ) {
            return 0;
        }
        // 判断是否为本次押注项目支持币种
        require(
            matches[_matchId].matchInfo.payToken == _payAsset.payToken,
            "Current match does not support betting in this currency"
        );
        if (matches[_matchId].matchInfo.startAt < block.timestamp) {
            matches[_matchId].state = MatchState.STARTED;
            return 0;
        }
        if (_payAsset.assetType == AssetType.ETH) {
            require(
                _payAsset.payAmount == msg.value && _payAsset.payAmount != 0,
                "Invalid amount bet"
            );
            payable(address(this)).transfer(_payAsset.payAmount);
        } else if (_payAsset.assetType == AssetType.ERC20) {
            require(_payAsset.payAmount != 0, "Invalid amount bet");
            require(
                IERC20(_payAsset.payToken).transferFrom(
                    _msgSender(),
                    address(this),
                    _payAsset.payAmount
                )
            );
        }
        MatchResult matchResultBetOn = MatchResult(_resultBetOn);
        //update team's total payout
        if (matchResultBetOn == MatchResult.TEAM_A_WON) {
            matches[_matchId].totalPayoutTeamA = matches[_matchId]
                .totalPayoutTeamA
                .add(_payAsset.payAmount);
        } else if (matchResultBetOn == MatchResult.TEAM_B_WON) {
            matches[_matchId].totalPayoutTeamB = matches[_matchId]
                .totalPayoutTeamB
                .add(_payAsset.payAmount);
        } else {
            matches[_matchId].totalPayoutDraw = matches[_matchId]
                .totalPayoutDraw
                .add(_payAsset.payAmount);
        }

        RealTimeAmount memory realTimeAmount = RealTimeAmount(
            matches[_matchId].totalPayoutTeamA,
            matches[_matchId].totalPayoutTeamB,
            matches[_matchId].totalPayoutDraw
        );

        // 将押注金额mint成一个NFT作为流动性质押凭证，通过凭证质押获取额外利息
        uint256 smartAssetId = awardSmartAsset(
            _msgSender(),
            matches[_matchId].leagueId,
            _matchId,
            matchResultBetOn,
            _payAsset,
            realTimeAmount
        );

        matchesBetted[_msgSender()].push(smartAssetId);
        //Save bettor's bet
        matchBets[_matchId][matchResultBetOn].push(smartAssetId);
        // 更新押注ID
        matches[_matchId].finalAssetId = smartAssetId;

        emitBetPlacedEvent(_msgSender(), _matchId, matchResultBetOn, _payAsset);

        return smartAssetId;
    }

    /**
     *  @notice  New bet creation. Mint NFT to bettor
     *  @dev
     *  @param
     */
    function placeBetMatch(
        bytes32 _hashId,
        uint256 _matchId,
        // 比赛参与方信息：(主场):(客场):(次场)
        string calldata _matchTeamName,
        // 押注team队名称
        string calldata _betTeamName,
        // 押注金额
        uint256 _payAmount,
        // 押注用户Code
        uint256 _userCode,
        // 最终赢率（含本金） finalOdds
        uint256 _finalOdds
    ) public onlyOwner {
        placeBetInfoByHash[_hashId] = PlaceBetInfo(
            _msgSender(),
            _hashId,
            _matchId,
            _matchTeamName,
            _betTeamName,
            _payAmount,
            _userCode,
            block.timestamp,
            _finalOdds
        );
        emit PlaceBetMatchEvent(
            _msgSender(),
            _hashId,
            _matchId,
            _matchTeamName,
            _betTeamName,
            _payAmount,
            _userCode,
            block.timestamp,
            _finalOdds
        );
    }

    function emitBetPlacedEvent(
        address _bettor,
        uint256 _matchId,
        MatchResult _matchResultBetOn,
        PayAsset memory _payAsset
    ) internal {
        emit BetPlacedEvent(
            _bettor,
            matches[_matchId].leagueId,
            _matchId,
            _matchResultBetOn,
            _payAsset.payAmount,
            block.timestamp,
            _payAsset.assetType,
            _payAsset.payToken
        );
    }

    /**
    设置押注信息
     */
    function awardBetSmartAsset(
        address _bettor,
        uint256 _leagueId,
        uint256 _matchId,
        MatchResult _matchResultBetOn,
        AssetType _payType,
        address _payToken,
        uint256 _assetValue,
        RealTimeAmount memory _realTimeAmount
    ) internal {
        PayAsset memory payAsset = PayAsset(_payType, _payToken, _assetValue);
        uint256 smartAssetId = awardSmartAsset(
            _bettor,
            _leagueId,
            _matchId,
            _matchResultBetOn,
            payAsset,
            _realTimeAmount
        );
        matchesBetted[_bettor].push(smartAssetId);
        matchBets[_matchId][_matchResultBetOn].push(smartAssetId);
    }

    /**
     * 设置押注信息
     */
    function awardSmartAsset(
        address _bettor,
        uint256 _leagueId,
        uint256 _matchId,
        MatchResult _matchResultBetOn,
        PayAsset memory _payAsset,
        RealTimeAmount memory _realTimeAmount
    ) internal returns (uint256) {
        tokenIds.increment();

        uint256 smartAssetId = tokenIds.current();
        // _mint(bettor, smartAssetId);
        // 创建资产白条押注关联关系
        _smartAssetIdOwners[smartAssetId] = _bettor;

        string memory betTeamName = "DRAW";
        //update team's total payout
        if (_matchResultBetOn == MatchResult.TEAM_A_WON) {
            betTeamName = matches[_matchId].matchInfo.teamAName;
        } else if (_matchResultBetOn == MatchResult.TEAM_B_WON) {
            betTeamName = matches[_matchId].matchInfo.teamBName;
        } else if (_matchResultBetOn == MatchResult.DRAW) {
            betTeamName = matches[_matchId].matchInfo.drawName;
        }

        smartAssets[smartAssetId] = SmartAsset(
            _bettor,
            _leagueId,
            _matchId,
            _matchResultBetOn, // 押注 哪一方
            _payAsset, // ETH 或ERC20 实付币种 // USDC
            _realTimeAmount, // 实时押注时间节点累计总金额：A B O
            0, // 累计利息
            block.timestamp, // bet_timestamp :下注时间
            0, // 手续费金额
            0, // withdraw_到手提款金额
            0, // withdraw_timestamp提取时间
            betTeamName
        );

        assetCount = assetCount + 1;
        emit SmartAssetAwardedEvent(
            _bettor,
            _leagueId,
            _matchId,
            _matchResultBetOn,
            smartAssetId,
            block.timestamp,
            _payAsset.assetType,
            _payAsset.payToken,
            _realTimeAmount
        );

        return smartAssetId;
    }

    /**
     * 计算赔率:
     *  A赔率=（O总金额+B总金额）/A总金额 + 1
     *  B赔率=（O总金额+A总金额）/B总金额 + 1
     *  O赔率=（A总金额+B总金额）/O总金额 + 1
     */
    function calculateOdds(uint256 _matchId) internal {
        uint256 totalPayoutTeamA = matches[_matchId].totalPayoutTeamA;
        uint256 totalPayoutTeamB = matches[_matchId].totalPayoutTeamB;
        uint256 totalPayoutDraw = matches[_matchId].totalPayoutDraw;

        if (matches[_matchId].result == MatchResult.TEAM_A_WON) {
            // TeamA最终赔率
            matches[_matchId].finalOdds = MetaBetLib.calculateAssetOdds(
                totalPayoutDraw,
                totalPayoutTeamB,
                totalPayoutTeamA
            );
        } else if (matches[_matchId].result == MatchResult.TEAM_B_WON) {
            // TeamB最终赔率
            matches[_matchId].finalOdds = MetaBetLib.calculateAssetOdds(
                totalPayoutDraw,
                totalPayoutTeamA,
                totalPayoutTeamB
            );
        } else {
            // TeamA和TeamB平局最终赔率
            matches[_matchId].finalOdds = MetaBetLib.calculateAssetOdds(
                totalPayoutTeamB,
                totalPayoutTeamA,
                totalPayoutDraw
            );
        }
    }

    /*
     *  @notice  Match manual start by admin.
     *  @param 以比赛下半场算启动
     *  @return
     */
    function startMatch(uint256 _matchId)
        public
        virtual
        override
        onlyOperator
        matchExists(_matchId)
        matchNotStarted(_matchId)
    {
        matches[_matchId].state = MatchState.STARTED;
        emit MatchStartEvent(
            _msgSender(),
            matches[_matchId].leagueId,
            _matchId,
            block.timestamp
        );
    }

    /*
     *  @notice  Match manual close by admin. Trigger "getResult()"
     *  @dev     [Real] ChainlinkClient API Request oracles gets match result of winning team. Then, match is closed.
     *           [Temporary] (Implemented because there's no BSC testnet oracle node)
     *                       Frontend gets result via result link and posts winning team. Then, match is closed.
     *  @param
     *  @return  success success status
     */
    function closeMatch(
        uint256 _matchId,
        uint8 _matchResult,
        uint8 scoreDraw,
        uint8 scoreTeamA,
        uint8 scoreTeamB
    )
        public
        virtual
        override
        onlyOperator
        matchExists(_matchId)
        matchStarted(_matchId)
        validateMatchResult(_matchResult)
    {
        matches[_matchId].state = MatchState.FINISHED;

        // getMatchResult(_matchId);
        MatchResult matchResult = MatchResult(_matchResult);
        // 设置比赛结果
        setMatchResult(
            _matchId,
            matchResult,
            scoreDraw,
            scoreTeamA,
            scoreTeamB
        );

        if (matchResult == MatchResult.TEAM_A_WON) {
            invalidateAssets(matchBets[_matchId][MatchResult.TEAM_B_WON]);
            invalidateAssets(matchBets[_matchId][MatchResult.DRAW]);
        } else if (matchResult == MatchResult.TEAM_B_WON) {
            invalidateAssets(matchBets[_matchId][MatchResult.TEAM_A_WON]);
            invalidateAssets(matchBets[_matchId][MatchResult.DRAW]);
        } else if (matchResult == MatchResult.DRAW) {
            invalidateAssets(matchBets[_matchId][MatchResult.TEAM_A_WON]);
            invalidateAssets(matchBets[_matchId][MatchResult.TEAM_B_WON]);
        }

        emit MatchClosedEvent(
            _msgSender(),
            matches[_matchId].leagueId,
            _matchId,
            block.timestamp
        );
    }

    function setMatchResult(
        uint256 _matchId,
        MatchResult _matchResult,
        uint8 scoreDraw,
        uint8 scoreTeamA,
        uint8 scoreTeamB
    ) internal {
        matches[_matchId].result = _matchResult;
        matches[_matchId].scoreDraw = scoreDraw;
        matches[_matchId].scoreTeamA = scoreTeamA;
        matches[_matchId].scoreTeamB = scoreTeamB;
        // 计算最终的 A,B,平 的赔率
        calculateOdds(_matchId);

        emit MatchResultSetEvent(
            matches[_matchId].leagueId,
            _matchId,
            matches[_matchId].result,
            block.timestamp,
            scoreTeamA,
            scoreTeamB
        );
    }

    function invalidateAssets(uint256[] memory assets) internal {
        for (uint256 i = 0; i < assets.length; i++) {
            invalidateAsset(assets[i]);
        }
    }

    // 销毁押注关联关系
    function invalidateAsset(uint256 _smartAssetId) internal {
        _burn(_smartAssetId);
    }

    function _burn(uint256 _smartAssetId) internal virtual {
        assetCount = assetCount - 1;
        delete _smartAssetIdOwners[_smartAssetId];
    }

    /*
     *  @notice  Liquidate smart asset's value
     *  @dev     validated   NFT is burned and caller gets value funds in account
     *  @param   _smartAssetId smart asset id
     *  @return  success status
     */
    function liquidateAsset(uint256 _smartAssetId)
        public
        payable
        isCircuitBreakOff
        validateToken(_smartAssetId)
        isTokenOwner(_smartAssetId)
        returns (bool)
    {
        SmartAsset memory smartAsset = smartAssets[_smartAssetId];
        require(
            matches[smartAsset.matchId].state == MatchState.FINISHED,
            "Cannot liquidate asset until match is finished"
        );
        // 获取比赛结果
        MatchResult matchResult = matches[smartAsset.matchId].result;

        uint256 lastWinValue = smartAsset.betInfo.payAmount;
        // 提取赢得的押注资产
        if (matchResult == smartAsset.matchResult) {
            // 获取最终赔率
            uint256 lastBetOdds = matches[smartAsset.matchId].finalOdds;
            // 计算最终获取金额
            lastWinValue = lastWinValue.mul(lastBetOdds).div(
                100000000000000000
            );
        }
        // 手续费金额
        uint256 feesAmount = lastWinValue
            .mul(matches[smartAsset.matchId].matchInfo.winnerFeeRate)
            .div(100);
        // withdraw_到手提款金额
        uint256 withdrawAmount = lastWinValue.sub(feesAmount);
        // 判断是否存在小于0.01的尾数
        if (smartAsset.betInfo.assetType == AssetType.ETH) {
            uint256 smartBalance = address(this).balance;
            require(
                smartBalance >= smartAsset.betInfo.payAmount,
                "Contract has insufficient funds"
            );
            if (smartBalance < lastWinValue) {
                lastWinValue = smartBalance;
            }
            invalidateAsset(_smartAssetId);
            require(!retryAttach, "this contract attack !!");
            retryAttach = true;
            // 用户提款
            payable(_msgSender()).transfer(withdrawAmount);
            // 给比赛发起者转账佣金
            payable(matches[smartAsset.matchId].creator).transfer(feesAmount);
            retryAttach = false;
        }
        if (smartAsset.betInfo.assetType == AssetType.ERC20) {
            uint256 smartBalance = IERC20(smartAsset.betInfo.payToken)
                .balanceOf(address(this));
            require(
                smartBalance >= smartAsset.betInfo.payAmount,
                "Contract has Token insufficient funds"
            );
            if (smartBalance < lastWinValue) {
                lastWinValue = smartBalance;
            }
            invalidateAsset(_smartAssetId);
            // 用户提款
            require(
                IERC20(smartAsset.betInfo.payToken).transfer(
                    _msgSender(),
                    withdrawAmount
                )
            );
            // 给比赛发起者转账佣金
            require(
                IERC20(smartAsset.betInfo.payToken).transfer(
                    matches[smartAsset.matchId].creator,
                    feesAmount
                )
            );
        }

        //totalCollected; 每取一笔更新对账结果
        matches[smartAsset.matchId].totalWithDraw = matches[smartAsset.matchId]
            .totalWithDraw
            .add(lastWinValue);
        // 手续费金额
        smartAssets[_smartAssetId].feesAmount = feesAmount;
        // withdraw_到手提款金额
        smartAssets[_smartAssetId].withdrawAmount = withdrawAmount;
        // withdraw_timestamp提取时间
        smartAssets[_smartAssetId].withdrawTimestamp = block.timestamp;

        emit AssetLiquidatedEvent(
            _msgSender(),
            smartAsset.leagueId,
            smartAsset.matchId,
            smartAsset.betInfo.payAmount,
            block.timestamp,
            smartAsset.betInfo.assetType,
            smartAsset.betInfo.payToken
        );
        return true;
    }

    /*
     *  @notice  Contract Circuit Breaker
     *  @dev     Admin can [de]activate core functons in contract
     *  @param
     *  @return  success success status
     */
    function toggleCircuitBreaker() public onlyOwner {
        circuitBreaker = !circuitBreaker;
    }

    /*
     *  @notice  Fetch League details
     *  @dev
     *  @oaram   _leagueId
     *  @return League details
     */
    function getLeague(uint256 _leagueId)
        public
        view
        leagueExists(_leagueId)
        returns (League memory league_)
    {
        return leagues[_leagueId];
    }

    /*
     *  @notice  Fetch match details
     *  @dev
     *  @oaram   _matchId
     *  @return match match details
     */
    function getMatch(uint256 _matchId)
        public
        view
        matchExists(_matchId)
        returns (Match memory match_)
    {
        return matches[_matchId];
    }

    /*
     *  @notice  Fetch single SmartAsset
     *  @dev
     *  @param   _smartAssetId
     *  @return  asset details
     */
    function getSmartAsset(uint256 _smartAssetId)
        public
        view
        validateToken(_smartAssetId)
        isTokenOwner(_smartAssetId)
        returns (SmartAsset memory asset)
    {
        return smartAssets[_smartAssetId];
    }

    /*
     *  @notice  Fetch single SmartAsset
     *  @dev
     *  @param   _smartAssetId
     *  @return  asset details
     */
    function getMatchSmartAssetInfo(uint256 _smartAssetId)
        public
        view
        returns (MatchSmartAssetInfo memory info)
    {
        SmartAsset memory smartAssetInfo = smartAssets[_smartAssetId];
        Match memory matchDetail = matches[smartAssetInfo.matchId];
        info = MatchSmartAssetInfo(smartAssetInfo, matchDetail);
        return info;
    }

    /*
     *  @notice  Tells of the _msgSender() is the admin
     *  @dev
     *  @return  true if _msgSender() is admin else false
     */
    function isAdmin() public view returns (bool) {
        return _msgSender() == owner();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function smartAssetIdOwnerOf(uint256 _smartAssetId)
        public
        view
        virtual
        returns (address)
    {
        address _owner = _smartAssetIdOwners[_smartAssetId];
        require(_owner != address(0), "MetaBet: invalid token ID");
        return _owner;
    }

    function _exists(uint256 _smartAssetId)
        internal
        view
        virtual
        returns (bool)
    {
        return _smartAssetIdOwners[_smartAssetId] != address(0);
    }

    /**
     * ownerMatchesBets
     */
    function ownerMatchesBets() public view virtual returns (uint256[] memory) {
        return matchesBetted[_msgSender()];
    }

    function getEthBalance() public view virtual returns (uint256) {
        return address(this).balance;
    }

    /**
     * Allow withdraw of tokens from the contract
     */
    function withdrawToken() public onlyOwner {
        require(assetCount == 0, "User has not withdrawn assets");
        for (uint8 i = 0; i < tokens.length; i++) {
            uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
            if (balance > 0) {
                require(IERC20(tokens[i]).transfer(_msgSender(), balance));
            }
        }
        uint256 smartBalance = address(this).balance;
        if (smartBalance > 0) {
            require(!retryAttach, "this contract attack !!");
            retryAttach = true;
            payable(_msgSender()).transfer(smartBalance);
            retryAttach = false;
        }
    }

    function grantOperator(address account) public onlyOwner {
        addSigner(account, Role.OPERATOR);
    }

    function revokeOperator(address account) public onlyOwner {
        removeSigner(account, Role.OPERATOR);
    }

    function isSigner(address account, Role role) public view returns (bool) {
        return has(account, role);
    }

    /**
     * @dev Give an account access to this role.
     */
    function addSigner(address account, Role role) internal {
        require(!has(account, role), "Roles: account already has role");
        if (role == Role.OPERATOR) {
            _operators[account] = true;
        } else {
            _signers[account] = true;
        }
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function removeSigner(address account, Role role) internal {
        require(has(account, role), "Roles: account does not have role");

        if (role == Role.OPERATOR) {
            _operators[account] = false;
        } else {
            _signers[account] = false;
        }
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(address account, Role role) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");

        // ADMIN,
        // CREATOR,
        // OPERATOR
        return role == Role.OPERATOR ? _operators[account] : _signers[account];
    }

    /**
     * @dev apiMatchId
     * @return uint256
     */
    function apiMatchId(uint256 _fixtureId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return apiMatches[_fixtureId];
    }

    /**
     * @dev _hashId
     * @return info
     */
    function getPlaceBetInfo(bytes32 _hashId)
        public
        view
        virtual
        override
        returns (PlaceBetInfo memory info)
    {
        return placeBetInfoByHash[_hashId];
    }

    /**
     * @dev countMatchs
     * @return uint256
     */
    function countMatchs() public view virtual override returns (uint256) {
        return matchIds.current();
    }

    /**
     * @dev currentMatchId
     * @return uint256
     */
    function matchResultLink(uint256 _matchId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return matches[_matchId].matchResultLink;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

abstract contract MetaBetDomain {
    // flag to determine if contracts core functionalities can be performed
    bool circuitBreaker = false;

    // 体育运动联赛
    mapping(uint256 => League) leagues;

    // holds all NFTs issued to winners
    mapping(uint256 => SmartAsset) smartAssets; // 押注表

    // holds all created matches (key: idCounter)
    mapping(uint256 => Match) matches; // 赛程表
    // holds all bets on a match
    // mapping(matchId => mapping(gameResult => smartAssetId[])) matchBets;
    mapping(uint256 => mapping(MatchResult => uint256[])) matchBets;

    // holds all apiMatchId -> onChain-MatchId to prevent duplicate entries
    // 同一个赛程Id可能从不同的网站获取赔率
    mapping(uint256 => uint256) apiMatches;

    // 用户押注
    mapping(bytes32 => PlaceBetInfo) placeBetInfoByHash;

    enum Role {
        ADMIN,
        CREATOR,
        OPERATOR
    }

    enum AssetType {
        ETH,
        ERC20,
        ERC1155,
        ERC721,
        ERC721Deprecated,
        Chip
    }

    enum MatchResult {
        NOT_DETERMINED,
        DRAW,
        TEAM_A_WON,
        TEAM_B_WON
    }
    enum MatchState {
        NOT_STARTED,
        STARTED,
        FINISHED
    }

    /**
    体育运动联赛
     */
    struct League {
        // 创建者
        address creator;
        // 联赛名称
        string name;
        // 国家
        string country;
        // 联赛logo
        string logo;
        // 标志（是否结束：默认flase）
        bool flag;
    }

    /**
        第一次：createMatch
        第二次：chainLink获取比赛结果后更新
     */
    struct Match {
        // 创建者
        address creator;
        // league编号
        uint256 leagueId;
        // 获取比赛结果链接
        string matchResultLink;
        uint256 totalPayoutTeamA;
        uint256 totalPayoutTeamB;
        uint256 totalPayoutDraw;
        //totalCollected; 每取一笔更新对账结果
        uint256 totalWithDraw;
        // 比赛项目是否存在
        bool exists;
        // raw名称(非team队，默认draw)
        uint8 scoreDraw;
        // A队得分 A 5
        uint8 scoreTeamA;
        // B队得分 scoreB 1
        uint8 scoreTeamB;
        // 最终赢率（含本金） finalOdds
        uint256 finalOdds;
        // 下注Id （最终下注ID）（chainlink取值后查询下注ID）
        uint256 finalAssetId;
        // 比赛信息
        MatchInfo matchInfo;
        // 比赛结果
        MatchResult result;
        // 押注赛程状态
        MatchState state;
    }

    // Match base Info
    struct MatchInfo {
        // draw名称(非team队，默认draw)
        string drawName;
        // teamA队名称
        string teamAName;
        // teamB队名称
        string teamBName;
        // 赢家手续费率 8% winnerfeerate (让玩家自己设置)
        uint256 winnerFeeRate;
        // 比赛开始时间
        uint256 startAt;
        // 押注资产类型
        AssetType assetType;
        // USDC和USDT不写这里，写在公共变量里面，新增发的币可以写在这里
        address payToken;
        uint256 initOddsTeamA;
        uint256 initOddsTeamB;
        uint256 initOddsDraw;
    }

    /**
    用户押注表
     */
    struct SmartAsset {
        // 押注者
        address owner;
        // league编号
        uint256 leagueId;
        // 赛程ID
        uint256 matchId;
        // 押注 哪一方
        MatchResult matchResult;
        // 押注资产信息
        PayAsset betInfo;
        // 实时押注金额信息
        RealTimeAmount realTimeAmount;
        // 累计利息
        uint8 accruedInterest;
        // bet_timestamp :下注时间
        uint256 betTimestamp;
        // 手续费金额
        uint256 feesAmount;
        // withdraw_到手提款金额
        uint256 withdrawAmount;
        // withdraw_timestamp提取时间
        uint256 withdrawTimestamp;
        // 押注team队名称
        string betTeamName;
    }

    /**
    用户押注详情信息
     */
    struct MatchSmartAssetInfo {
        SmartAsset smartAssetInfo;
        Match matchDetail;
    }

    /**
     *押注资产信息
     */
    struct PayAsset {
        // 押注资产类型 ETH 或ERC20 实付币种
        AssetType assetType;
        // USDC
        address payToken;
        // 押注金额
        uint256 payAmount;
    }

    /**
    实时押注金额信息
     */
    struct RealTimeAmount {
        // 实时押注时间节点累计总金额：A
        uint256 totalPayoutTeamA;
        // 实时押注时间节点累计总金额：B
        uint256 totalPayoutTeamB;
        // 实时押注时间节点累计总金额：O
        uint256 totalPayoutDraw;
    }

    /**
     *押注信息详情
     */
    struct PlaceBetInfo {
        // 押注者
        address bettor;
        // 唯一识别码
        bytes32 hashId;
        // 赛程ID
        uint256 matchId;
        // 比赛参与方信息：(主场):(客场):(次场)
        string matchTeamName;
        // 押注team队名称
        string betTeamName;
        // 押注金额
        uint256 payAmount;
        // 押注用户Code
        uint256 userCode;
        // bet_timestamp :下注时间
        uint256 betTimestamp;
        // 最终赢率（含本金） finalOdds
        uint256 finalOdds;
    }

    ////////////////////////////////////////
    //                                    //
    //              MODIFIERS             //
    //                                    //
    ////////////////////////////////////////

    /*
     *  @notice  Ensure league exists
     */
    modifier leagueExists(uint256 _leagueId) {
        require(leagues[_leagueId].flag, "on chain league does not exist");
        _;
    }

    /*
     *  @notice  Ensure match does not previously exist
     */
    modifier isNewMatch(uint256 _matchId) {
        require(!matches[_matchId].exists, "on chain match exists");
        _;
    }

    /*
     *  @notice  Ensure api match does not previously exist
     */
    modifier isNewAPIMatch(uint256 _api_matchId) {
        require(apiMatches[_api_matchId] == 0, "api match ID exists");
        _;
    }

    /*
     *  @notice  Ensure match exists
     */
    modifier matchExists(uint256 _matchId) {
        require(matches[_matchId].exists, "on chain match does not exist");
        _;
    }

    /*
     *  @notice  Ensure match has not started
     */
    modifier matchNotStarted(uint256 _matchId) {
        require(
            matches[_matchId].state == MatchState.NOT_STARTED,
            "match started"
        );
        _;
    }

    /*
     *  @notice  Ensure match has started
     */
    modifier matchStarted(uint256 _matchId) {
        require(
            matches[_matchId].state == MatchState.STARTED,
            "match not started"
        );
        _;
    }

    /*
     *  @notice  Ensure match has ended
     */
    modifier matchFinished(uint256 _matchId) {
        require(
            matches[_matchId].state == MatchState.FINISHED,
            "match not finished"
        );
        _;
    }

    /*
     *  @notice Checks if core functionalities can be performed
     *  @dev Checks if the circuitBreaker state variable is false
     */
    modifier isCircuitBreakOff() {
        require(!circuitBreaker, "Circuit breaker is on");
        _;
    }

    /*
     *  @notice  Ensures bets are allowed on the match
     *  @dev     The totalCollected on the match must be greater than the total payout on the team the bettor wants to bet on. The incoming bet is inclusive in the calculation
     */
    modifier isBetAllowed(uint256 _matchId) {
        require(true, "Bet is not allowed");
        _;
    }

    modifier validateMatchResult(uint8 _matchResult) {
        require(
            MatchResult(_matchResult) == MatchResult.TEAM_A_WON ||
                MatchResult(_matchResult) == MatchResult.TEAM_B_WON ||
                MatchResult(_matchResult) == MatchResult.DRAW,
            "Invalid match result"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./MetaBetDomain.sol";

interface MetaBetInterface {
    ////////////////////////////////////////
    //                                    //
    //              EVENTS                //
    //                                    //
    ////////////////////////////////////////

    //Can be used by the clients to get all Leagues in a particular time
    event LeagueCreatedEvent(
        address indexed creator,
        uint256 indexed leagueId,
        uint256 indexed createdOn,
        MetaBetDomain.League leagueInfo
    );

    event LeagueClosedEvent(
        address indexed by,
        uint256 indexed leagueId,
        uint256 indexed closedAt
    );

    //Can be used by the clients to get all matches in a particular time
    event MatchCreatedEvent(
        address indexed creator,
        uint256 indexed leagueId,
        uint256 matchId,
        uint256 apiMatchId,
        uint256 indexed createdOn,
        MetaBetDomain.MatchInfo info
    );

    //Can be used by the clients to get all bets placed by a better in a particular time
    event BetPlacedEvent(
        address indexed bettor,
        uint256 indexed leagueId,
        uint256 indexed matchId,
        MetaBetDomain.MatchResult result,
        uint256 amount,
        uint256 betPlacedAt,
        MetaBetDomain.AssetType assetType,
        address payToken
    );

    event PlaceBetMatchEvent(
        address indexed bettor,
        bytes32 indexed hashId,
        uint256 indexed matchId,
        // 比赛参与方信息：(主场):(客场):(次场)
        string matchTeamName,
        // 押注team队名称
        string betTeamName,
        // 押注金额
        uint256 payAmount,
        // 押注用户Code
        uint256 userCode,
        // bet_timestamp :下注时间
        uint256 betTimestamp,
        // 最终赢率（含本金） finalOdds
        uint256 finalOdds
    );

    event SmartAssetAwardedEvent(
        address indexed awardee,
        uint256 indexed leagueId,
        uint256 indexed matchId,
        MetaBetDomain.MatchResult result,
        uint256 smartAssetId,
        uint256 awardedAt,
        MetaBetDomain.AssetType assetType,
        address payToken,
        // 实时押注金额信息
        MetaBetDomain.RealTimeAmount realTimeAmount
    );
    event MatchStartEvent(
        address indexed by,
        uint256 indexed leagueId,
        uint256 indexed matchId,
        uint256 startAt
    );
    event MatchClosedEvent(
        address indexed by,
        uint256 indexed leagueId,
        uint256 indexed matchId,
        uint256 closedAt
    );
    event MatchResultSetEvent(
        uint256 indexed leagueId,
        uint256 indexed matchId,
        MetaBetDomain.MatchResult result,
        uint256 setAt,
        uint8 scoreTeamA,
        uint8 scoreTeamB
    );
    event AssetLiquidatedEvent(
        address indexed by,
        uint256 indexed leagueId,
        uint256 indexed matchId,
        uint256 amount,
        uint256 liquidatedAt,
        MetaBetDomain.AssetType assetType,
        address payToken
    );

    /**
     * @dev usercode
     * @return info
     */
    function getPlaceBetInfo(bytes32 _hashId)
        external
        view
        returns (MetaBetDomain.PlaceBetInfo memory info);

    /**
     * @dev apiMatchId
     * @return uint256
     */
    function apiMatchId(uint256 _fixtureId) external view returns (uint256);

    /**
     * @dev countMatchs
     * @return uint256
     */
    function countMatchs() external view returns (uint256);

    /**
     * @dev currentMatchId
     * @return uint256
     */
    function matchResultLink(uint256 _matchId)
        external
        view
        returns (string memory);

    /*
     *  @notice  Match manual start by admin.
     *  @param 以比赛下半场算启动
     *  @return
     */
    function startMatch(uint256 _matchId) external;

    /*
     *  @notice  Match manual close by admin. Trigger "getResult()"
     *  @dev     [Real] ChainlinkClient API Request oracles gets match result of winning team. Then, match is closed.
     *           [Temporary] (Implemented because there's no BSC testnet oracle node)
     *                       Frontend gets result via result link and posts winning team. Then, match is closed.
     *  @param
     *  @return  success success status
     */
    function closeMatch(
        uint256 _matchId,
        uint8 _matchResult,
        uint8 scoreDraw,
        uint8 scoreTeamA,
        uint8 scoreTeamB
    ) external;

    /*
     *  @notice  Fetch match details
     *  @dev
     *  @oaram   _matchId
     *  @return match match details
     */
    function getMatch(uint256 _matchId)
        external
        view
        returns (MetaBetDomain.Match memory match_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MetaBetDomain.sol";

library MetaBetLib {
    using SafeMath for uint256;

    function calculateAssetOdds(
        uint256 _oddsWin,
        uint256 _oddsFailOne,
        uint256 _oddsFailTwo
    ) internal pure returns (uint256) {
        return
            _oddsWin
                .add(_oddsFailOne)
                .mul(100000000000000000)
                .div(_oddsFailTwo)
                .add(100000000000000000);
    }

    function calculateAssetValue(uint256 _amountBet, uint256 _odds)
        internal
        pure
        returns (uint256)
    {
        return _amountBet.mul(_odds).div(100);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract MetaWallet {
    // 支持充值token
    IERC20 erc20Token;

    // 币种列表
    address[] tokens;

    // 币种记录表
    mapping(address => bool) supportTokens;

    // Token Balance = 蓝钻数量
    mapping(address => uint256) tokenBalance;

    /* Allow users to deposit Tokens */
    function deposit(uint256 _amount) public payable {
        // require(_amount <= MAX_DEPOSIT, "Cannot deposit more than 999999");
        require(_amount > 0, "Cannot deposit 0");

        require(erc20Token.transferFrom(msg.sender, address(this), _amount));
        tokenBalance[msg.sender] = tokenBalance[msg.sender] + _amount;
    }

    /* Allow users to withdraw Tokens */
    function withdraw(uint256 _amount) public {
        require(
            _amount <= tokenBalance[msg.sender],
            "Cannot withdraw more than account balance"
        );
        require(_amount > 0, "Cannot withdraw 0");

        require(erc20Token.transfer(msg.sender, _amount));
        tokenBalance[msg.sender] = tokenBalance[msg.sender] - _amount;
    }

    /**
    添加新币种
     */
    function addToken(address token) internal {
        if (token != address(0) && supportTokens[token] != true) {
            supportTokens[token] = true;
            tokens.push(token);
        }
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