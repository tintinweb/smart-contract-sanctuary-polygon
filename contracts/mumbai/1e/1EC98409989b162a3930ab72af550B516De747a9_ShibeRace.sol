// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "../Wuf.sol";
import "./RocketItems.sol";

contract ShibeRace {
    Wuf wuf;
    RocketItems items;

    // pack this later
    struct Race {
        uint256 id; // race dna?/id for attributes
        bool valid;
        bool active;
        uint256 start; // timestamp
        uint256 end;
        uint256 currentStage;
        uint256 maxStages;
        uint256 maxRockets;
        bytes32 winningDna;
        uint256 winningRocketId;
    }

    // struct Rocket {
    //     bytes32 dna; //starting
    //     uint256 acceleration;
    //     uint256 weight;
    //     uint256 armor;
    //     uint256 maxSpeed;
    //     uint256 fuelEffiency;
    //     uint256 position;
    //     // RocketItems.Consumables[] items;
    // }

    // byte encode
    // 2 acceleration (256 max)
    // 5 weight (1048576 max) (in grams? kg)
    // 2 armor (256 max)
    // 2 maxSpeed (256 max)
    // 2 fuelEffiency (256 max)
    // 4 secret attribute 1 (65536 max
    // 5 secret attribute 2 (65536 max)
    // 5 position (1048576 max)

    // 5 left

    event RaceCreated(uint256 indexed raceId, Race race);
    event RaceStart(uint256 indexed raceId);
    event RaceNewStage(uint256 indexed raceId, bytes32 seed);

    event RaceJoined(
        uint256 indexed raceId,
        uint256 indexed rocketId,
        uint256 dna
    );
    event RaceExit(uint256 indexed raceId, uint256 indexed rocketId);

    event RaceEnd(uint256 indexed raceId);

    event Winner(uint256 indexed rocketId, address indexed winner);

    mapping(uint256 => Race) raceIdToInfo;
    mapping(uint256 => uint256) rocketIdToraceId;
    mapping(uint256 => mapping(uint256 => bytes32)) raceIdToStageSeed;

    constructor(address wufToken) {
        wuf = Wuf(wufToken);
    }

    function createRace(uint256 raceId, Race memory _race) public {
        require(raceId != 0, "invalid id");
        raceIdToInfo[raceId] = _race;
        emit RaceCreated(raceId, _race);
    }

    function joinRace(uint256 rocketId, uint256 raceId) public {
        require(raceIdToInfo[raceId].valid == true, "invalid raceId");
        rocketIdToraceId[rocketId] = raceId;
        uint256 dna = wuf.getDna(rocketId);

        emit RaceJoined(raceId, rocketId, dna);
    }

    function exitRace(uint256 rocketId, uint256 raceId) public {
        require(raceIdToInfo[raceId].valid == true, "invalid raceId");
        rocketIdToraceId[rocketId] = 0;

        emit RaceExit(raceId, rocketId);
    }

    function newStage(uint256 raceId) public {
        Race memory race = raceIdToInfo[raceId];
        require(race.currentStage < race.maxStages, "no more stages");
        raceIdToStageSeed[raceId][race.currentStage++] = blockhash(
            block.number
        );
    }

    function getStageSeed(uint256 raceId, uint256 stageNum)
        public
        view
        returns (bytes32)
    {
        return raceIdToStageSeed[raceId][stageNum];
    }

    function calculateState(uint256 rocketId, bytes32 seed)
        public
        view
        returns (bytes32)
    {
        bytes32 rocketSeed = bytes32(wuf.getDna(rocketId));

        return rocketSeed & seed;
    }

    function calculateFinalState(uint256 rocketId, uint256 raceId)
        public
        view
        returns (bytes32)
    {
        bytes32 tmpSeed = bytes32(wuf.getDna(rocketId));
        Race memory race = raceIdToInfo[raceId];
        for (uint256 i = 0; i < race.maxStages; i++) {
            tmpSeed = tmpSeed & raceIdToStageSeed[raceId][i];
        }

        return tmpSeed;
    }

    function claimWin(uint256 raceId, uint256 rocketId) public view {
        Race memory race = raceIdToInfo[raceId];
        bytes32 finalState = calculateFinalState(rocketId, raceId);

        if (uint256(finalState) > uint256(race.winningDna)) {
            race.winningDna = finalState;
            race.winningRocketId = rocketId;
        }
    }

    function claimPrizesOrExp(uint256 raceId, uint256 rocketId) public {
        Race memory race = raceIdToInfo[raceId];
        require(race.end + 30 minutes > block.timestamp, "race hasn't ended"); // 30 minute to claim for now
        bytes32 finalState = calculateFinalState(rocketId, raceId);

        require(
            finalState == race.winningDna && rocketId == race.winningRocketId,
            "not winner"
        );

        wuf.devMint(42 ether, msg.sender);

        emit Winner(rocketId, msg.sender);
        emit RaceEnd(raceId);
    }
}

