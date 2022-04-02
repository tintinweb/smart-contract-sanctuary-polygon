// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "../interfaces/Interfaces.sol";

interface IERC165 {
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

interface IERC1155Metadata {
  event URI(string _uri, uint256 indexed _id);
  function uri(uint256 _id) external view returns (string memory);
}

interface IERC1155TokenReceiver {
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}

interface InvManLike {
    function getTokenURI(uint256 id) external view returns (string memory);
}

contract EtherOrcsItems is IERC1155 {

    address implementation_;
    address admin;

    /***********************************|
    |        Variables and Events       |
    |__________________________________*/

    // onReceive function signatures
    bytes4 constant internal ERC1155_RECEIVED_VALUE       = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;
    uint8 internal constant WRAPPED_BONESHARD_ID          = 5;

    mapping (address => mapping(uint256 => uint256))  internal balances;
    mapping (address => mapping(uint256 => uint256))  internal decimalBalances;
    mapping (address => mapping(address => bool))     internal operators;

    mapping(address => bool) public isMinter;

    address public inventoryManager;
    address public boneshards;

   /****************************************|
  |            Minting Functions           |
  |_______________________________________*/



    function _mint(address _to, uint256 _id, uint256 _amount) internal {
        decimalBalances[_to][_id] += _amount; 
        balances[_to][_id] = decimalBalances[_to][_id] / 1 ether;
        emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount / 1 ether);
    }
    
