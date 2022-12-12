// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.9;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {
    struct Member {
        string name;
        string regNo;
        uint256 point;
        bool activated;
        bool coordinator;
        address walletAddress;
    }
    mapping(address => string) regNoOf;
    Member[] members;
    mapping(address => uint256) Id;
    mapping(address => bool) isAdmin;
    mapping(address => bool) isRegistered;
    address[] registeredAddresses;

    uint256 length;

    constructor() {
        isAdmin[msg.sender] = true;
        length = 0;
    }

    function returnData() public view returns (Member[] memory) {
        //    Member[] calldata datas = members;
        return members;
    }

    function AdminStatus() public view returns (bool stat) {
        return isAdmin[msg.sender];
    }

    function makeAdmin(address walletAddress) public payable {
        require(isAdmin[msg.sender], "Non admin  access denied");
        isAdmin[walletAddress] = true;
    }

    function revokeAdmin(address walletAddress) public payable {
        require(isAdmin[msg.sender], "Non admin access revoked");
        isAdmin[walletAddress] = false;
    }

    function registerStatus() public view returns (bool) {
        return isRegistered[msg.sender];
    }

    function editRegNo(string memory newRegNo, address walletAddress)
        public
        payable
    {
        members[Id[walletAddress]].regNo = newRegNo;
    }

    function addMember(string memory name, string memory regNo) public payable {
        require(!isRegistered[msg.sender], "User already registered");
        isRegistered[msg.sender] = true;
        Id[msg.sender] = length;
        length += 1;
        registeredAddresses.push(msg.sender);
        members.push(Member(name, regNo, 0, true, false, msg.sender));

        regNoOf[msg.sender] = regNo;
    }

    function terminateUser(address walletAddress) public payable {
        require(isAdmin[msg.sender], "Non-admin access denied");
        members[Id[walletAddress]].activated = false;
    }

    function setCoordinator(address walletAddress) public payable {
        require(isAdmin[msg.sender], "Non admin access denied");
        members[Id[walletAddress]].coordinator = true;
    }

    function revertCoordinator(address walletAddress) public payable {
        require(isAdmin[msg.sender], "Non admin access denied");
        members[Id[walletAddress]].coordinator = false;
    }

    function deleteUser(address walletAddress) public payable {
        require(isAdmin[msg.sender], "Non-admin access denied");
        require(isRegistered[walletAddress], "Registered users only");
        members[Id[walletAddress]].activated = false;
        isRegistered[walletAddress] = false;

        regNoOf[walletAddress] = "";
    }

    function getMemberDetails(string memory regNo)
        public
        view
        returns (Member memory data)
    {
        for (uint256 i = 0; i < members.length; i++) {
            if (
                keccak256(abi.encodePacked(members[i].regNo)) ==
                keccak256(abi.encodePacked(regNo))
            ) {
                return members[i];
            }
        }
    }

    function addPoints(address walletAddress, uint256 addVal) public payable {
        require(isAdmin[msg.sender], "Non-admin access denied");
        members[Id[walletAddress]].point += addVal;
    }

    function minusPoints(address walletAddress, uint256 minVal) public payable {
        require(isAdmin[msg.sender], "Non-admin access denied");
        members[Id[walletAddress]].point -= minVal;
    }
}