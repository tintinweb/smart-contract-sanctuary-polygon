// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./ERC20.sol";
import "./IERC20.sol";
import "./ILockForever.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract LockForever is ERC20, Ownable, ILockForever {
    using SafeMath for uint256;

    bool public isPaused;
    address public tokenToLock;

    uint256 public locksCount;
    uint256 public currentLockBalance;

    uint256[] internal allLockRecordIds;
    mapping(address => uint256[]) internal lockRecordIds;
    mapping(uint256 => LockRecord) internal lockRecordsMapping;
    mapping(address => uint256) internal lockBalance;

    struct LockRecord {
        uint256 recordId;
        address lockerAddress;
        uint256 lockAmount;
        uint256 lockTime;
    }

    constructor(
        address _tokenToLock,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_, decimals_) {
        require(_tokenToLock != address(0));
        tokenToLock = _tokenToLock;
    }

    function pause() external onlyOwner {
        isPaused = true;
    }

    function resume() external onlyOwner {
        isPaused = false;
    }

    function lock(address account, uint256 amount) public returns (bool) {
        require(!isPaused, "Lock Forever: locking has been paused");
        require(amount > 0, "Lock Forever: amount cannot be 0");

        // Save user lock information
        locksCount = locksCount.add(1);
        LockRecord memory lockRecord = LockRecord({
            recordId: locksCount,
            lockerAddress: account,
            lockAmount: amount,
            lockTime: block.timestamp
        });

        // Update fields values
        allLockRecordIds.push(locksCount);
        lockRecordIds[account].push(locksCount);
        lockRecordsMapping[locksCount] = lockRecord;
        lockBalance[account] = lockBalance[account].add(amount);
        currentLockBalance = currentLockBalance.add(amount);

        _mint(account, amount);
        bool result = IERC20(tokenToLock).transferFrom(
            _msgSender(),
            address(this),
            amount
        );

        require(result, "Lock Forever: Token transfer failed");

        emit TokensLocked(tokenToLock, account, amount);
        return true;
    }

    function getAllLockRecordsLength() public view returns (uint256) {
        return allLockRecordIds.length;
    }

    function getWalletLockRecordsLength(address account)
        public
        view
        returns (uint256)
    {
        uint256 lockRecordsLength = lockRecordIds[account].length;
        return lockRecordsLength;
    }

    function getWalletLockRecords(address account)
        public
        view
        returns (LockRecord[] memory)
    {
        uint256 lockRecordsLength = lockRecordIds[account].length;
        LockRecord[] memory result = new LockRecord[](lockRecordsLength);
        for (uint256 i = 0; i < lockRecordsLength; i++) {
            result[i] = lockRecordsMapping[lockRecordIds[account][i]];
        }
        return result;
    }

    function getTokenToLock() public view returns (address) {
        return tokenToLock;
    }
}