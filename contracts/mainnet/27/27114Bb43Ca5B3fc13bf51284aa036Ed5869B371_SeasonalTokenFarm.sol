//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";

import "./INonfungiblePositionManager.sol";

/*
 * Seasonal Token Farm
 *
 * This contract receives donations of seasonal tokens and distributes them to providers of liquidity
 * for the token/MATIC trading pairs on Uniswap v3.
 *
 * Warning: Tokens can be lost if they are not transferred to the farm contract in the correct way.
 *
 * Seasonal tokens must be approved for use by the farm contract and donated using the 
 * receiveSeasonalTokens() function. Tokens sent directly to the farm address will be lost.
 *
 * Contracts that deposit Uniswap liquidity tokens need to implement the onERC721Received() function in order
 * to be able to withdraw those tokens. Any contracts that interact with the farm must be tested prior to 
 * deployment on the main network.
 * 
 * The developers accept no responsibility for tokens irretrievably lost in accidental transfers.
 * 
 */

struct LiquidityToken {
    address owner;
    address seasonalToken;
    uint256 depositTime;
    uint256 initialCumulativeSpringTokensFarmed;
    uint256 initialCumulativeSummerTokensFarmed;
    uint256 initialCumulativeAutumnTokensFarmed;
    uint256 initialCumulativeWinterTokensFarmed;
    uint256 liquidity;
}


