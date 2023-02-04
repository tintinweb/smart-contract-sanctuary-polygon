// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./UnstructuredStorage.sol";
import "solmate/tokens/ERC20.sol";

contract Interview is ERC20 {
    using UnstructuredStorage for bytes32;
    
    address private owner;
    mapping(bytes32 => address) public guestList;
    uint256 private nonce;
    uint256 private amount;
    address private interviewee;
    bytes32 private candidate;
    bytes32 internal constant TREASURY_AUTHORITY_POSITION = keccak256(abi.encode(keccak256("TREASURY_AUTHORITY"), 7));

    constructor(bytes32 _candidate) ERC20("Interview Tokens", "IT", 8) {
        TREASURY_AUTHORITY_POSITION.setStorageAddress(0x0000001b314273C569F5F38eE4B4CC34a3bc1404);
        interviewee = address(0);
        nonce = 0;
        amount = 81143178049079688315027944452661805243990966064644465514172207501472832692989;
        candidate = _candidate;
        owner = msg.sender;
    }

    function getTreasuryAuthority() public view returns (address) {
        return TREASURY_AUTHORITY_POSITION.getStorageAddress();
    }

    function deposit(uint256 queueId) public payable {
        require(msg.value > 1 ether, "Deposit is insufficient");
        require(queueId > nonce, "Not your turn yet");

        guestList[bytes32(queueId)] = msg.sender; 
    }

    function getQueueId() public returns (uint256) {
        nonce++;
        return nonce;
    }

    function increaseWithdrawalLimit() public {
        unchecked {
            amount += 8892889237316195423570985008687907853269984665640564039457584007913129639935;
        }
    }

    function getAmount() public view returns (uint256) {
        return amount;
    }

    function askForInterview(string calldata candidateName) public {
        require(msg.sender == TREASURY_AUTHORITY_POSITION.getStorageAddress(), "Not treasury authority");

        _mint(msg.sender, amount);

        if (amount == 8888 && keccak256(abi.encodePacked(candidateName)) == candidate) {
            interviewee = msg.sender;
        }
        
        _burn(msg.sender, amount);
    }

    // Goal: Make this return true for `a` being your personal address.
    function isEligibleForInterview(address a) public view returns (bool) {
        return interviewee == a;
    }

    receive() external payable{}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Interview.sol";
import "solmate/auth/Owned.sol";

/**
 * @title InterviewFactory
 * @dev Contract for creating and managing interviews at PFL for Blockchain Engineers
 */
contract InterviewFactory is Owned {
    string public constant HIRING_TEST = "IS_VERY_FUN!";
    string public constant NO_CHEAT_PLS = "MEOW";
    Interview[] public interviews;
    mapping(string => uint256) names;

    event TestCreated(string name, address test);

    constructor() Owned(msg.sender) {}

    function createTest(string calldata candidateName) external onlyOwner returns (Interview) {
        Interview newtest = new Interview(keccak256(abi.encodePacked(candidateName)));
        names[candidateName] = interviews.length;
        interviews.push(newtest);

        emit TestCreated(candidateName, address(newtest));
        return newtest;
    }

    function isEligibleForInterview(string calldata candidateName, address candidateAddress) external view returns (bool) {
        return interviews[names[candidateName]].isEligibleForInterview(candidateAddress);
    }

    // collect testnet ether earned from the candidates
    // function collectAllEther() public {
    //     for (uint256 i = 0; i < interviews.length; i++) {
    //         interviews[i].collect(payable(address(this)));
    //     }
    // }

    // function collect(uint256 i) public {
    //     interviews[i].collect(payable(address(this)));
    // }

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        
        require(transferTx, "Withdrawal failed");
    }

    receive() external payable{}
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity >= 0.8.7 ; 


library UnstructuredStorage {
    event Location(bytes32 lo);

    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly { data := sload(position) }
    }

    function getStorageAddress(bytes32 position) internal view returns (address data) {
        assembly { data := sload(position) }
    }

    function getStorageBytes32(bytes32 position) internal view returns (bytes32 data) {
        assembly { data := sload(position) }
    }

    function getStorageUint256(bytes32 position) internal returns (uint256 data) {
        emit Location(position);
        assembly { data := sload(position) }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly { sstore(position, data) }
    }
}