// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {GenericRegistry} from "../lib/autonolas-registries/contracts/GenericRegistry.sol";
import {ERC721} from "../lib/autonolas-registries/lib/solmate/src/tokens/ERC721.sol";

/// @dev Only `grower` has a privilege, but the `sender` was provided.
/// @param sender Sender address.
/// @param grower Required grower address.
/// @param growId Grow Id.
error GrowerOnly(address sender, address grower, uint256 growId);

/// @dev Only `owner` has a privilege, but the `sender` was provided.
/// @param sender Sender address.
/// @param owner Required grower address.
error OwnerOnly(address sender, address owner);

/// @dev Grow does not exist.
/// @param growId Grow Id.
error GrowNotFound(uint256 growId);

/// @dev Grow is already redeemed.
/// @param growId Grow Id.
error GrowRedeemed(uint256 growId);

/// @dev Proposed grow state is already redeemed.
/// @param growId Grow Id.
error WrongGrowState(uint256 growId);

/// @dev Only `multisig` has a privilege, but the `sender` was provided.
/// @param sender Sender address.
/// @param multisig Required multisig address.
/// @param growId Grow Id.
error MultisigOnly(address sender, address multisig, uint256 growId);

/// @dev Redeem is not approved by the grower.
/// @param growId Grow Id.
error RedeemNotApproved(uint256 growId);

