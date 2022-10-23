/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

// File: contracts/InterfaceLP.sol

pragma solidity ^0.7.4;


interface InterfaceLP {
    function sync() external;
}

// File: contracts/SafeMathInt.sol

pragma solidity ^0.7.4;


library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

// File: contracts/SafeMath.sol

pragma solidity ^0.7.4;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
        require(b != 0);
        return a % b;
    }
}

// File: contracts/Ownable.sol

pragma solidity ^0.7.4;


contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

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
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/IVVSRouter01.sol

pragma solidity ^0.7.4;


interface IVVSRouter01 {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: contracts/IVVSRouter.sol

pragma solidity ^0.7.4;



interface IVVSRouter is IVVSRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

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

// File: contracts/IVVSFactory.sol

pragma solidity ^0.7.4;


interface IVVSFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: contracts/IERC20.sol

pragma solidity ^0.7.4;


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

// File: contracts/ERC20Detailed.sol

pragma solidity ^0.7.4;



abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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

// File: contracts/Phenix.sol

pragma solidity ^0.7.4;










contract PhenixFinance is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event Rebase(uint256 indexed totalSupply);

    address[] public pairAddresses;
    address public liquidityReceiver;
    address public phenixFundReserveReceiver;
    bool public initialDistributionFinished;

    mapping(address => bool) _allowTransfer;
    mapping(address => bool) _isFeeExempt;

    uint256 private constant FXP_BASE = 1000000;
    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;
    uint256 private constant REBASE_INTERVAL = 86400;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY =
        10 * 10**6 * 10**DECIMALS;

    uint256 public liquidityFee = 2;
    uint256 public phenixVaultFee = 8;
    uint256 public sellFee = 5;
    uint256 public totalFee = liquidityFee.add(phenixVaultFee);
    uint256 public feeDenominator = 100;

    uint256 public lastRebaseTimestamp = block.timestamp;
    uint256 public lastRebaseDelta = 0;
    uint256 public rebasePercentDelta = (18 * FXP_BASE) / 1000;

    bool public rebaseRX3Enabled = true;
    uint256 public rebaseRX3Multiplier = FXP_BASE;
    uint256 public rebaseMaxRX3Multiplier = FXP_BASE + FXP_BASE / 2;
    uint256 public rebaseRX3MultiplierStep = (1 * FXP_BASE) / 1000;

    IVVSRouter public router;
    bool public swapEnabled = true;
    uint256 private gonSwapThreshold = (TOTAL_GONS * 10) / 10000;
    bool inSwap;

