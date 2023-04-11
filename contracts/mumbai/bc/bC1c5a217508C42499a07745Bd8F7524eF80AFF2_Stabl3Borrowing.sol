// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.19;

import "./Ownable.sol";

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IERC721.sol";
import "./ITreasury.sol";
import "./IROI.sol";
import "./IUCD.sol";

contract Stabl3Borrowing is Ownable {
    using SafeMath for uint256;

    uint8 private constant UCD_BORROW_POOL = 8;
    uint8 private constant UCD_PAYBACK_POOL = 9;
    uint8 private constant UCD_TO_TOKEN_EXCHANGE_POOL = 10;
    uint8 private constant STABL3_COLLATERAL_POOL = 11;

    address public donationWallet;

    ITreasury public TREASURY;
    IROI public ROI;

    IERC20 public immutable STABL3;

    IUCD public UCD;

    IERC721 public INVESTORS;

    uint256 public borrowFee;
    uint256 public exchangeUCDFee;

    uint8[] public returnBorrowingPools;

    uint256 private burnedUCD;

    Borrowing public getBorrowing;

    bool public borrowState;

    // structs

    struct Borrowing {
        uint256 amountUCD;
        uint256 amountStabl3;
        uint256 amountFee;
        uint256 amountStabl3Fee;
    }

    // events

    event UpdatedDonationWallet(address newDonationWallet, address oldDonationWallet);

    event UpdatedTreasury(address newTreasury, address oldTreasury);

    event UpdatedROI(address newROI, address oldROI);

    event UpdatedBorrowFee(uint256 newBorrowFee, uint256 oldBorrowFee);

    event UpdatedExchangeUCDFee(uint256 newExchangeUCDFee, uint256 oldExchangeUCDFee);

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

    constructor(address _TREASURY, address _ROI) {
        // TODO change
        donationWallet = 0x3edCe801a3f1851675e68589844B1b412EAc6B07;

        TREASURY = ITreasury(_TREASURY);
        ROI = IROI(_ROI);

        // TODO change
        STABL3 = IERC20(0xc3Bf0c0172E3638d383361801e9BF63B4FfE0d6e);

        // TODO change
        UCD = IUCD(0x78Ef94529fC06F08756a43f6Bdfe61395C0e1428);

        // TODO change
        INVESTORS = IERC721(0xE8CCB5e6c591414e767602688ff1F50B3990C206);

        borrowFee = 50;
        exchangeUCDFee = 25;

        returnBorrowingPools = [0, 1, 2, 5];
    }

    function updateDonationWallet(address _donationWallet) external onlyOwner {
        require(donationWallet != _donationWallet, "Stabl3Borrowing: Donation Wallet is already this address");
        emit UpdatedDonationWallet(_donationWallet, donationWallet);
        donationWallet = _donationWallet;
    }

    function updateTreasury(address _TREASURY) external onlyOwner {
        require(address(TREASURY) != _TREASURY, "Stabl3Borrowing: Treasury is already this address");
        emit UpdatedTreasury(_TREASURY, address(TREASURY));
        TREASURY = ITreasury(_TREASURY);
    }

    function updateROI(address _ROI) external onlyOwner {
        require(address(ROI) != _ROI, "Stabl3Borrowing: ROI is already this address");
        emit UpdatedROI(_ROI, address(ROI));
        ROI = IROI(_ROI);
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

    function updateExchangeUCDFee(uint256 _exchangeUCDFee) external onlyOwner {
        require(exchangeUCDFee != _exchangeUCDFee, "Stabl3Borrowing: Exchange Fee for UCD is already this value");
        emit UpdatedExchangeUCDFee(_exchangeUCDFee, exchangeUCDFee);
        exchangeUCDFee = _exchangeUCDFee;
    }

    function updateReturnBorrowingPools(uint8[] memory _returnBorrowingPools) external onlyOwner {
        returnBorrowingPools = _returnBorrowingPools;
    }

    function updateState(bool _state) external onlyOwner {
        require(borrowState != _state, "Stabl3Borrowing: Borrow State is already this state");
        borrowState = _state;
    }

    function getReservesUCD() public view returns (uint256 availableUCD, uint256 borrowedUCD, uint256 returnedUCD) {
        uint256 availableReserves = (TREASURY.getReserves() + ROI.getReserves()) / (10 ** (18 - UCD.decimals()));

        return (
            availableReserves.safeSub(UCD.totalSupply()),
            UCD.totalSupply(),
            burnedUCD
        );
    }

    /**
     * @dev This function allows users to deposit STABL3 and to receive UCD at current protocol rates
     * @dev Fees are cut in the form of stablecoins by reducing amount of UCD
     */
    function borrow(uint256 _amountStabl3) external borrowActive {
        require(_amountStabl3 > 0, "Stabl3Borrowing: Insufficient amount");

        uint256 amountUCD = TREASURY.getAmountIn(_amountStabl3, UCD);
        uint256 amountStabl3ToConsider = TREASURY.getAmountOut(UCD, amountUCD);

        uint256 fee;
        uint256 stabl3Fee;
        if (INVESTORS.balanceOf(msg.sender) == 0) {
            fee = amountUCD.mul(borrowFee).div(1000);
            stabl3Fee = TREASURY.getAmountOut(UCD, fee);
            if (_amountStabl3 > amountStabl3ToConsider) {
                stabl3Fee += _amountStabl3 - amountStabl3ToConsider;
            }
        }
        uint256 amountUCDWithFee = amountUCD - fee;
        uint256 amountStabl3WithFee = amountStabl3ToConsider - stabl3Fee;

        (uint256 availableUCD, , ) = getReservesUCD();
        require(amountUCDWithFee <= availableUCD, "Stabl3Borrowing: Insufficient available UCD");

        getBorrowing.amountUCD += amountUCDWithFee;
        getBorrowing.amountStabl3 += amountStabl3WithFee;
        getBorrowing.amountFee += fee;
        getBorrowing.amountStabl3Fee += stabl3Fee;

        IERC20 reservedToken = TREASURY.reservedTokenSelector();

        uint256 decimalsReservedToken = reservedToken.decimals();
        uint256 decimalsUCD = UCD.decimals();

        if (decimalsReservedToken > decimalsUCD) {
            fee *= 10 ** (decimalsReservedToken - decimalsUCD);
        }
        else if (decimalsReservedToken < decimalsUCD) {
            fee /= 10 ** (decimalsUCD - decimalsReservedToken);
        }

        _returnBorrowingFunds(reservedToken, fee, true);

        SafeERC20.safeTransferFrom(reservedToken, address(TREASURY), address(ROI), fee);

        STABL3.transferFrom(msg.sender, address(TREASURY), amountStabl3WithFee + stabl3Fee);

        UCD.mint(msg.sender, amountUCDWithFee);

        TREASURY.updatePool(UCD_BORROW_POOL, UCD, amountUCDWithFee, 0, 0, true);
        TREASURY.updatePool(STABL3_COLLATERAL_POOL, STABL3, amountStabl3WithFee + stabl3Fee, 0, 0, true);

        TREASURY.updateStabl3CirculatingSupply(amountStabl3WithFee + stabl3Fee, false);

        ROI.updateAPR();

        emit Borrow(msg.sender, amountUCDWithFee, amountStabl3WithFee + stabl3Fee, TREASURY.getRate(), block.timestamp);
    }

    /**
     * @dev This function allows users to repay their borrowed UCD in return for STABL3 at current protocol rates
     * @dev No fees are cut in this function
     */
    function payback(uint256 _amountUCD) external borrowActive {
        require(_amountUCD > 0, "Stabl3Borrowing: Insufficient amount");
        require(getBorrowing.amountUCD > 0, "Stabl3Borrowing: No debt to payback");

        uint256 amountStabl3 = TREASURY.getAmountOut(UCD, _amountUCD);

        uint256 amountStabl3ToUncollateralize = (getBorrowing.amountStabl3 * _amountUCD) / getBorrowing.amountUCD;
        uint256 amountFeeToUncollateralize = (getBorrowing.amountFee * _amountUCD) / getBorrowing.amountUCD;
        uint256 amountStabl3FeeToUncollateralize = (getBorrowing.amountStabl3Fee * _amountUCD) / getBorrowing.amountUCD;

        getBorrowing.amountUCD -= _amountUCD;
        getBorrowing.amountStabl3 -= amountStabl3ToUncollateralize;
        getBorrowing.amountFee -= amountFeeToUncollateralize;
        getBorrowing.amountStabl3Fee -= amountStabl3FeeToUncollateralize;

        UCD.burnFrom(msg.sender, _amountUCD);
        burnedUCD += _amountUCD;

        uint256 leftoverCollateralStabl3 = amountStabl3ToUncollateralize.safeSub(amountStabl3);

        STABL3.transferFrom(address(TREASURY), msg.sender, amountStabl3);
        if (leftoverCollateralStabl3 > 0) {
            // donation
            STABL3.transferFrom(address(TREASURY), donationWallet, leftoverCollateralStabl3);
        }

        TREASURY.updatePool(UCD_PAYBACK_POOL, UCD, _amountUCD, 0, 0, true);
        // amountStabl3ToUncollateralize is unlocked and transferred out as amountStabl3 and leftoverCollateralStabl3
        // amountStabl3FeeToUncollateralize is unlocked and stays in the treasury to be purchasable
        TREASURY.updatePool(
            STABL3_COLLATERAL_POOL,
            STABL3,
            amountStabl3ToUncollateralize + amountStabl3FeeToUncollateralize,
            0,
            0,
            false
        );

        TREASURY.updateStabl3CirculatingSupply(amountStabl3ToUncollateralize, true);

        emit Payback(msg.sender, _amountUCD, amountStabl3, TREASURY.getRate(), block.timestamp);
    }

    /**
     * @dev Fees are cut from amount of exchanging token
     */
    function exchangeUCD(IERC20 _exchangingToken, uint256 _amountUCD) external borrowActive reserved(_exchangingToken) {
        require(_amountUCD > 0, "Stabl3Borrowing: Insufficient amount");
        require(getBorrowing.amountUCD > 0, "Stabl3Borrowing: No debt to payback");

        uint256 amountStabl3 = TREASURY.getAmountOut(UCD, _amountUCD);

        uint256 amountStabl3ToUncollateralize = (getBorrowing.amountStabl3 * _amountUCD) / getBorrowing.amountUCD;
        uint256 amountFeeToUncollateralize = (getBorrowing.amountFee * _amountUCD) / getBorrowing.amountUCD;
        uint256 amountStabl3FeeToUncollateralize = (getBorrowing.amountStabl3Fee * _amountUCD) / getBorrowing.amountUCD;

        getBorrowing.amountUCD -= _amountUCD;
        getBorrowing.amountStabl3 -= amountStabl3ToUncollateralize;
        getBorrowing.amountFee -= amountFeeToUncollateralize;
        getBorrowing.amountStabl3Fee -= amountStabl3FeeToUncollateralize;

        UCD.burnFrom(msg.sender, _amountUCD);
        burnedUCD += _amountUCD;

        uint256 leftoverCollateralStabl3 = amountStabl3ToUncollateralize.safeSub(amountStabl3);

        if (leftoverCollateralStabl3 > 0) {
            // donation
            STABL3.transferFrom(address(TREASURY), donationWallet, leftoverCollateralStabl3);
        }

        // leftoverCollateralStabl3 is the only amount unlocked and the rest of the amountStabl3ToUncollateralize stays locked
        // amountStabl3FeeToUncollateralize is unlocked as this is not linked to the exact borrowing amount
        TREASURY.updatePool(
            STABL3_COLLATERAL_POOL,
            STABL3,
            leftoverCollateralStabl3 + amountStabl3FeeToUncollateralize,
            0,
            0,
            false
        );

        TREASURY.updateStabl3CirculatingSupply(leftoverCollateralStabl3, true);

        uint256 amountExchangingToken = _amountUCD;

        uint256 decimalsExchangingToken = _exchangingToken.decimals();
        uint256 decimalsUCD = UCD.decimals();

        if (decimalsExchangingToken > decimalsUCD) {
            amountExchangingToken *= 10 ** (decimalsExchangingToken - decimalsUCD);
        }
        else if (decimalsExchangingToken < decimalsUCD) {
            amountExchangingToken /= 10 ** (decimalsUCD - decimalsExchangingToken);
        }

        uint256 fee;
        if (INVESTORS.balanceOf(msg.sender) == 0) {
            fee = amountExchangingToken.mul(exchangeUCDFee).div(1000);
        }
        uint256 amountExchangingTokenWithFee = amountExchangingToken - fee;

        if (amountExchangingToken > _exchangingToken.balanceOf(address(TREASURY))) {
            ROI.returnFunds(_exchangingToken, amountExchangingToken - _exchangingToken.balanceOf(address(TREASURY)));
        }

        _returnBorrowingFunds(_exchangingToken, fee, true);
        _returnBorrowingFunds(_exchangingToken, amountExchangingTokenWithFee, false);

        SafeERC20.safeTransferFrom(_exchangingToken, address(TREASURY), address(ROI), fee);
        SafeERC20.safeTransferFrom(_exchangingToken, address(TREASURY), msg.sender, amountExchangingTokenWithFee);

        TREASURY.updatePool(UCD_TO_TOKEN_EXCHANGE_POOL, _exchangingToken, amountExchangingTokenWithFee, 0, 0, true);
        TREASURY.updatePool(UCD_TO_TOKEN_EXCHANGE_POOL, UCD, _amountUCD, 0, 0, true);

        ROI.updateAPR();

        emit ExchangeUCD(msg.sender, _exchangingToken, amountExchangingTokenWithFee, _amountUCD, fee, block.timestamp);
    }

    /**
     * @dev Calls TREASURY's updatePool to reduce the TREASURY amounts
     */
    function _returnBorrowingFunds(IERC20 _token, uint256 _amountToken, bool _isUpdate) internal {
        uint256 amountToUpdate = _amountToken;

        for (uint8 i = 0 ; i < returnBorrowingPools.length ; i++) {
            uint256 amountPool = TREASURY.getTreasuryPool(returnBorrowingPools[i], _token);

            if (amountPool != 0) {
                if (amountPool < amountToUpdate) {
                    TREASURY.updatePool(returnBorrowingPools[i], _token, amountPool, 0, 0, false);
                    if (_isUpdate) {
                        TREASURY.updatePool(returnBorrowingPools[i], _token, 0, amountPool, 0, true);
                    }

                    amountToUpdate -= amountPool;
                }
                else {
                    TREASURY.updatePool(returnBorrowingPools[i], _token, amountToUpdate, 0, 0, false);
                    if (_isUpdate) {
                        TREASURY.updatePool(returnBorrowingPools[i], _token, 0, amountToUpdate, 0, true);
                    }

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
        require(TREASURY.isReservedToken(_token), "Stabl3Borrowing: Not a reserved token");
        _;
    }
}