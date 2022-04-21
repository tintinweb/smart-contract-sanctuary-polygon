//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import { FlashLoanReceiverBase, IFlashLoanReceiver, IPoolAddressesProvider, IPool } from 'FlashLoanReceiverBase.sol';
import 'TransferHelper.sol';
import 'ISwapRouter.sol';
import 'IUniswapV2Router02.sol';
import 'Strings.sol';

/**
    Contract to call a Flash Loan and make token swaps from
    UniSwap and SushiSwap. The direction of which to use
    first can be controlled by providing a 1 to start with
    UniSwap or any other number acceptable for uint8 to 
    start with SushiSwap.
*/
contract AaveFlashLoanV3 is FlashLoanReceiverBase{
    
    /**
        owner variable to ensure the user that purchased
        this contract is the only one that can call certain
        functions.
    */
    address owner;

    /**
        This is used to determine the minimum Amout out
        when trading back to the original token. By 
        default I have set this to 40000 which will
        ensure a minimum of .25% profit.
    */
    uint24 public minimumProfitDividor = 40000;
    
    /**
        Variables used in construction variable to set
        the correct addresses.
    */
    ISwapRouter immutable uniSwapRouter;
    IUniswapV2Router02 immutable sushiRouter;

    /**
        Intantiate lending pool addresses provider and get lending pool address
    */
    constructor(IPoolAddressesProvider _addressProvider, address _owner, ISwapRouter _uniSwapRouter, IUniswapV2Router02 _sushiRouter) FlashLoanReceiverBase(_addressProvider) public {
        owner = _owner;
        uniSwapRouter = _uniSwapRouter;
        sushiRouter = _sushiRouter;
    }

     /** 
        Modifies functions to only be called by address that
        deployed this contract.
    */
    modifier onlyOwner{
        require(address(msg.sender) == owner);
        _;
    } 

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
        ) external override returns (bool){

        // This contract now has the funds requested.
        // Call function to swap tokens.
        swapERC20Tokens(params,premiums);

        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.
        bytes memory a = 'Not enough tokens to repay debt. Debt Amount: ';
        bytes memory b = ' - Amount in Contract: ';
        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i] + premiums[i];
            uint256 contractTokenBal = IERC20(assets[i]).balanceOf(address(this));
            // Put in require statement for better reverted reason string. I 
            // have provided the amount of payment needed by the Aave loan
            // vs. the amoount of the token currently in the contract.
            require(amountOwing < contractTokenBal,string(abi.encodePacked(abi.encodePacked(a,Strings.toString(amountOwing)),abi.encodePacked(b,Strings.toString(contractTokenBal)))));
            TransferHelper.safeApprove(assets[i], address(POOL), amountOwing);
        }
        
        return true;
    }

    /**
        This is the function that starts the flash loan.
     */
    function myFlashLoanCall(address token0, address token1, uint8 direction, uint24 poolFee, uint256 amountIn, uint256 amountOut, uint256 deadline) public onlyOwner {
        //Building information needed for flash loan
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = token0;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountIn;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;
        address onBehalfOf = address(this);

        // I am encoding parameters needed for other functions that are called in the
        // executeOperation call back function.
        bytes memory params = abi.encode(token0, token1, direction, poolFee, amountIn, amountOut, deadline);
        uint16 referralCode = 0;

        //Sends information for the flashLoan
        POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    /**
        Swapping mechanism that handles directional logic.
    */
    function swapERC20Tokens(bytes calldata params, uint256[] calldata premiums) internal{
        (address token0, address token1, uint8 direction, uint24 poolFee, uint256 amountIn, uint256 amountOut, uint256 deadline) = abi.decode(params, (address, address, uint8, uint24, uint256, uint256, uint256));

        address[] memory path = new address[](2);
        //amountOutMin calculates a minimum profit adjustable by minimumProfitDividor
        uint256 amountOutMin = amountIn+premiums[0]+(amountIn/minimumProfitDividor);
        // The direction is used to determine which DeFi exchange
        // will be used first.
        if(direction == 1){

            // Call order to go from UniSwap to SushiSwap
            uint256 uniSwapAmountOut = uniSwapExactInputSingle(amountIn, amountOut, token0, token1, poolFee);  

            // Reverse direction to trade back to original token 
            // Also will not make the trade unless we can get
            // a minimum of .25 % in profit
            path[0] = token1;
            path[1] = token0;
            sushiSwapExactInputSingle(uniSwapAmountOut, amountOutMin, path, deadline);

        }else{

            // Call order to go from SushiSwap to UniSwap
            path[0] = token0;
            path[1] = token1;
            uint256[] memory sushiSwapAmountOut = sushiSwapExactInputSingle(amountIn, amountOut, path, deadline);  

            // Reverse direction to trade back to original token 
            // Also will not make the trade unless we can get
            // a minimum of .25 % in profit
            uniSwapExactInputSingle(sushiSwapAmountOut[1], amountOutMin, token1, token0, poolFee);
        }
    }

    /**
        Base function to use UniSwap V3 Swap Router
    */
    function uniSwapExactInputSingle(uint256 amountIn, uint256 amountOutMinimum, address token0, address token1, uint24 poolFee) internal returns (uint256 amountOut) {

        // Approve the router to spend current token0.
        TransferHelper.safeApprove(token0, address(uniSwapRouter), amountIn);

        // We set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token0,
                tokenOut: token1,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = uniSwapRouter.exactInputSingle(params);
    }

    /**
        Base function to use SushiSwap Router
    */
    function sushiSwapExactInputSingle(uint256 amountIn, uint256 amountOutMin, address[] memory path, uint256 deadline) internal returns (uint256[] memory amountOut) {

        // Approve the router to spend WBTC.
        TransferHelper.safeApprove(path[0], address(sushiRouter), amountIn);

        // The call to `exactInputSingle` executes the swap.
        amountOut = sushiRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
    }

    /**
        Withdraw function to be used in case any funds are left over.
    */
    function withdraw() external onlyOwner(){
        (bool success, ) =  owner.call{ value: address(this).balance }("");
        require(success, "Withdraw failed.");
    }
    
    /**
        Withdraw provided ERC20 token.
    */
    function withdrawERC20Token(address token) external onlyOwner returns(uint256 currentAmount){
        currentAmount = IERC20(token).balanceOf(address(this));
        require(currentAmount > 0, 'Contract does not have the provided ERC20 token.');
        TransferHelper.safeTransfer(token, owner, currentAmount);
    }

    /**
        Function to get owner information that keeps 
        the owner variable private.
    */
    function getOwner() view external returns (address){
        return owner;
    }

    /**
        Change the owner of the contract.
     */
     function transferOwnership(address newOwner) external onlyOwner {
         owner = newOwner;
     }

     /**
        Allows owner to change the minimumProfitDividor
     */
    function setMinimumProfitDividor(uint24 setAmount) external onlyOwner {
        minimumProfitDividor = setAmount;
    }
}