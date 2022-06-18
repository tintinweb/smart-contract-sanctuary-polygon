// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AggregatorV3Interface.sol";
import "./Token.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract MidasTokenGenerator is Initializable {
    IUniswapV2Router02 public pcsV2Router;
    AggregatorV3Interface internal priceFeed;

    mapping(string => bool) private availableChainlinkNet;
    mapping(address => bool) public _managers;

    address public _aw;
    address public _bw;
    address public _cw;
    address public _dw;
    address public owner;
    address busdAddress;

    uint256 _ap;
    uint256 _bp;
    uint256 _cp;
    uint256 _dp;

    uint256 public creationPrice; // 50$
    address private aggregatorAddress;

    // CONSTRUCTOR ------------------------------------------------------------------------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address[] memory addresses) public virtual initializer {
        owner = msg.sender;
        _managers[owner] = true;
        // _aw = addresses[0];
        // _bw = addresses[1];
        // _cw = addresses[2];
        // _dw = addresses[3];

        // pcsV2Router = IUniswapV2Router02(addresses[4]);

        // if (addresses[5] != 0x0000000000000000000000000000000000000000) {

        // }


        // priceFeed = AggregatorV3Interface(addresses[5]);

        _ap = 5;
        _bp = 10;
        _cp = 15;
        _dp = 25;
        creationPrice = 50000000000000000000;
    }

    fallback() external payable {}

    receive() external payable {}
    

    modifier onlyOwner() {
        require(owner == msg.sender, "onlyOwner");
        _;
    }

    modifier onlyManager() {
        require(_managers[msg.sender] == true, "onlyManager");
        _;
    }

    function setBusdAddress(address _busdAddress) external onlyOwner {
        busdAddress = _busdAddress;
    }

    function setManagers(address manager, bool newVal) external onlyOwner {
        _managers[manager] = newVal;
    }

    function enableDisableChainlinkNet(string memory name, bool status)
        public
        onlyOwner
    {
        availableChainlinkNet[name] = status;
    }

    function setCreationPrice(uint256 amount) public onlyOwner {
        creationPrice = amount;
    }

    function setPriceDataFeed(address newValue) public onlyOwner {
        priceFeed = AggregatorV3Interface(address(newValue));
    }

    function setRouterAddress(address newValue) public onlyOwner {
        pcsV2Router = IUniswapV2Router02(newValue);
    }

    function createNewToken(
        address paymentTokenAddress,
        address tokenOwner,
        address payable _feeWallet,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 amountOfTokenWei,
        uint8 decimal,
        uint8[] memory fees,
        address routerAddress,
        string memory network
    ) public payable {
        // manager can create tokens for free
        if (!_managers[msg.sender]) {
            // if user pay using other token
            // the contract need how much tokens the user
            // should spend for swap for native network cryptocurrency for pay service
            if (paymentTokenAddress != pcsV2Router.WETH()) {
                // get required token amount for pay service
                uint256 requiredTokenAmount = getMinimunTokenAmout(
                    paymentTokenAddress,
                    network
                );

                // transfer from customer to contract
                require(
                    IERC20(address(paymentTokenAddress)).transferFrom(
                        msg.sender,
                        address(this),
                        requiredTokenAmount
                    )
                );

                // swap to native cryprocurrency | BNB, AVAX, MATIC, ETH ....
                swap(paymentTokenAddress, requiredTokenAmount);
            } else {
                require(
                    msg.value >= getRequiredEthAmount(network),
                    "low value"
                );
            }

            // send to team
            uint256 contractBalance = address(this).balance;
            if (contractBalance > 0) {
                payable(_aw).transfer((_ap * contractBalance) / 100);
                payable(_bw).transfer((_bp * contractBalance) / 100);
                payable(_cw).transfer((_cp * contractBalance) / 100);
                payable(_dw).transfer((_dp * contractBalance) / 100);
            }
        }

/*
        // create token and set user as owner
        Token newToken = new Token(
            tokenOwner,
            tokenName,
            tokenSymbol,
            decimal,
            amountOfTokenWei,
            fees[5],
            fees[6],
            _feeWallet,
            routerAddress
        );
        newToken.setAllFeePercent(fees[0], fees[1], fees[2], fees[3], fees[4]);
        */
    }

    function getRequiredEthAmount(string memory network)
        public
        view
        returns (uint256)
    {
        uint256 nativeTokenPrice;

        // contract need know if user are using network available on chainlink
        // for get native crypto price from chainlink or from router pool
        if (availableChainlinkNet[network]) {
            nativeTokenPrice = uint256(getLatestPrice()) * 1e8;
        } else {
            // get price from router pool
            nativeTokenPrice = estimatedTokensForTokens(
                pcsV2Router.WETH(),
                busdAddress,
                creationPrice
            );
        }

        return creationPrice / nativeTokenPrice;
    }

    function getMinimunTokenAmout(address tokenAddress, string memory network)
        public
        view
        returns (uint256)
    {
        return
            estimatedTokensForTokens(
                tokenAddress,
                pcsV2Router.WETH(),
                getRequiredEthAmount(network)
            );
    }

    // return amount of tokenA needed to buy 1 tokenB
    function estimatedTokensForTokens(
        address add1,
        address add2,
        uint256 amount
    ) public view returns (uint256) {
        return
            pcsV2Router.getAmountsOut(amount, pathTokensForTokens(add1, add2))[
                1
            ];
    }

    // return the route given the busd addresses and the token
    function pathTokensForTokens(address add1, address add2)
        private
        pure
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = add1;
        path[1] = add2;
        return path;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/
            ,
            ,

        ) = /*uint80 answeredInRound*/
            priceFeed.latestRoundData();
        return price;
    }

    function swap(address tokenAddress, uint256 tokenAmount) private {
        IERC20(tokenAddress).approve(address(pcsV2Router), tokenAmount);
        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            pathTokensForTokens(tokenAddress, pcsV2Router.WETH()),
            address(this),
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IMidasMultiNetworkRouter.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./IFactoryV2.sol";
import "./IUniswapV2Pair.sol";
import "./IBridgeToken.sol";
import "./AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./AggregatorV3Interface.sol";

contract Token is ERC20, IBridgeToken {
    //used for store the percentage of fees applied for purchase, sale, transfer and distribution to holders
    struct Fees {
        uint16 distributionToHoldersFee;
        uint16 liquidityFee;
        uint16 buyBackFee;
        uint16 busdReserveFee;
    }

    // used to designate the amount sent to the respective wallet after the fee is applied
    struct Ratios {
        uint16 liquidityRatio;
        uint16 buyBurnRatio;
        uint16 busdReserveRatio;
        uint16 total;
    }

    // internal accouting to manage fees
    struct FeeValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tBuyBurn;
        uint256 tReserve;
    }

    struct tFeeValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tBuyBurn;
        uint256 tReserve;
    }

    Ratios public _ratios;
    Fees public _taxRates;

    // STRINGS
    string currentNetwork;
    bool public bridgeEnabled;
    mapping(address => bool) public bridges;
    mapping(string => bool) public availableNetworks;
    mapping(string => bool) private availableChainlinkNetworks;
    address public usdAddress;

    // REFLECTION (DISTRIBUTION TO HOLDERS / SMART STAKING)
    uint256 private _max;
    uint256 private _tFeeTotal;
    uint16 private _previousTaxFee;
    address[] private _excluded;
    uint256 private constant MAX = type(uint256).max;
    uint256 internal _totalSupply;
    uint256 private _reflectionSupply;
    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromRewards;
    // --------------------------------------------------

    bool private gasLimitActive; // used for enable / disable max gas price limit
    uint256 private maxGasPriceLimit; // for store max gas price value
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily  // todo remove
    bool public transferDelayEnabled; // for enable / disable delay between transactions
    uint256 private initialDelayTime; // to store the block in which the trading was enabled

    // event for show burn txs
    event Burn(address indexed sender, uint256 amount);

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) internal _isFeeExcluded; // todo
    mapping(address => bool) internal lpPairs; // used for allow owner to add liquidity in diferents tokens
    event TransferedToPool(address, uint256);

    address internal contractAddress;

    IMidasMultiNetworkRouter public midasMultiNetworkRouter;
    address public lpPair;
    address public deadAddress;
    address payable public busdForLiquidityAddress;
    address payable public busdBuyBurnAddress;
    address payable public busdReserveAddress;
    bool public contractSwapEnabled;
    uint256 public swapThreshold;
    bool internal inSwap;
    bool public tradingActive;
    address public busdAddress;
    bool public transferToPoolsOnSwaps;
    mapping(address => bool) private _liquidityRatioHolders;
    uint256 internal maxBuyLimit;
    uint256 public timeDelayBetweenTx;
    uint256 internal totalDelayTime;

    AggregatorV3Interface internal priceFeed;

    // modifier for know when tx is swaping
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyBridge() {
        require(
            bridges[msg.sender] == true,
            "Only Bridge: caller is not the bridge"
        );
        _;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event ContractSwapEnabledUpdated(bool enabled);

    /// @notice initialize upgradable contract
    constructor(
        string[] memory strings,
        address[] memory addresses,
        uint256[] memory numbers
    ) ERC20(strings[0], strings[1]) {
        _owner = addresses[0];
        _name = strings[0];
        _symbol = strings[1];
        _decimals = uint8(numbers[0]);
        _mint(_owner, numbers[1]);

        // BRIDGE
        currentNetwork = strings[1];
        availableNetworks[currentNetwork] = true;
        bridgeEnabled = false;

        _tFeeTotal;
        _previousTaxFee = 0;
        // used for temporaly store previous fee

        gasLimitActive = false;
        // used enable or disable max gas price limit
        maxGasPriceLimit = 25000000000;
        // used for store max gas price limit value
        transferDelayEnabled = false;
        // used for enable / disable delay between transactions
        // when the token reaches a set price, liquidity is automatically injected.

        swapThreshold = 5000 ether;
        // token balance on contract needed for do swap
        contractSwapEnabled = true;
        // enable or disable swap when contract balance hits threshodl
        tradingActive = false;
        transferToPoolsOnSwaps = false;
        // enable / disable transfer to wallets when contract do swap tokens for busd
        timeDelayBetweenTx = 5;
        totalDelayTime = 3600;

        deadAddress = 0x000000000000000000000000000000000000dEaD;

        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[address(this)] = true;

        _excludeFromRewards(_owner);
        _excludeFromRewards(address(this));
        _excludeFromRewards(deadAddress);

        maxBuyLimit = 10000 ether; // 10000 TOKENS

        // set fees values
        _taxRates = Fees({
            distributionToHoldersFee: 50, // 0.5%
            liquidityFee: 100, // 1.0%
            buyBackFee: 100, // 1.0%
            busdReserveFee: 50 // 0.5%
        });

        // set ration values
        _ratios = Ratios({
            liquidityRatio: 100, // 1%
            buyBurnRatio: 100, // 1%
            busdReserveRatio: 50, // 0.5%
            total: 250 // 2.5%
        });

        // constructor -------------------------------------

        // set busd address
        busdAddress = address(addresses[0]);

        // give permissions to the router to spend tokens and busd of the contract and owner
        _approve(msg.sender, busdAddress, type(uint256).max);
        _approve(address(this), busdAddress, type(uint256).max);
        _approve(msg.sender, addresses[1], type(uint256).max);
        _approve(address(this), addresses[1], type(uint256).max);

        // initialize router and create lp pair
        IMidasMultiNetworkRouter _midasMultiNetworkRouter = IMidasMultiNetworkRouter(
                addresses[1]
            );
        midasMultiNetworkRouter = _midasMultiNetworkRouter;

        // wallets used to hold BUSD until liquidity is added/tokens are repurchased for burning.

        priceFeed = AggregatorV3Interface(
            0x0A77230d17318075983913bC2145DB16C7366156
        ); // AVAX / USDT
        usdAddress = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E; // USDT traderjoe main
        availableChainlinkNetworks[currentNetwork] = false;

        //createPair();
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function mintBridge(address to, uint256 amount)
        external
        virtual
        onlyBridge
    {
        require(bridgeEnabled, "bridge disabled");
        _mint(to, amount);
    }

    function getWethPriceInUsd(string memory network)
        external
        view
        returns (uint256)
    {
        uint256 avaxPrice;

        // contract need know if user are using network available on chainlink
        // for get native crypto price from chainlink or from router pool
        if (availableChainlinkNetworks[network]) {
            avaxPrice = uint256(getLatestPriceFromChainlink()) * 1e10;
        } else {
            // get price from router pool
            avaxPrice = getAmountOut(
                midasMultiNetworkRouter.WETH(),
                usdAddress,
                1000000000000000000
            ); // 1 avax
        }

        return avaxPrice;
    }

    function getAmountOut(
        address add1,
        address add2,
        uint256 _amount
    ) internal view returns (uint256) {
        if (address(midasMultiNetworkRouter) == address(0)) return 0;
        address[] memory path = new address[](2);
        path[0] = add1;
        path[1] = add2;
        uint256[] memory amountsOut = midasMultiNetworkRouter.getAmountsOut(
            _amount,
            path
        );
        return amountsOut[1];
    }

    function getAmountOutUSD(uint256 _amount, string memory network)
        public
        view
        returns (uint256)
    {
        // contract need know if user are using network available on chainlink
        // for get native crypto price from chainlink or from router pool
        if (availableChainlinkNetworks[network]) {
            uint256 wethPrice = uint256(getLatestPriceFromChainlink()) * 1e10;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = midasMultiNetworkRouter.WETH();
            uint256[] memory amountsOut = midasMultiNetworkRouter.getAmountsOut(
                _amount,
                path
            );
            uint256 tokenAmount = amountsOut[1];

            return (wethPrice * tokenAmount) / 1000000000000000000;
        } else {
            address[] memory path = new address[](3);
            if (address(midasMultiNetworkRouter) == address(0)) return 0;
            path[0] = address(this);
            path[1] = midasMultiNetworkRouter.WETH();
            path[2] = usdAddress;
            uint256[] memory amountsOut = midasMultiNetworkRouter.getAmountsOut(
                _amount,
                path
            );

            if (ERC20(usdAddress).decimals() != decimals()) {
                //amountsOut[2] *= decimalMultiplier;
                amountsOut[2] *= 1e1;
            }

            return amountsOut[2];
        }
    }

    /**
     * Returns the latest price
     */
    function getLatestPriceFromChainlink() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * @notice Emits a {Transfer} event with `from` set to the zero address.
     *         the total supply.
     * Requirements:
     * - `account` cannot be the zero address.
     */

    function _mint(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, _totalSupply);
        _totalSupply = amount;
        _reflectionSupply = (MAX - (MAX % _totalSupply));
        _reflectionBalance[_owner] = _reflectionSupply;

        emit Transfer(address(0), account, _totalSupply);

        _afterTokenTransfer(address(0), account, _totalSupply);
    }

    // ====================================================== //
    //                      FALLBACKS                         //
    // ====================================================== //
    receive() external payable {}

    // ====================================================== //
    //                      ONLY V3                           //
    // ====================================================== //

    /// @notice Function inherited from BEP20 and overrided
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(
            _allowances[sender][msg.sender] >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    /**
     * @dev This method set address of liquidity pair that was created previously
     * @param add1 Address to assign the liquidity pair
     */
    function setPairAddress(address add1) public onlyOwner {
        lpPair = add1;
        lpPairs[lpPair] = true;
        _excludeFromRewards(add1);
    }

    /**
     * @dev Update the max amount of tokens that can be buyed in one transaction
     * @param newVal New max buy limit in wei
     */
    function updateMaxBuyLimit(uint256 newVal) public onlyOwner {
        maxBuyLimit = newVal;
    }

    /**
     * @dev Update the max gas limit that can be used in the transaction
     * @param newVal New gas limit amount
     */
    function updateGasLimitActive(bool newVal) public onlyOwner {
        gasLimitActive = newVal;
    }

    // ====================================================== //
    //                       EXTERNAL                         //
    // ====================================================== //

    /**
     * @dev This method is used to change the taxes that affect the transfer from/to liquidity
     * @param distributionToHoldersFee Amount in basis point (1/100)
     * @param liquidityFee Amount in basis point (1/100)
     * @param buyBackFee Amount in basis point (1/100)
     * @param busdReserveFee Amount in basis point (1/100)
     */
    function setTaxes(
        uint16 distributionToHoldersFee,
        uint16 liquidityFee,
        uint16 buyBackFee,
        uint16 busdReserveFee
    ) external onlyOwner {
        // check each individual fee is not higher than 3%
        require(
            distributionToHoldersFee <= 4500,
            "distributionToHoldersFee EXCEEDED 45%"
        );
        require(liquidityFee <= 4500, "liquidityFee EXCEEDED 45%");
        require(buyBackFee <= 4500, "distributionToHoldersFee EXCEEDED 45%");
        require(
            busdReserveFee <= 4500,
            "distributionToHoldersFee EXCEEDED 45%"
        );

        // set values
        _taxRates.distributionToHoldersFee = distributionToHoldersFee;
        _taxRates.liquidityFee = liquidityFee;
        _taxRates.buyBackFee = buyBackFee;
        _taxRates.busdReserveFee = busdReserveFee;
    }

    /// @notice Function inherited from BEP20
    function transferOwner(address newOwner) external onlyOwner {
        _isFeeExcluded[_owner] = false;
        _isFeeExcluded[newOwner] = true;
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /// @notice Set different liquidity pair and update the state
    function setLpPair(address pair, bool newValue) external onlyOwner {
        if (newValue = false) {
            lpPairs[pair] = false;
        } else {
            lpPairs[pair] = true;
        }
    }

    /**
     * @notice This function is updating the value of the variable transferToPoolsOnSwaps
     * @param newVal New value of the variable
     */
    function updateTransferDelayEnabled(bool newVal) external onlyOwner {
        transferDelayEnabled = newVal;
    }

    // todo remove later
    /**
     * @notice This function is updating the value of the variable transferToPoolsOnSwaps
     * @param newValue New value of the variable
     */
    function updateTransferToPoolsOnSwaps(bool newValue) external onlyOwner {
        transferToPoolsOnSwaps = newValue;
    }

    /**
     * @notice This function is updating the value of the variable busdAddress
     * @param newAddress New value of the variable
     */
    function updateBUSDAddress(address newAddress) external onlyOwner {
        busdAddress = address(newAddress);
    }

    /**
     * @notice Send tokens to multiple wallets given wallets and amounts
     * @param accounts Array of accounts to send tokens to
     * @param amounts Array of amounts to send to each account
     */
    function multiSendTokens(
        address[] memory accounts,
        uint256[] memory amounts
    ) external {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(_tokenBalance[msg.sender] >= amounts[i]);
            _transfer(msg.sender, accounts[i], amounts[i] * 10**_decimals);
        }
    }

    /**
     * @notice Send tokens to multiple wallets given wallets and percents
     * @param accounts Array of accounts to send tokens to
     * @param percents Array of percentages
     * @param divisors Array of divisors
     */

    function multiSendPercents(
        address[] memory accounts,
        uint256[] memory percents,
        uint256[] memory divisors
    ) external {
        require(
            accounts.length == percents.length &&
                percents.length == divisors.length,
            "Lengths do not match."
        );
        for (uint8 i = 0; i < accounts.length; i++) {
            require(
                _tokenBalance[msg.sender] >=
                    (_totalSupply * percents[i]) / divisors[i]
            );
            _transfer(
                msg.sender,
                accounts[i],
                (_totalSupply * percents[i]) / divisors[i]
            );
        }
    }

    // ====================================================== //
    //                        PUBLIC                          //
    // ====================================================== //

    /// @notice Function inherited from BEP20
    function owner() public view returns (address) {
        return _owner;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /// @notice Function inherited from BEP20
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /// @notice Function inherited from BEP20
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @notice Function inherited from BEP20
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @notice Function inherited from BEP20
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromRewards[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    /// @notice Function inherited from BEP20
    function allowance(address tokenOwner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[tokenOwner][spender];
    }

    /// @notice Function inherited from BEP20
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Function inherited from BEP20
    function _approve(
        address tokenOwner,
        address spender,
        uint256 amount
    ) internal virtual override {
        require(
            tokenOwner != address(0),
            "ERC20: approve from the zero address"
        );
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[tokenOwner][spender] = amount;
        emit Approval(tokenOwner, spender, amount);
    }

    /// @notice Function inherited from BEP20 and overrided
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Function inherited from BEP20
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @notice Check if the address if excluded from rewards
     * @param account Address to be checked
     */
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromRewards[account];
    }

    /**
     * @notice Check if the address if excluded from fees
     * @param account Address to be checked
     */
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /**
     * @notice Allow the owner to exclude an address from fees
     * @param account Address to be excluded
     */
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    /**
     * @notice Allow the owner to exclude an address from fees
     * @param account Address to be excluded
     */
    function excludeFromRewards(address account) external onlyOwner {
        _isExcludedFromRewards[account] = true;
        require(!_isExcludedFromRewards[account], "Account is not included");
        _excludeFromRewards(account);
    }

    /**
     * @notice Allow the owner to include an address to the fees list
     * @param account Address to be included
     */
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**
     * @notice Set the liquidity address
     * @dev only called on initializer
     * @param _busdForLiquidityAddress Address of the BUSD Reserve
     */
    function setLiquidityAddress(address _busdForLiquidityAddress)
        public
        onlyOwner
    {
        busdForLiquidityAddress = payable(_busdForLiquidityAddress);
    }

    /**
     * @notice Set the address of the BuyBurn Reserve
     * @param _busdBuyBurnAddress Address of the BuyBurn Reserve
     */
    function setBusdBuyBurnAddress(address _busdBuyBurnAddress)
        public
        onlyOwner
    {
        busdBuyBurnAddress = payable(_busdBuyBurnAddress);
    }

    /**
     * @notice Set the address of the BUSD Reserve
     * @param _busdReserveAddress Address of the BUSD Reserve
     */
    function setBusdReserveAddress(address _busdReserveAddress)
        public
        onlyOwner
    {
        busdReserveAddress = payable(_busdReserveAddress);
    }

    /**
     * @notice Set the block delay between txs
     * @param time Time in seconds
     */
    function setTimeDelayBetweenTx(uint256 time) public onlyOwner {
        timeDelayBetweenTx = time;
    }

    /**
     * @notice Set the total block delay between txs
     * @param time Time in seconds
     */
    function setTotalDelayTime(uint256 time) public onlyOwner {
        totalDelayTime = time;
    }

    // ====================================================== //
    //                PUBLIC EXPERIMENTAL                     //
    // ====================================================== //

    /**
     * @dev Enable trading (swap) and set initial block
     */
    function enableTrading() public onlyOwner {
        require(!tradingActive, "Trading already enabled!");
        tradingActive = true;
        initialDelayTime = block.timestamp;
        contractSwapEnabled = true;
    }

    // todo check excluded
    // check rfi contract and check if is same or not
    // check if account is excluded from fees

    /**
     * @dev Is excluded from fee transaction
     * @param account address
     * @return bool
     */
    function isFeeExcluded(address account) public view returns (bool) {
        return _isFeeExcluded[account];
    }

    /**
     * @dev set router address and busd on this router
     * @param newRouter address of router
     * @param busd address of busd
     */
    function setNewRouter(address newRouter, address busd) public onlyOwner {
        IMidasMultiNetworkRouter _newRouter = IMidasMultiNetworkRouter(
            newRouter
        );
        address getPair = IFactoryV2(_newRouter.factory()).getPair(
            address(busd),
            address(this)
        );

        // check if pair exist
        // if not exists, create pair, otherwise get pair address from factory contract
        if (getPair == address(0)) {
            lpPair = IFactoryV2(_newRouter.factory()).createPair(
                address(busd),
                address(this)
            );
        } else {
            lpPair = getPair;
        }

        // set lp address on automatic market maker list
        lpPairs[lpPair] = true;
        midasMultiNetworkRouter = _newRouter;
        _approve(
            address(this),
            address(midasMultiNetworkRouter),
            type(uint256).max
        );
    }

    function burnBridge(address to, uint256 amount) public virtual {
        require(bridgeEnabled, "bridge disabled");
        require(amount >= 0, "Burn amount should be greater than zero");

        if (msg.sender != to) {
            uint256 currentAllowance = allowance(to, msg.sender);
            if (currentAllowance != type(uint256).max) {
                require(
                    currentAllowance >= amount,
                    "ERC20: transfer amount exceeds allowance"
                );
            }
        }

        require(
            amount <= balanceOf(to),
            "Burn amount should be less than account balance"
        );

        super._transfer(to, contractAddress, amount);
        emit Burn(to, amount);
    }

    function updateBridges(address bridgeAddress, bool newVal)
        external
        virtual
        onlyBridge
    {
        bridges[bridgeAddress] = newVal;
    }

    function updateNetworks(string memory network, bool newVal)
        external
        virtual
        onlyBridge
    {
        availableNetworks[network] = newVal;
    }

    // ====================================================== //
    //                      INTERNAL                          //
    // ====================================================== //

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint256 the amount of tokens to be transferred
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount != 0, "Transfer amount cannot be zero");

        if (
            !tradingActive &&
            from != _owner &&
            to != address(midasMultiNetworkRouter) &&
            to != address(lpPair)
        ) {
            revert("Trading not yet enabled!");
        }

        if (
            transferDelayEnabled &&
            block.timestamp < (initialDelayTime + totalDelayTime)
        ) {
            // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
            if (
                from != _owner &&
                to != address(midasMultiNetworkRouter) &&
                to != address(lpPair)
            ) {
                // in the first one hour, a maximum of XX BUSD purchase is adjustable (10000 BUSD is the default value)
                if (maxBuyLimit > 0) {
                    require(amount <= maxBuyLimit, "Max Buy Limit.");
                }

                // only use to prevent sniper buys in the first blocks.
                if (gasLimitActive) {
                    require(
                        tx.gasprice <= maxGasPriceLimit,
                        "Gas price exceeds limit."
                    );
                }

                // delay between tx
                require(
                    _holderLastTransferTimestamp[msg.sender] <= block.timestamp,
                    "_transfer:: Transfer Delay enabled."
                );
                _holderLastTransferTimestamp[msg.sender] =
                    block.timestamp +
                    timeDelayBetweenTx;
            }
        }

        // ====================================================== //
        //                      INTERNAL                          //
        // ====================================================== //

        // if transaction are internal transfer when contract is swapping
        // transfer no fee
        if (inSwap) {
            _transferNoFee(from, to, amount);
            return;
        }

        // SWAP
        if (contractMustSwap(from, to)) {
            contractSwap();
        }

        bool takeFee = true;
        bool isTransfer = isTransferBetweenWallets(from, to);

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        // Transfer between wallets have 0% fee
        // If takeFee is false there is 0% fee
        if (isTransfer || !takeFee) {
            _transferNoFee(from, to, amount);
            return;
        }

        _tokenTransfer(from, to, amount);
    }

    /**
     * @dev Handle if contract have to swap tokens
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     */
    function contractMustSwap(address from, address to)
        internal
        view
        returns (bool)
    {
        uint256 contractTokenBalance = balanceOf(address(this));
        return
            contractTokenBalance >= swapThreshold &&
            !inSwap &&
            from != lpPair &&
            balanceOf(lpPair) > 0 &&
            !_isExcludedFromFee[to] &&
            !_isExcludedFromFee[from] &&
            contractSwapEnabled;
    }

    /**
     * @dev Handle if transaction is between wallets and not from/to liquidity
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     */
    function isTransferBetweenWallets(address from, address to)
        internal
        view
        returns (bool)
    {
        return from != lpPair && to != lpPair;
    }

    /**
     * @dev This is the function that handles the actual transfer of tokens.
     * @param sender Address of the sender (from)
     * @param recipient Address of the recipient (to)
     * @param amount Amount of tokens to be transferred
     */
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (
            _isExcludedFromRewards[sender] && !_isExcludedFromRewards[recipient]
        ) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (
            !_isExcludedFromRewards[sender] && _isExcludedFromRewards[recipient]
        ) {
            _transferToExcluded(sender, recipient, amount);
        } else if (
            !_isExcludedFromRewards[sender] &&
            !_isExcludedFromRewards[recipient]
        ) {
            _transferStandard(sender, recipient, amount);
        } else if (
            _isExcludedFromRewards[sender] && _isExcludedFromRewards[recipient]
        ) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    /**
     * @dev Handle if sender is excluded from fees
     * @param sender address The address which you want to send tokens from
     * @param recipient address The address which you want to transfer to
     * @param amount uint256 The amount in wei of tokens to transfer
     */
    function _transferNoFee(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = amount * currentRate;

        _reflectionBalance[sender] -= rAmount;
        _reflectionBalance[recipient] += rAmount;

        if (_isExcludedFromRewards[sender]) {
            _tokenBalance[sender] -= amount;
        }

        if (_isExcludedFromRewards[recipient]) {
            _tokenBalance[recipient] += amount;
        }
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @notice This function is called when the _tokenTransfer function is called
     * @dev This function is used to distribute as proportional to the balance of each user
     */
    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        FeeValues memory _values = _getValues(tAmount);
        _tokenBalance[sender] -= tAmount;
        _reflectionBalance[sender] -= _values.rAmount;
        _tokenBalance[recipient] += _values.tTransferAmount;
        _reflectionBalance[recipient] += _values.rTransferAmount;
        _takeFees(sender, _values);
        _reflectFee(_values.rFee, _values.tFee);
        emit Transfer(sender, recipient, _values.tTransferAmount);
    }

    /// @notice Transfer function that handle the standard transfer
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        FeeValues memory _values = _getValues(tAmount);
        _reflectionBalance[sender] -= _values.rAmount;
        _reflectionBalance[recipient] += _values.rTransferAmount;
        _takeFees(sender, _values);
        _reflectFee(_values.rFee, _values.tFee);
        emit Transfer(sender, recipient, _values.tTransferAmount);
    }

    /// @notice Transfer function that handle transfer to a Excluded address
    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        FeeValues memory _values = _getValues(tAmount);
        _reflectionBalance[sender] -= _values.rAmount;
        _tokenBalance[recipient] += _values.tTransferAmount;
        _reflectionBalance[recipient] += _values.rTransferAmount;
        _takeFees(sender, _values);
        _reflectFee(_values.rFee, _values.tFee);
        emit Transfer(sender, recipient, _values.tTransferAmount);
    }

    /// @notice Transfer function that handle transfer from Excluded address
    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        FeeValues memory _values = _getValues(tAmount);
        _tokenBalance[sender] = _tokenBalance[sender] - tAmount;
        _reflectionBalance[sender] =
            _reflectionBalance[sender] -
            _values.rAmount;
        _reflectionBalance[recipient] =
            _reflectionBalance[recipient] +
            _values.rTransferAmount;
        _takeFees(sender, _values);
        _reflectFee(_values.rFee, _values.tFee);
        emit Transfer(sender, recipient, _values.tTransferAmount);
    }

    /**
     * @notice This function is used to send the fees directly to the contractAddress
     * @dev This function use a handler that is _takeFee that calculates the amount sended from _takeFees
     * @param sender Address of the sender (from)
     * @param values The fee values of (tFee, tLiquidiy, tBuyBurn, tReserve)
     */
    function _takeFees(address sender, FeeValues memory values) private {
        _takeFee(
            sender,
            values.tLiquidity + values.tBuyBurn + values.tReserve,
            address(this)
        );
    }

    /**
     * @notice This function is used to calculate the fee Amount
     * @param sender Address of the sender (from)
     * @param tAmount The amount of fee tokens to be transferred
     * @param recipient Address of the recipient (to)
     */
    function _takeFee(
        address sender,
        uint256 tAmount,
        address recipient
    ) private {
        if (recipient == address(0)) return;
        if (tAmount == 0) return;

        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount * currentRate;
        _reflectionBalance[recipient] += rAmount;
        if (_isExcludedFromRewards[recipient])
            _tokenBalance[recipient] += tAmount;

        emit Transfer(sender, recipient, tAmount);
    }

    /**
     * @notice This is used to autoswap when the threshold is reached
     * @dev Used to change the status of the contract swap. (true/false)
     * @param newValue The new status of the contract swap
     */
    function updateContractSwapEnabled(bool newValue) public onlyOwner {
        contractSwapEnabled = newValue;
    }

    /**
     * @notice This function is used to Update the Max Gas Price Limit for transactions
     * @dev This function is used inside the tokenTransfer during the first hour of the contract
     * @param newValue uint256 The new Max Gas Price Limit
     */
    function updateMaxGasPriceLimit(uint256 newValue) public onlyOwner {
        require(
            newValue >= 10000000000,
            "max gas price cant be lower than 10 gWei"
        );
        maxGasPriceLimit = newValue;
    }

    /**
     * @dev This function is used to update the Swap Threshold limit amount
     * @param newThreshold uint256 The new Swap Threshold limit amount
     */
    function updateSwapThreshold(uint256 newThreshold) public onlyOwner {
        swapThreshold = newThreshold;
    }

    /**
     * @notice Used to swap the fees tokens for busd
     * @dev This function is a _transfer middleware that handles
     *      the conversion of the fees that were retained in the contract.
     *      It uses a threshold to exchange directly to the Management fees.
     */

    function contractSwap() internal swapping {
        uint256 numTokensToSwap = balanceOf(address(this));

        // cancel swap if fees are zero
        if (_ratios.total == 0) {
            return;
        }

        // check allowances // todo
        if (
            _allowances[address(this)][address(midasMultiNetworkRouter)] !=
            type(uint256).max
        ) {
            _approve(
                address(this),
                address(midasMultiNetworkRouter),
                type(uint256).max
            );
            IERC20(busdAddress).approve(
                address(midasMultiNetworkRouter),
                type(uint256).max
            );
        }

        // calculate percentage to bsud reserver and manual buyback and burn
        uint256 tokensToliquidityAmount = (numTokensToSwap *
            _ratios.liquidityRatio) / (_ratios.total);
        uint256 tokensToBuyBurnAmount = (numTokensToSwap *
            _ratios.buyBurnRatio) / (_ratios.total);
        uint256 busdReserveAmount = (numTokensToSwap *
            _ratios.busdReserveRatio) / (_ratios.total);
        // swap tokens for busd and send to busd liquidity address
        if (tokensToliquidityAmount > 0) {
            address[] memory tokensBusdPath = getPathForTokensToTokens(
                address(this),
                busdAddress
            );
            IERC20(busdAddress).approve(
                address(midasMultiNetworkRouter),
                numTokensToSwap
            );

            midasMultiNetworkRouter
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tokensToliquidityAmount,
                    0,
                    tokensBusdPath,
                    busdForLiquidityAddress,
                    block.timestamp + 600
                );
        }

        // swap tokens for busd and send to manual busd buyback and burn address
        if (tokensToBuyBurnAmount > 0) {
            address[] memory tokensBusdPath = getPathForTokensToTokens(
                address(this),
                busdAddress
            );
            IERC20(busdAddress).approve(
                address(midasMultiNetworkRouter),
                numTokensToSwap
            );

            midasMultiNetworkRouter
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tokensToBuyBurnAmount,
                    0,
                    tokensBusdPath,
                    busdBuyBurnAddress,
                    block.timestamp + 600
                );
        }

        // swap tokens for busd and send to manual busd buyback and burn address
        if (busdReserveAmount > 0) {
            address[] memory tokensBusdPath = getPathForTokensToTokens(
                address(this),
                busdAddress
            );
            IERC20(busdAddress).approve(
                address(midasMultiNetworkRouter),
                numTokensToSwap
            );

            midasMultiNetworkRouter
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    busdReserveAmount,
                    0,
                    tokensBusdPath,
                    busdReserveAddress,
                    block.timestamp + 600
                );
        }
    }

    /**
     * @notice This function receives the reservations and returns them in an array
     * @return uint256[] - [busdReserve, tokenReserve]
     */

    function getReserves() public view returns (uint256[] memory) {
        IUniswapV2Pair pair = IUniswapV2Pair(lpPair);
        (uint256 res0, uint256 res1, ) = pair.getReserves();

        uint256[] memory reserves = new uint256[](2);
        reserves[0] = res0;
        reserves[1] = res1;

        return reserves;
    }

    function getTokenPrice(uint256 amount) public view returns (uint256) {
        uint256[] memory reserves = getReserves();
        uint256 res0 = reserves[0] * (10**_decimals);
        return ((amount * res0) / reserves[1]);
    }

    /// @notice return amount of tokenA needed to buy 1 tokenB
    function getOutEstimatedTokensForTokens(
        address tokenAddressA,
        address tokenAddressB,
        uint256 amount
    ) public view returns (uint256) {
        return
            midasMultiNetworkRouter.getAmountsOut(
                amount,
                getPathForTokensToTokens(tokenAddressA, tokenAddressB)
            )[1];
    }

    /// @notice return amount of tokenA needed to sell 1 tokenB
    function getInEstimatedTokensForTokens(
        address tokenAddressA,
        address tokenAddressB,
        uint256 amount
    ) public view returns (uint256) {
        return
            midasMultiNetworkRouter.getAmountsIn(
                amount,
                getPathForTokensToTokens(tokenAddressA, tokenAddressB)
            )[1];
    }

    /// @notice return the route given the busd addresses and the token
    function getPathForTokensToTokens(
        address tokenAddressA,
        address tokenAddressB
    ) private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = tokenAddressA;
        path[1] = tokenAddressB;
        return path;
    }

    /**
     * @dev Function used to burn torkens
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) public {
        require(amount >= 0, "Burn amount should be greater than zero");
        require(
            amount <= balanceOf(msg.sender),
            "Burn amount should be less than account balance"
        );

        _burnNoFee(msg.sender, amount);
        emit Burn(msg.sender, amount);
    }

    /**
     * @dev Burn tokens without fee, send to zero address and decreate total supply,
     *      emit a event Burn with two parameters `address` and `uint256`
     * @param sender Address of the sender (from)
     * @param amount uint256 The amount in wei of tokens to transfer
     *
     */
    function _burnNoFee(address sender, uint256 amount) private {
        _transferNoFee(sender, deadAddress, amount);
    }

    // reflection -------------------------------------------------------------------------------------------

    /**
     * @dev This function is used to get the reflection amount
     * @param tAmount Amount of tokens to get reflection for
     */
    function reflectionFromToken(uint256 tAmount)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _totalSupply, "Amount must be less than supply");
        FeeValues memory _values = _getValues(tAmount);
        return _values.rAmount;
    }

    /**
     * @dev Get the current rate for the given amount of tokens
     * @param rAmount Amount of tokens to get rate for
     */
    function tokenFromReflection(uint256 rAmount)
        internal
        view
        returns (uint256)
    {
        require(rAmount <= _reflectionSupply, "Amt must be less than tot refl");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    /**
     * @notice This function is used to grant access to the rewards
     *         again.
     * @dev Include address in the Reward List again
     * @param account Address of the account to add to the list
     */
    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromRewards[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenBalance[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    /**
     * @notice Exclude account from reward distribution and add to the
     *         excluded list
     * @param account Address of the account to exclude
     */
    function _excludeFromRewards(address account) internal {
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(
                _reflectionBalance[account]
            );
        }
        _isExcludedFromRewards[account] = true;
        _excluded.push(account);
    }

    /**
     * @dev Substract rFee from rTotal and add tFee to tFeeTotal
     * @param rFee Amount of reflection to substract from rTotal
     * @param tFee Amount of tokens to add to tFeeTotal
     */
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _reflectionSupply -= rFee;
        _tFeeTotal += tFee;
    }

    /**
     * @notice Function to calculate the extra fees for the given amount of tokens
     * @dev This function uses too the functions `_getRValues` and `_getTValues`
     * @param tAmount Amount of tokens to get fees for
     */
    function _getValues(uint256 tAmount)
        private
        view
        returns (FeeValues memory)
    {
        tFeeValues memory tValues = _getTValues(tAmount);
        // add all extra fees
        uint256 tTransferFee = tValues.tLiquidity +
            tValues.tBuyBurn +
            tValues.tReserve;
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tValues.tFee,
            tTransferFee,
            _getRate()
        );

        return
            FeeValues(
                rAmount,
                rTransferAmount,
                rFee,
                tValues.tTransferAmount,
                tValues.tFee,
                tValues.tLiquidity,
                tValues.tBuyBurn,
                tValues.tReserve
            );
    }

    /**
     * @notice Function to calculate the fees from a given inputs
     * @param tAmount Amount of tokens to get fees for
     * @param tFee Amount of tokens to get fees for
     * @param tTransferFee Amount of tokens to get fees for
     * @param currentRate Current rate of the token
     * @return uint256 Current rAmount multiplied by CurrentRate
     * @return uint256 Current rTransferAmount
     * @return uint256 Current rFee multiplied by CurrentRate
     */
    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTransferFee,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rTransferFee = tTransferFee * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rTransferFee;
        return (rAmount, rTransferAmount, rFee);
    }

    /**
     * @notice Calculate the base fees from tFeeValues
     * @param tAmount Amount of tokens to get fees for
     * @return tFeeValues - tFeeValues with base fees
     */
    function _getTValues(uint256 tAmount)
        private
        view
        returns (tFeeValues memory)
    {
        tFeeValues memory tValues = tFeeValues(
            0,
            calculateFee(tAmount, _taxRates.distributionToHoldersFee),
            calculateFee(tAmount, _taxRates.liquidityFee),
            calculateFee(tAmount, _taxRates.buyBackFee),
            calculateFee(tAmount, _taxRates.busdReserveFee)
        );

        tValues.tTransferAmount =
            tAmount -
            tValues.tFee -
            tValues.tLiquidity -
            tValues.tBuyBurn -
            tValues.tReserve;
        return tValues;
    }

    /**
     * @notice This function is used to calculate the base fees
     * @dev Calculate fee with the formula `amount * fee / (10 ** 4)`
     * @param _amount Amount of tokens to be calculated
     * @param _fee Fee to be used to calculate the fee
     * @return uint256 Fee calculated
     */
    function calculateFee(uint256 _amount, uint256 _fee)
        private
        pure
        returns (uint256)
    {
        if (_fee == 0) return 0;
        return (_amount * _fee) / 10**4;
    }

    /**
     * @notice Get the actual rate of the token
     * @return uint256 Current rate of the token
     */
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    /**
     * @notice Get the current supply of the token
     * @return uint256 Current rSupply
     * @return uint256 Current tSupply
     */
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _reflectionSupply;
        uint256 tSupply = _totalSupply;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectionBalance[_excluded[i]] > rSupply ||
                _tokenBalance[_excluded[i]] > tSupply
            ) return (_reflectionSupply, _totalSupply);
            rSupply = rSupply - _reflectionBalance[_excluded[i]];
            tSupply = tSupply - _tokenBalance[_excluded[i]];
        }
        if (rSupply < _reflectionSupply / _totalSupply)
            return (_reflectionSupply, _totalSupply);
        return (rSupply, tSupply);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./IJoeRouter02.sol";

interface IMidasMultiNetworkRouter is IUniswapV2Router02, IJoeRouter02 {
    // ROUTER V1
    function factory()
        external
        pure
        override(IUniswapV2Router01, IJoeRouter01)
        returns (address);

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
        override(IUniswapV2Router01, IJoeRouter01)
        returns (
            uint256 amountA,
            uint256 amountB,
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
    )
        external
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256 amountA, uint256 amountB);

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
    )
        external
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    )
        external
        pure
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    )
        external
        pure
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    )
        external
        pure
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256[] memory amounts);

    // ROUTER V2 ------------------------------------------------------------------
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override(IUniswapV2Router02, IJoeRouter02);

    // custom
    
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address lpPair);

    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IBridgeToken {
    function mintBridge(address to, uint256 amount) external;

    function burnBridge(address owner, uint256 amount) external;

    function updateBridges(address bridgeAddress, bool newVal) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

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

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountAVAX,
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

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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