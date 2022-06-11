/**
 *Submitted for verification at polygonscan.com on 2022-06-11
*/

/**
 *Submitted for verification at polygonscan.com on 2022-04-04
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

contract FlashArb {
    SushiRouterLike constant SUSHI_ROUTER = SushiRouterLike(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    address constant WMATIC = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address constant H_MATIC = address(0xEbd7f3349AbA8bB15b897e03D6c1a4Ba95B55e31);
    
    function dumpOnSushi(address src, uint srcAmount, address dest) public {
        address[] memory path = new address[](3);
        path[0] = src;
        path[1] = WMATIC;
        path[2] = dest;

        IERC20(src).approve(address(SUSHI_ROUTER), srcAmount);
        SUSHI_ROUTER.swapExactTokensForTokens(srcAmount, 1, path, address(this), now + 1);
    }

    function dumpMaticOnSushi(uint srcAmount, address dest) public {
        address[] memory path = new address[](2);
        path[0] = WMATIC;
        path[1] = dest;

        SUSHI_ROUTER.swapExactETHForTokens.value(srcAmount)(1, path, address(this), now + 1);
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
            dumpOnSushi(underlying, underlyingCollateralAmount, debtUnderlying);
        }
        else {
            dumpMaticOnSushi(underlyingCollateralAmount, debtUnderlying);
        }
        // deposit all balance to cBorrow
        uint debtUnderlyingBalance = IERC20(debtUnderlying).balanceOf(address(this));
        IERC20(debtUnderlying).approve(address(debt), debtUnderlyingBalance);
     
        debt.mint(debtUnderlyingBalance);

        // give allowance, to repay the flash loan
        debt.approve(msg.sender, lusdAmount); // this can be exploited if the contract has non zero balance
    }    

    function arb(address bamm, uint cBorrowAmount, address cCollateral) public returns(uint profit){
        bytes memory data = abi.encode(BAMMSwapLike(bamm).cBorrow(), cCollateral, cCollateral == H_MATIC);
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

contract FlashKeeper {
    FlashArb public arb;
    address public admin;
    uint public maxQtyFactor = (2 ** 4);
    BAMMSwapLike[] public bamms;
    uint public minProfitInUSD = 1e13;

    event KeepOperation(bool succ);

    constructor() public {
        arb = new FlashArb();
        admin = msg.sender;
    }

    function getMaxCBorrow(BAMMSwapLike bamm, address cCollateral) public view returns(uint) {
        uint colBalance = ICToken(cCollateral).balanceOf(address(bamm));
        if(colBalance == 0) return 0;

        uint price = bamm.fetchPrice(cCollateral);
        return colBalance * 1e18 / price;        
    }

    function findSmallestQty() public returns(uint, address, address) {
        for(uint i = 0 ; i < bamms.length ; i++) {
            BAMMSwapLike bamm = bamms[i];
            uint decimals = 18;
            if(! bamm.isCETH()) {
                IERC20 src = IERC20(ICToken(bamm.LUSD()).underlying());
                decimals = src.decimals();
            }
            
            uint factor = 10 ** decimals;

            uint collCount = bamm.collateralCount();
            for(uint d = 0 ; d < collCount ; d++) {
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


    function checkUpkeep(bytes calldata /*checkData*/) external returns (bool upkeepNeeded, bytes memory performData) {
        (uint qty, address bamm, address dest) = findSmallestQty();

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

    function checker()
        external
        returns (bool canExec, bytes memory execPayload)
    {
        (bool upkeepNeeded, bytes memory performData) = this.checkUpkeep(bytes(""));
        canExec = upkeepNeeded;

        execPayload = abi.encodeWithSelector(
            FlashKeeper.doer.selector,
            performData
        );
    }

    function doer(bytes calldata performData) external {
        this.performUpkeepSafe(performData);
    }    

    receive() external payable {}

    // admin stuff
    function transferAdmin(address newAdmin) external {
        require(msg.sender == admin, "!admin");
        admin = newAdmin;
    }

    function setArb(FlashArb _arb) external {
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