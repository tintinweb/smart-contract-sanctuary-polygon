/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract SAFTCoingOffering {
    IERC20 immutable GRL;
    IERC20 immutable DAI;
    uint256 public immutable totalTokens = 1 * 10**8 * 10**9;
    address public immutable admin;
    uint256 public tokensSold;
    bool public isGCOStarted;

    uint256 private immutable tokensPerPhase = 2 * 10**7 * 10**9;
    uint256[] private pricePerPhase;

    uint256 private startTime;
    uint256 public phaseDuration;

    constructor(
        IERC20 _grl,
        IERC20 _dai
    ) {
        pricePerPhase = new uint256[](5);
        pricePerPhase[0] = 20000000000000000; //0.02
        pricePerPhase[1] = 21000000000000000; //0.021
        pricePerPhase[2] = 22050000000000000; //0.02205
        pricePerPhase[3] = 23152000000000000; //0.023152
        pricePerPhase[4] = 24310000000000000; //0.024310
        GRL = _grl;
        DAI = _dai;
        admin = msg.sender;
        phaseDuration = 604800;
    }
// To make a function to change the duration

    modifier onlyOwner() {
        require(msg.sender == admin, "You're not authorized!");
        _;
    }

    function buyGreelance(uint256 _amountOfGRL) public {
        require(_amountOfGRL > 0, "Invalid amount!");
        require(
            GRL.balanceOf(address(this)) >= _amountOfGRL,
            "System out of greelance!"
        );
        uint256 amountOfDAI = calculateDAI(_amountOfGRL);
        require(
            tokensSold + _amountOfGRL <= totalTokens,
            "Not enough tokens left"
        );
        require(
            block.timestamp <= startTime + phaseDuration * 5,
            "No more coin offering!"
        );
        require(
            DAI.transferFrom(msg.sender, address(this), amountOfDAI),
            "You must Deposit some DAI"
        );
        GRL.transfer(msg.sender, _amountOfGRL);
        tokensSold += _amountOfGRL;
    }

    function exchangeDAIforGreelance(uint256 _amountOfDAI) public {
        require(_amountOfDAI > 0);
        uint256 priceOfGrl = getPrice();
        uint256 tokensToBuy = _amountOfDAI / priceOfGrl;
        require(
            tokensSold + tokensToBuy <= totalTokens,
            "Not enough tokens left"
        );
        require(
            block.timestamp <= startTime + phaseDuration * 5,
            "No more coin offering!"
        );
        require(
            DAI.transferFrom(msg.sender, address(this), _amountOfDAI),
            "You must Deposit some DAI"
        );
        GRL.transfer(msg.sender, tokensToBuy * 10**9);
        tokensSold += tokensToBuy;
    }

    function startGCO() external onlyOwner {
        startTime = block.timestamp;
        isGCOStarted = true;
    }

    function calculateGRL(uint256 _amountOfDAI) public view returns (uint256) {
        uint256 price = getPrice();
        uint256 tokensCalculated = _amountOfDAI / price;
        return tokensCalculated * 10**9;
    }

    function calculateDAI(uint256 _amountOfGRL) public view returns (uint256) {
        uint256 grlPrice = getPrice();
        uint256 amountOfDAI = grlPrice * _amountOfGRL;
        return amountOfDAI / 10**9;
    }

    function changeDuration(uint256 _newDuration) external onlyOwner{
        phaseDuration = _newDuration;
    }
    function getPrice() public view returns (uint256) {
        require(isGCOStarted, "GCO not started yet!");
        uint256 currentTime = block.timestamp;
        uint256 fixedFrice = pricePerPhase[4];
        uint256 grlPrice;
        if (currentTime <= startTime + phaseDuration) {
            grlPrice = pricePerPhase[0];
        } else if (
            tokensSold >= tokensPerPhase ||
            currentTime <= startTime + phaseDuration * 2
        ) {
            grlPrice = pricePerPhase[1];
        } else if (
            tokensSold >= tokensPerPhase * 2 ||
            currentTime <= startTime + phaseDuration * 3
        ) {
            grlPrice = pricePerPhase[2];
        } else if (
            tokensSold >= tokensPerPhase * 3 ||
            currentTime <= startTime + phaseDuration * 4
        ) {
            grlPrice = pricePerPhase[3];
        } else if (
            tokensSold >= tokensPerPhase * 4 ||
            currentTime <= startTime + phaseDuration * 5
        ) {
            grlPrice = fixedFrice;
        } else {
            grlPrice = fixedFrice;
        }

        return grlPrice;
    }

    function retrieveGRL() external onlyOwner {
        uint256 grlBalance = GRL.balanceOf(address(this));
        GRL.transfer(admin, grlBalance);
    }
}