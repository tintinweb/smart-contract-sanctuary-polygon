//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../concatenate.sol";

interface RulesInterface{
    function tokenCheck (uint id, uint valToCheck, address _con) external view returns (bool);
}

interface RacerInterface {
    function tokensOfOwner(address _owner) external view returns (uint[] memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address _owner, uint256 _id) external view returns (uint);
}

interface StakingInterface {
    function walletList() external view returns (address[] memory);
    function rulesByRace(uint _race) external view returns(uint,address,uint,uint,uint);
}

contract ORL_Engine is Ownable, Concatenate {
    using SafeMath for uint256;

    //peanuts
    address public tokenAddress = address(0xCAf44e62003De4B8bD17c724f2B78CC532550C2F); 
    IERC20 rewardToken = IERC20(tokenAddress);
    //Racers
    address public erc721Contract = address(0x72106Bbe2b447ECB9b52370Ddc63cfa8e553B08C);
    IERC721 stakeableNFT = IERC721(erc721Contract);
    
    address public customAddress = 0xabA082D325AdC08F9a1c5A8208Bb5c42B3A6F978;
    IERC721 public customContract = IERC721(customContract);

    address public stakingAddress = address(0);

    address public tierAddress = 0x4e0FdEc499A5bE21e1020151ace258D0A081E71e;


    //data//
    uint deployT;
    uint public raceNum = 1;

    //Required in order to avoid
    //the stack too deep error
    struct racerTemp{
        uint tempID;
        address tempCon;
        uint tempEvent;
        address tempOwner;
        uint tempBoost;
        uint tempRID;
        uint newN;
        uint num;
        uint week;
    }

    struct performance{
        uint id;
        address nftContract;
        address owner;
        uint leg1;
        uint leg2;
        uint leg3;
        uint eventWanted;
    }

    struct raceRules{
        uint gridSize;
        address conCheck;
        uint conValue;
        uint matPrice;
        uint prlPrice;     
    }

    mapping(uint => raceRules) public rulesByRace;

    mapping(address => bool) public isTeamMember;
    
    mapping(uint => mapping(address => mapping(uint => uint))) public tierFilled;

    mapping(uint => mapping(uint => performance)) public perfByRacer;

    mapping(uint => uint[]) public racersByEvent;

    mapping(address => mapping(uint => uint)) public slotByRacer;

    mapping(address => uint) public walletToID;

    mapping (address => uint) public walletToAnchor;
    mapping (address => uint) public walletToVC;
    
    address[] public walletID;

    mapping(address => uint) public contractByType;

    uint public currentlyStaked;

    constructor() {
        deployT = block.timestamp;
        isTeamMember[msg.sender] = true;
    }


    // ADMIN //
    function teamUpdate(address to, bool member) public {
        require(isTeamMember[msg.sender] == true, "Caller is not a member of the team.");
        isTeamMember[to] = member;
    }

    function createEvent(uint _id, uint _size, address _conCheck, uint _adv, uint _conValue, uint _matP, uint _nutP) public {
        raceRules memory _rules;
        _rules.gridSize = _size;
        _rules.conCheck = _conCheck;
        _rules.conValue = _conValue;
        _rules.matPrice = _matP;
        _rules.prlPrice = _nutP;
        rulesByRace[_id] = _rules;
    }

    function newStaking(address _stake) public onlyOwner {
        stakingAddress = _stake;
    }

    function addRacers(address _sender, address _con, uint[] calldata _id, uint[] calldata _ev) external { 
        racerTemp memory _temp;

        _temp.week = 0;
        uint _count = _id.length;

        _temp.num = block.timestamp;

        for(uint i=0; i<_count; i++){
            bool ownership;
            _temp.tempID = _id[i];
            _temp.tempCon = _con;
            _temp.tempEvent = _ev[i];
            _temp.tempOwner = _sender;
            address _own = address(0);
            if (_temp.tempCon == erc721Contract){
                _own = stakeableNFT.ownerOf(_temp.tempID);
                ownership = (_own == _temp.tempOwner);
            } else if (_temp.tempCon == customAddress) {
                _own = customContract.ownerOf(_temp.tempID);
                ownership = (_own == _temp.tempOwner);
            }
        
            string memory _err;
            string memory _uid;
            _uid = Strings.toString(_temp.tempID);
            _err = concat("Following token does not belong to you: ",_uid);

            uint teehee;
            teehee = slotByRacer[_temp.tempCon][_temp.tempID];

            if (teehee == 0){
                teehee = currentlyStaked;
                currentlyStaked = currentlyStaked + 1;
                slotByRacer[_temp.tempCon][_temp.tempID] = teehee;
            }
            

            perfByRacer[_temp.week][teehee].id = _temp.tempID;
            perfByRacer[_temp.week][teehee].nftContract = _temp.tempCon;
            perfByRacer[_temp.week][teehee].eventWanted = _temp.tempEvent;
            perfByRacer[_temp.week][teehee].owner = _temp.tempOwner;
            _temp.newN = randomNumber(_temp.num, 3, 10);  
            perfByRacer[_temp.week][teehee].leg1 = _temp.newN;
            _temp.num = _temp.num + _temp.newN;
            _temp.newN = randomNumber(_temp.num, 3, 10);  
            perfByRacer[_temp.week][teehee].leg2 = _temp.newN;
            _temp.num = _temp.num + _temp.newN;
            _temp.newN = randomNumber(_temp.num, 6, 12);  
            perfByRacer[_temp.week][teehee].leg3 = _temp.newN;
            
            racersByEvent[_temp.tempEvent].push(teehee);            

            if (_temp.tempEvent > 0 && _temp.tempEvent < 18){
                uint takenBy = tierFilled[_temp.week][_temp.tempOwner][_temp.tempEvent];
                if (takenBy != 0){
                    uint[] memory temp = new uint[](1);
                    temp[0] = takenBy;
                    returnTokens(temp);
                }
                tierFilled[_temp.week][_temp.tempOwner][_temp.tempEvent] = teehee;
            }

            require(ownership == true, _err);
            bool answer = RulesInterface(rulesByRace[_temp.tempEvent].conCheck).tokenCheck(_id[i],rulesByRace[_temp.tempEvent].conValue,_temp.tempCon);
        }
    }

    function returnTokens(uint256[] memory _tokenID) public {
        StakingInterface _staking = StakingInterface(stakingAddress);
        uint _week = 0;
        uint[] memory _racers = _tokenID;
        for( uint i = 0; i < _racers.length; i ++ ) {
            uint _tok = _racers[i];
            performance storage staking = perfByRacer[_week][_tok];

            uint _tt = staking.id;
            uint _ev = staking.eventWanted;
            uint256[] storage eventNFTs = racersByEvent[_ev];
            address _owner = stakeableNFT.ownerOf(_tt);
            require(_owner == msg.sender, "One of those NFTs does not belong to you.");
            
            uint j = 0;
            if (eventNFTs.length > 0) {
            
                for(j; j< eventNFTs.length; j++){
                    if (eventNFTs[j] == _tok){
                        eventNFTs[j] = eventNFTs[(eventNFTs.length-1)];
                        eventNFTs.pop();
                        break;
                    }
                }
            
            }
            perfByRacer[_week][_tok].eventWanted = 100;
            //slotByRacer[_week][_tt] = 0;
            //staking.id = 0;
        }
    }

    function getOwnerStaked(address _owner) public view returns ( uint [] memory){
        StakingInterface _staking = StakingInterface(stakingAddress);
        uint _week = 0;
        uint[] memory ownersTokens = RacerInterface(erc721Contract).tokensOfOwner(_owner);
        uint[] memory ownersStaked = new uint[](ownersTokens.length);
        uint index;
        for ( uint i = 0; i < ownersTokens.length; i ++ ) {
            uint t = (ownersTokens[i]);
            uint _slot = slotByRacer[erc721Contract][t];
            uint _id = perfByRacer[_week][_slot].id;
            if (_id == t && perfByRacer[_week][_slot].eventWanted != 100 ){
                ownersStaked[index] = _id;
                index = index + 1;
            }
        }

        uint[] memory _return = new uint[](index);
        uint j;
        for(j; j < index; j++){
            _return[j] = ownersStaked[j];
        }

        return _return;
    }

    function getOwnerUnstaked(address _owner) public view returns ( uint [] memory){
        StakingInterface _staking = StakingInterface(stakingAddress);
        uint _week = 0;
        uint[] memory ownersTokens = RacerInterface(erc721Contract).tokensOfOwner(_owner);
        uint[] memory ownersUnstaked = new uint[](ownersTokens.length);
        uint index;
        
        for ( uint i = 0; i < ownersTokens.length; i ++ ) {
            uint t = (ownersTokens[i]);
            address oh;
            
            uint _slot = slotByRacer[erc721Contract][t];
            uint _id = perfByRacer[_week][_slot].id;
            if (_id != ownersTokens[i] || perfByRacer[_week][_slot].eventWanted == 100 ){
                ownersUnstaked[index] = ownersTokens[i];
                index = index + 1;
            }
        }
        uint[] memory _return = new uint[](index);
        uint j;
        for(j; j < index; j++){
            _return[j] = ownersUnstaked[j];
        }
        return _return;
    }

    function getOwnerStakedCount(address _owner) public view returns (uint){
        uint[] memory _temp = getOwnerStaked(_owner);
        uint _return = _temp.length;
        return _return;
    }

    function returnRacers(uint _event) public view returns(uint[] memory){
        uint[] memory _racers = racersByEvent[_event];
        return _racers;
    }

    // DEBUG AND MANAGEMENT //
    function randomNumber(uint _nonce, uint _start, uint _end) private view returns (uint){
        uint _far = _end.sub(_start);
        uint random = uint(keccak256(abi.encodePacked(deployT, msg.sender, _nonce))).mod(_far);
        random = random.add(_start);
        return random;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;
contract Concatenate {
    function concat(string memory a,string memory b) public pure returns (string memory){
        return string(bytes.concat(bytes(a), "", bytes(b)));
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