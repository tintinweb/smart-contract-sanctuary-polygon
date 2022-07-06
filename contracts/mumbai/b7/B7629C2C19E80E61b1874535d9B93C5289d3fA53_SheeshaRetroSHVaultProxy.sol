//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ISheeshaRetroSHVault, ISheeshaVaultInfo} from "../utils/Interfaces.sol";

contract SheeshaRetroSHVaultProxy is ISheeshaVaultInfo, Ownable {
    address public retroVault;
    uint256 public override staked;

    event SetVault(address, address);
    event SetStaked(address, uint256);

    constructor(address retroVault_, uint256 staked_) {
        retroVault = retroVault_;
        staked = staked_;
    }

    function token() external view override returns (address token_) {
        (token_, , , ) = ISheeshaRetroSHVault(retroVault).poolInfo(0);
    }

    function stakedOf(address member)
        external
        view
        override
        returns (uint256 stakeOf_)
    {
        (stakeOf_, ) = ISheeshaRetroSHVault(retroVault).userInfo(0, member);
    }

    function setVault(address retroVault_) external onlyOwner {
        retroVault = retroVault_;
        emit SetVault(_msgSender(), retroVault_);
    }

    function setStaked(uint256 staked_) external onlyOwner {
        staked = staked_;
        emit SetStaked(_msgSender(), staked_);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaDao {
    function votes() external view returns (address);

    function activeVoting() external view returns (address);

    function latestVoting() external view returns (address);

    function delegates(address who, address whom) external view returns (bool);

    function setVotes(address) external;

    function setVaults(bytes calldata data) external;

    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external;

    event SetVotes(address who, address votes);
    event Executed(address who, address target, uint256 value, bytes data);
}

interface ISheeshaDaoInitializable {
    function initialize(address dao, bytes calldata data) external;
}

interface ISheeshaRetroLPVault {
    function poolInfo(uint256 id)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function userInfo(uint256 id, address user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        );

    function userCount() external view returns (uint256);

    function userList(uint256) external view returns (address);
}

interface ISheeshaRetroSHVault {
    function poolInfo(uint256 id)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function userInfo(uint256 id, address user)
        external
        view
        returns (uint256, uint256);

    function userCount() external view returns (uint256);

    function userList(uint256) external view returns (address);
}

interface ISheeshaVaultInfo {
    function token() external view returns (address);

    function staked() external view returns (uint256);

    function stakedOf(address member) external view returns (uint256);
}

interface ISheeshaVault is ISheeshaVaultInfo {
    function pendingSheesha(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function depositFor(
        address _depositFor,
        uint256 _pid,
        uint256 _amount
    ) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;
}

interface ISheeshaVesting {
    /**
     * @dev Calculates available amount of tokens to withdraw for vesting types
     * which participate in staking for FE.
     * @return _leftover Recipient amount which wasn't withdrawn.
     * @return _amountAvailable Recipient available amount to withdraw.
     */
    function calculateAvailableAmountForStaking(address _recipient)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Emitted when withdraw of tokens was made on staking contract.
     * @param _recipient Address of user for which withdraw from staking.
     * @param _amount The amount of tokens which was withdrawn.
     */
    function withdrawFromStaking(address _recipient, uint256 _amount) external;
}

interface ISheeshaVotesLocker {
    function total() external view returns (uint256);

    function locked() external view returns (uint256);

    function unlocked() external view returns (uint256);

    function totalOf(address member) external view returns (uint256);

    function lockedOf(address member) external view returns (uint256);

    function unlockedOf(address member) external view returns (uint256);

    function unlockedSHOf(address member) external view returns (uint256);

    function unlockedLPOf(address member) external view returns (uint256);
}

interface ISheeshaVotes is ISheeshaDaoInitializable, ISheeshaVotesLocker {
    function dao() external view returns (address);

    function SHVault() external view returns (address);

    function LPVault() external view returns (address);

    function SHToken() external view returns (address);

    function LPToken() external view returns (address);

    function prices() external view returns (uint256 shPrice, uint256 lpPrice);

    function setVaults(bytes calldata data_) external;

    event SetVaults(address, address);
}

interface ISheeshaVoting is ISheeshaDaoInitializable {
    enum State {
        STATE_INACTIVE,
        STATE_ACTIVE,
        STATE_COMPLETED_NO_QUORUM,
        STATE_COMPLETED_NO_WINNER,
        STATE_COMPLETED,
        STATE_COMPLETED_EXECUTED
    }

    function dao() external view returns (address);

    function begin() external view returns (uint32);

    function end() external view returns (uint32);

    function quorum() external view returns (uint8);

    function threshold() external view returns (uint8);

    function votesOf(address member) external view returns (uint256);

    function votesOfFor(address member, uint256 candidate)
        external
        view
        returns (uint256);

    function votesFor(uint256) external view returns (uint256);

    function votesForNum() external view returns (uint256);

    function votes() external view returns (uint256);

    function hasQuorum() external view returns (bool);

    function state() external view returns (State);

    function winners() external view returns (uint256);

    function executed() external view returns (bool);

    function vote(bytes calldata data) external;

    function verify(address[] calldata members)
        external
        view
        returns (address[] memory);

    function cancel(address[] calldata members) external;

    function execute() external;
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