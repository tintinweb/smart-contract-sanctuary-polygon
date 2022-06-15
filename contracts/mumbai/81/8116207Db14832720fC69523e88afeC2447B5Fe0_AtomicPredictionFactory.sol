// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./CloneBase.sol";
import "./interface/IFeeManager.sol";
import "./interface/IMinimalProxy.sol";
import "./interface/IReferralManager.sol";
import "./library/TransferHelper.sol";
import "./CloneBase.sol";

contract AtomicPredictionFactory is Ownable, CloneBase {
    event AtomicPredictionLaunched(address _atomicPrediction);

    event ImplementationLaunched(uint256 _id, address _implementation);
    event ImplementationUpdated(uint256 _id, address _implementation);

    address[] public atomicPredications;

    IFeeManager public feeManager;

    //Trigger for ReferralManager mode
    bool public isReferralManagerEnabled;

    IReferralManager public referralManager;

    mapping(uint256 => address) public implementationIdVsImplementation;

    uint256 public nextId;

    function addImplementation(address _newImplementation) external onlyOwner {
        require(_newImplementation != address(0), "Invalid implementation");
        implementationIdVsImplementation[nextId] = _newImplementation;

        emit ImplementationLaunched(nextId, _newImplementation);

        nextId = nextId + 1;
    }

    function updateImplementation(uint256 _id, address _newImplementation)
        external
        onlyOwner
    {
        address currentImplementation = implementationIdVsImplementation[_id];
        require(currentImplementation != address(0), "Incorrect Id");

        implementationIdVsImplementation[_id] = _newImplementation;
        emit ImplementationUpdated(_id, _newImplementation);
    }

    function _handleFeeManager()
        private
        returns (uint256 feeAmount_, address feeToken_)
    {
        require(address(feeManager) != address(0), "Add FeeManager");
        (feeAmount_, feeToken_) = getFeeInfo();
        if (feeToken_ != address(0)) {
            TransferHelper.safeTransferFrom(
                feeToken_,
                msg.sender,
                address(this),
                feeAmount_
            );

            TransferHelper.safeApprove(
                feeToken_,
                address(feeManager),
                feeAmount_
            );

            feeManager.fetchFees();
        } else {
            require(msg.value == feeAmount_, "Invalid value sent for fee");
            feeManager.fetchFees{value: msg.value}();
        }

        return (feeAmount_, feeToken_);
    }

    function getFeeInfo() public view returns (uint256, address) {
        return feeManager.getFactoryFeeInfo(address(this));
    }

    function _handleReferral(address referrer, uint256 feeAmount) private {
        if (isReferralManagerEnabled && referrer != address(0)) {
            referralManager.handleReferralForUser(
                referrer,
                msg.sender,
                feeAmount
            );
        }
    }

    function _createAtomicPrediction(
        uint256 _id,
        address _owner,
        bytes memory _implementationData
    ) private {
        require(_owner != address(0), "Owner should not be zero address");
        address implementation = implementationIdVsImplementation[_id];
        require(implementation != address(0), "Invalid implementation");

        address atomicPredictionLibrary = createClone(implementation);
        IMinimalProxy(atomicPredictionLibrary).init(_implementationData);

        atomicPredications.push(atomicPredictionLibrary);

        emit AtomicPredictionLaunched(atomicPredictionLibrary);
    }

    function createAtomicPrediction(
        uint256 _id,
        address _owner,
        bytes memory _implementationData
    ) external payable {
        _createAtomicPrediction(_id, _owner, _implementationData);

        _handleFeeManager();
    }

    function createAtomicPredictionWithReferral(
        uint256 _id,
        address _owner,
        address _referrer,
        bytes memory _implementationData
    ) external payable {
        _createAtomicPrediction(_id, _owner, _implementationData);
        (uint256 feeAmount, ) = _handleFeeManager();
        _handleReferral(_referrer, feeAmount);
    }

    function updateFeeManager(address _feeManager) external onlyOwner {
        require(_feeManager != address(0), "Fee Manager address cant be zero");
        feeManager = IFeeManager(_feeManager);
    }

    function updateReferralManagerMode(
        bool _isReferralManagerEnabled,
        address _referralManager
    ) external onlyOwner {
        require(
            _referralManager != address(0),
            "Referral Manager address cant be zero"
        );
        isReferralManagerEnabled = _isReferralManagerEnabled;
        referralManager = IReferralManager(_referralManager);
    }

    function withdrawERC20(address _token) external onlyOwner {
        TransferHelper.safeTransfer(
            address(_token),
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract CloneBase {

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IFeeManager {
    function fetchFees() external payable returns (uint256);
    function fetchExactFees(uint256 _feeAmount) external payable returns (uint256);

    function getFactoryFeeInfo(address _factoryAddress)
        external
        view
        returns (uint256, address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IMinimalProxy {
    function init(
        bytes memory extraData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReferralManager {
    function handleReferralForUser(
        address referrer,
        address user,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

// helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH transfer failed');
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}