// SPDX-License-Identifier: none

import "./interface/IERC1155ManagedSupply.sol";
import "./abstract/BaseRelayRecipient.sol";
import "./abstract/ReentrancyGuard.sol";

pragma solidity ^0.8.0;

contract MinterERC1155 is BaseRelayRecipient, ReentrancyGuard{
    address public immutable nft;

    mapping(address => bool) private _claimed;
    mapping(address => claimParameter) private _claimLog;

    struct claimParameter{
        uint256 id;
        uint256 amount;
        string longitude;
        string latitude;
        string altitude;
    }

    event claimNft(
        address indexed user,
        uint256 indexed id,
        uint256 indexed amount,
        string longitude,
        string latitude,
        string altitude
    );

    constructor(
        address nft_
    ) {
        nft = nft_;
    }

    function userClaimed(
        address user
    ) public view virtual returns (bool) {
        return _claimed[user];
    }

    function userClaimLog(
        address user
    ) public view virtual returns (
        claimParameter memory
    ) {
        require(
            userClaimed(user),
            "MinterERC1155 : This user not claim yet!"
        );
        
        return _claimLog[user];
    }

    function mint(
        uint256 id,
        string memory longitude,
        string memory latitude,
        string memory altitude
    ) public virtual {
        require(
            userClaimed(_msgSender()) == false,
            "MinterERC1155 : You are already claim!"
        );
        
        IERC1155ManagedSupply(nft).mint(
            _msgSender(),
            id,
            1
        );
        _claimed[_msgSender()] = true;
        _claimLog[_msgSender()] = claimParameter(
            id,
            1,
            longitude,
            latitude,
            altitude
        );

        emit claimNft(
            _msgSender(),
            id,
            1,
            longitude,
            latitude,
            altitude
        );
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

interface IERC1155ManagedSupply {
  function addBatchMaxSupply(uint256[] memory ids, uint256[] memory amount) external;
  function addBatchMetadataHash(uint256[] memory ids, string[] memory hashes) external;
  function addMaxId(uint256 amount) external;
  function addMaxSupply(uint256 id, uint256 amount) external;
  function addMetadataHash(uint256 id, string memory hash) external;
  function balanceOf(address account, uint256 id) external view returns(uint256);
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns(uint256[] memory);
  function baseURI() external view returns(string memory);
  function burn(address account, uint256 id, uint256 value) external;
  function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
  function exists(uint256 id) external view returns(bool);
  function isApprovedForAll(address account, address operator) external view returns(bool);
  function isManager(address user) external view returns(bool);
  function isTrustedForwarder(address forwarder) external view returns(bool);
  function maxId() external view returns(uint256);
  function maxSupply(uint256 id) external view returns(uint256);
  function mint(address account, uint256 id, uint256 value) external;
  function mintBatch(address account, uint256[] memory ids, uint256[] memory values) external;
  function name() external view returns(string memory);
  function nextId() external view returns(uint256 id);
  function owner() external view returns(address);
  function renounceOwnership() external;
  function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes calldata data) external;
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
  function setApprovalForAll(address operator, bool approved) external;
  function setManager(address user, bool status) external;
  function supportsInterface(bytes4 interfaceId) external view returns(bool);
  function symbol() external view returns(string memory);
  function totalSupply(uint256 id) external view returns(uint256);
  function transferOwnership(address newOwner) external;
  function trustedForwarder() external view returns(address);
  function uri(uint256 id) external view returns(string memory);
  function versionRecipient() external view returns(string memory);
}

import "./IRelayRecipient.sol";

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

abstract contract BaseRelayRecipient is IRelayRecipient {
    address private _trustedForwarder;
        string public override versionRecipient = "2.2.0";

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

abstract contract IRelayRecipient {
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    function _msgSender() internal virtual view returns (address);

    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}