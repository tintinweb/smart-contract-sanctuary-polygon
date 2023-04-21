/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool ok);

    function approve(address spender, uint256 amount) external returns (bool);
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

pragma solidity ^0.6.0;
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
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
     }


contract KycContract is Ownable{
    mapping (address => bool) public approved;

    function setKycCompleted(address _addr) public onlyOwner {
        approved[_addr] = true;
    }

    function removeKycRevoked(address _addr) public onlyOwner {
        approved[_addr] = false;
    }

    function kycStatus(address _addr) public view returns(bool) {
        return approved[_addr];
    }
}

contract BGCPresale {
    using SafeMath for uint256;

    IBEP20 public BGC;
     KycContract kyc;

    
    address payable public owner;

    
    uint256 public totalTokensToSell =  5000000 * 10**18;          // 81000000000 BGC tokens for sell
    uint256 public BGCPerBnb = 30000 * 10**18;             // 1 BNB = 30000000 BGC
    uint256 public minPerTransaction = 3000 * 10**18;         // min amount per transaction (0.1BNB)
    uint256 public maxPerUser = 1500000 * 10**18;                // max amount per user (5BNB)
    uint256 public totalSold;


    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;

    bool public saleEnded;
    
    mapping(address => uint256) public BGCPerAddresses;

    event tokensBought(address indexed user, uint256 amountSpent, uint256 amountBought, string tokenName, uint256 date);
    event tokensClaimed(address indexed user, uint256 amount, uint256 date);
    event addLiquidityEvent(uint256 tokenAmount, uint256 ethAmount, uint256 allowance);

    modifier checkSaleRequirements(uint256 buyAmount) {
        require(saleEnded == false, 'Sale ended');
        require(
            buyAmount > 0 && buyAmount <= unsoldTokens(),
            'Insufficient Token in Presale Contract'
        );
        _;
    }

    modifier checkWithdrawLPRequirements() {
        require(saleEnded == true, 'Sale not finished.');
        _;
    }

    constructor(
        address _BGC,  
        KycContract _kyc
    ) public {
        owner = msg.sender;
        BGC = IBEP20(_BGC);
        kyc = _kyc;
    }

    function buyWithBNB(uint256 buyAmount) public payable checkSaleRequirements(buyAmount) {
        uint256 amount = calculateBNBAmount(buyAmount);
        require(msg.value >= amount, 'Insufficient BNB balance');
        require(buyAmount >= minPerTransaction, 'Lower than the minimal transaction amount');
        require(kyc.kycStatus(msg.sender), "KYC is not completed, purchase is prohibited");
        
        uint256 sumSoFar = BGCPerAddresses[msg.sender].add(buyAmount);
        require(sumSoFar <= maxPerUser, 'Greater than the maximum purchase limit');

        BGCPerAddresses[msg.sender] = sumSoFar;
        totalSold = totalSold.add(buyAmount);
        
        BGC.transfer(msg.sender, buyAmount);
        emit tokensBought(msg.sender, amount, buyAmount, 'BNB', now);
    }

    receive() external payable {
    }


      

    function changeOwner(address payable _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }

    function setTotalTokensToSell(uint256 _totalTokensToSell) public {
        require(msg.sender == owner);
        totalTokensToSell = _totalTokensToSell;
    }

    function setMinPerTransaction(uint256 _minPerTransaction) public {
        require(msg.sender == owner);
        minPerTransaction = _minPerTransaction;
    }

    function setMaxPerUser(uint256 _maxPerUser) public {
        require(msg.sender == owner);
        maxPerUser = _maxPerUser;
    }

    function setTokenPricePerBNB(uint256 _BGCPerBnb) public {
        require(msg.sender == owner);
        require(_BGCPerBnb > 0, "Invalid BGC price per BNB");
        BGCPerBnb = _BGCPerBnb;
    }

    function endSale() public {
        require(msg.sender == owner && saleEnded == false);
        saleEnded = true;
        
        uint256 bnbAmount = address(this).balance.mul(90).div(100);
        uint256 tokenAmount = BGC.balanceOf(address(this));
        
        addLiquidity(tokenAmount, bnbAmount);
    }


    function withdrawCollectedTokens() public {
        require(msg.sender == owner);
        require(address(this).balance > 0, "Insufficient balance");
        owner.transfer(address(this).balance);
    }

    function withdrawUnsoldTokens() public {
        require(msg.sender == owner);
        uint256 remainedTokens = unsoldTokens();
        require(remainedTokens > 0, "No remained tokens");
        BGC.transfer(owner, remainedTokens);
    }

    function withdrawLockedLPTokens() public checkWithdrawLPRequirements(){
        require(msg.sender == owner);
        uint256 lockedLPTokens = lockedLPTokens();
        require(lockedLPTokens > 0, "No locked LP tokens");

        IUniswapV2Pair(uniswapV2Pair).transfer(owner, lockedLPTokens);
    }

    function unsoldTokens() public view returns (uint256) {
        // return totalTokensToSell.sub(totalSold);
        return BGC.balanceOf(address(this));
    }

    function lockedLPTokens() public view returns (uint256) {
        // return totalTokensToSell.sub(totalSold);
        return IUniswapV2Pair(uniswapV2Pair).balanceOf(address(this));
    }

    function calculateBGCAmount(uint256 bnbAmount) public view returns (uint256) {
        uint256 BGCAmount = BGCPerBnb.mul(bnbAmount).div(10**18);
        return BGCAmount;
    }

    function calculateBNBAmount(uint256 BGCAmount) public view returns (uint256) {
        require(BGCPerBnb > 0, "BGC price per BNB should be greater than 0");
        uint256 bnbAmount = BGCAmount.mul(10**18).div(BGCPerBnb);
        return bnbAmount;
    }

    function setRouter(address _router) public {
        require(msg.sender == owner && saleEnded == false);
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(_router);

        if (IUniswapV2Factory(_newPancakeRouter.factory()).getPair(address(BGC), _newPancakeRouter.WETH()) == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(BGC), _newPancakeRouter.WETH());
        } else {
            uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).getPair(address(BGC), _newPancakeRouter.WETH());
        }
        
        uniswapV2Router = _newPancakeRouter;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        BGC.approve(address(uniswapV2Router), tokenAmount);
        uint256 allowance = BGC.allowance(address(this), address(uniswapV2Router));
        
        emit addLiquidityEvent(tokenAmount, ethAmount, allowance);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(BGC),
            tokenAmount,
            0, // slippage is unavoidableF
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

}