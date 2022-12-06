// SPDX-License-Identifier: UNLICENSED

/**
 * Wallchain Wrapper Contract.
 * Designed by Wallchain in Metaverse.
 */

pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./interfaces/IWChainMaster.sol";
import "./interfaces/Utils.sol";
import "@ganache/console.log/console.sol";

contract WallchainWrapper is Ownable {
    event EventMessage(string message);

    IWChainMaster public wchainMaster;
    uint256 public exchangeShare = 80; // 80%
    address public augustusImplementation;

    constructor(IWChainMaster _wchainMaster) {
        wchainMaster = _wchainMaster;
        augustusImplementation = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
    }

    receive() external payable {}

    modifier coverUp(bytes calldata masterInput, address dexBeneficiary) {
        _;
        console.log("coverUp continuation");
        // masterInput should be empty if txn is not profitable
        if (masterInput.length > 8) {
            try
                wchainMaster.execute(
                    masterInput,
                    tx.origin,
                    dexBeneficiary,
                    exchangeShare
                )
            {} catch {
                emit EventMessage("Profit Capturing Error");
            }
        } else {
            emit EventMessage("Non Profit Txn");
        }
    }

    function setShare(uint256 _exchangeProfitShare) external onlyOwner {
        require(_exchangeProfitShare <= 80, "New share is too high");

        exchangeShare = _exchangeProfitShare;
        emit EventMessage("New Share Was Set");
    }

    function upgradeMaster() external onlyOwner {
        address nextAddress = wchainMaster.nextAddress();
        if (address(wchainMaster) != nextAddress) {
            wchainMaster = IWChainMaster(nextAddress);
            emit EventMessage("New WChainMaster Was Set");
            return;
        }
        emit EventMessage("WChainMaster Is Already Up To Date");
    }

    function _revertWithData(bytes memory data) private pure {
        assembly {
            revert(add(data, 32), mload(data))
        }
    }

    function _returnWithData(bytes memory data) private pure {
        assembly {
            return(add(data, 32), mload(data))
        }
    }

    function megaSwap(
        Utils.MegaSwapSellData memory data,
        bytes calldata masterInput,
        address dexBeneficiary
    ) public payable coverUp(masterInput, dexBeneficiary) returns (uint256) {
        console.log("megaSwap start");
        (bool success, bytes memory resultData) = augustusImplementation.delegatecall(abi.encodeWithSelector(0x46c67b6d, data));
        if (!success) {
            _revertWithData(resultData);
        }
        _returnWithData(resultData);
    }

    function buy(
        Utils.BuyData memory data,
        bytes calldata masterInput,
        address dexBeneficiary
    ) public payable coverUp(masterInput, dexBeneficiary) returns (uint256) {
        (bool success, bytes memory resultData) = augustusImplementation.delegatecall(
                abi.encodeWithSelector(
                    /* has to be buy selector */
                    0x46c67b6d,
                    data
                )
            );
        if (!success) {
            _revertWithData(resultData);
        }
        // _returnWithData(resultData);
    }

    function multiSwap(
        Utils.SellData memory data,
        bytes calldata masterInput,
        address dexBeneficiary
    ) public payable coverUp(masterInput, dexBeneficiary) returns (uint256) {
        (bool success, bytes memory resultData) = augustusImplementation.delegatecall(abi.encodeWithSelector(0xa94e78ef, data));
        if (!success) {
            _revertWithData(resultData);
        }
        _returnWithData(resultData);
    }

// simpleSwap((address,address,uint256,uint256,uint256,address[],bytes,uint256[],uint256[],address,address,uint256,bytes,uint256,bytes16),bytes,address)
// 0xe69bec9a fe14c5f6cac67471e8da27bfe582f3c7c3b780c923d64144d423a20d
    function simpleSwap(
        Utils.SimpleData memory data,
        bytes calldata masterInput,
        address dexBeneficiary
    ) public payable coverUp(masterInput, dexBeneficiary) {
        console.log("simpleSwap start");
        (bool success, bytes memory resultData) = augustusImplementation.delegatecall(abi.encodeWithSelector(0x54e3f31b, data));
        if (!success) {
            console.log("simpleSwap revert");
            _revertWithData(resultData);
        }
        console.log("simpleSwap success");
    }

    function simpleBuy(
        Utils.SimpleData calldata data,
        bytes calldata masterInput,
        address dexBeneficiary
    ) external payable coverUp(masterInput, dexBeneficiary) {
        (bool success, bytes memory resultData) = augustusImplementation.delegatecall(abi.encodeWithSelector(0x2298207a, data));
        if (!success) {
            _revertWithData(resultData);
        }
        _returnWithData(resultData);
    }
}

