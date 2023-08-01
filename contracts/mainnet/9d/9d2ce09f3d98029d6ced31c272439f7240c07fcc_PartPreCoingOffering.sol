/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

/**
 *Submitted for verification at polygonscan.com on 2023-07-28
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestAnswer() external view returns (int256);
}

contract PartPreCoingOffering {
    IERC20 immutable GRL;
    IERC20 immutable DAI;
    AggregatorV3Interface private ethToUsdPriceFeed;
    AggregatorV3Interface private daiToEthPriceFeed;

    uint256 public immutable totalTokens = 1 * 10 ** 8 * 10 ** 9;
    address public immutable admin;
    uint256 public tokensSold;
    bool public isGCOStarted;

    uint256 private immutable tokensPerPhase = 2 * 10 ** 7 * 10 ** 9;
    uint256[] private pricePerPhase;

    uint256 private startTime;
    uint256 private immutable phaseDuration;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(IERC20 _grl, IERC20 _dai) {
        pricePerPhase = new uint256[](5);
        pricePerPhase[0] = 46170482620000000; //0.030387
        pricePerPhase[1] = 48479006750000000; //0.031907
        pricePerPhase[2] = 50902957090000000; //0.033502
        pricePerPhase[3] = 53448104940000000; //0.035177
        pricePerPhase[4] = 56120510190000000; //0.036939
        GRL = _grl;
        DAI = _dai;
        //ethToUsdPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); mainnet
        //daiToEthPriceFeed = AggregatorV3Interface(0x773616E4d11A78F511299002da57A0a94577F1f4); mainnet
        ethToUsdPriceFeed = AggregatorV3Interface(
            0xF9680D99D6C9589e2a93a78A04A279e509205945
        ); //polygon
        daiToEthPriceFeed = AggregatorV3Interface(
            0xFC539A559e170f848323e19dfD66007520510085
        ); //polygon
        admin = msg.sender;
        phaseDuration = 43200;
    }

    modifier onlyOwner() {
        require(msg.sender == admin, "You're not authorized!");
        _;
    }

    function buyWithEth() public payable {
        require(msg.value > 0, "Inavlid eth amount");
        (uint256 grlEthPrice,) = getGrlPrice();
        require(msg.value >= grlEthPrice, "Lower value than Price");
        uint256 tokensToBuy = grlOfEth(msg.value);
        require(
            tokensSold + tokensToBuy <= totalTokens,
            "Not enough tokens left"
        );
        require(
            block.timestamp <= startTime + phaseDuration * 5,
            "No more coin offering!"
        );
        GRL.transfer(msg.sender, tokensToBuy);
        tokensSold += tokensToBuy;
        emit Transfer(address(this), msg.sender, tokensToBuy);
    }

    function buyWithDAI(uint256 _amountOfDAI) public {
        require(_amountOfDAI > 0);
        (, uint256 priceOfGrl) = getGrlPrice();
        require(_amountOfDAI>= priceOfGrl,"Lower value than Price");
        uint256 tokensToBuy = grlOfDai(_amountOfDAI);
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
        GRL.transfer(msg.sender, tokensToBuy);
        tokensSold += tokensToBuy;
    }

    function ethPriceInUSD() public view returns (uint256) {
        int256 answer = ethToUsdPriceFeed.latestAnswer();
        return uint256(answer * 10000000000);
    }

    function daiPriceInEth() public view returns (uint256) {
        (, int256 answer, , , ) = daiToEthPriceFeed.latestRoundData();
        return uint256(answer);
    }

    function convertDaiToEth(uint256 daiAmount) public view returns (uint256) {
        uint256 daiPrice = daiPriceInEth();
        uint256 daiAmountInEth = (daiPrice * daiAmount) / 1000000000000000000;
        return daiAmountInEth;
    }

    function convertEthToUsd(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = ethPriceInUSD();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    function startGCO() external onlyOwner {
        startTime = block.timestamp;
        isGCOStarted = true;
    }

    function grlOfDai(uint256 _amountOfDAI) public view returns (uint256) {
        (, uint256 price) = getGrlPrice();
        uint256 tokensCalculated = (_amountOfDAI*10**9) / price;
        return tokensCalculated;
    }

    function grlOfEth(uint256 _amountOfEth) public view returns (uint256) {
        (, uint256 price) = getGrlPrice();
        uint256 convertedUsd = convertEthToUsd(_amountOfEth);
        uint256 tokensCalculated = (convertedUsd*10**9) / price;
        return tokensCalculated;
    }

    function getGrlPrice() public view returns (uint256, uint256) {
        require(isGCOStarted == true, "GCO not started yet!");
        uint256 currentTime = block.timestamp;
        uint256 fixedFrice = pricePerPhase[4];
        uint256 grlEthPrice;
        uint256 grlPrice;
        if (currentTime <= startTime + phaseDuration) {
            grlPrice = pricePerPhase[0];
            grlEthPrice = convertDaiToEth(pricePerPhase[0]);
        } else if (
            tokensSold >= tokensPerPhase ||
            currentTime <= startTime + phaseDuration * 2
        ) {
            grlPrice = pricePerPhase[1];
            grlEthPrice = convertDaiToEth(pricePerPhase[1]);
        } else if (
            tokensSold >= tokensPerPhase * 2 ||
            currentTime <= startTime + phaseDuration * 3
        ) {
            grlPrice = pricePerPhase[2];
            grlEthPrice = convertDaiToEth(pricePerPhase[2]);
        } else if (
            tokensSold >= tokensPerPhase * 3 ||
            currentTime <= startTime + phaseDuration * 4
        ) {
            grlPrice = pricePerPhase[3];
            grlEthPrice = convertDaiToEth(pricePerPhase[3]);
        } else if (
            tokensSold >= tokensPerPhase * 4 ||
            currentTime <= startTime + phaseDuration * 5
        ) {
            grlPrice = fixedFrice;
            grlEthPrice = convertDaiToEth(fixedFrice);
        } else {
            grlPrice = fixedFrice;
            grlEthPrice = convertDaiToEth(fixedFrice);
        }

        return (grlEthPrice, grlPrice);
    }

    function withdrawGRL() external onlyOwner {
        uint256 grlBalance = GRL.balanceOf(address(this));
        require(grlBalance > 0, "no GRL in contract!");
        GRL.transfer(admin, grlBalance);
    }

    function withdrawEth() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "no eth in the contract!");
        (bool success, ) = admin.call{value: address(this).balance}("");
        require(success);
    }
}