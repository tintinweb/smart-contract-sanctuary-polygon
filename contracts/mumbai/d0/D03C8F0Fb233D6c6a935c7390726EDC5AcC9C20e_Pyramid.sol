//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IWAVAX.sol";
import "./FeeDistributor.sol";

contract Pyramid {

    using SafeMath for uint256;

    //Parameters

    uint256 public DEFAULT_PRICE = 0.00000002 ether; //TODO CHANGE 
    uint256 public MAX_BLOCKS = 440896;

    uint256 public INCREASE_FACTOR = 1500; // = 15%

    uint256 public PYRAMID_BUILD_SHARES = 5000; // = 50%

    uint256 public OWNER_REBUY_SHARES = 9000; // = 90%
    uint256 public PYRAMID_REBUY_SHARES = 500; // = 5%
    uint256 public PHARAOH_REBUY_SHARES = 500; // = 5%

    uint256 public constant BASE = 10000; // = 100%
    
    address payable public pharaoh;

    IWAVAX public wAVAX;

    FeeDistributor public feeDistributor;

    //Block data

    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => bytes) public colorOf;
    mapping(uint256 => uint256) private priceOf;

    //Events

    event BuildBlock (address indexed _owner, uint256 indexed _id, uint256 _toDistribute, bytes _color);
    event BuyBlock (address indexed _oldOwner, address indexed _newOwner, uint256 indexed _id, uint256 _price, uint256 _toDistribute, bytes _color);
    event UpdateColor (uint256 indexed _id, bytes _newColor, address _by);
    event TransferBlock (uint256 indexed _id, address _oldOwner, address _newOwner);

    //Modifiers 

    modifier onlyPharaoh ()  {
        require(pharaoh == msg.sender, "Not the pharaoh");
        _;
    }

    //Constructors

    constructor(address _wAVAX) {
        pharaoh = payable(msg.sender);
        wAVAX = IWAVAX(_wAVAX);
        feeDistributor = new FeeDistributor(address(this), address(wAVAX));
    }

    //Public functions

    function buildBlocks (uint256[] memory _blocks, bytes memory _color) payable public {
        require(msg.value == getTotalPrice(_blocks, msg.sender), "Not enough money");

        uint256 pyramidShare = 0;
        // uint256 discount = _getDiscount(_blocks);

        for (uint i; i < _blocks.length; i++) {
            
            uint256 blockId = _blocks[i];
            require(blockId >= 0 && blockId < MAX_BLOCKS, "Wrond id");

            address lastOwner = ownerOf[blockId];

			if (lastOwner != msg.sender) { //else it's just a repaint

				uint256 blockPrice = _getPrice(blockId);

				ownerOf[blockId] = msg.sender;
				priceOf[blockId] = blockPrice.add(blockPrice.mul(INCREASE_FACTOR).div(BASE));

				if(_isBuilt(blockId)) {
					//transfer to last owner

					uint256 ownerShare = blockPrice.mul(OWNER_REBUY_SHARES).div(BASE);
					payable(lastOwner).transfer(ownerShare);

					uint256 toDistribute = blockPrice.sub(ownerShare);
					pyramidShare = pyramidShare.add(toDistribute);

					emit BuyBlock(lastOwner, msg.sender, blockId, blockPrice, toDistribute, _color);
				}
				else {
					pyramidShare = pyramidShare.add(blockPrice);

					emit BuildBlock(msg.sender, blockId, blockPrice, _color);
                    // uint256 discountedPrice = blockPrice.sub((blockPrice.mul(discount).div(BASE)));
					// pyramidShare = pyramidShare.add(discountedPrice);

					// emit BuildBlock(msg.sender, blockId, discountedPrice, _color);
				}
			}
            else {
                emit UpdateColor(blockId, _color, msg.sender);
            }

			colorOf[blockId] = _color;            
        }

        _wrapAndTransfer(pyramidShare);
    }

    function getTotalPrice (uint256[] memory _blocks, address _for) public view returns (uint256) {
        uint256 sum = 0;
        // uint256 discount = _getDiscount(_blocks);

        for (uint i; i < _blocks.length; i++) {
            uint256 id = _blocks[i];
            if(ownerOf[id] != _for) {
                // uint256 price = _getPrice(id);
                // if(!_isBuilt(id)) {
                //     sum = sum.add(price.sub((price.mul(discount).div(BASE))));
                // }
                // else {
                //     sum = sum.add(price);
                // }
                sum = sum.add(_getPrice(id));
            }
        }

        return sum;
    }

    function transferBlocks (uint256[] memory _blocks, address _to) public {
        for (uint i; i < _blocks.length; i++) {
            uint256 id = _blocks[i];
            require(ownerOf[id] == msg.sender, "Not the owner");
            ownerOf[id] = _to;
            emit TransferBlock(id, msg.sender, _to);
        }
    }


    //Restricted functions 

    function setPharaoh (address payable _new) onlyPharaoh public {
        require(_new != address(0));
        pharaoh = _new;
    }

    function pauseRewards() onlyPharaoh public {
        feeDistributor.pause();
    }

    function setRewards(bytes32 _merkleRoot) onlyPharaoh public {
        feeDistributor.setMerkleRoot(_merkleRoot);
    }


    //Internal functions

    function _wrapAndTransfer (uint256 _amount) internal {
        wAVAX.deposit{value: _amount}();
        require(wAVAX.transfer(address(feeDistributor), _amount));
    }

    function _getPrice (uint256 _id) internal view returns (uint256) {
        require(_id >= 0 && _id < MAX_BLOCKS, "Wrond id");

        return _isBuilt(_id) ? priceOf[_id] : DEFAULT_PRICE;
    }

    // function _getDiscount (uint256[] memory _blocks) internal view returns (uint256) {
    //     uint256 toBuild = 0;

    //     for (uint i; i < _blocks.length; i++) {
    //         if(!_isBuilt(_blocks[i])) {
    //             toBuild = toBuild.add(1);
    //         }
    //     }

    //     if (toBuild >= MAX_BLOCKS.div(2)) return 6000; // 60% for 50% of the pyramid
    //     else if (toBuild >= MAX_BLOCKS.div(4)) return 4000; // 40% for 25% of the pyramid
    //     else if (toBuild >= 10000) return 2500; //25% for 10,000
    //     else if (toBuild >= 250) return 2000; // 20% for 250
    //     else if (toBuild >= 50) return 1000; // 10% for 50
    //     else return 0;
    // }

    function _isBuilt (uint256 _id) internal view returns (bool) {
        return ownerOf[_id] != address(0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.9;
interface IWAVAX {
    
    function deposit() external payable;

    function withdraw(uint wad) external;

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface IERC20 {
    /**
     * @dev Moves `amount` tokens from the caller"s account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract FeeDistributor {
    bytes32[] public merkleRoots;
    uint256 public lastRoot;

    address public token;

    address public authority;

    event Claimed(
        uint256 merkleIndex,
        uint256 index,
        address account,
        uint256 amount
    );

    event Pause(
        uint256 merkleIndex
    );

    bool public isPaused;

    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    constructor(address _authority, address _token) {
        authority = _authority;
        isPaused = true;
        token = _token;
    }

    function getIndex() public view returns (uint256){
        return merkleRoots.length - 1;
    }

    function setAuthority(address _account) public {
        require(msg.sender == authority, "Not authorized.");
        authority = _account;
    }

    function pause() public {
        require(msg.sender == authority, "Not authorized.");
        require(!isPaused, "Distributor already paused.");
        isPaused = true;
        emit Pause(merkleRoots.length - 1);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public {
        require(msg.sender == authority, "Not authorized.");
        require(isPaused, "Distributor must be paused.");
        require(_merkleRoot != 0x00, "Merkle root is null.");
        merkleRoots.push(_merkleRoot);
        isPaused = false;
    }

    function isClaimed(uint256 merkleIndex, uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[merkleIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 merkleIndex, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[merkleIndex][claimedWordIndex] =
            claimedBitMap[merkleIndex][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external {
        require(!isPaused, "Cannot claim when paused.");
        uint256 merkleIndex = merkleRoots.length - 1;
        require(!isClaimed(merkleIndex, index), "Already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(verify(merkleProof, merkleRoots[merkleIndex], node), "Invalid proof.");

        // Mark as claimed and send the token.
        _setClaimed(merkleIndex, index);
        IERC20(token).transfer(msg.sender, amount);

        emit Claimed(merkleIndex, index, msg.sender, amount);
    }

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}