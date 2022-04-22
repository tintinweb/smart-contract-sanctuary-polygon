pragma solidity ^0.7.4;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a), 'mul overflow');
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != - 1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a),
            'sub overflow');
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a),
            'add overflow');
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256,
            'abs overflow');
        return a < 0 ? - a : a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
        require(b != 0,
            'parameter 2 can not be 0');
        return a % b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface InterfaceLP {
    function sync() external;
}

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), 'Roles: account already has role');
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), 'Roles: account does not have role');
        role.bearer[account] = false;
    }

    function has(Role storage role, address account)
    internal
    view
    returns (bool)
    {
        require(account != address(0), 'Roles: account is the zero address');
        return role.bearer[account];
    }
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = _tokenDecimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IBalanceOfSphere {
    function balanceOfSphere(address _address) external view returns (uint256);
}

interface IPublicBalance {
    function balanceOf(address _address) external view returns (uint256);
}

interface IDEXPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
    external
    returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event TransferOwnerShip(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, 'Not owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit TransferOwnerShip(newOwner);
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),
            'Owner can not be 0');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SphereTokenV2 is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for uint256;

    bool public initialDistributionFinished = false;
    bool public swapEnabled = true;
    bool public autoRebase = false;
    bool private feesOnNormalTransfers = true;
    bool public isBurnEnabled = false;
    bool public isTaxBracket = false;
    bool public partyTime = true;
    bool public isMoveBalance = false;
    bool public isLiquidityEnabled = true;
    bool public isSellHourlyLimit = true;
    bool public isWall = false;
    bool public isTaxBracketEnabledInMoveFee = false;

    uint256 private rebaseIndex = 1 * 10 ** 18;
    uint256 private rewardYield = 3943560072416;
    uint256 private REWARD_YIELD_DENOMINATOR = 10000000000000000;
    uint256 public maxSellTransactionAmount = 500000 * 10 ** 18;
    uint256 public maxBuyTransactionAmount = 500000 * 10 ** 18;
    uint256 private swapThreshold = 400000 * 10 ** 18;
    uint256 private rebaseFrequency = 1800;
    uint256 public nextRebase = 1647385255;
    uint256 public rebaseEpoch = 0;
    uint256 public taxBracketMultiplier = 50;
    uint256 public _markerPairCount;
    uint256 private ONE_E_EIGHTEEN = 1 * 10 ** 18;
    uint256 private liquidityFee = 50;
    uint256 private treasuryFee = 30;
    uint256 private burnFee = 0;
    uint256 private investRemovalDelay = 3600;
    uint256 private sellBurnFee = 0;
    uint256 private buyGalaxyBondFee = 0;
    uint256 private riskFreeValueFee = 50;
    uint256 private sellFeeTreasuryAdded = 20;
    uint256 private sellFeeRFVAdded = 50;
    uint256 private sellGalaxyBond = 0;
    uint256 private partyListDivisor = 50;
    uint256 private realFeePartyArray = 490;
    uint256 public wallDivisor = 20;
    uint256 public wallMultiplier = 10;
    uint256 public totalBuyFee =
    liquidityFee.add(treasuryFee).add(riskFreeValueFee);
    uint256 public totalSellFee =
    totalBuyFee.add(sellFeeTreasuryAdded).add(sellFeeRFVAdded);

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    uint256 private gonSwapThreshold = (TOTAL_GONS * 10) / 10000;

    mapping(address => bool) _isTotalFeeExempt;
    mapping(address => bool) _isBuyFeeExempt;
    mapping(address => bool) _isSellFeeExempt;
    mapping(address => bool) canRebase;
    mapping(address => bool) canSetRewardYield;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public subContractCheck;
    mapping(address => bool) public sphereGamesCheck;
    mapping(address => bool) public partyArrayCheck;
    mapping(address => bool) private _disallowedToMove;
    mapping(address => uint256) private _gonBalances;
    mapping(address => uint256) public partyArrayFee;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => InvestorInfo) public investorInfoMap;

    address[] public _makerPairs;
    address[] public subContracts;
    address[] public sphereGamesContracts;
    address[] public partyArray;

    uint256 private constant MAX_TOTAL_BUY_FEE_RATE = 250;
    uint256 private constant MAX_TOTAL_SELL_FEE_RATE = 250;
    uint256 private constant MAX_INVEST_REMOVABLE_DELAY = 7200;
    uint256 private constant MAX_PARTY_ARRAY = 491;
    uint256 private constant MAX_REBASE_FREQUENCY = 1800;
    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY =
    5 * 10 ** 9 * 10 ** DECIMALS;
    uint256 private constant TOTAL_GONS =
    MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 private constant maxBracketTax = 10; // max bracket is holding 10%
    uint256 private constant MAX_TAX_BRACKET_FEE_RATE = 50;
    uint256 private constant MAX_PARTY_LIST_DIVISOR_RATE = 75;
    uint256 private constant MIN_SELL_AMOUNT_RATE = 500000 * 10 ** 18;
    uint256 private constant MIN_BUY_AMOUNT_RATE = 500000 * 10 ** 18;
    uint256 private constant FEE_DENOMINATOR = 1000;
    uint256 private constant MIN_INVEST_REMOVABLE_PER_PERIOD = 1500000 * 10 ** 18;
    uint256 private constant SECONDS_PER_DAY = 86400;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    address public liquidityReceiver =
    0x1a2Ce410A034424B784D4b228f167A061B94CFf4;
    address public treasuryReceiver =
    0x20D61737f972EEcB0aF5f0a85ab358Cd083Dd56a;
    address public riskFreeValueReceiver =
    0x826b8d2d523E7af40888754E3De64348C00B99f4;
    address public galaxyBondReceiver =
    0x20D61737f972EEcB0aF5f0a85ab358Cd083Dd56a;

    IDEXRouter public router;
    address public pair;

    uint256 maxInvestRemovablePerPeriod = 1500000 * 10 ** 18;

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0), 'recipient is not valid');
        _;
    }


    /* ======== STRUCTS ======== */
    struct Withdrawal {
        uint256 timestamp;
        uint256 withdrawAmount;
    }

    struct InvestorInfo {
        uint256 totalInvestableExchanged;
        Withdrawal[] withdrawHistory;
    }


    constructor(uint256 _rebaseIndex, uint256 _rebaseEpoch)
    ERC20Detailed('Sphere Finance', 'SPHERE', uint8(DECIMALS))
    {
        router = IDEXRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        address pair = IDEXFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        _allowedFragments[address(this)][address(router)] = uint256(- 1);
        _allowedFragments[address(this)][address(this)] = uint256(- 1);
        _allowedFragments[address(this)][pair] = uint256(- 1);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        _isTotalFeeExempt[treasuryReceiver] = true;
        _isTotalFeeExempt[riskFreeValueReceiver] = true;
        _isTotalFeeExempt[galaxyBondReceiver] = true;
        _isTotalFeeExempt[address(this)] = true;
        _isTotalFeeExempt[msg.sender] = true;

        setWhitelistSetters(msg.sender, true, 1);
        setWhitelistSetters(msg.sender, true, 2);

        rebaseIndex = _rebaseIndex;
        rebaseEpoch = _rebaseEpoch;

        setAutomatedMarketMakerPair(pair, true);


        emit Transfer(
            address(0x0),
            msg.sender,
            _totalSupply
        );
    }

    receive() external payable {}

    //gets every token in circulation no matter where
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    //how much a user is allowed to transfer from own address to another one
    function allowance(address owner_, address spender)
    external
    view
    override
    returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    //get balance of user
    function balanceOf(address who) public view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    //get the address in the iteration
    function markerPairAddress(uint256 value) public view returns (address) {
        return _makerPairs[value];
    }

    //get the current index of rebase
    function currentIndex() public view returns (uint256) {
        return rebaseIndex;
    }

    //checks if a user is exempt from protocol fees
    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isTotalFeeExempt[_addr];
    }

    //checks what the threshold is for swapping
    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold.div(_gonsPerFragment);
    }

    // validate if the last rebase is in the past, thus execute
    function shouldRebase() internal view returns (bool) {
        return nextRebase <= block.timestamp;
    }

    //enable tax bracket on users
    function isTaxBracketEnabled() internal view returns (bool) {
        return isTaxBracket;
    }

    //validates if the sell limit is enabled
    function isSellHourlyLimitEnabled() internal view returns (bool) {
        return isSellHourlyLimit;
    }

    //add the wall function that enables usages
    function isWallEnabled() internal view returns (bool) {
        return isWall;
    }

    // check if the wallet should be taxed or not
    function shouldTakeFee(address from, address to)
    internal
    view
    returns (bool)
    {
        if (_isTotalFeeExempt[from] || _isTotalFeeExempt[to]) {
            return false;
        } else if (feesOnNormalTransfers) {
            return true;
        } else {
            return (automatedMarketMakerPairs[from] ||
            automatedMarketMakerPairs[to]);
        }
    }

    //validates if the swap back function should be initiated or not
    function shouldSwapBack() internal view returns (bool) {
        return
        !automatedMarketMakerPairs[msg.sender] &&
        !inSwap &&
        swapThreshold > 0 &&
        totalBuyFee.add(totalSellFee) > 0 &&
        balanceOf(address(this)) >= gonSwapThreshold.div(_gonsPerFragment);
    }

    //calculates circulating supply (dead and zero is not added due to them being phased out of circulation forrever)
    function getCirculatingSupply() external view returns (uint256) {
        return
        (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(
            _gonsPerFragment
        );
    }

    //calculate the users total on different contracts
    function getUserTotalOnDifferentContractsSphere(address sender)
    public
    view
    returns (uint256)
    {
        uint256 userTotal = balanceOf(sender);

        //calculate the balance of different contracts on different wallets and sum them
        return userTotal.add(getBalanceContracts(sender));
    }

    //this function iterates through all other contracts that are being part of the Sphere ecosystem
    //we add a new contract like wSPHERE or sSPHERE, whales could technically abuse this
    //by swapping to these contracts and leave the dynamic tax bracket
    function getBalanceContracts(address sender)
    public
    view
    returns (uint256)
    {
        uint256 userTotal;

        for (uint256 i = 0; i < subContracts.length; i++) {
            userTotal += IBalanceOfSphere(subContracts[i]).balanceOfSphere(
                sender
            );
        }
        for (uint256 i = 0; i < sphereGamesContracts.length; i++) {
            userTotal += IERC20(sphereGamesContracts[i]).balanceOf(
                sender
            );
        }

        return userTotal;
    }

    function getTokensInLPCirculation() public view returns (uint256) {
        uint256 LPTotal;

        for (uint256 i = 0; i < _makerPairs.length; i++) {
            LPTotal += balanceOf(_makerPairs[i]);
        }

        return LPTotal;
    }

    function getCurrentTaxBracket(address _address)
    public
    view
    returns (uint256)
    {
        //gets the total balance of the user
        uint256 userTotal = getUserTotalOnDifferentContractsSphere(_address);

        //calculate the percentage
        uint256 totalCap = userTotal.mul(100).div(getTokensInLPCirculation());

        //calculate what is smaller, and use that
        uint256 _bracket = SafeMath.min(totalCap, maxBracketTax);

        //multiply the bracket with the multiplier
        _bracket *= taxBracketMultiplier;

        return _bracket;
    }

    //sync every LP to make sure Theft-of-Liquidity can't be arbitraged
    function manualSync() public {
        for (uint i = 0; i < _makerPairs.length; i++) {
            try IDEXPair(_makerPairs[i]).sync() {

            }catch Error (string memory reason) {
                emit GenericErrorEvent("manualSync(): _makerPairs.sync() Failed");
                emit GenericErrorEvent(reason);
            }
        }
    }

    //transfer from one valid to another
    function transfer(address to, uint256 value)
    external
    override
    validRecipient(to)
    returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    //basic transfer from one wallet to the other
    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);

        emit Transfer(from, to, amount);

        return true;
    }

    //inherent transfer function that calculates the taxes and the limits
    //limits like sell per hour, party array check
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        bool excludedAccount = _isTotalFeeExempt[sender] ||
        _isTotalFeeExempt[recipient];

        require(initialDistributionFinished || excludedAccount, 'Trade off');

        if (automatedMarketMakerPairs[recipient] && !excludedAccount) {
            require(amount <= maxSellTransactionAmount, 'Too much sell');
        }

        if (
            automatedMarketMakerPairs[recipient] &&
            !excludedAccount &&
            partyArrayCheck[sender] &&
            partyTime
        ) {
            require(
                amount <= maxSellTransactionAmount.div(partyListDivisor),
                'party div'
            );
        }

        if (automatedMarketMakerPairs[sender] && !excludedAccount) {
            require(amount <= maxBuyTransactionAmount, 'too much buy');
        }

        if (
            automatedMarketMakerPairs[recipient] &&
            !excludedAccount &&
            isSellHourlyLimit
        ) {
            InvestorInfo storage investor = investorInfoMap[sender];
            //Make sure they can't withdraw too often.
            Withdrawal[] storage withdrawHistory = investor.withdrawHistory;
            uint256 authorizedWithdraw = maxInvestRemovablePerPeriod.sub(
                getLastPeriodWithdrawals(sender)
            );
            require(amount <= authorizedWithdraw, 'max withdraw');
            withdrawHistory.push(
                Withdrawal({timestamp : block.timestamp, withdrawAmount : amount})
            );
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);

        if (shouldSwapBack()) {
            swapBack();
        }

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
        ? takeFee(sender, recipient, gonAmount)
        : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(_gonsPerFragment)
        );

        if (
            shouldRebase() &&
            autoRebase &&
            !automatedMarketMakerPairs[sender] &&
            !automatedMarketMakerPairs[recipient]
        ) {
            _rebase();
            manualSync();
        }

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != uint256(- 1)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
            msg.sender
            ].sub(value, 'Insufficient Allowance');
        }

        _transferFrom(from, to, value);
        return true;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isLiquidityEnabled ? liquidityFee : 0;
        uint256 realTotalFee = totalBuyFee.add(totalSellFee);

        uint256 contractTokenBalance = balanceOf(address(this));

        uint256 balanceBefore = address(this).balance;

        uint256 amountToBurn = contractTokenBalance
        .mul(burnFee.add(sellBurnFee))
        .div(realTotalFee);

        uint256 amountToLiquidate = contractTokenBalance
        .mul(dynamicLiquidityFee)
        .div(realTotalFee)
        .div(2)
        .sub(amountToBurn);

        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquidate).sub(amountToBurn);


        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountMATIC = address(this).balance.sub(balanceBefore);

        uint256 totalMATICFee = (totalBuyFee.add(totalSellFee)).sub(dynamicLiquidityFee.div(2));

        uint256 amountMATICLiquidity = amountMATIC
        .mul(dynamicLiquidityFee)
        .div(totalMATICFee)
        .div(2);

        uint256 amountToRFV = amountMATIC.mul(riskFreeValueFee.add(sellFeeRFVAdded)).div(totalMATICFee).sub(amountMATICLiquidity);
        uint256 amountToGalaxyBond = amountMATIC.mul(buyGalaxyBondFee.add(sellGalaxyBond).mul(2)).div(totalMATICFee).sub(amountToRFV);
        uint256 amountToTreasury = amountMATIC
        .sub(amountMATICLiquidity)
        .sub(amountToRFV)
        .sub(amountToGalaxyBond);


        (bool success,) = payable(treasuryReceiver).call{
        value : amountToTreasury,
        gas : 30000
        }("");
        (success,) = payable(riskFreeValueReceiver).call{
        value : amountToRFV,
        gas : 30000
        }("");
        (success,) = payable(galaxyBondReceiver).call{
        value : amountToGalaxyBond,
        gas : 30000
        }("");

        success = false;

        if (amountToLiquidate > 0) {
            router.addLiquidityETH{value : amountMATICLiquidity}(
                address(this),
                amountToLiquidate,
                0,
                0,
                liquidityReceiver,
                block.timestamp
            );
        }
    }


    /**
@dev Returns the total amount withdrawn by the _address during the last hour
        **/

    function getLastPeriodWithdrawals(address _address)
    public
    view
    returns (uint256 totalWithdrawLastHour)
    {
        InvestorInfo storage investor = investorInfoMap[_address];

        Withdrawal[] storage withdrawHistory = investor.withdrawHistory;
        for (uint256 i = 0; i < withdrawHistory.length; i++) {
            Withdrawal memory withdraw = withdrawHistory[i];
            if (withdraw.timestamp >= block.timestamp.sub(investRemovalDelay)) {
                totalWithdrawLastHour = totalWithdrawLastHour.add(
                    withdrawHistory[i].withdrawAmount
                );
            }
        }

        return totalWithdrawLastHour;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount
    ) internal returns (uint256) {
        uint256 _realFee = totalBuyFee;

        if (isWallEnabled()) {
            totalBuyFee = totalBuyFee.div(wallDivisor).mul(wallMultiplier);
        }

        if (_isBuyFeeExempt[sender]) {
            _realFee = 0;
        }

        //check if it's a sell fee embedded
        if (automatedMarketMakerPairs[recipient]) {
            _realFee = totalSellFee;

            //trying to join our party? Become the party maker :)
            if (partyArrayCheck[sender] && partyTime) {
                if (_realFee < realFeePartyArray) _realFee = partyArrayFee[sender];
            }

            if (_isSellFeeExempt[sender]) {
                _realFee = 0;
            }
        }

        if (!automatedMarketMakerPairs[sender]) {
            //calculate Tax
            if (isTaxBracketEnabled()) {
                _realFee += getCurrentTaxBracket(sender);
            }
        }

        uint256 feeAmount = gonAmount.mul(_realFee).div(FEE_DENOMINATOR);

        _gonBalances[address(this)] = _gonBalances[address(this)].add(feeAmount);

        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));

        return gonAmount.sub(feeAmount);
    }

    //burn tokens to the dead wallet
    function tokenBurner(uint256 _tokenAmount) private {
        _transferFrom(address(this), address(DEAD), _tokenAmount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
    external
    returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
        spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value)
    external
    override
    returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    //rebase either on circulating supply or total supply
    function _rebase() private {
        if (!inSwap) {
            int256 supplyDelta = int256(_totalSupply.mul(rewardYield).div(REWARD_YIELD_DENOMINATOR));
            coreRebase(supplyDelta);
        }
    }

    //rebase everyone
    function coreRebase(int256 supplyDelta) private returns (uint256) {
        require(nextRebase <= block.timestamp, 'rebase too early');
        uint256 epoch = nextRebase;

        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(- supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        updateRebaseIndex(epoch);

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    //set who is allowed to trigger the rebase or reward yield
    function setWhitelistSetters(address _addr, bool _value, uint256 _type) public onlyOwner {
        if (_type == 1) {
            require(canRebase[_addr] != _value, 'Not changed');
            canRebase[_addr] = _value;
        } else if (_type == 2) {
            require(canSetRewardYield[_addr] != _value, 'Not changed');
            canSetRewardYield[_addr] = _value;
        }

        emit SetRebaseWhitelist(_addr, _value, _type);
    }

    //set the router in case of dex switch
    function setRouter(address _router) external onlyOwner {
        router = IDEXRouter(_router);
        //mainnet: 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff

        pair = IDEXFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        _allowedFragments[address(this)][address(router)] = uint256(- 1);
        _allowedFragments[address(this)][address(this)] = uint256(- 1);
        _allowedFragments[address(this)][pair] = uint256(- 1);
        setAutomatedMarketMakerPair(pair, true);

        emit SetRouter(_router);
    }

    //execute the rebase
    function rebase(uint256 epoch, int256 supplyDelta)
    external
    onlyOwner
    returns (uint256)
    {
        require(!inSwap, 'Try again');
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(- supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        manualSync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    //execute manual rebase
    function manualRebase() external {
        require(canRebase[msg.sender], 'can not rebase');
        require(!inSwap, 'Try again');
        require(nextRebase <= block.timestamp, 'Not in time');

        int256 supplyDelta;
        int i = 0;

        do {
            supplyDelta = int256(_totalSupply.mul(rewardYield).div(REWARD_YIELD_DENOMINATOR));
            coreRebase(supplyDelta);
            emit LogManualRebase(supplyDelta, block.timestamp);
            i++;
        }
        while (nextRebase < block.timestamp && i < 100);

        manualSync();
    }

    //move full balance without the tax
    function moveBalance(address _to)
    public
    validRecipient(_to)
    returns (bool)
    {
        require(isMoveBalance, 'can not move');
        // Allow to move balance only once
        require(!_disallowedToMove[msg.sender], 'not allowed');
        require(balanceOf(msg.sender) > 0, 'No tokens');
        uint256 balanceOfAllSubContracts = 0;

        balanceOfAllSubContracts = getBalanceContracts(msg.sender);
        require(balanceOfAllSubContracts == 0, 'other balances');

        // Once an address received funds moved from another address it should
        // not be able to move its balance again
        _disallowedToMove[msg.sender] = true;
        uint256 gonAmount = _gonBalances[msg.sender];

        // reduce balance early
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonAmount);

        // Move the balance to the to address
        _gonBalances[_to] = _gonBalances[_to].add(gonAmount);

        emit Transfer(
            msg.sender,
                _to,
            gonAmount.div(_gonsPerFragment)
        );
        emit MoveBalance(msg.sender, _to);
        return true;
    }

    function updateRebaseIndex(uint256 epoch) private {
        // update the next Rebase time
        nextRebase = epoch.add(rebaseFrequency);

        //update Index similarly to OHM, so a wrapped token created is possible (wSPHERE)

        //formula: rebaseIndex * (1 * 10 ** 18 + ((1 * 10 ** 18) * rewardYield / rewardYieldDenominator)) / 1 * 10 ** 18
        rebaseIndex = rebaseIndex
        .mul(
            ONE_E_EIGHTEEN.add(
                ONE_E_EIGHTEEN.mul(rewardYield).div(
                    REWARD_YIELD_DENOMINATOR
                )
            )
        )
        .div(ONE_E_EIGHTEEN);

        //simply show how often we rebased since inception (how many epochs)
        rebaseEpoch += 1;
    }

    //add new subcontracts to the protocol so they can be calculated
    function addSubContracts(address _subContract, bool _value)
    public
    onlyOwner
    {
        subContractCheck[_subContract] = _value;

        if (_value) {
            subContracts.push(_subContract);
        } else {
            for (uint256 i = 0; i < subContracts.length; i++) {
                if (subContracts[i] == _subContract) {
                    subContracts[i] = subContracts[subContracts.length - 1];
                    subContracts.pop();
                    break;
                }
            }
        }

        emit SetSubContracts(_subContract, _value);
    }

    //Add S.P.H.E.R.E. Games Contracts
    function addSphereGamesAddies(address _sphereGamesAddy, bool _value)
    public
    onlyOwner
    {
        sphereGamesCheck[_sphereGamesAddy] = _value;

        if (_value) {
            sphereGamesContracts.push(_sphereGamesAddy);
        } else {
            require(sphereGamesContracts.length > 1, 'Required 1 pair');
            for (uint256 i = 0; i < sphereGamesContracts.length; i++) {
                if (sphereGamesContracts[i] == _sphereGamesAddy) {
                    sphereGamesContracts[i] = sphereGamesContracts[
                    sphereGamesContracts.length - 1
                    ];
                    sphereGamesContracts.pop();
                    break;
                }
            }
        }

        emit SetSphereGamesAddresses(_sphereGamesAddy, _value);
    }

    function addPartyAddies(address _partyAddy, bool _value, uint256 feeAmount) public onlyOwner {
        partyArrayCheck[_partyAddy] = _value;
        partyArrayFee[_partyAddy] = feeAmount;

        if (_value) {
            partyArray.push(_partyAddy);
        } else {
            for (uint256 i = 0; i < partyArray.length; i++) {
                if (partyArray[i] == _partyAddy) {
                    partyArray[i] = partyArray[partyArray.length - 1];
                    partyArray.pop();
                    break;
                }
            }
        }

        emit SetPartyAddresses(_partyAddy, _value);
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value)
    public
    onlyOwner
    {
        require(automatedMarketMakerPairs[_pair] != _value, 'already set');

        automatedMarketMakerPairs[_pair] = _value;

        if (_value) {
            _makerPairs.push(_pair);
            _markerPairCount++;
        } else {
            require(_makerPairs.length > 1, 'Required 1 pair');
            for (uint256 i = 0; i < _makerPairs.length; i++) {
                if (_makerPairs[i] == _pair) {
                    _makerPairs[i] = _makerPairs[_makerPairs.length - 1];
                    _makerPairs.pop();
                    break;
                }
            }
        }

        emit SetAutomatedMarketMakerPair(_pair, _value);
    }

    function setInitialDistributionFinished(bool _value) external onlyOwner {
        initialDistributionFinished = _value;

        emit SetInitialDistribution(_value);
    }

    function setInvestRemovalDelay(uint256 _value) external onlyOwner {
        require(_value < MAX_INVEST_REMOVABLE_DELAY, 'over 2 hours');
        investRemovalDelay = _value;

        emit SetInvestRemovalDelay(_value);
    }

    function setMaxInvestRemovablePerPeriod(uint256 _value) external onlyOwner {
        require(_value > MIN_INVEST_REMOVABLE_PER_PERIOD, 'Below minimum');
        maxInvestRemovablePerPeriod = _value;

        emit SetMaxInvestRemovablePerPeriod(_value);
    }

    function setSellHourlyLimit(bool _value) external onlyOwner {
        isSellHourlyLimit = _value;

        emit SetHourlyLimit(_value);
    }

    function setPartyListDivisor(uint256 _value) external onlyOwner {
        require(_value <= MAX_PARTY_LIST_DIVISOR_RATE, 'max party');
        partyListDivisor = _value;

        emit SetPartyListDivisor(_value);
    }

    function setMoveBalance(bool _value) external onlyOwner {
        isMoveBalance = _value;

        emit SetMoveBalance(_value);
    }

    function setFeeTypeExempt(address _addr, bool _value, uint256 _type) external onlyOwner {
        if (_type == 1) {
            require(_isTotalFeeExempt[_addr] != _value, 'Not changed');
            _isTotalFeeExempt[_addr] = _value;
            emit SetTotalFeeExempt(_addr, _value);

        } else if (_type == 2) {
            require(_isBuyFeeExempt[_addr] != _value, 'Not changed');
            _isBuyFeeExempt[_addr] = _value;
            emit SetBuyFeeExempt(_addr, _value);

        } else if (_type == 3) {
            require(_isSellFeeExempt[_addr] != _value, 'Not changed');
            _isSellFeeExempt[_addr] = _value;
            emit SetSellFeeExempt(_addr, _value);

        }
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _num,
        uint256 _denom
    ) external onlyOwner {
        swapEnabled = _enabled;
        gonSwapThreshold = TOTAL_GONS.mul(_num).div(_denom);
        emit SetSwapBackSettings(_enabled, _num, _denom);
    }

    function setFeeReceivers(
        address _liquidityReceiver,
        address _treasuryReceiver,
        address _riskFreeValueReceiver,
        address _galaxyBondReceiver
    ) external onlyOwner {
        liquidityReceiver = _liquidityReceiver;
        treasuryReceiver = _treasuryReceiver;
        riskFreeValueReceiver = _riskFreeValueReceiver;
        galaxyBondReceiver = _galaxyBondReceiver;
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _riskFreeValueFee,
        uint256 _treasuryFee,
        uint256 _burnFee,
        uint256 _buyGalaxyBondFee,
        uint256 _sellFeeTreasuryAdded,
        uint256 _sellFeeRFVAdded,
        uint256 _sellBurnFee,
        uint256 _sellGalaxyBond,
        uint256 _realFeePartyArray,
        bool _isTaxBracketEnabledInMoveFee
    ) external onlyOwner {
        liquidityFee = _liquidityFee;
        riskFreeValueFee = _riskFreeValueFee;
        treasuryFee = _treasuryFee;
        sellFeeTreasuryAdded = _sellFeeTreasuryAdded;
        sellFeeRFVAdded = _sellFeeRFVAdded;
        buyGalaxyBondFee = _buyGalaxyBondFee;
        burnFee = _burnFee;
        sellBurnFee = _sellBurnFee;
        sellGalaxyBond = _sellGalaxyBond;
        realFeePartyArray = _realFeePartyArray;

        totalBuyFee = liquidityFee
        .add(treasuryFee)
        .add(riskFreeValueFee)
        .add(burnFee)
        .add(buyGalaxyBondFee);

        uint256 maxTotalBuyFee = liquidityFee
        .add(treasuryFee)
        .add(burnFee)
        .add(buyGalaxyBondFee)
        .add(riskFreeValueFee);

        uint256 maxTotalSellFee = maxTotalBuyFee
        .add(sellFeeTreasuryAdded)
        .add(sellFeeRFVAdded)
        .add(sellBurnFee)
        .add(sellGalaxyBond);

        require(maxTotalBuyFee < MAX_TOTAL_BUY_FEE_RATE, 'max buy fees');

        require(maxTotalSellFee < MAX_TOTAL_SELL_FEE_RATE, 'max sell fees');

        require(realFeePartyArray < MAX_PARTY_ARRAY, 'max party fees');

        setSellFee(
            totalBuyFee
            .add(sellFeeTreasuryAdded)
            .add(sellFeeRFVAdded)
            .add(sellBurnFee)
            .add(sellGalaxyBond)
        );

        isTaxBracketEnabledInMoveFee = _isTaxBracketEnabledInMoveFee;

        emit SetFees(
            _liquidityFee,
            _riskFreeValueFee,
            _treasuryFee,
            _sellFeeTreasuryAdded,
            _sellFeeRFVAdded,
            _burnFee,
            sellBurnFee,
            totalBuyFee,
            _isTaxBracketEnabledInMoveFee
        );
    }

    function setSellFee(uint256 _sellFee) internal {
        totalSellFee = _sellFee;
    }

    function setPartyTime(bool _value) external onlyOwner {
        partyTime = _value;
        emit SetPartyTime(_value, block.timestamp);
    }

    function setTaxBracketFeeMultiplier(uint256 _taxBracketFeeMultiplier)
    external
    onlyOwner
    {
        require(
            _taxBracketFeeMultiplier <= MAX_TAX_BRACKET_FEE_RATE,
            'max bracket fee exceeded'
        );
        taxBracketMultiplier = _taxBracketFeeMultiplier;
        emit SetTaxBracketFeeMultiplier(
            _taxBracketFeeMultiplier,
            block.timestamp
        );
    }

    function clearStuckBalance(address _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
        emit ClearStuckBalance(balance, _receiver, block.timestamp);
    }

    function rescueToken(address tokenAddress)
    external
    onlyOwner
    returns (bool success)
    {
        uint256 tokens = ERC20Detailed(tokenAddress).balanceOf(address(this));
        emit RescueToken(tokenAddress, msg.sender, tokens, block.timestamp);
        return ERC20Detailed(tokenAddress).transfer(msg.sender, tokens);
    }

    function setAutoRebase(bool _autoRebase) external onlyOwner {
        autoRebase = _autoRebase;
        emit SetAutoRebase(_autoRebase, block.timestamp);
    }

    //enable burn fee if necessary
    function setTaxBracket(bool _isTaxBracketEnabled) external onlyOwner {
        isTaxBracket = _isTaxBracketEnabled;
        emit SetTaxBracket(_isTaxBracketEnabled, block.timestamp);
    }

    //set rebase frequency
    function setRebaseFrequency(uint256 _rebaseFrequency) external onlyOwner {
        require(_rebaseFrequency <= MAX_REBASE_FREQUENCY, 'Too high');
        rebaseFrequency = _rebaseFrequency;
        emit SetRebaseFrequency(_rebaseFrequency, block.timestamp);
    }

    //set reward yield
    function setRewardYield(
        uint256 _rewardYield,
        uint256 _rewardYieldDenominator
    ) external {
        require(canSetRewardYield[msg.sender], 'Not allowed for reward yield');
        rewardYield = _rewardYield;
        REWARD_YIELD_DENOMINATOR = _rewardYieldDenominator;
        emit SetRewardYield(
            _rewardYield,
            _rewardYieldDenominator,
            block.timestamp,
            msg.sender
        );
    }

    //set swap threshold
    function setSwapThreshold(uint256 _value) external onlyOwner {
        swapThreshold = _value;
    }

    //enable fees on normal transfer
    function setFeesOnNormalTransfers(bool _enabled) external onlyOwner {
        feesOnNormalTransfers = _enabled;
    }

    //set next rebase time
    function setNextRebase(uint256 _nextRebase) external onlyOwner {
        require(_nextRebase > block.timestamp, 'can not be in past');
        nextRebase = _nextRebase;
        emit SetNextRebase(_nextRebase, block.timestamp);
    }

    function setIsLiquidityEnabled(bool _value) external onlyOwner {
        isLiquidityEnabled = _value;
    }

    function setMaxTransactionAmount(uint256 _maxSellTxn, uint256 _maxBuyTxn) external onlyOwner {
        require(_maxSellTxn > MIN_SELL_AMOUNT_RATE, 'Below minimum sell amount');
        require(_maxBuyTxn > MIN_BUY_AMOUNT_RATE, 'Below minimum buy amount');
        maxSellTransactionAmount = _maxSellTxn;
        maxBuyTransactionAmount = _maxBuyTxn;
        emit SetMaxTransactionAmount(_maxSellTxn, _maxBuyTxn, block.timestamp);
    }

    function setWallDivisor(uint256 _wallDivisor, uint256 _wallMultiplier, bool _isWall) external onlyOwner {
        wallDivisor = _wallDivisor;
        wallMultiplier = _wallMultiplier;
        isWall = _isWall;
        emit SetWallDivisor(_wallDivisor, _wallMultiplier, _isWall);
    }

    event SwapBack(
        uint256 contractTokenBalance,
        uint256 amountToLiquify,
        uint256 amountToRFV,
        uint256 amountToTreasury,
        uint256 amountToGalaxyBond
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 MATICReceived,
        uint256 tokensIntoLiqudity
    );

    event SetFeeReceivers(
        address indexed _liquidityReceiver,
        address indexed _treasuryReceiver,
        address indexed _riskFreeValueReceiver,
        address _galaxyBondReceiver
    );

    event SetPartyTime(bool indexed state, uint256 indexed time);

    event SetTaxBracketFeeMultiplier(
        uint256 indexed state,
        uint256 indexed time
    );

    event ClearStuckBalance(
        uint256 indexed amount,
        address indexed receiver,
        uint256 indexed time
    );

    event RescueToken(
        address indexed tokenAddress,
        address indexed sender,
        uint256 indexed tokens,
        uint256 time
    );

    event SetAutoRebase(bool indexed value, uint256 indexed time);

    event SetTaxBracket(bool indexed value, uint256 indexed time);

    event SetRebaseFrequency(uint256 indexed frequency, uint256 indexed time);

    event SetRewardYield(
        uint256 indexed rewardYield,
        uint256 indexed frequency,
        uint256 indexed time,
        address setter
    );

    event SetFeesOnNormalTransfers(bool indexed value, uint256 indexed time);

    event SetNextRebase(uint256 indexed value, uint256 indexed time);

    event SetMaxTransactionAmount(uint256 indexed sell, uint256 indexed buy, uint256 indexed time);

    event SetWallDivisor(
        uint256 indexed _wallDivisor,
        uint256 indexed _wallMultiplier,
        bool indexed _isWall
    );

    event SetSwapBackSettings(
        bool indexed enabled,
        uint256 indexed num,
        uint256 indexed denum
    );


    event SetFees(
        uint256 indexed _liquidityFee,
        uint256 indexed _riskFreeValue,
        uint256 indexed _treasuryFee,
        uint256 _sellFeeTreasuryAdded,
        uint256 _sellFeeRFVAdded,
        uint256 _burnFee,
        uint256 sellBurnFee,
        uint256 totalBuyFee,
        bool _isTaxBracketEnabledInMoveFee
    );

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event LogManualRebase(int256 supplyDelta, uint256 timeStamp);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SetInitialDistribution(bool indexed value);
    event SetInvestRemovalDelay(uint256 indexed value);
    event SetMaxInvestRemovablePerPeriod(uint256 indexed value);
    event SetMoveBalance(bool indexed value);
    event SetIsLiquidityEnabled(bool indexed value);
    event SetPartyListDivisor(uint256 indexed value);
    event SetHourlyLimit(bool indexed value);
    event SetSwapThreshold(uint256 indexed value);
    event SetTotalFeeExempt(address indexed addy, bool indexed value);
    event SetBuyFeeExempt(address indexed addy, bool indexed value);
    event SetSellFeeExempt(address indexed addy, bool indexed value);
    event SetRebaseWhitelist(address indexed addy, bool indexed value, uint256 indexed _type);
    event SetSubContracts(address indexed pair, bool indexed value);
    event SetPartyAddresses(address indexed pair, bool indexed value);
    event SetSphereGamesAddresses(address indexed pair, bool indexed value);
    event GenericErrorEvent(string reason);
    event SetRouter(address indexed _address);
    event MoveBalance(address from, address to);
}