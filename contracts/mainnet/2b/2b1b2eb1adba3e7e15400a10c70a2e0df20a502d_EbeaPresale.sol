/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function mint(address to, uint amount) external returns (bool);
    function burn(address owner, uint amount) external returns (bool);
    function unpause() external;
    function settings(uint256 _BurnFee, bool _safeChartHistory, uint256 _offSetChartTime) external;
}


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        if (b == 0){
            return a;
        }
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}


abstract contract Auth {
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender)); _;
    }

    function authorize(address adr) public authorized {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

interface IRouter {

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH, uint liquidity);

}

interface IEbeaSwapExecuter{
    function snipeTokentoToken(uint256 amountIn, address tokenIn, address tokenOut, uint256 Slippage, address user) external;
    function snipeETHtoToken(address token, uint256 Slippage, address user) external payable;
}

abstract contract StructLib {
    struct BUYERS {
        uint256 BuyID;
        address Buyer;
        address InputCurrency;
        uint256 InputAmount;
        uint256 OutputAmount;
        bool successful;
    }

    mapping (uint256 => BUYERS) public BuyersList;
    mapping (address => uint256[]) public addressBuyer;
    uint256 public BuyersCount;

    function addBuyerList(address Buyer, address InputCurrency, uint256 InputAmount, uint256 OutputAmount, bool successful) internal {
        uint buyID = BuyersCount++;
        addressBuyer[Buyer].push(buyID);
        
        BuyersList[buyID] = BUYERS({
            BuyID: buyID,
            Buyer: Buyer,
            InputCurrency: InputCurrency,
            InputAmount: InputAmount,
            OutputAmount: OutputAmount,
            successful: successful
        });
    }
}

contract EbeaPresale is StructLib, Auth{
    using SafeMath for uint;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    address public Ebea;
    bool public Ended;
    
    modifier isNotEnded() {
        require(!Ended, "Ebea Presale is Ended!"); 
        _;
    }

    IEbeaSwapExecuter public EbeaSwapExecuter;
    IRouter public router;

    receive() external payable { }

    uint256 decimals = 10**18;
    uint256 public SellAmount = 250_000 * decimals;
    uint256 public LiqidityStartAmount = 200_000 * decimals;
    uint256 public ForSaleOver;
    uint256 public PreSalePrice = 2*(10**4);
    uint256 public maxBuy = 10_000 * decimals;


    constructor(address _Ebea, address _EbeaSwapExecuter, address _router) Auth(msg.sender) {
        EbeaSwapExecuter = IEbeaSwapExecuter(_EbeaSwapExecuter);
        ForSaleOver = SellAmount;
        router = IRouter(_router);
        Ebea = _Ebea;
    }


    function checkPresale(uint256 AmountOut, address user) internal {
        if(ForSaleOver <= AmountOut){
            require(IERC20(Ebea).mint(user, AmountOut), "can't mint");
            migrateLiquidity();
        }else{
            require(IERC20(Ebea).mint(user, AmountOut), "can't mint");
            ForSaleOver = ForSaleOver.sub(AmountOut);
        }

    }


    function migrateLiquidity() internal {
        uint256 amountUSDC = IERC20(USDC).balanceOf(address(this));
        IERC20(Ebea).unpause();
        IERC20(Ebea).mint(address(this), LiqidityStartAmount);
        IERC20(Ebea).approve(address(router), LiqidityStartAmount);
        IERC20(USDC).approve(address(router), amountUSDC);

        router.addLiquidity(
            USDC,
            Ebea,
            amountUSDC,
            LiqidityStartAmount,
            0,
            0,
            address(0x000000000000000000000000000000000000dEaD), // Burn LP Tokens immediately!
            block.timestamp
        );

        uint256 remainingUSDC = IERC20(USDC).balanceOf(address(this));
        if (remainingUSDC > 0){IERC20(USDC).transfer( owner, remainingUSDC);}

        uint256 remainingEbea = IERC20(Ebea).balanceOf(address(this));
        if (remainingEbea > 0){IERC20(Ebea).burn( address(this), remainingEbea);}

        IERC20(Ebea).settings(100, true, 1440);
        Ended = true;
        ForSaleOver = 0;
    }


    function manualEndOfPreSale() public {
        require(msg.sender == owner || msg.sender == address(0) || msg.sender == address(this), "Only owner and calls");
        migrateLiquidity();
    }


    // if migrateLiquidity() Fails, so the developer has the possibility to rescue USDC and add the liquidity manual.
    function ifAddLiquidityFails() external returns (bool error){
        require(msg.sender == owner || msg.sender == address(0), "Only owner and calls!");
        try this.manualEndOfPreSale() {
                error = false;
        }catch{
                error = true;
        }if(error){
            IERC20(USDC).transfer(owner, IERC20(USDC).balanceOf(address(this)));
        }
    }


    function BuyPresaleWithToken(uint256 amountIn, address tokenIn, uint256 Slippage) external isNotEnded{
        require(amountIn > 0, "amountIn is 0");
        uint256 balanceBeforeUSDC = IERC20(USDC).balanceOf(address(this));
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        if (tokenIn != USDC){
            uint256 balance = IERC20(tokenIn).balanceOf(address(this));
            TransferHelper.safeApprove(tokenIn, address(EbeaSwapExecuter), balance);
            EbeaSwapExecuter.snipeTokentoToken(balance, tokenIn, USDC, Slippage, address(this));
        }
        uint256 balanceForBuy = IERC20(USDC).balanceOf(address(this)).sub(balanceBeforeUSDC);
        uint256 AmountOut = (balanceForBuy*1e2).div(PreSalePrice*1e2)*decimals;
        require(balanceForBuy != 0 && AmountOut !=0, "Invalid amount!");
        require(maxBuy >= AmountOut, "Max exceeded!");
        checkPresale(AmountOut, msg.sender);
        addBuyerList(msg.sender, tokenIn, amountIn, AmountOut, true);        
    }

    function BuyPresaleWithETH(uint256 Slippage) external payable isNotEnded{
        require(msg.value > 0, "Invalid amount!");
        uint256 balanceBeforeUSDC = IERC20(USDC).balanceOf(address(this));
        EbeaSwapExecuter.snipeETHtoToken{value: msg.value}(USDC, Slippage, address(this));
        
        uint256 balanceForBuy = IERC20(USDC).balanceOf(address(this)).sub(balanceBeforeUSDC);
        uint256 AmountOut = (balanceForBuy*1e2).div(PreSalePrice*1e2)*decimals;

        require(balanceForBuy != 0 && AmountOut !=0,"Invalid amount!");
        require(maxBuy >= AmountOut, "Max Out exceeded!");

        checkPresale(AmountOut, msg.sender);
        addBuyerList(msg.sender, address(0), msg.value, AmountOut, true);        
    }

}