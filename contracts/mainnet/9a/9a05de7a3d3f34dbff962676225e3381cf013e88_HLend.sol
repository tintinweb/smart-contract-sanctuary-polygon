/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PcvStruct {

    struct PcvStrategy{
        uint256 strategyId;
        address[] protocol;
        string[] methods; // method and params
        bool available;
        address[][] inputTokens;
        address[][] outputTokens;
        address initToken; // tokens of initial capital
        uint256[][] inputPercent;
        uint percentBase;
        bool[][] needAmount; 
        bool[][] needInvest;
        bool closePosition;
    }

    struct PcvInfo{
        address factory;
        address owner;
        bool available;
        address collectAccount;
        address settleAsset;
        uint256 minInvest;
        uint256 maxInvest;
    }

    struct StrategyExecVariable{
        address[] allOutputTokens;
        uint256[] oldOutputBalance;
        uint256[] outputAmount ;
        uint256[] usedOutputAmount;
        uint256 initAmount;
    }


    struct ProtocolMethodInfo{
        string method;
        bytes abiCode;
        uint inputParams;
        uint outputParams;
        bool available;
        bool [] needAmount;
        bool [] needInvest;
    }

}

interface IPcvStorage is PcvStruct{

    function addPcv(address pcvOwner,address pcv,address settleAsset,uint256 minInvest,uint256 maxInvest) external ;

    function addStrategy(
        address[] memory protocols,
        string[] memory methods,
        address[][] memory inputTokens,
        address[][] memory outputTokens,
        address initToken,
        uint[][] memory inputPercent,
        bool closePosition) external;

    function removeStrategy(uint256 stragegyId) external ;

    function getPcvInfo(address pcv) external view returns(PcvInfo memory);

    function getPcvAssets(address pcv) external view returns(address [] memory);

    function getStrategy(address pcv,uint256 id) external view returns(PcvStrategy memory);

    function isSupportOperate(address pcv,bytes memory method) external view returns(bool);

    function addSupportOperate(address protocal,string[] memory methods) external ;

    function removeSupportOperate(address protocal,bytes memory method) external ;

    function setProxyFactory(address newPcvFactory)external ;

    // PCV Proxy contract logic executor
    function setExecutor(address executor) external;

    function getExecutor() external view returns(address);

    function getCollectAccount(address PCV) external view returns(address);

    function getMaticToken() external view returns(address);

    function getWMatic() external view returns(address);

    function getETHER() external view returns(address);

    function getPercentBase() external view returns(uint);

    function getMetodInfo(address protocol,bytes memory methodAbi) external view returns(ProtocolMethodInfo memory);

    function pcvIsExsit(address owner,address pcv) external view returns(bool);

    // about token start
     function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function name() external view returns (string memory);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function tokenAdd(address account, uint256 amount) external;
    
    function tokenSub(address account, uint256 amount) external;
    
    function allowance(address pcv,address owner,address spender) external view returns (uint256);
    
    function approve(address owner, address spender, uint256 amount) external ;
    
    function approveSub(address owner, address spender, uint256 amount) external;

    // about token end 

    function autoExecute(address pcv) external view returns(bool);

    function setAutoStrategy(uint strategyId) external ;

    function setAutoExecute(bool isAuto) external;

    function getAutoStrategy(address pcv) external view returns(uint);

    function isSupportAsset(address protocol,address token) external view returns(bool);

    function settlement() external returns(address); 

    function setSupportAssets(address protocol,address [] memory tokens) external;

    function comptroller() external view returns(address);

    function getLogic() external view returns(address);

    function recordPcvAssets(address [] memory newAssets) external;

    function setInvestLimit(uint minInvest,uint maxInvest) external ;

    function liquidator() external view returns(address);

    function setAutoClosePosition(uint strategyId) external ;
    
    function openClosePosition(bool open) external ;

    function autoClosePosition(address pcv) external view returns(uint);

    function autoClose(address pcv) external view returns(bool);

    }
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

/**
 * @dev Extended from interface of the ERC20.
 */
interface IERC20Extra is IERC20 {
    function decimals() external view returns (uint8) ;
}

interface SettlementOracle{
    // get underlying address by pToken address 
    // return decimals = 18
    function getUnderlyingPrice(address _token) external view returns (uint);
}

contract Hcommon{
    
    /* 
    @dev get token price, and convert to standardToken
    @param _token token
    @param standardToken price unit token
    */
    function getPrice(address _token, address standardToken) public view returns(uint price){
        address priceOracle = 0x35F3195F5A2dcbBf39b5fcB180e383d6355ba00c;
        address polygonUSDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        address polygonUSDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        if(_token == polygonUSDC || _token == polygonUSDT){
            return 1e6;
        }
        SettlementOracle oracle = SettlementOracle(priceOracle);
        price = oracle.getUnderlyingPrice(_token); // price of USD,decimals =18

        if(standardToken != polygonUSDT && standardToken != polygonUSDC){
            uint standardPrice = oracle.getUnderlyingPrice(standardToken);
            price =  price * 1e18 / standardPrice;
            uint8 decimalDiff = 18 - IERC20Extra(standardToken).decimals();
            return price / 10 ** decimalDiff;
        }
        price = price / 1e12;
    }

}

interface IPERC20 {
    // Deposit ,requires token authorization
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    // repay borrow params => -1
    function repayBorrow(uint256 repayAmount) external returns (uint256);

    // return 4 params: 0, deposit amount, borrow amount, share net value
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint) ;
    // return borrow amount
    function borrowBalanceStored(address account) external view returns (uint);
    // underlying token of the pool
    function underlying() external view returns(address);
    function balanceOf(address owner) external view returns(uint256);
}

