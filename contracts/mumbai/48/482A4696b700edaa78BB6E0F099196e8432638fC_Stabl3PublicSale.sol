// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./SafeMathUpgradeable.sol";
import "./SafeERC20.sol";

import "./ITreasury.sol";
import "./IROI.sol";

contract Stabl3PublicSale is Ownable, ReentrancyGuard {
    using SafeMathUpgradeable for uint256;

    uint8 private constant BUY_POOL = 0;

    uint8 private constant STAKE_POOL = 2;
    uint8 private constant LEND_POOL = 5;

    ITreasury public treasury;
    IROI public ROI;
    address public HQ;

    IERC20 public immutable STABL3;

    uint256 public treasuryPercentage;
    uint256 public ROIPercentage;
    uint256 public HQPercentage;

    uint256 public exchangePauseTime;
    uint256 public exchangeLimitTime;
    uint256 public exchangeLimitPercentage;

    bool public saleState;

    // structs

    struct Limit {
        address user;
        uint256 amount;
        uint256 startTime;
        uint256 lastExchangeTime;
    }

    // mappings

    mapping (address => Limit) public getLimit;

    // events

    event UpdatedTreasury(address newTreasury, address oldTreasury);

    event UpdatedROI(address newROI, address oldROI);

    event UpdatedHQ(address newHQ, address oldHQ);

    event Buy(
        address indexed user,
        uint256 amountStabl3,
        IERC20 token,
        uint256 amountToken,
        uint256 timestamp
    );

    event Exchange(
        address indexed user,
        IERC20 exchangingToken,
        uint256 amountExchangingToken,
        IERC20 token,
        uint256 amountToken,
        uint256 fee,
        uint256 timestamp
    );

    // constructor

    constructor(address _treasury, address _ROI) {
        treasury = ITreasury(_treasury);
        ROI = IROI(_ROI);
        // TODO change
        HQ = 0x294d0487fdf7acecf342ae70AFc5549A6E90f3e0;

        // TODO change
        STABL3 = IERC20(0xc3Bf0c0172E3638d383361801e9BF63B4FfE0d6e);

        treasuryPercentage = 800;
        ROIPercentage = 161;
        HQPercentage = 39;

        exchangePauseTime = 180; // 3 minutes time in seconds
        exchangeLimitTime = 86400; // 1 day time in seconds
        exchangeLimitPercentage = 300;
    }

    function updateTreasury(address _treasury) external onlyOwner {
        require(address(treasury) != _treasury, "Stabl3PublicSale: Treasury is already this address");
        emit UpdatedTreasury(_treasury, address(treasury));
        treasury = ITreasury(_treasury);
    }

    function updateROI(address _ROI) external onlyOwner {
        require(address(ROI) != _ROI, "Stabl3PublicSale: ROI is already this address");
        emit UpdatedROI(_ROI, address(ROI));
        ROI = IROI(_ROI);
    }

    function updateHQ(address _HQ) external onlyOwner {
        require(HQ != _HQ, "Stabl3PublicSale: HQ is already this address");
        emit UpdatedHQ(_HQ, HQ);
        HQ = _HQ;
    }

    function updateDistributionPercentages(
        uint256 _treasuryPercentage,
        uint256 _ROIPercentage,
        uint256 _HQPercentage
    ) external onlyOwner {
        require(_treasuryPercentage + _ROIPercentage + _HQPercentage == 1000,
            "Stabl3PublicSale: Sum of magnified percentages should equal 1000");

        treasuryPercentage = _treasuryPercentage;
        ROIPercentage = _ROIPercentage;
        HQPercentage = _HQPercentage;
    }

    function updateExchangePauseTime(uint256 _exchangePauseTime) external onlyOwner {
        require(exchangePauseTime != _exchangePauseTime, "Stabl3PublicSale: Exchange Pause Time is already this value");
        exchangePauseTime = _exchangePauseTime;
    }

    function updateExchangeLimitTime(uint256 _exchangeLimitTime) external onlyOwner {
        require(exchangeLimitTime != _exchangeLimitTime, "Stabl3PublicSale: Exchange Limit Time is already this value");
        exchangeLimitTime = _exchangeLimitTime;
    }

    function updateExchangeLimitPercentage(uint256 _exchangeLimitPercentage) external onlyOwner {
        require(exchangeLimitPercentage != _exchangeLimitPercentage, "Stabl3PublicSale: Exchange Limit Percentage is already this value");
        exchangeLimitPercentage = _exchangeLimitPercentage;
    }

    function updateState(bool _state) external onlyOwner {
        require(saleState != _state, "Stabl3PublicSale: Sale State is already this state");
        saleState = _state;
    }

    function buy(IERC20 _token, uint256 _amountToken) external saleActive reserved(_token) nonReentrant {
        require(_amountToken > 0, "Stabl3PublicSale: Insufficient amount");

        uint256 amountStabl3 = treasury.getAmountOut(_token, _amountToken);

        uint256 amountTreasury = _amountToken.mul(treasuryPercentage).div(1000);

        uint256 amountROI = _amountToken.mul(ROIPercentage).div(1000);

        uint256 amountHQ = _amountToken.mul(HQPercentage).div(1000);

        uint256 totalAmountDistributed = amountTreasury + amountROI + amountHQ;
        if (_amountToken > totalAmountDistributed) {
            amountTreasury += _amountToken - totalAmountDistributed;
        }

        SafeERC20.safeTransferFrom(_token, msg.sender, address(treasury), amountTreasury);
        SafeERC20.safeTransferFrom(_token, msg.sender, address(ROI), amountROI);
        SafeERC20.safeTransferFrom(_token, msg.sender, HQ, amountHQ);

        STABL3.transferFrom(address(treasury), msg.sender, amountStabl3);

        treasury.updatePool(BUY_POOL, _token, amountTreasury, amountROI, amountHQ, true);
        treasury.updateStabl3CirculatingSupply(amountStabl3, true);

        treasury.updateRate(_token, _amountToken);

        ROI.updateAPR();

        emit Buy(msg.sender, amountStabl3, _token, _amountToken, block.timestamp);
    }

    function _handleLimit(IERC20 _exchangingToken, uint256 _amountExchangingToken) internal {
        Limit storage limit = getLimit[msg.sender];

        if (limit.user != msg.sender) {
            limit.user = msg.sender;
            limit.amount = 0;
            limit.startTime = block.timestamp;
        }

        if (block.timestamp > limit.lastExchangeTime + exchangePauseTime) {
            limit.lastExchangeTime = block.timestamp;
        }
        else {
            revert("Stabl3PublicSale: For repeat exchanges, please wait a few minutes");
        }

        uint256 amountExchangingTokenToConsider =
            _exchangingToken.balanceOf(address(treasury))
            .safeSub(treasury.getTreasuryPool(STAKE_POOL, _exchangingToken))
            .safeSub(treasury.getTreasuryPool(LEND_POOL, _exchangingToken));

        uint256 decimals = _exchangingToken.decimals();

        (_amountExchangingToken, amountExchangingTokenToConsider) =
            decimals < 18 ?
            (_amountExchangingToken * (10 ** (18 - decimals)), amountExchangingTokenToConsider * (10 ** (18 - decimals))) :
            (_amountExchangingToken, amountExchangingTokenToConsider);

        if (limit.amount + _amountExchangingToken > amountExchangingTokenToConsider.mul(exchangeLimitPercentage).div(1000)) {
            require(block.timestamp > limit.startTime.add(exchangeLimitTime),
                "Stabl3PublicSale: Daily exchange limit reached. Please try again after limit expires or try a different amount");
        }

        if (block.timestamp > limit.startTime + exchangeLimitTime) {
            limit.amount = _amountExchangingToken;
            limit.startTime = block.timestamp;
        }
        else {
            limit.amount += _amountExchangingToken;
        }
    }

    /**
     * @dev This function allows users to exchange 1 stable coin with another but only if it is part of the protocol's reserve
     * @dev Multiple security features incorporated to secure funds
     * @dev Each user has a certain time wait before each consecutive exchange call
     * @dev Each user is limited to take out a maximum of X% within Y hours of the token they want which is currently in the treasury
            minus the amounts that came in through staking and lending
     * @dev Using the current chain's highest liquidity AMM for exchange price
     */
    function exchange(
        IERC20 _exchangingToken,
        uint256 _amountExchangingTokenMin,
        IERC20 _token,
        uint256 _amountToken
    ) external saleActive reserved(_exchangingToken) reserved(_token) nonReentrant {
        require(_exchangingToken != _token, "Stabl3PublicSale: Invalid exchange");
        require(_amountToken > 0, "Stabl3PublicSale: Insufficient amount");

        uint256 amountExchangingToken = treasury.getExchangeAmountOut(_exchangingToken, _token, _amountToken);

        require(amountExchangingToken >= _amountExchangingTokenMin, "StablePublicSale: Slippage");

        _handleLimit(_exchangingToken, amountExchangingToken);

        uint256 fee = _amountToken.mul(treasury.exchangeFee()).div(1000);
        uint256 amountTokenWithFee = _amountToken - fee;

        // buy
        uint256 amountStabl3 = treasury.getAmountOut(_token, fee);

        SafeERC20.safeTransferFrom(_token, msg.sender, address(ROI), fee);

        STABL3.transferFrom(address(treasury), msg.sender, amountStabl3);

        treasury.updatePool(BUY_POOL, _token, 0, fee, 0, true);
        treasury.updateStabl3CirculatingSupply(amountStabl3, true);

        treasury.updateRate(_token, fee);

        // exchange
        SafeERC20.safeTransferFrom(_exchangingToken, address(treasury), msg.sender, amountExchangingToken);

        SafeERC20.safeTransferFrom(_token, msg.sender, address(treasury), amountTokenWithFee);

        treasury.updatePool(BUY_POOL, _exchangingToken, amountExchangingToken, 0, 0, false);
        treasury.updatePool(BUY_POOL, _token, amountTokenWithFee, 0, 0, true);

        ROI.updateAPR();

        emit Exchange(msg.sender, _exchangingToken, amountExchangingToken, _token, amountTokenWithFee, fee, block.timestamp);
    }

    // modifiers

    modifier saleActive() {
        require(saleState, "Stabl3PublicSale: Sale not yet started");
        _;
    }

    modifier reserved(IERC20 _token) {
        require(treasury.isReservedToken(_token), "Stabl3PublicSale: Not a reserved token");
        _;
    }
}