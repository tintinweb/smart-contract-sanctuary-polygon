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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
            uint _initTokenBalance = _getBalance(strgy.initToken);

            if(_initTokenBalance < initAmount){
                vrb.oldOutputBalance[initIdx] = _initTokenBalance;
            } else {
                vrb.oldOutputBalance[initIdx] = _initTokenBalance - initAmount;
            }
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
        if (token == 0x0000000000000000000000000000000000001010 ||
            token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
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
        address ctr = IPcvStorage(_pcvStorage).comptroller();
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

interface IWMATIC {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
    function decimals() external view returns(uint8);
}

// settlement contract
interface Settlement{
    // params (PCV Address, total shares) 
    // return netWorth.decimals = 18
    function netAssetValue(address pcv) external view returns (uint netAssets, uint totalDebt, uint netWorth);
}

contract PcvProxy is PcvStruct, IERC20Extra{
    address public _pcvStorage;
    constructor(address pcvStorage){
        _pcvStorage = pcvStorage;
    }

    event executeEvent(uint256 strategyId, uint256 amount);
    event InvestEvent(address indexed storageContract,address indexed pcv,uint InvestAmount,uint pcvShares);
    event RedeemEvent(address indexed storageContract,address indexed pcv,uint redeemAmount,uint pcvShares);

    function addStrategy(
        address[] memory protocols,
        string [] memory methods ,
        address[][] memory inputTokens,
        address[][] memory outputTokens,
        uint256[][] memory inputPercent,
        bool closePosition
    ) external onlyPcvOwner{
        
        require(protocols.length == methods.length,_paramError("parameters length"));
        for(uint i = 0;i<protocols.length;i++){
            require(protocols[i] != address(0),_paramError("protocol"));
            for(uint j = 0;j < inputTokens[i].length;j++){
                require(inputTokens[i][j] != address(0),_paramError("input token"));
            }
        }

        lg_addStrategy(
        protocols,
        methods ,
        inputTokens,
        outputTokens,
        inputPercent,
        closePosition);

        _recordAssets(outputTokens);
        
    }

    function lg_addStrategy(
        address[] memory protocols,
        string [] memory methods ,
        address[][] memory inputTokens,
        address[][] memory outputTokens,
        uint256[][] memory inputPercent,
        bool closePosition) internal {

        // verify method
        ProtocolMethodInfo memory minfo;
        uint percentBase =  IPcvStorage(_pcvStorage).getPercentBase();
        address initToken =  getSettleAsset();

        bool[][] memory needAmount = new bool[][](inputTokens.length);
        bool[][] memory needInvest = new bool[][](inputTokens.length);
        for(uint m = 0; m < methods.length; m++){
            minfo = IPcvStorage(_pcvStorage).getMetodInfo(protocols[m],abi.encodeWithSignature(methods[m]));
            needAmount[m] = minfo.needAmount;
            needInvest[m] = minfo.needInvest;
            require(minfo.available,"operation is not support");
            require(minfo.inputParams == inputTokens[m].length,"input tokens is incorrect ");
            require(minfo.outputParams == outputTokens[m].length,"output tokens is incorrect ");
            require(needAmount[m].length == inputPercent[m].length,"inputPercent is incorrect");
           
            bool hasInvest = false; 
            uint hasMatic = 0;

            // check the white list of token
            _checkToken(protocols,inputTokens,outputTokens);

            for(uint p = 0; p < inputPercent[m].length;p++){
                require(percentBase * 20 >= inputPercent[m][p],"inputPercent is out of range");
                if((inputTokens[m][p] == initToken) && needInvest[m][p] ){
                    hasInvest = true;
                }

                if(_isMatic(inputTokens[m][p])){
                    hasMatic ++;
                }
            }
        }

        IPcvStorage(_pcvStorage).addStrategy(
            protocols,
            methods,
            inputTokens,
            outputTokens,
            initToken,
            inputPercent,
            closePosition);
    }

    function _checkToken(address [] memory protocols,address [][] memory inTokens,address [][] memory outTokens) public view {
        for(uint p = 0 ; p < protocols.length;p++){
            for(uint i = 0; i< inTokens[p].length;i++){      
                require(IPcvStorage(_pcvStorage).isSupportAsset(protocols[p],inTokens[p][i]),string(abi.encodePacked("protocol:",protocols[p]," not support token:",inTokens[p][i])));
            }

            for(uint out = 0; out < outTokens[p].length;out++){
                require(IPcvStorage(_pcvStorage).isSupportAsset(protocols[p],outTokens[p][out]),string(abi.encodePacked("protocol:",protocols[p]," not support token:",outTokens[p][out])));
            }
        }
    }

    function executor() internal view returns(address){
         address lg = IPcvStorage(_pcvStorage).getLogic();
         require(lg != address(0),"no logic executor");
         return lg;
    }

    function removeStrategy(uint256 strategyId) external onlyPcvOwner{
        IPcvStorage(_pcvStorage).removeStrategy(strategyId);
    }

    modifier pcvAvailable(){
        PcvInfo memory info = IPcvStorage(_pcvStorage).getPcvInfo(address(this));
        require(info.available,"PCV unavailable");
        _;
    }

    modifier onlyPcvOwner(){
        bool hasPcv = IPcvStorage(_pcvStorage).pcvIsExsit(msg.sender,address(this));
        require(hasPcv,"caller is not PCV owner");
        _;
    }

    function getPcvStorage() external view returns(address){
        return _pcvStorage;
    }

    function isSupportOperate(address protocol,bytes memory method) public view returns(bool){
        return  IPcvStorage(_pcvStorage).isSupportOperate(protocol,method);
    }

    function stringToBytes32(string memory source) pure external returns(bytes32 result){
        assembly{
            result := mload(add(source,32))
        }
    }

    // PCV Owner execute strategy (for close)
    function execute(
        uint256 strategyId,
        uint256 initAmount) public onlyPcvOwner{

        address lg = executor();
        bytes memory callData = abi.encodeWithSignature("lg_execute(uint256,uint256)",strategyId,initAmount);
        (bool res ,bytes memory returnData)  = lg.delegatecall(callData);
        require(res,string(returnData));
    }

    function _execute(
        uint256 strategyId,
        uint256 initAmount) internal pcvAvailable{
        // execute strategy when invest
        bytes memory callData = abi.encodeWithSignature("lg_execute(uint256,uint256)",strategyId,initAmount);
        address lg = executor();
        (bool res ,bytes memory returnData)  = lg.delegatecall(callData);
        require(res,string(returnData));
    }

    function invest(uint256 amount) external payable{

        require(amount >0,"amount error");
        PcvInfo memory info = IPcvStorage(_pcvStorage).getPcvInfo(address(this));
        require(amount <= info.maxInvest && amount >= info.minInvest,"Investment exceeds the limit");
        address settleAsset = info.settleAsset;
        bool ismatic = _isMatic(settleAsset);
        if(ismatic){
            IWMATIC(payable(_wmatic())).deposit{value:amount}();
            settleAsset = _wmatic();
        }else{
             bool transRes = IERC20(settleAsset).transferFrom(msg.sender,address(this), amount);
             require(transRes,"ERC20 token Transfer failed");
        }

        // fetch pcvToken value, calculate how many pcvToken can be exchanged
        (,, uint netWorth) = Settlement(_settlement()).netAssetValue(address(this));

        // mint pcvToken
        uint8 decimal = IERC20Extra(settleAsset).decimals();
        
        uint8 decimalDiff = pcvShareDecimals() - decimal;
        uint shares = amount * 10 ** (decimalDiff + pcvShareDecimals()) / netWorth;
        _mint(msg.sender,shares);

        // execute auto strategy
        if(IPcvStorage(_pcvStorage).autoExecute(address(this))){
            uint strgyId =  IPcvStorage(_pcvStorage).getAutoStrategy(address(this));
            require(strgyId > 0 , "no strategy to execute");
            PcvStrategy memory strgy = IPcvStorage(_pcvStorage).getStrategy(address(this),strgyId);
            require(strgy.available,"strategy is not available");
            _execute(strgyId,amount);
            emit executeEvent(strgyId,amount);
        }
        emit InvestEvent(_pcvStorage,address(this),amount,shares);
    }

    function redeem(uint256 amount) external payable{
        uint256 balance = balanceOf(msg.sender);
        require(balance >= amount,"not enough balance to redeem");
        address settleAsset = getSettleAsset();

        (,, uint netWorth) = Settlement(IPcvStorage(_pcvStorage).settlement()).netAssetValue(address(this));

        uint8 decimal = pcvShareDecimals() + networthDecimals() - IERC20Extra(settleAsset).decimals();
        uint256 redeemAmount = amount * netWorth / 10 ** (decimal);

        // 自动平仓
         if(IPcvStorage(_pcvStorage).autoClose(address(this))){
            uint strgyId =  IPcvStorage(_pcvStorage).autoClosePosition(address(this));
            require(strgyId > 0 , "no strategy to close position");
            PcvStrategy memory strgy = IPcvStorage(_pcvStorage).getStrategy(address(this),strgyId);
            require(strgy.available,"strategy is not available");
            _execute(strgyId,redeemAmount);
            emit executeEvent(strgyId,amount);
        }

        uint256 pcvBalance = IERC20(settleAsset).balanceOf(address(this));
        require(pcvBalance >= redeemAmount,"PCV has not enough asset to do redeem");

        _burn(msg.sender,amount);
        if(_isMatic(settleAsset)){
            IWMATIC(settleAsset).withdraw(redeemAmount);
            payable(msg.sender).transfer(redeemAmount);
        }else{
            IERC20(settleAsset).transfer(msg.sender, redeemAmount);
        }
        emit RedeemEvent(_pcvStorage,address(this),redeemAmount,amount);
    }

    function setStorage( address stoContract) external onlyPcvOwner {
        _pcvStorage = stoContract;
    }
    
    function getSettleAsset() public view returns(address){
        PcvInfo memory pcvinfo = IPcvStorage(_pcvStorage).getPcvInfo(address(this));
        return pcvinfo.settleAsset;
    }

    function setAutoStrategy(uint strategyId) external onlyPcvOwner{
        PcvStrategy memory strgy =  IPcvStorage(_pcvStorage).getStrategy(address(this),strategyId);
        require(!strgy.closePosition,"Close position strategy");
        IPcvStorage(_pcvStorage).setAutoStrategy(strategyId);
    }

    function setAutoExecute(bool open) external onlyPcvOwner{
        IPcvStorage(_pcvStorage).setAutoExecute(open);
    }

    // 设置平仓策略
    function setAutoClosePosition(uint strategyId) external onlyPcvOwner{
        PcvStrategy memory strgy =  IPcvStorage(_pcvStorage).getStrategy(address(this),strategyId);
        require(strgy.closePosition,"Not Close position strategy");
        IPcvStorage(_pcvStorage).setAutoClosePosition(strategyId);
    }

    // 自动平仓开关
    function openClosePosition(bool open) external onlyPcvOwner{
        IPcvStorage(_pcvStorage).openClosePosition(open);
    }

    // === about ERC20 token ===

    function decimals() public view override returns (uint8) {
        return IPcvStorage(_pcvStorage).decimals();
    }

    function totalSupply() public view override returns (uint256) {
        return IPcvStorage(_pcvStorage).totalSupply();
    }

    function symbol() public view returns (string memory) {
        return IPcvStorage(_pcvStorage).symbol();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return IPcvStorage(_pcvStorage).balanceOf(account);
    }

    function name() public view returns (string memory) {
        return IPcvStorage(_pcvStorage).name();
    }

    function _mint(address account, uint256 amount) internal {
        IPcvStorage(_pcvStorage).mint(account,amount);
        emit Transfer(address(0),account,amount);
    }

    function _burn(address account, uint256 amount) internal {
        IPcvStorage(_pcvStorage).burn(account,amount);
        emit Transfer(account,address(0),amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        IPcvStorage(_pcvStorage).tokenSub(recipient,amount);
        IPcvStorage(_pcvStorage).tokenAdd(sender,amount);
        emit Transfer(sender, recipient, amount);
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return IPcvStorage(_pcvStorage).allowance(address(this),owner,spender);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        IPcvStorage(_pcvStorage).approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        IPcvStorage(_pcvStorage).approveSub(sender, msg.sender, amount);
        return true;
    }

    // about token end ===

    function assetCollection(address[] memory assets) external onlyPcvOwner{
        address collectAccount = IPcvStorage(_pcvStorage).getCollectAccount(address(this));
        for(uint i = 0 ; i< assets.length;i++){
            if(assets[i] == 0x0000000000000000000000000000000000001010){
                payable(collectAccount).transfer(address(this).balance);
            }else{
                IERC20(assets[i]).transfer(collectAccount,IERC20(assets[i]).balanceOf(address(this)));
            }

        }
    }

    function _isMatic(address token) internal pure returns(bool){
        bool isMatic = (token == 0x0000000000000000000000000000000000001010 ||
         token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE );
        return isMatic;
    }

    function _paramError(string memory param) internal pure returns(string memory ){
        return string(abi.encodePacked("parameters error: ", param));
    }

    function _wmatic() internal view returns(address){
        return IPcvStorage(_pcvStorage).getWMatic();
    }

    function _settlement() internal returns(address){
        return IPcvStorage(_pcvStorage).settlement();
    }

    function _recordAssets(address [][] memory outputTokens) internal {
        uint allOutTokens = 0;
        for(uint s = 0; s < outputTokens.length;s++){
            allOutTokens += outputTokens[s].length;
        }

        address [] memory newOutTokens = new address[](allOutTokens);
        uint idx = 0;
        for(uint step = 0; step < outputTokens.length;step++){
            for(uint out = 0;out < outputTokens[step].length;out++){
            newOutTokens[idx] = (outputTokens[step][out]);
            idx++;
            }
        }
        IPcvStorage(_pcvStorage).recordPcvAssets(newOutTokens);
    }

    function setInvestLimit(uint minInvest,uint maxInvest) external onlyPcvOwner{
        require(minInvest <= maxInvest,"data error");
        IPcvStorage(_pcvStorage).setInvestLimit(minInvest,maxInvest);
    }

    // liquidate preprocess
    function preLiquidate(address token,uint amount) external returns(bool res){
        require(msg.sender == IPcvStorage(_pcvStorage).liquidator(),"caller is not liquidator");
       res = IERC20(token).approve(msg.sender,amount);
    }

    function pcvShareDecimals() private pure returns(uint8){
            return 18;
    }

    function networthDecimals() private pure returns(uint8){
            return 18;
    }

}



contract PcvFactory is Ownable{
    address public pcvStorage;

    constructor(address storageContract){
        pcvStorage = storageContract;
    }

   // build a new PcvProxy
    function buildPcvProxy(address pcvOwner,address settleAsset,uint256 minInvest,uint256 maxInvest) external returns(address){
        require(minInvest <= maxInvest," minInvest and maxInvest error");
        require(pcvOwner != address(0) && settleAsset != address(0),"pcvOwner and settleAsset error");
        address pcv = address(new PcvProxy(pcvStorage));
        _storePcv(pcvOwner,pcv,settleAsset,minInvest,maxInvest);
        emit buildPCVproxy(pcvOwner,pcv);
        return pcv;
    }
    event buildPCVproxy(address indexed pcvOwner,address indexed pcv);

    function _storePcv(address pcvOwner,address pcv,address settleAsset,uint256 minInvest,uint256 maxInvest) internal {
       IPcvStorage(pcvStorage).addPcv(pcvOwner,pcv,settleAsset,minInvest,maxInvest);
    }

    function setStore(address _pcvStorage) external onlyOwner {
        address oldStore = pcvStorage;
        pcvStorage = _pcvStorage;
        emit _setStore(oldStore,_pcvStorage);
    }
    event _setStore(address,address);
}