    uint256 private constant TOTAL_GONS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) public taxableAddress;
    mapping(address => bool) public authorizedRebaseAddress;

    constructor() ERC20Detailed("Phenix Finance", "PHNX", uint8(DECIMALS)) {
        router = IVVSRouter(0x51aBA405De2b25E5506DeA32A6697F450cEB1a17);

        address _pairAddress = address(
            IVVSFactory(router.factory()).createPair(
                router.WETH(),
                address(this)
            )
        );

        liquidityReceiver = address(msg.sender);
        phenixFundReserveReceiver = address(msg.sender);

        _allowedFragments[address(this)][address(router)] = uint256(-1);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[address(msg.sender)] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        _isFeeExempt[address(phenixFundReserveReceiver)] = true;
        _isFeeExempt[address(this)] = true;
        _isFeeExempt[address(msg.sender)] = true;

        taxableAddress[_pairAddress] = true;
        pairAddresses.push(_pairAddress);
        authorizedRebaseAddress[address(msg.sender)] = true;

        emit Transfer(address(0x0), address(msg.sender), _totalSupply);
    }

    /**
     * @dev Swapping switch used to mitigate any calculation
     * issues during swapBack.
     */
    modifier noReentrancy() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier initialDistributionLock() {
        require(
            initialDistributionFinished ||
                isOwner() ||
                _allowTransfer[msg.sender],
            "Initial distirbution not finalized."
        );
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    /**
     * @dev Returns the delta of the next rebase.
     * @return next rebase delta as uint256 value.
     */
    function getNextRebase(uint256 _timestamp) public view returns (uint256) {
        uint256 rebaseTimestampDelta = _timestamp - lastRebaseTimestamp;

        uint256 nextScaledRebaseIntervalPercentage = rebaseTimestampDelta
            .mul(FXP_BASE)
            .div(REBASE_INTERVAL);

        uint256 nextRebaseDelta = _totalSupply
            .mul(rebasePercentDelta)
            .div(FXP_BASE)
            .mul(nextScaledRebaseIntervalPercentage)
            .div(FXP_BASE);

        if (rebaseRX3Enabled == true) {
            nextRebaseDelta = nextRebaseDelta
                .mul(
                    rebaseRX3Multiplier < rebaseMaxRX3Multiplier
                        ? rebaseRX3Multiplier
                        : rebaseMaxRX3Multiplier
                )
                .div(FXP_BASE);
        }

        return nextRebaseDelta;
    }

    /**
     * @dev Rebases total token supply based on the getNextRebase()
     * return result. Rebase is capped when MAX_SUPPLY is reached.
     */
    function _rebase() internal {
        uint256 supplyDelta = getNextRebase(block.timestamp);
        _totalSupply = _totalSupply.add(uint256(supplyDelta));

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        lastRebaseDelta = supplyDelta;
        lastRebaseTimestamp = block.timestamp;
        rebaseRX3Multiplier = FXP_BASE;

        emit Rebase(_totalSupply);
    }

    /**
     * @dev Executes the internal _rebase() function and then
     * performs the sync() call on all applicable pairAddresses
     */
    function rebaseAndSync() external {
        require(
            authorizedRebaseAddress[msg.sender] == true,
            "Not authroized to execute rebase"
        );

        _rebase();

        for (uint256 i = 0; i < pairAddresses.length; i++) {
            if (taxableAddress[pairAddresses[i]] == true) {
                InterfaceLP(pairAddresses[i]).sync();
            }
        }
    }

    /**
     * @dev Returns total token supply. Overrides ERC-20
     * totalSupply() function to return elastic supply.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Transfers amount tokens to an address.
     * @param to Receiver of the transfered tokens.
     * @param value Amount of tokens that are received.
     * @return true
     */
    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        initialDistributionLock
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Adds LP contract address and removes
     * fees from the given address. Added pair contract tested
     * sync() before adding to see if it is a pair address.
     * Addition will fail if sync() fails.
     * @param _address Update LP contract address.
     */
    function addLPAddress(address _address) external onlyOwner {
        InterfaceLP(_address).sync();

        for (uint256 i = 0; i < pairAddresses.length; i++) {
            require(pairAddresses[i] != _address, "Pair address already added");
        }

        pairAddresses.push(_address);
        taxableAddress[_address] = true;
    }

    /**
     * @dev Returns array of all LP Addresses
     * @return address[] Array of LP Addresses.
     **/
    function getLPAddresses() external view returns (address[] memory) {
        return pairAddresses;
    }

    /**
     * @dev Updates given address' taxable status.
     * @param _address Subject address of taxable state adjustment.
     * @param _status State if address should be taxed.
     */
    function setTaxableAddress(address _address, bool _status)
        external
        onlyOwner
    {
        taxableAddress[_address] = _status;
    }

    /**
     * @dev Updates given address' Authorized Rebase status.
     * @param _address Subject address of Authorized Rebase state adjustment.
     * @param _status State if address should be allowed call rebaseAndSync().
     */
    function setAuthorizedRebaseAddress(address _address, bool _status)
        external
        onlyOwner
    {
        authorizedRebaseAddress[_address] = _status;
    }

    /**
     * @dev Returns spender alloance of an owner address.
     * Overides ERC-20 allowance(address, address) function
     * to return allowed fragments.
     * @param owner Owner address of tokens.
     * @param spender Spender address of tokens.
     * @return uint256 Amount of allowed tokens for the spender to use.
     */
    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner][spender];
    }

    /**
     * @dev Returns balance of given address. Overrides
     * ERC-20 balanceOf(address) to provide balance based
     * on holder gons and gonsPerFragment.
     * @param who Balance of address.
     * @return uint256 value of address balance.
     */
    function balanceOf(address who) external view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    /**
     * @dev Performs basic token transfer. Used as
     * internal function in _transferFrom(address,
     * address, uint256) function.
     * @param from sender address of transfer.
     * @param to receiver adddress of transfer.
     * @param amount amount of tokens for receiver.
     * @return true.
     */
    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        return true;
    }

    /**
     * @dev Transfers token from sender address
     * to receiver address. Performs token supply
     * rebase provided it is acceptable. Executes
     * _baseTransfer(address, address, uint256) if
     * swap is in progress.
     * @param sender sender address of transfer.
     * @param to receiver adddress of transfer.
     * @param amount amount of tokens for receiver.
     * @return true.
     */
    function _transferFrom(
        address sender,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, to, amount);
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);

        if (_shouldSwapBack()) {
            _swapBack();
        }

        if (rebaseRX3Enabled == true) {
            rebaseRX3Multiplier = rebaseRX3Multiplier.add(
                rebaseRX3MultiplierStep
            );
        }

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);

        uint256 gonAmountReceived = _shouldTakeFee(sender, to)
            ? _takeFee(sender, to, gonAmount)
            : gonAmount;
        _gonBalances[to] = _gonBalances[to].add(gonAmountReceived);

        emit Transfer(sender, to, gonAmountReceived.div(_gonsPerFragment));

        return true;
    }

    /**
     * @dev Transfers token from sender address
     * to receiver address. Overrides ERC-20
     * transferFrom(address, address, uint256) to
     * check value of allowed fragments that sender
     * can access from the owner (from address).
     * @param from sender address of transfer.
     * @param to receiver adddress of transfer.
     * @param value amount of tokens for receiver.
     * @return true.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != uint256(-1)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }

        _transferFrom(from, to, value);
        return true;
    }

    /**
     * @dev Executes fee allocations and distributes tokens
     * to contract address, phenix vault receiver address, and
     * liquidity receiver address.
     */
    function _swapBack() internal noReentrancy {
        uint256 contractTokenBalance = _gonBalances[address(this)].div(
            _gonsPerFragment
        );
        uint256 amountToLiquify = contractTokenBalance
            .mul(liquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));

        uint256 amountETHLiquidity = amountETH
            .mul(liquidityFee)
            .div(totalETHFee)
            .div(2);

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityReceiver,
                block.timestamp
            );
        }

        (bool success, ) = payable(phenixFundReserveReceiver).call{
            value: address(this).balance
        }("");
    }

    /**
     * @dev Calculates swap fee and returns new allocation
     * of swap based on swap conditions. Calculate is based
     * on liquidity fee and phenix vault fee. Sell fee will also
     * be taken into consideration if receiver is pair address.
     * @return uint256 gonAmount that is transfered in the swap.
     */
    function _takeFee(
        address sender,
        address to,
        uint256 gonAmount
    ) internal returns (uint256) {
        uint256 _totalFee = totalFee;
        if (taxableAddress[to] == true) _totalFee = _totalFee.add(sellFee);

        uint256 feeAmount = gonAmount.mul(_totalFee).div(feeDenominator);

        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            feeAmount
        );
        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));

        return gonAmount.sub(feeAmount);
    }

    /**
     * @dev Decreases spender allowance of sender address.
     * @param spender Spender address.
     * @param subtractedValue Amount to reduce spender allowance by.
     * @return bool
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        initialDistributionLock
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

    /**
     * @dev Updates router address
     * @param _address address to set for the dex router
     */
    function updateRouter(address _address) external onlyOwner {
        require(address(router) != _address, "Router address already set");
        router = IVVSRouter(_address);
    }

    /**
     * @dev Increases spender allowance of sender address.
     * @param spender Spender address.
     * @param addedValue Amount to increase spender allowance by.
     * @return bool
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        initialDistributionLock
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

    /**
     * @dev Approves spender address to use sender tokens.
     * @param spender Spender address.
     * @param value Amount of tokens spender can access.
     * @return bool
     */
    function approve(address spender, uint256 value)
        external
        override
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Checks if given address is exempt from swap fees.
     * @param _addr Address to check current exemption status.
     * @return bool
     */
    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    /**
     * @dev Unlocks tokens and sets initialDistributedFinished
     * to true. Only callable from owner address.
     */
    function setInitialDistributionFinished() external onlyOwner {
        initialDistributionFinished = true;
    }

    /**
     * @dev Enables transfers for a specific address.
     * Only callable from owner address.
     * @param _addr Address to enable transfers.
     */
    function enableTransfer(address _addr) external onlyOwner {
        _allowTransfer[_addr] = true;
    }

    /**
     * @dev Sets given address to have exceptions from
     * swap fees. Only callable from owner address.
     * @param _addr Address to set fee exemptions.
     */
    function setFeeExempt(address _addr) external onlyOwner {
        _isFeeExempt[_addr] = true;
    }

    /**
     * @dev Checks if a sender (from) and receiver
     * (to) need swap fees applied in transfer. Used
     * in _transferFrom(address, address, uint256) internal
     * function. Should only apply when user is interacting with
     * the pair (to or from)
     * @param from Sender address of swap
     * @param to Receiver address of swap.
     * @return bool True if fees apply on transfer.
     */
    function _shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        return
            (taxableAddress[from] || taxableAddress[to]) &&
            (!_isFeeExempt[from] && !_isFeeExempt[to]);
    }

    /**
     * @dev Updates swap back settings.
     * @param _enabled bool value to determine of swap back is enabled.
     * @param _num uint256 value for the swap back threshhold
     * @param _denom uint256 value used for the threshold deminator
     */
    function setSwapBackSettings(
        bool _enabled,
        uint256 _num,
        uint256 _denom
    ) external onlyOwner {
        swapEnabled = _enabled;
        gonSwapThreshold = TOTAL_GONS.div(_denom).mul(_num);
    }

    /**
     * @dev Updates RX3 Rebase settings.
     * @param _enabled bool value to determine of RX3 Protocol is enabled.
     * @param _rebaseMaxRX3Multiplier uint256 value for the max RX3 Multiplier
     * @param _rebaseRX3MultiplierStep uint256 value used for the RX3 Multiplier Step
     */
    function setRX3Settings(
        bool _enabled,
        uint256 _rebaseMaxRX3Multiplier,
        uint256 _rebaseRX3MultiplierStep
    ) external onlyOwner {
        rebaseRX3Enabled = _enabled;
        rebaseMaxRX3Multiplier = _rebaseMaxRX3Multiplier;
        rebaseRX3MultiplierStep = _rebaseRX3MultiplierStep;
    }

    /**
     * @dev Configures Rebase settings. Sets
     * RebasePercentDelta, and Accuracy.
     * @param _percentage value of rebase percent delta based on a daily interval (18)
     * @param _accuracy defines the value of the rebase delta percentage demoninator (1000)
     */
    function setRebaseSettings(uint256 _percentage, uint256 _accuracy)
        external
        onlyOwner
    {
        rebasePercentDelta = (_percentage * FXP_BASE) / _accuracy;
    }

    /**
     * @dev Check whether the a swap back can be performed.
     * @return bool, true if swapBack is allowed to execute.
     */
    function _shouldSwapBack() internal view returns (bool) {
        return
            taxableAddress[msg.sender] == false &&
            !inSwap &&
            swapEnabled &&
            _gonBalances[address(this)] >= gonSwapThreshold;
    }

    /**
     * @dev Returns current circulating token supply
     * @return uint256, value of total circulating supply.
     */
    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(
                _gonsPerFragment
            );
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold.div(_gonsPerFragment);
    }

    function setFeeReceivers(
        address _liquidityReceiver,
        address _phenixFundReserveReceiver
    ) external onlyOwner {
        liquidityReceiver = _liquidityReceiver;
        phenixFundReserveReceiver = _phenixFundReserveReceiver;
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _phenixVaultFee,
        uint256 _sellFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        liquidityFee = _liquidityFee;
        phenixVaultFee = _phenixVaultFee;
        sellFee = _sellFee;
        totalFee = liquidityFee.add(phenixVaultFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4);
    }

    function emergencyRecoverETH() external onlyOwner {
        require(address(this).balance > 0, "No ETH to recover.");
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Failed to recover ETH.");
    }

    function emergencyRecoverToken(address _tokenAddress) external onlyOwner {
        require(
            IERC20(_tokenAddress).balanceOf(address(this)) > 0,
            "No tokens to recover."
        );
        IERC20(_tokenAddress).transfer(
            msg.sender,
            IERC20(_tokenAddress).balanceOf(address(this))
        );
    }

    receive() external payable {}
}