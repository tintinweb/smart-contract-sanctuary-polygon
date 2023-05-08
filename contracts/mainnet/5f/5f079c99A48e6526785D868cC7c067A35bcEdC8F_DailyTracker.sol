// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract DailyTracker {
    /*
     * Mapping for tracking last timestamp when transaction for check-in was done

     */
    mapping(address => uint256) public _dailyTrackerTsDays;
    /*
     * Mapping for tracking unique UUID of the user from server.
     */
    mapping(string => address) public _dailyUserUuid;

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Greeting {
        string uuid;
    }

    bytes32 DOMAIN_SEPARATOR;

    constructor() {
        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: "DailyTracker",
                version: "1",
                chainId: block.chainid,
                verifyingContract: address(this)
            })
        );
    }

    function hash(
        EIP712Domain memory eip712Domain
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function hash(Greeting memory greeting) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("Greeting(string uuid)"),
                    keccak256(bytes(greeting.uuid))
                )
            );
    }

    function verify(
        Greeting memory greeting,
        address sender,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(greeting))
        );
        return ecrecover(digest, v, r, s) == sender;
    }

    /*
     * @dev Function to get current block's Ts in # of days
     */
    function currentDaysTimestamp() internal view returns (uint256) {
        return block.timestamp / 60 / 60 / 24;
    }

    function greet(
        Greeting memory greeting,
        address sender,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(verify(greeting, sender, v, r, s), "Invalid signature");
        _dailyUserUuid[greeting.uuid] = sender;
        _dailyTrackerTsDays[sender] = currentDaysTimestamp();
    }

    /*
     * @dev Check if user has been logged today
     */
    function hasLoggedToday(address userAddress) public view returns (bool) {
        uint256 lastTsDays = _dailyTrackerTsDays[userAddress];

        if (lastTsDays == 0 || lastTsDays < currentDaysTimestamp()) {
            return true;
        }
        return false;
    }
}