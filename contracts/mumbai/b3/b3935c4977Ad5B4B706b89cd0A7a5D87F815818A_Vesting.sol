/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Vesting is Ownable {
    struct Program {
        uint256 id;
        string name;
        uint256 start;
        uint256 end;
        uint256 availableAmount;
        uint256 tgeUnlockPercentage;
        uint256 unlockMoment;
        uint256 blockUnlockPercentage;
    }

    struct VestingInfo {
        uint256 claimedAmount;
        mapping(uint256 => uint256) atProgram;
    }

    uint256 public TGE;
    Program[] public allPrograms;
    uint256 private _block;
    mapping(address => bool) private _operators;
    mapping(address => VestingInfo) private _vestingInfoOf;

    event ProgramCreated(
        uint256 id,
        string name,
        uint256 start,
        uint256 end,
        uint256 initialAmount,
        uint256 tgeUnlockPercentage,
        uint256 unlockMoment,
        uint256 blockUnlockPercentage
    );
    event ParticipantRegistered(
        address participant,
        uint256 programId,
        uint256 amount
    );
    event TGEStarted();
    event ClaimSuccessful(address participant, uint256 amount);
    event EmergencyWithdrawn(address recipient, uint256 amount);

    constructor(uint256 block_) Ownable() {
        _block = block_;
        _operators[msg.sender] = true;
    }

    modifier onlyOperator() {
        require(_operators[msg.sender], "Caller is not operator");
        _;
    }

    function allProgramsLength() external view returns (uint256) {
        return allPrograms.length;
    }

    function getVestingAmount(address participant, uint256 programId)
        external
        view
        returns (uint256)
    {
        return _vestingInfoOf[participant].atProgram[programId];
    }

    function getClaimedAmount(address participants)
        external
        view
        returns (uint256)
    {
        return _vestingInfoOf[participants].claimedAmount;
    }

    function getClaimableAmount(address participants)
        public
        view
        returns (uint256)
    {
        uint256 totalUnlockedAmount = 0;
        for (uint256 i = 0; i < allPrograms.length; i++) {
            uint256 vestingAmount = _vestingInfoOf[participants].atProgram[i];
            if (vestingAmount > 0) {
                Program memory program = allPrograms[i];
                if (block.timestamp >= TGE)
                    totalUnlockedAmount +=
                        (vestingAmount * program.tgeUnlockPercentage) /
                        10000;
                uint256 numUnlockTimes = (block.timestamp -
                    program.unlockMoment) /
                    _block +
                    1;
                totalUnlockedAmount +=
                    (vestingAmount *
                        program.blockUnlockPercentage *
                        numUnlockTimes) /
                    10000;
            }
        }
        return totalUnlockedAmount - _vestingInfoOf[participants].claimedAmount;
    }

    function setOperators(address[] memory operators, bool[] memory isOperators)
        external
        onlyOwner
    {
        require(operators.length == isOperators.length, "Lengths mismatch");
        for (uint256 i = 0; i < operators.length; i++)
            _operators[operators[i]] = isOperators[i];
    }

    function createPrograms(
        string[] memory names,
        uint256[] memory starts,
        uint256[] memory ends,
        uint256[] memory initialAmounts,
        uint256[] memory tgeUnlockPercentages,
        uint256[] memory unlockMoments,
        uint256[] memory blockUnlockPercentages
    ) external onlyOperator {
        require(names.length == starts.length, "Lengths mismatch");
        require(names.length == ends.length, "Lengths mismatch");
        require(names.length == initialAmounts.length, "Lengths mismatch");
        require(
            names.length == tgeUnlockPercentages.length,
            "Lengths mismatch"
        );
        require(names.length == unlockMoments.length, "Lengths mismatch");
        require(
            names.length == blockUnlockPercentages.length,
            "Lengths mismatch"
        );
        for (uint256 i = 0; i < names.length; i++) {
            uint256 id = allPrograms.length;
            allPrograms.push(
                Program(
                    id,
                    names[i],
                    starts[i],
                    ends[i],
                    initialAmounts[i],
                    tgeUnlockPercentages[i],
                    unlockMoments[i],
                    blockUnlockPercentages[i]
                )
            );
            emit ProgramCreated(
                id,
                names[i],
                starts[i],
                ends[i],
                initialAmounts[i],
                tgeUnlockPercentages[i],
                unlockMoments[i],
                blockUnlockPercentages[i]
            );
        }
    }

    function registerParticipant(address participant, uint256 programId)
        external
        payable
        onlyOperator
    {
        require(participant != address(0), "Register the zero address");
        require(programId < allPrograms.length, "Program does not exist");
        Program storage program = allPrograms[programId];
        require(block.timestamp >= program.start, "Program not available");
        require(block.timestamp <= program.end, "Program is over");
        require(
            msg.value <= program.availableAmount,
            "Available amount not enough"
        );
        _vestingInfoOf[participant].atProgram[programId] += msg.value;
        program.availableAmount -= msg.value;
        emit ParticipantRegistered(participant, programId, msg.value);
    }

    function startTGE() external onlyOperator {
        require(TGE == 0, "TGE already launched");
        TGE = block.timestamp;
        emit TGEStarted();
    }

    function claimTokens() external {
        uint256 claimableAmount = getClaimableAmount(msg.sender);
        _vestingInfoOf[msg.sender].claimedAmount += claimableAmount;
        (bool success, ) = payable(msg.sender).call{value: claimableAmount}("");
        require(success, "Claim tokens failed");
        emit ClaimSuccessful(msg.sender, claimableAmount);
    }

    function emergencyWithdraw(address payable recipient) external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Emergency withdraw failed");
        emit EmergencyWithdrawn(recipient, amount);
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