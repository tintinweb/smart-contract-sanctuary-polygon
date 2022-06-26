/**
 *Submitted for verification at polygonscan.com on 2022-06-25
*/

/**
 *Submitted for verification at FtmScan.com on 2022-06-25
*/

/**
 *Submitted for verification at FtmScan.com on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface BAMMSwapLike {
    function swap(uint lusdAmount, address returnToken, uint minReturn, address dest, bytes memory data) external returns(uint);
    function cBorrow() view external returns(address);
    function isCETH() view external returns(bool);
    function fetchPrice(address token) external view returns(uint);
    function collateralCount() external view returns(uint);
    function collaterals(uint i) external view returns(address);
    function LUSD() external view returns(address);
}

interface IERC20 {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function decimals() external view returns(uint);
}

interface ICToken is IERC20 {
    function underlying() external view returns(address);
    function redeem(uint redeemAmount) external returns (uint);
    function mint(uint amount) external returns(uint);
    function symbol() external returns(string memory);
}

interface SushiRouterLike {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);    
}

interface SushiRouterReferrerLike {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        address referrer
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline, address referrer)
        external
        payable
        returns (uint[] memory amounts);    
}

interface CurveLike {
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns(uint);
    function exchange_underlying(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns(uint);    
    function coins(uint i) external view returns(address);
}

contract FlashArbFantom {
    address constant SUSHI_ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address constant H_FTM = 0xfCD8570AD81e6c77b8D252bEbEBA62ed980BD64D;
    address constant WETH = 0x74b23882a30290451A17c44f4F05243b6b58C76d;
    address constant USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    
    function dumpOnCurve(address curve, int128 i, int128 j) internal returns(uint) {
        address underlying = CurveLike(curve).coins(uint(i));
        uint swapAmount = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).approve(curve, swapAmount);

        return CurveLike(curve).exchange(i, j, swapAmount, 1);
    }

    function dumpOnCurveUnderlying(address curve, address underlying, int128 i, int128 j) internal returns(uint) {
        uint swapAmount = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).approve(curve, swapAmount);

        return CurveLike(curve).exchange_underlying(i, j, swapAmount, 1);
    }    

    function dumpRenBTCToWBTC() public returns(uint) {
        return dumpOnCurve(0x3eF6A01A0f81D6046290f3e2A8c5b843e738E604, 1, 0);
    }

    function dumpUSDCToUSDT() public returns(uint) {
        return dumpOnCurve(0x2dd7C9371965472E5A5fD28fbE165007c61439E1, 2, 1);
    }

    function dumpUSDCToMim() public returns(uint) {
        return dumpOnCurve(0x2dd7C9371965472E5A5fD28fbE165007c61439E1, 2, 0);
    }

    function dumpUSDCToFrax() public returns(uint) {
        return dumpOnCurveUnderlying(0x7a656B342E14F745e2B164890E88017e27AE7320, USDC, 2, 0);
    }

    function dumpUSDCToDai() public returns(uint) {
        return dumpOnCurveUnderlying(0x7a656B342E14F745e2B164890E88017e27AE7320, USDC, 2, 1);
    }

    function dumpYfiToEth(address yfi) public {
        uint yfiAmount = IERC20(yfi).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = yfi;
        path[1] = WETH;

        IERC20(yfi).approve(address(SUSHI_ROUTER), yfiAmount);
        SushiRouterLike(SUSHI_ROUTER).swapExactTokensForTokens(yfiAmount, 1, path, address(this), now + 1);
    }

    function dumpOnSushi(address src, address dest) public {
        uint srcAmount = IERC20(src).balanceOf(address(this));

        address[] memory path = new address[](3);
        path[0] = src;
        path[1] = WFTM;
        path[2] = dest;

        IERC20(src).approve(address(SUSHI_ROUTER), srcAmount);
        SushiRouterLike(SUSHI_ROUTER).swapExactTokensForTokens(srcAmount, 1, path, address(this), now + 1);
    }

    function dumpMaticOnSushi(uint srcAmount, address dest) public {
        address[] memory path = new address[](2);
        path[0] = WFTM;
        path[1] = dest;

        SushiRouterLike(SUSHI_ROUTER).swapExactETHForTokens.value(srcAmount)(1, path, address(this), now + 1);
    }

    function bammFlashswap(address /*initiator*/, uint lusdAmount, uint /*returnAmount*/, bytes memory data) external {
        (ICToken debt, ICToken collateral, bool isMaticCollateral) = abi.decode(data, (ICToken, ICToken, bool));

        // redeem the cCollateral
        collateral.redeem(collateral.balanceOf(address(this)));
        address underlying = isMaticCollateral ? address(0) : collateral.underlying();
        uint underlyingCollateralAmount = isMaticCollateral ? address(this).balance : IERC20(underlying).balanceOf(address(this));

        // dump it on sushi
        address debtUnderlying = debt.underlying();
        if(! isMaticCollateral) {
            if(underlying == 0x29b0Da86e484E1C0029B56e817912d778aC0EC69) {
                // yfi
                dumpYfiToEth(underlying);
                underlying = WETH;
            }

            if(underlying == 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501) {
                // renbtc
                dumpRenBTCToWBTC();
                underlying = 0x321162Cd933E2Be498Cd2267a90534A804051b11; // WBTC
            }

            dumpOnSushi(underlying, USDC);
        }
        else {
            dumpMaticOnSushi(underlyingCollateralAmount, USDC);
        }

        if(debtUnderlying == 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E) dumpUSDCToDai();
        else if(debtUnderlying == 0xdc301622e621166BD8E82f2cA0A26c13Ad0BE355) dumpUSDCToFrax();
        else if(debtUnderlying == 0x82f0B8B456c1A451378467398982d4834b6829c1) dumpUSDCToMim();
        else if(debtUnderlying == 0x049d68029688eAbF473097a2fC38ef61633A3C7A) dumpUSDCToUSDT();
        // else - leave as usdc

        // deposit all balance to cBorrow
        uint debtUnderlyingBalance = IERC20(debtUnderlying).balanceOf(address(this));
        IERC20(debtUnderlying).approve(address(debt), debtUnderlyingBalance);
     
        debt.mint(debtUnderlyingBalance);

        // give allowance, to repay the flash loan
        debt.approve(msg.sender, lusdAmount); // this can be exploited if the contract has non zero balance
    }    

    function arb(address bamm, uint cBorrowAmount, address cCollateral) public returns(uint profit){
        bytes memory data = abi.encode(BAMMSwapLike(bamm).cBorrow(), cCollateral, cCollateral == H_FTM);
        BAMMSwapLike(bamm).swap(cBorrowAmount, cCollateral, 0, address(this), data);

        address cBorrow = BAMMSwapLike(bamm).LUSD();
        uint ctokenBalance = ICToken(cBorrow).balanceOf(address(this));

        ICToken(cBorrow).redeem(ctokenBalance);

        if(BAMMSwapLike(bamm).isCETH()) {
            profit = address(this).balance;
            msg.sender.transfer(profit);
        }
        else {
            IERC20 src = IERC20(ICToken(BAMMSwapLike(bamm).LUSD()).underlying());
            profit = src.balanceOf(address(this));
            src.transfer(msg.sender, profit);
        }

    }

    // revert on failure
    function checkProfitableArb(uint cBorrowAmount, uint minProfit, BAMMSwapLike bamm, address cCollateral) external returns(bool){
        uint profit = this.arb(address(bamm), cBorrowAmount, cCollateral);
        require(profit >= minProfit, "min profit was not reached");

        return true;
    }      

    fallback() external payable {}
}

