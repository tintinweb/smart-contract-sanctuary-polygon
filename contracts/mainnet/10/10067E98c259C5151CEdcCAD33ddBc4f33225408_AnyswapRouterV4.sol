// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { IAnyswapRouterV4Min } from './IAnyswapRouterV4Min.sol';
import { Basic, IERC20Min } from '../../../common/Basic.sol';

contract AnyswapRouterV4 is Basic {
    IAnyswapRouterV4Min private immutable anyswapRouter;

    constructor(address executorMemory, address _anyswapRouter) Basic(executorMemory) {
        anyswapRouter = IAnyswapRouterV4Min(_anyswapRouter);
    }

    function swapOut(
        address token,
        address tokenUnderlying,
        address to,
        uint256 amount,
        uint256 toChainID,
        uint16 getId,
        bool underlying
    ) internal {
        amount = getUint(getId, amount);
        if (to == address(0)) to = msg.sender;
        if (underlying) {
            if (amount == 0) amount = IERC20Min(tokenUnderlying).balanceOf(address(this));
            approve(tokenUnderlying, address(anyswapRouter), amount);
            anyswapRouter.anySwapOutUnderlying(token, to, amount, toChainID);
        } else {
            if (amount == 0) amount = IERC20Min(token).balanceOf(address(this));
            anyswapRouter.anySwapOut(token, to, amount, toChainID);
        }
    }

    function anySwapOut(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID,
        uint16 getId
    ) external {
        swapOut(token, address(0), to, amount, toChainID, getId, false);
    }

    function anySwapOutUnderlying(
        address token,
        address tokenUnderlying,
        address to,
        uint256 amount,
        uint256 toChainID,
        uint16 getId
    ) external {
        swapOut(token, tokenUnderlying, to, amount, toChainID, getId, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IAnyswapRouterV4Min {
    function anySwapOut(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;

    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import { Storage } from './Storage.sol';
import { SafeERC20Min } from '../libraries/SafeERC20Min.sol';
import { IERC20Min } from './Interfaces.sol';

abstract contract Basic is Storage {
    using SafeERC20Min for address;

    /* solhint-disable no-empty-blocks */
    constructor(address executorMemory_) Storage(executorMemory_) {}

    function approve(
        address token,
        address spender,
        uint256 amount
    ) internal {
        if (IERC20Min(token).allowance(address(this), spender) < amount)
            token.safeApprove(spender, type(uint256).max);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import { IExecutorMemory } from './Interfaces.sol';

abstract contract Storage {
    // replicate storage of Executor to access callBackCaller for callback authorization
    address internal owner;
    address internal callBackCaller;
    IExecutorMemory internal immutable executorMemory;

    constructor(address executorMemory_) {
        executorMemory = IExecutorMemory(executorMemory_);
    }

    function setUint(uint16 id, uint256 val) internal {
        if (id != 0) executorMemory.setUint(id, val);
    }

    function getUint(uint16 id, uint256 val) internal returns (uint256) {
        return id == 0 ? val : executorMemory.getUint(id);
    }

    function setAddress(uint16 id, address val) internal {
        if (id != 0) executorMemory.setAddress(id, val);
    }

    function getAddress(uint16 id, address val) internal returns (address) {
        return id == 0 ? val : executorMemory.getAddress(id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

library SafeERC20Min {

	function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'SE: TF'
        );
    }

	function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'SE: TFF'
        );
    }

	function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'SE: AF'
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IExecutor {
    function initialize(address owner, address callBackReceiver) external;
}

interface IExecutorMemory {
    function setUint(uint16 id, uint256 val) external;

    function getUint(uint16 id) external returns (uint256);

    function setAddress(uint16 id, address val) external;

    function getAddress(uint16 id) external returns (address);
}

interface IERC20Min {
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 is IERC20Min {
    function totalSupply() external view returns (uint256);
}

interface IWEthMin {
    function deposit() external payable;

    function withdraw(uint256) external;
}