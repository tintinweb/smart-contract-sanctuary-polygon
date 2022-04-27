//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0 <0.9.0;

import './security/AccessControl.sol';

contract AdminB {
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    //1 addUser, 2 removeUser, 3 required, 4 changeAdmined, 5 setSuperAdmin, 6 setAdmin
    mapping(uint256 => uint256) internal idToType;
    uint256 public required;
    uint256 public proposalCount;
    address public admined;
    address[] public owners;

    struct Proposal {
        uint256 id;
        uint256 endAt;
        uint256 num;
        address proposer;
        address addr;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], 'already owner');
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], 'not owner');
        _;
    }

    modifier notConfirmed(uint256 id, address owner) {
        require(!confirmations[id][owner], 'tx confirmed');
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), 'invalid address');
        _;
    }

    /// @dev Fallback function does not allows to deposit ether.
    fallback() external {}

    /// @dev Contract constructor sets initial owners and required number of confirmations.
    constructor() {
        address[3] memory temp = [
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
            0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
            0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
        ];
        for (uint256 i = 0; i < 3; i++) {
            isOwner[temp[i]] = true;
            owners.push(temp[i]);
        }
        required = 2;
    }

    /// @dev Returns list of owners.
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function gainConfirmationCount(uint256 proposalId) public view returns (uint256 res) {
        uint256 l = owners.length;
        for (uint256 i = 0; i < l; i++) {
            if (confirmations[proposalId][owners[i]]) {
                res += 1;
            }
        }
    }

    Proposal[] addUserProposals;
    Proposal[] removeUserProposals;
    Proposal[] requiredProposals;
    Proposal[] adminedProposals;
    Proposal[] superAdminProposals;
    Proposal[] adminProposals;

    /// @dev Allows an owner to submit and confirm an addUser Proposal.
    /// @param addr Add addr to owners.
    function submitAddUserProposal(address addr)
        external
        ownerExists(msg.sender)
        notNull(addr)
        ownerDoesNotExist(addr)
        returns (uint256 proposalId)
    {
        removeExpiredProposal(addUserProposals);
        require(doublePropose(addUserProposals, msg.sender), 'proposed');
        proposalId = proposalCount;
        idToType[proposalId] = 1;
        Proposal memory _Proposal = Proposal({
            id: proposalId,
            endAt: block.timestamp + 300,
            num: 0,
            proposer: msg.sender,
            addr: addr
        });
        proposalCount += 1;
        addUserProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in addUserProposals, and list of addr of proposals in addUserProposals
    function gainAddUserProposals() external returns (uint256[7] memory, address[7] memory) {
        removeExpiredProposal(addUserProposals);
        uint256 l = addUserProposals.length;
        uint256[7] memory resId;
        address[7] memory resAddr;
        for (uint256 i = 0; i < l; i++) {
            resId[i] = addUserProposals[i].id;
            resAddr[i] = addUserProposals[i].addr;
        }
        return (resId, resAddr);
    }

    /// @dev Allows an owner to submit and confirm a removeUser Proposal.
    /// @param addr Remove addr from owners.
    function submitRemoveUserProposal(address addr)
        external
        ownerExists(msg.sender)
        ownerExists(addr)
        returns (uint256 proposalId)
    {
        removeExpiredProposal(removeUserProposals);
        require(doublePropose(removeUserProposals, msg.sender), 'proposed');
        proposalId = proposalCount;
        idToType[proposalId] = 2;
        Proposal memory _Proposal = Proposal({
            id: proposalId,
            endAt: block.timestamp + 300,
            num: 0,
            proposer: msg.sender,
            addr: addr
        });
        proposalCount += 1;
        removeUserProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in removeUserProposals, and list of addr of proposals in removeUserProposals
    function gainRemoveUserProposals() external returns (uint256[7] memory, address[7] memory) {
        removeExpiredProposal(removeUserProposals);
        uint256 l = removeUserProposals.length;
        uint256[7] memory resId;
        address[7] memory resAddr;
        for (uint256 i = 0; i < l; i++) {
            resId[i] = removeUserProposals[i].id;
            resAddr[i] = removeUserProposals[i].addr;
        }
        return (resId, resAddr);
    }

    /// @dev Allows an owner to submit and confirm a set required Proposal.
    /// @param num Proposed required value.
    function submitRequiredProposal(uint256 num) external ownerExists(msg.sender) returns (uint256 proposalId) {
        removeExpiredProposal(requiredProposals);
        require(doublePropose(requiredProposals, msg.sender), 'proposed');
        proposalId = proposalCount;
        idToType[proposalId] = 3;
        Proposal memory _Proposal = Proposal({
            id: proposalId,
            endAt: block.timestamp + 300,
            num: num,
            proposer: msg.sender,
            addr: address(0)
        });
        proposalCount += 1;
        requiredProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in requiredProposals, and list of num of proposals in requiredProposals
    function gainRequiredProposals() external returns (uint256[7] memory, uint256[7] memory) {
        removeExpiredProposal(requiredProposals);
        uint256 l = requiredProposals.length;
        uint256[7] memory resId;
        uint256[7] memory resNum;
        for (uint256 i = 0; i < l; i++) {
            resId[i] = requiredProposals[i].id;
            resNum[i] = requiredProposals[i].num;
        }
        return (resId, resNum);
    }

    /// @dev Allows an owner to submit and confirm a set admined Proposal.
    /// @param addr Proposed new admined address.
    function submitAdminedProposal(address addr)
        external
        ownerExists(msg.sender)
        notNull(addr)
        returns (uint256 proposalId)
    {
        removeExpiredProposal(adminedProposals);
        require(doublePropose(adminedProposals, msg.sender), 'proposed');
        proposalId = proposalCount;
        idToType[proposalId] = 4;
        Proposal memory _Proposal = Proposal({
            id: proposalId,
            endAt: block.timestamp + 300,
            num: 0,
            proposer: msg.sender,
            addr: addr
        });
        proposalCount += 1;
        adminedProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in adminedProposals, and list of addr of proposals in adminedProposals
    function gainAdminedProposals() external returns (uint256[7] memory, address[7] memory) {
        removeExpiredProposal(adminedProposals);
        uint256 l = adminedProposals.length;
        uint256[7] memory resId;
        address[7] memory resAddr;
        for (uint256 i = 0; i < l; i++) {
            resId[i] = adminedProposals[i].id;
            resAddr[i] = adminedProposals[i].addr;
        }
        return (resId, resAddr);
    }

    /// @dev Allows an owner to submit and confirm a superAdmin Proposal.
    /// @param addr Set addr as superAdmin of admined contract.
    function submitSuperAdminProposal(address addr)
        external
        ownerExists(msg.sender)
        notNull(addr)
        returns (uint256 proposalId)
    {
        removeExpiredProposal(superAdminProposals);
        require(doublePropose(superAdminProposals, msg.sender), 'proposed');
        proposalId = proposalCount;
        idToType[proposalId] = 5;
        Proposal memory _Proposal = Proposal({
            id: proposalId,
            endAt: block.timestamp + 300,
            num: 0,
            proposer: msg.sender,
            addr: addr
        });
        proposalCount += 1;
        superAdminProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in superAdminProposals, and list of addr of proposals in superAdminProposals
    function gainSuperAdminProposals() external returns (uint256[7] memory, address[7] memory) {
        removeExpiredProposal(superAdminProposals);
        uint256 l = superAdminProposals.length;
        uint256[7] memory resId;
        address[7] memory resAddr;
        for (uint256 i = 0; i < l; i++) {
            resId[i] = superAdminProposals[i].id;
            resAddr[i] = superAdminProposals[i].addr;
        }
        return (resId, resAddr);
    }

    /// @dev Allows an owner to submit and confirm a admin Proposal.
    /// @param addr Set addr as admin of admined contract.
    function submitAdminProposal(address addr)
        external
        ownerExists(msg.sender)
        notNull(addr)
        returns (uint256 proposalId)
    {
        removeExpiredProposal(adminProposals);
        require(doublePropose(adminProposals, msg.sender), 'proposed');
        proposalId = proposalCount;
        idToType[proposalId] = 6;
        Proposal memory _Proposal = Proposal({
            id: proposalId,
            endAt: block.timestamp + 300,
            num: 0,
            proposer: msg.sender,
            addr: addr
        });
        proposalCount += 1;
        adminProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in adminProposals, and list of addr of proposals in adminProposals
    function gainAdminProposals() external returns (uint256[7] memory, address[7] memory) {
        removeExpiredProposal(adminProposals);
        uint256 l = adminProposals.length;
        uint256[7] memory resId;
        address[7] memory resAddr;
        for (uint256 i = 0; i < l; i++) {
            resId[i] = adminProposals[i].id;
            resAddr[i] = adminProposals[i].addr;
        }
        return (resId, resAddr);
    }

    /// @dev Allows an owner to confirm a proposal.
    function confirmProposal(uint256 proposalId) public ownerExists(msg.sender) notConfirmed(proposalId, msg.sender) {
        require(proposalId < proposalCount, 'proposal not exists');
        confirmations[proposalId][msg.sender] = true;
        if (gainConfirmationCount(proposalId) >= required) {
            executeProposal(proposalId);
        }
    }

    /// @dev Execute a confirmed proposal.
    function executeProposal(uint256 proposalId) internal {
        uint256 i;
        uint256 l;
        if (idToType[proposalId] == 1) {
            (i, l) = findIndex(proposalId, addUserProposals);
            address addr = addUserProposals[i].addr;
            require(!isOwner[addr], 'already owner');
            isOwner[addr] = true;
            owners.push(addr);
            addUserProposals[i] = addUserProposals[l - 1];
            addUserProposals.pop();
        } else if (idToType[proposalId] == 2) {
            (i, l) = findIndex(proposalId, removeUserProposals);
            address addr = removeUserProposals[i].addr;
            require(required < owners.length, 'number of owner<required');
            require(isOwner[addr], 'not owner');
            removeUserProposals[i] = removeUserProposals[l - 1];
            removeUserProposals.pop();
            isOwner[addr] = false;
            l = owners.length;
            i = 0;
            while (i < l) {
                if (owners[i] == addr) {
                    break;
                }
                i += 1;
            }
            owners[i] = owners[l - 1];
            owners.pop();
        } else if (idToType[proposalId] == 3) {
            (i, l) = findIndex(proposalId, requiredProposals);
            required = requiredProposals[i].num;
            require(required <= owners.length, 'number of owner<required');
            requiredProposals[i] = requiredProposals[l - 1];
            requiredProposals.pop();
        } else if (idToType[proposalId] == 4) {
            (i, l) = findIndex(proposalId, adminedProposals);
            admined = adminedProposals[i].addr;
            adminedProposals[i] = adminedProposals[l - 1];
            adminedProposals.pop();
        } else if (idToType[proposalId] == 5) {
            (i, l) = findIndex(proposalId, superAdminProposals);
            AccessControl sc = AccessControl(admined);
            sc.changeSuperAdmin(payable(superAdminProposals[i].addr));
            superAdminProposals[i] = superAdminProposals[l - 1];
            superAdminProposals.pop();
        } else if (idToType[proposalId] == 6) {
            (i, l) = findIndex(proposalId, adminProposals);
            AccessControl sc = AccessControl(admined);
            sc.changeAdmin(payable(adminProposals[i].addr));
            adminProposals[i] = adminProposals[l - 1];
            adminProposals.pop();
        } else {
            require(false, 'can not execute proposal');
        }
    }

    /// @dev Find index of proposalId in array.
    function findIndex(uint256 proposalId, Proposal[] memory array) internal pure returns (uint256 i, uint256 l) {
        l = array.length;
        Proposal memory _Proposal;
        while (i < l) {
            _Proposal = array[i];
            if (_Proposal.id == proposalId) {
                break;
            }
            i++;
        }
        require(i < l, 'propose not found');
    }

    /// @dev Remove expired proposal in array.
    function removeExpiredProposal(Proposal[] storage array) internal {
        uint256 l = array.length;
        uint256 t = block.timestamp;
        for (uint256 i = 0; i < l; ) {
            if (array[i].endAt <= t) {
                array[i] = array[l - 1];
                array.pop();
                l -= 1;
            } else {
                i += 1;
            }
        }
    }

    /// @dev //Whether sender's previous proposal in array.
    function doublePropose(Proposal[] memory array, address sender) internal pure returns (bool) {
        uint256 l = array.length;
        for (uint256 i = 0; i < l; i++) {
            if (array[i].proposer == sender) {
                return false;
            }
        }
        return true;
    }
}

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl {
    /// @dev Error message.
    string constant NO_PERMISSION = "no permission";
    string constant INVALID_ADDRESS = "invalid address";

    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable public superAdmin;

    /// @dev Administrator of this contract.
    address payable public admin;

    /// @dev This event is fired after modifying superAdmin.
    event superAdminChanged(
        address indexed _from,
        address indexed _to,
        uint256 _time
    );

    /// @dev This event is fired after modifying admin.
    event adminChanged(
        address indexed _from,
        address indexed _to,
        uint256 _time
    );

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor() {
        superAdmin = payable(msg.sender);
        admin = payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin() {
        require(msg.sender == admin, NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin {
        require(addr != payable(address(0)), INVALID_ADDRESS);
        emit superAdminChanged(superAdmin, addr, block.timestamp);
        superAdmin = addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin {
        require(addr != payable(address(0)), INVALID_ADDRESS);
        emit adminChanged(admin, addr, block.timestamp);
        admin = addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin {
        superAdmin.transfer(amount);
    }

    fallback() external {}
}