contract FlashKeeperFantom {
    FlashArbFantom public arb;
    address public admin;
    uint public maxQtyFactor = (2 ** 4);
    BAMMSwapLike[] public bamms;
    uint public minProfitInUSD = 1e13;

    event KeepOperation(bool succ);
    constructor() public {
        arb = new FlashArbFantom();
        admin = msg.sender;
    }

    function getMaxCBorrow(BAMMSwapLike bamm, address cCollateral) public view returns(uint) {
        uint colBalance = ICToken(cCollateral).balanceOf(address(bamm));
        if(colBalance == 0) return 0;

        uint price = bamm.fetchPrice(cCollateral);
        return colBalance * price / 1e18;        
    }

    function findSmallestQty(uint hint) public returns(uint, address, address) {
        for(uint i = 0 ; i < bamms.length ; i++) {
            if(hint % bamms.length != i) continue;
            BAMMSwapLike bamm = bamms[i];
            uint decimals = 18;
            if(! bamm.isCETH()) {
                IERC20 src = IERC20(ICToken(bamm.LUSD()).underlying());
                decimals = src.decimals();
            }
            
            uint factor = 10 ** decimals;

            uint collCount = bamm.collateralCount();
            for(uint d = 0 ; d < collCount ; d++) {
                if((hint / bamms.length) % bamm.collateralCount() != d) continue;
                address collateral = bamm.collaterals(d);
                uint maxQty = getMaxCBorrow(bamm, collateral) * 90 / 100; // take 90%, don't be greedy

                for(uint qtyFactor = 1 ; qtyFactor <= maxQtyFactor ; qtyFactor = qtyFactor * 2) {
                    uint qty = maxQty / qtyFactor;
                    if(qty == 0) continue;

                    uint minProfit = minProfitInUSD * factor / 1e18;
                 
                    try arb.checkProfitableArb(qty, minProfit, BAMMSwapLike(bamm), collateral) returns(bool /*retVal*/) {
                        return (qty, address(bamm), collateral);
                    } catch {

                    }                    
                }
            }
        }

        return (0, address(0), address(0));
    }


    function checkUpkeep(uint hint) external returns (bool upkeepNeeded, bytes memory performData) {
        (uint qty, address bamm, address dest) = findSmallestQty(hint);

        upkeepNeeded = qty > 0;
        performData = abi.encode(qty, bamm, dest);
    }
    
    function performUpkeep(bytes calldata performData) external {
        (uint qty, address bamm, address dest) = abi.decode(performData, (uint, address, address));
        require(qty > 0, "0 qty");

        arb.arb(bamm, qty, dest);
        
        emit KeepOperation(true);        
    }

    function performUpkeepSafe(bytes calldata performData) external {
        try this.performUpkeep(performData) {
            emit KeepOperation(true);
        }
        catch {
            emit KeepOperation(false);
        }
    }

    function checker(uint hint)
        external
        returns (bool canExec, bytes memory execPayload)
    {
        (bool upkeepNeeded, bytes memory performData) = this.checkUpkeep(hint);
        canExec = upkeepNeeded;

        execPayload = abi.encodeWithSelector(
            FlashKeeperFantom.doer.selector,
            performData
        );
    }

    function doer(bytes calldata performData) external {
        this.performUpkeepSafe(performData);
    }

    function getNumHints() public view returns(uint) {
        uint result = 0;
        for(uint b = 0 ; b < bamms.length ; b++) {
            result += bamms[b].collateralCount();
        }

        return result;
    }    

    receive() external payable {}

    // admin stuff
    function transferAdmin(address newAdmin) external {
        require(msg.sender == admin, "!admin");
        admin = newAdmin;
    }

    function setArb(FlashArbFantom _arb) external {
        require(msg.sender == admin, "!admin");
        arb = _arb;
    }

    function setMinProfitInUSD(uint _minProfitInUSD) external {
        require(msg.sender == admin, "!admin");
        minProfitInUSD = _minProfitInUSD;
    }
    
    function setMaxQtyAttempts(uint numAttempts) external {
        require(msg.sender == admin, "!admin");
        maxQtyFactor = 2 ** numAttempts;
    }

    function addBamm(BAMMSwapLike newBamm) external {
        require(msg.sender == admin, "!admin");        
        bamms.push(newBamm);
    }

    function removeBamm(BAMMSwapLike bamm) external {
        require(msg.sender == admin, "!admin");
        for(uint i = 0 ; i < bamms.length ; i++) {
            if(bamms[i] == bamm) {
                bamms[i] = bamms[bamms.length - 1];
                bamms.pop();

                return;
            }
        }

        revert("bamm does not exist");
    }

    function withdrawToken(IERC20 token, address to, uint qty) external {
        require(msg.sender == admin, "!admin");
        token.transfer(to, qty);
    }    
}