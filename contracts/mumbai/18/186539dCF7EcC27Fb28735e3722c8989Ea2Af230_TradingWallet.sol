// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// address trader mitoone withdraw bezane.
// PolyFarm ham mitoone withdraw bezane.
contract TradingWallet {

    address public polyFarm;
    address public trader;

    constructor(address _polyFarm_, address _trader_) {
        polyFarm = _polyFarm_;
        trader = _trader_;
    }

    modifier onlyTrader() {
        require(
            msg.sender == trader,
            "Only trader can call this function"
        );
        _;
    }
    
    modifier onlyPolyFarm() {
        require(
            msg.sender == polyFarm,
            "Only PolyFarm can call this function"
        );
        _;
    }

    function withdraw(address to, uint256 amount) public onlyTrader {
        payable(to).transfer(amount);
    }

    function pay(address to, uint256 amount) public onlyPolyFarm {
        payable(to).transfer(amount);
    }

    receive() external payable {}
}