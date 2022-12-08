// SPDX-License-Identifier: UNLICENSED

/**
 * Wallchain Wrapper Contract.
 * Designed by Wallchain in Metaverse.
 */

pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./interfaces/IWChainMaster.sol";
import "./interfaces/Utils.sol";

contract WallchainWrapper is Ownable {
    event EventMessage(string message);

    IWChainMaster public wchainMaster;
    uint256 public exchangeShare = 60; // 60%
    address public augustusImplementation;

    constructor(IWChainMaster _wchainMaster, address _augustus) {
        wchainMaster = _wchainMaster;
        augustusImplementation = _augustus;
    }

    receive() external payable {}

    function coverUp(bytes calldata masterInput, address dexBeneficiary)
        private
    {
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

    function setAugustus(address _augustus) external onlyOwner {
        require(
            _augustus != augustusImplementation,
            "Augustus address is not new."
        );

        augustusImplementation = _augustus;
        emit EventMessage("New Augustus Was Set");
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
    ) public payable returns (uint256) {
        (bool success, bytes memory resultData) = augustusImplementation
            .delegatecall(abi.encodeWithSelector(0x46c67b6d, data));
        if (!success) {
            _revertWithData(resultData);
        }
        coverUp(masterInput, dexBeneficiary);
        _returnWithData(resultData);
    }

    function buy(
        Utils.BuyData memory data,
        bytes calldata masterInput,
        address dexBeneficiary
    ) public payable returns (uint256) {
        (bool success, bytes memory resultData) = augustusImplementation
            .delegatecall(abi.encodeWithSelector(0xb6a4e794, data));
        if (!success) {
            _revertWithData(resultData);
        }
        coverUp(masterInput, dexBeneficiary);
        _returnWithData(resultData);
    }

    function multiSwap(
        Utils.SellData memory data,
        bytes calldata masterInput,
        address dexBeneficiary
    ) public payable returns (uint256) {
        (bool success, bytes memory resultData) = augustusImplementation
            .delegatecall(abi.encodeWithSelector(0xa94e78ef, data));
        if (!success) {
            _revertWithData(resultData);
        }
        coverUp(masterInput, dexBeneficiary);
        _returnWithData(resultData);
    }

    function simpleSwap(
        Utils.SimpleData memory data,
        bytes calldata masterInput,
        address dexBeneficiary
    ) public payable returns (uint256) {
        (bool success, bytes memory resultData) = augustusImplementation
            .delegatecall(abi.encodeWithSelector(0x54e3f31b, data));
        if (!success) {
            _revertWithData(resultData);
        }
        coverUp(masterInput, dexBeneficiary);
        _returnWithData(resultData);
    }

    function simpleBuy(
        Utils.SimpleData calldata data,
        bytes calldata masterInput,
        address dexBeneficiary
    ) external payable returns (uint256) {
        (bool success, bytes memory resultData) = augustusImplementation
            .delegatecall(abi.encodeWithSelector(0x2298207a, data));
        if (!success) {
            _revertWithData(resultData);
        }
        coverUp(masterInput, dexBeneficiary);
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