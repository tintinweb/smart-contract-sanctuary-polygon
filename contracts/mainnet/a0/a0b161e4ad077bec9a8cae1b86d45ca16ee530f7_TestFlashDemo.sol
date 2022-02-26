// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import './FlashLoanReceiverBase.sol';
import './Interfaces.sol';
import './Libraries.sol';
import './Ownable.sol';


contract TestFlashDemo is FlashLoanReceiverBase, Ownable {
    
    ILendingPoolAddressesProvider provider;
    using SafeMath for uint256;
    address lendingPoolAddr;
    
    
    // intantiate lending pool addresses provider and get lending pool address
    constructor(ILendingPoolAddressesProvider _addressProvider) FlashLoanReceiverBase(_addressProvider) public {
        provider = _addressProvider;
        lendingPoolAddr = provider.getLendingPool();
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
    )
        external
        override
        returns (bool)
    {
        DecodedParams memory dparams = decodeParams(params);

       flashTotargetusingsushi(dparams.numberofpath, amounts[0], assets[0], dparams.targetToken);
       targetToflashusingquick(dparams.numberofpath, dparams.targetToken, assets[0]);

        
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(_lendingPool), amountOwing);
        }

        return true;
    }

  
    /*
    * This function is manually called to commence the flash loans sequence
    */
    function executeFlashLoans(address flashedcrypto, uint256 flashedamount, bytes memory _params) public onlyOwner {
        address receiverAddress = address(this);

        // the various assets to be flashed
        address[] memory assets = new address[](1);
        assets[0] = flashedcrypto; 
        
        // the amount to be flashed for each asset
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = flashedamount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory params = _params;
        uint16 referralCode = 0;

        _lendingPool.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }
    
        
    /*
    * Rugpull all ERC20 tokens from the contract
    */
    function rugPull(address[] memory crypto) public payable onlyOwner {
        
        // withdraw all ETH
        msg.sender.call{ value: address(this).balance }("");
        
        // withdraw all x ERC20 tokens\
        for(uint i = 0; i < crypto.length; i++)
        IERC20(crypto[i]).transfer(msg.sender, IERC20(crypto[i]).balanceOf(address(this)));
    }
    
    

    function getspreadsushitoquick(address flashedcrypto, address targetToken) public view returns(int profit, string memory stringpath) { 
     
     uint indecimal = IERC20Uniswap(flashedcrypto).decimals();
     uint amountsIn = 10**(indecimal);
     address[] memory path1 = Myutility.getpath(2,flashedcrypto,targetToken);
     address[] memory path2 = Myutility.getpath(3,flashedcrypto,targetToken);
     int profit1 = Myutility.getpropitwithdecimal4(amountsIn,path1);
     int profit2 = Myutility.getpropitwithdecimal4(amountsIn,path2);
     if(profit1 > profit2) {
         profit = profit1;
         stringpath="direct";
         }else{
         profit = profit2;
         stringpath="via wmatic";
         }
    }

    function getbytesparams(uint numberofpath, address targetToken) public pure returns(bytes memory){
        bytes memory bytesparams = abi.encode(numberofpath,targetToken);
        return bytesparams;
    }
     

    function flashTotargetusingsushi(uint numberofpath, uint amountIn, address flashedcrypto, address targetToken) internal{
     address to =  address(this);
     uint deadline = block.timestamp + 1 days;
     address[] memory path = Myutility.getpath(numberofpath,flashedcrypto,targetToken);     
     approvemanually(path);
     uint[] memory expectedAmountsOut = UniswapV2Library.getAmountsOut1(Myutility.getfactory(Myutility.sushiswaprouter), amountIn, path);
     uint amountOutMin = expectedAmountsOut[path.length-1] * 95 / 100;
     IUniswapV2Router02(Myutility.sushiswaprouter).swapExactTokensForTokens(amountIn,amountOutMin,path,to,deadline);
     }

     function targetToflashusingquick(uint numberofpath, address targetToken, address flashedcrypto) internal {
     address to =  address(this);
     uint amountIn = IERC20(targetToken).balanceOf(address(this));
     uint deadline = block.timestamp + 1 days;
     address[] memory path = Myutility.getpath(numberofpath,targetToken,flashedcrypto);
     uint[] memory expectedAmountsOut = UniswapV2Library.getAmountsOut2(Myutility.getfactory(Myutility.quickswaprouter), amountIn, path);
     uint amountOutMin = expectedAmountsOut[path.length-1] * 95 / 100;
     IUniswapV2Router02(Myutility.quickswaprouter).swapExactTokensForTokens(amountIn,amountOutMin,path,to,deadline);
     }

      function approvemanually(address[] memory token) internal {
        uint amount = 2**256 -1;
        for(uint i=0;i<token.length;i++){
        IERC20(token[i]).approve(Myutility.quickswaprouter,amount);
        IERC20(token[i]).approve(Myutility.sushiswaprouter,amount);
        }
    }

    struct DecodedParams {
        uint numberofpath;
        address targetToken;
    }

    function decodeParams(bytes memory params) internal pure returns (DecodedParams memory) {
    (uint numberofpath,address targetToken) = abi.decode(params,(uint,address));

    return DecodedParams(numberofpath,targetToken);
    }

}