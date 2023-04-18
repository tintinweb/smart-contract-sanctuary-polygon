// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IWETH.sol";
import "./interfaces/IEthHandler.sol";

contract ETHHandler is IEthHandler {
    receive() external payable {}

    //Send WETH and then call withdraw
    function withdraw(address weth, uint256 amount, address payable recipient) external override {
        IWETH(weth).withdraw(amount);
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEthHandler {
    function withdraw(address WETH, uint256 amount, address payable recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function approve(address guy, uint256 wad) external returns (bool);
}