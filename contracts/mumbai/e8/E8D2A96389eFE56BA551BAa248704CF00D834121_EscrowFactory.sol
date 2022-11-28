// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

error Escrow__NotPayer();
error Escrow__NotAdmin();
error Escrow__NotArbitrator();

contract Escrow {
    event ContractActivated();
    event ContractSettled();
    event DisputeRaised();
    event DisputeResolved();

    uint256 public contractActivatedTime;
    uint256 public timeToRaiseDispute;
    address public payer;
    address public payee;
    address public admin = 0xD63Ef08a38EfF4416d7EBf9895B69A525AE593F7;
    address public arbitrator;
    uint256 public amountPayable;
    uint256 public amountInEscrow;
    uint256 public platformFee;
    bool public activatedByPayee = false;
    bool public activatedByPayer = false;
    bool public contractActivated = false;
    bool public disputeRaised = false;
    bool public contractSettled = false;
    string public contentHash = "";

    modifier onlyPayer() {
        if (msg.sender != payer) revert Escrow__NotPayer();
        _;
    }
    modifier onlyAdmin() {
        if (msg.sender != admin) revert Escrow__NotAdmin();
        _;
    }
    modifier onlyArbitrator() {
        if (msg.sender != arbitrator) revert Escrow__NotArbitrator();
        _;
    }

    function initialize(
        address _payer,
        address _payee,
        address _arbitrator,
        uint256 _amountPayable,
        uint256 _platformFee,
        uint256 _timeToRaiseDispute,
        string memory _contentHash
    ) public {
        payee = _payee;
        payer = _payer;
        arbitrator = _arbitrator;
        amountPayable = _amountPayable;
        platformFee = _platformFee;
        timeToRaiseDispute = _timeToRaiseDispute;
        contentHash = _contentHash;
    }

    function paymentByPayer() public payable onlyPayer {
        //check if amount paid is not less than amount payable
        require(
            msg.value >= (amountPayable + platformFee) && !contractActivated
        );

        uint256 amountPaid = msg.value;
        uint256 amountPayableByPayer = amountPayable + platformFee;
        amountInEscrow = amountPayableByPayer;

        //if paid extra, return that amount
        if (amountPayableByPayer != amountPaid) {
            uint256 amountToReturn = amountPaid - amountPayableByPayer;
            // payable(msg.sender).transfer(amountToReturn);

            (bool sent, ) = payable(msg.sender).call{value: amountToReturn}("");
            require(sent);
        }
        activatedByPayer = true;

        //if contract is activated by both, start the timer and activate the contract
        if (activatedByPayee == true) {
            contractActivatedTime = block.timestamp;
            contractActivated = true;
            emit ContractActivated();
        }
    }

    function activateContractByPayee() public {
        // Check if payer has sent money
        require(amountInEscrow == platformFee + amountPayable);

        activatedByPayee = true;

        //if contract is activated by both, start the timer and activate the contract
        if (activatedByPayer == true) {
            contractActivatedTime = block.timestamp;
            contractActivated = true;
            emit ContractActivated();
        }
    }

    //withdraw money if other party is taking too much time and co or any other reason
    function withdrawByPayer() public onlyPayer {
        require(activatedByPayer && contractActivated == false);
        activatedByPayer = true;
        uint256 amountPayableByPayer = amountPayable + platformFee;
        // payable(payer).transfer(amountPayableByPayer);
        (bool sent, ) = payable(payer).call{value: amountPayableByPayer}("");
        require(sent);
    }

    //called by payer if transaction occured successfully
    function settle() public onlyPayer {
        (bool sent, ) = payable(payee).call{value: amountPayable}("");
        require(sent);
        (bool plat, ) = payable(admin).call{value: platformFee}("");
        require(plat);
        contractSettled = true;
        emit ContractSettled();
    }

    //called by anyone(generally payee if timeToRaiseDispute is passed
    function forceSettle() public {
        require(block.timestamp > (timeToRaiseDispute + contractActivatedTime));
        (bool sent, ) = payable(payee).call{value: amountPayable}("");
        require(sent);
        contractSettled = true;
        emit ContractSettled();
    }

    function raiseDispute() public onlyPayer {
        disputeRaised = true;
        emit DisputeRaised();
    }

    function payToPayee() public {
        require(msg.sender == arbitrator && disputeRaised == true);
        (bool sent, ) = payable(payee).call{value: amountPayable}("");
        require(sent);
        contractSettled = true;
        emit ContractSettled();
        emit DisputeResolved();
    }

    function withdrawByAdmin() public onlyAdmin {
        require(contractSettled == true);
        (bool sent, ) = payable(admin).call{value: platformFee}("");
        require(sent);
    }

    function payToPayer() public onlyArbitrator {
        require(disputeRaised == true);
        (bool sent, ) = payable(payer).call{value: amountPayable}("");
        require(sent);
        contractSettled = true;
        emit ContractSettled();
        emit DisputeResolved();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Escrow.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract EscrowFactory {
    address immutable tokenImplementation;

    // Escrow[] public escrowArray;

    constructor() {
        tokenImplementation = address(new Escrow());
    }

    function createEscrow(
        address payer,
        address payee,
        address arbitrator,
        uint256 amountPayable,
        uint256 platformFee,
        uint256 timeToRaiseDispute,
        string calldata contentHash
    ) external returns (address) {
        address clone = Clones.clone(tokenImplementation);
        Escrow(clone).initialize(
            payer,
            payee,
            arbitrator,
            amountPayable,
            platformFee,
            timeToRaiseDispute,
            contentHash
        );
        // escrowArray.push(clone);
        return clone;
    }

    // function viewAddress() public view returns (address) {
    //     return escrowArray;
    // }
}