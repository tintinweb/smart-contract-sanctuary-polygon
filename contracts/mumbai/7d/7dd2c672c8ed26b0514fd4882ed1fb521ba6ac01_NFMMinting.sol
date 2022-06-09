/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function _mint(address to, uint256 amount) external;
}

interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getController() external pure returns (address);

    function _getUV2Pool() external pure returns (address);

    function _getNFMStakingTreasuryERC20() external pure returns (address);

    function _getDaoReserveERC20() external pure returns (address);

    function _getTreasury() external pure returns (address);

    function _getDistribute() external pure returns (address);

    function _getNFM() external pure returns (address);

    function _getTimer() external pure returns (address);
}

interface INfmTimer {
    function _getEA()
        external
        pure
        returns (uint256 EYearAmount, uint256 EDayAmount);

    function _getEndMintTime() external pure returns (uint256);

    function _updateDailyMint() external returns (bool);
}

contract NFMMinting {
    using SafeMath for uint256;

    address private _Owner;
    INfmController public _Controller;
    IERC20 public _NFM;
    INfmTimer public _Timer;
    address private _SController;
    uint256 private _MonthlyEmissionCount = 1;
    uint256 private _DailyEmissionCount;
    uint256 private _dailyBNFTAmount;
    uint256 private _datamintCount = 0;
    uint256 private _YearlyEmissionAmount;
    uint256 private _BonusAmount = 10 * 10**18;
    mapping(uint256 => Mintings) public mintingtable;
    event Mint(
        address indexed zero,
        address indexed minter,
        uint256 Time,
        uint256 Amount
    );
    struct Mintings {
        address Sender;
        uint256 amount;
        uint256 timer;
    }

    constructor(address Controller) {
        _Owner = msg.sender;
        _SController = Controller;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
        IERC20 NFM = IERC20(address(_Controller._getNFM()));
        _NFM = NFM;
        INfmTimer Timer = INfmTimer(address(_Controller._getTimer()));
        _Timer = Timer;
        _DailyEmissionCount = 0;
        _dailyBNFTAmount = 0;
    }

    function _updateBNFTAmount(address minter) public virtual returns (bool) {
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        require(msg.sender != address(0), "0A");
        if (block.timestamp < _Timer._getEndMintTime()) {
            _NFM._mint(minter, _BonusAmount);
            _dailyBNFTAmount += _BonusAmount;
        }
        return true;
    }

    function calculateParts(uint256 amount)
        public
        pure
        returns (
            uint256 UVamount,
            uint256 StakeAmount,
            uint256 GovAmount,
            uint256 DevsAmount,
            uint256 TreasuryAmount
        )
    {
        uint256 onePercent = SafeMath.div(amount, 100);
        uint256 UV = SafeMath.mul(onePercent, 10);
        uint256 ST = SafeMath.mul(onePercent, 40);
        uint256 GV = SafeMath.mul(onePercent, 15);
        uint256 DV = SafeMath.mul(onePercent, 10);
        uint256 TY = SafeMath.sub(amount, (UV + ST + GV + DV));
        return (UV, ST, GV, DV, TY);
    }

    function storeMint(address Sender, uint256 amount) internal virtual {
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        require(msg.sender != address(0), "0A");
        mintingtable[_datamintCount] = Mintings(
            Sender,
            amount,
            block.timestamp
        );
        _datamintCount++;
    }

    function _getAllMintings(uint256 Elements)
        public
        view
        returns (Mintings[] memory)
    {
        if (Elements == 0) {
            Mintings[] memory lMintings = new Mintings[](_datamintCount);
            for (uint256 i = 0; i < _datamintCount; i++) {
                Mintings storage lMinting = mintingtable[i];
                lMintings[i] = lMinting;
            }
            return lMintings;
        } else {
            Mintings[] memory lMintings = new Mintings[](
                _datamintCount - Elements
            );
            for (
                uint256 i = _datamintCount - Elements;
                i < _datamintCount;
                i++
            ) {
                Mintings storage lMinting = mintingtable[i];
                lMintings[i] = lMinting;
            }
            return lMintings;
        }
    }

    function _minting(address sender) public virtual returns (bool) {
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        require(msg.sender != address(0), "0A");
        (uint256 EYearAmount, uint256 EDayAmount) = _Timer._getEA();
        uint256 amount = SafeMath.sub(EDayAmount, _dailyBNFTAmount);
        if (_MonthlyEmissionCount == 11 && _DailyEmissionCount == 29) {
            //Check minting amount of the year
            uint256 namount = SafeMath.add(EDayAmount, _YearlyEmissionAmount);
            namount = SafeMath.sub(EYearAmount, namount);
            amount = SafeMath.add(amount, namount);
            _DailyEmissionCount++;
            _YearlyEmissionAmount += amount;
            _dailyBNFTAmount = 0;
            (
                uint256 UVamount,
                uint256 StakeAmount,
                uint256 GovAmount,
                uint256 DevsAmount,
                uint256 TreasuryAmount
            ) = calculateParts(SafeMath.sub(amount, 10 * 10**18));
            _NFM._mint(_Controller._getUV2Pool(), UVamount); // 5%
            _NFM._mint(_Controller._getNFMStakingTreasuryERC20(), StakeAmount); // 65
            _NFM._mint(_Controller._getDaoReserveERC20(), GovAmount); // 5%
            _NFM._mint(_Controller._getDistribute(), DevsAmount); // 10%
            _NFM._mint(_Controller._getTreasury(), TreasuryAmount); //15%
            _NFM._mint(sender, _BonusAmount);
            storeMint(sender, amount);
            _Timer._updateDailyMint();
            emit Mint(address(0), sender, block.timestamp, EDayAmount);
            return true;
        } else {
            if (_DailyEmissionCount == 30) {
                _DailyEmissionCount = 1;
                if (_MonthlyEmissionCount == 11) {
                    _MonthlyEmissionCount = 1;
                    _YearlyEmissionAmount = 0;
                } else {
                    _MonthlyEmissionCount++;
                }
                _YearlyEmissionAmount += amount;
            } else {
                _DailyEmissionCount++;
                _YearlyEmissionAmount += amount;
            }
            _dailyBNFTAmount = 0;
            (
                uint256 UVamount,
                uint256 StakeAmount,
                uint256 GovAmount,
                uint256 DevsAmount,
                uint256 TreasuryAmount
            ) = calculateParts(SafeMath.sub(amount, 10 * 10**18));
            _NFM._mint(_Controller._getUV2Pool(), UVamount); // 5%
            _NFM._mint(_Controller._getNFMStakingTreasuryERC20(), StakeAmount); // 65
            _NFM._mint(_Controller._getDaoReserveERC20(), GovAmount); // 5%
            _NFM._mint(_Controller._getDistribute(), DevsAmount); // 10%
            _NFM._mint(_Controller._getTreasury(), TreasuryAmount); //15%
            _NFM._mint(sender, _BonusAmount);
            storeMint(sender, amount);
            _Timer._updateDailyMint();
            emit Mint(address(0), sender, block.timestamp, EDayAmount);
            return true;
        }
    }
}