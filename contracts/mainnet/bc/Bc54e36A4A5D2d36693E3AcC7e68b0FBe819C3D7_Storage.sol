pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: BSU-1.1

contract Storage {
    address public admin;
    address public pendingAdmin;

    constructor() {
        admin = msg.sender;
    }

    modifier adminOnly() {
        require(msg.sender == admin, "admin only");
        _;
    }

    /*********************/
    /****    Admin   *****/
    /*********************/

    /**
     * Request a new admin to be set for the contract.
     *
     * @param newAdmin New admin address
     */
    function setPendingAdmin(address newAdmin) public adminOnly {
        pendingAdmin = newAdmin;
    }

    /**
     * Accept admin transfer from the current admin to the new.
     */
    function acceptPendingAdmin() public {
        require(
            msg.sender == pendingAdmin && pendingAdmin != address(0),
            "Caller must be the pending admin"
        );

        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    /*********************/
    /***    Storage   ****/
    /*********************/

    mapping(bytes32 => address) public addressStorage;
    mapping(bytes32 => uint8) public currentVersion;
    mapping(bytes32 => uint256) public fees;

    /******** Contract Address Storage *******/
    function getContractAdd(string calldata name, uint8 version)
        external
        view
        returns (address)
    {
        bytes32 _name = stringToBytes32(name);
        bytes32 key = keccak256(abi.encode(_name, version));
        return addressStorage[key];
    }

    function getCurrentVersion(string calldata name)
        external
        view
        returns (uint8)
    {
        bytes32 _name = stringToBytes32(name);
        return currentVersion[_name];
    }

    function updateContractVersion(
        string calldata name,
        uint8 version,
        address value
    ) external adminOnly {
        bytes32 _name = stringToBytes32(name);
        require(
            version == currentVersion[_name] + 1,
            "Version not incremental"
        );
        bytes32 key = keccak256(abi.encode(_name, version));
        addressStorage[key] = value;
        currentVersion[_name] = version;
    }

    /******** DataX Fees Storage *******/
    function getFees(string calldata key) external view returns (uint256) {
        bytes32 _key = stringToBytes32(key);
        return fees[_key];
    }

    function updateFees(string calldata key, uint256 value) external adminOnly {
        bytes32 _key = stringToBytes32(key);
        fees[_key] = value;
    }

    /*********************/
    /*****    Utils   ****/
    /*********************/

    function stringToBytes32(string memory source)
        internal
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}