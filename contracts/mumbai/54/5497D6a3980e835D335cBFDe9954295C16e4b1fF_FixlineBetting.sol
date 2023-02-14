// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ICapsStaking {
    /***********************************************************************************************************************
     @notice This Method Is Used By Contract To Send Funds In Stacking Contract.
     This Method Will Be Invoked After Specific Time, When Any User Will Claim Loss.
     If Value Of 'maxRewardsInDay' (Storage Variable) Is 4 So After 6 Hours (24 Hour/4 Times Reward),
     Reward Will Be Transferred To Stacking Contract.
    ************************************************************************************************************************/
    function notifyReward() external payable;
}

interface ICapsToken {
    /***********************************************************************************************************************
     @notice This Method Is Used By Contract To Mint Tokens For Bet Looser's.
     This Method Will Be Invoked After Specific Time, When Any User Will Claim Loss.
     If Value Of 'capsTokenDistributionAmount' (Storage Variable) Is 1 So 1 Caps Token Will Be Transferred To Looser.

     @note When Any Maker Will Claim Loss So They Will Get (capsTokenDistributionAmount*totalSoldSlotsOfBet) Tokens.
    ************************************************************************************************************************/
    function mintTokens(address receiver, uint256 amount) external;
}

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

interface IWETH {
    function withdraw(uint256 amount) external;
}

