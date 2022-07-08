/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

// File: IPoolToken.sol

pragma solidity >=0.5.0;







interface IPoolTokenERC20 {

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



    // solhint-disable-next-line func-name-mixedcase

    function DOMAIN_SEPARATOR() external view returns (bytes32);



    // solhint-disable-next-line func-name-mixedcase

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

}


// File: SafeMath.sol

pragma solidity >=0.5.16;







/**

 * @dev Wrappers over Solidity's arithmetic operations with added overflow

 * checks.

 *

 * Arithmetic operations in Solidity wrap on overflow. This can easily result

 * in bugs, because programmers usually assume that an overflow raises an

 * error, which is the standard behavior in high level programming languages.

 * `SafeMath` restores this intuition by reverting the transaction when an

 * operation overflows.

 *

 * Using this library instead of the unchecked operations eliminates an entire

 * class of bugs, so it's recommended to use it always.

 */

library SafeMath {

    /**

     * @dev Returns the addition of two unsigned integers, reverting on

     * overflow.

     *

     * Counterpart to Solidity's `+` operator.

     *

     * Requirements:

     * - Addition cannot overflow.

     */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a + b;

        require(c >= a, "SafeMath: addition overflow");



        return c;

    }



    /**

     * @dev Returns the subtraction of two unsigned integers, reverting on

     * overflow (when the result is negative).

     *

     * Counterpart to Solidity's `-` operator.

     *

     * Requirements:

     * - Subtraction cannot overflow.

     */

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        return sub(a, b, "SafeMath: subtraction overflow");

    }



    /**

     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on

     * overflow (when the result is negative).

     *

     * Counterpart to Solidity's `-` operator.

     *

     * Requirements:

     * - Subtraction cannot overflow.

     */

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b <= a, errorMessage);

        uint256 c = a - b;



        return c;

    }



    /**

     * @dev Returns the multiplication of two unsigned integers, reverting on

     * overflow.

     *

     * Counterpart to Solidity's `*` operator.

     *

     * Requirements:

     * - Multiplication cannot overflow.

     */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

        // benefit is lost if 'b' is also tested.

        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522

        if (a == 0) {

            return 0;

        }



        uint256 c = a * b;

        require(c / a == b, "SafeMath: multiplication overflow");



        return c;

    }



    /**

     * @dev Returns the integer division of two unsigned integers. Reverts on

     * division by zero. The result is rounded towards zero.

     *

     * Counterpart to Solidity's `/` operator. Note: this function uses a

     * `revert` opcode (which leaves remaining gas untouched) while Solidity

     * uses an invalid opcode to revert (consuming all remaining gas).

     *

     * Requirements:

     * - The divisor cannot be zero.

     */

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        return div(a, b, "SafeMath: division by zero");

    }



    /**

     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on

     * division by zero. The result is rounded towards zero.

     *

     * Counterpart to Solidity's `/` operator. Note: this function uses a

     * `revert` opcode (which leaves remaining gas untouched) while Solidity

     * uses an invalid opcode to revert (consuming all remaining gas).

     *

     * Requirements:

     * - The divisor cannot be zero.

     */

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        // Solidity only automatically asserts when dividing by 0

        require(b > 0, errorMessage);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold



        return c;

    }



    /**

     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),

     * Reverts when dividing by zero.

     *

     * Counterpart to Solidity's `%` operator. This function uses a `revert`

     * opcode (which leaves remaining gas untouched) while Solidity uses an

     * invalid opcode to revert (consuming all remaining gas).

     *

     * Requirements:

     * - The divisor cannot be zero.

     */

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {

        return mod(a, b, "SafeMath: modulo by zero");

    }



    /**

     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),

     * Reverts with custom message when dividing by zero.

     *

     * Counterpart to Solidity's `%` operator. This function uses a `revert`

     * opcode (which leaves remaining gas untouched) while Solidity uses an

     * invalid opcode to revert (consuming all remaining gas).

     *

     * Requirements:

     * - The divisor cannot be zero.

     */

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b != 0, errorMessage);

        return a % b;

    }

}
// File: PoolToken.sol

pragma solidity ^0.7.4;