contract SeasonalTokenFarm is IERC721Receiver, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant REALLOCATION_INTERVAL = (365 * 24 * 60 * 60 * 3) / 4;

    int24 public constant REQUIRED_TICK_UPPER = 887272;
    int24 public constant REQUIRED_TICK_LOWER = -887272;

    uint256 public constant WITHDRAWAL_UNAVAILABLE_DAYS = 30;
    uint256 public constant WITHDRAWAL_AVAILABLE_DAYS = 7;

    mapping(address => uint256) public totalLiquidity;

    mapping(address => EnumerableSet.UintSet) tokenOfOwnerByIndex;
    mapping(uint256 => LiquidityToken) public liquidityTokens;

    address public immutable springTokenAddress;
    address public immutable summerTokenAddress;
    address public immutable autumnTokenAddress;
    address public immutable winterTokenAddress;
    address public immutable wethAddress;

    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    uint256 public immutable startTime;

    mapping(address => mapping(address => uint256)) public cumulativeTokensFarmedPerUnitLiquidity;

    event Deposit(address indexed from, uint256 liquidityTokenId);
    event Withdraw(address indexed tokenOwner, uint256 liquidityTokenId);
    event Donate(address indexed from, address seasonalTokenAddress, uint256 amount);
    event Harvest(address indexed tokenOwner, uint256 liquidityTokenId, 
                  uint256 springAmount, uint256 summerAmount, uint256 autumnAmount, uint256 winterAmount);


    constructor (INonfungiblePositionManager _nonfungiblePositionManager,
                 address _springTokenAddress,
                 address _summerTokenAddress,
                 address _autumnTokenAddress,
                 address _winterTokenAddress,
                 address _wethAddress,
                 uint256 _startTime) {

        require(_startTime < block.timestamp, 'Invalid start time');

        nonfungiblePositionManager = _nonfungiblePositionManager;
        springTokenAddress = _springTokenAddress;
        summerTokenAddress = _summerTokenAddress;
        autumnTokenAddress = _autumnTokenAddress;
        winterTokenAddress = _winterTokenAddress;
        wethAddress = _wethAddress;
        startTime = _startTime;
    }

    function balanceOf(address _liquidityProvider) external view returns (uint256) {
        return tokenOfOwnerByIndex[_liquidityProvider].length();
    }

    function numberOfReAllocations() public view returns (uint256) {
        if (block.timestamp < startTime + REALLOCATION_INTERVAL)
            return 0;
        uint256 timeSinceStart = block.timestamp - startTime;
        return timeSinceStart / REALLOCATION_INTERVAL;
    }

    function hasDoubledAllocation(uint256 _tokenNumber) internal view returns (uint256) {
        return (numberOfReAllocations() % 4 < _tokenNumber) ? 0 : 1;
    }

    function springAllocationSize() public view returns (uint256) {
        return 5 * 2 ** hasDoubledAllocation(1);
    }

    function summerAllocationSize() public view returns (uint256) {
        return 6 * 2 ** hasDoubledAllocation(2);
    }

    function autumnAllocationSize() public view returns (uint256) {
        return 7 * 2 ** hasDoubledAllocation(3);
    }

    function winterAllocationSize() public pure returns (uint256) {
        return 8;
    }

    function getValueFromTokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        return tokenOfOwnerByIndex[_owner].at(_index);
    }

    function getEffectiveTotalAllocationSize(uint256 _totalSpringLiquidity,
                                             uint256 _totalSummerLiquidity,
                                             uint256 _totalAutumnLiquidity,
                                             uint256 _totalWinterLiquidity) public view returns (uint256) {
        uint256 effectiveTotal = 0;
        if (_totalSpringLiquidity > 0)
            effectiveTotal += springAllocationSize();
        if (_totalSummerLiquidity > 0)
            effectiveTotal += summerAllocationSize();
        if (_totalAutumnLiquidity > 0)
            effectiveTotal += autumnAllocationSize();
        if (_totalWinterLiquidity > 0)
            effectiveTotal += winterAllocationSize();
        return effectiveTotal;
    }

    function allocateIncomingTokensToTradingPairs(address _incomingTokenAddress, uint256 _amount) internal {

        uint256 totalSpringLiquidity = totalLiquidity[springTokenAddress];
        uint256 totalSummerLiquidity = totalLiquidity[summerTokenAddress];
        uint256 totalAutumnLiquidity = totalLiquidity[autumnTokenAddress];
        uint256 totalWinterLiquidity = totalLiquidity[winterTokenAddress];

        uint256 effectiveTotalAllocationSize = getEffectiveTotalAllocationSize(totalSpringLiquidity,
                                                                               totalSummerLiquidity,
                                                                               totalAutumnLiquidity,
                                                                               totalWinterLiquidity);

        require(effectiveTotalAllocationSize > 0, "No liquidity in farm");

        uint256 springPairAllocation = (_amount * springAllocationSize()) / effectiveTotalAllocationSize;
        uint256 summerPairAllocation = (_amount * summerAllocationSize()) / effectiveTotalAllocationSize;
        uint256 autumnPairAllocation = (_amount * autumnAllocationSize()) / effectiveTotalAllocationSize;
        uint256 winterPairAllocation = (_amount * winterAllocationSize()) / effectiveTotalAllocationSize;

        if (totalSpringLiquidity > 0)
            cumulativeTokensFarmedPerUnitLiquidity[springTokenAddress][_incomingTokenAddress]
                += (2 ** 128) * springPairAllocation / totalSpringLiquidity;

        if (totalSummerLiquidity > 0)
            cumulativeTokensFarmedPerUnitLiquidity[summerTokenAddress][_incomingTokenAddress]
                += (2 ** 128) * summerPairAllocation / totalSummerLiquidity;

        if (totalAutumnLiquidity > 0)
            cumulativeTokensFarmedPerUnitLiquidity[autumnTokenAddress][_incomingTokenAddress]
                += (2 ** 128) * autumnPairAllocation / totalAutumnLiquidity;

        if (totalWinterLiquidity > 0)
            cumulativeTokensFarmedPerUnitLiquidity[winterTokenAddress][_incomingTokenAddress]
                += (2 ** 128) * winterPairAllocation / totalWinterLiquidity;
    }

    function receiveSeasonalTokens(address from, address _tokenAddress, uint256 _amount) public nonReentrant {

        require(_tokenAddress == springTokenAddress || _tokenAddress == summerTokenAddress
                || _tokenAddress == autumnTokenAddress || _tokenAddress == winterTokenAddress,
                "Only Seasonal Tokens can be donated");

        require(msg.sender == from, "Tokens must be donated by the address that owns them.");

        allocateIncomingTokensToTradingPairs(_tokenAddress, _amount);

        emit Donate(from, _tokenAddress, _amount);

        IERC20(_tokenAddress).safeTransferFrom(from, address(this), _amount);
    }

    function onERC721Received(address _operator, address _from, uint256 _liquidityTokenId, bytes calldata _data)
                             external override returns(bytes4) {

        require(msg.sender == address(nonfungiblePositionManager), 
                "Only Uniswap v3 liquidity tokens can be deposited");

        LiquidityToken memory liquidityToken = getLiquidityToken(_liquidityTokenId);
        
        liquidityToken.owner = _from;
        liquidityToken.depositTime = block.timestamp;

        tokenOfOwnerByIndex[_from].add(_liquidityTokenId);

        liquidityToken.initialCumulativeSpringTokensFarmed
            = cumulativeTokensFarmedPerUnitLiquidity[liquidityToken.seasonalToken][springTokenAddress];

        liquidityToken.initialCumulativeSummerTokensFarmed
            = cumulativeTokensFarmedPerUnitLiquidity[liquidityToken.seasonalToken][summerTokenAddress];

        liquidityToken.initialCumulativeAutumnTokensFarmed
            = cumulativeTokensFarmedPerUnitLiquidity[liquidityToken.seasonalToken][autumnTokenAddress];

        liquidityToken.initialCumulativeWinterTokensFarmed
            = cumulativeTokensFarmedPerUnitLiquidity[liquidityToken.seasonalToken][winterTokenAddress];

        liquidityTokens[_liquidityTokenId] = liquidityToken;
        totalLiquidity[liquidityToken.seasonalToken] += liquidityToken.liquidity;

        emit Deposit(_from, _liquidityTokenId);

        _data; _operator; // suppress unused variable compiler warnings
        return IERC721Receiver.onERC721Received.selector;
    }

    function getLiquidityToken(uint256 _tokenId) internal view returns(LiquidityToken memory) {

        LiquidityToken memory liquidityToken;
        address token0;
        address token1;
        int24 tickLower;
        int24 tickUpper;
        uint256 liquidity;
        uint24 fee;
        
        (token0, token1, fee, tickLower, tickUpper, liquidity) = getPositionDataForLiquidityToken(_tokenId);
        liquidityToken.liquidity = liquidity;
        
        if (token0 == wethAddress)
            liquidityToken.seasonalToken = token1;
        else if (token1 == wethAddress)
            liquidityToken.seasonalToken = token0;

        require(liquidityToken.seasonalToken == springTokenAddress ||
                liquidityToken.seasonalToken == summerTokenAddress ||
                liquidityToken.seasonalToken == autumnTokenAddress ||
                liquidityToken.seasonalToken == winterTokenAddress,
                "Invalid trading pair");

        require(tickLower == REQUIRED_TICK_LOWER && tickUpper == REQUIRED_TICK_UPPER,
                "Liquidity must cover full range of prices");

        require(fee == 100, "Fee tier must be 0.01%");

        return liquidityToken;
    }

    function getPositionDataForLiquidityToken(uint256 _tokenId)
                                             internal view returns (address, address, uint24, int24, int24, uint256){
        address token0;
        address token1;
        int24 tickLower;
        int24 tickUpper;
        uint256 liquidity;
        uint24 fee;

        (,, token0, token1, fee, tickLower, tickUpper, liquidity,,,,) 
            = nonfungiblePositionManager.positions(_tokenId);

        return (token0, token1, fee, tickLower, tickUpper, liquidity);
    }

    function setCumulativeSpringTokensFarmedToCurrentValue(uint256 _liquidityTokenId, address _seasonalToken) internal {
        liquidityTokens[_liquidityTokenId].initialCumulativeSpringTokensFarmed
            = cumulativeTokensFarmedPerUnitLiquidity[_seasonalToken][springTokenAddress];
    }

    function setCumulativeSummerTokensFarmedToCurrentValue(uint256 _liquidityTokenId, address _seasonalToken) internal {
        liquidityTokens[_liquidityTokenId].initialCumulativeSummerTokensFarmed
            = cumulativeTokensFarmedPerUnitLiquidity[_seasonalToken][summerTokenAddress];
    }

    function setCumulativeAutumnTokensFarmedToCurrentValue(uint256 _liquidityTokenId, address _seasonalToken) internal {
        liquidityTokens[_liquidityTokenId].initialCumulativeAutumnTokensFarmed
            = cumulativeTokensFarmedPerUnitLiquidity[_seasonalToken][autumnTokenAddress];
    }

    function setCumulativeWinterTokensFarmedToCurrentValue(uint256 _liquidityTokenId, address _seasonalToken) internal {
        liquidityTokens[_liquidityTokenId].initialCumulativeWinterTokensFarmed
            = cumulativeTokensFarmedPerUnitLiquidity[_seasonalToken][winterTokenAddress];
    }

    function getPayoutSize(uint256 _liquidityTokenId, address _farmedSeasonalToken,
                           address _tradingPairSeasonalToken) internal view returns (uint256) {

        uint256 initialCumulativeTokensFarmed;

        if (_farmedSeasonalToken == springTokenAddress)
            initialCumulativeTokensFarmed = liquidityTokens[_liquidityTokenId].initialCumulativeSpringTokensFarmed;
        else if (_farmedSeasonalToken == summerTokenAddress)
            initialCumulativeTokensFarmed = liquidityTokens[_liquidityTokenId].initialCumulativeSummerTokensFarmed;
        else if (_farmedSeasonalToken == autumnTokenAddress)
            initialCumulativeTokensFarmed = liquidityTokens[_liquidityTokenId].initialCumulativeAutumnTokensFarmed;
        else
            initialCumulativeTokensFarmed = liquidityTokens[_liquidityTokenId].initialCumulativeWinterTokensFarmed;

        uint256 tokensFarmedPerUnitLiquiditySinceDeposit 
            = cumulativeTokensFarmedPerUnitLiquidity[_tradingPairSeasonalToken][_farmedSeasonalToken]
              - initialCumulativeTokensFarmed;

        return (tokensFarmedPerUnitLiquiditySinceDeposit 
                * liquidityTokens[_liquidityTokenId].liquidity) / (2 ** 128);
    }

    function getPayoutSizes(uint256 _liquidityTokenId) external view returns (uint256, uint256, uint256, uint256) {

        address tradingPairSeasonalToken = liquidityTokens[_liquidityTokenId].seasonalToken;

        uint256 springPayout = getPayoutSize(_liquidityTokenId, springTokenAddress, tradingPairSeasonalToken);
        uint256 summerPayout = getPayoutSize(_liquidityTokenId, summerTokenAddress, tradingPairSeasonalToken);
        uint256 autumnPayout = getPayoutSize(_liquidityTokenId, autumnTokenAddress, tradingPairSeasonalToken);
        uint256 winterPayout = getPayoutSize(_liquidityTokenId, winterTokenAddress, tradingPairSeasonalToken);

        return (springPayout, summerPayout, autumnPayout, winterPayout);
    }

    function harvestSpring(uint256 _liquidityTokenId, address _tradingPairSeasonalToken) internal returns(uint256) {

        uint256 amount = getPayoutSize(_liquidityTokenId, springTokenAddress, _tradingPairSeasonalToken);
        setCumulativeSpringTokensFarmedToCurrentValue(_liquidityTokenId, _tradingPairSeasonalToken);
        return amount;
    }

    function harvestSummer(uint256 _liquidityTokenId, address _tradingPairSeasonalToken) internal returns(uint256) {

        uint256 amount = getPayoutSize(_liquidityTokenId, summerTokenAddress, _tradingPairSeasonalToken);
        setCumulativeSummerTokensFarmedToCurrentValue(_liquidityTokenId, _tradingPairSeasonalToken);
        return amount;
    }

    function harvestAutumn(uint256 _liquidityTokenId, address _tradingPairSeasonalToken) internal returns(uint256) {

        uint256 amount = getPayoutSize(_liquidityTokenId, autumnTokenAddress, _tradingPairSeasonalToken);
        setCumulativeAutumnTokensFarmedToCurrentValue(_liquidityTokenId, _tradingPairSeasonalToken);
        return amount;
    }

    function harvestWinter(uint256 _liquidityTokenId, address _tradingPairSeasonalToken) internal returns(uint256) {

        uint256 amount = getPayoutSize(_liquidityTokenId, winterTokenAddress, _tradingPairSeasonalToken);
        setCumulativeWinterTokensFarmedToCurrentValue(_liquidityTokenId, _tradingPairSeasonalToken);
        return amount;
    }

    function harvestAll(uint256 _liquidityTokenId, address _tradingPairSeasonalToken)
            internal returns (uint256, uint256, uint256, uint256) {

        uint256 springAmount = harvestSpring(_liquidityTokenId, _tradingPairSeasonalToken);
        uint256 summerAmount = harvestSummer(_liquidityTokenId, _tradingPairSeasonalToken);
        uint256 autumnAmount = harvestAutumn(_liquidityTokenId, _tradingPairSeasonalToken);
        uint256 winterAmount = harvestWinter(_liquidityTokenId, _tradingPairSeasonalToken);

        return (springAmount, summerAmount, autumnAmount, winterAmount);
    }

    function sendHarvestedTokensToOwner(address _tokenOwner, uint256 _springAmount, uint256 _summerAmount,
                                        uint256 _autumnAmount, uint256 _winterAmount) internal {

        if (_springAmount > 0)
            IERC20(springTokenAddress).transfer(_tokenOwner, _springAmount);
        if (_summerAmount > 0)
            IERC20(summerTokenAddress).transfer(_tokenOwner, _summerAmount);
        if (_autumnAmount > 0)
            IERC20(autumnTokenAddress).transfer(_tokenOwner, _autumnAmount);
        if (_winterAmount > 0)
            IERC20(winterTokenAddress).transfer(_tokenOwner, _winterAmount);
    }

    function harvest(uint256 _liquidityTokenId) external {
        
        LiquidityToken storage liquidityToken = liquidityTokens[_liquidityTokenId];
        require(msg.sender == liquidityToken.owner, "Only owner can harvest");
        
        (uint256 springAmount, 
         uint256 summerAmount,
         uint256 autumnAmount,
         uint256 winterAmount) = harvestAll(_liquidityTokenId, liquidityToken.seasonalToken);

        emit Harvest(msg.sender, _liquidityTokenId, springAmount, summerAmount, autumnAmount, winterAmount);
        
        sendHarvestedTokensToOwner(msg.sender, springAmount, summerAmount, autumnAmount, winterAmount);
    }

    function canWithdraw(uint256 _liquidityTokenId) public view returns (bool) {

        uint256 depositTime = liquidityTokens[_liquidityTokenId].depositTime;
        uint256 timeSinceDepositTime = block.timestamp - depositTime;
        uint256 daysSinceDepositTime = timeSinceDepositTime / (24 * 60 * 60);

        return (daysSinceDepositTime) % (WITHDRAWAL_UNAVAILABLE_DAYS + WITHDRAWAL_AVAILABLE_DAYS) 
                    >= WITHDRAWAL_UNAVAILABLE_DAYS;
    }

    function nextWithdrawalTime(uint256 _liquidityTokenId) external view returns (uint256) {
        
        uint256 depositTime = liquidityTokens[_liquidityTokenId].depositTime;
        uint256 timeSinceDepositTime = block.timestamp - depositTime;
        uint256 withdrawalUnavailableTime = WITHDRAWAL_UNAVAILABLE_DAYS * 24 * 60 * 60;
        uint256 withdrawalAvailableTime = WITHDRAWAL_AVAILABLE_DAYS * 24 * 60 * 60;

        if (timeSinceDepositTime < withdrawalUnavailableTime)
            return depositTime + withdrawalUnavailableTime;

        uint256 numberOfWithdrawalCyclesUntilNextWithdrawalTime 
                    = 1 + (timeSinceDepositTime - withdrawalUnavailableTime) 
                          / (withdrawalUnavailableTime + withdrawalAvailableTime);

        return depositTime + withdrawalUnavailableTime 
                           + numberOfWithdrawalCyclesUntilNextWithdrawalTime
                             * (withdrawalUnavailableTime + withdrawalAvailableTime);
    }

    function withdraw(uint256 _liquidityTokenId) external {

        require(canWithdraw(_liquidityTokenId), "This token cannot be withdrawn at this time");

        LiquidityToken memory liquidityToken = liquidityTokens[_liquidityTokenId];

        require(msg.sender == liquidityToken.owner, "Only owner can withdraw");

        (uint256 springAmount, 
         uint256 summerAmount,
         uint256 autumnAmount,
         uint256 winterAmount) = harvestAll(_liquidityTokenId, liquidityToken.seasonalToken);

        totalLiquidity[liquidityToken.seasonalToken] -= liquidityToken.liquidity;
        removeTokenFromListOfOwnedTokens(msg.sender, _liquidityTokenId);
        
        emit Harvest(msg.sender, _liquidityTokenId, springAmount, summerAmount, autumnAmount, winterAmount);
        emit Withdraw(msg.sender, _liquidityTokenId);

        sendHarvestedTokensToOwner(msg.sender, springAmount, summerAmount, autumnAmount, winterAmount);
        nonfungiblePositionManager.safeTransferFrom(address(this), liquidityToken.owner, _liquidityTokenId);
    }

    function removeTokenFromListOfOwnedTokens(address _owner, uint256 _liquidityTokenId) internal {
        tokenOfOwnerByIndex[_owner].remove(_liquidityTokenId);
        delete liquidityTokens[_liquidityTokenId];
    }

}