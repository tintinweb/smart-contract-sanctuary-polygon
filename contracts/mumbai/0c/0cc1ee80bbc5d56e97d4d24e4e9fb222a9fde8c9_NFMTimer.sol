/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

interface INfmController {
    function _checkWLSC(address, address) external pure returns (bool);
}

contract NFMTimer {
    address private _Owner;
    uint256 private _UV2_Swap_event;
    uint256 private _UV2_Liquidity_event;
    uint256 private _UV2_RemoveLiquidity_event;
    uint256 private _DailyMint;
    uint256 private _BeginLogic;
    uint256 private _EndMint;
    uint256 private _ExtraBonusAll;
    uint256 private _ExtraBonusAllEnd;
    uint256 private _StartBurn;
    uint256 private _StartBuyBack;
    uint256 private _SetUpLogicCountdown; //Countdown for starting
    uint256 private _YearInterval = 3600 * 24 * 30 * 12;
    uint256 private _DayInterval = 3600 * 24;
    INfmController public _Controller;
    address private _SController;

    constructor(address Controller) {
        _Owner = msg.sender;
        _SController = Controller;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
    }

    function _StartLogic(uint256 CountDays) public returns (bool) {
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        require(msg.sender != address(0), "0A");
        _SetUpLogicCountdown = block.timestamp + (_DayInterval * CountDays);
        _UV2_Swap_event =
            block.timestamp +
            (3600 * 5 + (_DayInterval * (9 + CountDays))); //Starts 9 Days later + 5 Hours
        _UV2_Liquidity_event =
            block.timestamp +
            (3600 * 10 + (_DayInterval * (7 + CountDays))); //Starts 7 Days later + 10 Hours
        _ExtraBonusAll =
            block.timestamp +
            (3600 * 15 + (_DayInterval * (100 + CountDays)));
        _ExtraBonusAllEnd = _ExtraBonusAll + (_DayInterval * (CountDays + 1));
        _UV2_RemoveLiquidity_event =
            block.timestamp +
            (_YearInterval * 11) +
            (_DayInterval * CountDays);
        _DailyMint = block.timestamp + (_DayInterval * (CountDays + 1));
        _BeginLogic = block.timestamp + (_DayInterval * CountDays);
        _EndMint =
            block.timestamp +
            (_YearInterval * 8) +
            3600 +
            (_DayInterval * CountDays);
        _StartBuyBack =
            block.timestamp +
            (_YearInterval * 11) +
            (3600 * 20) +
            (_DayInterval * CountDays);
        _StartBurn =
            block.timestamp +
            (_YearInterval * 4) +
            (_DayInterval * CountDays);
        return true;
    }

    function _timetester(uint256 timernum, uint256 btimestamp)
        public
        returns (bool)
    {
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        require(msg.sender != address(0), "0A");

        if (timernum == 1) {
            _DailyMint = btimestamp;
        } else if (timernum == 2) {
            _UV2_Swap_event = btimestamp;
        } else if (timernum == 3) {
            _UV2_Liquidity_event = btimestamp;
        } else if (timernum == 4) {
            _ExtraBonusAll = btimestamp;
        } else if (timernum == 5) {
            _StartBuyBack = btimestamp;
        } else if (timernum == 6) {
            _StartBurn = btimestamp;
        } else if (timernum == 7) {
            _SetUpLogicCountdown = btimestamp;
        }

        return true;
    }

    function _updateExtraBonusAll() public returns (bool) {
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        require(msg.sender != address(0), "0A");
        _ExtraBonusAll = _ExtraBonusAll + (_DayInterval * 100);
        _ExtraBonusAllEnd = _ExtraBonusAll + _DayInterval;
        return true;
    }

    function _updateUV2_Swap_event() public returns (bool) {
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        require(msg.sender != address(0), "0A");
        _UV2_Swap_event = _UV2_Swap_event + (_DayInterval * 9);
        return true;
    }

    function _updateStartBuyBack() public returns (bool) {
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        require(msg.sender != address(0), "0A");
        _StartBuyBack = _StartBuyBack + (_DayInterval * 30);
        return true;
    }

    function _updateUV2_Liquidity_event() public returns (bool) {
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        require(msg.sender != address(0), "0A");
        _UV2_Liquidity_event = _UV2_Liquidity_event + (_DayInterval * 7);
        return true;
    }

    function _updateDailyMint() public returns (bool) {
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        require(msg.sender != address(0), "0A");
        _DailyMint = _DailyMint + _DayInterval;
        return true;
    }

    function _getStartTime() public view returns (uint256) {
        return _BeginLogic;
    }

    function _getEndMintTime() public view returns (uint256) {
        return _EndMint;
    }

    function _getDailyMintTime() public view returns (uint256) {
        return _DailyMint;
    }

    function _getStartBurnTime() public view returns (uint256) {
        return _StartBurn;
    }

    function _getUV2_RemoveLiquidityTime() public view returns (uint256) {
        return _UV2_RemoveLiquidity_event;
    }

    function _getUV2_LiquidityTime() public view returns (uint256) {
        return _UV2_Liquidity_event;
    }

    function _getUV2_SwapTime() public view returns (uint256) {
        return _UV2_Swap_event;
    }

    function _getExtraBonusAllTime() public view returns (uint256) {
        return _ExtraBonusAll;
    }

    function _getEndExtraBonusAllTime() public view returns (uint256) {
        return _ExtraBonusAllEnd;
    }

    function _getLogicCountdown() public view returns (uint256) {
        return _SetUpLogicCountdown;
    }

    function _getStartBuyBackTime() public view returns (uint256) {
        return _StartBuyBack;
    }

    function _getEA()
        public
        view
        returns (uint256 EYearAmount, uint256 EDayAmount)
    {
        if (block.timestamp < _BeginLogic + (_YearInterval * 1)) {
            return (733333333.33 * 10**18, 2037037.037027770 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 2)) {
            return (957333333.33 * 10**18, 2659259.259250000 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 3)) {
            return (983333333.33 * 10**18, 2731481.481472220 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 4)) {
            return (1009333333.33 * 10**18, 2803703.703694440 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 5)) {
            return (1035333333.33 * 10**18, 2875925.925916660 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 6)) {
            return (1061333333.33 * 10**18, 2948148.148138880 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 7)) {
            return (754000000 * 10**18, 2094444.444444440 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 8)) {
            return (1066000000.02 * 10**18, 2961111.111166660 * 10**18);
        } else {}
    }
}