contract FixlineBetting is Ownable, ReentrancyGuard {
    event Created(
        address indexed by,
        uint256 indexed id,
        uint256 totalSlots,
        bool isETHBased
    );
    event Cancelled(
        address indexed by,
        uint256 indexed id,
        uint256 totalUnsoldSlots
    );
    event SlotPurchased(
        address indexed by,
        uint256 indexed id,
        uint256 amount,
        bool isETHBased
    );
    event WithdrawETH(address indexed by, uint256 amount);
    event WithdrawStableCoin(address indexed by, uint256 amount);
    event ClaimLoss(
        address indexed by,
        uint256 indexed id,
        uint256 totalBetAmount,
        bool isDeclaredByAdmin
    );
    event RewardSent(
        uint256 amountSentInCapsStackingContract,
        uint256 amountSentInFixlineStackingContract
    );

    enum BetType {
        Sports,
        Financial,
        Custom
    }

    struct Bet {
        address maker;
        uint256 makerAmountPerSlot;
        uint256 slotPrice;
        uint256 expiryTime;
        uint256 totalSlots;
        address[] slotTakers;
        bool[] isLossClaimed; // Note n+1th Index Will Tell About Whether Maker Claimed Loss.
        bytes data;
        bool isCancelled;
        bool isETHBased;
        BetType betType;
    }

    struct User {
        uint256 ETHBalance;
        uint256 ETHWithdrawableBalance;
        uint256 stableCoinBalance;
        uint256 stableCoinWithdrawableBalance;
        int256 reputation;
        uint256[] createdBets;
        uint256[] participatedInBets;
    }

    uint256 public subReputationAmount = 5;
    uint256 public addReputationAmount = 10;
    uint256 public minSlotsInBet = 1;
    uint256 public minMakerAmountPerSlotForETHBet = 1000000000000;
    uint256 public minMakerAmountPerSlotForStableCoinBet = 10000000;
    uint256 public winnerRewardPortion = 90;
    uint256 public looserRewardPortion = 5;
    uint256 public adminRewardPortion = 3;
    uint256 public capsStackingContractRewardPortion = 1;
    uint256 public fixlineStackingContractRewardPortion = 1;
    uint256 public capsTokenDistributionAmount = 1000000000000000000;
    uint256 public maxRewardsInDay = 4;
    uint256 public minRewardAmount = 1000000000;
    uint256 public minStableCoinSwapToETH = 100000000;
    uint256 public totalBets;

    uint256 private nextRewardTime;
    uint256 private pendingRewardsToSendInCapsStackingContract;
    uint256 private pendingStableCoinsToSwapForCapsStackingContract;
    uint256 private pendingRewardsToSendInFixlineStackingContract;
    uint256 private pendingStableCoinsToSwapForFixlineStackingContract;
    address public fixlineStackingContractAddress;
    address public uniswapV3SwapRouterAddress;
    address public uniswapV2RouterAddress;
    address public WETHAddress;
    mapping(address => User) private usersData;
    mapping(uint256 => Bet) private betsData;

    ICapsStaking private capsStakingContract_Ins;
    ICapsToken private capsTokenContract_Ins;
    IERC20 private stableCoin_Ins;

    constructor(
        address _capsStakingContractAddress,
        address _capsTokenContractAddress,
        address _stableCoinAddress,
        address _uniswapV3SwapRouterAddress,
        address _uniswapV2RouterAddress,
        address _WETHAddress
    ) {
        fixlineStackingContractAddress = msg.sender;
        capsStakingContract_Ins = ICapsStaking(_capsStakingContractAddress);
        capsTokenContract_Ins = ICapsToken(_capsTokenContractAddress);
        stableCoin_Ins = IERC20(_stableCoinAddress);
        uniswapV3SwapRouterAddress = _uniswapV3SwapRouterAddress;
        uniswapV2RouterAddress = _uniswapV2RouterAddress;
        WETHAddress = _WETHAddress;

        nextRewardTime = block.timestamp + (40 minutes / maxRewardsInDay);
        stableCoin_Ins.approve(uniswapV3SwapRouterAddress, type(uint256).max);
    }

    receive() external payable {}

    modifier isValidBetId(uint256 betId) {
        require(
            betsData[betId].maker != address(0),
            "Invalid Bet Id, Bet Not Exists"
        );
        _;
    }

    function createBetUsingETH(
        uint256 slots,
        uint256 slotPrice,
        uint256 expiryTime,
        BetType betType,
        bytes calldata data
    ) external payable returns (uint256) {
        require(
            slots >= minSlotsInBet,
            "Slots Should Greater Or Equal To Min Bets Value"
        );
        require(slotPrice != 0, "Slot Price Should Not Be Zero");
        // require(
        //     expiryTime > block.timestamp,
        //     "Expiry Time Should Greater Than Current Time"
        // );
        uint256 msgValue = msg.value;
        uint256 makerAmountPerSlot = msgValue / slots;
        require(
            makerAmountPerSlot >= minMakerAmountPerSlotForETHBet,
            "MakerAmountPerSlot Should Greater Or Equal To MinMakerAmountPerSlotForETHBet Value"
        );

        address msgSender = msg.sender;
        totalBets++;
        uint256 curBetId = totalBets;
        address[] memory emptyArr;
        bool[] memory emptyBoolArr = new bool[](slots + 1);
        betsData[curBetId] = Bet({
            maker: msgSender,
            makerAmountPerSlot: makerAmountPerSlot,
            slotPrice: slotPrice,
            expiryTime: expiryTime,
            totalSlots: slots,
            slotTakers: emptyArr,
            isLossClaimed: emptyBoolArr,
            data: data,
            isCancelled: false,
            isETHBased: true,
            betType: betType
        });

        usersData[msgSender].ETHBalance += msgValue;
        usersData[msgSender].reputation -= int256(slots * subReputationAmount);
        usersData[msgSender].createdBets.push(curBetId);

        emit Created(msgSender, curBetId, slots, true);
        return curBetId;
    }

    function createBetUsingStableCoin(
        uint256 slots,
        uint256 makerAmountPerSlot,
        uint256 slotPrice,
        uint256 expiryTime,
        BetType betType,
        bytes calldata data
    ) external returns (uint256) {
        require(
            slots >= minSlotsInBet,
            "Slots Should Greater Or Equal To Min Bets Value"
        );
        require(
            makerAmountPerSlot >= minMakerAmountPerSlotForStableCoinBet,
            "MakerAmountPerBet Should Greater Or Equal To MinMakerAmountPerBetForStableCoinBet Value"
        );
        require(slotPrice != 0, "Slot Price Should Not Be Zero");
        // require(
        //     expiryTime > block.timestamp,
        //     "Expiry Time Should Greater Than Current Time"
        // );
        address msgSender = msg.sender;
        uint256 makerTotalAmount = makerAmountPerSlot * slots;
        require(
            stableCoin_Ins.allowance(msgSender, address(this)) >=
                makerTotalAmount,
            "Insufficient Allowance Provided To Contract"
        );

        totalBets++;
        uint256 curBetId = totalBets;
        address[] memory emptyArr;
        bool[] memory emptyBoolArr = new bool[](slots + 1);
        betsData[curBetId] = Bet({
            maker: msgSender,
            makerAmountPerSlot: makerAmountPerSlot,
            slotPrice: slotPrice,
            expiryTime: expiryTime,
            totalSlots: slots,
            slotTakers: emptyArr,
            isLossClaimed: emptyBoolArr,
            data: data,
            isCancelled: false,
            isETHBased: false,
            betType: betType
        });

        usersData[msgSender].stableCoinBalance += makerTotalAmount;
        usersData[msgSender].reputation -= int256(slots * subReputationAmount);
        usersData[msgSender].createdBets.push(curBetId);

        SafeERC20.safeTransferFrom(
            IERC20(address(stableCoin_Ins)),
            msgSender,
            address(this),
            makerTotalAmount
        );

        emit Created(msgSender, curBetId, slots, false);
        return curBetId;
    }

    function buyBetSlots(uint256[] calldata betIds) external payable {
        uint256 totalBetIds = betIds.length;
        address msgSender = msg.sender;
        uint256 totalETHToTakeFromUser;
        uint256 totalStableCoinsToTakeFromUser;

        for (uint256 i; i < totalBetIds; ) {
            uint256 betId = betIds[i];
            Bet memory tempBetData = betsData[betId];
            require(
                tempBetData.maker != address(0),
                "Invalid Bet Id, Bet Not Exists"
            );
            require(
                tempBetData.isCancelled == false,
                "You Cannot Buy Slots Because Bet Is Cancelled"
            );
            // require(
            //     tempBetData.expiryTime > block.timestamp,
            //     "You Cannot Buy Slots Because Bet Is Expired"
            // );
            require(
                tempBetData.slotTakers.length < tempBetData.totalSlots,
                "All Slots Of Bet Are Sold"
            );
            require(
                getUserSlotNum(msgSender, betId) == 0,
                "You Cannot Buy Slots Because You Have Already Purchased Slot"
            );
            betsData[betId].slotTakers.push(msgSender);
            usersData[msgSender].participatedInBets.push(betId);
            if (tempBetData.isETHBased == true) {
                totalETHToTakeFromUser += tempBetData.slotPrice;
                emit SlotPurchased(
                    msgSender,
                    betId,
                    tempBetData.slotPrice,
                    true
                );
            } else {
                totalStableCoinsToTakeFromUser += tempBetData.slotPrice;
                emit SlotPurchased(
                    msgSender,
                    betId,
                    tempBetData.slotPrice,
                    false
                );
            }
            unchecked {
                i++;
            }
        }
        usersData[msgSender].reputation -= int256(
            (totalBetIds * subReputationAmount)
        );
        if (totalETHToTakeFromUser != 0) {
            require(
                msg.value >= totalETHToTakeFromUser,
                "Insufficient ETH Sent To Contract"
            );
            usersData[msgSender].ETHBalance += totalETHToTakeFromUser;
        } else {
            require(
                msg.value == 0,
                "You Are Accidentally Passing ETH To Contract"
            );
        }
        if (totalStableCoinsToTakeFromUser != 0) {
            require(
                stableCoin_Ins.allowance(msgSender, address(this)) >=
                    totalStableCoinsToTakeFromUser,
                "Insufficient Allowance Provided To Contract"
            );
            usersData[msgSender]
                .stableCoinBalance += totalStableCoinsToTakeFromUser;
            SafeERC20.safeTransferFrom(
                IERC20(address(stableCoin_Ins)),
                msg.sender,
                address(this),
                totalStableCoinsToTakeFromUser
            );
        }
    }

    function cancelBets(uint256[] calldata betIds) external {
        address msgSender = msg.sender;
        uint256 totalBetIds = betIds.length;
        int256 totalReputationToAdd;
        uint256 totalETHAmountToAdd;
        uint256 totalStableCoinAmountToAdd;
        for (uint256 i; i < totalBetIds; ) {
            uint256 betId = betIds[i];
            Bet memory tempBetData = betsData[betId];
            require(
                tempBetData.maker == msgSender,
                "Only Bet Maker Can Cancel This Bet"
            );
            // require(
            //     tempBetData.expiryTime <= block.timestamp,
            //     "You Can Cancel Bet After Bet Expiry Time"
            // );
            require(
                tempBetData.isCancelled == false,
                "Bet Is Already Cancelled"
            );
            uint256 totalUnsoldSlots = (tempBetData.totalSlots -
                tempBetData.slotTakers.length);
            require(
                totalUnsoldSlots != 0,
                "All Slots Are Sold, No Need To Cancel Bet"
            );
            totalReputationToAdd += int256(
                totalUnsoldSlots * subReputationAmount
            );
            uint256 amountToReturn = tempBetData.makerAmountPerSlot *
                totalUnsoldSlots;
            if (tempBetData.isETHBased == true) {
                totalETHAmountToAdd += amountToReturn;
            } else {
                totalStableCoinAmountToAdd += amountToReturn;
            }
            betsData[betId].isCancelled = true;
            emit Cancelled(msgSender, betId, totalUnsoldSlots);
            unchecked {
                i++;
            }
        }
        usersData[msgSender].reputation += totalReputationToAdd;
        if (totalETHAmountToAdd != 0) {
            usersData[msgSender].ETHBalance -= totalETHAmountToAdd;
            usersData[msgSender].ETHWithdrawableBalance += totalETHAmountToAdd;
        }
        if (totalStableCoinAmountToAdd != 0) {
            usersData[msgSender]
                .stableCoinBalance -= totalStableCoinAmountToAdd;
            usersData[msgSender]
                .stableCoinWithdrawableBalance += totalStableCoinAmountToAdd;
        }
    }

    function sendRewardsToStackingContract(
        uint256 amountToSendInCapsStackingContract,
        uint256 amountToSendInFixlineStackingContract,
        bool isETHBasedBetReward
    ) private {
        uint256 totalRewardToSendInCapsStackingContract = pendingRewardsToSendInCapsStackingContract;
        uint256 totalPendingStableCoinsToSwapForCapsStackingContract = pendingStableCoinsToSwapForCapsStackingContract;
        uint256 totalRewardToSendInFixlineStackingContract = pendingRewardsToSendInFixlineStackingContract;
        uint256 totalPendingStableCoinsToSwapForFixlineStackingContract = pendingStableCoinsToSwapForFixlineStackingContract;
        uint256 totalExpectedRewards;
        if (isETHBasedBetReward == true) {
            totalRewardToSendInCapsStackingContract += amountToSendInCapsStackingContract;
            totalRewardToSendInFixlineStackingContract += amountToSendInFixlineStackingContract;
        } else {
            totalPendingStableCoinsToSwapForCapsStackingContract += amountToSendInCapsStackingContract;
            totalPendingStableCoinsToSwapForFixlineStackingContract += amountToSendInFixlineStackingContract;
        }

        if (
            (block.timestamp >= nextRewardTime) &&
            (((totalPendingStableCoinsToSwapForCapsStackingContract +
                totalPendingStableCoinsToSwapForFixlineStackingContract) >=
                minStableCoinSwapToETH) &&
                ((totalRewardToSendInCapsStackingContract +
                    totalRewardToSendInFixlineStackingContract) <
                    minRewardAmount))
        ) {
            address[] memory path = new address[](2);
            path[0] = address(stableCoin_Ins);
            path[1] = WETHAddress;
            uint256[] memory amounts = IUniswapV2Router(uniswapV2RouterAddress)
                .getAmountsOut(
                    (totalPendingStableCoinsToSwapForCapsStackingContract +
                        totalPendingStableCoinsToSwapForFixlineStackingContract),
                    path
                );
            totalExpectedRewards += (totalRewardToSendInCapsStackingContract +
                totalRewardToSendInFixlineStackingContract +
                amounts[1]);
        }

        if (
            ((block.timestamp >= nextRewardTime) &&
                (((totalRewardToSendInCapsStackingContract +
                    totalRewardToSendInFixlineStackingContract) >=
                    minRewardAmount) ||
                    (totalExpectedRewards >= minRewardAmount))) ||
            (block.timestamp >= (nextRewardTime + 40 minutes))
        ) {
            if (
                (totalPendingStableCoinsToSwapForCapsStackingContract +
                    totalPendingStableCoinsToSwapForFixlineStackingContract) >=
                minStableCoinSwapToETH
            ) {
                uint256 amountOut = IUniswapV3(uniswapV3SwapRouterAddress)
                    .exactInputSingle(
                        IUniswapV3.ExactInputSingleParams(
                            address(stableCoin_Ins),
                            WETHAddress,
                            3000,
                            address(this),
                            (totalPendingStableCoinsToSwapForCapsStackingContract +
                                totalPendingStableCoinsToSwapForFixlineStackingContract),
                            0,
                            0
                        )
                    );
                IWETH(WETHAddress).withdraw(amountOut);
                uint256 amountForCapsStacking = ((((amountOut * 1e18) /
                    (totalPendingStableCoinsToSwapForCapsStackingContract +
                        totalPendingStableCoinsToSwapForFixlineStackingContract)) *
                    totalPendingStableCoinsToSwapForCapsStackingContract) /
                    1e18);
                totalRewardToSendInCapsStackingContract += amountForCapsStacking;
                totalRewardToSendInFixlineStackingContract += (amountOut -
                    amountForCapsStacking);
            }

            pendingRewardsToSendInCapsStackingContract = 0;
            pendingRewardsToSendInFixlineStackingContract = 0;
            nextRewardTime = block.timestamp + (40 minutes / maxRewardsInDay);
            capsStakingContract_Ins.notifyReward{
                value: totalRewardToSendInCapsStackingContract
            }();
            payable(fixlineStackingContractAddress).transfer(
                totalRewardToSendInFixlineStackingContract
            );
            emit RewardSent(
                totalRewardToSendInCapsStackingContract,
                totalRewardToSendInFixlineStackingContract
            );
        } else if (isETHBasedBetReward == true) {
            pendingRewardsToSendInCapsStackingContract = totalRewardToSendInCapsStackingContract;
            pendingRewardsToSendInFixlineStackingContract = totalRewardToSendInFixlineStackingContract;
        } else {
            pendingStableCoinsToSwapForCapsStackingContract = totalPendingStableCoinsToSwapForCapsStackingContract;
            pendingStableCoinsToSwapForFixlineStackingContract = totalPendingStableCoinsToSwapForFixlineStackingContract;
        }
    }

    function makerLoss(
        uint256 betId,
        Bet memory tempBetData,
        bool isDeclaredByAdmin
    ) private {
        address makerAddress = tempBetData.maker;
        uint256 totalSlotTakers = tempBetData.slotTakers.length;
        betsData[betId].isLossClaimed[tempBetData.totalSlots] = true;
        usersData[makerAddress].reputation += int256(
            addReputationAmount * totalSlotTakers
        );
        uint256 totalMakerAmount = tempBetData.makerAmountPerSlot *
            totalSlotTakers;
        uint256 totalBetAmount = totalMakerAmount +
            (tempBetData.slotPrice * totalSlotTakers);
        if (tempBetData.isETHBased == true) {
            usersData[makerAddress].ETHBalance -= totalMakerAmount;
            usersData[makerAddress].ETHWithdrawableBalance +=
                (totalBetAmount * looserRewardPortion) /
                100;
            usersData[owner()].ETHWithdrawableBalance += ((totalBetAmount *
                adminRewardPortion) / 100);
            sendRewardsToStackingContract(
                (totalBetAmount * capsStackingContractRewardPortion) / 100,
                (totalBetAmount * fixlineStackingContractRewardPortion) / 100,
                true
            );
        } else {
            usersData[makerAddress].stableCoinBalance -= totalMakerAmount;
            usersData[makerAddress].stableCoinWithdrawableBalance +=
                (totalBetAmount * looserRewardPortion) /
                100;
            usersData[owner()]
                .stableCoinWithdrawableBalance += ((totalBetAmount *
                adminRewardPortion) / 100);
            sendRewardsToStackingContract(
                (totalBetAmount * capsStackingContractRewardPortion) / 100,
                (totalBetAmount * fixlineStackingContractRewardPortion) / 100,
                false
            );
        }

        uint256 rewardPerUser = ((totalBetAmount * winnerRewardPortion) / 100) /
            totalSlotTakers;
        for (uint256 i; i < totalSlotTakers; ) {
            if (tempBetData.isETHBased == true) {
                usersData[tempBetData.slotTakers[i]].ETHBalance -= tempBetData
                    .slotPrice;
                usersData[tempBetData.slotTakers[i]]
                    .ETHWithdrawableBalance += rewardPerUser;
            } else {
                usersData[tempBetData.slotTakers[i]]
                    .stableCoinBalance -= tempBetData.slotPrice;
                usersData[tempBetData.slotTakers[i]]
                    .stableCoinWithdrawableBalance += rewardPerUser;
            }

            usersData[tempBetData.slotTakers[i]].reputation += int256(
                subReputationAmount
            );
            unchecked {
                i++;
            }
        }
        capsTokenContract_Ins.mintTokens(
            makerAddress,
            capsTokenDistributionAmount * totalSlotTakers
        );
        emit ClaimLoss(makerAddress, betId, totalBetAmount, isDeclaredByAdmin);
    }

    function takerLoss(
        uint256 betId,
        address takerAddress,
        uint256 userBetSlotNum,
        Bet memory tempBetData,
        bool isDeclaredByAdmin
    ) private {
        uint256 totalBetAmount = tempBetData.makerAmountPerSlot +
            tempBetData.slotPrice;
        betsData[betId].isLossClaimed[userBetSlotNum] = true;
        usersData[tempBetData.maker].reputation += int256(subReputationAmount);
        usersData[takerAddress].reputation += int256(addReputationAmount);
        if (tempBetData.isETHBased == true) {
            usersData[takerAddress].ETHBalance -= tempBetData.slotPrice;
            usersData[takerAddress].ETHWithdrawableBalance +=
                (totalBetAmount * looserRewardPortion) /
                100;
            usersData[tempBetData.maker].ETHBalance -= tempBetData
                .makerAmountPerSlot;
            usersData[tempBetData.maker].ETHWithdrawableBalance +=
                (totalBetAmount * winnerRewardPortion) /
                100;
            usersData[owner()].ETHWithdrawableBalance +=
                (totalBetAmount * adminRewardPortion) /
                100;
            sendRewardsToStackingContract(
                (totalBetAmount * capsStackingContractRewardPortion) / 100,
                (totalBetAmount * fixlineStackingContractRewardPortion) / 100,
                true
            );
        } else {
            usersData[takerAddress].stableCoinBalance -= tempBetData.slotPrice;
            usersData[takerAddress].stableCoinWithdrawableBalance +=
                (totalBetAmount * looserRewardPortion) /
                100;
            usersData[tempBetData.maker].stableCoinBalance -= tempBetData
                .makerAmountPerSlot;
            usersData[tempBetData.maker].stableCoinWithdrawableBalance +=
                (totalBetAmount * winnerRewardPortion) /
                100;
            usersData[owner()].stableCoinWithdrawableBalance +=
                (totalBetAmount * adminRewardPortion) /
                100;
            sendRewardsToStackingContract(
                (totalBetAmount * capsStackingContractRewardPortion) / 100,
                (totalBetAmount * fixlineStackingContractRewardPortion) / 100,
                false
            );
        }

        capsTokenContract_Ins.mintTokens(
            takerAddress,
            capsTokenDistributionAmount
        );
        emit ClaimLoss(takerAddress, betId, totalBetAmount, isDeclaredByAdmin);
    }

    /***********************************************************************************************************************
     @notice This Method Is Used To Declare Bets Looser's.
     @note Only Admin Can Access This Method.
     (1) If Bet Is Not Expired.
     Admin Will Be Not Able To Declare Looser's Of Any Bet In Given Conditions,
     (2) If Any Slot Is Not Purchased.
     @param betIds, Bet Id's Of Bets Whose Looser Admin Wants To Declare.
     @param isMakerLoss, Bool Inputs To Specify Whether Maker Is Looser.
     Inputs Can Be,
     true -> If Maker Is Looser.
     false -> If Takers Are Looser.

     @note Check "claimLossByMaker" And "claimLossByMaker",
     For More Info About Reward Distribution And Reputation Calculation
    ************************************************************************************************************************/
    function declareLooserByAdmin_Batch(
        uint256[] calldata betIds,
        bool[] calldata isMakerLoss
    ) external {
        require(betIds.length == isMakerLoss.length, "Invalid Input");
        uint256 totalBetIds = betIds.length;
        for (uint256 i; i < totalBetIds; ) {
            declareLooserByAdmin(betIds[i], isMakerLoss[i]);
            unchecked {
                i++;
            }
        }
    }

    /***********************************************************************************************************************
     @notice This Method Is Used To Declare Bet Looser.
     @note Check "declareLooserByAdmin_Batch" Comments.
     @param betId, Bet Id Of Bet Whose Looser Admin Wants To Declare.
     @param isMakerLoss, Bool Input To Specify Whether Maker Is Looser.
    ************************************************************************************************************************/
    function declareLooserByAdmin(uint256 betId, bool isMakerLoss)
        public
        onlyOwner
        isValidBetId(betId)
    {
        Bet memory tempBetData = betsData[betId];
        // require(
        //     tempBetData.expiryTime <= block.timestamp,
        //     "You Can Claim Loss After Bet Expiry Time"
        // );
        require(
            tempBetData.slotTakers.length > 0,
            "Loss Cannot Be Claimed Until Bet Slot Is Purchased By Any User"
        );
        if (isMakerLoss == true) {
            require(
                tempBetData.isLossClaimed[tempBetData.totalSlots] == false,
                "Maker Has Already Claimed Loss"
            );
            makerLoss(betId, tempBetData, true);
        } else {
            for (uint256 i; i < tempBetData.slotTakers.length; ) {
                if (tempBetData.isLossClaimed[i] == false) {
                    takerLoss(
                        betId,
                        tempBetData.slotTakers[i],
                        i,
                        tempBetData,
                        true
                    );
                }
                unchecked {
                    i++;
                }
            }
        }
    }

    /***********************************************************************************************************************
     @notice This Method Is Used To Claim Loss By Bet Maker.
     User Will Be Not Able To Claim Loss In Given Conditions,
     (1) If User Is Not Maker Of Bet.
     (2) If Bet Is Not Expired.
     (3) If Zero Slots Are Purchased.
     (4) If User Have Already Claimed Loss.
     @param betId, Id Of Bet.
     @note Maker Will Get (capsTokenDistributionAmount * totalSoldSlotsOfBet) Amount Of Caps Tokens.
     Consider capsTokenDistributionAmount Is 1 And Total Slots In Bet Is 5 But Only 3 Are Sold And Maker Claim Loss,
     So Now Maker Will Get 3 Tokens (3 soldSlots * 1 capsTokenDistributionAmount).

     @note (unsoldSlots*addReputationAmount) Number Of Bet Maker's Reputation Will Be Incremented,
     And 'subReputationAmount' Amount Of Every Bet Taker's Reputation Will Be Incremented.
     Consider 'subReputationAmount' Is 5, 'addReputationAmount' Is 10 And Total Sold Slots Are 3,
     So Now Maker's 30 Reputation (3*10) Will  Be Incremented And 5 Reputation Of Every Bet Taker Will Be Incremented.

     @note Total Bet Amount Will Be Distributed In Given Manner,
     90% / Total Bet Takers -> Each Winner.
     5% -> Maker.
     3% -> Admin.
     1% -> CapsStacking Contract.
     1% -> FixlineStacking Contract
     Total Bet Amount:- ((makerAmountPerSlot * Sold Slots) + (slotPrice * Sold Slots))
     Note This Values Can Be Change In Future.

     Now Consider makerAmountPerSlot Is 1 ETH, slotPrice Is 0.5 Eth And To Total Sold Slots Are 3.
     Total Bet Amount -> 4.5 ETH ((1 ETH makerAmountPerSlot * 3 Sold Slots) + (0.5 ETH slotPrice * 3 Sold Slots)).
     Each Bet taker -> 1.35 ETH (((4.5 ETH Total Bet Amount * 90 winnerRewardPortion) / 100) / 3 Total Bet Takers)
     Maker -> 0.225 ETH ((4.5 ETH Total Bet Amount * 5 looserRewardPortion) / 100)
     Admin -> 0.135 ETH ((4.5 ETH Total Bet Amount * 3 adminRewardPortion) / 100)
     CapsStacking Contract -> 0.045 ETH ((4.5 ETH Total Bet Amount * 1 capsStackingContractRewardPortion) / 100)
     FixlineStacking Contract -> 0.045 ETH ((4.5 ETH Total Bet Amount * 1 fixlineStackingContractRewardPortion) / 100)
    ************************************************************************************************************************/

    function claimLossByMaker(uint256 betId) public nonReentrant {
        address msgSender = msg.sender;
        Bet memory tempBetData = betsData[betId];
        require(
            tempBetData.maker == msgSender,
            "Only Bet Maker Can Access This Method"
        );
        // require(
        //     tempBetData.expiryTime <= block.timestamp,
        //     "You Can Claim Loss After Bet Expiry Time"
        // );
        require(
            tempBetData.slotTakers.length > 0,
            "You Cannot Claim Loss Until Bet Slot Is Purchased By Any User"
        );
        require(
            tempBetData.isLossClaimed[tempBetData.totalSlots] == false,
            "Maker Has Already Claimed Loss"
        );
        makerLoss(betId, tempBetData, false);
    }

    /***********************************************************************************************************************
     @notice This Method Is Used To Claim Loss By Bet Taker.
     User Will Be Not Able To Claim Loss In Given Conditions,
     (1) If Bet Is Not Expired.
     (2) If Zero Slots Are Purchased.
     (3) If User Have Already Claimed Loss.
     @param betId, Id Of Bet.

     @note Taker Will Get 'capsTokenDistributionAmount' Amount Of Caps Tokens.
     Consider 'capsTokenDistributionAmount' Is 1, So Now Taker 1 Token.

     @note 'addReputationAmount' Number Of Bet Taker's Reputation Will Be Incremented,
     And 'subReputationAmount' Of Bet Maker's Reputation Will Be Incremented.
     Consider 'subReputationAmount' Is 5, 'addReputationAmount' Is 10,
     So Now Maker's 5 Reputation Will Be Incremented And 10 Reputation Of Bet Taker Will Be Incremented.

     @note Amount Will Be Distributed In Given Manner,
     90% -> Maker.
     5% -> Taker.
     3% -> Admin.
     1% -> CapsStacking Contract.
     1% -> FixlineStacking Contract
     Amount:- (makerAmountPerSlot + slotPrice)
     Note This Values Can Be Change In Future.
     Now Consider makerAmountPerSlot Is 1 ETH, slotPrice Is 0.5 Eth.
     Amount -> 1.5 ETH (1 ETH makerAmountPerSlot + 0.5 ETH slotPrice).
     Maker -> 1.35 ETH ((1.5 ETH Amount * 90 winnerRewardPortion) / 100)
     Taker -> 0.075 ETH ((1.5 ETH Amount * 5 looserRewardPortion) / 100)
     Admin -> 0.045 ETH ((1.5 ETH Amount * 3 adminRewardPortion) / 100)
     CapsStacking Contract -> 0.015 ETH ((1.5 Amount * 1 capsStackingContractRewardPortion) / 100)
     FixlineStacking Contract -> 0.015 ETH ((1.5 ETH Amount * 1 fixlineStackingContractRewardPortion) / 100)
    ************************************************************************************************************************/
    function claimLossByTaker(uint256 betId) public nonReentrant {
        address msgSender = msg.sender;
        Bet memory tempBetData = betsData[betId];
        // require(
        //     tempBetData.expiryTime <= block.timestamp,
        //     "You Can Claim Loss After Bet Expiry Time"
        // );
        uint256 userBetSlotNum = getUserSlotNum(msgSender, betId);
        require(
            userBetSlotNum != 0,
            "You Cannot Claim Loss Because You Have Not Buy Slot"
        );
        userBetSlotNum -= 1;
        require(
            tempBetData.isLossClaimed[userBetSlotNum] == false,
            "You Have Already Claimed Loss"
        );
        takerLoss(betId, msgSender, userBetSlotNum, tempBetData, false);
    }

    /***********************************************************************************************************************
     @notice This Method Is Used To Claim Loss In Bets.
     @note If User Is Bet Maker Of Bet So 'claimLossByMaker' Will Be Invoked Otherwise 'claimLossByTaker' Will Be Invoked.
     Check 'claimLossByMaker' And 'claimLossByTaker' Comments.
     @param amount, Id's Of Bet Ids.
    ************************************************************************************************************************/
    function claimLoss_Batch(uint256[] calldata betIds) external {
        address msgSender = msg.sender;
        for (uint256 i; i < betIds.length; ) {
            if (betsData[betIds[i]].maker == msgSender) {
                claimLossByMaker(betIds[i]);
            } else {
                claimLossByTaker(betIds[i]);
            }
            unchecked {
                i++;
            }
        }
    }

    /***********************************************************************************************************************
     @notice This Method Is Used To Withdraw ETH Balance.
     User Will Be Not Able To Withdraw Amount If They Don't Have Sufficient ETH Withdrawable Balance.
     @param amount, Amount User Wants To Withdraw.
    ************************************************************************************************************************/
    function withdrawETHBalance(uint256 amount) external {
        address msgSender = msg.sender;
        require(
            amount <= usersData[msgSender].ETHWithdrawableBalance,
            "Insufficient Withdrawable Balance"
        );
        usersData[msgSender].ETHWithdrawableBalance -= amount;
        payable(msgSender).transfer(amount);
        emit WithdrawETH(msgSender, amount);
    }

    /***********************************************************************************************************************
     @notice This Method Is Used To Withdraw StableCoin Balance.
     User Will Be Not Able To Withdraw Amount If They Don't Have Sufficient StableCoin Withdrawable Balance.
     @param amount, Amount User Wants To Withdraw.
    ************************************************************************************************************************/
    function withdrawStableCoinBalance(uint256 amount) external {
        address msgSender = msg.sender;
        require(
            amount <= usersData[msgSender].stableCoinWithdrawableBalance,
            "Insufficient Withdrawable Balance"
        );
        usersData[msgSender].stableCoinWithdrawableBalance -= amount;
        SafeERC20.safeTransfer(
            IERC20(address(stableCoin_Ins)),
            msgSender,
            amount
        );
        emit WithdrawStableCoin(msgSender, amount);
    }

    /********** Setter Functions **********/

    function setSubReputationAmount(uint256 _subReputationAmount)
        external
        onlyOwner
    {
        subReputationAmount = _subReputationAmount;
    }

    function setAddReputationAmount(uint256 _addReputationAmount)
        external
        onlyOwner
    {
        addReputationAmount = _addReputationAmount;
    }

    function setMinSlotsInBet(uint256 _minSlotsInBet) external onlyOwner {
        minSlotsInBet = _minSlotsInBet;
    }

    function setMinMakerAmountPerSlotForETHBet(
        uint256 _minMakerAmountPerSlotForETHBet
    ) external onlyOwner {
        minMakerAmountPerSlotForETHBet = _minMakerAmountPerSlotForETHBet;
    }

    function setMinMakerAmountPerSlotForStableCoinBet(
        uint256 _minMakerAmountPerSlotForStableCoinBet
    ) external onlyOwner {
        minMakerAmountPerSlotForStableCoinBet = _minMakerAmountPerSlotForStableCoinBet;
    }

    function setWinnerRewardPortion(uint256 _winnerRewardPortion)
        external
        onlyOwner
    {
        winnerRewardPortion = _winnerRewardPortion;
    }

    function setLooserRewardPortion(uint256 _looserRewardPortion)
        external
        onlyOwner
    {
        looserRewardPortion = _looserRewardPortion;
    }

    function setAdminRewardPortion(uint256 _adminRewardPortion)
        external
        onlyOwner
    {
        adminRewardPortion = _adminRewardPortion;
    }

    function setCapsStackingContractRewardPortion(
        uint256 _capsStackingContractRewardPortion
    ) external onlyOwner {
        capsStackingContractRewardPortion = _capsStackingContractRewardPortion;
    }

    function setFixlineStackingContractRewardPortion(
        uint256 _fixlineStackingContractRewardPortion
    ) external onlyOwner {
        fixlineStackingContractRewardPortion = _fixlineStackingContractRewardPortion;
    }

    function setCapsTokenDistributionAmount(
        uint256 _capsTokenDistributionAmount
    ) external onlyOwner {
        capsTokenDistributionAmount = _capsTokenDistributionAmount;
    }

    // Note:- Owner Avoid To Set Large Amount Of Rewards In A Day, We Suggests You To Set Value Of Param "newMaxRewardsInDay" Less Than 10;
    function setMaxRewardsInDay(uint256 _maxRewardsInDay) external onlyOwner {
        maxRewardsInDay = _maxRewardsInDay;
    }

    function setMinRewardAmount(uint256 _minRewardAmount) external onlyOwner {
        minRewardAmount = _minRewardAmount;
    }

    function setMinStableCoinSwapToETH(uint256 _minStableCoinSwapToETH)
        external
        onlyOwner
    {
        minStableCoinSwapToETH = _minStableCoinSwapToETH;
    }

    function setFixlineStackingContractAddress(
        address _fixlineStackingContractAddress
    ) external onlyOwner {
        fixlineStackingContractAddress = _fixlineStackingContractAddress;
    }

    function setUniswapV3SwapRouterContractAddress(
        address _uniswapV3SwapRouterAddress
    ) external onlyOwner {
        uniswapV3SwapRouterAddress = _uniswapV3SwapRouterAddress;
    }

    function setUniswapV2RouterAddress(address _uniswapV2RouterAddress)
        external
        onlyOwner
    {
        uniswapV2RouterAddress = _uniswapV2RouterAddress;
    }

    function setWETHAddress(address _WETHAddress) external onlyOwner {
        WETHAddress = _WETHAddress;
    }

    function setCapsTokenContract_Ins(address _capsTokenContractAddress)
        external
        onlyOwner
    {
        capsTokenContract_Ins = ICapsToken(_capsTokenContractAddress);
    }

    function setCapsStackingContract_Ins(address _capsStakingContractAddress)
        external
        onlyOwner
    {
        capsStakingContract_Ins = ICapsStaking(_capsStakingContractAddress);
    }

    function setStableCoinContract_Ins(address _stableCoinContractAddress)
        external
        onlyOwner
    {
        stableCoin_Ins = IERC20(_stableCoinContractAddress);
    }

    function approveToUniswapSwapRouter() external onlyOwner {
        stableCoin_Ins.approve(uniswapV3SwapRouterAddress, type(uint256).max);
    }

    /********** View Functions **********/

    function getCapsTokenAddress() external view returns (address) {
        return address(capsTokenContract_Ins);
    }

    function getCapsStackingAddress() external view returns (address) {
        return address(capsStakingContract_Ins);
    }

    function getStableCoinAddress() external view returns (address) {
        return address(stableCoin_Ins);
    }

    function getUserSlotNum(address userAddress, uint256 betId)
        public
        view
        returns (uint256)
    {
        address[] memory _slotTakers = betsData[betId].slotTakers;
        uint256 totalSlotTakers = _slotTakers.length;

        for (uint256 i; i < totalSlotTakers; ) {
            if (_slotTakers[i] == userAddress) {
                return i + 1;
            }
            unchecked {
                i++;
            }
        }
        return 0;
    }

    function getUserData(address userAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            int256,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (
            usersData[userAddress].ETHBalance,
            usersData[userAddress].ETHWithdrawableBalance,
            usersData[userAddress].stableCoinBalance,
            usersData[userAddress].stableCoinWithdrawableBalance,
            usersData[userAddress].reputation,
            usersData[userAddress].createdBets,
            usersData[userAddress].participatedInBets
        );
    }

    function getBetData(uint256 betId)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            address[] memory,
            bool[] memory
        )
    {
        return (
            betsData[betId].maker,
            betsData[betId].makerAmountPerSlot,
            betsData[betId].slotPrice,
            betsData[betId].expiryTime,
            betsData[betId].totalSlots,
            betsData[betId].slotTakers,
            betsData[betId].isLossClaimed
        );
    }

    function getIsETHBasedBet(uint256 betId) external view returns (bool) {
        return betsData[betId].isETHBased;
    }

    function getIsBetCancelled(uint256 betId) external view returns (bool) {
        return betsData[betId].isCancelled;
    }

    function getBetType(uint256 betId) external view returns (BetType) {
        return betsData[betId].betType;
    }

    function getBetTempData(uint256 betId)
        external
        view
        returns (bytes memory)
    {
        return betsData[betId].data;
    }

    // Note:- This Is Temp Function
    function withdrawFunds() external {
        payable(owner()).transfer(address(this).balance);
        stableCoin_Ins.transfer(
            owner(),
            stableCoin_Ins.balanceOf(address(this))
        );
    }
}

/* 
uniswapV2Router:- 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
uniswapSwapRouter:- 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
WMatic:- 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889
WETH:- 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa Note:- We Will Use It As Stable Coin 

CapsToken:- 0x5aCA1D308A87b2576F7e0fD9107f3EDdba896Ca8
CapsStacking:- 0x5134000F9FC09C123055B3FE10d7eD5526Fd62ae
FixlineBetting:- 0xA028E7C3566cb335405d16076db7BF43884Ac7DE
*/

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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