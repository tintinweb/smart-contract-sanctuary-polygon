// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IStoneFlashBorrower.sol";
import "../interfaces/IStone.sol";
import "../interfaces/IERC20.sol";
import "../lib/TransferHelper.sol";

contract FlashLoaner is IStoneFlashBorrower {
    address private _stoneAddressBuffer;
    uint256 private _amountToReturn;
    event FlashLoanSuccess();

    function execute(address stone, uint256 amount) external {
        _stoneAddressBuffer = stone;
        _amountToReturn = amount + ((amount / 100000) * 5);

        IStone(stone).flash(address(this), amount, "");
    }

    function executeFail(address stone, uint256 amount) external {
        _stoneAddressBuffer = stone;
        _amountToReturn = 0;
        IStone(stone).flash(address(this), amount, "");
    }

    function onStoneFlash(address, address token, uint256 amount, bytes calldata) external returns (bytes4) {
        require(msg.sender == _stoneAddressBuffer, "permission-denied");
        _stoneAddressBuffer = address(0);
        
        require(IERC20(token).balanceOf(address(this)) >= amount, "invalid-balance");
        TransferHelper.safeTransfer(token, msg.sender, _amountToReturn);
        emit FlashLoanSuccess();
        return IStoneFlashBorrower.onStoneFlash.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStoneFlashBorrower {
    function onStoneFlash(address operator, address token, uint256 amount, bytes memory data) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface IStone {
    function mint(address to, uint256 unlockTime) external;
    function burn(uint256 tokenId) external;
    function withdraw(address to) external returns (uint256);
    function token() external returns (address);
    function flash(
        address borrower, 
        uint256 amount, 
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function decimals() external returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}