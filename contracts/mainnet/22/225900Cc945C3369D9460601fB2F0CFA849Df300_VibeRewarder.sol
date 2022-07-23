// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./common/ReentrancyGuard.sol";
import "./common/ERC20.sol";
import "./interfaces/IERC20.sol";
import "./lib/TransferHelper.sol";
import "./lib/SafeMath.sol";


contract VibeRewarder is ReentrancyGuard, ERC20 {
    using TransferHelper for address;
    using SafeMath for uint256;

    mapping(address => uint256) public rewardPerMonth;
    mapping(address => uint256) public lastClaim;
    uint256 public rewardAccounts = 0;
    address public token;

    address operator = msg.sender;

    constructor(address _token) {
        token = _token;

        decimals = IERC20(_token).decimals();
        name = string(abi.encodePacked("Vibe ", IERC20(_token).name()));
        symbol = string(abi.encodePacked("v", IERC20(_token).symbol()));
    }

    modifier onlyOperator {
        require(operator == msg.sender, "only-operator");
        _;
    }

    function claimableAmount(address account) public view returns (uint256) {
        uint256 last = lastClaim[account];
        uint256 rewardRate = rewardPerMonth[account];

        uint256 rewardPerSecond = rewardRate.mul(1e8).div(30 days);
        uint256 secondsToReward = block.timestamp.sub(last);

        return (secondsToReward * rewardPerSecond).div(1e8);
    }

    function claim() external {
        _claim(msg.sender);
        uint256 debt = balanceOf[msg.sender];
        uint256 balance = IERC20(token).balanceOf(address(this));
        
        if(balance < debt) {
            debt = balance;
        }
        _redeem(msg.sender, debt);
    }

    function redeem(uint256 amount) external {
        _redeem(msg.sender, amount);
    }

    function setRewardPerMonth(address account, uint256 reward) external onlyOperator {
        _setRewardPerMonth(account, reward);
    }

    function withdrawReserve(uint256 value) external onlyOperator {
        require(rewardAccounts == 0, "permission-denied");
        token.safeTransfer(msg.sender, value);
    }

    function transferOperator(address _newOperator) external onlyOperator {
        require(msg.sender != address(0), "zero-address");
        require(balanceOf[_newOperator] > 0 || claimableAmount(_newOperator) > 0, "invalid-new-operator");
        operator = _newOperator;
    }

    function _redeem(address account, uint256 amount) internal {
        if(amount == 0) return;
        
        _burn(account, amount);
        token.safeTransfer(account, amount);
    }

    function _claim(address account) internal returns (uint256) {
        uint256 reward = claimableAmount(account);
        lastClaim[account] = block.timestamp;
        if(reward > 0) {
            _mint(account, reward);
        }
        return reward;
    }

    function _setRewardPerMonth(address account, uint256 reward) internal {
        _claim(account);

        if(rewardPerMonth[account] > 0 && reward == 0) {
            rewardAccounts--;
        } else if(rewardPerMonth[account] == 0 && reward > 0) {
            rewardAccounts++;
        }
        rewardPerMonth[account] = reward;
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

import "../lib/SafeMath.sol";
import "../interfaces/IERC20.sol";

contract ERC20 is IERC20 {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal {
        require(balanceOf[from] >= value, "insufficient-funds");
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
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

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
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