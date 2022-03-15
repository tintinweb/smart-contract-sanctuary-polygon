// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./ERC1155.sol";
import "./Ownable.sol";

contract ERC1155_NFT is ERC1155, Ownable {
    string public name;
    string public symbol;
    uint256 public publicCost = 0.02 ether;
    bool public paused = false;
    uint256 public maxPublic = 10;
    uint256 public AntiWhale = 1;

    mapping(uint256 => string) public tokenURI;

    constructor() ERC1155("") {
        name = "Harvest Chronicle";
        symbol = "HCC";
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external onlyOwner {
        _mint(_to, _id, _amount, "");
    }

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyOwner {
        _mintBatch(_to, _ids, _amounts, "");
    }

    function mint(uint256 _id, uint256 quantity) external payable {
        require(!paused, "The contract is paused!");
        require(quantity > 0, "Quantity Must Be Higher Than Zero");

        if (msg.sender != owner()) {
            require(
                quantity <= maxPublic,
                "You're Not Allowed To Mint more than maxMint Amount"
            );
            require(
                quantity + balanceOf(msg.sender, _id) <= AntiWhale,
                "Amount is Bigger Than What You Can Mint"
            );
            require(msg.value >= publicCost * quantity, "Insufficient Funds");
        }

        _mint(msg.sender, _id, quantity, "");
    }

    function airdrop(
        uint256 _id,
        uint256 quantity,
        address[] memory _addresses
    ) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], _id, quantity, "");
        }
    }

    function burn(uint256 _id, uint256 _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(uint256[] memory _ids, uint256[] memory _amounts)
        external
    {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function burnForMint(
        address _from,
        uint256[] memory _burnIds,
        uint256[] memory _burnAmounts,
        uint256[] memory _mintIds,
        uint256[] memory _mintAmounts
    ) external onlyOwner {
        _burnBatch(_from, _burnIds, _burnAmounts);
        _mintBatch(_from, _mintIds, _mintAmounts, "");
    }

    function setURI(uint256 _id, string memory _uri) external onlyOwner {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function setCost(uint256 _publicCost) public onlyOwner {
        publicCost = _publicCost;
    }

    function setMaxAndAntiWhale(uint256 _public, uint256 _AntiWhale)
        public
        onlyOwner
    {
        maxPublic = _public;
        AntiWhale = _AntiWhale;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return tokenURI[_id];
    }
}