/**
 *Submitted for verification at polygonscan.com on 2022-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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
        // address investAmount;
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


interface ISettlementOracle{
    // get underlying address by pToken address 
    // return decimals = 18
    function getUnderlyingPrice(address _token) external view returns (uint);
}

// settlement contract
interface ISettlement{
    // params (PCV Address, total shares) 
    function netAssetValue(address pcv) external view returns (uint netAssets, uint totalDebt, uint netWorth);
    //返回 基本单位，质押率
    function tokenConfig(address token) external view returns(uint baseUnit,uint exchangeRateMantissa);
}

library Hcommon{
    
    /* 
    @dev get token price, and convert to standardToken
    @param _token token
    @param standardToken price unit token
    */
    function getPrice(address _token, address standardToken) public view returns(uint price){
        address priceOracle = 0x97cae7e1261f25D4a8226b9D2C89d259121b04a2; // price oracle of settlement contract 
        address polygonUSDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        address polygonUSDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        if(_token == polygonUSDC || _token == polygonUSDT){
            return 1e6;
        }
        ISettlementOracle oracle = ISettlementOracle(priceOracle);
        price = oracle.getUnderlyingPrice(_token); // price of USD,decimals =18

        if(standardToken != polygonUSDT && standardToken != polygonUSDC){
            uint standardPrice = oracle.getUnderlyingPrice(standardToken);
            price =  price * 1e18 / standardPrice;
            uint8 decimalDiff = 18 - IERC20Extra(standardToken).decimals();
            return price / 10 ** decimalDiff;
        }
        price = price / 1e12;
    }

    function getBalance(address token, address account) public view returns(uint){
       return IERC20(token).balanceOf(account);
    }

    // 风控资金利用率 0.8
    function riskRate() public pure returns(uint){
        return 8*1e17;
    }

    function fullRiskRate() public pure returns(uint){
        return 1e18;
    }

    // 如有重新部署dpLend封装合约，需要修改dpLend
    function hDpLend() public pure returns(address dpLend){
        dpLend =0x2d72B2855553C51745F05ec73d4aD37DB7cED9E9 ;
    }

    // 如有重新部署quickswap封装合约，需要修改qSwap
    function hQuickswap() public pure returns(address qSwap){
        qSwap = 0xC4A73c157d437387fE0751611e391B95c7a3F45C;
    }

    // 如有重新部署：quickDualStakingReward 封装合约，需要修改qStaking
    function hQuickStaking() public pure returns(address qStaking){
        qStaking = 0x1788B907e821802284818C6165438BE203ad0545;
    }


}