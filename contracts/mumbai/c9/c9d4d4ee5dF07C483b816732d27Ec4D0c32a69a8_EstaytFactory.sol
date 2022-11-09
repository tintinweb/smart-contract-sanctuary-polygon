/**
 *Submitted for verification at polygonscan.com on 2022-11-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IBeneficiary {
    struct Beneficiary {
        address address_;
        uint8 shares;
    }
}

interface IEstaytFactory {
    function emitClaimedTooEarly(address claimer) external;
    function emitProveLife(uint256 newUnlockTime) external;
    function emitReclaimNative(address recipient, uint256 amount) external;
    function emitReclaimTokens(address recipient, address token, uint256 amount) external;
    function emitSetBeneficiaries(IBeneficiary.Beneficiary[] memory beneficiaries) external;
    function emitSetProofOfLifeDuration(uint256 proofOfLifeDuration) external;
    function emitTransferNative(address recipient, uint256 amount) external;
    function emitTransferTokens(address recipient, address token, uint256 amount) external;
}

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

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract Estayt is Owned, ReentrancyGuard {
    IEstaytFactory immutable factory;
    IBeneficiary.Beneficiary[] public beneficiaries;
    uint256 public lastProofOfLife;
    uint256 public proofOfLifeDuration;

    constructor(address _owner, uint256 _proofOfLifeDuration, IBeneficiary.Beneficiary[] memory _beneficiaries)
        Owned(_owner)
    {
        factory = IEstaytFactory(msg.sender);

        _setBeneficiaries(_beneficiaries);
        _setProofOfLifeDuration(_proofOfLifeDuration);
    }

    receive() external payable {}

    function unlockTime() public view returns (uint256 _unlockTime) {
        _unlockTime = lastProofOfLife + proofOfLifeDuration;
    }

    function claim(IERC20[] calldata tokens, bool claimNative) external nonReentrant {
        if (unlockTime() > block.timestamp) {
            factory.emitClaimedTooEarly(msg.sender);

            return;
        }

        uint256 tokensLength = tokens.length;
        IBeneficiary.Beneficiary[] memory _beneficiaries = beneficiaries;
        uint256 beneficiariesLength = _beneficiaries.length;

        for (uint256 i; i < tokensLength; ++i) {
            IERC20 token = tokens[i];
            uint256 balance = token.balanceOf(address(this));

            for (uint256 j; j < beneficiariesLength; ++j) {
                IBeneficiary.Beneficiary memory beneficiary = _beneficiaries[j];
                address address_ = beneficiary.address_;
                uint256 amount = balance * beneficiary.shares / 100;

                token.transfer(address_, amount);

                factory.emitTransferTokens(address_, address(token), amount);
            }
        }

        if (claimNative) {
            uint256 balance = address(this).balance;

            for (uint256 i; i < beneficiariesLength; ++i) {
                IBeneficiary.Beneficiary memory beneficiary = _beneficiaries[i];
                address address_ = beneficiary.address_;
                uint256 amount = balance * beneficiary.shares / 100;

                (bool sent,) = address_.call{value: amount}("");
                require(sent, "Failed to send Ether");

                factory.emitTransferNative(address_, amount);
            }
        }
    }

    function proveLife() external onlyOwner {
        _proveLife();
    }

    function reclaim(IERC20[] calldata tokens, bool claimNative) external nonReentrant onlyOwner {
        uint256 tokensLength = tokens.length;

        for (uint256 i; i < tokensLength; ++i) {
            IERC20 token = tokens[i];
            uint256 balance = token.balanceOf(address(this));

            token.transfer(msg.sender, balance);

            factory.emitReclaimTokens(msg.sender, address(token), balance);
        }

        if (claimNative) {
            uint256 balance = address(this).balance;

            (bool sent,) = msg.sender.call{value: balance}("");
            require(sent, "Failed to send Ether");

            factory.emitReclaimNative(msg.sender, balance);
        }
    }

    function setBeneficiaries(IBeneficiary.Beneficiary[] memory _beneficiaries) external onlyOwner {
        _setBeneficiaries(_beneficiaries);
    }

    function setProofOfLifeDuration(uint256 _proofOfLifeDuration) external onlyOwner {
        _setProofOfLifeDuration(_proofOfLifeDuration);
    }

    function _proveLife() internal {
        lastProofOfLife = block.timestamp;

        factory.emitProveLife(unlockTime());
    }

    function _setBeneficiaries(IBeneficiary.Beneficiary[] memory _beneficiaries) internal {
        delete beneficiaries;

        uint256 length = _beneficiaries.length;
        uint8 totalShares;

        for (uint256 i; i < length; ++i) {
            IBeneficiary.Beneficiary memory beneficiary = _beneficiaries[i];

            beneficiaries.push(beneficiary);
            totalShares += beneficiary.shares;
        }

        require(100 == totalShares, "Shares");

        factory.emitSetBeneficiaries(_beneficiaries);
    }

    function _setProofOfLifeDuration(uint256 _proofOfLifeDuration) internal {
        proofOfLifeDuration = _proofOfLifeDuration;

        factory.emitSetProofOfLifeDuration(_proofOfLifeDuration);

        _proveLife();
    }
}

contract EstaytFactory is IEstaytFactory {
    event ClaimedTooEarly(address indexed estayt, address indexed claimer);
    event NewEstayt(address indexed estayt, address indexed owner);
    event ProveLife(address indexed estayt, uint256 indexed newUnlockTime);
    event ReclaimNative(address indexed estayt, address indexed recipient, uint256 amount);
    event ReclaimTokens(address indexed estayt, address indexed recipient, address indexed token, uint256 amount);
    event SetBeneficiaries(address indexed estayt, IBeneficiary.Beneficiary[] beneficiaries);
    event SetProofOfLifeDuration(address indexed estayt, uint256 proofOfLifeDuration);
    event TransferNative(address indexed estayt, address indexed recipient, uint256 amount);
    event TransferTokens(address indexed estayt, address indexed recipient, address indexed token, uint256 amount);

    mapping(address => bool) public isEstayt;
    mapping(address => address) public estaytForAddress;

    /// This is only for the MVP - allows us to reset the demo quickly to show it again.
    function deleteEstayt() external {
        delete estaytForAddress[msg.sender];
    }

    function createEstayt(uint256 _proofOfLifeDuration, IBeneficiary.Beneficiary[] memory _beneficiaries) external {
        Estayt estayt = new Estayt(msg.sender, _proofOfLifeDuration, _beneficiaries);

        isEstayt[address(estayt)] = true;
        estaytForAddress[msg.sender] = address(estayt);

        emit NewEstayt({estayt: address(estayt), owner: msg.sender});
    }

    modifier onlyEstayt() {
        require(isEstayt[msg.sender], "Unauthorized");

        _;
    }

    function emitClaimedTooEarly(address claimer) external onlyEstayt {
        emit ClaimedTooEarly(msg.sender, claimer);
    }

    function emitProveLife(uint256 newUnlockTime) external onlyEstayt {
        emit ProveLife(msg.sender, newUnlockTime);
    }

    function emitReclaimNative(address recipient, uint256 amount) external onlyEstayt {
        emit ReclaimNative(msg.sender, recipient, amount);
    }

    function emitReclaimTokens(address recipient, address token, uint256 amount) external onlyEstayt {
        emit ReclaimTokens(msg.sender, recipient, token, amount);
    }

    function emitSetBeneficiaries(IBeneficiary.Beneficiary[] memory beneficiaries) external onlyEstayt {
        emit SetBeneficiaries(msg.sender, beneficiaries);
    }

    function emitSetProofOfLifeDuration(uint256 proofOfLifeDuration) external onlyEstayt {
        emit SetProofOfLifeDuration(msg.sender, proofOfLifeDuration);
    }

    function emitTransferNative(address recipient, uint256 amount) external onlyEstayt {
        emit TransferNative(msg.sender, recipient, amount);
    }

    function emitTransferTokens(address recipient, address token, uint256 amount) external onlyEstayt {
        emit TransferTokens(msg.sender, recipient, token, amount);
    }
}