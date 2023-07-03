// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../../libraries/LibRetire.sol";
import "../../libraries/TokenSwap/LibSwap.sol";
import "../../ReentrancyGuard.sol";

contract RetireSourceFacet is ReentrancyGuard {
    event CarbonRetired(
        LibRetire.CarbonBridge carbonBridge,
        address indexed retiringAddress,
        string retiringEntityString,
        address indexed beneficiaryAddress,
        string beneficiaryString,
        string retirementMessage,
        address indexed carbonPool,
        address poolToken,
        uint retiredAmount
    );

    /* ========== Default Redemption Retirements ========== */

    /**
     * @notice                     Retires an exact amount of a source token using default redemption
     * @param sourceToken          Source ERC-20 token to use for the retirement
     * @param poolToken            Pool token to use for this retirement
     * @param maxAmountIn          Maximum amount of source tokens to spend in this retirement
     * @param retiringEntityString String description of the retiring entity
     * @param beneficiaryAddress   0x address for the beneficiary
     * @param beneficiaryString    String description of the beneficiary
     * @param retirementMessage    String message for this specific retirement
     * @param fromMode             From Mode for transfering tokens
     * @return retirementIndex     The latest retirement index for the beneficiary address
     */
    function retireExactSourceDefault(
        address sourceToken,
        address poolToken,
        uint maxAmountIn,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        LibTransfer.From fromMode
    ) external payable nonReentrant returns (uint retirementIndex) {
        require(maxAmountIn > 0, "Cannot retire zero tonnes");

        LibTransfer.receiveToken(IERC20(sourceToken), maxAmountIn, msg.sender, fromMode);

        /// @dev Initial value set assuming source == pool.
        uint totalCarbon = maxAmountIn;

        if (sourceToken != poolToken) {
            if (sourceToken == C.wsKlima()) {
                maxAmountIn = LibKlima.unwrapKlima(maxAmountIn);
            }
            if (sourceToken == C.sKlima()) LibKlima.unstakeKlima(maxAmountIn);

            totalCarbon = LibSwap.swapExactSourceToCarbonDefault(sourceToken, poolToken, maxAmountIn);
            require(totalCarbon > 0, "Swap returned nothing");
        }

        // Record the amount to retire based on the current fee.
        uint retireAmount = totalCarbon - LibRetire.getFee(totalCarbon);

        LibRetire.retireReceivedCarbon(
            poolToken,
            retireAmount,
            msg.sender,
            retiringEntityString,
            beneficiaryAddress,
            beneficiaryString,
            retirementMessage
        );

        // Send any aggregator fees to treasury
        if (totalCarbon - retireAmount > 0) {
            LibTransfer.sendToken(IERC20(poolToken), totalCarbon - retireAmount, C.treasury(), LibTransfer.To.EXTERNAL);
        }

        return LibRetire.getTotalRetirements(beneficiaryAddress);
    }

    /* ========== Specific Redemption Retirements ========== */

    /**
     * @notice                     Retires an exact amount of a source token using specific redemption
     * @param sourceToken          Source ERC-20 token to use for the retirement
     * @param poolToken            Pool token to use for this retirement
     * @param projectToken         Project token to redeem and retire
     * @param maxAmountIn          Maximum amount of source tokens to spend in this retirement
     * @param retiringEntityString String description of the retiring entity
     * @param beneficiaryAddress   0x address for the beneficiary
     * @param beneficiaryString    String description of the beneficiary
     * @param retirementMessage    String message for this specific retirement
     * @param fromMode             From Mode for transfering tokens
     * @return retirementIndex     The latest retirement index for the beneficiary address
     */
    function retireExactSourceSpecific(
        address sourceToken,
        address poolToken,
        address projectToken,
        uint maxAmountIn,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        LibTransfer.From fromMode
    ) external payable nonReentrant returns (uint retirementIndex) {
        require(maxAmountIn > 0, "Cannot retire zero tonnes");

        LibTransfer.receiveToken(IERC20(sourceToken), maxAmountIn, msg.sender, fromMode);

        /// @dev Initial value set assuming source == pool.
        uint totalCarbon = maxAmountIn;

        if (sourceToken != poolToken) {
            if (sourceToken == C.wsKlima()) {
                maxAmountIn = LibKlima.unwrapKlima(maxAmountIn);
            }
            if (sourceToken == C.sKlima()) LibKlima.unstakeKlima(maxAmountIn);

            totalCarbon = LibSwap.swapExactSourceToCarbonDefault(sourceToken, poolToken, maxAmountIn);
            require(totalCarbon > 0, "Swap returned nothing");
        }

        // Record the amount to retire based on the current fee.
        uint retireAmount = totalCarbon - LibRetire.getFee(totalCarbon);
        if (s.poolBridge[poolToken] == LibRetire.CarbonBridge.C3) {
            retireAmount = LibC3Carbon.getExactSourceSpecificRetireAmount(poolToken, retireAmount);
        }

        uint redeemedAmount = LibRetire.retireReceivedCarbonSpecificFromSource(
            poolToken,
            projectToken,
            retireAmount,
            msg.sender,
            retiringEntityString,
            beneficiaryAddress,
            beneficiaryString,
            retirementMessage
        );

        // Send any aggregator fees to treasury
        if (totalCarbon - redeemedAmount > 0) {
            LibTransfer.sendToken(
                IERC20(poolToken),
                totalCarbon - redeemedAmount,
                C.treasury(),
                LibTransfer.To.EXTERNAL
            );
        }

        return LibRetire.getTotalRetirements(beneficiaryAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @author Cujo
 * @title LibRetire
 */

import "../C.sol";
import "./LibAppStorage.sol";
import {LibMeta} from "./LibMeta.sol";
import "./Bridges/LibToucanCarbon.sol";
import "./Bridges/LibMossCarbon.sol";
import "./Bridges/LibC3Carbon.sol";
import "./Token/LibTransfer.sol";
import "./TokenSwap/LibSwap.sol";
import "../interfaces/IKlimaInfinity.sol";
import "../interfaces/IKlimaCarbonRetirements.sol";

library LibRetire {
    using LibTransfer for IERC20;
    using LibBalance for address payable;
    using LibApprove for IERC20;

    enum CarbonBridge {
        TOUCAN,
        MOSS,
        C3
    }

    /* ========== Default Redemption Retirements ========== */

    /**
     * @notice                     Retire received carbon based on the bridge of the provided pool tokens using default redemption
     * @param poolToken            Pool token used to retire
     * @param amount               The amount of carbon to retire
     * @param retiringEntityString String description of the retiring entity
     * @param beneficiaryAddress   0x address for the beneficiary
     * @param beneficiaryString    String description of the beneficiary
     * @param retirementMessage    String message for this specific retirement
     */
    function retireReceivedCarbon(
        address poolToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (s.poolBridge[poolToken] == CarbonBridge.TOUCAN) {
            LibToucanCarbon.redeemAutoAndRetire(
                poolToken,
                amount,
                retiringAddress,
                retiringEntityString,
                beneficiaryAddress,
                beneficiaryString,
                retirementMessage
            );
        } else if (s.poolBridge[poolToken] == CarbonBridge.MOSS) {
            LibMossCarbon.offsetCarbon(
                poolToken,
                amount,
                retiringAddress,
                retiringEntityString,
                beneficiaryAddress,
                beneficiaryString,
                retirementMessage
            );
        } else if (s.poolBridge[poolToken] == CarbonBridge.C3) {
            LibC3Carbon.freeRedeemAndRetire(
                poolToken,
                amount,
                retiringAddress,
                retiringEntityString,
                beneficiaryAddress,
                beneficiaryString,
                retirementMessage
            );
        }
    }

    /* ========== Specific Redemption Retirements ========== */

    /**
     * @notice                     Retire received carbon based on the bridge of the provided pool tokens using specific redemption
     * @param poolToken            Pool token used to retire
     * @param projectToken         Project token being retired
     * @param amount               The amount of carbon to retire
     * @param retiringEntityString String description of the retiring entity
     * @param beneficiaryAddress   0x address for the beneficiary
     * @param beneficiaryString    String description of the beneficiary
     * @param retirementMessage    String message for this specific retirement
     */
    function retireReceivedExactCarbonSpecific(
        address poolToken,
        address projectToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage
    ) internal returns (uint redeemedAmount) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(
            s.poolBridge[poolToken] == CarbonBridge.TOUCAN || s.poolBridge[poolToken] == CarbonBridge.C3,
            "Specific redeem not supported."
        );

        redeemedAmount = amount;

        if (s.poolBridge[poolToken] == CarbonBridge.TOUCAN) {
            redeemedAmount += LibToucanCarbon.getSpecificRedeemFee(poolToken, amount);
            LibToucanCarbon.redeemSpecificAndRetire(
                poolToken,
                projectToken,
                redeemedAmount,
                retiringAddress,
                retiringEntityString,
                beneficiaryAddress,
                beneficiaryString,
                retirementMessage
            );
        } else if (s.poolBridge[poolToken] == CarbonBridge.C3) {
            redeemedAmount += LibC3Carbon.getExactCarbonSpecificRedeemFee(poolToken, amount);

            LibC3Carbon.redeemSpecificAndRetire(
                poolToken,
                projectToken,
                amount,
                retiringAddress,
                retiringEntityString,
                beneficiaryAddress,
                beneficiaryString,
                retirementMessage
            );
        }
    }

    /**
     * @notice                     Additional function to handle the differences in wanting to fully retire x pool tokens specifically
     * @param poolToken            Pool token used to retire
     * @param projectToken         Project token being retired
     * @param amount               The amount of carbon to retire
     * @param retiringEntityString String description of the retiring entity
     * @param beneficiaryAddress   0x address for the beneficiary
     * @param beneficiaryString    String description of the beneficiary
     * @param retirementMessage    String message for this specific retirement
     * @return redeemedAmount      Number of pool tokens redeemed
     */
    function retireReceivedCarbonSpecificFromSource(
        address poolToken,
        address projectToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage
    ) internal returns (uint redeemedAmount) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(
            s.poolBridge[poolToken] == CarbonBridge.TOUCAN || s.poolBridge[poolToken] == CarbonBridge.C3,
            "Specific redeem not supported."
        );

        redeemedAmount = amount;

        if (s.poolBridge[poolToken] == CarbonBridge.TOUCAN) {
            LibToucanCarbon.redeemSpecificAndRetire(
                poolToken,
                projectToken,
                amount,
                retiringAddress,
                retiringEntityString,
                beneficiaryAddress,
                beneficiaryString,
                retirementMessage
            );
        } else if (s.poolBridge[poolToken] == CarbonBridge.C3) {
            redeemedAmount += LibC3Carbon.getExactCarbonSpecificRedeemFee(poolToken, amount);
            LibC3Carbon.redeemSpecificAndRetire(
                poolToken,
                projectToken,
                amount,
                retiringAddress,
                retiringEntityString,
                beneficiaryAddress,
                beneficiaryString,
                retirementMessage
            );
        }
    }

    /* ========== Helper Functions ========== */

    /* ========== Common Functions ========== */

    /**
     * @notice                  Returns the total carbon needed fee included
     * @param retireAmount      Pool token used to retire
     * @return totalCarbon      Total pool token needed
     */
    function getTotalCarbon(uint retireAmount) internal view returns (uint totalCarbon) {
        return retireAmount + getFee(retireAmount);
    }

    /**
     * @notice                  Returns the total carbon needed fee included
     * @param poolToken         Pool token used to retire
     * @param retireAmount      Amount of carbon wanting to retire
     * @return totalCarbon      Total pool token needed
     */
    function getTotalCarbonSpecific(address poolToken, uint retireAmount) internal view returns (uint totalCarbon) {
        // This is for exact carbon retirements
        AppStorage storage s = LibAppStorage.diamondStorage();

        totalCarbon = getTotalCarbon(retireAmount);

        if (s.poolBridge[poolToken] == CarbonBridge.TOUCAN) {
            totalCarbon += LibToucanCarbon.getSpecificRedeemFee(poolToken, retireAmount);
        } else if (s.poolBridge[poolToken] == CarbonBridge.C3) {
            totalCarbon += LibC3Carbon.getExactCarbonSpecificRedeemFee(poolToken, retireAmount);
        }
    }

    /**
     * @notice                  Returns the total fee needed to retire x number of tokens
     * @param carbonAmount      Amount being retired
     * @return fee              Total fee charged
     */
    function getFee(uint carbonAmount) internal view returns (uint fee) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        fee = (carbonAmount * s.fee) / 100_000;
    }

    /**
     * @notice                      Saves the details of the retirement over to KlimaCarbonRetirements and project details within AppStorage
     * @param poolToken             Pool token used to retire
     * @param projectToken          Pool token used to retire
     * @param amount                Amount of carbon wanting to retire
     * @param beneficiaryAddress    0x address for the beneficiary
     * @param beneficiaryString     String description of the beneficiary
     * @param retirementMessage     String message for this specific retirement
     */
    function saveRetirementDetails(
        address poolToken,
        address projectToken,
        uint amount,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        (uint currentRetirementIndex,,) =
            IKlimaCarbonRetirements(C.klimaCarbonRetirements()).getRetirementTotals(beneficiaryAddress);

        // Save the base details of the retirement
        IKlimaCarbonRetirements(C.klimaCarbonRetirements()).carbonRetired(
            beneficiaryAddress, poolToken, amount, beneficiaryString, retirementMessage
        );

        // Save the details of the retirement
        s.a[beneficiaryAddress].retirements[currentRetirementIndex].projectTokenAddress = projectToken;
        s.a[beneficiaryAddress].totalProjectRetired[projectToken] += amount;
    }

    /* ========== Account Getters ========== */

    function getTotalRetirements(address account) internal view returns (uint totalRetirements) {
        (totalRetirements,,) = IKlimaCarbonRetirements(C.klimaCarbonRetirements()).getRetirementTotals(account);
    }

    function getTotalCarbonRetired(address account) internal view returns (uint totalCarbonRetired) {
        (, totalCarbonRetired,) = IKlimaCarbonRetirements(C.klimaCarbonRetirements()).getRetirementTotals(account);
    }

    function getTotalPoolRetired(address account, address poolToken) internal view returns (uint totalPoolRetired) {
        return IKlimaCarbonRetirements(C.klimaCarbonRetirements()).getRetirementPoolInfo(account, poolToken);
    }

    function getTotalProjectRetired(address account, address projectToken) internal view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.a[account].totalProjectRetired[projectToken];
    }

    function getTotalRewardsClaimed(address account) internal view returns (uint totalClaimed) {
        (,, totalClaimed) = IKlimaCarbonRetirements(C.klimaCarbonRetirements()).getRetirementTotals(account);
    }

    function getRetirementDetails(address account, uint retirementIndex)
        internal
        view
        returns (
            address poolTokenAddress,
            address projectTokenAddress,
            address beneficiaryAddress,
            string memory beneficiary,
            string memory retirementMessage,
            uint amount
        )
    {
        (poolTokenAddress, amount, beneficiary, retirementMessage) =
            IKlimaCarbonRetirements(C.klimaCarbonRetirements()).getRetirementIndexInfo(account, retirementIndex);
        beneficiaryAddress = account;

        AppStorage storage s = LibAppStorage.diamondStorage();
        projectTokenAddress = s.a[account].retirements[retirementIndex].projectTokenAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @author Cujo
 * @title LibSwap
 */

import "../../C.sol";
import "../LibAppStorage.sol";
import "../LibKlima.sol";
import "../Token/LibTransfer.sol";
import "./LibUniswapV2Swap.sol";
import "./LibTridentSwap.sol";
import "./LibTreasurySwap.sol";

library LibSwap {
    using LibTransfer for IERC20;

    /* ========== Swap to Exact Carbon Default Functions ========== */

    /**
     * @notice                      Swaps to an exact number of carbon tokens
     * @param sourceToken           Source token provided to swap
     * @param carbonToken           Pool token needed
     * @param sourceAmount          Max amount of the source token
     * @param carbonAmount          Needed amount of tokens out
     * @return carbonReceived       Pool tokens actually received
     */
    function swapToExactCarbonDefault(
        address sourceToken,
        address carbonToken,
        uint sourceAmount,
        uint carbonAmount
    ) internal returns (uint carbonReceived) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // If providing a staked version of Klima, update sourceToken to use Klima default path.
        if (sourceToken == C.sKlima() || sourceToken == C.wsKlima()) sourceToken = C.klima();

        // If source token is not defined in the default, swap to USDC on Sushiswap.
        // This is wrapped in its own statement to allow for the fewest number of swaps
        if (s.swap[carbonToken][sourceToken].swapDexes.length == 0) {
            address[] memory firstPath = new address[](s.swap[carbonToken][C.usdc()].swapPaths[0].length + 1);
            firstPath[0] = sourceToken;
            for (uint8 i = 0; i < s.swap[carbonToken][C.usdc()].swapPaths[0].length; ++i) {
                firstPath[i + 1] = s.swap[carbonToken][C.usdc()].swapPaths[0][i];
            }

            // Now that we have added to the initial USDC path, set the sourceToken to USDC and proceed as normal.
            sourceToken = C.usdc();

            // Single DEX swap
            if (s.swap[carbonToken][sourceToken].swapDexes.length == 1) {
                return
                    _performToExactSwap(
                        s.swap[carbonToken][sourceToken].swapDexes[0],
                        s.swap[carbonToken][sourceToken].ammRouters[0],
                        firstPath,
                        sourceAmount,
                        carbonAmount
                    );
            }

            // Multiple DEX swap
            uint256[] memory amountsIn = getMultipleSourceAmount(sourceToken, carbonToken, carbonAmount);
            carbonReceived = sourceAmount;
            for (uint256 i = 0; i < s.swap[carbonToken][sourceToken].swapDexes.length; ++i) {
                carbonReceived = _performToExactSwap(
                    s.swap[carbonToken][sourceToken].swapDexes[i],
                    s.swap[carbonToken][sourceToken].ammRouters[i],
                    i == 0 ? firstPath : s.swap[carbonToken][sourceToken].swapPaths[uint8(i)],
                    carbonReceived,
                    i + 1 == s.swap[carbonToken][sourceToken].swapDexes.length ? carbonAmount : amountsIn[i + 1]
                );
            }
            return carbonReceived;
        }

        // Single DEX swap
        if (s.swap[carbonToken][sourceToken].swapDexes.length == 1) {
            return
                _performToExactSwap(
                    s.swap[carbonToken][sourceToken].swapDexes[0],
                    s.swap[carbonToken][sourceToken].ammRouters[0],
                    s.swap[carbonToken][sourceToken].swapPaths[0],
                    sourceAmount,
                    carbonAmount
                );
        }

        // Multiple DEX swap
        uint256[] memory amountsIn = getMultipleSourceAmount(sourceToken, carbonToken, carbonAmount);
        carbonReceived = sourceAmount;
        for (uint256 i = 0; i < s.swap[carbonToken][sourceToken].swapDexes.length; ++i) {
            carbonReceived = _performToExactSwap(
                s.swap[carbonToken][sourceToken].swapDexes[i],
                s.swap[carbonToken][sourceToken].ammRouters[i],
                s.swap[carbonToken][sourceToken].swapPaths[uint8(i)],
                carbonReceived,
                i + 1 == s.swap[carbonToken][sourceToken].swapDexes.length ? carbonAmount : amountsIn[i + 1]
            );
        }
        return carbonReceived;
    }

    /* ========== Swap to Exact Source Default Functions ========== */

    /**
     * @notice                      Swaps to an exact number of source tokens
     * @param sourceToken           Source token provided to swap
     * @param carbonToken           Pool token needed
     * @param amount                Amount of the source token to swap
     * @return carbonReceived       Pool tokens actually received
     */
    function swapExactSourceToCarbonDefault(
        address sourceToken,
        address carbonToken,
        uint amount
    ) internal returns (uint carbonReceived) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // If providing a staked version of Klima, update sourceToken to use Klima default path.
        if (sourceToken == C.sKlima() || sourceToken == C.wsKlima()) sourceToken = C.klima();

        // If source token is not defined in the default, swap to USDC on Sushiswap.
        // Then use the USDC default path.
        if (s.swap[carbonToken][sourceToken].swapDexes.length == 0) {
            address[] memory path = new address[](2);
            path[0] = sourceToken;
            path[1] = C.usdc();

            amount = _performExactSourceSwap(
                s.swap[carbonToken][C.usdc()].swapDexes[0],
                s.swap[carbonToken][C.usdc()].ammRouters[0],
                path,
                amount
            );
            // Now that we have USDC, set the sourceToken to USDC and proceed as normal.
            sourceToken = C.usdc();
        }

        // Single DEX swap
        if (s.swap[carbonToken][sourceToken].swapDexes.length == 1) {
            return
                _performExactSourceSwap(
                    s.swap[carbonToken][sourceToken].swapDexes[0],
                    s.swap[carbonToken][sourceToken].ammRouters[0],
                    s.swap[carbonToken][sourceToken].swapPaths[0],
                    amount
                );
        }

        // Multiple DEX swap
        uint256 currentOutput;
        for (uint256 i = 0; i < s.swap[carbonToken][sourceToken].swapDexes.length; ++i) {
            currentOutput = _performExactSourceSwap(
                s.swap[carbonToken][sourceToken].swapDexes[i],
                s.swap[carbonToken][sourceToken].ammRouters[i],
                s.swap[carbonToken][sourceToken].swapPaths[uint8(i)],
                i == 0 ? amount : currentOutput
            );
        }
        return currentOutput;
    }

    /**
     * @notice                  Return any dust/slippaged amounts still held by the contract
     * @param sourceToken       Source token provided to swap
     * @param poolToken         Pool token used
     */
    function returnTradeDust(address sourceToken, address poolToken) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        address dustToken = sourceToken;
        if (sourceToken == C.wsKlima() || sourceToken == C.sKlima()) dustToken = C.klima();
        else if (s.swap[poolToken][sourceToken].swapDexes.length == 0) {
            dustToken = C.usdc();
            sourceToken = C.usdc();
        }

        uint256 dustBalance = IERC20(dustToken).balanceOf(address(this));

        if (dustBalance != 0) {
            if (sourceToken == C.wsKlima()) dustBalance = LibKlima.wrapKlima(dustBalance);
            if (sourceToken == C.sKlima()) LibKlima.stakeKlima(dustBalance);

            LibTransfer.sendToken(IERC20(sourceToken), dustBalance, msg.sender, LibTransfer.To.EXTERNAL);
        }
    }

    /* ========== Smaller Specific Swap Functions ========== */

    /**
     * @notice                  Swaps a given amount of USDC for KLIMA using Sushiswap
     * @param sourceAmount      Amount of USDC to swap
     * @param klimaAmount       Amount of KLIMA to swap for
     * @return klimaReceived    Amount of KLIMA received
     */
    function swapToKlimaFromUsdc(uint256 sourceAmount, uint256 klimaAmount) internal returns (uint256 klimaReceived) {
        address[] memory path = new address[](2);
        path[0] = C.usdc();
        path[1] = C.klima();

        return _performToExactSwap(0, C.sushiRouter(), path, sourceAmount, klimaAmount);
    }

    /**
     * @notice                  Swaps from arbitrary token routed through USDC for KLIMA
     * @param sourceToken       Source token provided to swap
     * @param sourceAmount      Amount of source token to swap
     * @param klimaAmount       Amount of KLIMA to swap for
     * @return klimaReceived    Amount of KLIMA received
     */
    function swapToKlimaFromOther(address sourceToken, uint256 sourceAmount, uint256 klimaAmount)
        internal
        returns (uint256 klimaReceived)
    {
        address[] memory path = new address[](3);
        path[0] = sourceToken;
        path[1] = C.usdc();
        path[2] = C.klima();
        return _performToExactSwap(0, C.sushiRouter(), path, sourceAmount, klimaAmount);
    }

    /**
     * @notice                  Performs a swap with Retirement Bonds for carbon to retire.
     * @param sourceToken       Source token provided to swap
     * @param carbonToken       Carbon token to receive
     * @param sourceAmount      Amount of source token to swap
     * @param carbonAmount      Amount of carbon token needed
     * @return carbonRecieved   Amount of carbon token received from the swap
     */
    function swapWithRetirementBonds(
        address sourceToken,
        address carbonToken,
        uint256 sourceAmount,
        uint256 carbonAmount
    ) internal returns (uint256 carbonRecieved) {
        // Any form of KLIMA should be unwrapped/unstaked before this is called.
        if (sourceToken == C.klima() || sourceToken == C.sKlima() || sourceToken == C.wsKlima()) {
            LibTreasurySwap.swapToExact(carbonToken, sourceAmount, carbonAmount);
            return carbonAmount;
        }

        // The only other source tokens at this point should be USDC or non-KLIMA and non-Pool tokens

        if (sourceToken == C.usdc()) {
            sourceAmount = swapToKlimaFromUsdc(sourceAmount, LibTreasurySwap.getAmountIn(carbonToken, carbonAmount));
        } else {
            sourceAmount =
                swapToKlimaFromOther(sourceToken, sourceAmount, LibTreasurySwap.getAmountIn(carbonToken, carbonAmount));
        }

        LibTreasurySwap.swapToExact(carbonToken, sourceAmount, carbonAmount);
        return carbonAmount;
    }

    /* ========== Source Amount View Functions ========== */

    /**
     * @notice                  Get the source amount needed when swapping within a single DEX
     * @param sourceToken       Source token provided to swap
     * @param carbonToken       Pool token used
     * @param amount            Amount of carbon tokens needed
     * @return sourceNeeded     Total source tokens needed for output amount
     */
    function getSourceAmount(
        address sourceToken,
        address carbonToken,
        uint amount
    ) internal view returns (uint sourceNeeded) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint8 wrapped;
        if (sourceToken == C.wsKlima()) wrapped = 1;
        if (sourceToken == C.sKlima() || sourceToken == C.wsKlima()) sourceToken = C.klima();

        if (s.swap[carbonToken][sourceToken].swapDexes.length == 1) {
            if (wrapped == 0) {
                return
                    _getAmountIn(
                        s.swap[carbonToken][sourceToken].swapDexes[0],
                        s.swap[carbonToken][sourceToken].ammRouters[0],
                        s.swap[carbonToken][sourceToken].swapPaths[0],
                        amount
                    );
            }

            return
                LibKlima.toWrappedAmount(
                    _getAmountIn(
                        s.swap[carbonToken][sourceToken].swapDexes[0],
                        s.swap[carbonToken][sourceToken].ammRouters[0],
                        s.swap[carbonToken][sourceToken].swapPaths[0],
                        amount
                    )
                );
        } else if (s.swap[carbonToken][sourceToken].swapDexes.length > 1) {
            uint256[] memory amountsIn = getMultipleSourceAmount(sourceToken, carbonToken, amount);
            if (wrapped == 0) return amountsIn[0];
            return LibKlima.toWrappedAmount(amountsIn[0]);
        } else {
            uint256 usdcAmount = getSourceAmount(C.usdc(), carbonToken, amount);
            address[] memory usdcPath = new address[](2);
            usdcPath[0] = sourceToken;
            usdcPath[1] = C.usdc();
            // Swap to USDC on Sushiswap
            return _getAmountIn(0, C.sushiRouter(), usdcPath, usdcAmount);
        }
    }

    /**
     * @notice                  Get the source amount needed when swapping between multiple DEXs
     * @param sourceToken       Source token provided to swap
     * @param carbonToken       Pool token used
     * @param amount            Amount of carbon tokens needed
     * @return sourcesNeeded    Total source tokens needed for output amount
     */
    function getMultipleSourceAmount(
        address sourceToken,
        address carbonToken,
        uint amount
    ) internal view returns (uint[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256[] memory sourcesNeeded = new uint256[](s.swap[carbonToken][sourceToken].swapDexes.length);
        uint256 currentAmount = amount;
        for (uint256 i = 0; i < s.swap[carbonToken][sourceToken].swapDexes.length; ++i) {
            // Work backwards from the path definitions to get total source amount
            uint8 index = uint8(s.swap[carbonToken][sourceToken].swapDexes.length - 1 - i);

            sourcesNeeded[s.swap[carbonToken][sourceToken].swapDexes.length - 1 - i] = _getAmountIn(
                s.swap[carbonToken][sourceToken].swapDexes[index],
                s.swap[carbonToken][sourceToken].ammRouters[index],
                s.swap[carbonToken][sourceToken].swapPaths[index],
                currentAmount
            );

            currentAmount = sourcesNeeded[s.swap[carbonToken][sourceToken].swapDexes.length - 1 - i];
        }

        return sourcesNeeded;
    }

    /**
     * @notice                  Fetches the amount of KLIMA needed for a retirement bond, then calculates the source
     *                          amount needed if a DEX swap is required.
     * @param sourceToken       Source token provided to swap
     * @param carbonToken       Pool token used
     * @param amount            Amount of carbon tokens needed
     * @return sourceNeeded     Total source tokens needed for output amount
     */
     function getSourceAmountFromRetirementBond(
        address sourceToken,
        address carbonToken,
        uint256 amount
    ) internal view returns (uint256 sourceNeeded) {
        // Return the direct quote in KLIMA first
        if (sourceToken == C.klima() || sourceToken == C.sKlima())
            return LibTreasurySwap.getAmountIn(carbonToken,amount);

        // Wrap the amount if using wsKLIMA
        if (sourceToken == C.wsKlima())
            return LibKlima.toWrappedAmount(LibTreasurySwap.getAmountIn(carbonToken,amount));

        // Direct swap from USDC to KLIMA on Sushi
        if (sourceToken == C.usdc()) {
            uint256 klimaAmount = LibTreasurySwap.getAmountIn(carbonToken,amount);
            
            address[] memory path = new address[](2);
            path[0] = C.usdc();
            path[1] = C.klima();
            
            return LibUniswapV2Swap.getAmountIn(C.sushiRouter(), path, klimaAmount);
        }

        // At this point we only have non USDC and not KLIMA tokens. Route through a source <> USDC pool on Sushi
        uint256 klimaAmount = LibTreasurySwap.getAmountIn(carbonToken,amount);
        
        address[] memory path = new address[](3);
        path[0] = sourceToken;
        path[1] = C.usdc();
        path[2] = C.klima();
            
        return LibUniswapV2Swap.getAmountIn(C.sushiRouter(), path, klimaAmount);
    }

    /* ========== Output Amount View Functions ========== */

    /**
     * @notice                  Get the source amount needed when swapping between multiple DEXs
     * @param sourceToken       Source token provided to swap
     * @param carbonToken       Pool token used
     * @param amount            Amount of carbon tokens needed
     * @return amountOut        Amount of carbonTokens recieved for the input amount
     */
    function getDefaultAmountOut(
        address sourceToken,
        address carbonToken,
        uint amount
    ) internal view returns (uint amountOut) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        amountOut = amount;

        if (sourceToken == C.wsKlima()) amountOut = LibKlima.toUnwrappedAmount(amount);
        if (sourceToken == C.sKlima() || sourceToken == C.wsKlima()) sourceToken = C.klima();

        for (uint8 i = 0; i < s.swap[carbonToken][sourceToken].swapDexes.length; ++i) {
            amountOut = _getAmountOut(
                s.swap[carbonToken][sourceToken].swapDexes[i],
                s.swap[carbonToken][sourceToken].ammRouters[i],
                s.swap[carbonToken][sourceToken].swapPaths[i],
                amountOut
            );
        }
    }

    /* ========== Private Functions ========== */

    /**
     * @notice              Perform a toExact swap depending on the dex provided
     * @param dex           Identifier for which DEX to use
     * @param router        Router for the swap
     * @param path          Trade path to use
     * @param maxAmountIn   Max amount of source tokens to swap
     * @param amount        Total pool tokens needed
     * @return amountOut    Total pool tokens swapped
     */
    function _performToExactSwap(
        uint8 dex,
        address router,
        address[] memory path,
        uint maxAmountIn,
        uint amount
    ) private returns (uint amountOut) {
        // UniswapV2 is DEX ID 0
        if (dex == 0) {
            amountOut = LibUniswapV2Swap.swapTokensForExactTokens(router, path, maxAmountIn, amount);
        }
        if (dex == 1) {
            amountOut = LibTridentSwap.swapExactTokensForTokens(
                router,
                LibTridentSwap.getTridentPool(path[0], path[1]),
                path[0],
                LibTridentSwap.getAmountIn(LibTridentSwap.getTridentPool(path[0], path[1]), path[0], path[1], amount),
                amount
            );
        }

        return amountOut;
    }

    /**
     * @notice              Perform a swap using all source tokens
     * @param dex           Identifier for which DEX to use
     * @param router        Router for the swap
     * @param path          Trade path to use
     * @param amount        Amount of tokens to swap
     * @return amountOut    Total pool tokens swapped
     */
    function _performExactSourceSwap(
        uint8 dex,
        address router,
        address[] memory path,
        uint amount
    ) private returns (uint amountOut) {
        // UniswapV2 is DEX ID 0
        if (dex == 0) {
            amountOut = LibUniswapV2Swap.swapExactTokensForTokens(router, path, amount);
        } else if (dex == 1) {
            amountOut = LibTridentSwap.swapExactTokensForTokens(
                router,
                LibTridentSwap.getTridentPool(path[0], path[1]),
                path[0],
                amount,
                1
            );
        }

        return amountOut;
    }

    /**
     * @notice              Return the amountIn needed for an exact swap
     * @param dex           Identifier for which DEX to use
     * @param router        Router for the swap
     * @param path          Trade path to use
     * @param amount        Total pool tokens needed
     * @return amountIn     Total pool tokens swapped
     */
    function _getAmountIn(
        uint8 dex,
        address router,
        address[] memory path,
        uint amount
    ) private view returns (uint amountIn) {
        if (dex == 0) {
            amountIn = LibUniswapV2Swap.getAmountIn(router, path, amount);
        } else if (dex == 1) {
            amountIn = LibTridentSwap.getAmountIn(
                LibTridentSwap.getTridentPool(path[0], path[1]),
                path[0],
                path[1],
                amount
            );
        }
    }

    /**
     * @notice              Return the amountIn needed for an exact swap
     * @param dex           Identifier for which DEX to use
     * @param router        Router for the swap
     * @param path          Trade path to use
     * @param amount        Total source tokens spent
     * @return amountOut    Total pool tokens swapped
     */
    function _getAmountOut(
        uint8 dex,
        address router,
        address[] memory path,
        uint amount
    ) private view returns (uint amountOut) {
        if (dex == 0) {
            amountOut = LibUniswapV2Swap.getAmountOut(router, path, amount);
        } else if (dex == 1) {
            amountOut = LibTridentSwap.getAmountOut(
                LibTridentSwap.getTridentPool(path[0], path[1]),
                path[0],
                path[1],
                amount
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./AppStorage.sol";

/**
 * @author Beanstalk Farms
 * @title Variation of Oepn Zeppelins reentrant guard to include Silo Update
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts%2Fsecurity%2FReentrancyGuard.sol
 *
 */
abstract contract ReentrancyGuard {
    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;

    AppStorage internal s;

    modifier nonReentrant() {
        require(s.reentrantStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        s.reentrantStatus = _ENTERED;
        _;
        s.reentrantStatus = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author Cujo
 * @title C holds the constants for Klima Infinity
 */

library C {
    // Chain
    uint private constant CHAIN_ID = 137; // Polygon

    // Klima Protocol Contracts
    address private constant KLIMA = 0x4e78011Ce80ee02d2c3e649Fb657E45898257815;
    address private constant SKLIMA = 0xb0C22d8D350C67420f06F48936654f567C73E8C8;
    address private constant WSKLIMA = 0x6f370dba99E32A3cAD959b341120DB3C9E280bA6;
    address private constant STAKING = 0x25d28a24Ceb6F81015bB0b2007D795ACAc411b4d;
    address private constant STAKING_HELPER = 0x4D70a031Fc76DA6a9bC0C922101A05FA95c3A227;
    address private constant TREASURY = 0x7Dd4f0B986F032A44F913BF92c9e8b7c17D77aD7;

    // Standard Swap ERC20s
    address private constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    // DEX Router Addresses
    address private constant SUSHI_POLYGON = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address private constant QUICKSWAP_POLYGON = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address private constant SUSHI_BENTO = 0x0319000133d3AdA02600f0875d2cf03D442C3367;
    address private constant SUSHI_TRIDENT_POLYGON = 0xc5017BE80b4446988e8686168396289a9A62668E;

    /* Carbon Pools */
    // Toucan
    address private constant BCT = 0x2F800Db0fdb5223b3C3f354886d907A671414A7F;
    address private constant NCT = 0xD838290e877E0188a4A44700463419ED96c16107;

    // Moss
    address private constant MCO2 = 0xAa7DbD1598251f856C12f63557A4C4397c253Cea;

    // C3
    address private constant UBO = 0x2B3eCb0991AF0498ECE9135bcD04013d7993110c;
    address private constant NBO = 0x6BCa3B77C1909Ce1a4Ba1A20d1103bDe8d222E48;

    // Other important addresses
    address private constant TOUCAN_RETIRE_CERT = 0x5e377f16E4ec6001652befD737341a28889Af002;
    address private constant MOSS_CARBON_CHAIN = 0xeDAEFCf60e12Bd331c092341D5b3d8901C1c05A8;
    address private constant KLIMA_CARBON_RETIREMENTS = 0xac298CD34559B9AcfaedeA8344a977eceff1C0Fd;
    address private constant KLIMA_RETIREMENT_BOND = 0xa595f0d598DaF144e5a7ca91E6D9A5bAA09dDeD0;

    function toucanCert() internal pure returns (address) {
        return TOUCAN_RETIRE_CERT;
    }

    function mossCarbonChain() internal pure returns (address) {
        return MOSS_CARBON_CHAIN;
    }

    function staking() internal pure returns (address) {
        return STAKING;
    }

    function stakingHelper() internal pure returns (address) {
        return STAKING_HELPER;
    }

    function treasury() internal pure returns (address) {
        return TREASURY;
    }

    function klima() internal pure returns (address) {
        return KLIMA;
    }

    function sKlima() internal pure returns (address) {
        return SKLIMA;
    }

    function wsKlima() internal pure returns (address) {
        return WSKLIMA;
    }

    function usdc() internal pure returns (address) {
        return USDC;
    }

    function bct() internal pure returns (address) {
        return BCT;
    }

    function nct() internal pure returns (address) {
        return NCT;
    }

    function mco2() internal pure returns (address) {
        return MCO2;
    }

    function ubo() internal pure returns (address) {
        return UBO;
    }

    function nbo() internal pure returns (address) {
        return NBO;
    }

    function sushiRouter() internal pure returns (address) {
        return SUSHI_POLYGON;
    }

    function quickswapRouter() internal pure returns (address) {
        return QUICKSWAP_POLYGON;
    }

    function sushiTridentRouter() internal pure returns (address) {
        return SUSHI_TRIDENT_POLYGON;
    }

    function sushiBento() internal pure returns (address) {
        return SUSHI_BENTO;
    }

    function klimaCarbonRetirements() internal pure returns (address) {
        return KLIMA_CARBON_RETIREMENTS;
    }

    function klimaRetirementBond() internal pure returns (address) {
        return KLIMA_RETIREMENT_BOND;
    }
}

/*
 SPDX-License-Identifier: MIT*/

pragma solidity ^0.8.16;

import "../AppStorage.sol";

/**
 * @author Publius
 * @title App Storage Library allows libaries to access Klima Infinity's state.
 *
 */
library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32 domainSeparator_)
    {
        domainSeparator_ = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this)
            )
        );
    }

    function getChainID() internal view returns (uint id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../../C.sol";
import "oz/token/ERC721/IERC721.sol";
import "../../interfaces/IToucan.sol";
import "../LibAppStorage.sol";
import "../LibRetire.sol";
import "../Token/LibTransfer.sol";
import "../LibMeta.sol";

/**
 * @author Cujo
 * @title LibToucanCarbon
 * Handles interactions with Toucan Protocol carbon
 */

library LibToucanCarbon {
    event CarbonRetired(
        LibRetire.CarbonBridge carbonBridge,
        address indexed retiringAddress,
        string retiringEntityString,
        address indexed beneficiaryAddress,
        string beneficiaryString,
        string retirementMessage,
        address indexed carbonPool,
        address carbonToken,
        uint retiredAmount
    );

    /**
     * @notice                      Redeems Toucan pool tokens using default redemtion and retires the TCO2
     * @param poolToken             Pool token to use for this retirement
     * @param amount                Amount of the project token to retire
     * @param retiringAddress       Address initiating this retirement
     * @param retiringEntityString  String description of the retiring entity
     * @param beneficiaryAddress    0x address for the beneficiary
     * @param beneficiaryString     String description of the beneficiary
     * @param retirementMessage     String message for this specific retirement
     */
    function redeemAutoAndRetire(
        address poolToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage
    ) internal {
        // Redeem pool tokens
        (address[] memory listTCO2, uint[] memory amounts) = IToucanPool(poolToken).redeemAuto2(amount);

        // Retire TCO2
        for (uint i = 0; i < listTCO2.length; i++) {
            if (amounts[i] == 0) continue;

            retireTCO2(
                poolToken,
                listTCO2[i],
                amounts[i],
                retiringAddress,
                retiringEntityString,
                beneficiaryAddress,
                beneficiaryString,
                retirementMessage
            );
        }
    }

    /**
     * @notice                      Redeems Toucan pool tokens using specific redemtion and retires the TCO2
     * @param poolToken             Pool token to use for this retirement
     * @param projectToken          Project token to use for this retirement
     * @param amount                Amount of the project token to retire
     * @param retiringAddress       Address initiating this retirement
     * @param retiringEntityString  String description of the retiring entity
     * @param beneficiaryAddress    0x address for the beneficiary
     * @param beneficiaryString     String description of the beneficiary
     * @param retirementMessage     String message for this specific retirement
     * @return retiredAmount        The amount of TCO2 retired
     */
    function redeemSpecificAndRetire(
        address poolToken,
        address projectToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage
    ) internal returns (uint retiredAmount) {
        // Redeem pool tokens
        // Put redemption address into arrays for calling the redeem.
        address[] memory projectTokens = new address[](1);
        projectTokens[0] = projectToken;

        uint[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        // Fetch balances, redeem, and update for net amount of TCO2 received from redemption.
        uint beforeBalance = IERC20(projectToken).balanceOf(address(this));
        IToucanPool(poolToken).redeemMany(projectTokens, amounts);
        amount = IERC20(projectToken).balanceOf(address(this)) - beforeBalance;

        // Retire TCO2
        retireTCO2(
            poolToken,
            projectToken,
            amount,
            retiringAddress,
            retiringEntityString,
            beneficiaryAddress,
            beneficiaryString,
            retirementMessage
        );
        return amount;
    }

    /**
     * @notice                      Redeems Toucan TCO2s
     * @param poolToken             Pool token to use for this retirement
     * @param projectToken          Project token to use for this retirement
     * @param amount                Amount of the project token to retire
     * @param retiringAddress       Address initiating this retirement
     * @param retiringEntityString  String description of the retiring entity
     * @param beneficiaryAddress    0x address for the beneficiary
     * @param beneficiaryString     String description of the beneficiary
     * @param retirementMessage     String message for this specific retirement
     */
    function retireTCO2(
        address poolToken,
        address projectToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage
    ) internal {
        IToucanCarbonOffsets(projectToken).retireAndMintCertificate(
            retiringEntityString,
            beneficiaryAddress,
            beneficiaryString,
            retirementMessage,
            amount
        );

        LibRetire.saveRetirementDetails(
            poolToken,
            projectToken,
            amount,
            beneficiaryAddress,
            beneficiaryString,
            retirementMessage
        );

        emit CarbonRetired(
            LibRetire.CarbonBridge.TOUCAN,
            retiringAddress,
            retiringEntityString,
            beneficiaryAddress,
            beneficiaryString,
            retirementMessage,
            poolToken,
            projectToken,
            amount
        );

        sendRetireCert(beneficiaryAddress);
    }

    /**
     * @notice                      Send the ERC-721 retirement certificate received to a beneficiary
     * @param _beneficiary          Beneficiary to send the certificate to
     */
    function sendRetireCert(address _beneficiary) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // Transfer the latest ERC721 retirement token to the beneficiary
        IERC721(C.toucanCert()).safeTransferFrom(address(this), _beneficiary, s.lastERC721Received);
    }

    /**
     * @notice                      Calculates the additional pool tokens needed to specifically redeem x TCO2s
     * @param poolToken             Pool token to redeem
     * @param amount                Amount of TCO2 needed
     * @return poolFeeAmount        Number of additional pool tokens needed
     */
    function getSpecificRedeemFee(address poolToken, uint amount) internal view returns (uint poolFeeAmount) {
        bool feeExempt;

        try IToucanPool(poolToken).redeemFeeExemptedAddresses(address(this)) returns (bool result) {
            feeExempt = result;
        } catch {
            feeExempt = false;
        }

        if (feeExempt) {
            poolFeeAmount = 0;
        } else {
            uint feeRedeemBp = IToucanPool(poolToken).feeRedeemPercentageInBase();
            uint feeRedeemDivider = IToucanPool(poolToken).feeRedeemDivider();
            poolFeeAmount = ((amount * feeRedeemDivider) / (feeRedeemDivider - feeRedeemBp)) - amount;
        }
    }

    /**
     * @notice                      Returns the number of TCO2s retired when selectively redeeming x pool tokens
     * @param poolToken             Pool token to redeem
     * @param amount                Amount of pool tokens redeemed
     * @return retireAmount        Number TCO2s that can be retired.
     */
    function getSpecificRetireAmount(address poolToken, uint amount) internal view returns (uint retireAmount) {
        bool feeExempt;

        try IToucanPool(poolToken).redeemFeeExemptedAddresses(address(this)) returns (bool result) {
            feeExempt = result;
        } catch {
            feeExempt = false;
        }

        if (feeExempt) {
            retireAmount = amount;
        } else {
            uint feeRedeemBp = IToucanPool(poolToken).feeRedeemPercentageInBase();
            uint feeRedeemDivider = IToucanPool(poolToken).feeRedeemDivider();
            retireAmount = (amount * (feeRedeemDivider - feeRedeemBp)) / feeRedeemDivider;
        }
    }

    /**
     * @notice                      Simple wrapper to use redeem Toucan pools using the default list
     * @param poolToken             Pool token to redeem
     * @param amount                Amount of tokens being redeemed
     * @param toMode                Where to send TCO2 tokens
     * @return projectTokens        TCO2 token addresses redeemed
     * @return amounts              TCO2 token amounts redeemed
     */
    function redeemPoolAuto(
        address poolToken,
        uint amount,
        LibTransfer.To toMode
    ) internal returns (address[] memory projectTokens, uint[] memory amounts) {
        (projectTokens, amounts) = IToucanPool(poolToken).redeemAuto2(amount);
        for (uint i; i < projectTokens.length; i++) {
            LibTransfer.sendToken(IERC20(projectTokens[i]), amounts[i], msg.sender, toMode);
        }
    }

    /**
     * @notice                      Simple wrapper to use redeem Toucan pools using the specific list
     * @param poolToken             Pool token to redeem
     * @param projectTokens         Project tokens to redeem
     * @param amounts               Token amounts to redeem
     * @param toMode                Where to send TCO2 tokens
     * @return redeemedAmounts      TCO2 token amounts redeemed
     */
    function redeemPoolSpecific(
        address poolToken,
        address[] memory projectTokens,
        uint[] memory amounts,
        LibTransfer.To toMode
    ) internal returns (uint[] memory) {
        uint[] memory beforeBalances = new uint256[](projectTokens.length);
        uint[] memory redeemedAmounts = new uint256[](projectTokens.length);

        IToucanPool(poolToken).redeemMany(projectTokens, amounts);

        for (uint i; i < projectTokens.length; i++) {
            redeemedAmounts[i] = IERC20(projectTokens[i]).balanceOf(address(this)) - beforeBalances[i];
            LibTransfer.sendToken(IERC20(projectTokens[i]), redeemedAmounts[i], msg.sender, toMode);
        }
        return redeemedAmounts;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../../C.sol";
import "../LibRetire.sol";
import "../Token/LibApprove.sol";
import "../../interfaces/ICarbonChain.sol";

/**
 * @author Cujo
 * @title LibMossCarbon
 */

library LibMossCarbon {
    using LibApprove for IERC20;

    event CarbonRetired(
        LibRetire.CarbonBridge carbonBridge,
        address indexed retiringAddress,
        string retiringEntityString,
        address indexed beneficiaryAddress,
        string beneficiaryString,
        string retirementMessage,
        address indexed carbonPool,
        address carbonToken,
        uint retiredAmount
    );

    /**
     * @notice                      Retires Moss MCO2 tokens on Polygon
     * @param poolToken             Pool token to use for this retirement
     * @param amount                Amounts of the project tokens to retire
     * @param retiringAddress      Address initiating this retirement
     * @param retiringEntityString String description of the retiring entity
     * @param beneficiaryAddress   0x address for the beneficiary
     * @param beneficiaryString    String description of the beneficiary
     * @param retirementMessage    String message for this specific retirement
     */
    function offsetCarbon(
        address poolToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage
    ) internal {
        // Retire MCO2
        LibApprove.approveToken(IERC20(poolToken), C.mossCarbonChain(), amount);
        ICarbonChain(C.mossCarbonChain()).offsetCarbon(amount, retirementMessage, beneficiaryString);

        LibRetire.saveRetirementDetails(
            poolToken,
            address(0), // MCO2 does not have an underlying project token.
            amount,
            beneficiaryAddress,
            beneficiaryString,
            retirementMessage
        );

        emit CarbonRetired(
            LibRetire.CarbonBridge.MOSS,
            retiringAddress,
            retiringEntityString,
            beneficiaryAddress,
            beneficiaryString,
            retirementMessage,
            poolToken,
            address(0), // MCO2 does not have an underlying project token.
            amount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../LibRetire.sol";
import "../Token/LibTransfer.sol";
import "../../interfaces/IC3.sol";

import "lib/forge-std/src/console.sol";

/**
 * @author Cujo
 * @title LibC3Carbon
 */

library LibC3Carbon {
    event CarbonRetired(
        LibRetire.CarbonBridge carbonBridge,
        address indexed retiringAddress,
        string retiringEntityString,
        address indexed beneficiaryAddress,
        string beneficiaryString,
        string retirementMessage,
        address indexed carbonPool,
        address carbonToken,
        uint retiredAmount
    );

    /**
     * @notice                     Calls freeRedeem on a C3 pool and retires the underlying C3T
     * @param poolToken            Pool token to use for this retirement
     * @param amount               Amount of tokens to redeem and retire
     * @param retiringAddress      Address initiating this retirement
     * @param retiringEntityString String description of the retiring entity
     * @param beneficiaryAddress   0x address for the beneficiary
     * @param beneficiaryString    String description of the beneficiary
     * @param retirementMessage    String message for this specific retirement
     */
    function freeRedeemAndRetire(
        address poolToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage
    ) internal {
        address[] memory projectTokens = IC3Pool(poolToken).getFreeRedeemAddresses();

        // Redeem pool tokens
        IC3Pool(poolToken).freeRedeem(amount);

        // Retire C3T
        for (uint i = 0; i < projectTokens.length && amount > 0; i++) {
            uint balance = IERC20(projectTokens[i]).balanceOf(address(this));
            // Skip over any C3Ts returned that were not actually redeemed.
            if (balance == 0) continue;

            retireC3T(
                poolToken,
                projectTokens[i],
                balance,
                retiringAddress,
                retiringEntityString,
                beneficiaryAddress,
                beneficiaryString,
                retirementMessage
            );

            amount -= balance;
        }

        require(amount == 0, "Didn't retire all tons");
    }

    /**
     * @notice                     Calls taxedRedeem on a C3 pool and retires the underlying C3T
     * @param poolToken            Pool token to use for this retirement
     * @param projectToken         Project token being redeemed
     * @param amount               Amount of tokens to redeem and retire
     * @param retiringAddress      Address initiating this retirement
     * @param retiringEntityString String description of the retiring entity
     * @param beneficiaryAddress   0x address for the beneficiary
     * @param beneficiaryString    String description of the beneficiary
     * @param retirementMessage    String message for this specific retirement
     */
    function redeemSpecificAndRetire(
        address poolToken,
        address projectToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage
    ) internal {
        // Redeem pool tokens
        // C3 fee is additive, not subtractive

        // Put redemption address into arrays for calling the redeem.

        address[] memory projectTokens = new address[](1);
        projectTokens[0] = projectToken;

        uint[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        IC3Pool(poolToken).taxedRedeem(projectTokens, amounts);

        // Retire C3T
        retireC3T(
            poolToken,
            projectToken,
            amount,
            retiringAddress,
            retiringEntityString,
            beneficiaryAddress,
            beneficiaryString,
            retirementMessage
        );
    }

    /**
     * @notice                     Retire a C3T token
     * @param poolToken            Pool token to use for this retirement
     * @param projectToken         Project token being redeemed
     * @param amount               Amount of tokens to redeem and retire
     * @param retiringAddress      Address initiating this retirement
     * @param retiringEntityString String description of the retiring entity
     * @param beneficiaryAddress   0x address for the beneficiary
     * @param beneficiaryString    String description of the beneficiary
     * @param retirementMessage    String message for this specific retirement
     */
    function retireC3T(
        address poolToken,
        address projectToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage
    ) internal {
        IC3ProjectToken(projectToken).offsetFor(amount, beneficiaryAddress, beneficiaryString, retirementMessage);

        LibRetire.saveRetirementDetails(
            poolToken,
            projectToken,
            amount,
            beneficiaryAddress,
            beneficiaryString,
            retirementMessage
        );

        emit CarbonRetired(
            LibRetire.CarbonBridge.C3,
            retiringAddress,
            retiringEntityString,
            beneficiaryAddress,
            beneficiaryString,
            retirementMessage,
            poolToken,
            projectToken,
            amount
        );
    }

    /**
     * @notice                     Return the additional fee needed to redeem specific number of project tokens.
     * @param poolToken            Pool token to use for this retirement
     * @param amount               Amount of tokens to redeem and retire
     * @return poolFeeAmount       Additional C3 pool tokens needed for the redemption
     */
    function getExactCarbonSpecificRedeemFee(
        address poolToken,
        uint amount
    ) internal view returns (uint poolFeeAmount) {
        uint feeRedeem = IC3Pool(poolToken).feeRedeem();
        uint feeDivider = 10_000; // This is hardcoded in current C3 contract.

        poolFeeAmount = (amount * feeRedeem) / feeDivider;
    }

    /**
     * @notice                     Return the amount that can be specifically redeemed from a C3 given x number of tokens.
     * @param poolToken            Pool token to use for this retirement
     * @param amount               Amount of tokens to redeem and retire
     * @return retireAmount        Amount of C3T that can be specifically redeemed from a given pool amount
     */
    function getExactSourceSpecificRetireAmount(
        address poolToken,
        uint amount
    ) internal view returns (uint retireAmount) {
        // Backing into a redemption amount from a total pool token amount
        uint feeRedeem = IC3Pool(poolToken).feeRedeem();
        uint feeDivider = 10_000; // This is hardcoded in current C3 contract.

        retireAmount = (amount * feeDivider) / (feeDivider + feeRedeem);
    }

    /**
     * @notice                     Receives and redeems a number of pool tokens and sends the C3T to a destination..
     * @param poolToken            Pool token to use for this retirement
     * @param amount               Amount of tokens to redeem and retire
     * @param toMode               Where to send redeemed tokens to
     * @return allProjectTokens    Default redeem C3T list from the pool
     * @return amounts             Amount of C3T that was redeemed from the pool
     */
    function redeemPoolAuto(
        address poolToken,
        uint amount,
        LibTransfer.To toMode
    ) internal returns (address[] memory allProjectTokens, uint[] memory amounts) {
        allProjectTokens = IC3Pool(poolToken).getFreeRedeemAddresses();
        amounts = new uint256[](allProjectTokens.length);

        // Redeem pool tokens
        IC3Pool(poolToken).freeRedeem(amount);

        for (uint i = 0; i < allProjectTokens.length && amount > 0; i++) {
            uint balance = IERC20(allProjectTokens[i]).balanceOf(address(this));
            // Skip over any C3Ts returned that were not actually redeemed.
            if (balance == 0) continue;

            amounts[i] = balance;

            LibTransfer.sendToken(IERC20(allProjectTokens[i]), balance, msg.sender, toMode);
            amount -= balance;
        }

        require(amount == 0, "Didn't redeem all tons");
    }

    /**
     * @notice                      Receives and redeems a number of pool tokens and sends the C3T to a destination.
     * @param poolToken             Pool token to use for this retirement
     * @param projectTokens         Project tokens to redeem
     * @param amounts               Amounts of the project tokens to redeem
     * @param toMode                Where to send redeemed tokens to
     * @return redeemedAmounts      Amounts of the project tokens redeemed
     */
    function redeemPoolSpecific(
        address poolToken,
        address[] memory projectTokens,
        uint[] memory amounts,
        LibTransfer.To toMode
    ) internal returns (uint[] memory) {
        uint[] memory beforeBalances = new uint256[](projectTokens.length);
        uint[] memory redeemedAmounts = new uint256[](projectTokens.length);
        for (uint i; i < projectTokens.length; i++) {
            beforeBalances[i] = IERC20(projectTokens[i]).balanceOf(address(this));
        }

        IC3Pool(poolToken).taxedRedeem(projectTokens, amounts);

        for (uint i; i < projectTokens.length; i++) {
            redeemedAmounts[i] = IERC20(projectTokens[i]).balanceOf(address(this)) - beforeBalances[i];
            LibTransfer.sendToken(IERC20(projectTokens[i]), redeemedAmounts[i], msg.sender, toMode);
        }
        return redeemedAmounts;
    }
}

/*
 SPDX-License-Identifier: MIT*/

/**
 * @author publius
 * @title LibTransfer handles the recieving and sending of Tokens to/from internal Balances.
 *
 */
pragma solidity ^0.8.16;

import "oz/token/ERC20/utils/SafeERC20.sol";
import "./LibBalance.sol";

library LibTransfer {
    using SafeERC20 for IERC20;

    enum From {
        EXTERNAL,
        INTERNAL,
        EXTERNAL_INTERNAL,
        INTERNAL_TOLERANT
    }
    enum To {
        EXTERNAL,
        INTERNAL
    }

    function transferToken(IERC20 token, address recipient, uint amount, From fromMode, To toMode)
        internal
        returns (uint transferredAmount)
    {
        if (fromMode == From.EXTERNAL && toMode == To.EXTERNAL) {
            uint beforeBalance = token.balanceOf(recipient);
            token.safeTransferFrom(msg.sender, recipient, amount);
            return token.balanceOf(recipient) - beforeBalance;
        }
        amount = receiveToken(token, amount, msg.sender, fromMode);
        sendToken(token, amount, recipient, toMode);
        return amount;
    }

    function receiveToken(IERC20 token, uint amount, address sender, From mode)
        internal
        returns (uint receivedAmount)
    {
        if (amount == 0) return 0;
        if (mode != From.EXTERNAL) {
            receivedAmount = LibBalance.decreaseInternalBalance(sender, token, amount, mode != From.INTERNAL);
            if (amount == receivedAmount || mode == From.INTERNAL_TOLERANT) return receivedAmount;
        }
        uint beforeBalance = token.balanceOf(address(this));
        token.safeTransferFrom(sender, address(this), amount - receivedAmount);
        return receivedAmount + (token.balanceOf(address(this)) - beforeBalance);
    }

    function sendToken(IERC20 token, uint amount, address recipient, To mode) internal {
        if (amount == 0) return;
        if (mode == To.INTERNAL) LibBalance.increaseInternalBalance(recipient, token, amount);
        else token.safeTransfer(recipient, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

interface IKlimaInfinity {
    function toucan_retireExactCarbonPoolDefault(
        address sourceToken,
        address carbonToken,
        uint amount,
        address retiringAddress,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function toucan_retireExactCarbonPoolWithEntityDefault(
        address sourceToken,
        address carbonToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function toucan_retireExactSourcePoolDefault(
        address sourceToken,
        address carbonToken,
        uint amount,
        address retiringAddress,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function toucan_retireExactSourcePoolWithEntityDefault(
        address sourceToken,
        address carbonToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function toucan_retireExactCarbonPoolSpecific(
        address sourceToken,
        address carbonToken,
        address projectToken,
        uint amount,
        address retiringAddress,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function toucan_retireExactCarbonPoolWithEntitySpecific(
        address sourceToken,
        address poolToken,
        address projectToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function toucan_retireExactSourcePoolWithEntitySpecific(
        address sourceToken,
        address poolToken,
        address projectToken,
        uint sourceAmount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function toucan_retireExactSourcePoolSpecific(
        address sourceToken,
        address poolToken,
        address projectToken,
        uint sourceAmount,
        address retiringAddress,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function moss_retireExactCarbonPoolDefault(
        address sourceToken,
        address carbonToken,
        uint amount,
        address retiringAddress,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function moss_retireExactCarbonPoolWithEntityDefault(
        address sourceToken,
        address carbonToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function moss_retireExactSourcePoolDefault(
        address sourceToken,
        address carbonToken,
        uint sourceAmount,
        address retiringAddress,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function moss_retireExactSourcePoolWithEntityDefault(
        address sourceToken,
        address carbonToken,
        uint sourceAmount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function c3_retireExactCarbonPoolDefault(
        address sourceToken,
        address carbonToken,
        uint amount,
        address retiringAddress,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function c3_retireExactCarbonPoolWithEntityDefault(
        address sourceToken,
        address carbonToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function c3_retireExactSourcePoolDefault(
        address sourceToken,
        address carbonToken,
        uint sourceAmount,
        address retiringAddress,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function c3_retireExactSourcePoolWithEntityDefault(
        address sourceToken,
        address carbonToken,
        uint sourceAmount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function c3_retireExactCarbonPoolSpecific(
        address sourceToken,
        address carbonToken,
        address projectToken,
        uint amount,
        address retiringAddress,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function c3_retireExactCarbonPoolWithEntitySpecific(
        address sourceToken,
        address poolToken,
        address projectToken,
        uint amount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function c3_retireExactSourcePoolWithEntitySpecific(
        address sourceToken,
        address poolToken,
        address projectToken,
        uint sourceAmount,
        address retiringAddress,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);

    function c3_retireExactSourcePoolSpecific(
        address sourceToken,
        address poolToken,
        address projectToken,
        uint sourceAmount,
        address retiringAddress,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external returns (uint retirementIndex);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKlimaCarbonRetirements {
    function carbonRetired(
        address _retiree,
        address _pool,
        uint _amount,
        string calldata _beneficiaryString,
        string calldata _retirementMessage
    ) external;

    function getUnclaimedTotal(address _minter) external view returns (uint);

    function offsetClaimed(address _minter, uint _amount) external returns (bool);

    function getRetirementIndexInfo(address _retiree, uint _index)
        external
        view
        returns (address, uint, string memory, string memory);

    function getRetirementPoolInfo(address _retiree, address _pool) external view returns (uint);

    function getRetirementTotals(address _retiree) external view returns (uint, uint, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @author Cujo
 * @title LibKlima
 */

import "../C.sol";
import "./LibAppStorage.sol";
import "../interfaces/IKlima.sol";
import "./Token/LibApprove.sol";

library LibKlima {
    /**
     * @notice                  Returns wsKLIMA amount for provided sKLIMA amount
     * @param amount            sKLIMA provided
     * @return wrappedAmount    wsKLIMA amount
     */
    function toWrappedAmount(uint amount) internal view returns (uint wrappedAmount) {
        // @dev Account for rounding differences in wsKLIMA contract.
        return IwsKLIMA(C.wsKlima()).sKLIMATowKLIMA(amount) + 5;
    }

    /**
     * @notice                  Returns sKLIMA amount for provided wsKLIMA amount
     * @param amount            wsKLIMA provided
     * @return unwrappedAmount    sKLIMA amount
     */
    function toUnwrappedAmount(uint amount) internal view returns (uint unwrappedAmount) {
        // @dev Account for rounding differences in wsKLIMA contract.
        return IwsKLIMA(C.wsKlima()).wKLIMATosKLIMA(amount);
    }

    /**
     * @notice                  Unwraps and unstakes provided wsKLIMA amount
     * @param amount            wsKLIMA provided
     * @return unwrappedAmount    Final KLIMA amount
     */
    function unwrapKlima(uint amount) internal returns (uint unwrappedAmount) {
        unwrappedAmount = IwsKLIMA(C.wsKlima()).unwrap(amount);
        unstakeKlima(unwrappedAmount);
    }

    /**
     * @notice                  Unstakes provided sKLIMA amount
     * @param amount            sKLIMA provided
     */
    function unstakeKlima(uint amount) internal {
        IStaking(C.staking()).unstake(amount, false);
    }

    /**
     * @notice                  Stakes and wraps provided KLIMA amount
     * @param amount            KLIMA provided
     * @return wrappedAmount    Final wsKLIMA amount
     */
    function wrapKlima(uint amount) internal returns (uint wrappedAmount) {
        stakeKlima(amount);
        wrappedAmount = IwsKLIMA(C.wsKlima()).wrap(amount);
    }

    /**
     * @notice                  Stakes provided KLIMA amount
     * @param amount            KLIMA provided
     */
    function stakeKlima(uint amount) internal {
        IStakingHelper(C.stakingHelper()).stake(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @author Cujo
 * @title LibUniswapV2Swap
 */

import "../../interfaces/IUniswapV2Router02.sol";
import "../Token/LibApprove.sol";

library LibUniswapV2Swap {
    function swapTokensForExactTokens(
        address router,
        address[] memory path,
        uint amountIn,
        uint amountOut
    ) internal returns (uint) {
        LibApprove.approveToken(IERC20(path[0]), router, amountIn);

        uint[] memory amountsOut = IUniswapV2Router02(router).swapTokensForExactTokens(
            amountOut,
            amountIn,
            path,
            address(this),
            block.timestamp
        );

        return amountsOut[path.length - 1];
    }

    function swapExactTokensForTokens(address router, address[] memory path, uint amount) internal returns (uint) {
        uint[] memory amountsOut = IUniswapV2Router02(router).getAmountsOut(amount, path);

        LibApprove.approveToken(IERC20(path[0]), router, amount);

        amountsOut = IUniswapV2Router02(router).swapExactTokensForTokens(
            amount,
            amountsOut[path.length - 1],
            path,
            address(this),
            block.timestamp
        );

        return amountsOut[path.length - 1];
    }

    function getAmountIn(address router, address[] memory path, uint amount) internal view returns (uint) {
        uint[] memory amountsIn = IUniswapV2Router02(router).getAmountsIn(amount, path);
        return amountsIn[0];
    }

    function getAmountOut(address router, address[] memory path, uint amount) internal view returns (uint) {
        uint[] memory amountsOut = IUniswapV2Router02(router).getAmountsOut(amount, path);
        return amountsOut[amountsOut.length - 1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @author Cujo
 * @title LibTridentSwap
 */

import "../../interfaces/ITrident.sol";
import "../Token/LibApprove.sol";
import "../LibAppStorage.sol";
import "../../C.sol";

library LibTridentSwap {
    function swapExactTokensForTokens(
        address router,
        address pool,
        address tokenIn,
        uint amountIn,
        uint minAmountOut
    ) internal returns (uint amountOut) {
        ITridentRouter.ExactInputSingleParams memory swapParams;
        swapParams.amountIn = amountIn;
        swapParams.amountOutMinimum = minAmountOut;
        swapParams.pool = pool;
        swapParams.tokenIn = tokenIn;
        swapParams.data = abi.encode(tokenIn, address(this), true);
        amountOut = ITridentRouter(router).exactInputSingleWithNativeToken(swapParams);
    }

    function getAmountIn(
        address pool,
        address tokenIn,
        address tokenOut,
        uint amountOut
    ) internal view returns (uint amountIn) {
        uint shareAmount = ITridentPool(pool).getAmountIn(abi.encode(tokenOut, amountOut));
        amountIn = IBentoBoxMinimal(C.sushiBento()).toAmount(IERC20(tokenIn), shareAmount, true);
    }

    function getAmountOut(
        address pool,
        address tokenIn,
        address tokenOut,
        uint amountIn
    ) internal view returns (uint amountOut) {
        uint shareAmount = ITridentPool(pool).getAmountOut(abi.encode(tokenIn, amountIn));
        amountOut = IBentoBoxMinimal(C.sushiBento()).toAmount(IERC20(tokenOut), shareAmount, true);
    }

    function getTridentPool(address tokenOne, address tokenTwo) internal view returns (address tridentPool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return
            s.tridentPool[tokenOne][tokenTwo] == address(0)
                ? s.tridentPool[tokenTwo][tokenOne]
                : s.tridentPool[tokenOne][tokenTwo];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @author Cujo
 * @title LibTreasurySwap
 */

import {IKlimaRetirementBond} from "../../interfaces/IKlima.sol";
import "../Token/LibApprove.sol";
import "../../C.sol";

library LibTreasurySwap {
    function getAmountIn(address tokenIn, uint amountOut) internal view returns (uint amountIn) {
        return IKlimaRetirementBond(C.klimaRetirementBond()).getKlimaAmount(amountOut, tokenIn);
    }

    function swapToExact(address carbonToken, uint amountIn, uint amountOut) internal {
        LibApprove.approveToken(IERC20(C.klima()), C.klimaRetirementBond(), amountIn);

        IKlimaRetirementBond(C.klimaRetirementBond()).swapToExact(carbonToken, amountOut);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "oz/token/ERC20/IERC20.sol";
import "./libraries/LibRetire.sol";

/**
 * @author Cujo
 * @title App Storage defines the state object for Klima Infinity
 */

contract Account {
    struct Retirement {
        address poolTokenAddress; // Pool token used
        address projectTokenAddress; // Fractionalized ERC-20 address for project/vintage
        address beneficiaryAddress; // Address of the beneficiary
        string beneficiary; // Retirement beneficiary
        string retirementMessage; // Specific message going along with this retirement
        uint amount; // Amount of carbon retired
        uint pledgeID; // The ID of the pledge this retirement is associated with.
    }

    struct State {
        mapping(uint => Retirement) retirements;
        mapping(address => uint) totalPoolRetired;
        mapping(address => uint) totalProjectRetired;
        uint totalRetirements;
        uint totalCarbonRetired;
        uint totalRewardsClaimed;
    }
}

contract Storage {
    struct CarbonBridge {
        string name;
        address defaultRouter;
        uint8 routerType;
    }

    struct DefaultSwap {
        uint8[] swapDexes;
        address[] ammRouters;
        mapping(uint8 => address[]) swapPaths;
    }
}

struct AppStorage {
    mapping(uint => Storage.CarbonBridge) bridges; // Details for current carbon bridges
    mapping(address => bool) isPoolToken;
    mapping(address => LibRetire.CarbonBridge) poolBridge; // Mapping of pool token address to the carbon bridge
    mapping(address => mapping(address => Storage.DefaultSwap)) swap; // Mapping of pool token to default swap behavior.
    mapping(address => Account.State) a; // Mapping of a user address to account state.
    uint lastERC721Received; // Last ERC721 Toucan Retirement Certificate received.
    uint fee; // Aggregator fee charged on all retirements to 3 decimals. 1000 = 1%
    uint reentrantStatus; // An intra-transaction state variable to protect against reentrance.
    // Internal Balances
    mapping(address => mapping(IERC20 => uint)) internalTokenBalance; // A mapping from Klimate address to Token address to Internal Balance. It stores the amount of the Token that the Klimate has stored as an Internal Balance in Klima Infinity.
    // Meta tx items
    mapping(address => uint) metaNonces;
    bytes32 domainSeparator;
    // Swap routing
    mapping(address => mapping(address => address)) tridentPool; // Trident pool to use for getting swap info
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

pragma solidity ^0.8.16;

interface IToucanPool {
    function redeemAuto2(uint amount) external returns (address[] memory tco2s, uint[] memory amounts);

    function redeemMany(address[] calldata erc20s, uint[] calldata amounts) external;

    function feeRedeemPercentageInBase() external pure returns (uint);

    function feeRedeemDivider() external pure returns (uint);

    function redeemFeeExemptedAddresses(address) external view returns (bool);

    function getScoredTCO2s() external view returns (address[] memory);
}

interface IToucanCarbonOffsets {
    function retire(uint amount) external;

    function retireAndMintCertificate(
        string calldata retiringEntityString,
        address beneficiary,
        string calldata beneficiaryString,
        string calldata retirementMessage,
        uint amount
    ) external;

    function mintCertificateLegacy(
        string calldata retiringEntityString,
        address beneficiary,
        string calldata beneficiaryString,
        string calldata retirementMessage,
        uint amount
    ) external;
}

/*
 SPDX-License-Identifier: MIT*/

pragma solidity ^0.8.16;

import "oz/token/ERC20/utils/SafeERC20.sol";

/**
 * @author publius
 * @title LibApproval handles approval other ERC-20 tokens.
 *
 */

library LibApprove {
    using SafeERC20 for IERC20;

    function approveToken(IERC20 token, address spender, uint amount) internal {
        if (token.allowance(address(this), spender) == type(uint).max) return;
        token.safeIncreaseAllowance(spender, amount);
    }
}

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface ICarbonChain {
    function offsetCarbon(uint _carbonTon, string calldata _transactionInfo, string calldata _onBehalfOf) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IC3Pool {
    function freeRedeem(uint amount) external;

    function taxedRedeem(address[] memory erc20Addresses, uint[] memory amount) external;

    function getFreeRedeemAddresses() external view returns (address[] memory);

    function getERC20Tokens() external view returns (address[] memory);

    function feeRedeem() external view returns (uint);
}

interface IC3ProjectToken {
    function offsetFor(uint amount, address beneficiary, string memory transferee, string memory reason) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
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

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
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

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
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

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
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

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
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

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
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

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
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

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
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

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
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

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
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

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
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

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
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

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
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

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
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

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
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

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
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

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
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

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
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

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
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

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
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

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
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

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
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

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
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

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
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

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
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

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
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

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
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

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
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

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
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

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
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

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
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

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
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

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
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

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
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

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
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

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
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

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
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

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
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

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
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

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
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

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
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

/*
 SPDX-License-Identifier: MIT*/

pragma solidity ^0.8.16;

import "oz/token/ERC20/utils/SafeERC20.sol";
import "oz/utils/math/Math.sol";
import {SafeCast} from "oz/utils/math/SafeCast.sol";
import "../LibAppStorage.sol";

/**
 * @author LeoFib, Publius
 * @title LibInternalBalance Library handles internal read/write functions for Internal User Balances.
 * Largely inspired by Balancer's Vault
 *
 */

library LibBalance {
    using SafeERC20 for IERC20;
    using SafeCast for uint;

    /**
     * @dev Emitted when a account's Internal Balance changes, through interacting using Internal Balance.
     *
     */
    event InternalBalanceChanged(address indexed account, IERC20 indexed token, int delta);

    function getBalance(address account, IERC20 token) internal view returns (uint combined_balance) {
        combined_balance = token.balanceOf(account) + getInternalBalance(account, token);
        return combined_balance;
    }

    /**
     * @dev Increases `account`'s Internal Balance for `token` by `amount`.
     */
    function increaseInternalBalance(address account, IERC20 token, uint amount) internal {
        uint currentBalance = getInternalBalance(account, token);
        uint newBalance = currentBalance + amount;
        setInternalBalance(account, token, newBalance, amount.toInt256());
    }

    /**
     * @dev Decreases `account`'s Internal Balance for `token` by `amount`. If `allowPartial` is true, this function
     * doesn't revert if `account` doesn't have enough balance, and sets it to zero and returns the deducted amount
     * instead.
     */
    function decreaseInternalBalance(address account, IERC20 token, uint amount, bool allowPartial)
        internal
        returns (uint deducted)
    {
        uint currentBalance = getInternalBalance(account, token);
        require(allowPartial || (currentBalance >= amount), "Balance: Insufficient internal balance");

        deducted = Math.min(currentBalance, amount);
        // By construction, `deducted` is lower or equal to `currentBalance`, so we don't need to use checked
        // arithmetic.
        uint newBalance = currentBalance - deducted;
        setInternalBalance(account, token, newBalance, -(deducted.toInt256()));
    }

    /**
     * @dev Sets `account`'s Internal Balance for `token` to `newBalance`.
     *
     * Emits an `InternalBalanceChanged` event. This event includes `delta`, which is the amount the balance increased
     * (if positive) or decreased (if negative). To avoid reading the current balance in order to compute the delta,
     * this function relies on the caller providing it directly.
     */
    function setInternalBalance(address account, IERC20 token, uint newBalance, int delta) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.internalTokenBalance[account][token] = newBalance;
        emit InternalBalanceChanged(account, token, delta);
    }

    /**
     * @dev Returns `account`'s Internal Balance for `token`.
     */
    function getInternalBalance(address account, IERC20 token) internal view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.internalTokenBalance[account][token];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IStaking {
    function unstake(uint _amount, bool _trigger) external;
}

interface IStakingHelper {
    function stake(uint _amount) external;
}

interface IwsKLIMA {
    function wrap(uint _amount) external returns (uint);

    function unwrap(uint _amount) external returns (uint);

    function wKLIMATosKLIMA(uint _amount) external view returns (uint);

    function sKLIMATowKLIMA(uint _amount) external view returns (uint);
}

interface IKlimaRetirementBond {
    function swapToExact(address poolToken, uint256 amount) external;

    function getKlimaAmount(uint256 poolAmount, address poolToken) external view returns (uint256 klimaNeeded);

    function owner() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "oz/token/ERC20/IERC20.sol";

interface IBentoBoxMinimal {
    /// @dev Approves users' BentoBox assets to a "master" contract.
    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function toAmount(IERC20 token, uint share, bool roundUp) external view returns (uint amount);
}

/// @notice Trident pool router interface.
interface ITridentRouter {
    struct ExactInputSingleParams {
        uint amountIn;
        uint amountOutMinimum;
        address pool;
        address tokenIn;
        bytes data;
    }

    function exactInputSingleWithNativeToken(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint amountOut);
}

/// @notice Trident pool interface.
interface ITridentPool {
    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that will be sent to the user if the trade is executed.
    function getAmountOut(bytes calldata data) external view returns (uint finalAmountOut);

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountIn The amount of input tokens that are required from the user if the trade is executed.
    function getAmountIn(bytes calldata data) external view returns (uint finalAmountIn);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}