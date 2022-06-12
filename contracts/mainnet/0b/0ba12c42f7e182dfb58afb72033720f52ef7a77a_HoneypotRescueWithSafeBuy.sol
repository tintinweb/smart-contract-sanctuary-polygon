// SPDX-License-Identifier: MIT
/* 
██╗░░██╗░█████╗░███╗░░██╗███████╗██╗░░░██╗██████╗░░█████╗░████████╗  ██████╗░███████╗░██████╗░█████╗░██╗░░░██╗███████╗
██║░░██║██╔══██╗████╗░██║██╔════╝╚██╗░██╔╝██╔══██╗██╔══██╗╚══██╔══╝  ██╔══██╗██╔════╝██╔════╝██╔══██╗██║░░░██║██╔════╝
███████║██║░░██║██╔██╗██║█████╗░░░╚████╔╝░██████╔╝██║░░██║░░░██║░░░  ██████╔╝█████╗░░╚█████╗░██║░░╚═╝██║░░░██║█████╗░░
██╔══██║██║░░██║██║╚████║██╔══╝░░░░╚██╔╝░░██╔═══╝░██║░░██║░░░██║░░░  ██╔══██╗██╔══╝░░░╚═══██╗██║░░██╗██║░░░██║██╔══╝░░
██║░░██║╚█████╔╝██║░╚███║███████╗░░░██║░░░██║░░░░░╚█████╔╝░░░██║░░░  ██║░░██║███████╗██████╔╝╚█████╔╝╚██████╔╝███████╗
╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝╚══════╝░░░╚═╝░░░╚═╝░░░░░░╚════╝░░░░╚═╝░░░  ╚═╝░░╚═╝╚══════╝╚═════╝░░╚════╝░░╚═════╝░╚══════╝

░██╗░░░░░░░██╗██╗████████╗██╗░░██╗  ░██████╗░█████╗░███████╗███████╗██████╗░██╗░░░██╗██╗░░░██╗
░██║░░██╗░░██║██║╚══██╔══╝██║░░██║  ██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗██║░░░██║╚██╗░██╔╝
░╚██╗████╗██╔╝██║░░░██║░░░███████║  ╚█████╗░███████║█████╗░░█████╗░░██████╦╝██║░░░██║░╚████╔╝░
░░████╔═████║░██║░░░██║░░░██╔══██║  ░╚═══██╗██╔══██║██╔══╝░░██╔══╝░░██╔══██╗██║░░░██║░░╚██╔╝░░
░░╚██╔╝░╚██╔╝░██║░░░██║░░░██║░░██║  ██████╔╝██║░░██║██║░░░░░███████╗██████╦╝╚██████╔╝░░░██║░░░
░░░╚═╝░░░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝  ╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚══════╝╚═════╝░░╚═════╝░░░░╚═╝░░░

Cross-chain honeypot checker with some rescue functionality and a safeBuy() method for purchasing
tokens with automated honeypot check. Supports any swap or chain, as you supply the router
factory or router address where necessary.

If a honeypot isn't detected, transactions made with safeBuy() will go through, and the tokens
bought are sent to the user. If a honeypot is detected, the transaction does not execute.

The honeypot checker (and safeBuy method which uses the checker) tests the transaction with
an initial buy (for a very small amount) to see if those tokens can then be sold. The contract
pays for all costs and gas during the testing (although this implementation inherits from 
MembershipDAO contract for paid access).

Rescue functionality includes emergency withdrawal from all pools found in a MasterChef contract
(saving users time from manual lookup, anticipating time being more costly than gas), and proxy
transfer methods using DEX library, so if a contract's transfer methods have been disabled,
this may be able to work to recover funds. 

Some honeypots can be more complex, where selling is disabled only after a certain time, so 
it'd be better to do a delayed transaction sell test instead of immediately after the buy. This
would require some external tools to work in conjunction with smart contracts, which has some downsides
opposed to doing it completely on-chain via escrow.

   ___  .___    __.    ___    __.    ___/ `  |     ___ 
 .'   ` /   \ .'   \ .'   ` .'   \  /   | |  |   .'   `
 |      |   ' |    | |      |    | ,'   | |  |   |----'
  `._.' /      `._.'  `._.'  `._.' `___,' / /\__ `.___,         
                                        `              
*/

