// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ERC20 {
    function transfer(address to, uint256 value) external returns(bool);

    function approve(address spender, uint256 value) external returns(bool);

    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function totalSupply() external view returns(uint256);

    function balanceOf(address who) external view returns(uint256);

    function allowance(address owner, address spender) external view returns(uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

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

// pragma solidity >=0.6.2;

interface UniswapRouter02 {
    function factory() external pure returns(address);

    function WETH() external pure returns(address);
    function WBNB() external pure returns(address);
    function WAVAX() external pure returns(address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);

  }





/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public voter;
    mapping(address => bool) public Deployer;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}




contract feesCheckContract is Ownable {

    uint256 public regPresaleFeesNative = 1 * (10**18); // 1 ETH
    uint256 public regWhitelistFeesNative = 9 * (10**17); // 0.9 ETH

    uint256 public fairPresaleFeesNative = 1 * (10**18); // 1 ETH
    uint256 public fairWhitelistFeesNative = 9 * (10**17); // 0.9 ETH

    uint256 public nftTokenPresaleFeesNative = 1 * (10**18); // 1 ETH
    uint256 public nftTokenWhitelistFeesNative = 9 * (10**17); // 0.9 ETH

    uint256 public nftPresaleFeesNative = 1 * (10**18); // 1 ETH
    uint256 public nftWhitelistFeesNative = 9 * (10**17); // 0.9 ETH

    uint256 public dxlockFeesTokenStdNative = 2 * (10**17); // 0.2 ETH
    uint256 public dxlockFeesTokenRwdNative = 5 * (10**17); // 0.5 ETH
    uint256 public dxlockFeesTokenLPNative = 2 * (10**17); // 0.2 ETH


    uint256 public dxDropFeesNative = 1 * (10**17); // 0.1 ETH


    uint256 public regPresaleFees = 1 * (10**3); // low for testing
    uint256 public regWhitelistFees = 0.5 * (10**3); // low for testing

    uint256 public fairPresaleFees = 0.8 * (10**3); // low for testing
    uint256 public fairWhitelistFees = 0.4 * (10**3); // low for testing

    uint256 public nftTokenPresaleFees = 1.4 * (10**3); // low for testing
    uint256 public nftTokenWhitelistFees = 0.7 * (10**3); // low for testing

    uint256 public nftPresaleFees = 1.2 * (10**3); // low for testing
    uint256 public nftWhitelistFees = 0.6 * (10**3); // low for testing

    uint256 public dxlockFeesTokenStd = 1 * (10**2); // low for testing
    uint256 public dxlockFeesTokenRwd = 4 * (10**2); // low for testing
    uint256 public dxlockFeesTokenLP = 2 * (10**2); // low for testing

    uint256 public dxMintStd = 1 * (10**2); // low for testing
    uint256 public dxMintBurn = 2 * (10**2); // low for testing
    uint256 public dxMintDiv = 3 * (10**2); // low for testing
    uint256 public dxMintLiq = 4 * (10**2); // low for testing

    uint256 public dxDropFees = 3 * (10**2); // low for testing

    bool public stableFee = true;
    uint256 public dappNumber;
    uint256 public dappWhitelistNumber;
    mapping(string => uint256) public feesMap;
    mapping(string => uint256) public feesMapNative;
    mapping(string => bool) public feesMapBool;
    mapping(string => bool) public whitelistMapBool;
    mapping(string => uint256) public whitelistFeeMap;
    mapping(string => uint256) public whitelistFeeMapNative;
    mapping(uint256 => string) public dappNames;
    mapping(uint256 => string) public dappWhitelistNames;
    address public swapRouter_Address;
    address public currency;
    constructor(address _dexRouter, address _currency) {

        swapRouter_Address = _dexRouter;
        currency = _currency;
// native Fees

        feesMapNative["regPresaleFees"] = regPresaleFeesNative;
        feesMapNative["fairPresaleFees"] = fairPresaleFeesNative;
        feesMapNative["nftTokenPresaleFees"] = nftTokenPresaleFeesNative;
        feesMapNative["nftPresaleFees"] = nftPresaleFeesNative;
        feesMapNative["dxlockFeesTokenStd"] = dxlockFeesTokenStdNative;
        feesMapNative["dxlockFeesTokenRwd"] = dxlockFeesTokenRwdNative;
        feesMapNative["dxlockFeesTokenLP"] = dxlockFeesTokenLPNative;
        feesMapNative["dxDropFees"] = dxDropFeesNative;
        whitelistFeeMapNative["regWhitelistFees"] = regWhitelistFeesNative; 
        whitelistFeeMapNative["fairWhitelistFees"] = fairWhitelistFeesNative; 
        whitelistFeeMapNative["nftTokenWhitelistFees"] = nftTokenWhitelistFeesNative; 
        whitelistFeeMapNative["nftWhitelistFees"] = nftWhitelistFeesNative; 

// USDC converted Fees
        feesMap["regPresaleFees"] = regPresaleFees;
        dappNames[dappNumber] = "regPresaleFees";
        dappNumber++;
        feesMapBool["regPresaleFees"] = true;

        feesMap["fairPresaleFees"] = fairPresaleFees;
        dappNames[dappNumber] = "fairPresaleFees";
        dappNumber++;
        feesMapBool["fairPresaleFees"] = true;

        feesMap["nftTokenPresaleFees"] = nftTokenPresaleFees;
        dappNames[dappNumber] = "nftTokenPresaleFees";
        dappNumber++;
        feesMapBool["nftTokenPresaleFees"] = true;

        feesMap["nftPresaleFees"] = nftPresaleFees;
        dappNames[dappNumber] = "nftPresaleFees";
        dappNumber++;
        feesMapBool["nftPresaleFees"] = true;

        feesMap["dxlockFeesTokenStd"] = dxlockFeesTokenStd;
        dappNames[dappNumber] = "dxlockFeesTokenStd";
        dappNumber++;
        feesMapBool["dxlockFeesTokenStd"] = true;

        feesMap["dxlockFeesTokenRwd"] = dxlockFeesTokenRwd;
        dappNames[dappNumber] = "dxlockFeesTokenRwd";
        dappNumber++;
        feesMapBool["dxlockFeesTokenRwd"] = true;

        feesMap["dxlockFeesTokenLP"] = dxlockFeesTokenLP;
        dappNames[dappNumber] = "dxlockFeesTokenLP";
        dappNumber++;
        feesMapBool["dxlockFeesTokenLP"] = true;

        feesMap["dxDropFees"] = dxDropFees;
        dappNames[dappNumber] = "dxDropFees";
        dappNumber++;
        feesMapBool["dxDropFees"] = true;

        feesMap["dxMintStd"] = dxMintStd;
        dappNames[dappNumber] = "dxMintStd";
        dappNumber++;
        feesMapBool["dxMintStd"] = true;

        feesMap["dxMintBurn"] = dxMintBurn;
        dappNames[dappNumber] = "dxMintBurn";
        dappNumber++;
        feesMapBool["dxMintBurn"] = true;

        feesMap["dxMintDiv"] = dxMintDiv;
        dappNames[dappNumber] = "dxMintDiv";
        dappNumber++;
        feesMapBool["dxMintDiv"] = true;

        feesMap["dxMintLiq"] = dxMintLiq;
        dappNames[dappNumber] = "dxMintLiq";
        dappNumber++;
        feesMapBool["dxMintLiq"] = true;

        whitelistFeeMap["regWhitelistFees"] = regWhitelistFees;
        dappWhitelistNames[dappWhitelistNumber] = "regWhitelistFees";
        dappWhitelistNumber++;
        whitelistMapBool["regWhitelistFees"] = true;

        whitelistFeeMap["fairWhitelistFees"] = fairWhitelistFees;
        dappWhitelistNames[dappWhitelistNumber] = "fairWhitelistFees"; 
        dappWhitelistNumber++;
        whitelistMapBool["fairWhitelistFees"] = true;

        whitelistFeeMap["nftTokenWhitelistFees"] = nftTokenWhitelistFees;
        dappWhitelistNames[dappWhitelistNumber] = "nftTokenWhitelistFees"; 
        dappWhitelistNumber++;
        whitelistMapBool["nftTokenWhitelistFees"] = true;

        whitelistFeeMap["nftWhitelistFees"] = nftWhitelistFees;
        dappWhitelistNames[dappWhitelistNumber] = "nftWhitelistFees"; 
        dappWhitelistNumber++;
        whitelistMapBool["nftWhitelistFees"] = true;


    }
    function getWrapAddrRouterSpecific(address _router) public pure returns (address){
        try UniswapRouter02(_router).WETH() {
            return UniswapRouter02(_router).WETH();
        }
        catch (bytes memory) {
            //return UniswapRouter02(_router).WBNB();
            try UniswapRouter02(_router).WBNB() {
                return UniswapRouter02(_router).WBNB();
        }
            catch (bytes memory) {
                return UniswapRouter02(_router).WAVAX();
        }
        }
    }
    function getAmountsMinETH(uint256 _tokenIN) public view returns(uint256) {

      //  UniswapRouter02 pancakeRouter = UniswapRouter02(_router);
        // generate the pair path of token -> weth
        uint256[] memory amountMinArr;
        uint256 AmountMin;
        address[] memory path = new address[](2);
        path[0] = address(currency);
        path[1] = getWrapAddrRouterSpecific(swapRouter_Address);

        amountMinArr = UniswapRouter02(swapRouter_Address).getAmountsOut(_tokenIN, path);
        AmountMin = uint256(amountMinArr[1]);

        return AmountMin;


    }

    function addNewDapp(string memory _dappName, uint256 _newDappFees) onlyOwner public {
        
        require(!feesMapBool[_dappName],"dapp already added");
        feesMap[_dappName] = _newDappFees;
        feesMapNative[_dappName] = getAmountsMinETH(_newDappFees);
        feesMapBool[_dappName] = true;
        dappNames[dappNumber] = _dappName;
        dappNumber++;

    }
    function addNewDappWhitelist(string memory _dappWhitelistName, uint256 _newDappWhitelistFees) onlyOwner public {

        require(!whitelistMapBool[_dappWhitelistName],"dapp whitelist already added");
        whitelistFeeMap[_dappWhitelistName] = _newDappWhitelistFees;
        whitelistFeeMapNative[_dappWhitelistName] = getAmountsMinETH(_newDappWhitelistFees);
        dappWhitelistNames[dappWhitelistNumber] = _dappWhitelistName;
        dappWhitelistNumber++;

    }

    function changeDappFees(string memory _dappName, uint256 _updatedDappFees) onlyOwner public{

        require(feesMapBool[_dappName],"dapp not found");
        feesMap[_dappName] = _updatedDappFees;
        feesMapNative[_dappName] = getAmountsMinETH(_updatedDappFees);
    }

    function changeDappWhitelistFees(string memory _dappWhitelistName, uint256 _updatedDappWhitelistFees) onlyOwner public{

        require(whitelistMapBool[_dappWhitelistName],"dapp whitelist not found");
        whitelistFeeMap[_dappWhitelistName] = _updatedDappWhitelistFees;
        whitelistFeeMapNative[_dappWhitelistName] = getAmountsMinETH(_updatedDappWhitelistFees);
    }

    function changeDexRouter(address _newRouter) onlyOwner public {

        require(swapRouter_Address != _newRouter,"router already there");
        swapRouter_Address = _newRouter;

    }
    function changeCurrency(address _newCurrency) onlyOwner public {

        require(currency != _newCurrency,"currency already in use");
        currency = _newCurrency;

    }
    function getFees(string memory _dappName) public view returns(uint256){

        require(feesMapBool[_dappName],"dapp not found");
        if(stableFee){
            
            return getAmountsMinETH(feesMap[_dappName]);
        }
        else {

            return feesMapNative[_dappName];
        }

    }

    function getWhitelistFees(string memory _dappWhitelistName) public view returns(uint256){
        
        require(whitelistMapBool[_dappWhitelistName],"dapp whitelist not found");
        if(stableFee){

            return getAmountsMinETH(whitelistFeeMap[_dappWhitelistName]);
        }
    
        else {

            return whitelistFeeMapNative[_dappWhitelistName];
        }

    }

    function enableStableFee() onlyOwner public {

        stableFee = true;

    }

    function disableStableFee() onlyOwner public {

        stableFee = false;

    }

    function withdrawETH(uint256 ethAmount) public payable onlyOwner {

        //payable(platform_wallet).transfer(ethAmount);
        Address.sendValue(payable(msg.sender),ethAmount);
    }


    function withdrawToken(address _tokenAddress, uint256 _Amount) public payable onlyOwner {

        ERC20(_tokenAddress).transfer(msg.sender, _Amount);

    }
}



// DxMint fees -- mumbai testnet
// dxMintStd = 10000wei usd
//dxMintBurn = 11000wei usd
//dxMintDiv = 12000wei usd
//dxMintLiq = 14000wei usd