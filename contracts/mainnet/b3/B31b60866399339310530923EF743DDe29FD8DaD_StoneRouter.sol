// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/IWETH.sol";
import "./interfaces/IStone.sol";
import "./common/StoneData.sol";
import "./interfaces/IStoneFactory.sol";
import "./interfaces/IERC20Mintable.sol";
import "./interfaces/IVerificationTokenOracle.sol";
import "./lib/TransferHelper.sol";
import "./lib/SafeMath.sol";

import "./common/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract StoneRouter is ReentrancyGuard {
    using SafeMath for uint256;

    IWETH public weth;
    IStoneFactory public factory;
    IERC20Mintable public rewardToken;
    IVerificationTokenOracle public verificationTokenOracle;
    mapping(address => mapping(uint256 => uint256)) public stoneReward;

    address private _creator = msg.sender;

    constructor(
        IStoneFactory _factory, 
        IVerificationTokenOracle _verificationTokenOracle, 
        IWETH _weth
    ) {
        weth = _weth;
        factory = _factory;
        verificationTokenOracle = _verificationTokenOracle;
    }

    function initRewardToken(IERC20Mintable _rewardToken) external {
        require(_creator == msg.sender && address(rewardToken) == address(0));
        rewardToken = _rewardToken;
    }

    function depositEth(address to, uint256 unlockTime) external payable nonReentrant {
        address wethStone = factory.createOrGetStone(address(weth));
        weth.deposit{value: msg.value}();
        weth.transfer(wethStone, msg.value);
        uint256 tokenId = IStone(wethStone).mint(to, unlockTime);
        _insertTokenReward(wethStone, tokenId);
    }

    function withdrawEth(uint256 tokenId, address to) external nonReentrant {
        address wethStone = factory.createOrGetStone(address(weth));
        uint256 amount = _burnAndWithdraw(wethStone, tokenId, address(this));
        weth.withdraw(amount);
        TransferHelper.safeTransferETH(to, amount);
    }

    function deposit(address token, address to, uint256 value, uint256 unlockTime) external nonReentrant {
        address stone = factory.createOrGetStone(token);
        TransferHelper.safeTransferFrom(token, msg.sender, stone, value);
        uint256 tokenId = IStone(stone).mint(to, unlockTime);
        _insertTokenReward(stone, tokenId);
    }
    
    function withdraw(address token, uint256 tokenId, address to) external nonReentrant {
        address stone = factory.createOrGetStone(token);
        _burnAndWithdraw(stone, tokenId, to);
    }

    function _insertTokenReward(address stone, uint256 tokenId) internal {
        StoneData memory stoneData = IStone(stone).stonesInfo(tokenId);
        address token = IStone(stone).token();
        uint256 reward = verificationTokenOracle.reward(token);

        if(reward > 0) {
            uint256 rewardPerTime = stoneData.unlockTime > stoneData.createdTime ? 
                                    stoneData.unlockTime - stoneData.createdTime : 
                                    0;
            stoneReward[stone][tokenId] = rewardPerTime.mul(reward).mul(stoneData.value).div(1e18);
        }
    }

    function _burnAndWithdraw(address stone, uint256 tokenId, address to) private returns (uint256) {
        IStone(stone).burn(tokenId);

        uint256 rewardAmount = stoneReward[stone][tokenId];
        if(rewardAmount > 0 && address(rewardToken) != address(0)) {
            stoneReward[stone][tokenId] = 0;
            rewardToken.mint(to, rewardAmount);
        }
        return IStone(stone).withdraw(to);
    }

    function onERC721Received(address operator, address, uint256 tokenId, bytes calldata) external returns (bytes4) {
        _burnAndWithdraw(msg.sender, tokenId, operator);
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address, uint256) external;
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../common/StoneData.sol";

interface IStone {
    function mint(address to, uint256 unlockTime) external returns (uint256 tokenId); 
    function burn(uint256 tokenId) external;
    function withdraw(address to) external returns (uint256);
    function token() external view returns (address);
    function reserve() external view returns (uint256);
    function flash(
        address borrower, 
        uint256 amount, 
        bytes calldata data
    ) external returns (bool);
    function getApproved(uint256) external view returns (address);
    function isApprovedForAll(address,address) external view returns (bool);
    function ownerOf(uint256) external view returns (address);
    function stonesInfo(uint256) external view returns (StoneData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct StoneData {
    uint256 unlockTime;
    uint256 value;
    uint256 createdTime;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStoneFactory {
    function createStone(address token) external returns (address stone);
    function createOrGetStone(address token) external returns (address stone);
    function feeTo() external returns (address);
    function allStones(address) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";
interface IERC20Mintable is IERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVerificationTokenOracle {
    function STATUS_NONE() external pure returns (uint8);
    function STATUS_VERIFIED() external pure returns (uint8);
    function STATUS_SCAM() external pure returns (uint8);
    function reward(address) external view returns (uint256);
    function status(address) external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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