pragma abicoder v2;
pragma solidity ^0.8.7;

// Import MembershipDAO
import "./MembershipDAO.sol";
// Import DEX Libraries and Interfaces for better cross-chain support
import "./DexLibrary.sol";

// We have a interface for ERC20 tokens imported from MembershipDAO contract.
interface IWETH {
    
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}


// **** MasterChef Contract Interface **** 
interface IMasterChef {
    function BONUS_MULTIPLIER() external view returns (uint256);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) external;

    function bonusEndBlock() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function dev(address _devaddr) external;

    function devFundDivRate() external view returns (uint256);

    function devaddr() external view returns (address);

    function emergencyWithdraw(uint256 _pid) external;

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    function massUpdatePools() external;

    function owner() external view returns (address);

    function pendingPickle(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function pickle() external view returns (address);

    function picklePerBlock() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accPicklePerShare
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setBonusEndBlock(uint256 _bonusEndBlock) external;

    function setDevFundDivRate(uint256 _devFundDivRate) external;

    function setPicklePerBlock(uint256 _picklePerBlock) external;

    function startBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;
}


// **** Honeypot Checker / Rescuer with Safe Buy Proxy Method for ERC-20 Tokens **** 
contract HoneypotRescueWithSafeBuy is MembershipDAO(100000000000000000, 2500000000000000) {
    // Inherits from MembershipDAO so there's paid access.
    // We set our membership fee to .1 eth and our withdrawal fee to .025 eth.

    uint256 minTransactionAmount = 1000000000000000; // .001 eth. The amount of eth we'll use to test initial buy/sell transactions.
                                                     // Note: These funds and gas cost for testing comes from the contract,
                                                     // not transaction sender.
    uint256 approveMaxAmount = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    bool public paused;
    IDEXRouter router;
    IERC20 wCoin;

    // Honeypoy prevention. We prevent the transaction from going through and emit an event. Thes events can be logged somewhere so the tokens
    // are blacklisted.
    event HoneypotCheckerPreventTransaction(address senderAddr, uint amountToTransfer, uint expectedAmount, uint buyCost, address tokenToCheck); 
    // Honeypot test has passed. Forward the transaction through, transfer the resulting tokens back to the user, and emit an event.
    // Since honeypot contract traps can be "activated" at any time, it's good to use a safeBuy() proxy purchase for best security.
    event HoneypotCheckerSafeTransaction(address senderAddr, uint amountToTransfer, uint expectedAmount, uint buyCost, address tokenToCheck); 
    // Honeypot transaction bypass. Someone was able to successfully use our bypass methods to withdraw their funds from a honeypot.
    event HoneypotRescueTransferBypass(address senderAddr, uint expectedAmount, address honeypotToken, address liquidityToken); 
    // Honeypot transaction fail. Someone was not able to use our bypass methods to withdraw their funds from a honeypot.
    event HoneypotRescueTransferBypassFail(address senderAddr, uint expectedAmount, address honeypotToken, address liquidityToken, string err); 
    // Honeypot rescue transaction
    event HoneypotRescueEmergencyWithdrawal(address senderAddr, address honeypotContract, uint poolId);


    struct HoneypotCheckResponse {
        uint256 buyResult; // Result of buying transaction of honeypot token test
        uint256 targetTokenBalance; // Balance of the token we wanted to transfer (Usually set to $minTransactionAmount)
        uint256 sellResult; // Result of sell transaction of honeypot token test (If it's greater than 0 then we were able to sell)
        uint256 buyCost; // Cost of the gas to buy
        uint256 sellCost; // Cost of the gas to sell 
        uint256 expectedAmount; // How much user expected to receive. This will be equal to our $minTransactionAmount in the default test.
    }

    struct SafeBuyResponse {
        uint256 buyResult; // Result of how much we bought
        uint256 buyCost; // Cost of the gas to buy
        uint256 expectedAmount; // How much user expected to receive (should be close to buyResult)
    }

   struct HoneypotRescueTransferBypassResponse {
       bool rescued; // Successful transfer bypass?
       uint256 amount; // The amount we rescued in balance of liquidity token
       address contractAddr; // Honeypot contract address
    }


    // **** Paid Membership Functionality Below ****

    // **** Honeypot Checking ****

    /**
    * @dev Checks a token address for a honeypot, given a router contract.
           Uses contract wETH balance to do a stimulated buy/sell transaction.
    * @param targetTokenAddress Token address to check for honeypot.
    * @param routerAddr Router address to do transaction on token.
    * @return honeypotResponse Results response from honeypot test simulation transaction.
    *
    * Requirements:
    *
    * - The contract must not be paused.
    * - Wallet address must be whitelisted.
    */
    function honeypotCheck(address targetTokenAddress, address routerAddr) 
        public 
        onlyWhitelisted
        returns (HoneypotCheckResponse memory honeypotResponse) 
        {
        require(paused == false, "Contract is paused.");

        router = IDEXRouter(routerAddr);

        IERC20 targetToken = IERC20(targetTokenAddress); // token to honeypot test

        int256 wCoinBalBeginning = int(wCoin.balanceOf(address(this)));

        address[] memory buyPath = new address[](2);
        buyPath[0] = router.WETH();
        buyPath[1] = targetTokenAddress;

        address[] memory sellPath = new address[](2);
        sellPath[0] = targetTokenAddress;
        sellPath[1] = router.WETH();

        wCoin.approve(routerAddr, minTransactionAmount * 2); // Approve 2x the amount we're testing

        uint256 startBuyGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            minTransactionAmount, // For our honeypot we will attempt to sell a small amount, .001 eth
            1,
            buyPath,
            address(this),
            block.timestamp + 10
        );

        int256 wCoinBalMiddle = int(wCoin.balanceOf(address(this)));

        int256 buyResult = abs(wCoinBalMiddle - wCoinBalBeginning);

        uint256 finishBuyGas = gasleft();

        wCoin.approve(routerAddr, minTransactionAmount * 2); // Approve 2x the amount we're testing

        uint256 startSellGas = gasleft();

        // Now try to sell the balance of the token we bought
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            uint(buyResult),
            1,
            sellPath,
            address(this),
            block.timestamp + 10
        );

        int256 wCoinBalEnd = int(wCoin.balanceOf(address(this)));

        uint256 finishSellGas = gasleft();

        uint256 targetTokenBalance = targetToken.balanceOf(address(this));

        int256 sellResult = abs(wCoinBalEnd - wCoinBalMiddle);
        // Return if we were able to sell our bought tokens (honeypot check)
        // as well as the slippage detected.
        honeypotResponse = HoneypotCheckResponse(
            uint(buyResult),
            targetTokenBalance,
            uint(sellResult),
            startBuyGas - finishBuyGas, // buyCost
            startSellGas - finishSellGas, // sellCost,
            minTransactionAmount
        );
        return honeypotResponse;
    }
    
    /**
    * @dev Checks a token address for a honeypot, given a router contract, with
           a custom amount of the token to test.

           User pays for this test, sending the amount to test with (this 
           will be sent back to the user *if* the tokens can be sold), minus
           any gas costs, as the contract will subtract those.

    * @param targetTokenAddress Token address to check for honeypot.
    * @param routerAddr Router address to do transaction on token.
    * @return honeypotResponse Results response from honeypot test simulation transaction.
    *
    * Requirements:
    *
    * - The contract must not be paused.
    * - Wallet address must be whitelisted.
    */
    function honeypotCheckCustomAmount(address targetTokenAddress, address routerAddr) 
        public 
        payable
        onlyWhitelisted
        returns (HoneypotCheckResponse memory honeypotResponse) 
        {

        require(paused == false, "Contract is paused.");
        uint256 customAmount = msg.value;

        router = IDEXRouter(routerAddr);

        IERC20 targetToken = IERC20(targetTokenAddress); // token to honeypot test

        int256 wCoinBalBeginning = int(wCoin.balanceOf(address(this)));

        address[] memory buyPath = new address[](2);
        buyPath[0] = router.WETH();
        buyPath[1] = targetTokenAddress;

        address[] memory sellPath = new address[](2);
        sellPath[0] = targetTokenAddress;
        sellPath[1] = router.WETH();

        wCoin.approve(routerAddr, minTransactionAmount * 2); // Approve 2x the amount we're testing

        uint256 startBuyGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            customAmount, // For our honeypot we will attempt to sell a small amount, .001 eth
            1,
            buyPath,
            address(this),
            block.timestamp + 10
        );

        int256 wCoinBalMiddle = int(wCoin.balanceOf(address(this)));

        int256 buyResult = abs(wCoinBalMiddle - wCoinBalBeginning);

        uint256 finishBuyGas = gasleft();

        wCoin.approve(routerAddr, customAmount * 2); // Approve 2x the amount we're testing

        uint256 startSellGas = gasleft();

        // Now try to sell the balance of the token we bought
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            uint(buyResult),
            1,
            sellPath,
            address(this),
            block.timestamp + 10
        );

        int256 wCoinBalEnd = int(wCoin.balanceOf(address(this)));

        uint256 finishSellGas = gasleft();

        int256 sellResult = abs(wCoinBalEnd - wCoinBalMiddle);
        
        // Return the wETH amount back minus gas cost
        wCoin.transferFrom(msg.sender, address(this), uint(sellResult) - finishSellGas);

        uint256 targetTokenBalance = targetToken.balanceOf(address(this));

        // Return if we were able to sell our bought tokens (honeypot check)
        // as well as the slippage detected.
        honeypotResponse = HoneypotCheckResponse(
            uint(buyResult),
            targetTokenBalance,
            uint(sellResult),
            startBuyGas - finishBuyGas, // buyCost
            startSellGas - finishSellGas, // sellCost,
            customAmount
        );
        return honeypotResponse;
    }


    // **** Safe Buy (Proxy Purchase) for Tokens **** 

    /**
    * @dev Contract makes a token test purchase and sell transaction with a minimal amount of ETH
           (paid for by contract). If we can sell the token, we assume it's not a honeypot, and
           we let user's transaction go through, and transfer back the new swapped tokens
           to the user. If it is a honeypot, we do nothing and the user's funds go nowhere.
    * @param targetTokenAddress Token address to check for honeypot.
    * @param routerAddr Router address to do transaction on token.
    * @return safeBuyResponse Results response from safeBuy proxy transaction after honeypot test.
    *
    * Requirements:
    *
    * - The contract must not be paused.
    * - Wallet address must be whitelisted.
    */
    function safeBuy(address targetTokenAddress, address routerAddr)
        public
        payable
        onlyWhitelisted
        returns (SafeBuyResponse memory safeBuyResponse)
    {

        require(paused == false, "Contract is paused.");

        HoneypotCheckResponse memory honey_response = honeypotCheck(targetTokenAddress, routerAddr);

        address[] memory buyPath = new address[](2);
        buyPath[0] = router.WETH();
        buyPath[1] = targetTokenAddress;

        uint256[] memory amounts = router.getAmountsOut(msg.value, buyPath);

        uint256 expectedAmount = amounts[1];
        uint256 startBuyGas = gasleft();
        address _targetToken = targetTokenAddress;

        if (honey_response.sellResult == 0) {

            // Honeypot detected, because we couldn't sell anything.
            // do NOTHING and user keeps tokens, contract pays for gas

            uint256 finishBuyGas = gasleft();
            uint256 buyCost = startBuyGas - finishBuyGas;

            safeBuyResponse = SafeBuyResponse(
                0, // no tokens were swapped because it was a honeypot
                buyCost,
                expectedAmount
            );
            
            emit HoneypotCheckerPreventTransaction(msg.sender, 0, expectedAmount, buyCost, _targetToken);
        } else {

            // Not a honeypot, swap the tokens then send it back to user

            IWETH(router.WETH()).deposit{value: msg.value}();

            wCoin.approve(routerAddr, approveMaxAmount);
            
            IERC20 targetToken = IERC20(targetTokenAddress); // token to honeypot test

            targetToken.approve(routerAddr, approveMaxAmount);

            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                msg.value - startBuyGas, // We'll take the gas cost out of the deposit from the user
                1,
                buyPath,
                msg.sender,
                block.timestamp + 10
            );

            // Get the amount of tokens we bought
            uint256 buyResult = targetToken.balanceOf(address(this));
            uint256 finishBuyGas = gasleft();
            uint256 buyCost = startBuyGas - finishBuyGas;

            // Send tokens back to sender
            targetToken.transferFrom(msg.sender, address(this), buyResult);

            safeBuyResponse = SafeBuyResponse(
                buyResult,
                buyCost,
                expectedAmount
            );

            emit HoneypotCheckerSafeTransaction(msg.sender, buyResult, expectedAmount, buyCost, _targetToken);
        }
        return safeBuyResponse;
    }


    // **** HoneyPot Rescuer Tools **** 

    /**
    * @dev Attempts to bypass a disabled transfer or sell function within a honeypot contract,
           by calling the factory methods of the dex to attempt to transfer.

           Will try to sell all of the balance from the liquidityToken deposited into the dcontract.

    * @param honeypotToken Address of honeypot token.
    * @param liquidityToken Address of token you want to swap liquidity for (you must send this token
             to this contract using the depositToken()).
    * @param factoryAddr Address of the factory contract (UniSwap, PancakeSwap, etc).
    *
    * Requirements:
    *
    * - The contract must not be paused.
    * - Wallet address must be whitelisted.
    */
    // Before this function can be used, tokens must be sent to this created contract, using the 
    // depositToken() method. If transfer fails, we have no chance to sell it.
    function honeypotBypassAllTokenAmount(address honeypotToken, address liquidityToken, address factoryAddr)
     external virtual onlyWhitelisted 
     returns (HoneypotRescueTransferBypassResponse memory)
     {
        // uint256 honeypotTokenBalance = IERC20(honeypotToken).balanceOf(address(this));
        uint256 liquidityTokenBalance = membershipTokensBalances[msg.sender][liquidityToken];
        uint256 swapped_amount = swapExactTokensForTokensSupportingFeeOnTransferTokens(liquidityTokenBalance, honeypotToken, liquidityToken, factoryAddr, msg.sender);
        bool rescued = false;
        if (swapped_amount > 0) {
            // Swap was successful
            rescued = true;
            emit HoneypotRescueTransferBypass(msg.sender, swapped_amount, honeypotToken, liquidityToken);
        } else {
            rescued = false;
        }
        HoneypotRescueTransferBypassResponse memory honeypotRescueTransferBypassResponse = HoneypotRescueTransferBypassResponse(
            rescued,
            swapped_amount,
            honeypotToken
        );
        return honeypotRescueTransferBypassResponse;
    }

    /**
    * @dev Attempts to bypass a disabled transfer or sell function within a honeypot contract,
           by calling the factory methods of the dex to attempt to transfer.


    * @param honeypotToken Address of honeypot token.
    * @param liquidityToken Address of token you want to swap liquidity for (you must send this 
             token to this contract using the depositToken()).
    * @param factoryAddr Address of the factory contract (UniSwap, PancakeSwap, etc).
    * Requirements:
    *
    * - The contract must not be paused.
    * - Wallet address must be whitelisted.
    */
    function honeypotBypassCustomTokenAmount(
        address honeypotToken,
        address liquidityToken,
        address factoryAddr
        ) external virtual onlyWhitelisted 
        payable
        returns (HoneypotRescueTransferBypassResponse memory)
        {
        uint256 amount = msg.value;
        bool rescued = false;
        uint256 liquidityTokenBalance = membershipTokensBalances[msg.sender][liquidityToken];
        if (amount >= liquidityTokenBalance) {
            emit HoneypotRescueTransferBypassFail(msg.sender, amount, honeypotToken, liquidityToken,
                "Honeypot bypass failed. Not enough liquidity to cover amount asked to transfer.");
        }
        uint256 swapped_amount = swapExactTokensForTokensSupportingFeeOnTransferTokens(liquidityTokenBalance,
             honeypotToken, liquidityToken, factoryAddr, msg.sender);
        if (swapped_amount > 0) {
            // Swap was successful
            emit HoneypotRescueTransferBypass(msg.sender, swapped_amount, honeypotToken, liquidityToken);
        } else {
            emit HoneypotRescueTransferBypassFail(msg.sender, amount, honeypotToken, liquidityToken,
             "Was unable to transfer bypass funds for Honeypot rescue.");
        }
        HoneypotRescueTransferBypassResponse memory honeypotRescueTransferBypassResponse = HoneypotRescueTransferBypassResponse(
            rescued,
            swapped_amount,
            honeypotToken
        );
        return honeypotRescueTransferBypassResponse;
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        address honeypotToken,
        address liquidityToken,
        address factory,
        address receiver
    ) internal virtual returns (uint256) {
        IERC20(honeypotToken).transfer(DexLibrary.pairFor(factory, honeypotToken, liquidityToken),
         amountIn);
        uint256 balanceBefore = IERC20(liquidityToken).balanceOf(receiver);
        _swapSupportingFeeOnTransferTokens(honeypotToken, liquidityToken, factory, receiver);
        uint256 balanceAfter = IERC20(liquidityToken).balanceOf(receiver);
         // update their liquidtyToken balance with what was swapped if any
        membershipTokensBalances[receiver][liquidityToken] = balanceAfter - balanceBefore;
        // If we were able to swap, we should have a greater balanceAfter than balanceBefore
        return balanceAfter - balanceBefore;
    }

    function _swapSupportingFeeOnTransferTokens(
        address honeypotToken,
        address liquidityToken,
        address factory,
        address _to) internal virtual
        {
        (address input, address output) = (honeypotToken, liquidityToken);
        (address token0,) = DexLibrary.sortTokens(input, output);
        IDexPair pair = IDexPair(DexLibrary.pairFor(factory, input, output));
        uint amountInput;
        uint amountOutput;

        { // scope to avoid stack too deep errors
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = SafeMath.sub(IERC20(input).balanceOf(address(pair)), reserveInput);
        amountOutput = DexLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
        }

        (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
        pair.swap(amount0Out, amount1Out, _to, new bytes(0));
    }


    // Emergency Withdrawals from MasterChef
    /**
    * @dev Emergency withdrawal from a masterchef contract.
    * @param addr MasterChef contract address.
    * @param addr Pool ID to withdraw from.
    *
    * Requirements:
    *
    * - The contract must not be paused.
    * - Wallet address must be whitelisted.
    */
    function emergencyWithdrawFromPoolInMasterChef(uint8 poolId, address addr)
        public
        onlyWhitelisted
    {
        require(paused == false, "Contract is paused.");
        IMasterChef(addr).emergencyWithdraw(poolId);
        // In the future, we should only probably only
        // emit an event if the pool had any funds withdrawn.
        emit HoneypotRescueEmergencyWithdrawal(msg.sender, addr, poolId);
    }

    /**
    * @dev Emergency withdrawal from all found pools in a masterchef contract.

           Use this when you don't know which poolId, or if you have funds 
           deposited in multiple pools and you want to extract them quickly.
    * @param addr MasterChef contract address.
    *
    * Requirements:
    *
    * - The contract must not be paused.
    * - Wallet address must be whitelisted.
    */
    function emergencyWithdrawFromAllPoolsInMasterChef(address addr)
        public
        onlyWhitelisted
    {
        require(paused == false, "Contract is paused.");
        uint256 poolLength = IMasterChef(addr).poolLength();
        for (uint i=0; i <= poolLength; i++) {
            IMasterChef(addr).emergencyWithdraw(i);
        }
    }
    

    // **** Utils **** 

    /**
    * @dev Sets pause state of contract.
    * @param _paused Pause state to set.
    */
    function setPaused(bool _paused) public {
        require(msg.sender == owner(), "You are not the owner.");
        paused = _paused;
    }

    /**
    * @dev Gets abs value of int.
    * @param x Int x to get absolute value of.
    */
    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }
}