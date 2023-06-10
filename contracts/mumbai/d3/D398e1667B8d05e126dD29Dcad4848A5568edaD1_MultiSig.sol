// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Verify.sol";

interface IERC20 {
    function transfer(address to, uint amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint);
}

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Multisig
/// @author Zartaj
/// @notice this contract serves you as a joint wallet where you and your partners can store your funds
/// safely and can only withdraw if everyone agrees on the withdrawl
/// @dev This is the base contract. Users will create wallet from the factory contract.

contract MultiSig {
    //events
    event DepositedEther(address depositor, uint256 amount, uint256 timestamp);
    event DepositedErc20(
        address depositor,
        uint256 amount,
        address TokenAddress,
        uint256 timestamp
    );
    event SubmittedErc20(
        address SubmittedBy,
        address to,
        address TokenAddress,
        uint256 amount,
        uint256 timestamp
    );
    event SubmittedEther(
        address SubmittedBy,
        address to,
        uint256 amount,
        uint256 timestamp
    );
    event Approved(
        address approvedBy,
        Transaction transaction,
        uint256 timestamp
    );
    event Executed(address to, Transaction transaction, uint256 timestamp);
    event AddedOwner(address newOwner, uint256 timestamp);
    event RemovedOwner(address wasOwner, uint256 timestamp);
    event ChangedPolicy(uint256 newPolicy, uint256 timestamp);

    //state Variables
    //uint256 i;
    VerifySignature verification;
    uint256 public requiredApproval;
    bool public paused;
    address[] owners;
    Transaction[] public transactions;
    Proposal[] public proposals;

    //mapppings
    mapping(address => bool) private isOwner;
    mapping(address => uint) private ownerIndex;
    mapping(uint256 => mapping(address => bool)) private confirmedTx;
    mapping(uint256 => mapping(address => bool)) private confirmedProposal;
    mapping(uint256 => OwnerProposal) public OwnerMap;
    mapping(uint256 => PolicyProposal) public PolicyMap;
    mapping(uint256 => PauseProposal) public PauseMap;
    mapping(uint256 => address) public TokenAddress;

    //enum
    enum Type {
        ERC20,
        Ether
    }
    enum ProposalType {
        RevokeOwner,
        AddNewOwner,
        ChangeRequired,
        pause
    }

    //structs
    struct Transaction {
        address submittedBy;
        address to;
        uint256 amount;
        uint256 txIndex;
        bool executed;
        uint256 confirmCount;
        Type _type;
    }

    struct Proposal {
        address submittedBy;
        ProposalType proposalType;
        uint256 Index;
        bool executed;
        uint256 confirmCount;
    }

    struct OwnerProposal {
        address owner;
        ProposalType proposalType;
    }

    struct PolicyProposal {
        uint256 previousSignRequirement;
        uint256 newRequiredSign;
    }

    struct PauseProposal {
        bool _pause;
    }

    //modifiers
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) {
            revert("Not owner");
        }
        // require(isOwner[msg.sender], "you are not an owner");
        _;
    }

    modifier txExist(uint256 _txIndex) {
        if (_txIndex >= transactions.length) {
            revert();
        }
        // require(_txIndex < transactions.length, "transaction doesn't exist");
        _;
    }
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "Already executed");
        _;
    }
    modifier notconfirmedTx(uint256 _txIndex) {
        require(!confirmedTx[_txIndex][msg.sender], "Already confirmedTx");
        _;
    }

    modifier isPaused() {
        require(!paused, "wallet is paused");
        _;
    }

    //constructor
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 1, "must be mmore than 1 owner");
        require(
            _owners.length >= _required && _required > 1,
            "Invalid require input"
        );
        unchecked {
            for (uint i = 0; i < _owners.length; ) {
                address owner = _owners[i];

                require(owner != address(0), "invalid address");
                require(!isOwner[owner], "Owner is already added");

                isOwner[owner] = true;
                owners.push(owner);
                ownerIndex[owner] = i;

                ++i;
            }
        }
        requiredApproval = _required;
    }

    //view functions
    function showOwners() external view returns (address[] memory) {
        return owners;
    }

    function allTxs() external view returns (Transaction[] memory) {
        return transactions;
    }

    function balanceErc20(address Erc20) public view returns (uint256) {
        return IERC20(Erc20).balanceOf(address(this));
    }

    function allProposals() external view returns (Proposal[] memory) {
        return proposals;
    }

    function balanceEther() public view returns (uint) {
        return address(this).balance;
    }

    function checkOwner(address _addr) external view returns (bool) {
        return isOwner[_addr];
    }

    //write functions

    //Submit Proposals and Transactions

    function submitERC20Tx(
        address _to,
        address ERC20,
        uint256 _amount
    ) external onlyOwner isPaused {
        uint256 balance = balanceErc20(ERC20);

        require(_amount <= balance, "Not enough balance");
        uint256 _txIndex = transactions.length;

        confirmedTx[_txIndex][msg.sender] = true;

        transactions.push(
            Transaction({
                submittedBy: msg.sender,
                to: _to,
                amount: _amount,
                txIndex: _txIndex,
                executed: false,
                confirmCount: 1,
                _type: Type.ERC20
            })
        );

        TokenAddress[_txIndex] = ERC20;

        emit SubmittedErc20(msg.sender, _to, ERC20, _amount, block.timestamp);
    }

    function submitEtherTx(
        address _to,
        uint256 _amount
    ) external onlyOwner isPaused {
        require(_amount < balanceEther(), "Not enough balance");
        uint256 _txIndex = transactions.length;

        confirmedTx[_txIndex][msg.sender] = true;

        transactions.push(
            Transaction({
                submittedBy: msg.sender,
                to: _to,
                amount: _amount,
                txIndex: _txIndex,
                executed: false,
                confirmCount: 1,
                _type: Type.Ether
            })
        );

        emit SubmittedEther(msg.sender, _to, _amount, block.timestamp);
    }

    function submitProposal(
        uint8 _proposalType,
        address _owner,
        uint256 _requiredSign,
        bool _pause
    ) external onlyOwner {
        uint256 _index = proposals.length;

        if (_proposalType == 0) {
            require(!paused, "wallet is paused");
            require(isOwner[_owner], "This address is not an owner");
            proposals.push(
                Proposal({
                    submittedBy: msg.sender,
                    proposalType: ProposalType(_proposalType),
                    Index: _index,
                    executed: false,
                    confirmCount: 1
                })
            );
            OwnerMap[_index] = OwnerProposal({
                owner: _owner,
                proposalType: ProposalType(_proposalType)
            });
            confirmedProposal[_index][msg.sender] = true;
        } else if (_proposalType == 1) {
            require(!paused, "wallet is paused");
            require(_owner != address(0), "Zero address can't be owner");
            proposals.push(
                Proposal({
                    submittedBy: msg.sender,
                    proposalType: ProposalType(_proposalType),
                    Index: _index,
                    executed: false,
                    confirmCount: 1
                })
            );
            OwnerMap[_index] = OwnerProposal({
                owner: _owner,
                proposalType: ProposalType(_proposalType)
            });
            confirmedProposal[_index][msg.sender] = true;
        } else if (_proposalType == 2) {
            require(!paused, "wallet is paused");
            require(
                _requiredSign > 1 && owners.length >= _requiredSign,
                "inavlid policy input"
            );
            proposals.push(
                Proposal({
                    submittedBy: msg.sender,
                    proposalType: ProposalType(2),
                    Index: _index,
                    executed: false,
                    confirmCount: 1
                })
            );
            PolicyMap[_index] = PolicyProposal({
                previousSignRequirement: requiredApproval,
                newRequiredSign: _requiredSign
            });
            confirmedProposal[_index][msg.sender] = true;
        } else if (_proposalType == 3) {
            proposals.push(
                Proposal({
                    submittedBy: msg.sender,
                    proposalType: ProposalType(3),
                    Index: _index,
                    executed: false,
                    confirmCount: 1
                })
            );
            PauseMap[_index] = PauseProposal({_pause: _pause});
            confirmedProposal[_index][msg.sender] = true;
        }
    }

    //APPROVE VIA SIG
    function approveTxViaSig(
        address sender,
        uint256 _txIndex,
        bytes memory sign
    ) external isPaused txExist(_txIndex) notExecuted(_txIndex) {
        require(isOwner[sender]);
        require(!confirmedTx[_txIndex][sender], "Already confirmedTx");

        string memory message = "I allowed";
        bool veri = verification.verify(sender, message, sign);
        require(veri);

        Transaction storage transaction = transactions[_txIndex];

        confirmedTx[_txIndex][sender] = true;
        unchecked {
            transaction.confirmCount += 1;
        }
        if (transaction.confirmCount == requiredApproval) {
            if (
                transaction._type == Type.ERC20 ||
                transaction._type == Type.Ether
            ) {
                executeTx(_txIndex);
            }
        }
        emit Approved(sender, transactions[_txIndex], block.timestamp);
    }

    // Approve transaction and Approve Proposals

    function approveTx(
        uint256 _txIndex
    )
        external
        onlyOwner
        isPaused
        txExist(_txIndex)
        notExecuted(_txIndex)
        notconfirmedTx(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        confirmedTx[_txIndex][msg.sender] = true;
        unchecked {
            transaction.confirmCount += 1;
        }
        if (transaction.confirmCount == requiredApproval) {
            if (
                transaction._type == Type.ERC20 ||
                transaction._type == Type.Ether
            ) {
                executeTx(_txIndex);
            }
        }
        emit Approved(msg.sender, transactions[_txIndex], block.timestamp);
    }

    function approveProposal(uint256 _index) external onlyOwner {
        require(_index < proposals.length, "invalid index");
        require(!proposals[_index].executed, "Already executed");
        require(!confirmedProposal[_index][msg.sender], "Already approved");

        if (proposals[_index].proposalType != ProposalType.pause) {
            require(!paused, "wallet is paused");

            confirmedProposal[_index][msg.sender] = true;
            // unchecked { //Using more gas
            proposals[_index].confirmCount += 1;
            // }
            if (proposals[_index].confirmCount == requiredApproval) {
                executeProposal(_index);
            }
        } else {
            confirmedProposal[_index][msg.sender] = true;
            // unchecked { //Using more gas
            proposals[_index].confirmCount += 1;
            // }
            if (proposals[_index].confirmCount == requiredApproval) {
                executeProposal(_index);
            }
        }
    }

    // Execute transaction and Execute Proposals

    function executeTx(
        uint256 _txIndex
    ) internal notExecuted(_txIndex) isPaused {
        Transaction storage transaction = transactions[_txIndex];

        if (transaction._type == Type.Ether) {
            transaction.executed = true;
            (bool result, ) = transaction.to.call{value: transaction.amount}(
                ""
            );

            require(result, " tx failed ");
        } else {
            address token = TokenAddress[_txIndex];
            transaction.executed = true;

            bool succes = IERC20(token).transfer(
                transaction.to,
                transaction.amount
            );
            require(succes, "transafer fail");
        }
        emit Executed(transaction.to, transaction, block.timestamp);
    }

    function executeProposal(uint256 _index) internal onlyOwner {
        require(!proposals[_index].executed, "Already executed");
        require(
            proposals[_index].confirmCount == requiredApproval,
            "Not approved by everyone"
        );

        ProposalType _propsalType = proposals[_index].proposalType;

        if (_propsalType == ProposalType(0)) {
            require(!paused, "wallet is paused");

            address ownerToRemove = OwnerMap[_index].owner;
            isOwner[ownerToRemove] = false;
            uint _i = ownerIndex[ownerToRemove];
            unchecked {
                for (uint i = _i; i < owners.length - 1; ) {
                    owners[i] = owners[i + 1];
                    ++i;
                }
            }
            owners.pop();

            emit RemovedOwner(ownerToRemove, block.timestamp);
        } else if (_propsalType == ProposalType(1)) {
            require(!paused, "wallet is paused");
            address ownerToAdd = OwnerMap[_index].owner;
            isOwner[ownerToAdd] = true;
            owners.push(ownerToAdd);
            emit AddedOwner(ownerToAdd, block.timestamp);
        } else if (_propsalType == ProposalType(2)) {
            require(!paused, "wallet is paused");
            uint256 policyToChange = PolicyMap[_index].newRequiredSign;
            requiredApproval = policyToChange;
            emit ChangedPolicy(policyToChange, block.timestamp);
        } else if (_propsalType == ProposalType(3)) {
            paused = PauseMap[_index]._pause;
        }
    }

    receive() external payable {
        emit DepositedEther(msg.sender, msg.value, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VerifySignature {
    function getMessageHash(
        string memory _message
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        address _signer,
        string memory _message,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        address signerRecoverd = ecrecover(_ethSignedMessageHash, v, r, s);
        return signerRecoverd;
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}