contract PoolTokenERC20 is IPoolTokenERC20 {

    using SafeMath for uint256;



    /* solhint-disable const-name-snakecase */

    string public constant override name = "Black & White";

    string public constant override symbol = "BWLT";

    uint8 public constant override decimals = 18;

    /* solhint-enable const-name-snakecase */

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;



    // solhint-disable-next-line var-name-mixedcase

    bytes32 public override DOMAIN_SEPARATOR;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 public constant override PERMIT_TYPEHASH =

        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public override nonces;



    constructor() {

        uint256 chainId;

        assembly {

            chainId := chainid()

        }

        DOMAIN_SEPARATOR = keccak256(

            abi.encode(

                keccak256(

                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"

                ),

                keccak256(bytes(name)),

                keccak256(bytes("1")),

                chainId,

                address(this)

            )

        );

    }



    function _mint(address to, uint256 value) internal {

        totalSupply = totalSupply.add(value);

        balanceOf[to] = balanceOf[to].add(value);

        emit Transfer(address(0), to, value);

    }



    function _burn(address from, uint256 value) internal {

        balanceOf[from] = balanceOf[from].sub(value);

        totalSupply = totalSupply.sub(value);

        emit Transfer(from, address(0), value);

    }



    function _approve(

        address owner,

        address spender,

        uint256 value

    ) private {

        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);

    }



    function _transfer(

        address from,

        address to,

        uint256 value

    ) private {

        balanceOf[from] = balanceOf[from].sub(value);

        balanceOf[to] = balanceOf[to].add(value);

        emit Transfer(from, to, value);

    }



    function approve(address spender, uint256 value)

        external

        override

        returns (bool)

    {

        _approve(msg.sender, spender, value);

        return true;

    }



    function transfer(address to, uint256 value)

        external

        override

        returns (bool)

    {

        _transfer(msg.sender, to, value);

        return true;

    }



    function transferFrom(

        address from,

        address to,

        uint256 value

    ) external override returns (bool) {

        if (allowance[from][msg.sender] != uint256(-1)) {

            allowance[from][msg.sender] = allowance[from][msg.sender].sub(

                value

            );

        }

        _transfer(from, to, value);

        return true;

    }



    function permit(

        address owner,

        address spender,

        uint256 value,

        uint256 deadline,

        uint8 v,

        bytes32 r,

        bytes32 s

    ) external override {

        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");

        bytes32 digest = keccak256(

            abi.encodePacked(

                "\x19\x01",

                DOMAIN_SEPARATOR,

                keccak256(

                    abi.encode(

                        PERMIT_TYPEHASH,

                        owner,

                        spender,

                        value,

                        nonces[owner]++,

                        deadline

                    )

                )

            )

        );

        address recoveredAddress = ecrecover(digest, v, r, s);

        require(

            recoveredAddress != address(0) && recoveredAddress == owner,

            "UniswapV2: INVALID_SIGNATURE"

        );

        _approve(owner, spender, value);

    }

}


// File: DSMath.sol



// See <http://www.gnu.org/licenses/>



pragma solidity >0.4.13;



contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {

        require((z = x + y) >= x, "ds-math-add-overflow");

    }

    function sub(uint x, uint y) internal pure returns (uint z) {

        require((z = x - y) <= x, "ds-math-sub-underflow");

    }

    function mul(uint x, uint y) internal pure returns (uint z) {

        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");

    }



    function min(uint x, uint y) internal pure returns (uint z) {

        return x <= y ? x : y;

    }

    function max(uint x, uint y) internal pure returns (uint z) {

        return x >= y ? x : y;

    }

    function imin(int x, int y) internal pure returns (int z) {

        return x <= y ? x : y;

    }

    function imax(int x, int y) internal pure returns (int z) {

        return x >= y ? x : y;

    }



    uint constant WAD = 10 ** 18;

    uint constant RAY = 10 ** 27;



    //rounds to zero if x*y < WAD / 2

    function wmul(uint x, uint y) internal pure returns (uint z) {

        z = add(mul(x, y), WAD / 2) / WAD;

    }

    //rounds to zero if x*y < WAD / 2

    function rmul(uint x, uint y) internal pure returns (uint z) {

        z = add(mul(x, y), RAY / 2) / RAY;

    }

    //rounds to zero if x*y < WAD / 2

    function wdiv(uint x, uint y) internal pure returns (uint z) {

        z = add(mul(x, WAD), y / 2) / y;

    }

    //rounds to zero if x*y < RAY / 2

    function rdiv(uint x, uint y) internal pure returns (uint z) {

        z = add(mul(x, RAY), y / 2) / y;

    }



    // This famous algorithm is called "exponentiation by squaring"

    // and calculates x^n with x as fixed-point and n as regular unsigned.

    //

    // It's O(log n), instead of O(n) for naive repeated multiplication.

    //

    // These facts are why it works:

    //

    //  If n is even, then x^n = (x^2)^(n/2).

    //  If n is odd,  then x^n = x * x^(n-1),

    //   and applying the equation for even x gives

    //    x^n = x * (x^2)^((n-1) / 2).

    //

    //  Also, EVM division is flooring and

    //    floor[(n-1) / 2] = floor[n / 2].

    //

    function rpow(uint x, uint n) internal pure returns (uint z) {

        z = n % 2 != 0 ? x : RAY;



        for (n /= 2; n != 0; n /= 2) {

            x = rmul(x, x);



            if (n % 2 != 0) {

                z = rmul(z, x);

            }

        }

    }

}


// File: iPredictionCollateralization.sol

pragma solidity ^0.7.4;







// solhint-disable-next-line contract-name-camelcase

interface iPredictionCollateralization {

    function buySeparately(

        address destination,

        uint256 tokensAmount,

        address tokenAddress,

        uint256 payment,

        address paymentTokenAddress

    ) external;



    function buyBackSeparately(

        address destination,

        uint256 tokensAmount,

        address tokenAddress,

        uint256 payment

    ) external;



    function withdrawCollateral(address destination, uint256 tokensAmount)

