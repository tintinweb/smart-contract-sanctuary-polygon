/**
 *Submitted for verification at polygonscan.com on 2022-04-12
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

    function getComtroller() external view returns(address);

    function getLogic() external view returns(address);

    function recordPcvAssets(address [] memory newAssets) external;

    function setInvestLimit(uint minInvest,uint maxInvest) external ;

    function liquidator() external view returns(address);

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



// Comptroller Contract
 interface Comptroller{
    // PCV fund utilization counting, for the purpose of judge the availability of the fund
    function canUsePcvFund(address account) external view returns (bool) ;
}

// Warp the protocol contract
interface WrapProtocol{
    // get the price of the token
    function getPrice(address _token, address standardToken) external view returns(uint price);
}


contract LogicExecutor is PcvStruct{
    address _pcvStorage ;

    // Execute the strategy logic
    function lg_execute(
        uint256 strategyId,
        uint256 initAmount
    ) external {
        PcvStrategy memory strgy =  IPcvStorage(_pcvStorage).getStrategy(address(this),strategyId);
        require(strgy.available,"strategy is unavailable");

        uint steps = strgy.protocol.length;  // Execute steps of the strategy
        uint outputLen = 0;  // Execute output params length
        uint inputLen = 0;  // Execute input params length

        address Wmatic = _wmatic();
        for(uint s = 0; s < steps; s++){
            for(uint out = 0; out < strgy.outputTokens[s].length; out++){
                // matic transfer to wmatic
                if(_isMatic(strgy.outputTokens[s][out])){
                    strgy.outputTokens[s][out] = Wmatic;
                }
                outputLen += 1;
            }
            for(uint i = 0; i < strgy.inputTokens[s].length; i++){
                if(_isMatic(strgy.inputTokens[s][i])){
                    strgy.inputTokens[s][i] = Wmatic;
                }
                inputLen += 1;
            }
        }

        StrategyExecVariable memory vrb = StrategyExecVariable({
            // make init token as output, add one position
            allOutputTokens:new address[](outputLen+1),  // all output tokens
            oldOutputBalance:new uint256[](outputLen+1),  // all output balance
            outputAmount:new uint256[](outputLen+1),  // record output amount 
            usedOutputAmount:new uint256[](outputLen+1),  // record used output amount
            initAmount:initAmount
        });
         
        // put all output tokens into vrb.allOutputTokens
        uint outIdx = 0;
        for(uint s = 0; s < steps; s++){
            for(uint out = 0; out < strgy.outputTokens[s].length; out++){
                if(strgy.outputTokens[s][out] == address(0)){
                    continue;
                }
                uint index = _getIndex(strgy.outputTokens[s][out] , vrb.allOutputTokens);
                // put output token into vrb.allOutputTokens if not exist
                if(index > vrb.allOutputTokens.length){
                    vrb.allOutputTokens[outIdx] = strgy.outputTokens[s][out];
                    outIdx += 1;
                    }
                }
        }

        // put all output balance into vrb.oldOutputBalance
        for(uint i = 0; i< vrb.allOutputTokens.length; i++){
            if(vrb.allOutputTokens[i] == address(0)){
                continue;
            }
            vrb.oldOutputBalance[i] = _getBalance(vrb.allOutputTokens[i]);
        }

        // initzialize the initAmount as one output
        uint initIdx = _getIndex(strgy.initToken,vrb.allOutputTokens);
        if(initIdx > vrb.allOutputTokens.length){
            vrb.allOutputTokens[outIdx] = strgy.initToken;
            vrb.outputAmount[outIdx] = initAmount;
            vrb.oldOutputBalance[outIdx] = _getBalance(strgy.initToken);
        }else{
            vrb.outputAmount[initIdx] = initAmount;
            vrb.oldOutputBalance[initIdx] = _getBalance(strgy.initToken) - initAmount;
        }

        for(uint i = 0; i < steps; i++){
            (strgy,vrb) = _callMethod(strgy,vrb,i);
            require(_canUseFund(),"Fail by utilization");
        }
    }


    function _callMethod(PcvStrategy memory strgy,StrategyExecVariable memory vrb, uint step) internal
    returns(PcvStrategy memory ,StrategyExecVariable memory ) {
        // record the balance before transaction
        uint256 [] memory beforeOutBalance = new uint256[](strgy.outputTokens[step].length);
        for (uint b = 0;b < beforeOutBalance.length; b++) {
            beforeOutBalance[b] = _getBalance(strgy.outputTokens[step][b]);
        }

        ProtocolMethodInfo memory minfo = IPcvStorage(_pcvStorage).getMetodInfo(strgy.protocol[step],abi.encodeWithSignature(strgy.methods[step]));

        uint256 [] memory inAmount = new uint256 [] (strgy.inputTokens[step].length);
        uint inIdx = 0;

        // calculate input token amount
        for (uint i = 0 ; i < strgy.inputTokens[step].length; i++) {
            uint outIdx = _getIndex(strgy.inputTokens[step][i],vrb.allOutputTokens);
            
            if (minfo.needInvest[i]) {
                inAmount[inIdx] = vrb.outputAmount[outIdx] * strgy.inputPercent[step][i] / strgy.percentBase;
                vrb.outputAmount[outIdx] -= inAmount[inIdx];
                vrb.usedOutputAmount[outIdx] += inAmount[inIdx];
                inIdx += 1;
            }
            else if (minfo.needAmount[i] || outIdx > vrb.allOutputTokens.length) {
                uint price = WrapProtocol(strgy.protocol[step]).getPrice(strgy.inputTokens[step][i],strgy.initToken);
                inAmount[inIdx] = vrb.initAmount * strgy.inputPercent[step][i] / strgy.percentBase * 10 ** IERC20Extra(strgy.inputTokens[step][i]).decimals() / price;
                inIdx += 1;
            }
        }

        // execute the method
        uint256 beforeBalance1 = 0;
        if (minfo.needInvest[0]) {
               beforeBalance1 = _getBalance(strgy.inputTokens[step][0]);
            }
            else if (minfo.needAmount[0]) {
                beforeBalance1 = _getBalance(strgy.outputTokens[step][0]);
            }

        if (minfo.inputParams == 1) {
             bytes memory callData = abi.encodeWithSignature(strgy.methods[step],strgy.inputTokens[step][0],inAmount[0]);

            (bool res,bytes memory returnData) = strgy.protocol[step].delegatecall(callData);
            require(res,string(returnData));

        // verify the transaction result
        if (minfo.needInvest[0]) {
                require(beforeBalance1 != _getBalance(strgy.inputTokens[step][0]), _failMsg(minfo.method) );
            }
            else if(minfo.needAmount[0]){
                // only verify first output token balance if there are two output tokens
                require(beforeBalance1 != _getBalance(strgy.outputTokens[step][0]), _failMsg(minfo.method) );
            }
        }

        if (minfo.inputParams == 2) {
            uint256 beforeBalance2 = 0;
            if(minfo.needInvest[1]){
               beforeBalance2 = _getBalance(strgy.inputTokens[step][1]);
            }
            else if(minfo.needAmount[1]){
                beforeBalance2 = _getBalance(strgy.outputTokens[step][1]);
            }

            bytes memory callData;
            uint needAmount = 0;
            for(uint i = 0; i< minfo.needAmount.length;i++){
                if(minfo.needAmount[i]){
                    needAmount += 1;
                }
            }
 
            if(needAmount == 1){
                callData =  abi.encodeWithSignature(
                strgy.methods[step],
                strgy.inputTokens[step][0],
                strgy.inputTokens[step][1],
                inAmount[0]);
            }
            else if(needAmount == 2){
                callData =  abi.encodeWithSignature(
                strgy.methods[step],
                strgy.inputTokens[step][0],
                strgy.inputTokens[step][1],
                inAmount[0],
                inAmount[1]);
            }

            (bool res,bytes memory returnData) = strgy.protocol[step].delegatecall(callData);
            require(res,string(returnData));
            // verify the transaction result
            if(minfo.needInvest[0]){
                require(beforeBalance1 != _getBalance(strgy.inputTokens[step][0]), _failMsg(minfo.method) );
            }
            if(minfo.needInvest[1]){
                require(beforeBalance2 != _getBalance(strgy.inputTokens[step][1]), _failMsg(minfo.method) );
            }
            if(minfo.needAmount[0]){
                require(beforeBalance1 != _getBalance(strgy.outputTokens[step][0]), _failMsg(minfo.method) );
            }
            if(minfo.needAmount[1]){
                require(beforeBalance2 != _getBalance(strgy.outputTokens[step][1]), _failMsg(minfo.method) );
            }
        }
       
       // record the transaction output
       for(uint r = 0; r < strgy.outputTokens[step].length;r++) {
           if(strgy.outputTokens[step][r] == address(0)){
               continue;
            }
            uint outIdx = _getIndex(strgy.outputTokens[step][r],vrb.allOutputTokens);
            vrb.outputAmount[outIdx] = _getBalance(strgy.outputTokens[step][r]) - vrb.oldOutputBalance[outIdx];
        }
          
        return (strgy,vrb);

    }

    function _getIndex(address token, address[] memory tokens) internal pure returns(uint256) {
        // initialize a index which is not exist in the tokens.
        uint256 index = tokens.length+1;
        for(uint256 i = 0; i < tokens.length;i++){
            if(token == tokens[i]) {
                index = i;
                break;
            }
        }
        return index;
    }

   function _getBalance(address token) internal view returns (uint256) {
        if(token == address(0)){
            return 0;
        }
        // ETH case
        if (token == 0x0000000000000000000000000000000000001010) {
            return address(this).balance;
        }
        // ERC20 token case
        return IERC20(token).balanceOf(address(this));
    }
  
    function getSettleAsset() public view returns(address) {
        PcvInfo memory pcvinfo = IPcvStorage(_pcvStorage).getPcvInfo(address(this));
        return pcvinfo.settleAsset;
    }

    function _canUseFund() internal view returns(bool) {
        address ctr = IPcvStorage(_pcvStorage).getComtroller();
        return Comptroller(ctr).canUsePcvFund(address(this));
    }

    function _failMsg(string memory method) internal pure returns(string memory) {
        return string(abi.encodePacked("execute ", method," fail"));
    }

    function _isMatic(address token) public pure returns(bool){
        bool isMatic =  (token == 0x0000000000000000000000000000000000001010);
        return isMatic;
    }

    // wmatic address
    function _wmatic() internal view returns(address){
        return IPcvStorage(_pcvStorage).getWMatic();
    }
}