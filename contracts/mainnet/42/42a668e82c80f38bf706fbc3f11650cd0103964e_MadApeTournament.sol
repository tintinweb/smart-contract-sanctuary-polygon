// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";

contract MadApeTournament is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Address for address;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 10;
    uint256 public nftPerAddressLimit = 10;

    bool internal allowedUnrestrictedTransfers = false;
    mapping(address => bool) internal operators;

    event TransfersAllowed(bool oldValue, bool newValue);
    event OperatorAdded(address operator);
    event OperatorRemoved(address operator);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uriUrl
    ) ERC721(_name, _symbol) {
        setBaseURI(_uriUrl);
    }

    // =========== MODIFIERS METHODS ==========
    /**
     * @dev Throws if called by any account other than an operator.
     */
    modifier onlyOperator() {
        require(operators[_msgSender()], "MirroredApe: caller is not an operator");
        _;
    }

    /**
     * @dev Throws if transfers are not allowed and called by any account other than the operator.
     */
    modifier onlyAllowedTransfers() {
        if (allowedUnrestrictedTransfers) {
            _;
        } else {
            require(operators[_msgSender()], "MirroredApe: caller is not an operator");
            _;
        }
    }
    // =========== MODIFIERS METHODS ==========

    // =========== PUBLIC METHODS ==========
    /**
      * @dev Returns all the tokens owned by an address.
      */
    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /**
      * @dev Returns the token uri for specific tokenId.
      */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    /**
     * @dev Returns boolean if given address is an operator.
     */
    function isOperator(address operator) public view returns (bool){
        return operators[operator];
    }
    // =========== PUBLIC METHODS ==========

    // =========== ADMIN METHODS ==========
    /**
     * @dev Add address as operator.
     * Can only be called by the current owner.
     */
    function addOperator(address operator) public onlyOwner {
        operators[operator] = true;
        emit OperatorAdded(operator);
    }

    /**
     * @dev Remove operator.
     * Can only be called by the current owner.
     */
    function removeOperator(address operator) public onlyOwner {
        operators[operator] = false;
        emit OperatorRemoved(operator);
    }

    /**
     * @dev Sets bool _transfersAllowed.
     * Can only be called by the current owner.
     */
    function setTransfersAllowed(bool allowed) public onlyOwner {
        bool oldValue = allowedUnrestrictedTransfers;
        allowedUnrestrictedTransfers = allowed;
        emit TransfersAllowed(oldValue, allowed);
    }
    // =========== ADMIN METHODS ==========


    // =========== OPERATOR METHODS ==========
    /**
      * @dev Mint multiple specific nfts at once. Can only be called by an operator.
      */
    function multipleMint(address[] calldata receivers, uint256[] calldata tokenIds) public onlyOperator {
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], tokenIds[i]);
        }
    }

    /**
      * @dev Mint a specific nfts. Can only be called by an operator.
      */
    function mint(address receiver, uint256 tokenId) public onlyOperator {
        _safeMint(receiver, tokenId);
    }
    // =========== OPERATOR METHODS ==========

    // =========== OWNER ONLY METHODS ==========
    /**
      * @dev Sets a new base URI. Only callable by owner.
      */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
      * @dev Sets a new base extension. Only callable by owner.
      */
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    /**
      * @dev Method to withdraw all native currency. Only callable by owner.
      */
    function withdraw() public onlyOwner {
        (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
        require(success);
    }

    /**
      * @dev Method to withdraw all tokens complying to ERC20 interface. Only callable by owner.
      */
    function withdrawERC20(address _token) public onlyOwner {
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) > 0, "SafeERC20: Balance already 0");

        bytes memory data = abi.encodeWithSelector(token.transferFrom.selector, address(this), owner(), token.balanceOf(address(this)));
        bytes memory return_data = address(_token).functionCall(data, "SafeERC20: low-level call failed");
        if (return_data.length > 0) {
            // Return data is optional to support crappy tokens like BNB and others not complying to ERC20 interface
            require(abi.decode(return_data, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
    // =========== OWNER ONLY METHODS ==========

    // =========== INTERNAL METHODS ==========
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    // =========== INTERNAL METHODS ==========

    // =========== CUSTOM TRANSFER METHODS ==========
    /**
     * @dev Custom operatorOnly transfers overriding ERC721 ones.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedTransfers {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev Custom operatorOnly transfers overriding ERC721 ones.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedTransfers {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Custom operatorOnly transfers overriding ERC721 ones.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override onlyAllowedTransfers {
        _safeTransfer(from, to, tokenId, _data);
    }
    // =========== CUSTOM TRANSFER METHODS ==========
}