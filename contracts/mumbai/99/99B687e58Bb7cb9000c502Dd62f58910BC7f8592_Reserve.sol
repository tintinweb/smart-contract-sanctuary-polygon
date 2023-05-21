pragma solidity ^0.8.0;

import "IERC20.sol";
import "ISheqelToken.sol";
import "Uniswap.sol";
import "DistributorV2.sol";

contract Reserve {
    ISheqelToken private sheqelToken;
    IERC20 private USDC;
    uint256 private shqToConvert;
    uint256 taxRate = 7;
    IUniswapV2Router02 private uniswapV2Router;
    address private WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address private teamAddress;
    bool shqAddressSet=false;


    Distributor public distributor;

    event ShqBought(uint256 amountSHQ, uint256 amountUSDC);
    event ShqSold(uint256 amountSHQ, uint256 amountUSDC);



    constructor(address _spookyswapRouter, address _usdcAddress) {
        // Contract constructed by the Sheqel token
        USDC = IERC20(_usdcAddress);
        uniswapV2Router = IUniswapV2Router02(_spookyswapRouter);
        teamAddress = msg.sender;
        shqToConvert = 0;
    }

    modifier onlyToken() {
        require(msg.sender == address(sheqelToken), "Must be Sheqel Token");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == address(teamAddress), "Must be Sheqel Team");
        _;
    }

    function setTaxRate(uint256 _taxRate) external onlyTeam() {
        taxRate = _taxRate;
    }
    function setSheqelTokenAddress(address _addr) public onlyTeam() {
        require(shqAddressSet == false, "Can only change the address once");
        sheqelToken = ISheqelToken(_addr);
        address distributorAddress = sheqelToken.getDistributor();
        distributor = Distributor(distributorAddress);
        shqAddressSet=true;

        // Initial buying of 999USDC


        // Burning
        sheqelToken.transfer(0x1234567890123456789012345678901234567890, 2*10**18);

        // Adding liquidity
        sheqelToken.transfer(teamAddress, 2000 * 10 ** 18);

        sheqelToken.transfer(teamAddress, 197998 * 10 ** 18);


        
    }

    function addToShqToConvert(uint256 amount) public onlyToken() {
        shqToConvert += amount;
    }

    function buyPrice() public view returns (uint256) {
        uint256 usdcInReserve = USDC.balanceOf(address(this)) * (10 ** 6);
        uint256 shqOutsideReserve = (sheqelToken.totalSupply() - sheqelToken.balanceOf(address(this))) / (10 ** 12);

        return (usdcInReserve / shqOutsideReserve); // Price in USDC (6 decimals)
    }

    function buyPriceWithTax() public view returns (uint256) {
        uint256 usdcInReserve = USDC.balanceOf(address(this)) * (10 ** 6);
        uint256 shqOutsideReserve = (sheqelToken.totalSupply() - sheqelToken.balanceOf(address(this))) / (10 ** 12);

        return (usdcInReserve / shqOutsideReserve) + ((usdcInReserve / shqOutsideReserve) * taxRate) / 100; // Price in USDC (6 decimals)
    }

    function sellPrice() public view returns (uint256) {
        uint256 totalShq = sheqelToken.totalSupply();
        uint256 shqInReserve = sheqelToken.balanceOf(address(this));
        uint256 usdcInReserve = USDC.balanceOf(address(this));
        uint256 shqOutsideReserve = totalShq - shqInReserve;
        uint256 shqBurned = sheqelToken.balanceOf(0x1234567890123456789012345678901234567890);
        uint256 shqDecimals = 10**18;
        uint256 coefficient = 97;

        //(((Tokens outside of the reserve + burned) * standardised price * 1.07 - USDC in reserve)+((Tokens inside the reserve + burned) * standardised price * 1.07)) /(tokens inside the reserve-1)
        // good return (((shqOutsieReserve + shqBurned) * buyPriceWithTax() - usdcInReserce) + ((shqInReserve + shqBurned) * buyPriceWithTax())) / (shqInReserve - 1); // Price in USDC (6 decimals)
        
        //  return ((totalShq * buyPriceWithTax())) / (shqInReserve - 1); // Price in USDC (6 decimals)
        //return ((((totalShq-shqInReserve) * taxRate)/100 - (usdcInReserve * 9)/10) + (shqInReserve)* buyPriceWithTax()) / (shqInReserve - 1); // Price in USDC (6 decimals) brand new formula
        // WORKS return ((totalShq * buyPriceWithTax()) - usdcInReserve) / (shqInReserve - 1); // Price in USDC (6 decimals)
        // works 2return ((shqInReserve * buyPriceWithTax()) + (shqOutsideReserve * buyPrice() * 1001)/1000 - usdcInReserve) / (shqInReserve - 1);
        //return ((shqInReserve * buyPrice() * 1067)/1000 + (shqOutsideReserve * buyPrice() * 101)/100 - usdcInReserve) / (shqInReserve - 1); // Price in USDC (6 decimals)
        return ((totalShq * buyPriceWithTax()) - (usdcInReserve*shqDecimals*coefficient)/100) / (shqInReserve - 1); // Price in USDC (6 decimals)
    }


    function buyShq(address _beneficiary, uint256 _shqAmount) external {
        require(_shqAmount > 0, "Amount of tokens purchased must be positive");
        _processPurchase(_beneficiary, _shqAmount);
    }

    function buyShqWithUsdc(address _beneficiary, uint256 _usdcAmount) public {
        require(_usdcAmount > 0, "Amount of tokens purchased must be positive");
        uint256 shqAmount = (_usdcAmount * (10 ** 18)) / sellPrice();
        _processPurchase(_beneficiary, shqAmount);
    }

    function sellShq(address _beneficiary, uint256 _shqAmount) external {
        require(_shqAmount > 0, "Amount of tokens sold must be positive");
        _processSell(_beneficiary, _shqAmount);
    }

    function _processSell(address _beneficiary, uint256 _shqAmount) internal {
        // Converting shq to usdc
        uint256 usdcAmount = (_shqAmount * buyPrice()) / (10 ** 18);
    
        // Making the user pay
        require(sheqelToken.transferFrom(msg.sender, address(this), _shqAmount), "Deposit failed");

        // Delivering the tokens
        uint256 usdcAmountTaxed = _takeTax(usdcAmount);
        _deliverUsdc(_beneficiary, usdcAmountTaxed);

        emit ShqSold(usdcAmount, _shqAmount);

  }

    function _processPurchase(address _beneficiary, uint256 _shqAmount) internal {
        require(sheqelToken.balanceOf(address(this)) - _shqAmount >= 2 * 10**18, "Cannot buy remaining SHQ");
        // Converting shq to usdc
        uint256 usdcAmount = (_shqAmount * sellPrice()) / (10 ** 18);
    
        // Making the user pay
        require(USDC.transferFrom(msg.sender, address(this), usdcAmount), "Deposit failed");

        // Paying the tax
        _takeTax(usdcAmount);

        // Delivering the tokens
        _deliverShq(_beneficiary, _shqAmount);


        emit ShqBought(_shqAmount, usdcAmount);
    }

    function _deliverShq(address _beneficiary, uint256 _shqAmount) internal {
        sheqelToken.transfer(_beneficiary, _shqAmount);
    }

    function _deliverUsdc(address _beneficiary, uint256 _usdcAmount) internal {
        USDC.transfer(_beneficiary, _usdcAmount);
    }

  /** @dev Creates `amount` tokens and takes all the necessary taxes for the account.*/
     
    function _takeTax(uint256 amount)
        internal
        returns (uint256 amountRecieved)
    {
        // Calculating the tax
        uint256 reserve = (amount * 130) / 10000;
        uint256 rewards = (amount * 370) / 10000;
        uint256 MDO = (amount * 60) / 10000;
        uint256 UBR = (amount * 100) / 10000;
        uint256 liquidity = (amount * 40) / 10000;


        // Adding the liquidity to the contract
        _addToLiquidity(liquidity); 

        // Sending the tokens to the reserve
        _sendToReserve(reserve);

        // Sending the MDO wallet
        _sendToMDO(MDO);

        // Adding to the Universal Basic Reward pool
        _addToUBR(UBR);

        // Adding to the rewards pool
        _addToRewards(rewards);

        return (amount - (reserve + rewards + MDO + UBR + liquidity));
    }

    function _addToLiquidity(uint256 _amount) private {
        USDC.transfer(sheqelToken.liquidityManagerAddress(), _amount);
    }

    function _sendToReserve(uint256 amount) private {
        USDC.transfer(address(this), amount);
    }

    function _addToRewards(uint256 amount) private {
        USDC.transfer(address(distributor), amount);

        distributor.addToCurrentUsdcToRewards(amount);
    }

    function _addToUBR(uint256 amount) private {
        USDC.transfer(address(distributor), amount);

        distributor.addToCurrentUsdcToUBR(amount);
    }

    function _sendToMDO(uint256 amount) private {
        address MDOAddress = sheqelToken.MDOAddress();
        USDC.transfer(MDOAddress, amount);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

interface ISheqelToken {
    function getDistributor() external returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function MDOAddress() external returns (address);
    function liquidityManagerAddress() external returns (address);
    function reserveAddress() external view returns (address);



}

// SPDX-License-Identifier: MIT
// Uniswap V2 router
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
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

interface IUniswapV2Pair {
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

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// SPDX-License-Identifier: MIT
// Rewards Distributor
pragma solidity ^0.8.0;

import "ISheqelToken.sol"; 
import "IERC20.sol";
import "IReserve.sol";

contract Distributor {
    event Log(string message, uint data);

    uint256 public lastDistribution;
    uint256 public currentShqToUBR;
    uint256 public currentShqToRewards;
    uint256 public currentUSDCToUBR;
    uint256 public currentUSDCToRewards;
    bool public shqSet = false;
    ISheqelToken public sheqelToken;
    IERC20 public USDC;
    address public teamAddress;
    IReserve public reserveContract;

    constructor(address _usdcAddress, address _reserveAddress) {
        teamAddress = msg.sender;
        USDC = IERC20(_usdcAddress);
        reserveContract = IReserve(_reserveAddress);
    }

    modifier onlyTeam() {
        require(msg.sender == teamAddress, "Caller must be team address");
        _;
    }

    modifier onlyToken() {
        require(msg.sender == address(sheqelToken), "Caller must be Sheqel Token");
        _;
    }

    modifier onlyReserve() {
        require(msg.sender == address(reserveContract), "Caller must be Reserve");
        _;
    }

    function setShq(address _addr) external onlyTeam() {
        require(shqSet == false, "SHQ Already set");
        sheqelToken = ISheqelToken(_addr);
        shqSet = true;
    }

    function addToCurrentShqToUBR(uint256 _amount) external onlyToken() {
        currentShqToUBR += _amount;
    }

    function addToCurrentShqToRewards(uint256 _amount) external onlyToken() {
        currentShqToRewards += _amount;
    }

    function addToCurrentUsdcToRewards(uint256 _amount) external onlyReserve() {
        currentUSDCToRewards += _amount;
    }

    function addToCurrentUsdcToUBR(uint256 _amount) external onlyReserve() {
        currentUSDCToUBR += _amount;
    }



    function processAllRewards(address[] calldata _addresses , uint256[] calldata _balances, address[] calldata _ubrAddresses, uint256 _totalBalance) onlyTeam() external{
        require(block.timestamp >= lastDistribution + 1 days, "Cannot distribute two times in a day");
        require(_addresses.length == _balances.length, "Addresses and balances must be the same length");

        // Convert all SHQ to USDC
        if(currentShqToRewards > 0){
            currentUSDCToRewards += swapSHQToUSDC(currentShqToRewards);
            currentShqToRewards = 0;
        }
        if(currentShqToUBR > 0){
            currentUSDCToUBR += swapSHQToUSDC(currentShqToUBR);
            currentShqToUBR = 0;
        }   

        require(currentUSDCToRewards > 0, "No USDC to distribute prec");
        require(currentUSDCToUBR > 0, "No USDC to distribute UBR");

        // Iterate through all balances and add it to checkTotalBalance
        uint256 checkTotalBalance = 0;
        for (uint256 i = 0; i < _balances.length; i++) {
            checkTotalBalance += _balances[i];
        }

        // Check if the total balance is the same as the total balance
        require(checkTotalBalance == _totalBalance, "Total balance does not match");

        // Iterate through all addresses
        for (uint256 i = 0; i < _addresses.length; i++) {
            // Get the address
            address holder = _addresses[i];
            // Get the balance
            uint256 balance = _balances[i];

            // Calculate the rewards
            uint256 percentageReward = (balance * (currentUSDCToRewards-100)) / _totalBalance;
            // Send the rewards
            USDC.transfer(holder, percentageReward);
        }
        currentUSDCToRewards = 0;

        currentUSDCToUBR = USDC.balanceOf(address(this));

        // Compute the UBR
        uint256 ubrReward = (currentUSDCToUBR / _ubrAddresses.length) - 100;
        // Iterate through all UBR addresses
        for (uint256 i = 0; i < _ubrAddresses.length; i++) {
            // Get the address
            address holder = _ubrAddresses[i];

            // Send the UBR
            USDC.transfer(holder, ubrReward);
        }
        currentUSDCToUBR = 0;

        // Update last distribution
        lastDistribution = block.timestamp;

        // Send rest to the reserve 
        USDC.transfer(address(reserveContract), USDC.balanceOf(address(this)));
        sheqelToken.transfer(address(reserveContract), sheqelToken.balanceOf(address(this)));
    }

    function swapSHQToUSDC(uint256 amount) internal returns(uint256){
        uint256 balancePreswapUSDC = USDC.balanceOf(address(this));
        sheqelToken.approve(address(reserveContract), amount);
        reserveContract.sellShq(address(this), amount);

        return USDC.balanceOf(address(this)) - balancePreswapUSDC;
    }
}

pragma solidity ^0.8.0;

interface IReserve {
    function sellShq(address _beneficiary, uint256 _shqAmount) external;
    function buyShq(address _beneficiary, uint256 _shqAmount) external;
    function buyShqWithUsdc(address _beneficiary, uint256 _usdcAmount) external;
}