        external;



    function changePoolAddress(address poolAddress) external;



    function changeGovernanceAddress(address governanceAddress) external;



    function getCollateralization() external view returns (uint256);



    function whiteToken() external returns (address);



    function blackToken() external returns (address);

}


// File: Eventable.sol

pragma solidity ^0.7.4;







interface Eventable {

    function submitEventStarted(uint256 currentEventPriceChangePercent)

        external;



    function submitEventResult(int8 _result) external;

}


// File: Common/IERC20.sol

pragma solidity ^0.7.4;





interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}
// File: PredictionPool.sol

pragma solidity ^0.7.4;











contract PredictionPool is Eventable, DSMath, PoolTokenERC20 {

    using SafeMath for uint256;



    bool public _eventStarted = false;

    bool public _poolShutdown = false;

    bool public _onlyOrderer = false;



    address public _governanceAddress;

    address public _eventContractAddress;

    address public _governanceWalletAddress;

    address public _ordererAddress;



    /*

    Founders wallets

    */

    address public _controllerWalletAddress;



    event BuyBlack(address user, uint256 amount, uint256 price);

    event BuyWhite(address user, uint256 amount, uint256 price);

    event SellBlack(address user, uint256 amount, uint256 price);

    event SellWhite(address user, uint256 amount, uint256 price);

    event AddLiquidity(

        address user,

        uint256 whitePrice,

        uint256 blackPrice,

        uint256 bwAmount,

        uint256 colaterallAmount

    );

    event WithdrawLiquidity(

        address user,

        uint256 whitePrice,

        uint256 blackPrice,

        uint256 bwAmount,

        uint256 colaterallAmount

    );



    IERC20 public _whiteToken;

    IERC20 public _blackToken;

    IERC20 public _collateralToken;

    iPredictionCollateralization public _thisCollateralization;



    uint256 public _whitePrice; // in 1e18

    uint256 public _blackPrice; // in 1e18



    // solhint-disable-next-line var-name-mixedcase

    uint256 public BW_DECIMALS = 18;



    // in percents (1e18 == 100%)

    uint256 public _currentEventPercentChange;



    // 0.3% (1e18 == 100%)

    uint256 public FEE = 0.003 * 1e18;



    // governance token holders fee of total FEE

    uint256 public _governanceFee = 0.4 * 1e18;



    // controller fee of total FEE

    uint256 public _controllerFee = 0.55 * 1e18;



    // initial pool fee  of total FEE

    uint256 public _bwAdditionFee = 0.05 * 1e18;



    uint256 public _maxFeePart = 0.9 * 1e18;



    /*

    Part which will be sent as governance incentives

    Only not yet distributed fees.

    */

    uint256 public _feeGovernanceCollected;



    /*

    Part which will sent to the team

    Only not yet distributed fees.

    */

    uint256 public _controllerFeeCollected;



    uint256 public _collateralForBlack;

    uint256 public _collateralForWhite;



    uint256 public _blackBought;

    uint256 public _whiteBought;



    uint256 public _whiteBoughtThisCycle;

    uint256 public _blackBoughtThisCycle;

    uint256 public _whiteSoldThisCycle;

    uint256 public _blackSoldThisCycle;



    // Minimum amount of tokens pool should hold after initial actions.

    uint256 public constant MIN_HOLD = 2 * 1e18;



    bool public inited;



    constructor(

        address thisCollateralizationAddress,

        address collateralTokenAddress,

        address whiteTokenAddress,

        address blackTokenAddress,

        uint256 whitePrice,

        uint256 blackPrice

    ) {

        require(

            whiteTokenAddress != address(0),

            "WHITE token address should not be null"

        );

        require(

            blackTokenAddress != address(0),

            "BLACK token address should not be null"

        );



        _thisCollateralization = iPredictionCollateralization(

            thisCollateralizationAddress

        );

        _collateralToken = IERC20(collateralTokenAddress);



        _whiteToken = IERC20(whiteTokenAddress);



        _blackToken = IERC20(blackTokenAddress);



        _governanceAddress = msg.sender;



        _whitePrice = whitePrice;

        _blackPrice = blackPrice;



        _collateralToken.approve(

            address(thisCollateralizationAddress),

            type(uint256).max

        );



        _whiteToken.approve(

            address(thisCollateralizationAddress),

            type(uint256).max

        );



        _blackToken.approve(

            address(thisCollateralizationAddress),

            type(uint256).max

        );

    }



    function init(

        address governanceWalletAddress,

        address eventContractAddress,

        address controllerWalletAddress,

        address ordererAddress,

        bool onlyOrderer

    ) external onlyGovernance {

        require(!inited, "Pool already initiated");

        require(

            controllerWalletAddress != address(0),

            "controllerWalletAddress should not be null"

        );

        require(

            governanceWalletAddress != address(0),

            "governanceWalletAddress should not be null"

        );

        _eventContractAddress = eventContractAddress == address(0)

            ? msg.sender

            : eventContractAddress;



        _governanceWalletAddress = governanceWalletAddress;

        _controllerWalletAddress = controllerWalletAddress;

        _onlyOrderer = onlyOrderer;

        _ordererAddress = ordererAddress;



        inited = true;

    }



    modifier noEvent() {

        require(

            _eventStarted == false,

            "Function cannot be called during ongoing event"

        );

        _;

    }



    modifier onlyGovernance() {

        require(

            _governanceAddress == msg.sender,

            "CALLER SHOULD BE GOVERNANCE"

        );

        _;

    }



    modifier onlyEventContract() {

        require(

            _eventContractAddress == msg.sender,

            "CALLER SHOULD BE EVENT CONTRACT"

        );

        _;

    }



    modifier notPoolShutdown() {

        require(

            _poolShutdown == false,

            "Pool is shutting down. This function does not work"

        );

        _;

    }



    modifier onlyOrdererModifier() {

        if (_onlyOrderer) {

            require(_ordererAddress == msg.sender, "Incorrerct orderer");

        }

        _;

    }



    struct EventEnd {

        uint256 whitePrice;

        uint256 blackPrice;

        uint256 whiteWinVolatility;

        uint256 blackWinVolatility;

        uint256 changePercent;

        uint256 whiteCoefficient;

        uint256 blackCoefficient;

        uint256 totalFundsInSecondaryPool;

        uint256 allWhiteCollateral;

        uint256 allBlackCollateral;

        uint256 spentForWhiteThisCycle;

        uint256 spentForBlackThisCycle;

        uint256 collateralForWhite;

        uint256 collateralForBlack;

        uint256 whiteBought;

        uint256 blackBought;

        uint256 receivedForWhiteThisCycle;

        uint256 receivedForBlackThisCycle;

    }



    event CurrentWhitePrice(uint256 currrentWhitePrice);

    event CurrentBlackPrice(uint256 currentBlackPrice);

    event WhiteBoughtThisCycle(uint256 whiteBoughtThisCycle);

    event BlackBoughtThisCycle(uint256 blackBoughtThisCycle);

    event WhiteSoldThisCycle(uint256 whiteSoldThisCycle);

    event BlackSoldThisCycle(uint256 blackSoldThisCycle);

    event WhiteBought(uint256 whiteBought);

    event BlackBought(uint256 blackBought);

    event ReceivedForWhiteThisCycle(uint256 receivedForWhiteThisCycle);

    event ReceivedForBlackThisCycle(uint256 receivedForBlackThisCycle);

    event SpentForWhiteThisCycle(uint256 spentForWhiteThisCycle);

    event SpentForBlackThisCycle(uint256 spentForBlackThisCycle);

    event AllWhiteCollateral(uint256 allWhiteCollateral);

    event AllBlackCollateral(uint256 allBlackCollateral);

    event TotalFunds(uint256 totalFundsInSecondaryPool);

    event WhiteCefficient(uint256 whiteCoefficient);

    event BlackCefficient(uint256 blackCoefficient);

    event ChangePercent(uint256 changePercent);

    event WhiteWinVolatility(uint256 whiteWinVolatility);

    event BlackWinVolatility(uint256 blackWinVolatility);

    event CollateralForWhite(uint256 collateralForWhite);

    event CollateralForBlack(uint256 collateralForBlack);

    event WhitePrice(uint256 whitePrice);

    event BlackPrice(uint256 blackPrice);

    event SecondaryPoolBWPrice(uint256 secondaryPoolBWPrice);



    /**

     * Receive event results. Receives result of an event in value between -1 and 1. -1 means

     * Black won,1 means white-won.

     */

    function submitEventResult(int8 _result)

        external

        override

        onlyEventContract

    {

        require(

            _result == -1 || _result == 1 || _result == 0,

            "Result has inappropriate value. Should be -1, 0 or 1"

        );



        _eventStarted = false;



        if (_result == 0) {

            return;

        }



        EventEnd memory eend;

        //Cells are cell numbers from SECONDARY POOL FORMULA DOC page



        // Cell 3

        uint256 currentWhitePrice = _whitePrice;

        emit CurrentWhitePrice(currentWhitePrice);



        // Cell 4

        uint256 currentBlackPrice = _blackPrice;

        emit CurrentBlackPrice(currentBlackPrice);



        //Cell 7

        uint256 whiteBoughtThisCycle = _whiteBoughtThisCycle;

        _whiteBoughtThisCycle = 0; // We need to start calculations from zero for the next cycle.

        emit WhiteBoughtThisCycle(whiteBoughtThisCycle);



        //Cell 8

        uint256 blackBoughtThisCycle = _blackBoughtThisCycle;

        _blackBoughtThisCycle = 0; // We need to start calculations from zero for the next cycle.

        emit BlackBoughtThisCycle(blackBoughtThisCycle);



        // Cell 10

        uint256 whiteSoldThisCycle = _whiteSoldThisCycle;

        _whiteSoldThisCycle = 0; // We need to start calculations from zero for the next cycle.

        emit WhiteSoldThisCycle(whiteSoldThisCycle);



        // Cell 11

        uint256 blackSoldThisCycle = _blackSoldThisCycle;

        _blackSoldThisCycle = 0; // We need to start calculations from zero for the next cycle.

        emit BlackSoldThisCycle(blackSoldThisCycle);



        // Cell 13

        eend.whiteBought = _whiteBought;

        emit WhiteBought(eend.whiteBought);

        if (eend.whiteBought == 0) {

            return;

        }



        // Cell 14

        eend.blackBought = _blackBought;

        emit BlackBought(eend.blackBought);

        if (eend.blackBought == 0) {

            return;

        }



        // Cell 16

        eend.receivedForWhiteThisCycle = wmul(

            whiteBoughtThisCycle,

            currentWhitePrice

        );

        emit ReceivedForWhiteThisCycle(eend.receivedForWhiteThisCycle);



        // Cell 17

        eend.receivedForBlackThisCycle = wmul(

            blackBoughtThisCycle,

            currentBlackPrice

        );

        emit ReceivedForBlackThisCycle(eend.receivedForBlackThisCycle);



        // Cell 19

        eend.spentForWhiteThisCycle = wmul(

            whiteSoldThisCycle,

            currentWhitePrice

        );

        emit SpentForWhiteThisCycle(eend.spentForWhiteThisCycle);



        // Cell 20

        eend.spentForBlackThisCycle = wmul(

            blackSoldThisCycle,

            currentBlackPrice

        );

        emit SpentForBlackThisCycle(eend.spentForBlackThisCycle);



        // Cell 22

        eend.allWhiteCollateral = _collateralForWhite;

        emit AllWhiteCollateral(eend.allWhiteCollateral);



        if (eend.allWhiteCollateral == 0) {

            return;

        }



        // Cell 23

        eend.allBlackCollateral = _collateralForBlack;

        emit AllBlackCollateral(eend.allBlackCollateral);



        if (eend.allBlackCollateral == 0) {

            return;

        }



        // Cell 24

        eend.totalFundsInSecondaryPool = eend.allWhiteCollateral.add(

            eend.allBlackCollateral

        );

        emit TotalFunds(eend.totalFundsInSecondaryPool);



        // To exclude division by zero There is a check for a non zero eend.allWhiteCollateral above

        // Cell 26

        eend.whiteCoefficient = wdiv(

            eend.allBlackCollateral,

            eend.allWhiteCollateral

        );

        emit WhiteCefficient(eend.whiteCoefficient);



        // To exclude division by zero There is a check for a non zero eend.allBlackCollateral above

        // Cell 27

        eend.blackCoefficient = wdiv(

            eend.allWhiteCollateral,

            eend.allBlackCollateral

        );

        emit BlackCefficient(eend.blackCoefficient);



        // Cell 29

        eend.changePercent = _currentEventPercentChange;

        emit ChangePercent(eend.changePercent);



        // Cell 30

        eend.whiteWinVolatility = wmul(

            eend.whiteCoefficient,

            eend.changePercent

        );

        emit WhiteWinVolatility(eend.whiteWinVolatility);



        // Cell 31

        eend.blackWinVolatility = wmul(

            eend.blackCoefficient,

            eend.changePercent

        );

        emit BlackWinVolatility(eend.blackWinVolatility);



        // white won

        if (_result == 1) {

            // Cell 33, 43

            eend.collateralForWhite = wmul(

                eend.allWhiteCollateral,

                WAD.add(eend.whiteWinVolatility)

            );

            emit CollateralForWhite(eend.collateralForWhite);



            // Cell 36, 44

            eend.collateralForBlack = wmul(

                eend.allBlackCollateral,

                WAD.sub(eend.changePercent)

            );

            emit CollateralForBlack(eend.collateralForBlack);



            // To exclude division by zero There is a check for a non zero eend.whiteBought above

            // Like Cell 47

            eend.whitePrice = wdiv(eend.collateralForWhite, eend.whiteBought);

            emit WhitePrice(eend.whitePrice);



            // To exclude division by zero There is a check for a non zero eend.blackBought above

            // Like Cell 48

            eend.blackPrice = wdiv(eend.collateralForBlack, eend.blackBought);

            emit BlackPrice(eend.blackPrice);



            // Cell 48

            uint256 secondaryPoolBWPrice = eend.whitePrice.add(eend.blackPrice);

            emit SecondaryPoolBWPrice(secondaryPoolBWPrice);

        }



        // black won

        if (_result == -1) {

            // Cell 34, 43

            eend.collateralForWhite = wmul(

                eend.allWhiteCollateral,

                WAD.sub(eend.changePercent)

            );

            emit CollateralForWhite(eend.collateralForWhite);



            // Cell 35, 44

            eend.collateralForBlack = wmul(

                eend.allBlackCollateral,

                WAD.add(eend.blackWinVolatility)

            );

            emit CollateralForBlack(eend.collateralForBlack);



            // To exclude division by zero There is a check for a non zero eend.whiteBought above

            // Like Cell 47

            eend.whitePrice = wdiv(eend.collateralForWhite, eend.whiteBought);

            emit WhitePrice(eend.whitePrice);



            // To exclude division by zero There is a check for a non zero eend.blackBought above

            // Like Cell 48

            eend.blackPrice = wdiv(eend.collateralForBlack, eend.blackBought);

            emit BlackPrice(eend.blackPrice);



            // Cell 48

            uint256 secondaryPoolBWPrice = eend.whitePrice.add(eend.blackPrice);

            emit SecondaryPoolBWPrice(secondaryPoolBWPrice);

        }



        _whitePrice = eend.whitePrice;

        _blackPrice = eend.blackPrice;



        _collateralForWhite = eend.collateralForWhite;

        _collateralForBlack = eend.collateralForBlack;

    }



    /**

     * @param currentEventPriceChangePercent - from 1% to 40% (with 1e18 math: 1e18 == 100%)

     * */

    function submitEventStarted(uint256 currentEventPriceChangePercent)

        external

        override

        onlyEventContract

    {

        require(

            currentEventPriceChangePercent <= 0.4 * 1e18,

            "Too high event price change percent submitted: no more than 40%"

        );

        require(

            currentEventPriceChangePercent >= 0.01 * 1e18,

            "Too lower event price change percent submitted: at least 1%"

        );



        _currentEventPercentChange = currentEventPriceChangePercent;



        _eventStarted = true;

    }



    function exchangeBW(uint256 tokensAmount, uint8 tokenId)

        external

        noEvent

        notPoolShutdown

        onlyOrdererModifier

    {

        require(tokenId == 0 || tokenId == 1, "TokenId should be 0 or 1");



        IERC20 sellToken;

        IERC20 buyToken;

        uint256 sellPrice;

        uint256 buyPrice;

        address tokenAddress;

        bool isWhite = false;



        if (tokenId == 0) {

            sellToken = _blackToken;

            buyToken = _whiteToken;

            sellPrice = _blackPrice;

            buyPrice = _whitePrice;

            tokenAddress = address(_whiteToken);

            isWhite = true;

        } else if (tokenId == 1) {

            sellToken = _whiteToken;

            buyToken = _blackToken;

            sellPrice = _whitePrice;

            buyPrice = _blackPrice;

            tokenAddress = address(_blackToken);

        }

        require(

            sellToken.allowance(msg.sender, address(_thisCollateralization)) >=

                tokensAmount,

            "Not enough delegated tokens"

        );



        uint256 collateralWithFee = wmul(tokensAmount, sellPrice);

        uint256 collateralToBuy = collateralWithFee.sub(

            wmul(collateralWithFee, FEE)

        );



        updateFees(wmul(collateralWithFee, FEE), isWhite);



        uint256 amountToSend = wdiv(collateralToBuy, buyPrice);



        _thisCollateralization.buySeparately(

            msg.sender,

            amountToSend,

            tokenAddress,

            tokensAmount,

            address(sellToken)

        );

        //--------------------------------

        if (tokenId == 0) {

            _blackBought = _blackBought.sub(tokensAmount);

            _blackSoldThisCycle = _blackSoldThisCycle.add(tokensAmount);

            _collateralForBlack = _collateralForBlack.sub(collateralWithFee);

            _whiteBought = _whiteBought.add(amountToSend);

            _whiteBoughtThisCycle = _whiteBoughtThisCycle.add(amountToSend);

            _collateralForWhite = _collateralForWhite.add(collateralToBuy);

        } else if (tokenId == 1) {

            _whiteBought = _whiteBought.sub(tokensAmount);

            _whiteSoldThisCycle = _whiteSoldThisCycle.add(tokensAmount);

            _collateralForWhite = _collateralForWhite.sub(collateralWithFee);

            _blackBought = _blackBought.add(amountToSend);

            _blackBoughtThisCycle = _blackBoughtThisCycle.add(amountToSend);

            _collateralForBlack = _collateralForBlack.add(collateralToBuy);

        }

    }



    function sellBlack(uint256 tokensAmount, uint256 minPrice)

        external

        noEvent

        onlyOrdererModifier

    {

        require(

            _blackBought > tokensAmount.add(MIN_HOLD),

            "Cannot buyback more than sold from the pool"

        );



        (

            uint256 collateralAmountWithFee,

            uint256 collateralToSend

        ) = genericSell(_blackToken, _blackPrice, minPrice, tokensAmount, true);



        _blackBought = _blackBought.sub(tokensAmount);

        _collateralForBlack = _collateralForBlack.sub(collateralAmountWithFee);

        _blackSoldThisCycle = _blackSoldThisCycle.add(tokensAmount);

        emit SellBlack(msg.sender, collateralToSend, _blackPrice);

    }



    function sellWhite(uint256 tokensAmount, uint256 minPrice)

        external

        noEvent

        onlyOrdererModifier

    {

        require(

            _whiteBought > tokensAmount.add(MIN_HOLD),

            "Cannot buyback more than sold from the pool"

        );



        (

            uint256 collateralAmountWithFee,

            uint256 collateralToSend

        ) = genericSell(

                _whiteToken,

                _whitePrice,

                minPrice,

                tokensAmount,

                false

            );

        _whiteBought = _whiteBought.sub(tokensAmount);

        _collateralForWhite = _collateralForWhite.sub(collateralAmountWithFee);

        _whiteSoldThisCycle = _whiteSoldThisCycle.add(tokensAmount);

        emit SellWhite(msg.sender, collateralToSend, _whitePrice);

    }



    function genericSell(

        IERC20 token,

        uint256 price,

        uint256 minPrice,

        uint256 tokensAmount,

        bool isWhite

    ) private returns (uint256, uint256) {

        require(

            token.allowance(msg.sender, address(_thisCollateralization)) >=

                tokensAmount,

            "Not enough delegated tokens"

        );

        require(

            price >= minPrice,

            "Actual price is lower than acceptable by the user"

        );



        uint256 collateralWithFee = wmul(tokensAmount, price);

        uint256 feeAmount = wmul(collateralWithFee, FEE);

        uint256 collateralToSend = collateralWithFee.sub(feeAmount);



        updateFees(feeAmount, isWhite);



        require(

            _collateralToken.balanceOf(address(_thisCollateralization)) >

                collateralToSend,

            "Not enought collateral liquidity in the pool"

        );



        _thisCollateralization.buyBackSeparately(

            msg.sender,

            tokensAmount,

            address(token),

            collateralToSend

        );



        return (collateralWithFee, collateralToSend);

    }



    function buyBlack(uint256 maxPrice, uint256 payment)

        external

        noEvent

        notPoolShutdown

        onlyOrdererModifier

    {

        (uint256 tokenAmount, uint256 collateralToBuy) = genericBuy(

            maxPrice,

            _blackPrice,

            _blackToken,

            payment,

            false

        );

        _collateralForBlack = _collateralForBlack.add(collateralToBuy);

        _blackBought = _blackBought.add(tokenAmount);

        _blackBoughtThisCycle = _blackBoughtThisCycle.add(tokenAmount);

        emit BuyBlack(msg.sender, tokenAmount, _blackPrice);

    }



    function buyWhite(uint256 maxPrice, uint256 payment)

        external

        noEvent

        notPoolShutdown

        onlyOrdererModifier

    {

        (uint256 tokenAmount, uint256 collateralToBuy) = genericBuy(

            maxPrice,

            _whitePrice,

            _whiteToken,

            payment,

            true

        );

        _collateralForWhite = _collateralForWhite.add(collateralToBuy);

        _whiteBought = _whiteBought.add(tokenAmount);

        _whiteBoughtThisCycle = _whiteBoughtThisCycle.add(tokenAmount);

        emit BuyWhite(msg.sender, tokenAmount, _whitePrice);

    }



    function genericBuy(

        uint256 maxPrice,

        uint256 price,

        IERC20 token,

        uint256 payment,

        bool isWhite

    ) private returns (uint256, uint256) {

        require(

            price <= maxPrice,

            "Actual price is higher than acceptable by the user"

        );

        require(

            _collateralToken.allowance(

                msg.sender,

                address(_thisCollateralization)

            ) >= payment,

            "Not enough delegated tokens"

        );



        uint256 feeAmount = wmul(payment, FEE);



        updateFees(feeAmount, isWhite);



        uint256 paymentToBuy = payment.sub(feeAmount);

        uint256 tokenAmount = wdiv(paymentToBuy, price);



        _thisCollateralization.buySeparately(

            msg.sender,

            tokenAmount,

            address(token),

            payment,

            address(_collateralToken)

        );

        return (tokenAmount, paymentToBuy);

    }



    function updateFees(uint256 feeAmount, bool isWhite) internal {

        // update team fee collected

        _controllerFeeCollected = _controllerFeeCollected.add(

            wmul(feeAmount, _controllerFee)

        );



        // update governance fee collected

        _feeGovernanceCollected = _feeGovernanceCollected.add(

            wmul(feeAmount, _governanceFee)

        );



        // update BW addition fee collected. For better price

        // stability we add fees to opposite collateral of the transaction

        if (isWhite) {

            _collateralForBlack = _collateralForBlack.add(

                wmul(feeAmount, _bwAdditionFee)

            );

        } else {

            _collateralForWhite = _collateralForWhite.add(

                wmul(feeAmount, _bwAdditionFee)

            );

        }

    }



    function changeGovernanceAddress(address governanceAddress)

        public

        onlyGovernance

    {

        require(

            governanceAddress != address(0),

            "New Gouvernance address should not be null"

        );

        _governanceAddress = governanceAddress;

    }



    function changeEventContractAddress(address evevntContractAddress)

        external

        onlyGovernance

    {

        require(

            evevntContractAddress != address(0),

            "New event contract address should not be null"

        );



        _eventContractAddress = evevntContractAddress;

    }



    function changeGovernanceWalletAddress(address payable newAddress)

        external

        onlyGovernance

    {

        require(

            newAddress != address(0),

            "New Gouvernance wallet address should not be null"

        );



        _governanceWalletAddress = newAddress;

    }



    function shutdownPool(bool isShutdown) external onlyGovernance {

        _poolShutdown = isShutdown;

    }



    function distributeProjectIncentives() external {

        _thisCollateralization.withdrawCollateral(

            _governanceWalletAddress,

            _feeGovernanceCollected

        );

        _feeGovernanceCollected = 0;

        _thisCollateralization.withdrawCollateral(

            _controllerWalletAddress,

            _controllerFeeCollected

        );

        _controllerFeeCollected = 0;

    }



    function addCollateral(uint256 forWhiteAmount, uint256 forBlackAmount)

        external

        onlyGovernance

    {

        _collateralForBlack = _collateralForBlack.add(forBlackAmount);

        _collateralForWhite = _collateralForWhite.add(forWhiteAmount);

        _collateralToken.transferFrom(

            msg.sender,

            address(_thisCollateralization),

            forWhiteAmount.add(forBlackAmount)

        );

    }



    function changeFees(

        uint256 fee,

        uint256 governanceFee,

        uint256 controllerFee,

        uint256 bwAdditionFee

    ) external onlyGovernance {

        require(fee <= 0.1 * 1e18, "Too high total fee");

        require(governanceFee <= _maxFeePart, "Too high governance fee");

        require(controllerFee <= _maxFeePart, "Too high controller fee");

        require(bwAdditionFee <= _maxFeePart, "Too high bwAddition fee");



        FEE = fee;

        _governanceFee = governanceFee;

        _controllerFee = controllerFee;

        _bwAdditionFee = bwAdditionFee;

    }



    function changeOrderer(address newOrderer) external onlyGovernance {

        _ordererAddress = newOrderer;

    }



    function setOnlyOrderer(bool only) external onlyGovernance {

        _onlyOrderer = only;

    }



    function addLiquidity(uint256 tokensAmount) public {

        require(

            _collateralToken.allowance(msg.sender, address(this)) >=

                tokensAmount,

            "Not enough tokens are delegated"

        );

        require(

            _collateralToken.balanceOf(msg.sender) >= tokensAmount,

            "Not enough tokens on the user balance"

        );



        uint256 wPrice = _whitePrice;

        uint256 bPrice = _blackPrice;

        uint256 sPrice = wPrice.add(bPrice);

        uint256 bwAmount = wdiv(tokensAmount, sPrice);

        uint256 forWhite = wmul(bwAmount, wPrice);

        uint256 forBlack = wmul(bwAmount, bPrice);



        _collateralForWhite = _collateralForWhite.add(forWhite);

        _collateralForBlack = _collateralForBlack.add(forBlack);

        _whiteBought = _whiteBought.add(bwAmount);

        _blackBought = _blackBought.add(bwAmount);



        _mint(msg.sender, bwAmount);



        emit AddLiquidity(msg.sender, wPrice, bPrice, bwAmount, tokensAmount);



        _collateralToken.transferFrom(msg.sender, address(this), tokensAmount);



        /* solhint-disable prettier/prettier */

        _thisCollateralization.buySeparately(

            address(this),              // address destination,

            bwAmount,                   // uint256 tokensAmount,

            address(_whiteToken),       // address tokenAddress,

            forWhite,                   // uint256 payment,

            address(_collateralToken)   // address paymentTokenAddress

        );



        _thisCollateralization.buySeparately(

            address(this),              // address destination,

            bwAmount,                   // uint256 tokensAmount,

            address(_blackToken),       // address tokenAddress,

            forBlack,                   // uint256 payment,

            address(_collateralToken)   // address paymentTokenAddress

        );

        /* solhint-enable prettier/prettier */

    }



    function withdrawLiquidity(uint256 poolTokensAmount) public {

        require(

            allowance[msg.sender][address(this)] >= poolTokensAmount,

            "Not enough pool tokens are delegated"

        );

        require(

            balanceOf[msg.sender] >= poolTokensAmount,

            "Not enough tokens on the user balance"

        );



        uint256 wPrice = _whitePrice;

        uint256 bPrice = _blackPrice;

        uint256 sPrice = wPrice.add(bPrice);

        uint256 forWhite = wmul(poolTokensAmount, wPrice);

        uint256 forBlack = wmul(poolTokensAmount, bPrice);



        _collateralForWhite = _collateralForWhite.sub(forWhite);

        _collateralForBlack = _collateralForBlack.sub(forBlack);

        _whiteBought = _whiteBought.sub(poolTokensAmount);

        _blackBought = _blackBought.sub(poolTokensAmount);



        uint256 collateralToSend = wmul(poolTokensAmount, sPrice);



        require(

            _collateralToken.balanceOf(address(_thisCollateralization)) >=

                collateralToSend,

            "Not enough collateral in the contract"

        );



        _burn(msg.sender, poolTokensAmount);



        emit WithdrawLiquidity(

            msg.sender,

            wPrice,

            bPrice,

            poolTokensAmount,

            collateralToSend

        );



        _thisCollateralization.buyBackSeparately(

            address(this),

            poolTokensAmount,

            address(_whiteToken),

            forWhite

        );



        _thisCollateralization.buyBackSeparately(

            address(this),

            poolTokensAmount,

            address(_blackToken),

            forBlack

        );



        _collateralToken.transfer(msg.sender, collateralToSend);

    }

}