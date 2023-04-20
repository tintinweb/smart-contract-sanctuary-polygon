/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

// File: contracts/interfaces/IERC721Receiver.sol



pragma solidity >= 0.8.0 <0.9.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// File: contracts/standards/ERC721Holder.sol


pragma solidity ^0.8.0;


contract ERC721Holder is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
// File: contracts/interfaces/IERC20.sol



pragma solidity >= 0.8.0 <0.9.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
// File: contracts/interfaces/IERC165.sol



pragma solidity >= 0.8.0 <0.9.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: contracts/standards/ERC165.sol



pragma solidity >=0.8.0 <0.9.0;


abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
// File: contracts/interfaces/IERC1155Receiver.sol



pragma solidity >= 0.8.0 <0.9.0;



interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
// File: contracts/standards/ERC1155Receiver.sol


pragma solidity ^0.8.0;



abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
// File: contracts/standards/ERC1155Holder.sol



pragma solidity ^0.8.0;


contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
// File: contracts/interfaces/IERC721.sol



pragma solidity >= 0.8.0 <0.9.0;


interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
// File: contracts/interfaces/IERC1155.sol



pragma solidity >= 0.8.0 <0.9.0;


interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
// File: contracts/utils/TokenAccessControl.sol


pragma solidity >=0.7.0 <0.9.0;

contract TokenAccessControl {
    bool public paused = false;
    address public owner;
    address public newContractOwner;
    mapping(address => bool) public authorizedContracts;

    event Pause();
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier ifNotPaused() {
        require(!paused, "contract is paused");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not an owner");
        _;
    }

    modifier onlyAuthorizedUser() {
        require(
            authorizedContracts[msg.sender],
            "caller is not an authorized user"
        );
        _;
    }

    modifier onlyOwnerOrAuthorizedUser() {
        require(
            authorizedContracts[msg.sender] || msg.sender == owner,
            "caller is not an authorized user or an owner"
        );
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        newContractOwner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newContractOwner = _newOwner;
    }

    function acceptOwnership() public ifNotPaused {
        require(msg.sender == newContractOwner);
        emit OwnershipTransferred(owner, newContractOwner);
        owner = newContractOwner;
        newContractOwner = address(0);
    }

    function setAuthorizedUser(
        address _operator,
        bool _approve
    ) public onlyOwner {
        if (_approve) {
            authorizedContracts[_operator] = true;
        } else {
            delete authorizedContracts[_operator];
        }
    }

    function setPause(bool _paused) public onlyOwner {
        paused = _paused;
        if (paused) {
            emit Pause();
        }
    }
}

// File: contracts/asset_locking.sol


pragma solidity >=0.7.0 <0.9.0;







