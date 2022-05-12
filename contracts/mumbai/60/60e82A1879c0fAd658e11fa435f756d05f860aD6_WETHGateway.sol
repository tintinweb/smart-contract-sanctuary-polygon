//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IWETH} from "./interfaces/IWETH.sol";
import {IBridge} from "./interfaces/IBridge.sol";


contract WETHGateway {
    IWETH internal immutable WETH;
    IBridge internal immutable BRIDGE;
    address public bridgeAddress; 


    constructor(address weth, address bridge) {
        WETH = IWETH(weth);
        BRIDGE= IBridge(bridge);
        bridgeAddress= bridge;
    }

    function depositETH(uint8 destinationChainID,bytes32 resourceID,bytes calldata data) external payable {
        WETH.deposit{value: msg.value}();
        WETH.approve(bridgeAddress, msg.value);
        BRIDGE.deposit(destinationChainID, resourceID,data);
    }

    function withdrawETH(uint256 amount) external {
        
        uint256 amountToWithdraw = amount;
        WETH.withdraw(amountToWithdraw);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBridge {

  function deposit(uint8 destinationChainID, bytes32 resourceID, bytes calldata data) external payable;

}