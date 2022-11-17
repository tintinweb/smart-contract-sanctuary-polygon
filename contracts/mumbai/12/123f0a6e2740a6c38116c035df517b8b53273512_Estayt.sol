/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

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

interface IBeneficiary {
    struct Beneficiary {
        address address_;
        uint8 shares;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
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

contract Estayt is Owned, ReentrancyGuard {
    IEstaytFactory immutable factory;
    IBeneficiary.Beneficiary[] private beneficiaries;
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

    function getBeneficiaries() external view returns (IBeneficiary.Beneficiary[] memory) {
        return beneficiaries;
    }

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