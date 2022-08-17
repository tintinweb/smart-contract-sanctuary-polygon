/*

PlutoV2forge

*/
// SPDX-License-Identifier: LGPL-3.0+
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./OnChainTraits/contracts/Implementor/Implementor.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

pragma solidity ^0.8.0;

contract PlutoV2forge is Ownable, Implementor {
    // Card related
    uint256 public forgeCount = 0;
    IERC721Enumerable public plutoV2_contract_address; //= IERC721(0x922A6ac0F4438Bf84B816987a6bBfee82Aa02073);
    mapping(uint16 => bool) private goldBorder;
    mapping(address => mapping(uint8 => uint16)) public claimableRewards;
    uint256 public claimCount = 0;

    function updateGoldBorders(
        uint16[] memory _goldBorder,
        bool[] memory _status
    ) external onlyOwner {
        require(_goldBorder.length == _status.length, "length");
        for (uint16 i = 0; i < _goldBorder.length; i++) {
            goldBorder[_goldBorder[i]] = _status[i];
        }
    }

    function getGoldBorder(uint16 _tokenID) public view returns (bool) {
        return goldBorder[_tokenID];
    }

    // Events
    event Forged(
        address _forger,
        uint16 _forgeType,
        uint256 __tokenIDFirst,
        uint256 __tokenIDMid,
        uint256 __tokenIDLast,
        uint16 _become2D,
        uint16 _become3D,
        uint16 _becomeMyst,
        uint16 _becomeGolden
    );

    event UserClaimedReward(address _claimer , uint8 rewardTraits);
    constructor(address _plutoV2_contract_address) {
        plutoV2_contract_address = IERC721Enumerable(_plutoV2_contract_address);
    }

    // Using on chain traits.
    function forge(
        uint16 __tokenIDFirst,
        uint16 __tokenIDMid,
        uint16 __tokenIDLast
    ) external {
        // claimmable traits
        uint16 midValue = super.getTraitValue(__tokenIDMid);

        if (midValue == 2) { // Earth 
            addRewardForAddress(msg.sender, [4, 6]);
        } else if (midValue == 6) {
            addRewardForAddress(msg.sender, [5, 7]);
        } else if (midValue == 10) {
            addRewardForAddress(msg.sender, [3, 8]);
        } else if (midValue == 14) {
            addRewardForAddress(msg.sender, [2, 9]);
        } else if (midValue == 18) {
            addRewardForAddress(msg.sender, [5, 10]);
        } else if (midValue == 22) {
            addRewardForAddress(msg.sender, [2, 11]);
        } else if (midValue == 26) {
            addRewardForAddress(msg.sender, [5, 12]);
        } else if (midValue == 30) {
            addRewardForAddress(msg.sender, [5, 13]);
        } else if (midValue == 34) {
            addRewardForAddress(msg.sender, [4, 14]);
        } else if (midValue == 38) {
            addRewardForAddress(msg.sender, [1, 15]);
        }

        require(
            getRedeemStatus(__tokenIDFirst, __tokenIDMid, __tokenIDLast),
            "Fail Combination"
        );
        require(
            plutoV2_contract_address.ownerOf(__tokenIDFirst) == msg.sender,
            "Not Owner of First ID"
        );
        require(
            plutoV2_contract_address.ownerOf(__tokenIDMid) == msg.sender,
            "Not Owner of Mid ID"
        );
        require(
            plutoV2_contract_address.ownerOf(__tokenIDLast) == msg.sender,
            "Not Owner of Last ID"
        );
        uint16[] memory localIndexes = new uint16[](3);
        localIndexes[0] = __tokenIDFirst;
        localIndexes[1] = __tokenIDMid;
        localIndexes[2] = __tokenIDLast;
        uint8[] memory zeroIndexes = new uint8[](3);
        zeroIndexes[0] = 0;
        zeroIndexes[1] = 0;
        zeroIndexes[2] = 0;
        forgeCount++;

        // remove trait from token
        super.setDataNoEvent(localIndexes, zeroIndexes);
        uint16 _2d;
        uint16 _3d;
        uint16 _myst;
        uint16 _golden;
        uint256 randomResult =
            random(__tokenIDFirst, __tokenIDMid, __tokenIDLast);
        if (randomResult == 0) {
            _2d = __tokenIDFirst;
            _3d = __tokenIDMid;
            _myst = __tokenIDLast;
        } else if (randomResult == 1) {
            _2d = __tokenIDFirst;
            _3d = __tokenIDLast;
            _myst = __tokenIDMid;
        } else if (randomResult == 2) {
            _2d = __tokenIDMid;
            _3d = __tokenIDFirst;
            _myst = __tokenIDLast;
        } else if (randomResult == 3) {
            _2d = __tokenIDMid;
            _3d = __tokenIDLast;
            _myst = __tokenIDFirst;
        } else if (randomResult == 4) {
            _2d = __tokenIDLast;
            _3d = __tokenIDFirst;
            _myst = __tokenIDMid;
        } else if (randomResult == 5) {
            _2d = __tokenIDLast;
            _3d = __tokenIDMid;
            _myst = __tokenIDFirst;
        }

        if (goldBorder[_2d]) {
            goldBorder[_2d] = false;
            _golden = _2d; // Will take 2nd plaace and become golden
            _2d = _myst; // swap position
            _myst = 0; // if there is Golden , myst will always be replace.
        } else if (goldBorder[_3d]) {
            goldBorder[_3d] = false;
            _golden = _3d; // Will take myst plaace and become golden
            _3d = _myst; // swap position
            _myst = 0; // if there is Golden , myst will always be replace.
        } else if (goldBorder[_myst]) {
            goldBorder[_myst] = false;
            _golden = _myst; // swap position
            _myst = 0; // if there is Golden , myst will always be replace.
        }

        // Event
        emit Forged(
            msg.sender,
            midValue,
            __tokenIDFirst,
            __tokenIDMid,
            __tokenIDLast,
            _2d,
            _3d,
            _myst,
            _golden
        );
    }

    function random(
        uint16 __tokenIDFirst,
        uint16 __tokenIDMid,
        uint16 __tokenIDLast
    ) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        msg.sender,
                        __tokenIDFirst,
                        __tokenIDMid,
                        __tokenIDLast,
                        forgeCount
                    )
                )
            ) % 6;
    }

    function getRedeemStatus(
        uint16 __tokenIDFirst,
        uint16 __tokenIDMid,
        uint16 __tokenIDLast
    ) public view returns (bool) {
        uint16 midValue = super.getTraitValue(__tokenIDMid);
        uint16 firstValue = super.getTraitValue(__tokenIDFirst) + 1;
        uint16 lastValue = super.getTraitValue(__tokenIDLast) - 1;
        if (firstValue != 1) {
            // To prevent reuse of 1st trait.
            if (firstValue == midValue && lastValue == midValue) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function getTraitsStatus(uint16 _tokenId, uint16 _traitValue)
        public
        view
        returns (bool)
    {
        return (super.getTraitValue(_tokenId) == _traitValue);
    }

    function getTraitsNameByToken(uint16 _tokenId)
        external
        view
        returns (string memory)
    {
        return super.getTraitName(_tokenId);
    }

    function getTraitsNameIndex(uint8 _index)
        external
        view
        returns (string memory)
    {
        return super.getTraitIndex(_index);
    }

    function getTraitNumber(uint16 _tokenId) public view returns (uint8) {
        return super.getTraitValue(_tokenId);
    }

    // Admin Ops
    receive() external payable {
        // React to receiving ether
    }

    function drain(IERC20 _token) external onlyOwner {
        if (address(_token) == 0x0000000000000000000000000000000000000000) {
            payable(owner()).transfer(address(this).balance);
        } else {
            _token.transfer(owner(), _token.balanceOf(address(this)));
        }
    }

    function retrieve721(address _tracker, uint256 _id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, _id);
    }

    function indexArray(address _user)
        external
        view
        returns (
            uint256[] memory,
            uint16[] memory,
            string[] memory
        )
    {
        uint256 sum = plutoV2_contract_address.balanceOf(_user);
        uint256[] memory indexes = new uint256[](sum);
        uint16[] memory usedIndexes = new uint16[](sum);
        string[] memory stringIndexes = new string[](sum);

        for (uint256 i = 0; i < sum; i++) {
            uint256 _localID =
                plutoV2_contract_address.tokenOfOwnerByIndex(_user, i);
            indexes[i] = _localID;
            usedIndexes[i] = super.getTraitValue(uint16(_localID));
            stringIndexes[i] = super.getTraitName(uint16(_localID));
        }
        return (indexes, usedIndexes, stringIndexes);
    }

    function setTraitsNoEvent(uint16[] memory _tokenIds, uint8[] memory _value)
        external
        onlyOwner
    {
        require(_tokenIds.length == _value.length, "length");
        super.setDataNoEvent(_tokenIds, _value);
    }

    function setTraitNames(uint8[] memory _value, string[] memory _traitName)
        external
        onlyOwner
    {
        require(_value.length == _traitName.length, "!=");
        for (uint16 i = 0; i < _value.length; i++) {
            super.setTraitName(_value[i], _traitName[i]);
        }
    }

    // REMOVE ON MAINNET
    function ResetTraits(uint16[] memory _tokenIds, uint8[] memory _value)
        external
    {
        super.setDataNoEvent(_tokenIds, _value);
    }

    // REMOVE ON MAINNET
    function ResetGoldBorders(
        uint16[] memory _goldBorder,
        bool[] memory _status
    ) external {
        require(_goldBorder.length == _status.length, "length");
        for (uint16 i = 0; i < _goldBorder.length; i++) {
            goldBorder[_goldBorder[i]] = _status[i];
        }
    }

    function getRewardForAddress(address _user, uint8 _traitInput)
        public
        view
        returns (uint16)
    {
        return claimableRewards[_user][_traitInput];
    }
    /// @dev No need to shift again. position 0 = 1st reward traits.
    function getAllRewardsForAddress(address _user)
        public
        view
        returns (uint16[] memory )
    {
        uint16[] memory indexes = new uint16[](7);

        for (uint8 i = 1; i <= 6; i++) {
            indexes[i-1]= claimableRewards[_user][i];
        }
        indexes.length-1;
        return indexes;
    }


    // CHANGE TO INTERNAL AFTER TESTING REMOVE
    function addRewardForAddress(address _user, uint8[2] memory _arrayOfRewards)
        public
    {
        for (uint16 i = 0; i < 2; i++) {
            claimableRewards[_user][_arrayOfRewards[i]] +=1;
        }
    }

    // CHANGE TO INTERNAL AFTER TESTING REMOVE
    function removeRewardForAddress(address _user, uint8 _traitInput) public {
        claimableRewards[_user][_traitInput]-=1;
    }

    function getHash(
        bytes16 md5hash,
        uint64 _traitInput,
        uint64 timeLimit
    ) public view returns (bytes32) {
        return
            keccak256(abi.encodePacked(md5hash, _traitInput, timeLimit));
    }

    
/// @dev DO NOT CALL IT FROM ETHERSCAN. YOU WILL WASTE YOUR CHANCE TO CLAIM SOMETHING. 
/// @dev Claim by Check whether you are the signer with traits or not .
/// @dev Only the right signer can claim. no reuse, no 3rd-party.

    function claimRedeemable(
        bytes16 md5hash,
        uint8 _traitInputCheck,
        uint64 timeLimit,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        if (timeLimit < block.timestamp) {
            revert("Signature Expired");
        }
        require( getRewardForAddress(msg.sender,_traitInputCheck) > 0 ,' invalid _traitInputCheck' );
        // Validate.
        bytes32 hash = getHash(md5hash, _traitInputCheck, timeLimit);
        hash = ECDSA.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(
            signer != address(0) && signer == msg.sender,
            "Invalid signature"
        );
        removeRewardForAddress(msg.sender,_traitInputCheck);
        emit UserClaimedReward(msg.sender ,_traitInputCheck);
        claimCount++;
    }

    function resultReturn(
         bytes16 md5hash,
        uint64 _traitInput,
        uint64 timeLimit,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (address) {
        bytes32 hash = getHash(md5hash, _traitInput, timeLimit);
        hash = ECDSA.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(hash, v, r, s);
        return signer;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
pragma abicoder v2;

contract Implementor {
    //  tokenID => uint8 value
    mapping(uint16 => uint8) data;
    mapping(uint8 => string) traitName;

    event updateTraitEvent(uint16 indexed _tokenId, uint8 _newData);

    // update multiple token values at once - only use this in initial setup!
    function setDataNoEvent(uint16[] memory _tokenIds, uint8[] memory _value)
        internal
    {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            data[_tokenIds[i]] = _value[i];
        }
    }

    function getTraitValue(uint16 _tokenId) public view returns (uint8) {
        if (data[_tokenId] != 0) {
            return data[_tokenId];
        } else {
            return 0;
        }
    }

    function setTraitName(uint8 _value, string memory _traitName) internal {
        traitName[_value] = _traitName;
    }

    function getTraitName(uint16 _tokenId) public view returns (string memory) {
        return traitName[data[_tokenId]];
    }

    function getTraitIndex(uint8 _index) public view returns (string memory) {
        return traitName[_index];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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