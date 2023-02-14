// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IERC20 {

    function totalSupply() external view returns(uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns(uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns(bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns(uint256);

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
    function approve(address spender, uint256 amount) external returns(bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


}


abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns(uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


interface IUniswapV2Router02 {

    function WETH() external pure returns(address);
    function WBNB() external pure returns(address);
    function WAVAX() external pure returns(address);
    function WFTM() external pure returns(address);
    function WMATIC() external pure returns(address);
    function WCRO() external pure returns(address);
    function WONE() external pure returns(address);
    function WMADA() external pure returns(address); // this code was changed to support specific chains
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;    
}



contract feeDeposit is Ownable {
 
    //address public router;
    uint256 public totalNativeFromAllDapps;
    uint256 public totalNativeRecievedFromTokenSell;
    uint256 public finalizedPayment;
    uint256 public dappNumLimit = 100;
    mapping(address => bool) public whitelisted;
    mapping(uint256 => uint256) public timeStampCount;
    mapping(uint256 => address) public chainIDToRouter;
    mapping(address => uint256) public nativeReceivedFromEachToken;
    mapping(uint256 => uint256) public nativeTokenReceivedTotal;
    mapping (address => bool) public routerValid;
    mapping(uint256 => mapping(uint256 => uint256)) public nativeTokenReceivedEach;
    mapping(uint256 => mapping(uint256 => uint256)) public nativeTokenReceivedCumulative;
    mapping(uint256 => mapping(uint256 => uint256)) public timestampMAP;
    mapping(uint256 => mapping(address => uint256)) public senderMAP;

    constructor() {

        //router = _router;
        chainIDToRouter[1] = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // uniswap - ethereum
        chainIDToRouter[56] = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // pancake - binance
        chainIDToRouter[137] = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // quickswap - polygon
        chainIDToRouter[100] = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // sushiswap - gnosis
        chainIDToRouter[43114] = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4; // traderJoe - AVAX
        chainIDToRouter[250] = 0x31F63A33141fFee63D4B26755430a390ACdD8a4d; // Spookyswap - FTM
        chainIDToRouter[1666600000] = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // sushiswap - Harmony
        chainIDToRouter[42220] = 0x1421bDe4B10e8dd459b3BCb598810B1337D56842; // sushiswap - celo
        chainIDToRouter[321] = 0xc0fFee0000C824D24E0F280f1e4D21152625742b; // KoffeeSwap - KCC
        chainIDToRouter[128] = 0xED7d5F38C79115ca12fe6C0041abb22F0A06C300; // MDEX - HECO
        chainIDToRouter[42161] = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; // uniswap - Arbitrum
        chainIDToRouter[25] = 0x145677FC4d9b8F19B5D56d1820c48e0443049a30; // MMF - CRO
        chainIDToRouter[66] = 0x069A306A638ac9d3a68a6BD8BE898774C073DCb3; // JSWAP - OKT
        chainIDToRouter[10000] = 0x5d0bF8d8c8b054080E2131D8b260a5c6959411B8; // MistSwap - smartBCH
        chainIDToRouter[1285] = 0xAA30eF758139ae4a7f798112902Bf6d65612045f; // SolarBeam - Moonriver
        chainIDToRouter[2001] = 0x9D2E30C2FB648BeE307EDBaFDb461b09DF79516C; // Milkyswap - Milkomeda
        routerValid[chainIDToRouter[block.chainid]] = true;


    }
    mapping(uint256 => uint256) public burntMap;

    // router addresses

   // chainIDToRouter['56'] = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // pancake
    uint256 public burnCount;

/*
// _dappNum meaning in payment function //
    0 --> fees from regular presale with referral
    1 --> fees from regular presale without referral
    2 --> fees for whitelist function in regular presale
    3 --> fees from Fair presale with referral
    4 --> fees from Fair presale without referral
    5 --> fees for whitelist function in Fair presale



    11 --> standard token lock using DxLock and referral
    12 --> standard token lock using DxLock and NO referral
    13 --> LP lock usng DxLock and referral
    14 --> Lp Lock without referral and NO referral
    15 --> reward token lock using DxLock and referral
    16 --> reward token lock using DxLock and NO referral
*/
    function payment(uint256 _dappNum) public payable {
        require(_dappNum <= dappNumLimit,"invalid dapp num");
        nativeTokenReceivedEach[_dappNum][block.timestamp] = msg.value;
        nativeTokenReceivedTotal[_dappNum] = nativeTokenReceivedTotal[_dappNum] + msg.value;
        nativeTokenReceivedCumulative[_dappNum][block.timestamp] = nativeTokenReceivedTotal[_dappNum];
        timestampMAP[_dappNum][timeStampCount[_dappNum]] = block.timestamp;
        timeStampCount[_dappNum]++;
        totalNativeFromAllDapps = totalNativeFromAllDapps + msg.value;
    }


    function sellToken(address _tokenAddress, address _routerAddress, uint256 _tokenOut, uint256 slippage) public { //slippage value: 1 means 0.1%, 10 means 1%, 100 means 10%, 1000 means 100%
       
       require(routerValid[_routerAddress],"invalid router");
       require(msg.sender == tx.origin,"not original sender");
       require(whitelisted[msg.sender],"not whitelisted");
       require(_tokenOut > 0,"token out cannot be zero");

        IERC20(_tokenAddress).approve(address(_routerAddress), _tokenOut);

        uint256 amountInNative = getAmountsMinSlipToken(_routerAddress, _tokenAddress, _tokenOut, slippage);
    
        swapTokensForETH(_routerAddress, _tokenAddress, address(this), _tokenOut, amountInNative);
        totalNativeRecievedFromTokenSell = totalNativeRecievedFromTokenSell + amountInNative;    
        nativeReceivedFromEachToken[_tokenAddress] = nativeReceivedFromEachToken[_tokenAddress] + amountInNative;

    }
    
    function getWrapAddrRouterSpecific(address _router) public pure returns (address){
        try IUniswapV2Router02(_router).WETH() {
            return IUniswapV2Router02(_router).WETH();
        }
        catch (bytes memory) {
            return IUniswapV2Router02(_router).WBNB();
        }
    }

  

    function swapTokensForETH(
        address routerAddress,
        address tokenAddress,
        address recipient,
        uint256 tokenAmount,
        uint256 minAmountSlippage
    ) internal {
        IUniswapV2Router02 pancakeRouter = IUniswapV2Router02(routerAddress);

        // generate the pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(tokenAddress);
        //path[1] = pancakeRouter.WETH();
        path[1] = getWrapAddrRouterSpecific(routerAddress);
        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            minAmountSlippage, // accept any amount of mainnet token
            path,
            address(recipient),
            block.timestamp + 360
        );
    }



    function getAmountsMinToken(address _router, address _tokenAddress, uint256 _tokenIN) public view returns(uint256) {

        IUniswapV2Router02 pancakeRouter = IUniswapV2Router02(_router);
        // generate the pair path of token -> weth
        uint256[] memory amountMinArr;
        uint256 AmountMin;
        address[] memory path = new address[](2);
        path[0] = address(_tokenAddress);
        //path[1] = pancakeRouter.WETH();
        path[1] = getWrapAddrRouterSpecific(_router);
        amountMinArr = pancakeRouter.getAmountsOut(_tokenIN, path);
        AmountMin = uint256(amountMinArr[1]);

        return AmountMin;


    }
    
    
    function getAmountsMinTokenETH(address _router, address _tokenAddress, uint256 _tokenIN) public view returns(uint256) {

        IUniswapV2Router02 pancakeRouter = IUniswapV2Router02(_router);
        // generate the pair path of token -> weth
        uint256[] memory amountMinArr;
        uint256 AmountMin;
        address[] memory path = new address[](2);
        path[0] = address(_tokenAddress);
        //path[1] = pancakeRouter.WETH();
        path[1] = getWrapAddrRouterSpecific(_router);
        amountMinArr = pancakeRouter.getAmountsOut(_tokenIN, path);
        AmountMin = uint256(amountMinArr[0]);

        return AmountMin;


    }






    function getAmountsMinSlipToken(address _router, address _tokenAddress, uint256 tokenToSell, uint256 _slippage) public view returns(uint256) {

        uint256 _minAmount = getAmountsMinToken(_router, _tokenAddress, tokenToSell);
        uint256 _minAmountSlippage = _minAmount - (_minAmount * (_slippage) / (1000));

        return _minAmountSlippage;


    }

    function BlockTimestamp() public view returns(uint256) {


        return block.timestamp;


    }

    function withdrawETH(uint256 ethAmount) public payable onlyOwner {

        //payable(platform_wallet).transfer(ethAmount);
        Address.sendValue(payable(msg.sender),ethAmount);
    }


    function withdrawToken(address _tokenAddress, uint256 _Amount) public payable onlyOwner {

        IERC20(_tokenAddress).transfer(msg.sender, _Amount);

    }

    

    function updateDappNumLimit (uint256 _newLimit) onlyOwner public {
        
        
        dappNumLimit = _newLimit;
        
    }   

    
    
    function addToWhitelist (address _wallet) onlyOwner public {
        
        
        whitelisted[_wallet] = true;
        
    }
    
    function removeFromWhitelist (address _wallet) onlyOwner public {
        
        
        whitelisted[_wallet] = false;
        
    }  
    
    function addToRouter (address _routerToAdd) onlyOwner public {
        
        
        routerValid[_routerToAdd] = true;
        
    }
    
    function removeRouter (address _routerToDelete) onlyOwner public {
        
        
        routerValid[_routerToDelete] = false;
        
    }  

    

    

    function getNativeRecieveDataCumulative(uint256 _dappNum) public view returns(uint256[] memory, uint256[] memory){
        uint256 dappNum = _dappNum;
        uint256 timeStampCountCurrent = timeStampCount[dappNum];
        
         uint256[] memory nativeIn = new uint256[](timeStampCountCurrent);
         uint256[] memory timeStampRecord = new uint256[](timeStampCountCurrent); 
        for(uint256 i = 0; i < timeStampCountCurrent; i++){

            timeStampRecord[i] = timestampMAP[dappNum][i];
            nativeIn[i] = nativeTokenReceivedCumulative[dappNum][timestampMAP[dappNum][i]];

        }

        return(nativeIn,timeStampRecord);
    }

    function getNativeRecieveData(uint256 _dappNum) public view returns(uint256[] memory, uint256[] memory){
        uint256 dappNum = _dappNum;
        uint256 timeStampCountCurrent = timeStampCount[dappNum];
        
         uint256[] memory nativeIn = new uint256[](timeStampCountCurrent);
         uint256[] memory timeStampRecord = new uint256[](timeStampCountCurrent); 
        for(uint256 i = 0; i < timeStampCountCurrent; i++){

            timeStampRecord[i] = timestampMAP[dappNum][i];
            nativeIn[i] = nativeTokenReceivedEach[dappNum][timestampMAP[dappNum][i]];

        }

        return(nativeIn,timeStampRecord);
    }

    receive() external payable {
    finalizedPayment = finalizedPayment + msg.value; // variable to track payments coming when a presale is finalized or funds are send from any external sources
        
    }

}