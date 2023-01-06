// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface token {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract DGTScatterContract {
    token public DAI = token(0xc71D4BFBF1914f7B1e977bceC4bc9A94f96178F5);

    address public a1;
    address public a2;
    address public a3;

    address owner;

    constructor(address _a1, address _a2, address _a3) {
        a1 = _a1;
        a2 = _a2;
        a3 = _a3;
        owner = msg.sender;
    }

    function withdraw() public {
        uint256 balance = DAI.balanceOf(address(this));
        DAI.transfer(a1, balance / 3);
        DAI.transfer(a2, balance / 3);
        DAI.transfer(a3, balance / 3);
    }

    function changeAddress(uint256 n, address addr) external onlyOwner {
        if(n == 1) {
            a1 = addr;
        }
        else if(n == 2) {
            a2 = addr;
        }
        else if(n == 3) {
            a3 = addr;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}