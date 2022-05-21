/**
 *Submitted for verification at polygonscan.com on 2022-05-21
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity >=0.8.12;

interface IGrindHelper {
    struct Ingredient {
        address token;
        address token0;
        address token1;
    }
    function factory() external view returns (address);
    function grind(uint256 itemId, Ingredient[] memory ingredients) external;
    function grinder() external view returns (address);
}




pragma solidity >=0.8.12;

contract BulkGrinder is Ownable, IERC721Receiver {

    address grinder;
    address comethItems;
    address[] resources;

    constructor (address _grinder, address _comethItems, address[] memory _resources) Ownable() {
        grinder = _grinder;
        comethItems = _comethItems;
        resources = _resources;
        IERC721(comethItems).setApprovalForAll(grinder, true);
    }


    function bulkGrind (uint256[] memory itemIDs, IGrindHelper.Ingredient[] memory ingredients) external {
        uint256[] memory balances = new uint256[](resources.length);
        for (uint i = 0; i < resources.length; i++) {
            balances[i] = IERC20(resources[i]).balanceOf(address(this));
        }
        for (uint i = 0; i < itemIDs.length; i++) {
            IERC721(comethItems).safeTransferFrom(msg.sender, address(this), itemIDs[i]);
            IGrindHelper(grinder).grind(itemIDs[i], ingredients);
        }
        for (uint i = 0; i < resources.length; i++) {
            uint256 profit = IERC20(resources[i]).balanceOf(address(this)) - balances[i];
            uint256 taxes = profit * 100 / 1000;
            uint256 leftover = profit - taxes;
            IERC20(resources[i]).transfer(msg.sender, leftover);
            IERC20(resources[i]).transfer(owner(), taxes);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}