/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    struct EscrowData {
        uint256 escrowId;
        uint256 timestamp;
        uint256 amount;
        address creator;
        address admin;
        bool released;
        bool cancelled;
        bool expired;
        string collabUrl;
        string creatorUsername;
        string adminUsername;
    }

    EscrowData[] public escrows;
    mapping(address => uint256[]) public adminEscrows;
    mapping(address => uint256[]) public creatorEscrows;

    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed creator,
        address indexed admin,
        uint256 amount,
        uint256 expiry,
        string collabUrl,
        string creatorUsername,
        string adminUsername
    );
    event EscrowReleased(
        uint256 indexed escrowId,
        address indexed creator,
        address indexed admin
    );
    event EscrowCancelled(
        uint256 indexed escrowId,
        address indexed creator,
        address indexed admin
    );

    event EscrowExpired(uint256 indexed escrowId, address indexed creator, address indexed admin);


    function createEscrow(
        address _creator,
        uint256 _timestamp,
        string memory _collabUrl,
        string memory _creatorUsername,
        string memory _adminUsername
    ) public payable returns (uint256) {
        require(msg.sender != _creator, "Cannot create escrow with yourself");
        require(msg.value > 0, "Cannot create escrow with 0 ETH");

        uint256 escrowId = escrows.length;

        escrows.push(
            EscrowData({
                escrowId: escrowId,
                timestamp: _timestamp,
                amount: msg.value,
                creator: _creator,
                admin: msg.sender,
                released: false,
                cancelled: false,
                expired: false,
                collabUrl: _collabUrl,
                creatorUsername: _creatorUsername,
                adminUsername: _adminUsername
            })
        );

        adminEscrows[msg.sender].push(escrowId);
        creatorEscrows[_creator].push(escrowId);

        emit EscrowCreated(
            escrowId,
            _creator,
            msg.sender,
            msg.value,
            _timestamp,
            _collabUrl,
            _creatorUsername,
            _adminUsername
        );

        return escrowId;
    }

    function getSellerEscrows() public view returns (EscrowData[] memory) {
        uint256[] memory escrowIds = adminEscrows[msg.sender];
        EscrowData[] memory result = new EscrowData[](escrowIds.length);
        for (uint256 i = 0; i < escrowIds.length; i++) {
            EscrowData storage escrow = escrows[escrowIds[i]];
            result[i] = escrow;
        }
        return result;
    }

    function getBuyerEscrows() public view returns (EscrowData[] memory) {
        uint256[] memory escrowIds = creatorEscrows[msg.sender];
        EscrowData[] memory result = new EscrowData[](escrowIds.length);
        for (uint256 i = 0; i < escrowIds.length; i++) {
            EscrowData storage escrow = escrows[escrowIds[i]];
            result[i] = escrow;
        }
        return result;
    }

    function releaseEscrow(uint256 _escrowId) public {
        EscrowData storage escrow = escrows[_escrowId];
        require(escrow.admin == msg.sender, "Only admin can release escrow");
        require(!escrow.released, "Escrow is already released");
        require(!escrow.cancelled, "Escrow is cancelled");

        escrow.released = true;
        payable(escrow.creator).transfer(escrow.amount);
        emit EscrowReleased(_escrowId, escrow.creator, escrow.admin);
    }

    function cancelEscrow(uint256 _escrowId) public {
        EscrowData storage escrow = escrows[_escrowId];
        require(
            escrow.creator == msg.sender || escrow.admin == msg.sender,
            "Only admin or creator can cancel escrow"
        );
        require(!escrow.released, "Escrow is already released");
        require(!escrow.cancelled, "Escrow is already cancelled");

        escrow.cancelled = true;
        payable(escrow.admin).transfer(escrow.amount);
        emit EscrowCancelled(_escrowId, escrow.creator, escrow.admin);
    }

    function checkAndRefundExpiredEscrow(uint256 _escrowId) public {
        EscrowData storage escrow = escrows[_escrowId];
        require(!escrow.released, "Escrow is already released");
        require(!escrow.cancelled, "Escrow is already cancelled");
        require(!escrow.expired, "Escrow is already expired");
        require(
            block.timestamp > escrow.timestamp,
            "Escrow has not expired yet"
        );

        escrow.expired = true;
        payable(escrow.admin).transfer(escrow.amount);
        emit EscrowExpired(_escrowId, escrow.creator, escrow.admin);

    }
}