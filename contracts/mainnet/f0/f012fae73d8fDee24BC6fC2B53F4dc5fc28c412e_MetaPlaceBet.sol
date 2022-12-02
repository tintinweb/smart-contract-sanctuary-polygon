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
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @notice SmartBet core smart contract. Handles matches, bets and farming
 */
contract MetaPlaceBet is Context, Ownable {
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
     *押注信息提现详情
     */
    struct WithdrawInfo {
        // 押注者
        address bettor;
        // 唯一识别码
        bytes32 hashId;
        // 赛程ID
        uint256 matchId;
        // 赢家手续费率 8% winnerfeerate (让玩家自己设置)
        uint256 winnerFeeRate;
        // 手续费金额
        uint256 feesAmount;
        // withdraw_到手提款金额
        uint256 withdrawAmount;
        // withdraw_timestamp提取时间
        uint256 withdrawTimestamp;
        // 最终赢率（含本金） finalOdds
        uint256 finalOdds;
        // 最终押注总金额
        RealTimeAmount finalTotalAmount;
    }

    ////////////////////////////////////////
    //                                    //
    //         STATE VARIABLES            //
    //                                    //
    ////////////////////////////////////////
    // 用户押注
    mapping(bytes32 => PlaceBetInfo) placeBetInfoByHash;
    // 用户金额提现
    mapping(bytes32 => WithdrawInfo) withdrawInfoByHash;

    ////////////////////////////////////////
    //                                    //
    //              EVENTS                //
    //                                    //
    ////////////////////////////////////////
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

    event WithdrawEvent(
        address indexed bettor,
        bytes32 indexed hashId,
        uint256 indexed matchId,
        // 赢家手续费率 8% winnerfeerate (让玩家自己设置)
        uint256 winnerFeeRate,
        // 手续费金额
        uint256 feesAmount,
        // withdraw_到手提款金额
        uint256 withdrawAmount,
        // withdraw_timestamp提取时间
        uint256 withdrawTimestamp,
        // 最终赢率（含本金） finalOdds
        uint256 finalOdds,
        // 最终押注总金额
        RealTimeAmount finalTotalAmount
    );

    ////////////////////////////////////////
    //                                    //
    //           CONSTRUCTOR              //
    //                                    //
    ////////////////////////////////////////
    constructor() {}

    ////////////////////////////////////////
    //                                    //
    //              FUNCTIONS             //
    //                                    //
    ////////////////////////////////////////

    /**
     *  @notice  placeBetMatch
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

    /**
     *  @notice  withdraw
     *  @dev
     *  @param
     */
    function withdraw(
        bytes32 _hashId,
        uint256 _matchId,
        // 赢家手续费率 8% winnerfeerate (让玩家自己设置)
        uint256 _winnerFeeRate,
        // 手续费金额
        uint256 _feesAmount,
        // withdraw_到手提款金额
        uint256 _withdrawAmount,
        // 最终赢率（含本金） finalOdds
        uint256 _finalOdds,
        // 最终押注总金额
        RealTimeAmount calldata _finalTotalAmount
    ) public onlyOwner {
        withdrawInfoByHash[_hashId] = WithdrawInfo(
            _msgSender(),
            _hashId,
            _matchId,
            _winnerFeeRate,
            _feesAmount,
            _withdrawAmount,
            block.timestamp,
            _finalOdds,
            _finalTotalAmount
        );

        emit WithdrawEvent(
            _msgSender(),
            _hashId,
            _matchId,
            _winnerFeeRate,
            _feesAmount,
            _withdrawAmount,
            block.timestamp,
            _finalOdds,
            _finalTotalAmount
        );
    }

    /**
     * @dev _hashId
     * @return info
     */
    function getPlaceBetInfo(bytes32 _hashId)
        public
        view
        virtual
        returns (PlaceBetInfo memory info)
    {
        return placeBetInfoByHash[_hashId];
    }

    /**
     * @dev _hashId
     * @return info
     */
    function getWithdraw(bytes32 _hashId)
        public
        view
        virtual
        returns (WithdrawInfo memory info)
    {
        return withdrawInfoByHash[_hashId];
    }

    receive() external payable {}
}