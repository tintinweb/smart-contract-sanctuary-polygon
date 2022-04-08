//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./lib/IChildChainManager.sol";
import "./lib/IChildToken.sol";

contract WithdrawToWrapperChild {
    IChildChainManager public immutable childChainManager;

    event MessageSent(bytes);

    constructor(IChildChainManager _childChainManager) {
        childChainManager = _childChainManager;
    }

    function withdrawTo(IChildToken _childToken, uint256 _amount, address _destination) external {
        address _rootToken = childChainManager.childToRootToken(address(_childToken));
        require(_rootToken != address (0), "NO_ROOT_TOKEN");
        require(_childToken.transferFrom(msg.sender, address(this), _amount), "TRANSFER_FAILED");
        _childToken.withdraw(_amount);
        emit MessageSent(abi.encode(_rootToken, _childToken, _amount, _destination));
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IChildChainManager {
	function childToRootToken(address rootToken) external returns (address);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IChildToken {
    function withdraw(uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}