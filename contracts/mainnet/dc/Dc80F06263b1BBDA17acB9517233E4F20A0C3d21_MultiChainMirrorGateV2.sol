// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./multichain/IAnyswapV6CallProxy.sol";
import "./multichain/IApp.sol";

struct LockedBalance {
    int128 amount;
    uint256 end;
}

struct MirroredChain {
    uint256 chain_id;
    uint256 escrow_count;
}

interface IVotingEscrow {
    function locked(address _user) external view returns(LockedBalance memory);
}

interface IMirroredVotingEscrow {

    function voting_escrows(uint256 _index) external view returns(address);

    function mirrored_locks(address _user, uint256 _chain, uint256 _escrow_id) external view returns(LockedBalance memory);

    function mirror_lock(address _to, uint256 _chain, uint256 _escrow_id, uint256 _value, uint256 _unlock_time) external;
}

contract MultiChainMirrorGateV2 is Ownable, Pausable, IApp {

    uint256 chainId;

    IMirroredVotingEscrow public mirrorEscrow;

    IAnyswapV6CallProxy public endpoint;

    constructor(IAnyswapV6CallProxy _endpoint, IMirroredVotingEscrow _mirrorEscrow, uint256 _chainId) public {
        endpoint = _endpoint;
        mirrorEscrow = _mirrorEscrow;
        chainId = _chainId;
    }

    function changeMirroredVotingEscrow(address _newMirrorVE) external onlyOwner {
        require(_newMirrorVE != address(0)); 
        IMirroredVotingEscrow _newMirror = IMirroredVotingEscrow(_newMirrorVE);
        require(_newMirror != mirrorEscrow);
        mirrorEscrow = _newMirror;
    }

    function mirrorLocks(uint256 _toChainId, address _toMirrorGate, uint256[] memory _chainIds, uint256[] memory _escrowIds, int128[] memory _lockAmounts, uint256[] memory _lockEnds) external payable whenNotPaused {
        require(_toChainId != chainId, "Cannot mirror from/to same chain");

        uint256 nbLocks_ = _chainIds.length;
        address user_ = _msgSender();
        for (uint256 i = 0; i < nbLocks_; i++) {
            require(_chainIds[i] != _toChainId, "Cannot mirror target chain locks");

            if (_chainIds[i] == chainId) {
                address escrow_ = mirrorEscrow.voting_escrows(i);
                LockedBalance memory lock_ = IVotingEscrow(escrow_).locked(user_);

                require(lock_.amount == _lockAmounts[i], "Incorrect lock amount");
                require(lock_.end == _lockEnds[i], "Incorrect lock end");
            } else {
                LockedBalance memory mirroredLock_ = mirrorEscrow.mirrored_locks(user_, _chainIds[i], _escrowIds[i]);

                require(mirroredLock_.amount == _lockAmounts[i], "Incorrect lock amount");
                require(mirroredLock_.end == _lockEnds[i], "Incorrect lock end");
            }
        }

        bytes memory payload = abi.encode(user_, _chainIds, _escrowIds, _lockAmounts, _lockEnds);
        endpoint.anyCall{value: msg.value}(_toMirrorGate, payload, address(0), _toChainId);
    }

    function calculateFee(address _user, uint256 _toChainID, uint256[] memory _chainIds, uint256[] memory _escrowIds, int128[] memory _lockAmounts, uint256[] memory _lockEnds) external view returns (uint256) {
        bytes memory payload = abi.encode(_user, _chainIds, _escrowIds, _lockAmounts, _lockEnds);
        return endpoint.calcSrcFees(address(this), _toChainID, payload.length);
    }

    function anyFallback(address _to, bytes calldata _data) override external {

    }

    function anyExecute(bytes calldata _data) override external returns (bool success, bytes memory result) {
        require(_msgSender() == address(endpoint), "Only multichain enpoint can trigger mirroring");

        (address to_, uint256[] memory chainIds_, uint256[] memory escrowIds_, uint256[] memory lockAmounts_, uint256[] memory lockEnds_) = abi.decode(_data, (address, uint256[], uint256[], uint256[], uint256[]));

        uint256 nbLocks = chainIds_.length;
        for (uint256 i = 0; i < nbLocks; i++) {
            mirrorEscrow.mirror_lock(to_, chainIds_[i], escrowIds_[i], lockAmounts_[i], lockEnds_[i]);
        }

        return (true, "");
    }

    function recoverExecutionBudget() external onlyOwner {
        uint256 amount_ = endpoint.executionBudget(address(this));
        endpoint.withdraw(amount_);

        uint256 balance_ = address(this).balance;

        (bool success, ) = msg.sender.call{value: balance_}("");
        require(success, "Fee transfer failed");
    }

    function setEndpoint(IAnyswapV6CallProxy _endpoint) external onlyOwner {
        endpoint = _endpoint;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unPause() external onlyOwner whenPaused {
        _unpause();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IAnyswapV6CallProxy {

    function anyCall(address _to, bytes calldata _data, address _fallback, uint256 _toChainID) external payable;

    function calcSrcFees(address _app, uint256 _toChainID, uint256 _dataLength) external view returns (uint256);

    function deposit(address _account) external payable;

    function withdraw(uint256 _amount) external;

    function executionBudget(address _account) external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IApp {
    function anyExecute(bytes calldata _data) external returns (bool success, bytes memory result);

    function anyFallback(address _to, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}