pragma solidity ^0.8.4;

import "../lib/solmate/src/tokens/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/contracts/contracts/tunnel/FxBaseChildTunnel.sol";

contract Wuf is ERC20, FxBaseChildTunnel, Ownable {
    struct RocketData {
        address owner;
        uint256 timestamp;
        uint256 dna;
        uint256 yield;
        bool staked;
    }

    mapping(uint256 => RocketData) rocketInfo;

    event Staked(address indexed from, uint256 token, uint256 yield);
    event Unstaked(uint256 indexed token);

    constructor(address _fxChild)
        FxBaseChildTunnel(_fxChild)
        ERC20("RocketShibe Token", "WUF", 18)
    {
        // pre mint here
    }

    function getLatestYield(uint256 tokenId) public view returns (uint256) {
        return rocketInfo[tokenId].yield;
    }

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal override {
        (address owner, uint256 token, uint256 yield, bool staked) = abi.decode(
            message,
            (address, uint256, uint256, bool)
        );

        if (claimable(token) > 0) {
            claim(token, owner);
        }

        RocketData memory info = RocketData({
            owner: owner,
            timestamp: block.timestamp,
            dna: rocketInfo[token].dna,
            yield: yield,
            staked: staked
        });

        rocketInfo[token] = info;

        if (owner == address(0)) {
            emit Unstaked(token);
        } else {
            emit Staked(owner, token, yield);
        }
    }

    function claimable(uint256 rocketId) public view returns (uint256) {
        require(rocketInfo[rocketId].staked, "not staked");

        uint256 timeDiff = block.timestamp > rocketInfo[rocketId].timestamp
            ? uint256(block.timestamp - rocketInfo[rocketId].timestamp)
            : 0;
        uint256 amount = (timeDiff * rocketInfo[rocketId].yield * 1 ether) /
            1 days;

        return amount;
    }

    function claim(uint256 rocketId, address to) public {
        require(rocketInfo[rocketId].staked, "not staked");
        _mint(to, claimable(rocketId));

        rocketInfo[rocketId].timestamp = block.timestamp;
    }

    function getDna(uint256 rocketId) public view returns (uint256) {
        return rocketInfo[rocketId].dna;
    }

    function generateDna(uint256 rocketId) public {
        require(rocketInfo[rocketId].staked, "not staked");
        require(rocketInfo[rocketId].dna == 0, "generated already");

        rocketInfo[rocketId].dna = uint256(
            keccak256(abi.encodePacked(block.timestamp))
        );
    }

    // dev functions

    function devMint(uint256 amount, address receiver) public {
        _mint(receiver, amount);
    }

    function devSetDna(uint256 rocketId, uint256 dna) public {
        rocketInfo[rocketId].dna = dna;
    }

    function isStaked(uint256 rocketId) public view returns (bool) {
        return rocketInfo[rocketId].staked;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "../../lib/solmate/src/tokens/ERC1155.sol";

contract RocketItems is ERC1155 {
    string public baseURI = "test";

    enum Consumables {
        SolarPanel,
        Nitrous,
        GravityPotion,
        Invisibility,
        Teleporter,
        Armor,
        Turret,
        ForceField
    }

    enum Prizes {
        Trophy,
        Crown,
        Trinket,
        Amulet,
        Talisman
    }

    function mintConsumable(
        Consumables consumable,
        address to,
        uint256 count
    ) public {
        // TODO gate access to our contracts only here

        _mint(to, uint256(consumable), count, "");
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // metadata stuff here
        return "tester";
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}