interface LendComptroller{
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);
    /**
     * PIGGY-MODIFY:
     * @notice Add assets to be included in account liquidity calculation
     * @param pTokens List of cToken market addresses to be activated
     * @return Whether to enter each corresponding market success indicator
     */
    function enterMarkets(address[] memory pTokens) external returns(uint[] memory);

    function exitMarket(address pTokenAddress) external returns (uint);

    // Query available loan (whether it is normal 0: normal, remaining loanable amount, loan asset premium)
    function getAccountLiquidity(address account) external view returns (uint, uint, uint) ;

    // Query the fund pool that has opened the pledge
    function getAssetsIn(address account) external view returns(address [] memory);
}

interface IPoolProvider{
    // get asset pool address by token address
    function getUnderlyingByPToken(address underlying) external view returns (address pToken);
    // return rate;  rate = token / pToken; pToken.decimals = 8;
    function currentExchangeRateStored(address pToken) external view returns (uint);
}

contract HLend is Hcommon{
    address _pcvStorage ;

    function deposit(address token,uint256 amount) external  {
        address pool = getPool(token);
        IERC20(token).approve(pool,amount);
        uint balance = _pTokenBalance(token);
        IPERC20(pool).mint(amount);
        require(balance > _pTokenBalance(token));
    }

    function borrow(address token,uint256 amount) external  {
        address pool = getPool(token);
        pledge(pool);
        uint balance = _pTokenBalance(token);
        IPERC20(pool).borrow(amount);
        require(balance < _tokenBalance(token));
        
        address[] memory assets = new address[](1);
        assets[0] = pool;
        IPcvStorage(_pcvStorage).recordPcvAssets(assets);
    }

    function withdrawByPToken(address pToken,uint256 amount) external {
        uint balance = _pTokenBalance(pToken);
        IPERC20(pToken).redeem(amount);
        require(balance > _pTokenBalance(pToken));
    }

    function withdraw(address token,uint256 amount) external{
        address pool = getPool(token);
        uint balance = _tokenBalance(token);
        IPERC20(pool).redeem(amount);
        require(balance < _pTokenBalance(token));
    }

    function repayBorrow(address token,uint256 amount) external {
            address pool = getPool(token);
            uint borrowed = IPERC20(pool).borrowBalanceStored(address(this));
            if(borrowed == 0){
                return;
            }
            IERC20(token).approve(pool,amount);
            uint balance = _pTokenBalance(token);
            if(amount <= borrowed){
                IPERC20(pool).repayBorrow(amount);
            }else{
                int repayAll = -1;
                IPERC20(pool).repayBorrow(uint(repayAll));
            }
        require(balance > _pTokenBalance(token));
        }


    // Turn on the pledge switch
    function pledge(address pool) internal {
        address comptorller = getLendComptroller();
        address [] memory assets = LendComptroller(comptorller).getAssetsIn(address(this));
        uint256 arrayLen = assets.length;
        bool hasPledge = false;
        for(uint256 i = 0;i<arrayLen;i++){
            if(pool == assets[i]){
                hasPledge = true;
            }
        }
        if(!hasPledge){
            address[] memory pledges = new address[](1);
            pledges[0] = pool;
            LendComptroller(comptorller).enterMarkets(pledges);
        }
    }

    function enterMarket(address[] memory pools) public{
            address comptorller = getLendComptroller();
            LendComptroller(comptorller).enterMarkets(pools);
    } 

    function  isEntermarket(address pToken) public view returns(address[] memory) {
        address comptorller = getLendComptroller();
        address[] memory assets = LendComptroller(comptorller).getAssetsIn(pToken);
        return assets;
    }

    function getPool(address token) public view returns(address ){
        // pool address
       return IPoolProvider(poolProvider()).getUnderlyingByPToken(token);
        
    }

    function getLendComptroller() internal pure returns(address comptroller ){
        comptroller = 0xE19bedCc1beDF52F63b401bd21f16529be33Fc7E;
        return comptroller;
    }

    // borrowed amount
    function borrowedAmount(address token) public view returns(uint borrowed){
       borrowed = IPERC20(getPool(token)).borrowBalanceStored(address(this));
    }

    function poolProvider() public pure returns(address){
       return 0x76831939fc9A078a9Fd4A5B005C8A19c9012bA45;
       }

       function pTokenDecimals() private pure returns(uint){
           return 8;
       }

    //@dev get pToken amount by token
    function getPTokenAmount(address token , uint amount) public view returns(uint pTokenAmount){
        address pToken = getPool(token);
        uint changeRate = IPoolProvider(poolProvider()).currentExchangeRateStored(pToken);
        uint tokenDecimals = IERC20Extra(token).decimals();
        uint _pTokenDecimals = pTokenDecimals();
        
        // 1e18 - pToken.decimals = 10; pToken.decimals = 8;
        uint changeRateScale = 10**(tokenDecimals + 18 -_pTokenDecimals);
        
        pTokenAmount = (tokenDecimals >= _pTokenDecimals) ?
        amount * changeRateScale / changeRate / 10**(tokenDecimals - _pTokenDecimals):
        amount * changeRateScale  / changeRate * 10**(_pTokenDecimals - tokenDecimals);
    }

    // @dev get token amount by pToken
    function getTokenAmount(address pToken , uint amount) public view returns(uint tokenAmount){
        uint changeRate = IPoolProvider(poolProvider()).currentExchangeRateStored(pToken);
         tokenAmount  =  amount * changeRate / 1e18;
    }
    
    function _tokenBalance(address token) private view returns(uint){
       return IERC20(token).balanceOf(address(this));
    }

    function _pTokenBalance(address pToken) private view returns(uint){
       return IPERC20(pToken).balanceOf(address(this));
    }
}