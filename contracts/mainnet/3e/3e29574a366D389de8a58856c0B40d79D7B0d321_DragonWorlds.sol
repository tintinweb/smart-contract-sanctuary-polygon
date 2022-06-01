pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";
import "./SafeMath.sol";

contract DragonWorlds is ERC1155, AccessControl, Pausable, ERC1155Burnable
{
    using SafeMath for uint256;

    string public constant name = "Dragon World Pet";

    string public constant symbol = "PET";

    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address private chairman;

    uint256 private curNftId = 10000;

    uint256 private _totalSupply;

    constructor() ERC1155("")
    {
        chairman = msg.sender;
        _setupRole(ADMIN_ROLE, chairman);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    function getOwner() public view returns (address)
    {
        return chairman;
    }

    function setOwner(address owner) external
    {
        require(owner != address(0), "dragonworlds: set owner address is 0");
        renounceRole(ADMIN_ROLE, chairman);
        chairman = owner;
        _setupRole(ADMIN_ROLE, chairman);
    }

    function create(address owner, bytes memory data) private returns (uint256)
    {
        curNftId = curNftId.add(1);
        _mint(owner, curNftId, 1, data);
        _totalSupply = _totalSupply.add(1);
        return curNftId;
    }

    function createNFT(address owner, bytes memory data) public onlyRole(ADMIN_ROLE) returns (uint256)
    {
        return create(owner, data);
    }

    function createBatchNFT(address owner, uint256 num, bytes memory data) public onlyRole(ADMIN_ROLE) returns (uint256[] memory)
    {
        uint256[] memory nftIds = new uint256[](num);
        uint256[] memory nums = new uint256[](num);
        for (uint256 i = 0; i < num; i++)
        {
            curNftId = curNftId.add(1);
            nftIds[i] = curNftId;
            nums[i] = 1;
        }
        _mintBatch(owner, nftIds, nums, data);
        return nftIds;
    }

    function mint(address owner, uint256 id, uint256 num, bytes memory data) public onlyRole(ADMIN_ROLE)
    {
        require(num > 0, "mint: invaild num");
        _mint(owner, id, num, data);
    }

    function mintBatch(address owner, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyRole(ADMIN_ROLE)
    {
        _mintBatch(owner, ids, amounts, data);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public onlyRole(ADMIN_ROLE) virtual override
    {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()) || hasRole(ADMIN_ROLE, _msgSender()), "ERC1155: caller is not owner nor approved");
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyRole(ADMIN_ROLE) virtual override
    {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()) || hasRole(ADMIN_ROLE, _msgSender()), "ERC1155: transfer caller is not owner nor approved");
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function burn(address account, uint256 id, uint256 amount) public onlyRole(ADMIN_ROLE) override
    {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()) || hasRole(ADMIN_ROLE, _msgSender()), "burn: caller is not owner nor approved");
        require(balanceOf(account, id) > 0, "burn: invaild id");
        _burn(account, id, amount);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) public onlyRole(ADMIN_ROLE) override
    {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()) || hasRole(ADMIN_ROLE, _msgSender()), "burn: caller is not owner nor approved");
        _burnBatch(account, ids, amounts);
    }

    function setURI(string memory uri) public onlyRole(ADMIN_ROLE)
    {
        _setURI(uri);
    }

    function pause() public onlyRole(ADMIN_ROLE)
    {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE)
    {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }
}