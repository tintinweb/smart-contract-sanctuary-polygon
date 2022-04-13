// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./common/ReentrancyGuard.sol";
import "./interfaces/IERC20.sol";
import "./lib/TransferHelper.sol";
import "./lib/SafeMath.sol";

contract VibeRewarder is ReentrancyGuard {
    using TransferHelper for address;
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) public rewardPerMonth;
    mapping(address => mapping(address => uint256)) public lastClaim;
    uint256 public rewardAccounts = 0;

    address operator = msg.sender;

    modifier onlyOperator {
        require(operator == msg.sender, "only-operator");
        _;
    }

    function claimableAmount(address account, address token) public view returns (uint256) {
        uint256 last = lastClaim[account][token];
        uint256 rewardRate = rewardPerMonth[account][token];

        uint256 rewardPerSecond = rewardRate.div(30 days);
        uint256 secondsToReward = block.timestamp.sub(last);

        return secondsToReward * rewardPerSecond;
    }

    function _claim(address account, address token) internal {
        uint256 reward = claimableAmount(account, token);
        if(reward == 0) {
            token.safeTransfer(account, reward);
        }
        lastClaim[account][token] = block.timestamp;
    }

    function _setRewardPerMonth(address account, address token, uint256 reward) internal {
        _claim(account, token);

        if(rewardPerMonth[account][token] > 0 && reward == 0) {
            rewardAccounts--;
        } else if(rewardPerMonth[account][token] == 0 && reward > 0) {
            rewardAccounts++;
        }
        rewardPerMonth[account][token] = reward;
    }

    function claim(address token) external {
        _claim(msg.sender, token);
    }

    function setRewardPerMonth(address account, address token, uint256 reward) external onlyOperator {
        uint256 currentBalance = IERC20(token).balanceOf(address(this));
        require(currentBalance >= reward, "forbidden-set-greater-reserve");

        _setRewardPerMonth(account, token, reward);
    }

    function withdrawReserve(address token, uint256 value) external onlyOperator {
        require(rewardAccounts == 0, "permission-denied");
        token.safeTransfer(msg.sender, value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ReentrancyGuard {
    bool private lock = false;

    modifier nonReentrant() {
        require(!lock, "non-reentrancy-guard");
        lock = true;
        _;
        lock = false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y != 0, "ds-math-div-overflow");
        z = x / y;
    }
}