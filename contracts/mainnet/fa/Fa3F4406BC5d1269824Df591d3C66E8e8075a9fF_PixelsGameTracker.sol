// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract PixelsGameTracker {
    /**
     * Event emitted when user sign-in
     */
    event DailyLogDone(address userAddress, uint256 blockTimestamp, string uid);

    /*
     * Mapping for tracking last day when user sign-in
     */
    mapping(address => uint256) public _userDays;

    /*
     * Mapping for tracking uuid of the user
     */
    mapping(string => address) public _userUid;

    constructor() {}

    /*
     * @dev sign in
     */
    function dailyLog(string calldata uid) external {
        address userAddress = msg.sender;
        _userDays[userAddress] = block.timestamp / 60 / 60 / 24;
        _userUid[uid] = userAddress;

        emit DailyLogDone(userAddress, block.timestamp, uid);
    }

    /*
     * @dev Check if user sign in today
     */
    function hasSignInToday(address userAddress) public view returns (bool) {
        uint256 d = _userDays[userAddress];
        if (d == block.timestamp / 60 / 60 / 24) {
            return true;
        }
        return false;
    }
}