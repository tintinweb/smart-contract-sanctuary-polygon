//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./DefaultOperatorFilterer.sol";

// =============================================================
//        @title: Tipont Loyalty Pass
//        @author: nfteam.eu
// =============================================================

contract TipontPass is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri
    ) ERC721A(name, symbol) {
        tokenUriBase = baseUri;
    }

    // =============================================================
    //                            VARIABLES
    // =============================================================

    string public tokenUriBase;
    State public state;

    uint256 public mintPrice = 0.001 ether;

    uint256 public maxPerWallet = 5;
    mapping(address => uint256) public mintedPerWallet;

    uint256 public maxSupply = 10000;

    // =============================================================
    //                            STATES
    // =============================================================

    enum State {
        Closed,
        Open
    }

    // =============================================================
    //                            EVENTS
    // =============================================================

    event EtherWithdrawn(address _to, uint256 _amount);
    event StateChanged(State _state);

    // =============================================================
    //                            FUNCTIONS
    // =============================================================

    function mint(uint qty) external payable noContract nonReentrant {
        require(state == State.Open, "NO_SALE");
        require(msg.value * qty >= mintPrice, "INSUFFICIENT_ETHER");
        require(totalSupply() + qty <= maxSupply, "NO_MORE_SUPPLY");
        require(
            mintedPerWallet[msg.sender] + qty <= maxPerWallet,
            "MAX_PER_WALLET"
        );

        mintedPerWallet[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function airdrop(
        address[] calldata _wallets,
        uint256[] calldata _amounts
    ) public onlyOwner {
        uint256 totalAmount = 0;
        require(_wallets.length == _amounts.length, "ARRAY_LENGTH_MISMATCH");
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }
        require(totalAmount + totalSupply() <= maxSupply, "NO_MORE_SUPPLY");

        for (uint256 i = 0; i < _wallets.length; i++) {
            _safeMint(_wallets[i], _amounts[i]);
        }
    }

    // =============================================================
    //                            GETTERS
    // =============================================================

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A) returns (string memory) {
        return string(abi.encodePacked(tokenUriBase, _toString(tokenId)));
    }

    // =============================================================
    //                            SETTERS
    // =============================================================

    function setOpen() external onlyOwner {
        state = State.Open;
        emit StateChanged(state);
    }

    function setClosed() external onlyOwner {
        state = State.Closed;
        emit StateChanged(state);
    }

    function setTokenURI(string memory _tokenUriBase) public onlyOwner {
        tokenUriBase = _tokenUriBase;
    }

    // =============================================================
    //                            MODIFIERS
    // =============================================================

    modifier noContract() {
        require(msg.sender == tx.origin, "NO_CONTRACT");
        _;
    }

    // =============================================================
    //                            MISCELLANEOUS
    // =============================================================

    function withdrawAll(address _recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        _withdrawCall(_recipient, balance);

        emit EtherWithdrawn(_recipient, balance);
    }

    function _withdrawCall(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "WITHDRAW_FAIL");
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}