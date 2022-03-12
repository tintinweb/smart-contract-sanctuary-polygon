/**
 *Submitted for verification at polygonscan.com on 2022-03-12
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

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

    event Mint(address indexed sender, uint amount0, uint amount1);
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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

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


// File contracts/Treasury.sol

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add32(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function mul32(uint256 a, uint256 b) internal pure returns (uint256) {
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

library Address {

  function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function functionCall(
        address target, 
        bytes memory data, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(
        address target, 
        bytes memory data, 
        uint256 weiValue, 
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _verifyCallResult(
        bool success, 
        bytes memory returndata, 
        string memory errorMessage
    ) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IOwnable {
  function manager() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyManager() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyManager() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC20Mintable {
  function mint( uint256 amount_ ) external;

  function mint( address account_, uint256 ammount_ ) external;
}

interface ISCATERC20 {
    function burn( uint256 burnAmount ) external;
    function startAntiBot() external;
}

interface IBondCalculator {
  function valuation( address pair_, uint amount_ ) external view returns ( uint _value );
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract SCATTreasury is Ownable, ReentrancyGuard {

    using SafeMath for uint;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposit( address indexed token, uint amount, uint value );
    event Withdrawal( address indexed token, uint amount, uint value );
    event CreateDebt( address indexed debtor, address indexed token, uint amount, uint value );
    event RepayDebt( address indexed debtor, address indexed token, uint amount, uint value );
    event ReservesManaged( address indexed token, uint amount );
    event ReservesUpdated( uint indexed totalReserves );
    event ReservesAudited( uint indexed totalReserves );
    event RewardsMinted( address indexed caller, address indexed recipient, uint amount );
    event ChangeQueued( MANAGING indexed managing, address queued );
    event ChangeActivated( MANAGING indexed managing, address activated, bool result );
    event HouseCutSent( address caller, uint timestamp );
    event TreasuryLiquidationCalled( address caller, uint timestamp, uint percentLiquidation, uint SCATBurnt, bool hasFinishedLiquidating );
    event LiquidationFinalized( address caller, uint timestamp );
    event SetSCATRouter( address router );

    enum MANAGING { 
        RESERVEDEPOSITOR, 
        RESERVESPENDER, 
        RESERVETOKEN, 
        RESERVEMANAGER, 
        LIQUIDITYDEPOSITOR, 
        LIQUIDITYTOKEN, 
        LIQUIDITYMANAGER, 
        DEBTOR, 
        REWARDMANAGER, 
        XSCAT 
    }

    address public immutable SCAT;

    address[] public reserveTokens; // Push only, beware false-positives.
    mapping( address => bool ) public isReserveToken;

    address[] public reserveDepositors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveDepositor;

    address[] public reserveSpenders; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveSpender;

    address[] public liquidityTokens; // Push only, beware false-positives.
    mapping( address => bool ) public isLiquidityToken;

    address[] public liquidityDepositors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isLiquidityDepositor;

    mapping( address => address ) public bondCalculator; // bond calculator for liquidity token

    address[] public reserveManagers; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveManager;

    address[] public liquidityManagers; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isLiquidityManager;

    address[] public debtors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isDebtor;
    mapping( address => uint ) public debtorBalance;

    address[] public rewardManagers; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isRewardManager;

    address public xSCAT;
    
    uint public totalReserves; // Risk-free value of all assets
    uint public totalDebt;

    // initial 10x
    uint public fractionality = 100000;

    // house cut of liquidity 100 = 1%, 2000 = 20%
    uint public constant houseCutPercentage = 2000;

    uint public immutable startTime;

    // TODO: ADJUST TIMININGS TO LIKING (for public finalize liquidity time)
    uint public constant oneDay = 20 minutes;//3600 * 24;

    // 8 days of mayhem
    // TODO: ADJUST TIMININGS TO LIKING
    uint public constant phaseOneDuration = 3600;//oneDay * 14;

    bool public hasSendHouseCutExecuted = false;
    bool public hasLiquidateTreasuryExecuted = false;
    bool public hasFinalizeLiquidationExecuted = false;

    uint256 public SCATBurntFromBuyBack = 0;

    // AVAX DAI Address
    address public immutable stableTokenAddress;

    IUniswapV2Router02 public SCATSwapRouter;

    address public constant houseWallet = 0x4E5D385E44DCD0b7adf5fBe03A6BB867A8A90E7B;

    constructor (
        address _SCAT,
        address [] memory _reserveTokens,
        address[] memory _liquidityTokens,
        address _bondCalc,
        address _stableTokenAddress,
        uint _startTime
    ) {
        require( _SCAT != address(0) );
        SCAT = _SCAT;

        require( _stableTokenAddress != address(0) );
        stableTokenAddress = _stableTokenAddress;

        for (uint256 i = 0;i<_reserveTokens.length;i++) {
            isReserveToken[ _reserveTokens[i] ] = true;
            reserveTokens.push( _reserveTokens[i] );
        }

        for (uint256 i = 0;i<_liquidityTokens.length;i++) {
            isLiquidityToken[ _liquidityTokens[i] ] = true;
            liquidityTokens.push( _liquidityTokens[i] );
            bondCalculator[ _liquidityTokens[i] ] = _bondCalc;
        }

        require(_startTime != 0, "start time cannot be 0!");
        startTime = _startTime;
    }

    function bondStartTime() external view returns ( uint ) {
        return startTime;
    }

    function endTime() public view returns ( uint ) {
        return startTime + phaseOneDuration;
    }

    /**
        @notice allow approved address to deposit an asset for SCAT
        @param _amount uint
        @param _token address
        @param _profit uint
        @return send_ uint
     */
    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint send_ ) {
        require( isReserveToken[ _token ] || isLiquidityToken[ _token ], "Not accepted" );
        IERC20( _token ).safeTransferFrom( msg.sender, address(this), _amount );

        if ( isReserveToken[ _token ] ) {
            require( isReserveDepositor[ msg.sender ], "Not approved" );
        } else {
            require( isLiquidityDepositor[ msg.sender ], "Not approved" );
        }

        uint value = valueOf(_token, _amount);
        // mint SCAT needed and store amount of rewards for distribution
        send_ = value.sub( _profit );

        require( block.timestamp <= endTime(), "No more minting is possible!");
        IERC20Mintable( SCAT ).mint( msg.sender, send_ );

        totalReserves = totalReserves.add( value );
        emit ReservesUpdated( totalReserves );

        emit Deposit( _token, _amount, value );
    }


    /**
        @notice sends a cut of the treasury to the house wallet.
     */
    function sendHouseCut() public  {
        require( _owner == msg.sender || hasFinalizeLiquidationExecuted, "Ownable: caller is not the owner" );
        require( !hasSendHouseCutExecuted,  "Send house cut cannot be called twice!" );
        require( block.timestamp > endTime(), "Cannot deal house cut yet.");

        // We ignore LP assets
        for( uint256 i = 0; i < reserveTokens.length; i++ ) {
            if ( isReserveToken[ reserveTokens[ i ] ] ) {
                uint treasuryBalance = IERC20( reserveTokens[ i ] ).balanceOf( address(this) );

                uint houseCut = treasuryBalance.mul( houseCutPercentage ).div( 10000 );

                if ( houseCut > 0 )
                    IERC20( reserveTokens[ i ] ).safeTransfer( houseWallet, houseCut );
            }
        }

        emit HouseCutSent( msg.sender, block.timestamp );

        hasSendHouseCutExecuted = true;
    }



    /**
        @notice liquidates a % of the treasury to a stable coin and then swaps it SCAT and then burns it.
     */
    function liquidateTreasury( uint percentLiquidation ) public {
        require( percentLiquidation <= 10000,  "percentLiquidation is greater than 100!" ); 
        require( _owner == msg.sender || hasFinalizeLiquidationExecuted, "Ownable: caller is not the owner" );
        require( !hasLiquidateTreasuryExecuted,  "Treasury has already been liquidated!" );
        require( block.timestamp > endTime(), "Cannot liquidate treasury yet.");
        
        if ( !hasSendHouseCutExecuted )
            sendHouseCut();

        bool hasFullyLiquidated = true;

        address[] memory path = new address[](2);

        // We ignore LP assets
        for( uint256 i = 0; i < reserveTokens.length; i++ ) {
            if ( isReserveToken[ reserveTokens[ i ] ] ) {
                if ( reserveTokens[ i ] == stableTokenAddress || reserveTokens[ i ] == SCATSwapRouter.WETH() )
                    continue;

                uint treasuryBalance = IERC20( reserveTokens[ i ] ).balanceOf( address(this) );

                uint liquidationAmount = treasuryBalance.mul( percentLiquidation ).div( 10000 );

                if ( liquidationAmount == 0 ) {
                    if ( treasuryBalance != 0 )
                        hasFullyLiquidated = false;

                    continue;
                }

                require(IERC20( reserveTokens[ i ] ).approve( address(SCATSwapRouter), liquidationAmount ), "!approved");

                path[0] = reserveTokens[ i ];
                path[1] = SCATSwapRouter.WETH();

                // make the swap
                SCATSwapRouter.swapExactTokensForETH(
                    liquidationAmount,
                    0, // accept any amount of tokens
                    path,
                    address(this),
                    block.timestamp
                );

                if ( IERC20( reserveTokens[ i ] ).balanceOf( address(this) ) != 0 )
                    hasFullyLiquidated = false;
            }
        }

        uint stableBalanceBefore = IERC20( stableTokenAddress ).balanceOf( address(this) );
        uint stableLiquidationAmount = stableBalanceBefore.mul( percentLiquidation ).div( 10000 );

        path[0] = SCATSwapRouter.WETH();
        path[1] = stableTokenAddress;


        uint wftmBalance = IERC20( SCATSwapRouter.WETH() ).balanceOf( address(this) );

        uint wftmLiquidationAmount = wftmBalance.mul( percentLiquidation ).div( 10000 );

        if ( wftmLiquidationAmount > 0 )
            IWETH( SCATSwapRouter.WETH() ).withdraw( wftmLiquidationAmount );

        if ( IERC20( SCATSwapRouter.WETH() ).balanceOf( address(this) ) != 0 )
            hasFullyLiquidated = false;

        // make the swap
        SCATSwapRouter.swapExactETHForTokens{value: address(this).balance}(
            0, // accept any amount of tokens
            path,
            address(this),
            block.timestamp
        );

        uint newStableBalance = IERC20( stableTokenAddress ).balanceOf( address(this) ).sub( stableBalanceBefore.sub( stableLiquidationAmount ) );

        require( IERC20( stableTokenAddress ).approve( address(SCATSwapRouter), newStableBalance ), "!approved");

        path[0] = stableTokenAddress;
        path[1] = SCAT;

        // make the swap
        SCATSwapRouter.swapExactTokensForTokens(
            newStableBalance,
            0, // accept any amount of tokens
            path,
            address(this),
            block.timestamp
        );

        uint SCATBurnt = IERC20( SCAT ).balanceOf( address(this) );

        ISCATERC20( SCAT ).burn( SCATBurnt );

        SCATBurntFromBuyBack+= SCATBurnt;

        if ( hasFullyLiquidated )
            hasLiquidateTreasuryExecuted = true;

        ISCATERC20( SCAT ).startAntiBot(); 

        emit TreasuryLiquidationCalled( msg.sender, block.timestamp, percentLiquidation, SCATBurnt, hasLiquidateTreasuryExecuted );
    }


    /**
        @notice finalizes the treasury liquidation process, can be called by anyone a day after mintng ends.
     */
    function finalizeLiquidation() external nonReentrant {
        require( !hasFinalizeLiquidationExecuted,  "Finalize liquidation cannot be called twice!" );
        require( block.timestamp > endTime() + oneDay, "Cannot finalize liquiation yet.");
        
        hasFinalizeLiquidationExecuted = true;    

        if ( !hasSendHouseCutExecuted )
            sendHouseCut();

        if ( !hasLiquidateTreasuryExecuted )
            liquidateTreasury( 10000 );

        emit LiquidationFinalized( msg.sender, block.timestamp );
    }

    /**
        @notice send epoch reward to staking contract
     */
    function mintRewards( address _recipient, uint _amount ) external {
        require( isRewardManager[ msg.sender ], "Not approved" );
        require( _amount <= excessReserves(), "Insufficient reserves" );

        if ( block.timestamp <= endTime() ) {
            IERC20Mintable( SCAT ).mint( _recipient, _amount );
            emit RewardsMinted( msg.sender, _recipient, _amount );
        }
    }

    /**
        @notice returns excess reserves not backing tokens
        @return uint
     */
    function excessReserves() public view returns ( uint ) {
        return totalReserves.mul( fractionality ).div( 10000 ).sub( IERC20( SCAT ).totalSupply().sub( totalDebt ) );
    }

    /**
        @notice sets the fractionality of the treasury
     */
    function setFractionality( uint256 _fractionality ) external onlyManager() {
        require( _fractionality >= 10000 && _fractionality <= 1000000, "fractionality must be 1-100x!" );
        fractionality = _fractionality;
    }

    /**
        @notice takes inventory of all tracked assets
        @notice always consolidate to recognized reserves before audit
     */
    function auditReserves() external {
        uint256 reserves;
        for( uint256 i = 0; i < reserveTokens.length; i++ ) {
            if ( isReserveToken[ reserveTokens[ i ] ] ) {
                reserves = reserves.add (
                    valueOf( reserveTokens[ i ], IERC20( reserveTokens[ i ] ).balanceOf( address(this) ) )
                );
            }
        }
        for( uint256 i = 0; i < liquidityTokens.length; i++ ) {
            if ( !isReserveToken[ liquidityTokens[ i ] ] && isLiquidityToken[ liquidityTokens[ i ] ] ) {
                reserves = reserves.add (
                    valueOf( liquidityTokens[ i ], IERC20( liquidityTokens[ i ] ).balanceOf( address(this) ) )
                );
            }
        }
        totalReserves = reserves;
        emit ReservesUpdated( reserves );
        emit ReservesAudited( reserves );
    }

    /**
        @notice returns SCAT valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function valueOf( address _token, uint _amount ) public view returns ( uint value_ ) {
        if ( isReserveToken[ _token ] ) {
            // convert amount to match SCAT decimals
            value_ = _amount.mul( 10 ** IERC20( SCAT ).decimals() ).div( 10 ** IERC20( _token ).decimals() );
        } else if ( isLiquidityToken[ _token ] ) {
            value_ = IBondCalculator( bondCalculator[ _token ] ).valuation( _token, _amount );
        }
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateSCATSwapRouter( address _router ) external onlyManager() {
        require( _router != address(0), "!!0");
        require( address(SCATSwapRouter) == address(0), "!unset" );

        SCATSwapRouter = IUniswapV2Router02( _router );

        emit SetSCATRouter( address(SCATSwapRouter) );
    }

    // To receive ETH from SCATSwapRouter when swapping
    receive() external payable {}

    /**
        @notice verify queue then set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @param _calculator address
        @return bool
     */
    function toggle(
        MANAGING _managing, 
        address _address, 
        address _calculator 
    ) external onlyManager() returns ( bool ) {
        require( _address != address(0) );
        bool result;
        if ( _managing == MANAGING.RESERVEDEPOSITOR ) { // 0
            if( !listContains( reserveDepositors, _address ) ) {
                reserveDepositors.push( _address );
            }

            result = !isReserveDepositor[ _address ];
            isReserveDepositor[ _address ] = result;
            
        } else if ( _managing == MANAGING.RESERVESPENDER ) { // 1
            if( !listContains( reserveSpenders, _address ) ) {
                reserveSpenders.push( _address );
            }

            result = !isReserveSpender[ _address ];
            isReserveSpender[ _address ] = result;

        } else if ( _managing == MANAGING.RESERVETOKEN ) { // 2
            if( !listContains( reserveTokens, _address ) ) {
                reserveTokens.push( _address );
            }

            result = !isReserveToken[ _address ];
            isReserveToken[ _address ] = result;

        } else if ( _managing == MANAGING.RESERVEMANAGER ) { // 3
            if( !listContains( reserveManagers, _address ) ) {
                reserveManagers.push( _address );
            }

            result = !isReserveManager[ _address ];
            isReserveManager[ _address ] = result;

        } else if ( _managing == MANAGING.LIQUIDITYDEPOSITOR ) { // 4
            if( !listContains( liquidityDepositors, _address ) ) {
                liquidityDepositors.push( _address );
            }

            result = !isLiquidityDepositor[ _address ];
            isLiquidityDepositor[ _address ] = result;

        } else if ( _managing == MANAGING.LIQUIDITYTOKEN ) { // 5
            if( !listContains( liquidityTokens, _address ) ) {
                liquidityTokens.push( _address );
            }

            result = !isLiquidityToken[ _address ];
            isLiquidityToken[ _address ] = result;
            bondCalculator[ _address ] = _calculator;

        } else if ( _managing == MANAGING.LIQUIDITYMANAGER ) { // 6
            if( !listContains( liquidityManagers, _address ) ) {
                liquidityManagers.push( _address );
            }

            result = !isLiquidityManager[ _address ];
            isLiquidityManager[ _address ] = result;

        } else if ( _managing == MANAGING.DEBTOR ) { // 7
            if( !listContains( debtors, _address ) ) {
                debtors.push( _address );
            }

            result = !isDebtor[ _address ];
            isDebtor[ _address ] = result;

        } else if ( _managing == MANAGING.REWARDMANAGER ) { // 8
            if( !listContains( rewardManagers, _address ) ) {
                rewardManagers.push( _address );
            }

            result = !isRewardManager[ _address ];
            isRewardManager[ _address ] = result;

        } else if ( _managing == MANAGING.XSCAT ) { // 9
            xSCAT = _address;
            result = true;

        } else return false;

        emit ChangeActivated( _managing, _address, result );
        return true;
    }

    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains( address[] storage _list, address _token ) internal view returns ( bool ) {
        for( uint i = 0; i < _list.length; i++ ) {
            if( _list[ i ] == _token ) {
                return true;
            }
        }
        return false;
    }
}