/// @title Grow Registry - Smart contract for registering grows
contract GrowRegistry is GenericRegistry {
    enum GrowState {
        Growing,
        HarvestProposed,
        ReadyToHarvest,
        Harvested,
        Redeemed
    }

    struct Grow {
        // Grow hash
        bytes32 hash;
        // Grower address
        address grower;
        // Grow temperature;
        uint16 growTemperature;
        // Local temperature;
        uint16 localTemperature;
        // Grow moisture;
        int8 moisture;
        // Approval for redemption
        bool approval;
        // Grow state
        GrowState state;
    }

    event CreateGrow(address indexed growOwner, address grower, uint256 indexed growId, bytes32 indexed growHash);
    event UpdateGrowHash(address indexed grower, uint256 indexed growId, bytes32 indexed growHash);
    event Growing(address indexed multisig, uint256 indexed growId);
    event HarvestProposed(address indexed grower, uint256 indexed growId);
    event ReadyToHarvest(address indexed multisig, uint256 indexed growId);
    event Harvested(address indexed grower, uint256 indexed growId);
    event ApproveRedeem(address indexed grower, uint256 indexed growId);
    event Redeemed(address indexed growOwner, uint256 indexed growId);

    // Grow registry version number
    string public constant VERSION = "1.0.0";
    // Agent multisig address
    address public multisig;
    // Map of grow Id => Grow struct
    mapping(uint256 => Grow) public mapGrows;

    /// @dev Grow registry constructor.
    /// @param _name Grow registry contract name.
    /// @param _symbol Grow registry contract symbol.
    /// @param _baseURI Grow registry token base URI.
    constructor(string memory _name, string memory _symbol, string memory _baseURI)
        ERC721(_name, _symbol)
    {
        baseURI = _baseURI;
        owner = msg.sender;
    }

    /// @dev Sets the agent multisig address.
    /// @param _multisig Agent multisig address.
    function setMultisig(address _multisig) external {
        // Check the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        if (_multisig == address(0)) {
            revert ZeroAddress();
        }

        multisig = _multisig;
    }

    /// @dev Creates a grow.
    /// @param growOwner Owner of the grow.
    /// @param grower Grower address.
    /// @param growHash IPFS CID hash of the grow metadata.
    /// @return growId The id of a created grow.
    function create(address growOwner, address grower, bytes32 growHash) external returns (uint256 growId) {
        // Reentrancy guard
        if (_locked > 1) {
            revert ReentrancyGuard();
        }
        _locked = 2;

        // Checks for a non-zero grow owner and grower addresses
        if(growOwner == address(0) || grower == address(0)) {
            revert ZeroAddress();
        }

        // Check for the non-zero hash value
        if (growHash == 0) {
            revert ZeroValue();
        }

        // Grow Id is derived from the totalSupply value
        growId = totalSupply;
        // Grow with Id = 0 is left empty not to do additional checks for the index zero
        growId++;

        // Initialize the grow and mint its token
        Grow storage grow = mapGrows[growId];
        grow.hash = growHash;

        // Set the grower address
        grow.grower = grower;

        // Set total supply to the grow Id number
        totalSupply = growId;
        // Safe mint is needed since contracts can create grows as well
        _safeMint(growOwner, growId);

        emit CreateGrow(growOwner, grower, growId, growHash);
        _locked = 1;
    }

    /// @dev Updates the grow hash.
    /// @param growId Grow Id.
    /// @param growHash Updated IPFS CID hash of the grow metadata.
    function updateHash(uint256 growId, bytes32 growHash) external {
        Grow storage grow = mapGrows[growId];
        // Checking the grower address
        address grower = grow.grower;
        if (grower != msg.sender) {
            revert GrowerOnly(msg.sender, grower, growId);
        }

        // Check for the hash value
        if (growHash == 0) {
            revert ZeroValue();
        }

        // Update grow hash
        grow.hash = growHash;
        emit UpdateGrowHash(msg.sender, growId, growHash);
    }

    /// @dev Gets the latest grow hash for the grow Id.
    /// @notice The latest hash is going to be used by the tokenURI() function.
    /// @param growId Grow Id.
    function _getUnitHash(uint256 growId) internal view override returns (bytes32) {
        if (growId > 0 && growId <= totalSupply) {
            return mapGrows[growId].hash;
        } else {
            revert GrowNotFound(growId);
        }
    }

    /// @dev Proposes to harvest.
    /// @param growId The id of a grow.
    function proposeToHarvest(uint256 growId) external {
        Grow storage grow = mapGrows[growId];
        // Checking the grower address
        address grower = grow.grower;
        if (grower != msg.sender) {
            revert GrowerOnly(msg.sender, grower, growId);
        }

        // Check for the correct grow state
        GrowState currentGrowState = grow.state;
        if (currentGrowState != GrowState.Growing) {
            revert WrongGrowState(growId);
        }

        // Record the proposed grow state
        grow.state = GrowState.HarvestProposed;
        emit HarvestProposed(msg.sender, growId);
    }

    /// @dev Sets ready to harvest or back to the growing grow state.
    /// @notice This function is accessed by the multisig only.
    /// @param growId The id of a grow.
    /// @param isReady Flag for the harvest to be ready.
    function setGrowState(uint256 growId, bool isReady) external {
        // Checking the multisig address
        if (multisig != msg.sender) {
            revert MultisigOnly(msg.sender, multisig, growId);
        }

        Grow storage grow = mapGrows[growId];
        // Get the proposed grow state
        GrowState growState = grow.state;
        if (growState != GrowState.HarvestProposed) {
            revert WrongGrowState(growId);
        }

        // Change the grow state
        if (isReady) {
            grow.state = GrowState.ReadyToHarvest;
            emit ReadyToHarvest(msg.sender, growId);
        } else {
            grow.state = GrowState.Growing;
            emit Growing(msg.sender, growId);
        }
    }

    /// @dev Sets grow parameters.
    /// @notice This function is accessed by the multisig only.
    /// @param growId The id of a grow.
    /// @param _growTemperature Grow temperature.
    /// @param _localTemperature Local temperature.
    /// @param _moisture Moisture.
    function setGrowParameters(uint256 growId, uint16 _growTemperature, uint16 _localTemperature, int8 _moisture) external {
        // Checking the multisig address
        if (multisig != msg.sender) {
            revert MultisigOnly(msg.sender, multisig, growId);
        }

        Grow storage grow = mapGrows[growId];
        grow.growTemperature = _growTemperature;
        grow.localTemperature = _localTemperature;
        grow.moisture = _moisture;
    }

    /// @dev Harvests the grow.
    /// @param growId Grow id.
    function harvest(uint256 growId) external {
        Grow storage grow = mapGrows[growId];
        // Checking the grower address
        address grower = grow.grower;
        if (grower != msg.sender) {
            revert GrowerOnly(msg.sender, grower, growId);
        }

        // Check for the correct grow state
        GrowState currentGrowState = grow.state;
        if (currentGrowState != GrowState.ReadyToHarvest) {
            revert WrongGrowState(growId);
        }

        // Record the proposed grow state
        grow.state = GrowState.Harvested;
        emit Harvested(msg.sender, growId);
    }

    /// @dev Approves to redeem the grow.
    /// @param growId Grow id.
    function approveRedeem(uint256 growId) external {
        Grow storage grow = mapGrows[growId];
        // Checking the grower address
        address grower = grow.grower;
        if (grower != msg.sender) {
            revert GrowerOnly(msg.sender, grower, growId);
        }

        // Check for the correct grow state
        GrowState currentGrowState = grow.state;
        if (currentGrowState != GrowState.Harvested) {
            revert WrongGrowState(growId);
        }

        // Approve the grow redemption
        grow.approval = true;
        emit ApproveRedeem(msg.sender, growId);
    }

    /// @dev Redeems the grow.
    /// @param growId Grow id.
    function redeem(uint256 growId) external {
        Grow storage grow = mapGrows[growId];
        // Checking the grow ownership
        address growOwner = ownerOf(growId);
        if (growOwner != msg.sender) {
            revert GrowerOnly(msg.sender, growOwner, growId);
        }

        // Check for the correct grow state
        GrowState currentGrowState = grow.state;
        if (currentGrowState != GrowState.Harvested) {
            revert WrongGrowState(growId);
        }

        // Checking the redemption approval
        bool approved = grow.approval;
        if (!approved) {
            revert RedeemNotApproved(growId);
        }

        // Record the proposed grow state
        grow.state = GrowState.Redeemed;
        emit Redeemed(msg.sender, growId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../lib/solmate/src/tokens/ERC721.sol";
import "./interfaces/IErrorsRegistries.sol";

/// @title Generic Registry - Smart contract for generic registry template
/// @author Aleksandr Kuperman - <[email protected]>
abstract contract GenericRegistry is IErrorsRegistries, ERC721 {
    event OwnerUpdated(address indexed owner);
    event ManagerUpdated(address indexed manager);
    event BaseURIChanged(string baseURI);

    // Owner address
    address public owner;
    // Unit manager
    address public manager;
    // Base URI
    string public baseURI;
    // Unit counter
    uint256 public totalSupply;
    // Reentrancy lock
    uint256 internal _locked = 1;
    // To better understand the CID anatomy, please refer to: https://proto.school/anatomy-of-a-cid/05
    // CID = <multibase_encoding>multibase_encoding(<cid-version><multicodec><multihash-algorithm><multihash-length><multihash-hash>)
    // CID prefix = <multibase_encoding>multibase_encoding(<cid-version><multicodec><multihash-algorithm><multihash-length>)
    // to complement the multibase_encoding(<multihash-hash>)
    // multibase_encoding = base16 = "f"
    // cid-version = version 1 = "0x01"
    // multicodec = dag-pb = "0x70"
    // multihash-algorithm = sha2-256 = "0x12"
    // multihash-length = 256 bits = "0x20"
    string public constant CID_PREFIX = "f01701220";

    /// @dev Changes the owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external virtual {
        // Check for the ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /// @dev Changes the unit manager.
    /// @param newManager Address of a new unit manager.
    function changeManager(address newManager) external virtual {
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (newManager == address(0)) {
            revert ZeroAddress();
        }

        manager = newManager;
        emit ManagerUpdated(newManager);
    }

    /// @dev Checks for the unit existence.
    /// @notice Unit counter starts from 1.
    /// @param unitId Unit Id.
    /// @return true if the unit exists, false otherwise.
    function exists(uint256 unitId) external view virtual returns (bool) {
        return unitId > 0 && unitId < (totalSupply + 1);
    }
    
    /// @dev Sets unit base URI.
    /// @param bURI Base URI string.
    function setBaseURI(string memory bURI) external virtual {
        // Check for the ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero value
        if (bytes(bURI).length == 0) {
            revert ZeroValue();
        }

        baseURI = bURI;
        emit BaseURIChanged(bURI);
    }

    /// @dev Gets the valid unit Id from the provided index.
    /// @notice Unit counter starts from 1.
    /// @param id Unit counter.
    /// @return unitId Unit Id.
    function tokenByIndex(uint256 id) external view virtual returns (uint256 unitId) {
        unitId = id + 1;
        if (unitId > totalSupply) {
            revert Overflow(unitId, totalSupply);
        }
    }

    // Open sourced from: https://stackoverflow.com/questions/67893318/solidity-how-to-represent-bytes32-as-string
    /// @dev Converts bytes16 input data to hex16.
    /// @notice This method converts bytes into the same bytes-character hex16 representation.
    /// @param data bytes16 input data.
    /// @return result hex16 conversion from the input bytes16 data.
    function _toHex16(bytes16 data) internal pure returns (bytes32 result) {
        result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
        (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
        result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
        (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
        result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
        (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
        result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
        (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
        result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
        (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
        result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
        uint256 (result) +
            (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 39);
    }

    /// @dev Gets the hash of the unit.
    /// @param unitId Unit Id.
    /// @return Unit hash.
    function _getUnitHash(uint256 unitId) internal view virtual returns (bytes32);

    /// @dev Returns unit token URI.
    /// @notice Expected multicodec: dag-pb; hashing function: sha2-256, with base16 encoding and leading CID_PREFIX removed.
    /// @param unitId Unit Id.
    /// @return Unit token URI string.
    function tokenURI(uint256 unitId) public view virtual override returns (string memory) {
        bytes32 unitHash = _getUnitHash(unitId);
        // Parse 2 parts of bytes32 into left and right hex16 representation, and concatenate into string
        // adding the base URI and a cid prefix for the full base16 multibase prefix IPFS hash representation
        return string(abi.encodePacked(baseURI, CID_PREFIX, _toHex16(bytes16(unitHash)),
            _toHex16(bytes16(unitHash << 128))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @dev Errors.
interface IErrorsRegistries {
    /// @dev Only `manager` has a privilege, but the `sender` was provided.
    /// @param sender Sender address.
    /// @param manager Required sender address as a manager.
    error ManagerOnly(address sender, address manager);

    /// @dev Only `owner` has a privilege, but the `sender` was provided.
    /// @param sender Sender address.
    /// @param owner Required sender address as an owner.
    error OwnerOnly(address sender, address owner);

    /// @dev Hash already exists in the records.
    error HashExists();

    /// @dev Provided zero address.
    error ZeroAddress();

    /// @dev Agent Id is not correctly provided for the current routine.
    /// @param agentId Component Id.
    error WrongAgentId(uint256 agentId);

    /// @dev Wrong length of two arrays.
    /// @param numValues1 Number of values in a first array.
    /// @param numValues2 Numberf of values in a second array.
    error WrongArrayLength(uint256 numValues1, uint256 numValues2);

    /// @dev Canonical agent Id is not found.
    /// @param agentId Canonical agent Id.
    error AgentNotFound(uint256 agentId);

    /// @dev Component Id is not found.
    /// @param componentId Component Id.
    error ComponentNotFound(uint256 componentId);

    /// @dev Multisig threshold is out of bounds.
    /// @param currentThreshold Current threshold value.
    /// @param minThreshold Minimum possible threshold value.
    /// @param maxThreshold Maximum possible threshold value.
    error WrongThreshold(uint256 currentThreshold, uint256 minThreshold, uint256 maxThreshold);

    /// @dev Agent instance is already registered with a specified `operator`.
    /// @param operator Operator that registered an instance.
    error AgentInstanceRegistered(address operator);

    /// @dev Wrong operator is specified when interacting with a specified `serviceId`.
    /// @param serviceId Service Id.
    error WrongOperator(uint256 serviceId);

    /// @dev Operator has no registered instances in the service.
    /// @param operator Operator address.
    /// @param serviceId Service Id.
    error OperatorHasNoInstances(address operator, uint256 serviceId);

    /// @dev Canonical `agentId` is not found as a part of `serviceId`.
    /// @param agentId Canonical agent Id.
    /// @param serviceId Service Id.
    error AgentNotInService(uint256 agentId, uint256 serviceId);

    /// @dev The contract is paused.
    error Paused();

    /// @dev Zero value when it has to be different from zero.
    error ZeroValue();

    /// @dev Value overflow.
    /// @param provided Overflow value.
    /// @param max Maximum possible value.
    error Overflow(uint256 provided, uint256 max);

    /// @dev Service must be inactive.
    /// @param serviceId Service Id.
    error ServiceMustBeInactive(uint256 serviceId);

    /// @dev All the agent instance slots for a specific `serviceId` are filled.
    /// @param serviceId Service Id.
    error AgentInstancesSlotsFilled(uint256 serviceId);

    /// @dev Wrong state of a service.
    /// @param state Service state.
    /// @param serviceId Service Id.
    error WrongServiceState(uint256 state, uint256 serviceId);

    /// @dev Only own service multisig is allowed.
    /// @param provided Provided address.
    /// @param expected Expected multisig address.
    /// @param serviceId Service Id.
    error OnlyOwnServiceMultisig(address provided, address expected, uint256 serviceId);

    /// @dev Multisig is not whitelisted.
    /// @param multisig Address of a multisig implementation.
    error UnauthorizedMultisig(address multisig);

    /// @dev Incorrect deposit provided for the registration activation.
    /// @param sent Sent amount.
    /// @param expected Expected amount.
    /// @param serviceId Service Id.
    error IncorrectRegistrationDepositValue(uint256 sent, uint256 expected, uint256 serviceId);

    /// @dev Insufficient value provided for the agent instance bonding.
    /// @param sent Sent amount.
    /// @param expected Expected amount.
    /// @param serviceId Service Id.
    error IncorrectAgentBondingValue(uint256 sent, uint256 expected, uint256 serviceId);

    /// @dev Failure of a transfer.
    /// @param token Address of a token.
    /// @param from Address `from`.
    /// @param to Address `to`.
    /// @param value Value.
    error TransferFailed(address token, address from, address to, uint256 value);

    /// @dev Caught reentrancy violation.
    error ReentrancyGuard();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}