    function _burn(address _from, uint256 _id, uint256 _amount) internal {
        decimalBalances[_from][_id] -= _amount; 
        balances[_from][_id] = decimalBalances[_from][_id] / 1 ether;
        emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount / 1 ether);
    }

    function mint(address to,uint256 id, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO MINT");
        _mint(to, id, value);
    }

    function burn(address from,uint256 id, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO BURN");
        _burn(from, id, value);
    }

    function wrapBoneshard(uint256 value) external {
        ERC20Like(boneshards).transferFrom(msg.sender, address(this), value * 1 ether);
        _mint(msg.sender, WRAPPED_BONESHARD_ID, value);
    }

    function unwrapBoneshard(uint256 value) external {
        _burn(msg.sender, WRAPPED_BONESHARD_ID, value);
        ERC20Like(boneshards).transferFrom(address(this), msg.sender, value * 1 ether);
    }

    function setMinter(address minter, bool status) external {
        require(msg.sender == admin, "NOT ALLOWED TO RULE");

        isMinter[minter] = status;
    }

    function setInventoryManager(address inv_) external {
        require(msg.sender == admin);
        inventoryManager = inv_;
    }

    function setBoneshards(address bone_) external {
        require(msg.sender == admin);
        boneshards = bone_;
    }

    /***********************************|
    |     Public Transfer Functions     |
    |__________________________________*/

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
        public override
    {
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
        require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");

        _safeTransferFrom(_from, _to, _id, _amount);
        _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
        public override
    {
        // Requirements
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
        require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

        _safeBatchTransferFrom(_from, _to, _ids, _amounts);
        _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
    }


    /***********************************|
    |    Internal Transfer Functions    |
    |__________________________________*/

    function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
        internal
    {
        // Update balances
        decimalBalances[_from][_id] -= _amount * 1 ether;
        decimalBalances[_to][_id]   += _amount * 1 ether;

        balances[_from][_id] = decimalBalances[_from][_id] / 1 ether;
        balances[_to][_id]   = decimalBalances[_to][_id] / 1 ether;

        // Emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    /**
    * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
    */
    function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data) internal {
        // Check if recipient is contract
        if (_to.code.length != 0) {
        bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas: _gasLimit}(msg.sender, _from, _id, _amount, _data);
        require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
        }
    }

    function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts) internal {
        require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

        // Number of transfer to execute
        uint256 nTransfer = _ids.length;

        // Executing all transfers
        for (uint256 i = 0; i < nTransfer; i++) {
            // Update storage balance of previous bin
            decimalBalances[_from][_ids[i]] -= _amounts[i] * 1 ether;
            decimalBalances[_to][_ids[i]]   += _amounts[i] * 1 ether;

            balances[_from][_ids[i]] = decimalBalances[_from][_ids[i]] / 1 ether;
            balances[_to][_ids[i]]   = decimalBalances[_to][_ids[i]] / 1 ether;
        }

        // Emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    /**
    * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
    */
    function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data) internal {
        // Pass data if recipient is contract
        if (_to.code.length != 0) {
        bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
        require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
        }
    }


    /***********************************|
    |         Operator Functions        |
    |__________________________________*/


    function setApprovalForAll(address _operator, bool _approved)
        external override
    {
        // Update operator status
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator)
        public override view returns (bool isOperator)
    {
        return operators[_owner][_operator];
    }


    /***********************************|
    |         Balance Functions         |
    |__________________________________*/

    function balanceOf(address _owner, uint256 _id) public override view returns (uint256) {
        return balances[_owner][_id];
    }

    function balanceOfDecimals(address _owner, uint256 _id) public view returns (uint256) {
        return decimalBalances[_owner][_id];
    }

    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids) public override view returns (uint256[] memory) {
        require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

        // Variables
        uint256[] memory batchBalances = new uint256[](_owners.length);

        // Iterate over each owner and token ID
        for (uint256 i = 0; i < _owners.length; i++) {
        batchBalances[i] = balances[_owners[i]][_ids[i]];
        }

        return batchBalances;
    }

    function uri(uint256 _id) public view returns (string memory) {
        return InvManLike(inventoryManager).getTokenURI(_id);
    }

    function owner() external view returns(address own_) {
        own_ = admin;
    }


    /***********************************|
    |          ERC165 Functions         |
    |__________________________________*/

    function supportsInterface(bytes4 _interfaceID) public override pure returns (bool) {
        if (_interfaceID == type(IERC1155).interfaceId) {
            return true;
        }
        if (_interfaceID == type(IERC1155Metadata).interfaceId) {
            return true;
        }
        return _interfaceID == this.supportsInterface.selector;
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface OrcishLike {
    function pull(address owner, uint256[] calldata ids) external;
    function manuallyAdjustOrc(uint256 id, uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress) external;
    function transfer(address to, uint256 tokenId) external;
    function orcs(uint256 id) external view returns(uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress);
    function allies(uint256 id) external view returns (uint8 class, uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, bytes22 details);
    function adjustAlly(uint256 id, uint8 class_, uint16 level_, uint32 lvlProgress_, uint16 modF_, uint8 skillCredits_, bytes22 details_) external;
    function ogres(uint256 id) external view returns(uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, uint8 body, uint8 mouth, uint8 nose, uint8 eyes, uint8 armor, uint8 mainhand, uint8 offhand);
    function claim(uint256[] calldata ids) external;
    function rogue(bytes22 details) external pure returns(uint8 body, uint8 face, uint8 boots, uint8 pants,uint8 shirt,uint8 hair ,uint8 armor ,uint8 mainhand,uint8 offhand);
}


        

interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface OracleLike {
    function request() external returns (uint64 key);
    function getRandom(uint64 id) external view returns(uint256 rand);
}

interface MetadataHandlerLike {
    function getTokenURI(uint16 id, uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier) external view returns (string memory);
}

interface MetadataHandlerAllies {
    function getTokenURI(uint256 id_, uint256 class_, uint256 level_, uint256 modF_, uint256 skillCredits_, bytes22 details_) external view returns (string memory);
}

interface RaidsLike {
    function stakeManyAndStartCampaign(uint256[] calldata ids_, address owner_, uint256 location_, bool double_) external;
    function startCampaignWithMany(uint256[] calldata ids, uint256 location_, bool double_) external;
    function commanders(uint256 id) external returns(address);
    function unstake(uint256 id) external;
}

interface RaidsLikePoly {
    function stakeManyAndStartCampaign(uint256[] calldata ids_, address owner_, uint256 location_, bool double_, uint256[] calldata potions_, uint256[] calldata runes_) external;
    function startCampaignWithMany(uint256[] calldata ids, uint256 location_, bool double_,  uint256[] calldata potions_, uint256[] calldata runes_) external;
    function commanders(uint256 id) external returns(address);
    function unstake(uint256 id) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

interface EtherOrcsLike {
    function ownerOf(uint256 id) external view returns (address owner_);
    function activities(uint256 id) external view returns (address owner, uint88 timestamp, uint8 action);
    function orcs(uint256 orcId) external view returns (uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress);
}

interface ERC20Like {
    function balanceOf(address from) external view returns(uint256 balance);
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface ERC1155Like {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface HallOfChampionsLike {
    function joined(uint256 orcId) external view returns (uint256 joinDate);
} 

interface AlliesLike {
    function allies(uint256 id) external view returns (uint8 class, uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, bytes22 details);
}