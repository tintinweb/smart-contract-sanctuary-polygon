/**
 *Submitted for verification at polygonscan.com on 2022-05-27
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

    // 投注区域, 大小
    enum BetRegion {
        None,
        Big,
        Small
    }

    //投注记录, 谁在x区域投注多少钱,派彩多钱
    struct BetRecord {
        address account;
        BetRegion region;
        uint256 amount;
        uint256 payout;
    }

    GameState public state;
    address public owner; //庄家
    bool private isWaitingForMaintain; //等待维护
    BetRecord[] public bets; //投注记录
    mapping(BetRegion => uint256) public odds; //赔率 * 10000, 支持到 1 : 1.15 这样
    uint256 public availableBetAmount; //可用投注额

    uint256 public betEndTime; //投注结束时间

    uint256 public randomNumHashed; //随机数hash后

    string public orderId; //局号
    bool private haspaid; //betend无返回重复调用,只付一次款

    constructor() {
        owner = msg.sender;
        initOdds();
    }

    //初始化数据
    function reset() public isOwner {
        //把钱还给玩家
        for (uint256 i = 0; i < bets.length; i++) {
            payable(bets[i].account).transfer(bets[i].amount);
        }

        delete bets;
        state = GameState.Ready;
        isWaitingForMaintain = false;
        initOdds();
        emit Reset(orderId);
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

    event Reset(string orderId); //重置通知
    event BetBegin(string orderId, uint256 randomNumHashed, uint256 betEndTime); //游戏开始通知
    event BetSuccess(string orderId, address betMan, BetRegion betRegion, uint256 betAmount); //下注成功通知
    event SettlementEnd(string orderId, uint256 randomNum, uint256 randomNumHashed, uint256[] cards, BetRegion[] winRegions, address[] accounts, BetRegion[] betRegions, uint256[] betAmounts, uint256[] payouts, uint256 contractBalance); //结算完成
    event Maintain(string message); //维护通知
    event MaintainEnd(string message); //维护通知

    event OwnerDeposit();
    event OwnerWithdraw();

    /// @param _randomNumHashed 随机数的哈希值  _randomNumHashed = keccak256(abi.encodePacked((randomNum))
    /// 游戏开始, 定时任务调用
    function betBegin(
        string memory _orderId,
        uint _bettingSeconds,
        uint256 _randomNumHashed
    ) public isOwner {
        require(state == GameState.Ready || state == GameState.Betting, "not ready state.");
        require(address(this).balance > 0, "owner don't have any money.");
        require(bytes(_orderId).length > 0, "orderid is empty.");
        require(_bettingSeconds > 0, "betting seconds need gt zero.");

        //有时候调用没返回或报错(调用成功,没响应),会重复调用该函数,直接返回emit
        if(state == GameState.Betting) {
            emit BetBegin(orderId, randomNumHashed,betEndTime);
            return;
        }

        delete bets;
        orderId = _orderId;
        randomNumHashed = _randomNumHashed;
        betEndTime = block.timestamp + _bettingSeconds;
        availableBetAmount = address(this).balance;
        state = GameState.Betting;
        haspaid = false;
        emit BetBegin(orderId, randomNumHashed,betEndTime);
    }

    //玩家投注
    function bet(BetRegion betRegion) public payable {
        require(msg.sender != owner, "the owner is not allowed to bet.");
        require(state == GameState.Betting, "not betting time.");
        require(betRegion != BetRegion.None, "please select bet region.");
        require(block.timestamp < betEndTime, "betting time has ended.");
        require(msg.value > 0, "bet amount need ge 0.");
        require(availableBetAmount - msg.value - msg.value / 10000 * odds[betRegion]  > 0, "bet amount has over the owner's capacity.");

        availableBetAmount -= msg.value + msg.value / 10000 * odds[betRegion] ; //庄家余额还能赔付多钱
        bets.push(BetRecord(msg.sender, betRegion, msg.value, 0));
        emit BetSuccess(orderId, msg.sender, betRegion, msg.value);
    }

    /// 投注结束 定时任务调用 披露原随机数
    function betEnd(uint256 _randomNum) public isOwner {
        // require(state == GameState.Betting, "betend can be called only in betting state.");
        require(block.timestamp >= betEndTime, "haven't reached the end time yet.");
        require(randomNumHashed == uint256(keccak256(abi.encodePacked((_randomNum)))),"randomNum is wrong.");

        state = GameState.Settlement;
        uint256[] memory cards = resolveRandomNum(_randomNum, 3);

        doSettlement(_randomNum, cards);
    }

    /// keccak256计算
    function getKeccak256(uint256 origin) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(origin)));
    }

    function resolveRandomNum(uint256 randomValue, uint n) private pure returns (uint256[] memory) {
        uint256[] memory results = new uint256[](n);
        for (uint i = 0; i < n; i++) {
            uint256 expandedValue = uint256(keccak256(abi.encodePacked(randomValue, i)));
            uint256 remainder = (expandedValue % 6) + 1;
            results[i] = remainder;
        }
        return results;
    }

    /// 结算
    function doSettlement(uint256 randomNum, uint256[] memory cards) private {
        state = GameState.Ready;

        BetRegion[] memory winRegions = calculateWinRegion(cards);
        for (uint256 i = 0; i < winRegions.length; i++) {
            BetRegion winRegion = winRegions[i];

            for (uint256 j = 0; j < bets.length; j++) {
                if (bets[j].region != winRegion) {
                    continue;
                }

                //玩家的每一笔投注, 都单独派奖
                uint256 payout = bets[j].amount + bets[j].amount / 10000 * odds[winRegion];
                bets[j].payout = payout;
                if(!haspaid){
                    payable(bets[j].account).transfer(payout);
                }
            }
        }
        haspaid = true;

        address[] memory accounts = new address[](bets.length);
        BetRegion[] memory betRegions = new BetRegion[](bets.length);
        uint256[] memory betAmounts = new uint256[](bets.length);
        uint256[] memory payouts = new uint256[](bets.length);
        for (uint256 i = 0; i < bets.length; i++) {
            accounts[i] = bets[i].account;
            betRegions[i] = bets[i].region;
            betAmounts[i] = bets[i].amount;
            payouts[i] = bets[i].payout;
        }
        emit SettlementEnd(orderId, randomNum, randomNumHashed, cards, winRegions, accounts, betRegions, betAmounts, payouts, address(this).balance);

        if (isWaitingForMaintain) {
            isWaitingForMaintain = false;
            state = GameState.Maintain;
            emit Maintain("our website is in maintenance.");
        }

        // delete bets;
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
        require(msg.value > 0, "owner deposit amount need gt 0.");

        emit OwnerDeposit();
    }

    /// 庄家提现
    function ownerWithdraw() public isOwner {
        require(state == GameState.Ready, "only withdraw in ready state.");

        payable(owner).transfer(address(this).balance);
        emit OwnerWithdraw();
    }

    /// 系统维护, 该局结束后
    function maintainBegin() public isOwner {
        isWaitingForMaintain = true;
    }

    /// 维护结束
    function maintainEnd() public isOwner {
        require(state == GameState.Maintain, "game is not in maintain state.");
        state = GameState.Ready;

        emit MaintainEnd("maintenance is end.");
    }
}