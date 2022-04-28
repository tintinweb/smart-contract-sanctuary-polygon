/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract PcvStorage is Ownable, PcvStruct{

    address private constant MATIC_TOKEN = 0x0000000000000000000000000000000000001010;

    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    address  public constant ETHER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public pcvFactory;

    address public settlement;  // settlement contract
    address public comptroller;  // comptroller contract

    // pcv => PcvInfo
    mapping (address => PcvInfo) public pcvMap;
    //pcvOwner => (pcv => isExist)
    mapping (address => mapping (address => bool))  userPcvMap;

    // pcv => ( strategyId => Strategy )
    mapping (address => mapping (uint256 => PcvStrategy)) pcvStrategyMap;
    // pcv => (strategyCount)
    mapping (address => uint256) strategyCountMap;

    // protocol => (method => methodDetail)
    mapping (address => mapping (bytes => ProtocolMethodInfo)) supportOperateMap;

    uint _percentBase = 100;

    // === pcv token start ===

    uint8 _decimals = 18;
    // pcv => (account => balance)
    mapping (address => mapping (address => uint256)) _balances;
    // pcv => totalSupply
    mapping (address => uint256) _totalSupply;
    string _symbol = "DP-PCV";
    string _name = "DP-PCV TOKEN";

    // pcv => (owner => (spender => allowanceAmount) )
    mapping (address => mapping (address => mapping (address => uint256) ) )  _allowances;
    // === pcv token end ===

    mapping (address => bool) public autoExecute;
    mapping(address => bool) public autoClose; // whether auto close the pcv
    // pcv => strategyId
    mapping (address => uint256) _autoExecuteStrategy;
    mapping(address => uint) public autoClosePosition; // close pcv strategy

    // protocol => assetsAddress
    mapping(address => address[]) protocolAssets;

    // PCV Position (PCV address => position token address)
    mapping(address => address[]) _pcvAssets;
    mapping(address => mapping(address => bool)) _pcvAssetsMap;

    address public logicExecutor;
    address public liquidator;

    event addPcvEvent(address indexed storageContract,address indexed pcvOwner, address indexed pcv);
    event addStrategyEvent(address indexed storageContract ,address indexed pcv,uint strategyId);
    event removeStrategyEvent(address,uint256);
    event removeSupportOperateEvent(address ,address,bytes); // (owner,protocol,method)
    event setProxyFactoryEvent(address,address); // (oldAddress ,newAddress)
    event stopPCVevent(address);
    event Approval(address indexed pcv ,address indexed owner, address indexed spender, uint256 value);
    event autoExecuteEvent(bool oldValue,bool newValue);
    event setAutoStrategyEvent(uint256 oldStrategy,uint256 newStrategy);
    event setCollect(address oldAccount ,address newAccount);
    event setAutoCloseEvent(uint oldStrategy,uint strategyId);

    function addPcv(address pcvOwner,address pcv,address settleAsset,uint256 minInvest,uint256 maxInvest) external onlyFactory{
        PcvInfo memory newPcv = PcvInfo({
        factory:_msgSender(),
        owner:pcvOwner,
        available:true,
        collectAccount:address(0),
        settleAsset:settleAsset,
        minInvest:minInvest,
        maxInvest:maxInvest
        });
        pcvMap[pcv] = newPcv;
        userPcvMap[pcvOwner][pcv] = true;
        _pcvAssets[pcv].push(settleAsset);
        _pcvAssetsMap[pcv][settleAsset] = true;

        emit addPcvEvent(address(this),pcvOwner,pcv);
    }

    function addStrategy(
         address[] memory protocols,
        string[] memory methods,
        address[][] memory inputTokens,
        address[][] memory outputTokens,
        address initToken,
        uint[][] memory inputPercent,
        bool closePosition
    ) external onlyPcv {
        
        address pcv = _msgSender();

        (bool[][] memory needAmount,bool[][] memory needInvest) = getAmountAndInvest(protocols,methods);

        PcvStrategy memory strgy = PcvStrategy({
            strategyId:strategyCountMap[pcv]+1, // id create by store contract
            protocol:protocols,
            methods:methods,
            available:true,
            inputTokens:inputTokens,
            outputTokens:outputTokens,
            initToken:initToken,
            inputPercent:inputPercent,
            percentBase:_percentBase,
            needAmount:needAmount,// 
            needInvest:needInvest,
            closePosition:closePosition
        });

        pcvStrategyMap[pcv][strategyCountMap[pcv]+1] = strgy;

        if(strgy.strategyId == 1 && (!strgy.closePosition)){
            _autoExecuteStrategy[pcv] = 1;
            autoExecute[pcv] = true;
        }
        strategyCountMap[pcv] = strategyCountMap[pcv]+1;

        emit addStrategyEvent(address(this),pcv,strategyCountMap[pcv]);
    }


    function getAmountAndInvest(address [] memory protocols , string [] memory methods) internal view returns(bool[][] memory , bool[][] memory){
        bool[][] memory needAmount = new bool[][](methods.length);
        bool[][] memory needInvest = new bool[][](methods.length);
        ProtocolMethodInfo memory minfo;
        address protocol;
        bytes memory methodAbi;
        for(uint i = 0; i < methods.length;i++){
            protocol = protocols[i];
            methodAbi = abi.encodeWithSignature(methods[i]);
            minfo = supportOperateMap[protocol][methodAbi];
            needAmount[i] = minfo.needAmount;
            needInvest[i] = minfo.needInvest;
        }

        return (needAmount,needInvest);
    }

    function getParamsNeed(address protocol,bytes memory methodAbi) internal view  returns(bool[] memory amount ,bool[] memory invest) {
        ProtocolMethodInfo memory mInfo = supportOperateMap[protocol][methodAbi];
        return (mInfo.needAmount,mInfo.needInvest);
    }

    function removeStrategy(uint256 stragegyId) external onlyPcv{
        delete pcvStrategyMap[_msgSender()][stragegyId];
        emit removeStrategyEvent(_msgSender(),stragegyId);
    }

    function getPcvInfo(address pcv) external view returns(PcvInfo memory){
        return  pcvMap[pcv];
    }

    function getPcvInfoByPcv(address pcv) public view returns(
        address pcvOwner,
        address settleAsset,
        bool available,
        uint256 minInvest,
        uint256 maxInvest){
        PcvInfo memory info = pcvMap[pcv];
        pcvOwner = info.owner;
        settleAsset = info.settleAsset;
        available = info.available;
        minInvest = info.minInvest;
        maxInvest = info.maxInvest;
        return  ( pcvOwner,settleAsset,available,minInvest,maxInvest);
    }

    function getStrategy(address pcv,uint256 id) external view returns(PcvStrategy memory){
        return pcvStrategyMap[pcv][id];
    }

    function isSupportOperate(address protocol,bytes memory method) external view returns(bool){
        ProtocolMethodInfo memory info = supportOperateMap[protocol][method];
        return info.available;
    }

    function addSupportOperate(
        address protocol,
        string[] memory methods,
        uint[] memory inputParams,
        uint[] memory outputParams,
        bool[][] memory needAmount,
        bool[][] memory needInvest) external onlyOwner{
        uint mLength = methods.length;
        require(mLength > 0 , "No input parameters");
        require(protocol != address(0),"Protocol error");
        require(mLength == inputParams.length && mLength == outputParams.length,"The length error");

        for(uint i = 0 ; i < mLength;i++){
            bytes memory methodAbi = abi.encodeWithSignature(methods[i]);
            require(methodAbi.length > 0,"Method error");
            require(needAmount[i].length == inputParams[i]," The length of input  error");
            require(needInvest[i].length == inputParams[i]," The length Of needInvest error");

            ProtocolMethodInfo memory mInfo = ProtocolMethodInfo({
            method:methods[i],
            abiCode:methodAbi,
            inputParams:inputParams[i],
            outputParams:outputParams[i],
            available:true,
            needAmount:needAmount[i],
            needInvest:needInvest[i]
            });
            supportOperateMap[protocol][methodAbi] = mInfo;
        }
    }

    function removeSupportOperate(address protocol,bytes memory method) external onlyOwner{
        delete supportOperateMap[protocol][method];
        emit removeSupportOperateEvent(_msgSender(),protocol,method);
    }

    function setProxyFactory(address newPcvFactory)external onlyOwner{
        require(newPcvFactory != address(0),"parameters error");
        address oldAddress = pcvFactory;
        pcvFactory = newPcvFactory;
        emit setProxyFactoryEvent(oldAddress,newPcvFactory);
    }


    modifier onlyFactory(){
        require(_msgSender() == pcvFactory,"no permissions");
        _;
    }

    modifier onlyPcv(){
        address pcv = _msgSender();
        PcvInfo memory info =  pcvMap[pcv];
        require(info.available == true,"no permissions");
        _;
    }

    function stopPCV(address pcv) external {
        PcvInfo memory info = pcvMap[pcv];
        require(info.owner == _msgSender(),"no permissions ");
        info.available = false;
        userPcvMap[_msgSender()][pcv] = false;
        emit stopPCVevent(pcv);
    }

    function getMetodInfo(address protocol,bytes memory methodAbi) public view returns(ProtocolMethodInfo memory){
        return supportOperateMap[protocol][methodAbi];
    }

    function getMaticToken() external pure returns(address){
        return MATIC_TOKEN;
    }

    function getWMatic() external pure returns(address){
        return WMATIC;
    }

    function pcvIsExsit(address owner,address pcv) external view returns(bool){
        return userPcvMap[owner][pcv];
    }

    function pcvIsExsit(address pcv) external view returns(bool){
        PcvInfo memory info = pcvMap[pcv];
        return info.available;
    }

    function getEther() external pure returns(address){
        return ETHER;
    }

    // =================== pcv token start

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply[_msgSender()];
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[_msgSender()][account];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function mint(address account, uint256 amount) external onlyPcv{
        _balances[_msgSender()][account] = _balances[_msgSender()][account] + amount;
        _totalSupply[_msgSender()] += amount; 
    }

    function burn(address account, uint256 amount) external onlyPcv{
        require(_balances[_msgSender()][account] >= amount,"not enough balance to burn");
        _balances[_msgSender()][account] = _balances[_msgSender()][account] - amount;
        _totalSupply[_msgSender()] -= amount; 

    }

    function tokenAdd(address account, uint256 amount)  external onlyPcv{
        _balances[_msgSender()][account] = _balances[_msgSender()][account] + amount;
    }
    
    function tokenSub(address account, uint256 amount) external onlyPcv{
        require(_balances[_msgSender()][account] >= amount,"not enough balance to burn");
        _balances[_msgSender()][account] = _balances[_msgSender()][account] - amount;

    }

    function allowance(address pcv,address owner, address spender) public view returns (uint256) {
        return _allowances[pcv][owner][spender];
    }

    function approve(address owner,address spender, uint256 amount) public onlyPcv returns (bool) {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_msgSender()][owner][spender] = amount;
        emit Approval(_msgSender(),owner, spender, amount);
        return true;
    }

    function approveSub(address owner, address spender, uint256 amount) external onlyPcv{
         uint256 allowances =  allowance(address(this),owner,spender);
        require(allowances <= amount,"ERC20: transfer amount exceeds allowance");
        _allowances[_msgSender()][owner][spender] = _allowances[_msgSender()][owner][spender] - amount;
    }

    // =================== pcv token end

    function setAutoExecute(bool isAuto) external onlyPcv{
            require(isAuto != autoExecute[_msgSender()],"value already exist");
            bool oldVal = autoExecute[_msgSender()];
            autoExecute[_msgSender()] = isAuto;
            emit autoExecuteEvent(oldVal,isAuto);
    }

    function setAutoStrategy(uint strategyId) external onlyPcv{
            PcvStrategy memory strgy =  pcvStrategyMap[_msgSender()][strategyId];
            require(strgy.available, " strategy is not exsit or not available");
            uint256 oldStrategy = _autoExecuteStrategy[_msgSender()];
            _autoExecuteStrategy[_msgSender()] = strategyId;
             autoExecute[_msgSender()] = true;
            emit setAutoStrategyEvent(oldStrategy,strategyId);
    }

    function getAutoStrategy(address pcv) external view returns(uint) {
        return _autoExecuteStrategy[pcv];
    }

    // collecte pcv funds

    function setCollectAccount(address pcv,address collecAccount) external onlyOwner{
        require(pcvMap[pcv].available,"PCV is not available");
        emit setCollect(pcvMap[pcv].collectAccount,collecAccount);
        pcvMap[pcv].collectAccount = collecAccount;
    }

    function getCollectAccount(address PCV) external view returns(address){
        PcvInfo memory info = pcvMap[PCV];
        return info.collectAccount;
    }

    // Execute the strategy input, using the ratio of the previously set transaction results
    function setPercentBase(uint256 percentBase) external onlyOwner{
        _percentBase = percentBase;
    }
    function getPercentBase() public view returns(uint256){
        return _percentBase;
    }

    // set the whitelist of the protocol token
    function setSupportAssets(address protocol,address [] memory tokens) public { 
        for(uint i = 0 ; i< tokens.length;i++){
            if(isSupportAsset(protocol,tokens[i])){
                continue;
            }
         protocolAssets[protocol].push(tokens[i]);
        }
    }

    function isSupportAsset(address protocol,address token) public view returns(bool){
        if(protocolAssets[protocol].length == 0){
            return false;
        }
        address [] memory assets = protocolAssets[protocol];
        uint len = protocolAssets[protocol].length;
        for(uint i ; i < len; i++){
            if(assets[i] == token){
                return true;
            }
        }
        return false;
    }

    function getSupportAssets(address pro) public view returns(address[] memory){
        return protocolAssets[pro];
    }

    // set the contract address of the settlement contract
    function setSettlement(address settleContract) external{
        settlement = settleContract;
    }

    // get PCV position assets
    function getPcvAssets(address pcv) public view returns(address [] memory assets){
        assets = _pcvAssets[pcv];
        return assets;
    }

    // record PCV position assets
    function recordPcvAssets(address [] memory newAssets) external onlyPcv{
       address pcv = _msgSender();
       for(uint n = 0; n < newAssets.length;n++){
                if(_pcvAssetsMap[pcv][newAssets[n]]){
                    continue;
                }
                _pcvAssetsMap[pcv][newAssets[n]] = true;
                _pcvAssets[pcv].push(newAssets[n]);
       }
    }

    function setComtroller(address _comptroller) external {
        comptroller = _comptroller;
    }

    function setLogic(address logic) external {
        logicExecutor = logic;
    }

    function getLogic() external view returns(address){
        return logicExecutor;
    }

    function lastStrategyId(address pcv) external view returns(uint){
        return strategyCountMap[pcv];
    }

    function setInvestLimit(uint minInvest,uint maxInvest) external onlyPcv{
        address pcv = _msgSender();
        pcvMap[pcv].minInvest = minInvest;
        pcvMap[pcv].maxInvest = maxInvest;
    }

    function setLiquidator(address newLiquidator) external  onlyOwner {
        liquidator = newLiquidator;
    }

    function setAutoClosePosition(uint strategyId) external onlyPcv{
         PcvStrategy memory strgy =  pcvStrategyMap[_msgSender()][strategyId];
            require(strgy.available, " Invalid strategy");
            uint256 oldStrategy = _autoExecuteStrategy[_msgSender()];
             autoClosePosition[_msgSender()] = strategyId;
             autoClose[_msgSender()] = true;
            emit setAutoCloseEvent(oldStrategy,strategyId);
    }

    function openClosePosition(bool open) external onlyPcv{
         autoClose[_msgSender()] = open;
    }

}