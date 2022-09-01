// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

import "./interfaces/IOracle.sol";
import "./interfaces/IMultiAssetPool.sol";
import "./Operator.sol";
import "./interfaces/ICurrencyReserve.sol";
import "./interfaces/ICollateralFund.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IAssetController.sol";
import "./interfaces/IMultiAssetTreasury.sol";
import "./interfaces/IInvestmentController.sol";

contract MultiAssetTreasury is IMultiAssetTreasury, Operator, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    struct CollateralPolicy {
        uint256 target_collateral_ratio;
        uint256 effective_collateral_ratio;
        uint256 price_band;
        uint256 missing_decimals;
    }

    mapping(uint256 => CollateralPolicy) public assetCollateralPolicy;// Map Collateral policy to assetId

    address public override collateralFund;
    address public daoFund;
    address public profitSharingFund;
    address public profitController;
    address public assetController;

    address public share;

    bool public migrated = false;
    bool public initialized = false;

    // Investment Controller => This will using unused collateral for investing in lending protocol or yield to get profit
    IInvestmentController investmentController;

    // pools
    address[] public pools_array;
    mapping(address => bool) public pools;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant RATIO_PRECISION = 1e6;

    // fees
    uint256 public redemption_fee; // 6 decimals of precision
    uint256 public minting_fee; // 6 decimals of precision

    //re-balance function
    uint256 public rebalance_cooldown = 10;
    uint256 public last_rebalance_timestamp;

    //swap router
    address public router;

    // collateral_ratio
    uint256 public last_refresh_cr_timestamp;
    uint256 public refresh_cooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public ratio_step; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint256 public price_target; // The price of DOLLAR at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
    bool public collateral_ratio_paused = false; // during bootstraping phase, collateral_ratio will be fixed at 100%
    bool public using_effective_collateral_ratio = true; // toggle the effective collateral ratio usage
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;
    uint256 public MINIMUM_CRT = 250000;

    uint256 public excess_collateral_safety_margin;
    uint256 public constant EXCESS_COLLATERAL_SAFETY_MARGIN_MIN = 150000;

    /* ========== MODIFIERS ========== */

    modifier notMigrated() {
        require(migrated == false, "migrated");
        _;
    }

    modifier onlyPoolsOrOperator {
        require(pools[msg.sender] || operator() == msg.sender, "Only pools can use this function");
        _;
    }

    modifier onlyProfitController {
        require(
            msg.sender == profitController || msg.sender == operator(),
            "Only profit controller or owner can trigger"
        );
        _;
    }

    modifier checkRebalanceCooldown() {
        uint256 _blockTimestamp = block.timestamp;
        require(_blockTimestamp - last_rebalance_timestamp >= rebalance_cooldown, "<rebalance_cooldown");
        _;
        last_rebalance_timestamp = _blockTimestamp;
    }

    modifier onlyAssetController() {
        require(msg.sender == assetController, "!AssetController");
        _;
    }

    /* ========== EVENTS ============= */
    event TransactionExecuted(address indexed target, uint256 value, string signature, bytes data);
    event ProfitExtracted(uint256 amount);
    event BoughtBackAndBurned(uint256 collateral_value, uint256 collateral_amount, uint256 output_share_amount);
    event Recollateralized(uint256 share_amount, uint256 output_collateral_amount);

    /* ========== CONSTRUCTOR ========== */

    constructor(address _router) public {
        ratio_step = 2500;
        // = 0.25% at 6 decimals of precision

        refresh_cooldown = 3600;
        // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        price_target = 1000000;
        // = $1. (6 decimals of precision). Collateral ratio will adjust according to the $1 price target at genesis
        redemption_fee = 4000;
        minting_fee = 3000;
        router = _router;
    }

    function initializing(address _share, address _collateralFund, address _daoFund, address _assetController) external onlyOperator {
        require(!initialized, "alreadyInitialized");
        share = _share;
        collateralFund = _collateralFund;
        daoFund = _daoFund;
        initialized = true;
        assetController = _assetController;
    }

    /* ========== VIEWS ========== */

    function assetPrice(uint256 _assetId) public view returns (uint256) {
        return IAssetController(assetController).getAssetPrice(_assetId);
    }

    function sharePrice() public view returns (uint256) {
        return IAssetController(assetController).getXSharePrice();
    }

    function assetTcr(uint256 _assetId) public view returns (uint256) {
        return assetCollateralPolicy[_assetId].target_collateral_ratio;
    }

    function assetEcr(uint256 _assetId) public view returns (uint256) {
        return assetCollateralPolicy[_assetId].effective_collateral_ratio;
    }

    function getMissingDecimal(uint256 _assetId) public view returns (uint256) {
        return assetCollateralPolicy[_assetId].missing_decimals;
    }

    function assetPriceBand(uint256 _assetId) public view returns (uint256) {
        return assetCollateralPolicy[_assetId].price_band;
    }

    function hasPool(address _address) external view override returns (bool) {
        return pools[_address] == true;
    }

    function info(uint256 _assetId)
    external
    view
    override
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        uint256 assetTotalSupply = IAssetController(assetController).getAssetTotalSupply(_assetId);
        return (assetPrice(_assetId), sharePrice(), assetTotalSupply, assetTcr(_assetId), assetEcr(_assetId), collateralValue(_assetId), minting_fee, redemption_fee);
    }

    function globalCollateralValue() public view returns (uint256 _global_collateral_value) {
        uint256 _assetCount = IAssetController(assetController).assetCount();
        _global_collateral_value = 0;
        for (uint256 aid = 0; aid < _assetCount; aid++) {
            uint256 collateral_price = IAssetController(assetController).getCollateralPriceInDollar(aid);
            uint256 collateral_value = collateralValue(aid);
            _global_collateral_value = _global_collateral_value.add(collateral_price.mul(collateral_value).div(1e18));
        }
    }

    // Iterate through all pools and calculate all value of collateral in all pools globally
    function globalCollateralBalance(uint256 _assetId) public view override returns (uint256) {
        address _collateral = IAssetController(assetController).getCollateral(_assetId);
        uint256 investedBalance = 0;
        if (address(investmentController) != address(0)) {
            investedBalance = investmentController.collateralBalance(_assetId);
        }
        uint256 _collateralReserveBalance = IERC20(_collateral).balanceOf(collateralFund) + investedBalance;
        return _collateralReserveBalance - totalUnclaimedBalance(_assetId) ;
    }

    function collateralValue(uint256 _assetId) public view override returns (uint256) {
        uint256 _missing_decimals = assetCollateralPolicy[_assetId].missing_decimals;
        return
        (globalCollateralBalance(_assetId) * PRICE_PRECISION * (10 ** _missing_decimals)) /
        PRICE_PRECISION;
    }

    function calcEffectiveCollateralRatio(uint256 _assetId) public view returns (uint256) {
        uint256 _tcr = assetTcr(_assetId);
        if (!using_effective_collateral_ratio) {
            return _tcr;
        }
        uint256 total_collateral_value = collateralValue(_assetId);
        uint256 total_supply_asset = IAssetController(assetController).getAssetTotalSupply(_assetId);
        uint256 ecr = total_collateral_value.mul(PRICE_PRECISION).div(total_supply_asset);
        if (ecr > COLLATERAL_RATIO_MAX) {
            return COLLATERAL_RATIO_MAX;
        }
        return ecr;
    }

    function totalUnclaimedBalance(uint256 _assetId) public view returns (uint256) {
        uint256 _totalUnclaimed = 0;
        for (uint256 i = 0; i < pools_array.length; i++) {
            // Exclude null addresses
            if (pools_array[i] != address(0)) {
                _totalUnclaimed =
                _totalUnclaimed +
                (IMultiAssetPool(pools_array[i]).getUnclaimedCollateral(_assetId));
            }
        }
        return _totalUnclaimed;
    }

    function excessCollateralBalance(uint256 _assetId) public view returns (uint256 _excess) {
        uint256 _tcr = assetTcr(_assetId);
        uint256 _ecr = assetEcr(_assetId);
        if (_ecr <= _tcr) {
            _excess = 0;
        } else {
            _excess = ((_ecr - _tcr) * globalCollateralBalance(_assetId)) / RATIO_PRECISION;
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function refreshCollateralRatio() public {
        require(collateral_ratio_paused == false, "Collateral Ratio has been paused");
        require(block.timestamp - last_refresh_cr_timestamp >= refresh_cooldown, "Must wait for the refresh cooldown since last refresh");
        uint256 assetCount = IAssetController(assetController).assetCount();

        for (uint256 aid = 0; aid < assetCount; aid++) {
            CollateralPolicy storage _collateralPolicy = assetCollateralPolicy[aid];
            IAssetController(assetController).updateOracle(aid);
            uint256 current_asset_price = assetPrice(aid);
            uint256 _tcr = _collateralPolicy.target_collateral_ratio;
            uint256 _ecr = _collateralPolicy.effective_collateral_ratio;
            uint256 _price_band = _collateralPolicy.price_band;
            // Step increments are 0.25% (upon genesis, changable by setRatioStep())
            if (current_asset_price > price_target.add(_price_band)) {
                // decrease collateral ratio
                if (_tcr <= ratio_step) {
                    // if within a step of 0, go to 0
                    _collateralPolicy.target_collateral_ratio = 0;
                } else {
                    _collateralPolicy.target_collateral_ratio = _tcr.sub(ratio_step);
                }
            }
            // IRON price is below $1 - `price_band`. Need to increase `collateral_ratio`
            else if (current_asset_price < price_target.sub(_price_band)) {
                // increase collateral ratio
                if (_tcr.add(ratio_step) >= COLLATERAL_RATIO_MAX) {
                    _collateralPolicy.target_collateral_ratio = COLLATERAL_RATIO_MAX;
                    // cap collateral ratio at 1.000000
                } else {
                    _collateralPolicy.target_collateral_ratio = _tcr.add(ratio_step);
                }
            }

            // If using ECR, then calcECR. If not, update ECR = TCR
            if (using_effective_collateral_ratio) {
                _collateralPolicy.effective_collateral_ratio = calcEffectiveCollateralRatio(aid);
            } else {
                _collateralPolicy.effective_collateral_ratio = _collateralPolicy.target_collateral_ratio;
            }
        }

        last_refresh_cr_timestamp = block.timestamp;
    }

    // Check if the protocol is over- or under-collateralized, by how much
    function calcCollateralBalance(uint256 _assetId) public view returns (uint256 _collateral_value, bool _exceeded) {
        uint256 total_collateral_value = collateralValue(_assetId);
        uint256 asset_total_supply = IAssetController(assetController).getAssetTotalSupply(_assetId);
        uint256 target_collateral_value = asset_total_supply.mul(assetCollateralPolicy[_assetId].target_collateral_ratio).div(PRICE_PRECISION);
        if (total_collateral_value >= target_collateral_value) {
            _collateral_value = total_collateral_value.sub(target_collateral_value);
            _exceeded = true;
        } else {
            _collateral_value = target_collateral_value.sub(total_collateral_value);
            _exceeded = false;
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    //Transfer fund from Collateral Fund to Pools
    function requestTransfer(
        address _token,
        address _receiver,
        uint256 _amount
    ) external override onlyPoolsOrOperator {
        ICollateralFund(collateralFund).transferTo(_token, _receiver, _amount);
    }

    function extractProfit(uint256 _amount, uint256 _assetId) external onlyProfitController {
        require(_amount > 0, "zero amount");
        require(profitSharingFund != address(0), "Invalid profitSharingFund");
        uint256 _maxExcess = excessCollateralBalance(_assetId);
        uint256 _maxAllowableAmount = _maxExcess - ((_maxExcess * excess_collateral_safety_margin) / RATIO_PRECISION);
        require(_amount <= _maxAllowableAmount, "Excess allowable amount");
        address _collateral = IAssetController(assetController).getCollateral(_assetId);
        ICollateralFund(collateralFund).transferTo(_collateral, profitSharingFund, _amount);
        emit ProfitExtracted(_amount);
    }

    //Extract to internal functino to avoid "Stack Too Deep" exception
    function calcCollateralValue(uint256 _collateral_amount, uint256 _assetId) internal view returns (uint256 _collateral_value) {
        uint256 _missing_decimals = getMissingDecimal(_assetId);
        bool isStable = IAssetController(assetController).isAssetStable(_assetId);
        _collateral_value = _collateral_amount.mul(10 ** _missing_decimals);

        if (!isStable) {
            uint256 _collateral_exchange_price = IAssetController(assetController).getCollateralPriceInDollar(_assetId);
            _collateral_value = _collateral_amount.mul(_collateral_exchange_price).div(PRICE_PRECISION);
        }
    }

    // Use excess collateral to buy back Alpha, then using Alpha to buy back xShare and burn
    function buyback(uint256 _collateral_amount, uint256 _min_share_amount, uint256 _min_asset_out, uint256 _assetId) external override onlyOperator notMigrated checkRebalanceCooldown {
        (uint256 _excess_collateral_value, bool _exceeded) = calcCollateralBalance(_assetId);
        require(_exceeded && _excess_collateral_value > 0, "!exceeded");
        uint256 _collateral_value = calcCollateralValue(_collateral_amount, _assetId);
        require(_collateral_amount > 0 && _collateral_value < _excess_collateral_value, "Invalid collateral amount");
        address _collateral = IAssetController(assetController).getCollateral(_assetId);
        address _asset = IAssetController(assetController).getAsset(_assetId);
        ICollateralFund(collateralFund).transferTo(_collateral, address(this), _collateral_amount);
        uint256 _assetPrice = assetPrice(_assetId);
        //
        uint256 out_asset_amount = _swap(_collateral, _asset, _collateral_amount, _min_asset_out);
        // Buy back share with dollar
        uint256 out_xShare_amount = _swap(_asset, share, out_asset_amount, _min_share_amount);

        ERC20Burnable(share).burn(out_xShare_amount);
        emit BoughtBackAndBurned(_collateral_amount, _collateral_amount, out_xShare_amount);
    }

    // Transfer xShare from Dao Fund to sell and recollateraliza
    function recollateralize(uint256 _share_amount, uint256 _min_collateral_amount, uint256 _assetId) external override onlyOperator notMigrated checkRebalanceCooldown {
        (uint256 _deficit_collateral_value, bool _exceeded) = calcCollateralBalance(_assetId);
        require(!_exceeded && _deficit_collateral_value > 0, "exceeded");
        require(_min_collateral_amount <= _deficit_collateral_value, ">deficit");
        (address _asset, address _collateral, ,) = IAssetController(assetController).getAssetInfo(_assetId);
        uint256 _share_balance = IERC20(share).balanceOf(daoFund);
        require(_share_amount <= _share_balance, ">shareBalance");
        ICurrencyReserve(daoFund).transferTo(share, address(this), _share_amount);
        uint256 out_collateral_amount = _swap(share, _collateral, _share_amount, _min_collateral_amount);
        // Transfer collateral from Treasury to Pool
        IERC20(_collateral).transfer(collateralFund, out_collateral_amount);
        emit Recollateralized(_share_amount, out_collateral_amount);
    }

    // Add asset
    function addCollateralPolicy(uint256 _aid, uint256 _price_band, uint256 _missing_decimals, uint256 _init_tcr, uint256 _init_ecr) external override onlyAssetController {
        CollateralPolicy storage _collateralPolicy = assetCollateralPolicy[_aid];
        _collateralPolicy.target_collateral_ratio = _init_tcr;
        _collateralPolicy.effective_collateral_ratio = _init_ecr;
        _collateralPolicy.price_band = _price_band;
        _collateralPolicy.missing_decimals = _missing_decimals;
    }

    // Add new Pool
    function addPool(address pool_address) public onlyOperator notMigrated {
        require(pools[pool_address] == false, "poolExisted");
        pools[pool_address] = true;
        pools_array.push(pool_address);
    }

    // Remove a pool
    function removePool(address pool_address) public onlyOperator notMigrated {
        require(pools[pool_address] == true, "!pool");
        // Delete from the mapping
        delete pools[pool_address];
        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < pools_array.length; i++) {
            if (pools_array[i] == pool_address) {
                pools_array[i] = address(0);
                // This will leave a null in the array and keep the indices the same
                break;
            }
        }
    }

    function migrate(address _new_treasury) external onlyOperator notMigrated {
        migrated = true;
        uint256 _share_balance = IERC20(share).balanceOf(address(this));
        if (_share_balance > 0) {
            IERC20(share).safeTransfer(_new_treasury, _share_balance);
        }

    }

    /* -========= INTERNAL FUNCTIONS ============ */

    function _swap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmountMin) public onlyOperator returns (uint256) {
        address[] memory _path = new address[](2);
        _path[0] = inputToken;
        _path[1] = outputToken;
        IERC20(inputToken).approve(router, 0);
        IERC20(inputToken).approve(router, inputAmount);
        uint256[] memory out_amounts = IUniswapV2Router01(router).swapExactTokensForTokens(inputAmount, outputAmountMin, _path, address(this), now.add(1800));
        return out_amounts[out_amounts.length - 1];
    }

    /* -========= SETTER ============ */

    function setRedemptionFee(uint256 _redemption_fee) public onlyOperator {
        redemption_fee = _redemption_fee;
    }

    function setMintingFee(uint256 _minting_fee) public onlyOperator {
        minting_fee = _minting_fee;
    }

    function setRatioStep(uint256 _ratio_step) public onlyOperator {
        ratio_step = _ratio_step;
    }

    function setPriceTarget(uint256 _price_target) public onlyOperator {
        price_target = _price_target;
    }

    function setRefreshCooldown(uint256 _refresh_cooldown) public onlyOperator {
        refresh_cooldown = _refresh_cooldown;
    }

    function setPriceBand(uint256 _price_band, uint256 _assetId) external onlyOperator {
        CollateralPolicy storage _collateralPolicy = assetCollateralPolicy[_assetId];
        _collateralPolicy.price_band = _price_band;
    }

    function toggleCollateralRatio() public onlyOperator {
        collateral_ratio_paused = !collateral_ratio_paused;
    }

    function toggleEffectiveCollateralRatio() public onlyOperator {
        using_effective_collateral_ratio = !using_effective_collateral_ratio;
    }

    function setProfitSharingFund(address _profitSharingFund) public onlyOperator {
        require(_profitSharingFund != address(0), "invalidAddress");
        profitSharingFund = _profitSharingFund;
    }

    function setProfitController(address _profitController) public onlyOwner {
        require(_profitController != address(0), "invalidAddress");
        profitController = _profitController;
    }

    function setRouter(address _router) public onlyOwner {
        require(_router != address(0), "invalidAddress");
        router = _router;
    }

    function setDaoFund(address _daoFund) public onlyOwner {
        require(_daoFund != address(0), "invalidAddress");
        daoFund = _daoFund;
    }

    function setMissingDecimals(uint256 _missing_decimals, uint256 _assetId) external override onlyAssetController {
        CollateralPolicy storage _collateralPolicy = assetCollateralPolicy[_assetId];
        _collateralPolicy.missing_decimals = _missing_decimals;
    }

    function setCollateralFund(address _collateralFund) public onlyOperator {
        require(_collateralFund != address(0), "invalidAddress");
        collateralFund = _collateralFund;
    }


    function setExcessCollateralSafetyMargin(uint256 _excess_collateral_safety_margin) public onlyOwner {
        require(
            _excess_collateral_safety_margin >= EXCESS_COLLATERAL_SAFETY_MARGIN_MIN,
            "<EXCESS_COLLATERAL_SAFETY_MARGIN_MIN"
        );
        excess_collateral_safety_margin = _excess_collateral_safety_margin;
    }

    function setRebalanceCoolDown(uint256 _rebalance_cooldown) public onlyOperator {
        require(_rebalance_cooldown > 0, "!invalid");
        rebalance_cooldown = _rebalance_cooldown;
    }

    function setAssetController(address _assetController) public onlyOperator {
        require(_assetController != address(0), "Invalid address");
        assetController = _assetController;
    }

    function setInvestmentController(address _investmentController) public onlyOperator {
        require(_investmentController != address(0), "Invalid address");
        investmentController = IInvestmentController(_investmentController);
    }

    /* ========== EMERGENCY ========== */

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public onlyOperator returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value : value}(callData);
        require(success, string("Treasury::executeTransaction: Transaction execution reverted."));
        emit TransactionExecuted(target, value, signature, data);
        return returnData;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IOracle {
    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IMultiAssetPool {
    function addAssetStat(uint256 _aid, uint256 _missingDecimals) external;

    function collateralBalance(uint256 _assetId) external view returns (uint256);

    function getUnclaimedCollateral(uint256 _assetId) external view returns (uint256);

    function netSupplyMinted(uint256 _assetId) external view returns (uint256);

    function getCollateralToken(uint256 _assetId) external view returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

pragma solidity >=0.6.12;

interface ICurrencyReserve {
    function transferTo(
        address _token,
        address _receiver,
        uint256 _amount
    ) external;
}

pragma solidity >=0.6.12;

interface ICollateralFund {
    function transferTo(
        address _token,
        address _receiver,
        uint256 _amount
    ) external;
}

pragma solidity >=0.6.12;

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

pragma solidity >=0.6.12;

interface IAssetController {
    function assetCount() external view returns(uint256);

    function getAssetInfo(uint256 _assetId) external view returns (
        address _asset,
        address _collateral,
        address _oracle,
        bool _isStable
    );

    function getAsset(uint256 _assetId) external view returns(address);

    function getCollateral(uint256 _assetId) external view returns(address);

    function getOracle(uint256 _assetId) external view returns (address);

    function isAssetStable(uint256 _assetId) external view returns(bool);

    function getAssetPrice(uint256 _assetId) external view returns (uint256);

    function getXSharePrice() external view returns (uint256);

    function getAssetTotalSupply(uint256 _assetId) external view returns (uint256);

    function getCollateralPriceInDollar(uint256 _assetId) external view returns (uint);

    function updateOracle(uint256 _assetId) external;
}

pragma solidity >=0.6.12;

interface IMultiAssetTreasury {
    function addCollateralPolicy(uint256 _aid, uint256 _price_band, uint256 _missing_decimals, uint256 _init_tcr, uint256 _init_ecr) external;

    function setMissingDecimals(uint256 _missing_decimals, uint256 _assetId) external;

    function hasPool(address _address) external view returns (bool);

    function collateralFund() external view returns (address);

    function globalCollateralBalance(uint256 _assetId) external view returns (uint256);

    function collateralValue(uint256 _assetId) external view returns (uint256);

    function buyback(uint256 _collateral_amount, uint256 _min_share_amount,uint256 _min_asset_out,uint256 _assetId) external;

    function recollateralize(uint256 _share_amount, uint256 _min_collateral_amount, uint256 _assetId) external;

    function requestTransfer(
        address token,
        address receiver,
        uint256 amount
    ) external;

    function info(uint256 _assetId)
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );
}

pragma solidity >=0.6.12;

abstract contract IInvestmentController {
    function collateralBalance(uint256 _assetId) external view virtual returns (uint256);

    function getUnDistributedReward(uint256 _strategyId) external view virtual returns (uint256, address);

    function getStrategyUnclaimedReward(uint256 _strategyId) external view virtual returns (uint256);

    function getInvestedAmount(address _strategyContract) external view virtual returns (uint256);

    function invest(uint256 _strategyId, uint256 _amount) external virtual;

    function recollateralized(uint256 _amount) external virtual;

    function claimReward(uint256 _strategyId, uint256 _amount) external virtual;

    function exitStrategy(uint256 _strategyId) external virtual;

    function distributeReward(uint256 _strategyId, uint256 _amount) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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