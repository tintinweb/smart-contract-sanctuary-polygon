/**
 *Submitted for verification at polygonscan.com on 2022-08-01
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts/carteras/crypto/portfolio_crypto.sol


pragma solidity ^0.8.14;

interface ICarterasDesbloqueadas {
    function getCartera(address ad) external view returns(uint);
}
interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external pure returns (uint8);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}
interface ISwapper {
    function getGasEfficientSwapsByTokens(address tokenA, address tokenB,uint amountA) external view returns (uint price,bytes memory bestSwap);
    function getBestSwapsByTokens(address tokenA, address tokenB,uint amountA) external view returns (uint price,bytes memory bestSwap);
    function bestSwapTokensForTokensByPath(bytes calldata path,uint amountA,uint minAmountTokenB) external payable returns(uint amountOut);
    function bestSwapTokensForTokens(address tokenA,address tokenB,uint amountA,uint minAmountTokenB) external payable returns(uint amountOut);
}
interface ILiquidity {
    function swapAndLiquify(uint256 amount) external;
    function addLiquidity(uint256 tokenAmount, uint256 otherTokenAmount) external;
    function getTokenPrice() external view returns(uint);
}
interface IDEXRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
}
contract PortfolioCrypto {
    ICarterasDesbloqueadas public unlocked_carteras;
    ISwapper public swapper;
    ILiquidity public liquidity;
    struct InitialInvest{
        uint time;
        uint investedUSDC;// Quantity of USDC
        bytes userTokens;// Token and quantity of token
    }
    struct Tracker{
        uint time;
        address tokenA;
        address tokenB;
        uint distribution;//1.000.000=1%, distribution tokenA to tokenB
        uint price;
    }
    struct TokenERC20{
        address token;
        uint decimals;
        uint currentBalance;
    }
    mapping (address => bool) public permitedAddress;
    mapping (address => InitialInvest[]) private investOf;
    uint public sizeHistorical;
    mapping (uint => Tracker) public historical;
    uint public sizeTokens;
    mapping (uint => address) public tokens;
    mapping (address => uint) private token_pos;
    mapping (address => TokenERC20) public ERC20Data;
    uint private constant maxPercent=100000000;
    uint private constant onePercent=1000000;
    uint public totalInvestedUSDC;
    address constant private USDC=0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant private HBLOCK=0x1b69D5b431825cd1fC68B8F883104835F3C72C80;
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        delete unlocked;
        _;
        unlocked = 1;
    }
    constructor(){
        sizeTokens=1;
        token_pos[USDC]=0;
        tokens[0]=USDC;
        ERC20Data[USDC]=TokenERC20(USDC,6,0);
        permitedAddress[msg.sender]=true;
        swapper=ISwapper(0x836Dc5d6DE75E306d59f7393d2f67874474fADBe);
        unlocked_carteras=ICarterasDesbloqueadas(0x9798982ce54DD67D7b225B6043539F505a5287ad);
        liquidity=ILiquidity(0xA967d9e99b94704369e099CAb4c2235Cd417E6b6);
    }
    modifier whenPermited() {
        require(permitedAddress[msg.sender],"Not permited");
        _;
    }
    function setPermitedAddress(address ad, bool permited) external whenPermited {
        permitedAddress[ad]=permited;
    }
    function setLiquidityAddress(address ad) external whenPermited {
        liquidity=ILiquidity(ad);
    }
    function setSwapperAddress(address ad) external whenPermited {
        swapper=ISwapper(ad);
    }
    function setCarterasDesbloquedas(address ad) external whenPermited{
        unlocked_carteras=ICarterasDesbloqueadas(ad);
    }
    function swapAndSendHBLOCK(address ad,uint amount) internal{
        address router=0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = HBLOCK;
        IERC20(USDC).approve(router,amount);
        IDEXRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount,0,path,ad,block.timestamp);
    }
    function autoLiquidityFee(uint fee) internal{
        if(fee>0){
            address liquidityContract=address(liquidity);
            uint minBalanceFeeToken=(fee*ILiquidity(liquidityContract).getTokenPrice())/(10**6);
            if(IERC20(HBLOCK).balanceOf(liquidityContract)>=minBalanceFeeToken){
                IERC20(USDC).transfer(liquidityContract,fee);
                ILiquidity(liquidityContract).addLiquidity(minBalanceFeeToken,fee);
            }else{
                swapAndSendHBLOCK(liquidityContract,fee);
                uint tAmount=IERC20(HBLOCK).balanceOf(liquidityContract);
                if(tAmount>200*10**18){
                    ILiquidity(liquidityContract).swapAndLiquify(tAmount);
                }
            }
        }
    }
    function getPriceOnChain(address token) external view returns(uint price){
        (price,)=swapper.getGasEfficientSwapsByTokens(token,USDC,10**IERC20(token).decimals());
    }
    function getPriceOnChainWithDecimals(address token,uint decimals) public view returns(uint price){
        (price,)=swapper.getGasEfficientSwapsByTokens(token,USDC,10**decimals);
    }
    function getBalancesTokens(uint start, uint end) external view returns(TokenERC20[] memory balancesTokens){
        require(start<end && start>=0 && end<=sizeTokens,"Invalid start or end.");
        balancesTokens=new TokenERC20[](end-start);
        while(start<end){
            balancesTokens[start]=ERC20Data[tokens[start]];
            assembly{
                start:=add(start,1)
            }
        }
    }
    function getBalancesTokensInUSDC() public view returns(uint totalAssetsInUSDC,uint[] memory balancesTokensInUSDC){
        uint len=sizeTokens;
        TokenERC20 memory token;
        balancesTokensInUSDC=new uint[](len);
        uint i;
        while(i<len){
            token=ERC20Data[tokens[i]];
            if(token.token==USDC){
                balancesTokensInUSDC[i]=token.currentBalance;
            }else{
                balancesTokensInUSDC[i]=token.currentBalance*getPriceOnChainWithDecimals(token.token,token.decimals);
            }
            totalAssetsInUSDC+=balancesTokensInUSDC[i];
            assembly{
                i:=add(i,1)
            }
        }
    }
    function getDistributionTokens() external view returns(uint[] memory distribution){
        uint totalEquivalentUSDC;
        (totalEquivalentUSDC,distribution)=getBalancesTokensInUSDC();
         uint i;
        while(i<distribution.length){
            distribution[i]=onePercent*distribution[i]/totalEquivalentUSDC;
            assembly{
                i:=add(i,1)
            }
        }
    }
    function swapAndSetInitTokens(uint amount,uint totalEquivalentUSDC,uint[] memory distribution) internal {
        address _token;
        uint amountLeft=amount;
        uint calc;
        uint i;
        InitialInvest memory newInvest;
        newInvest.time=block.timestamp;
        newInvest.investedUSDC=amount;
        TokenERC20[] memory initBalance=new TokenERC20[](distribution.length); 
        while(i<distribution.length){
            _token=tokens[i];
            calc=amount*distribution[i]/totalEquivalentUSDC;
            if(i==distribution.length-1){
                calc=amountLeft;
            }
            amountLeft-=calc;
            if(_token!=USDC){
                (uint amountOut,bytes memory path)=swapper.getGasEfficientSwapsByTokens(USDC,_token,calc);
                if(amountOut>0){
                    IERC20(USDC).approve(address(swapper),calc);
                    amountOut=swapper.bestSwapTokensForTokensByPath(path,calc,amountOut*95/100);
                    ERC20Data[_token].currentBalance+=amountOut;
                    initBalance[i]=TokenERC20(_token,ERC20Data[_token].decimals,amountOut);
                }else{
                    ERC20Data[USDC].currentBalance+=calc;
                    initBalance[i]=TokenERC20(USDC,6,calc);
                }
            }else{
                ERC20Data[USDC].currentBalance+=calc;
                initBalance[i]=TokenERC20(USDC,6,calc);
            }
            assembly{
                i:=add(i,1)
            }
        }
        newInvest.userTokens=abi.encode(initBalance);
        investOf[msg.sender].push(newInvest);
    }
    function syncBalances() external {
        uint len=sizeTokens;
        address _token;
        uint i;
        while(i<len){
            _token=tokens[i];
            ERC20Data[_token].currentBalance=IERC20(_token).balanceOf(address(this));
            assembly{
                i:=add(i,1)
            }
        }
    }
    function invest(uint amount) external lock {
        require(unlocked_carteras.getCartera(msg.sender)>5, "Error: Can't invest, need to unlock this investment first");
        (uint totalEquivalentUSDC,uint[] memory balancesTokens)=getBalancesTokensInUSDC();
        require(IERC20(USDC).transferFrom(msg.sender,address(this),amount),"Error: Not approved or can't transfer this token");
        uint fee=amount/100;//1% fee
        autoLiquidityFee(fee);
        amount-=fee;
        swapAndSetInitTokens(amount,totalEquivalentUSDC,balancesTokens);
        totalInvestedUSDC+=amount;
    }
    function simulateBalanceByInitialInvest(InitialInvest memory inv) public view returns(uint[] memory balancesTokens) {
        uint size=sizeHistorical;
        balancesTokens=new uint[](sizeTokens);
        Tracker memory _track;
        uint i;uint pos;
        TokenERC20[] memory initBalance=abi.decode(inv.userTokens,(TokenERC20[]));
        while(i<initBalance.length){
            pos=token_pos[initBalance[i].token];
            balancesTokens[pos]+=initBalance[i].currentBalance;
            assembly{
                i:=add(i,1)
            }
        }
        i=0;
        while(i<size){
            _track=historical[i];
            if(_track.time>inv.time){
                pos=token_pos[_track.tokenA];
                uint amountA=balancesTokens[pos]*_track.distribution/onePercent;
                balancesTokens[pos]-=amountA;
                pos=token_pos[_track.tokenB];
                balancesTokens[pos]+=amountA*_track.price/10**25;
            }
            assembly{
                i:=add(i,1)
            }
        }
    }
    function getTokensBalanceOf(address ad) public view returns(uint _totalInvestedUSDC,TokenERC20[] memory balancesTokens){
        InitialInvest[] memory inv=investOf[ad];
        require(inv.length>0,"No investment found.");
        uint[] memory b1=simulateBalanceByInitialInvest(inv[0]);
        uint i=1;
        while(i<inv.length){
            _totalInvestedUSDC+=inv[i].investedUSDC;
            b1=sumBalances(b1,simulateBalanceByInitialInvest(inv[i]));
            assembly{
                i:=add(i,1)
            }
        }
        i=0;
        balancesTokens=new TokenERC20[](countWithoutZero(b1));
        uint count;
        while(i<b1.length){
            if(b1[i]>0){
                address t0=tokens[i];
                balancesTokens[count]=TokenERC20(t0,ERC20Data[t0].decimals,b1[i]);
                assembly{
                    count:=add(count,1)
                }
            }
            assembly{
                i:=add(i,1)
            }
        }
    }
    function getTokensBalanceInUSDCOf(address ad) public view returns(uint totalAssetsInUSDC,TokenERC20[] memory balancesTokens){
        (,balancesTokens)=getTokensBalanceOf(ad);
        uint i;
        while(i<balancesTokens.length){
            if(balancesTokens[i].token!=USDC){
                balancesTokens[i].currentBalance=balancesTokens[i].currentBalance*getPriceOnChainWithDecimals(balancesTokens[i].token,balancesTokens[i].decimals);
            }
            totalAssetsInUSDC+=balancesTokens[i].currentBalance;
            assembly{
                i:=add(i,1)
            }
        }
    }
    function countWithoutZero(uint[] memory arr) internal pure returns(uint count){
        uint i;
        while(i<arr.length){
            if(arr[i]>0){
                count++;
            }
            assembly{
                i:=add(i,1)
            }
        }
    }
    function sumBalances(uint[] memory b1,uint[] memory b2) internal pure returns(uint[] memory) {
        uint i;
        while(i<b1.length){
            b1[i]+=b2[i];
            assembly{
                i:=add(i,1)
            }
        }
        return b1;
    }
    function swap(bytes calldata path,uint amountA,uint minAmountTokenB) external whenPermited lock {
        address tokenA;address tokenB;
        assembly {
            tokenA := shr(96, calldataload(add(path.offset, 20)))
            tokenB := shr(96, calldataload(add(path.offset,sub(path.length,24))))
        }
        Tracker memory track;
        track.time=block.timestamp;
        track.tokenA=tokenA;
        track.tokenB=tokenB;
        track.distribution=onePercent*amountA/ERC20Data[tokenA].currentBalance;
        IERC20(tokenA).approve(address(swapper),amountA);
        uint amountOut=swapper.bestSwapTokensForTokensByPath(path,amountA,minAmountTokenB);
        track.price=amountOut*10**25/amountA;
        // add track to historical
        uint size=sizeHistorical;
        historical[size]=track;
        sizeHistorical=size+1;
        //update info
        size=sizeTokens;
        TokenERC20 memory _tokenA=ERC20Data[tokenA];
        _tokenA.currentBalance-=amountA;
        /*
        if(_tokenA.currentBalance==0){
            _tokenA.token=address(0);
            uint pos=token_pos[tokenA];
            address aux=tokens[size-1];
            tokens[pos]=aux;
            token_pos[aux]=pos;
            sizeTokens=size-1;
        }
        */
        ERC20Data[tokenA]=_tokenA;
        TokenERC20 memory _tokenB=ERC20Data[tokenB];
        _tokenB.currentBalance+=amountOut;
        if(_tokenB.token==address(0)){
            _tokenB.token=tokenB;
            _tokenB.decimals=IERC20(tokenB).decimals();
            tokens[size]=tokenB;
            token_pos[tokenB]=size;
            sizeTokens=size+1;
        }
        ERC20Data[tokenB]=_tokenB;
    }
    //percent 1.000.000=1%
    function withdraw(uint percent) external lock returns(uint amount) {
        (uint investedUSDC,TokenERC20[] memory bTokens)=getTokensBalanceOf(msg.sender);
        if(percent>maxPercent){
            percent=maxPercent;
        }
        //swap all tokens of user to USDC
        uint i;
        while(i<bTokens.length){
            uint amountIn=bTokens[i].currentBalance*percent/maxPercent;
            if(amountIn>0){
                (uint amountOut,bytes memory path)=swapper.getGasEfficientSwapsByTokens(bTokens[i].token,USDC,amountIn);
                IERC20(bTokens[i].token).approve(address(swapper),amountIn);
                amountOut=swapper.bestSwapTokensForTokensByPath(path,amountIn,amountOut*95/100);
                amount+=amountOut;
                ERC20Data[bTokens[i].token].currentBalance-=amountIn;
                bTokens[i].currentBalance-=amountIn;
            }
            assembly{
                i:=add(i,1)
            }
        }
        totalInvestedUSDC-=investedUSDC*percent/maxPercent;
        investedUSDC-=investedUSDC*percent/maxPercent;
        if(investedUSDC>0){
            InitialInvest memory unifyInvest;
            unifyInvest.time=block.timestamp;
            unifyInvest.investedUSDC=investedUSDC;
            unifyInvest.userTokens=abi.encode(bTokens);
            delete investOf[msg.sender];
            investOf[msg.sender].push(unifyInvest);
        }else{
            delete investOf[msg.sender];
        }
        //end swap
        uint fee=amount/100;//1% fee
        autoLiquidityFee(fee);
        amount-=fee;
        require(IERC20(USDC).transfer(msg.sender,amount),"Withdraw: Error on transfer");
    }
    address constant private WMATIC=0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    receive() external payable {
        (bool success,) = WMATIC.call{value:msg.value}(new bytes(0));
        require(success, 'MATIC to WMATIC TRANSFER FAILED');
    }
    function priceOffChainETH_USD() external view returns(uint){
        uint price=getLatestPriceOffChainD30(0xF9680D99D6C9589e2a93a78A04A279e509205945); //ETH/USD
        return  price/10**24;
    }
    function getLatestPriceOffChainD30(address ad) public view returns (uint priceD30) {
        (,int price,,,) = AggregatorV3Interface(ad).latestRoundData();
        priceD30=uint(price)*10**(30-AggregatorV3Interface(ad).decimals());
    }
    function withdrawToken(address token,address wallet,uint amount) external whenPermited {
        require(IERC20(token).transfer(wallet,amount),"Fail on transfer.");
    }
    function withdrawMatic(address wallet,uint amount) external whenPermited {
        (bool success,) = wallet.call{value:amount}(new bytes(0));
        require(success, 'MATIC TRANSFER FAILED');
    }
}