// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./SafeMathUpgradeable.sol";
import "./SafeERC20.sol";

import "./ITreasury.sol";
import "./IROI.sol";
import "./IUCD.sol";

contract Stabl3Borrowing is Ownable, ReentrancyGuard {
    using SafeMathUpgradeable for uint256;

    uint8 private constant UCD_BORROW_POOL = 8;
    uint8 private constant UCD_PAYBACK_POOL = 9;
    uint8 private constant UCD_TO_TOKEN_EXCHANGE_POOL = 10;
    uint8 private constant STABL3_COLLATERAL_POOL = 11;

    uint8 private constant UNCONSOLIDATED_FEE_POOL = 26;

    ITreasury public treasury;
    IROI public ROI;
    address public HQ;

    IERC20 public immutable STABL3;

    IUCD public UCD;

    uint256 private burnedUCD;

    uint256 public borrowFee;
    uint256 public exchangeFeeUCD;

    uint8[] public returnBorrowingPools;

    bool public borrowState;

    // structs

    struct Borrowing {
        uint256 amountStabl3;
        uint256 amountUCD;
    }

    // mappings

    mapping (address => Borrowing) public getBorrowings;

    // events

    event UpdatedTreasury(address newTreasury, address oldTreasury);

    event UpdatedROI(address newROI, address oldROI);

    event UpdatedHQ(address newHQ, address oldHQ);

    event UpdatedBorrowFee(uint256 newBorrowFee, uint256 oldBorrowFee);

    event UpdatedExchangeFeeUCD(uint256 newExchangeFeeUCD, uint256 oldExchangeFeeUCD);

    event Borrow(
        address indexed user,
        uint256 amountUCD,
        uint256 amountStabl3,
        uint256 rate,
        uint256 timestamp
    );

    event Payback(
        address indexed user,
        uint256 amountUCD,
        uint256 amountStabl3,
        uint256 rate,
        uint256 timestamp
    );

    event ExchangeUCD(
        address indexed user,
        IERC20 exchangingToken,
        uint256 amountExchangingToken,
        uint256 amountUCD,
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

        // TODO change
        UCD = IUCD(0xB0124F5d0e906d3652d0b58F03E315eC42A57E9a);

        borrowFee = 50;
        exchangeFeeUCD = 25;

        returnBorrowingPools = [0, 1, 2, 5];
    }

    function updateTreasury(address _treasury) external onlyOwner {
        require(address(treasury) != _treasury, "Stabl3Borrowing: Treasury is already this address");
        emit UpdatedTreasury(_treasury, address(treasury));
        treasury = ITreasury(_treasury);
    }

    function updateROI(address _ROI) external onlyOwner {
        require(address(ROI) != _ROI, "Stabl3Borrowing: ROI is already this address");
        emit UpdatedROI(_ROI, address(ROI));
        ROI = IROI(_ROI);
    }

    function updateHQ(address _HQ) external onlyOwner {
        require(HQ != _HQ, "Stabl3Borrowing: HQ is already this address");
        emit UpdatedHQ(_HQ, HQ);
        HQ = _HQ;
    }

    function updateUCD(address _ucd) external onlyOwner {
        require(address(UCD) != _ucd, "Stabl3Borrowing: UCD is already this address");
        UCD = IUCD(_ucd);
    }

    function updateBorrowFee(uint256 _borrowFee) external onlyOwner {
        require(borrowFee != _borrowFee, "Stabl3Borrowing: Borrow Fee is already this value");
        emit UpdatedBorrowFee(_borrowFee, borrowFee);
        borrowFee = _borrowFee;
    }

    function updateExchangeFeeUCD(uint256 _exchangeFeeUCD) external onlyOwner {
        require(exchangeFeeUCD != _exchangeFeeUCD, "Stabl3Borrowing: Exchange Fee for UCD is already this value");
        emit UpdatedExchangeFeeUCD(_exchangeFeeUCD, exchangeFeeUCD);
        exchangeFeeUCD = _exchangeFeeUCD;
    }

    function updateReturnBorrowingPools(uint8[] memory _returnBorrowingPools) external onlyOwner {
        returnBorrowingPools = _returnBorrowingPools;
    }

    function updateState(bool _state) external onlyOwner {
        require(borrowState != _state, "Stabl3Borrowing: Borrow State is already this state");
        borrowState = _state;
    }

    function getReservesUCD() public view returns (uint256 availableUCD, uint256 borrowedUCD, uint256 returnedUCD) {
        return (
            ((treasury.getReserves() + ROI.getReserves()) / (10 ** 12)).safeSub(UCD.totalSupply()),
            UCD.totalSupply(),
            burnedUCD
        );
    }

    function _reservedTokenSelector() internal view returns (IERC20) {
        IERC20 selectedReservedToken;

        uint256 maxAmountReservedToken;

        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);

            if (treasury.isReservedToken(reservedToken)) {
                uint256 amountReservedToken = reservedToken.balanceOf(address(treasury));

                uint256 decimals = reservedToken.decimals();

                uint256 amountReservedTokenConverted =
                    decimals < 18 ?
                    (amountReservedToken * (10 ** (18 - decimals))) :
                    amountReservedToken;

                if (amountReservedTokenConverted > maxAmountReservedToken) {
                    selectedReservedToken = reservedToken;

                    maxAmountReservedToken = amountReservedTokenConverted;
                }
            }
        }

        return selectedReservedToken;
    }

    /**
     * @dev This function allows users to deposit STABL3 and to receive UCD at current protocol rates
     * @dev fees in borrow
     */
    function borrow(uint256 _amountStabl3) external borrowActive nonReentrant {
        require(_amountStabl3 > 0, "Stabl3Borrowing: Insufficient amount");

        uint256 rate = treasury.getRate();

        uint256 amountUCD = (_amountStabl3 * rate) / (10 ** 18);

        uint256 fee = amountUCD.mul(borrowFee).div(1000);
        uint256 amountUCDWithFee = amountUCD - fee;

        (uint256 availableUCD, , ) = getReservesUCD();
        require(amountUCDWithFee <= availableUCD, "Stabl3Borrowing: Insufficient available UCD");

        IERC20 reservedToken = _reservedTokenSelector();

        uint256 decimalsReservedToken = reservedToken.decimals();
        uint256 decimalsUCD = UCD.decimals();

        if (decimalsReservedToken > decimalsUCD) {
            fee *= 10 ** (18 - decimalsReservedToken);
        }
        else if (decimalsReservedToken < decimalsUCD) {
            fee /= 10 ** (18 - decimalsReservedToken);
        }

        _returnBorrowingFunds(reservedToken, fee);

        SafeERC20.safeTransferFrom(reservedToken, address(treasury), address(ROI), fee);

        treasury.updatePool(UNCONSOLIDATED_FEE_POOL, reservedToken, 0, fee, 0, true);

        Borrowing storage borrowing = getBorrowings[msg.sender];

        borrowing.amountUCD += amountUCDWithFee;
        borrowing.amountStabl3 += _amountStabl3;

        STABL3.transferFrom(msg.sender, address(treasury), _amountStabl3);

        UCD.mintWithPermit(msg.sender, amountUCDWithFee);

        treasury.updatePool(UCD_BORROW_POOL, UCD, amountUCDWithFee, 0, 0, true);
        treasury.updatePool(STABL3_COLLATERAL_POOL, STABL3, _amountStabl3, 0, 0, true);

        treasury.updateStabl3CirculatingSupply(_amountStabl3, false);

        emit Borrow(msg.sender, amountUCDWithFee, _amountStabl3, rate, block.timestamp);
    }

    // TODO
    // DONE when a user has fully returned his UCD do we uncollateralize the rest of his collateralized Stabl3
    // DONE consider current price when borrowing/paying back
    // flashloan protection (how to add?)
    // frontrunning bots -> Slippage (where to add? Stabl3 Purchase and UCD Exchange?)
    // handle limit in UCD Exchange (ask if this is needed)

    /**
     * @dev This function allows users to repay their borrowed UCD in return for Stabl3 Token at current protocol rates
     * @dev no fees in payback
     */
    function payback(uint256 _amountUCD) external borrowActive nonReentrant {
        require(_amountUCD > 0, "Stabl3Borrowing: Insufficient amount");

        Borrowing storage borrowing = getBorrowings[msg.sender];

        require(borrowing.amountUCD > 0, "Stabl3Borrowing: No UCD to payback");

        uint256 rate = treasury.getRate();

        uint256 amountStabl3 = (_amountUCD * (10 ** 18)) / rate;

        borrowing.amountUCD = borrowing.amountUCD.safeSub(_amountUCD);
        borrowing.amountStabl3 = borrowing.amountStabl3.safeSub(amountStabl3);

        UCD.burnWithPermit(msg.sender, _amountUCD);
        burnedUCD += _amountUCD;

        STABL3.transferFrom(address(treasury), msg.sender, amountStabl3);

        uint256 amountStabl3ToConsider = amountStabl3;

        if (borrowing.amountUCD == 0) {
            amountStabl3ToConsider += borrowing.amountStabl3;
            borrowing.amountStabl3 = 0;
        }

        treasury.updatePool(UCD_PAYBACK_POOL, UCD, _amountUCD, 0, 0, true);
        treasury.updatePool(STABL3_COLLATERAL_POOL, STABL3, amountStabl3ToConsider, 0, 0, false);

        treasury.updateStabl3CirculatingSupply(amountStabl3, true);

        emit Payback(msg.sender, _amountUCD, amountStabl3, rate, block.timestamp);
    }

    function exchangeUCD(IERC20 _exchangingToken, uint256 _amountUCD) external borrowActive reserved(_exchangingToken) nonReentrant {
        require(_amountUCD > 0, "Stabl3Borrowing: Insufficient amount");

        // TODO
        // handleLimit?

        uint256 amountExchangingToken = _amountUCD;

        uint256 decimalsExchangingToken = _exchangingToken.decimals();
        uint256 decimalsUCD = UCD.decimals();

        if (decimalsExchangingToken > decimalsUCD) {
            amountExchangingToken *= 10 ** (decimalsExchangingToken - decimalsUCD);
        }
        else if (decimalsExchangingToken < decimalsUCD) {
            amountExchangingToken /= 10 ** (decimalsUCD - decimalsExchangingToken);
        }

        uint256 fee = amountExchangingToken.mul(exchangeFeeUCD).div(1000);
        uint256 amountExchangingTokenWithFee = amountExchangingToken - fee;

        if (amountExchangingToken > _exchangingToken.balanceOf(address(treasury))) {
            ROI.returnFunds(_exchangingToken, amountExchangingToken - _exchangingToken.balanceOf(address(treasury)));
        }

        _returnBorrowingFunds(_exchangingToken, amountExchangingToken);

        SafeERC20.safeTransferFrom(_exchangingToken, address(treasury), address(ROI), fee);

        treasury.updatePool(UNCONSOLIDATED_FEE_POOL, _exchangingToken, 0, fee, 0, true);

        SafeERC20.safeTransferFrom(_exchangingToken, address(treasury), msg.sender, amountExchangingTokenWithFee);

        UCD.burnWithPermit(msg.sender, _amountUCD);
        burnedUCD += _amountUCD;

        treasury.updatePool(UCD_TO_TOKEN_EXCHANGE_POOL, _exchangingToken, amountExchangingTokenWithFee, 0, 0, true);
        treasury.updatePool(UCD_TO_TOKEN_EXCHANGE_POOL, UCD, _amountUCD, 0, 0, true);

        emit ExchangeUCD(msg.sender, _exchangingToken, amountExchangingTokenWithFee, _amountUCD, fee, block.timestamp);
    }

    function _returnBorrowingFunds(IERC20 _token, uint256 _amountToken) internal {
        uint256 amountToUpdate = _amountToken;

        for (uint8 i = 0 ; i < returnBorrowingPools.length ; i++) {
            uint256 amountPool = treasury.getTreasuryPool(returnBorrowingPools[i], _token);

            if (amountPool != 0) {
                if (amountPool < amountToUpdate) {
                    treasury.updatePool(returnBorrowingPools[i], _token, amountPool, 0, 0, false);

                    amountToUpdate -= amountPool;
                }
                else {
                    treasury.updatePool(returnBorrowingPools[i], _token, amountToUpdate, 0, 0, false);

                    amountToUpdate = 0;
                    break;
                }
            }
        }

        require(amountToUpdate == 0, "Stabl3Borrowing: Not enough funds in the specified pools");
    }

    // modifiers

    modifier borrowActive() {
        require(borrowState, "Stabl3Borrowing: Borrow not yet started");
        _;
    }

    modifier reserved(IERC20 _token) {
        require(treasury.isReservedToken(_token), "Stabl3Borrowing: Not a reserved token");
        _;
    }
}