/*solhint-disable avoid-low-level-calls */
// SPDX-License-Identifier: ISC

pragma solidity >=0.7.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IERC20PermitLegacy {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library Utils {
    address private constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function ethAddress() internal pure returns (address) {
        return ETH_ADDRESS;
    }

    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct BuyData {
        address adapter;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Route[] route;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee; //NOT USED
        Route[] route;
    }

    struct Route {
        uint256 index; //Adapter at which index needs to be used
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee; //NOT USED - Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee; //NOT USED - Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }

    function permit(address token, bytes memory permit) internal {
        if (permit.length == 32 * 7) {
            (bool success, ) = token.call(
                abi.encodePacked(IERC20Permit.permit.selector, permit)
            );
            require(success, "Permit failed");
        }

        if (permit.length == 32 * 8) {
            (bool success, ) = token.call(
                abi.encodePacked(IERC20PermitLegacy.permit.selector, permit)
            );
            require(success, "Permit failed");
        }
    }

    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (token == ETH_ADDRESS) {
                (bool result, ) = destination.call{value: amount, gas: 10000}(
                    ""
                );
                require(result, "Failed to transfer Ether");
            } else {
                TransferHelper.safeTransferFrom(
                    token,
                    address(this),
                    destination,
                    amount
                );
            }
        }
    }

     function tokenBalance(address token, address account) internal view returns (uint256) {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6;

interface IWChainMaster {
    function nextAddress() external view returns (address);
    function execute(bytes calldata input, address sender, address beneficiary, uint256 exchangeProfitShare) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.7;

import "./Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.7;

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

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        address consoleAddress = CONSOLE_ADDRESS;
        assembly {
            let argumentsLength := mload(payload)
            let argumentsOffset := add(payload, 32)
            pop(staticcall(gas(), consoleAddress, argumentsOffset, argumentsLength, 0, 0))
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logAddress(address value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", value));
    }

    function logBool(bool value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", value));
    }

    function logString(string memory value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", value));
    }

    function logUint256(uint256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", value));
    }

    function logUint(uint256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", value));
    }

    function logBytes(bytes memory value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", value));
    }

    function logInt256(int256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", value));
    }

    function logInt(int256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", value));
    }

    function logBytes1(bytes1 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", value));
    }

    function logBytes2(bytes2 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", value));
    }

    function logBytes3(bytes3 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", value));
    }

    function logBytes4(bytes4 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", value));
    }

    function logBytes5(bytes5 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", value));
    }

    function logBytes6(bytes6 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", value));
    }

    function logBytes7(bytes7 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", value));
    }

    function logBytes8(bytes8 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", value));
    }

    function logBytes9(bytes9 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", value));
    }

    function logBytes10(bytes10 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", value));
    }

    function logBytes11(bytes11 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", value));
    }

    function logBytes12(bytes12 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", value));
    }

    function logBytes13(bytes13 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", value));
    }

    function logBytes14(bytes14 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", value));
    }

    function logBytes15(bytes15 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", value));
    }

    function logBytes16(bytes16 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", value));
    }

    function logBytes17(bytes17 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", value));
    }

    function logBytes18(bytes18 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", value));
    }

    function logBytes19(bytes19 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", value));
    }

    function logBytes20(bytes20 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", value));
    }

    function logBytes21(bytes21 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", value));
    }

    function logBytes22(bytes22 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", value));
    }

    function logBytes23(bytes23 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", value));
    }

    function logBytes24(bytes24 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", value));
    }

    function logBytes25(bytes25 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", value));
    }

    function logBytes26(bytes26 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", value));
    }

    function logBytes27(bytes27 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", value));
    }

    function logBytes28(bytes28 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", value));
    }

    function logBytes29(bytes29 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", value));
    }

    function logBytes30(bytes30 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", value));
    }

    function logBytes31(bytes31 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", value));
    }

    function logBytes32(bytes32 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", value));
    }

    function log(address value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", value));
    }

    function log(bool value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", value));
    }

    function log(string memory value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", value));
    }

    function log(uint256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", value));
    }

    function log(address value1, address value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", value1, value2));
    }

    function log(address value1, bool value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", value1, value2));
    }

    function log(address value1, string memory value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", value1, value2));
    }

    function log(address value1, uint256 value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", value1, value2));
    }

    function log(bool value1, address value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", value1, value2));
    }

    function log(bool value1, bool value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", value1, value2));
    }

    function log(bool value1, string memory value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", value1, value2));
    }

    function log(bool value1, uint256 value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", value1, value2));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", value1, value2));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", value1, value2));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", value1, value2));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", value1, value2));
    }

    function log(uint256 value1, address value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", value1, value2));
    }

    function log(uint256 value1, bool value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", value1, value2));
    }

    function log(uint256 value1, string memory value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", value1, value2));
    }

    function log(uint256 value1, uint256 value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", value1, value2));
    }

    function log(address value1, address value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", value1, value2, value3));
    }

    function log(address value1, address value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", value1, value2, value3));
    }

    function log(address value1, address value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", value1, value2, value3));
    }

    function log(address value1, address value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", value1, value2, value3));
    }

    function log(address value1, bool value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", value1, value2, value3));
    }

    function log(address value1, bool value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", value1, value2, value3));
    }

    function log(address value1, bool value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", value1, value2, value3));
    }

    function log(address value1, bool value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", value1, value2, value3));
    }

    function log(address value1, string memory value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", value1, value2, value3));
    }

    function log(address value1, string memory value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", value1, value2, value3));
    }

    function log(address value1, string memory value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", value1, value2, value3));
    }

    function log(address value1, string memory value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", value1, value2, value3));
    }

    function log(address value1, uint256 value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", value1, value2, value3));
    }

    function log(address value1, uint256 value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", value1, value2, value3));
    }

    function log(address value1, uint256 value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", value1, value2, value3));
    }

    function log(address value1, uint256 value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", value1, value2, value3));
    }

    function log(bool value1, address value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", value1, value2, value3));
    }

    function log(bool value1, address value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", value1, value2, value3));
    }

    function log(bool value1, address value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", value1, value2, value3));
    }

    function log(bool value1, address value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", value1, value2, value3));
    }

    function log(bool value1, bool value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", value1, value2, value3));
    }

    function log(bool value1, bool value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", value1, value2, value3));
    }

    function log(bool value1, bool value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", value1, value2, value3));
    }

    function log(bool value1, bool value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", value1, value2, value3));
    }

    function log(bool value1, string memory value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", value1, value2, value3));
    }

    function log(bool value1, string memory value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", value1, value2, value3));
    }

    function log(bool value1, string memory value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", value1, value2, value3));
    }

    function log(bool value1, string memory value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", value1, value2, value3));
    }

    function log(bool value1, uint256 value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", value1, value2, value3));
    }

    function log(bool value1, uint256 value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", value1, value2, value3));
    }

    function log(bool value1, uint256 value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", value1, value2, value3));
    }

    function log(bool value1, uint256 value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", value1, value2, value3));
    }

    function log(uint256 value1, address value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", value1, value2, value3));
    }

    function log(uint256 value1, address value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", value1, value2, value3));
    }

    function log(uint256 value1, address value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", value1, value2, value3));
    }

    function log(uint256 value1, address value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", value1, value2, value3));
    }

    function log(uint256 value1, bool value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", value1, value2, value3));
    }

    function log(uint256 value1, bool value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", value1, value2, value3));
    }

    function log(uint256 value1, bool value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", value1, value2, value3));
    }

    function log(uint256 value1, bool value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", value1, value2, value3));
    }

    function log(uint256 value1, string memory value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", value1, value2, value3));
    }

    function log(uint256 value1, string memory value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", value1, value2, value3));
    }

    function log(uint256 value1, string memory value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", value1, value2, value3));
    }

    function log(uint256 value1, string memory value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", value1, value2, value3));
    }

    function log(uint256 value1, uint256 value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", value1, value2, value3));
    }

    function log(uint256 value1, uint256 value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", value1, value2, value3));
    }

    function log(uint256 value1, uint256 value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", value1, value2, value3));
    }

    function log(uint256 value1, uint256 value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", value1, value2, value3));
    }

    function log(address value1, address value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", value1, value2, value3, value4));
    }
}