// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "./IERC20.sol";

contract Receiver {
    event Reception(address token, address from, uint256 amount);

    fallback() external payable {
        if (msg.value > 0) {
            emit Reception(address(0), msg.sender, msg.value);
            return;
        }

        uint256 cdSize;

        assembly {
            cdSize := calldatasize()
        }

        require(cdSize >= 20);

        address tokenAddress;

        assembly {
            tokenAddress := shr(96, calldataload(0))
        }

        uint256 allowance = IERC20(tokenAddress).allowance(
            msg.sender,
            address(this)
        );

        require(allowance > 0);

        require(
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                allowance
            )
        );

        emit Reception(tokenAddress, msg.sender, allowance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}