contract AssetLocking is TokenAccessControl, ERC1155Holder, ERC721Holder {

    uint256 lockingPeriod = 86400;

    mapping(address => mapping(address => mapping(uint256 => uint256))) private _lockedAssets;
    mapping(address => uint256) private _lockedAssetsCount;
    mapping(address => uint256) private _lockedUntil;
    mapping(address => bool) private _isErc721;

    bytes4 constant private IERC165_ID = 0x01ffc9a7;
    bytes4 constant private IERC1155_ID = 0xd9b67a26;
    bytes4 constant private IERC721_ID = 0x80ac58cd;

    event LockAsset(address indexed owner, address contractAddress, uint256 tokenId);
    event LockBatchAssets(address indexed owner, address contractAddress, uint256[] tokenIds, uint256[] amounts);
    event RelockAsset(address indexed owner);
    event UnlockAsset(address indexed owner, address contractAddress, uint256 tokenId);
    event UnlockBatchAssets(address indexed owner, address contractAddress, uint256[] tokenIds, uint256[] amounts);


    function setLockingPeriod(uint256 _lockingPeriod) onlyOwner external returns (bool) {
        lockingPeriod = _lockingPeriod;
        return true;
    }

    function lock(address contractAddress, uint256 tokenId) external returns (uint256) {
        uint16 contractType = determineContractType(contractAddress);
        if(contractType==1155){
            IERC1155(contractAddress).safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        }
        else if(contractType==721){
            IERC721(contractAddress).transferFrom(msg.sender, address(this), tokenId);
            _isErc721[contractAddress] = true;
        }
        else{
            revert("AssetLocking: Not valid NFT standard");
        }

        _lockedAssets[msg.sender][contractAddress][tokenId]++;
        _lockedAssetsCount[msg.sender]++;
        _lockedUntil[msg.sender] = block.timestamp + lockingPeriod;

        // return new timestamp the asset is locked until
        emit LockAsset(msg.sender, contractAddress, tokenId);
        return _lockedUntil[msg.sender];
    }

    function lockBatch(address contractAddress, uint256[] memory tokenIds, uint256[] memory amounts) external returns (uint256) {
        uint16 contractType = determineContractType(contractAddress);
        if(contractType==1155){
            IERC1155(contractAddress).safeBatchTransferFrom(msg.sender, address(this), tokenIds, amounts, "");
        }
        else{
            revert("AssetLocking: Not valid NFT standard");
        }

        for (uint256 j = 0; j < amounts.length ; j++) {
            _lockedAssets[msg.sender][contractAddress][tokenIds[j]] += amounts[j];
            _lockedAssetsCount[msg.sender] += amounts[j];
        }
        _lockedUntil[msg.sender] = block.timestamp + lockingPeriod;

        // return new timestamp the asset is locked until
        emit LockBatchAssets(msg.sender,contractAddress,tokenIds,amounts);
        return _lockedUntil[msg.sender];
    }

    function relock() external returns (uint256) {
        _lockedUntil[msg.sender] = block.timestamp + lockingPeriod;

        // return new timestamp the asset is locked until
        emit RelockAsset(msg.sender);
        return _lockedUntil[msg.sender];
    }

    function unlock(address contractAddress, uint256 tokenId) external returns (uint256) {
        require(_lockedAssets[msg.sender][contractAddress][tokenId] > 0, "AssetLocking: Insufficient assets locked");
        require(_lockedUntil[msg.sender] < block.timestamp, "AssetLocking: Assets are still locked");

        _lockedAssets[msg.sender][contractAddress][tokenId]--;
        _lockedAssetsCount[msg.sender]--;

        if (_isErc721[contractAddress]) {
            IERC721(contractAddress).transferFrom(address(this), msg.sender, tokenId);
        } else {
            IERC1155(contractAddress).safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
        }

        // return remaining locked count
        emit UnlockAsset(msg.sender,contractAddress,tokenId);
        return _lockedAssets[msg.sender][contractAddress][tokenId];
    }

    function unlockBatch(address contractAddress, uint256[] memory tokenIds, uint256[] memory amounts) external returns (uint256) {
        require(tokenIds.length==amounts.length, "AssetLocking: Length of tokenIds and amounts does not match");
        require(_lockedUntil[msg.sender] < block.timestamp, "AssetLocking: Assets are still locked");
        require(_isErc721[contractAddress] == false, "AssetLocking: Batch transfers are only supported for ERC1155");

        for (uint256 j = 0; j < amounts.length ; j++) {
            require(_lockedAssets[msg.sender][contractAddress][tokenIds[j]] >= amounts[j], "AssetLocking: Insufficient assets locked");

            _lockedAssets[msg.sender][contractAddress][tokenIds[j]] -= amounts[j];
            _lockedAssetsCount[msg.sender] -= amounts[j];
        }

        IERC1155(contractAddress).safeBatchTransferFrom(address(this), msg.sender, tokenIds, amounts, "");

        // return remaining locked total count
        emit UnlockBatchAssets(msg.sender,contractAddress,tokenIds,amounts);
        return _lockedAssetsCount[owner];
    }

    function checkCount(address owner, address contractAddress, uint256 tokenId) external view returns (uint256) {
        return _lockedAssets[owner][contractAddress][tokenId];
    }

    function checkTotalCount(address owner) external view returns (uint256) {
        return _lockedAssetsCount[owner];
    }

    function checkUntil(address owner) external view returns (uint256) {
        return _lockedUntil[owner];
    }

    function determineContractType(address contractAddress) internal view returns(uint16){
        (bool isSuccess, bytes memory response) = contractAddress.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)",IERC1155_ID));
        if(isSuccess){
            if(abi.decode(response, (bool))) return 1155;
            (isSuccess,response) = contractAddress.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)",IERC721_ID));
            if(isSuccess && abi.decode(response, (bool))) return 721;
        }
        (isSuccess,) = contractAddress.staticcall(abi.encodeWithSignature("balanceOf(address,uint256)",msg.sender, 1));
        if(isSuccess) return 1155;
        (isSuccess,) = contractAddress.staticcall(abi.encodeWithSignature("balanceOf(address)",msg.sender));
        if(isSuccess){
            (isSuccess,) = contractAddress.staticcall(abi.encodeWithSignature("decimals()"));
            if(isSuccess) return 20;
            return 721;
        }
        return 0;
    } 

}