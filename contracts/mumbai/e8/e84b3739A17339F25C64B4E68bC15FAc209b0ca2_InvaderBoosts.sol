// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC1155.sol";
import "./ERC20.sol";
import "./Owned.sol";
import "./Strings.sol";

error BadTransfer();
error InvalidID();
error MintedOut();

contract InvaderBoosts is ERC1155, Owned {
    using Strings for uint256;

    string public name;
    string public symbol;
    ERC20 public spaceContract;

    uint256 public spacePrice = 100 ether;
    uint256 public constant TOTAL_IDS = 3;
    uint256 public constant MAX_SUPPLY = 200;

    mapping(uint256 => uint256) public totalSupply;

    string baseURI; 

    constructor(
        string memory _baseURI, 
        string memory _name, 
        string memory _symbol,
        address _spaceContract
    ) ERC1155() Owned(msg.sender) {
        baseURI = _baseURI;
        name = _name;
        symbol = _symbol;
        spaceContract = ERC20(_spaceContract);
        _mint(msg.sender, 0, 1, "");
        _mint(msg.sender, 1, 1, "");
        _mint(msg.sender, 2, 1, "");
    }

    function setURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 _id) 
        public 
        view 
        override 
        returns (string memory) 
    {
        return string(abi.encodePacked(baseURI, _id.toString(), ".json"));
    }

    function mint(uint256 _id, uint256 _amt) external {
        if(_id >= TOTAL_IDS) revert InvalidID();
        if(totalSupply[_id] + _amt > MAX_SUPPLY) revert MintedOut();

        bool success = spaceContract.transferFrom(msg.sender, address(this), spacePrice * _amt);
        if(!success) revert BadTransfer();

        unchecked {
            _mint(msg.sender, _id, _amt, "");
            totalSupply[_id] += _amt; 
        }
    }

    function burn(uint256 _id, uint256 _amt) external {
        _burn(msg.sender, _id, _amt);
    }

    function batchBurn(uint256[] memory _ids, uint[] memory _amounts) external {
        _batchBurn(msg.sender, _ids, _amounts);
    }

    function setPrice(uint256 _spacePrice) external onlyOwner {
        spacePrice = _spacePrice;
    }
}