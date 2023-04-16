/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
    event EscrowExpired(
        uint256 indexed escrowId,
        address indexed creator,
        address indexed admin
    );

    modifier onlyAdmin(uint256 _escrowId) {
        require(
            escrows[_escrowId].admin == msg.sender,
            "Only admin can perform this action"
        );
        _;
    }

    modifier onlyCreator(uint256 _escrowId) {
        require(
            escrows[_escrowId].creator == msg.sender,
            "Only creator can perform this action"
        );
        _;
    }

    modifier onlyAdminOrCreator(uint256 _escrowId) {
        require(
            escrows[_escrowId].admin == msg.sender ||
                escrows[_escrowId].creator == msg.sender,
            "Only admin or creator can perform this action"
        );
        _;
    }

    modifier notReleased(uint256 _escrowId) {
        require(!escrows[_escrowId].released, "Escrow is already released");
        _;
    }

    modifier notCancelled(uint256 _escrowId) {
        require(!escrows[_escrowId].cancelled, "Escrow is already cancelled");
        _;
    }

    modifier notExpired(uint256 _escrowId) {
        require(!escrows[_escrowId].expired, "Escrow is already expired");
        _;
    }

    function getEscrows(
        uint256[] memory escrowIds
    ) private view returns (EscrowData[] memory) {
        EscrowData[] memory result = new EscrowData[](escrowIds.length);
        for (uint256 i = 0; i < escrowIds.length; i++) {
            EscrowData storage escrow = escrows[escrowIds[i]];
            result[i] = escrow;
        }
        return result;
    }

    function createEscrow(
        address _creator,
        uint256 _timestamp,
        string memory _collabUrl,
        string memory _creatorUsername,
        string memory _adminUsername
    ) external payable returns (uint256) {
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

    function getAdminEscrows() external view returns (EscrowData[] memory) {
        return getEscrows(adminEscrows[msg.sender]);
    }

    function getCreatorEscrows() external view returns (EscrowData[] memory) {
        return getEscrows(creatorEscrows[msg.sender]);
    }

    function releaseEscrow(
        uint256 _escrowId
    )
        external
        onlyAdmin(_escrowId)
        notReleased(_escrowId)
        notCancelled(_escrowId)
        notExpired(_escrowId)
    {
        EscrowData storage escrow = escrows[_escrowId];
        escrow.released = true;

        (bool success, ) = escrow.creator.call{value: escrow.amount}("");
        require(success, "Transfer failed");

        emit EscrowReleased(_escrowId, escrow.creator, escrow.admin);
    }

    function cancelEscrow(
        uint256 _escrowId
    )
        external
        onlyCreator(_escrowId)
        notReleased(_escrowId)
        notCancelled(_escrowId)
        notExpired(_escrowId)
    {
        EscrowData storage escrow = escrows[_escrowId];
        escrow.cancelled = true;

        (bool success, ) = escrow.admin.call{value: escrow.amount}("");
        require(success, "Transfer failed");

        emit EscrowCancelled(_escrowId, escrow.creator, escrow.admin);
    }

    function expireEscrow(
        uint256 _escrowId
    )
        external
        onlyAdminOrCreator(_escrowId)
        notReleased(_escrowId)
        notCancelled(_escrowId)
        notExpired(_escrowId)
    {
        EscrowData storage escrow = escrows[_escrowId];
        require(block.timestamp >= escrow.timestamp, "Escrow has not expired");

        escrow.expired = true;
        emit EscrowExpired(_escrowId, escrow.creator, escrow.admin);
    }
}