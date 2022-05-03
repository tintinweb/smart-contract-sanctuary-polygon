/**
 *Submitted for verification at polygonscan.com on 2022-05-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract dice {

    //开始,准备,投注,结算,维护中
    enum GameState {
        Ready,
        Betting,
        Settlement,
        Maintain
    }

    /// 投注区域, 大小
    enum BetRegion {
        None,
        Big,
        Small
    }

    //投注记录, 谁在x区域投注多少钱,派彩多钱
    struct BetRecord {
        address user;
        BetRegion region;
        uint256 amount;
        uint256 payout;
    }

    GameState public state;
    address public owner; //庄家
    bool private isWaitingForMaintain; //等待维护
    BetRecord[] public bets; //投注记录
    // mapping(string => mapping(address => uint256)) public winnerDatas; //局号 => 玩家 => 赢钱金额

    mapping(BetRegion => uint256) public odds; //赔率 * 10000, 支持到 1 : 1.15 这样
    uint256 public availableBetAmount; //可用投注额
    // mapping(BetRegion => uint256) public betLimits; //限红,保证庄家有钱够赔

    uint256 public betEndTime; //投注结束时间

    // uint256 public randomNum; //随机数
    uint256 public randomNumHashed; //随机数hash后

    string public orderId; //局号

    constructor() {
        owner = msg.sender;
        initOdds();
    }

    function initOdds() private {
        odds[BetRegion.Big] = 1.00 * 10000;
        odds[BetRegion.Small] = 1.00 * 10000;
    }

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "caller is not owner.");
        _;
    }

    event BetBegin(string orderId, uint256 randomNumHashed, uint256 betEndTime); //游戏开始通知
    event BetOver(uint256 randomNum, uint256[] results); //结束投注通知&披露随机数
    event BetSuccess(string indexed orderIdIdx, string orderId, address betMan, BetRegion betRegion, uint256 betAmount); //下注成功通知
    event SettlementOver(string indexed orderIdIdx, string orderId, uint256 randomNum, uint256[] results, BetRecord[] bets); //结算完成
    event Maintain(string message); //维护通知
    event MaintainOver(string message); //维护通知

    event OwnerDeposit();
    event OwnerWithdraw();

    /// @param _randomNumHashed 随机数的哈希值  _randomNumHashed = keccak256(abi.encodePacked((randomNum))
    /// 游戏开始, 定时任务调用
    function betBegin(
        string memory _orderId,
        uint _bettingSeconds,
        uint256 _randomNumHashed
    ) public isOwner {
        require(address(this).balance > 0, "owner don't have any money.");
        require(state == GameState.Ready);
        require(bytes(_orderId).length > 0);
        require(_bettingSeconds > 0);

        delete bets;
        orderId = _orderId;
        randomNumHashed = _randomNumHashed;
        betEndTime = block.timestamp + _bettingSeconds;
        availableBetAmount = address(this).balance;

        state = GameState.Betting;
        emit BetBegin(orderId, randomNumHashed,betEndTime);
    }

    /// 投注结束 定时任务调用 披露原随机数
    function betOver(uint256 _randomNum) public isOwner {
        require(state == GameState.Betting);
        require(block.timestamp >= betEndTime);
        require(randomNumHashed == uint256(keccak256(abi.encodePacked((_randomNum)))));

        state = GameState.Settlement;
        // randomNum = _randomNum;
        uint256[] memory results = resolveRandomNum(_randomNum, 3);
        // emit BetOver(randomNum, results);

        doSettlement(_randomNum, results);
    }

    function resolveRandomNum(uint256 randomValue, uint n) private pure returns (uint256[] memory)
    {
        uint256[] memory results = new uint256[](n);
        for (uint i = 0; i < n; i++) {
            uint256 expandedValue = uint256(keccak256(abi.encodePacked(randomValue, i)));
            uint256 remainder = (expandedValue % 6) + 1;
            results[i] = remainder;
        }
        return results;
    }

    /// 结算
    function doSettlement(uint256 randomNum, uint256[] memory results) private {
        require(state == GameState.Settlement);

        state = GameState.Ready;

        BetRegion[] memory winRegions = calculateWinRegion(results);
        for (uint256 i = 0; i < winRegions.length; i++) {
            BetRegion winRegion = winRegions[i];

            for (uint256 j = 0; j < bets.length; j++) {
                if (bets[j].region != winRegion) {
                    continue;
                }
                
                //玩家的每一笔投注, 都单独派奖
                uint256 payout = bets[j].amount + (bets[j].amount * odds[winRegion]) / 10000;
                bets[i].payout = payout;
                // winnerDatas[orderId][bets[j].user] += payout;
                payable(bets[j].user).transfer(payout);
            }
        }

        emit SettlementOver(orderId, orderId, randomNum, results, bets);

        if (isWaitingForMaintain) {
            isWaitingForMaintain = false;
            state = GameState.Maintain;
            emit Maintain("our website is in maintenance.");
        }
        // else {
        //     state = GameState.Ready;
        // }

        // settlementOver();
    }

    function calculateWinRegion(uint256[] memory results)
        private
        pure
        returns (BetRegion[] memory)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < results.length; i++) {
            sum += results[i];
        }

        //3-10 小, 11-18 大
        BetRegion winRegion;
        if (sum >= 3 && sum <= 10) {
            winRegion = BetRegion.Small;
        } else {
            winRegion = BetRegion.Big;
        }

        BetRegion[] memory winRegions = new BetRegion[](1);
        winRegions[0] = winRegion;
        return winRegions;
    }

    /// 庄家补钱
    function ownerDeposit() public payable isOwner {
        require(state == GameState.Ready, "only deposit in ready state.");
        require(msg.value > 0);

        emit OwnerDeposit();
    }

    /// 庄家提现
    function ownerWithdraw(uint256 amount) public isOwner {
        require(state == GameState.Ready, "only withdraw in ready state.");
        require(amount <= address(this).balance);

        payable(owner).transfer(amount);
        emit OwnerWithdraw();
    }

    /// 系统维护, 该局结束后
    function maintainBegin() public isOwner {
        isWaitingForMaintain = true;
    }

    /// 维护结束
    function maintainOver() public isOwner {
        require(state == GameState.Maintain, "game is not in maintain state.");
        state = GameState.Ready;

        emit MaintainOver("maintenance is over.");
    }

    /// keccak256计算
    function getKeccak256(uint256 origin) public view isOwner returns (uint256) {
        return uint256(keccak256(abi.encodePacked(origin)));
    }

    //玩家投注
    function bet(BetRegion betRegion) public payable {
        require(betRegion != BetRegion.None, "please select bet region.");
        require(state == GameState.Betting, "not betting time.");
        require(msg.value > 0, "bet amount need greater ge 0.");
        require(availableBetAmount - msg.value * odds[betRegion] > 0, "bet amount has over the owner's capacity.");

        availableBetAmount -= msg.value * odds[betRegion]; //庄家余额还能赔付多钱
        bets.push(BetRecord(msg.sender, betRegion, msg.value, 0));
        emit BetSuccess(orderId, orderId, msg.sender, betRegion, msg.value);
    }
}