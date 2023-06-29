// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IOtter.sol";
import "./OtterManager.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
    @dev Otter合约
 */
contract Otter is IOtter, OtterManager {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    uint256 public constant TIMELOCK_DAY = 30 minutes;

    /// MAX_RAFTS代表一个Stream允许的最大Raft数量
    uint256 public constant MAX_RAFTS = 10;

    /// _nonce 递增，用于计算位移StreamId
    CountersUpgradeable.Counter private _nonce;

    /// _streams 存储当前的Stream列表
    mapping(bytes32 => Stream) private _streams;
    /// _rafts 存储当前所有的Raft
    /// raft id = keccak256(abi.encodePacked(_streamId, _raftIndex))
    mapping(bytes32 => Raft) private _rafts;
    // _investors 记录当前raft下所有的投资者
    mapping(bytes32 => Investor[]) private _investors;
    // _investorsIndexes 记录当前raft下所有的投资者对应的索引
    mapping(bytes32 => mapping(address => uint256)) private _investorsIndexes;

    // _streamTerms 记录Stream的返还收益的周期
    mapping(bytes32 => Term[]) private _streamTerms;

    // _profits RAFT所有的收益记录
    mapping(bytes32 => RaftProfit[]) private _profits;
    // _profitsMapper 记录 (raftId => (term => index))
    mapping(bytes32 => mapping(uint256 => uint256)) private _profitsMapper;

    Transfer[] private _transfers;
    Exit[] private _exits;

    /// USDC合约(ERC20 Compatiable)
    IERC20Upgradeable private _usdc;

    /// @dev 用于Otter合约的初始化
    /// @param _usdcContract USDC合约地址
    function initialize(address _usdcContract) public initializer {
        __OtterManagerInit();
        _usdc = IERC20Upgradeable(_usdcContract);
    }

    event AddStream(
        string name,
        bytes32 streamId,
        address organizer,
        uint256 capacity,
        bytes32[] raftIds,
        uint256[] rafts
    );

    function getTimelock() public pure override returns (uint256) {
        return TIMELOCK_DAY;
    }

    /// @dev 添加一个新的Stream
    /// @param _name stream名称
    /// @param _capacity stream总量
    /// @param _raftsInStream stream中的raft数量和各自的份额
    /// @param _reserveRate 收益留存率
    /// @param _firstWithdrawRate 首次提取留存率
    /// @return steamId stream的唯一id
    function addStream(
        string memory _name,
        uint256 _capacity,
        uint256[] memory _raftsInStream,
        uint256 _reserveRate,
        uint256 _firstWithdrawRate
    ) public override returns (bytes32) {
        address _organizer = msg.sender;

        bytes32 streamId = _beforeAddStream(
            _organizer,
            _capacity,
            _raftsInStream,
            _reserveRate,
            _firstWithdrawRate
        );

        bytes32[] memory raftIds = _addStream(streamId, _capacity, _raftsInStream);

        _afterAddStream(
            _name,
            streamId,
            _organizer,
            _capacity,
            _raftsInStream.length,
            _reserveRate,
            _firstWithdrawRate
        );

        emit AddStream(_name, streamId, _organizer, _capacity, raftIds, _raftsInStream);

        return streamId;
    }

    function _beforeAddStream(
        address _organizer,
        uint256 _capacity,
        uint256[] memory _raftsInStream,
        uint256 _reserveRate,
        uint256 _firstWithdrawRate
    ) internal returns (bytes32) {
        require(_capacity > 0, "capacity must > 0");
        require(_raftsInStream.length > 0, "raftcount must > 0");
        require(_raftsInStream.length <= MAX_RAFTS, "excceedes MAX_RAFTS(10)");

        require(_reserveRate < MAX_RATE, "invalid reserve ratio");
        require(_firstWithdrawRate < MAX_RATE, "invalid first ratio");

        return _nextStreamId(_organizer);
    }

    function _addStream(
        bytes32 _streamId,
        uint256 _capacity,
        uint256[] memory _raftsInStream
    ) internal returns (bytes32[] memory) {
        uint256 total;
        bytes32[] memory raftIds = new bytes32[](_raftsInStream.length);
        for (uint256 i = 0; i < _raftsInStream.length; i++) {
            Raft memory raft;
            raft.stream = _streamId;
            raft.capacity = _raftsInStream[i];

            if (i == 0) {
                raft.status = RaftStatus.Joinable;
            } else {
                raft.status = RaftStatus.Unopen;
            }

            bytes32 _raftId = _calculateRaftId(_streamId, i);
            _rafts[_raftId] = raft;
            raftIds[i] = _raftId;

            total = total + _raftsInStream[i];
        }
        require(total == _capacity, "stream's capacity mistmatch with the sum(rafts)");
        return raftIds;
    }

    function _afterAddStream(
        string memory _name,
        bytes32 _streamId,
        address _organizer,
        uint256 _capacity,
        uint256 _raftCount,
        uint256 _reserveRate,
        uint256 _firstWithdrawRate
    ) internal {
        Stream memory stream;
        stream.name = keccak256(bytes(_name));
        stream.capacity = _capacity;
        stream.organizer = _organizer;
        stream.status = StreamStatus.Joinable;

        stream.earningRafts = 0;
        stream.currentJoinableRaft = 0;
        stream.totalRafts = _raftCount;

        stream.reserveRate = _reserveRate;
        stream.firstWithdrawRate = _firstWithdrawRate;

        _streams[_streamId] = stream;
    }

    function _getRaft(bytes32 _streamId, uint256 _raftIndex) internal view returns (Raft memory) {
        return _rafts[_calculateRaftId(_streamId, _raftIndex)];
    }

    function _getRaft(bytes32 _raftId) internal view returns (Raft memory) {
        return _rafts[_raftId];
    }

    function _calculateRaftId(bytes32 _streamId, uint256 _raftIndex)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_streamId, _raftIndex));
    }

    function getInvestor(bytes32 _raftId, address _investor)
        public
        override
        returns (uint256, Investor memory)
    {
        (uint256 index, Investor memory investor) = _getInvestor(_raftId, _investor);
        return (index, investor);
    }

    function _getInvestor(bytes32 _raftId, address _investor)
        internal
        returns (uint256, Investor storage)
    {
        Investor[] memory raftInvestors = _investors[_raftId];
        uint256 index = _investorsIndexes[_raftId][_investor];
        /*if (raftInvestors.length != 0 && _investors[_raftId][index].account != address(_investor)) {
            index = _newInvestor(_raftId, _investor);
        }

        if (raftInvestors.length == 0) {
            index = _newInvestor(_raftId, _investor);
        }*/
        if (raftInvestors.length == 0 || _investors[_raftId][index].account != _investor) {
            index = _newInvestor(_raftId, _investor);
        }

        return (index, _investors[_raftId][index]);
    }

    function _newInvestor(bytes32 _raftId, address _investor) internal returns (uint256) {
        Investor memory newInvestor;
        newInvestor.account = _investor;
        _investorsIndexes[_raftId][_investor] = _investors[_raftId].length;
        _investors[_raftId].push(newInvestor);
        return _investors[_raftId].length - 1;
    }

    function clear(bytes32 _streamId, bytes32 _raftId) public {
        _clearing(_streamId, _raftId, msg.sender);
    }

    event Clearing(bytes32 stream, bytes32 raftId, address investor, uint256 earning);

    // 清算期间，没有transfer/exit(每次transfer/exit都直接清算)
    // 只需要再扣除一个准入的收益差额
    function _clearing(
        bytes32 _streamId,
        bytes32 _raftId,
        address _investor
    ) internal {
        (, Investor storage investor) = _getInvestor(_raftId, _investor);

        uint256 currCalTerm = investor.lastCalTerm;
        uint256 lastCalTime = investor.lastCalTime;

        uint256 earning;
        uint256 _days;
        (Term memory lastTerm, ) = _getLastTerm(_streamId);

        for (; currCalTerm <= lastTerm.index; currCalTerm++) {
            Term memory term = _streamTerms[_streamId][currCalTerm];
            // 1. 计算当前时间相对周期开始时间，已经过了多久
            // 1.1 如果是最后一个结算周期,则计算当前时间和周期的开始时间差值,获得 elapsed days
            if(lastCalTime==0){
                _days = (block.timestamp - term.startAt) / TIMELOCK_DAY;
                lastCalTime = block.timestamp;
            }else if (term.index == lastTerm.index) {
                _days = (block.timestamp - lastCalTime) / TIMELOCK_DAY;
                lastCalTime = block.timestamp;
            } else {
                // 1.2 如果不是最后一个计算周期,则通过周期结束时间和上一次结算的时间，获得elapsed days
                _days = (term.endAt - lastCalTime) / TIMELOCK_DAY;
                lastCalTime = term.endAt;
            }
            // 1.3 周期中的days最大不超过RELEASE_PERIOD(30days)
            if (_days > RELEASE_PERIOD) {
                _days = RELEASE_PERIOD;
            }

            // 2. 计算差额(直接转给otter)
            uint256 realContribution = investor.contribution;
            uint256 margin;
            for (uint256 indexIn = 0; indexIn < investor.transferIns.length; indexIn++) {
                Transfer memory tin = _transfers[investor.transferIns[indexIn]];
                // 每次transfer在当前周期前发生，需要计算差额
                if (tin.term > currCalTerm) {
                    continue;
                }
                // 如果是当前周期转出，则不应该放在本周期的收益计算中
                if (tin.term == currCalTerm) {
                    realContribution -= tin.amount;
                    continue;
                }

                // 计算差额:  trasfer时的每股收益 * 转移数量 * 损失时间
                margin = margin + _days * tin.profitPerShare * tin.amount;
            }

            if (margin > 0) {
                _transferTo(otterManager(), margin);
            }

            // 3. 计算investor此次结算时，在此周期的收益
            RaftProfit storage _profit = _getRaftProfit(currCalTerm, _raftId);
            uint256 totalContribution = _rafts[_raftId].contribution;

            uint256 thisProfit = (realContribution * _profit.amount * _days) /
                totalContribution /
                RELEASE_PERIOD;

            // 4. 扣除差额
            earning = earning + thisProfit - margin;
        }

        emit Clearing(_streamId, _raftId, _investor, earning);
        investor.lastCalTerm = lastTerm.index;
        investor.lastCalTime = block.timestamp;
        investor.totalEarned = investor.totalEarned + earning;
        investor.undrawnEarnings = investor.undrawnEarnings + earning;
    }


    event JoinStream(bytes32 streamId, bytes32 raftId, address investor, uint256 amount);
    event RaftEarning(bytes32 streamId, bytes32 raftId, uint256 raftIndex);

    /// @dev 用户发起对Stream下某个raft的投资
    /// @param _streamId stream对应的id
    /// @param _raftId  要投资的raft id
    /// @param _amount 要投资的USDC数量
    /// @return bool 是否投资成功
    function joinStream(
        bytes32 _streamId,
        bytes32 _raftId,
        uint256 _amount
    ) public override returns (bool) {
        address investor = msg.sender;

        _transferToOtterContract(_amount);

        Stream storage stream = _streams[_streamId];
        require(stream.organizer != address(0), "stream not exist");

        (
            RaftStatus status,
            uint256 currentContribution,
        ) = _joinOnRaft(_streamId, _raftId, investor, _amount);

        // increase stream's total contriution if Raft is Earning
        if (status == RaftStatus.Earning) {
            stream.undrawnContribution = stream.undrawnContribution + currentContribution;
            stream.contribution = stream.contribution + currentContribution;
            stream.earningRafts = stream.earningRafts + 1;
            emit RaftEarning(_streamId, _raftId, stream.currentJoinableRaft);
        }

        // set next raft to `Joinable`
        if (status == RaftStatus.Earning && stream.totalRafts > stream.currentJoinableRaft + 1) {
            stream.currentJoinableRaft++;
            bytes32 currentRaftId = _calculateRaftId(_streamId, stream.currentJoinableRaft);
            Raft storage raft = _rafts[currentRaftId];
            raft.status = RaftStatus.Joinable;
        }

        // when any raft is Earning,stream will be at Earning status
        if (status == RaftStatus.Earning && stream.status == StreamStatus.Joinable) {
            stream.status = StreamStatus.Earning;
            stream.firstEarningDate = block.timestamp;
        }

        emit JoinStream(_streamId, _raftId, investor, _amount);

        return true;
    }

    function _joinOnRaft(
        bytes32 _streamId,
        bytes32 _raftId,
        address _investor,
        uint256 _amount
    )
        internal
        returns (
            RaftStatus,
            uint256,
            uint256
        )
    {
        Raft storage raft = _rafts[_raftId];
        require(raft.stream == _streamId, "raft not in this stream");
        require(raft.status == RaftStatus.Joinable, "raft not joinable");

        uint256 available = raft.capacity - raft.contribution;
        require(available >= _amount, "exceedes the raft capacity");

        raft.contribution = raft.contribution + _amount;

        if (raft.contribution == raft.capacity) {
            raft.status = RaftStatus.Earning;
        }

        (, Investor storage investor) = _getInvestor(_raftId, _investor);
        investor.contribution = investor.contribution + _amount;

        return (raft.status, raft.contribution, investor.contribution);
    }

    function getExitableAmount(
        bytes32 _streamId,
        bytes32 _raftId,
        address _investor
    ) public override returns (uint256) {
        Stream memory stream = _streams[_streamId];
        (, Investor memory investor) = _getInvestor(_raftId, _investor);
        return (investor.contribution * stream.reserve) / stream.capacity;
    }

    event ExitStream(bytes32 streamId, bytes32 raftId, address investor, uint256 amount);

    /// @dev 用户退出部分RAFT投资
    /// @param _streamId Stream的ID
    /// @param _raftId raft的ID
    /// @param _amount 退出的份额数量
    function exitStream(
        bytes32 _streamId,
        bytes32 _raftId,
        uint256 _amount
    ) public override {
        (, Investor storage investor) = _getInvestor(_raftId, msg.sender);
        require(
            investor.contribution >= _amount,
            "withdraw amount cannot exceedes investor's conribution"
        );

        Raft memory raft = _rafts[_raftId];
        require(raft.stream == _streamId, "raft and stream mismatch");
        require(raft.status == RaftStatus.Earning, "raft not earning yet");

        Stream storage stream = _streams[_streamId];

        // 可退出额度计算
        require(
            (investor.contribution * stream.reserve) / stream.capacity >= _amount,
            "withdrawable amount not enough"
        );

        // 清算之前的收益
        _clearing(_streamId, _raftId, msg.sender);

        // 记录退出，并计算未到账收益应转给平台部分
        _clearExit(_raftId, _amount);

        // 更新
        stream.contribution = stream.contribution - _amount;
        raft.contribution = raft.contribution - _amount;
        stream.reserve = stream.reserve - _amount;
        investor.contribution = investor.contribution - _amount;

        // 提取到investor地址
        _transferTo(msg.sender, _amount);

        emit ExitStream(_streamId, _raftId, msg.sender, _amount);
    }

    function _clearExit(bytes32 _raftId, uint256 _exitAmount) internal {
        Raft memory raft = _getRaft(_raftId);
        (, Investor storage investor) = _getInvestor(_raftId, msg.sender);

        Exit memory exit;
        exit.investor = msg.sender;
        exit.stream = raft.stream;
        exit.raft = _raftId;
        exit.exitAt = block.timestamp;
        exit.amount = _exitAmount;

        (Term memory lastTerm, ) = _getLastTerm(raft.stream);
        exit.term = lastTerm.index;

        // 如果是在收益周期内，则需要处理给manager的损失
        if (block.timestamp < lastTerm.endAt && block.timestamp >= lastTerm.startAt) {
            uint256 lostDays = (lastTerm.endAt - block.timestamp + TIMELOCK_DAY) / TIMELOCK_DAY;
            if(lostDays > RELEASE_PERIOD){
                lostDays = RELEASE_PERIOD;
            }
            
            uint256 pi = _profitsMapper[_raftId][lastTerm.index];
            RaftProfit memory profit = _profits[_raftId][pi];

            // (损失占比)*退出前日收益*未到账收益天数
            uint256 toOtterAmount = (_exitAmount * profit.amount * lostDays) /
                raft.contribution /
                RELEASE_PERIOD;

            _transferTo(otterManager(), toOtterAmount);
        }

        _exits.push(exit);
        investor.exits.push(_exits.length - 1);
    }

    // User(Investor)
    event TransferInvestment(
        bytes32 streamId,
        bytes32 raftId,
        uint256 term,
        address from,
        address to,
        uint256 amount
    );

    /// @dev 用户转让其下Raft部分份额到其他用户
    /// @param _raftId RAFT的ID
    /// @param _toInvestor 转入用户地址
    /// @param _amount 转让的份额数量
    function transferInvestment(
        bytes32 _raftId,
        address _toInvestor,
        uint256 _amount
    ) public override {
        require(_toInvestor != address(0), "zero investor address");
        require(_amount > 0, "can not be zero amount");
        (, Investor storage fromInvestor) = _getInvestor(_raftId, msg.sender);
        require(fromInvestor.contribution >= _amount, "contribution not enough");

        (, Investor storage toInvestor) = _getInvestor(_raftId, _toInvestor);

        Raft memory raft = _rafts[_raftId];
        (Term memory lastTerm, ) = _getLastTerm(raft.stream);

        // 清算fromInvestor的收益
        _clearing(raft.stream, _raftId, msg.sender);
        // 清算toVestor的收益
        _clearing(raft.stream, _raftId, _toInvestor);

        // 存储Transfer信息
        Transfer memory trans;
        trans.from = msg.sender;
        trans.to = _toInvestor;
        trans.term = lastTerm.index;
        trans.stream = raft.stream;
        trans.raft = _raftId;
        trans.amount = _amount;
        trans.transferedAt = block.timestamp;
        trans.profitPerShare = raft.profitPerShare;

        // 如果是在收益周期内，则需要处理给manager的损失
        if (block.timestamp < lastTerm.endAt && block.timestamp >= lastTerm.startAt) {
            uint256 lostDays = (lastTerm.endAt - block.timestamp + TIMELOCK_DAY) / TIMELOCK_DAY;
            if(lostDays > RELEASE_PERIOD){
                lostDays = RELEASE_PERIOD;
            }

            uint256 pi = _profitsMapper[_raftId][lastTerm.index];
            RaftProfit memory profit = _profits[_raftId][pi];

            // (损失占比)*退出前日收益*未到账收益天数
            uint256 toOtterAmount = (_amount * profit.amount * lostDays) /
                raft.contribution /
                RELEASE_PERIOD;
            _transferTo(otterManager(), toOtterAmount);
        }

        // 更新
        _transfers.push(trans);
        fromInvestor.transferOuts.push(_transfers.length - 1);
        fromInvestor.contribution = fromInvestor.contribution - _amount;
        toInvestor.transferIns.push(_transfers.length - 1);
        toInvestor.contribution = toInvestor.contribution + _amount;

        emit TransferInvestment(
            raft.stream,
            _raftId,
            lastTerm.index,
            msg.sender,
            _toInvestor,
            _amount
        );
    }

    event WithdrawnProfit(
        bytes32 raftId,
        address investor,
        uint256 amount,
        uint256 undrawnEarnings
    );

    /// @dev 用户提取部分收益
    /// @param _raftId RAFT的ID
    /// @param _amount 提取的收益数量
    function withdrawProfit(bytes32 _raftId, uint256 _amount) public override {
        Raft memory raft = _rafts[_raftId];
        require(raft.status == RaftStatus.Earning, "raft not earning");

        _clearing(raft.stream, _raftId, msg.sender);

        (uint256 index, Investor memory investor) = _getInvestor(_raftId, msg.sender);

        // withdraw USDCs
        require(investor.undrawnEarnings >= _amount, "do not have enough undrawn earnings");

        uint256 fee = caculateWithdrawFee(OTTER_USER, _amount);

        _transferTo(msg.sender, _amount - fee);
        _transferTo(otterManager(), fee);

        investor.undrawnEarnings = investor.undrawnEarnings - _amount;

        _investors[_raftId][index] = investor;

        emit WithdrawnProfit(_raftId, msg.sender, _amount, investor.undrawnEarnings);
    }

    event Withdraw(bytes32 steamId, uint256 amount, uint256 fee, uint256 reserved);

    /// @dev Stream组织者提取用户贡献的USDC资金
    /// @param _streamId 要提取的Stream id
    /// @param _amount 提取的资金数量
    function withdraw(bytes32 _streamId, uint256 _amount) public override {
        Stream storage stream = _streams[_streamId];
        require(stream.organizer == msg.sender, "only stream's organizer can withdraw");
        require(stream.undrawnContribution >= _amount, "undrawnContribution not enough");

        uint256 fee = caculateWithdrawFee(OTTER_ORGANIZER, _amount);

        uint256 reserve;
        // keep some usdc as reserved at the first time
        if (!stream.withdrawed) {
            reserve = (_amount * stream.firstWithdrawRate) / MAX_RATE;
            stream.withdrawed = true;
        }

        // transfer usdc to organizer
        require(_transferTo(msg.sender, _amount - fee - reserve), "transfer usdc to organizer");

        // transfer fee to otter manager
        require(_transferTo(otterManager(), fee), "transfer fee to otter manager");

        stream.reserve = stream.reserve + reserve;
        stream.undrawnContribution = stream.undrawnContribution - _amount;

        emit Withdraw(_streamId, _amount, fee, reserve);
    }

    // Organizer refund profit to investors
    // 每次返回收益时，清算上一次收益
    event ReturnProfit(
        bytes32 streamId,
        uint256 term,
        uint256 profit,
        uint256 startAt,
        uint256 endAt
    );

    /// @dev Stream组织者返还收益
    /// @param _streamId 要提取的Stream id
    /// @param _profit 返还的USDC数量
    /// @param _startAt 返利开始时间
    /// @return uint256 stream下返还利润周期的index
    function returnProfit(
        bytes32 _streamId,
        uint256 _profit,
        uint256 _startAt
    ) public override returns (uint256) {
        require(_profit > 0, "zero profit not allowed");
        Stream storage stream = _streams[_streamId];
        require(stream.organizer == msg.sender, "only stream's organizer can return profit");
        require(stream.withdrawed, "can't return profit before first time withdraw contribution");

        // make sure current term finished
        (Term memory lastTerm, uint256 length) = _getLastTerm(_streamId);
        // last term mut finished
        require(
            length == 0 || lastTerm.endAt < block.timestamp,
            "curren stream term not finished yet"
        );

        _transferToOtterContract(_profit);

        // calculate reserved profit
        uint256 reserved = (_profit * stream.reserveRate) / MAX_RATE;
        if (stream.reserve + reserved > stream.contribution) {
            reserved = stream.contribution - stream.reserve;
        }

        // save reserved USDC
        stream.reserve = stream.reserve + reserved;

        // save total USDC
        stream.cumulativeProfit = stream.cumulativeProfit + _profit;

        Term memory term;
        term.index = stream.term++;
        term.earningRafts = stream.earningRafts;
        term.profit = _profit - reserved;

        term.startAt = _startAt;
        term.endAt = _startAt + RELEASE_PERIOD * TIMELOCK_DAY;

        _streamTerms[_streamId].push(term);

        _returnProfitToRafts(_streamId, term);
        emit ReturnProfit(_streamId, term.index, _profit, term.startAt, term.endAt);

        return term.index;
    }

    function _returnProfitToRafts(bytes32 streamId, Term memory term) internal {
        uint256 profitPerRaft = term.profit / term.earningRafts;
        uint256 accuracyLoss = term.profit - profitPerRaft * term.earningRafts;
        uint256 earningRaftsTolCap = 0;
        for (uint256 index = 0; index < term.earningRafts; index++) {
            bytes32 _raftId = _calculateRaftId(streamId, index);
            Raft storage raft = _rafts[_raftId];
            require(raft.status == RaftStatus.Earning, "raft is not earning");

            if (index + 1 == term.earningRafts) {
                profitPerRaft = profitPerRaft + accuracyLoss;
            }

            // update raft
            raft.totalProfit = raft.totalProfit + profitPerRaft;
            raft.profitPerShare = raft.profitPerShare + profitPerRaft / raft.capacity;

            // save raft profit share
            RaftProfit memory profit;
            profit.term = term.index;
            profit.amount = profitPerRaft;
            _profits[_raftId].push(profit);
            _profitsMapper[_raftId][term.index] = _profits[_raftId].length - 1;

            earningRaftsTolCap = earningRaftsTolCap + raft.capacity;
        }
        term.earnRaftsCapacity = term.profit / earningRaftsTolCap;
    }

    function _getRaftProfit(uint256 term, bytes32 _raftId)
        internal
        view
        returns (RaftProfit storage)
    {
        uint256 index = _profitsMapper[_raftId][term];
        return _profits[_raftId][index];
    }

    /// @dev 转移USDC到当前Otter合约
    /// @param _amount 转账数量
    function _transferToOtterContract(uint256 _amount) internal {
        require(_usdc.transferFrom(msg.sender, address(this), _amount), "Do no have enough USDC");
    }

    /// @dev 从otter合约转移USDC到某个账户地址
    /// @param _account 账户地址
    /// @param _amount 转移数量
    /// @return bool 返回校验结果
    function _transferTo(address _account, uint256 _amount) internal returns (bool) {
        return _usdc.transfer(_account, _amount);
    }

    /// @dev 计算下一个StreamId
    /// @param _organizer stream的组织者地址
    /// @return bytes32 streamId
    function _nextStreamId(address _organizer) internal returns (bytes32) {
        _nonce.increment();
        return keccak256(abi.encodePacked(_organizer, _nonce.current()));
    }

    /// @dev 通过stream id查看Stream
    /// @param _streamId stream对应的id
    /// @return Stream stream详细信息
    function getStream(bytes32 _streamId) public view override returns (Stream memory) {
        Stream memory stream = _streams[_streamId];
        require(stream.organizer != address(0), "stream not found");
        return stream;
    }

    /// @dev 通过stream id查看Stream下所有的收益返还周期
    /// @param _streamId stream对应的id
    /// @return Term[] 收益返还周期列表
    function getTerms(bytes32 _streamId) public view override returns (Term[] memory) {
        return _streamTerms[_streamId];
    }

    /// @dev 查看某stream下所有的raft
    /// @return Raft[] raft列表
    function getRafts(bytes32 _streamId) public view override returns (Raft[] memory) {
        Stream memory stream = getStream(_streamId);
        Raft[] memory rafts = new Raft[](stream.totalRafts);
        for (uint256 index = 0; index < stream.totalRafts; index++) {
            bytes32 raftId = _calculateRaftId(_streamId, index);
            Raft memory raft = _rafts[raftId];
            raft.raftId = raftId;
            rafts[index] = raft;
        }
        return rafts;
    }

    /// @dev 查询当前所有的transfer
    /// @return Transfer[] transfer列表
    function getTransfers() public view override returns (Transfer[] memory) {
        return _transfers;
    }

    /// @dev 查询某RAFT下investor列表
    /// @param _raftId raft id
    /// @return Investor[]  返回investor列表
    function getInvestors(bytes32 _raftId) public view override returns (Investor[] memory) {
        return _investors[_raftId];
    }

    function _getTerm(bytes32 _streamId, uint256 index) internal view returns (Term memory) {
        Term[] memory terms = _streamTerms[_streamId];
        Term memory term;
        if (terms.length == 0) {
            return term;
        }
        return terms[index];
    }

    function _getLastTerm(bytes32 _streamId) internal view returns (Term memory, uint256) {
        Term[] memory terms = _streamTerms[_streamId];
        Term memory term;
        if (terms.length == 0) {
            return (term, 0);
        }
        return (terms[terms.length - 1], terms.length);
    }

    function getRaftProfit(bytes32 _raftId, uint256 index) public view returns (RaftProfit memory) {
        return _profits[_raftId][index];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IOtterManager.sol";

interface IOtter is IOtterManager {
    enum StreamStatus {
        Joinable,
        Earning
    }

    struct Stream {
        bytes32 name;
        address organizer;
        uint256 createdAt;
        uint256 capacity;
        StreamStatus status;
        uint256 currentJoinableRaft;
        uint256 earningRafts;
        // total rafts
        uint256 totalRafts;
        uint256 firstEarningDate;
        uint256 reserveRate;
        uint256 firstWithdrawRate;
        // 项目保证金
        uint256 reserve;
        // 返还的收益
        uint256 term; // 利益返回最新周期(start from 0)
        uint256 cumulativeProfit;
        // 2442/100 = 24.22%
        uint256 expectedAPY;
        uint256 actuaAPY;
        // total contribution
        uint256 contribution;
        // withdrawed means organizer already started to withdraw the contribution
        bool withdrawed;
        // contibution which is undrawn
        uint256 undrawnContribution;
    }

    struct Term {
        uint256 index;
        uint256 earningRafts;
        uint256 profit;
        uint256 startAt;
        uint256 endAt;
        uint256 earnRaftsCapacity;
    }

    // (amount - cleared) => otter manager
    struct RaftProfit {
        uint256 term;
        uint256 amount;
        uint256 cleared; // by investors
        bool managerCleared; // by otter manager
    }

    enum RaftStatus {
        Unopen,
        Joinable,
        Earning
    }

    struct Raft {
        bytes32 stream;
        uint256 capacity;
        uint256 contribution;
        uint256 totalProfit;
        uint256 profitPerShare;
        RaftStatus status;
        bytes32 raftId;
    }

    struct Transfer {
        address from;
        address to;
        uint256 term;
        bytes32 stream;
        bytes32 raft;
        uint256 amount;
        uint256 profitPerShare;
        uint256 transferedAt;
    }

    function getTransfers() external view returns (Transfer[] memory);

    struct Exit {
        address investor;
        uint256 term;
        bytes32 stream;
        bytes32 raft;
        uint256 amount;
        uint256 beforeContribution;
        uint256 afterContribution;
        uint256 afterrofitPerDay;
        uint256 exitAt;
    }

    /// investor收益计算需要考虑多个情况：
    /// - 用户中途退出部分投资 (contibutionAtTermStart - contribution)
    /// - 用户中途向其他用户转出了部分投资(transfer out)
    /// - 用户中途接收到了其他用户的部分投资(transfer in)
    /// 即用户当前的投资总额： contribution + ins - outs
    struct Investor {
        address account;
        uint256 contribution;
        uint256 totalEarned;
        uint256 undrawnEarnings;
        uint256 lastCalTerm;
        uint256 lastCalTime;
        uint256[] transferIns;
        uint256[] transferOuts;
        uint256[] exits;
    }

    function getTimelock() external view returns(uint256);

    function getStream(bytes32 _streamId) external view returns (Stream memory);

    function getRafts(bytes32 _streamId) external view returns (Raft[] memory);

    function getTerms(bytes32 _streamId) external view returns (Term[] memory);

    function getExitableAmount(bytes32 _streamId,bytes32 _raftId,address _investor) external returns(uint256);

    function getInvestor(bytes32 _raftId, address _investor) external returns(uint256,Investor memory);

    function getInvestors(bytes32 _raftId) external view returns (Investor[] memory);

    function addStream(
        string memory _name,
        uint256 _capacity,
        uint256[] memory _raftsInStream,
        uint256 _reserveRatio,
        uint256 _firstWithdrawRate
    ) external returns (bytes32);

    // User(Investor)
    function joinStream(
        bytes32 _streamId,
        bytes32 _raftIndex,
        uint256 _amount
    ) external returns (bool);

    function exitStream(
        bytes32 _streamId,
        bytes32 _raftId,
        uint256 _amount
    ) external;

    function transferInvestment(
        bytes32 _raftId,
        address _toInvestor,
        uint256 _amount
    ) external;

    function withdrawProfit(bytes32 _raftId, uint256 _amount) external;

    // by organizer
    function withdraw(bytes32 _streamId, uint256 _amount) external;

    function returnProfit(
        bytes32 _streamId,
        uint256 _profit,
        uint256 _startAt
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IOtterManager {
    function otterManager() external view returns (address);

    function setWithdrawRate(bytes32 _role, uint256 _newRate) external;

    function getWithdrawRate(bytes32 _role) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IOtterManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
    @dev Otter配置参数管理合约
 */
contract OtterManager is
    Initializable,
    OwnableUpgradeable,
    AccessControlEnumerableUpgradeable,
    IOtterManager
{
    ///  Otter管理员角色
    bytes32 public constant OTTER_MANAGER = keccak256("OTTER_MANAGER");
    ///  Stream组建者角色
    bytes32 public constant OTTER_ORGANIZER = keccak256("OTTER_ORGANIZER");
    /// Otter普通用户(投资者)
    bytes32 public constant OTTER_USER = keccak256("OTTER_USER");

    /// 精度(小数点后两位)
    // 10000
    // 9999 / 100  = 99.99
    uint256 public constant MAX_RATE = 10000; // 2442/100 = 24.22%

    /// 收益释放周期(30天)
    uint256 public constant RELEASE_PERIOD = 30; // 30days

    /// 用户提取USDC的费率，按角色划分
    mapping(bytes32 => uint256) private _withdrawRates;

    function __OtterManagerInit() internal onlyInitializing {
        __Ownable_init();
        __AccessControl_init();

        _setRoleAdmin(OTTER_MANAGER, OTTER_MANAGER);
        _setRoleAdmin(OTTER_ORGANIZER, OTTER_MANAGER);

        _setupRole(OTTER_MANAGER, owner());
    }

    /// @dev 查看otter管理员用户
    /// @return address 管理员用户地址
    function otterManager() public view override returns (address) {
        return owner();
    }

    event SetWithdrawRate(bytes32 role, uint256 oldRate, uint256 newRate);

    /// @dev 设置收益提取费率(仅允许Otter管理员)
    /// @param _role 角色类型
    /// @param _newRate 角色对应的提取费率
    function setWithdrawRate(bytes32 _role, uint256 _newRate)
        public
        override
        onlyRole(OTTER_MANAGER)
    {
        require(1000<=_newRate && _newRate<= 9000,"excceedes max rate");
        emit SetWithdrawRate(_role, _withdrawRates[_role], _newRate);
        _withdrawRates[_role] = _newRate;
    }

    /// @dev 查询角色对应的提取费率
    /// @param _role 角色类型
    /// @return uint256 收取的费用
    function getWithdrawRate(bytes32 _role) public view override returns (uint256) {
        return _withdrawRates[_role];
    }

    /// @dev 计算提取一定收益的费率
    /// @param _role 角色类型
    /// @param _total 需提取的收益总量
    /// @return uint256 收取的费用
    function caculateWithdrawFee(bytes32 _role, uint256 _total) public view returns (uint256) {
        uint256 rate = getWithdrawRate(_role);
        return (_total * rate) / MAX_RATE;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
library CountersUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}