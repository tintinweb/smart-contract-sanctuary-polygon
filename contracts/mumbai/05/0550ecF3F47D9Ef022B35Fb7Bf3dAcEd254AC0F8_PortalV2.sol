// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../utils/Typecast.sol";
import "../interfaces/IGateKeeper.sol";


contract EndPoint is Typecast, Ownable {

    /// @dev
    string public version;
    /// @dev
    address public gateKeeper;
    /// @dev
    address public bridge;
    /// @dev
    address public whitelist;
    /// @dev
    address public treasury;
    /// @dev clp address book
    address public addressBook;

    modifier onlyBridge() {
        require(bridge == msg.sender, "EndPoint: bridge only");
        _;
    }

    constructor (address gateKeeper_, address whitelist_, address treasury_, address addressBook_) {
        version = "2.2.3";
        _setBridge(gateKeeper_);
        gateKeeper = gateKeeper_;
        whitelist = whitelist_;
        treasury = treasury_;
        addressBook = addressBook_;
    }

    function setGateKeeper(address gateKeeper_) external onlyOwner {
        _setBridge(gateKeeper_);
        gateKeeper = gateKeeper_;
    }

    function setWhitelist(address whitelist_) external onlyOwner {
        whitelist = whitelist_;
    }

    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }

    function setAddressBook(address addressBook_) external onlyOwner {
        addressBook = addressBook_;
    }

    function _setBridge(address gateKeeper_) private {
        address bridge_ = IGateKeeper(gateKeeper_).bridge();
        require(bridge_ != address(0), "Portal: GateKeeper not initialized");
        bridge = bridge_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./EndPoint.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWhitelist.sol";
import "../interfaces/IAddressBook.sol";


contract PortalV2 is EndPoint {

    /// @dev locked balances
    mapping(address => uint256) public balanceOf;

    event Locked(address token, uint256 amount, address from, address to);
    event Unlocked(address token, uint256 amount, address from, address to);

    modifier checkAmount(uint256 amount, address token) {
        require(
            IWhitelist(whitelist).tokenMin(token) < amount && IWhitelist(whitelist).tokenMax(token) > amount,
            "Portal: wrong amount"
        );
        _;
    }

    modifier onlyRouter() {
        address router = IAddressBook(addressBook).router(uint64(block.chainid));
        require(router == msg.sender, "Portal: router only");
        _;
    }

    constructor (
        address gateKeeper_,
        address whitelist_,
        address treasury_,
        address addressBook_
    ) EndPoint(gateKeeper_, whitelist_, treasury_, addressBook_) {

    }

    /**
     * @dev Lock token.
     *
     * @param token token address to synthesize;
     * @param amount amount to synthesize;
     * @param from sender address;
     * @param to receiver address.
     */
    function lock(
        address token,
        uint256 amount,
        address from,
        address to
    ) external onlyRouter checkAmount(amount, token) {
        require(IWhitelist(whitelist).tokenList(token), "Portal: token must be whitelisted");
        _updateBalance(token, amount);
        emit Locked(token, amount, from, to);
    }

    /**
     * @dev Unlock. Can be called only by router after initiation on a second chain.
     *
     * @param requestId request id;
     * @param otoken token address to unsynth;
     * @param amount amount to unsynth;
     * @param from sender address;
     * @param to recipient address.
     */
    function unlock(
        bytes32 requestId,
        address otoken,
        uint256 amount,
        address from,
        address to
    ) external onlyRouter returns (uint256 amountOut) {
        require(IWhitelist(whitelist).tokenList(otoken), "Portal: token must be whitelisted");

        // TODO denom constant
        uint256 feeAmount = amount * IWhitelist(whitelist).bridgeFee(otoken) / 10000;
        amountOut = amount - feeAmount;
        TransferHelper.safeTransfer(otoken, to, amountOut);
        TransferHelper.safeTransfer(otoken, treasury, feeAmount);
        balanceOf[otoken] -= amount;

        emit Unlocked(otoken, amount, from, to);
    }

    function _updateBalance(address token, uint256 expectedAmount) private {
        uint256 oldBalance = balanceOf[token];
        require(
            (IERC20(token).balanceOf(address(this)) - oldBalance) >= expectedAmount,
            "Portal: insufficient balance"
        );
        balanceOf[token] += expectedAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IAddressBook {
    /// @dev returns portal by given chainId
    function portal(uint64 chainId) external returns (address);

    /// @dev returns synthesis by given chainId
    function synthesis(uint64 chainId) external returns (address);

    /// @dev returns router by given chainId
    function router(uint64 chainId) external returns (address);

    /// @dev returns cryptoPoolAdapter by given chainId
    function cryptoPoolAdapter(uint64 chainId) external returns (address);

    /// @dev returns stablePoolAdapter by given chainId
    function stablePoolAdapter(uint64 chainId) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function balanceOf(address user) external returns (uint256);

    function decimals() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IGateKeeper {

    function calculateCost(
        address payToken,
        uint256 dataLength,
        uint256 chainIdTo,
        address sender
    ) external returns (uint256 amountToPay);

    function sendData(
        bytes calldata data,
        address to,
        uint256 chainIdTo,
        address payToken
    ) external payable returns (bytes32);

    function getNonce() external view returns (uint256);

    function bridge() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWhitelist {
    
    function tokenList(address token) external returns (bool);

    function poolTokensList(address pool) external returns (address[] calldata);

    function checkDestinationToken(address pool, int128 index) external view returns(bool);

    function nativeReturnAmount() external returns(uint256);

    function stableFee() external returns(uint256);

    function dexList(address dexAddr) external returns (bool);

    function dexFee(address dexAddr) external returns (uint256);

    function tokenMin(address token) external returns(uint256);

    function tokenMax(address token) external returns(uint256);

    function bridgeFee(address token) external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Typecast {
    function castToAddress(bytes32 x) public pure returns (address) {
        return address(uint160(uint256(x)));
    }

    function castToBytes32(address a) public pure returns (bytes32) {
        return bytes32(uint256(uint160(a)));
    }
}