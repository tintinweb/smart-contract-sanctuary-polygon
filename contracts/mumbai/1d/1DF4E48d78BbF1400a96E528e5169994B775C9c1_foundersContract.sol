// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
}

contract foundersContract is Ownable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    IERC721 NFT;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint8 private totalCategories;

    uint256 private perTransactionCap;
    uint256 private totalSupply;
    uint256 private totalMintedSupply;
    uint256 private totalPublicSupply;
    uint256 private totalPublicMintedSupply;
    uint256 private totalReservedSupply;
    uint256 private totalReservedMintedSupply;
    uint256 private totalLeaderboardSupply;
    uint256 private totalLeaderboardMintedSupply;

    address private leaderboardSignerAddress;
    address private reservedSignerAddress;
    address payable private withdrawAddress;

    struct Category {
        uint256 publicSupplyPoint; // point 1
        uint256 reservedSupplyPoint; // point 2
        uint256 leaderboardSupplyPoint; // point 3
        uint256 maxSupplyPoint; // point 4
        uint256 totalSupply;
        uint256 publicSupply;
        uint256 publicMintedSupply;
        uint256 reservedSupply;
        uint256 reservedMintedSupply;
        uint256 leaderboardSupply;
        uint256 leaderboardMintedSupply;
        uint256 categoryPrice;
        uint256[3] counter;
        /* [0] --> public counter
        /  [1] --> reserved counter
        /  [2] --> leaderboard counter
        */
    }

    mapping(uint8 => Category) public categories;
    mapping(bytes => bool) private signatures;

    event LeaderboardMint(
        address indexed _beneficiary,
        uint256 indexed _tokenId,
        uint8 category
    );
    event ReservedMint(
        address indexed _beneficiary,
        uint256 indexed _tokenId,
        uint8 category
    );
    event PublicMint(
        address indexed _beneficiary,
        uint256 indexed _tokenId,
        uint256 indexed _category,
        uint256 price
    );
    event UpdatePerTransactionCap(
        uint256 indexed _perTransactionCap
    );
    event UpdateLeaderboardSignerAddress(
        address indexed _leaderboardSignerAddress
    );
    event UpdateReservedSignerAddress(
        address indexed _reservedSignerAddress
    );
    event UpdateNFTContractAddress(
        address indexed _nftContractAddress
    );
    event UpdateWithdrawAddress(
        address indexed _withdrawAddress
    );
    event WithdrawEthFunds(
        uint256 indexed _amount
    );

    constructor(
        Category[] memory _categories,
        uint8 _categoryCounter,
        uint256 _perTransactionCap,
        address _nftContractAddress,
        address _leaderboardSignerAddress,
        address _reservedSignerAddress,
        address payable _withdrawAddress
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        require(
            _categoryCounter == _categories.length,
            "Founder Contract: Categories length does not match"
        );
        perTransactionCap = _perTransactionCap;
        leaderboardSignerAddress = _leaderboardSignerAddress;
        reservedSignerAddress = _reservedSignerAddress;
        NFT = IERC721(_nftContractAddress);
        withdrawAddress = payable(_withdrawAddress);
        for (uint8 index = 0; index < _categories.length; index++) {
            _addCategory(_categoryCounter, _categories[index]);
            _categoryCounter--;
        }
    }

    function leaderboardMint(
        uint8 _category,
        uint256 _timestamp,
        address _nftContractAddress,
        bytes32 _msgHash,
        bytes memory _signature
    ) public {
        require(
            !signatures[_signature],
            "Founder Contract: Signature already used"
        );
        require(
            categories[_category].leaderboardMintedSupply.add(1) <=
                categories[_category].leaderboardSupply,
            "Founder Contract: Max supply of leaders in this category minted"
        );
        require(
            categories[_category].counter[2] >=
                categories[_category].leaderboardSupplyPoint &&
                categories[_category].counter[2] <=
                categories[_category].maxSupplyPoint,
            "Founder Contract: Invalid token id for leaderboard supply range"
        );
        bytes32 msgHash = getMessageHash(
            msg.sender,
            _timestamp,
            _category,
            _nftContractAddress
        );
        bytes32 signedMsgHash = msgHash.toEthSignedMessageHash();
        require(
            signedMsgHash == _msgHash,
            "Founder Contract: Invalid message hash"
        );
        require(
            _msgHash.recover(_signature) == leaderboardSignerAddress,
            "Founder Contract: Invalid signer"
        );

        signatures[_signature] = true;
        categories[_category].leaderboardMintedSupply++;
        totalLeaderboardMintedSupply++;
        totalMintedSupply++;

        NFT.mint(msg.sender, categories[_category].counter[2]);

        emit LeaderboardMint(
            msg.sender,
            categories[_category].counter[2],
            _category
        );
        
        categories[_category].counter[2]++;
    }

    function reservedMint(
        uint8 _category,
        uint256 _timestamp,
        address _nftContractAddress,
        bytes32 _msgHash,
        bytes memory _signature
    ) public {
        require(
            !signatures[_signature],
            "Founder Contract: Signature already used"
        );
        require(
            categories[_category].reservedMintedSupply.add(1) <=
                categories[_category].reservedSupply,
            "Founder Contract: Max supply of reserve in this category minted"
        );
        require(
            categories[_category].counter[1] >=
                categories[_category].reservedSupplyPoint &&
                categories[_category].counter[1] <
                categories[_category].leaderboardSupplyPoint,
            "Founder Contract: Invalid token id for reserve supply range"
        );
        bytes32 msgHash = getMessageHash(
            msg.sender,
            _timestamp,
            _category,
            _nftContractAddress
        );
        bytes32 signedMsgHash = msgHash.toEthSignedMessageHash();
        require(
            signedMsgHash == _msgHash,
            "Founder Contract: Invalid message hash"
        );
        require(
            _msgHash.recover(_signature) == reservedSignerAddress,
            "Founder Contract: Invalid signer"
        );
        signatures[_signature] = true;
        categories[_category].reservedMintedSupply++;
        totalReservedMintedSupply++;
        totalMintedSupply++;
        NFT.mint(msg.sender, categories[_category].counter[1]);
        emit ReservedMint(
            msg.sender,
            categories[_category].counter[1],
            _category
        );
        categories[_category].counter[1]++;
    }

    function publicMint(
        uint256 _tokenIdsLength,
        uint8 _category
    ) public payable {
        require(
            msg.value ==
                _tokenIdsLength.mul(categories[_category].categoryPrice),
            "Founder Contract: Invalid Price"
        );
        require(
            _tokenIdsLength <= perTransactionCap,
            "Founder Contract: Cannot mint more than transaction cap"
        );
        require(
            categories[_category].publicMintedSupply.add(_tokenIdsLength) <=
                categories[_category].publicSupply,
            "Founder Contractt: Max supply of public in this category minted"
        );
        for (uint256 index = 0; index < _tokenIdsLength; index++) {
            require(
                categories[_category].counter[0] >=
                    categories[_category].publicSupplyPoint &&
                    categories[_category].counter[0] <
                    categories[_category].reservedSupplyPoint,
                "Founder Contract: Invalid token id for public supply range"
            );
            // categories[_category].publicMintedSupply++;
            // totalPublicMintedSupply++;
            // totalMintedSupply++;
            NFT.mint(msg.sender, categories[_category].counter[0]);
            emit PublicMint(
                msg.sender,
                categories[_category].counter[0],
                _category,
                msg.value
            );
            categories[_category].counter[0]++;
        }
        categories[_category].publicMintedSupply = categories[_category]
            .publicMintedSupply
            .add(_tokenIdsLength);
        totalPublicMintedSupply = totalPublicMintedSupply.add(_tokenIdsLength);
        totalMintedSupply = totalMintedSupply.add(_tokenIdsLength);
    }

    function _addCategory(
        uint8 _category,
        Category memory _categoryValue
    ) internal {
        require(
            _categoryValue.publicSupplyPoint ==
                categories[_category + 1].maxSupplyPoint.add(1),
            "Founder Contract: Next cateogry should start next from last category ending"
        );
        require(
            _categoryValue.maxSupplyPoint ==
                _categoryValue.publicSupplyPoint.add(
                    _categoryValue.totalSupply.sub(1)
                ),
            "Founder Contract: Invalid supply range"
        );
        require(
            _categoryValue.totalSupply ==
                _categoryValue.publicSupply.add(
                    _categoryValue.reservedSupply.add(
                        _categoryValue.leaderboardSupply
                    )
                ),
            "Founder Contract: should be equal to total supply"
        );
        require(
            _categoryValue.counter[0] == _categoryValue.publicSupplyPoint &&
                _categoryValue.counter[1] ==
                _categoryValue.reservedSupplyPoint &&
                _categoryValue.counter[2] ==
                _categoryValue.leaderboardSupplyPoint,
            "Founder Contract: Counter doesn't match with the starting points"
        );
        categories[_category].publicSupplyPoint = _categoryValue
            .publicSupplyPoint;
        categories[_category].reservedSupplyPoint = _categoryValue
            .reservedSupplyPoint;
        categories[_category].leaderboardSupplyPoint = _categoryValue
            .leaderboardSupplyPoint;
        categories[_category].maxSupplyPoint = _categoryValue.maxSupplyPoint;
        categories[_category].totalSupply = _categoryValue.totalSupply;
        categories[_category].publicSupply = _categoryValue.publicSupply;
        categories[_category].reservedSupply = _categoryValue.reservedSupply;
        categories[_category].leaderboardSupply = _categoryValue
            .leaderboardSupply;
        categories[_category].categoryPrice = _categoryValue.categoryPrice;
        categories[_category].counter[0] = _categoryValue.counter[0]; // public counter
        categories[_category].counter[1] = _categoryValue.counter[1]; // reserved counter
        categories[_category].counter[2] = _categoryValue.counter[2]; // leaderboard counter
        totalCategories = totalCategories + 1; // unit8
        totalSupply = totalSupply.add(_categoryValue.totalSupply);
        totalPublicSupply = totalPublicSupply.add(_categoryValue.publicSupply);
        totalReservedSupply = totalReservedSupply.add(
            _categoryValue.reservedSupply
        );
        totalLeaderboardSupply = totalLeaderboardSupply.add(
            _categoryValue.leaderboardSupply
        );
    }

    function updatePerTransactionCap(uint256 _perTransactionCap) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Founder Contract: Must have admin role to update"
        );
        require(
            _perTransactionCap != 0,
            "Founder Contract: Invalid amount for cap"
        );
        require(
            _perTransactionCap != perTransactionCap,
            "Founder Contract: Invalid amount for cap"
        );
        perTransactionCap = _perTransactionCap;
        emit UpdatePerTransactionCap(_perTransactionCap);
    }

    function updateLeaderboardSignerAddress(
        address _leaderboardSignerAddress
    ) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Founder Contract: Must have admin role to update"
        );
        require(
            _leaderboardSignerAddress != address(0),
            "Founder Contract: Invalid Address"
        );
        require(
            _leaderboardSignerAddress != leaderboardSignerAddress,
            "Founder Address: Invalid Address"
        );
        leaderboardSignerAddress = _leaderboardSignerAddress;
        emit UpdateLeaderboardSignerAddress(_leaderboardSignerAddress);
    }

    function updateReservedSignerAddress(
        address _reservedSignerAddress
    ) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Founder Contract: Must have admin role to update"
        );
        require(
            _reservedSignerAddress != address(0),
            "Founder Contract: Invalid Address"
        );
        require(
            _reservedSignerAddress != reservedSignerAddress,
            "Founder Address: Invalid Address"
        );
        reservedSignerAddress = _reservedSignerAddress;
        emit UpdateReservedSignerAddress(_reservedSignerAddress);
    }

    function updateNFTContractAddress(address _nftContractAddress) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Founder Contract: Must have admin role to update"
        );
        require(
            _nftContractAddress != address(0),
            "Founder Contract: Invalid Address"
        );
        NFT = IERC721(_nftContractAddress);
        emit UpdateNFTContractAddress(_nftContractAddress);
    }

    function updateWithdrawAddress(address payable _withdrawAddress) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Founder Contract: Must have admin role to update withdraw address"
        );
        require(
            _withdrawAddress != address(0),
            "Founder Contract: Invalid address"
        );
        require(_withdrawAddress != withdrawAddress, "Invalid address");
        withdrawAddress = _withdrawAddress;
        emit UpdateWithdrawAddress(_withdrawAddress);
    }

    function withdrawEthFunds(uint256 _amount) public onlyOwner nonReentrant {
        require(
            _amount > 0 && _amount <= address(this).balance,
            "Founder Contract: Invalid amount"
        );
        withdrawAddress.transfer(_amount);
        emit WithdrawEthFunds(_amount);
    }

    function getMessageHash(
        address _to,
        uint256 _timestamp,
        uint256 _category,
        address _nftContractAddress
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _to,
                    _timestamp,
                    _category,
                    _nftContractAddress
                )
            );
    }

    function getperTransactionCap() public view returns (uint256) {
        return perTransactionCap;
    }

    function getTotalCategories() public view returns (uint8) {
        return totalCategories;
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getTotalMintedSupply() public view returns (uint256) {
        return totalMintedSupply;
    }

    function getTotalPublicSupply() public view returns (uint256) {
        return totalPublicSupply;
    }

    function getTotalPublicMintedSupply() public view returns (uint256) {
        return totalPublicMintedSupply;
    }

    function getTotalReservedSupply() public view returns (uint256) {
        return totalReservedSupply;
    }

    function getTotalReservedMintedSupply() public view returns (uint256) {
        return totalReservedMintedSupply;
    }

    function getTotalLeaderboardSupply() public view returns (uint256) {
        return totalLeaderboardSupply;
    }

    function getTotalLeaderboardMintedSupply() public view returns (uint256) {
        return totalLeaderboardMintedSupply;
    }

    function getLeaderboardSignerAddress() public view returns (address) {
        return leaderboardSignerAddress;
    }

    function getReservedSignerAddress() public view returns (address) {
        return reservedSignerAddress;
    }

    function getNFTContractAddress() public view returns (IERC721) {
        return NFT;
    }

    function getWithdrawAddress() public view returns (address) {
        return withdrawAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
}

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}