// SPDX-License-Identifier: MIT

library Math {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        return a**b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface EistienEggs {
    function userExists(address adr) external view returns (bool);
}

pragma solidity 0.8.15;



contract EISTIEN {
    address private owner;

    constructor() {
        owner = msg.sender;
    }
    
    address internal TEAM_ADDRESS = 0xB9bbDCcBabe90986258e4A0Eda3362E55aF6Dc3D;
    uint256 internal MAX_EISTIEN_EGGS_TIMER  = 108000; // 30 hours
    uint256 internal MAX_EISTIEN_EGGS_AUTOCOMPOUND_TIMER = 518400; // 144 hours / 6 days
    uint256 internal WITHDRAWAL_LIMIT_TIMER = 21600; // 6 hours
    uint256 internal BNB_PER_EGGEISTIEN = 6048000000;
    uint256 internal SECONDS_PER_DAY = 86400;
    uint256 internal DAILY_REWARD = 2;
    uint256 internal REQUIRED_WITHDRAWALS_BEFORE_SELLCROP = 6;
    uint256 internal TEAM_AND_CONTRACT_FEE = 8;
    uint256 internal REF_BONUS = 5;
    uint256 internal FIRST_DEPOSIT_REF_BONUS = 5; // 5 for the first deposit
    uint256 internal MAX_DEPOSITLINE = 10;
    uint256 internal MIN_DEPOSIT = 50000000000000000; // 0.05 BNB
    uint256 internal BNB_THRESHOLD_FOR_DEPOSIT_REWARD = 5000000000000000000; // 5 BNB
    uint256 internal MAX_PAYOUT = 260000000000000000000; // 260 BNB
    uint256 internal MAX_DEFROST_WITHDRAWAL_IN_BNB = 5000000000000000000; // 5 BNB
    uint256 internal MAX_WALLET_TVL_IN_BNB = 250000000000000000000; // 250 BNB
    uint256 internal DEPOSIT_BONUS_REWARD_PERCENT = 10; 
    uint256 internal TOTAL_USERS;
    bool internal depositAndAirdropBonusEnabled = true;
    bool internal requireReferralEnabled = false;
    bool internal airdropEnabled = true;
    bool internal sellCropEnabled = false;
    bool internal permanentRewardFromDownlineEnabled = true;
    bool internal permanentRewardFromDepositEnabled = true;
    bool internal rewardPercentCalculationEnabled = true;
    bool internal aHProtocollized = false;
    bool internal autoCompoundFeeEnabled = true;
    bool internal eggBattleEnabled = false;
    address payable internal teamAddress;
    address payable internal ownerAddress;
    mapping(address => address) internal sender;
    mapping(address => uint256) internal lockedEistienEggs;
    mapping(address => uint256) internal lastFreeze;
    mapping(address => uint256) internal lastSellCrop;
    mapping(address => uint256) internal firstDeposit;
    mapping(address => uint256) internal compoundsSinceLastSellCrop;
    mapping(address => bool) internal hasReferred;
    mapping(address => bool) internal migrationRequested;
    mapping(address => uint256) internal lastMigrationRequest;
    mapping(address => bool) internal userInfoMigrated;
    mapping(address => bool) internal userDataMigrated;
    mapping(address => bool) internal isNewUser;
    mapping(address => address) internal upline;
    mapping(address => address[]) internal referrals;
    mapping(address => uint256) internal downLineCount;
    mapping(address => uint256) internal depositLineCount;
    mapping(address => uint256) internal totalDeposit;
    mapping(address => uint256) internal totalPayout;
    mapping(address => uint256) internal airdrops_sent;
    mapping(address => uint256) internal airdrops_sent_count;
    mapping(address => uint256) internal airdrops_received;
    mapping(address => uint256) internal airdrops_received_count;
    mapping(address => string) internal userName;
    mapping(address => bool) internal autoCompoundEnabled;
    mapping(address => uint256) internal autoCompoundStart;

    modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this function.");
    _;
}

    struct EggsBattleParticipant {
        address adr;
        uint256 totalDeposit;
        uint256 fighters;
    }

    struct DetailedReferral {
        address adr;
        uint256 totalDeposit;
        string userName;
        bool hasMigrated;
    }
    
    struct PreviousEggsBattles {
        uint256 endedAt;
        address winnerAdr;
        string winnerUserName;
        uint256 winnerTotalDeposit;
        uint256 winnerFighters;
        address runUpAdr;
        string runUpUserName;
        uint256 runUpTotalDeposit;
        uint256 runUpFighters;
    }

    PreviousEggsBattles[] internal previousEggsBattles;
    EggsBattleParticipant[] internal eggBattleParticipants;
    //bool internal eggBattleEnabled;
    uint256 internal eggBattleCycleStart;
    uint256 internal EGG_BATTLE_CYCLE_TIME = 108000; // 30 hours

    mapping(address => uint256) internal eggBattleFighters;

    uint256 public totalPreviousBattles;

    event EmitBoughtEistienEggs(
        address indexed adr,
        address indexed ref,
        uint256 bnbamount,
        uint256 EGGEISTIENsamount
    );
    event EmitFroze(
        address indexed adr,
        address indexed ref,
        uint256 EGGEISTIENsamount
    );
    event EmitDeFroze(
        address indexed adr,
        uint256 bnbamount,
        uint256 EGGEISTIENsamount
    );
    event EmitAirDropped(
        address indexed adr,
        address indexed reviever,
        uint256 bnbamount,
        uint256 EGGEISTIENsamount
    );
    event Emitlized(bool lized);
    event EmitPresalelized(bool lized);
    event EmitPresaleEnded(bool presaleEnded);
    event EmitAutoCompounderStart(
        address investor,
        uint256 msgValue,
        uint256 tvl,
        uint256 fee,
        bool feeEnabled
    );
    event EmitOwnerDeposit(
        uint256 bnbamount
    );

    function isOwner(address adr) public view returns (bool) {
        return adr == owner;
    }

    function ownerDeposit() public payable onlyOwner {
        emit EmitOwnerDeposit(msg.value);
    }

    function toggleEggsBattle(bool start)
        public
        onlyOwner
        returns (bool enabled)
    {
        eggBattleEnabled = start;
        EGG_BATTLE_CYCLE_TIME = 108000; // 30 hours
        return eggBattleEnabled;
    }

    function getEggsBattleValues()
        public
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            bool enabled
        )
    {
        uint256 end = Math.add(eggBattleCycleStart, EGG_BATTLE_CYCLE_TIME);
        return (eggBattleCycleStart, end, eggBattleEnabled);
    }

    function eggBattleHasEnded() public view returns (bool ended) {
        uint256 end = Math.add(eggBattleCycleStart, EGG_BATTLE_CYCLE_TIME);
        return block.timestamp > end;
    }

    function createEggsBattleParticipant(address adr) private {
        for (uint256 i = 0; i < eggBattleParticipants.length; i++) {
            if (eggBattleParticipants[i].adr == adr) {
                return;
            }
        }

        EggsBattleParticipant memory newParticipant = EggsBattleParticipant(
            adr,
            0,
            0
        );
        
        eggBattleParticipants.push(newParticipant);
        return;
    }

    function handleEggsBattleDeposit(address adr, uint256 bnbWeiDeposit)
        private
    {
        createEggsBattleParticipant(adr);
        uint256 multiplier = 1;
        if (block.timestamp <= (eggBattleCycleStart + 36000)) {
            //Bought within the first 10 hours
            multiplier = 3;
        } else if (
            block.timestamp > (eggBattleCycleStart + 36000) &&
            block.timestamp <= (eggBattleCycleStart + 72000)
        ) {
            //Bought within the 10-20 hours
            multiplier = 2;
        }

        for (uint256 i = 0; i < eggBattleParticipants.length; i++) {
            if (eggBattleParticipants[i].adr == adr && eggBattleParticipants[i].fighters <= 0) {
                uint256 fightersPerBNB = 100;
                uint256 fighters = Math.div(
                    Math.mul(bnbWeiDeposit, fightersPerBNB),
                    1000000000000000000
                );

                eggBattleParticipants[i].totalDeposit = Math.add(
                    eggBattleParticipants[i].totalDeposit,
                    bnbWeiDeposit
                );
                eggBattleParticipants[i].fighters = Math.add(
                    eggBattleParticipants[i].fighters,
                    Math.mul(fighters, multiplier)
                );
            }
        }
    }

    function generateRandomNumber(uint256 winnerIndex, uint256 arrayLength)
        private
        view
        returns (uint256)
    {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        uint256 arrayIndexLength = (arrayLength - 1);
        uint256 randomRunUpIndex = (seed -
            ((seed / arrayIndexLength) * arrayIndexLength));

        if (randomRunUpIndex == winnerIndex && arrayLength > 1) {
            if (randomRunUpIndex == arrayIndexLength) {
                randomRunUpIndex = randomRunUpIndex - 1;
            } else {
                randomRunUpIndex = randomRunUpIndex + 1;
            }
        }

        return randomRunUpIndex;
    }

    function setDailyReward(uint256 newReward) external onlyOwner {
        require(newReward >= 1 && newReward <= 10, "Invalid daily reward value.");
        DAILY_REWARD = newReward;
    }

    function startNewEggsBattle() public onlyOwner {
        require(eggBattleEnabled, "EggsBattle is not enabled");
        address winner = address(0);
        uint256 winnerIndex = 0;
        uint256 highestAmountOfFighters = 0;
        uint256 highestDepositAmount = 0;

        PreviousEggsBattles memory historyItem = PreviousEggsBattles(
            block.timestamp,
            address(0),
            userName[address(0)],
            0,
            0,
            address(0),
            userName[address(0)],
            0,
            0
        );

        for (uint256 i = 0; i < eggBattleParticipants.length; i++) {
            if (eggBattleParticipants[i].fighters > highestAmountOfFighters) {
                highestAmountOfFighters = eggBattleParticipants[i].fighters;
                highestDepositAmount = eggBattleParticipants[i].totalDeposit;
                winner = eggBattleParticipants[i].adr;
                winnerIndex = i;

                historyItem.winnerAdr = eggBattleParticipants[i].adr;
                historyItem.winnerUserName = userName[
                    eggBattleParticipants[i].adr
                ];
                historyItem.winnerFighters = eggBattleParticipants[i].fighters;
                historyItem.winnerTotalDeposit = eggBattleParticipants[i]
                    .totalDeposit;
            }
        }

        if (eggBattleParticipants.length > 1 && winner != address(0)) {
            uint256 randomIndex = generateRandomNumber(
                winnerIndex,
                eggBattleParticipants.length
            );
            uint256 extraRunUpEistienEggs = calcPercentAmount(
                calcBuyEistienEggs(
                    eggBattleParticipants[randomIndex].totalDeposit
                ),
                3
            );
            lockedEistienEggs[eggBattleParticipants[randomIndex].adr] = Math
                .add(
                    lockedEistienEggs[eggBattleParticipants[randomIndex].adr],
                    extraRunUpEistienEggs
                );

            historyItem.runUpAdr = eggBattleParticipants[randomIndex].adr;
            historyItem.runUpUserName = userName[
                eggBattleParticipants[randomIndex].adr
            ];
            historyItem.runUpFighters = eggBattleParticipants[randomIndex]
                .fighters;
            historyItem.runUpTotalDeposit = eggBattleParticipants[randomIndex]
                .totalDeposit;
        }

        if (winner != address(0)) {
            previousEggsBattles.push(historyItem);

            uint256 extraEistienEggs = calcPercentAmount(
                calcBuyEistienEggs(highestDepositAmount),
                7
            );
            lockedEistienEggs[winner] = Math.add(
                lockedEistienEggs[winner],
                extraEistienEggs
            );
        }

        delete eggBattleParticipants;
        eggBattleCycleStart = block.timestamp;

        if (previousEggsBattles.length > 50) {
            totalPreviousBattles = Math.add(totalPreviousBattles, 1);
            removeLastBattle();
        } else {
            totalPreviousBattles = previousEggsBattles.length;
        }
    }

    function removeLastBattle() private {
        for (uint i = 0; i < previousEggsBattles.length-1; i++){
            previousEggsBattles[i] = previousEggsBattles[i+1];
        }
        previousEggsBattles.pop();
    }

    function getPreviousEggsBattles()
        public
        view
        returns (PreviousEggsBattles[] memory eggBattles)
    {
        uint256 resultCount = previousEggsBattles.length;
        PreviousEggsBattles[] memory result = new PreviousEggsBattles[](resultCount);

        for (uint256 i = 0; i < previousEggsBattles.length; i++) {
            PreviousEggsBattles memory previousBattle = previousEggsBattles[i];
            result[i] = previousBattle;
            result[i].winnerUserName = userName[previousBattle.winnerAdr];
            result[i].runUpUserName = userName[previousBattle.runUpAdr];
        }

        return result;
    }

    function getMyEggsBattleValues()
        public
        view
        returns (uint256 myEggsBattleTotalDeposit, uint256 myEggsBattleFighters)
    {
        for (uint256 i = 0; i < eggBattleParticipants.length; i++) {
            if (eggBattleParticipants[i].adr == msg.sender) {
                return (
                    eggBattleParticipants[i].totalDeposit,
                    eggBattleParticipants[i].fighters
                );
            }
        }
        return (0, 0);
    }

    function hireFarmers(address ref) public payable {
        require(
            msg.value >= MIN_DEPOSIT,
            "Deposit doesn't meet the minimum requirements"
        );
        require(
            totalPayout[msg.sender] < MAX_PAYOUT,
            "Total payout must be lower than max payout"
        );
        require(
            maxTvlReached(msg.sender) == false,
            "Total wallet TVL reached"
        );
        require(
            autoCompoundEnabled[msg.sender] == false,
            "Can't deposit while autocompounding is active"
        );
        require(
            upline[ref] != msg.sender,
            "You are upline of the ref. Ref can therefore not be your upline."
        );
        require(
            maxReferralsReached(ref) == false,
            "Ref has too many referrals."
        );

        sender[msg.sender] = msg.sender;

        if (eggBattleEnabled && eggBattleHasEnded() == false) {
            handleEggsBattleDeposit(msg.sender, msg.value);
        }

        uint256 marketingFee = calcPercentAmount(
            msg.value,
            TEAM_AND_CONTRACT_FEE
        );
        uint256 bnbValue = Math.sub(msg.value, marketingFee);
        uint256 eggsEiestienBought = calcBuyEistienEggs(bnbValue);

        if (depositAndAirdropBonusEnabled) {
            eggsEiestienBought = Math.add(
                eggsEiestienBought,
                calcPercentAmount(
                    eggsEiestienBought,
                    DEPOSIT_BONUS_REWARD_PERCENT
                )
            );
        }

        uint256 totalEistienEggsBought = calcMaxLockedEistienEggs(
            msg.sender,
            eggsEiestienBought
        );
        lockedEistienEggs[msg.sender] = totalEistienEggsBought;

        uint256 amountToLP = Math.div(bnbValue, 2);

        if (
            !hasReferred[msg.sender] &&
            ref != msg.sender &&
            ref != address(0) &&
            upline[ref] != msg.sender
        ) {
            upline[msg.sender] = ref;
            hasReferred[msg.sender] = true;
            referrals[upline[msg.sender]].push(msg.sender);
            downLineCount[upline[msg.sender]] = Math.add(
                downLineCount[upline[msg.sender]],
                1
            );
            if (firstDeposit[msg.sender] == 0 && !isOwner(ref)) {
                uint256 eggsEiestienRefBonus = calcPercentAmount(
                    eggsEiestienBought,
                    FIRST_DEPOSIT_REF_BONUS
                );
                uint256 totalRefEistienEggs = calcMaxLockedEistienEggs(
                    upline[msg.sender],
                    eggsEiestienRefBonus
                );
                lockedEistienEggs[upline[msg.sender]] = totalRefEistienEggs;
            }
        }

        if (firstDeposit[msg.sender] == 0) {
            firstDeposit[msg.sender] = block.timestamp;
            isNewUser[msg.sender] = true;
            TOTAL_USERS++;
        }

        if (msg.value >= 5000000000000000000) {
            depositLineCount[msg.sender] = Math.add(
                depositLineCount[msg.sender],
                Math.div(msg.value, 5000000000000000000)
            );
        }

        totalDeposit[msg.sender] = Math.add(
            totalDeposit[msg.sender],
            msg.value
        );

        payable(0xCd8F1eE54F59C8e66a62152345A2C913e3796Cdf).transfer(
            marketingFee
        );
        ownerAddress.transfer(amountToLP);

        handleFreeze(true);

        emit EmitBoughtEistienEggs(
            msg.sender,
            ref,
            msg.value,
            eggsEiestienBought
        );
    }

    function compound() public {
        require(
            totalPayout[msg.sender] < MAX_PAYOUT,
            "Total payout must be lower than max payout"
        );
        require(
            maxTvlReached(msg.sender) == false,
            "Total wallet TVL reached"
        );
        require(canFreeze(), "Now must exceed time limit for next compound");
        require(
            autoCompoundEnabled[msg.sender] == false,
            "Can't compound while autocompounding is active"
        );

        handleFreeze(false);
    }

    function calcAutoCompoundReturn(address adr)
        private
        view
        returns (uint256)
    {
        uint256 secondsPassed = Math.sub(
            block.timestamp,
            autoCompoundStart[adr]
        );
        secondsPassed = Math.min(
            secondsPassed,
            MAX_EISTIEN_EGGS_AUTOCOMPOUND_TIMER
        );

        uint256 daysStarted = Math.add(
            1,
            Math.div(secondsPassed, SECONDS_PER_DAY)
        );
        daysStarted = Math.min(daysStarted, 6);

        uint256 rewardFactor = Math.pow(102, daysStarted);
        uint256 maxTvlAfterRewards = Math.div(
            Math.mul(rewardFactor, lockedEistienEggs[adr]),
            Math.pow(10, Math.mul(2, daysStarted))
        );
        uint256 maxRewards = Math.mul(
            Math.sub(maxTvlAfterRewards, lockedEistienEggs[adr]),
            100000
        );
        uint256 rewardsPerSecond = Math.div(
            maxRewards,
            Math.min(
                Math.mul(SECONDS_PER_DAY, daysStarted),
                MAX_EISTIEN_EGGS_AUTOCOMPOUND_TIMER
            )
        );
        uint256 currentRewards = Math.mul(rewardsPerSecond, secondsPassed);
        currentRewards = Math.div(currentRewards, 100000);
        return currentRewards;
    }

    function handleFreeze(bool postDeposit) private {
        uint256 eggsEiestien = getEistienEggsSincelastFreeze(msg.sender);

        if (
            upline[msg.sender] != address(0) && upline[msg.sender] != msg.sender
        ) {
            if ((postDeposit && !isOwner(upline[msg.sender])) || !postDeposit) {
                uint256 eggsEiestienRefBonus = calcPercentAmount(
                    eggsEiestien,
                    REF_BONUS
                );
                uint256 totalRefEistienEggs = calcMaxLockedEistienEggs(
                    upline[msg.sender],
                    eggsEiestienRefBonus
                );
                lockedEistienEggs[upline[msg.sender]] = totalRefEistienEggs;
            }
        }

        uint256 totalEistienEggs = calcMaxLockedEistienEggs(
            msg.sender,
            eggsEiestien
        );
        lockedEistienEggs[msg.sender] = totalEistienEggs;

        lastFreeze[msg.sender] = block.timestamp;
        compoundsSinceLastSellCrop[msg.sender] = Math.add(
            compoundsSinceLastSellCrop[msg.sender],
            1
        );

        emit EmitFroze(msg.sender, upline[msg.sender], eggsEiestien);
    }

    function setTeamAndContractFeePercent(uint256 percent) external {
        require(percent >= 1 && percent <= 10, "Percentage should be between 1 and 10");
        TEAM_AND_CONTRACT_FEE = percent;
    }

    function calculateFee(uint256 amount) internal view returns (uint256) {
        uint256 fee = amount * TEAM_AND_CONTRACT_FEE / 100;
        return fee;
    }

    function sellCrop() public {
        require(sellCropEnabled, "SellCrop isn't enabled at this moment");
        require(canSellCrop(), "Can't sellCrop at this moment");
        require(
            totalPayout[msg.sender] < MAX_PAYOUT,
            "Total payout must be lower than max payout"
        );
        require(
            autoCompoundEnabled[msg.sender] == false,
            "Can't sellCrop while autocompounding is active"
        );

        uint256 eggsEiestien = getEistienEggsSincelastFreeze(msg.sender);
        uint256 eggsEiestienInBnb = sellEistienEggs(eggsEiestien);

        uint256 marketingAndContractFee = calcPercentAmount(
            eggsEiestienInBnb,
            TEAM_AND_CONTRACT_FEE
        );
        eggsEiestienInBnb = Math.sub(eggsEiestienInBnb, marketingAndContractFee);
        uint256 marketingFee = Math.div(marketingAndContractFee, 2);

        eggsEiestienInBnb = Math.sub(eggsEiestienInBnb, marketingFee);

        bool totalPayoutHigherThanMax = Math.add(
            totalPayout[msg.sender],
            eggsEiestienInBnb
        ) > MAX_PAYOUT;
        if (totalPayoutHigherThanMax) {
            uint256 payout = Math.sub(MAX_PAYOUT, totalPayout[msg.sender]);
            eggsEiestienInBnb = payout;
        }

        lastSellCrop[msg.sender] = block.timestamp;
        lastFreeze[msg.sender] = block.timestamp;
        compoundsSinceLastSellCrop[msg.sender] = 0;

        totalPayout[msg.sender] = Math.add(
            totalPayout[msg.sender],
            eggsEiestienInBnb
        );

        payable(0xCd8F1eE54F59C8e66a62152345A2C913e3796Cdf).transfer(
            marketingFee
        );
        payable(msg.sender).transfer(eggsEiestienInBnb);

        emit EmitDeFroze(msg.sender, eggsEiestienInBnb, eggsEiestien);
    }

    function airdrop(address receiver) public payable {
        handleAirdrop(receiver, msg.value);
    }

    function massAirdrop() public payable {
        require(msg.value > 0, "You must state an amount to be airdropped.");

        uint256 sharedAmount = Math.div(
            msg.value,
            referrals[msg.sender].length
        );
        require(sharedAmount > 0, "Shared amount cannot be 0.");

        for (uint256 i = 0; i < referrals[msg.sender].length; i++) {
            address refAdr = referrals[msg.sender][i];
            handleAirdrop(refAdr, sharedAmount);
        }
    }

    function handleAirdrop(address receiver, uint256 amount) private {
        require(
            sender[receiver] != address(0),
            "Upline not found as a user in the system"
        );
        require(receiver != msg.sender, "You cannot airdrop yourself");

        uint256 eggsEiestienToAirdrop = calcBuyEistienEggs(amount);

        uint256 marketingAndContractFee = calcPercentAmount(
            eggsEiestienToAirdrop,
            TEAM_AND_CONTRACT_FEE
        );
        uint256 eggsEiestienMarketingFee = Math.div(marketingAndContractFee, 2);
        uint256 marketingFeeInBnb = calcSellEistienEggs(
            eggsEiestienMarketingFee
        );

        eggsEiestienToAirdrop = Math.sub(
            eggsEiestienToAirdrop,
            marketingAndContractFee
        );

        if (depositAndAirdropBonusEnabled) {
            eggsEiestienToAirdrop = Math.add(
                eggsEiestienToAirdrop,
                calcPercentAmount(
                    eggsEiestienToAirdrop,
                    DEPOSIT_BONUS_REWARD_PERCENT
                )
            );
        }

        uint256 totalEistienEggsForReceiver = calcMaxLockedEistienEggs(
            receiver,
            eggsEiestienToAirdrop
        );
        lockedEistienEggs[receiver] = totalEistienEggsForReceiver;

        airdrops_sent[msg.sender] = Math.add(
            airdrops_sent[msg.sender],
            Math.sub(amount, calcPercentAmount(amount, TEAM_AND_CONTRACT_FEE))
        );
        airdrops_sent_count[msg.sender] = Math.add(
            airdrops_sent_count[msg.sender],
            1
        );
        airdrops_received[receiver] = Math.add(
            airdrops_received[receiver],
            Math.sub(amount, calcPercentAmount(amount, TEAM_AND_CONTRACT_FEE))
        );
        airdrops_received_count[receiver] = Math.add(
            airdrops_received_count[receiver],
            1
        );

        payable(0xCd8F1eE54F59C8e66a62152345A2C913e3796Cdf).transfer(
            marketingFeeInBnb
        );

        emit EmitAirDropped(msg.sender, receiver, amount, eggsEiestienToAirdrop);
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }

    function enableAutoCompounding() public payable {
        require(canFreeze(), "You need to wait 6 hours between each cycle.");
        require(sender[msg.sender] != address(0), "Must be a current user");
        uint256 tvl = getUserTLV(msg.sender);
        uint256 fee = 0;
        if (tvl >= 500000000000000000) {
            fee = Math.div(calcPercentAmount(tvl, 1), 5);
            require(
                msg.value >= fee,
                string.concat(
                    string.concat(
                        string.concat(
                            "msg.value '",
                            string.concat(uint2str(msg.value), "' ")
                        ),
                        "needs to be equal or highter to the fee: "
                    ),
                    uint2str(fee)
                )
            );
            payable(0xCd8F1eE54F59C8e66a62152345A2C913e3796Cdf).transfer(
                fee / 2
            );
        }

        handleFreeze(false);
        autoCompoundEnabled[msg.sender] = true;
        autoCompoundStart[msg.sender] = block.timestamp;

        emit EmitAutoCompounderStart(
            msg.sender,
            msg.value,
            tvl,
            fee,
            true
        );
    }

    function disableAutoCompounding() public {
        uint256 secondsPassed = Math.sub(
            block.timestamp,
            autoCompoundStart[msg.sender]
        );
        uint256 daysPassed = Math.div(secondsPassed, SECONDS_PER_DAY);
        uint256 compounds = daysPassed;
        if (compounds > 5) {
            compounds = 5;
        }
        if (compounds > 0) {
            compoundsSinceLastSellCrop[msg.sender] = Math.add(
                compoundsSinceLastSellCrop[msg.sender],
                compounds
            );
        }
        handleFreeze(false);
        autoCompoundEnabled[msg.sender] = false;
    }

    function calcMaxLockedEistienEggs(address adr, uint256 eggsEiestienToAdd)
        public
        view
        returns (uint256)
    {
        uint256 totalEistienEggs = Math.add(
            lockedEistienEggs[adr],
            eggsEiestienToAdd
        );
        uint256 maxLockedEistienEggs = calcBuyEistienEggs(
            MAX_WALLET_TVL_IN_BNB
        );
        if (totalEistienEggs >= maxLockedEistienEggs) {
            return maxLockedEistienEggs;
        }
        return totalEistienEggs;
    }

    function getSellCropEnabled() public view returns (bool) {
        return sellCropEnabled;
    }

    function canFreeze() public view returns (bool) {
        uint256 lastAction = lastFreeze[msg.sender];
        if (lastAction == 0) {
            lastAction = firstDeposit[msg.sender];
        }
        return block.timestamp >= Math.add(lastAction, WITHDRAWAL_LIMIT_TIMER);
    }

    function canSellCrop() public view returns (bool) {
        if (
            maxTvlReached(msg.sender)
        ) {
            return sellCropTimeRequirementReached();
        }
        return
            sellCropFreezeRequirementReached() &&
            sellCropTimeRequirementReached();
    }

    function sellCropTimeRequirementReached() public view returns (bool) {
        uint256 lastSellCropOrFirstDeposit = lastSellCrop[msg.sender];
        if (lastSellCropOrFirstDeposit == 0) {
            lastSellCropOrFirstDeposit = firstDeposit[msg.sender];
        }

        if (
            maxTvlReached(msg.sender)
        ) {
            return block.timestamp >= (lastSellCropOrFirstDeposit + 7 days);
        }

        return block.timestamp >= (lastSellCropOrFirstDeposit + 6 days);
    }

    function sellCropFreezeRequirementReached() public view returns (bool) {
        return
            compoundsSinceLastSellCrop[msg.sender] >=
            REQUIRED_WITHDRAWALS_BEFORE_SELLCROP;
    }

    function maxPayoutReached(address adr) public view returns (bool) {
        return totalPayout[adr] >= MAX_PAYOUT;
    }

    function maxReferralsReached(address refAddress) public view returns (bool) {
        return downLineCount[refAddress] >= 200;
    }

    function maxTvlReached(address adr) public view returns (bool) {
        return lockedEistienEggs[adr] >= calcBuyEistienEggs(getBackwardCompatibleMaxTVLInBNB());
    }

    function getBackwardCompatibleMaxTVLInBNB() private view returns (uint256) {
        return MAX_WALLET_TVL_IN_BNB - 5920000000; // Necessary to handle fractal issue for already maxed wallets
    }

    function getReferrals(address adr)
        public
        view
        returns (address[] memory myReferrals)
    {
        return referrals[adr];
    }

    function getDetailedReferrals(address adr)
        public
        view
        returns (DetailedReferral[] memory myReferrals)
    {
        uint256 resultCount = referrals[adr].length;
        DetailedReferral[] memory result = new DetailedReferral[](resultCount);

        for (uint256 i = 0; i < referrals[adr].length; i++) {
            address refAddress = referrals[adr][i];
            result[i] = DetailedReferral(
                refAddress,
                totalDeposit[refAddress],
                userName[refAddress],
                true
            );
        }

        return result;
    }

    function getUserInfo(address adr)
        public
        view
        returns (
            string memory myUserName,
            address myUpline,
            uint256 myReferrals,
            uint256 myTotalDeposit,
            uint256 myTotalPayouts
        )
    {
        return (
            userName[adr],
            upline[adr],
            downLineCount[adr],
            totalDeposit[adr],
            totalPayout[adr]
        );
    }

    function getDepositAndAirdropBonusInfo()
        public
        view
        returns (bool enabled, uint256 bonus)
    {
        return (depositAndAirdropBonusEnabled, DEPOSIT_BONUS_REWARD_PERCENT);
    }

    function getUserAirdropInfo(address adr)
        public
        view
        returns (
            uint256 MyAirdropsSent,
            uint256 MyAirdropsSentCount,
            uint256 MyAirdropsReceived,
            uint256 MyAirdropsReceivedCount
        )
    {
        return (
            airdrops_sent[adr],
            airdrops_sent_count[adr],
            airdrops_received[adr],
            airdrops_received_count[adr]
        );
    }

    function userExists(address adr) public view returns (bool) {
        return sender[adr] != address(0);
    }


    function getTotalUsers() public view returns (uint256) {
        return TOTAL_USERS;
    }

    function getBnbRewards(address adr) public view returns (uint256) {
        uint256 eggsEiestien = getEistienEggsSincelastFreeze(adr);
        uint256 bnbinWei = sellEistienEggs(eggsEiestien);
        return bnbinWei;
    }

    function getUserTLV(address adr) public view returns (uint256) {
        uint256 bnbinWei = calcSellEistienEggs(lockedEistienEggs[adr]);
        return bnbinWei;
    }

    function getUserName(address adr) public view returns (string memory) {
        return userName[adr];
    }

    function setUserName(string memory name)
        public
        returns (string memory)
    {
        userName[msg.sender] = name;
        return userName[msg.sender];
    }

    function getMyUpline() public view returns (address) {
        return upline[msg.sender];
    }

    function setMyUpline(address myUpline) public returns (address) {
        require(msg.sender != myUpline, "You cannot refer to yourself");
        require(upline[msg.sender] == address(0), "Upline already set");
        require(
            sender[msg.sender] != address(0),
            "Upline user does not exists"
        );
        require(
            upline[myUpline] != msg.sender,
            "Cross referencing is not allowed"
        );

        upline[msg.sender] = myUpline;
        hasReferred[msg.sender] = true;
        referrals[upline[msg.sender]].push(msg.sender);
        downLineCount[upline[msg.sender]] = Math.add(
            downLineCount[upline[msg.sender]],
            1
        );

        return upline[msg.sender];
    }

    function getMyTotalDeposit() public view returns (uint256) {
        return totalDeposit[msg.sender];
    }

    function getMyTotalPayout() public view returns (uint256) {
        return totalPayout[msg.sender];
    }

    function getAutoCompoundValues()
        public
        view
        returns (
            bool isAutoCompoundEnabled,
            uint256 autoCompoundStartValue,
            bool isAutoCompoundFeeEnabled
        )
    {
        return (
            autoCompoundEnabled[msg.sender],
            autoCompoundStart[msg.sender],
            true
        );
    }

    function getRefBonus() public view returns (uint256) {
        return REF_BONUS;
    }

    function getMarketingAndContractFee() public view returns (uint256) {
        return TEAM_AND_CONTRACT_FEE;
    }

    function calcDepositLineBonus(address adr) private view returns (uint256) {
        if (depositLineCount[adr] >= 10) {
            return 10;
        }

        return depositLineCount[adr];
    }

    function getMyDownlineCount() public view returns (uint256) {
        return downLineCount[msg.sender];
    }

    function getMyDepositLineCount() public view returns (uint256) {
        return depositLineCount[msg.sender];
    }

    function toggleDepositBonus(bool toggled, uint256 bonus) public onlyOwner {
        if (bonus >= 10) {
            DEPOSIT_BONUS_REWARD_PERCENT = 10;
        } else {
            DEPOSIT_BONUS_REWARD_PERCENT = bonus;
        }
        depositAndAirdropBonusEnabled = toggled;
    }

    function calcReferralBonus(address adr) private view returns (uint256) {
        uint256 myReferrals = downLineCount[adr];

        if (myReferrals >= 160) {
            return 10;
        }
        if (myReferrals >= 80) {
            return 9;
        }
        if (myReferrals >= 40) {
            return 8;
        }
        if (myReferrals >= 20) {
            return 7;
        }
        if (myReferrals >= 10) {
            return 6;
        }
        if (myReferrals >= 5) {
            return 5;
        }

        return 0;
    }

    function sellEistienEggs(uint256 eggsEiestien)
        public
        view
        returns (uint256)
    {
        uint256 bnbInWei = calcSellEistienEggs(eggsEiestien);
        bool bnbToSellGreateThanMax = bnbInWei > MAX_DEFROST_WITHDRAWAL_IN_BNB;
        if (bnbToSellGreateThanMax) {
            bnbInWei = MAX_DEFROST_WITHDRAWAL_IN_BNB;
        }
        return bnbInWei;
    }

    function calcSellEistienEggs(uint256 eggsEiestien)
        internal
        view
        returns (uint256)
    {
        uint256 bnbInWei = Math.mul(eggsEiestien, BNB_PER_EGGEISTIEN);
        return bnbInWei;
    }

    function calcBuyEistienEggs(uint256 bnbInWei)
        public
        view
        returns (uint256)
    {
        uint256 eggsEiestien = Math.div(bnbInWei, BNB_PER_EGGEISTIEN);
        return eggsEiestien;
    }

    function calcPercentAmount(uint256 amount, uint256 fee)
        private
        pure
        returns (uint256)
    {
        return Math.div(Math.mul(amount, fee), 100);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getConcurrentFreezes(address adr) public view returns (uint256) {
        return compoundsSinceLastSellCrop[adr];
    }

    function getLastFreeze(address adr) public view returns (uint256) {
        return lastFreeze[adr];
    }

    function getLastSellCrop(address adr) public view returns (uint256) {
        return lastSellCrop[adr];
    }

    function getFirstDeposit(address adr) public view returns (uint256) {
        return firstDeposit[adr];
    }

    function getLockedEistienEggs(address adr) public view returns (uint256) {
        return lockedEistienEggs[adr];
    }

    function getMyExtraRewards()
        public
        view
        returns (uint256 downlineExtraReward, uint256 depositlineExtraReward)
    {
        uint256 extraDownlinePercent = calcReferralBonus(msg.sender);
        uint256 extraDepositLinePercent = calcDepositLineBonus(msg.sender);
        return (extraDownlinePercent, extraDepositLinePercent);
    }

    function getExtraRewards(address adr)
        public
        view
        returns (uint256 downlineExtraReward, uint256 depositlineExtraReward)
    {
        uint256 extraDownlinePercent = calcReferralBonus(adr);
        uint256 extraDepositLinePercent = calcDepositLineBonus(adr);
        return (extraDownlinePercent, extraDepositLinePercent);
    }

    function getExtraBonuses(address adr) private view returns (uint256) {
        uint256 extraBonus = 0;
        if (downLineCount[adr] > 0) {
            uint256 extraRefBonusPercent = calcReferralBonus(adr);
            extraBonus = Math.add(extraBonus, extraRefBonusPercent);
        }
        if (depositLineCount[adr] > 0) {
            uint256 extraDepositLineBonusPercent = calcDepositLineBonus(adr);
            extraBonus = Math.add(extraBonus, extraDepositLineBonusPercent);
        }
        return extraBonus;
    }

    function getEistienEggsSincelastFreeze(address adr)
        public
        view
        returns (uint256)
    {
        uint256 maxEistienEggs = MAX_EISTIEN_EGGS_TIMER;
        uint256 lastFreezeOrFirstDeposit = lastFreeze[adr];
        if (lastFreeze[adr] == 0) {
            lastFreezeOrFirstDeposit = firstDeposit[adr];
        }

        uint256 secondsPassed = Math.min(
            maxEistienEggs,
            Math.sub(block.timestamp, lastFreezeOrFirstDeposit)
        );

        uint256 eggsEiestien = calcEistienEggsReward(
            secondsPassed,
            DAILY_REWARD,
            adr
        );

        if (autoCompoundEnabled[adr]) {
            eggsEiestien = calcAutoCompoundReturn(adr);
        }

        uint256 extraBonus = getExtraBonuses(adr);
        if (extraBonus > 0) {
            uint256 extraBonusEistienEggs = calcPercentAmount(
                eggsEiestien,
                extraBonus
            );
            eggsEiestien = Math.add(eggsEiestien, extraBonusEistienEggs);
        }

        return eggsEiestien;
    }

    function calcEistienEggsReward(
        uint256 secondsPassed,
        uint256 dailyReward,
        address adr
    ) private view returns (uint256) {
        uint256 rewardsPerDay = calcPercentAmount(
            Math.mul(lockedEistienEggs[adr], 100000),
            dailyReward
        );
        uint256 rewardsPerSecond = Math.div(rewardsPerDay, SECONDS_PER_DAY);
        uint256 eggsEiestien = Math.mul(rewardsPerSecond, secondsPassed);
        eggsEiestien = Math.div(eggsEiestien, 100000);
        return eggsEiestien;
    }
}