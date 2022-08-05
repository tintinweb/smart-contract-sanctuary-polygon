// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// Trade a minimum of 25 Waste tokens for Astro Credits (NFT) at 1:1 ratio with a 5% fee going to the GWS Wallet and burn Waste Token

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IWasteToCash.sol";
import "./IAssetManager.sol";
/* error codes */
error WasteTrader__NotGovernance();
error WasteTrader__ZeroAddress();
error WasteTrader__MinimumOrderNotMet(uint256 _required);
error WasteTrader__MaximumOrderAmountExceeded(uint256 _tokenOrderAmount);
error WasteTrader__NoOrdersPlaced();
error WasteTrader__SpeedUpUnitsExceedClaimAmount(uint256 _mintableAmount);

/**@title Waste Trading
 * @author @Haltoshi
 * @notice This contract is for trading Waste NFTs for Astro Credits
 * @dev This uses the NFT contract for minting and burning Polygon Asset NFTs
 */
contract WasteTrader is OwnableUpgradeable, ReentrancyGuardUpgradeable, IWasteToCash {
    /* Type Declarations */
    struct WasteOrder {
        uint256 orderAmount;
        uint256 createdAt;
        uint256 speedUpDeductedAmount;
        uint256 timeRemaining;
        bool completed;
    }

    /* State Variables */
    address private s_signer;
    IAssetManager private s_iAssetManager;
    address private s_moderator;
    address private s_feeWallet;
    uint256 private s_gwsTime;
    uint256 private s_speedupTime;
    uint256 private s_gwsMinimumOrder;
    uint256 private s_multiplier;
    uint256 private s_gwsTax;
    uint8 private s_gwsMax;
    uint8 private s_gwsSpeedupCost;
    mapping(address => WasteOrder[]) private s_wasteOrders;

    string private constant MINT_MESSAGE = "mission control";
    uint256 constant WASTE_ID = uint256(IAssetManager.AssetIds.Waste);
    uint256 constant ASTRO_CREDIT_ID = uint256(IAssetManager.AssetIds.AstroCredit);

    /* Events */
    event WasteOrderPlaced(address indexed player, uint256 amount);
    event MintedMissionControl(address indexed player, uint256 indexed tokenId, uint256 amount);
    event WasteOrderSpedUp(address indexed player, uint256 amount, uint256 conversionTimeRemaining);
    event WasteOrderCompleted(address indexed player);

    /* Modifiers */
    modifier onlyGov() {
        if (msg.sender != owner() || msg.sender != s_moderator) revert WasteTrader__NotGovernance();
        _;
    }

    /* Functions */
    /**
     * @notice Initializer for the WasteTrader contract
     * @param assetManagerImpl address of the implementation 
        contract for the assetManager interface
     * @param gwsWalletAddress gws wallet address for the fees
     * @param gwsTime duration of time to convert waste to Astro Credits
     * @param speedupTime the conversion reduction time to convert
        Waste tokens to Astro Credits
     * @param gwsMinimumOrder the minimum amount of Waste tokens to burn
     * @param gwsTax fee represented as basis points e.g. 500 == 5 pct
     * @param gwsMax maximum amount of waste tokens per 
        conversion to Astro Credits
     * @param gwsSpeedupCost amount of Astro Credits to speed up 
        conversion of Waste tokens
     * @param multiplier  multiplier amount of minted tokens 
        i.e. 2 would represent a ratio of 1:2
     */
    function initialize(
        address assetManagerImpl,
        address gwsWalletAddress,
        uint256 gwsTime,
        uint256 speedupTime,
        uint256 gwsMinimumOrder,
        uint256 gwsTax,
        uint8 gwsMax,
        uint8 gwsSpeedupCost,
        uint8 multiplier
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        s_iAssetManager = IAssetManager(assetManagerImpl);
        s_feeWallet = gwsWalletAddress;
        s_gwsTime = gwsTime;
        s_speedupTime = speedupTime;
        s_gwsMinimumOrder = gwsMinimumOrder;
        s_gwsTax = gwsTax;
        s_gwsMax = gwsMax;
        s_gwsSpeedupCost = gwsSpeedupCost;
        s_moderator = msg.sender;
        s_multiplier = multiplier > 0 ? multiplier : 1;
    }

    function placeWasteOrder(uint256 _wasteAmount) external nonReentrant {
        uint256 gwsTime = s_gwsTime;
        uint256 gwsMax = s_gwsMax;
        if (gwsTime > 0) {
            WasteOrder[] storage wasteOrders = s_wasteOrders[msg.sender];

            if (wasteOrders.length == 0) {
                createNewOrder(_wasteAmount);
            } else {
                for (uint256 orderIndex; orderIndex < wasteOrders.length; ++orderIndex) {
                    if (
                        (s_wasteOrders[msg.sender][orderIndex].createdAt > 0) &&
                        (block.timestamp - s_wasteOrders[msg.sender][orderIndex].createdAt >
                            gwsTime)
                    ) {
                        if (s_wasteOrders[msg.sender][orderIndex].completed == false) {
                            s_wasteOrders[msg.sender][orderIndex].completed = true;
                            createNewOrder(_wasteAmount);
                            break;
                        }
                    } else {
                        if (s_wasteOrders[msg.sender][orderIndex].createdAt > 0) {
                            if (
                                s_wasteOrders[msg.sender][orderIndex].orderAmount + _wasteAmount <=
                                gwsMax
                            ) {
                                s_wasteOrders[msg.sender][orderIndex].orderAmount += _wasteAmount;
                            } else {
                                revert WasteTrader__MaximumOrderAmountExceeded(
                                    s_wasteOrders[msg.sender][orderIndex].orderAmount + _wasteAmount
                                );
                            }
                            emit WasteOrderPlaced(msg.sender, _wasteAmount);
                        }
                    }
                }
            }
        } else {
            burnAndMintMissionControlToken(msg.sender, WASTE_ID, _wasteAmount);
        }
    }

    /** @notice places a new Waste order
     *  @param _wasteAmount amount of waste tokens
     */
    function createNewOrder(uint256 _wasteAmount) internal {
        if (_wasteAmount > s_gwsMax) revert WasteTrader__MaximumOrderAmountExceeded(_wasteAmount);
        if (_wasteAmount < s_gwsMinimumOrder)
            revert WasteTrader__MinimumOrderNotMet(s_gwsMinimumOrder);
        s_wasteOrders[msg.sender].push(
            WasteOrder(_wasteAmount, block.timestamp, 0, s_gwsTime, false)
        );
        emit WasteOrderPlaced(msg.sender, _wasteAmount);
    }

    function claimAstroCredits() external nonReentrant {
        uint256 gwsTime = s_gwsTime;
        WasteOrder[] storage wasteOrders = s_wasteOrders[msg.sender];
        for (uint256 orderIndex; orderIndex < wasteOrders.length; ) {
            if (
                (s_wasteOrders[msg.sender][orderIndex].createdAt > 0) &&
                (block.timestamp - s_wasteOrders[msg.sender][orderIndex].createdAt > gwsTime)
            ) {
                uint256 deductedAmount = s_wasteOrders[msg.sender][orderIndex]
                    .speedUpDeductedAmount;
                uint256 orderAmount = s_wasteOrders[msg.sender][orderIndex].orderAmount -
                    deductedAmount;
                if (orderAmount > 0) {
                    if (orderIndex == wasteOrders.length - 1) {
                        for (uint256 orderIdx; orderIdx < wasteOrders.length; orderIdx++) {
                            s_wasteOrders[msg.sender].pop();
                        }
                    } else {
                        delete s_wasteOrders[msg.sender][orderIndex];
                    }
                    if (deductedAmount > 0) {
                        // burn deducted amount of tokens from the player
                        s_iAssetManager.trustedBurn(msg.sender, WASTE_ID, deductedAmount);
                        // mint deducted amount of tokens to the fee wallet
                        s_iAssetManager.trustedMint(s_feeWallet, ASTRO_CREDIT_ID, deductedAmount);
                    }
                    burnAndMintMissionControlToken(msg.sender, WASTE_ID, orderAmount);
                    emit WasteOrderCompleted(msg.sender);
                }
            }
            unchecked {
                ++orderIndex;
            }
        }
    }

    function getExchangeRate() external view returns (uint256 _numerator, uint256 _denominator) {
        return (1, s_multiplier);
    }

    function speedUpExchange(uint256 _numSpeedups) external nonReentrant {
        // ensure _numSpeedups * s_gwsSpeedupCost <= waste per order
        uint256 gwsTime = s_gwsTime;
        uint256 gwsTax = s_gwsTax;
        uint256 multiplier = s_multiplier;
        uint256 speedupTime = s_speedupTime;
        uint8 gwsSpeedupCost = s_gwsSpeedupCost;
        WasteOrder[] storage wasteOrders = s_wasteOrders[msg.sender];
        if (wasteOrders.length == 0) revert WasteTrader__NoOrdersPlaced();
        for (uint256 orderIndex; orderIndex < wasteOrders.length; ) {
            if (
                ((block.timestamp - s_wasteOrders[msg.sender][orderIndex].timeRemaining <
                    block.timestamp + gwsTime) &&
                    (s_wasteOrders[msg.sender][orderIndex].orderAmount > 0) &&
                    (s_wasteOrders[msg.sender][orderIndex].completed == false))
            ) {
                uint256 orderAmount = s_wasteOrders[msg.sender][orderIndex].orderAmount;
                uint256 feeTokenAmount = calculateFee(gwsTax, orderAmount, multiplier);
                uint256 mintableAmount = (orderAmount * multiplier) - feeTokenAmount;
                if (_numSpeedups * gwsSpeedupCost > mintableAmount)
                    revert WasteTrader__SpeedUpUnitsExceedClaimAmount(mintableAmount);
                s_wasteOrders[msg.sender][orderIndex].createdAt -= _numSpeedups * speedupTime;

                s_wasteOrders[msg.sender][orderIndex].speedUpDeductedAmount +=
                    _numSpeedups *
                    gwsSpeedupCost;

                uint256 timeRemaining;

                if (s_wasteOrders[msg.sender][orderIndex].timeRemaining > 0) {
                    if (!((_numSpeedups * speedupTime) >= gwsTime)) {
                        timeRemaining =
                            s_wasteOrders[msg.sender][orderIndex].timeRemaining -
                            (_numSpeedups * speedupTime);
                    }
                } else {
                    timeRemaining = gwsTime - (_numSpeedups * speedupTime);
                }

                s_wasteOrders[msg.sender][orderIndex].timeRemaining = timeRemaining;

                emit WasteOrderSpedUp(
                    msg.sender,
                    s_wasteOrders[msg.sender][orderIndex].orderAmount,
                    timeRemaining
                );
            }
            unchecked {
                ++orderIndex;
            }
        }
    }

    /** @notice burn and mint mission control token(s)
     *  @param from origin address
     *  @param tokenId to be burnt
     *  @param amount number of tokens to be burnt
     */
    function burnAndMintMissionControlToken(
        address from,
        uint256 tokenId,
        uint256 amount
    ) internal {
        uint256 tokenIdToMint = getMissionControlTokenToMint(tokenId);
        // calculate mintFee token amount
        uint256 feeTokenAmount = calculateFee(s_gwsTax, amount, s_multiplier);
        // calculate mintable token amount
        uint256 mintableAmount = (amount * s_multiplier) - feeTokenAmount;

        // burn mission control token(s) e.g. Waste Token at tokenId=7
        s_iAssetManager.trustedBurn(from, tokenId, amount);
        // mint mission control token(s) to the player/caller
        s_iAssetManager.trustedMint(from, tokenIdToMint, mintableAmount);
        // mint fee amount of tokens to the fee wallet
        s_iAssetManager.trustedMint(s_feeWallet, tokenIdToMint, feeTokenAmount);
        emit MintedMissionControl(from, tokenIdToMint, mintableAmount);
    }

    /** @notice retrieves the mintable tokenId for a given 
        burnable tokenId for mission control tokens
     *  @param tokenIdToBurn tokenId of the mission control 
        token that gets burnt
     */
    function getMissionControlTokenToMint(uint256 tokenIdToBurn)
        internal
        pure
        returns (uint256 tokenIdToMint)
    {
        if (tokenIdToBurn == WASTE_ID) {
            return ASTRO_CREDIT_ID;
        }
    }

    /** @notice calculates the amount of tokens determined as a fee
     *  @param bpsFee fee amount as a bps (basis points) e.g. 500 == 5 pct
     *  @param amount number of tokens to be minted
     *  @param multiplier amount of minted tokens to be
         burnt e.g. 1 represents a 1:1 ratio (burn:mint)
     */
    function calculateFee(
        uint256 bpsFee,
        uint256 amount,
        uint256 multiplier
    ) internal pure returns (uint256) {
        return ((amount * bpsFee) / 10000) * multiplier;
    }

    /** @notice verifies the message hash and signature of the signer
     *  @param hash message hash
     *  @param signature message signature
     *  @param to mint to address
     *  @param amount mint amount
     *  @param nonce sequential minter nonce
     */
    function checkMintValidity(
        bytes32 hash,
        bytes memory signature,
        address to,
        uint256 amount,
        uint256 nonce
    ) public view returns (bool) {
        bytes32 payloadHash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(abi.encodePacked(to, amount, MINT_MESSAGE, nonce))
        );
        bytes32 ethSignedMessageHash = ECDSAUpgradeable.toEthSignedMessageHash(hash);

        require(payloadHash == ethSignedMessageHash, "NFT: INVALID_HASH");
        require(
            ECDSAUpgradeable.recover(ethSignedMessageHash, signature) == s_signer,
            "NFT: INVALID_SIGNATURE"
        );
        return true;
    }

    /** @notice change signer
     *  @param _signer new signer
     */
    function setSigner(address _signer) external onlyGov {
        s_signer = _signer;
    }

    /** @notice retreive signer
     */
    function getSigner() public view returns (address) {
        return s_signer;
    }

    /** @notice change Moderator
     *  @param _moderator new moderator
     */
    function setModerator(address _moderator) external onlyOwner {
        if (_moderator == address(0)) revert WasteTrader__ZeroAddress();
        s_moderator = _moderator;
    }

    /** @notice retreive Moderator
     */
    function getModerator() public view returns (address) {
        return s_moderator;
    }

    /** @notice change Fee Wallet Address
     *  @param _feeWallet new fee wallet address
     */
    function setFeeWallet(address _feeWallet) external onlyGov {
        if (_feeWallet == address(0)) revert WasteTrader__ZeroAddress();
        s_feeWallet = _feeWallet;
    }

    /** @notice retreive Fee Wallet Address
     */
    function getFeeWallet() public view returns (address) {
        return s_feeWallet;
    }

    /** @notice change multiplier amount of minted tokens i.e. 2 would represent a ratio of 1:2
     *  @param _multiplier multiplier amount of minted tokens to be 
        burnt e.g. 1 represents a 1:1 ratio (burn:mint)
     */
    function setMultiplier(uint256 _multiplier) external onlyGov {
        s_multiplier = _multiplier;
    }

    /** @notice retreive multiplier amount of minted tokens to be 
        burnt e.g. 1 represents a 1:1 ratio (burn:mint)
     */
    function getMultiplier() public view returns (uint256) {
        return s_multiplier;
    }

    /** @notice change duration of time to convert waste to Astro Credits
     *  @param _gwsTime converting time duration
     */
    function setGwsTime(uint256 _gwsTime) external onlyGov {
        s_gwsTime = _gwsTime;
    }

    /** @notice retreive duration of time to convert waste to Astro Credits
     */
    function getGwsTime() public view returns (uint256) {
        return s_gwsTime;
    }

    /** @notice change maximum amount of waste tokens per 
        conversion to Astro Credits
     *  @param _gwsMax maximum amount
     */
    function setGwsMax(uint8 _gwsMax) external onlyGov {
        s_gwsMax = _gwsMax;
    }

    /** @notice retreive maximum amount of waste tokens per 
        conversion to Astro Credits
     */
    function getGwsMax() public view returns (uint8) {
        return s_gwsMax;
    }

    /** @notice change amount of Astro Credits to speed up 
        conversion of Waste tokens
     *  @param _gwsSpeedupCost Astro Credits amount
     */
    function setGwsSpeedupCost(uint8 _gwsSpeedupCost) external onlyGov {
        s_gwsSpeedupCost = _gwsSpeedupCost;
    }

    /** @notice retreive amount of Astro Credits to speed up 
        conversion of Waste tokens
     */
    function getGwsSpeedupCost() public view returns (uint8) {
        return s_gwsSpeedupCost;
    }

    /** @notice change the conversion reduction time to convert
        Waste tokens to Astro Credits
     *  @param _speedupTime conversion reduction time amount
     */
    function setSpeedupTime(uint256 _speedupTime) external onlyGov {
        s_speedupTime = _speedupTime;
    }

    /** @notice retreive the conversion reduction time to convert
        Waste tokens to Astro Credits
     */
    function getSpeedupTime() public view returns (uint256) {
        return s_speedupTime;
    }

    /** @notice change the minimum amount of Waste tokens to burn
        to redeem Astro Credits
     *  @param _gwsMinimumOrder minimum amount of Waste tokens
     */
    function setGwsMinimumOrder(uint16 _gwsMinimumOrder) external onlyGov {
        s_gwsMinimumOrder = _gwsMinimumOrder;
    }

    /** @notice retreive the minimum amount of Waste tokens to burn
        to redeem Astro Credits
     */
    function getGwsMinimumOrder() public view returns (uint256) {
        return s_gwsMinimumOrder;
    }

    /** @notice change basis points for the fee
     *  @param _gwsTax fee represented as basis points e.g. 500 == 5 pct
     */
    function setGwsTax(uint16 _gwsTax) external onlyGov {
        s_gwsTax = _gwsTax;
    }

    /** @notice retreive basis points for the fee
     */
    function getGwsTax() public view returns (uint256) {
        return s_gwsTax;
    }

    /** @notice change the implementation address for the iAssetManager
     *  @param _iAssetManager implementation address
     */
    function setIAssetManager(address _iAssetManager) external onlyGov {
        s_iAssetManager = IAssetManager(_iAssetManager);
    }

    /** @notice returns the iAssetManager
     */
    function getIAssetManager() public view returns (IAssetManager) {
        return s_iAssetManager;
    }

    /** @notice retreives the player's wasteOrders
     *  @param _player player address
     */
    function getWasteOrders(address _player) public view returns (WasteOrder[] memory) {
        WasteOrder[] memory wasteOrders = s_wasteOrders[_player];
        return wasteOrders;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

pragma solidity ^0.8.0;

/// @title The global waste systems exchanges waste for Astro Credits, as defined per the specs.
interface IWasteToCash {

    /**
    * @notice Places an order to have waste exchanged for Astro Credits
    * @param _wasteAmount The amount of waste to exchange
    */
    function placeWasteOrder(uint _wasteAmount) external;

    /// @notice Claims astro credits from completed orders
    function claimAstroCredits() external;

    /**
    * @notice Checks the current exchange rate, AC = round((WASTE)*(_numerator/_denominator))
    * @dev (_numerator/_denominator) may round to zero if integer division is used, so be careful in implementing
    * @return _numerator Numerator of exchange rate
    * @return _denominator Denominator of exchange rate
    */
    function getExchangeRate() external view returns (uint _numerator, uint _denominator);

    /**
    * @notice Speeds up exchanging
    * @param _numSpeedups Number of "units" of speed up
    */
    function speedUpExchange(uint _numSpeedups) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contract responsible for minting rewards and burning payment in the context of the mission control
interface IAssetManager {
    enum AssetIds {
        UNUSED_0, // 0, unused
        GoldBadge, //1
        SilverBadge, //2
        BronzeBadge, // 3
        GenesisDrone, //4
        PiercerDrone, // 5
        YSpaceShare, //6
        Waste, //7
        AstroCredit, // 8
        Blueprint, // 9
        BioModOutlier, // 10
        BioModCommon, //11
        BioModUncommon, // 12
        BioModRare, // 13
        BioModLegendary, // 14
        LootCrate, // 15
        TicketRegular, // 16
        TicketPremium, //17
        TicketGold, // 18
        FacilityOutlier, // 19
        FacilityCommon, // 20
        FacilityUncommon, // 21
        FacilityRare, //22
        FacilityLegendary, // 23,
        Energy // 24
    }

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenId Id of newly minted tokens
     * @param _amount Number of tokens to mint
     */
    function trustedMint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenIds Ids of newly minted tokens
     * @param _amounts Number of tokens to mint
     */
    function trustedBatchMint(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice Used to burn tokens by trusted contracts
     * @param _from Address to burn tokens from
     * @param _tokenId Id of to-be-burnt tokens
     * @param _amount Number of tokens to burn
     */
    function trustedBurn(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to burn tokens by trusted contracts
     * @param _from Address to burn tokens from
     * @param _tokenIds Ids of to-be-burnt tokens
     * @param _amounts Number of tokens to burn
     */
    function trustedBatchBurn(
        address _from,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}