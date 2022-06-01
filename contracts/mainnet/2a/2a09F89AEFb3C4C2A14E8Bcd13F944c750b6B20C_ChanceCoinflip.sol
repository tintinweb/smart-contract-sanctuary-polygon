// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ChanceInvite.sol";
import "./interface/IChanceInvite.sol";
import "./interface/IVRFConsumer.sol";
import "./interface/IChanceVault.sol";

contract ChanceCoinflip is Ownable, Pausable, ReentrancyGuard {

    event withdrawLog(address indexed _Chance, address _addrWithdraw, uint256 amount);
    event withdrawInviteLog(address _addrWithdraw, uint256 amount);
    event roundStart(uint256 round, address addrA, bool _coinflip, uint256 amount);
    event roundRemove(uint256 round, address addrA);
    event roundEnd(uint256 round, address _winner, address addrB, bool _coinflip, uint256 amount, uint256 winAmount);
    event inviteLog(address _addrMint, address _addrInvite, uint256 amount);

    uint256 round;
    uint256 public treasuryAmount; // treasury amount that was not claimed

    address public INVITE_ADDR;
    address public VAULT_ADDR;
    address VRF_ADDR;
    address public constant BLACKHOLE_ADDR = 0x0000000000000000000000000000000000000000;

    struct Game {
        uint256 _round;
        address addrA;
        address addrB;
        address inviterA;
        address inviterB;
        bool choiceA;
        bool _coinflip;
        uint256 _block;
        uint256 amount;
        uint256 winAmount;
    }
    mapping(uint256 => Game) public gameMap;
    mapping(address => uint256) public accountMap;
    mapping(address => uint256) public inviteMap;

    Game[] public gameList;

    constructor() {
    }

    function setVRF(address _addr) public onlyOwner {
        VRF_ADDR = _addr;
    }

    function setVaultAddr(address v_addr) public onlyOwner {
        VAULT_ADDR = v_addr;
    }

    function setChanceInvite(address _addr) public onlyOwner {
        INVITE_ADDR = _addr;
    }

    function getGames() public view returns (Game[] memory) {
        return gameList;
    }

    function pushRound(uint256 i) internal {
        gameList.push(gameMap[i]);
        emit roundStart(i, gameMap[i].addrA, gameMap[i].choiceA, gameMap[i].amount);
    }

    function removeRound(uint256 r) internal {
        uint256 index;
        for (uint i; i<gameList.length;++i) {
            if (r == gameList[i]._round) {
                index = i;
                break;
            }
        }
        if (index >= gameList.length) return;

        for (uint i = index; i<gameList.length-1; ++i){
            gameList[i] = gameList[i+1];
        }
        gameList.pop();
        emit roundRemove(r, gameMap[r].addrA);
    }

    function get_rand(uint256 start, uint256 end, uint256 _seed) private pure returns(uint256) {
        if (end == 1) {
            return 1;
        }
        if (start == 0) {
            return 1 + _seed%(end);
        }
        return start + _seed%(end - start + 1);
    }

    function getFlip(uint256 _round) private returns (bool){

        uint256 _seed = IVRFConsumer(VRF_ADDR).getSeed(_round%24);
        uint256 number = get_rand(1, 2, _seed);
        bool coinflip;
        if (number == 1) {
            coinflip = true;
        } else {
            coinflip = false;
        }
        return coinflip;
    }

    function allotAmount(uint256 _round) private {
        uint256 community_amount = gameMap[_round].amount * 3 / 100;
        uint256 invite_amount;
        address winner;
        address inviter;
        if (gameMap[_round].choiceA == gameMap[_round]._coinflip) {
            winner = gameMap[_round].addrA;
            inviter = gameMap[_round].inviterA;
        } else {
            winner = gameMap[_round].addrB;
            inviter = gameMap[_round].inviterB;
        }

        if (inviter != BLACKHOLE_ADDR) {
            invite_amount = community_amount  * 10 / 100;
            inviteMap[inviter] += invite_amount;
            emit inviteLog(msg.sender, inviter, invite_amount);
        }

        // community_amount = community_amount - invite_amount;
        treasuryAmount += community_amount;
        gameMap[_round].winAmount = gameMap[_round].amount - community_amount;
        accountMap[winner] += gameMap[_round].winAmount;

        IChanceVault(VAULT_ADDR).syncAmount(gameMap[_round].winAmount, community_amount - invite_amount, invite_amount);

        emit roundEnd(_round, winner, gameMap[_round].addrB, gameMap[_round]._coinflip, gameMap[_round].amount, gameMap[_round].winAmount);
    }

    function createGame(bool choice, string memory _inviteCode) payable public {
        require(msg.value >= 0.025 ether || msg.value <= 2500 ether, "betLimitError");
        IChanceVault(VAULT_ADDR).deposit{value: msg.value}();

        if (round % 20 == 0) {
            IVRFConsumer(VRF_ADDR).requestRandomWords();
        }

        Game memory game;
        game.addrA = msg.sender;
        game.choiceA = choice;
        game.amount = msg.value;
        game.inviterA = IChanceInvite(INVITE_ADDR).inviteParty(msg.sender, _inviteCode);
        game._round = round;
        gameMap[round] = game;

        pushRound(round);
        round += 1;
    }

    function cancelGame(uint256 _round) public {
        require(gameMap[_round].addrA == msg.sender, "ErrorA");
        require(gameMap[_round].addrB == BLACKHOLE_ADDR, "ErrorB");
        require(gameMap[_round].amount > 0, "Error");
        uint amount = gameMap[_round].amount;
        gameMap[_round].amount = 0;
        removeRound(_round);
        // _withdrow(msg.sender, amount);
        IChanceVault(VAULT_ADDR).withdrow(msg.sender, amount);
    }

    function joinGame(uint256 _round, string memory _inviteCode) payable public {
        require(msg.value == gameMap[_round].amount, "ErrorAmount");
        require(msg.sender != gameMap[_round].addrA, "ErrorGame");
        require(gameMap[_round].addrB == BLACKHOLE_ADDR, "ErrorGame");

        IChanceVault(VAULT_ADDR).deposit{value: msg.value}();

        gameMap[_round].addrB = msg.sender;
        gameMap[_round].amount += msg.value;
        gameMap[_round].inviterB = IChanceInvite(INVITE_ADDR).inviteParty(msg.sender, _inviteCode);

        bool coinflip = getFlip(_round);
        gameMap[_round]._coinflip = coinflip;

        allotAmount(_round);

        removeRound(_round);
    }

    // function _withdrow(address _to, uint256 amount) private {
    //     // if (treasuryAmount > 0){
    //     //     // uint256 c_amount = treasuryAmount;
    //     //     // treasuryAmount = 0;
    //     //     IChanceVault(VAULT_ADDR).withdrow(_to, amount, c_amount);
    //     // } else {
    //     //     IChanceVault(VAULT_ADDR).withdrow(_to, amount, 0);
    //     // }
    //     IChanceVault(VAULT_ADDR).withdrow(_to, amount);
    // }

    function withdrawInvite() public whenNotPaused nonReentrant {
        require(inviteMap[msg.sender] >= 0.025 ether, "AtLest0.025");
        uint amount = inviteMap[msg.sender];
        inviteMap[msg.sender] = 0;
        IChanceVault(VAULT_ADDR).inviteWithdrow(msg.sender, amount);
        emit withdrawInviteLog(msg.sender, amount);
    }

    function withdrawAmount(address payable _to, uint256 _amount) public whenNotPaused nonReentrant {
        uint256 amount = accountMap[msg.sender];
        require(amount > 0 ether, "AtLest0");
        require(_amount <= amount, "NotEnough");
        if (_amount == 0){
            _amount = amount;
        }
        accountMap[msg.sender] -= _amount;
        // _withdrow(_to, amount);
        IChanceVault(VAULT_ADDR).withdrow(_to, amount);
        emit withdrawLog(address(this), msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVRFConsumer {

  function requestRandomWords() external;

  function getSeed(uint256 _s) external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChanceVault {
    function withdrow(address _to, uint256 amount) external;

    function deposit() external payable;

    function syncAmount(uint256 gAmount, uint256 cAmount, uint256 iAmount) external;

    function inviteWithdrow(address _to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChanceInvite {
    function inviteParty(address _addr, string memory _inviteCode) external returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChanceInvite is Ownable {
    using Strings for string;

    struct INVITE {
        address _inviteAddr;
        uint256 _timestamp;
        uint256 number;
    }
    mapping(address => INVITE) public inviteRecordMap;
    mapping(address => bool) public allowMap;
    mapping(address => string) public inviteCodeMap;
    mapping(string => address) public inviteAddrMap;

    address public constant BLACKHOLE_ADDR = 0x0000000000000000000000000000000000000000;
    address public INVITE_MINTER;

    uint private randNonce = 10000000;
    uint256 public inviteTTL;

    function setInviteTTL(uint256 _t) public onlyOwner {
        inviteTTL = _t;
    }

    modifier onlyBase64Hash (string memory str) {
        bytes memory b = bytes (str);
        for (uint i = 0; i < b.length; i++)
            require (0x7FFFFFE07FFFFFE03FF000000000000 & (uint(1) << uint8 (b [i])) > 0);
        _;
    }

    function setInviteCode(string memory inviteCode) public onlyBase64Hash (inviteCode) {
        require(inviteAddrMap[inviteCode] == BLACKHOLE_ADDR, "invite code is used");
        require(bytes(inviteCodeMap[msg.sender]).length == 0, "invite code only set once");
        require(bytes(inviteCode).length < 64, "invite code too long");
        inviteCodeMap[msg.sender] = inviteCode;
        inviteAddrMap[inviteCode] = msg.sender;
    }

    function setInviteAddr(address _addr) public onlyOwner {
        INVITE_MINTER = _addr;
    }

    function setAllowMap(address _addr) public onlyOwner {
        allowMap[_addr] = true;
    }

    function removeAllowMap(address _addr) public onlyOwner {
        // Reset the value to the default value.
        delete allowMap[_addr];
    }

    function inviteParty(address _addr, string memory _inviteCode) external onlyBase64Hash (_inviteCode) returns (address) {
        require(allowMap[msg.sender] == true, "Permission Denied");
        if (inviteRecordMap[_addr]._inviteAddr == BLACKHOLE_ADDR) {
            if (keccak256(abi.encodePacked((_inviteCode))) == keccak256(abi.encodePacked(("")))) {
                return BLACKHOLE_ADDR;
            }
        }

        // self invite code check
        address inviteAddr = inviteAddrMap[_inviteCode];
        if (inviteAddr == _addr) {
            return BLACKHOLE_ADDR;
        }
        if (inviteAddr != BLACKHOLE_ADDR) {
            bool flag;
            // not in record
            if (inviteRecordMap[_addr]._timestamp == 0) {
                INVITE memory invite;
                invite._inviteAddr = inviteAddr;
                invite._timestamp = block.timestamp;
                invite.number = block.number;
                inviteRecordMap[_addr] = invite;
                flag = true;
            } else {
                if (block.number - inviteRecordMap[_addr].number < inviteTTL) {
                    flag = true;
                }
            }
            if (flag == true) {
                inviteAddr = inviteRecordMap[_addr]._inviteAddr;
            }
            return inviteAddr;
        } else {
            return BLACKHOLE_ADDR;
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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